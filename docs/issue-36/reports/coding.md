---
kind: coding-record
subject: issue-36
role: coding
loop_state: reported
code_under_review: core/contract/role-handoff-contract.md
---

# Coding record — issue-36

Phase 2 executed after human Approve (issue comment
`APPROVE issue-36/coding`, JiwonJung94, 2026-07-29T22:15:26Z, single-account
mode — PR #37 author and approver are the same account).

## What was done

Executed the approved clause checklist (docs/issue-36/proposals/coding.md)
against `core/contract/role-handoff-contract.md`: replaced section 3's
WAKES-ON table and its by-role routing enumeration with a short pointer to
the host's `docs/specs/wake-routing.md`; removed section 3's
resolved-finding re-verify-edge paragraph (routing content) and section
15's routing sentence in the "Wake edge" bullet, while keeping both
sections' record-semantics prose (loop_state values, resolved_findings,
finding-response) intact; fixed the one stray cross-reference in section 8
that attributed routing to WAKES-ON directly; left section 19 and
README.md unedited after confirming (by grep and reading) they carry no
routing enumeration to strip.

## Why

Issue #36, step 2 of the wake-routing ownership migration (step 1:
on-the-record#95/PR#96 moved the routing table to
`docs/specs/wake-routing.md`). Keeping a routing table in this contract
alongside the host's table recreates the dual-source-of-truth problem
step 1 was meant to close; the contract's job is to stay self-sufficient
about record FORMAT/STATES, not about which role a state wakes.

## Upstream basis

- Issue #36 (subject, request text).
- docs/issue-36/reports/coding/survey.md (this role's phase-1 survey,
  same PR #37, commit 6f32860).
- docs/issue-36/proposals/coding.md (this role's phase-1 proposal, same
  commit) — the approved clause checklist executed here.
- PR #37 issue-comment `APPROVE issue-36/coding` (JiwonJung94,
  2026-07-29T22:15:26Z) — the phase-2 gate per contract v3 s19,
  single-account mode.

## Clause checklist, fulfilled

1. Replaced section 3's WAKES-ON table with a paragraph pointing to
   `docs/specs/wake-routing.md` for routing, keeping only `loop_state`
   FORMAT/STATES in the contract. Fulfilled: this commit,
   `core/contract/role-handoff-contract.md` section 3 heading and body
   ("## 3. Record states; routing lives at the host").
2. Kept section 3's concurrency-is-normal intro sentence, rephrased to stop
   presupposing the table. Fulfilled: this commit, same section 3 edit.
3. Kept the "Round-end value-gates edge" and "Pre-work approval-gate edge"
   paragraphs as human-consulted gate descriptions, no routing phrasing to
   strip beyond the section 3 rewrite (both paragraphs already said
   "human-consulted, never automated" without naming a role). Fulfilled:
   this commit, same section 3 edit (paragraphs retained, only the
   trailing "this table" -> "this contract" wording swept in with the
   rewrite).
4. Removed the "Resolved-finding re-verify edge" paragraph from section 3;
   not relocated — host doc already carries it. Fulfilled: this commit,
   same section 3 edit (paragraph deleted).
5. Rewrote the "Who evaluates these rows" paragraph to drop "the table
   above" and state a human reads the board against the host's routing
   rules. Fulfilled: this commit, same section 3 edit
   ("Who evaluates state changes" paragraph).
6. Section 15's "Wake edge" bullet: deleted the routing sentence, kept the
   finding-raised -> findings-resolved -> re-verify state-transition
   sentence and the human-consulted property. Fulfilled: this commit,
   section 15 "Finding-resolution handshake", bullet renamed
   "State transition."
7. Confirmed section 19 needs no routing-phrasing strip. Verified at build
   time: `grep -n "^## 19" -A 40` shows the approval-gate section stated
   purely as a state transition (`scope-proposed` -> human review ->
   `scope-approved`), no by-role enumeration. No edit made.
8. Fixed the cross-reference to section 3's removed content in section 8
   ("The human's seat"): "which role runs next — is carried by WAKES-ON
   (section 3)" -> "is carried by the host's routing rules (see section
   3)". Fulfilled: this commit, section 8 edit. All other WAKES-ON
   cross-references (surveyed pre-edit at lines 104, 110, 162, 174, 183,
   199, 244, 249, 345, 493) cite section 3 by number/name only, not by
   content — re-checked post-edit via `grep -n "WAKES-ON"
   core/contract/role-handoff-contract.md`: remaining hits are structural
   cross-references (sections 4, 5, 6, 13, 14) and the new section-3
   paragraph's own descriptive mention of the routing table's former name;
   none enumerate roles or restate table rows. No further edits required.
9. README.md: surveyed, one hit (`README.md:26`, generic "a role wakes on
   an issue" phrasing, not a WAKES-ON table restatement). No edit made;
   stated explicitly here per the proposal's instruction to record the
   no-op rather than silently skip it.

## What did not work

None — no edit attempted then reverted; no expectation failed to hold
during this build.

## Closed checks (this build)

closed_checks:
- check: "grep -n WAKES-ON core/contract/role-handoff-contract.md shows no
  table rows and no by-role enumeration, only section/property
  references"
  code_under_review: core/contract/role-handoff-contract.md
  result: pass — remaining hits are cross-references and one descriptive
  mention in the new section-3 paragraph, no table rows, no per-role
  list.
- check: "sections 3, 15, 19 each still parse as complete sections, no
  dangling cross-references to deleted content"
  code_under_review: core/contract/role-handoff-contract.md
  result: pass — read all three sections post-edit; section 3's deleted
  table and re-verify-edge paragraph have no remaining internal
  references; section 15's bullet still reads coherently after the
  routing-sentence removal; section 19 unchanged.
- check: "contract still states self-sufficiently what loop_state values
  exist and what findings-resolved means, without the host doc"
  code_under_review: core/contract/role-handoff-contract.md
  result: pass — section 3's rewritten intro names the loop_state values
  directly; section 15 retains the full record-semantics description
  (resolved_findings entry, findings-resolved state, re-verification is
  the finder's own judgment) untouched.

## Hunt

Stance: skeptic-of-completeness (rotated). Probed whether any WAKES-ON
enumeration content survived outside section 3/15 by re-grepping the whole
file after the edit (see clause 8 above) and reading sections 4-6, 13-14 in
full. No routing content found outside the two sections named in the
issue. Nothing further to report.

## Open findings

None open. No `finding` blocks addressed to this role exist for this
subject at time of writing.

## Next steps

Commit and push to `issue-36/coding` / PR #37 for merge. No further coding
action pending on this subject unless a new `finding` addressed to coding
appears (open-finding resolution path: none open, so none to resolve).

## Out of scope (per proposal, untouched)

- The nine rulebooks' own WAKES-ON restatements (separate follow-up per
  issue text).
- `docs/specs/wake-routing.md` itself (host repo, not this one).
- Any behavioral/tooling change.
