---
subject: issue-43
role: coding
kind: coding-record
loop_state: landed
code_under_review: de940cb
---

## Phase 2 — execution record

Active `build-proposal`: `docs/issue-43/proposals/coding.md` (PR #44, approved via PR review Approve, issue-43/coding).

### Why

Three roles across two repos (#89 phase 2, #92 initial version, console
#1 phase 2) recorded approval provenance as an issue comment — traced
to the contract's own wording: sections 10 and 19 said "issue-level
comment" for the single-account APPROVE signal while `README.md:43-46`
already said "PR comment" for the same signal. Per the approved
proposal, converge the contract onto the PR-level wording and add the
normative line the issue requests.

### What was done

`core/contract/role-handoff-contract.md`:

- Section 10 (~line 322-326): "an issue-level comment" → "a PR-level
  comment, attached to the PR under review"; appended the normative
  sentence: approval, acceptance, and refusal comments are always
  attached to the PR under review, never the issue; an issue comment is
  never approval provenance.
- Section 19 single-account bullet (~line 667-680): "an issue-level
  comment" → "a PR-level comment, attached to the PR under review";
  appended the provenance-citation clause: a role recording provenance
  for this signal must cite the PR comment (URL or PR-comment id), never
  the issue.
- Section 19 "Never self-served" bullet (~line 710-713): no wording
  change needed — re-read in isolation post-edit, still reads correctly
  now that "issue-level" is gone upstream.

### What did not work

Nothing — both edits applied cleanly on first attempt.

### Verification (generation-time confirmation, not a review pass)

- `grep -n "issue-level" core/contract/role-handoff-contract.md` → no
  output (stale phrase fully removed).
- Section 10 and section 19 both now read "PR-level comment, attached to
  the PR under review", matching `README.md:43-46`'s "PR comment"
  wording.
- Re-read both edited passages in isolation: self-consistent, exact
  APPROVE string unchanged, two-account path untouched, "posted by an
  approvers.md account" / "never textual inference" / "agent accounts
  never satisfy this" rules all still present.

### Hunt cadence

Skipped: contract-text-only wording change (location of a comment, not
its content or matching logic), no code path, no script parses
"issue-level" vs "PR-level" out of the text — a warrant-hunter pass has
nothing to probe here beyond the greps above.

### Open findings

None.

### Out of scope (per proposal, untouched)

- `README.md` — already correct, not touched.
- Backfilling the three already-merged incident records (#89, #92,
  console #1).
- Any hook/script change (`gh-guard.sh`, `board-gate.sh`, etc.).

commit shas landed: de940cb
