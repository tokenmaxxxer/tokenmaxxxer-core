---
proposal: docs/issue-146/proposals/2026-08-07-gate-prose-coverage-check.md
---

# Hunt record — gate-prose-coverage-check

## before-landing — stance 0: assume the gate/check just built is bypassable — find the bypass

Verdict: FINDING — naive case-insensitive substring match lets a short/common gate needle "pass" coverage by accidentally appearing inside an unrelated word in the prose, producing a false clean (0 violations, exit 0) when the needle's real topic is never actually covered.
Kind: silent-failure
Seed: core/hooks/tests/gate-prose-coverage-check.py (new file, static gate/prose coverage checker)
cap_seconds: 180
tier: size:>200, default
diff_stat_lines: n/a (new files: gate-prose-coverage-check.py, run-gate-prose-coverage-tests.sh, docs/handbooks/gate-prose-coverage-check.md)
started_at: 2026-08-08T17:19:16+09:00
ended_at: 2026-08-08T17:29:00+09:00

### Reproduce
```
mkdir -p /tmp/fixture/unit/hooks
printf '#!/bin/bash\n# talks about skip nothing\necho hi\n' > /tmp/fixture/unit/hooks/directive.sh
printf '#!/bin/bash\nhas_any("ip")\n' > /tmp/fixture/unit/hooks/my-gate.sh
python3 core/hooks/tests/gate-prose-coverage-check.py /tmp/fixture
echo EXIT=$?
```

### Observed
```
summary: 0 violation(s), 1 gate(s) with needles checked, 0 gate(s) with >=1 violation, 0 unit(s) with >=1 violation
EXIT=0
```
The needle "ip" is only present because it is a substring of the unrelated word "skip" in the directive's comment — the directive never actually documents an "ip" check. Confirmed the checker's extraction/matching machinery itself is otherwise sound by swapping in an unrelated needle ("TOTALLY-UNRELATED-XYZ") against the same fixture, which correctly produces `VIOLATION ... exit=1`.

### Expected
The checker should not treat an incidental substring match inside an unrelated word as coverage; it should require a word-boundary (or otherwise semantically-grounded) match, or it fails to catch exactly the kind of gate/prose divergence issue-146 exists to catch — any gate literal that is short enough, or common enough, to appear inside some unrelated word anywhere in the corpus silently defeats the check.
