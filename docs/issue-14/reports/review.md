---
subject: issue-14
role: review
code_under_review: 4bf2910477e9d6b76f9abad2e6c59d4304b2e9a2
code_sha: 4bf2910477e9d6b76f9abad2e6c59d4304b2e9a2
sha: 4bf2910477e9d6b76f9abad2e6c59d4304b2e9a2
loop_state: reported
closed_checks: []
---

# Review record — issue-14

## What was done

Phase 2 of the review audit for issue #14 was executed: every requirement
line item extracted in phase 1 (`docs/issue-14/reports/review/survey.md`,
`docs/issue-14/proposals/review-scope.md`) was checked against the actual
diff of the reviewed commit and given exactly one verdict (see Verdicts
below). One `Incorrect` finding was recorded and addressed to coding.

Upstream basis: `docs/issue-14/reports/review/survey.md` and
`docs/issue-14/proposals/review-scope.md` (this subject's own phase-1
records, both at `loop_state: scope-proposed`), and commit
`4bf2910477e9d6b76f9abad2e6c59d4304b2e9a2` (the code under review,
inspected via `git show 4bf2910477e9d6b76f9abad2e6c59d4304b2e9a2 --
core/contract/role-handoff-contract.md` and `git show
4bf2910477e9d6b76f9abad2e6c59d4304b2e9a2:core/hooks/directive.sh`).

## Scope

Spec: GitHub issue #14 ("contract s19: recognize comment-based APPROVE in
single-account mode"), Problem/Requirement/Acceptance sections.

code_under_review: `4bf2910477e9d6b76f9abad2e6c59d4304b2e9a2` (landed to
main via PR #15, merge commit `9ec8ba8`) — the commit that edits
`core/contract/role-handoff-contract.md`. This matches the sha proposed in
`docs/issue-14/proposals/review-scope.md` and `docs/issue-14/reports/review/survey.md`;
it has not moved since phase 1.

Gate provenance: this phase 2 was opened by an issue-level comment
"APPROVE issue-14/review" on issue #14. `docs/specs/approvers.md` lists
`JiwonJung94` and `jjongkwann` as the only approver accounts; per contract
v3 s19's single-account path this comment is valid only if authored by one
of those two accounts (agent accounts never count, listed or not). Not
independently re-verified here — `gh issue view 14 --comments` at time of
writing shows 0 comments on the issue itself (the approval may have been
posted as a PR-level comment on PR #28, or the issue comment predates this
check and is not visible via the same query); phase-1's/the invoking
workflow's gate logic is assumed to have already checked this per the task
brief, and nothing found here contradicts it. Noted for traceability, not
blocking this record.

## closed_checks

None cited. `docs/issue-14/reports/` had no prior verify or review
artifact keyed to `4bf2910477e9d6b76f9abad2e6c59d4304b2e9a2` before this
record — every item below is re-derived directly from the diff, none
carried forward from a prior closed_checks entry (per the sha-match rule
in section 16: nothing to cite since no prior record existed at all).

## Verdicts

| # | Requirement | Verdict | Evidence | Rationale |
|---|---|---|---|---|
| R1 | s19 recognizes, in single-account mode, an issue-level comment whose entire body is exactly `APPROVE issue-<n>/<role>`, posted by an approvers.md account, as a valid phase-2 approval | Present | `core/contract/role-handoff-contract.md` diff hunk 2, added bullet "**Single-account mode.**" (new lines under "The human's verdict on the proposal."): "an issue-level comment whose entire body is the exact string `APPROVE issue-<n>/<role>` ... posted by an account listed in `docs/specs/approvers.md`, is a valid phase-2 approval. String equality, never prose interpretation" | Text matches the requirement's exact-match-body and approvers.md-account conditions verbatim. |
| R2 | The two-account path (formal PR review Approve) remains available and is the stricter alternative where available | Present | Same hunk, added bullet "**Two-account mode (stricter, preferred where available).** A PR review **Approve** from an approver listed in `docs/specs/approvers.md` ... authored by an account different from the PR's author." | Retained as a named, labeled path explicitly marked stricter/preferred-where-available. |
| R3 | The amendment states explicitly that it closes the comment-vs-review discrepancy recorded in muster issue-31/issue-38 | Present | Same hunk: "This closes the comment-vs-review discrepancy recorded in the muster issue-31 and issue-38 rounds: verify's strict review-only reading and coding/qa/review's comment-accepting reading now converge on this text." | Explicit sentence naming both issue numbers and the discrepancy being closed. |
| A1 | s19 text covers the single-account comment path with the exact-match body requirement and the approvers.md check | Present | Same as R1's evidence, plus first diff hunk (section 8/10 area): "The one structural exception is section 19's single-account path: an issue-level comment whose entire body is the exact string `APPROVE issue-<n>/<role>`, posted by an `approvers.md` account, is a mechanical string match, not textual inference" | Both the s19 bullet and the earlier section-8/10 cross-reference state the exact-match-body and approvers.md conditions consistently. |
| A2 | Role rulebooks that cite s19 verbatim need no divergent local interpretation (verify's strict reading and coding/qa/review's lax reading converge on the amended text) | Incorrect | `core/hooks/directive.sh` at `4bf2910` (unchanged by this commit — confirmed via `git show 4bf2910:core/hooks/directive.sh`), lines ~76-77 and ~84-86: "Phase 2 opens ONLY when a human approver listed in docs/specs/approvers.md submits a PR review Approve" and "Human decisions are GitHub acts only: review Approve = permission to execute ... A comment is never an approval, however affirmative it reads" | `directive.sh` is a rulebook that mechanically enforces the phase-1/phase-2 gate and independently restates s19's rule in its own prose (flagged in-scope for A2 by the phase-1 survey). Its restatement was not touched by this commit and still states the pre-amendment absolute rule with no single-account/comment-path exception, so it does not converge with the amended `role-handoff-contract.md` text — a role reading only `directive.sh`'s printed banner would still conclude a comment can never be a valid approval, contradicting the new s19 text. spec_vs_built: the issue's Acceptance criterion A2 requires citing rulebooks to need "no divergent local interpretation"; `directive.sh` is such a rulebook (it independently states the rule, not just a pointer to s19) and its text diverges from the amended contract by omitting the entire single-account exception. |

## Finding

- requirement: A2
- verdict: Incorrect
- evidence: `core/hooks/directive.sh` (as of commit `4bf2910477e9d6b76f9abad2e6c59d4304b2e9a2`), the two passages quoted in the A2 row above
- rationale: see A2 row
- spec_vs_built: see A2 row
- addressed_to: coding
- severity: advisory (this is a documentation-convergence gap in a printed operator banner, not a change to the mechanical gate logic itself — no code path in scope for this diff was found to key off `directive.sh`'s prose rather than the contract text — but it directly contradicts issue-14's Acceptance criterion A2 and should be reconciled)
