---
kind: build-proposal
subject: issue-38
produced_by: coding
loop_state: proposed
upstream:
  - path: docs/issue-38/reports/coding/survey.md
    sha: <set at commit>
---

## Request

Audit the remaining WAKES-ON/routing mentions in
`core/contract/role-handoff-contract.md` outside #36's write set (section
3, section 15) and strip or repoint anything that names WHICH role a
board state summons, per the operator rule: core contains nothing about
who wakes next. Pure record/visibility semantics stay.

## Constraints

- Scope is `core/contract/role-handoff-contract.md` only — no other file.
- Keep every requirement that a role's contract entry carries a WAKES-ON
  edge/channel (the structural fact); remove only the naming of which
  other role sits on the other end of that edge.
- Repoint using the same pattern #36 already used at lines 91-93 and
  520-522 (`docs/specs/wake-routing.md`), not a new phrasing.
- Do not touch section 3 or section 15 (already #36's write set).

## What will be done

files: `core/contract/role-handoff-contract.md`

- [ ] Line 150 (ux-design DEPENDS-ON entry): drop "after product" and
  "feeds coding on reaching `loop_state: reviewed`"; keep "a
  `ux-design-record` exists per subject and carries a WAKES-ON edge",
  repointed to `docs/specs/wake-routing.md`.
- [ ] Lines 162-163 (verify DEPENDS-ON entry): drop "a blocking-finding
  channel back to coding"; keep "carries its own WAKES-ON edges" and "emits
  its blocking-finding channel per section 5", repointed to
  `docs/specs/wake-routing.md`.
- [ ] Line 171 (reflect DEPENDS-ON entry): drop "after verify/review
  conclude"; keep "carries its own WAKES-ON edge", repointed to
  `docs/specs/wake-routing.md`.
- [ ] Line 187 (finding back-edge, section 5): drop the stale citation to
  section 3's now-deleted per-role rows; state that findings addressed to
  a role are part of that role's WAKES-ON triggers, routed per
  `docs/specs/wake-routing.md`.
- [ ] Verify no other line changes: re-grep `WAKES-ON\|wakes\|wake` post-edit
  and confirm every remaining hit is pure record/visibility semantics per
  the survey's classification table.

## Out of scope

- `docs/specs/wake-routing.md` itself (host doc, different repo/role's
  concern — this contract only points to it).
- Section 3 and section 15 (#36's write set, already landed).
- Any rulebook that adopts this contract (separate proposal per repo, per
  the contract's own header).

## How you'll know it worked

`grep -n "WAKES-ON\|wakes\|Wakes\|wake"
core/contract/role-handoff-contract.md` after the edit shows no line
naming a specific other role as the destination/predecessor of a WAKES-ON
edge — every hit either repoints to `docs/specs/wake-routing.md` or states
pure record-state/visibility semantics with no role named.

## Alternatives considered

- **Rewrite section 4's DEPENDS-ON entries wholesale to remove all
  routing-adjacent phrasing, not just the four flagged sites.** Not
  chosen: the survey found only four sites carrying role-summoning prose;
  broader rewriting risks losing the structural-enforcement statements
  (e.g. "a ux-design-record exists per subject") that section 4 still
  needs to state, and the issue explicitly asks for an audit, not a
  rewrite.
- **Replace `docs/specs/wake-routing.md` references with a generic "see
  the host's routing doc" to avoid hardcoding a path.** Not chosen: #36
  already established the concrete path as the canon reference in two
  places (lines 93, 522); a third phrasing style would fragment the
  convention instead of following it.

## Failure signal

If a future host-doc change renames or removes
`docs/specs/wake-routing.md` and this contract's four repointed sites are
not updated to match, `grep -rn "wake-routing.md"
core/contract/role-handoff-contract.md` returning a path that no longer
resolves in the host repo is the concrete signal this proposal turned out
wrong (a dangling reference instead of a resolved one).
