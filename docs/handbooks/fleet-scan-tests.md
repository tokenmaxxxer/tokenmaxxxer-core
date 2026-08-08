# fleet-scan test harness

`core/hooks/tests/run-fleet-scan-tests.sh` exercises
`core/hooks/tests/fleet-silent-failure-scan.sh` and
`core/hooks/tests/run-fleet-scan.sh` (issue-168) against synthetic
throwaway repos, plus a live 43-repo fleet run when `gh`/network access is
available (clearly skipped otherwise, never silently passed).

Run it directly, no setup required:

    bash core/hooks/tests/run-fleet-scan-tests.sh

Covers: a clean synthetic repo scans to a `clean` row with exit 0; a
synthetic repo carrying a swallowed-error shape surfaces a `FINDING` row
(never `blocked`) with a non-zero exit; a nonexistent scan path is a hard
error (exit 2), never a `blocked` row; and, network-permitting, the live
43-repo fleet run produces exactly 43 result rows with zero `blocked`
rows.

**issue-173: `--canon-duplication` stub-vs-vendored red-green pair.**
`compliance-check.sh --canon-duplication` used to flag any file named
`directive.sh` as a vendored copy of core canon by filename alone, so a
correctly-rolled-out rulebook's sanctioned per-repo `directive.sh` stub
(`docs/handbooks/canon-rollout.md` step 3 — source `role-directive.sh`,
call `core_role_directive`) could never pass. Fixed by extracting
`stub-check.sh`'s existing structural stub classification into a shared
`gate_is_role_directive_stub()` (`core/hooks/lib/gate-lib.sh`), reused by
both `stub-check.sh` and `compliance-check.sh --canon-duplication`'s
`directive.sh`-specific branch, so a sanctioned stub passes and a
genuinely vendored full copy still flags. Pinned here by two synthetic
rulebook fixtures: a correct single-call `directive.sh` stub scans clean
(exit 0, no vendored-copy line) under `--canon-duplication`; a
full pre-promotion `directive.sh` body still flags (exit 1, vendored-copy
message present). Every other `canon-manifest.txt` entry keeps its
existing unconditional filename-match FAIL, unchanged.

Known gap (out of this file's scope, recorded in
`docs/issue-173/reports/implementation.md`): `stub-check.sh`'s own
unconditional `CANON_GATES` manifest loop still flags `directive.sh` by
filename before its later structural check runs, so one invocation of
`stub-check.sh` can emit a contradictory FAIL/ok pair for the same
sanctioned stub — pre-existing, not introduced by this fix, and not
covered by this issue's approved write set (only `compliance-check.sh`'s
`--canon-duplication` mode was in scope).
