---
kind: build-proposal
subject: issue-90
produced_by: implementation
loop_state: proposed
upstream:
  - path: docs/issue-90/reports/implementation/survey.md
    sha: <set at commit>
---

files: `core/hooks/board-gate.sh`, `core/hooks/approval-gate.sh`, `core/hooks/tests/run-board-gate-tests.sh`, `core/hooks/tests/run-approval-gate-tests.sh`, `docs/handbooks/board-gate-tests.md`, `docs/handbooks/approval-gate-tests.md`

## Request

Two defects, both confirmed live against the current file (survey):

1. `core/hooks/board-gate.sh`'s `Bash` candidate builder
   (`board-gate.sh:234-246`): when `_reads_only(cmdline)` returns `False`
   because ANY segment of the command line cannot be proven read-only,
   the candidate scan then runs `re.findall` over the **entire raw
   command line**, sweeping in every `docs/`-shaped token — including
   ones sitting inside a DIFFERENT, already-provably-read-only segment —
   as an R4 write candidate. A genuinely read-only command (e.g. `grep`
   reading a foreign issue's path) gets refused solely because some
   unrelated segment on the same line could not be classified.
2. `core/hooks/approval-gate.sh` carries the identical twin defects
   `board-gate.sh` had before PR #89 (issue-88): `READ_ONLY_HEADS`
   (`approval-gate.sh:84`) has no `"cd"` entry, and `WRITEISH`
   (`approval-gate.sh:86`) is quote-blind (`re.compile(r"[>|`]|\$\(")`
   flags a `>`/`|` inside a quoted string as if it were a real shell
   write-ish character). Both were named out-of-scope by issue-88's
   survey with an explicit follow-up recommendation, which this issue is.

## Constraints

- Neither gate's protection purpose is weakened: board-gate's R1-R5, and
  approval-gate's phase-gate rule (execution-surface writes wait for a
  human Approve). This file's own "over-blocking is the safe direction"
  stance (`board-gate.sh:173`) holds for both.
- Every existing case in both `core/hooks/tests/run-board-gate-tests.sh`
  and `core/hooks/tests/run-approval-gate-tests.sh` keeps its current
  verdict.
- Allow/deny regression pairs are pinned into each gate's own existing
  test harness (the issue's explicit ask), including an
  escaped-quote-bypass case on `approval-gate.sh` equivalent to PR #89's
  `bash-escaped-quote-then-write`.
- Each gate keeps its own file, its own test harness, and its own rule
  shape — `approval-gate.sh` is not rewritten to import `board-gate.sh`'s
  segment model wholesale; the fix ports the verified *pattern*
  (quote-span-first, `(?<!\\)`-guarded recognition), adapted to this
  gate's simpler one-head-word structure, not the *code*.

## Rationale

**Defect 1 fix shape: scope candidate extraction to the segment(s) that
failed classification, not the whole command line.** Considered instead
reacting only to actual write syntax (redirect targets, or the write-arg
position of commands like `tee`/`cp`/`mv`/`sed -i`). Rejected: this would
need a per-command table of "which argument position is the write
target" (redirects put it after `>`, `tee`/`cp`/`mv` put it in different
positional slots, `sed -i` sometimes takes a suffix arg first) — a
materially larger, open-ended surface with a new failure mode every time
a write-capable command's argument shape isn't yet in the table.
Segment-scoping reuses the exact per-segment classification PR #89
already built and tested (`_split_segments`/`_head_of`/`READ_ONLY_HEADS`/
`GIT_READ_SUBCOMMANDS`): a segment is already either "proven read-only"
or "not" by that existing logic; the only change is *returning which
segments landed in "not"* instead of collapsing to one `bool`, then
scanning only those for docs-path tokens. No new write-detection
mechanism, no per-command argument table, no widened rule surface.

