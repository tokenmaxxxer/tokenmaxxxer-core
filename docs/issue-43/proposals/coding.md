---
subject: issue-43
role: coding
loop_state: scope-proposed
---

# Proposal: state explicitly that approval/acceptance/refusal comments attach to the PR, never the issue

## Request (paraphrased intent)

Three roles across two repos recorded approval provenance citing an
"issue comment" — a shared misreading traced to the contract's own
wording (`core/contract/role-handoff-contract.md` sections 10 and 19
currently say "issue-level comment" for the single-account APPROVE
signal, while `README.md` already says "PR comment" for the same
signal). Add one normative line making explicit that approval,
acceptance, and refusal comments attach to the PR under review, never
the issue; an issue comment is never approval provenance; a role
recording provenance must cite the PR comment. Converge the contract's
wording onto the PR-level form the README already uses.

## Constraints

- Exact-string match for the APPROVE signal (`APPROVE issue-<n>/<role>`)
  is unchanged — only its *location* (issue vs. PR) is being corrected.
- The two-account review-Approve path is untouched (it is already
  PR-scoped by construction — a PR review).
- Must not silently drop the "posted by an `approvers.md` account" /
  "never textual inference" / "agent accounts never satisfy this" rules
  already present at each site.
- `README.md` is not changed — it already states the target wording; the
  contract converges to it, not the other way around.

## What will be done (clause checklist)

File: `core/contract/role-handoff-contract.md`.

1. Section 10 (~line 313-326, "Human decisions are GitHub acts, and only
   GitHub acts"): change "an issue-level comment whose entire body is the
   exact string `APPROVE issue-<n>/<role>`" to "a PR-level comment,
   attached to the PR under review, whose entire body is the exact
   string `APPROVE issue-<n>/<role>`". Add one normative sentence to this
   bullet: approval, acceptance, and refusal comments are attached to the
   PR under review, never the issue; an issue comment is never approval
   provenance.
2. Section 19 (~line 664-670, "Single-account mode"): change "an
   issue-level comment whose entire body is the exact string" to "a
   PR-level comment, attached to the PR under review, whose entire body
   is the exact string". Add one clause: a role recording provenance for
   this signal must cite the PR comment (URL or PR-comment id), never the
   issue.
3. Section 19 (~line 707-710, "Never self-served"): no wording change
   needed beyond what #1/#2 already fix by reference — verified in
   phase 2 that the surrounding sentence still reads correctly once
   "issue-level" is gone upstream.

## Out of scope

- `README.md` — already correct, not touched.
- Backfilling or correcting the three already-merged role records issue
  #43 cites as incidents (#89, #92, console #1) — the issue asks for the
  normative line going forward, not a retroactive fix.
- Any hook/script change (`gh-guard.sh`, `board-gate.sh`, etc.) — this is
  a contract-text-only fix; no script currently parses "issue-level" vs.
  "PR-level" out of the contract text.

## Alternatives considered

- **Leave the contract's "issue-level" wording and instead correct
  README.md to say "issue comment".** Rejected: the issue explicitly
  frames the target behavior as PR-attached ("attached to the PR under
  review, never the issue"), and PR-level is also the behavior GitHub
  structurally supports better for provenance (the comment lives next to
  the diff being approved, not on a long-lived issue thread reused across
  re-wakes).
- **Only add the new normative sentence, leave "issue-level comment"
  standing alongside it.** Rejected: leaving both wordings in the same
  section reproduces exactly the ambiguity issue #43 reports; the fix
  must change the operative phrase, not just append a caveat next to a
  contradicting one.

## Failure signal

If a future role again records approval provenance as an issue comment
after this change lands, the fix was insufficient (either the wording
change missed a location, or the normative line needs to also live in
each role's own record template, not just the contract).

## How success will be judged

- Sections 10 and 19 of `core/contract/role-handoff-contract.md` no
  longer contain the phrase "issue-level comment" in connection with the
  APPROVE signal; both say PR-level.
- Section 19's single-account bullet includes the explicit provenance
  instruction: cite the PR comment, never the issue.
- The wording in sections 10 and 19 is mutually consistent with each
  other and with `README.md:43-46`.
