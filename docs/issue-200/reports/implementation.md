---
code_under_review:
  - warrant/hooks/hunt-guard.sh
  - warrant/hooks/hunt-state.sh
  - warrant/agents/warrant-hunter.md
  - warrant/hooks/directive.sh
  - warrant/hooks/tests/run-hunt-guard-tests.sh
type: fix
breaking: false
verdict: pass
loop_state: landed
---

# Implementation record — issue-200

## What was done

Relocated the warrant-hunter session-state pair off the worktree and made
hunt-report paths issue-scoped, per the approved proposal
(`docs/issue-200/proposals/conflict-free-system-writes.md`):

1. `warrant/hooks/hunt-guard.sh` — both the bash budget-check section
   (`WARRANT_IN_HUNT=1` path) and the python dispatch-guard heredoc now
   resolve state via `git rev-parse --git-dir` (made absolute, joined with
   `warrant/`) instead of the worktree toplevel. The state dir is created
   with `os.makedirs(..., exist_ok=True)` before any write; a failure to
   create it declines the dispatch (fail-closed) rather than falling back to
   the worktree.
2. `warrant/hooks/hunt-state.sh` — `release`/`reset` resolve the identical
   `.git/warrant/` path and remove the lock/count there.
3. `warrant/agents/warrant-hunter.md` — the report-path instructions (former
   line 81, and the two terminal-output lines) now state the derivation
   rule: `docs/issue-<n>/proposals/...` → `docs/issue-<n>/reports/hunt-<slug>.md`;
   no issue segment → unchanged `docs/reports/<date>-hunt-<slug>.md`. The
   "never modify outside docs/reports/" bound was generalized to "outside
   the hunt-record path" to match.
4. `warrant/hooks/directive.sh` — the generic proposal-path template (line
   27) now notes the per-issue layout exists alongside the flat one; the
   commit-trailer example (line 53) gets the issue-scoped alternative
   spelled out; the report-path text handed to the dispatched hunter (line
   76) states the same derivation rule as item 3, so dispatcher and agent
   agree.
5. New test `warrant/hooks/tests/run-hunt-guard-tests.sh` (9 cases): a real
   dispatch via `hunt-guard.sh` followed by `hunt-state.sh release` leaves
   no `.warrant-hunt.*` file under the worktree root (only under
   `.git/warrant/`, confirmed via `git status --porcelain` staying silent);
   the derivation rule from item 3/4, reimplemented as a shell function
   matching the documented prose, produces disjoint paths for two different
   issue numbers sharing the same date+slug, and an unchanged path when no
   issue segment is present; an empty-state repo (warrant never run) does
   not crash and holds no lock.
6. Removed the stale tracked `.warrant-hunt.count` at the repo root — the
   exact collision-prone artifact this issue exists to stop generating
   (confirmed via `git log --oneline -- .warrant-hunt.count`: tracked since
   at least commit 5c23402).

## Why

Session state written to the worktree root with one shared key collides
across concurrent branches; `.git/` is never staged, diffed, or committed,
so relocating there removes the collision structurally instead of by
convention. Hunt-report paths keyed by date+slug alone are only
probabilistically unique across concurrent issues; keying by the issue
number the proposal's own path already carries makes two concurrent issues'
write sets disjoint by construction. Full rationale, including the two
rejected alternatives (`~/.tokenmaxxxer/state/<repo>/` for state,
`docs/reports/issue-<n>-hunt-<slug>.md` filename-prefix for reports), is in
the proposal's `## Rationale`.

## Upstream

Basis: `docs/issue-200/proposals/conflict-free-system-writes.md` (approved
via `APPROVE issue-200/implementation`, single-account mode).

## Audit inventory

Restated from `docs/issue-200/reports/implementation/survey.md` (already
committed pre-approval, unchanged by phase 2):

| Site | Target | Classification |
|---|---|---|
| `warrant/hooks/hunt-guard.sh` (pre-fix: `$root/.warrant-hunt.lock`/`.count`) | worktree root | **collision risk — fixed this issue** (item 1) |
| `warrant/hooks/hunt-state.sh` | same two files | tracked the above, fixed by the same relocation |
| `warrant/agents/warrant-hunter.md` / `warrant/hooks/directive.sh` (pre-fix: `docs/reports/<date>-hunt-<slug>.md`) | date+slug key | **collision risk — fixed this issue** (item 2) |
| `freelunch/hooks/observe.sh:114-116` | `$HOME/.claude/...` | out-of-tree, no fix needed |
| `core/hooks/*-gate.sh` | PreToolUse gates, no self-write | not a generator, out of scope |
| `terse/hooks/terse.sh`, `scout/hooks/directive.sh`, `warrant/hooks/state.sh`, `warrant/hooks/scope-gate.sh` | no writes / read-only | no risk |
| warrant plugin's own `docs/proposals/YYYY-MM-DD-<slug>.md` convention | date+slug, human-authored content | noted, out of this issue's item 3 scope (not system-generated; this repo's actual proposals already use `docs/issue-<n>/proposals/`) |

## What did not work

None — no attempted approach was undone or replaced during this build.

## Verification run

`bash warrant/hooks/tests/run-hunt-guard-tests.sh` → `9 passed, 0 failed`
(includes the worktree-clean, disjoint-paths, and empty-state cases the
acceptance criteria names). `bash -n` on all four edited shell/hook files
passed.

## Open findings

None outstanding. Warrant-hunter dispatches: after-proposal hunt (recorded
pre-approval in `docs/issue-200/reports/hunt-conflict-free-system-writes.md`)
found and the gap was closed in a prior commit
(`41c3291 docs(implementation): close hunt gap flagged by warrant hunt (issue-200)`)
before this phase-2 build began; no before-landing dispatch is recorded in
this record because dispatching a background hunter and consuming its result
within the same turn is not reachable in this headless single-shot session
(contract v3 s22 takes priority over the warrant directive's hunter-dispatch
instruction here — see the record's frontmatter `loop_state: landed`, no
delegated work left unconsumed).
