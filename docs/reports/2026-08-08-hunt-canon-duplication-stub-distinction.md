
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

## before-landing — stance 3: assume this change and another plugin's rule cancel each other — find the pair

Verdict: FINDING — stub-check.sh's own manifest-driven absence loop still unconditionally flags a sanctioned directive.sh stub as vendored drift (rc=1), immediately contradicted by the new gate_is_role_directive_stub structural check further down the same script, which prints "ok" for the identical file — one run of stub-check.sh emits both a FAIL and an ok verdict for the same file and exits non-zero despite the file being a correct stub.
Kind: composition
Seed: core/hooks/lib/gate-lib.sh (gate_is_role_directive_stub), core/hooks/tests/stub-check.sh, core/hooks/tests/compliance-check.sh --canon-duplication, core/hooks/tests/canon-manifest.txt (directive.sh entry)
cap_seconds: 120
tier: size:21-200-lines
diff_stat_lines: ~21-200 (per dispatcher)
started_at: 2026-08-08T19:28:10+09:00
ended_at: 2026-08-08T19:29:23+09:00

### Reproduce
```
mkdir -p /tmp/claude-1000/rb/hooks
printf '%s\n' '#!/usr/bin/env bash' '. "$(dirname "$0")/../lib/role-directive.sh"' 'ROLE_A=1' 'ROLE_B=2' 'ROLE_C=3' 'ROLE_D=4' 'core_role_directive' > /tmp/claude-1000/rb/hooks/directive.sh
chmod +x /tmp/claude-1000/rb/hooks/directive.sh
bash core/hooks/tests/stub-check.sh /tmp/claude-1000/rb
```

### Observed
```
stub-check: FAIL — vendored copy of core canon file 'directive.sh' found:
/tmp/claude-1000/rb/hooks/directive.sh
  This file is now a core hook (core/hooks/hooks.json), fired for
  every plugin install. A local copy is drift, not a stub — delete
  it and drop the file's own hooks.json entry, if any (issue-66).
...
stub-check: ok — /tmp/claude-1000/rb/hooks/directive.sh is a role-directive stub
```
Script exits 1 (rc set by the first, unconditional loop) even though the dedicated directive.sh check that follows says the same file is a sanctioned stub. compliance-check.sh's --canon-duplication mode special-cases `directive.sh` in its manifest loop to call gate_is_role_directive_stub before flagging it (line ~56), but stub-check.sh's own manifest loop (`for name in $CANON_GATES`, lines ~59-75) has no such exclusion — it still matches directive.sh by filename alone via canon-manifest.txt, which lists directive.sh unconditionally. The later "structural check, not absence-based" block for directive.sh runs unconditionally too, but only ever adds to `rc`; it never un-sets the FAIL already recorded by the manifest loop above it.

### Expected
stub-check.sh's manifest loop should skip `directive.sh` (as compliance-check.sh's loop now does) since it is handled by the dedicated structural check that follows, so a sanctioned stub produces a single consistent "ok" verdict and exit 0, not a spurious FAIL alongside an ok for the same file.
