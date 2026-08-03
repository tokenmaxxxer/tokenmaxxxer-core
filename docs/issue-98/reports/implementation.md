---
kind: coding-record
subject: issue-98
produced_by: implementation
code_under_review: 27a0c8aaeba542400f7c3c43828b89c94ffa2d9a
loop_state: landed
upstream:
  - path: docs/issue-98/proposals/2026-08-03-wrapper-head-class-fix-for-dequote-bypass.md
    sha: 27a0c8aaeba542400f7c3c43828b89c94ffa2d9a
---

# Implementation record — issue-98

## Why

Phase 2, approved via issue-level comment `APPROVE issue-98/implementation`
(exact string, posted by an approvers.md account, jjongkwann:
https://github.com/tokenmaxxxer/tokenmaxxxer-core/issues/98#issuecomment-5163202727).
Delivering exactly the approved proposal's `## What will be done`: a
per-quoted-span wrapper-head resolver (`gate_lib.WRAPPER_HEADS` +
`gate_lib.gate_wrapper_head_before`), reusing `board-gate.sh`'s relocated
`TRANSPARENT`/`gate_head_of`, that closes the class of bypass issue-94's
own execution-observation confirmed live (`bash -c "gh pr merge 5"` and
seven other wrapper-headed shapes silently allowing after #94's dequote
fix), plus a separate, independent fix for `board-gate.sh`'s
`READ_UNLESS_INPLACE` awk/sed quoted-redirect gap (requirement 2).

## What was done

1. `core/hooks/lib/gate-lib.py` — added `TRANSPARENT` (relocated from
   board-gate.sh, extended with `timeout`/`nohup`), `TRANSPARENT_TAKES_ARG`,
   `_resolve_transparent`/`gate_head_of` (the public API `_head_of` is
   renamed to, per the proposal), `WRAPPER_HEADS`, and
   `gate_wrapper_head_before(cmdline, span_start)`. `run-gate-lib-tests.sh`
   gained a new `wrapper-head` group (+67 lines): `gate_head_of` parity
   checks against board-gate's pre-move behavior (`xargs`/`xargs -I{}`
   resolve through to the real command; `timeout`'s bare DURATION arg is
   skipped, not mistaken for the head), and `gate_wrapper_head_before`
   unit checks for all 9 issue-named variants plus the two negative-space
   cases (a quoted grep pattern, a bare `bash "script.sh"` with no `-c`).
2. `core/hooks/board-gate.sh` — imports `gate_lib`; the local `TRANSPARENT`/
   `_head_of` definitions are removed, the one call site now reads
   `gate_lib.gate_head_of(stripped)`; `SEGMENT` is now built from
   `gate_lib.GATE_QUOTE_SPAN.pattern` instead of a duplicated literal
   (Finding 3 from the issue-94 execution-observation, `docs/issue-94/
   reports/execution-observation.md`, included per the proposal's
   Rationale since this proposal already opens this exact code). The
   `READ_UNLESS_INPLACE` branch now also checks, alongside `INPLACE`: a
   raw (not `gate_outside_quotes`) `FILE_REDIR` match for `awk`/`gawk`
   segments, and a new `SED_WRITE_CMD` pattern (`\b[wW]\s+\S`) for `sed`
   segments. 8 new cases added to `run-board-gate-tests.sh` (+29 lines):
   3 regression guards confirming wrapper-headed foreign-record writes
   were already denied pre-issue-98 via the unrecognized-head fail-closed
   default (survey's own settled finding, not a new fix here), 1
   confirming a wrapped write to the role's own record still allows, 2
   pinning the real awk/sed gap as `deny` on a foreign-record path, 1
   pinning a plain `sed -n` read as still `allow`, and 1 (`gap-awk-
   comparison-over-block`) pinning the accepted false-positive named in
   the proposal's Rationale (`awk '$1 > 5 {print}' ...`'s bare `>` is a
   numeric comparison, not a redirect, but is indistinguishable from one
   without a real awk parser — over-blocking is this file's own
   established safe direction for exactly this ambiguity).
