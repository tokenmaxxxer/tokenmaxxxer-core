---
code_under_review:
  - warrant/hooks/scope-gate.sh
  - warrant/hooks/hunt-guard.sh
  - core/hooks/trailer-gate.sh
  - tests/test_silent_failure_repros.py
loop_state: phase-2-complete
---

# Implementation record — issue-167

Phase 2 execution of the approved proposal
`docs/issue-167/proposals/2026-08-08-fix-163-defects.md` (approved via
`APPROVE issue-167/implementation` issue comment, contract v3 s19
single-account mode). Fixes A4, A2, A5 per the proposal's
`## What will be done`; basis is the phase-1 survey
`docs/issue-167/reports/implementation/survey.md` and issue #167.

## What was done
- `warrant/hooks/scope-gate.sh`: Bash branch's default-allow replaced with
  a narrow read-only allowlist; anything not on it falls through without
  emitting `permissionDecision: allow`.
- `warrant/hooks/hunt-guard.sh`: agent-type check now matches either
  `warrant-hunter` or `warrant:warrant-hunter`.
- `core/hooks/trailer-gate.sh`: commit-verb regex now runs against a
  quote-collapsed copy of the command (adjacent `""`/`''` stripped) before
  matching.
- `tests/test_silent_failure_repros.py`: A2/A4/A5 assertions flipped to
  demonstrate the fixed behavior; existing control assertions kept.

## What did not work
- Expected: proposal's stated `re.sub(r"(?:''|\"\")+", "", command)`
  adjacent-empty-quote-pair strip would close A5. Actual: warrant-hunter's
  before-landing hunt (stance 0, "assume the gate just touched is
  bypassable") found it misses single-char quote-splitting
  (`git c'o'm'm'i't`), which shell-concatenates to `git commit` the same
  way `git commi""t` does but isn't an adjacent-*empty*-pair. Replaced with
  a general quote-character strip (mapped back to original offsets so the
  downstream `-m` payload resolver still runs against the real, quoted
  text) in `core/hooks/trailer-gate.sh`; added a regression case to
  `test_A5_...` for the single-char-split form. Still within the frozen
  write set — no scope widening.

## Open findings
resolved_findings:
  - finder: warrant-hunter (before-landing, stance 0)
    record: docs/reports/2026-08-08-hunt-fix-163-defects.md
    finding: trailer-gate.sh's quote-collapse regex only stripped adjacent
      empty quote pairs, missing single-char quote-splitting
      (`git c'o'm'm'i't`)
    resolution: generalized to strip all quote characters with an
      offset map back to the original command, in
      core/hooks/trailer-gate.sh; regression case added to
      tests/test_silent_failure_repros.py::test_A5_...
    status: fixed, re-verified green (full repro suite + both gate suites)
None further. Resolution path: n/a — no other open findings.

## Doc placement
- No new env var / config key / dependency / migration — no doctrine-ladder
  trigger applies.
- No public signature/wire-format change beyond what the phase-1
  proposal's `## Rationale` already recorded — no new
  `docs/issue-167/decisions/` entry needed.

## Hunt cadence
- Before-landing dispatch: warrant-hunter, stance 0 ("assume the gate just
  touched is bypassable — find the bypass"), 120s cap, default tier.
  Result: FINDING (trailer-gate quote-collapse gap, see Open findings
  above) — resolved before landing, gate suites re-verified green after
  the fix. Record: docs/reports/2026-08-08-hunt-fix-163-defects.md.

## Next steps
- None — closing issue #167 via this PR.
