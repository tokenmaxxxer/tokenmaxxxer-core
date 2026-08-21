# Current-state survey — conformance review of issue #263

## Target artifact

`docs/issue-263/reports/implementation.md` (387 lines), delivered by commit
`38052e5` (merged PR #265, "deliver(issue-263): fold record-section-shape
family into parameterized record-shape gate"). Code under review per that
record's frontmatter: `core/hooks/record-shape-gate.sh`,
`core/hooks/record-shape-config.json`, `scripts/extract-record-shape-config.py`,
`core/hooks/tests/run-record-shape-gate-tests.sh`, `core/hooks/tests/run-all.sh`.

## Spec

Issue #263 body, `## Acceptance`, two numbered checks:

1. disposition/extraction table in the record summing to 145, plus the
   extractor command executed-live.
2. harness output + coverage list in the record, fast tier output.

## Requirement extraction (derived from the two acceptance checks)

- R1a: record contains a disposition/extraction table whose rows sum to 145.
- R1b: record shows the extractor command actually executed (not narrated),
  with its live output.
- R2a: record shows harness output (pass/fail counts) for the new
  record-shape-gate test suite.
- R2b: record shows a coverage list — every rulebook × every distinct
  check_type shape.
- R2c: record shows fast-tier (`run-all.sh`) output, green.

## What I checked live (executed, not read-only trust)

- `python3 scripts/extract-record-shape-config.py` — tail: `total=145
  high=86 low=59`. Matches the record's quoted extractor output.
- `grep -c '| promoted-into-config |' docs/issue-263/reports/implementation.md`
  → 145. Matches the extractor total.
- Config file row sum (`sum(len(v) for v in json.load(...).values())`) → 145.
- `bash core/hooks/tests/run-all.sh` → exit 0, `ALL OK`; the record-shape
  block reads `record-shape-gate (issue-263 fold): 53 passed, 0 failed`
  (record's body text says 53 too, after the warrant-hunt fix bumped it
  from 52 — consistent).
- Config JSON has 43 top-level rulebook keys and exactly the 4 check_type
  values the record's coverage section names
  (`checklist_entry_fields`, `section_markers_conditional`,
  `field_literal_token_cooccurrence`, `methodology_checklist_gated`).
- `core/hooks/record-shape-gate.sh` — the `tool == "Bash"` branch (lines
  289-316) calls `deny()`, not a silent pass; matches the record's
  warrant-hunt fix claim.

## Gaps found

- None against the two literal acceptance checks — every claim in the
  record's disposition table, extractor output, coverage list, and fast
  tier section reproduced live.
- The record's own "Rationale for deviations" section discloses a
  completeness gap not covered by the acceptance checks as written: not
  every `confidence: low` row (59 of 145) was individually hand-verified
  against its source hook, contrary to the phase-1 proposal's stated
  method. This is an honest disclosure inside the record, not a
  contradiction of the disposition table's row count — the table still
  sums to 145 and every row got a real, working config assignment. It is
  a candidate finding for phase 2 (Surface vs Present), not a scope gap
  in this survey.

## Skip conditions

Scout-directive skip: not applicable — this is a conformance-review
verification task with a literal, closed spec (two numbered acceptance
checks against one already-delivered record); no product-facing design
decision is open. Scouting is skipped under the "spec leaves no design
decision open" condition.
