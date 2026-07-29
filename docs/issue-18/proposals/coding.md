# Proposal: fix stale single-path approval rule in directive.sh (issue #18)

## files

- `core/hooks/directive.sh` (lines 82-88, the human-decisions paragraph
  injected into every role session's `SessionStart` prompt)

No other file needs an update. The survey
(`docs/issue-18/reports/coding/survey.md`) greps the whole repo and finds
this is the only stale restatement of the pre-amendment single-path
approval rule; `core/hooks/approval-gate.sh` and `core/hooks/gh-guard.sh`
already implement and describe the two-path (amended) rule correctly.

## Request

Issue #18: `directive.sh`'s human-decisions paragraph still tells every
role session "A comment is never an approval, however affirmative it
reads" — the pre-amendment, single-path (review-Approve-only) rule. Issue
#14 / PR #15 amended contract v3 s19/s10 to add a second valid path:
single-account mode, where an exact-match issue-level comment
`APPROVE issue-<n>/<role>` from an `approvers.md` account counts as
phase-2 approval when the PR author is that same approver's own account.
`directive.sh` was missed by issue #14's phase-1 survey and now
contradicts the amended contract it is supposed to summarize, causing a
live refusal of an authorized phase-2 start (muster PR #75).

## Constraints

- Phase-1-only session (contract v3 s19): this proposal does not touch
  `core/hooks/directive.sh` or any `src/` code. Only
  `docs/issue-18/reports/coding/survey.md` and
  `docs/issue-18/proposals/coding.md` are written in this phase.
- The eventual edit to `directive.sh` must preserve every other clause of
  the existing paragraph verbatim in spirit: PR merge = acceptance,
  PR comment (non-matching) = feedback, issue/PR closed unmerged =
  refusal, bot/agent Approve never counts, no reading approval out of
  free-text prose, and the role never approves or merges anything itself.
  Only the single-path "a comment is never an approval" sentence is to be
  replaced by the amended two-path rule.
- The new wording must track `core/contract/role-handoff-contract.md`
  section 19's language precisely enough that a role session reading
  either document reaches the same conclusion about what counts as
  approval — this is the same "informing half must describe what the
  enforcing half enforces" property `directive.sh`'s own header comment
  already states as its design intent.
- No change to `approval-gate.sh`, `gh-guard.sh`, or their tests: they
  already implement/describe the two-path rule correctly (see survey).

## What will be done

In phase 2 (after Approve), replace the current paragraph in
`core/hooks/directive.sh` (lines 82-88):

```
- Human decisions are GitHub acts only: review Approve = permission to
  execute, PR merge = acceptance of the delivered work, PR comment =
  feedback (revise on the same branch, push to the same PR), issue/PR
  closed unmerged = refusal. A comment is never an approval, however
  affirmative it reads; a bot's or another agent's Approve is not a
  human's. Never read approval out of prose, and never approve or merge
  anything yourself.
```

with the following exact text:

```
- Human decisions are GitHub acts only: PR merge = acceptance of the
  delivered work, issue/PR closed unmerged = refusal. Phase 2 opens
  through exactly two paths (contract v3 s19): a PR review Approve from
  an approvers.md account different from the PR's author (two-account
  mode); or, in single-account mode — when the PR author and the
  approver are the same account — an issue-level comment whose entire
  body is the exact string APPROVE issue-<n>/<role>, posted by an
  approvers.md account. String equality only, never prose interpretation:
  any other comment, including a near-match or an affirmative-sounding
  one, is feedback, not approval (revise on the same branch, push to the
  same PR). A bot's or another agent's Approve or APPROVE-shaped comment
  is never a human's — agent accounts are never listed in
  approvers.md. Never read approval out of prose, and never approve,
  merge, or relay an approval yourself.
```

This keeps the bot-exclusion clause ("a bot's or another agent's Approve
... is never a human's"), the no-prose-inference clause ("string equality
only, never prose interpretation" / "Never read approval out of prose"),
and the never-self-approve clause ("never approve, merge, or relay an
approval yourself") intact, while replacing the single-path sentence with
the amended two-path rule (review Approve, or single-account
`APPROVE issue-<n>/<role>` comment when PR author == approver).

## Out of scope

- Editing `directive.sh` itself, or any `src/` code — this is phase-1
  only; the edit above is deferred to phase 2, after a human Approve on
  this PR.
- Any change to `approval-gate.sh`, `gh-guard.sh`, their tests, or
  `role-handoff-contract.md` — all already correct per the survey.
- Re-litigating the contract amendment itself (issue #14 / PR #15); this
  proposal only brings `directive.sh` into agreement with it.

## How we'll know it worked

- `grep -n "A comment is never an approval" core/hooks/directive.sh`
  returns no match after the phase-2 edit (the stale single-path phrase
  is gone).
- `grep -rn "A comment is never an approval, however affirmative it
  reads" docs core src` matches only
  `core/contract/role-handoff-contract.md` (the source-of-truth contract
  text, which is correct as written and out of scope to change), not
  `directive.sh`.
- The new `directive.sh` paragraph, read side by side with
  `role-handoff-contract.md` section 19's two-path rule, describes the
  same approval surface: review Approve (two-account mode) or exact
  `APPROVE issue-<n>/<role>` comment from an approvers.md account when
  PR author == approver (single-account mode), with the bot-exclusion,
  no-prose-inference, and never-self-approve clauses all still present.
- A role session that reads the new prompt no longer refuses an
  authorized single-account comment approval (the failure mode reported
  live on muster PR #75).
