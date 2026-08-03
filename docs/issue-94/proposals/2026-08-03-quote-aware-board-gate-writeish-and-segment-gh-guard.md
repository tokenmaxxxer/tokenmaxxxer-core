---
kind: build-proposal
subject: issue-94
produced_by: implementation
loop_state: proposed
upstream:
  - path: docs/issue-94/reports/implementation/survey.md
    sha: <set at commit>
---

files: `core/hooks/lib/gate-lib.py`, `core/hooks/board-gate.sh`, `core/hooks/approval-gate.sh`, `core/hooks/gh-guard.sh`, `core/hooks/tests/run-gate-lib-tests.sh`, `core/hooks/tests/run-board-gate-tests.sh`, `core/hooks/tests/run-approval-gate-tests.sh`, `core/hooks/tests/run-gh-guard-tests.sh`, `docs/handbooks/gate-house-standard.md`, `docs/handbooks/board-gate-tests.md`, `docs/handbooks/approval-gate-tests.md`, `docs/handbooks/gh-guard-tests.md`

## Request

Two remaining defects in the "shell text read as plaintext, not tokens"
family (survey):

1. `core/hooks/board-gate.sh:226` — `_write_candidate_segments`'s
   `SUBSHELL.search(seg) or FILE_REDIR.search(seg)` runs on each
   segment's **raw** text. `_split_segments` (issue-88) already keeps
   quoted spans from causing a false segment split, but nothing excludes
   a write-ish character sitting *inside* a quoted span from this
   judgment. `grep -n "A > B" docs/issue-49/reports/x.md` — a pure read —
   fails classification on the quoted `>` and gets refused as a write
   candidate.
2. `core/hooks/gh-guard.sh:70-111` — the entire `RULES` list runs
   `re.search(pat, cmd)` against the full raw command string, with no
   quote awareness at all. `grep -n "^def \|gh pr merge\|pr merge"
   spawn.py` — a `grep` that never calls `gh` — is denied because the
   quoted grep pattern contains the literal text `gh pr merge`, which
   `:74`'s `r"\bgh\s+pr\s+(merge|close|reopen)\b"` matches with no idea
   it is sitting inside a string argument.

Both were reproduced live against the current, unfixed code this session
(survey, "Live reproduction"): this session's own board-gate and
gh-guard hooks denied two of this session's own diagnostic Bash calls the
instant their command text contained the issue's two exact repro
strings, with exactly the stated (wrong) reasons.

A synchronous warrant-hunt pass against this proposal's first draft
(survey, "Hunt") found that the straightforward version of this fix —
blank every quoted span everywhere, including `board-gate.sh`'s
`SUBSHELL` and all 11 of `gh-guard.sh`'s `RULES` — opens real holes: a
`$(...)`/backtick command substitution stays *live* even inside double
quotes (bash does not suppress it there), so quote-blind detection of
subshells is a real requirement, not a residual bug; and several
`gh-guard.sh` rules exist specifically to detect content that legitimately
lives inside a quoted argument to a real `gh`/`curl` invocation (a
`--body` string, a GraphQL `-f query='...'` body) — blanket
quote-exclusion there would disable their true-positive path, not just
close an edge case. This proposal's scope (below) is narrowed
accordingly from the first draft the hunt tested.

## Constraints

- Neither gate's protection purpose narrows: board-gate's R1-R5,
  approval-gate's phase-gate rule (untouched in behavior; touched only
  for reuse — see Rationale), and gh-guard's two-account act list all
  keep denying every real, unquoted violation they deny today, and this
  proposal introduces no new false-allow (verified by the hunt for the
  design actually specified below, not just the first draft).
- Every existing case in `run-board-gate-tests.sh` (67),
  `run-approval-gate-tests.sh` (42), and `run-gh-guard-tests.sh` (all
  groups) keeps its current verdict.
- Regression cases use the issue's two exact repro commands verbatim, an
  escaped-quote negative-space case (the issue-88 warrant-hunt shape:
  `\"` outside any real quote must not open a fake quoted span), and a
  real-violation-outside-quotes sibling per fixed check, per the issue's
  explicit ask.