**Defect 2 fix shape: port the quote-guard mechanism, not
`board-gate.sh`'s segment splitter.** Considered giving `approval-gate.sh`
the same `_split_segments`-based pipeline `board-gate.sh` uses, so both
gates share one parsing core. Rejected for this issue: `approval-gate.sh`
today does not split on `;`/`|`/`&&` at all — it only ever inspects the
first word of the whole line as `head` and searches `WRITEISH` globally.
Building a full segment model here is a materially larger change than
this issue's two named defects (it would also touch how `head`/candidate
extraction work generally, well past "cd absent" and "quote-blind"), and
risks a different, un-warrant-hunted set of edge cases in a file that
guards phase-2 authorization, not just board layout. The two named
defects are fixed directly: `"cd"` added to `READ_ONLY_HEADS` (identical
tuple addition to board-gate's fix — `cd` has no write-capable form under
any invocation, board-gate's own reasoning for the same addition holds
verbatim), and `WRITEISH` gets the same quote-span-first,
`(?<!\\)`-guarded regex shape as `board-gate.sh`'s `SEGMENT`, walked by a
`finditer`-based helper that answers a boolean ("any unquoted write-ish
character?") instead of returning segments — matching what `WRITEISH` is
actually asked to answer today, not manufacturing segments nobody
downstream of it consumes.

## What will be done

- [ ] `core/hooks/board-gate.sh:208-227` (`_reads_only`): rename/reshape
  the internal loop into a new function
  `_write_candidate_segments(cmdline)` that returns the list of segments
  (from `_split_segments(probe)`) which could not be proven read-only —
  a segment lands in that list when it matches `SUBSHELL`/`FILE_REDIR`
  (checked per-segment now, not once over the whole `probe`), or when its
  head is an unresolved `git` write subcommand, or when its head is
  outside `READ_ONLY_HEADS`/`READ_UNLESS_INPLACE` (unchanged
  classification rules — only the granularity of what's returned
  changes). `_reads_only(cmdline)` becomes
  `return not _write_candidate_segments(cmdline)` — a one-line wrapper,
  so its existing call site (line 239) needs no change in meaning.
- [ ] `core/hooks/board-gate.sh:234-246` (`Bash` candidate builder):
  compute `failing_segments = _write_candidate_segments(cmdline)` once;
  `if not failing_segments: allow()`; otherwise run the existing
  `re.findall(r"[\w./~$-]*docs/[\w./-]*", ...)` scan over
  `"\n".join(failing_segments)` instead of the raw `cmdline`, so only
  docs-path tokens inside a segment that could not be proven read-only
  become candidates.
- [ ] `core/hooks/approval-gate.sh:84-86`: add `"cd"` to
  `READ_ONLY_HEADS`. Extend `WRITEISH` with quoted-span alternatives
  ordered before the write-ish-character alternatives, each guarded by
  `(?<!\\)`:
  `re.compile(r"(?<!\\)'[^']*'|(?<!\\)\"(?:[^\"\\]|\\.)*\"|[>|`]|\$\(")`.
  Add a `_writeish(cmdline)` helper that walks
  `WRITEISH.finditer(cmdline)`: a quote-shaped match (`group()[:1]` in
  `("'", '"')`) is skipped; any other match returns `True` immediately;
  no real match at all returns `False`.
- [ ] `core/hooks/approval-gate.sh:120`: replace
  `not WRITEISH.search(cmdline)` with `not _writeish(cmdline)`.
- [ ] `core/hooks/tests/run-board-gate-tests.sh`: add, after the issue-88
  section:
  - `run allow bash-unresolved-head-then-read Bash '{"command":"date; grep -n foo docs/issue-49/reports/x.md"}'`
    — a read-only segment (`grep` on a foreign issue path) must allow
    even though a different, unresolvable segment (`date`) is on the same
    line.
  - `run deny bash-unresolved-head-real-write Bash '{"command":"date > docs/issue-49/reports/x.md"}'`
    (negative-space sibling) — a real write INSIDE the failing segment
    itself must still deny; the scoping narrows *where* candidates are
    hunted for, not *whether*.
- [ ] `core/hooks/tests/run-approval-gate-tests.sh`: add, after the
  branch/role precondition block:
  - `run allow bash-cd-then-read-own-reports nopr x cmd='cd docs/issue-7/reports/coding && ls'`
  - `run deny bash-cd-then-write-src nopr x cmd='cd docs/issue-7 && echo x > src/app.py'`
    (negative-space sibling — a `cd`-headed line that really writes must
    still deny)
  - `run allow bash-quoted-redirect-in-grep nopr x cmd='grep -n "a > b" src/app.py'`
  - `run allow bash-single-quoted-pipe-grep nopr x cmd='grep -n '\''a > b'\'' src/app.py'`
  - `run deny bash-quoted-redirect-then-real-pipe nopr x cmd='grep -n "a > b" x | tee docs/issue-7/reports/coding.md'`
    (negative-space sibling — a real, unquoted `|` later in the same line
    must still deny)
  - `run deny bash-escaped-quote-then-write nopr x cmd='ls \" > docs/issue-7/x.md #"'`
    (warrant-hunt regression ported from PR #89's
    `bash-escaped-quote-then-write`, per the issue's explicit ask — a
    backslash-escaped quote CHARACTER outside any real shell quote must
    not open a fake quoted span that swallows the real `>` between two
    real tokens)
- [ ] `docs/handbooks/board-gate-tests.md`: one entry documenting the
  candidate-scoping fix and its negative-space sibling, issue-90.
- [ ] `docs/handbooks/approval-gate-tests.md`: one entry documenting both
  ported fixes (`cd`, quote-aware `WRITEISH`) and the ported
  escaped-quote regression, issue-90.
- [ ] Verify: `bash core/hooks/tests/run-board-gate-tests.sh` and
  `bash core/hooks/tests/run-approval-gate-tests.sh`, both `0 failed`.

## Out of scope

- Any other `board-gate.sh` rule (R1-R5) or `approval-gate.sh` rule
  beyond the two named defects.
- Giving `approval-gate.sh` a full segment/pipeline model matching
  `board-gate.sh`'s — deliberately not chosen (Rationale).
- `approval-gate.sh`'s lack of any semicolon/pipeline segmentation in
  general (e.g. whether `cat x; rm y` is correctly classified when `rm`
  never appears in a `src/`/`test/`/`docs/issue-<n>/` token) — not named
  by this issue's two defects; a materially different, wider defect class
  that would need its own survey.
- The `execution_surface()` asymmetry between `proposals` (has both a
  `startswith("proposals/")` and an `== "proposals"` branch) and
  `reports/<role>` (only `startswith("reports/%s/" % role)`, no bare-tail
  branch) noted in the survey — the `cd` fix masks its `cd`-triggered
  manifestation (matching how every other `READ_ONLY_HEADS` member
  already masks it), but the underlying asymmetry itself is untouched and
  out of this issue's two named defects.
- A backslash escaping a metacharacter *outside* any quotes, for either
  gate — not in this issue's reproduction set (same carve-out issue-88
  made for `board-gate.sh`).

