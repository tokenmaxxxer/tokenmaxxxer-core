
## before-landing — stance: assume the write set cannot carry this work — find the path the build will need that the proposal does not list

Verdict: FINDING — the new canon-source lookup in compliance-check.sh excludes its own canon file, so an identical vendored copy of compliance-check.sh (and stub-check.sh) is misclassified as clean
Kind: silent-failure
Seed: git diff 3a1a3ae..1c74e06 (core/hooks/tests/compliance-check.sh canon_hits lookup line)
cap_seconds: 180
tier: default
diff_stat_lines: 296 insertions, 3 deletions across 8 files
started_at: 2026-08-08T00:00:00Z
ended_at: 2026-08-08T00:05:00Z

### Reproduce
```
TD=$(mktemp -d)
mkdir -p "$TD/core/hooks/tests"
cp core/hooks/tests/compliance-check.sh "$TD/core/hooks/tests/compliance-check.sh"
bash core/hooks/tests/compliance-check.sh --canon-duplication "$TD"
```

### Observed
```
compliance-check: ok — 'compliance-check.sh' under $TD differs in content from core canon (role-specific, not vendored)
```
(exit code 0; no FAIL line for a byte-for-byte identical vendored copy)

### Expected
`compliance-check.sh` and `stub-check.sh` are manifest entries whose own
canonical source lives at `core/hooks/tests/compliance-check.sh` /
`core/hooks/tests/stub-check.sh` — i.e. under a path containing `/tests/`.
The new lookup `find "$repo_root" -name "$name" -type f -not -path '*/tests/*'`
(added in this diff to compliance-check.sh, intended to exclude the tool's
*own test fixtures* from being treated as canon sources) also excludes the
real canon file for any manifest entry that itself resides in a `tests/`
directory. `canon_hits` comes back empty, `matched` stays 0 for every hit,
and a byte-identical vendored copy of compliance-check.sh/stub-check.sh is
reported as "role-specific, clean" instead of flagged — the false-negative
case the whole feature exists to catch, and it's invisible (exit 0, "ok"
line) rather than erroring.
