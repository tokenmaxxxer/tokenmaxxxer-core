---
code_under_review:
  - core/hooks/board-gate.sh
  - core/hooks/test_board_gate.py
type: fix
breaking: false
verdict: pass
loop_state: landed
---

# implementation record — issue-198

## Summary of work

board-gate.sh's Bash-command write-target scan split the raw command text
on every newline before classifying segments. A heredoc body sits between
its `<<DELIM` line and the terminator line, delivered as literal stdin
data, but each of its lines became its own pseudo-segment with no
recognizable command head — so a body line that only **mentioned** a
`docs/issue-<n>` path (a grep/echo result quoted for review, a code
comment) was misread as an unproven write candidate and denied outright.
Plain `grep`/`echo` invocations were already exempted via
`READ_ONLY_HEADS` before this fix; only the heredoc-body case was open.

Fix: added `_mask_heredocs()`, applied to the command line right before
both `_split_segments` call sites (`_write_candidate_segments` and the
main Bash-tool branch). It locates each `<<[-]DELIM` operator, finds the
matching terminator line, and blanks the interior body (newlines
preserved so line-based regexes elsewhere stay unaffected) before segment
splitting runs. The `<<` line itself — where a real redirect target such
as `cat <<EOF > docs/issue-3/x.md` lives — is left untouched, so an
actual heredoc-delivered write to the board still resolves its target and
is still judged by R1–R5 exactly as before.

## Why

The gate judged Bash calls by scanning command TEXT for `docs/`
substrings rather than the tool payload's resolved write target — a
heredoc body line matching that substring pattern was read as if it were
a write argument. Design reused from on-the-record#651's proposal
(originally filed against the wrong repo — the gate script lives in
core, not on-the-record); this record narrows that design to the one gap
the field survey (below) found still open: heredoc bodies specifically,
since grep/echo whole-command mentions were already exempted by the
existing `READ_ONLY_HEADS` head-based check.

## Upstream basis

Refs on-the-record#651, on-the-record#628. Issue: #198.

## What will be done / done

- [x] `core/hooks/board-gate.sh`: added `_mask_heredocs()`; wired into
  both `_split_segments` call sites so heredoc body content is never
  scanned as a write candidate, while the `<<` operator line's own
  redirect target stays live.
- [x] `core/hooks/test_board_gate.py`: pytest red/green pairs — mention-only
  grep/echo/heredoc-body cases pass; real writes (redirect on the `<<`
  line, foreign issue dir, foreign role report, own-record heredoc
  write) are still correctly allowed/denied per R1–R5.

## Out of scope

No change to R1–R5 semantics, to the existing shell test suite
(`core/hooks/tests/run-board-gate-tests.sh`), or to any file outside
`core/hooks/board-gate.sh` / `core/hooks/test_board_gate.py`.

## How it was confirmed to work

`derived: python3 -m pytest core/hooks/test_board_gate.py -q`
```
........
8 passed in 0.38s
```

`derived: bash core/hooks/tests/run-board-gate-tests.sh | tail -2`
```
== 102 passed, 0 failed ==
```

`derived: bash core/hooks/tests/run-all.sh | tail -1`
```
ALL OK
```

## What did not work

None.

## Open findings

None open.
