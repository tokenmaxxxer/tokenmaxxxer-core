---
status: proposed
files:
  - core/hooks/ordering-gate.sh
  - core/hooks/hooks.json
  - tests/test_promoted_hooks.py
  - tests/test_ordering_gates_237.py
  - docs/handbooks/ordering-gate.md
---

# Proposal — issue-240: consolidate role-scoped ordering gates into one parameterized gate

## Request

core#234 + core#237 landed 8 role-scoped ordering-gate scripts under
`core/hooks/` whose only real differences are surface path(s), required
sibling file(s), and one of four verification mechanisms (file-existence,
content-citation regex, cross-file lookup, JSON-cache-backed two-way
precondition). Consolidate them into one parameterized `ordering-gate.sh`
that dispatches on a per-role table, preserving each gate's behavior
byte-for-byte, wire it into `hooks.json` in place of the 8 entries, and
retarget the two existing test files at the new filename with assertions
unchanged. Net `core/hooks` gate-file count must decrease.

## Constraints

- Every assertion in `tests/test_promoted_hooks.py` (9 tests) and
  `tests/test_ordering_gates_237.py` (21 tests) must keep passing;
  changes to those files are limited to the `run_gate("<file>.sh", ...)`
  filename argument — no payload or `assert` line changes (per #237's
  equivalence table being the frozen spec).
- Old per-role gate files (`arch-sequence-gate.sh`,
  `content-design-phase1-basis-gate.sh`, `devrel-phase-order-gate.sh`,
  `incident-response-order-gate.sh`, `interaction-design-stage-order-gate.sh`,
  `issue-retrospective-proposal-order-gate.sh`,
  `security-threat-model-sequence-gate.sh`, `survey-order-gate.sh`) are
  removed only in this same PR, alongside the equivalence proof (the test
  run against the new gate).
- `record-fields-gate.sh`, `proposal-shape-gate.sh`, `record-shape-gate.sh`
  are out of scope (different concern: field/document-shape completeness,
  not write ordering — the issue text asides them explicitly).
- `hooks.json` must stay valid JSON (checked via `python3 -c
  "import json; json.load(open('core/hooks/hooks.json'))"`, recorded in
  the implementation record).
- Kill-switch behavior is preserved per role (each role keeps its own env
  var name, e.g. `PHASE_ORDER_GATE_OFF`, checked before that role's rule
  fires) so existing operator overrides keep working unchanged.
- Each role's surface regex is carried over verbatim as it stands on
  `main` today, including the issue-242 filename-scoping fix already
  landed for the 3 previously-unscoped gates (interaction-design,
  content-design, security-threat-model) — no further scoping change.

## Rationale

Alternative considered: extract only the shared plumbing (`_plausible`
path-normalize helper, project-root resolution, fail-closed EXIT trap —
byte-identical across 5 of the 8 scripts today) into `gate-lib.sh`, and
leave 8 thin per-role scripts in place. Rejected: this reduces
duplication but does not shrink `core/hooks` gate-file count, and leaves
the exact accumulation shape the issue calls out — one new file added per
future role — unaddressed. It fails acceptance criterion 2 ("net
hook-file count under core/hooks decreases") on its face.

Chosen approach: a single script whose Python payload holds a per-role
table (surface regex(es), required sibling file(s), mechanism tag) and
dispatches by matching the target path against each role's surface
regex(es) in first-match-wins order, falling through to no-op when
nothing matches (preserving today's "sessions with no role match pass
through silently" empty-state). Each of the four mechanisms observed in
the survey (file-existence, content-citation regex, cross-file lookup,
JSON-cache two-way precondition) becomes one dispatched function keyed by
the table's mechanism tag, ported from the matching original script with
no logic change — this is the only option that both shrinks file count
and keeps every gate's own mechanism verbatim, per the survey's
Alternatives section.

## What will be done

1. Write `core/hooks/ordering-gate.sh`: shared bootstrap (source
   `gate-lib.sh`, `gate_trap_fail_closed`, JSON payload parse, Bash-target
   reconstruction) run once, then a single `python3` heredoc holding:
   - a `ROLES` table: one entry per of the 8 original gates, carrying its
     surface regex(es) (as they stand on `main` post-#242), required
     file(s), direction (proposal-side vs. record-side vs. both), and
     mechanism tag, transcribed from the survey's per-gate table;
   - one dispatch function per mechanism tag (`file_exists`,
     `content_regex`, `cross_file_lookup`, `json_cache_precondition`),
     each a direct port of the corresponding original script's Python
     logic with variable renames only;
   - a kill-switch check per matched role before that role's function
     runs, using that role's original env-var name.
2. Update `core/hooks/hooks.json`: remove the 8 individual `command`
   entries under `PreToolUse`, add one entry for `ordering-gate.sh`
   inserted at the position of the first removed entry (preserving
   relative order against non-ordering gates in the array).
3. Update `tests/test_promoted_hooks.py` and
   `tests/test_ordering_gates_237.py`: change every
   `run_gate("<original-filename>.sh", ...)` call to
   `run_gate("ordering-gate.sh", ...)`; no other line in either file
   changes.
4. Delete the 8 original per-role gate scripts.
5. Add `docs/handbooks/ordering-gate.md` documenting the per-role table
   shape and how to add a new role's ordering rule (the doc-placement
   ladder step for a changed setup/config surface).
6. Run both test files via the fast tier and record the pass output, plus
   the `hooks.json` `json.load` check and `git diff --stat` file list, in
   the implementation record.

## Out of scope

- `record-fields-gate.sh`, `proposal-shape-gate.sh`, `record-shape-gate.sh`
  (different concern, explicitly asided by the issue text).
- Adding new roles or new ordering rules beyond the 8 being consolidated.
- Changing any role's required-file set, surface regex, or kill-switch
  variable name — behavior is preserved byte-for-byte, not redesigned.
- Extracting `gate-lib.sh` further or refactoring shared plumbing beyond
  what consolidation itself requires.

## How you'll know it worked

- `tests/test_promoted_hooks.py` and `tests/test_ordering_gates_237.py`
  pass unchanged-assertion runs against `ordering-gate.sh` via the fast
  tier (pytest output pasted into the record, including any SKIPPED
  lines).
- `python3 -c "import json; json.load(open('core/hooks/hooks.json'))"`
  succeeds, recorded in the record.
- `git diff --stat` against `main` shows a net decrease in `core/hooks`
  gate-file count (8 files removed, 1 added) and no assertion-line diff
  in either test file (only `run_gate(...)` filename arguments change).
