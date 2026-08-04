---
kind: proposal
subject: issue-124
produced_by: execution-observation
phase: 1
observed_pr: 126
observed_role: implementation
---

# Proposal — step 2 independent observation of PR #126 (issue-124)

files (this role's own write surface, phase 2):
`docs/issue-124/reports/execution-observation.md` only.

## What this proposal covers

Issue #124's execution plan lists two steps. Step 1 (`implementation`)
landed as PR #126, merged `43bd873`. Step 2 is this role's independent
observation of that execution. This document states, before any judgment
is formed, which verdict levels the phase-2 record will check and what
evidence each will be checked against. It renders no judgment, provisional
or otherwise.

Inputs already read first-hand this session are listed in
`docs/issue-124/reports/execution-observation/survey.md`
(`## What was read this session, first-hand`); the survey's `## Unknowns`
is what the checks below are aimed at. Direction inputs are in
`docs/issue-124/reports/execution-observation/scout-brief.md`.

**Phase state.** Issue #124's only comment is `APPROVE
issue-124/implementation` ([issuecomment-5175349028](https://github.com/tokenmaxxxer/tokenmaxxxer-core/issues/124#issuecomment-5175349028)),
which names a different role's subject-role pair. Per contract §19 this
role's phase 2 is not open; this PR is phase-1 only and stops here.

## Verdict levels to be checked, and against what

All three levels of contract §19/the role's execution-judgment facet will
be addressed; none is skipped, and a level that turns out not to apply
will say so and why.

### 1. Outcome — did PR #126 land what issue #124 asked

Checked against the issue's three numbered requirements and its three
constraints, one at a time, each against a named artifact:

- **Requirement 1** (all three habitats fixed in one delivery, each in the
  minimum form the issue names, deviations reasoned): the source diff of
  `fdb620d` (`git show fdb620d -- core/hooks/…`), hunk by hunk, against
  issue #124's own R1/R2/R3 prescriptions and against the approved
  proposal's `## What will be done`
  (`…-close-remaining-wrapper-parser-differential-habitats-r1-r2-r3.md:119-189`).
- **Requirement 2** (per-habitat red→green plus a write-direction case):
  the test diff of `fdb620d` (`git show fdb620d -- core/hooks/tests/`)
  read as code — which case asserts what, and whether the write-direction
  sibling actually exercises the same parse path as its read twin — plus
  the record's captured RED/GREEN output blocks
  (`docs/issue-124/reports/implementation.md:54-162`) checked for internal
  consistency against the added-case count. Explicitly **not** by running
  any suite.
- **Requirement 3** (post-fix re-enumeration proving zero remaining
  habitats): the record's `## Verify` re-enumeration block
  (`docs/issue-124/reports/implementation.md:346-408`) versus this role's
  own independent enumeration, per `## Independent re-enumeration plan`
  below.
- **The three `## 제약` constraints** (`gh-guard.sh` unchanged; #107/#114
  skeletons respected; no regression in landed negative space): the file
  list and hunk set of `fdb620d`, and the record's own `## Hunt`
  before-landing stance which claims the same boundary
  (`docs/issue-124/reports/implementation.md:243-266`).

### 2. Trajectory — was the phase-1 → phase-2 path sound

Checked against process artifacts, not code:

- Whether survey and proposal preceded execution — `git show --stat
  7fcd4cd` (2 files, survey + proposal, +490, authored 06:10:30Z) versus
  `fdb620d` (authored 06:45:04Z), and PR #126's `createdAt` 06:11:15Z.
- Whether the approval was real and correctly typed — issue #124's single
  comment (exact body, author, timestamp 06:20:10Z),
  `docs/specs/approvers.md`, and PR #126's `reviews: []`; including
  whether single-account mode was correctly identified and whether the
  approval preceded the phase-2 commit.
- Whether the observed proposal met §19's own floor for a proposal —
  enumerable clause checklist, 1-2 alternatives with reasons, and a stated
  failure signal — read directly off the proposal file, and whether phase 2
  marked fulfilment per clause.
- Whether phase-2 output stayed inside the approved scope — the proposal's
  `## What will be done` / `## Out of scope` versus what `fdb620d`
  actually changed, and whether anything declined was disclosed rather
  than silently dropped.
- Whether scouting ran or was recorded as skipped for the observed role —
  `git ls-tree -r origin/main -- docs/issue-124` shows no
  `reports/implementation/scout-brief.md`; the observed survey is checked
  for a skip record.

### 3. Step — which specific artifact, if any, is deficient

Checked per artifact, named individually: the three source hunks of
`fdb620d`; the six-or-eight added test cases in the same commit; the two
handbook edits including the stale-sentence correction the record claims
(`docs/issue-124/reports/implementation.md:180-188`); the record file
itself against contract §20's items 1-6; and the record's `## Hunt`
stances. Where the record asserts a check, the assertion is compared
against the diff and against primary specs — never by re-running the
observed role's task.

## Independent re-enumeration plan (issue #124 requirement 3, contract §20 item 6)

The scout brief's must-be is that a textual sweep is not itself closure
evidence and that what the sweep cannot see must be stated. The
enumeration will therefore run on **two axes**, and its method is fixed
here, before any result is seen:

- **Axis A — site enumeration.** Re-run issue-114's own two greps, but at
  the pinned merge SHA rather than the working tree
  (`git grep -n "gate_head_of\|gate_trailing_words\|gate_wrapper_head_before" 43bd873 -- core warrant`
  and `git grep -n "split()" 43bd873 -- core/hooks warrant/hooks`), then
  widen past what those two patterns can match, since issue-114's own
  record states that residue outright: additionally enumerate `\[0\]`
  indexing, `shlex`, `re.match`/`re.search` over a whole command line,
  `partition`, `startswith(` head tests, and `argv`-style word indexing
  across both hook trees. Every production hit is read at `43bd873` before
  being cited. This is enumeration of the tree's present state as the
  class question requires — not a re-execution of the observed role's
  task, and not a substitute for the diff as evidence of what that role
  did.
- **Axis B — grammar completeness.** Diff each landed table against the
  spec it claims to mirror: `TRANSPARENT_FLAG_TAKES_ARG`'s four wrappers
  against the GNU man pages for `nice`, `env`, `timeout`, `xargs`; and
  `GIT_GLOBAL_VALUE_FLAGS` against git's own documented global options.
  The scout brief already records the sourced spec facts this axis reads
  against ([7]-[11] there). No grep can surface a missing table row, so
  this axis exists precisely because axis A structurally cannot see it.
- **Decision rule, fixed now, before any result is taken:** the class is
  reported exhausted only if both axes come back empty. If axis B returns
  a shape the landed tables do not cover, the record states it as a
  finding with its source and its misread direction (fail-closed or
  fail-open), and states plainly whether it falls inside the observed
  proposal's declared `## Out of scope` — an out-of-scope residue named in
  advance by the proposal is reported as a class-status fact about the
  codebase, not charged against PR #126 as a scope violation. Either way
  the record states what the enumeration could not see.

## Commitments — clause checklist (§19)

Phase 2 marks each clause with the commit or hunk that fulfilled it, or
states it was dropped and re-approval is required.

1. Write `docs/issue-124/reports/execution-observation.md` as the first
   act of phase 2, with `loop_state` updated at every transition.
2. Place the independence statement (this role did not author or edit the
   observed artifact) **before** any verdict language in that file.
3. Render all three verdict levels — outcome, trajectory, step — with a
   level that does not apply written as "not applicable, because X".
4. Carry a citation (commit SHA, `file:line`, or comment URL) adjacent to
   every verdict-bearing sentence.
5. Check requirement 1 hunk-by-hunk against the issue's R1/R2/R3 minimum
   forms and the approved proposal's frozen text.
6. Check requirement 2 by reading the added test cases as code plus the
   record's RED/GREEN blocks for internal consistency, without running any
   suite.
7. Run axis A of the re-enumeration at `43bd873`, widened beyond
   issue-114's two grep patterns, and publish the full hit list.
8. Run axis B of the re-enumeration against primary specs and publish the
   table-vs-spec diff.
9. Reconcile the 8 added test cases visible in `fdb620d` against the
   record's "six new cases (2 per habitat)" wording
   (`docs/issue-124/reports/implementation.md:321`).
10. Check the record against contract §20 items 1-6, including item 6 for
    any confirmed finding this record itself states.
11. Give every deficiency finding the four-part blameless shape — impact,
    timeline, root cause, action item.
12. State the coverage limit of this observation explicitly, including
    what was not verifiable without re-execution.
13. File no issue and edit nothing under `core/`, `warrant/`,
    `core/hooks/tests/`, `docs/handbooks/`, or the observed role's
    `docs/issue-124/` paths.

## Alternatives considered

- **Accept the record's own re-enumeration as the answer to requirement 3
  and check only that it was run.** Not chosen: the field's must-be is
  that a textual sweep does not itself close a class [scout-brief 1] and
  that self-reported verification is the weakest evidence tier
  [scout-brief 4], so the observation would be relaying the doer's claim
  rather than corroborating it.
- **Re-run the three test harnesses to settle the RED/GREEN numbers
  directly.** Not chosen: this role's independence rule bars re-executing
  the observed role's task, and the audit answer to "cannot re-perform" is
  corroboration plus disclosed limits [scout-brief 5][6], which clauses 6
  and 12 provide.

## Failure signal

If this proposal is wrong, the phase-2 record will read as a re-derivation
of the observed record's own conclusions — every verdict resting on a
sentence quoted from `docs/issue-124/reports/implementation.md` with no
independently obtained artifact behind it — and the class-exhaustion
verdict will be exactly the observed record's own, reached by the observed
record's own two greps.

## Out of scope

- Any edit to `core/`, `warrant/`, `core/hooks/tests/`, `docs/handbooks/`,
  or to the observed role's `docs/issue-124/proposals/…-r1-r2-r3.md` and
  `docs/issue-124/reports/implementation*` paths.
- Filing an issue for anything found. Under contract v3 issues are
  user-authored only; a confirmed deficiency returns as a finding in this
  role's record on this PR, for the human to judge.
- Re-running any test suite, hook, or gate belonging to the observed role.
- Re-opening `gh-guard.sh`'s fail-open design, which both issue #124 and
  the observed proposal fix as unchanged — its status is reported only as
  a boundary the enumeration reaches, never as a defect charged here.
- Judging any subject other than issue #124 / PR #126. Where a lineage
  artifact (#99, #107, #114, #118) is read, it is read as context for the
  class question, not re-observed.

## How you'll know it worked

- `docs/issue-124/reports/execution-observation.md` exists on this branch,
  committed, with the independence statement preceding every verdict.
- All three verdict levels appear, each verdict-bearing sentence carrying
  an adjacent citation.
- Both enumeration axes are published with their raw output, and the
  class-status conclusion follows the decision rule fixed above rather
  than a rule chosen after seeing the result.
- Every clause in `## Commitments` is marked fulfilled or explicitly
  dropped.
- Nothing outside this role's own record path is modified — checkable by
  the file list of this PR.
