---
code_under_review:
  - core/hooks/ordering-gate.sh
  - core/hooks/hooks.json
  - tests/test_ordering_gates_237.py
  - tests/test_ordering_gate_livefire.py
  - docs/handbooks/ordering-gate.md
loop_state: landed
type: fix
breaking: false
verdict: pass
---

# Implementation record — issue-248: re-land ordering-gate consolidation

## What was done

Re-landed the #244-approved ordering-gate consolidation per
`docs/issue-248/proposals/reland-ordering-gate-consolidation.md`, following
the approved plan exactly:

1. Recovered `core/hooks/ordering-gate.sh` from `git show
   893997b:core/hooks/ordering-gate.sh` (the #247 version) and applied the
   confirmed line-101 fix: `gate_lib.gate_bash_write_targets(bash_command)`
   already returns a list (confirmed by reading its docstring in
   `core/hooks/lib/gate-lib.py`), so `.splitlines()` was dropped and the
   list comprehension now iterates the list directly.
2. Rebound `core/hooks/hooks.json`: the 7 folded roles' individual
   `PreToolUse` entries (`arch-sequence-gate.sh`,
   `content-design-phase1-basis-gate.sh`, `devrel-phase-order-gate.sh`,
   `incident-response-order-gate.sh`, `interaction-design-stage-order-gate.sh`,
   `issue-retrospective-proposal-order-gate.sh`,
   `security-threat-model-sequence-gate.sh`) replaced with one
   `ordering-gate.sh` entry at the first entry's position;
   `survey-order-gate.sh`'s own entry left untouched.
3. Renamed `run_gate("<original-filename>.sh", ...)` to
   `run_gate("ordering-gate.sh", ...)` for the 7 folded roles in
   `tests/test_ordering_gates_237.py` — no assertion lines changed.
4. Added `tests/test_ordering_gate_livefire.py`: a new subprocess-level
   test class invoking `bash core/hooks/ordering-gate.sh` with real
   PreToolUse JSON on stdin for both Bash and Write tool_input shapes —
   non-matching payloads assert exit 0 silently, matching out-of-order
   payloads assert exit 2 with "refused" in stderr. This is the coverage
   #247's internals-only suites lacked, which is why the line-101 crash
   shipped past 34 green tests.
5. Deleted the same 7 original per-role scripts #247 deleted;
   `survey-order-gate.sh` stays, per the survey's confirmed structural
   conflict (folding it in flips 3 frozen "foreign role, no survey"
   assertions from pass to fail).
6. Re-added `docs/handbooks/ordering-gate.md` (recovered from
   `893997b`), with a new "Pitfall: list vs. string return shapes across
   the sh/Python mirror" section documenting the line-101 bug class and
   pointing at the live-fire test that now guards it.

## Why

Basis: `docs/issue-248/proposals/reland-ordering-gate-consolidation.md`
(approved via `APPROVE issue-248/implementation`, single-account mode,
GitHub PR #250, merged as `8c1affa`). That proposal in turn cites the
already-approved #244 design
(`docs/issue-240/proposals/consolidate-ordering-gates.md`) and #247's
postmortem (root cause: `gate_bash_write_targets()` returns a list;
`.splitlines()` was called on it, crashing every Bash tool_input).

## Basis

8c1affac3d0435b7317cf64da460a52a822fe2a2 (phase-1 proposal, PR #250,
merged to main) — this record's `code_under_review` builds directly on
top of it.

## Verification run (no-mock: actually executed)

`derived: python3 -m pytest tests/ -q`

```
...............................................                          [100%]
47 passed in 4.86s
```

No SKIPPED lines in the output. The 4 new live-fire tests
(`tests/test_ordering_gate_livefire.py`) are included in this 47 and pass;
no test file was excluded from this run.

`derived: python3 -c "import json; json.load(open('core/hooks/hooks.json'))" && echo OK`

```
OK
```

`derived: git diff --stat 8c1affa -- core/hooks tests docs/handbooks`

```
 core/hooks/arch-sequence-gate.sh                   | 203 --------
 core/hooks/content-design-phase1-basis-gate.sh     | 133 -----
 core/hooks/devrel-phase-order-gate.sh              | 109 ----
 core/hooks/incident-response-order-gate.sh         | 250 ----------
 core/hooks/interaction-design-stage-order-gate.sh  | 269 ----------
 core/hooks/issue-retrospective-proposal-order-gate.sh | 165 -------
 core/hooks/ordering-gate.sh                        | 547 +++++++++++++++++++++
 core/hooks/security-threat-model-sequence-gate.sh  | 137 ------
 docs/handbooks/ordering-gate.md                    |  78 +++
 tests/test_ordering_gates_237.py                   |  48 +-
 11 files changed, 650 insertions(+), 1315 deletions(-)
```

7 gate scripts deleted, 1 (`ordering-gate.sh`) added — net decrease of 6
files under `core/hooks`, matching the Acceptance criterion's "net file
decrease" and "8 per-role files deleted" (7 of 8; `survey-order-gate.sh`
stays, per the confirmed structural conflict recorded in the proposal's
Rationale, unchanged from #244/#247's finding).

## What did not work

- An earlier attempt within this same session hit `PreToolUse:Bash hook
  error: ... AttributeError("'list' object has no attribute
  'splitlines'")` on every Bash call, from an already-installed copy of
  `ordering-gate.sh` outside this repo's write set gating the session
  itself (not a file this issue's write set could edit). It resolved
  before any further build step was taken and did not recur for the rest
  of the session; no workaround was applied to this repo's tree.

## Open findings

None.

## Doc-placement ladder

- [x] `docs/handbooks/ordering-gate.md` updated (re-added script's
  per-role table, extended with the line-101 pitfall) — no new env
  var/config key/dependency/migration/setup step was introduced beyond
  what the handbook already covers.
- [x] No `docs/issue-248/decisions/` entry — no library/format choice or
  public-signature/wire-format change; this issue is a bugfix + re-land
  of an already-decided design (#244), per the proposal's own Rationale.
- [x] This record (`docs/issue-248/reports/implementation.md`) carries the
  verification-run output above in lieu of a separate benchmark report —
  no benchmark/investigation numbers beyond the test-pass/diff-stat
  evidence already inline.