- The issue's constraint against growing "three gates, three ways" is
  honored for the mechanism that is actually shared: the dequote-and-match
  primitive is written once (`core/hooks/lib/gate-lib.py`) and every gate
  that safely can use it does, rather than each keeping its own inline
  copy of the same six-line algorithm.

## Rationale

**Centralize the dequote-and-match primitive in `gate-lib.py`, rather
than port the pattern inline the way issue-90 ported it into
`approval-gate.sh`.** Issue-90's proposal explicitly considered and
rejected centralizing: at that time `gate-lib.py` had no established
consumer among the deny-only gates, and folding `approval-gate.sh` into
a shared model was judged "a materially larger change" risking "a
different, un-warrant-hunted set of edge cases" than porting the
verified regex *pattern* by hand. This issue reopens that same choice,
and the codebase state that motivated the earlier rejection has changed:
`record-fields-gate.sh` already imports `gate_lib` via
`importlib.util.spec_from_file_location` in production (not test-only),
so the import path is proven, not novel; and the quote-span-first
`(?<!\\)` mechanism has now been through two independent warrant-hunted
rounds (issue-88's board-gate `SEGMENT`, issue-90's approval-gate
`WRITEISH`) with regression coverage pinned in both harnesses. This
issue's own constraint ("가능하면 판정 헬퍼를 한 자리로 모은다") is the
user naming this same tradeoff and calling it the other way now that a
third occurrence exists. Duplicating a third inline copy into
`gh-guard.sh` was the alternative that keeps issue-90's posture
unchanged; rejected because it is exactly the outcome the constraint
names as the thing not to keep doing.

**`gate_dequote` (blank quoted spans, then match with the existing
pattern) replaces `_writeish`'s finditer-skip-quote-matches trick as the
shared mechanism, rather than generalizing that trick.** The trick — put
quoted-span alternatives first in one combined regex so `finditer`
consumes a whole quoted span as one match, and skip those — is
mathematically equivalent to dequote-then-match for a single
bare-character pattern (`SUBSHELL`, `FILE_REDIR`, `WRITEISH`'s char
class), so relocating it changes no observable behavior for those.
Dequote-then-match is chosen as the shared primitive instead of the
trick because it is the one of the two that can be scoped *per pattern*
by the caller (see next two points) — the trick has no equivalent notion
of "apply to this character class but not that one within the same
regex," since it is one combined alternation.

