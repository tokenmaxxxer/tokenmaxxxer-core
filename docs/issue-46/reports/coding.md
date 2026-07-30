---
kind: coding-record
subject: issue-46
produced_by: coding
loop_state: done
upstream:
  - path: docs/issue-46/reports/coding/survey.md
    sha: <set at commit>
  - path: docs/issue-46/proposals/2026-07-30-build-strip-wake-vocabulary.md
    sha: <set at commit>
code_under_review: <set at commit>
closed_checks:
  - name: grep-zero-wake-hits
    code_sha: <set at commit>
---

# Coding record — issue-46, phase 2

Approved via issue-level comment `APPROVE issue-46/coding` (single-account
mode; PR #47 author and approver were the same account), posted
2026-07-30T04:26:36Z on issue #46.

## Why

on-the-record #120 deleted the wake system (wakes.py, `spawn.py wake`,
wake-routing.md, WAKES-ON). `core/contract/role-handoff-contract.md`
still described that removed mechanism and pointed at a
`docs/specs/wake-routing.md` that no longer exists anywhere — a dangling
reference the approved proposal names as the exact failure signal
issue-38 had warned about. Removing it keeps the contract accurate to
what actually exists: routing is the orchestrating session's judgment
from reading the board, not an encoded table.

## Scope

`core/contract/role-handoff-contract.md` only, per the approved proposal.
Removing wake/WAKES-ON vocabulary and dangling `docs/specs/wake-routing.md`
pointers; routing becomes the orchestrating session's judgment read
directly off the board. Record FORMAT/STATE semantics (`loop_state`
vocabulary, section 7 authority, section 19 scope mechanics) unchanged.

## What was done

Edited every wake/WAKES-ON occurrence in
`core/contract/role-handoff-contract.md` per the proposal's checklist
(section 3 title/intro, section 5 finding back-edge, section 6 loop
termination, section 7 authority, sections 10/14/15/19, and the three
DEPENDS-ON entries), replacing routing-table language with prose stating
routing is the orchestrator's judgment from reading the board. Structural
facts (trigger conditions, findings visibility, human-consulted-not-
automated edges, loop termination logic) preserved verbatim in meaning.

Verification: `grep -niE "wake" core/contract/role-handoff-contract.md`
returns zero hits (ran directly, confirmed after the edit).

## What did not work

(none — single mechanical text edit, no false starts)

## Open findings

None. Open-finding resolution path: not applicable — no `finding` block
is open against this record; should verify or review post one later, it
routes `addressed_to: coding` per section 5 and is closed via this
record's next revision.

## Next steps

None on this subject. Downstream: `README.md:26`'s informal "wakes"
mention and any rulebook adopting this contract that still names roles
inline for routing are separate proposals, per the approved proposal's
out-of-scope list.

## Hunt (warrant-hunter, end of phase 2)

One finding returned: `README.md:26` still reads "A role wakes on an
issue". Not new — the approved proposal explicitly listed this line as
out of scope ("left for a future prose sweep if the human wants it"), so
this confirms the scope boundary held rather than surfacing a defect. No
action taken; carried forward as a future-proposal candidate, not a
blocking finding against this delivery.

closed_checks:
- name: grep-zero-wake-hits
  code_sha: <set at commit>
- name: warrant-hunt-end-of-phase2
  code_sha: <set at commit>
