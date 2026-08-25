---
status: proposed
files:
  - docs/issue-305/reports/conformance-review/survey.md
  - docs/issue-305/proposals/review-python3-consistency-silent-failure-sweep.md
  - docs/issue-305/reports/conformance-review.md
  - docs/issue-305/reports/conformance-review/hunt-review-python3-consistency-silent-failure-sweep.md
---

## Request

Conformance-review issue #305 (python3-missing fail-closed consistency
across 4 core gates + the remaining 15 per-file silent-failure findings
from #301's sweep) against the work already landed as open PR #313 on
branch `issue-305/implementation` — confirm the 5 python3-missing sites
now name the problem while keeping fail-closed semantics unchanged, that
each of the 19 findings is fixed as its commit message claims with real
independently re-executed evidence, and that the fix stays confined to
this issue's scope without re-touching sibling issues #303/#304's
mechanisms.

## Constraints

- Operator-frozen (2026-08-25), carried from the issue verbatim: systemic
  for every consumer session against any target repo; no added per-spawn
  overhead/steady-state load; no new conflict surfaces; no stall/deadlock
  modes; no consumer-tree pollution; unavoidable trade-offs measured and
  stated in the record. Two of these (overhead/load, conflict/stall
  surfaces) have no stated observable threshold and will be recorded as
  Unverifiable rather than scored against an invented bar — same
  conclusion issue-304's review reached for the identical boilerplate.
- This role writes only its own record area
  (`docs/issue-305/reports/conformance-review*`); it does not touch the
  implementation role's files or `docs/issue-305/reports/implementation.md`.
- Two-phase contract applies: `CORE_BUILD_NOW` is unset in this session's
  environment, so this PR is phase-1 only (survey + this proposal); the
  actual review and the filled `conformance-review.md` record are
  phase-2, gated on an Approve.
- Full enumeration, not sampling: the survey's sampling-derivation pass
  concluded the 19-item population is small, individually named, and
  falls entirely inside this repo's own highest-scrutiny class
  (hooks/gates scripts) — every finding gets inspected, none sampled.

## Rationale

Considered relying on the implementation record's own pasted live-fire
repro output and test-suite pass counts as sufficient evidence, skipping
independent re-execution in phase 2. Rejected: this repo's
verify-at-landing convention treats a deliverable as code plus evidence
produced by the role that stands behind it — an implementer's
self-reported pass count and repro transcript are exactly the class of
claim a conformance review exists to independently confirm, not relay.
Re-running `run-gate-shape-tests.sh`, `run-all.sh`, and each finding's own
stated repro command against this role's own checkout of the
implementation branch is what makes the verdict traceable to this review
rather than borrowed from the build.

Also considered sampling a subset of the 19 findings (e.g. spot-checking
5-6 representative ones) instead of full enumeration, given the
population is over 4x issue-304's. Rejected: unlike a review whose
population is files or endpoints (interchangeable, risk-differentiable),
this population is a fixed list of 19 individually-diagnosed defects the
issue itself names by ID — a missed sample item isn't "one file among
many," it's "one specific silent-failure bug this review was asked to
confirm got fixed or not." The issue's own acceptance section instructs
top-down traversal of the findings table, not a spot-check, and every
finding lives in the exact `hooks/`/`gates/` file class this repo's own
warrant-protocol already exempts from size-based downgrading. Sampling
here would repeat the failure mode issue-305 itself exists to close (a
prior fix, issue-72/issue-282, reached some sites and silently missed
others — see F19/F20's parallel history in #304).

## What will be done

Phase 1 (this PR): current-state survey
(`docs/issue-305/reports/conformance-review/survey.md`, already
committed) extracting 31 dimension-tagged requirement lines (28 checkable
+ 2 flagged unverifiable-as-written + 1 classification label excluded)
from issue #305 and its linked observability.md findings, folding
duplicate/subsumed line items down to 24 independently checkable
Demonstration/Test/Inspection/Analysis items, and selecting a
verification method per item; this proposal.

Phase 2 (on Approve): independently re-execute
`core/hooks/tests/run-gate-shape-tests.sh` and
`core/hooks/tests/run-all.sh` against the `issue-305/implementation`
branch tree; re-run the PATH-without-python3 live-fire repro for each of
the 5 python3-missing sites and each of the 19 findings' own stated
repro command; inspect each fix's diff against a `git show` of the
pre-fix version to confirm the fail-open/fail-closed decision itself is
unchanged; inspect PR #313's diff against PR #306 (#303) and PR #307
(#304)'s diffs for non-overlap; trace diff file-scope for the
consumer-tree-residue proxy check; record one verdict per requirement
(Present / Surface / Absent / Incorrect / Unverifiable) with file/line/sha
citations in `docs/issue-305/reports/conformance-review.md`, filling the
existing skeleton's frontmatter and headings without changing its
structure.

## Out of scope

Reviewing or modifying `docs/issue-305/reports/implementation.md` or any
`core/hooks/*`, `warrant/hooks/*`, `freelunch/hooks/*`, `terse/hooks/*`
file directly — this role verifies, it does not fix. Scoring the two
unverifiable operator-frozen constraints against an invented threshold.
Re-reviewing sibling issues #303 or #304's own mechanisms beyond
confirming PR #313 doesn't re-touch them. Any work on issues other than
#305.

## How you'll know it worked

`docs/issue-305/reports/conformance-review.md` is filled in with a
verdict for each of the 24 independently checkable requirements (plus the
2 explicitly Unverifiable ones) extracted in the survey, each citing
concrete evidence (file/line, or independently re-executed command output
pasted verbatim); `loop_state` is set to this record kind's terminal
value; the PR carries `Closes #305` only once this record lands (not on
this phase-1 PR).
