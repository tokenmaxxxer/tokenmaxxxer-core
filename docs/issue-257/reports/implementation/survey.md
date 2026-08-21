# Survey — issue #257 (phase-4b-2: fold ordering-methodology family)

## Source: classification report

`docs/reports/keep-role-family-classification.md`, on-the-record `main`
(fetched via `gh api repos/tokenmaxxxer/on-the-record/contents/...`),
names `ordering-methodology` (18 hooks, disposition `fold`) with target
`core/hooks/ordering-norm-gate.sh`, guessed config shape
`{rulebook: {step_sequence: [...], marker_regex: {...}}}` — explicitly a
guess made at the family-boundary stage, same caveat #254's survey found
for `facet-keyword`.

derived: `gh api repos/tokenmaxxxer/on-the-record/contents/docs/reports/keep-role-family-classification.md -q .content | base64 -d`

## The 18 ordering-methodology hook instances (per-hook rows, classification report)

15 distinct files map to the classification report's 18 counted rows —
several rows repeat the same file (`verify-state.sh` x2,
`execution-observation/plugins/eo-state/hooks/state.sh` x3) because the
report counts per-role-mention, not per-file. Confirmed by reading all
15 files in full (cloned live from each rulebook's own GitHub repo under
`tokenmaxxxer/<rulebook>`), not the audit's header excerpt.

| rulebook | hook path | kill-switch | Pre/state-tracker |
|---|---|---|---|
| conformance-review-rulebook | `review/hooks/state.sh` | none | SessionStart tracker, never denies |
| customer-support-rulebook | `customer-support-phase1-order/hooks/phase1-order-gate.sh` | `CUSTOMER_SUPPORT_PHASE1_ORDER_GATE_OFF` | PreToolUse |
| defect-verification-rulebook | `verify-state-guard/hooks/verify-state.sh` (x2 rows) | `VERIFY_STATE_GUARD_OFF` | state-tracker, never denies |
| execution-observation-rulebook | `execution-observation/plugins/eo-state/hooks/state.sh` (x3 rows) | `EXECUTION_OBSERVATION_STATE_OFF` | SessionStart+PostToolUse tracker |
| issue-retrospective-rulebook | `timeline-order-gate/hooks/timeline-order-gate.sh` | `ISSUE_RETROSPECTIVE_TIMELINE_ORDER_GATE_OFF` | PreToolUse |
| observability-rulebook | `observability-methodology-selector/hooks/methodology-selector-gate.sh` | `OBSERVABILITY_METHODOLOGY_SELECTOR_GATE_OFF` | PreToolUse |
| observability-rulebook | `observability-methodology-selector/hooks/methodology-selector-status.sh` | `OBSERVABILITY_METHODOLOGY_SELECTOR_STATUS_OFF` | state-tracker, never denies |
| observability-rulebook | `observability-phase-trace/hooks/phase-trace-gate.sh` | `OBSERVABILITY_PHASE_TRACE_GATE_OFF` | PreToolUse |
| performance-engineering-rulebook | `performance-engineering-order-check/hooks/order-check.sh` | `PERFORMANCE_ENGINEERING_ORDER_CHECK_OFF` | PreToolUse |
| performance-engineering-rulebook | `performance-engineering-session-informer/hooks/state.sh` | `PERFORMANCE_ENGINEERING_SESSION_INFORMER_OFF` | SessionStart, stdout only |
| pr-communications-rulebook | `race-sequence/hooks/race-sequence-gate.sh` | `RACE_SEQUENCE_GATE_DISABLE` | PreToolUse |
| risk-management-rulebook | `erm-verdict-methodology/hooks/erm-order-gate.sh` | `ERM_VERDICT_METHODOLOGY_GATE_OFF` | PreToolUse |
| user-discovery-rulebook | `user-discovery-hypothesis-order/hooks/hypothesis-order-gate.sh` | `USER_DISCOVERY_HYPOTHESIS_ORDER_GATE_OFF` | PreToolUse |
| user-discovery-rulebook | `user-discovery-hypothesis-order/hooks/hypothesis-order-state-sync.sh` | `USER_DISCOVERY_HYPOTHESIS_ORDER_GATE_OFF` | state-tracker, never denies |
| ux-engineering-rulebook | `ux-phase1-structure-gate/hooks/phase1-structure-gate.sh` | `UX_PHASE1_STRUCTURE_GATE_OFF` | PreToolUse |

