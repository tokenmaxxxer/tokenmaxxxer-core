# Current-state survey — issue-248: re-land ordering-gate consolidation

## Baseline (post-revert)

`main` / this branch currently carries the pre-#247 state: 8 per-role
gate scripts live under `core/hooks/` (`arch-sequence-gate.sh`,
`content-design-phase1-basis-gate.sh`, `devrel-phase-order-gate.sh`,
`incident-response-order-gate.sh`, `interaction-design-stage-order-gate.sh`,
`issue-retrospective-proposal-order-gate.sh`,
`security-threat-model-sequence-gate.sh`, `survey-order-gate.sh`), each
with its own `hooks.json` `PreToolUse` entry. `core/hooks/ordering-gate.sh`
does not exist on disk. `tests/test_ordering_gates_237.py` and
`tests/test_promoted_hooks.py` call the 8 originals by filename.

The full #244 design (per-role table, first-match-wins dispatch, four
mechanism functions) is already approved and recorded at
`docs/issue-240/proposals/consolidate-ordering-gates.md` — cited here,
not re-derived.

## Root cause of the #247 crash (confirmed)

`core/hooks/lib/gate-lib.py`'s `gate_bash_write_targets(command)` returns
`_BASH_WRITE_TARGET_RE.findall(command)` — a **list** (its own docstring
states this explicitly: "the sh version prints one token per line ...
this returns the equivalent list of tokens"). The #247
`ordering-gate.sh` (recovered via `git show 893997b:core/hooks/ordering-gate.sh`)
has at its line 101:

```python
bash_targets = [t for t in gate_lib.gate_bash_write_targets(bash_command).splitlines() if t.strip()]
```

`.splitlines()` is called on the list return value, not a string —
`AttributeError: 'list' object has no attribute 'splitlines'` on every
Bash tool_input, because `bash_command` is a non-empty string on every
real Bash invocation. The fix is mechanical: drop `.splitlines()` and
iterate the list directly:

```python
bash_targets = [t for t in gate_lib.gate_bash_write_targets(bash_command) if t.strip()]
```

No other line in the #247 script touches this helper.

## Live-fire test gap (confirmed)

`tests/test_ordering_gates_237.py` and `tests/test_promoted_hooks.py`
both call gate internals/functions directly (per their existing
`run_gate("<file>.sh", ...)` harness helper — need to confirm exact
harness shape at build time) rather than shelling out to
`bash core/hooks/ordering-gate.sh` with real PreToolUse JSON on stdin the
way the actual Claude Code harness invokes it. That is exactly why the
line-101 crash shipped past 34 green tests in #247: no test in either
suite exercises the script as a subprocess end-to-end. A new live-fire
test class closes this gap.

## Inherited structural conflict (from #240's implementation record)

`docs/issue-240/reports/implementation.md` (the #247-era record, still
readable via `git show 893997b:...` though the file itself was reverted)
documents a reproduced, unavoidable conflict: `survey-order-gate.sh`'s
scope is a genuine catch-all — `docs/issue-<n>/proposals/*.md` for **any**
issue, not filtered by role (confirmed by reading
`core/hooks/survey-order-gate.sh` directly: its `PROPOSAL_RE` matches any
issue's proposal path, no role-token filter). Folding it into
`ordering-gate.sh`'s first-match-wins table as the broadest fallback rule
causes any foreign-role proposal write with no survey on disk to fall
through every scoped role and hit survey-order's deny — flipping 3 frozen
`tests/test_ordering_gates_237.py` assertions
(`test_arch_sequence_gate_allows_foreign_role_proposal_without_survey` and
its devrel/interaction-design equivalents, each asserting RC==0) from
pass to fail. This is a design-level incompatibility between "fold all 8"
and "assertions preserved verbatim," not a coding bug — re-confirmed here
by direct inspection of `survey-order-gate.sh`'s regex, independent of
the prior record's claim.

## Write set for this issue

- `core/hooks/ordering-gate.sh` (new, ported from the #247 version with
  the line-101 fix)
- `core/hooks/hooks.json` (rebind)
- `tests/test_ordering_gates_237.py` (rename `run_gate()` filename args
  for the 7 folded roles only, per the inherited conflict above)
- A new live-fire test file/class (exact filename decided in the
  proposal)
- `docs/handbooks/ordering-gate.md` (re-add, updated)
- 7 of the 8 original per-role scripts deleted (`survey-order-gate.sh`
  stays, same reason as #247)

## Skip conditions

Not applicable — this survey exists (scout-directive's two skip
conditions are not invoked); the design itself is not re-scouted because
it is already approved (#244) and this issue's own scope is explicitly
the postmortem fix + test-gap closure, not a new design decision.