3. `core/hooks/gh-guard.sh` — imports `gate_lib`; for the three
   `dequote=True` rules only, after the existing dequoted-pattern check,
   added: when the pattern misses dequoted `dq` but matches raw `cmd`,
   scan every `GATE_QUOTE_SPAN` match whose own raw text also matches the
   pattern, and deny if `gate_lib.gate_wrapper_head_before` returns a
   non-empty head for any of them. The 8 `dequote=False` rules are
   untouched. 10 new cases added to `run-gh-guard-tests.sh`'s original
   design (+41 lines before the hunt-driven additions in step 4): one
   `deny` per issue-named variant, spread across all three in-scope rules
   (merge, review --approve, issue create) rather than all merge, plus
   `wrapper-bash-c-plain-grep` (the accepted over-block residual named in
   the proposal's Rationale — a real `bash -c` wrapping a legitimate
   nested grep still denies, since the resolver denies on the wrapper
   head firing regardless of what its own quoted argument contains). The
   three pre-existing `quote-*` negative-space cases were re-run
   unchanged by the same suite run, confirming no regression to #94's own
   negative space.
4. Hunt-driven fix (see `## Hunt` below): `gate_wrapper_head_before`'s
   first version resolved the local head via `gate_head_of`'s TRANSPARENT
   hop-by-hop walk, which — correctly for board-gate's own fail-closed
   use, but wrongly (fail-OPEN) for this new check — assumes every
   `-`-prefixed token is a self-contained flag. A hunt pass found this
   let a TRANSPARENT wrapper's OWN value-taking flag (`nice -n 10`,
   `env -u FOO`, `timeout -s KILL 30`, `xargs -I fmt` with a space)
   misresolve the head to the flag's value token, silently allowing the
   wrapped verb. Redesigned `gate_wrapper_head_before` to scan the local
   segment's words DIRECTLY for the rightmost `WRAPPER_HEADS` word
   instead of depending on that walk (`gate_head_of`/`TRANSPARENT`
   themselves are unchanged, still used as-is by `board-gate.sh`, where
   the same imprecision is harmless — confirmed by the hunt). The same
   pass found `perl`'s own code-execution flag is `-e`, not `-c` (`-c`
   means "check syntax, don't run" for perl) — added a `perl`-specific
   `-e`-shaped flag check. 5 new `deny` cases added to
   `run-gh-guard-tests.sh` (`wrapper-timeout-flag-arg`,
   `wrapper-nice-flag-arg`, `wrapper-env-flag-arg`,
   `wrapper-xargs-space-flag`, `wrapper-perl-e`) and 2 new unit checks to
   `run-gate-lib-tests.sh`'s `wrapper-head` group, pinning the fix.
5. `docs/handbooks/gate-house-standard.md`, `docs/handbooks/board-gate-tests.md`,
   `docs/handbooks/gh-guard-tests.md`: one entry each (+31/+40/+53 lines),
   documenting the new primitives, both gates' fixes, the accepted
   over-block residuals, and the hunt-driven redesign, per the proposal's
   `## What will be done` and the record-shape doc-placement ladder.

## What did not work

- Expected `gate_wrapper_head_before` to resolve the local head by
  literally reusing `gate_head_of`'s TRANSPARENT walk "the same way
  board-gate resolves a segment head today" (proposal's own wording).
  Actual: for `timeout 30 bash -c "..."`, the original `_head_of`
  algorithm's flag-filter (borrowed unmodified) stripped `bash`'s own
  `-c` flag along with `timeout`'s bare DURATION arg in one pass,
  because it filtered the WHOLE remaining word list per hop instead of
  stopping at the first surviving word — losing the trailing `-c` needed
  for this check specifically (board-gate never needed this trailing
  information, only the head word, so the bug was invisible there).
  Fixed by rewriting `_resolve_transparent` to stop skipping at the
  first non-flag word per hop, keeping everything after it (including
  later flags) untouched in `trailing_words`.
