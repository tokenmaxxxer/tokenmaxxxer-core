---
code_under_review:
  - core/hooks/citation-gate.sh
  - core/hooks/citation-config.json
  - core/hooks/hooks.json
  - core/hooks/tests/run-citation-gate-tests.sh
  - core/hooks/tests/run-all.sh
type: feature
breaking: false
verdict: none
loop_state: landed
---

# Implementation record — issue #260 (phase-4b-3: citation-gate fold)

## What was done

Delivered the approved phase-1 proposal
(`docs/issue-260/proposals/citation-gate-fold.md`, approved via
`APPROVE issue-260/implementation` on the issue): folded all 11
classification-report rows of the `citation-sourcing` family into one
parameterized `core/hooks/citation-gate.sh`, config-driven off
`core/hooks/citation-config.json`, registered in
`core/hooks/hooks.json` under `PreToolUse`. Promote-first: none of the
9 rulebooks' hook files were touched.

All 11 source files were read in full from their own rulebook repo's
live clone (9 under `/home/jwjung/tokenmaxxxer/rulebooks/<rulebook>`, 2
under `/tmp/idr/interaction-design/plugins/` for interaction-design),
per [[survey.md]] and the proposal's Rationale — not re-derived from the
classification report's guessed flat shape.

## Disposition table (11 hooks -> 11 config rows)

| # | rulebook | hook path | check_type | disposition |
|---|---|---|---|---|
| 1 | api-design-rulebook | `evidence-citation-gate/hooks/gate.sh` | `claim_adjacent_marker` (paragraph scope) | promoted-into-config |
| 2 | architecture-rulebook | `arch-citation-gate/hooks/citation-gate.sh` | `claim_adjacent_marker` (section-or-window scope) | promoted-into-config |
| 3 | capacity-planning-rulebook | `capacity-order-enforcement/hooks/citation-gate.sh` | `sequencing_filename_anchor` | promoted-into-config |
| 4 | conformance-review-rulebook | `review-traceability/hooks/traceability-gate.sh` | `verdict_field_required_plus_list_shape` | promoted-into-config |
| 5 | finance-unit-economics-rulebook | `finance-evidence-chain/hooks/evidence-chain-gate.sh` | `whole_doc_metric_source_and_paragraph_pair` | promoted-into-config |
| 6 | interaction-design-rulebook | `id-citation-format/hooks/citation-gate.sh` | `bullet_adjacent_plus_doc_sources` | promoted-into-config |
| 7 | interaction-design-rulebook | `id-traceability/hooks/traceability-gate.sh` | `section_required_fields` | promoted-into-config |
| 8 | requirements-engineering-rulebook | `traceability-matrix-gate/hooks/traceability-matrix-gate.sh` | `table_req_membership` | promoted-into-config |
| 9 | security-threat-model-rulebook | `security-threat-model-canon-citation/hooks/methodology-gate.sh` | `anti_pattern_section` | promoted-into-config |
| 10 | technical-feasibility-rulebook | `evidence-citation/hooks/citation-gate.sh` | `claim_adjacent_marker_phase_scoped` | promoted-into-config |
| 11 | test-authoring-rulebook | `traceability-line/hooks/traceability-gate.sh` | `whole_doc_keyword_and_ref_plus_branch` | promoted-into-config |

All 11 rows: **promoted-into-config**, 0 covered-by-core — matches
[[survey.md]]'s "Existing core gates checked for overlap" finding
(no landed core gate checks REQ-id table logic, shebang/script-paste
detection, or branch-name-vs-issue-ref cross-checks).

