---
subject: issue-63
role: implementation
code_under_review: HEAD
loop_state: delivered
---

# Implementation record — mechanize remaining issue-63 acceptance checks

Approved via issue comment (single-account mode): `APPROVE issue-63/implementation`,
2026-08-08T09:21:11Z. Builds on the earlier `delivered` phase (canon
promotion + directive-text cadence, PR #65) — this pass closes the two
Acceptance checks that PR #65 left mechanically unmet.

## What was done

Proposal: `docs/issue-63/proposals/2026-08-08-mechanize-warrant-hunt-budget-and-manifest.md`.

1. **`core/hooks/tests/canon-manifest.txt`** — appended the six
   warrant-hunt filenames (`directive.sh`, `hunt-guard.sh`,
   `hunt-state.sh`, `scope-gate.sh`, `state.sh`, `warrant-hunter.md`).
   `compliance-check.sh --canon-duplication` now catches a vendored copy
   of any of them (verified below).

2. **`core/hooks/lib/gate-lib.sh`** — added `gate_budget_exceeded
   <started_epoch> <cap_seconds> [<now_epoch>]`, fail-open on malformed
   numeric input per this file's existing convention.

3. **`warrant/hooks/hunt-guard.sh`** — the dispatch-side lock write now
   carries a second field, the cap in seconds (`WARRANT_HUNT_CAP_SECONDS`,
   defaulting to `0`). A new budget-check block runs before the
   Agent/Task/Workflow tool-type filtering (so it is reachable for the
   hunter's own Bash/Read/Grep/Glob/Write calls, not just its disallowed
   dispatch attempts), active only when `WARRANT_IN_HUNT=1`: it reads the
   lock's started/cap fields and calls `gate_budget_exceeded`, refusing
   the call with a loud stderr message and exit 2 when the budget is
   exceeded.

4. **`core/hooks/tests/run-gate-lib-tests.sh`** — added a
   `gate_budget_exceeded` test group: the red/green pair from the
   proposal plus two fail-open cases (malformed `started`, malformed
   `cap`).

5. **Before-landing hunt fix (beyond the proposal text)** — the
   before-landing warrant hunt (stance 2: "assume this guard goes silent
   when its own input is malformed") reproduced a real gap: when the
   lock file's cap field is non-numeric, `gate_budget_exceeded`'s
   fail-open convention — correct for genuinely untrusted external
   input — made `hunt-guard.sh` silently allow the hunter to continue
   with zero stderr output, because the check couldn't distinguish "not
   yet exceeded" from "budget unreadable." Fixed in `hunt-guard.sh`:
   before calling `gate_budget_exceeded`, a malformed `started` or `cap`
   field on an existing lock is now treated as a corrupt lock and denied
   loudly (fail-closed, exit 2, explicit stderr message) rather than
   falling through to the library function's general fail-open default.
   `gate_budget_exceeded` itself is unchanged — its fail-open contract
   still holds for genuinely absent/malformed external callers, per the
   proposal's Constraints.

## Why

The lock is the guard's own bookkeeping, not external input, so silent
fail-open there would defeat the whole point of this proposal (mechanical
enforcement instead of directive prose the previous PR relied on). Every
other choice above is the proposal's own stated rationale — see the
proposal file for the alternative it rejected (self-reported cadence in
`warrant-hunter.md`'s prompt text) and why.

upstream: HEAD (this commit)

## What did not work

- First cut of the malformed-lock guard in `hunt-guard.sh` used
  `read -r started cap _rest < "$lock" 2>/dev/null || started="" cap=""`
  — invalid bash (`||` cannot chain two assignments as a compound
  command). Replaced with pre-clearing `started=""; cap=""` on the line
  before the `read`.

## Verification run this turn

- `bash -n core/hooks/lib/gate-lib.sh` and `bash -n warrant/hooks/hunt-guard.sh` — clean.
- `bash core/hooks/tests/run-gate-lib-tests.sh` — 62 passed, 0 failed,
  including the new `budget-exceeded` group.
- `bash core/hooks/tests/compliance-check.sh --canon-duplication <tmp-dir-with-a-copy-of-hunt-guard.sh>` —
  FAILs (catches the vendored copy) as required.
- Manual repro of the pre-fix silent-allow and the post-fix loud-deny
  through the real `hunt-guard.sh` with `WARRANT_IN_HUNT=1` and a
  corrupt lock file — confirmed exit 2 with explicit stderr after the fix.

## Doc placement

- No new env var, dependency, or migration — nothing to add to a
  handbook.
- No public-signature or wire-format change beyond what the proposal
  and this record already describe.
- No benchmark/investigation numbers produced.

## Hunt cadence

- after-proposal: recorded in
  `docs/reports/2026-08-08-hunt-issue-63-mechanize-budget.md` (prior
  turn, before this phase-2 approval).
- before-landing: same file, `before-landing` section — stance 2
  ("assume this guard goes silent when its own input is malformed"),
  cap 120s, tier default, diff_stat_lines 61. Returned one finding
  (silent fail-open on a corrupt lock), fixed above.

closed_checks:
- run-gate-lib-tests.sh full suite (code_sha: HEAD)
- compliance-check.sh --canon-duplication on the six new manifest entries (code_sha: HEAD)
- bash -n syntax check on both edited shell files (code_sha: HEAD)

## Out of scope (unchanged from the proposal)

- Editing the 43 vendored rulebook copies or the standalone `warrant`
  plugin repo.
- The delivery-size-bucketed time/token measurement table (issue item 2).
- Killing a running hunter mid-call (not achievable from a PreToolUse hook).

## Open findings

None outstanding — the one finding from the before-landing hunt (silent
fail-open on a corrupt lock) is fixed and verified above.
