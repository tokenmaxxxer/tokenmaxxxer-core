---
kind: current-state-survey
subject: issue-98
produced_by: implementation
---

# Current-state survey — issue-98

## Scope of this survey

Issue #98 asks for a class-level fix to the wrapper-command bypass Finding 1
(`docs/issue-94/reports/execution-observation.md:275-313`) named against
`gh-guard.sh`, plus a separate confirm-and-fix pass on `board-gate.sh`'s
`READ_UNLESS_INPLACE` heads (requirement 2). This survey reads the two gates
and their shared library, then live-reproduces every variant the issue lists
against the current (unfixed) code on this branch, to settle two things the
issue itself leaves open: whether board-gate's `FILE_REDIR` half is actually
exploitable by the wrapper class (issue text: "다른 분기가 잡는지는 관찰이
미확정으로 남김"), and what board-gate's real `awk`/`sed` gap looks like.

## Files read

- `core/hooks/gh-guard.sh` — 11 `RULES`, 3 tagged `dequote=True` (review
  --approve, merge/close/reopen, issue create/close/…), 8 tagged `False`.
  The loop (`:128-130`) does `dq = gate_lib.gate_dequote(cmd)` once, then
  `re.search(pat, dq if dequote else cmd)`. No segmentation.
- `core/hooks/board-gate.sh` — `_write_candidate_segments` (`:212-244`):
  per segment, first checks `SUBSHELL.search(seg) or
  gate_lib.gate_outside_quotes(seg, FILE_REDIR.pattern)`; if that's clean,
  resolves `head = _head_of(stripped)` (`:199-209`, walking `TRANSPARENT =
  ("xargs","env","time","nice","command","builtin")`) and classifies: `git`
  read-subcommands skip, `READ_ONLY_HEADS` skip, `READ_UNLESS_INPLACE =
  ("sed","awk","gawk")` skip unless `INPLACE` (`-i`/`--in-place`) matches —
  **any other head falls through to `failing.append(seg)`, i.e. fails
  closed.** `SEGMENT` (`:140`) still carries its own inline copy of the
  quote-span alternation, byte-identical to `gate_lib.GATE_QUOTE_SPAN`
  (Finding 3, unresolved since #94).
- `core/hooks/lib/gate-lib.py` — `GATE_QUOTE_SPAN`, `gate_dequote`,
  `gate_outside_quotes` (`:174-192`), added by #94, consumed by all three of
  `approval-gate.sh`, `board-gate.sh`, `gh-guard.sh` today. No head-resolution
  primitive lives here yet — `TRANSPARENT`/`_head_of` are board-gate-local.
- `core/hooks/tests/run-gh-guard-tests.sh` (37 assertions),
  `run-board-gate-tests.sh` (67 `run`/`runb` sites + 2 hand-rolled), both
  read in full; harness shape (`run`/`runb`/`drifted`/`noRole`/`noremote`/
  `fastpath`/`garbage` closures, `$BOARD=docs/issue-3`, role `qa` on branch
  `issue-3/qa`) confirmed reusable for new cases with no harness changes
  needed.
- `docs/issue-94/reports/execution-observation.md` (Finding 1, 3, 5 read in
  full) and `docs/issue-94/proposals/2026-08-03-…-writeish-and-segment-gh-
  guard.md` (the prior proposal's Rationale on why `gh-guard.sh` was
  deliberately NOT segmented — reused below, not re-litigated).

## Live reproduction against the current (unfixed) code

Run directly on this branch, `env CLAUDE_ROLE=<role> bash core/hooks/<gate>.sh`
fed the same JSON shape the test harnesses use.

### gh-guard.sh — all 8 issue-named wrapper variants bypass, confirmed

| command | verdict (current) | expected |
|---|---|---|
| `gh pr merge 5` (baseline) | deny | deny (unchanged) |
| `bash -c "gh pr merge 5"` | **allow** | deny |
| `bash -lc "gh pr merge 7 --merge"` | **allow** | deny |
| `timeout 30 bash -c "gh pr merge 7 --merge"` | **allow** | deny |
| `env bash -c "gh pr merge 7 --merge"` | **allow** | deny |
| `nohup bash -c "gh pr merge 7 --merge"` | **allow** | deny |
| `xargs -I X bash -c "gh pr merge 7 --merge" X` | **allow** | deny |
| `python3 -c "import os; os.system('gh pr merge 7 --merge')"` | **allow** | deny |
| `sh -c "gh pr merge 5"` | **allow** | deny |
| `eval "gh pr merge 5"` | **allow** | deny |
| `grep "gh pr merge" file.txt` (negative space) | allow | allow (unchanged) |

Every wrapper variant the issue lists is a live false-allow today. All ten
lines above were run as real subprocesses in this session (not inferred);
the negative-space `grep` case already allows and must keep doing so.

### board-gate.sh — the FILE_REDIR half is bypassed, but a different branch
already catches every named variant; the `awk`/`sed` half is genuinely open

Confirms the issue's own uncertainty both ways — different things are true
of the two named checks:

- `bash -c "echo hi > docs/issue-3/reports/review.md"` (foreign record,
  role `qa`) → **deny**, with the R5 message ("belongs to another role"),
  identical to the unwrapped `echo hi > …` case. Same result for
  `timeout 30 bash -c "…"` and `nohup bash -c "…"`. Reason, traced in
  `_write_candidate_segments`: `gate_outside_quotes(seg, FILE_REDIR.pattern)`
  does miss it (the `>` is dequoted away, confirming the issue's claim
  literally) — but `_head_of()` then resolves the segment's head to `bash`
  (or `timeout`/`nohup`, neither in `TRANSPARENT` either), which is not in
  `READ_ONLY_HEADS`/`READ_UNLESS_INPLACE`, so the segment still fails
  closed via the fall-through `failing.append(seg)`, and the raw (non-
  dequoted) docs-path token scan (`:264-266`) still finds the path inside
  the quotes regardless. **No board-gate fix is needed for this half** —
  confirmed by running the R5-foreign-record case, not merely reasoned.
  A wrapped write to the role's OWN record (`…/reports/qa.md`) allows, which
  is the correct verdict either way (qa may write qa.md) and is not
  evidence of a hole.
- `awk '{print > "docs/issue-3/reports/x.md"}' f` → **allow** — a real gap.
  `_head_of()` resolves to `awk`, which IS in `READ_UNLESS_INPLACE`; the
  branch only checks `INPLACE` (`-i`/`--in-place`), never notices that awk's
  own `print > "file"` redirect syntax writes a file with no `-i` involved.
  This is not the wrapper-command class (no `bash -c` here at all) — it's
  `READ_UNLESS_INPLACE` trusting "no `-i`" as "this head cannot write,"
  which is false for awk.
- `sed -n '/x/{ w docs/issue-3/reports/x.md\n}' f` → **allow** — the same
  family of gap for sed's `w` command (writes matched lines to a file,
  independent of `-i`).
- Negative-space controls confirming the awk/sed fix has room to land
  without new false-positives: `awk '$1 > 5 {print}' …/review.md` (a
  read-only *comparison* using `>`, not a redirect) → allow today; a fix
  that flags any bare `>` in an awk segment as a write-candidate would
  **newly deny this** — a real, known false-positive cost that has no
  clean regex-only avoidance (awk's grammar overloads `>` for both), and
  the existing file's own repeated comment ("over-blocking is the safe
  direction here") is the precedent for accepting it. `sed -n 1,5p
  …/review.md` (plain read) → allow, unaffected either way.

## What board-gate already has that gh-guard doesn't (the reuse question,
requirement 1)

`TRANSPARENT` + `_head_of()` is a real, working "resolve through
pass-through wrappers to the command that actually runs" primitive — but it
answers a different question than requirement 1 needs. It tells you *which
single word is the head*, after skipping xargs/env/time/nice/command/
builtin's own flags. It has no notion of "this head takes its next argument
as a **string to execute**, and that argument may itself be a quoted span,"
which is what `bash -c`/`sh -c`/`eval`/`python3 -c` are and `xargs`/`env` are
not (`xargs cmd arg1 arg2` runs `cmd` with bare word arguments; `bash -c
"cmd arg1 arg2"` runs a **new shell parse** of one string). Reusing
`_head_of()` means relocating it (and `TRANSPARENT`) to `gate_lib.py` so both
gates call the same resolver — not reimplementing head-resolution — and
then adding a **new, sibling** enumeration (`WRAPPER_HEADS`) for the
different question, on top of the same resolver. `TRANSPARENT` itself is
also missing `timeout` and `nohup` — two of the issue's own named variants —
which don't matter for board-gate today (an unrecognized head already fails
closed there) but would matter for gh-guard's new check if it needs to see
through them to find the real wrapper head underneath.

## Test harness fit

Both `run-gh-guard-tests.sh`'s `run()` and `run-board-gate-tests.sh`'s
`run()`/`runb()` already parametrize command/role/branch/path with no
harness change required to add the regression and negative-space cases
requirement 3 asks for; new cases append after the existing issue-94
section in each file, following the same naming convention
(`wrapper-*`/`quote-*` prefix, `gap-*` for a deliberately-kept-open
residual, mirroring `gap-c-*`/`gap-f-*` already in `run-gh-guard-tests.sh`).

## Scout brief

`docs/issue-98/reports/implementation/scout-brief.md` — GTFOBins and sudo's
`noexec` bypass history both converge on "enumerate the interpreter-escape
family; there's no clean structural detector," which is the same choice
`TRANSPARENT`/`READ_ONLY_HEADS`/`READ_UNLESS_INPLACE` already made for their
own questions. `perl` and `python`/`python3`/`python2` are added to the
enumeration on that basis (python3 is also the issue's own named case,
independently required).
