---
subject: issue-72
role: implementation
code_under_review: core/hooks/lib/gate-lib.sh, core/hooks/lib/gate-lib.py, core/hooks/tests/run-gate-lib-tests.sh, core/hooks/tests/compliance-check.sh, core/hooks/approval-gate.sh, core/hooks/board-gate.sh, core/hooks/directive.sh, core/hooks/gh-guard.sh, core/hooks/trailer-gate.sh, core/hooks/record-fields-gate.sh, core/hooks/handbook-trigger-gate.sh, core/hooks/tests/canon-manifest.txt, docs/handbooks/gate-house-standard.md
loop_state: landed
---

# Record — gate-house standard canonization (phase 2)

## What was done

Built the gate-house standard the approved proposal
(`docs/issue-72/proposals/2026-08-01-gate-house-standard-canonization.md`)
specified:

- `core/hooks/lib/gate-lib.sh` — sourceable bash library: `gate_trap_fail_closed`,
  `gate_kill_switch_active`, `gate_deny`/`gate_allow`, `gate_bash_write_targets`.
- `core/hooks/lib/gate-lib.py` — Python helper loaded via `importlib`:
  `gate_parse_json_or_deny`, `gate_normalize_path`, `gate_reconstruct_write`
  (full `Write`/`Edit`/`MultiEdit`/`NotebookEdit` reconstruction honoring
  `replace_all`).
- Migrated all seven `core/hooks/*.sh` gates (`approval-gate.sh`,
  `board-gate.sh`, `directive.sh`, `gh-guard.sh`, `trailer-gate.sh`,
  `record-fields-gate.sh`, `handbook-trigger-gate.sh`) to source
  `gate-lib.sh` and call `gate_kill_switch_active` instead of their own
  inline `case` statement.
- Fixed `record-fields-gate.sh`'s reconstruction to call
  `gate_lib.gate_reconstruct_write`, closing the confirmed `replace_all`-
  ignored bug and adding `NotebookEdit` coverage (previously unhandled).
- `core/hooks/tests/run-gate-lib-tests.sh` — the mandatory six-case-group
  harness (replace_all-edit, multiedit-replace_all, malformed-json,
  kill-switch, absolute-path, bash-write-coverage), plus end-to-end
  `record-fields-gate.sh` assertions, a `compliance-check.sh` self-test,
  and a `stub-check.sh` manifest-catch assertion. 28/28 passing.
- `core/hooks/tests/compliance-check.sh` — the stub-check.sh-modeled
  compliance detector: flags a gate reading a `*_OFF` var without calling
  `gate_kill_switch_active`, and a gate reconstructing content via its own
  `.replace(old, new[, 1])` instead of `gate_reconstruct_write`. Verified
  clean against core's own seven migrated gates and correctly flags a
  synthetic hand-rolled fixture.
- `core/hooks/tests/canon-manifest.txt` — added `gate-lib.sh`, `gate-lib.py`,
  `compliance-check.sh`, so `stub-check.sh` catches a vendored copy of any
  of the three (asserted in the new harness).
- `docs/handbooks/gate-house-standard.md` — the 43-repo migration path
  document: what the library provides, the two core-canon bugs it fixed,
  the six mandatory test groups, `compliance-check.sh`'s invocation model,
  and the five-step per-repo migration checklist.

## Why

Issue #72's audit found the same six defect classes recurring across the
43 rulebook repos because every rulebook maintained its own copy of the
gate logic instead of referencing shared canon — the exact drift pattern
`docs/handbooks/canon-scripts.md` and `stub-check.sh` already exist to
stop for five other files. `gate-lib.sh`/`gate-lib.py` extend that
reference-not-copy model to gate internals; `compliance-check.sh` extends
`stub-check.sh`'s detection model to catch a gate that hand-rolls what the
library already provides instead of calling it. Full rationale, including
the two rejected alternatives (per-repo independent fixes; a lint-only
detector with no runtime library), is in the phase-1 proposal.

## Upstream basis

`docs/issue-72/proposals/2026-08-01-gate-house-standard-canonization.md`
(approved via issue-level comment `APPROVE issue-72/implementation` from
`JiwonJung94`, an `docs/specs/approvers.md`-listed account — single-account
path), built on findings in
`docs/issue-72/reports/implementation/survey.md`.

## Doc-placement ladder

- [x] `core/hooks/lib/gate-lib.sh`, `core/hooks/lib/gate-lib.py` —
  src-equivalent canon code, under `core/hooks/lib/` alongside the existing
  `role-directive.sh` precedent.
- [x] `core/hooks/tests/run-gate-lib-tests.sh`,
  `core/hooks/tests/compliance-check.sh` — under `core/hooks/tests/`
  alongside the existing `run-*-tests.sh`/`stub-check.sh` siblings.
- [x] `core/hooks/tests/canon-manifest.txt` — updated in place, not a new
  file.
- [x] `docs/handbooks/gate-house-standard.md` — standing handbook bucket
  (component-operational documentation, per §21's handbook-trigger
  convention), not under `docs/issue-72/`, since it is meant to outlive
  this issue and be linked from all 43 remediation issues.
- [x] `docs/issue-72/reports/implementation.md` — this record, the
  role's own phase-2 deliverable home.

## What did not work

None. The kill-switch fix required correcting the library's own first
draft mid-session (see "Rationale for deviations" below) — that was
caught by the new test harness before landing, not a dead end that
survived.

## Rationale for deviations

The proposal's "What will be done" describes `gate_kill_switch_active`
only at the outcome level ("only a recognized off-spelling disables;
every other value... returns active"), matching the *existing* idiom's
matched-branch semantics. Implementing that literally
(`""|0|false|no|off` stays active, `*` disables) reproduces the exact bug
the proposal names, because the original code's wildcard branch already
covered both the intended on-spellings (`1`/`true`/`yes`/`on`) and
unrecognized garbage identically. The first draft of
`gate_kill_switch_active` copied this shape and failed its own new test
(`kswitch 1 "1" "'1' -> active"` came back disabled, and
`kswitch 1 "banana" -> active` also failed under the literal reading).
The fix — narrowing the *disabling* set to only the recognized
on-spellings (`1`/`true`/`yes`/`on`), so empty/off-spellings/unrecognized
values all stay active — is what the proposal's stated acceptance
criterion ("`CORE_OFF=banana` ... leaves the gate active") actually
requires; the proposal text's literal case-list was underspecified on
this point, not a scope change. All 28 harness assertions pass with the
corrected semantics, including every one of the acceptance criteria the
proposal lists under "How you'll know it worked."

## Next steps

None — this record is terminal (`loop_state: landed`). Downstream:
the 43 per-repo A+ remediation issues cite
`docs/handbooks/gate-house-standard.md` per this issue's stated ordering
constraint; no further work in this repo is required for issue #72
itself.

## Open findings

None outstanding. `gate_normalize_path` (Python) is pure path-algebra,
deliberately not doing filesystem `realpath`/symlink resolution itself
(documented in its own docstring) — a gate needing symlink-safe
resolution against a live filesystem still realpaths its own root before
calling it, the same division of labor `record-fields-gate.sh`'s
`resolve()` already had. Not a gap: no current core gate needs
symlink resolution inside `gate_normalize_path` itself, and the docstring
states the contract so a future caller isn't surprised.
