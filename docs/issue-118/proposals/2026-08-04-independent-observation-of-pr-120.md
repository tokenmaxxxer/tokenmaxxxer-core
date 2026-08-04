---
kind: proposal
subject: issue-118
produced_by: execution-observation
loop_state: phase-1
upstream:
  - path: docs/issue-118/reports/execution-observation/survey.md
  - path: docs/issue-118/reports/execution-observation/scout-brief.md
---

# Proposal — independent observation of PR #120 (issue-118 step 2)

## Subject

Issue #118's execution plan step 2. The observation target is the
`implementation` role's session on branch `issue-118/implementation`,
delivered as **PR #120** (merged `a167f11`), commits `caed0b1` (phase 1)
and `1b10565` (phase 2), together with that role's own record
`docs/issue-118/reports/implementation.md` and its phase-1 artifacts
(`docs/issue-118/proposals/2026-08-04-add-defect-class-and-other-habitats-question-to-record-norm.md`,
`docs/issue-118/reports/implementation/survey.md`).

This proposal names what will be checked and against what. It renders
nothing about the target. No judgment of PR #120 — provisional, partial, or
otherwise — appears in this document.

## Which verdict levels will be checked, and against what

All three contract levels will be addressed; a level that turns out not to
apply will be written as "not applicable, because X" rather than dropped.

1. **Outcome** — did PR #120 land what issue #118 asked. Evidence: the
   issue body's three numbered `## 요구사항` items and two `## 제약` items,
   each adjudicated against (a) the `gh pr diff 120` hunk on
   `core/contract/role-handoff-contract.md` (`@@ -836,6 +836,15 @@`, 9
   insertions / 0 deletions), (b) the `git show --stat` of both commits for
   the untouched-file constraints (`record-fields-gate.sh`, any test file,
   any existing `docs/issue-<n>/reports/execution-observation.md`), and
   (c) the record's `## Next steps` (`docs/issue-118/reports/implementation.md:128-144`)
   for requirement 3. Survey unknowns U4 and U6 enter here.

2. **Trajectory** — was the phase-1 → approval → phase-2 path the one
   contract v3 §19 prescribes. Evidence: the six timestamps tabulated in
   the survey (`caed0b1` `authoredDate` and its docs-only `--stat` proving
   the phase-1 commit carried no `core/` file; PR #120 `createdAt`; the
   issue-#118 comment's byte-exact body, author, and `created_at` from the
   GitHub API; `caed0b1`'s post-rebase `committedDate`; `1b10565`'s commit
   date; `mergedAt`), plus `gh pr view 120 --json reviews` → `[]`, plus
   `docs/specs/approvers.md`, read against §19's two approval paths.
   Ordering is established from timestamps, never inferred from document
   order. Also at this level: whether a survey preceded the proposal (both
   are in `caed0b1`), whether a scout pass or a scout skip record exists at
   all (U1), and whether the post-approval rebase of the phase-1 commit
   disturbs the ordering the approval path depends on.

3. **Step** — which specific artifact, if any, is deficient. Candidate
   artifacts, each read at a pinned SHA: the record
   (`docs/issue-118/reports/implementation.md`), the proposal
   (`caed0b1:docs/issue-118/proposals/2026-08-04-add-defect-class-and-other-habitats-question-to-record-norm.md`),
   the survey (`caed0b1:docs/issue-118/reports/implementation/survey.md`),
   and the landed contract text itself (`a167f11:core/contract/role-handoff-contract.md`
   §20). Survey unknowns U2, U3, U5, U7, U8 enter here. Any confirmed
   deficiency is written in the four-part blameless shape (impact /
   timeline / root cause / action item), one charge per artifact defect,
   with the action item left to the human — this role files no issues.

## The five check points, and the evidence each rests on

**Check point 1 — requirement and constraint coverage.** Each of issue
#118's three requirements and two constraints, one at a time, against the
diff and the two `--stat`s. Requirement 1 splits into *location* (is §20 the
document the issue's "계약 §20 계열의 기록 요건을 정의하는 이 레포 문서"
names) and *content* (does the landed sentence require both (a) the defect
class and (b) the other-habitats sweep result or its impossibility reason).
Constraint 2 (no retroactive edits to existing records) is checked from the
`--stat` of both commits: no `docs/issue-<n>/reports/execution-observation.md`
may appear in either.

**Check point 2 — approval typing and ordering.** Whether the approval that
opened phase 2 is the kind §19 admits given `reviews: []`, a PR author of
`jjongkwann`, and an `approvers.md` containing both `jjongkwann` and
`JiwonJung94`; and whether the phase-2 commit followed it. Evidence: the
byte-exact comment body from the API (compared for string equality, never
read for intent), `docs/specs/approvers.md`, and the survey's timestamp
table. The post-approval `committedDate` on `caed0b1` is examined here for
whether it changes what the approval was given against.

