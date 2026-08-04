---
kind: proposal
subject: issue-128
produced_by: execution-observation
phase: 1
loop_state: proposed
observed_pr: 129
observed_role: implementation
upstream:
  - path: docs/issue-128/reports/execution-observation/survey.md
    sha: same-commit
  - path: docs/issue-128/reports/execution-observation/scout-brief.md
    sha: same-commit
---

files: `docs/issue-128/reports/execution-observation.md` (phase-2 record only)

# Proposal — step 2 independent observation of PR #129 (issue-128)

## What this proposal covers

Issue #128's `## 실행 계획` lists two steps. Step 1 (`implementation`) landed
as PR #129, merged `d588e95`. Step 2 is this role's independent observation
of that execution. This document states, before any judgment is formed,
which verdict levels the phase-2 record will address and what evidence each
will be checked against. It renders no judgment of its own, not even
provisionally.

The inputs already read first-hand this session are enumerated in
`docs/issue-128/reports/execution-observation/survey.md`
(`## What was read this session, first-hand`), together with the six
unknowns that survey leaves open. Direction inputs — the category must-bes
this observation is built to meet — are in
`docs/issue-128/reports/execution-observation/scout-brief.md`.

Two facts about this role's position, stated here so the human need not
infer them: this role did not author and will not edit any artifact under
observation, and this role will not re-run the delivered test suite. The
delivered diff, the commit messages, the observed role's own record, and
the PR/issue metadata are the whole admissible evidence set. The frontmatter
above also exercises, live, the very convention under observation: both
upstream entries land in this same commit and are cited as `same-commit`.

## Verdict levels to be checked, and against what

All three levels of the contract's execution judgment will be addressed in
the phase-2 record; none will be omitted, and a level that turns out not to
apply will say so and why rather than being dropped silently.

### 1. Outcome — did PR #129 land what issue #128 asked

Checked forward (each requirement to an artifact) and backward (each
delivered change to a requirement that asked for it), per the scout brief's
first must-be:

- **Requirement 1** (decide the canonical same-commit citation, comparing
  candidates a/b/c): against `## Rationale` of
  `docs/issue-128/proposals/2026-08-04-build-same-commit-upstream-sha-convention.md`,
  checking that all three candidates are addressed and one is selected.
- **Requirement 2** (codify the decision in the record-norm text the issue
  names as "계약 §20 계열"): against the `6486c4b` diff hunks for
  `core/contract/role-handoff-contract.md`, and against §20's own text as
  read from the contract. Survey unknown 1 — the delivered edits are in §1
  and §12, and the diff touches no §20 line — is resolved at this level,
  including whether the proposal's restatement of the target as "§1/§12
  family" was a reading of the requirement or a change to it, and whether
  such a change needed to be flagged for approval.
- **Requirement 3** (judge whether to mechanically reject a leftover
  placeholder, and design the check): against the `6486c4b` diff of
  `core/hooks/record-fields-gate.sh` and `run-role-gates-tests.sh`, read as
  a diff, never as working-tree source.
- **Constraints** (no retroactive fix; no change to the existing
  `record-fields-gate.sh` checks): against the same diff, by inspecting
  which existing lines the hunks touch — and against `git show 6486c4b^:` of
  the gate file where the pre-change baseline is needed, since that baseline
  is history, not the working tree.

### 2. Trajectory — was the phase-1 → phase-2 path sound

- **Phase-1 completeness** against `git show --stat 6963e3b` (survey +
  scout brief + proposal, no execution work in that commit) and against
  §19's three phase-1 requirements: an enumerable clause checklist, 1-2
  named alternatives with a reason each, and a stated failure signal —
  checked against the proposal's `## What will be done`, `## Rationale`, and
  `**Failure signal.**` text.
- **Approval validity** against the artifacts already recorded in the
  survey's `## Approval state`: the comment body, its author's presence in
  `docs/specs/approvers.md`, PR #129's author, and the single-account
  condition of §19 — plus the timestamp ordering `6963e3b` (06:47:26Z) → PR
  created (06:47:51Z) → APPROVE comment (06:48:33Z) → `6486c4b` (06:58:26Z).
- **Scout-before-build and survey-before-scout ordering**, which survey
  unknown 5 records as unsettled from the squashed phase-1 commit alone:
  checked against the observed role's own `survey.md` and `scout-brief.md`
  as committed in `6963e3b` (the brief's own stated mode/stage count and any
  ordering it states), and, only if those are silent, against the observed
  session's transcript files named in the survey's `## Scope`. Reading a
  transcript is reading the observed session's own record, not a
  re-execution; if the transcripts prove unreadable this level will say the
  ordering is unverifiable rather than assume it.
- **Delivery-to-proposal conformance**: each of the proposal's five
  `## What will be done` clauses mapped to the hunk in `6486c4b` that
  fulfils it, or recorded as unfulfilled.

### 3. Step — which specific artifact, if any, is deficient

Three named probes, each producing either a finding or an explicit
no-finding:

