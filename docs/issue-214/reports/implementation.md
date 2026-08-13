---
code_under_review:
  - warrant/hooks/hunt-tier.sh
  - warrant/hooks/tests/run-hunt-tier-tests.sh
  - warrant/hooks/directive.sh
type: feature
breaking: false
verdict: pass
loop_state: landed
---

## What was done
Added `warrant/hooks/hunt-tier.sh`, a mechanical script that classifies a
`git diff` between two refs into a warrant-hunt budget tier: `none` (empty
diff, no hunt), `docs-only` (60s cap, 1 max stance — docs-only paths or
<=20 changed lines), `small` (120s cap, 1 max stance — <=200 lines and
<=5 files), or `full` (180s cap, 2 max stances — >200 lines, >5 files, OR
any changed path under a `hooks/`/`gates/` directory segment regardless of
size). The last clause is the regression guard the issue required: a
one-line diff touching a gates/hooks path still gets full treatment, not
downgraded by line count.

Added `warrant/hooks/tests/run-hunt-tier-tests.sh` (repo's existing
`run-*-tests.sh` bash convention, fixture git repos via
`core/hooks/tests/_tmp.sh`'s `mktd`), asserting: empty diff -> `tier=none`;
docs-only diff -> `tier=docs-only`, `cap_seconds<=180`, `max_stances=1`;
a one-line diff inside `warrant/hooks/` -> `tier=full`, `cap_seconds=180`,
`max_stances=2` despite its small size; and a path merely containing the
substring "hooks" (`hookspec/`, not a `hooks/` directory segment) does NOT
trip the override — stays `docs-only`. 9/9 assertions pass.

Added one paragraph to `warrant/hooks/directive.sh`'s existing tier table
(landed under issue-63) stating the gates/hooks-always-full override
explicitly and naming `hunt-tier.sh` as the mechanical check the stated
mapping must match — closing the gap between the issue's acceptance
criteria (a mechanically checkable test) and the previously prose-only
tier table.

## Why
Issue #214: warrant-hunt dispatch overhead (median 284s, p90 900s across 53
records) is disproportionate on small/docs-only diffs, and the acceptance
criteria explicitly require a mechanical test — not just directive prose —
asserting the tier mapping, plus a regression guard keeping the
composition-bypass class (caught via small gates/hooks diffs) in the full
tier.

## Upstream
Basis: docs/issue-214/proposals/tiered-hunt-budget.md

## Survey
docs/issue-214/reports/implementation/survey.md — found requirements 1-3
of the issue (tiering exists in prose, one-hunt-default, mapping stated in
directive) already satisfied by issue-63's landed work; the actual gap was
requirement 4 (mechanical check) and the gates/hooks size-independent
override.

## What did not work
- First draft of `run-hunt-tier-tests.sh` invoked `hunt-tier.sh` from the
  test's own cwd (the project repo) instead of the fixture repo (`$td`),
  passing commit SHAs that only existed in the fixture — every assertion
  read an empty diff and returned `tier=none`. Fixed by running the script
  with `cd "$td" &&` before each invocation so it resolves the SHAs against
  the fixture repo, not the outer one.

## Doc placement
- No new env var, dependency, migration, or setup step — nothing routes to
  a handbook.
- No public signature/wire-format change and no library choice over a
  named alternative beyond what `## Rationale` in the proposal already
  covers — no `docs/issue-214/decisions/` entry.
- No benchmark/investigation numbers produced this session (the "live
  before/after" acceptance line is explicitly out of scope, per the
  proposal) — no `docs/issue-214/reports/` entry beyond this record and
  the survey/hunt records already in that tree.

## Hunt records
- After-proposal (stance: "assume the rule as written cannot hold"):
  FINDING — the proposal's original "stances" field implied automatic
  FIND-driven escalation with no state carrying a prior dispatch's result
  into the script, contradicting `directive.sh`'s existing adaptive-cadence
  text. Resolved: proposal and script renamed the field `max_stances` (a
  ceiling the tier permits) and stated explicitly that escalating within
  it stays a session-level judgment call gated on a FIND, not something
  the script tracks. Record: docs/issue-214/reports/implementation/2026-08-13-hunt-tiered-hunt-budget.md
- Before-landing (stance: "assume this change and another plugin's rule
  cancel each other"): FINDING — `hunt-tier.sh`'s `hooks/`/`gates/`
  path-segment override matched on the FULL path including a `docs/`
  prefix, so a docs-only diff whose path happened to mention "hooks" (e.g.
  `docs/issue-1/reports/hooks/notes.md`, a report ABOUT hooks) forced
  `tier=full`, silently cancelling `directive.sh`'s docs-only fast-path
  skip. Resolved: the override now only matches non-`docs/` paths — a path
  under `docs/` is never gates/hooks code even when its own path mentions
  those words. Added regression test
  `docs-path-mentioning-hooks-stays-docs-only`. Record:
  docs/issue-214/reports/implementation/2026-08-13-hunt-tiered-hunt-budget.md

## closed_checks
- run-hunt-tier-tests.sh (10/10 assertions) — code_under_review as above
- run-directive-hunt-path-tests.sh (5/5, unaffected by the new paragraph's
  wording — no existing grep pattern collides) — code_under_review as above
- run-hunt-guard-tests.sh (9/9, unrelated surface, run as a regression
  check) — code_under_review as above

## Open findings
None outstanding — both the after-proposal and before-landing FINDINGs
above were resolved in this diff before commit.

## Next steps
None — push and open the PR carrying `Closes #214`; the "live before/after"
acceptance line (observing real sessions' hunt records post-rollout) is a
follow-up observation on the issue itself, outside this record's scope.

## Resolution path
Not applicable — no open findings remain; both hunt findings are recorded
above with their fixes already landed in this diff.

## Rationale for deviations
None — build matched the approved proposal (field renamed `stances` ->
`max_stances` per the after-proposal hunt finding, which is exactly the
kind of in-scope resolution the proposal's own write set covers, not a
scope change).
