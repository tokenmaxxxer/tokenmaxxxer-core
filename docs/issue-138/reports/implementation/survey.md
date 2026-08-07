# Survey — issue-138

Scout skip condition: pure bugfix. The issue names the exact defect (trap
cleared before rc propagation; empty-payload fast-path miss) and the exact
fix pattern to adopt (`_fc_rc`-style remap already shipped in
trailer-gate.sh/record-fields-gate.sh). No product-shaped or open design
decision exists to scout.

## Current state

`core/hooks/board-gate.sh`, `core/hooks/approval-gate.sh`,
`core/hooks/gh-guard.sh` each end with:

```
CORE_PAYLOAD="$payload" python3 -c "$CORE_..._GATE"
rc=$?
trap - EXIT
exit "$rc"
```

`trap - EXIT` disarms the fail-closed EXIT trap before `rc` (the python
judge's exit code) is propagated. If the python judge dies with an
uncaught exception (rc=1 — e.g. a gate-lib import/compat failure), `rc`
propagates as 1 unmodified. Claude Code treats a non-2 hook exit as
non-blocking, so the gated act is ALLOWED instead of denied.

`core/hooks/trailer-gate.sh` (line 169-174) and
`core/hooks/record-fields-gate.sh` already guard this: after the python
heredoc, they check `rc` explicitly and remap anything other than 0/2 to
2, with a message, before the final `exit "$rc"`. That is the pattern to
port into the three broken files.

Each of the three files also drains stdin with
`payload="$(cat 2>/dev/null || true)"` and then runs a shell substring
fast-path (`case "$payload" in *docs*) ;; *) exit 0 ;; esac` or
equivalent) before python3 ever starts. An empty payload (stdin delivery
failure) never matches the substring pattern, falls through the `*)`
branch, and exits 0 (allow) — the gate never reaches
`gate_parse_json_or_deny`, which would have denied. trailer-gate.sh
instead denies explicitly on empty payload (line 36) before doing
anything else.

## Write set

- `core/hooks/board-gate.sh` — remap rc after the python judge; deny empty
  payload before the `*docs*` fast-path.
- `core/hooks/approval-gate.sh` — same, before the `*src/*|*test/*|*issue-*`
  fast-path.
- `core/hooks/gh-guard.sh` — same, before its two fast-path `case`
  statements (Bash-tool check, then gh/git/curl/wget/http check). The
  empty-payload deny is placed after the existing `CLAUDE_ROLE` check
  (non-role sessions already pass through untouched by design, and
  inserting the check earlier would newly deny non-role sessions that
  happen to receive no stdin — outside this issue's scope).
- `core/hooks/tests/run-board-gate-tests.sh`,
  `core/hooks/tests/run-approval-gate-tests.sh`,
  `core/hooks/tests/run-gh-guard-tests.sh` — pin both behaviors: a stub
  `python3` that exits 1 must produce exit 2 (deny), and empty stdin must
  produce exit 2 (deny).

No new dependency, no schema change, no env var.
