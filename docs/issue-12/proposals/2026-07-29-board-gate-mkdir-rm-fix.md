# Proposal: fix R5 false positive on a role's own bare record dir

## Request (paraphrased intent)
board-gate's R5 ownership check denies Bash `mkdir`/`rm` on a role's own
`docs/issue-<n>/reports/<role>/` directory, treating it as a foreign
record, while a `Write` under the same path is allowed. Migrated from
tokenmaxxxer/muster#40 (root cause located in muster#42 phase-1 survey).

## Constraints
- Fail-closed for foreign roles must be preserved exactly.
- Minimal diff: this is a one-line logic fix plus regression tests.

## What will be done
- `core/hooks/board-gate.sh`: in the R5 loop, change the own-role allow
  condition from `tail[0] == role and len(tail) > 1` to `tail[0] == role`
  (drop the `len(tail) > 1` requirement), so the bare role directory
  itself is included in the own-role allow.
- `core/hooks/tests/run-board-gate-tests.sh`: add regression cases —
  `mkdir`/`rm` on the role's own bare dir (must allow, was the false
  positive) and on a foreign role's bare dir (must stay deny).

## Out of scope
- Any other board-gate rule (R1-R4) or ownership semantics beyond the
  bare-directory case.

## How it will be verified
`bash core/hooks/tests/run-board-gate-tests.sh` — all cases pass,
including the new regression cases.
