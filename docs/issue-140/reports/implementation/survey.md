Skip condition: pure bugfix (scout-directive). Issue #140 fully specifies the fix
direction (accumulate violations, widen terminal states + normalize `-`/`_`, emit
accepted literals) with no open design decision — no exemplar field to scout.

# Current-state survey — issue-140

Write set: `core/hooks/record-fields-gate.sh` (single file, ~261 lines) and its test
coverage `core/hooks/tests/run-role-gates-tests.sh`.

`record-fields-gate.sh` is a PreToolUse gate. Its python payload (lines 96-255)
checks §20 record fields in this order, each with its own `deny()` (which calls
`sys.exit(2)` immediately):
- `is_proposal` sha placeholder check (lines 190-194) — separate artifact kind,
  single check, already denies once. Out of scope.
- missing §20 sections: what-was-done, why, upstream-basis, loop_state,
  open-findings (lines 201-221) — first `deny()`, exits before any later check runs.
- sha placeholder re-check for records (lines 223-225).
- `code_under_review` bare-sha check, coding/implementation only (lines 227-235).
- loop_state terminal-state check + next-steps/resolution-path (lines 237-249),
  gated on `TERMINAL = set(os.environ["RF_TERMINAL"].split())` where
  `RF_TERMINAL` defaults to the single value `landed` (line 95).

Each stage's `deny()` exits the whole process, so a record violating multiple
checks only ever surfaces the first one — exactly the staircase issue-140
measures (8,157s / 337 refusals / 65-of-65 multi-refusal chains with a
different reason each attempt).

`has_any()` (line 198) already accepts several literal spellings per section
(e.g. `"what was done"`, `"what i did"`, `"## done"`) but the `deny()` messages
at lines 218-221 and 246-249 name only the abstract label (`what-was-done`,
`next-steps`), never the literal strings `has_any()` actually tests — the
model has to guess.

Existing test coverage: `core/hooks/tests/run-role-gates-tests.sh` exercises this
gate via `run_rf()` (subprocess, real payload on stdin), covering the single-violation
deny/allow cases, `RECORD_FIELDS_TERMINAL_STATES` override, `code_under_review`
bare-sha, and the sha placeholder allow-list. No existing test asserts a
multi-violation write gets one deny listing everything, and no test exercises the
default terminal-state set beyond `landed`.

Alternative considered: rewrite the checks as a declarative list of
`(predicate, label)` pairs and loop generically. Rejected in the proposal's
Rationale (not needed for this fix — see proposal) but it was on the table
during survey since the current five checks are structurally near-identical
(each is "test predicate, append/deny with message").

Nothing outside `core/hooks/record-fields-gate.sh` and its test file needs to
change: no other gate imports this file's checks, and no handbook documents the
literal `landed`-only terminal-state default (checked via grep for
`RECORD_FIELDS_TERMINAL_STATES` — only referenced in the gate script itself and
in the test file's override case).
