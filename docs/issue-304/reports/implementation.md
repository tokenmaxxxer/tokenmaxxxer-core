---
issue: 304
role: implementation
loop_state: landed
upstream:
  - path: core/hooks/lib/gate-lib.sh (gate_kill_switch_active, fixed under issue-72)
    sha: same-commit
code_under_review:
  - core/hooks/lib/role-directive.sh
  - core/hooks/proposal-shape-directive.sh
  - core/hooks/record-shape-directive.sh
  - core/hooks/survey-order-directive.sh
  - core/hooks/tests/run-directive-shape-tests.sh
type: fix
breaking: "no — kill-switch behavior only changes for previously-typo'd/garbage off-var values, which now correctly keep the hook active instead of silently disabling it; every recognized on/off spelling is unchanged"
verdict: pass
---

# issue-304 — implementation record

Build-now bypass (`CORE_BUILD_NOW=1`, contract v3 s19a) — delivered directly,
no phase-1 proposal round. Survey-order skip: pure bugfix propagating an
already-approved fix (issue-72) into 4 files that missed it; no open design
decision.

## What was done

Propagated `gate-lib.sh`'s fixed `gate_kill_switch_active` helper into the
4 directive hooks (F19/F20 from the #301 sweep) that still carried the
pre-fix inline case statement, where any unrecognized value (a typo) in the
kill-switch env var silently disabled the hook instead of only the
recognized on-spellings (`1`/`true`/`yes`/`on`):

- `core/hooks/proposal-shape-directive.sh`
- `core/hooks/record-shape-directive.sh`
- `core/hooks/survey-order-directive.sh`
- `core/hooks/lib/role-directive.sh` (the `core_role_directive` function's
  `<ROLE>_CYCLE_OFF` check — this one used `return 0` instead of `exit 0`
  since it's a function inside a sourced library, not a standalone script)

Each of the three top-level scripts now sources `gate-lib.sh` (with the
canonical `||`-guarded source line, matching `core/hooks/directive.sh`,
`scout/hooks/directive.sh`, and `warrant/hooks/directive.sh`, which already
had the fix) and calls `gate_kill_switch_active "${X_OFF:-}" || exit 0`.
`role-directive.sh` now sources `gate-lib.sh` from its own directory (it
lives next to `gate-lib.sh` under `core/hooks/lib/`) and calls
`gate_kill_switch_active "$off_val" || return 0` inside `core_role_directive`.

Added a drift test to `core/hooks/tests/run-directive-shape-tests.sh` (the
gate named in the issue's Acceptance) covering all 4 files:

- executed-live behavioral checks: kill-switch unset (empty state) keeps
  each hook active; a typo value (`typo-not-a-real-spelling`) keeps each
  hook ACTIVE (this is exactly what the pre-fix code got backwards); the
  exact on-spelling `1` disables each hook.
- a static drift guard: none of the 4 files may contain the hand-rolled
  `*) exit 0 ;;` / `*) return 0 ;;` off-spelling case branch again (matched
  on the joined-line text, so a branch split across physical lines is still
  caught, mirroring `compliance-check.sh`'s own detector), and each file
  must call `gate_kill_switch_active`.

## Why

`gate_kill_switch_active` (gate-lib.sh) was already fixed under issue-72 to
fail-active on any unrecognized value; the 3 sibling `*-directive.sh` hooks
already carried explanatory comments describing that fixed behavior, but
their actual `case` statements still implemented the pre-fix logic — the
comment and the code had drifted apart. `role-directive.sh` never got a
comment update either. Replacing the 4 inline copies with the shared helper
removes the drift source entirely: there is now exactly one place
(`gate-lib.sh`) that defines what counts as an off-spelling, matching the
pattern the other 3 already-correct directive hooks (`core`, `scout`,
`warrant`) use.

`compliance-check.sh` (issue-142's generic drift detector) already flags
this exact shape — `reads a *_OFF kill-switch env var but does not call
gate_kill_switch_active` and `contains a hand-rolled '*) exit 0 ;;' case
branch` — for any hooks.json-wired script. Running it against `core/hooks`
itself (`bash core/hooks/tests/compliance-check.sh core/hooks`) confirmed it
already catches 3 of the 4 files for free; that generic check was just never
run against core's own tree in the test suite, which is how this drift
shipped and sat unnoticed. `role-directive.sh` is a library sourced by
other repos' own `directive.sh` stubs, not itself wired into
`core/hooks/hooks.json`, so `compliance-check.sh`'s hooks.json-driven scan
cannot reach it — its case also uses `return 0`, not `exit 0`, so even a
generic re-scan wouldn't match `compliance-check.sh`'s existing regex.
The new drift test in `run-directive-shape-tests.sh` is self-contained
(behavioral + a joined-line static check covering both the `exit 0` and
`return 0` shapes) specifically so it also covers `role-directive.sh`
without depending on `compliance-check.sh`'s hooks.json-registration scope.

## What did not work

None.

## Upstream basis

`core/hooks/lib/gate-lib.sh`'s `gate_kill_switch_active` (already fixed,
unchanged by this commit) is the shared helper being propagated; it ships
in this same commit's tree (`same-commit`). The already-correct sibling
examples (`core/hooks/directive.sh`, `scout/hooks/directive.sh`,
`warrant/hooks/directive.sh`) were used as the template for the source-line
idiom.

## Post-approval rebase (PR #307 merge conflict)

By the time PR #307 was reviewed, `main` had advanced with 4 issue-304
review/observation commits (`conformance-review` phase 1/2,
`execution-observation`) that documented and graded this PR's diff but
never actually merged it — the fix itself was still only on this branch.
Because both `main` and this branch independently touched the same 5 files
(`core/hooks/lib/role-directive.sh`, the 3 sibling `*-directive.sh` hooks,
`core/hooks/tests/run-directive-shape-tests.sh`) with no common ancestor
commit containing them (this repo squash-merges, so the branch's commit
graph and `main`'s diverge even where content matches), `git merge
origin/main` reported all 5 as add/add conflicts. Diffing each side showed
`main`'s copies were still the pre-fix inline `case` statements — the
review commits describe the fix but `main` had never received it — so every
conflict was resolved by keeping this branch's (`--ours`) fixed content.
Merge commit `5c93962`; pushed; re-ran the named gate to confirm:

```
$ bash core/hooks/tests/run-directive-shape-tests.sh 2>&1 | tail -3
directive-shape: 31 passed, 0 failed
```

`gh pr view 307 --json mergeable,mergeStateStatus` went from
`CONFLICTING`/`DIRTY` to `MERGEABLE`/`CLEAN` after the push.

## Open findings

None.

## Next steps

None — loop_state: landed.

## Acceptance evidence

Gate: `core/hooks/tests/run-directive-shape-tests.sh`.

```
$ bash core/hooks/tests/run-directive-shape-tests.sh
ok     names spec-index regeneration before docs/specs edits        present
ok     names the Closes/Fixes phase split for non-coding roles      present
ok     names verify-at-landing and pasted-output fidelity           present
ok     cites no phantom enforcement scripts                         absent
ok     states the phase contract conditionally (default + checkpoint) present
ok     empty-state fixture (no spec-index rule) has no spec_index.py mention absent
ok     empty-state fixture (no phase-split rule) has no plain #<issue> mention absent
ok     empty-state fixture (no test-claim rule) has no SKIPPED mention absent
ok     bypass fixture (disconnected bullets) is not accepted as the phase-split rule absent
ok     names the build-now bypass and its spawner-only env var      present
ok     empty-state fixture (no build-now rule) has no CORE_BUILD_NOW mention absent

--- issue-304: kill-switch drift, executed live ---
ok     proposal-shape-directive.sh: kill-switch unset (empty state) — hook active present
ok     proposal-shape-directive.sh: typo value in $PROPOSAL_SHAPE_OFF keeps hook ACTIVE (was: disabled) present
ok     proposal-shape-directive.sh: exact '1' in $PROPOSAL_SHAPE_OFF disables hook absent
ok     record-shape-directive.sh: kill-switch unset (empty state) — hook active present
ok     record-shape-directive.sh: typo value in $RECORD_SHAPE_OFF keeps hook ACTIVE (was: disabled) present
ok     record-shape-directive.sh: exact '1' in $RECORD_SHAPE_OFF disables hook absent
ok     survey-order-directive.sh: kill-switch unset (empty state) — hook active present
ok     survey-order-directive.sh: typo value in $SURVEY_ORDER_OFF keeps hook ACTIVE (was: disabled) present
ok     survey-order-directive.sh: exact '1' in $SURVEY_ORDER_OFF disables hook absent
ok     role-directive.sh: kill-switch unset (empty state) — hook active present
ok     role-directive.sh: typo value in $IMPLEMENTATION_CYCLE_OFF keeps hook ACTIVE (was: disabled) present
ok     role-directive.sh: exact '1' in $IMPLEMENTATION_CYCLE_OFF disables hook absent
ok     proposal-shape-directive.sh: no hand-rolled '*) exit|return 0 ;;' off-spelling branch (drift guard) absent
ok     proposal-shape-directive.sh: calls gate_kill_switch_active   present
ok     record-shape-directive.sh: no hand-rolled '*) exit|return 0 ;;' off-spelling branch (drift guard) absent
ok     record-shape-directive.sh: calls gate_kill_switch_active     present
ok     survey-order-directive.sh: no hand-rolled '*) exit|return 0 ;;' off-spelling branch (drift guard) absent
ok     survey-order-directive.sh: calls gate_kill_switch_active     present
ok     role-directive.sh: no hand-rolled '*) exit|return 0 ;;' off-spelling branch (drift guard) absent
ok     role-directive.sh: calls gate_kill_switch_active             present

directive-shape: 31 passed, 0 failed
```

Empty state (kill-switch unset, all four hooks active, unchanged) is the
first behavioral assertion per file above ("kill-switch unset (empty
state) — hook active", 4/4 present).

Supporting evidence — `compliance-check.sh` (issue-142's existing generic
drift detector) run against `core/hooks` itself, before and after the fix:

```
$ git stash
$ bash core/hooks/tests/compliance-check.sh core/hooks
compliance-check: ok — .../core/hooks/directive.sh
compliance-check: ok — .../core/hooks/pretooluse-dispatcher.sh
compliance-check: FAIL — .../core/hooks/proposal-shape-directive.sh:
  - reads a *_OFF kill-switch env var but does not call gate_kill_switch_active — likely a hand-rolled case statement with the confirmed fail-open bug (unrecognized value disables the gate)
  - contains a hand-rolled '*) exit 0 ;;' case branch — the issue-72-confirmed fail-open kill-switch idiom (any unrecognized value silently disables the hook), even alongside a canonical gate_kill_switch_active call elsewhere in the file; remove the hand-rolled case statement and rely on gate_kill_switch_active (gate-lib.sh) exclusively
compliance-check: FAIL — .../core/hooks/record-shape-directive.sh: (same two reasons)
compliance-check: FAIL — .../core/hooks/survey-order-directive.sh: (same two reasons)
$ git stash pop
$ bash core/hooks/tests/compliance-check.sh core/hooks
compliance-check: ok — .../core/hooks/directive.sh
compliance-check: ok — .../core/hooks/pretooluse-dispatcher.sh
compliance-check: ok — .../core/hooks/proposal-shape-directive.sh
compliance-check: ok — .../core/hooks/record-shape-directive.sh
compliance-check: ok — .../core/hooks/survey-order-directive.sh
```

Regression check — full `core/hooks/tests/run-gate-lib-tests.sh`, before
and after (CORE_BUILD_NOW unset either way, so this session's own ambient
value can't skew it):

```
$ git stash && env -u CORE_BUILD_NOW bash core/hooks/tests/run-gate-lib-tests.sh 2>&1 | tail -3
gate-lib: 63 passed, 3 failed
$ git stash pop && env -u CORE_BUILD_NOW bash core/hooks/tests/run-gate-lib-tests.sh 2>&1 | tail -3
gate-lib: 64 passed, 2 failed
```

The fix turns one of those 3 pre-existing failures into a pass; the
remaining 2 (`record-fields-gate.sh` §20-fields / `RECORD_FIELDS_GATE_OFF`
cases) are pre-existing and out of scope — unrelated to any of the 4 files
this issue targets, present identically before and after this change.

Also ran, unaffected by this change:

```
$ bash core/hooks/tests/run-role-gates-tests.sh 2>&1 | tail -3
role-gates: 83 passed, 0 failed

$ env -u CORE_BUILD_NOW bash core/hooks/tests/run-approval-gate-tests.sh 2>&1 | tail -3
== 66 passed, 0 failed ==
```

(The full `run-all.sh` run under this session's own ambient
`CORE_BUILD_NOW=1` shows the same 2 pre-existing `approval-gate` failures
documented in prior sessions' records, issue-288/290/295, as an artifact of
that ambient env leaking into subprocess tests — not a regression from this
change — plus one pre-existing, environment-timing-dependent dispatcher
latency flake unrelated to any file this issue touches.)

skill-verdict: work-in-english — applied: invoked; used for this record, commit messages, and PR body (task communicated partly in Korean) | other mounted skills: not triggered (mechanical propagation of an already-existing, already-proven fix into 4 files — no coupling/cohesion threshold, no GoF pattern decision, no data-structure/algorithm choice, and no multi-module structural decision needing implementation-blueprint).
