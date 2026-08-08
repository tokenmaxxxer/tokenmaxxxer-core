
## after-proposal — stance 4: assume the write set cannot carry this work — find the path the build will need that the proposal does not list

Verdict: FINDING — the frozen write set omits core/hooks/tests/run-all.sh, which is the only file that wires a test runner into the aggregate suite, and it currently does not invoke run-fleet-scan-tests.sh (the runner the write set does list) at all.
Kind: design-error
Seed: proposal docs/issue-173/proposals/2026-08-08-canon-duplication-stub-distinction.md (write set: core/hooks/lib/gate-lib.sh, core/hooks/tests/stub-check.sh, core/hooks/tests/compliance-check.sh, core/hooks/tests/run-fleet-scan-tests.sh, plus the two already-committed docs files)
cap_seconds: 60
tier: size:small (docs-only diff, ~207 lines across 2 new proposal/report docs)
diff_stat_lines: 207
started_at: 2026-08-08T19:01:24+09:00
ended_at: 2026-08-08T19:02:20+09:00

### Reproduce
```
grep -n "run-gate-lib-tests\|run-fleet-scan-tests" core/hooks/tests/run-all.sh
bash core/hooks/tests/run-all.sh 2>&1 | grep -i "fleet\|gate-lib"
```

### Observed
`grep` for `run-gate-lib-tests` / `run-fleet-scan-tests` against `core/hooks/tests/run-all.sh` returns no matches, and running `run-all.sh` end to end produces no "fleet scan" or "gate-lib" section anywhere in its output — the sections it does print are: bash 3.2 parse, deny-only, board gate, approval gate, gh guard, role-agnostic gates, stub-check canon combination forms, compliance-check hooks.json scan scope, terse, freelunch, freelunch observe.sh enforcement, scout. `run-fleet-scan-tests.sh` (the file the proposal's write set explicitly names as a target for new test coverage of the shared `gate_is_role_directive_stub()` behavior) is never called by the aggregate runner, so any new tests the build adds there will pass or fail in complete isolation from `run-all.sh`/CI-equivalent checks.

### Expected
Since the proposal's plan is to add coverage in `run-fleet-scan-tests.sh` for a shared classification function used by both `stub-check.sh` and `compliance-check.sh --canon-duplication`, that new coverage needs to actually run as part of the suite that catches regressions — which means `core/hooks/tests/run-all.sh` needs an added invocation line (`/bin/bash "$here/run-fleet-scan-tests.sh" | tail -2 || rc=1`, following the pattern of every other line in the file). The frozen write set does not list `run-all.sh`, so as written the build can add and pass new tests in `run-fleet-scan-tests.sh` while `run-all.sh` continues to report "ALL OK" whether or not those tests exist or fail.
