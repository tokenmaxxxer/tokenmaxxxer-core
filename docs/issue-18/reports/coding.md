---
subject: issue-18
role: coding
loop_state: landed
code_under_review: PENDING
---

# Coding record — issue-18

## What was done

Amended `core/hooks/directive.sh` per the approved proposal
(`docs/issue-18/proposals/coding.md`), replacing the stale single-path
"human decisions are GitHub acts" paragraph (lines ~82-88) with the
two-path approval rule from contract v3 s19:

- PR review Approve from an `approvers.md` account different from the
  PR's author (two-account mode); or
- in single-account mode, an issue-level comment whose entire body is
  the exact string `APPROVE issue-<n>/<role>`, posted by an
  `approvers.md` account.

The old sentence "A comment is never an approval, however affirmative
it reads" is removed and replaced with equivalent string-equality-only
language ("String equality only, never prose interpretation: any other
comment ... is feedback, not approval").

## Diff applied

```diff
-- Human decisions are GitHub acts only: review Approve = permission to
-  execute, PR merge = acceptance of the delivered work, PR comment =
-  feedback (revise on the same branch, push to the same PR), issue/PR
-  closed unmerged = refusal. A comment is never an approval, however
-  affirmative it reads; a bot's or another agent's Approve is not a
-  human's. Never read approval out of prose, and never approve or merge
-  anything yourself.
+- Human decisions are GitHub acts only: PR merge = acceptance of the
+  delivered work, issue/PR closed unmerged = refusal. Phase 2 opens
+  through exactly two paths (contract v3 s19): a PR review Approve from
+  an approvers.md account different from the PR's author (two-account
+  mode); or, in single-account mode — when the PR author and the
+  approver are the same account — an issue-level comment whose entire
+  body is the exact string APPROVE issue-<n>/<role>, posted by an
+  approvers.md account. String equality only, never prose interpretation:
+  any other comment, including a near-match or an affirmative-sounding
+  one, is feedback, not approval (revise on the same branch, push to the
+  same PR). A bot's or another agent's Approve or APPROVE-shaped comment
+  is never a human's — agent accounts are never listed in
+  approvers.md. Never read approval out of prose, and never approve,
+  merge, or relay an approval yourself.
```

## Why

No alternative wording considered — proposal was approved verbatim and
the task was to execute it exactly, not redesign it.

## Basis

- Upstream: `docs/issue-18/proposals/coding.md` (approved), grounded in
  `core/contract/role-handoff-contract.md` s19 (v3, amended under
  issue-14).
- Approval: phase-2 execution instruction received directly.
- `loop_state`: landed (single-file edit applied, verified, committed;
  phase 2 complete for this subject).

## Verification

Ran the two required checks after the edit:

1. `grep -n "A comment is never an approval" core/hooks/directive.sh`
   Output: (no match — command produced no lines), confirming the old
   sentence is gone from directive.sh.

2. `grep -rn "A comment is never an approval, however affirmative it reads" docs core src`
   Output:
   ```
   ugrep: warning: src: No such file or directory
   ```
   No matching lines from docs/ or core/ (src/ does not exist in this
   repo, hence the warning). Zero matches means the exact stale
   sentence is not present verbatim anywhere in docs/ or core/,
   including `core/contract/role-handoff-contract.md`.

## Open findings

None. The edit is scoped exactly to the approved paragraph in
`core/hooks/directive.sh`; no other files were touched; no follow-up
work identified.

## What did not work

None.
