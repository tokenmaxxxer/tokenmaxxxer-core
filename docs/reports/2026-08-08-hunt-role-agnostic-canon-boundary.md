---
proposal: docs/issue-66/proposals/architecture.md
---

# Hunt record — role-agnostic-canon-boundary

## before-landing — stance 3: assume the rule as written cannot hold — find the state nothing maintains

Verdict: FINDING — `--canon-duplication`'s `find -maxdepth 3` bound is an unmaintained assumption about rulebook layout depth; a vendored canon file placed one directory deeper than that (e.g. under a `lib/` or `vendor/` subdir inside `hooks/`) is silently reported "ok" with exit 0 instead of FAIL.
Kind: silent-failure
Seed: core/hooks/tests/compliance-check.sh new `--canon-duplication <rulebook-path>` mode (`find "$target" -maxdepth 3 -name "$name" -type f`)
cap_seconds: 120
tier: default
diff_stat_lines: 21-200 bucket
started_at: 2026-08-08T18:10:38+09:00
ended_at: 2026-08-08T18:16:00+09:00

### Reproduce
```
mkdir -p rb/hooks/vendor/deep/deeper
echo fake > rb/hooks/vendor/deep/deeper/trailer-gate.sh
/path/to/core/hooks/tests/compliance-check.sh --canon-duplication rb
echo exit is $?
```

### Observed
```
compliance-check: ok — no vendored 'trailer-gate.sh' under rb
...
exit is 0
```
A vendored copy of core canon file `trailer-gate.sh` sits under `rb/hooks/vendor/deep/deeper/` (4 path components below `rb`), so `find "$target" -maxdepth 3` never reaches it. The check reports every canon file "ok" and exits 0, exactly as if no vendored copy existed.

### Expected
The check should either FAIL (detect the vendored copy at any depth, since nothing in the ADR, the rollout doc, or the script itself constrains how deep a rulebook's hooks/ tree may nest a vendored file) or the `-maxdepth 3` bound should be documented and enforced against actual rulebook layouts — currently no state (comment, manifest field, or test) records why 3 is the right bound, so a rulebook that vendors a canon file one level deeper than today's rulebooks happen to nest their hooks defeats the duplication check without any error, warning, or non-zero exit.
