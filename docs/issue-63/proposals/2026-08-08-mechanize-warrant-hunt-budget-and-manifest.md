---
subject: issue-63
role: implementation
loop_state: scope-proposed
files:
  - core/hooks/tests/canon-manifest.txt
  - core/hooks/lib/gate-lib.sh
  - warrant/hooks/hunt-guard.sh
  - core/hooks/tests/run-gate-lib-tests.sh
---

# Proposal: mechanize the two remaining issue-63 Acceptance checks

## Request

Issue #63's Acceptance lists two mechanical checks that PR #65 (canon
promotion + directive-text cadence) did not satisfy: (1) the #66
canon-duplication scan must actually cover the warrant-hunt files, and
(2) the hunt time budget must be a mechanically enforced bound (refuse
or loudly truncate over-budget, proceed in-budget), not directive prose
alone, verified by a red/green pair in `run-gate-lib-tests.sh`.

## Constraints

- The 43-rulebook rollout stays out of this repo's write authority
  (per the issue's own "unverifiable" note); this proposal only makes
  the in-repo scan and test infrastructure correct.
- A PreToolUse hook cannot terminate a running subagent — confirmed by
  `hunt-guard.sh`'s own existing stale-lock comment. Enforcement can
  only gate the hunter's *next* tool call, not stop it mid-call.
- Follow the two existing gate patterns in `warrant/` exactly: a
  `gate_*` helper in `gate-lib.sh`, sourced via `CLAUDE_PLUGIN_ROOT_CORE`,
  fail-open on ambiguous/malformed input, honoring `WARRANT_OFF=1`.

## Rationale

Considered enforcing the budget purely inside `warrant-hunter.md`'s
prompt text (the hunter self-reports elapsed time and stops itself).
Rejected: that is what already exists today (the cadence is currently
directive prose only, per the survey), and it is exactly the
unenforced state the issue's owner is complaining about — a prompt can
be, and evidently is, silently not followed. A mechanical `gate_*`
check that fires on the hunter's own next tool call closes that gap the
same way `scope-gate.sh` already closes the write-set-drift gap for
regular builds; it composes with the existing kill switch and
single-flight lock instead of introducing a second cadence mechanism.

## What will be done

1. **`core/hooks/tests/canon-manifest.txt`**: append `directive.sh`,
   `hunt-guard.sh`, `hunt-state.sh`, `scope-gate.sh`, `state.sh`,
   `warrant-hunter.md` (six lines). This alone makes
   `compliance-check.sh --canon-duplication` catch a vendored copy of
   any warrant-hunt file, satisfying Acceptance check 1.

2. **`core/hooks/lib/gate-lib.sh`**: add `gate_budget_exceeded
   <started_epoch> <cap_seconds> [<now_epoch>]` — returns 0 (true) when
   `now - started > cap`, 1 otherwise; `now_epoch` defaults to `$(date
   +%s)` when omitted (the optional third arg exists solely so tests can
   pass fixed timestamps instead of racing the real clock). Malformed
   numeric input (non-integer) returns 1 (not-exceeded / fail-open),
   matching this file's existing fail-open convention.

3. **`warrant/hooks/hunt-guard.sh`**: at dispatch, write the chosen cap
   as a second field in `.warrant-hunt.lock` (`"<started_epoch>
   <cap_seconds> <prompt-head>"`) — the cap the dispatching session
   already computes per `directive.sh`'s tiers, passed through
   `WARRANT_HUNT_CAP_SECONDS`. Add a check, active only when
   `WARRANT_IN_HUNT=1` (i.e. this is the hunter's own next tool call):
   read the lock's started/cap fields and call `gate_budget_exceeded`;
   if it returns true, print a loud "warrant: hunt budget of Ns
   exceeded (ran Ns) — stop and return your finding (or nothing) now"
   message to stderr and exit 2, refusing the call. In-budget calls
   proceed unchanged (`allow()`).

4. **`core/hooks/tests/run-gate-lib-tests.sh`**: add one red case
   (`gate_budget_exceeded 1000 60 1200` -> exceeded -> hunt-guard-style
   caller refuses) and one green case (`gate_budget_exceeded 1000 120
   1050` -> not exceeded -> proceeds), following this file's existing
   `report <want> <got> <name>` harness pattern.

## Out of scope

- Editing the 43 vendored rulebook copies or the standalone `warrant`
  plugin repo (outside this repo's write authority, per the issue's own
  acceptance note).
- The delivery-size-bucketed time/token measurement table (issue item
  2) — no real hunt records with the PR #65 instrumentation fields have
  accumulated yet; still an open follow-up, unchanged from PR #65's
  record.
- Killing a running hunter mid-call — not achievable from a PreToolUse
  hook (see Constraints).

## How you'll know it worked

- `core/hooks/tests/compliance-check.sh --canon-duplication <path>`
  reports a FAIL for a path containing a copy of any of the six newly
  listed warrant filenames, and `ok` when none are present.
- `core/hooks/tests/run-gate-lib-tests.sh` passes, including the new
  red/green budget-bound pair (script exits 0 with `fail=0`).
- `bash -n` on `gate-lib.sh` and `hunt-guard.sh` after the edits.
