---
status: proposed
files:
  - core/hooks/record-shape-gate.sh
  - core/hooks/record-shape-config.json
  - core/hooks/hooks.json
  - core/hooks/tests/test_record_shape_gate.py
  - scripts/extract-record-shape-config.py
---

files:
  - core/hooks/record-shape-gate.sh
  - core/hooks/record-shape-config.json
  - core/hooks/hooks.json
  - core/hooks/tests/test_record_shape_gate.py
  - scripts/extract-record-shape-config.py

## Request

Fourth and final fold of skill-axis phase-4b, following the validated
#254/#257/#260 pattern. Fold the `record-section-shape` family (145 hook
instances across all 43 rulebooks, per
`docs/reports/keep-role-family-classification.md` on on-the-record
main) — PreToolUse gates checking a phase-1 proposal or phase-2 record
for required sections, headings, frontmatter fields, or named-methodology
checklist entries — into the existing `core/hooks/record-shape-gate.sh`,
extended with a config table, behavior-equivalent to each source hook
under its own config row. Per hook, disposition as
`promoted-into-config` or `covered-by-core`. Promote-first: no rulebook
file modified. Given the family's scale, delivery includes a mechanical
extraction script (`scripts/extract-record-shape-config.py`) that parses
each of the 145 source hooks into a config row with a per-row
extraction-confidence column; only low-confidence rows are hand-verified.

#263

## Constraints

- Behavior-equivalent per hook: each source hook's allow/refuse verdict
  on realistic content must be reproduced by the extended core gate under
  that hook's config row (per [[survey.md]]'s per-shape breakdown).
