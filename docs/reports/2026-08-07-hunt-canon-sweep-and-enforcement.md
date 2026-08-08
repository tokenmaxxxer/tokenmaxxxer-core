---
proposal: docs/issue-142/proposals/2026-08-07-canon-sweep-and-enforcement.md
---

# Hunt record — canon-sweep-and-enforcement

## after-proposal — stance 1: assume this guard goes silent when its own input is malformed — make it go silent.

Verdict: FINDING — the new fail-open-idiom regex only matches when `*)`, `exit 0`, and `;;` sit on one physical line, so the same kill-switch bug written across multiple lines is never flagged.
Kind: silent-failure
Seed: git diff HEAD -- core/hooks/tests/compliance-check.sh (new check: grep -qE '^\s*\*\)\s*exit\s+0\s*;;' "$f")
cap_seconds: unknown
tier: default
diff_stat_lines: 42
started_at: 2026-08-07T00:00:00Z
ended_at: 2026-08-07T00:15:00Z

### Reproduce
cat > /tmp/f.sh <<'SCRIPT'
#!/usr/bin/env bash
case "$FOO_OFF" in
  1|true) exit 0 ;;
  *)
    exit 0
    ;;
esac
SCRIPT
grep -qE '^\s*\*\)\s*exit\s+0\s*;;' /tmp/f.sh && echo MATCH || echo NOMATCH

### Observed
NOMATCH — the hand-rolled `*) ... exit 0 ... ;;` fail-open case branch is present (semantically identical to the confirmed issue-72 bug this check exists to catch) but the guard reports nothing, so a script written this way would pass compliance-check with rc=0 silently.

### Expected
The check should flag any `*)` branch whose body is `exit 0`, regardless of whether the branch is written on one line or wrapped across several — a purely cosmetic reformatting should not defeat a guard specifically added to catch reintroductions of this exact bug.
