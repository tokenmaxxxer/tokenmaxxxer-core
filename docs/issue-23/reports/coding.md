# coding record — issue-23

loop_state: landed
subject: issue-23
upstream basis: docs/issue-23/proposals/coding.md, approved via `APPROVE issue-23/coding` on PR #24; code_under_review base sha 2918638956059467c225a2bb1fc8b5247ba603c5

## What was done

Edited `scout/hooks/directive.sh` (the `THE PROTOCOL` / `NEVER` blocks of
the injected `<scout-directive>`) and `scout/README.md` ("## The
protocol" section) to replace the single-pass, two-judge-point scout
protocol with a two-stage protocol: stage 1 sweep (parallel fan-out
across up to 4 search angles, no judgment interleaved, named
batched-sequential fallback if parallelism unavailable), then stages
2-5 observe-and-deepen (judgment moved here: judge sweep results,
snowball-deepen only on decision-relevant hits, saturation stop rule).
Hard budget 5 stages total, soft budget ~2min wall-clock.

## Why

Issue #23 + approved proposal docs/issue-23/proposals/coding.md (PR #24,
approved via `APPROVE issue-23/coding`): breadth search doesn't need
judgment, so serializing it in the old protocol cost speed/coverage for
no benefit; judgment is only needed when deciding where to deepen.
Phase-1 survey (docs/issue-23/reports/coding/survey.md) measured that
parallel `Agent` and `WebSearch` dispatch both work in this headless
session, making a genuine parallel-sweep stage feasible within a ~2min
soft budget.

## Verification run (generation-time confirmation, not a review pass)

- `grep -n "Unbounded or parallel fan-out research" scout/hooks/directive.sh`
  → no match (old ban removed). Confirmed.
- `grep -n "STAGE 1 — SWEEP" scout/hooks/directive.sh` → matches at line 35.
  Confirmed.
- `bash scout/hooks/tests/parse-check.sh` → `ok directive.sh`, `ok
  tests/parse-check.sh`, exit 0. Confirmed passing, unmodified.

## What did not work

(none — edit applied cleanly on first pass, all three "how we'll know it
worked" checks passed on first run)

## Open findings

None outstanding. No blocking finding was addressed to this record prior
to this commit.

## closed_checks

- old-ban-removed-check (grep for banned phrase absent): code_sha 2918638956059467c225a2bb1fc8b5247ba603c5
- new-structure-present-check (grep for STAGE 1 marker): code_sha 2918638956059467c225a2bb1fc8b5247ba603c5
- parse-check-still-passes: code_sha 2918638956059467c225a2bb1fc8b5247ba603c5

## Out of scope (per proposal)

- `scout/hooks/hooks.json`, `scout/hooks/tests/parse-check.sh` — untouched.
- No live timed 5-stage scout pass run as part of this change.
- No plugin version/marketplace metadata change.
