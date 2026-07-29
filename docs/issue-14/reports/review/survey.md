---
subject: issue-14
role: review
loop_state: scope-proposed
---

# Current-state survey — issue-14

Spec: GitHub issue #14 ("contract s19: recognize comment-based APPROVE
in single-account mode"), Problem/Requirement/Acceptance sections.
code_under_review: 4bf2910477e9d6b76f9abad2e6c59d4304b2e9a2 (the commit
that actually edits core/contract/role-handoff-contract.md; merged to
main via PR #15 / 9ec8ba8).

No prior verify run exists on this subject (docs/issue-14 has no
closed_checks artifact) — every requirement below is re-derived, none
cited.

## Extracted requirement line items

From "Requirement":
R1. s19 recognizes, in single-account mode (PR author == approver), an
    issue-level comment whose entire body is exactly
    `APPROVE issue-<n>/<role>`, posted by an approvers.md account, as a
    valid phase-2 approval.
R2. The two-account path (formal PR review Approve) remains available
    and is the stricter alternative where available.
R3. The amendment states explicitly that it closes the comment-vs-review
    discrepancy recorded in muster issue-31/issue-38.

From "Acceptance":
A1. s19 text covers the single-account comment path with the exact-match
    body requirement and the approvers.md check.
A2. Role rulebooks that cite s19 verbatim need no divergent local
    interpretation — verify's strict reading and coding/qa/review's lax
    reading converge on the amended text.

## Artifact inspected

git show 4bf2910 -- core/contract/role-handoff-contract.md (52 insertions
across two hunks: section 8/10 boundary sentence, and section 19's
"human's verdict on the proposal" bullet plus four downstream bullets
that reference it: scope-approved, gate-blocks, re-wakes, never-self-served).

Also inspected for A2: `core/hooks/directive.sh` at commit 4bf2910 (the
issue-14 landing point) — this is a rulebook that mechanically enforces
the gate and contains its own prose statement of the rule, so it is
in scope for "rulebooks that cite s19 verbatim."