Bundled behavior not modeled by a dedicated `check_type` but preserved
inside the closest-fitting checker: capacity-planning's
survey.md-exempt/terminal-trigger gating (inside
`check_sequencing_filename_anchor`); conformance-review's phase-1
list-shape check and Bash-write refusal (inside
`check_verdict_field_required_plus_list_shape` / the gate's shared
Bash-write path via `bash_write_refuses`); technical-feasibility's
phase-1/phase-2 split and cross-file carry-forward exemption (inside
`check_claim_adjacent_marker_phase_scoped`) and its own
`bash_write_refuses`; id-citation-format's per-bullet marker check
bundled with its document-level Sources-heading requirement (inside
`check_bullet_adjacent_plus_doc_sources`); test-authoring's
branch-name-vs-issue-ref cross-check (inside
`check_whole_doc_keyword_and_ref_plus_branch`). The two source hooks'
best-effort `.status.json` side-effect writes (id-citation-format,
id-traceability) are not replicated — they are a state-file
side-effect, not part of the citation check's allow/deny behavior, and
no landed core-gate fold in this family (#254, #257) replicates a
source hook's own state-file writes either.

## Fast-tier live-fire output

derived: `bash core/hooks/tests/run-all.sh`

```
=== bash 3.2 parse ===
...
ok    citation-gate.sh
...
parse-check: 43 file(s) under /bin/bash

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

=== citation gate ===
citation-gate: 24 passed, 0 failed

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

`core/hooks/tests/run-citation-gate-tests.sh` (24 live-fire cases: one
allow + one refuse per configured hook — 11 hooks — plus one
empty-state case and one no-config-file case) is included in the above
`citation-gate: 24 passed, 0 failed` line and registered in
`run-all.sh`.

## git diff file list

derived: `git diff --stat --cached main` (after `git add` of the write
set; `runs/` is pre-existing untracked clutter outside this issue's
scope and was left alone)

```
core/hooks/citation-config.json                 | 189 +++++++
core/hooks/citation-gate.sh                     | 666 ++++++++++++++++++++++++
core/hooks/hooks.json                           |   4 +
core/hooks/tests/run-all.sh                     |   3 +
core/hooks/tests/run-citation-gate-tests.sh     | 246 +++++++++
docs/issue-260/proposals/citation-gate-fold.md  | 163 ++++++
docs/issue-260/reports/implementation/survey.md | 146 ++++++
7 files changed, 1417 insertions(+)
```

Only `core/` and `docs/issue-260/` paths touched — no rulebook file
modified, matching the proposal's promote-first constraint and its "How
you'll know it worked" criterion.

## Why

Third fold of skill-axis phase-4b, following the validated #254/#257
pattern (`facet-keyword-gate.sh` / `ordering-norm-gate.sh`).
Consolidating 11 citation/traceability-sourcing hooks scattered across 9
rulebooks into one core-owned, config-driven gate reduces the audit
surface and gives every future rulebook a promote-first path instead of
hand-rolling its own citation-check script.

## Upstream basis

`docs/issue-260/proposals/citation-gate-fold.md` (approved),
`docs/issue-260/reports/implementation/survey.md`.

## Rationale for deviations

The proposal's write set named
`core/hooks/tests/test_citation_gate.py` and its "How you'll know it
worked" section implicitly assumed a pytest-style test file (mirroring
#254's/#257's proposals, which made and then corrected the same
assumption in their own delivery records). This repository has no
pytest infrastructure — every existing gate (including
`facet-keyword-gate.sh` and `ordering-norm-gate.sh`, this proposal's
own named precedent) is tested by a bash `run-<gate>-tests.sh` script
invoked from `core/hooks/tests/run-all.sh`, the actual "fast tier"
entry point named in this issue's acceptance criteria. Delivered
`core/hooks/tests/run-citation-gate-tests.sh` instead, in the project's
real bash live-fire idiom, registered in `run-all.sh` exactly as
`run-facet-keyword-gate-tests.sh` and `run-ordering-norm-gate-tests.sh`
are. The proposal's substantive test requirements (one allow + one
refuse per configured hook, empty-state, no-config-file, run via the
fast tier) are all met — only the file extension/framework named in the
proposal's prose was corrected to match the repository's actual
convention, same correction #257's record already made for the same
reason.

## What did not work

None — every live-fire case (24) passed on first run; the fast tier
(`run-all.sh`) was green with no fixture rework needed.

## Open findings

None.
