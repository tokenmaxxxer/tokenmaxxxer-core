---
status: approved
files:
  - warrant/hooks/hunt-tier.sh
  - warrant/hooks/tests/run-hunt-tier-tests.sh
  - warrant/hooks/directive.sh
  - docs/issue-214/reports/implementation.md
---

## Request
Warrant-hunt dispatch cost is disproportionate to change size (median 284s,
p90 900s across 53 records), often on docs-only or few-line diffs. Make the
hunt budget mechanically tiered by diff size/kind: docs-only/small diffs get
a capped single-stance hunt (or a recorded skip), gates/hooks diffs keep full
treatment, one hunt is the session default with extra stances only on FIND,
and the tier mapping is stated in the directive and checkable by a test.

## Constraints
- The directive (`warrant/hooks/directive.sh`) already states a tier table
  and an adaptive-cadence rule (issue-63); this proposal must not duplicate
  or contradict that text, only close the gap the survey found.
- The gap: no mechanical script computes a tier from an actual diff, and the
  current size-only mapping does not force gates/hooks diffs into the full
  tier regardless of size — the regression guard the issue requires.
- Acceptance requires a test that: maps a docs-only fixture diff to a
  single-stance tier with cap_seconds <= 180 (or a recorded-skip shape),
  maps a gates/hooks fixture diff to the full tier, and asserts an empty
  diff produces no hunt (tier=none). Test must exit 0.

## Rationale
Considered computing the tier inline inside `hunt-guard.sh` (the existing
PreToolUse hook that already reads `WARRANT_HUNT_CAP_SECONDS`) rather than a
new standalone script. Rejected: `hunt-guard.sh` fires on the dispatch tool
call and only sees `tool_input` (agent type, prompt) — it has no diff
context — and folding diff-scanning in would couple two independent
concerns (dispatch bounding vs. tier classification), making the
acceptance test's fixture-diff assertions harder to isolate cleanly.
Chose a standalone `hunt-tier.sh` that any caller (a session, `hunt-guard.sh`
later, or a test) can invoke with two refs and get back a tier line.

## What will be done
- Add `warrant/hooks/hunt-tier.sh`: takes `<base-ref> [<head-ref>]`, runs
  `git diff --numstat`, and prints `tier=<none|docs-only|small|full>
  cap_seconds=<N> max_stances=<0|1|2> reason=<...>`. `max_stances` is a
  ceiling the tier permits, not a dispatch count the script drives — the
  script has no cross-call state, so it cannot know whether a prior hunt in
  this session FOUND anything. Escalating from 1 to 2 stances within that
  ceiling stays the session's own judgment call gated on a FIND, exactly as
  `directive.sh` already states ("additional stances only when the first
  hunt FINDs") — the same way its existing adaptive-cadence miss-streak rule
  is read by the session rather than mechanically enforced by a script.
  Rules: empty diff -> `none`/0s/0 (no hunt); any changed path under a
  `hooks/` or `gates/` directory -> `full`/180s/max_stances=2 regardless of
  size (the regression guard); else docs-only paths or <=20 changed lines ->
  `docs-only`/60s/max_stances=1; else <=200 lines and <=5 files ->
  `small`/120s/max_stances=1; else -> `full`/180s/max_stances=2.
- Add `warrant/hooks/tests/run-hunt-tier-tests.sh` following this
  directory's `run-*-tests.sh` convention (pass/fail counter, `report()`
  helper, fixture git repos via `core/hooks/tests/_tmp.sh`'s `mktd`):
  asserts a docs-only fixture -> `tier=docs-only` with `cap_seconds<=180`;
  a gates/hooks fixture (small diff, one line changed inside a `hooks/`
  path) -> `tier=full`; an empty diff (base==head) -> `tier=none`.
- Add one paragraph to `warrant/hooks/directive.sh`'s tier table stating the
  gates/hooks override explicitly and naming `warrant/hooks/hunt-tier.sh` as
  the mechanical check backing the stated mapping.
- Write the phase-2 record at `docs/issue-214/reports/implementation.md`.

## Out of scope
- Wiring `hunt-tier.sh`'s output into `hunt-guard.sh` or auto-computing
  `WARRANT_HUNT_CAP_SECONDS` from it — the issue asks for a mechanically
  checkable tier mapping, not a behavior change to dispatch enforcement.
  That wiring is a follow-up once the tier script's shape is settled.
- The "live before/after" acceptance line (observing real sessions' hunt
  records post-rollout) — that is a follow-up observation on the issue, not
  buildable in this session.

## How you'll know it worked
`bash warrant/hooks/tests/run-hunt-tier-tests.sh` exits 0 and its output
shows the three fixture assertions passing (docs-only tier/cap, gates/hooks
full tier, empty-diff no-hunt).
