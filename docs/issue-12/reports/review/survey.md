# Current-state survey: issue #12 vs landed change

## Spec (source: GitHub issue #12 body, verbatim requirements)

R1. `core/hooks/board-gate.sh` R5 own-role allow condition must change from
    `tail[0] == role and len(tail) > 1` to `tail[0] == role` (drop the
    `len(tail) > 1` requirement).
R2. Foreign-role paths must remain denied (fail-closed preserved) —
    unaffected by the change.
R3. `core/hooks/tests/run-board-gate-tests.sh` must gain a regression case
    for the original false positive (mkdir/rm on a role's own bare
    `reports/<role>` dir → allow).
R4. `core/hooks/tests/run-board-gate-tests.sh` must gain a regression case
    for the foreign-role denial (mkdir/rm on another role's bare dir →
    deny).

## Artifact inspected

code_under_review: `380c263b7e8000a487665f451589b4ad5ed1096b`
(merged to main via PR #13, `b0d5c27`).

Diff scope: `core/hooks/board-gate.sh` (1 line changed),
`core/hooks/tests/run-board-gate-tests.sh` (4 lines added, 2 test IDs x
mkdir/rm), `docs/handbooks/board-gate-tests.md` (new doc, non-normative).
Total non-doc diff: 9 lines. Full-diff audit, no sampling — diff is well
under the 100-300 line session budget.

## Per-requirement verdict

- R1: **Present**. `core/hooks/board-gate.sh:278` reads
  `if tail[0] == role:` (was `tail[0] == role and len(tail) > 1`), matching
  the spec exactly.
- R2: **Present**. The foreign-role branch (`deny()` fallthrough) is
  untouched by the diff; own-role condition only widens `tail[0] == role`
  matches, which by construction excludes any `tail[0] != role` path — a
  foreign role's tail never satisfies it. Confirmed empirically: test IDs
  `bash-mkdir-foreign-dir` / `bash-rm-foreign-dir` (own `reports/review`
  target from a `qa`-role fixture) both assert `want deny` and pass.
- R3: **Present**. `run-board-gate-tests.sh:166-167` adds
  `bash-mkdir-own-dir` / `bash-rm-own-dir` — `mkdir -p`/`rm -rf` on
  `$BOARD/reports/qa` from the qa role, `want allow`.
- R4: **Present**. `run-board-gate-tests.sh:169-170` adds
  `bash-mkdir-foreign-dir` / `bash-rm-foreign-dir` — same ops on
  `$BOARD/reports/review` from the qa role, `want deny`.

## Independent re-run

`bash core/hooks/tests/run-board-gate-tests.sh` at HEAD (main, containing
380c263) re-executed directly: `== 40 passed, 0 failed ==`, including all
four new regression IDs. Matches the coding record's closed_checks claim
(`code_sha: 380c263b7e8000a487665f451589b4ad5ed1096b`) — cited, not
re-derived, since the sha matches code_under_review.

## Overall

All four extracted requirements: Present. No Surface/Absent/Incorrect
findings. No sampling was needed (full diff read).