All 15 are PreToolUse gates or their SessionStart/PostToolUse
state-tracker siblings (per the issue's own family description), each
its own fail-closed script over `gate-lib.sh` conventions, its own
`<ROLE>_<HOOK>_GATE_OFF`-style kill switch, guarding its own target-path
scope.

## What each hook actually checks (real shape, not the report's guess)

Reading all 15 bodies shows the family is **not** the uniform
"marker-A-before-marker-B" shape the classification report guessed.
Two real sub-shapes exist:

**A. Genuine intra-document step-sequence checks (5 of 15 files)** — a
document's own headings/markers must appear in a fixed order:
- `timeline-order-gate.sh` (issue-retrospective): a `## Timeline`
  heading's position must precede any causal-claim regex match.
- `order-check.sh` (performance-engineering): a workload-characterization
  heading must precede an evidence heading (vocabulary-group offset
  compare).
- `race-sequence-gate.sh` (pr-communications): RACE steps — Research,
  Action, Communication, Evaluation — labeled lines must appear in that
  order, but the check is **conditional**: only enforced once
  `loop_state: landed` appears in the document, plus 4 separate
  field-presence checks bundled in the same file.
- `erm-order-gate.sh` (risk-management): ISO 31000's 4 stages —
  Governance/context, Assessment, Risk treatment, Monitoring — heading
  position compare, plus sub-markers within each stage and a
  labeled-pair-must-differ check (two paired headings' text must not be
  identical) bundled in.
- `phase1-structure-gate.sh` (ux-engineering): Double Diamond's 7
  sections in fixed order, plus a bundled Sources-block check and an
  on-disk-path-existence check unrelated to ordering.

Even these 5 "clean" cases bundle at least one extra check the
classification report's flat `{step_sequence, marker_regex}` shape
cannot express alone — same lesson #254's survey drew for
`facet-keyword`: the guessed shape undercounts the real per-hook
config surface.

**B. Not a step-sequence check at all (10 of 15 files)**:
- `state.sh` (conformance-review), `verify-state.sh`
  (defect-verification), `state.sh` (execution-observation),
  `methodology-selector-status.sh` and part of `hypothesis-order-*`
  (user-discovery) are state-trackers: they read/write a persisted
  state file (JSON or marker file) and never deny a tool call — they
  *record* progress through a state machine (e.g.
  idle→reproducing→reproduced→cleared, monotonic rank) rather than
  gate document structure.
- `customer-support-phase1-order/hooks/phase1-order-gate.sh` bundles a
  survey→scout-brief→proposal file-existence chain (contract-phase
  ordering, not domain-methodology) with 5 unrelated facet-citation
  checks in the same file.
- `observability-methodology-selector/hooks/methodology-selector-gate.sh`
  checks that a methodology name AND a surface classification are both
  present — no order relationship between them at all.
- `observability-phase-trace/hooks/phase-trace-gate.sh` requires a
  reason string adjacent to a "deviation" marker, conditioned on a
  separate JSON state file's phase-1 flag — cross-file state-conditioned,
  not an in-document sequence.
- `performance-engineering-session-informer/hooks/state.sh` only prints
  narration at SessionStart (`gh` lookups, glob checks) — no order is
  enforced by the file itself.
- `user-discovery-hypothesis-order/hooks/hypothesis-order-gate.sh`
  checks hypotheses→evidence→verdict OR'd against a persisted
  `.state.json` boolean — mixed live-detection/persisted-state logic,
  not a flat marker-position compare.

## covered-by-core check (against `core/hooks/ordering-gate.sh`)

Read `core/hooks/ordering-gate.sh` in full (547 lines, this repo,
landed by #248/#252). It is a 7-role dispatcher —
`content-design-phase1-basis`, `phase-order-gate` (devrel),
`security-threat-model-sequence`, `incident-response-order`,
`arch-sequence`, `id-stage-order`, `issue-retrospective-proposal-order`
(env `ISSUE_RETROSPECTIVE_PROPOSAL_ORDER_GATE_OFF`) — that checks a
**cross-file** contract-phase ordering norm: a phase-2 write (proposal
or record) is denied unless a phase-1 artifact (survey.md/scout-brief.md)
already exists on disk for that issue. This is the same norm the
`no-mock`/`scout`/`survey-order` directives describe, already promoted
per #234/#237/#240.

None of the 18 domain-methodology hooks duplicate this. Specifically
checked, since both name overlaps are plausible:
- `timeline-order-gate.sh` (issue-retrospective) checks an
  **intra-document** heading-before-causal-claim order inside
  `docs/issue-N/reports/issue-retrospective.md` — a different document,
  different check, and a different mechanism (heading-position compare
  vs cross-file existence) than core's existing
  `issue-retrospective-proposal-order` role, which only gates a
  proposal write against a prior survey file's existence. Both hooks
  can be live on the same rulebook simultaneously without conflict —
  confirmed distinct, not a duplicate.
- `erm-order-gate.sh` (risk-management, ISO 31000) has **no**
  corresponding role in `ordering-gate.sh` at all — core carries no
  risk-management or ISO-31000-shaped role currently.
- `customer-support-phase1-order/hooks/phase1-order-gate.sh`'s
  survey→scout-brief→proposal chain component *resembles* core's
  contract-phase norm shape, but is not registered as a core role
  either (customer-support is absent from `ordering-gate.sh`'s 7
  roles) — so still not covered-by-core; it stays with this fold as
  the family's own artifact-existence sub-check, kept alongside its
  bundled facet-citation checks (out of scope — see below).

Disposition for all 18: **none are covered-by-core**. All 18 are
dispositioned `promoted-into-config` (fold), reproducing each hook's
real behavior — including its bundled non-order sub-checks, where
removing them would break the acceptance criterion's
per-hook-equivalence requirement, exactly as #254 handled facet-keyword's
richer-than-guessed shape.

## Existing core fold pattern to reuse

Same as #254: `core/hooks/record-fields-gate.sh` /
`record-shape-gate.sh` / (just-landed) `facet-keyword-gate.sh` establish
the pattern — one parameterized bash entrypoint sourcing `gate-lib.sh`,
a JSON config file (`core/hooks/ordering-norm-config.json`), dispatch by
rulebook/hook-slug via a Python payload reading the same
`gate_reconstruct_write`/`gate_normalize_path` helpers.

New wrinkle this fold has that #254 did not: the family includes
SessionStart/PostToolUse state-tracker siblings (5 of the 15 files),
which never deny and are triggered on different hook events than
Write/Edit/MultiEdit/Bash. The config needs a `mode: gate|tracker`
field and `event: PreToolUse|SessionStart|PostToolUse` field so the
dispatcher can register correctly in `hooks.json` and skip the deny
path entirely for tracker rows.

## bash-3.2 guard (#245)

Same guard applies; the new gate copies `record-shape-gate.sh`'s
`payload="$(cat)"` + `python3 <<'PYEOF'` idiom, no heredoc-in-command-
substitution.

## Write set (frozen for the proposal)

- `core/hooks/ordering-norm-gate.sh` (new)
- `core/hooks/ordering-norm-config.json` (new)
- `core/hooks/hooks.json` (register PreToolUse + SessionStart +
  PostToolUse entries)
- `core/hooks/tests/` — live-fire test file(s) (new), one case per
  configured role covering allow/refuse/empty-state, plus a
  no-config-file case
- `docs/issue-257/reports/implementation.md` (phase-2 record, not
  written yet)

No rulebook file is touched (promote-first).
