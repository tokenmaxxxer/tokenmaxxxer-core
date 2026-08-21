# Survey — issue #260 (phase-4b-3: fold citation-sourcing family)

## Source: classification report

`docs/reports/keep-role-family-classification.md`, on-the-record `main`
(local clone at `/tmp/otr`), names `citation-sourcing` (11 hooks,
disposition `fold`) with target `core/hooks/citation-gate.sh`, guessed
config shape `{rulebook: {claim_patterns: [...], citation_markers:
[...], adjacency_window: N}}` — explicitly a family-boundary guess, the
same caveat #254's and #257's surveys found for their families.

derived: `grep -n "citation-sourcing" /tmp/otr/docs/reports/keep-role-family-classification.md`

## The 11 citation-sourcing hook instances (per-hook rows, classification report)

| rulebook | hook path |
|---|---|
| api-design-rulebook | `api-design/plugins/evidence-citation-gate/hooks/gate.sh` |
| architecture-rulebook | `arch-citation-gate/hooks/citation-gate.sh` |
| capacity-planning-rulebook | `capacity-order-enforcement/hooks/citation-gate.sh` |
| conformance-review-rulebook | `review-traceability/hooks/traceability-gate.sh` |
| finance-unit-economics-rulebook | `finance-evidence-chain/hooks/evidence-chain-gate.sh` |
| interaction-design-rulebook | `interaction-design/plugins/id-citation-format/hooks/citation-gate.sh` |
| interaction-design-rulebook | `interaction-design/plugins/id-traceability/hooks/traceability-gate.sh` |
| requirements-engineering-rulebook | `traceability-matrix-gate/hooks/traceability-matrix-gate.sh` |
| security-threat-model-rulebook | `security-threat-model-canon-citation/hooks/methodology-gate.sh` |
| technical-feasibility-rulebook | `evidence-citation/hooks/citation-gate.sh` |
| test-authoring-rulebook | `traceability-line/hooks/traceability-gate.sh` |

All 11 files were read in full from their own rulebook repo's live
clone (9 under `/home/jwjung/tokenmaxxxer/rulebooks/<rulebook>`, 2 under
`/tmp/idr/interaction-design/plugins/` for interaction-design), not the
classification report's header excerpt.

## What each hook actually checks (real shape, not the report's guess)

Confirmed the report's guessed flat shape does not hold across all 11:
only a minority are a pure "claim_pattern found -> citation_marker
required within adjacency_window" check. Four real sub-shapes exist:

**A. Clean claim-adjacent-to-marker checks (paragraph/section window; 3 of 11)**
- `evidence-citation-gate/gate.sh` (api-design): claim phrase
  (`standard practice|common practice|established practice|is
  standard|conventionally`) requires an RFC number or a
  `per/sourced to/following/...guidelines` marker in the same
  blank-line-delimited paragraph.
- `arch-citation-gate/citation-gate.sh` (architecture): claim phrase
  (`industry practice|well-established|widely used` + Korean
  equivalents) requires a URL or `Sources:` line within the same
  Markdown section (heading-to-heading), falling back to a ±15-line
  window when the file carries no headings.
- `evidence-citation/citation-gate.sh` (technical-feasibility): a
  claim-shaped line (non-comment, ends in `.`/`:`) inside a scoped
  section requires an em-dash/`--`/` - `-prefixed `source:`/URL/
  `path:line` marker on the same or an adjacent line (±1 line); bundles
  a phase-1 section-scope restriction and a phase-2 cross-file
  carry-forward exemption (a claim line verbatim-matching the phase-1
  proposal is exempt) plus a Bash-write blocker on top of the core
  adjacency check.

**B. Whole-document/whole-section existence checks (not per-occurrence adjacency; 4 of 11)**
- `finance-evidence-chain/evidence-chain-gate.sh` (finance-unit-economics):
  two independent sub-checks — a metric-mention trigger requires a
  source-or-assumption marker anywhere in the whole document (no
  proximity at all), and a separate same-paragraph mandate+causal-word
  pair check.
- `id-traceability/traceability-gate.sh` (interaction-design): a
  required section (heading matching `traceability|scope growth`) must
  contain three required fields (`spec-only` boundary, `scope-growth`
  key, `feedback:`) — field presence within one section, not a
  per-claim marker.
