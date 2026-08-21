# Survey — issue-234: promote 7 rulebook hooks into core

Scout skip: mechanical (issue text pre-declares `design-research-skip:
mechanical`) — the audit already names exact source files and exact core
targets; no product-shaped exemplar search applies.

## Audit source (tokenmaxxxer/on-the-record, docs/reports/rulebook-hook-audit.md)

`promote` class = 7 rows:
1. `customer-support` PreToolUse -> `record-fields-gate.sh` — already a
   direct ref to core's own file (no local copy exists). No action; note
   only.
2-3. `proposal-shape` plugin (in `implementation-rulebook`):
   `hooks/directive.sh` (UserPromptSubmit) + `hooks/proposal-shape-gate.sh`
   (PreToolUse) -> core target `core/hooks/proposal-shape-gate.sh` (+ its
   directive).
4-5. `record-shape` plugin: `hooks/directive.sh` +
   `hooks/record-shape-gate.sh` -> core target `core/hooks/record-shape-gate.sh`.
6-7. `survey-order` plugin: `hooks/directive.sh` +
   `hooks/survey-order-gate.sh` -> core target `core/hooks/survey-order-gate.sh`.

Fetched verbatim via `gh api repos/tokenmaxxxer/implementation-rulebook/contents/<path>`:
- `proposal-shape/hooks/directive.sh` (40 lines), `proposal-shape/hooks/proposal-shape-gate.sh` (205 lines)
- `record-shape/hooks/directive.sh` (58 lines), `record-shape/hooks/record-shape-gate.sh` (217 lines)
- `survey-order/hooks/directive.sh` (34 lines), `survey-order/hooks/survey-order-gate.sh` (183 lines)

## Current core state

`core/hooks/hooks.json` currently binds only `SessionStart` (directive.sh)
and `PreToolUse` (board-gate.sh, approval-gate.sh, gh-guard.sh,
trailer-gate.sh, record-fields-gate.sh, handbook-trigger-gate.sh). No
`UserPromptSubmit` array exists yet — this issue adds the first one.

`core/hooks/lib/gate-lib.sh` already exports `GATE_LIB_PY`,
`gate_kill_switch_active`, and `gate_reconstruct_write` — all three are
used unmodified by the fetched gate scripts, confirmed by grep of the
fetched sources. No core lib change needed.

Path convention divergence found: the rulebook copies source
`gate-lib.sh` via
`${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}`
(two levels up, matching a `pluginroot/hooks/*.sh` rulebook layout).
Existing core hooks (`record-fields-gate.sh`, `trailer-gate.sh`,
`handbook-trigger-gate.sh`) instead use one level up:
`${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)}`
— because a file already living at `core/hooks/*.sh` is one level, not
two, from `core/`. The fetched scripts need this one-line path fix to
behave correctly once moved into `core/hooks/`; everything else in each
file promotes unmodified (byte-identical logic, verified no other
`../../core` or rulebook-specific string appears — grep checked).

The `record-shape-gate.sh` and `survey-order-gate.sh` sources hardcode
their target path to `docs/issue-<n>/reports/implementation.md` /
`docs/issue-<n>/reports/implementation/survey.md` (the phase-1/phase-2
artifact shape is specific to the two-phase build flow role-handoff
contract v3 s19/s20 defines, which today only `implementation` follows) —
the audit's own promote note says "no per-role parameterization needed"
for this reason: the requirement text is contract-wide, but the artifact
path itself is not per-role generic today. Promoting verbatim preserves
today's exact behavior (the acceptance's own bar), so no path
parameterization is added in this issue — a future issue can generalize
if another role adopts the same proposal/record shape.

## Test conventions found

Two parallel test surfaces exist:
- `core/hooks/tests/*.sh` — the bash harness pattern
  (`run-role-gates-tests.sh` etc.), invoked by
  `core/hooks/tests/run-all.sh`, which the README's "Run the checks"
  section declares as the fast tier (`/bin/bash core/hooks/tests/run-all.sh`).
- top-level `tests/*.py` — pytest files invoking gate scripts via
  `subprocess`, run directly with `python3 -m pytest tests/...` (used by
  issue-163/167/179/183's repro suites; not wired into `run-all.sh`).

Issue-234's frozen scope line names `tests/` (top-level, not
`core/hooks/tests/`) as the only test-writable directory, so this issue's
allow/refuse tests land as a new `tests/test_*.py` file, run via
`python3 -m pytest tests/test_promoted_hooks.py -q` — a real, runnable
fast-tier command consistent with the existing top-level pytest
convention, not the bash harness (which lives under `core/hooks/`, outside
the frozen write set).

## Write set (frozen)

- `core/hooks/proposal-shape-directive.sh` (new)
- `core/hooks/proposal-shape-gate.sh` (new)
- `core/hooks/record-shape-directive.sh` (new)
- `core/hooks/record-shape-gate.sh` (new)
- `core/hooks/survey-order-directive.sh` (new)
- `core/hooks/survey-order-gate.sh` (new)
- `core/hooks/hooks.json` (add `UserPromptSubmit` array + 3 new
  `PreToolUse` entries)
- `tests/test_promoted_hooks.py` (new)
- `docs/issue-234/reports/implementation/survey.md` (this file)
- `docs/issue-234/proposals/2026-08-21-promote-7-rulebook-hooks.md`
