---
subject: issue-41
role: coding
kind: coding-record
loop_state: landed
code_under_review: 10ab50b9eafdba78459858460ac2fa754c2e4a67
---

## Phase 2 — execution record

Active `build-proposal`: `docs/issue-41/proposals/2026-07-30-reword-qa-coding-cycle-note.md` (PR #42, approved via `APPROVE issue-41/coding`).

### Why

The qa↔coding cycle-termination bullet named "qa" and cited section 3 as
the routing authority, but #36 removed section 3's routing table,
leaving a stale, role-naming residual — the last one #38's sweep missed.
Repointing to `docs/specs/wake-routing.md` finishes the pattern #36/#38
already applied elsewhere in this file, per the approved proposal.

### What was done

`core/contract/role-handoff-contract.md` lines 206-208: replaced "wakes
qa again per section 3" with "is a board change that may wake the next
role per `docs/specs/wake-routing.md`" — dropped the role name and the
stale section-3 cite, kept the termination semantics (cycle ends when a
wake produces no new board change) and the two named participants
(qa's `finding`, coding's `finding-response`/fix commit), matching the
#36/#38 pattern.

### What did not work

Nothing — single string replacement, applied cleanly on first attempt.

### Verification (generation-time confirmation, not a review pass)

- `grep -n "wakes qa again per section 3" core/contract/role-handoff-contract.md` → no output (stale phrase removed).
- `grep -c "wake-routing.md" core/contract/role-handoff-contract.md` → 7 (was 6 before the edit, per survey).
- Bullet re-read in isolation: still self-consistent (states who produces the commit, that it's a board change, and the exact termination condition).

### Hunt cadence

Skipped: single three-line wording substitution in a markdown contract
file, no code path, no logic, no composition surface — a warrant-hunter
pass has nothing to probe here beyond what the two greps above already
confirm.

### Open findings

None.

### Out of scope (per proposal, untouched)

- Any file other than `core/contract/role-handoff-contract.md`.
- The verify↔coding termination bullet.
- `docs/specs/wake-routing.md` itself.

commit shas landed: cdae842
