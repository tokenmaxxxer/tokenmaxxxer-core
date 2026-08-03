---
kind: coding-record
subject: issue-90
produced_by: implementation
loop_state: proposed
upstream: []
---

# Current-state survey — issue-90

## 1. Defect 1 — board-gate.sh: read-classification failure sweeps the
   whole command line into write candidates

Issue-cited line 198-203 (audit-time) has drifted to the current file
after PR #89 (issue-88) merged; re-derived against the live file:

- `core/hooks/board-gate.sh:234-246` — the `Bash` branch of the candidate
  builder.

```python
elif tool == "Bash":
    cmdline = ti.get("command")
    if not isinstance(cmdline, str):
        deny("Bash payload carries no command string")
    if DOCS in cmdline:
        if _reads_only(cmdline):
            allow()          # a plain read of the board is not a write (s4)
        # every docs-path-shaped token becomes a candidate target; this is
        # a superset scan, and over-blocking is the safe direction here
        for tok in re.findall(r"[\w./~$-]*%s[\w./-]*" % re.escape(DOCS), cmdline):
            candidates.append(tok)
        if not candidates:
            candidates.append(DOCS)   # mentioned but unextractable: adjudicate
```

`_reads_only(cmdline)` (`board-gate.sh:208-227`, PR #89 shape) walks
`_split_segments(probe)` and returns `False` the moment ANY segment's
head cannot be proven read-only — but it returns a plain `bool`, not
*which* segment failed. When it returns `False`, the code above does not
re-derive the failing segment either: it runs `re.findall(...)` over the
**entire raw `cmdline`**, so every `docs/`-shaped token anywhere on the
line — including ones that sit inside a DIFFERENT, already-provably-
read-only segment — becomes an R4 write candidate.

### Traced repro

`date; grep -n foo docs/issue-49/reports/x.md` (role `qa`, branch
`issue-3/qa`):

- `_split_segments` splits on the real `;` into `"date"` and
  `" grep -n foo docs/issue-49/reports/x.md"`.
- Segment 1: `_head_of("date")` → `"date"` — not in `READ_ONLY_HEADS`, not
  `git`, not in `READ_UNLESS_INPLACE` → classifies as "cannot prove
  read-only" (correct and conservative: `date` truly isn't whitelisted).
- Segment 2: `_head_of(...)` → `"grep"` → in `READ_ONLY_HEADS` →
  correctly read-only.
- `_reads_only()` returns `False` for the whole line (because of segment
  1) — correct so far.
- But candidate extraction then runs `re.findall(...)` over the **whole
  `cmdline`**, not just segment 1, and picks up
  `docs/issue-49/reports/x.md` from segment 2 — a path that a
  provably-read-only `grep` merely searched.
- `docs/issue-49/reports/x.md` bucket-checks fine (R1), and role `qa` on
  branch `issue-3/qa` fails R4 against `issue-49` → **denied** — a
  read-only command refused solely because an unrelated, non-docs
  segment on the same line (`date`) could not be classified.

This matches the issue's own description exactly: "읽기로 판정 못 하면 …
명령줄 텍스트에 등장한 모든 docs 경로를 … 쓰기 후보로 삼고 R4로 거부" —
confirmed against the live file, not just the issue's prose.

### Fix shape available in the existing architecture

`_split_segments`/`SEGMENT` (PR #89) already gives per-segment
boundaries and a working per-segment read classification (the loop body
inside `_reads_only`). The minimal fix reshapes that loop to *return the
list of segments it could not clear* instead of collapsing to a `bool`
immediately; `_reads_only` becomes a one-line wrapper
(`not <that list>`) so its one existing call site (line 239) is
unaffected in meaning. Candidate-token extraction then runs `re.findall`
over the joined text of only the failing segments, not the raw
`cmdline`. No new dependency, no new regex construct — reuses the
segment model PR #89 already introduced and verified.

## 2. Defect 2 — approval-gate.sh: the twin defects named by the issue,
   confirmed live

`core/hooks/approval-gate.sh:84-86` (issue cites the same two lines the
issue-88 survey found; unchanged since, confirmed against the live
file):

```python
READ_ONLY_HEADS = ("ls", "cat", "head", "tail", "grep", "rg", "find", "wc",
                   "diff", "stat", "file", "git")
WRITEISH = re.compile(r"[>|`]|\$\(")
```

Used at `approval-gate.sh:119-121`:

```python
head = cmdline.strip().split()[0].rsplit("/", 1)[-1] if cmdline.strip() else ""
if head in READ_ONLY_HEADS and not WRITEISH.search(cmdline):
    allow()              # reading the tree is phase-agnostic
```

Two confirmed defects, both present verbatim:

- **`cd` absent from `READ_ONLY_HEADS`.** A `cd`-prefixed read (e.g. `cd
  docs/issue-7/reports/coding && ls`) has head `"cd"`, which is not in
  the tuple, so the fast-path shortcut above never fires. The command
  falls through to the raw `re.findall(r"[\w./~$-]+", cmdline)` token
  scan and `execution_surface()` classification regardless of whether
  anything is actually written. Traced: `execution_surface()`
  (`approval-gate.sh:95-108`) exempts a role's own `reports/<role>/`
  subtree only via `tail.startswith("reports/%s/" % role)` — a bare `cd`
  target with no trailing slash (`"reports/coding"`, not
  `"reports/coding/"`) does not satisfy that prefix check (unlike the
  `proposals` exemption, which has both a `startswith("proposals/")` *and*
  an `== "proposals"` branch — an asymmetry this defect exposes). Every
  OTHER read-only head (`cat`, `grep`, …) already short-circuits past this
  quirk via the `READ_ONLY_HEADS` fast path; `cd` alone falls through and
  hits it, producing a spurious pre-approval deny on a command that never
  writes anything — the identical failure shape issue-88 found in
  `board-gate.sh` (a `cd`-prefixed read denied while the identical read
  without the `cd` prefix is allowed).
- **`WRITEISH` is quote-blind.** `re.compile(r"[>|`]|\$\(")` flags a `>`
  or `|` character anywhere in the raw command line, including inside a
  quoted string. `grep -n "a > b" src/app.py` — a read-only `grep` whose
  pattern merely contains the literal text `"a > b"` — trips
  `WRITEISH.search()`, so the `READ_ONLY_HEADS` shortcut is skipped even
  though `head` (`grep`) qualifies; the command falls through to the
  execution-surface candidate scan and gets denied pre-approval solely
  because of a quoted `>` that was never a real shell redirect. Same root
  cause `board-gate.sh`'s pre-PR#89 `SEGMENT` had.

## 3. The verified fix pattern (PR #89 / issue-88) and how it maps here

`board-gate.sh`'s fix (commit 881f6e3):

1. Added `"cd"` to `READ_ONLY_HEADS` — a plain tuple addition, `cd` has no
   write-capable invocation.
2. Extended `SEGMENT` with quoted-span alternatives ordered *before* the
   separator alternatives, each guarded by a `(?<!\\)` negative
   lookbehind so a backslash-escaped quote CHARACTER outside any real
   shell quote cannot open a fake quoted span (closed after a
   warrant-hunt found exactly that bypass:
   `ls \" ; rm -rf docs/issue-1/x #"` swallowing the real `;` and hiding
   a write).
3. Added `_split_segments()`, a `finditer`-based walker: a quote-shaped
   match extends the current segment (does not cut); a separator-shaped
   match cuts a new one.

`approval-gate.sh` does not build segments at all today — it only
inspects the first word of the raw command line as `head`, and searches
`WRITEISH` over the whole line. Porting "cd registered" is a direct,
identical tuple addition. Porting "quote-aware" cannot reuse
`_split_segments` verbatim (there is no segmenting here to reuse); the
adapted shape is a `finditer`-based walker over the same
quote-span-first, `(?<!\\)`-guarded regex, but answering a boolean
("does an unquoted write-ish character exist?") instead of returning
segments — the same mechanism (recognize-and-skip quoted spans, guard
against the escaped-quote bypass), restructured to fit this gate's
simpler "one head word, one boolean" architecture instead of importing
board-gate's full segment model wholesale (which would be a materially
larger, unrequested redesign of a file with its own separate test
harness and a different rule surface, R1-R5 vs. the phase gate).

## 4. Write-set projection

- `core/hooks/board-gate.sh` — reshape `_reads_only`'s internals to
  expose the failing segment list; scope candidate-token extraction to
  it.
- `core/hooks/approval-gate.sh` — add `"cd"` to `READ_ONLY_HEADS`; make
  `WRITEISH` quote-aware via a guarded quoted-span-first regex plus a
  boolean walker.
- `core/hooks/tests/run-board-gate-tests.sh` — allow/deny regression pair
  for the scoping fix (a foreign-issue read-only segment must allow when
  a DIFFERENT, unrelated segment cannot be classified; a real write
  INSIDE the failing segment must still deny).
- `core/hooks/tests/run-approval-gate-tests.sh` — allow/deny regression
  pairs for both approval-gate fixes, plus the escaped-quote warrant-hunt
  case the issue explicitly asks be pinned equivalently
  (`bash-escaped-quote-then-write`-shaped).
- `docs/handbooks/board-gate-tests.md`,
  `docs/handbooks/approval-gate-tests.md` — one entry each documenting
  the new regression classes, matching issue-88's precedent of pinning
  reproduction cases into the test inventory doc, not just the test file.

## Skip record (scout-directive)

Scouting skipped — bugfix-shaped: the issue names the exact two defects
(board-gate's candidate-collection scope, approval-gate's twin defects),
points at the exact verified fix pattern already merged in PR #89, and
states the exact constraint (don't weaken R1-R5 / the phase gate, pin
regression cases including the escaped-quote case). No product-facing or
external-field design question is open; the only decisions are internal
parsing-fix shape (segment-scoped extraction vs. redirect-target-only
extraction for defect 1; how to adapt the quote-guard mechanism to a
gate with no segment model for defect 2), both covered above and in the
proposal's Rationale.
