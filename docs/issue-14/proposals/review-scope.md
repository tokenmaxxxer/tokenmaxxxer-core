---
subject: issue-14
role: review
loop_state: scope-proposed
---

# Proposal: review scope for issue-14

## What is being audited

Spec: GitHub issue #14 (full text in docs/issue-14/reports/review/survey.md).
code_under_review: `4bf2910477e9d6b76f9abad2e6c59d4304b2e9a2` — the
commit that edits `core/contract/role-handoff-contract.md` (landed to
main via PR #15, merge commit `9ec8ba8`).

## Requirement list to verdict (phase 2)

R1, R2, R3 (from the issue's "Requirement" section) and A1, A2 (from
"Acceptance") as extracted in the survey — five line items, one verdict
each: Present | Surface | Absent | Incorrect | Unverifiable.

## closed_checks

None available: no verify run exists on this subject
(`docs/issue-14/reports/` has no verify artifact). All five items will
be re-derived from the diff directly, not cited.

## Method

Full-diff audit, not sampling — the change is a single ~52-line doc
edit to one file plus a coding record; this is well under the
100-300-line session pace, so no sampling derivation is needed.

## Note carried into phase 2

The survey flagged `core/hooks/directive.sh` as in-scope for A2
("rulebooks that cite s19 verbatim") since it independently states the
same rule in prose and is a mechanical enforcement point. Its state at
the issue-14 landing commit will be checked as part of A2's verdict.
