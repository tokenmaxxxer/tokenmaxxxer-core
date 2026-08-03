---
kind: coding-record
subject: issue-99
produced_by: implementation
code_under_review: `core/hooks/board-gate.sh`, `core/hooks/tests/run-board-gate-tests.sh`, `docs/handbooks/board-gate-tests.md`
loop_state: landed
upstream:
  - path: docs/issue-99/proposals/2026-08-03-fix-board-gate-dead-fallback-and-cd-write-verb-gap.md
    sha: e1638153b41925b09851fed301374d227727a80e
---

# Implementation record — issue-99

## Why

Phase 2, approved via issue-level comment `APPROVE issue-99/implementation`
(exact string, posted by an approvers.md account, jjongkwann:
https://github.com/tokenmaxxxer/tokenmaxxxer-core/issues/99#issuecomment-5163202866).
Delivering exactly the approved proposal's `## What will be done`: the
`candidates.append(DOCS)` fallback in `board-gate.sh`'s `Bash` candidate
builder is annotated "mentioned but unextractable: adjudicate" but
structurally can never adjudicate anything (`posixpath.normpath("docs/")`
is `"docs"`, whose `.find("docs/")` is `-1`) — root-caused independently
by `docs/issue-90/reports/execution-observation.md` Finding 1 — so a
command whose write target is expressed relative to a preceding `cd` into
a foreign `docs/` path (`cd docs/issue-49 && date > x.md`) reached
`allow()` with no adjudication, and the same gap caught non-redirect
write verbs (`cp`, `mv`) too.

Before starting, merged `origin/main` (fast-forward-clean, no conflicts —
the phase-1 commit only added `docs/issue-99/**`) to pick up issue-98's
merged wrapper-head class fix and the `TRANSPARENT`/`gate_head_of`
relocation into `gate_lib.py`, since the proposal's write set opens the
same file issue-98 just changed. Baseline re-confirmed post-merge: `bash
core/hooks/tests/run-board-gate-tests.sh` → 79 passed, 0 failed (matching
the survey's own pre-issue-98 baseline count).

## What was done

1. `core/hooks/board-gate.sh:202-231` — extracted the per-segment
   read/fail test previously inlined in `_write_candidate_segments`'s loop
   into `_segment_is_failing(seg, stripped)`, returning the identical bool
   for the identical input (SUBSHELL/FILE_REDIR, `git` subcommand,
   `READ_ONLY_HEADS`, `READ_UNLESS_INPLACE`'s own write mechanisms —
   unchanged logic, only relocated). `_write_candidate_segments`
   (`:233-250`) is now a thin filter over it; `_reads_only` (`:254-256`) is
   unchanged and still calls `_write_candidate_segments`, so its behavior
   for any existing caller is provably identical.
2. `core/hooks/board-gate.sh:259-267` — added `_cd_target(stripped)`: the
   first non-flag word after `cd`, or `""`.
3. `core/hooks/board-gate.sh:272-289` — moved `norm(p)` earlier (previously
   defined only at the old hit-extraction site) and added
   `_docs_relative_tail(token)`, the same normalize-then-find-`DOCS` logic
   the hit-extraction loop already performed inline, now a shared helper
   the `cd`-tracking walk also calls.
4. `core/hooks/board-gate.sh:296-341` (the `Bash` candidate builder) —
   replaced the `_write_candidate_segments`-then-whole-block-rescan flow
   with a single in-order classification pass over `_split_segments`'
   output, followed by an in-order walk: a read-only segment whose head is
   `cd` updates `cd_tail` — sticky, set only when the `cd` target itself
   lands under `docs/` (via `_docs_relative_tail`), never cleared by a
   later non-`docs/` `cd`. A write-classified (failing) segment first
   tries its own `docs/`-shaped tokens (unchanged regex, same as before);
   if it has none and `cd_tail` is set, the candidate is now
   `DOCS + cd_tail` instead of the dead `candidates.append(DOCS)`; if it
   has none and `cd_tail` is unset, it contributes nothing — preserving
   issue-90's own negative space (a `docs/` mention sitting only in an
   already-read-only segment elsewhere on the line must not manufacture a
   candidate). The later hit-extraction loop (`:344-349`) now just calls
   `_docs_relative_tail` per candidate instead of duplicating the
   normalize-then-find logic inline.
5. `core/hooks/tests/run-board-gate-tests.sh` (+24 lines, after the
   issue-90 candidate-scoping section) — 5 new cases exactly matching the
   proposal's list: `bash-cd-relative-redirect-foreign` (the issue's
   headline repro, deny), `bash-cd-relative-cp-foreign` /
   `bash-cd-relative-mv-foreign` (the non-redirect write-verb gap, deny),
   `bash-cd-relative-write-own-issue` (negative-space sibling, allow, now
   via genuine R1-R4 adjudication instead of the dead fallback's
   accidental allow), `bash-cd-out-then-write-elsewhere` (the accepted
   over-blocking trade-off, deny). `bash-unresolved-head-then-read`
   (issue-90's negative space) was left untouched, per the proposal.
6. `docs/handbooks/board-gate-tests.md` (+54 lines) — one entry documenting
   the dead-fallback root cause, the `cd_tail` fix shape, the negative-space
   siblings, and the accepted over-blocking trade-off, same turn as the
   code change.

## What did not work

None — the fix landed as designed on the first attempt; the survey's own
disposable scratch prototype (section 6) had already empirically validated
this exact shape (71/71 existing cases held, every new case produced its
intended verdict) before the proposal was written, so this delivery mainly
transcribed that validated design into the current (post-issue-98) file
rather than discovering it fresh.

## Doc-placement ladder

- No new env var, config key, dependency, or migration.
- The library-or-format choice this delivery makes — a sticky, existential
  `cd`-into-`docs/` tracker over the existing per-segment model, rejecting
  a whole-line rescan (provably unreachable, same structural trap as the
  bug itself), full relative-path resolution (larger, unexhausted surface),
  and a real shell parser (new dependency, disproportionate) — is already
  fully recorded in the phase-1 proposal's `## Rationale`
  (`docs/issue-99/proposals/2026-08-03-fix-board-gate-dead-fallback-and-cd-write-verb-gap.md`).
  No separate `docs/issue-99/decisions/` entry needed; this delivery made
  no design choice the proposal did not already decide.
- `docs/handbooks/board-gate-tests.md` confirmed actually touched (`git
  diff --stat`: +54 lines), same turn as the code change.

## Hunt

`warrant-hunter` is not among this session's available `Agent`-tool
subagent types (same absence noted in issue-88/90/93/94/98's own records).
Rotating away from issue-98's self-directed `general-purpose` hostile
bypass-hunter stance, this pass is self-directed under a
`contract-literalist` stance: re-reading the issue's own four requirements
line by line against the actual diff, rather than searching for novel
bypasses.

- Requirement 1 ("fallback judges per its own comment; no candidate that
  structurally can't pass hit-extraction"): the `DOCS` literal candidate is
  gone from every code path; the only candidates the `Bash` builder ever
  appends are either segment-local tokens already containing a `docs/`
  literal (which `_docs_relative_tail` always resolves) or
  `DOCS + cd_tail`, and `cd_tail` is only ever set from a value
  `_docs_relative_tail` already proved resolves to a non-empty tail before
  assignment — no reachable path re-creates the old dead shape. Confirmed
  by code inspection and by the stash/pop regression check below.
- Requirement 2 (`cp`/`mv` gap addressed or its handling named): closed via
  the same `cd_tail` mechanism, since it depends only on the segment's
  read/write classification (already `cp`/`mv`-aware via
  `READ_ONLY_HEADS`/`_segment_is_failing`) and never on which argument is
  the write target — `bash-cd-relative-cp-foreign`/`-mv-foreign` pin it.
- Requirement 3 (regression cases pre-change-failing; negative space held):
  see the stash/pop closed_check below — all 4 new `deny` cases failed
  (`want=deny got=allow`) against the pre-fix code; `bash-cd-relative-write-own-issue`
  already passed pre-fix (the dead fallback's accidental allow) and still
  passes post-fix (now via genuine adjudication); `bash-unresolved-head-then-read`
  (issue-90's own negative space) and `date; grep ...`-shaped cases pass
  unchanged.
- Requirement 4 (no branch whose reachability isn't proven): the
  rescan-the-whole-line alternative the issue itself warns against was
  never implemented (proposal Rationale rejects it before prototyping); the
  one branch this delivery does add for the "no token, no cd_tail" case is
  exercised live by `bash-unresolved-head-then-read` (reaches it, produces
  the `allow` the negative space requires) — not merely asserted.

No new bypass found; no negative-space regression found.

closed_checks:
- name: all 4 new `deny` cases fail (want=deny got=allow) against the pre-fix board-gate.sh, with only the test file changed
  ref: core/hooks/tests/run-board-gate-tests.sh:283-289
  result: `git stash push -- core/hooks/board-gate.sh` (keeping the new
    test cases and handbook entry in the working tree), then
    `bash core/hooks/tests/run-board-gate-tests.sh` produced exactly 4
    FAILs — `bash-cd-relative-redirect-foreign`, `bash-cd-relative-cp-foreign`,
    `bash-cd-relative-mv-foreign`, `bash-cd-out-then-write-elsewhere`, all
    `want=deny got=allow` (80 passed, 4 failed); `bash-cd-relative-write-own-issue`
    passed even pre-fix (the dead fallback's own accidental allow, as the
    survey documented). `git stash pop` restored the fix; the same suite
    returned to 84 passed, 0 failed. Confirmed.
- name: full existing 79-case baseline (post-issue-98 merge) holds unchanged after the fix, plus the 5 new cases
  ref: core/hooks/tests/run-board-gate-tests.sh:1-341
  result: `bash core/hooks/tests/run-board-gate-tests.sh` → 84 passed, 0
    failed (79 pre-existing + 5 new). Re-run a second time after restoring
    the stash to confirm no leftover state. Confirmed.
- name: no cross-gate regression from the `_segment_is_failing` extraction and the moved `norm`/new `_docs_relative_tail` helpers
  ref: core/hooks/lib/gate-lib.py (unchanged by this delivery — imported, not modified)
  result: `env -u CLAUDE_PLUGIN_ROOT_CORE bash core/hooks/tests/run-gate-lib-tests.sh`
    → 53 passed, 1 failed (the pre-existing, unrelated macOS `mktemp -d`
    sandbox artifact already documented in issue-94/98's own records, not
    caused by this change); `env -u CLAUDE_PLUGIN_ROOT_CORE bash
    core/hooks/tests/run-gh-guard-tests.sh` → 52 passed, 0 failed
    (gh-guard.sh is untouched by this delivery). Confirmed.

## Open findings

None new. The proposal's own named residual (survey section 5 / proposal
Out of scope: the same-issue, cross-role R5 gap — `cd docs/issue-3/reports
&& cp /tmp/a review.md` allowing when R5 would want deny, since
reconstructing only the `cd` target directory is enough for R1-R4 but not
the exact-filename check R5 needs) is unchanged by this delivery, confirmed
still present by construction (this fix's `DOCS + cd_tail` candidate never
carries the write-target filename, on purpose, matching the proposal's
named scope boundary) — not re-verified live this session since the
proposal already named it out of scope with reasoning, and no new
regression to it was introduced (the mechanism that produces it, R5's
`len(parts) < 3` skip, is untouched by this diff).

## Next steps

None from this delivery's own scope — all four issue requirements met
(fail-closed fallback replaced with genuine adjudication, `cp`/`mv` gap
closed via the same directory-level mechanism, regression cases confirmed
pre-change-failing, negative space preserved), handbook updated same turn.
The named same-issue cross-role R5 gap (proposal Out of scope) is a
candidate for a future issue, not a blocker on this one.

## Resolution path

Any open finding against this record is resolved by amending this file
with a `resolved_findings:` entry referencing the finder's record, per
contract v3 s16, before further build commits proceed.

## Verify

`bash core/hooks/tests/run-board-gate-tests.sh` → `84 passed, 0 failed`
(79 pre-existing + 5 new, all unchanged verdicts confirmed; run both
before and after a stash/pop regression check, see `closed_checks` above).
`env -u CLAUDE_PLUGIN_ROOT_CORE bash core/hooks/tests/run-gate-lib-tests.sh`
→ `gate-lib: 53 passed, 1 failed` (pre-existing, unrelated macOS sandbox
artifact, documented in issue-94/98's own records).
`env -u CLAUDE_PLUGIN_ROOT_CORE bash core/hooks/tests/run-gh-guard-tests.sh`
→ `52 passed, 0 failed` (gh-guard.sh untouched by this delivery).
`env -u CLAUDE_PLUGIN_ROOT_CORE` avoids the same ambient
`CLAUDE_PLUGIN_ROOT_CORE`-points-at-a-stale-plugin-copy sandbox hazard
issue-94/98's records document.
