---
code_under_review: `core/hooks/record-fields-gate.sh`, `core/hooks/tests/run-role-gates-tests.sh`
loop_state: landed
---

upstream: docs/issue-140/proposals/2026-08-07-accumulate-record-fields-violations.md, sha: same-commit

## What was done

Fixed the record-fields-gate.sh staircase (#140):

1. Replaced the five sequential `deny()` + `sys.exit(2)` call sites (missing
   §20 sections, sha placeholder, bare-sha `code_under_review`, missing
   next-steps/resolution-path) with `missing.append(...)` onto one list; a
   single `deny()` fires at the end listing every violation, joined with `; `.
   Each entry now names the literal accepted strings (e.g.
   `"what was done", "what i did"`) instead of only the abstract label.
2. Widened `RECORD_FIELDS_TERMINAL_STATES`'s default from `landed` to
   `landed complete closed done delivered phase-2-complete`, and added
   `norm_state()` which collapses `_` to `-` before the terminal-state
   membership test, so `phase_2_complete`/`phase-2_complete` normalize the
   same as `phase-2-complete`.
3. Added pinning tests to `run-role-gates-tests.sh`: one deny lists all 4
   missing sections for a record with only `loop_state: landed`;
   `phase-2-complete`'s `-`/`_` variants and `closed`/`done`/`complete`
   normalize to terminal without an env override; the deny message body
   contains the literal accepted strings.
4. (PR #143 feedback) `norm_state()` normalized `-`/`_` but not the digit
   boundary, so `phase2-complete`/`phase2_complete` still normalized to
   `phase2-complete`, distinct from `phase-2-complete`, and were still
   misclassified NON-TERMINAL — a large share of the issue's measured 87
   terminal-state refusals per the feedback. Fixed by inserting `-` across
   every letter/digit boundary in `norm_state()` (`phase2` -> `phase-2`)
   before the terminal-state set test. Extended the pinning test to loop
   over all 11 spellings from the feedback comment's table (`landed`,
   `complete`, `closed`, `done`, `delivered`, `phase-2-complete`,
   `phase-2_complete`, `Complete`, `COMPLETE`, `phase2-complete`,
   `phase2_complete`) asserting each is accepted as terminal, plus a
   non-terminal control (`in_progress`) pinned both denied-without and
   allowed-with the required next-steps/resolution-path fields.

## Why

Issue #140 measured 8,157s / 337 refusals across 76 of 222 sessions from this
gate's staircase behavior — each deny revealed only the next violation, so
65/65 multi-refusal chains hit a different reason every attempt. The fix
direction (accumulate + deny once, widen terminal states + normalize `-`/`_`,
surface accepted literals) was given in the issue and weakens no check —
confirmed by running the full pre-existing test suite before and after (same
pass/fail set, one pre-existing unrelated failure in
`compliance-check.sh` present on `main` before this change).

## What did not work

None.

## Doc placement

- [x] `docs/handbooks/role-gates-tests.md` updated: documents the
  accumulate-once behavior and the widened, normalized
  `RECORD_FIELDS_TERMINAL_STATES` default (handbook-trigger-gate.sh caught
  the missing update on first commit attempt and this addresses it).
- No decision record or report doc applies: no new env var, config key,
  dependency, migration, public signature, or wire-format change — only the
  default *value* of an existing env var changed.

## Open findings

None.

## Hunt

No warrant-hunter dispatch this session — single-file bugfix, self-contained
gate logic, verified directly against the existing subprocess test harness
(`run-role-gates-tests.sh`) rather than a separate hunt pass. `verify` should
re-derive coverage from the diff and the new pinning tests rather than cite
this record's own test run as closed.
