---
proposal: docs/issue-233 (PR #354 follow-up: interpreter-head expansion fix, board-gate.sh / scope-gate.py)
---

# Hunt record — scope-gate-splice-line-continuations

## after-proposal — stance 1: warrant-hunter (composition regression / silent failure at this transition)

Verdict: FINDING — `_splice_line_continuations()` in scope-gate.py is quote-blind: it splices a backslash-newline pair even inside a single-quoted argument (where real bash never processes escapes), so a literal multi-line single-quoted string can be accidentally welded into the literal word `tee`/`dd`/`ed`/`ex`, turning a previously non-blocking Bash call into a hard `exit 2` refusal.
Kind: composition
Seed: git diff origin/main..HEAD -- core/hooks/board-gate.sh warrant/hooks/lib/scope-gate.py core/hooks/tests/run-board-gate-tests.sh core/hooks/tests/run-scope-gate-tests.sh
cap_seconds: not specified by dispatcher (standalone invocation)
tier: not specified by dispatcher (standalone invocation)
diff_stat_lines: not specified by dispatcher (standalone invocation)
started_at: 2026-08-30T00:00:00Z (wall-clock not tracked precisely; session-relative)
ended_at: 2026-08-30T00:00:00Z (wall-clock not tracked precisely; session-relative)

### Reproduce

```
cd /tmp && mkdir -p sg3 && cd sg3
git init -q
mkdir -p docs/proposals
python3 - "docs/proposals/2026-08-08-probe.md" <<'PYEOF'
import sys
open(sys.argv[1], "w").write("---\nstatus: approved\nfiles:\n  - src/app.py\n---\nbody\n")
PYEOF

ROOT=<repo-root>
python3 - <<'PYEOF' > /tmp/sg3/payload.json
import json
# One literal backslash immediately followed by a literal embedded newline,
# both inside single quotes -- in real bash this is NOT a line continuation
# (single quotes suppress all escape processing); the argument to grep is
# meant to keep the backslash AND the newline as two literal characters,
# spanning "t" and "ee" as unrelated halves of an incidental match target.
cmd = "grep 'foo t" + "\\" + "\n" + "ee bar' src/other.py"
print(json.dumps({"tool_name": "Bash", "tool_input": {"command": cmd}, "cwd": "/tmp/sg3"}))
PYEOF

# current HEAD (this diff)
PAYLOAD=$(cat /tmp/sg3/payload.json)
printf '%s' "$PAYLOAD" | CLAUDE_PROJECT_DIR=/tmp/sg3 CLAUDE_PLUGIN_ROOT_CORE="$ROOT/core" \
  /bin/bash "$ROOT/warrant/hooks/scope-gate.sh"
echo "rc=$?"

# origin/main (pre-fix) scope-gate.py, same payload, same env
git -C "$ROOT" show origin/main:warrant/hooks/lib/scope-gate.py > /tmp/scope-gate-main.py
printf '%s' "$PAYLOAD" | WARRANT_PAYLOAD="$PAYLOAD" CLAUDE_PROJECT_DIR=/tmp/sg3 python3 /tmp/scope-gate-main.py
echo "rc=$?"
```

### Observed

Current HEAD (this diff):
```
warrant: refused — this Bash call carries an un-analyzable write-capable shape
(a heredoc body, an interpreter -c/-e inline script, or tee/dd) while
docs/proposals/2026-08-08-probe.md's write set is enforced. ...
rc=2
```

origin/main (pre-fix), identical payload:
```
rc=0
```

Root cause, confirmed directly against the shipped regex/function
(`warrant/hooks/lib/scope-gate.py`):

```python
>>> import re
>>> _BACKSLASH_NEWLINE_RUN_RE = re.compile(r"\\+\n")
>>> def splice(text):
...     def repl(m):
...         b = m.group()[:-1]
...         lit = "\\" * (len(b)//2)
...         return lit if len(b) % 2 == 1 else lit + "\n"
...     return _BACKSLASH_NEWLINE_RUN_RE.sub(repl, text)
>>> cmd = "grep 'foo t" + "\\" + "\n" + "ee bar' src/other.py"
>>> splice(cmd)
"grep 'foo tee bar' src/other.py"
```

`_splice_line_continuations` runs unconditionally over the raw command text
before `UNANALYZABLE_WRITE_SHAPE.search()` — it has no notion of quoting at
all, so a single-quoted argument (where bash performs zero escape
processing, including line continuations) gets the exact same backslash-run
parity treatment as an unquoted head token. Here that welds the harmless
substring "t" + newline + "ee" into "tee", which then trips the
pre-existing, unscoped `(?:^|\s)tee\b` alternative and produces a hard
`exit 2` deny — even though the command is an ordinary `grep` read with no
`tee`, `-c`/`-e`, or write of any kind, unrelated to the interpreter-head
masking class this round of fixes targets.

### Expected

`_splice_line_continuations` should not weld characters together across a
quoted span the same way `board-gate.sh`'s own `_split_segments` already
avoids (its quote-span match is consumed as one atomic token before the
backslash-run count ever inspects it — the sibling implementation this
scope-gate splice was explicitly modeled on). A quote-aware scope-gate
splice (or one scoped only to the position right after a genuine command
boundary, matching how the two new `UNANALYZABLE_WRITE_SHAPE` alternatives
already anchor themselves) would leave this ordinary `grep` read
undisturbed and preserve the pre-fix `rc=0`.

Neither `run-board-gate-tests.sh` nor `run-scope-gate-tests.sh` exercises a
backslash-newline pair *inside a quoted argument*; every existing
backslash-newline test targets the unquoted interpreter-head position only.