- Live-fire tests only (issue #248's lesson) — tests invoke the gate
  entrypoint with real PreToolUse JSON on stdin, not unit-test Python
  helpers in isolation. Coverage requirement (per the issue's acceptance
  criterion 2): every rulebook covered at least once, and every distinct
  `check_type` schema shape covered at least once — not one test per
  hook (145 would be disproportionate to the other folds' test counts).
- bash-3.2-safe: no heredoc inside command substitution (issue #245's
  guard test must stay green).
- Promote-first: none of the 43 rulebooks' hook files or `hooks.json`
  entries are modified or removed in this pass.
- `core/hooks/record-shape-gate.sh`'s existing hardcoded behavior (the
  `implementation` role's own phase-2 record shape, landed under core
  issue #52) must keep working unchanged after the extension — regression
  risk unique to this fold, since #254/#257/#260 built new files while
  this one extends a file with its own live, already-enforced behavior.
- No new dependency; reuse `core/hooks/lib/gate-lib.sh` and its existing
  `gate_reconstruct_write`/`gate_normalize_path` helpers, already used by
  the landed `record-fields-gate.sh`/`record-shape-gate.sh`/
  `facet-keyword-gate.sh`/`ordering-norm-gate.sh`/`citation-gate.sh`
  folds. `scripts/extract-record-shape-config.py` uses only Python's
  standard library (`re`, `json`, `pathlib`) — no new dependency.

## Rationale

**Config shape: `{rulebook: [{hook, kill_switch_env, target_path_regex,
check_type, ...check_type-specific fields, extraction_confidence}]}`
dispatched through a `CHECKERS` table keyed by `check_type`, with four
initial check_types (`checklist_entry_fields`,
`section_markers_conditional`, `field_literal_token_cooccurrence`,
`methodology_checklist_gated`), not the classification report's flat
`{surface, required_sections, required_frontmatter_fields,
checklist_entry_schema}` shape.** Considered adopting the report's
guessed shape verbatim, as #260 first considered for citation-sourcing.
Rejected for the same reason #260 rejected it: per [[survey.md]]'s
four-shape sample, only shape A (`wcag-em-gate`) cleanly matches the
report's `checklist_entry_schema` guess, and even that shape has
per-verdict conditional required keys (fail→remediation,
not-applicable→scope-note) the flat guess does not express. Shape B
(`arch-adr-content-gate`) is a `loop_state`-conditional section-marker
check; shape C (`deprecation-plan-gate`) is a literal-token-value
co-occurrence check inside one field, not a presence check at all; shape
D (`kimball-gate` and its `methodology-gate.sh`-named siblings across
data-modeling, ml-engineering, and security-threat-model) is a
topic-keyword-gated fixed methodology checklist. A flat shape would
force dropping most of the sample from clean representation, repeating
the exact failure mode #260's survey already documented for
citation-sourcing. This mirrors `citation-gate.sh`'s own `CHECKERS`
pattern (extended with a `check_type` vocabulary for this family) rather
than inventing a new mechanism.

**Mechanical extraction with a confidence column, not a full manual
per-hook read, given the 4x scale jump over the prior three folds
combined (145 vs. 11+8+18=37).** Considered repeating #254/#257/#260's
method of reading every source file in full before writing its config
row. Rejected: the issue's own SCALE NOTE names this explicitly ("145
scripts is too many for one sitting to hand-verify"), and
[[survey.md]]'s four-shape sample (4 hooks read in full) already shows
the family's variation is bounded and mechanically detectable — each
shape's required-section/field/checklist-entry literals are extractable
via regex against each source file's own literal patterns
(`required_sections`-style heading regexes, frontmatter key regexes,
checklist-entry marker + required-key-list literals), the same kind of
literal-pattern matching the source hooks themselves perform. A script
that extracts these patterns and flags any hook whose logic does not
cleanly reduce to one of the four known check_types (bundled unrelated
sub-checks, a fifth shape not yet seen, or a parse failure) as
low-confidence gives the acceptance criterion's required per-hook
disposition at 145-hook scale without silently guessing on rows the
extractor cannot confidently characterize — those get the manual read
[[survey.md]]'s sample already demonstrated is reliable.

**Extend `core/hooks/record-shape-gate.sh` in place rather than write a
new `core/hooks/record-shape-family-gate.sh` alongside it.** Considered
keeping the two concerns separate — the existing file's
`implementation`-role hardcoded check, and this fold's 145
rulebook-hook config rows — as two files sharing only a name prefix, to
avoid regression risk on the live-enforced existing behavior.  Rejected:
the classification report's family row explicitly names
`record-shape-gate.sh` as this fold's target, not a new file, and
`facet-keyword-gate.sh`/`ordering-norm-gate.sh`/`citation-gate.sh` all
established the pattern of one gate file dispatching many roles through
one config table — a second gate file here would fork that established
pattern for no reason beyond risk-aversion, and the existing hardcoded
check converts cleanly into one unconditional default row (or a reserved
`implementation` config row) exercised by the new `test_record_shape_gate.py`
alongside the 145 rulebook rows, keeping the regression risk covered by
tests rather than by file separation.

## What will be done

1. Write `scripts/extract-record-shape-config.py`: walks the 43 rulebook
   repos' 145 hook files listed in [[survey.md]] (repo-relative paths
   read from the survey's table, not re-derived), for each file
   attempts to classify it into one of the four `check_type`s found in
   [[survey.md]] by regexing for that shape's literal patterns (heading/
   marker regexes, frontmatter key regexes, checklist-entry key lists,
   `loop_state`/topic-trigger gating), extracts the check_type-specific
   fields, and emits one config-row candidate per hook plus a
   `confidence: high|low` column (high = classification matched exactly
   one check_type with no unrecognized bundled logic; low = ambiguous,
   multi-shape, or unparseable). Prints a summary table (145 rows,
   rulebook / hook / check_type / confidence) to stdout — this is the
   extractor command the record documents as executed-live per
   acceptance criterion 1.
2. Hand-verify every `confidence: low` row against its source file
   (reading it in full, the same method [[survey.md]]'s sample used),
   correcting its check_type/fields as needed, and mark it
   `confidence: low (hand-verified)` in the final table — never silently
   promoted un-reviewed.
3. Write `core/hooks/record-shape-config.json`: the 145 rulebook rows
   (post hand-verification) plus one row (or an unconditional default,
   whichever the implementation shows preserves current behavior most
   directly) reproducing `record-shape-gate.sh`'s existing
   `implementation`-role check unchanged.
4. Extend `core/hooks/record-shape-gate.sh`: add a `CHECKERS` dispatch
   table keyed by `check_type` (four handlers per [[survey.md]]'s
   shapes), load `record-shape-config.json`, resolve the acting role via
   `CLAUDE_ROLE`, and for each matching config row: target-path match →
   dispatch to the row's check_type handler → deny with the per-hook
   message shape on failure. The existing hardcoded logic (lines
   93-205 of the current file) is preserved as the `implementation`
   role's own code path, either as its dedicated config row through the
   new dispatch or left as an early-exit default before config dispatch
   — decided during implementation by whichever keeps its current tests
   passing unmodified. Passes silently (exit 0) when no row matches the
   acting role (empty state) or the config file is absent/malformed
   (no-op) — same empty-state contract as the landed folds.
5. Register `record-shape-gate.sh` in `core/hooks/hooks.json` (already
   registered for the `implementation` role's PreToolUse; confirm the
   registration still matches after the extension, no new entry needed
   unless the extension changes its role-matching behavior).
6. Write `core/hooks/tests/test_record_shape_gate.py`: live-fire cases
   invoking the gate binary with real PreToolUse JSON on stdin via the
   fast tier — per acceptance criterion 2, coverage across every one of
   the 43 rulebooks at least once and every distinct check_type shape at
   least once (not 145 individual cases), plus the existing
   `implementation`-role regression cases carried over unchanged, an
   empty-state case (unconfigured role passes silently), and a
   no-config-file case (gate file absent → no-op).
7. Record `docs/issue-263/reports/implementation.md`: the 145-row
   disposition/extraction table (rulebook, hook file, check_type,
   confidence, disposition — summing to 145 per acceptance criterion 1),
   the extractor command's live-executed output, the coverage list
   (rulebooks × check_types), and fast tier output including the
   heredoc guard.

## Out of scope

- Modifying any of the 43 rulebooks' hook files, plugin manifests, or
  `hooks.json` entries — promote-first, source hooks keep running
  unmodified.
- The `role-directive` (113, demoted) and `field-format-numeric` (5,
  demoted) families — separate issues, not folds.
- Re-classifying `deprecation-plan-gate`'s shape-C literal-token-value
  check out of `record-section-shape` into `field-format-numeric` even
  though it structurally resembles that sibling demoted family — the
  classification report placed it here; re-classification is a
  classification-report change, not this issue's business.
- Migrating any rulebook to skill-axis phase-3 guidance text — this
  issue is core-landing only.
- A fifth or later `check_type` for shapes not found in
  [[survey.md]]'s sample — if the mechanical extraction pass (step 1-2)
  surfaces a shape the sample missed, it is added at that point as part
  of this same delivery (the extraction step is exactly what makes this
  discoverable at 145-hook scale); no speculative check_types added
  ahead of what the extractor actually finds.

## How you'll know it worked

- `docs/issue-263/reports/implementation.md` carries the 145-row
  disposition/extraction table (rulebook, hook file, check_type,
  confidence, disposition) summing to 145, plus the extractor command
  shown executed live (per acceptance criterion 1).
- The record shows every `confidence: low` row was hand-verified before
  being written into the config, with the verification noted per row.
- Fast tier (`core/hooks/tests/`, `test_record_shape_gate.py` included)
  runs green, output pasted in the record, including the bash-3.2
  heredoc guard test.
- The record's coverage list shows every one of the 43 rulebooks
  exercised at least once and every distinct `check_type` shape
  exercised at least once (per acceptance criterion 2), plus the
  existing `implementation`-role case still passing.
- `git diff --stat` file list in the record shows only
  `core/hooks/record-shape-gate.sh`, `core/hooks/record-shape-config.json`,
  `core/hooks/hooks.json`, `core/hooks/tests/test_record_shape_gate.py`,
  `scripts/extract-record-shape-config.py`, and `docs/issue-263/**` — no
  rulebook path touched.
