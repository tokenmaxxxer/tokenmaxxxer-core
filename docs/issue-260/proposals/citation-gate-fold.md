---
status: proposed
files:
  - core/hooks/citation-gate.sh
  - core/hooks/citation-config.json
  - core/hooks/hooks.json
  - core/hooks/tests/test_citation_gate.py
---

files:
  - core/hooks/citation-gate.sh
  - core/hooks/citation-config.json
  - core/hooks/hooks.json
  - core/hooks/tests/test_citation_gate.py

## Request

Third fold of skill-axis phase-4b, following the validated #254/#257
pattern. Fold the `citation-sourcing` family (11 hook instances across
9 rulebooks, per `docs/reports/keep-role-family-classification.md` on
on-the-record main) — PreToolUse gates requiring a citation/source/
traceability marker adjacent to a flagged claim — into one parameterized
`core/hooks/citation-gate.sh`, behavior-equivalent to each source hook
under its own config row. Per hook, disposition as `promoted-into-config`
or `covered-by-core`. Promote-first: no rulebook file modified.

#260

## Constraints

- Behavior-equivalent per hook: each source hook's allow/refuse verdict
  on realistic content must be reproduced by the core gate under that
  hook's config row (per [[survey.md]]'s per-hook table).
- Live-fire tests only (issue #248's lesson) — tests invoke the gate
  entrypoint with real PreToolUse JSON on stdin, not unit-test the
  Python helpers in isolation.
- bash-3.2-safe: no heredoc inside command substitution (issue #245's
  guard test must stay green).
- Promote-first: none of the 9 rulebooks' hook files or `hooks.json`
  entries are modified or removed in this pass.
- No new dependency; reuse `core/hooks/lib/gate-lib.sh` and its existing
  `gate_reconstruct_write`/`gate_normalize_path` helpers, already used
  by all 11 source files and by the landed `record-fields-gate.sh`/
  `record-shape-gate.sh`/`facet-keyword-gate.sh`/`ordering-norm-gate.sh`
  folds.

## Rationale

**Config shape: `{rulebook: [{hook, kill_switch_env, target_path_regex,
check_type, ...check_type-specific fields}]}` dispatched through a
`CHECKERS` table keyed by `check_type`, not the classification report's
flat `{rulebook: {claim_patterns, citation_markers, adjacency_window}}`.**
Considered adopting the report's guessed shape verbatim — it is the
frozen family definition and would need no new design discussion.
Rejected: per [[survey.md]], only 3 of the 11 source files (api-design,
architecture, technical-feasibility) are a clean claim-pattern-found
→ citation-marker-within-window check. The other 8 are whole-document/
whole-section existence checks with no proximity requirement (finance,
id-traceability, test-authoring), a table/cell-shape membership check
(requirements-engineering), a document-sequencing filename-anchor check
(capacity-planning), an inverted anti-paste check with no citation
marker at all (security-threat-model), a per-bullet check bundled with
an unrelated document-level Sources-heading requirement
(id-citation-format), and a phase-2 clean check bundled with an
unrelated phase-1 list-shape check and a Bash-write interceptor
(conformance-review). A flat shape would force either dropping 8 hooks
from the fold (breaking check 1's per-hook-disposition acceptance
criterion — dropping yields neither `promoted-into-config` nor
`covered-by-core`) or stuffing unrelated logic into `claim_patterns` as
an ad hoc mini-language, which #254 and #257 already rejected for the
same reason on their own families. This mirrors `facet-keyword-gate.sh`'s
already-landed `CHECKERS` dict keyed by `check_type` — the same
config-table-dispatch mechanism, extended with this family's own
check_type vocabulary instead of a new mechanism.

**All 11 hooks disposition `promoted-into-config`; none `covered-by-core`.**
Considered checking whether any of the 8 non-clean-adjacency hooks were
already redundant with a landed core gate (record-fields-gate.sh,
record-shape-gate.sh, trailer-gate.sh) and could be dispositioned
`covered-by-core` instead of folded. Rejected after grepping `core/
hooks/*.sh` for REQ-id table logic, shebang/script-paste detection, and
branch-name-vs-issue-ref cross-checks (per [[survey.md]]'s "Existing
core gates checked for overlap" section) — none exist; every one of the
11 hooks checks content no landed core gate currently checks, so all 11
are `promoted-into-config`.

## What will be done

1. Write `core/hooks/citation-config.json`: 11 entries (one per source
   file, `security-threat-model-canon-citation` keeping its file-derived
   role name as-is), each row carrying `hook`, `kill_switch_env`,
   `target_path_regex` (per-phase where the source hook has one, e.g.
   technical-feasibility's phase1/phase2 pair), `check_type` (one of
   `claim_adjacent_marker`, `whole_doc_metric_source_and_paragraph_pair`,
   `section_required_fields`, `whole_doc_keyword_and_ref_plus_branch`,
   `table_req_membership`, `sequencing_filename_anchor`,
   `anti_pattern_section`, `bullet_adjacent_plus_doc_sources`,
   `verdict_field_required_plus_list_shape`), and the check_type's
   specific fields (claim/marker regex pairs, window size, required
   field lists, table column specs, anchor/token pairs, forbidden-token
   lists) reproducing that hook's real logic per [[survey.md]]'s
   per-hook breakdown — including each hook's bundled extra checks
   (technical-feasibility's phase-1 section-scope + phase-2 carry-forward
   exemption; conformance-review's phase-1 list-shape check;
   id-citation-format's document-level Sources-heading check;
   test-authoring's branch-name cross-reference), named per hook, not
   generalized into one mini-language.
2. Write `core/hooks/citation-gate.sh`: sources `gate-lib.sh`, reads the
   payload via `payload="$(cat)"` (issue #245-safe, env-relayed into the
   Python heredoc exactly as `facet-keyword-gate.sh`/`ordering-norm-gate.sh`
   already do), loads the config JSON, resolves the acting role via
   `CLAUDE_ROLE`, and for each matching config row: target-path match →
   dispatch to the row's `check_type` handler in a `CHECKERS` table →
   deny with the per-hook message shape on failure. Passes silently
   (exit 0) when no row matches the acting role (empty state) or the
   config file is absent/malformed (no-op) — same empty-state contract
   as the landed folds. Bash-tool writes to a governed path are refused
   as unverifiable (same as `facet-keyword-gate.sh`'s Bash-write
   handling) for hooks whose source carried that behavior
   (conformance-review, technical-feasibility).
3. Register the new gate in `core/hooks/hooks.json` under PreToolUse.
4. Write `core/hooks/tests/test_citation_gate.py`: live-fire cases
   invoking the gate binary with real PreToolUse JSON on stdin via the
   fast tier — one allow + one refuse case per configured role (11),
   plus an empty-state case (unconfigured role passes silently) and a
   no-config-file case (gate file absent → no-op), matching #254/#257's
   test shape.
5. Record `docs/issue-260/reports/implementation.md`: the 11-row
   disposition table (all `promoted-into-config`), `git diff` file list,
   and fast tier output (including the heredoc guard).

## Out of scope

- Modifying any of the 9 rulebooks' hook files, plugin manifests, or
  `hooks.json` entries — promote-first, source hooks keep running
  unmodified.
- The `record-section-shape` (145), `ordering-methodology` (18, landed
  #257), `facet-keyword` (8, landed #254), `role-directive` (113,
  demoted), and `field-format-numeric` (5, demoted) families — separate
  issues.
- Migrating any rulebook to skill-axis phase-3 guidance text — this
  issue is core-landing only, per the classification report's
  migration-blocking map (a rulebook maps only after all its
  dispositioned-fold families have landed in core).
- Generalizing `check_type` handlers beyond what the 11 source hooks
  need; no speculative check_types for hooks outside this family.

## How you'll know it worked

- `docs/issue-260/reports/implementation.md` carries the 11-row
  disposition table (rulebook, hook file, check_type, disposition) with
  every row `promoted-into-config`.
- Fast tier (`core/hooks/tests/`, `test_citation_gate.py` included) runs
  green, output pasted in the record, including the bash-3.2 heredoc
  guard test.
- `git diff --stat` file list in the record shows only
  `core/hooks/citation-gate.sh`, `core/hooks/citation-config.json`,
  `core/hooks/hooks.json`, `core/hooks/tests/test_citation_gate.py`, and
  `docs/issue-260/**` — no rulebook path touched.
- Live-fire cases demonstrate: an unconfigured role passes silently
  (empty state), a missing config file no-ops, and each of the 11
  configured roles both allows compliant content and refuses content
  matching its source hook's original refuse case.
