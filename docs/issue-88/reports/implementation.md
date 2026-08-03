---
kind: implementation-record
subject: issue-88
produced_by: implementation
code_under_review: core/hooks/board-gate.sh, core/hooks/tests/run-board-gate-tests.sh, docs/handbooks/board-gate-tests.md
loop_state: landed
upstream:
  - path: docs/issue-88/proposals/2026-08-03-fix-board-gate-quoted-pipe-and-cd-read-classification.md
    sha: ca5c7dafb7608d9b28b94c9f294efc0bb1c73ec5
---

# Record — board-gate quoted-pipe + cd read-classification fixes (phase 2)

Phase 2 opened via issue-level single-account approval: comment
`APPROVE issue-88/implementation` by `jjongkwann` (an approvers.md
account, same account as this branch's PR author) on issue #88.

## What was done

Built the approved proposal
(`docs/issue-88/proposals/2026-08-03-fix-board-gate-quoted-pipe-and-cd-read-classification.md`)
checklist, with one regex correction beyond its literal text (see
"Rationale for deviations"):

- `core/hooks/board-gate.sh:96-99` (`READ_ONLY_HEADS`): added `"cd"`.
- `core/hooks/board-gate.sh:119-125` (`SEGMENT`): extended with quoted-span
  alternatives ordered before the separator alternatives, each guarded by
  a `(?<!\\)` negative lookbehind (the correction — the proposal's literal
  regex omitted this and a warrant-hunt found why it's needed, below).
- `core/hooks/board-gate.sh:128-151`: added `_split_segments(cmdline)` —
  walks `SEGMENT.finditer()`, extends the running segment on a quote
  match, cuts a new one on a real separator match. Same list shape
  `SEGMENT.split()` produced before.
- `core/hooks/board-gate.sh:200` (formerly line 170): `for seg in
  SEGMENT.split(probe):` → `for seg in _split_segments(probe):`.
- `core/hooks/tests/run-board-gate-tests.sh`: added the proposal's 6
  regression cases (4 allow, 2 deny) after `bash-git-show-foreign-issue`,
  plus one more the warrant-hunt required (`bash-escaped-quote-then-write`,
  deny) — 7 new cases total, all passing.
- `docs/handbooks/board-gate-tests.md`: documented both original
  regression classes plus the warrant-hunt's finding and fix.
- Verified: `bash core/hooks/tests/run-board-gate-tests.sh` → `65 passed,
  0 failed` (was 58 before this issue's cases were added). `bash -n` on
  both modified shell files: syntax-clean.

### Organic reproduction, during this session, before any code was touched

The `cd`-classification bug reproduced live and unprompted, twice, from
this session's own ordinary tool use (not a synthetic harness): a Bash
tool call combining `cd <repo>` with a later `git show
<sha>:docs/issue-20/reports/implementation.md` was denied by the gate on
`_reads_only` failing at the `cd` segment, falling through to the
write/candidate scan and R4-denying against a foreign issue tree it was
never going to write to. This matches the issue's report exactly. After
the fix landed, the identical command (re-run to confirm) returned
`0`/succeeded.

## Why

`core/hooks/board-gate.sh`'s `_reads_only()` misclassified two read-only
Bash shapes as writes: a quoted `\|` inside a BRE pattern split the
command into fake segments (line 121's `SEGMENT` had no quote-awareness),
and `cd <dir> && cat docs/...` was denied outright because `cd` was
absent from `READ_ONLY_HEADS` (line 96). Both reproduced repeatedly
outside this repo per the issue, and the `cd` bug reproduced live in this
very session (above).

## Hunt cadence

`warrant-hunter` is not among this session's available `Agent`-tool
subagent types (same absence noted in `docs/issue-20/reports/implementation.md`).
In its place, before declaring this delivery done, dispatched a
`general-purpose` subagent with an explicit adversarial stance
("hostile bypass-hunter — assume the fix is wrong until you can't find a
hole"), pointed at the new `_split_segments`/`SEGMENT` code and the
question: does any command line now get classified read-only (skipping
R1-R5 entirely) that would actually execute a write?

**Result: one real, confirmed bypass**, found before this record's code
was finalized. A backslash-escaped quote CHARACTER outside any real
shell quote (e.g. `ls \" ; rm -rf docs/issue-1/x #"`) was matched by the
proposal's literal quoted-span regex as opening a quote anyway (regex
alternation has no notion of "this quote char is itself escaped"); the
fake quote then ran to an unrelated later quote (here, one inside a `#`
comment), swallowing the real `;` between two real commands as if it
were quoted content, and hiding a real write (`rm -rf docs/...`) in the
second real command from the per-segment head check — `_reads_only()`
returned `True` and `allow()` skipped R1-R5 entirely. Verified directly
against the file's actual code (not just described) before and after the
fix. Fixed with a `(?<!\\)` negative lookbehind on both quote
alternatives in `SEGMENT` (own probe, below, re-confirms both the
bypass's prior existence and the fix). Pinned as
`bash-escaped-quote-then-write` in the test file.

No second bypass surfaced across the other angles the hunt tried
(quote/separator interaction with `FILE_REDIR`/`SUBSHELL`/`DEVNULL_REDIR`,
which run on the whole string pre-segmentation and are independent of
`SEGMENT`'s matching; well-formed same/cross-type quote nesting; `cd`
having no other `READ_ONLY_HEADS` consumer to disturb).

## What did not work

The phase-1 proposal's literal test commands for `bash-cd-then-cat` and
`bash-cd-then-write-foreign` (`cd $BOARD && cat x.md` /
`cd $BOARD && echo x > review.md`) do not exercise what their names
claim: neither read nor write target in those exact strings contains a
`docs/` substring itself (only the `cd` argument does), so the gate's
candidate-token extraction — a superset scan over the raw command text,
with no shell-cwd simulation — never sees `x.md`/`review.md` as a
docs-path candidate at all; both pass trivially regardless of whether
the `cd` fix is present. Running the harness with the literal proposal
text confirmed this: `bash-cd-then-write-foreign` came back
`want=deny got=allow`, an unintended pass-through, not a true negative
test. Replaced both with equivalent commands whose targets are
themselves docs-path-shaped (`cd $BOARD && cat $BOARD/x.md`;
`cd $BOARD && echo x > $BOARD/reports/review.md`, the latter a foreign
role's record file, mirroring the existing `foreign-record` case) — see
"Rationale for deviations".

A stray unmatched trailing quote in the warrant-hunt's bypass string
(the `#"` at the end) was initially suspected to need special handling
in `_split_segments`; it does not — `SEGMENT`'s quote alternative
requires two quote characters to match at all, so a single trailing
quote with no partner simply fails to match and is consumed as ordinary
non-separator content. Confirmed by direct trace, no code change needed
for that half.

## Rationale for deviations

Two adjustments beyond the approved proposal's literal text, both
discovered empirically during this build, not chosen speculatively:

1. **`SEGMENT`'s quote alternatives gained a `(?<!\\)` negative
   lookbehind** the proposal's literal regex
   (`'[^']*'|"(?:[^"\\]|\\.)*"|\|\||&&|[|;\n]`) did not have. Without it,
   a backslash-escaped quote character outside any real shell quote
   opens a fake quote match that can swallow a real separator and hide a
   real write — the concrete bypass the warrant-hunt found (see "Hunt
   cadence"). The lookbehind closes it: a quote char immediately preceded
   by a backslash never starts a quoted-span match. The one accepted
   cost — a genuine quote preceded by an already-escaped backslash
   (`\\"real quote"`, a rare shell idiom) now over-splits instead of
   parsing correctly — is the same direction the gate already commits to
   elsewhere (comment at `board-gate.sh:173`, "over-blocking is the safe
   direction"), and does not weaken any existing R1-R5 case (full suite
   still `0 failed`).
2. **Two of the proposal's six regression-test commands were replaced**
   with equivalent-intent commands whose write/read target is itself
   docs-path-shaped, because the literal proposal text did not actually
   exercise the claim in its own name (detailed in "What did not work").
   No case was removed or weakened — `bash-cd-then-write-foreign` now
   denies for a real reason (R5, foreign-role record) instead of passing
   by accident, and `bash-cd-then-cat` now genuinely tests that a
   `cd`-then-`cat` read of a `docs/` path allows, instead of testing
   nothing.

Neither change alters the proposal's Constraints (R1-R5 unweakened,
minimal diff confined to `core/hooks/board-gate.sh` and its test/doc
pair) or its Out of scope (still no `approval-gate.sh` change, still no
bare unquoted-backslash handling beyond what quote-tracking covers).

## Doc-placement ladder

- [x] Both original regression classes (quoted-`|` segment-split
  blindness, `cd` absent from `READ_ONLY_HEADS`) plus the warrant-hunt's
  finding and fix (backslash-escaped-quote segment-merge) documented in
  `docs/handbooks/board-gate-tests.md`, the component's handbook, same
  turn as the code change. No new env var, dependency, or migration —
  no `.env.example`/manifest entry applies.
- [x] No library-or-format choice beyond what the phase-1 proposal's own
  "Alternatives considered" section already decided, and no changed
  public signature/wire format — no `docs/issue-88/decisions/` entry.
- [x] No benchmark/investigation numbers produced (not that kind of
  change) — no `docs/issue-88/reports/` entry beyond this record.

## Closed checks

- `core/hooks/tests/run-board-gate-tests.sh` (code_sha: HEAD of this
  record): 65 passed, 0 failed — run locally, output captured above,
  includes all pre-existing R1-R5/git-subcommand/fast-path/kill-switch/
  fail-closed cases unchanged plus the 7 new cases for this issue.
- `bash -n` on both modified shell files (code_sha: HEAD of this
  record): syntax-clean.
- Live re-run of the organically-reproduced `cd`-prefixed `git show`
  command from this same session, before and after the fix (code_sha:
  HEAD of this record): denied before, allowed after.
- Adversarial hunt by an independent `general-purpose` subagent, stance
  "hostile bypass-hunter" (code_sha: HEAD of this record): 4 angles
  tried, 1 confirmed bypass found and fixed (backslash-escaped-quote
  segment-merge), re-confirmed closed by the subagent's own before/after
  trace plus this session's own isolated regex probe.

## Next steps

None from this phase. Residual gaps explicitly out of this issue's
scope (per the proposal): `approval-gate.sh`'s identical two defects
(separate gate, separate harness — recommend a follow-up issue); a bare
unquoted backslash escaping a metacharacter (e.g. unescaped `A\|B` with
no quotes at all); the pre-existing `--output=<file>` residual on `git
log`/`show`/`diff` (already flagged in issue-60's survey).

## Open findings

None outstanding — the one finding raised during this session (the
warrant-hunt's bypass) was fixed and pinned into a regression test
before this record's `loop_state` was set to `landed`; see "Closed
checks".
