files:
  - core/hooks/board-gate.sh
  - core/hooks/approval-gate.sh
  - core/hooks/gh-guard.sh
  - core/hooks/tests/run-board-gate-tests.sh
  - core/hooks/tests/run-approval-gate-tests.sh
  - core/hooks/tests/run-gh-guard-tests.sh

## Request

board-gate.sh, approval-gate.sh, and gh-guard.sh clear the fail-closed
EXIT trap (`trap - EXIT`) before propagating the python judge's exit
code. An internal python error (rc=1) is therefore treated by Claude
Code as non-blocking and the gated act is ALLOWED instead of denied.
Adopt the `_fc_rc` internal-error remap already used by
trailer-gate.sh/record-fields-gate.sh, and deny empty stdin payloads
before the shell substring fast-path in all three files. Pin both
behaviors with tests.

## Constraints

- Scout skip condition: pure bugfix, no design decision open — see
  `docs/issue-138/reports/implementation/survey.md`.
- Fix direction is prescribed by the issue itself (adopt the existing
  `_fc_rc` pattern) — this is a port, not a new design.
- Must not change any currently-passing allow/deny verdict for a
  well-formed payload; only the internal-error and empty-payload paths
  change.
- `gh-guard.sh`'s non-role passthrough (`CLAUDE_ROLE` unset → exit 0
  untouched) must not gain a new failure mode from the empty-payload
  check.

## Rationale

Two structurally different fixes were on the table:

1. **Remap inline at the trap** (rewrite the `trap '...' EXIT` handler
   itself to remap unconditionally, and never call `trap - EXIT` before
   the final `exit`). Rejected: `trap - EXIT` exists deliberately in the
   passthrough early-exits (kill switch, non-role session, fast-path
   miss) so those already-clean 0-exits are not run back through the
   remap logic a second time; ripping it out everywhere would work but
   means auditing and touching every early-exit site instead of exactly
   one — the tail before the final `exit "$rc"`. The chosen fix instead
   ports trailer-gate.sh's proven approach: keep the early `trap - EXIT`
   disarms as-is, and add one explicit rc check immediately after the
   python judge returns, mirroring code already shipped and already
   covered by trailer-gate's own test suite.

2. **Deny empty payload unconditionally at the very top of the script**
   (before any kill-switch or role check). Rejected for gh-guard.sh:
   that would newly deny non-role sessions (the user's own, the
   orchestrator's) on empty stdin, which is out of this gate's business
   by design — gh-guard.sh explicitly passes those through untouched.
   The chosen fix places the empty-payload deny after the existing
   `CLAUDE_ROLE` check (gh-guard.sh) or right after the payload capture
   for the two gates that have no such pre-check (board-gate.sh,
   approval-gate.sh — approval-gate.sh already has its own
   `CLAUDE_ROLE` check earlier, so the ordering there is unchanged).

## What will be done

- Port trailer-gate.sh's rc-remap block into all three gates: after
  `CORE_PAYLOAD="$payload" python3 -c "$CORE_..._GATE"; rc=$?; trap -
  EXIT`, add `if [ "$rc" -ne 0 ] && [ "$rc" -ne 2 ]; then echo
  "...: refused — fail-closed: internal error (gate judge exited $rc)"
  >&2; exit 2; fi` before `exit "$rc"`.
- Add an empty-payload deny (`[ -n "$payload" ] || { echo "...refused —
  empty tool-use payload..." >&2; exit 2; }`) before each file's shell
  substring fast-path, placed after any existing `CLAUDE_ROLE`
  passthrough check so non-gated sessions are unaffected.
- Add two tests per gate to each of the three existing test suites: a
  stub `python3` on `PATH` that unconditionally `exit 1`s must produce
  gate exit 2 (deny); empty stdin must produce gate exit 2 (deny). Run
  all three suites and confirm 0 failures (including all pre-existing
  cases, to catch a verdict regression).

## Out of scope

- `record-fields-gate.sh`, `trailer-gate.sh`, `handbook-trigger` — these
  already carry the fix; untouched.
- Any change to the allow/deny logic itself (R1-R5 board rules, the
  approval decision tree, the gh-command denylist) — only the rc-plumbing
  and empty-payload paths change.
- The R3 fail-open regression tracked separately under #132.

## How you'll know it worked

- `bash core/hooks/tests/run-board-gate-tests.sh`,
  `run-approval-gate-tests.sh`, `run-gh-guard-tests.sh` all report `0
  failed`, including the two new cases each (`empty-payload`,
  `python3-internal-error`) asserting `deny`.
- Manually stubbing `python3` to `exit 1` and piping a well-formed
  payload into each of the three gates exits 2, not 1.
