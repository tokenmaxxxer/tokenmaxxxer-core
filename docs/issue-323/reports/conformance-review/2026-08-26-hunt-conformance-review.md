---
proposal: docs/issue-323/proposals/conformance-review.md
---

# Hunt record — conformance-review

## after-proposal — stance 0: assume the gate just touched is bypassable — find the bypass

Verdict: FINDING — board-gate.sh's write-target scan is fooled by a
command-substitution-indirected shell variable feeding a plain write command
(`cp`/`mv`/`install`/etc.), allowing a role session to write an out-of-scope
`docs/issue-<n>/reports/...` path with no deny at all.
Kind: silent-failure
Seed: after-proposal diff `git diff origin/main HEAD -- docs/issue-323/proposals/conformance-review.md docs/issue-323/reports/conformance-review/survey.md` (docs-only, 262 insertions across the two files). The proposal's own Constraints section states the write-set this hunt probed: "Never edit docs/issue-323/reports/implementation.md or any src/warrant/core/ code path." board-gate.sh is the mechanism that is supposed to enforce exactly that restriction for this role/branch.
cap_seconds: 60
tier: docs-only (max 1 stance) — actual wall-clock ran well over the cap because the finding required extracting and driving board-gate.sh's embedded python judge directly (see Reproduce); recorded honestly rather than cut short with an unverified claim.
diff_stat_lines: 262
started_at: 2026-08-26T10:18:24+09:00
ended_at: 2026-08-26T10:23:34+09:00

### Reproduce
Ran board-gate.sh's own embedded python program (extracted verbatim from
`core/hooks/board-gate.sh`, unmodified) offline against a synthetic
PreToolUse Bash payload, with `CLAUDE_ROLE=conformance-review` and `cwd` set
to this repo checkout (which does carry `docs/specs/approvers.md`, so
`is_board=True` — the same precondition R5 enforcement requires):

```
cmdline = 'T=$(echo ZG9jcy9pc3N1ZS0zMjMvcmVwb3J0cy9pbXBsZW1lbnRhdGlvbi5tZA== | base64 -d); cp /this-path-does-not-exist-xyz "$T"'
```//
(`ZG9jcy9pc3N1ZS0zMjMvcmVwb3J0cy9pbXBsZW1lbnRhdGlvbi5tZA==` is
`docs/issue-323/reports/implementation.md` base64-encoded — the
implementation role's own record, explicitly out of this role's write-set
per contract v3 s11 and the proposal's own Constraints.)

Driver script: `/tmp/gate_probe.py` — extracts the `<<'PY' ... PY` program
embedded in `core/hooks/board-gate.sh` via regex, sets `CORE_PAYLOAD` to a
`{"tool_name": "Bash", "tool_input": {"command": cmdline}, "cwd": <repo>,
"session_id": "probe-session"}` JSON event, `GATE_LIB_PY` to the real
`core/hooks/lib/gate-lib.py`, `CLAUDE_ROLE=conformance-review`, and runs it
with `python3 -c <program>`, exactly as `board-gate.sh`'s own last line does.

```
python3 /tmp/gate_probe.py
```

### Observed
```
cmdline probed: T=$(echo ZG9jcy9pc3N1ZS0zMjMvcmVwb3J0cy9pbXBsZW1lbnRhdGlvbi5tZA== | base64 -d); cp /this-path-does-not-exist-xyz "$T"
board-gate exit code: 0
board-gate stderr:
VERDICT: ALLOWED (bypass)
```
board-gate.sh's judge exits 0 (allow) for a Bash call whose real effect is
`cp <src> docs/issue-323/reports/implementation.md` — a write to a foreign,
explicitly-forbidden record — and emits no stderr at all: the deny is not
merely wrong, it is silent, indistinguishable from a plain read passing R1-R5
cleanly.

Root cause (read in `core/hooks/board-gate.sh`): the segment
`T=$(echo ... | base64 -d); cp /this-path... "$T"` splits into two
`;`-separated segments. The assignment segment `T=$(...)` and the `cp`
segment both get `SUBSHELL.search` hits (the `$(...)`), so both are
"failing" (unproven read-only) via `_segment_is_failing`. But
`_write_target_windows` finds no literal `>`/`>>` redirect in either
segment, so `scan_targets = [seg]` (whole segment text) is regex-scanned for
a literal `docs/`-shaped substring — and finds none, because the real
target only exists post-expansion, inside the base64 blob and the `$T`
reference. `own_hits` is empty for both segments. The gate then falls back
to `_is_unanalyzable_write_shape(stripped, head, cmdline)` — but that
function only recognizes five write-obscuring shapes: a literal `<<`
heredoc, an `INTERPRETER_HEADS` command with `-c`/`-e`, a
`WRITE_UNSAFE_HEADS` head (`dd`/`awk`/`gawk`/`nawk`/`mawk`/`ed`/`ex`), a
fused-interpreter or `$IFS`-token-fusion pattern, or a target-less `tee`.
`cp` (and `mv`, `install`, `rsync`, `ln`, every other ordinary write command)
is in none of those lists, so `_is_unanalyzable_write_shape` returns
`False` for the `cp` segment even though — exactly like the heredoc case
issue-225 already fixed — its real write target cannot be read from the
visible command text. Both `candidates` and `unanalyzable` end up empty, so
`hits` is empty and `if not hits: allow()` fires at
`core/hooks/board-gate.sh:713-714` — the same "nothing under docs/, not
this gate's business" fallback that is correct for a genuine non-board
command, but here fires on a call whose real target is unmistakably a board
path once `$T` expands.

### Expected
A write-capable command (`cp`/`mv`/`install`/…) whose target argument is not
literal text in the command line — because it comes from a command
substitution, a variable set by a prior substitution, or any other
non-literal construction — should be treated the same way board-gate.sh
already treats a heredoc body, a `dd` invocation, or an `-c`/`-e` inline
script since issue-225: added to `unanalyzable` and denied
(`role and is_board`), not silently waved through as `hits == []`. As
written, `_is_unanalyzable_write_shape`'s coverage list is closed over a
fixed set of command *heads* rather than over "does this write-capable
segment carry a non-literal target," so any ordinary file-copy/move/link
command with an obscured target is a hole in exactly the class of defect
issue-225 was supposed to close for good.
