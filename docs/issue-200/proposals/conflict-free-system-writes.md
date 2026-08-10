---
status: proposed
files:
  - warrant/hooks/hunt-guard.sh
  - warrant/hooks/hunt-state.sh
  - warrant/agents/warrant-hunter.md
  - warrant/hooks/directive.sh
  - warrant/hooks/tests/run-hunt-guard-tests.sh
  - docs/issue-200/reports/implementation/survey.md
  - docs/issue-200/reports/implementation.md
---

## Request

Four merge conflicts/day come from two warrant-plugin generators writing into the target repo's worktree with keys that are not structurally unique across concurrent branches: (1) `.warrant-hunt.count`/`.warrant-hunt.lock` at the worktree root, one shared counter for every branch; (2) hunt reports at `docs/reports/<date>-hunt-<slug>.md`, keyed by date+title-slug, which two same-day similar-topic proposals on different branches can both produce. Relocate (1) out of the worktree, key (2) by issue number, and audit every other core-plugin write into a target repo for the same failure shape.

## Constraints

- Session-cap and stance-rotation *behavior* must not change — only *where* the two state files live.
- Hunt-report content/format is unchanged — only its *path*.
- No new dependency, no new env var beyond what already exists (`WARRANT_HUNT_MAX`, `WARRANT_HUNT_CAP_SECONDS`, `CLAUDE_PROJECT_DIR`).
- Must degrade safely (fail-closed, per existing `gate_trap_fail_closed` convention) if the new out-of-tree location cannot be created.
- Empty-state tolerance (a repo where warrant never ran) must survive relocation.

## Rationale

**Chosen:** relocate the count/lock pair to `.git/warrant/` inside the same repo (resolved via the same `git rev-parse --show-toplevel` the scripts already call, then `.git` instead of the toplevel). `.git/` is never a worktree path — it is never staged, diffed, or committed, so two branches can never produce a conflicting entry for it; it is also per-clone, matching the current per-repo (not per-user) semantics the count/lock already have (a fresh clone starts at zero, same as today).

**Rejected alternative — `~/.tokenmaxxxer/state/<repo>/`:** the issue text offers this as an example. Rejected because it changes semantics: the hunt count is currently scoped to *this repository checkout* (reset on `SessionStart`, tracked per work directory); a home-directory path keyed by repo name would need a stable repo identity independent of remote/path (two clones of the same repo would either collide or need extra machinery to disambiguate), and it introduces a cross-repo shared location for what is presently local, single-machine state. `.git/` gives the same per-checkout scoping the code already has with zero identity-resolution work and no new failure mode (a bare/worktree-linked `.git` file instead of a directory is already handled by `git rev-parse`, which `hunt-guard.sh`/`hunt-state.sh` already call).

**Report path — chosen:** `docs/issue-<n>/reports/hunt-<slug>.md`, moving the whole file under the issue's own tree (matching how this repo already scopes every other role's phase-1/phase-2 output per contract v3 s19) rather than only prefixing the filename.

**Rejected alternative — `docs/reports/issue-<n>-hunt-<slug>.md`** (the issue's other example, filename-prefix only, same directory): rejected because it is still weaker than directory-scoping for no benefit — this repo's existing convention (contract v3 s19, `docs/issue-<n>/reports/<role>.md`) already keys every generated doc by issue at the directory level, and a hunter dispatch always knows its proposal's issue number (the dispatcher reads it from the branch/proposal path), so there is no case where directory-scoping is harder to compute than filename-prefixing. Keeping hunt reports in the same `docs/issue-<n>/reports/` directory other roles already write into is one less exception for anyone reading the tree structure to remember.

The audit (see `docs/issue-200/reports/implementation/survey.md`) found no third generator writing into a target-repo worktree with an unscoped key: `freelunch/hooks/observe.sh` already writes to `$HOME/.claude/...` (out-of-tree, no fix needed); every `core/hooks/*-gate.sh` is a PreToolUse gate, not a generator; `terse`, `scout`, and `warrant/hooks/state.sh`/`scope-gate.sh` write nothing. No further fix is required beyond items 1 and 2.

## What will be done

1. **`warrant/hooks/hunt-guard.sh`**: change `lock = posixpath.join(root, ".warrant-hunt.lock")` / `count = posixpath.join(root, ".warrant-hunt.count")` to resolve a `.git`-relative state directory instead (`git rev-parse --git-dir`, made absolute, joined with `warrant/`), creating that directory if absent before writing. Same change in the bash section that reads the lock for `WARRANT_IN_HUNT` budget checks.
2. **`warrant/hooks/hunt-state.sh`**: same `.git`-relative resolution for the `rm -f` targets in `release`/`reset`.
3. **`warrant/agents/warrant-hunter.md`**: update the report-path line (81) and the two example lines (150, 153) from `docs/reports/<date>-hunt-<proposal-slug>.md` to `docs/issue-<n>/reports/hunt-<proposal-slug>.md`.
4. **`warrant/hooks/directive.sh`**: update the matching path text (line 76) the dispatching role hands the hunter, and the `docs/reports/` reference so both dispatch instructions agree with the agent file.
5. **New test** `warrant/hooks/tests/run-hunt-guard-tests.sh`: asserts (a) after a simulated dispatch, no `.warrant-hunt.*` file exists anywhere under the worktree (only under `.git/`); (b) two temp repos standing in for two concurrent issues produce disjoint hunt-report path strings for the same date+slug once the issue number differs; (c) a repo where the state dir has never been created (empty state) is tolerated — no crash, no lock held, cap check falls through to 0 used, matching current behavior.
6. Record the audit inventory (the table already in `docs/issue-200/reports/implementation/survey.md`) as part of this commit; phase-2 will additionally restate it in the record per contract v3 s19.

## Out of scope

- The warrant plugin's own standing `docs/proposals/YYYY-MM-DD-<slug>.md` convention (human-authored proposal docs, not system-generated) — noted in the survey, not fixed here.
- on-the-record's own generated paths — explicitly out of scope per the issue text, tracked in on-the-record's own repo issue.
- Any change to hunt cadence, stance rotation order, session cap value, or budget-second tiers — behavior-preserving only.

## How you'll know it worked

- `warrant/hooks/tests/run-hunt-guard-tests.sh` passes: no state file left in the worktree after a dispatch/release cycle; two issue-scoped report paths for the same date+slug are provably different strings; empty-state (no prior run) does not error and behaves as today (0 used, no lock).
- Manual check: `git status` after a simulated hunt-guard write shows no untracked/modified file at the repo root (the count/lock no longer appear in `git status` at all, since `.git/` is never tracked).
- The audit table is committed and lists every generator found with its file:line and classification.
