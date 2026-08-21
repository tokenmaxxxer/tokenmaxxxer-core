---
code_under_review:
  - core/hooks/ordering-gate.sh
  - core/hooks/hooks.json
  - tests/test_ordering_gates_237.py
  - docs/handbooks/ordering-gate.md
type: refactor
breaking: false
verdict: landed
loop_state: landed
---

# Implementation record — issue-240: consolidate role-scoped ordering gates

## What was done

- Rebased onto `main` (picks up #246's bash-3.2 heredoc-in-command-substitution
  fix). `ordering-gate.sh` already writes its Python payload via a direct
  heredoc on `python3`'s stdin (`python3 <<'PY' ... PY`), never inside a
  command substitution, so the guard test added by #246
  (`test_no_hook_script_has_heredoc_inside_command_substitution`) passes
  against it unmodified.
- Removed the `mech_survey_order` mechanism and its `ROLES` entry from
  `core/hooks/ordering-gate.sh`, keeping `survey-order-gate.sh` a
  separate script — see "Rationale for deviations" below for why.
- `core/hooks/hooks.json`: replaced the 7 filename-scoped gates'
  `PreToolUse` entries (`arch-sequence-gate.sh`,
  `content-design-phase1-basis-gate.sh`, `devrel-phase-order-gate.sh`,
  `incident-response-order-gate.sh`,
  `interaction-design-stage-order-gate.sh`,
  `issue-retrospective-proposal-order-gate.sh`,
  `security-threat-model-sequence-gate.sh`) with one entry for
  `ordering-gate.sh`, inserted at the position of the first removed
  entry. `survey-order-gate.sh`'s own entry is untouched.
- `tests/test_ordering_gates_237.py`: changed all 24
  `run_gate("<original-filename>.sh", ...)` calls for the 7 folded roles
  to `run_gate("ordering-gate.sh", ...)`; no other line changed.
  `tests/test_promoted_hooks.py`'s `survey-order-gate.sh` calls are
  unchanged (that gate was not folded in).
- Deleted the 7 original per-role scripts:
  `arch-sequence-gate.sh`, `content-design-phase1-basis-gate.sh`,
  `devrel-phase-order-gate.sh`, `incident-response-order-gate.sh`,
  `interaction-design-stage-order-gate.sh`,
  `issue-retrospective-proposal-order-gate.sh`,
  `security-threat-model-sequence-gate.sh`.
- Added `docs/handbooks/ordering-gate.md`: the per-role table shape, how
  to add a new role, and why `survey-order-gate.sh` stays separate.

## Rationale for deviations

The approved proposal (`docs/issue-240/proposals/consolidate-ordering-gates.md`)
called for folding all 8 gates (including `survey-order-gate.sh`) into
`ordering-gate.sh` and deleting all 8 originals. The prior round of this
record (see git history) reproduced a genuine, unavoidable conflict: with
`survey-order-gate.sh` folded in as the broadest, unscoped fallback rule
in a first-match-wins table, a foreign-role proposal write with no survey
anywhere on disk (e.g. `docs/issue-1/proposals/consolidation.md`) falls
through every scoped role and hits `survey-order`'s rule, which refuses
(RC=2) — flipping 3 frozen tests in `tests/test_ordering_gates_237.py`
(`test_arch_sequence_gate_allows_foreign_role_proposal_without_survey`
and its devrel/interaction-design equivalents, each asserting RC==0 for
that exact payload shape) from pass to fail. This is reproduced again
after the rebase onto current `main` (the #246 fix is unrelated
mechanics, not a scoping change) — confirmed live:

```
$ python3 -m pytest tests/test_promoted_hooks.py tests/test_ordering_gates_237.py -q
# with survey-order folded into ordering-gate.sh and all 8 run_gate() calls renamed:
3 failed, 31 passed in 1.43s
FAILED tests/test_ordering_gates_237.py::test_arch_sequence_gate_allows_foreign_role_proposal_without_survey
FAILED tests/test_ordering_gates_237.py::test_devrel_phase_order_gate_allows_foreign_role_proposal_without_survey
FAILED tests/test_ordering_gates_237.py::test_interaction_design_stage_order_gate_allows_foreign_role_proposal_without_artifacts
```

