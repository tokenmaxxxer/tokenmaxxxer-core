---
kind: coding-record
subject: issue-12
upstream:
  - path: docs/issue-12/proposals/2026-07-29-board-gate-mkdir-rm-fix.md
    sha: 380c263b7e8000a487665f451589b4ad5ed1096b
loop_state: landed
---

## Pointer

Governing `build-proposal`: `docs/issue-12/proposals/2026-07-29-board-gate-mkdir-rm-fix.md`.
PR #13 (`issue-12/coding` -> `main`), Approve review comment: "APPROVE issue-12/coding".

## What was done

`core/hooks/board-gate.sh` R5's own-role allow condition required
`tail[0] == role and len(tail) > 1`, which excluded the bare
`reports/<role>` directory itself (`len(tail) == 1`) — the exact mkdir/rm
target — and let it fall through to the foreign-role denial. Dropped the
`len(tail) > 1` requirement so `tail[0] == role` alone allows; foreign-role
paths are unaffected and still deny.

Regression tests added to `core/hooks/tests/run-board-gate-tests.sh`:
`bash-mkdir-own-dir`, `bash-rm-own-dir` (the false positive, now allow),
`bash-mkdir-foreign-dir`, `bash-rm-foreign-dir` (foreign-role denial,
preserved).

## Why

Bash `mkdir`/`rm` on a role's own bare `reports/<role>/` directory was
falsely denied as "belongs to another role" while an equivalent Write to
the same path passed, blocking a role from managing its own record
subtree via shell. Fixed by removing the spurious `len(tail) > 1`
requirement in R5's own-role check; kept fail-closed for foreign-role
paths.

## Commits landed

- `380c263b7e8000a487665f451589b4ad5ed1096b` — fix: board-gate R5 allows mkdir/rm on a role's own bare record dir

## Closed checks

```yaml
closed_checks:
  - check: full hook test harness (core/hooks/tests/run-board-gate-tests.sh)
    code_sha: 380c263b7e8000a487665f451589b4ad5ed1096b
```

Fresh full-harness run at code sha `380c263b7e8000a487665f451589b4ad5ed1096b`:
`== 40 passed, 0 failed ==`, including the four new regression cases above.

## What did not work

Nothing discarded or replaced during this build; the fix matched the
phase-1 survey's root-cause finding on the first pass.

## Open findings

None. No `finding` blocks addressed to coding are open against this
subject.

## Next steps

None open. Awaiting qa/review/verify wakes per the standard WAKES-ON table.
