---
code_under_review:
  - core/hooks/ordering-norm-gate.sh
  - core/hooks/ordering-norm-config.json
  - core/hooks/hooks.json
  - core/hooks/tests/run-ordering-norm-gate-tests.sh
  - core/hooks/tests/run-all.sh
type: feature
breaking: false
verdict: none
loop_state: landed
---

# Implementation record — issue #257 (phase-4b-2: ordering-norm-gate fold)

## What was done

Delivered the approved phase-1 proposal
(`docs/issue-257/proposals/ordering-norm-gate-fold.md`, approved via
`APPROVE issue-257/implementation` on the issue): folded all 18
classification-report rows / 15 distinct source files of the
`ordering-methodology` family into one parameterized
`core/hooks/ordering-norm-gate.sh`, config-driven off
`core/hooks/ordering-norm-config.json`, registered in
`core/hooks/hooks.json` under `PreToolUse`, `SessionStart`, and
`PostToolUse`. Promote-first: none of the 11 rulebooks' hook files were
touched.

All 15 source files were fetched live from their own rulebook repos
(`gh api repos/tokenmaxxxer/<rulebook>/contents/<path>`) and read in full
before writing the config — not re-derived from the classification
report's guessed shape (per [[survey.md]] and the proposal's Rationale).

## Disposition table (18 classification-report rows -> 15 config rows)

| # | rulebook | hook path | disposition | config row (role -> hook) |
|---|---|---|---|---|
| 1 | conformance-review-rulebook | `review/hooks/state.sh` | promoted-into-config | `conformance-review` -> `review/hooks/state.sh` (tracker, `context_informer`) |
| 2 | customer-support-rulebook | `customer-support-phase1-order/hooks/phase1-order-gate.sh` | promoted-into-config | `customer-support` -> `customer-support-phase1-order/hooks/phase1-order-gate.sh` (gate: `artifact_exists_before` + `citation_adjacency`) |
| 3 | defect-verification-rulebook | `verify-state-guard/hooks/verify-state.sh` (row 1/2) | promoted-into-config | `defect-verification` -> `verify-state-guard/hooks/verify-state.sh` (tracker, `loop_state_rank_bump`) |
| 4 | defect-verification-rulebook | `verify-state-guard/hooks/verify-state.sh` (row 2/2) | promoted-into-config | same row as #3 (one physical file, one config row, per the proposal's collapse note) |
| 5 | execution-observation-rulebook | `execution-observation/plugins/eo-state/hooks/state.sh` (row 1/3) | promoted-into-config | `execution-observation` -> `execution-observation/plugins/eo-state/hooks/state.sh` (tracker, `marker_file_reset_or_touch`) |
| 6 | execution-observation-rulebook | same file (row 2/3) | promoted-into-config | same row as #5 |
| 7 | execution-observation-rulebook | same file (row 3/3) | promoted-into-config | same row as #5 |
| 8 | issue-retrospective-rulebook | `timeline-order-gate/hooks/timeline-order-gate.sh` | promoted-into-config | `issue-retrospective` -> `timeline-order-gate/hooks/timeline-order-gate.sh` (gate: `heading_before_forbidden`) |
| 9 | observability-rulebook | `observability-methodology-selector/hooks/methodology-selector-gate.sh` | promoted-into-config | `observability` -> `.../methodology-selector-gate.sh` (gate: `needle_any_missing`) |
| 10 | observability-rulebook | `observability-methodology-selector/hooks/methodology-selector-status.sh` | promoted-into-config | `observability` -> `.../methodology-selector-status.sh` (tracker, `needle_state_record`) |
| 11 | observability-rulebook | `observability-phase-trace/hooks/phase-trace-gate.sh` | promoted-into-config | `observability` -> `observability-phase-trace/hooks/phase-trace-gate.sh` (gate: `adjacency_required`) |
| 12 | performance-engineering-rulebook | `performance-engineering-order-check/hooks/order-check.sh` | promoted-into-config | `performance-engineering` -> `.../order-check.sh` (gate: `step_sequence` workload-before-evidence) |
| 13 | performance-engineering-rulebook | `performance-engineering-session-informer/hooks/state.sh` | promoted-into-config | `performance-engineering` -> `.../session-informer/hooks/state.sh` (tracker, `context_informer`) |
| 14 | pr-communications-rulebook | `race-sequence/hooks/race-sequence-gate.sh` | promoted-into-config | `pr-communications` -> `race-sequence/hooks/race-sequence-gate.sh` (gate: `conditional_race_sequence`) |
| 15 | risk-management-rulebook | `erm-verdict-methodology/hooks/erm-order-gate.sh` | promoted-into-config | `risk-management` -> `erm-verdict-methodology/hooks/erm-order-gate.sh` (gate: `step_sequence` 4 ISO-31000 stages + `distinct_pair`) |
| 16 | user-discovery-rulebook | `user-discovery-hypothesis-order/hooks/hypothesis-order-gate.sh` | promoted-into-config | `user-discovery` -> `.../hypothesis-order-gate.sh` (gate: `hypothesis_state_or_marker`) |
| 17 | user-discovery-rulebook | `user-discovery-hypothesis-order/hooks/hypothesis-order-state-sync.sh` | promoted-into-config | `user-discovery` -> `.../hypothesis-order-state-sync.sh` (tracker, `hypothesis_state_sync`) |
| 18 | ux-engineering-rulebook | `ux-phase1-structure-gate/hooks/phase1-structure-gate.sh` | promoted-into-config | `ux-engineering` -> `ux-phase1-structure-gate/hooks/phase1-structure-gate.sh` (gate: `step_sequence` 7 Double-Diamond-report sections + `sources_or_paths_required`) |

