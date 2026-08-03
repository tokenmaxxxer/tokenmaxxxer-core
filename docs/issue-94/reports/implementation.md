---
kind: coding-record
subject: issue-94
produced_by: implementation
code_under_review: 74c790d00d6ee802af92671f3240216b4be4da41
loop_state: landed
upstream:
  - path: docs/issue-94/proposals/2026-08-03-quote-aware-board-gate-writeish-and-segment-gh-guard.md
    sha: 74c790d00d6ee802af92671f3240216b4be4da41
---

# Implementation record — issue-94

## Why

Phase 2, approved via issue-level comment `APPROVE issue-94/implementation`
(exact string, posted by an approvers.md account, jjongkwann:
https://github.com/tokenmaxxxer/tokenmaxxxer-core/issues/94#issuecomment-5162414768).
Delivering exactly the approved proposal's `## What will be done`: a
shared quote-aware match primitive centralized in `gate-lib.py`, used to
fix `board-gate.sh`'s `FILE_REDIR` half of its write-candidate check and
three of `gh-guard.sh`'s eleven two-account `RULES`, plus a mechanical
reuse of the same primitive to replace `approval-gate.sh`'s existing
`WRITEISH`/`_writeish` (same observable behavior, one shared mechanism).

## What was done

1. `core/hooks/lib/gate-lib.py:174-191` — added `GATE_QUOTE_SPAN`
   (`re.compile(r"(?<!\\)'[^']*'|(?<!\\)\"(?:[^\"\\]|\\.)*\"")`, line
   174), `gate_dequote(text)` (line 177, blanks every quoted span to a
   single space via `GATE_QUOTE_SPAN.sub(" ", text)` at line 186), and
   `gate_outside_quotes(text, pattern)` (line 189,
   `re.search(pattern, gate_dequote(text)) is not None`). `run-gate-lib-tests.sh`
   gained a new `gate_dequote / gate_outside_quotes` group (+40 lines):
   a quoted `>`/`gh pr merge`-shaped phrase is absent from
   `gate_dequote`'s output, the same text outside any quote survives,
   and `gate_outside_quotes` is `True` for a real unquoted occurrence,
   `False` for a quotes-only one.
2. `core/hooks/board-gate.sh` — imports `gate_lib` via
   `importlib.util.spec_from_file_location` (lines 69-70, the same
   pattern `record-fields-gate.sh` already uses in production). At line
   230, `_write_candidate_segments`'s check is now
   `SUBSHELL.search(seg) or gate_lib.gate_outside_quotes(seg, FILE_REDIR.pattern)`
   — only the `FILE_REDIR` half moved to the shared primitive (using
   `FILE_REDIR.pattern`, i.e. the compiled regex's own pattern text
   rather than a duplicated literal, so the two can never drift). `SUBSHELL`
   (line 122, `re.compile(r"[\`]|\$\(")`) is untouched, confirmed
   byte-for-byte identical against `main` (Hunt, below) — it stays
   quote-blind on purpose per the proposal's Rationale. 4 new cases added
   to `run-board-gate-tests.sh` (+17 lines):
   `bash-quoted-redirect-in-grep` (allow, issue's defect-1 repro),
   `bash-real-redirect-then-quote` (deny, negative-space sibling),
   `bash-escaped-quote-then-redirect` (deny, escaped-quote warrant-hunt
   sibling), and `bash-quoted-subshell-write` (deny, proving `SUBSHELL`
   stays quote-blind). Suite: `71 passed, 0 failed`.
3. `core/hooks/approval-gate.sh` — imports `gate_lib` the same way
   (lines 63-64). `WRITEISH`/`_writeish` (formerly lines 86-107) are
   fully removed; the one call site (line 123) now reads
   `gate_lib.gate_outside_quotes(cmdline, r"[>|\`]|\$\(")` — the exact
   same non-quote-alternative pattern text `WRITEISH` used, confirmed
   against the pre-image (Hunt, below). No new test cases (existing
   cases already pin the observable behavior, which does not change;
   confirmed by re-running the suite, not assumed). Suite:
   `42 passed, 0 failed`, all pre-existing verdicts unchanged.
4. `core/hooks/gh-guard.sh` — imports `gate_lib` (lines 51-52). Each of
   the 11 `RULES` tuples (lines 74-126) gained a trailing bool: `True`
   for the first 3 (review-verdict `:75-78`, merge/close/reopen
   `:79-82`, issue create/close/reopen/edit/transfer/delete `:83-86`),
   `False` for the other 8 (`:87-125`), with every pattern string and
   `why` message left byte-for-byte unchanged (confirmed, Hunt below).
   The loop (lines 128-132) now computes `dq = gate_lib.gate_dequote(cmd)`
   once and checks `re.search(pat, dq if dequote else cmd)`, same order,
   same deny-message shape. `_split_segments`/`SEGMENT` are not imported
   or referenced anywhere in the file (confirmed, Hunt below) — no
   segmentation added, per the proposal's Rationale. 5 new cases added
   to `run-gh-guard-tests.sh` (+14 lines): `quote-gh-pr-merge-in-grep`,
   `quote-review-approve-in-grep`, `quote-issue-create-in-grep` (allow,
   one per in-scope rule, issue's defect-2 repro shape),
   `quote-real-merge-after-quote` (deny, a real unquoted violation later
   on the same line still fires), and `gap-f-api-merge-in-quote-still-fires`
   (deny, the named residual false-positive on an out-of-scope rule,
   kept visible rather than silently dropped). Suite: `37 passed, 0 failed`.
5. `docs/handbooks/gate-house-standard.md`, `docs/handbooks/board-gate-tests.md`,
   `docs/handbooks/approval-gate-tests.md`, `docs/handbooks/gh-guard-tests.md`:
   one entry each (66 lines total across the 4 files), documenting the
   new primitive and each gate's fix, per the proposal's `## What will
   be done`.

## What did not work

None beyond the sandbox hazard already on record from the prior three
units: this session's shell carries an ambient `CLAUDE_PLUGIN_ROOT_CORE`
env var pointing at a separately-installed, stale plugin copy predating
this issue's `gate-lib.py` changes. Expected the suites to run clean
against the repo's own `gate-lib.py`; actual, running any of the four
suites without unsetting it sources the stale copy (missing
`gate_dequote`/`gate_outside_quotes`) and produces spurious
`AttributeError`s with nothing to do with the real code. Fixed by
running every suite with `env -u CLAUDE_PLUGIN_ROOT_CORE` prefixed, as
this record's own combined verification run (below) did throughout.

## Doc-placement ladder

- No new env var, config key, dependency, or migration.
- The one real design choice this delivery makes — centralizing the
  dequote-and-match primitive in `gate-lib.py`, and leaving `SUBSHELL`
  and 8-of-11 `gh-guard.sh` rules unchanged on purpose — is already
  fully recorded in the phase-1 proposal's `## Rationale`
  (`docs/issue-94/proposals/2026-08-03-quote-aware-board-gate-writeish-and-segment-gh-guard.md`),
  same posture as issue-93's record. No separate `docs/issue-94/decisions/`
  entry needed.
- Confirmed all 4 handbook files were actually touched (`git diff --stat`):
  `docs/handbooks/gate-house-standard.md` (+7), `docs/handbooks/board-gate-tests.md`
  (+21), `docs/handbooks/approval-gate-tests.md` (+16),
  `docs/handbooks/gh-guard-tests.md` (+22).

## Hunt

`warrant-hunter` is not among this session's available `Agent`-tool
subagent types (same absence noted in issue-88/90/93's records). In its
place, adopted the stance directly: **contract-literalist — assume the
shipped code silently drifted from the frozen contract or the
proposal's own Rationale during independent parallel implementation,
until proven otherwise by reading the actual diff.** Read `git diff` for
all four changed source files (not tests/handbooks) against this
stance.

closed_checks:
- name: board-gate.sh SUBSHELL byte-for-byte unchanged; gate_outside_quotes applies only to FILE_REDIR
  code_sha: 74c790d00d6ee802af92671f3240216b4be4da41
  result: `git diff` for `core/hooks/board-gate.sh` shows no hunk
    touching line 122's `SUBSHELL = re.compile(r"[\`]|\$\(")` definition
    — only the import block (lines 69-70) and the one check line (230)
    changed. Line 230 reads `SUBSHELL.search(seg) or
    gate_lib.gate_outside_quotes(seg, FILE_REDIR.pattern)` — the `or`'s
    left operand (`SUBSHELL`) is still a raw `.search`, only the right
    operand (`FILE_REDIR`) is wrapped in the new primitive. Confirmed.
- name: gh-guard.sh's 8 unchanged rules identical text, order preserved, no _split_segments reuse
  code_sha: 74c790d00d6ee802af92671f3240216b4be4da41
  result: `git diff` shows, for every one of the 8 `False`-tagged rules,
    the only changed characters are the tuple's closing punctuation
    (trailing `)` → `,` plus a new `False)` line) — every pattern string
    and every `why` message line is unchanged text. `RULES`'s list order
    is unchanged (only a third tuple element appended per entry, no
    reordering); the loop still iterates it top-to-bottom in the same
    order via `for pat, why, dequote in RULES`. `grep -n
    "_split_segments\|SEGMENT" core/hooks/gh-guard.sh` returns no match
    — not imported or referenced anywhere in the file. Confirmed.
- name: approval-gate.sh WRITEISH/_writeish fully removed, pattern text preserved
  code_sha: 74c790d00d6ee802af92671f3240216b4be4da41
  result: `grep -n "WRITEISH\|_writeish" core/hooks/approval-gate.sh`
    returns no match — no dead reference anywhere in the file. The
    replacement call site (line 123) uses
    `r"[>|\`]|\$\("` — byte-for-byte the same non-quote-alternative
    pattern text the removed `WRITEISH`'s compiled pattern held
    (`(?<!\\)'[^']*'|(?<!\\)"(?:[^"\\]|\\.)*"|[>|\`]|\$\(`, per the
    pre-image in the diff) — only the quote-span alternatives moved into
    `gate_lib.gate_dequote`, called by `gate_outside_quotes` before the
    same pattern is matched. Confirmed.
- name: gate-lib.py GATE_QUOTE_SPAN text matches board-gate.sh SEGMENT / approval-gate.sh's former WRITEISH exactly
  code_sha: 74c790d00d6ee802af92671f3240216b4be4da41
  result: `GATE_QUOTE_SPAN = re.compile(r"(?<!\\)'[^']*'|(?<!\\)\"(?:[^\"\\]|\\.)*\"")`
    (gate-lib.py:174) compared character-for-character against
    `board-gate.sh`'s `SEGMENT` (line 140:
    `re.compile(r"(?<!\\)'[^']*'|(?<!\\)\"(?:[^\"\\]|\\.)*\"|\|\||&&|[|;\n]")`)
    — the quote-span prefix before `|\|\||&&|[|;\n]` is identical — and
    against the pre-image `WRITEISH` fragment shown in the
    `approval-gate.sh` diff, also identical. No accidental typo
    introduced when centralizing. Confirmed.

## Open findings

None raised against this record.

## Next steps

None — delivery complete, all four harnesses green except the one
confirmed-pre-existing/unrelated gate-lib failure, PR ready for merge.

## Resolution path

Any open finding against this record is resolved by amending this file
with a `resolved_findings:` entry referencing the finder's record, per
contract v3 s16, before further build commits proceed.

## Verify

`bash core/hooks/tests/run-gate-lib-tests.sh` → `gate-lib: 36 passed, 1
failed` (the 1 failure is `compliance-check.sh: flags a hand-rolled
kill-switch + replace shape`, a pre-existing, unrelated macOS sandbox
artifact where `mktemp -d` ignores `$TMPDIR`; reconfirmed by `git
stash`-ing this delivery's 11 changed files and re-running — the same
single failure persists identically against the unmodified branch, then
`git stash pop` restored all four units' work).
`bash core/hooks/tests/run-board-gate-tests.sh` → `71 passed, 0 failed`.
`bash core/hooks/tests/run-approval-gate-tests.sh` → `42 passed, 0
failed`.
`bash core/hooks/tests/run-gh-guard-tests.sh` → `37 passed, 0 failed`.
All four runs used `env -u CLAUDE_PLUGIN_ROOT_CORE` to avoid the sandbox
hazard described in "What did not work".
