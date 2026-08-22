---
code_under_review:
  - core/hooks/directive.sh
  - core/hooks/tests/run-auth-probe-ttl-tests.sh
loop_state: landed
type: fix
breaking: false
verdict: pass
---

# implementation record — issue-269

## What was done

TTL-cached the `gh auth status` precondition probe in
`core/hooks/directive.sh`: the probe result is now written to a file under
`${TMPDIR:-/tmp}/core-auth-probe-<hash-of-repo-root>.cache`, keyed by repo
root, and a cache hit within `CORE_AUTH_PROBE_TTL` seconds (default 300)
skips the `gh auth status` call entirely. `CORE_AUTH_PROBE_TTL=0` disables
caching and always probes. A failed probe is never cached (the cache file
is removed on failure), so a broken auth state always re-probes on the
next turn rather than hiding behind a stale success.

Added `core/hooks/tests/run-auth-probe-ttl-tests.sh`, which stubs `gh` with
a counting fake and covers the three acceptance cases: (1) a cache-miss
run makes one `gh` call and a second run inside the TTL makes zero
additional calls; (2) `CORE_AUTH_PROBE_TTL=0` makes both runs call `gh`;
(3) a failing probe is re-invoked on the very next run instead of being
served from cache. All 4 assertions pass, alongside the pre-existing
`run-directive-shape-tests.sh` (9/9) and
`run-role-directive-staging-tests.sh` (4/4), which are unaffected.

Timing (warm cache vs. cold, on this machine):
- cold (`gh auth status` actually runs): ~4.02s
- warm (served from cache): ~0.045s

## Why

Issue #269: `directive.sh` ran this network probe unconditionally on every
UserPromptSubmit, costing ~4.0s/turn (measured, on-the-record
docs/issue-2016/reports/performance-engineering/survey.md). Auth state
changes rarely, so the ~4s is nearly always wasted. Mirrors the TTL-cache
pattern on-the-record PR #2027 already landed for its stopgate.

## Upstream

Re-filed from on-the-record#2028; PR #2029 scoped the fix out of that repo
into this one (core#269).

## What did not work

None.

## Open findings

None.
