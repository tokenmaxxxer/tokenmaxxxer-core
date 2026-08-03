---
kind: build-proposal
subject: issue-88
produced_by: implementation
loop_state: proposed
upstream:
  - path: docs/issue-88/reports/implementation/survey.md
    sha: <set at commit>
---

files: `core/hooks/board-gate.sh`, `core/hooks/tests/run-board-gate-tests.sh`, `docs/handbooks/board-gate-tests.md`

## Request

`core/hooks/board-gate.sh`'s `_reads_only()` misclassifies two read-only
Bash command shapes as writes, each on its own line the issue names
exactly (survey confirmed both against the live file, no drift):

- `SEGMENT = re.compile(r"\|\||&&|[|;\n]")` (line 121) splits on any bare
  `|` character with no quote-awareness, so a quoted BRE `OR` pattern like
  `grep -n "A\|B" docs/issue-14/x.md` gets cut at the quoted `\|`, and the
  second fragment's head becomes an arbitrary word — denied.
- `READ_ONLY_HEADS` (line 96) has no `cd` entry, so `cd <dir> && cat
  docs/...` is denied outright even though the identical read without the
  `cd` prefix is allowed.

Both have reproduced repeatedly outside this repo (core #56 three times,
on-the-record issue-189 and issue-216) — see the survey's traces.

## Constraints

- The gate's protection purpose (R1-R5, blocking foreign/unauthorized
  board writes) is not weakened by either fix — this file's own
  "over-blocking is the safe direction" stance (comment at
  `board-gate.sh:173`) holds.
- Every existing case in `core/hooks/tests/run-board-gate-tests.sh` keeps
  its current verdict (R1-R5, s4 READ-broad, git subcommand awareness,
  fast path, kill switch, fail-closed garbage payload).
- Regression cases for both false positives are pinned into
  `docs/handbooks/board-gate-tests.md`'s test inventory, per the issue's
  explicit ask.
- Minimal diff: both fixes stay inside `core/hooks/board-gate.sh` (no
  shell-grammar dependency, no change to `approval-gate.sh`, which shares
  the same two root causes but is a separate gate with its own test
  harness — survey section 2).

## Rationale

Considered tokenizing the whole command line with the stdlib `shlex`
module (POSIX mode) and rebuilding segments from its token stream instead
of extending the regex. Rejected: `shlex` discards the quote characters
and normalizes escapes as it tokenizes, so the reconstructed text would
no longer match byte-for-byte against what `_head_of()` and the
`docs/`-path token extraction (`re.findall` over the raw `cmdline`,
line ~200) expect to see — every downstream consumer of a segment would
need its own re-normalization pass, trading one regex for two parsing
layers over the same string. Extending `SEGMENT` to also match quoted
spans (as a "skip, don't split" alternative) keeps exactly one mechanism:
the same object still finds every separator; it now also recognizes the
spans that must not count as one.

Also considered a full shell-grammar parser (e.g. a `bashlex`-style
dependency). Rejected: `core/hooks/board-gate.sh` has zero dependencies
today (stdlib `json`/`os`/`posixpath`/`re`/`subprocess`/`sys` only), and
pulling in a shell parser to fix two narrowly-scoped, precisely-repro'd
false positives is disproportionate — matching issue-60's precedent of a
targeted, verifiable fix over a heavier general one.

## What will be done

- [ ] `core/hooks/board-gate.sh:96-99` (`READ_ONLY_HEADS`): add `"cd"` to
  the tuple. `cd` has no write-capable invocation at all (unlike `git`,
  issue-60, where subcommand — not command name — decides read vs.
  write), so a plain addition is correct and sufficient.
- [ ] `core/hooks/board-gate.sh:121` (`SEGMENT`): extend the regex with
  quoted-span alternatives ordered *before* the separator alternatives:
  `re.compile(r"'[^']*'|\"(?:[^\"\\]|\\.)*\"|\|\||&&|[|;\n]")` — single
  quotes (no escapes, POSIX) and double quotes (backslash escapes the
  next character) both covered.
- [ ] Same location: add a `_split_segments(cmdline)` helper that walks
  `SEGMENT.finditer(cmdline)` — a match starting with `'` or `"` is a
  quoted span and is kept inside the running segment (not a cut point);
  a `||`/`&&`/`[|;\n]` match cuts a new segment there. Returns the same
  list shape `SEGMENT.split(probe)` produced before, so every downstream
  consumer (`_head_of`, the `git`/`READ_ONLY_HEADS`/`READ_UNLESS_INPLACE`
  checks) is unchanged.
- [ ] `core/hooks/board-gate.sh:170`: replace
  `for seg in SEGMENT.split(probe):` with
  `for seg in _split_segments(probe):`.
