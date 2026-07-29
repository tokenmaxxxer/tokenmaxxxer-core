---
kind: coding-record
subject: issue-38
produced_by: coding
loop_state: done
code_under_review: HEAD
closed_checks:
  - name: grep-no-role-summoning-wakes-on
    code_sha: <set at commit>
---

# Coding record: issue-38

## Upstream

- `docs/issue-38/reports/coding/survey.md` (loop_state: surveyed)
- `docs/issue-38/proposals/2026-07-30-build-strip-residual-wake-routing.md` (loop_state: proposed)
- Approval: issue-level comment "APPROVE issue-38/coding" by JiwonJung94
  (approvers.md, single-account mode), 2026-07-29T22:40:21Z, on PR #40.

## Why

Phase-2 execution of the approved build proposal: the survey found four
sites in `core/contract/role-handoff-contract.md` (lines 150, 162-163,
171, 187) outside #36's write set (section 3, section 15) that still name
WHICH role a WAKES-ON edge summons, violating the operator rule that core
states nothing about who wakes next. #36 already established the fix
pattern (repoint to `docs/specs/wake-routing.md`) at lines 91-93 and
520-522; this issue applies it to the remaining four sites.

## What was done

Edited `core/contract/role-handoff-contract.md`, exactly per the
proposal's checklist:

- Line 150 (ux-design DEPENDS-ON entry): dropped "after product" and
  "feeds coding on reaching `loop_state: reviewed`"; kept the structural
  requirement (a `ux-design-record` exists per subject and carries a
  WAKES-ON edge), repointed to `docs/specs/wake-routing.md`.
- Lines 162-164 (verify DEPENDS-ON entry): dropped "a blocking-finding
  channel back to coding"; kept "carries its own WAKES-ON edges" and
  "emits its blocking-finding channel per section 5", repointed to
  `docs/specs/wake-routing.md`.
- Line 172 (reflect DEPENDS-ON entry): dropped "after verify/review
  conclude"; kept "carries its own WAKES-ON edge", repointed to
  `docs/specs/wake-routing.md`.
- Lines 188-189 (finding back-edge, section 5): dropped the stale citation
  to section 3's now-deleted per-role rows; states findings addressed to
  a role are part of that role's WAKES-ON triggers, routed per
  `docs/specs/wake-routing.md`.

No other file touched; no other line in `role-handoff-contract.md`
changed, per the proposal's out-of-scope list (section 3, section 15,
and `docs/specs/wake-routing.md` itself untouched).

## Verification (closed_checks)

- `grep-no-role-summoning-wakes-on`: re-ran
  `grep -n "WAKES-ON\|wakes\|Wakes\|wake" core/contract/role-handoff-contract.md`
  post-edit and inspected every hit. Every remaining hit is either a
  repoint to `docs/specs/wake-routing.md` (including the four newly
  edited sites) or pure record/visibility semantics with no destination
  role named, matching the survey's classification table and the
  proposal's "how you'll know it worked" criterion. No unclassified hit
  remained.

## What did not work

None — the proposal's checklist applied cleanly with no deviation from
the frozen scope.

## Open findings

None. Open-finding resolution path: not applicable — no `finding` block
is open against this record; should verify or review post one later, it
routes `addressed_to: coding` per section 5 and is closed via this
record's next revision.

## Next steps

None on this subject. Downstream: any rulebook adopting this contract
that still names roles inline for WAKES-ON routing is a separate
proposal, per the contract's own header (out of scope here, as stated in
the proposal).
