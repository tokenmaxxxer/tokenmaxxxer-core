# Phase-1 survey: board-gate R5 false positive on own bare record dir

## Confirmed root cause
`core/hooks/board-gate.sh`, R5 ownership loop (originally line 278):

    if tail[0] == role and len(tail) > 1:
        continue

`tail` is the path under `docs/issue-<n>/reports/`. For a role's own bare
directory (`reports/<role>`, e.g. a `mkdir`/`rm` target), `tail == [role]`
and `len(tail) == 1`, so this allow branch does not fire and execution
falls through to the foreign-role `deny()` at the bottom of the loop —
even though the directory belongs to the role itself. A `Write` to
`reports/<role>/x.md` has `len(tail) == 2` and was already allowed, which
is why the bug was Bash-specific (mkdir/rm on the bare dir) rather than
visible on file writes.

## Test harness
`core/hooks/tests/run-board-gate-tests.sh` runs `board-gate.sh` as a real
subprocess against synthetic git repos and JSON tool-call payloads via a
`run`/`runb` harness (`want allow|deny`, exit 0/2). The existing R5
section (`foreign-record`, `foreign-subtree`, `own-subtree`,
`feasibility-spikes`, `ops-postmortems`, `qa-not-spikes`) covers file-level
ownership but had no case for the bare directory itself.

## Fix applied
Dropped `len(tail) > 1`: `if tail[0] == role: continue`. Foreign-role
paths are unaffected — they never satisfy `tail[0] == role` and still
fall through to `deny()`.

## Regression tests added
- `bash-mkdir-own-dir` / `bash-rm-own-dir`: `mkdir -p`/`rm -rf` on
  `docs/issue-3/reports/qa` (role's own bare dir) — must allow (was the
  false positive).
- `bash-mkdir-foreign-dir` / `bash-rm-foreign-dir`: same ops on
  `docs/issue-3/reports/review` (another role's dir) — must stay deny.

## Verification run
`bash core/hooks/tests/run-board-gate-tests.sh` — 40 passed, 0 failed
(all pre-existing cases plus the 4 new ones).