## How you'll know it worked

`bash core/hooks/tests/run-board-gate-tests.sh` and
`bash core/hooks/tests/run-approval-gate-tests.sh` both report `0
failed`, including: the new board-gate scoped-candidate allow case and
its real-write negative-space sibling; the new approval-gate `cd`-read
allow case and its `cd`-write-still-denies sibling; the new
quoted-redirect (`"`- and `'`-quoted) allow cases and their
real-pipe-still-denies sibling; the ported escaped-quote-bypass deny
case; and every pre-existing case in both files unchanged.

## Alternatives considered

- **Defect 1: react only to actual write syntax (redirect targets /
  write-command argument positions) instead of segment-scoping.** Not
  chosen: needs an open-ended per-command table of write-argument
  positions with a new failure mode per untabulated command, versus
  reusing PR #89's already-verified per-segment classification
  (Rationale).
- **Defect 2: give `approval-gate.sh` `board-gate.sh`'s full
  `_split_segments` pipeline.** Not chosen: a materially larger,
  unrequested redesign of a file with its own separate rule surface and
  test harness, versus porting the quote-guard mechanism directly onto
  what `WRITEISH` already answers (a boolean) (Rationale).

## Failure signal

If a future edit collapses `_write_candidate_segments` back to scanning
the raw `cmdline`, or reverts `approval-gate.sh`'s `WRITEISH`/
`READ_ONLY_HEADS` changes, the new regression cases above flip from
`allow` back to `deny` (or, for the negative-space and escaped-quote
siblings, from `deny` back to a wrongly-permissive `allow`) — the
concrete, mechanical re-detection of this exact class of bug.
