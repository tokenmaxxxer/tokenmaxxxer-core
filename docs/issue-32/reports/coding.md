# Report: coding (issue-32)

loop_state: landed

## What was done

Applied the approved proposal
`docs/issue-32/proposals/survey-rigor-floor-and-scout-consumption.md`
verbatim to three files:

- `core/contract/role-handoff-contract.md` — added the "Current-state
  survey rigor floor" bullet to section 19, immediately after the
  existing phase-1 bullet's "...The role opens the PR at this point and
  stops." sentence. Purely additive; no existing s19 text reworded.
- `scout/hooks/directive.sh` — added the SURVEY-FIRST ORDER paragraph
  before "THE PROTOCOL, two stages..."; amended STAGE 1's opening clause
  to derive search angles from the survey's gaps/unknowns first; amended
  JUDGE POINT 1 to judge against the surveyed current state; amended the
  SCOUT BRIEF paragraph to add the GAP LINE clause.
- `scout/README.md` — mirrored the same four additions in prose form
  under "## The protocol", kept textually parallel to directive.sh.

Did not touch `scout/hooks/tests/parse-check.sh`, the 5-stage/3min
budget, or the two skip conditions.

## Why

Phase-1 survey (issue-32) found the current-state survey step had no
rigor floor and scout's sweep angles were derived from the issue text
alone, with no consumption of the survey's own gap findings. The
approved proposal closes both gaps with additive text only.

## Upstream basis

`docs/issue-32/proposals/survey-rigor-floor-and-scout-consumption.md`
(approved), building on the phase-1 survey at
`docs/issue-32/reports/coding/survey.md`.

## What did not work

N/A — all edits applied cleanly on the first pass.

## Open findings

None.

## Closed checks

- `bash scout/hooks/tests/parse-check.sh` — passed (exit 0).
