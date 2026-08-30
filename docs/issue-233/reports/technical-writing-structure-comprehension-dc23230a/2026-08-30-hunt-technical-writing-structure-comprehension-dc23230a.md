---
proposal: docs/issue-233/reports/technical-writing-structure-comprehension-dc23230a.md
---

# Hunt record — technical-writing-structure-comprehension-dc23230a

## before-landing — stance: wording-fix commit fcfdbce (PR #382 follow-up, "unify jurisdiction wording to #374's phrasing") may hide a logic change, a message/test coupling, or a cross-file phrasing mismatch

Verdict: NO FINDING
Seed: git show fcfdbce (core/hooks/board-gate.sh header comment + deny() string,
warrant/hooks/lib/scope-gate.py header comment + deny message, both rewording
"outside what this gate claims to bound"/"claims to catch" to #374's
"out of this gate's jurisdiction")
cap_seconds: unspecified (not given by dispatcher this round)
tier: default
diff_stat_lines: 27 (16 in core/hooks/board-gate.sh + 11 in warrant/hooks/lib/scope-gate.py; excludes the unrelated 105-line report file also touched by fcfdbce)
started_at: 2026-08-30T00:00:00Z
ended_at: 2026-08-30T00:25:00Z

Checked all four angles named in the brief:

1. Constant byte-identity: diffed each of the ten named regex/set constants
   (INTERPRETER_HEADS, INLINE_FLAG_HEADS, WRITE_UNSAFE_HEADS, FUSED_INTERP_RE,
   VAR_INTERP_RE, UNANALYZABLE_WRITE_SHAPE, UNANALYZABLE_HEAD_RE,
   UNANALYZABLE_FLAG_RE, UNANALYZABLE_WRITE_HEAD_RE, IFS_TOKEN_RE) against
   origin/main by md5sum of each definition block in core/hooks/board-gate.sh —
   all ten OK. `git diff origin/main -- core/hooks/board-gate.sh
   warrant/hooks/lib/scope-gate.py` never touches a line containing any of
   these names in either file.

2. Read both changed comment paragraphs and both changed deny-message strings
   in full, before and after. The rewording preserves the same clauses in the
   same order in both files — no dropped clause, no inverted meaning. The
   "same limit holds on the head side" sentence added in PR #382 (this
   session's own prior addition) is untouched by fcfdbce except for its
   trailing "claims to catch" -> "out of this gate's jurisdiction" swap.

3. Repo-wide grep for the literal retired phrases "claims to bound" /
   "claims to catch" outside docs/ found zero hits in any test file
   (core/hooks/tests/, warrant/hooks/tests/). No test does a string-match
   against gate deny-message wording; `run-board-gate-tests.sh` and
   `run-scope-gate-tests.sh` assert only exit codes (deny/allow) per named
   case, never message text.

4. Extracted the "same limit holds on the head side" paragraph from both
   files' header comments and both files' deny() messages side by side:
   word-for-word identical (modulo line-wrap points only) between
   core/hooks/board-gate.sh and warrant/hooks/lib/scope-gate.py — no extra
   word, no punctuation or capitalization drift.

Ran both test suites as a behavioral check: `run-scope-gate-tests.sh` 62/62
pass. `run-board-gate-tests.sh` 159 passed / 2 failed
(`feasibility-spikes`, `ops-postmortems`) — reproduced the identical 2
failures on origin/main via a clean `git worktree add /tmp/wt-main
origin/main`, confirming they predate and are unrelated to fcfdbce.

No reproduction of a logic change, a message/test coupling, or a cross-file
phrasing mismatch survives; this is a genuine wording-only diff, matching its
stated intent.
