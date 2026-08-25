---
status: proposed
files:
  - docs/issue-304/reports/conformance-review/survey.md
  - docs/issue-304/proposals/review-kill-switch-drift-propagation.md
  - docs/issue-304/reports/conformance-review.md
  - docs/issue-304/reports/conformance-review/hunt-review-kill-switch-drift-propagation.md
---

## Request

Conformance-review issue #304 (F19/F20 kill-switch propagation) against
the work already landed as open PR #307 on branch
`issue-304/implementation` — confirm the 4 directive hooks now call the
shared `gate_kill_switch_active` helper instead of their pre-fix inline
case statement, and that the required drift test exists and passes with
real, independently re-executed evidence.

## Constraints

- Operator-frozen (2026-08-25), carried from the issue verbatim: systemic
  for every consumer session against any target repo; no added
  overhead/load; no new conflict/stall surfaces; no consumer-tree
  residue; unavoidable trade-offs measured and stated in the record. Two
  of these (overhead/load, conflict/stall surfaces) have no stated
  observable threshold and will be recorded as Unverifiable rather than
  scored against an invented bar.
- This role writes only its own record area
  (`docs/issue-304/reports/conformance-review*`); it does not touch the
  implementation role's files or `docs/issue-304/reports/implementation.md`.
- Two-phase contract applies: `CORE_BUILD_NOW` is unset in this session's
  environment, so this PR is phase-1 only (survey + this proposal); the
  actual review and the filled `conformance-review.md` record are phase-2,
  gated on an Approve.

## Rationale

Considered relying on the implementation record's own pasted
`run-directive-shape-tests.sh` output as sufficient evidence and skipping
independent re-execution in phase 2. Rejected: this repo's verify-at-landing
convention treats a deliverable as code plus evidence produced by the
role that stands behind it — an implementer's self-reported pass count is
exactly the class of claim a conformance review exists to independently
confirm, not relay. Re-running the same gate from this role's own
checkout is cheap (one shell command, 4 files) and is what makes the
verdict traceable to this review rather than borrowed from the build.

Also considered sampling a subset of the 4 hook files instead of full
inspection. Rejected: the issue's own Acceptance section already states
full enumeration ("for each of the 4 files"), the population is only 4
files, and this exact issue exists *because* a prior propagation of the
same fix (issue-72) reached 3 of 7 directive-hook-shaped files and missed
the rest — sampling here would repeat the failure mode under review.

## What will be done

Phase 1 (this PR): current-state survey
(`docs/issue-304/reports/conformance-review/survey.md`, already
committed) extracting 14 dimension-tagged requirements from issue #304
and selecting a verification method per requirement; this proposal.

Phase 2 (on Approve): independently re-execute
`core/hooks/tests/run-directive-shape-tests.sh` against the
`issue-304/implementation` branch tree; inspect the 4 changed hook files
for the `gate_kill_switch_active` call and the joined-line drift-guard
regex; trace the diff's file scope for the consumer-tree-residue proxy
check; inspect `implementation.md` for the trade-offs-stated requirement;
record one verdict per requirement (Present / Surface / Absent /
Incorrect / Unverifiable) with file/line/sha citations in
`docs/issue-304/reports/conformance-review.md`, filling the existing
skeleton's frontmatter and headings without changing its structure.

## Out of scope

Reviewing or modifying `docs/issue-304/reports/implementation.md` or any
`core/hooks/*` file directly — this role verifies, it does not fix.
Scoring the two unverifiable operator-frozen constraints against an
invented threshold. Any work on issues other than #304.

## How you'll know it worked

`docs/issue-304/reports/conformance-review.md` is filled in with a
verdict for each of the 14 extracted requirements, each citing concrete
evidence (file/line, or the independently re-executed
`run-directive-shape-tests.sh` output pasted verbatim); `loop_state` is
set to this record kind's terminal value (`reported`); the PR carries
`Closes #304` only once this record lands (not on this phase-1 PR).
