---
proposal: docs/issue-233 (PR #358 follow-up: gate-lib.py _shell_split word-formation fix for board-gate.sh)
---

# Hunt record — gate-lib-shell-split-ansi-c-quote

## after-proposal — stance: word-formation mechanism the new `_shell_split` tokenizer does not handle (ANSI-C `$'...'` quoting)

Verdict: FINDING — `core/hooks/lib/gate-lib.py`'s new `_shell_split`/`_WORD_TOKEN_RE` does not recognize bash's ANSI-C quoting (`$'...'`): it tokenizes the leading `$` as a separate bare-word token and then glues it onto the immediately-following single-quoted span, producing a fused word like `$-c` instead of the real word `-c`. When the interpreter's `-c`/`-e` flag itself is spelled as `$'-c'`/`$'-e'`, `gate_trailing_words()` never contains a literal `"-c"`/`"-e"` string, so board-gate.sh's `INLINE_FLAG_WORDS` membership check in `_is_unanalyzable_write_shape()` never fires — even though real bash executes it as an ordinary `-c` invocation. Combined with a payload that builds its write-target path at Python runtime (via `chr()` codes) instead of spelling it literally in the Bash command text, this is a full, live, undetected bypass of the write-set enforcement board-gate.sh exists to provide: the command is allowed (exit 0) yet actually writes outside the calling role's write-set.
Kind: silent-failure
Seed: core/hooks/lib/gate-lib.py's `_shell_split`/`_WORD_TOKEN_RE` addition (replacing `segment.split()` in `_resolve_transparent`), and its consumers `gate_head_of`/`gate_trailing_words` used by core/hooks/board-gate.sh's `_is_unanalyzable_write_shape`
cap_seconds: not specified by dispatcher (standalone invocation)
tier: not specified by dispatcher (standalone invocation)
diff_stat_lines: not specified by dispatcher (standalone invocation; diff vs previous gate-lib.py commit adds ~80 lines, the `_shell_split`/`_WORD_TOKEN_RE` block)
started_at: 2026-08-30T00:00:00Z (wall-clock not tracked precisely; session-relative)
ended_at: 2026-08-30T00:05:00Z (wall-clock not tracked precisely; session-relative)

### Reproduce

First, confirm bash itself really executes `$'-c'` as the literal flag `-c` (no exotic behavior, pure standard ANSI-C quoting):

```
$ bash -c 'python3 $'"'"'-c'"'"' "print(123456)"'
123456
```

Confirm the tokenizer bug directly against `gate-lib.py` (run from the repo root):

```python
import importlib.util, os
spec = importlib.util.spec_from_file_location(
    "gate_lib", os.path.join(os.getcwd(), "core/hooks/lib/gate-lib.py"))
gate_lib = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gate_lib)

seg = """python3 $'-c' "print(1)" """
print(gate_lib._shell_split(seg))          # -> ['python3', '$-c', 'print(1)']
print(gate_lib.gate_head_of(seg))          # -> 'python3'
print(gate_lib.gate_trailing_words(seg))   # -> ['$-c', 'print(1)']  (never literal '-c')
```

Then a full end-to-end run of `core/hooks/board-gate.sh` in a fresh fixture repo (git init,
`docs/specs/approvers.md`, branch `issue-3/qa`, `CLAUDE_SKILL=qa`,
`CLAUDE_PLUGIN_ROOT_CORE=<repo>/core`), sending a `Bash` tool_input whose command is

```
python3 $'-c' "import pathlib; p=''.join(chr(c) for c in [100,111,99,115,47,105,115,115,117,101,45,51,47,114,101,112,111,114,116,115,47,112,119,110,101,100,46,109,100]); pathlib.Path(p).write_text('bypass')"
```

(the `chr()` list spells `docs/issue-3/reports/pwned.md` at Python runtime only, so the
literal substring never appears in the Bash command text board-gate.sh's own literal-scan
sees) as role `qa` on branch `issue-3/qa` — a write `qa` does not own (R5: `qa` may write only
`qa.md`/`qa/**`, not a foreign `reports/pwned.md`):

```
$ printf '%s' "$PAYLOAD" | env CLAUDE_PROJECT_DIR="$TD" CLAUDE_PLUGIN_ROOT_CORE="$REPO/core" \
      CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" CLAUDE_SKILL=qa /bin/bash "$REPO/core/hooks/board-gate.sh"
```

### Observed

- Gate verdict: exit code **0** (ALLOW), no stderr.
- Real bash execution of the identical command string in the same fixture directory
  (`/bin/bash -c "$CMD"`) exits 0 and actually creates
  `docs/issue-3/reports/pwned.md` with content `bypass` — a real write outside role
  `qa`'s write-set, performed via a genuine `-c` interpreter invocation the gate's own
  `INTERPRETER_HEADS`/`INLINE_FLAG_WORDS`/`_is_unanalyzable_write_shape` logic exists
  specifically to catch.

### Expected

board-gate.sh should deny this call — either because `_is_unanalyzable_write_shape`
correctly recognizes `python3 $'-c' "..."` as an interpreter `-c` invocation (fail-closed,
matching the deny already given to `python3 $'-c' "..."` when the write target IS spelled
literally in the command text, which own_hits catches by a different path and denies with
"belongs to another role"), or, failing that, by falling into the same
`unanalyzable`/fail-closed branch that a bare `bash -c "..."` already takes. Instead the
call is silently ALLOWED, identical in effect to the pre-issue-233 bypass this whole fix
round exists to close.