**`board-gate.sh`'s `SUBSHELL` is left completely unchanged — raw text,
quote-blind — rather than routed through `gate_dequote` alongside
`FILE_REDIR`.** The issue names `FILE_REDIR`/`SUBSHELL` together as the
check's location, but the concrete repro (`grep -n "A > B" ...`) only
exercises `FILE_REDIR`; the hunt found that giving `SUBSHELL` the same
treatment is unsafe, not merely unnecessary: `` ` ``/`$(` stay live
inside a double-quoted span (bash only suppresses substitution inside
*single* quotes), so `grep -n "$(touch docs/issue-1/pwned.md)" README.md`
is a real write that today's raw-text `SUBSHELL.search` catches only
because it has no quote awareness at all — the same absence of
awareness this issue is fixing for `FILE_REDIR`. Making `SUBSHELL`
quote-aware the same way would newly **allow** that write. `>` has no
such exception (a `>` inside any quote, single or double, is always
inert shell-wise), so `FILE_REDIR` alone is safe to dequote. Because
`board-gate.sh`'s check is `SUBSHELL.search(seg) or
gate_lib.gate_outside_quotes(seg, FILE_REDIR_PATTERN)` (an OR), leaving
`SUBSHELL` as an unconditional raw-text check is also a safety net for
`FILE_REDIR`'s own dequoting: a segment containing `$(touch x > y)`
still fails classification via the unchanged `SUBSHELL` half regardless
of what dequoting does to the `>` inside it. Considered scoping
`SUBSHELL`'s quote-exclusion to single-quoted spans only (where
substitution truly is inert) — rejected for this issue: it is a real,
narrower fix for a case the issue does not reproduce, and would need a
second quote-span definition (single-quote-only) alongside the existing
one, adding a real interface for a case with no named repro; left as a
follow-up, not built speculatively.

**`gh-guard.sh`'s fix narrows to the three `RULES` that are pure
command/verb invocation syntax (`:71-73` review-verdict flags,
`:74-76` merge/close/reopen — the issue's exact repro — `:77-79` issue
create/close/reopen/edit/transfer/delete); the other eight stay
unchanged.** The hunt found that several of the unchanged eight —
comment-body `APPROVE` (`:82-84`, `:85-87`), the raw-API endpoint/state
rules (`:80-81`, `:94-97`, `:98-101`, `:102-105`), and the GraphQL
mutation rule (`:106-110`) — exist specifically to detect content that
legitimately lives *inside* a quoted argument to a real invocation (a
`gh pr comment --body "APPROVE ..."`, a `-f query='mutation{
mergePullRequest(...) }'`): that is their true-positive path for the
overwhelming majority of real invocations, not an edge case they
tolerate. Blanket quote-exclusion across all 11 rules — the design this
proposal's own first draft used before the hunt — would silently
disable detection for the expected shape of exactly the acts these
rules exist to catch; a naive fix would be strictly worse than the
status quo for those eight. The three rules kept in scope have no such
exception: `gh pr merge`/`gh pr review --approve`/`gh issue create` are
subcommand-and-verb syntax no real `gh` invocation spells inside a
quoted argument, so excluding quotes for exactly these three has no
true-positive cost, and directly fixes the issue's named repro. The
remaining eight rules' identical false-positive class (a quoted string
belonging to an unrelated command that happens to contain an
endpoint-shaped or `APPROVE`-shaped substring) is a real, named
limitation of this proposal, listed in Out of scope with the reasoning
above rather than narrowed silently.

**No segmentation added to `gh-guard.sh`; `_split_segments` is not
reused there.** This directly answers the issue's "확인" ask (requirement
2). Two things were found once the scope above was fixed: first,
whole-command dequoting (no segmentation) already gives the identical,
correct verdict to per-segment dequoting for the three in-scope rules —
a real, unquoted `gh pr merge` in one segment is still visible in the
dequoted whole string regardless of an unrelated quoted phrase in
another segment joined by `;`, since dequoting acts on quote boundaries,
not segment boundaries — so segmentation adds no correctness benefit
there. Second, the only place segmentation would add value is bounding
the four lookahead rules' `.*` reach to one real command instead of an
entire multi-command line — but the hunt found that reusing
`_split_segments` there is unsafe: it is quote-aware but not
paren-aware, so a real single invocation with an unquoted separator-shaped
character inside a `$(...)` (e.g. `curl -X POST $(cat token.txt || echo
default) https://.../pulls/5/merge`) would be sliced into two segments,
and a lookahead rule needing both halves in one segment would no longer
fire on a real invocation it catches today. Segmenting only the three
in-scope rules while leaving the other eight matched against the
unsegmented raw string (already the plan, since they are otherwise
unchanged) was considered and rejected as needless complexity: it would
require two different code paths through the same `RULES` loop for zero
behavioral gain over plain whole-command dequoting.

## What will be done

- [ ] `core/hooks/lib/gate-lib.py`: add `GATE_QUOTE_SPAN` (the
  `(?<!\\)'[^']*'|(?<!\\)"(?:[^"\\]|\\.)*"` fragment, identical text
  today duplicated in `board-gate.sh`'s `SEGMENT` and
  `approval-gate.sh`'s `WRITEISH`); `gate_dequote(text)` (blanks every
  matched quote span to a single space — same "substitute with a space"
  idiom `board-gate.sh`'s own `DEVNULL_REDIR.sub(" ", cmdline)` already
  uses); `gate_outside_quotes(text, pattern)`
  (`re.search(pattern, gate_dequote(text)) is not None` — the new shared
  primitive `FILE_REDIR`, `WRITEISH`, and `gh-guard.sh`'s three in-scope
  rules call, each with its own pattern).