- [ ] `core/hooks/tests/run-board-gate-tests.sh`: add a block after the
  git-subcommand-awareness section (after `bash-git-show-foreign-issue`)
  covering both fixes and their negative-space siblings, so neither
  loosens R1-R5:
  - `run allow bash-quoted-pipe-grep      Bash '{"command":"grep -n \"A\\|B\" '$BOARD'/x.md"}'`
  - `run allow bash-quoted-pipe-classtest Bash '{"command":"grep -n \"^class \\|^    def test_\" '$BOARD'/x.md"}'`
    (the on-the-record issue-216 repro shape)
  - `run allow bash-single-quoted-pipe    Bash '{"command":"grep -n '\''A|B'\'' '$BOARD'/x.md"}'`
    (the other quote style — an actual unescaped `|` inside single quotes)
  - `run allow bash-cd-then-cat           Bash '{"command":"cd '$BOARD' && cat x.md"}'`
  - `run deny  bash-cd-then-write-foreign Bash '{"command":"cd '$BOARD' && echo x > review.md"}'`
    (a `cd`-prefixed *write* into a foreign tree must still deny — proves
    the `cd` addition doesn't open a hole)
  - `run deny  bash-quoted-pipe-then-redirect Bash '{"command":"grep -n \"A\\|B\" x | tee '$BOARD'/review.md"}'`
    (a quoted-pipe read whose pipeline ends in a real write to a foreign
    tree must still deny — proves the quote-aware split doesn't swallow
    the real, unquoted `|` later in the same line)
- [ ] `docs/handbooks/board-gate-tests.md`: add one line each documenting
  the two new regression classes (quoted-`|` segment-split blindness,
  `cd` absent from `READ_ONLY_HEADS`), issue-88.
- [ ] Verify: `bash core/hooks/tests/run-board-gate-tests.sh` — all cases
  pass, `0 failed`.

## Out of scope

- `approval-gate.sh`'s identical `READ_ONLY_HEADS`-missing-`cd` and
  quote-blind `WRITEISH` (survey section 2) — a different gate (phase-2
  execution-surface check) with its own test harness; recommend a
  follow-up issue, mirroring how issue-60 scoped out the same gate's
  parallel git-subcommand defect.
- A backslash escaping a metacharacter *outside* any quotes (e.g. unquoted
  `A\|B`) — not in this issue's reproduction set; the quote-tracking fix
  here only recognizes quoted spans, not bare backslash-escapes. Noted as
  a residual gap for a future proposal if it starts mattering in
  practice.
- The pre-existing `--output=<file>` residual risk on `git log`/`show`/
  `diff` (already flagged, out of scope, in issue-60's survey section 4)
  — unrelated to this issue's two named defects.
- Any other `board-gate.sh` rule (R1-R5) or read-only head not named
  above.

## How you'll know it worked

`bash core/hooks/tests/run-board-gate-tests.sh` reports `0 failed`,
including: the new quoted-pipe allow cases (double- and single-quote
variants, plus the issue-216-shaped repro), the new `cd`-prefixed allow
case, both new deny-shaped negative-space siblings (`cd`-prefixed write,
quoted-pipe-then-redirect), and every pre-existing case (R1-R5, s4
READ-broad, git subcommand awareness, fast path, kill switch,
fail-closed) unchanged.

## Alternatives considered

- **`shlex`-based tokenize-and-rebuild.** Not chosen: normalizes/loses
  quote and escape characters during tokenization, forcing every
  downstream string consumer to re-normalize against a different
  representation than the raw `cmdline` — trading one regex for two
  parsing layers over the same data (detailed in Rationale).
- **A full shell-grammar parser dependency.** Not chosen: no new
  dependency is needed for two narrowly-scoped, precisely-repro'd false
  positives; the file is pure stdlib today and issue-60 set the precedent
  of a targeted fix over a heavier general one.
- **Blanket regex substitution stripping backslash-escaped
  metacharacters before splitting, instead of quote-tracking.** Not
  chosen: does not cover the single-quoted variant (`'A|B'`, an actual
  unescaped `|` with no backslash at all) that sits directly beside the
  issue's own double-quoted repro; quote-tracking handles both quote
  styles with one mechanism, a backslash-strip would not.

## Failure signal

If a future edit reverts `_split_segments` back to a bare
`SEGMENT.split(probe)`, or drops `"cd"` from `READ_ONLY_HEADS` again,
`bash core/hooks/tests/run-board-gate-tests.sh` regresses
`bash-quoted-pipe-grep`/`bash-single-quoted-pipe` and `bash-cd-then-cat`
from `allow` back to `deny` — the concrete, mechanical re-detection of
this exact class of bug.
