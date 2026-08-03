---
kind: coding-record
subject: issue-90
produced_by: implementation
code_under_review: d52d1e68c15dc8711ee0834520d643059942404d
loop_state: landed
upstream:
  - path: docs/issue-90/proposals/2026-08-03-scope-board-gate-candidates-and-port-approval-gate-fixes.md
    sha: d52d1e68c15dc8711ee0834520d643059942404d
---

# Implementation record — issue-90

## Why

Phase 2, approved via issue-level comment `APPROVE issue-90/implementation`
(exact string, posted by an approvers.md account). Delivering exactly the
approved proposal's `## What will be done`: two false-positive
read-classification defects, one per gate, both already root-caused by
the phase-1 survey (docs/issue-90/reports/implementation/survey.md).

## What was done

1. `core/hooks/board-gate.sh`: `_write_candidate_segments(cmdline)`
   replaces the loop that used to live inside `_reads_only`, checking
   SUBSHELL/FILE_REDIR/git-subcommand/READ_ONLY_HEADS/READ_UNLESS_INPLACE
   per segment (same rules, finer granularity) and returning the list of
   segments that could not be proven read-only. `_reads_only(cmdline)` is
   now `return not _write_candidate_segments(cmdline)`. The `Bash`
   candidate builder computes `failing_segments` once and runs the
   existing `docs/`-token `re.findall` scan over
   `"\n".join(failing_segments)` instead of the raw `cmdline`.
2. `core/hooks/approval-gate.sh`: added `"cd"` to `READ_ONLY_HEADS`.
   `WRITEISH` now leads with quote-span alternatives
   (`(?<!\\)'[^']*'|(?<!\\)"(?:[^"\\]|\\.)*"`) ahead of the write-ish-char
   alternatives, same shape as `board-gate.sh`'s `SEGMENT`. Added
   `_writeish(cmdline)`, which walks `WRITEISH.finditer` and returns
   `True` on the first non-quote match, `False` if every match was a
   quoted span (or there were none). The call site at the old line 120
   now calls `not _writeish(cmdline)` instead of
   `not WRITEISH.search(cmdline)`.
3. Regression cases added exactly as scoped in the proposal:
   `core/hooks/tests/run-board-gate-tests.sh` gained
   `bash-unresolved-head-then-read` (allow) and its negative-space
   sibling `bash-unresolved-head-real-write` (deny).
   `core/hooks/tests/run-approval-gate-tests.sh` gained
   `bash-cd-then-read-own-reports` (allow) / `bash-cd-then-write-src`
   (deny sibling), `bash-quoted-redirect-in-grep` (allow) /
   `bash-single-quoted-pipe-grep` (allow) /
   `bash-quoted-redirect-then-real-pipe` (deny sibling), and
   `bash-escaped-quote-then-write` (deny, ported warrant-hunt
   regression) — 8 cases total, 2 + 6, matching the proposal.
4. `docs/handbooks/board-gate-tests.md` and
   `docs/handbooks/approval-gate-tests.md`: one entry each documenting
   the fixes above.
5. Ran both harnesses: `run-board-gate-tests.sh` → `67 passed, 0 failed`;
   `run-approval-gate-tests.sh` → `42 passed, 0 failed` (all pre-existing
   cases unchanged, all 8 new cases pass to their proposal-specified
   verdict).

## What did not work

- Initially wrote the 3 new `approval-gate` regression cases that carry
  a literal `"` in their `cmd=` value (`bash-quoted-redirect-in-grep`,
  `bash-quoted-redirect-then-real-pipe`, `bash-escaped-quote-then-write`)
  without escaping that quote for the harness's `run()`, which builds
  the `Bash` tool's JSON `tinput` via a bare `printf '{"command":"%s"}'
  "$cmd"` with no JSON-escaping. Expected: valid JSON exercising
  `_writeish`. Actual: the unescaped `"` produced invalid JSON, which
  `approval-gate.sh` denies via its unrelated "unreadable PreToolUse
  payload" path — for the two `want deny` cases this coincidentally
  matched the expected verdict without ever running `_writeish`, so the
  first full-suite run showed only 1 explicit `FAIL` (the `want allow`
  case, where the mismatch showed) even though 3 cases were vacuous.
  Fixed by pre-escaping `"` → `\"` (and, for the case with a real
  backslash in the target command, `\` → `\\` first) in the `cmd=`
  literal so the harness's naive substitution yields valid JSON whose
  parsed `command` equals the intended raw command line; verified the
  round-trip in isolation before re-running the suite. Documented as a
  test-authoring note in `docs/handbooks/approval-gate-tests.md` so a
  future case with an embedded quote doesn't repeat this silently.

## Doc-placement ladder

- [x] `docs/handbooks/board-gate-tests.md` — candidate-scoping fix entry
  (same-turn, board-gate.sh behavior change).
- [x] `docs/handbooks/approval-gate-tests.md` — `cd` + quote-aware
  `WRITEISH` fix entry, plus the test-authoring escaping note (same-turn,
  approval-gate.sh behavior change).
- No new env var, dependency, migration, or public-signature/wire-format
  change — no `docs/issue-90/decisions/` entry needed.

## Hunt

Stance for this pass: adversarial-reader (recheck the ported quote-span
regex and the segment-scoping change against the same bypass class PR #89's
warrant-hunt found, since defect 2 explicitly ports that exact mechanism).

closed_checks:
- name: escaped-quote-bypass ported to approval-gate WRITEISH
  code_sha: d52d1e68c15dc8711ee0834520d643059942404d
  result: `bash-escaped-quote-then-write` added to
    run-approval-gate-tests.sh and passes deny — a backslash-escaped
    quote character outside any real shell quote does not open a fake
    quoted span in `_writeish`.
- name: segment-scoping does not widen R1-R5 to allow real writes
  code_sha: d52d1e68c15dc8711ee0834520d643059942404d
  result: `bash-unresolved-head-real-write` negative-space sibling added
    and passes deny — a real write inside the failing segment itself
    still denies after scoping the scan to failing segments only.
- name: cd-then-write still denies on approval-gate
  code_sha: d52d1e68c15dc8711ee0834520d643059942404d
  result: `bash-cd-then-write-src` negative-space sibling added and
    passes deny — adding `cd` to READ_ONLY_HEADS does not exempt a
    cd-prefixed line that really writes.
- name: real unquoted pipe after a quoted redirect still denies
  code_sha: d52d1e68c15dc8711ee0834520d643059942404d
  result: `bash-quoted-redirect-then-real-pipe` added and passes deny —
    quote-span-first matching in WRITEISH does not swallow a later real,
    unquoted write-ish character.
- name: naive JSON substitution in the approval-gate harness's cmd= path
  code_sha: d52d1e68c15dc8711ee0834520d643059942404d
  result: caught mid-build (see "What did not work") — 3 new cases with
    embedded quotes needed manual JSON-escaping in their cmd= literal or
    they would have silently vacuously passed via a JSON-parse-failure
    deny instead of exercising _writeish. Verified round-trip before
    finalizing; documented as a handbook note for future test authors.

## Open findings

None raised against this record.

## Next steps

None — delivery complete, both harnesses at 0 failed, PR ready for
merge.

## Resolution path

Any open finding against this record is resolved by amending this file
with a `resolved_findings:` entry referencing the finder's record, per
contract v3 s16, before further build commits proceed.

## Verify

`bash core/hooks/tests/run-board-gate-tests.sh` → `67 passed, 0 failed`.
`bash core/hooks/tests/run-approval-gate-tests.sh` → `42 passed, 0 failed`.
