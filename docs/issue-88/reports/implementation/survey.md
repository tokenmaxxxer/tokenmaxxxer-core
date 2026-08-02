---
kind: coding-record
subject: issue-88
produced_by: implementation
loop_state: proposed
upstream: []
---

# Current-state survey — issue-88

## 1. Issue trace, re-derived against the live code

Both line numbers the issue cites match the live file exactly — no drift
since the issue was filed:

- `READ_ONLY_HEADS` (issue: line 96) — confirmed at
  `core/hooks/board-gate.sh:96-99`.
- `SEGMENT` (issue: line 121) — confirmed at `core/hooks/board-gate.sh:121`.
- `SEGMENT.split(probe)` consumer — `core/hooks/board-gate.sh:170`, inside
  `_reads_only()`.

### False positive 1 — quoted `\|` split into a fake segment boundary

Traced `_reads_only()` by hand against
`grep -n "A\|B" docs/issue-14/x.md`:

- `DEVNULL_REDIR`/`SUBSHELL`/`FILE_REDIR` — no `/dev/null`, no backtick/`$(`,
  no bare `>` — all clear, so the segment loop runs.
- `SEGMENT.split(probe)` — the regex `\|\||&&|[|;\n]` matches the single
  `|` inside the quoted string with no quote-awareness at all, splitting
  the line into `grep -n "A\` and `B" docs/issue-14/x.md`.
- `_head_of()` on segment 1 → `"grep"` → in `READ_ONLY_HEADS` → `continue`.
- `_head_of()` on segment 2 → first word is `B"` (no `/`, so `rsplit`
  returns it unchanged) → not in `TRANSPARENT`, not `"git"`, not in
  `READ_ONLY_HEADS`/`READ_UNLESS_INPLACE` → `return False`.
- `_reads_only()` returns `False` for a command that never touches a
  file. Back in the `Bash` branch (line ~200), execution falls through to
  candidate extraction: `docs/issue-14/x.md` becomes a candidate, R1
  bucketing runs on it (`bucketed()`, line ~253) and denies it — `x.md` is
  a bare file directly under `docs/issue-14/`, not one of the six buckets
  — exactly the refusal class the issue reports.

Same trace shape reproduces the two `on-the-record` incidents the issue
cites: `grep -rn "...\|..." ` (issue-189, ghost-file investigation) and
`grep -n "^class \|^    def test_"` (issue-216) both carry a quoted `|`
that the naive character-class split does not distinguish from a real
pipe.

### False positive 2 — `cd` absent from `READ_ONLY_HEADS`

Traced `_reads_only()` against `cd docs/issue-14 && cat x.md`:

- `SEGMENT.split(probe)` splits on `&&` into `cd docs/issue-14 ` and
  ` cat x.md` — two segments, correctly separated this time.
- `_head_of()` on segment 1 → `"cd"` → not in `TRANSPARENT`, not
  `"git"`, not in `READ_ONLY_HEADS` (absent) or `READ_UNLESS_INPLACE` →
  `return False` immediately. The loop never reaches segment 2 (the
  actual `cat`), so the read-only short-circuit is lost for the whole
  command regardless of what follows `&&`.
- Same fallthrough into the R1-R5 write scan as false positive 1, and the
  same class of spurious denial on a command that writes nothing.

`cd` cannot write a file under any invocation (`cd [-L|-P] [dir]`), so it
belongs in `READ_ONLY_HEADS` on the same footing as `ls`/`true`/`test`.
Unlike `git` (issue-60, split off because subcommand — not command name —
decides read vs. write), `cd` has no write-capable form at all: a plain
tuple addition is correct and sufficient, no subcommand table needed.

## 2. Does `approval-gate.sh` independently share or block this? Shares the same defect, out of scope

`core/hooks/approval-gate.sh:84-86` carries both root causes verbatim:

- `READ_ONLY_HEADS = ("ls", "cat", "head", "tail", "grep", "rg", "find",
  "wc", "diff", "stat", "file", "git")` — no `cd`.
- `WRITEISH = re.compile(r"[>|`]|\$\(")` — flags any `|` character with no
  quote-awareness, the same class of bug as `board-gate.sh`'s pre-fix
  `SEGMENT`.

This is a parallel defect in a different gate (the phase-2 execution-
surface check, not board layout/ownership) with its own test harness. The
issue's scope (title, background, and the R1-R5 protection this survey
must not weaken) names only `board-gate.sh`. Recommend a follow-up issue
for `approval-gate.sh` once this one lands — same reasoning `docs/issue-60/
reports/implementation/survey.md` section 3 used for the identical
git-subcommand defect.

## 3. Write-set projection

- `core/hooks/board-gate.sh` — the two fixes (quote-aware segment split,
  `cd` added to `READ_ONLY_HEADS`).
- `core/hooks/tests/run-board-gate-tests.sh` — regression cases for both
  false positives, plus a same-shape negative case per fix (a quoted-pipe
  read on a foreign issue tree must still allow; a `cd`-prefixed *write*
  to a foreign tree must still deny) so neither fix loosens R1-R5.
- `docs/handbooks/board-gate-tests.md` — one line each documenting the two
  new regression classes, per the issue's explicit constraint to pin
  reproduction cases into this file's test inventory.

## 4. Fix shape (detail for the proposal's Rationale)

`SEGMENT.split(probe)` is a bare `re.split` with no way to know it is
inside a quoted string. The minimal quote-aware fix extends the same
regex object with quoted-span alternatives ordered *before* the separator
alternatives, then walks matches with `finditer` instead of `split`:
`quote-match → skip (keep in the current segment)`, `separator-match →
cut here`. This keeps the change to one regex literal and one small
walker function, not a shell-grammar parser — matching this file's
existing "over-blocking is the safe direction" stance (comment at
`board-gate.sh:173`) and issue-60's precedent for a narrowly-scoped,
verifiable fix.

An unterminated/unbalanced quote cannot be exploited to swallow a real
separator: the quoted-span alternative simply fails to match at that
position (no closing quote found), so `finditer` produces no match there
and scanning continues normally — any real, later separator is still
found. Single quotes (`'...'`, no escapes) and double quotes (`"..."`,
backslash-escapes the next character) are both covered; a backslash
escaping a metacharacter *outside* any quotes (e.g. unquoted `A\|B`) is
not in the issue's reproduction set and is noted as a follow-on gap in
the proposal's Out of scope, not folded into this diff.

## Skip record (scout-directive)

Scouting skipped — bugfix-shaped: the issue names the exact two defects,
the exact lines, and the exact constraint (don't weaken R1-R5, pin
regression cases). No product-facing or external-field design question is
open; the only decision is an internal parsing-fix shape, covered above.
