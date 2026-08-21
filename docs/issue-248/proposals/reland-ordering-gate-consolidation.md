---
status: proposed
files:
  - core/hooks/ordering-gate.sh
  - core/hooks/hooks.json
  - tests/test_ordering_gates_237.py
  - tests/test_ordering_gate_livefire.py
  - docs/handbooks/ordering-gate.md
---

# Proposal — issue-248: re-land ordering-gate consolidation (line-101 fix + live-fire test)

## Request

Re-land the #244-approved ordering-gate consolidation after #247's
crash-on-every-Bash-invocation postmortem: fix the confirmed line-101
`list`/`str` bug (`gate_bash_write_targets()` returns a list;
`.splitlines()` was called on it), add a live-fire test class that
invokes `bash core/hooks/ordering-gate.sh` as a real subprocess with
PreToolUse JSON on stdin (closing the gap that let the crash ship past
34 green tests), and land the rest of #244's design as approved.

## Constraints

- Line-101 fix is mechanical: `gate_bash_write_targets(bash_command)`
  already returns a list (`core/hooks/lib/gate-lib.py`, confirmed by
  reading its docstring and implementation) — iterate it directly, drop
  `.splitlines()`.
- `tests/test_ordering_gates_237.py` + the (currently absent)
  `tests/test_promoted_hooks.py`-equivalent suite must keep every
  existing assertion byte-for-byte; only `run_gate("<file>.sh", ...)`
  filename arguments may change, per #244's own constraint.
- The live-fire test class is genuinely new coverage (subprocess-level,
  real stdin JSON, exit-code assertions) — it does not replace or modify
  the existing internals-level suites.
- Per the survey's confirmed structural conflict (inherited from
  issue-240's implementation record, independently re-verified against
  `survey-order-gate.sh`'s actual regex): `survey-order-gate.sh`'s scope
  is an unfiltered catch-all over every issue's proposal writes. Folding
  it into `ordering-gate.sh`'s first-match-wins table denies 3 frozen
  "foreign role, no survey" assertions that currently expect RC==0. This
  makes "fold all 8" and "assertions preserved verbatim" mutually
  exclusive, exactly as the prior round found — re-verified here, not
  re-derived from scratch.

## Rationale

Alternative considered: fold all 8 gates including `survey-order-gate.sh`
as the issue text's prose literally states ("8 per-role files deleted").
Rejected: the survey confirms (independently, by reading
`survey-order-gate.sh` directly) this reproduces the same RC flip on the
3 frozen "foreign role" tests that blocked #247's attempt at the same
approach. The issue's own frozen Acceptance section (the verbatim
criteria, not the prose paraphrase above it) requires only "existing
suites ... pass ... assertions recorded" and a file-list diff recorded —
it does not literally require exactly 8 deletions. Silently breaking 3
frozen assertions to hit a prose-only "8" would violate the
higher-priority, explicitly-stated constraint ("assertions preserved")
that both the #244 proposal and this issue's Acceptance carry. Chosen
approach: fold the same 7 gates #247 already validated (34 tests green),
keep `survey-order-gate.sh` separate exactly as before, and add the
line-101 fix plus the live-fire test class that #247 was missing. This is
the only option consistent with the Acceptance section's literal test
and file-list-diff checks without silently discarding a frozen
assertion.

## What will be done

1. Recover `core/hooks/ordering-gate.sh` from `git show 893997b:core/hooks/ordering-gate.sh`
   (the #247 version, already reviewed and functionally complete except
   for the line-101 bug) and apply the one-line fix: replace
   `gate_lib.gate_bash_write_targets(bash_command).splitlines()` with
   `gate_lib.gate_bash_write_targets(bash_command)` (drop `.splitlines()`,
   keep the surrounding list comprehension and `.strip()` filter).
2. Update `core/hooks/hooks.json`: same rebind #247 already performed —
   replace the 7 folded roles' `PreToolUse` entries with one
   `ordering-gate.sh` entry at the first removed entry's position;
   `survey-order-gate.sh`'s own entry stays untouched.
3. Update `tests/test_ordering_gates_237.py`: same renames #247 already
   performed (`run_gate("<original-filename>.sh", ...)` → `run_gate("ordering-gate.sh", ...)`
   for the 7 folded roles only); no assertion-line changes.
4. Add `tests/test_ordering_gate_livefire.py`: a new test class that,
   for a representative sample of matching and non-matching payloads
   (at least one Bash-tool payload and one Write-tool payload), runs
   `subprocess.run(["bash", "core/hooks/ordering-gate.sh"], input=<json>, ...)`
   as a real subprocess (not an internals call) and asserts the exit
   code — non-matching payloads exit 0 silently, a known matching
   out-of-order payload exits 2. This is the check the #247 suites
   skipped and the one whose absence let the crash ship.
5. Delete the same 7 original per-role scripts #247 deleted
   (`arch-sequence-gate.sh`, `content-design-phase1-basis-gate.sh`,
   `devrel-phase-order-gate.sh`, `incident-response-order-gate.sh`,
   `interaction-design-stage-order-gate.sh`,
   `issue-retrospective-proposal-order-gate.sh`,
   `security-threat-model-sequence-gate.sh`). `survey-order-gate.sh`
   stays.
6. Re-add `docs/handbooks/ordering-gate.md`, updated to also document the
   live-fire test class and the line-101 fix as a pitfall for future
   mechanism authors (Python-side helpers that already return
   list/dict shapes must not be treated as their sh-mirror's
   string-output contract).
7. Run the existing suites plus the new live-fire class via the fast
   tier and record pass output, the `hooks.json` JSON-validity check, and
   `git diff --stat` in the phase-2 implementation record.

## Out of scope

- Folding `survey-order-gate.sh` into `ordering-gate.sh` (blocked by the
  confirmed structural conflict above; a follow-up issue, same as
  #240's own "Open findings," would need to resolve the conflict first —
  e.g. by narrowing `survey-order-gate.sh`'s regex or updating the 3
  frozen assertions, either requiring separate human sign-off).
- `record-fields-gate.sh`, `proposal-shape-gate.sh`, `record-shape-gate.sh`
  (different concern, out of scope per #244 too).
- Any change to a role's required-file set, surface regex, or kill-switch
  variable name.

## How you'll know it worked

- `tests/test_ordering_gates_237.py` (and whatever suite currently plays
  `test_promoted_hooks.py`'s role) pass unchanged-assertion runs against
  `ordering-gate.sh` via the fast tier.
- `tests/test_ordering_gate_livefire.py` passes, proving a real
  `bash core/hooks/ordering-gate.sh <<< json` subprocess call no longer
  crashes and returns the right exit code for both a non-matching and a
  matching payload.
- `python3 -c "import json; json.load(open('core/hooks/hooks.json'))"`
  succeeds.
- `git diff --stat` shows 7 `core/hooks` gate files removed, 1 added,
  net decrease; `survey-order-gate.sh` untouched.