- [ ] `core/hooks/board-gate.sh`: import `gate_lib` (the
  `importlib.util.spec_from_file_location` pattern
  `record-fields-gate.sh:147-151` already uses). At `:226`, replace
  `SUBSHELL.search(seg) or FILE_REDIR.search(seg)` with
  `SUBSHELL.search(seg) or gate_lib.gate_outside_quotes(seg, r">>?(?!&)")`
  — `SUBSHELL`'s own check stays exactly as written today (Rationale).
  `_split_segments`/`SEGMENT` are untouched (no reuse need from
  `gh-guard.sh` — Rationale). Docs-path token extraction (`:264-266`)
  keeps scanning the raw (non-dequoted) failing-segment text — unrelated
  to this defect, unchanged.
- [ ] `core/hooks/approval-gate.sh`: import `gate_lib` the same way.
  Replace `WRITEISH`/`_writeish` (`:86-107`) with a call to
  `gate_lib.gate_outside_quotes(cmdline, r"[>|`]|\$\(")` at the one call
  site (`:139`) — same pattern text as today's `WRITEISH` char class
  (including its own pre-existing, out-of-scope `$(`-in-quotes gap,
  unchanged either way), only the mechanism computing the boolean moves.
- [ ] `core/hooks/gh-guard.sh`: import `gate_lib`. Split `RULES` into the
  three in-scope entries (`:71-73`, `:74-76`, `:77-79`) and the eight
  unchanged ones. Compute `dq = gate_lib.gate_dequote(cmd)` once; the
  three in-scope patterns are checked via `re.search(pat, dq)`, the
  eight unchanged patterns via `re.search(pat, cmd)` exactly as today —
  same loop, same deny message shape and order, no rule text changes.
- [ ] `core/hooks/tests/run-gate-lib-tests.sh`: unit-test
  `gate_dequote`/`gate_outside_quotes` directly via the file's existing
  `importlib` load pattern (parity with the existing
  `gate_bash_write_targets` sh/py-parity tests): a quoted `>`/`gh pr
  merge`-shaped phrase is absent from `gate_dequote`'s output; the same
  character/phrase outside any quote survives; `gate_outside_quotes` is
  true for a real unquoted occurrence, false for a quotes-only one.
- [ ] `core/hooks/tests/run-board-gate-tests.sh`: add, after the
  issue-90 section — `run allow bash-quoted-redirect-in-grep Bash
  '{"command":"grep -n \"A > B\" '$BOARD'/x.md"}'` (issue's exact
  defect-1 repro, adapted to the harness's `$BOARD` fixture path);
  negative-space sibling `run deny bash-real-redirect-then-quote Bash
  '{"command":"echo hi > '$BOARD'/x.md"}'`; an escaped-quote
  warrant-hunt sibling mirroring `bash-escaped-quote-then-write` but
  targeting `FILE_REDIR` specifically; a `SUBSHELL`-stays-quote-blind
  negative-space case — `run deny bash-quoted-subshell-write Bash
  '{"command":"grep -n \"$(touch '$BOARD'/x.md)\" README.md"}'` — proving
  the hunt-driven scope decision holds.
- [ ] `core/hooks/tests/run-approval-gate-tests.sh`: no new case (existing
  quote cases already pin `_writeish`'s observable behavior, which does
  not change) — confirmed by re-running the suite, not assumed unchanged.
- [ ] `core/hooks/tests/run-gh-guard-tests.sh`: add a `quote-*` group —
  `run allow quote-gh-pr-merge-in-grep coding 'grep -n "^def \|gh pr
  merge\|pr merge" spawn.py'` (issue's exact defect-2 repro); one allow
  case per in-scope rule (`review --approve`, `issue create`) with the
  same quoted-elsewhere shape; negative-space sibling `run deny
  quote-real-merge-after-quote coding 'grep -n "gh pr merge" x.py; gh pr
  merge 5'` (a real, unquoted violation later on the same line still
  denies); an explicit `gap-f-*` case naming the residual, deliberately
  unfixed false-positive path on an out-of-scope rule — `run deny
  gap-f-api-merge-in-quote-still-fires coding 'echo "note: pulls/5/merge
  discussed" ; curl -X PUT https://api.github.com/repos/o/r/pulls/5/merge'`
  — kept visible (mirrors the existing `gap-c-*` "kept visible rather
  than silently dropped" convention) as a real remaining false-positive
  class this issue does not close, alongside its own real-violation
  sibling continuing to deny correctly.
- [ ] `docs/handbooks/gate-house-standard.md`: add `gate_dequote`/
  `gate_outside_quotes` to "## What `gate-lib.sh` / `gate-lib.py`
  provide".
- [ ] `docs/handbooks/board-gate-tests.md`, `docs/handbooks/approval-gate-tests.md`,
  `docs/handbooks/gh-guard-tests.md`: one entry each, issue-94, including
  a line naming gh-guard's three-of-eleven scope and the reason (link to
  the proposal).
- [ ] Verify: `bash core/hooks/tests/run-gate-lib-tests.sh`, `bash
  core/hooks/tests/run-board-gate-tests.sh`, `bash
  core/hooks/tests/run-approval-gate-tests.sh`, `bash
  core/hooks/tests/run-gh-guard-tests.sh` — all `0 failed`, including
  every pre-existing case unchanged. Each new deny case's stderr is
  inspected directly (not just its exit code) to confirm it denies for
  the rule this proposal names, not some other rule firing first
  (constraint: "deny 가 의도한 이유로 나는지").

## Out of scope

- `board-gate.sh`'s `SUBSHELL` quote-awareness (any quote type) —
  deliberately not fixed; quote-blindness there is required, not a bug
  (Rationale). A narrower, single-quote-only version is a real possible
  follow-up, not built here (no named repro).
- Eight of `gh-guard.sh`'s eleven `RULES` (all but `:71-73`, `:74-76`,
  `:77-79`) keep their current quote-blind false-positive path — fixing
  it safely needs distinguishing "this quote is the real invocation's own
  argument" from "this quote is unrelated data," which needs
  per-segment head-command identification, a materially larger change
  than this issue's two named repro commands (Rationale). Tracked via
  the `gap-f-*` regression case, not silently dropped.
- Any other board-gate rule (R1-R5's other logic, the docs-path
  token-extraction regex itself, the `DEVNULL_REDIR` idiom).
- `approval-gate.sh`'s `WRITEISH`'s own pre-existing `$(`/backtick-in-quotes
  gap (present since `c66aecc`, not introduced or widened here) — not
  this issue's named defect.
- `approval-gate.sh`'s phase-gate logic beyond the `_writeish` call site
  — `execution_surface`, the GitHub-approval precondition chain, etc.
- The harness's exit-code-only comparison (named out of scope by the
  issue itself; #90's observation record already tracks it).
- A backslash escaping a metacharacter *outside* any quotes — not in
  this issue's reproduction set (same carve-out issue-88/90 made).
- Migrating any other `core/hooks/*.sh` gate to `gate_lib` beyond the
  two named here (`board-gate.sh`, `approval-gate.sh`) plus `gh-guard.sh`.
- `gh-guard.sh` segmentation / relocating `_split_segments` — evaluated
  and rejected (Rationale), not merely deferred.

## How you'll know it worked

All four test harnesses (`run-gate-lib-tests.sh`, `run-board-gate-tests.sh`,
`run-approval-gate-tests.sh`, `run-gh-guard-tests.sh`) report `0 failed`,
including: the issue's two exact repro commands now `allow`; the
`SUBSHELL`-stays-quote-blind negative-space case still `deny`s; every
new negative-space sibling `deny`s for its intended rule (message
inspected, not just exit code); the `gap-f-*` residual-limitation case
still `deny`s (proving the unchanged eight `RULES` still work exactly as
today); every pre-existing case in all four files keeps its current
verdict unchanged.