- `traceability-line/traceability-gate.sh` (test-authoring): keyword
  presence (`traces|traceability|covers issue|requirement:`) and an
  issue-number reference are checked as two independent whole-document
  booleans with no required co-location, plus an unrelated
  branch-name-vs-issue-reference cross-check.
- `id-citation-format/citation-gate.sh` (interaction-design): the
  per-bullet same-line check (bullet with an exemplar/convention phrase
  requires a same-line `sources:`/URL/`attributed to`/`assumption`
  marker) is real adjacency, but the hook also bundles an independent
  document-level "a `## Sources` heading with a URL/path in its body
  must exist" structural requirement — two checks, only one of which is
  adjacency-shaped.

**C. Table/cell-shape checks, not claim-marker adjacency (1 of 11)**
- `traceability-matrix-gate.sh` (requirements-engineering): every
  `REQ-*` token found in the record must appear as a row in a
  "traceability matrix" markdown table with 4 required columns
  (ID/Description/Source/Downstream Link) and reference-shape-valid
  Source/Downstream Link cells. This is membership-in-a-table plus
  cell-shape validation, structurally unlike the other 10.

**D. Sequencing/anti-pattern checks with no claim-marker relationship (2 of 11)**
- `capacity-order-enforcement/citation-gate.sh` (capacity-planning):
  gated on a terminal-state trigger (`loop_state: terminal` etc.), then
  requires a required upstream-document filename token
  (`survey.md`/`scout-brief.md`) to appear within ~200 chars of an
  anchor phrase (`basis:`/`sources:`/a rationale heading) — a
  document-sequencing citation, not a prose claim.
- `security-threat-model-canon-citation/methodology-gate.sh`
  (security-threat-model): inverted shape — a `canon-references`
  section must NOT contain pasted script artifacts (shebang lines,
  `PreToolUse`, `set -uo pipefail` tokens). No citation marker is
  required at all; this is an anti-paste check, opposite in shape from
  the rest of the family.
- `review-traceability/traceability-gate.sh` (conformance-review): its
  phase-2 sub-check (`verdict:` line requires `spec_ref:` always, plus
  `evidence:` unless verdict is Unverifiable, within the same block) is
  clean adjacency; its phase-1 sub-check (requires a ≥2-item requirement
  list or a "sampling derivation" phrase) is an unrelated list-shape
  check, and a Bash-write interceptor is bundled on top.

## Existing core gates checked for overlap (covered-by-core candidates)

Grepped `core/hooks/*.sh` for REQ-id table logic, shebang/script-paste
detection, and branch-name cross-reference logic — none exist in core
today (`record-fields-gate.sh`/`record-shape-gate.sh` check section/
frontmatter shape, not table-cell or anti-paste content;
`trailer-gate.sh` checks commit trailers, not branch-name-vs-in-doc
issue refs). No hook in this family is already redundant with a landed
core gate — all 11 are candidates for `promoted-into-config`, none for
`covered-by-core`.

derived:
```
grep -rl "shebang\|script.paste\|#!/" core/hooks/*.sh   # no hits besides this family's own future file
grep -rln "REQ-" core/hooks/*.sh                          # no hits
grep -rln "branch.*name" core/hooks/*.sh                  # gh-guard.sh, board-gate.sh, directive.sh -- unrelated (PR/board state, not issue-ref cross-check)
```

## Implication for config shape

Following #254's (`facet-keyword-gate.sh`'s `CHECKERS` dispatch keyed by
`check_type`) and #257's (`ordering-norm-gate.sh`'s `mode`/`extra_checks`
fields) precedent: the classification report's flat
`{claim_patterns, citation_markers, adjacency_window}` shape covers only
3 of 11 hooks cleanly. A `check_type`-dispatched config (mirroring
`facet-keyword-gate.sh`'s proven `CHECKERS` table) is needed to
reproduce all 11 behavior-equivalently under one gate, each hook keeping
its own row with a `check_type` naming its real mechanism
(`claim_adjacent_marker`, `whole_doc_metric_source`,
`section_required_fields`, `whole_doc_keyword_and_ref`,
`table_req_membership`, `sequencing_filename_anchor`,
`anti_pattern_section`, `verdict_field_required`, plus each hook's
bundled `extra_checks`), not a single generalized regex-adjacency
mini-language.
