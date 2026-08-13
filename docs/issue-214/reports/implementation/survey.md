# Survey: issue-214 — tiered warrant-hunt budget, mechanically checkable

## Current state
- `warrant/hooks/directive.sh` (landed under issue-63, commit 130cb13) already
  renders a tier table in the warrant directive: diff <=20 lines or docs-only
  paths -> 60s/1 stance; 21-200 lines -> 120s/1 stance; >200 lines or >5 files
  -> 180s/up to 2 stances; a docs-only fast path skips the before-landing
  dispatch; an adaptive-cadence rule drops the tier on 3 consecutive misses.
  So issue-214's requirements 1-3 (tiering exists, one-hunt-default,
  escalation-on-FIND, mapping stated in the directive) are already satisfied
  in prose.
- What is missing: the tier decision is entirely prompt-driven — no script in
  the repo computes a tier from an actual diff. The issue's acceptance check
  explicitly asks for a *mechanically checkable* test asserting tier
  classification from fixture diffs, which nothing in `warrant/hooks/`
  currently provides.
- Requirement 4 (regression guard: composition-bypass class stays in full
  tier) is not met by the current table: tiering is diff-size-only. A small
  diff (say, 10 lines) touching a gates/hooks file would fall into the
  60s/docs-only-sized tier by line count alone, even though `gates/hooks
  diffs keep full treatment` per the issue text. There is no gates/hooks
  override in the current mapping.

## Write set implied by the gap
- `warrant/hooks/hunt-tier.sh` — new mechanical tier-computation script,
  `git diff --numstat`-based, output as `tier=... cap_seconds=... stances=...
  reason=...`. Follows this repo's hook-script conventions (`set -uo
  pipefail`, no external deps beyond git/awk).
- `warrant/hooks/tests/run-hunt-tier-tests.sh` — new test file, matching this
  directory's existing `run-*-tests.sh` bash convention (see
  `run-hunt-guard-tests.sh`, `run-directive-hunt-path-tests.sh`): builds
  fixture git repos, diffs two commits, asserts tier/cap per fixture kind
  (docs-only, gates/hooks, empty diff).
- `warrant/hooks/directive.sh` — one addition to the tier table text: state
  the gates/hooks-always-full override explicitly, and name the mechanical
  script as the thing that now computes it (directive text is the norm;
  hunt-tier.sh is the mechanical check).
- `docs/issue-214/reports/implementation.md` — phase-2 record (this session).

## Alternatives considered
- Compute the tier inside `hunt-guard.sh` itself (the existing PreToolUse
  hook that already reads `WARRANT_HUNT_CAP_SECONDS`) instead of a standalone
  script. Rejected: `hunt-guard.sh` fires on the *dispatch* tool call, which
  carries no diff context (it only sees the Agent/Task/Workflow tool_input),
  and folding diff-scanning into it would couple two independent concerns
  (dispatch bounding vs. tier classification) into one script, making the
  acceptance test's fixture-diff assertions harder to isolate.
- A python script instead of bash. Rejected: every other file in
  `warrant/hooks/` is bash-first with an embedded `python3` heredoc only when
  JSON parsing is unavoidable (see `scope-gate.sh`, `hunt-guard.sh`); this
  script needs no JSON, so plain bash/git/awk matches the surrounding
  convention and needs no python3 availability check.

## Existing conventions confirmed
- Test files live in `warrant/hooks/tests/`, named `run-<subject>-tests.sh`,
  use a `pass`/`fail` counter with a `report()` helper printing `ok`/`FAIL`
  lines, and exit non-zero on any failure.
- `core/hooks/tests/_tmp.sh` supplies `mktd` for scratch git fixtures.