- **False-negative probe of the new regex** (scout brief's third must-be):
  the delivered pattern is `^\s*sha:\s*(<[^\n]*>)\s*$`. Candidate inputs
  will be traced by hand against it — a non-bracket unresolved value, a
  value with trailing prose after the closing bracket, a placeholder on a
  continuation line, an already-committed file whose placeholder is never
  re-written by an `Edit`. This is inspection-tier reasoning over the diff,
  stated as such; no execution.
- **Path-scope probe**: `PROPOSALS_RE` matches only
  `docs/issue-[0-9]+/proposals/.*\.md`, and `RECORDS_RE` only a role's own
  `reports/<role>.md`. Whether the same field appears in document homes
  neither pattern matches — the standing `docs/proposals/`,
  `docs/decisions/`, `docs/reports/` buckets, and per-issue
  `reports/<role>/` subtrees such as a survey or scout brief — will be
  established by a read-only repo sweep.
- **Record-content probe** against contract §20's list, applied to
  `docs/issue-128/reports/implementation.md` as committed.

Each verdict-bearing sentence in the phase-2 record will carry its source —
commit sha, `file:line`, or comment URL — immediately adjacent to it, and
will name the evidence tier it rests on (inspection of the diff, inspection
of the record's own claim, or metadata), per the scout brief's second
must-be. Any deficiency finding will carry the four-part blameless shape:
impact, timeline, root cause, action item.

## Clause checklist (what phase 2 commits to producing)

- C1. `docs/issue-128/reports/execution-observation.md` written as the first
  act of phase 2, with `loop_state` updated at each transition.
- C2. The independence statement placed before any verdict language in that
  record.
- C3. Outcome verdict covering issue requirements 1, 2, 3 and both
  constraints, each with an adjacent citation.
- C4. Trajectory verdict covering phase-1 completeness, approval validity,
  phase ordering, and delivery-to-proposal clause conformance.
- C5. Step verdict covering the three probes above, each closing as a
  finding or an explicit no-finding.
- C6. Every verdict-bearing sentence carries an adjacent source citation and
  its evidence tier.
- C7. Any confirmed finding carries impact / timeline / root cause / action
  item.
- C8. Any confirmed finding carries contract §20 item 6: its defect class,
  and the result of the other-habitats sweep for that class (or the reason a
  sweep was not possible).
- C9. No file outside `docs/issue-128/reports/execution-observation.md` is
  written in phase 2; no issue is filed; nothing under the observed role's
  paths is edited.
- C10. The record states plainly which claims rest on the observed role's
  own assertion (e.g. the quoted `24 passed, 0 failed`) rather than on
  evidence this role could inspect independently.

## §20 class question, applied

Contract §20 item 6 (`core/contract/role-handoff-contract.md:855-862`)
requires, for any confirmed finding, both the defect class and whether that
class was checked for elsewhere outside the observed scope. The class in
play here is named up front so the sweep is designed rather than improvised:
*a convention that requires a value to be resolved after the write, with no
mechanism forcing the resolution* — the class issue #128 itself was opened
about, recorded as having recurred three times. The sweep will therefore
look, read-only and repo-wide, for (i) other unresolved-value shapes in
record and proposal frontmatter, and (ii) other document homes carrying the
same fields outside the two path patterns the new check matches. The sweep
result will be recorded whether or not it produces a finding.

## Alternatives considered

- **Outcome-only verdict read from the observed role's record.** Not
  chosen: the record is the observed role's own account, so an outcome read
  solely from it would rest entirely on inquiry-tier evidence, and it cannot
  answer the backward-traceability question (what landed that no
  requirement asked for) at all — the scout brief's gap line names that as
  the primary missing direction.
- **Re-running `run-role-gates-tests.sh` to confirm the `24 passed`
  claim.** Not chosen: re-executing the observed role's task is prohibited
  for this role, and the inspection-tier substitute — reading the five added
  cases in the `6486c4b` diff against the regex they exercise — is available
  and is what the audit-evidence hierarchy admits when re-performance is
  not.

## Failure signal

If this observation design is wrong, the signal is one of: (i) a later
session finds an instance of the placeholder class in a habitat this
record's sweep declared clear; (ii) a verdict in the phase-2 record turns
out to describe the working tree rather than what `6486c4b` delivered —
the one evidence substitution this role is specifically barred from making;
or (iii) the human reading the record cannot tell which claims were
inspected first-hand and which were taken from the observed role's own
assertion.

## Out of scope

- Any edit to `core/`, `test/`, `docs/handbooks/`, or the observed role's
  `docs/issue-128/reports/implementation*` paths.
- Filing an issue for any finding — under contract v3 findings return in
  this record on this PR; the human files what they judge valid.
- Re-opening issue #128's own excluded items: retroactive fixes to existing
  placeholder instances, and `code_under_review` / `closed_checks[].code_sha`.
- Re-executing any test, gate, or script belonging to the observed delivery.

## How you'll know it worked

- The phase-2 record addresses all three verdict levels explicitly, with no
  level silently omitted.
- Every verdict-bearing sentence in it names a commit sha, `file:line`, or
  URL adjacent to the verdict.
- The independence statement appears before the first verdict sentence.
- Clauses C1-C10 are each marked fulfilled with the section that fulfils
  them, or marked dropped with a reason.
