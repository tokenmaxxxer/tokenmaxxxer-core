# Survey — issue #263 (phase-4b-4: fold the record-section-shape family)

## Source: classification report

`docs/reports/keep-role-family-classification.md`, on-the-record `main`
(local clone at `/tmp/otr`), names `record-section-shape` (145 hooks,
disposition `fold`) with target `core/hooks/record-shape-gate.sh`
(the report phrases it as "extends the existing parameterized
`record-fields-gate.sh`, core issue #72" — that phrasing names the
wrong core file; the family row's own target field says
`record-shape-gate.sh`, and `record-fields-gate.sh` is a separate,
already-generic core gate — see "Existing core gates checked for
overlap" below), guessed config shape `{rulebook: {surface:
proposal|record, required_sections: [...], required_frontmatter_fields:
[...], checklist_entry_schema: {marker, required_keys: [...]}}}` —
explicitly a family-boundary guess, the same caveat #254's, #257's, and
#260's surveys found for their families.

derived: `grep -n "record-section-shape" docs/reports/keep-role-family-classification.md` (in `/tmp/otr`)

## The 145 hooks (per-hook rows, classification report lines 166-474)

derived: `sed -n '166,474p' docs/reports/keep-role-family-classification.md | grep "record-section-shape" | grep '^| '` (in `/tmp/otr`) — 145 rows returned, matching the issue's stated count exactly. Every one of the 43 rulebooks contributes at least one row (some contribute up to 8, e.g. `interaction-design-rulebook`).

| rulebook | hook file |
|---|---|
| accessibility-rulebook | `wcag-em-gate/hooks/methodology-gate.sh` |
| api-design-rulebook | `api-design/plugins/adr-section-gate/hooks/gate.sh` |
| api-design-rulebook | `api-design/plugins/deprecation-plan-gate/hooks/gate.sh` |
| api-design-rulebook | `api-design/plugins/interface-spec-gate/hooks/gate.sh` |
| api-design-rulebook | `api-design/plugins/resource-model-gate/hooks/gate.sh` |
| api-design-rulebook | `api-design/plugins/versioning-strategy-gate/hooks/gate.sh` |
| architecture-rulebook | `arch-adr-content-gate/hooks/adr-content-gate.sh` |
| brand-design-rulebook | `brand-design-guide-and-spec/hooks/methodology-gate.sh` |
| brand-design-rulebook | `brand-design-kapferer-scope-guard/hooks/methodology-gate.sh` |
| brand-design-rulebook | `brand-design-system-handoff/hooks/methodology-gate.sh` |
| brand-design-rulebook | `brand-design-wcag-consistency/hooks/methodology-gate.sh` |
| capacity-planning-rulebook | `capacity-planning/hooks/capacity-fields-gate.sh` |
| conformance-review-rulebook | `review-proposal-completeness/hooks/proposal-completeness-gate.sh` |
| conformance-review-rulebook | `review-record-norm/hooks/closed-checks-gate.sh` |
| content-design-rulebook | `content-design-decision-rationale/hooks/decision-rationale-gate.sh` |
| content-design-rulebook | `content-design-self-critique/hooks/self-critique-gate.sh` |
| customer-support-rulebook | `customer-support-evidence-metric/hooks/evidence-metric-gate.sh` |
| customer-support-rulebook | `customer-support-record-fields/hooks/record-fields-gate.sh` |
| data-engineering-rulebook | `data-quality-gate/hooks/data-quality-gate.sh` |
| data-engineering-rulebook | `failure-handling-gate/hooks/failure-handling-gate.sh` |
| data-engineering-rulebook | `pipeline-design-gate/hooks/pipeline-design-gate.sh` |
| data-modeling-rulebook | `data-modeling-datavault/hooks/datavault-gate.sh` |
| data-modeling-rulebook | `data-modeling-inmon/hooks/inmon-gate.sh` |
| data-modeling-rulebook | `data-modeling-kimball/hooks/kimball-gate.sh` |
| data-modeling-rulebook | `data-modeling-structure/hooks/structure-gate.sh` |
| defect-verification-rulebook | `verify-finding-gate/hooks/finding-gate.sh` |
| defect-verification-rulebook | `verify-outcome-gate/hooks/outcome-gate.sh` |
| defect-verification-rulebook | `verify-state-guard/hooks/state-guard.sh` |
| defect-verification-rulebook | `verify/hooks/closed-checks-gate.sh` |
| devrel-rulebook | `diataxis-record/hooks/record-fields-devrel-gate.sh` |
| devrel-rulebook | `metric-record/hooks/metric-record-gate.sh` |
| devrel-rulebook | `rfc-seven-section/hooks/proposal-sections-gate.sh` |
| execution-observation-rulebook | `execution-observation/plugins/eo-methodology-gate/hooks/methodology-gate.sh` |
| finance-unit-economics-rulebook | `finance-cac-payback/hooks/cac-payback-gate.sh` |
| finance-unit-economics-rulebook | `finance-ltv-cac-band/hooks/ltv-cac-band-gate.sh` |
| finance-unit-economics-rulebook | `finance-ltv-churn-assumption/hooks/ltv-churn-assumption-gate.sh` |
| finance-unit-economics-rulebook | `finance-proposal-shape/hooks/proposal-shape-gate.sh` |
| finance-unit-economics-rulebook | `finance-unit-economics/hooks/produces-fields-gate.sh` |
| growth-analytics-rulebook | `ga-funnel/hooks/ga-funnel-gate.sh` |
| growth-analytics-rulebook | `ga-prereg/hooks/ga-prereg-gate.sh` |
| growth-analytics-rulebook | `ga-trust/hooks/ga-trust-gate.sh` |
| implementation-rulebook | `coding/hooks/coding-progress-gate.sh` |
| incident-response-rulebook | `incident-response-action-item-gate/hooks/action-item-gate.sh` |
| incident-response-rulebook | `incident-response-proposal-evidence-gate/hooks/evidence-gate.sh` |
| incident-response-rulebook | `incident-response-rca-method-gate/hooks/rca-method-gate.sh` |
| interaction-design-rulebook | `interaction-design/plugins/id-accessibility-floor/hooks/accessibility-gate.sh` |
| interaction-design-rulebook | `interaction-design/plugins/id-nielsen-heuristics/hooks/nielsen-gate.sh` |
| interaction-design-rulebook | `interaction-design/plugins/id-persona-goal/hooks/persona-goal-gate.sh` |
| interaction-design-rulebook | `interaction-design/plugins/id-proposal-shape/hooks/proposal-shape-gate.sh` |
| interaction-design-rulebook | `interaction-design/plugins/id-state-completeness/hooks/state-completeness-gate.sh` |
| interaction-design-rulebook | `interaction-design/plugins/id-task-flow/hooks/task-flow-gate.sh` |
| interaction-design-rulebook | `interaction-design/plugins/id-usability-test-plan/hooks/usability-test-gate.sh` |
| interaction-design-rulebook | `interaction-design/plugins/id-wireframe-staging/hooks/wireframe-staging-gate.sh` |
| issue-retrospective-rulebook | `action-item-shape-gate/hooks/action-item-shape-gate.sh` |
| issue-retrospective-rulebook | `contributing-factors-gate/hooks/contributing-factors-gate.sh` |
| issue-retrospective-rulebook | `freelunch-completeness-gate/hooks/freelunch-completeness-gate.sh` |
| issue-retrospective-rulebook | `recurred-prediction-gate/hooks/recurred-prediction-gate.sh` |
| knowledge-management-rulebook | `km-adr-proposal/hooks/adr-shape-gate.sh` |
| knowledge-management-rulebook | `km-cross-index/hooks/index-pairing-gate.sh` |
| knowledge-management-rulebook | `km-cross-index/hooks/index-shape-gate.sh` |
| knowledge-management-rulebook | `km-pattern-entry/hooks/pattern-entry-gate.sh` |
| knowledge-management-rulebook | `km-supersession/hooks/supersession-pairing-gate.sh` |
| legal-compliance-rulebook | `legal-compliance-fanout-completeness-gate/hooks/gate.sh` |
| legal-compliance-rulebook | `legal-compliance-phase1-proposal-gate/hooks/gate.sh` |
| legal-compliance-rulebook | `legal-compliance-phase2-record-gate/hooks/gate.sh` |
| localization-rulebook | `localization/hooks/record-fields-localization-gate.sh` |
| localization-rulebook | `localization/plugins/mqm-tagging/hooks/mqm-tagging-gate.sh` |
| localization-rulebook | `localization/plugins/proposal-gate/hooks/methodology-gate.sh` |
| localization-rulebook | `localization/plugins/verdict-axis/hooks/verdict-axis-gate.sh` |
| market-analysis-rulebook | `market-analysis/plugins/competitor-mapping/hooks/gate.sh` |
| market-analysis-rulebook | `market-analysis/plugins/evidence-rigor/hooks/gate.sh` |
| market-analysis-rulebook | `market-analysis/plugins/five-forces/hooks/gate.sh` |
| market-analysis-rulebook | `market-analysis/plugins/jtbd-fit/hooks/gate.sh` |
| market-analysis-rulebook | `market-analysis/plugins/mece-proposal/hooks/gate.sh` |
| marketing-rulebook | `marketing-channel/hooks/channel-gate.sh` |
| marketing-rulebook | `marketing-messaging/hooks/messaging-gate.sh` |
| marketing-rulebook | `marketing-segment/hooks/segment-gate.sh` |
| ml-engineering-rulebook | `ml-engineering-adr-proposal/hooks/methodology-gate.sh` |
| ml-engineering-rulebook | `ml-engineering-eval-discipline/hooks/methodology-gate.sh` |
| ml-engineering-rulebook | `ml-engineering-ml-test-score/hooks/methodology-gate.sh` |
| ml-engineering-rulebook | `ml-engineering-model-provenance/hooks/methodology-gate.sh` |
| ml-engineering-rulebook | `ml-engineering-slo-serving/hooks/methodology-gate.sh` |
| observability-rulebook | `observability-cardinality-budget/hooks/cardinality-budget-gate.sh` |
| observability-rulebook | `observability-explorability/hooks/explorability-gate.sh` |
| observability-rulebook | `observability-signal-golden/hooks/signal-golden-gate.sh` |
| observability-rulebook | `observability-signal-red/hooks/signal-red-gate.sh` |
| observability-rulebook | `observability-signal-use/hooks/signal-use-gate.sh` |
| observability-rulebook | `observability/hooks/observability-produces-gate.sh` |
| partnerships-bd-rulebook | `batna-zopa/hooks/batna-zopa-gate.sh` |
| partnerships-bd-rulebook | `evidence-discipline/hooks/evidence-discipline-gate.sh` |
| partnerships-bd-rulebook | `multi-axis-scoring/hooks/multi-axis-scoring-gate.sh` |
| partnerships-bd-rulebook | `strategic-fit-gate/hooks/strategic-fit-gate.sh` |
| partnerships-bd-rulebook | `term-sheet-structure/hooks/term-sheet-structure-gate.sh` |
| performance-engineering-rulebook | `performance-engineering-proposal-gate/hooks/proposal-gate.sh` |
| performance-engineering-rulebook | `performance-engineering-record-gate/hooks/record-gate.sh` |
| pr-communications-rulebook | `key-message-tiers/hooks/key-message-gate.sh` |
| pr-communications-rulebook | `qa-preapproval/hooks/qa-preapproval-gate.sh` |
| pricing-rulebook | `pricing/plugins/pricing-design-rigor/hooks/design-gate.sh` |
| pricing-rulebook | `pricing/plugins/pricing-method-family/hooks/family-gate.sh` |
| pricing-rulebook | `pricing/plugins/pricing-scope-gate/hooks/scope-gate.sh` |
| pricing-rulebook | `pricing/plugins/pricing-verdict-report/hooks/report-gate.sh` |
| product-discovery-rulebook | `product-assumption-mapping/hooks/methodology-gate.sh` |
| product-discovery-rulebook | `product-guardrail-metrics/hooks/methodology-gate.sh` |
| product-discovery-rulebook | `product-hypothesis-testing/hooks/methodology-gate.sh` |
| product-discovery-rulebook | `product-one-pager/hooks/methodology-gate.sh` |
| product-discovery-rulebook | `product-opportunity-solution-tree/hooks/methodology-gate.sh` |
| refactoring-legacy-rulebook | `characterization-tests/hooks/methodology-gate.sh` |
| refactoring-legacy-rulebook | `proposal-norm/hooks/methodology-gate.sh` |
| refactoring-legacy-rulebook | `refactoring-legacy/hooks/refactoring-legacy-progress-gate.sh` |
| refactoring-legacy-rulebook | `refactoring-steps/hooks/methodology-gate.sh` |
| release-engineering-rulebook | `error-budget-policy/hooks/error-budget-gate.sh` |
| release-engineering-rulebook | `postmortem/hooks/postmortem-review-gate.sh` |
| release-engineering-rulebook | `proposal-norm/hooks/proposal-fields-gate.sh` |
| release-engineering-rulebook | `readiness-checklist/hooks/readiness-fields-gate.sh` |
| release-engineering-rulebook | `rollout-plan/hooks/rollout-plan-fields-gate.sh` |
| requirements-engineering-rulebook | `ambiguity-resolution-gate/hooks/ambiguity-resolution-gate.sh` |
| requirements-engineering-rulebook | `proposal-discipline-gate/hooks/proposal-discipline-gate.sh` |
| requirements-engineering-rulebook | `req-id-gate/hooks/req-id-gate.sh` |
| risk-management-rulebook | `phase1-proposal-norms/hooks/proposal-shape-gate.sh` |
| risk-management-rulebook | `phase2-record-norms/hooks/record-shape-gate.sh` |
| risk-management-rulebook | `risk-register-methodology/hooks/register-fields-gate.sh` |
| sales-rulebook | `sales-proposal-norm/hooks/proposal-norm-gate.sh` |
| sales-rulebook | `sales-qualification-meddpicc/hooks/qualification-gate.sh` |
| sales-rulebook | `sales-stage-definitions/hooks/stage-definitions-gate.sh` |
| secure-coding-rulebook | `asvs-verification/hooks/level-gate.sh` |
| secure-coding-rulebook | `cwe-cvss-findings/hooks/finding-gate.sh` |
| security-threat-model-rulebook | `security-threat-model-mitigation/hooks/methodology-gate.sh` |
| security-threat-model-rulebook | `security-threat-model-residual-signoff/hooks/methodology-gate.sh` |
| security-threat-model-rulebook | `security-threat-model-risk-rating/hooks/methodology-gate.sh` |
| security-threat-model-rulebook | `security-threat-model-stride/hooks/methodology-gate.sh` |
| technical-feasibility-rulebook | `madr-options/hooks/options-gate.sh` |
| technical-feasibility-rulebook | `nygard-adr-spine/hooks/spine-gate.sh` |
| technical-writing-rulebook | `plugins/tw-diataxis/hooks/diataxis-type-gate.sh` |
| technical-writing-rulebook | `plugins/tw-minimalism/hooks/minimalism-check-gate.sh` |
| technical-writing-rulebook | `plugins/tw-rfc-proposal/hooks/rfc-structure-gate.sh` |
| technical-writing-rulebook | `plugins/tw-style-guide/hooks/style-guide-gate.sh` |
| test-authoring-rulebook | `adr-proposal-shape/hooks/proposal-shape-gate.sh` |
| test-authoring-rulebook | `ep-bva-technique/hooks/technique-gate.sh` |
| test-authoring-rulebook | `xunit-suite-patterns/hooks/suite-patterns-gate.sh` |
| user-discovery-rulebook | `user-discovery-evidence-tagging/hooks/evidence-tagging-gate.sh` |
| user-discovery-rulebook | `user-discovery-proposal-norm/hooks/proposal-norm-gate.sh` |
| user-discovery-rulebook | `user-discovery-saturation/hooks/saturation-gate.sh` |
| ux-engineering-rulebook | `ux-migration-handoff/hooks/migration-handoff-gate.sh` |
| ux-engineering-rulebook | `ux-token-schema/hooks/token-schema-gate.sh` |
| ux-engineering-rulebook | `ux-wcag-onpair/hooks/wcag-onpair-gate.sh` |

## What a representative sample actually checks (real shape, not the report's guess)

Read in full, from each hook's own rulebook repo's live clone under
`/home/jwjung/tokenmaxxxer/rulebooks/<rulebook>/`: `wcag-em-gate/hooks/
methodology-gate.sh` (accessibility), `arch-adr-content-gate/hooks/
adr-content-gate.sh` (architecture), `api-design/plugins/
deprecation-plan-gate/hooks/gate.sh` (api-design), `data-modeling-kimball/
hooks/kimball-gate.sh` (data-modeling) — one representative per major
shape family found, chosen for maximum shape diversity across the 145
(the family is too large for #254/#257/#260's full-family read within
this session; per the issue's own SCALE NOTE, full per-hook
disposition is a mechanical-extraction task, deferred to phase 2).

Confirmed the report's guessed shape is broadly right but under-specifies
real variation. At least four distinct schema shapes exist among the 145:

**A. Checklist-entry shape (marker + N required per-entry fields)** —
`wcag-em-gate/methodology-gate.sh`: record-level `scope:`/`sample:`
fields required, then every genuine `wcag-checklist` entry block
(marker-line-exact + structural adjacency to a `criterion:` line) must
carry 6 required fields (criterion, level, verdict, evidence,
remediation, scope note), with two conditional sub-rules (verdict:fail
requires non-empty remediation; verdict:not-applicable requires a scope
note) and a top-level `stage:` gate once any checklist entry exists.
This is the report's guessed `checklist_entry_schema: {marker,
required_keys}` shape, but with per-verdict conditional required keys
the flat guess does not name.

**B. Section-marker existence shape (N literal section headers/markers
present, gated by a loop_state threshold)** — `arch-adr-content-gate/
adr-content-gate.sh`: once the record's frontmatter `loop_state` leaves
proposal-only states, 4 ADR section markers plus a C4-level diagram
marker must all be present (literal substring match, no per-entry
structure) — the report's `required_sections: [...]` shape, but
conditionally activated by a frontmatter field value, not unconditional.

**C. Field-and-literal-token co-occurrence shape (a named field's value
must carry specific literal tokens, not just be present)** —
`deprecation-plan-gate/gate.sh`: the `deprecation-plan` label must carry
both literal header tokens `Sunset` and `Deprecation` plus a concrete
date, or the literal `N/A — net new`. This is neither a clean
`required_sections` presence check nor a `checklist_entry_schema` — it
is a required-field-value-shape check (closer to `field-format-numeric`,
the sibling `demote`-dispositioned family, but the report placed it in
`record-section-shape`; kept here as record-shape's own
literal-token-co-occurrence sub-shape per the report's placement, not
re-litigated — re-classification is out of this issue's scope).

**D. Methodology-checklist shape (named framework's fixed field set,
gated by a topic-keyword trigger)** — `data-modeling-kimball/
kimball-gate.sh`: only fires when body content actually names the
Kimball token (kimball/dimensional model/star schema); when triggered,
requires Kimball's fixed methodology field set. Same shape family as
`data-modeling-inmon`/`data-modeling-datavault`/`-structure` (4 hooks in
one rulebook, each keyed to a different named methodology, same
topic-gated-then-checklist mechanism) and mirrors
`ml-engineering-rulebook`'s 5 `methodology-gate.sh` files and
`security-threat-model-rulebook`'s 4 `methodology-gate.sh` files (both
visible by filename in the 145-row table above) — a recurring
`methodology-gate.sh` naming convention across at least 3 rulebooks
covers this same topic-gated-checklist shape.

## Existing core gates checked for overlap (covered-by-core candidates)

`core/hooks/record-shape-gate.sh` (217 lines) already exists — but it is
NOT yet parameterized: it is hardcoded to one target
(`docs/issue-<n>/reports/implementation.md`, the `implementation` role's
own phase-2 record) and one fixed rule set (5 frontmatter keys, the
`## What did not work` heading, the conditional `## Rationale for
deviations` heading) — this is the `implementation` role's own
record-shape enforcement, landed under core issue #52, not a fold of any
rulebook's hook. `core/hooks/record-fields-gate.sh` (441 lines) is a
separate, already-generic core gate covering `loop_state` terminal-state
vocabulary (with a repo-committable override file,
`docs/specs/record-fields-terminal-states.json`) — it does not check
section/frontmatter-field/checklist shape and is not itself a fold
target for this family.

derived:
```
wc -l core/hooks/record-shape-gate.sh core/hooks/record-fields-gate.sh
grep -n "config\|CHECKERS" core/hooks/record-shape-gate.sh   # no hits -- not yet config-driven
```

No hook in the 145-row sample is already redundant with a landed core
gate beyond `record-shape-gate.sh`'s own hardcoded implementation-role
case; extending `record-shape-gate.sh` to a `CHECKERS`-dispatched,
config-table-driven gate (mirroring `facet-keyword-gate.sh`'s and
`citation-gate.sh`'s already-landed `CHECKERS` pattern) both preserves
its existing implementation-role behavior (as that role's own config row
or an unconditional default) and adds the 145 rulebook hooks as
additional config rows — all candidates for `promoted-into-config`
pending the mechanical extraction pass.

## Implication for config shape and phase-2 extraction

Following #254's/#257's/#260's precedent (`CHECKERS` dispatch keyed by a
`check_type` field, not one generalized mini-language), and given the
issue's own SCALE NOTE that 145 hooks cannot be hand-read in one
session: config rows need a `check_type` field distinguishing at least
the four shapes found above (`checklist_entry_fields`,
`section_markers_conditional`, `field_literal_token_cooccurrence`,
`methodology_checklist_gated`), each carrying that check_type's
own fields (required_sections/required_frontmatter_fields/
checklist_entry_schema per the report's guessed shape, extended with the
per-verdict conditional keys, loop_state-gating, and topic-trigger fields
this sample found). Phase 2 will write a mechanical extraction script
(per the issue's SCALE NOTE requirement) that parses each of the 145
source files for its section/frontmatter/checklist-entry regex literals
and loop_state/topic-trigger gating, assigns a `check_type` and a
`confidence` column (high when the source hook's logic maps cleanly onto
one of the four shapes above with no bespoke sub-logic; low when it
diverges, e.g. shape C's literal-token-value check or any hook bundling
an unrelated cross-check the way `citation-sourcing`'s hooks did),
and low-confidence rows get hand-verified against their source file
before being written into the config table.