- A hunt pass (below) then found that even the rewritten walk still
  misresolves when a TRANSPARENT wrapper's OWN flag takes a separate
  value token (`nice -n 10`, `env -u FOO`, `timeout -s KILL 30`, `xargs
  -I fmt`) — the value token isn't flag-shaped, so it survives the
  filter and gets treated as the next head candidate. Fixed by having
  `gate_wrapper_head_before` stop depending on the walk at all for its
  own purpose (see `## What was done` item 4).
- Expected the proposal's own `## What will be done` test-list bullet
  ("`awk '$1 > 5 {print}' …` … still allow") to be literally correct.
  Actual: the SAME proposal's `## Rationale` explicitly and reasonedly
  states the opposite — this exact case is refused as a write candidate,
  "a false positive but not a hole," matching the file's own established
  over-block convention — and running the actual raw `FILE_REDIR` regex
  against `$1 > 5` confirms it matches (a bare `>` not followed by `&`).
  Resolved in favor of the Rationale (the reasoned, deliberate design
  decision) over the summary bullet (evidently an internal
  inconsistency in the phase-1 proposal): the regression case
  (`gap-awk-comparison-over-block`) asserts `deny` on a foreign-record
  path and is named with the `gap-*` prefix this file's own convention
  uses for an accepted, kept-visible residual, rather than the "allow"
  the bullet's summary implied.

## Doc-placement ladder

- No new env var, config key, dependency, or migration.
- The library-or-format choices this delivery makes — reusing
  `TRANSPARENT`/`gate_head_of` rather than growing a gh-guard-local
  copy, a new sibling `WRAPPER_HEADS` enumeration rather than folding
  wrapper heads into `TRANSPARENT`, per-quoted-span resolution rather
  than whole-line-head, raw (not `gate_outside_quotes`) checks for the
  awk/sed write mechanisms — are already fully recorded in the phase-1
  proposal's `## Rationale` (`docs/issue-98/proposals/2026-08-03-
  wrapper-head-class-fix-for-dequote-bypass.md`). The two implementation-
  level corrections this record's "What did not work" and "Hunt"
  sections describe (the tail-preserving `_resolve_transparent` rewrite,
  and `gate_wrapper_head_before`'s direct-word-scan redesign) are fixes
  to bugs in my own first attempt at the proposal's stated design, not
  alternative designs of its own — no separate `docs/issue-98/decisions/`
  entry needed, same posture as issue-94's record.
- Confirmed all 3 handbook files were actually touched (`git diff
  --stat`): `docs/handbooks/gate-house-standard.md` (+31),
  `docs/handbooks/board-gate-tests.md` (+40),
  `docs/handbooks/gh-guard-tests.md` (+53, including the hunt addendum).

## Hunt

`warrant-hunter` is not among this session's available `Agent`-tool
subagent types (same absence noted in issue-88/90/93/94's records).
Rotating away from issue-94's self-directed `contract-literalist` stance
(and issue-90's self-directed `adversarial-reader`), this pass dispatched
a `general-purpose` subagent (`model: sonnet`, run in the foreground —
this session is a single headless turn with no later turn for a
background notification to land in) with an explicit hostile stance
("hostile bypass-hunter — assume the fix is wrong until you can't find a
hole"), pointed at the actual `git diff` and told to run real commands
against `gh-guard.sh`/`board-gate.sh` as subprocesses rather than reason
abstractly, asked specifically to stress: nested/double wrapping, unusual
`-c`-flag spellings, adjacent-quoted-span edge cases, and TRANSPARENT
wrappers whose own flags take a separate value token.

The hunt found two confirmed, real bypass classes (both fixed, see
`## What was done` item 4 and `## What did not work`) and one confirmed
pre-existing, out-of-scope limitation:

- Value-taking-flag-on-TRANSPARENT-wrapper (`nice -n 10 bash -c "..."`,
  `env -u FOO bash -c "..."`, `timeout -s KILL 30 bash -c "..."`,
  `xargs -I fmt bash -c "..."` with a space instead of `xargs -I{}`) —
  fixed.