All 18 rows: **promoted-into-config**, 0 covered-by-core — matches
[[survey.md]]'s prediction (`core/hooks/ordering-gate.sh` carries no
overlapping role or check).

## Fast-tier live-fire output

derived: `bash core/hooks/tests/run-all.sh`

```
=== bash 3.2 parse ===
...
ok    ordering-norm-gate.sh
...
parse-check: 41 file(s) under /bin/bash

=== deny-only ===
deny-only-check: ok — no permissionDecision allow under .../core/hooks
...

=== board gate ===
== 130 passed, 0 failed ==

=== scope gate (warrant) ===
== 46 passed, 0 failed ==

=== approval gate ===
== 50 passed, 0 failed ==

=== gh guard ===
== 54 passed, 0 failed ==

=== role-agnostic gates (trailer/record-fields/handbook-trigger) ===
role-gates: 83 passed, 0 failed

=== facet-keyword gate ===
facet-keyword-gate: 14 passed, 0 failed

=== ordering-norm gate ===
pass=27 fail=0

=== stub-check canon combination forms ===
pass=12 fail=0

=== compliance-check hooks.json scan scope ===
pass=4 fail=0

=== compliance-check --canon-duplication content-hash ===
pass=4 fail=0

=== terse (sibling plugin) ===
...
=== freelunch (sibling plugin) ===
...
=== freelunch observe.sh enforcement (sibling plugin) ===
== 9 passed, 0 failed ==

=== scout (sibling plugin) ===
...
ALL OK
```

`core/hooks/tests/run-ordering-norm-gate-tests.sh` (27 live-fire cases:
one allow + one refuse per configured `mode: gate` role — 9 gate rows —
plus one case per configured `mode: tracker` role — 6 tracker rows,
observability's tracker exercised alongside its gate — plus one
empty-state case and one no-config-file case) is included in the above
`pass=27 fail=0` line and registered in `run-all.sh`.

## git diff file list

derived: `git diff --stat --cached main` (after `git add` of the write
set; `runs/` is pre-existing untracked clutter outside this issue's
scope and was left alone)

```
core/hooks/hooks.json                              |  19 +
core/hooks/ordering-norm-config.json               | 272 +++++++++++
core/hooks/ordering-norm-gate.sh                   | 518 +++++++++++++++++++++
core/hooks/tests/run-all.sh                        |   3 +
core/hooks/tests/run-ordering-norm-gate-tests.sh   | 366 +++++++++++++++
docs/issue-257/proposals/ordering-norm-gate-fold.md | 160 +++++++
docs/issue-257/reports/implementation/survey.md    | 187 ++++++++
7 files changed, 1525 insertions(+)
```

Only `core/` and `docs/issue-257/` paths touched — no rulebook file
modified, matching the proposal's promote-first constraint and its "How
you'll know it worked" criterion.

## Why

Second fold of skill-axis phase-4b, following the validated #254
pattern (`facet-keyword-gate.sh`). Consolidating 15 near-duplicate
ordering/state-tracker hooks scattered across 11 rulebooks into one
core-owned, config-driven gate reduces the audit surface and gives every
future rulebook a promote-first path instead of hand-rolling its own
order-check script.

## Upstream basis

`docs/issue-257/proposals/ordering-norm-gate-fold.md` (approved),
`docs/issue-257/reports/implementation/survey.md`.

## Rationale for deviations

The proposal's write set named `core/hooks/tests/test_ordering_norm_gate.py`
and its "How you'll know it worked" section named `pytest ... (fast
tier)`. This repository has no pytest infrastructure at all — every
existing gate (including the #254 `facet-keyword-gate.sh` this proposal
explicitly names as the pattern to reuse) is tested by a bash
`run-<gate>-tests.sh` script invoked from `core/hooks/tests/run-all.sh`,
the actual "fast tier" entry point. Writing a pytest file here would have
been unrunnable by the repository's own test harness and inconsistent
with every sibling gate. Delivered
`core/hooks/tests/run-ordering-norm-gate-tests.sh` instead, in the
project's real bash live-fire idiom, registered in `run-all.sh` exactly
as `run-facet-keyword-gate-tests.sh` is. The proposal's substantive test
requirements (one allow + one refuse per `mode: gate` role, one case per
`mode: tracker` role, empty-state, no-config-file, run via the fast
tier) are all met — only the file extension/framework named in the
proposal's prose was corrected to match the repository's actual
convention.

## What did not work

- First `observability/phase-trace-gate` refuse fixture used the word
  "reason" inside its own filler padding text ("no reason ever stated
  for the deviation above"), which the `adjacency_required` check
  correctly matched as a nearby reason marker and allowed the write —
  expected: deny, actual: allow. This was a test-fixture bug, not a gate
  bug: reworded the filler text to avoid the trigger word and the case
  passed. No production code changed for this.

## Open findings

None.
