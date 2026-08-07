files:
- core/hooks/record-fields-gate.sh
- core/hooks/tests/run-role-gates-tests.sh

Skip condition (scout-directive): pure bugfix — issue #140 fully specifies the
fix direction with no open design decision; see
docs/issue-140/reports/implementation/survey.md.

## Request

Fix `record-fields-gate.sh`'s sequential-deny staircase (#140): a record
violating N §20 requirements currently gets denied N times, once per attempt,
each time revealing only the next violation — measured at 8,157s / 337
refusals across 76 sessions, 65/65 multi-refusal chains showing a different
reason each time. Fix asks for three structural changes that weaken no check:
accumulate all violations and deny once with the complete set; widen
`RECORD_FIELDS_TERMINAL_STATES` beyond the lone `landed` default and normalize
`-`/`_` before the set test; put the accepted literal strings in the deny
message.

## Constraints

- Weaken no check: every currently-denied write must still be denied.
- Keep the per-role-labeled refusal format (`"${role}: refused — ..."`) other
  gates and tests depend on.
- Stay inside the two files in the write set — no other gate touches this
  logic (confirmed in survey).

## Rationale

Considered rewriting the five checks as a generic `(predicate, label)` list
processed in a loop, instead of hand-accumulating into a `missing` list at each
call site. Rejected: the checks aren't uniform enough for a clean generic
loop — `code_under_review` and the loop_state-terminal check both need extra
context (role, the matched loop_state value) baked into their message, and the
sha-placeholder check already has its own message-building helper
(`deny_placeholder`/`placeholder_shas`) reused by both the proposal and record
paths. A generic loop would need to carry that context through as closures or a
dict anyway, adding a layer of indirection over five call sites for no
behavioral gain — direct accumulation (`missing.append(...)` at each existing
check site, single `deny()` call at the end) gets the same one-deny-per-write
result with a smaller diff and keeps each check's existing message text
recognizable in review.

Considered leaving `RECORD_FIELDS_TERMINAL_STATES` as-is and only fixing the
staircase. Rejected: the issue's evidence shows 87 of 337 refusals come from
terminal-state spelling mismatches alone (`complete`, `closed`, `done`,
`delivered`, and six `-`/`_` spellings of `phase-2-complete`) — fixing only the
staircase would still leave the single largest refusal cause unaddressed.

## What will be done

1. In `record-fields-gate.sh`'s python payload, replace the five sequential
   `deny()` call sites (missing §20 sections, sha placeholder, bare-sha
   `code_under_review`, missing next-steps/resolution-path) with
   `missing.append(...)` onto one list, each message naming the literal
   accepted strings (e.g. `"what was done"`, `"what i did"`) instead of only
   the abstract label. A single `deny()` fires at the end if `missing` is
   non-empty, joining all entries.
2. Widen the `RECORD_FIELDS_TERMINAL_STATES` default from `landed` to
   `landed complete closed done delivered phase-2-complete` and normalize
   both the recorded `loop_state` value and every configured terminal state by
   collapsing `_` to `-` before the set-membership test, so
   `phase_2_complete`/`phase-2_complete`/`phase_2-complete` all match
   `phase-2-complete`.
3. Add pinning tests to `run-role-gates-tests.sh`: a record with 4 missing §20
   fields yields exactly one deny listing all 4; `-`/`_` variants of
   `phase-2-complete` normalize to the same terminal state; `closed`, `done`,
   `complete` are accepted as terminal without an env override; the deny
   message body contains the literal accepted strings.

## Out of scope

- Any other gate file (trailer-gate.sh, handbook-trigger-gate.sh, etc.) —
  none of them share this staircase pattern per survey.
- Documenting the terminal-state literals in a handbook — no handbook
  currently references `RECORD_FIELDS_TERMINAL_STATES`, and the gate's own
  deny message is the discoverability fix the issue asks for.
- Rulebook copies of this gate outside `core/hooks/` (this file is canon per
  issue-66; per-rulebook copies, if any exist, are a separate sync mechanism
  not touched here).

## How you'll know it worked

- `bash core/hooks/tests/run-role-gates-tests.sh` passes, including the new
  issue-140 pinning tests: one deny lists all N violations for a record
  missing multiple §20 fields; `phase-2-complete` and its `-`/`_` variants,
  plus `closed`/`done`/`complete`, are accepted as terminal without an env
  override; the deny message text contains the literal accepted strings.
- `bash core/hooks/tests/run-gate-lib-tests.sh` shows no new failures
  (baseline has one pre-existing, unrelated `compliance-check.sh` failure
  confirmed present on `main` before this change).
