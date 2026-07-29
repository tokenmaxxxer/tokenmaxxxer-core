---
subject: issue-14
role: coding
loop_state: scope-proposed
---

# Survey: comment-vs-review discrepancy in s19

## Problem restated

`core/contract/role-handoff-contract.md` s19 (phase-2 gate) and s10 (human
decisions) currently recognize only a submitted PR review Approve as valid
phase-2 permission. In single-account mode (the default — README.md
"One account, by default"), the PR author and the approver are the same
GitHub account, and GitHub structurally forbids approving your own PR, so
a review Approve is impossible to obtain. README.md already documents a
comment-based fallback (`APPROVE issue-<n>/<role>`, exact string, posted
by an approvers.md account) but the formal contract text in s19/s10 has
not been amended to match, so a strict reader of s19 (e.g. verify) can
correctly refuse phase 2 even when the human's decision already exists as
that comment — the failure observed live on muster PR #49
(issue-31/issue-38 rounds).

## Every place restating "a comment is never approval"

Grepped `*.md` repo-wide for `never an approval`, `comment is never`,
`APPROVE issue-`, `no comment text`, `A comment is feedback`:

1. **`core/contract/role-handoff-contract.md:328`** (section 10, "Human
   decisions are GitHub acts, and only GitHub acts"): "A free-text comment
   is never an approval, however affirmative it reads: deciding what a
   sentence means is a language problem, and the review Approve state
   exists precisely so no one has to."
2. **`core/contract/role-handoff-contract.md:645-649`** (section 19, "The
   human's verdict on the proposal"): "A PR review **Approve** from an
   approver listed in `docs/specs/approvers.md` (section 8) is permission
   to proceed to phase 2. A comment is feedback on the proposal — revise
   and push to the same PR. A close is refusal. Nothing else — no comment
   text, no reaction, no bot Approve — opens phase 2."
3. Downstream section-19 bullets that assume "Approve" means only a
   *review* and would otherwise read as contradicting the amendment if
   left untouched:
   - line 657-658 (`scope-approved` trigger): "once the allowlisted
     human's Approve review exists on the PR".
   - line 665-666 (what the gate blocks): "while its `issue-<n>/<role>`
     PR lacks an allowlisted human's Approve review".
   - line 672-674 (re-wakes unaffected): "unless the human has since
     dismissed the approving review" — a retracted single-account
     comment has no equivalent phrase today.
   - line 675-677 (never self-served): "Agent accounts are not listed in
     `approvers.md`, so their reviews cannot satisfy this gate" — silent
     on agent-authored comments, which the amendment must also exclude.

No other repo file restates the rule: `docs/specs/approvers.md` is just
the login list (already correct, no change needed); `README.md:37-48`
already carries the target behavior in prose and needs no edit — it is
the amendment's spec, not a place to fix. No role rulebooks (coding/qa/
review/verify) live in this repo; issue #14's acceptance criterion that
"role rulebooks... need no divergent local interpretation" is satisfied
once s19's own text is unambiguous, since those rulebooks cite s19
verbatim rather than restating it.

## Existing precedent

`docs/issue-12/reports/coding.md:13` (already merged to `main`) records a
past single-account approval exactly in the target shape: `Approve review
comment: "APPROVE issue-12/coding"` — i.e. coding has already been
operating on the lax reading issue #14 asks the contract to formalize.
