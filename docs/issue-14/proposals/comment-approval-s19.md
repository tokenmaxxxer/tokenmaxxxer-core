---
subject: issue-14
role: coding
loop_state: scope-proposed
---

# Proposal: amend contract v3 s19/s10 for single-account comment approval

## Request (paraphrased intent)

Contract v3 s19 currently only accepts a PR review Approve as phase-2
permission, which is structurally impossible in single-account mode
(GitHub forbids self-approval). README.md already documents a comment
fallback but the formal contract text doesn't, so strict readers of s19
(observed: verify on muster PR #49) correctly refuse phase 2 even when
the human already approved via comment. Amend s19 (and s10, which states
the same rule) so an exact-match issue-level comment
`APPROVE issue-<n>/<role>` from an approvers.md account is a valid
phase-2 approval in single-account mode, while formal review Approve
stays the stricter two-account path.

## Constraints

- Exact-string match only (`APPROVE issue-<n>/<role>`, matching the
  role's own subject and role name) — no prose inference, per the
  existing "never textual inference by a model" principle.
- Commenter must be listed in `docs/specs/approvers.md`.
- The two-account review-Approve path must remain available and stricter
  (preferred where a machine account exists — README.md "Hardening
  options").
- Downstream s19 bullets that say "Approve review" must not silently
  exclude the comment path, and must not silently accept agent-authored
  comments either.
- Must explicitly close the muster issue-31/issue-38 discrepancy per the
  issue's acceptance criteria.

## What will be done (exact wording, phase 2 only — not applied yet)

File: `core/contract/role-handoff-contract.md`.

**1. Section 19, replace the "human's verdict on the proposal" bullet
(current lines 645-649):**

Current:
> - **The human's verdict on the proposal.** A PR review **Approve** from
>   an approver listed in `docs/specs/approvers.md` (section 8) is
>   permission to proceed to phase 2. A comment is feedback on the
>   proposal — revise and push to the same PR. A close is refusal.
>   Nothing else — no comment text, no reaction, no bot Approve — opens
>   phase 2.

New:
> - **The human's verdict on the proposal.** Two paths open phase 2:
>   - **Two-account mode (stricter, preferred where available).** A PR
>     review **Approve** from an approver listed in
>     `docs/specs/approvers.md` (section 8), authored by an account
>     different from the PR's author.
>   - **Single-account mode.** When the PR author and the approver are
>     the same GitHub account (the default setup — section 10 — under
>     which GitHub structurally forbids a review Approve on your own
>     PR), an issue-level comment whose entire body is the exact string
>     `APPROVE issue-<n>/<role>` — this role's own subject and role name,
>     verbatim, nothing else in the comment — posted by an account
>     listed in `docs/specs/approvers.md`, is a valid phase-2 approval.
>     String equality, never prose interpretation; an agent account's
>     comment never counts, listed or not, since agent accounts are
>     never in `approvers.md` (section 8). This closes the
>     comment-vs-review discrepancy recorded in the muster issue-31 and
>     issue-38 rounds: verify's strict review-only reading and
>     coding/qa/review's comment-accepting reading now converge on this
>     text.
>   - Any other comment is feedback on the proposal — revise and push to
>     the same PR. A close is refusal. Nothing else — no free-text
>     comment, no reaction, no bot Approve — opens phase 2.

**2. Section 19, "`loop_state: scope-proposed` / `scope-approved`" bullet
(current lines 655-660) — generalize "Approve review" to cover both
paths:**

Current: "...`scope-approved` once the allowlisted human's Approve review
exists on the PR — recorded then in the role's record, whose first write
is itself phase-2 work. The review is the authority; any `loop_state`
write is its bookkeeping, never the other way around."

New: "...`scope-approved` once one of the two Approve signals above
exists on the PR — recorded then in the role's record, whose first write
is itself phase-2 work. The Approve signal is the authority; any
`loop_state` write is its bookkeeping, never the other way around."

**3. Section 19, "What the gate blocks, mechanically" bullet (current
lines 661-669) — same generalization:**

Current: "...while its `issue-<n>/<role>` PR lacks an allowlisted human's
Approve review — including while no PR exists at all..."

New: "...while its `issue-<n>/<role>` PR lacks one of the two Approve
signals above — including while no PR exists at all..."

**4. Section 19, "Re-wakes are unaffected" bullet (current lines
670-674) — cover comment retraction alongside review dismissal:**

Current: "...unless the human has since dismissed the approving review."

New: "...unless the human has since dismissed the approving review or
deleted/edited away the approving comment."

**5. Section 19, "Never self-served" bullet (current lines 675-677) —
extend to comments explicitly:**

Current: "No role approves, merges, or relays an approval. Agent
accounts are not listed in `approvers.md`, so their reviews cannot
satisfy this gate — the exclusion is mechanical, not behavioral."

New: "No role approves, merges, or relays an approval. Agent accounts
are not listed in `approvers.md`, so neither their reviews nor their
`APPROVE issue-<n>/<role>` comments can satisfy this gate — the
exclusion is mechanical, not behavioral."

**6. Section 10, "Human decisions are GitHub acts, and only GitHub acts"
bullet (current lines 322-330) — carve the single-account exception into
the same-rule restatement so it doesn't contradict s19:**

Current ends: "...These are GitHub-authenticated mechanical acts recorded
in history — never textual inference by a model. A free-text comment is
never an approval, however affirmative it reads: deciding what a
sentence means is a language problem, and the review Approve state
exists precisely so no one has to."

New: append one sentence: "The one structural exception is section 19's
single-account path: an issue-level comment whose entire body is the
exact string `APPROVE issue-<n>/<role>`, posted by an `approvers.md`
account, is a mechanical string match, not textual inference — free-text
approval commentary of any other shape remains categorically rejected."

## Out of scope

- No role rulebooks in this repo to amend (coding/qa/review/verify live
  in separate plugin marketplaces; they cite s19 rather than restate it).
- `README.md` and `docs/specs/approvers.md` already carry the correct
  behavior/data — no changes proposed there.
- No change to section 8 ("the human's seat") — its listing of GitHub
  acts (review Approve, merge, comment, close) already lists "PR comment"
  generically as one of the four acts; section 19 is where the specific
  string-match carve-out belongs, and section 8 is not restated stricter
  language that would need loosening.
- No hook/script changes (`gh-guard.sh`, `directive.sh`, `board-gate.sh`)
  — issue #14 is a contract-text amendment only.

## How success will be judged

- s19's phase-2-verdict bullet states both paths (review Approve,
  single-account comment) with the exact-match requirement and the
  approvers.md check, and closes the issue-31/issue-38 discrepancy by
  name.
- No remaining s19 bullet uses "Approve review" in a way that silently
  excludes the comment path or silently admits an agent-authored comment.
- Section 10's restatement of the same rule is consistent with s19,
  carrying the same exception rather than contradicting it.
