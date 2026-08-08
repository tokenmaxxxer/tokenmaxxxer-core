---
subject: issue-171
role: implementation
loop_state: surveyed
---

# Current-state survey — 43-repo canon rollout execution

## What issue-171 actually asks (phase 1 of this session)

Issue-171 embeds a real `run-fleet-scan.sh` run (2026-08-08): 43/43
rulebooks scanned, 0 `blocked` rows, every repo carries at least one
finding — `canon-duplication` (vendored copy of a core canon file) on
all 43, plus per-repo `mktemp-footgun`/`fail-open-on-internal-error`
signal hits. The issue's own text asks to "execute the canon rollout ...
per the #66 rollout doc with the #168 scan as exit gate." Per the user's
literal instruction for this session, phase 1 is: **plan the rollout
mechanics (per-repo PRs, batching, re-scan cadence) — do not execute.**
This repo has no write access to the 43 sibling repos regardless (every
prior rollout doc in this tree states that constraint explicitly), so
"execute" here means: dispatch the plan, not push commits from this
repo.

## What already exists (the "#66 rollout doc")

There is no single file named a "rollout doc" — the rollout procedure is
distributed across three prior artifacts, all merged to main, all
reusable as-is:

1. `docs/issue-66/reports/implementation.md` ("Transition path (batches
   with #63)") — defines the file-level rollout unit: delete each
   rulebook's vendored `trailer-gate.sh`, `record-fields-gate.sh`,
   `handbook-trigger-gate.sh`, `parse-check.sh`; replace `directive.sh`
   with the `core_role_directive` lib-call stub; add
   `RECORD_FIELDS_TERMINAL_STATES` env override where a rulebook's
   terminal-state set is non-default.
2. `docs/issue-69/reports/implementation/reclaim-21-copies.md` — the
   most concrete rollout runbook on file: **Enumerate → Delete-and-
   reference → Verify per-repo → Batch sequencing**, plus an explicit
   "confirm the resolved path against one pilot rulebook repo before
   applying to all [N]" pilot step. This is the template issue-171's
   plan should extend, not reinvent — it already answers "how does a
   single-file reclaim propagate to 43 repos."
3. `docs/handbooks/canon-scripts.md` — the standing rule ("referenced,
   never copied") every rollout write-up is expected to carry or
   explicitly except from.
4. `docs/issue-63/reports/implementation.md` — the warrant-hunter canon
   promotion, batched with #66 per its own decision record
   (`docs/issue-66/decisions/2026-08-08-role-agnostic-canon-boundary.md`,
   item 4: "the rollout batching ... is shared; that is a scheduling
   note, not a scope merge").

Net: three independent promotions (#63 warrant-hunter, #66 four gates +
directive.sh split, #69 stub-check.sh dedup) all converge on the same 43
repos and are already on record as intended to land in **one coordinated
per-repo change**, not three separate touches. Issue-171's fleet scan
confirms none of the three has actually reached any of the 43 repos yet
— canon-duplication fires on all 43.

## What the #168 scan actually checks, and its shape as an exit gate

`core/hooks/tests/fleet-silent-failure-scan.sh <repo-path>` runs two
passes per repo:

1. `compliance-check.sh --canon-duplication <path>` — reads
   `core/hooks/tests/canon-manifest.txt` and fails if any manifest-listed
   filename is found anywhere under the target repo. This is exactly the
   detector the #63/#66/#69 rollouts need satisfied to be "done" for a
   given repo.
2. A grep-based sweep for six other silent-failure signatures
   (swallowed-errors, fail-open-on-internal-error, absent-input-allow,
   string-judged-command, mktemp-footgun, dead-deny-branch), scoped to
   that repo's own `.sh`/`.py` files. These are **not** canon-copy
   findings — they are genuine per-repo defects a rollout stub-swap does
   not fix by itself (e.g. `mktemp-footgun: ux-wcag-onpair/tests/...` in
   issue-171's embedded table is a bug in that rulebook's own test
   script, unrelated to which gate files it vendors).

`run-fleet-scan.sh` orchestrates: enumerates repos via `gh repo list
tokenmaxxxer --json name -q '.[].name' | grep 'rulebook$'`, shallow-clones
each (`--depth 1`, read-only, plain HTTPS), scans, prints one aggregated
`repo | result` row per repo, cleans up its temp dir on exit. It is
already re-runnable on demand from this repo with no argument beyond
`--org` — this is the exit-gate mechanism issue-171 names; no new
scan-driver code is needed for the re-scan step.

**Consequence for the rollout plan:** canon-duplication rows clear only
via the per-repo stub swap (#63/#66/#69 mechanics). The six-signal rows
are per-repo defect fixes that a fleet-wide file swap cannot silently
close — issue-171's acceptance line ("clean or its residue is justified
in that repo's own record") anticipates this: some rows will stay open
past the stub swap and need either a defect fix commit in that repo or a
written justification.

## Per-repo finding-count profile (from issue-171's embedded table)

43 repos, counts range 1 (e.g. `content-design-rulebook`,
`market-analysis-rulebook`, `architecture-rulebook`) to 15
(`interaction-design-rulebook`). Every repo shows at least one
`canon-duplication` FAIL. Repos with count 1 are canon-duplication only
(directive.sh's boilerplate reference, no additional signal hit) —
mechanically the cheapest rollout unit. The scan's finding-line text is
truncated per-repo in the issue body (embedded table caps line length),
so the exact secondary signals per repo beyond the first are not fully
readable from the issue text alone — the rollout plan cannot assume the
full defect list per repo is known ahead of the per-repo PR; each
repo's own PR diff is where the actual remaining findings surface.

## What this repo can and cannot do

- Cannot push to any of the 43 sibling repos (no write access, stated as
  a constraint in every prior rollout doc in this tree).
- Can re-run `run-fleet-scan.sh` against public clones on demand — this
  is the exit-gate check, callable with zero new code.
- Can produce the rollout plan (mechanics: batching, per-repo PR
  shape, sequencing, re-scan cadence) and the reusable stub-swap
  instructions (extending #69's runbook) as this repo's own record —
  execution against the 43 repos is then an orchestration/dispatch
  concern outside this repo's write set, exactly as #63/#66/#69 already
  state.

## Scout-directive skip record

Scouting (external exemplar research) is skipped. Reason: this is an
internal rollout-mechanics decision (batch size, PR-per-repo vs.
PR-per-wave, re-scan cadence) fully constrained by in-repo precedent
already executed once at smaller scale — issue-63's warrant-hunter stub
rollout and issue-69's reclaim runbook are the direct comparables, not
an external fleet-CI or monorepo-rollout product category. The relevant
"best-in-class" comparison is this repo's own prior rollout write-ups,
already read above, not a web search for generic multi-repo-rollout
tooling.
