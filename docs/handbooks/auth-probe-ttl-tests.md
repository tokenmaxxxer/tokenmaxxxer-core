# gh auth-probe TTL-cache tests

`core/hooks/tests/run-auth-probe-ttl-tests.sh` covers the TTL-cache added
to `core/hooks/directive.sh`'s `gh auth status` precondition probe
(issue-269): auth state changes rarely, so an unconditional network probe
on every UserPromptSubmit (~4.0s measured) is cached under
`${TMPDIR:-/tmp}/core-auth-probe-<hash-of-repo-root>.cache`, keyed by
repo root, for `CORE_AUTH_PROBE_TTL` seconds (default 300).

Run it directly, no setup required:

    bash core/hooks/tests/run-auth-probe-ttl-tests.sh

It stubs `gh` on `PATH` with a fake that appends to a counter file and
exits with a chosen code, then runs `directive.sh` against an isolated
fake git repo and isolated `TMPDIR` (so cache files never collide across
cases or with a real cache), asserting gh-invocation counts for:

1. a cache-miss run makes one `gh` call; a second run inside the default
   TTL makes zero additional calls.
2. `CORE_AUTH_PROBE_TTL=0` disables caching — both runs call `gh`.
3. a failing probe is never served from cache — the very next run
   re-probes instead of returning the stale failure.
