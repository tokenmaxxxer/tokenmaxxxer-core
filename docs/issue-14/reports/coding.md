---
subject: issue-14
role: coding
loop_state: landed
code_under_review: 8b5f0fc1c37f012ea08b643b30a1168a43380d84
---

# Coding record — issue-14

## What was done

Amended `core/contract/role-handoff-contract.md` per the approved
proposal (`docs/issue-14/proposals/comment-approval-s19.md`), applying
all six edits verbatim:

1. Section 19 "human's verdict on the proposal" bullet: replaced with
   the two-path form (two-account review Approve, stricter; single-account
   exact-match `APPROVE issue-<n>/<role>` comment from an
   `approvers.md` account) and named the issue-31/issue-38 discrepancy
   it closes.
2. Section 19 `scope-approved` bullet: generalized "the allowlisted
   human's Approve review" to "one of the two Approve signals above."
3. Section 19 "what the gate blocks" bullet: same generalization.
4. Section 19 "re-wakes are unaffected" bullet: added comment
   deletion/edit alongside review dismissal as a re-gating trigger.
5. Section 19 "never self-served" bullet: extended the mechanical
   exclusion to `APPROVE issue-<n>/<role>` comments, not just reviews.
6. Section 10 "human decisions are GitHub acts" bullet: appended the
   single-account exception sentence so it doesn't contradict s19's
   amended text.

## Why

No alternative wording considered — proposal was approved verbatim
(PR #15 review comment `APPROVE issue-14/coding`) and the task was to
execute it exactly, not redesign it.

## Basis

- Upstream: proposal commit 8b5f0fc (docs/issue-14/proposals/comment-approval-s19.md).
- Approval: PR #15, comment `APPROVE issue-14/coding` from an
  `approvers.md`-listed account (single-account mode — this is the
  first case that exact path formally covers).
- `loop_state`: landed (all six edits applied, phase 2 complete for
  this subject).
- No open findings on this subject.

## What did not work

Nothing — proposal wording applied as written; no edit needed rework.
