# Current-state survey — issue-43

## Scope of the write surface

The proposal will touch exactly one file: `core/contract/role-handoff-contract.md`
(sections 10 and 19). No other file needs a write.

## Scouting skip record

Skip condition 2 applies: the spec leaves no open design decision. Issue
#43 supplies the normative sentence verbatim, and the correct target
wording already exists verbatim in this same repo (`README.md:43-46`,
quoted below) — the task is to converge the formal contract text onto
wording the repo already treats as authoritative, not to invent new
design. No category/exemplar research applies to a contract-text
consistency fix.

## Current state, by location (evidence: file + line, this repo, branch `issue-43/coding`)

1. `core/contract/role-handoff-contract.md:322-326` (section 10, "Human
   decisions are GitHub acts, and only GitHub acts") — states the
   single-account exception as: "an issue-level comment whose entire body
   is the exact string `APPROVE issue-<n>/<role>`, posted by an
   `approvers.md` account, is a mechanical string match."
2. `core/contract/role-handoff-contract.md:664-670` (section 19, "The
   human's verdict on the proposal" → "Single-account mode") — states:
   "an issue-level comment whose entire body is the exact string `APPROVE
   issue-<n>/<role>` ... posted by an account listed in
   `docs/specs/approvers.md`, is a valid phase-2 approval."
3. `core/contract/role-handoff-contract.md:707-710` (section 19, "Never
   self-served") — refers back to "their `APPROVE issue-<n>/<role>`
   comments" without a location word, inheriting whatever #1/#2 say.
4. `README.md:43-46` — already states the single-account signal as "a PR
   comment that is EXACTLY `APPROVE issue-<n>/<role>`, posted by an
   approvers.md login" — i.e. PR-level, not issue-level. This is the
   inconsistency: the formal contract (the file rulebooks are bound to)
   says issue-level; the README (the human-facing quick reference) says
   PR-level. Nothing in the repo currently states explicitly that
   approval/acceptance/refusal provenance must cite a PR comment and that
   an issue comment is never valid provenance — issue #43's three cited
   incidents (#89 phase 2, #92 initial version, console #1 phase 2) each
   read the contract's "issue-level" wording literally and recorded
   provenance accordingly, which is consistent with #1/#2 as currently
   worded, not a misreading of them.
5. No other file in this repo specifies the comment forms: `grep -rn
   "APPROVE issue-<n>\|issue-level comment\|issue comment" core/
   README.md docs/specs/` returns only the four hits above plus
   `docs/specs/approvers.md`, which lists accounts only and does not
   restate the comment-location rule.
6. History: `docs/issue-14/proposals/comment-approval-s19.md` is the
   proposal that introduced the current "issue-level comment" wording
   into sections 10 and 19 (landed via PR referenced there). It did not
   address location consistency with README.md, which already had the
   PR-comment wording before and after that change (unconfirmed exact
   date via `git log -p README.md` was not run — flagged as unknown
   below).

## Unknowns

- Whether `README.md`'s PR-comment wording predates or postdates
  issue-14's contract change was not checked via `git blame`/`git log
  -p`; not load-bearing for this fix since both the issue text and the
  README already agree on the target wording (PR-level), so the
  direction of the fix does not depend on which came first.
- Whether any already-merged role record (e.g. the three incidents named
  in issue #43) needs retroactive correction — out of scope per the
  issue's own framing (it asks for the normative line, not a backfill of
  past records).
