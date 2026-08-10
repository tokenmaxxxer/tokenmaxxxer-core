---
code_under_review: pending-commit
type: feature
breaking: false
verdict: n/a
loop_state: landed
---

## What was done

Implemented the frozen write set from
`docs/issue-189/proposals/2026-08-10-implement-rejection-withdrawal-lifecycle.md`
(build plan approved, PR #193 merged):

1. `warrant/hooks/scope-gate.sh:39` — added `"rejected"` to `KNOWN_STATES`,
   alongside `"withdrawn"`.
2. `core/hooks/approval-gate.sh`:
   - Added `reject_challenge = "REJECT issue-%s/%s"`, matched via the same
     exact-match/`approvers.md`-gated/`isMinimized`-skip machinery as
     `APPROVE`, refactored into a shared `comment_matches(challenge_str)`
     function used for both tokens.
   - Added the `CHANGES_REQUESTED`/`DISMISSED` read: `CHANGES_REQUESTED`
     from an approver produces one contract §5 `finding` block
     (`verdict: contradicts`, `addressed_to: <role>`, `severity: blocking`,
     `rationale:` the review body); `DISMISSED` produces no finding. The
     new read lives strictly inside the existing
     `if pr_out.returncode == 0:` guarded block, computed alongside the
     existing `last[login]` map — no unconditional reference, so the
     no-PR-open case stays a no-op per the after-proposal hunt finding.
   - Added `state_reason` to the `gh issue view --json` field list;
     read-only (parsed into `issue_state_reason`, used for nothing else —
     no enforcement branch added).
   - The rejection finding, when present, is folded into the existing
     deny message when the write is refused for lack of approval — it is
     read-only (never a write, never an auto-deny beyond the write that
     was already being refused), matching the design's explicit deferred
     scope.
3. `warrant/hooks/state.sh` — added a second pass collecting
   `status in ("withdrawn", "rejected")` proposals into a labeled
   "closed (withdrawn/rejected) — history" SessionStart section, alongside
   the existing open-units pass; empty when no such proposals exist.
4. `core/contract/role-handoff-contract.md` §2 preamble — added the shared
   `refused` loop_state value (any kind, mandatory finding pointer),
   distinct from a role's own negative-verdict terminal states.
5. Test coverage, one red/green pair each:
   - `run-scope-gate-tests.sh`: `status: rejected` proposal stands down
     the gate the same way `withdrawn` does.
   - `run-role-gates-tests.sh`: bare `refused` with no next-steps/
     resolution-path pointer denied; `refused` paired with a pointer
     allowed. Uses `record-fields-gate.sh`'s existing non-terminal-state
     next-steps/resolution-path requirement mechanically — `refused` is
     deliberately not added to any kind's `KIND_TERMINAL_DEFAULTS`
     (record-fields-gate.sh is outside this proposal's frozen write set
     and needed no change: the existing pointer-required-for-non-terminal
     rule already enforces contract §2's "a bare refused with no pointer
     is not a valid consumption" mechanically).
   - `deny-only-check.sh`: added `reject_forgery_probe`, symmetric to the
     existing `forgery_probe`, confirming an off-branch forged board write
     is refused the same way regardless of whether its content spells
     approval or rejection (no new trust boundary, per the design).

All four touched/reference suites run in this session, all green:
`run-scope-gate-tests.sh` 13/13, `run-role-gates-tests.sh` 81/81,
`deny-only-check.sh` (both probes ok), `run-approval-gate-tests.sh`
(read-only reference, unchanged behavior) 46/46:

```
$ bash core/hooks/tests/run-scope-gate-tests.sh
== 13 passed, 0 failed ==

$ bash core/hooks/tests/run-role-gates-tests.sh
role-gates: 81 passed, 0 failed

$ bash core/hooks/tests/deny-only-check.sh core/hooks
deny-only-check: ok — no permissionDecision allow under core/hooks
deny-only-check: ok — approval-gate.sh refuses the forged board write
deny-only-check: ok — board-gate.sh refuses the forged board write
deny-only-check: ok — approval-gate.sh refuses the forged rejected-state board write
deny-only-check: ok — board-gate.sh refuses the forged rejected-state board write

$ bash core/hooks/tests/run-approval-gate-tests.sh
== 46 passed, 0 failed ==
```

## Why

Composition point with on-the-record #573: `REJECT`/`CHANGES_REQUESTED`
is the human act that *produces* the contract §5 `finding` #573 consumes;
symmetric with `APPROVE` so rejection is no longer silent/unrepresentable
across the deployed surface (step-1 finding #6/#7 test debt, closed
here). `state.sh`'s closed-history section closes step-1 finding #5 (a
fresh session on a branch with prior withdrawal/rejection history no
longer sees bare silence).

## Upstream

Based on: `docs/issue-189/proposals/2026-08-10-implement-rejection-withdrawal-lifecycle.md`,
`docs/issue-189/proposals/2026-08-10-rejection-withdrawal-lifecycle-design.md`
(PR #192, merged), `docs/issue-189/reports/2026-08-10-hunt-implement-rejection-withdrawal-lifecycle.md`.

## What did not work

None — no write attempted-then-reverted, and no held expectation broke
during this build.

## Hunt (before-landing, stance 1)

Dispatched `warrant:warrant-hunter`, model sonnet, 180s cap (7 files
touched), record at
`docs/reports/2026-08-10-hunt-implement-rejection-withdrawal-lifecycle.md`.
One finding returned: a second approver's plain `APPROVED` PR review
causes `pr_approved` to be `True` (existing `any(...)` logic, predating
this build) even when another approver's review is `CHANGES_REQUESTED`
on the same PR — the computed `rejection_finding` is then never surfaced
anywhere, since it is only folded into the deny message on the
`not approved` path. This is real, but it is exactly the proposal's own
named out-of-scope item: "Auto-enforcement off `CHANGES_REQUESTED`
(design's own deferred item)." Fixing it would mean denying execution
writes whenever *any* reviewer requested changes regardless of another
reviewer's approval — that is auto-enforcement, explicitly deferred to a
phase-2 follow-up or a new issue by the approved design, not silently
decided here. Left open; not fixed in this pass.

## closed_checks

- check: run-scope-gate-tests.sh full suite | code_sha: pending-commit
- check: run-role-gates-tests.sh full suite | code_sha: pending-commit
- check: deny-only-check.sh (core/hooks) | code_sha: pending-commit
- check: run-approval-gate-tests.sh full suite (reference, unchanged) | code_sha: pending-commit

## Open findings

- The before-landing hunt finding above (mixed-review `CHANGES_REQUESTED`
  vs. `APPROVED` on the same PR is not auto-enforced) is left open,
  matching the approved design's explicit deferred scope. Resolution
  path: a future issue proposing auto-enforcement off `CHANGES_REQUESTED`,
  if the human wants that blast radius.