**Check point 3 — proposal-to-delivery fidelity (U3).** Whether the landed
placement matches what the approved proposal said would be done: the
proposal's `## What will be done` item 1 (`:116-124`) and `## How you'll
know it worked` (`:157-160`) against the diff's actual structure (item 6
under its own new conditional lead-in, a third tier beside items 1–3 and
4–5). Both readings will be shown if they cannot be reconciled from the
committed text alone.

**Check point 4 — the non-mechanization claim (U5), checked statically.**
Whether `record-fields-gate.sh` in fact cannot pick up the new item.
Evidence: `a167f11:core/hooks/record-fields-gate.sh` read directly at the
pinned SHA — specifically whether its required-field set is a literal list
or is derived from §20's numbering — plus the `--stat`s showing the script
unchanged. The gate is **not executed**; this is a read of committed text
against a claim the observed record itself makes, which is the only purpose
for which this observation opens a `core/` file.

**Check point 5 — the population question (U7), i.e. the issue's own
question turned on the delivery.** Which other in-repo homes state
record-content requirements, and would therefore now trail §20 by one
question. Method: enumerate at pinned SHA every file that states what a
record must contain — the contract's other sections, `core/hooks/record-fields-gate.sh`'s
own header comments, `docs/handbooks/*`, the three `directive.sh` files the
record already grepped — read each before citing it, and state plainly
whether the enumeration is exhaustive or partial, naming the uncovered
remainder if partial. Scoped deliberately: a home outside PR #120's write
set is reported for the human to judge, never charged against this delivery
unless issue #118's own text placed it in scope. `tokenmaxxxer/execution-observation-rulebook`
is unreachable from this checkout and will be stated as out of reach, not
guessed at.

## Method and its limits

- **No re-execution.** `run-role-gates-tests.sh`, `run-gate-lib-tests.sh`,
  and every hook and gate are not invoked. The record's counts (19/0
  role-gates; 53/1 gate-lib, with its pre-existing-sandbox-artifact
  explanation at `docs/issue-118/reports/implementation.md:167-179`) are
  treated as record claims and labelled as such wherever they are used.
- **Pinned reads only.** Every citation is `<sha>:<path>:<line>` at
  `a167f11` or at the commit that introduced the line, never a floating
  `origin/main` read.
- **Source code is not evidence of conduct.** `core/` files are opened for
  exactly two purposes: checking the internal consistency of a claim the
  observed record itself makes (check point 4), and the population question
  (check point 5). What the observed role did and decided is established
  from the diff, the commit messages, the PR metadata, and that role's own
  record.
- **Evidence tiers.** Each claim is marked *artifact* (direct read of a
  blob, diff, or GitHub API record), *analytic* (derived by reasoning over
  committed text), or *out of reach* (stated as unjudged).
- **No delegated reading.** Every artifact cited is read by this session
  directly; no subagent read stands in for a citation.
- **Independence.** This role did not author, edit, or contribute to PR
  #120, its commits, or the `implementation` record, survey, or proposal.
  The phase-2 record carries that statement before any verdict language,
  and this session's write surface stays inside the three phase-1 paths
  named in the survey plus `docs/issue-118/reports/execution-observation.md`.
- **Self-application.** The norm this delivery landed binds this role's own
  phase-2 record: every confirmed finding it states will itself carry (a)
  the defect class and (b) the other-habitats sweep result or the reason a
  sweep was not possible, per the landed §20 item 6. This is a commitment
  about this record's shape, not an assessment of the delivery.

## Alternatives considered and rejected

1. **Judge the norm's wording on its merits — propose better phrasing.**
   Rejected: this role never edits the observed artifact, and a wording
   preference is not a deficiency. Where the landed wording and the issue's
   ask diverge (U4), the divergence is reported as evidence for the human,
   not as a rewrite.
2. **Treat "documented norm only, no gate" as unverifiable because the gate
   was not run.** Rejected: the claim is about what a committed script can
   do, which a static read at a pinned SHA settles without re-execution;
   check point 4 does exactly that and states the residual limit.
3. **Scope the observation to the contract diff alone.** Rejected: the
   three-level verdict is mandatory, and the trajectory level (U1's scout
   question, the post-approval rebase) lives entirely outside that diff.

## Failure signal

If a claim cannot be pinned to a named-SHA blob, a diff, or a GitHub API
artifact read in this session, it is recorded as out of reach and left
unjudged — never asserted at a lower confidence. Specifically: if check
point 5's enumeration cannot be shown to be exhaustive, the record states
"the population could not be closed, because X" and lists what was covered.
If check point 3's two readings cannot be reconciled from committed text
alone, that is written as an unreconciled discrepancy with both readings
shown, not as a charge.

## Phase-2 deliverable

One file: `docs/issue-118/reports/execution-observation.md`, written as the
first act of phase 2, with `loop_state` updated at each transition, the
independence statement ahead of all verdict language, the three verdict
levels each with adjacent citations, the five check points above, any
findings in the four-part blameless shape plus the landed §20 item 6 fields,
an explicit "what is not deficient" section, and the method-limits section.
Committed on this branch and delivered through this PR. No other path is
written.

## Out of scope

- Any edit to `core/`, to `docs/issue-118/reports/implementation*`, to the
  observed proposal, or to any other artifact of the observed role.
  Findings return only in this role's own record.
- Filing any GitHub issue. Under contract v3 issues are user-authored; a
  confirmed deficiency is recorded here for the human to judge and file.
- Editing or filing against `tokenmaxxxer/execution-observation-rulebook` —
  unreachable from this checkout; its state is reported as out of reach.
- Judging issue #116/PR #117, PR #121, or issue #122/PR #123 — all outside
  PR #120.
- Re-observing PR #115 (issue-114) or PR #108 (issue-107). Their records are
  read as format precedent and as ledger input, not as observation targets.
- The merge decision itself. PR merge is the human's act of acceptance;
  this role reports, it does not ratify.
