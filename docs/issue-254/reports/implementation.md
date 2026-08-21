---
code_under_review:
  - core/hooks/facet-keyword-gate.sh
  - core/hooks/facet-keyword-config.json
  - core/hooks/hooks.json
  - core/hooks/tests/run-facet-keyword-gate-tests.sh
  - core/hooks/tests/run-all.sh
type: feature
breaking: false
verdict: pass
loop_state: landed
---

# Phase-2 record — issue #254 (facet-keyword-gate fold)

## What was done

Delivered the approved proposal
(`docs/issue-254/proposals/facet-keyword-gate-fold.md`, approved via
`APPROVE issue-254/implementation`):

- `core/hooks/facet-keyword-gate.sh` — one parameterized PreToolUse gate,
  built on `core/hooks/lib/gate-lib.sh`, dispatching on `CLAUDE_ROLE` to
  the matching row(s) of `core/hooks/facet-keyword-config.json`. Each
  config row carries a `check_type` (`header_present_or_skip`,
  `trigger_required_elements`, `trigger_count`, `marker_required_elements`,
  `table_header_columns`, `heading_scenario_min_labels`,
  `heading_sections_required`) reproducing the actual per-hook logic read
  from the 8 source hooks' full bodies (survey.md), not the classification
  report's guessed `{keyword_regex, claim_context_regex}` shape. A facet
  row governs both `Write`/`Edit`/`MultiEdit` reconstruction (via
  `gate_reconstruct_write`) and a Bash-tool write to the same target path
  (denied outright as unverifiable, matching every source hook).
- `core/hooks/facet-keyword-config.json` — 8 rows across 4 rulebook keys
  (content-design: tone-axis; customer-support: escalation-path,
  five-whys, kcs, playbook-scenario, sla-tier; finance-unit-economics:
  sensitivity-scenario; sales: playbook), each carrying its own
  `kill_switch_env`, `target_path_regex`, and check-type-specific fields
  (required-element tag/regex lists, deny-message templates) transcribed
  from the source hooks' own regexes and message text.
- `core/hooks/hooks.json` — registered `facet-keyword-gate.sh` as a
  PreToolUse hook in the existing `.*`-matcher group, alongside the other
  core gates.
- `core/hooks/tests/run-facet-keyword-gate-tests.sh` — live-fire tests:
  real PreToolUse JSON piped to the gate binary as a subprocess (never an
  in-process unit test of a Python helper). 14 cases: one allow + one
  refuse per configured role (content-design, customer-support x5 facets,
  finance-unit-economics, sales — 8 source hooks total), one empty-state
  case (`CLAUDE_ROLE=engineering`, no config row, passes through
  silently), and one no-config-file case
  (`FACET_KEYWORD_CONFIG=<nonexistent path>` → no-op). Wired into
  `core/hooks/tests/run-all.sh` (this repo's fast tier — no pytest
  infrastructure exists in this repo; see Rationale for deviations).
- No rulebook file touched (promote-first, per the proposal); the 8
  source hooks keep running unmodified.

## Why

Fold the facet-keyword family per issue #254 / the phase-4a
classification (`docs/reports/keep-role-family-classification.md`,
on-the-record#1764), validating the config-extraction fold pattern ahead
of the much larger 145-hook `record-section-shape` fold, per
[[docs/issue-254/reports/implementation/survey.md]] and the approved
proposal's Rationale (config shape reproduces the real per-hook
mechanics — target-path regex + optional trigger + section-scope +
ordered required-element list + deny template — rather than the
report's single keyword/context-regex pair, which cannot express e.g.
kcs's 5 required tags or sla-tier's header-row column check without
either dropping hooks or overloading one regex field into an ad hoc
mini-language).

## Upstream basis

- `docs/issue-254/proposals/facet-keyword-gate-fold.md` (approved)
- `docs/issue-254/reports/implementation/survey.md`
- Source hooks read in full from live clones: content-design-rulebook,
  customer-support-rulebook, finance-unit-economics-rulebook,
  sales-rulebook (git clone --depth 1, per survey.md)

## What did not work

None.

## Rationale for deviations

The approved proposal's write set named
`core/hooks/tests/test_facet_keyword_gate.py` run via `pytest`. Once
inside `core/hooks/tests/`, no pytest infrastructure exists anywhere in
this repo — every other gate's live-fire suite is a `run-<name>-tests.sh`
shell script invoking the gate as a real subprocess, aggregated by
`core/hooks/tests/run-all.sh` (this repo's actual fast tier; e.g.
`run-role-gates-tests.sh`, `run-board-gate-tests.sh`). This was not
visible until phase 2 (the survey scoped the write set to a test file
under `core/hooks/tests/`, not its concrete tooling). Delivered
`core/hooks/tests/run-facet-keyword-gate-tests.sh` instead, following the
repo's actual established convention, and wired it into `run-all.sh`
next to the other gate suites — same live-fire coverage (allow/refuse
per role + empty-state + no-config-file), same subprocess-invocation
discipline the proposal asked for (issue #248's lesson), different file
name/tooling to match what this repo's fast tier actually runs.

## Fast tier output

derived: `bash core/hooks/tests/run-all.sh`

```
=== bash 3.2 parse ===
...
ok    facet-keyword-gate.sh
ok    tests/run-facet-keyword-gate-tests.sh
...
parse-check: 39 file(s) under /bin/bash

=== deny-only ===
...
=== board gate ===
== ... passed, 0 failed ==
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

The #245 heredoc-in-command-substitution guard (`=== bash 3.2 parse ===`)
stays green — `facet-keyword-gate.sh` uses the same
`payload="$(cat)"` + top-level `python3 <<'PYEOF'` idiom as
`record-shape-gate.sh`, never a heredoc inside a command substitution.

## Diff scope

derived: `git diff --stat --cached HEAD` (phase-2 commit contents)

```
 core/hooks/facet-keyword-config.json             | 128 ++++++++
 core/hooks/facet-keyword-gate.sh                 | 375 +++++++++++++++++++++++
 core/hooks/hooks.json                            |   4 +
 core/hooks/tests/run-all.sh                      |   3 +
 core/hooks/tests/run-facet-keyword-gate-tests.sh | 354 +++++++++++++++++++++
 docs/issue-254/reports/implementation.md         | 174 +++++++++++
 6 files changed, 1038 insertions(+)
```

(`docs/issue-254/proposals/facet-keyword-gate-fold.md` and
`docs/issue-254/reports/implementation/survey.md` landed in the prior
phase-1 commit, `7e9ac8d`.) Only `core/` and `docs/issue-254/` paths
touched across both commits. No rulebook file modified.

## Open findings

None.