- `perl -e "system('gh pr merge 5')"` not caught (perl's real
  code-argument flag is `-e`, not the `-c` this check was scoped to) —
  fixed.
- Adjacent-quoted-string shell concatenation (`bash -c "gh pr mer""ge
  5"`, or mixing `"..."`+`'...'`) splits a single shell word across two
  separate `GATE_QUOTE_SPAN` matches, defeating both the new per-span
  check AND the pre-existing raw-`cmd` prefilter this issue's fix builds
  on — NOT fixed, out of scope: this is a structural limitation of the
  regex-based `GATE_QUOTE_SPAN`/`gate_dequote` primitive itself (issue-94,
  predates this issue), affects ALL three gates' existing quote-aware
  matching regardless of any wrapper class, and is exactly the kind of
  "no real shell parsing" limitation this file's own design has
  repeatedly and deliberately accepted elsewhere (`SUBSHELL` staying
  quote-blind, `_split_segments` staying paren-blind per the issue-94
  proposal's own warrant-hunt). Recorded here as an open finding
  (below), not fixed under this issue's write set.

The hunt also confirmed no new false positives: a real `grep`/`sed`
read, a bare `bash "script.sh"` with no `-c`, a `grep -c` count flag (not
a wrapper), adjacent quoted spans with no wrapper head, and an unrelated
wrapper span appearing after a real one on the same line all still
resolve correctly. All 3 test harnesses were re-run clean after every
fix in this record (not just once at the end).

closed_checks:
- name: gate_wrapper_head_before resolves all 9 issue-named wrapper variants plus the 5 hunt-found variants; negative space (grep, bare bash "path", grep -c, find -c) stays empty
  code_sha: 27a0c8aaeba542400f7c3c43828b89c94ffa2d9a
  result: Verified twice — once via a disposable unit-test script run
    directly against `gate_lib.gate_wrapper_head_before` (deleted after
    use, not committed), and again via the full `run-gh-guard-tests.sh`
    suite's `wrapper-*` group (15 cases) and `run-gate-lib-tests.sh`'s
    `wrapper-head` group (17 cases), both `0 failed`. Confirmed.
- name: all 15 new gh-guard wrapper/hunt cases fail (wrong verdict) on the pre-issue-98 code
  code_sha: 27a0c8aaeba542400f7c3c43828b89c94ffa2d9a
  result: `git stash` on the three source files only (keeping the new
    test cases in the working tree) then re-running
    `run-gh-guard-tests.sh` produced 10 FAILs (all 9 original wrapper
    cases plus `wrapper-bash-c-plain-grep`) against the pre-fix code, all
    `want=deny got=allow`; `git stash pop` restored the fix and the same
    suite went back to 0 failed. (The 5 hunt-driven cases were added
    after this stash/pop cycle, against the already-hunt-fixed code —
    see the next closed_check for their pre-hunt-fix behavior instead.)
    Confirmed.
- name: the 5 hunt-found bypasses actually failed against the pre-hunt-fix gate_wrapper_head_before (not just against pre-issue-98 main)
  code_sha: 27a0c8aaeba542400f7c3c43828b89c94ffa2d9a
  result: this is exactly what the hunting subagent demonstrated live —
    it ran `timeout -s KILL 30 bash -c "gh pr merge 5"`,
    `nice -n 10 bash -c "gh pr merge 5"`, `env -u FOO bash -c "gh pr
    merge 5"`, `echo 5 | xargs -I {} bash -c "gh pr merge {}"`, and
    `perl -e "system('gh pr merge 5')"` as real subprocesses against the
    gh-guard.sh committed at that point in this session (the first
    `gate_wrapper_head_before` design, before this record's item-4
    redesign) and got `allow` (exit 0) for all five; re-run against the
    redesigned code (this record's own final diff) via the same 5 gh-guard
    test cases plus 2 gate-lib unit checks, now `deny`/matching. Confirmed.
- name: board-gate.sh's FILE_REDIR half needs no fix for the wrapper class (survey's own settled finding); the awk/sed READ_UNLESS_INPLACE gap is real and independent
  code_sha: 27a0c8aaeba542400f7c3c43828b89c94ffa2d9a
  result: the same stash/pop cycle above, run against `run-board-gate-
    tests.sh`, produced exactly 3 FAILs pre-fix (`awk-quoted-redirect-
    foreign`, `sed-w-cmd-foreign`, `gap-awk-comparison-over-block`, all
    `want=deny got=allow`) while the 4 wrapper-headed foreign-record
    cases (`bash-wrapper-*-foreign`, `bash-wrapper-own-record`) already
    passed pre-fix — confirming the survey's split finding by live
    re-running it, not re-asserting it. Confirmed.
- name: SEGMENT built from gate_lib.GATE_QUOTE_SPAN.pattern is character-for-character identical to the prior inline literal (Finding 3 closed with no behavior change)
  code_sha: 27a0c8aaeba542400f7c3c43828b89c94ffa2d9a
  result: `gate_lib.GATE_QUOTE_SPAN.pattern` is
    `(?<!\\)'[^']*'|(?<!\\)"(?:[^"\\]|\\.)*"`, which is exactly the
    prefix the old inline `SEGMENT` literal carried before
    `|\|\||&&|[|;\n]` (confirmed already byte-identical by the issue-94
    execution-observation's Finding 3, which this proposal's Rationale
    cites as the reason no new test is needed — the full
    `run-board-gate-tests.sh` suite, which already exercises `SEGMENT`'s
    splitting behavior, stayed at 0 failed across every re-run in this
    session). Confirmed.

## Open findings

One, raised by this record's own Hunt against a pre-existing (issue-94),
not this-issue, primitive: adjacent-quoted-string shell concatenation
(`"a""b"` or `"a"'b'` with no separator) splits one real shell word
across two separate `GATE_QUOTE_SPAN` matches, defeating both raw-`cmd`
pattern matching and the new per-span wrapper check for a command
deliberately obfuscated this way. Out of this issue's write set (a
structural limitation of `gate_dequote`/`GATE_QUOTE_SPAN` itself, not
introduced or worsened by this issue) — worth a future issue proposing a
real shell-tokenizing pass (or accepting it as a permanent, documented
residual the way `SUBSHELL`'s quote-blindness already is), not resolved
here.

## Next steps

None from this delivery's own scope — all three test harnesses green,
every issue requirement (wrapper-head class fix, awk/sed independent
gap, pre-change-failing regression cases, negative space preserved,
handbook commit) met. The one open finding above is a candidate for a
future issue, not a blocker on this one.

## Resolution path

Any open finding against this record is resolved by amending this file
with a `resolved_findings:` entry referencing the finder's record, per
contract v3 s16, before further build commits proceed.

## Verify

`env -u CLAUDE_PLUGIN_ROOT_CORE bash core/hooks/tests/run-gate-lib-tests.sh`
→ `gate-lib: 53 passed, 1 failed` (the 1 failure is
`compliance-check.sh: flags a hand-rolled kill-switch + replace shape`, a
pre-existing, unrelated macOS sandbox artifact where `mktemp -d` ignores
`$TMPDIR` — same failure documented in issue-94's own record; reconfirmed
here by the same stash/pop cycle used for the regression checks above,
which showed this exact single failure persisting identically against
both the pre- and post-fix code).
`env -u CLAUDE_PLUGIN_ROOT_CORE bash core/hooks/tests/run-board-gate-tests.sh`
→ `79 passed, 0 failed` (71 pre-existing + 8 new, all unchanged verdicts
confirmed).
`env -u CLAUDE_PLUGIN_ROOT_CORE bash core/hooks/tests/run-gh-guard-tests.sh`
→ `52 passed, 0 failed` (37 pre-existing + 15 new, all unchanged verdicts
confirmed).
`env -u CLAUDE_PLUGIN_ROOT_CORE` avoids the same sandbox hazard issue-94's
record first documented (an ambient `CLAUDE_PLUGIN_ROOT_CORE` in this
shell points at a separately-installed, stale plugin copy predating this
issue's `gate-lib.py` changes).