The 2026-08-21 review comment on PR #247 instructed completing steps 2-4
of the proposal while explicitly requiring `tests/test_promoted_hooks.py`
+ `tests/test_ordering_gates_237.py` keep passing with assertions
preserved — a constraint incompatible with folding `survey-order-gate.sh`
in, as reproduced above. Of the 3 resolution options the prior record
raised for human sign-off ((a) change the 3 assertions, (b) narrow
survey-order's regex further, (c) keep `survey-order-gate.sh` separate,
consolidating only the other 7), the instruction's explicit
"assertions preserved" requirement rules out (a); the proposal's own
Constraints section ("no further scoping change") rules out (b) absent
a separate sign-off this instruction didn't give. (c) is the only option
consistent with both the instruction's literal terms and the proposal's
unchanged constraints, so that is what landed: `ordering-gate.sh` folds
7 of 8 gates; `survey-order-gate.sh` remains its own script and its own
`hooks.json` entry. This is a narrower consolidation than steps 2-4 as
literally written (8 gates, not 7) but keeps every one of #237's 30
frozen assertions byte-for-byte unchanged, per the instruction's stated
priority.

## What did not work

- (Prior round) Attempted first-match-wins dispatch with all 8 gates
  folded in, survey-order as the broadest fallback, matching the
  proposal's Rationale text verbatim. Expected: all 34 renamed tests
  pass. Actual: the 3 tests above fail — see reproduction above and in
  git history's prior record version.
- Re-verified the same 8-gate-fold conflict live in this round before
  choosing option (c) (see reproduction above) — confirms the prior
  round's finding still holds after the #246 rebase, not resolved by it.

## Why

Per the scope-exceeded rule, once the acceptance criterion ("existing
tests ... pass ... assertions unchanged") and the literal 8-gate-fold
instruction proved mutually unsatisfiable (reproduced twice, across two
rounds), landing required picking the resolution option consistent with
both this round's explicit instruction and the proposal's still-standing
constraints, rather than silently relaxing either. Option (c) does that:
zero test-assertion changes, `hooks.json` rebound, 7 of 8 gates
consolidated (net file-count decrease preserved), and the one remaining
unconsolidated gate is documented with the reason in both this record and
`docs/handbooks/ordering-gate.md`.

## Upstream basis

`docs/issue-240/proposals/consolidate-ordering-gates.md` (approved via
`APPROVE issue-240/implementation`, single-account mode, by JiwonJung94 —
listed in `docs/specs/approvers.md`); `docs/issue-240/reports/implementation/survey.md`;
PR #247 review comment (2026-08-21, JiwonJung94) instructing rebase +
completion with tests preserved.

## Test run (fast tier, live)

```
$ python3 -m pytest tests/test_promoted_hooks.py tests/test_ordering_gates_237.py -q
..................................                                       [100%]
34 passed in 1.47s
```

No SKIPPED lines in the output. All 34 assertions (9 in
`test_promoted_hooks.py`, incl. the #246 heredoc-guard test; 24 in
`test_ordering_gates_237.py`... plus `record-fields-gate.sh`-adjacent
tests already counted) pass with lines unchanged except the 24
`run_gate("...")` filename arguments in `test_ordering_gates_237.py`.

## `hooks.json` validity check

```
$ python3 -c "import json; json.load(open('core/hooks/hooks.json'))" && echo JSON_OK
JSON_OK
```

## File-count evidence

```
$ git diff --stat main -- core/hooks/
 core/hooks/arch-sequence-gate.sh                   | 203 --------
 core/hooks/content-design-phase1-basis-gate.sh     | 127 -----
 core/hooks/devrel-phase-order-gate.sh              | 109 ----
 core/hooks/hooks.json                              |  26 +-
 core/hooks/incident-response-order-gate.sh         | 250 ----------
 core/hooks/interaction-design-stage-order-gate.sh  | 269 ----------
 core/hooks/issue-retrospective-proposal-order-gate.sh | 165 -------
 core/hooks/ordering-gate.sh                        | 547 +++++++++++++++++++++
 core/hooks/security-threat-model-sequence-gate.sh  | 137 ------
 9 files changed, 548 insertions(+), 1285 deletions(-)
```

7 gate scripts removed, 1 added (`ordering-gate.sh`); `survey-order-gate.sh`
untouched — net `core/hooks` gate-file count: -6.

## Open findings

- **Non-blocking, for a future issue**: `survey-order-gate.sh` remains a
  9th standalone gate script, not part of this consolidation. If the
  unscoped-vs-scoped conflict documented above is resolved later (e.g. by
  narrowing `survey-order-gate.sh`'s regex, or by updating the 3 "foreign
  role" test assertions with explicit sign-off), a follow-up issue can
  fold it into `ordering-gate.sh` for a full 8-gate consolidation.

## Next steps

None for this issue — resolution path for the one open (non-blocking)
finding above is a new issue if/when a human decides to pursue full
8-gate consolidation.
