---
code_under_review:
  - core/hooks/board-gate.sh
  - warrant/hooks/scope-gate.sh
  - core/hooks/tests/run-board-gate-tests.sh
  - core/hooks/tests/run-scope-gate-tests.sh
type: fix
breaking: false
verdict: pass
loop_state: landed
---

## What was done

Closed the two residual write-gate holes issue #227 named (found during
core#226's adversarial review of #225, not regressions from it):

- **`${IFS}`/`$IFS` token-fusion fail-open (both gates).** A command like
  `python3${IFS}-c${IFS}'open(1)'` carries no literal whitespace before
  `-c` in the command TEXT the gates parse — `gate_head_of`'s
  whitespace `.split()` reads `python3${IFS}-c${IFS}'open(1)'` as one
  fused word, and scope-gate's `\s-[A-Za-z]*[ce]` alternative needs a
  literal `\s` it never finds. Rather than normalize the fused token
  apart (floated by the issue but flagged there as possibly riskier),
  applied the issue's own "cheap, high-value catch": the bare presence
  of `$IFS`/`${IFS}` in a write-context command is now itself treated as
  an unanalyzable write shape and denied, fail-closed — no legitimate
  gated write needs it.
  - `core/hooks/board-gate.sh`: added `IFS_TOKEN_RE` and a check inside
    `_is_unanalyzable_write_shape` (only reached when the ordinary token
    scan already found no docs/-shaped hit of its own, same call site
    the heredoc/`-c`/`dd` checks already use).
  - `warrant/hooks/scope-gate.sh`: added `\$\{?IFS\}?` as a new
    alternative in `UNANALYZABLE_WRITE_SHAPE`.
- **board-gate indirect-tee miss.** `echo docs/issue-3/reports/x.md |
  xargs tee` resolves (via `gate_head_of`'s existing `TRANSPARENT` walk
  through `xargs`) to head `tee`, but with no trailing argument word of
  its own — its real write target arrives on stdin, invisible in the
  command text — so it fell through both the existing `own_hits` scan
  and the pre-227 `_is_unanalyzable_write_shape` (heredoc/`-c`/`-e`/`dd`
  only) and reached `if not hits: allow()` unseen. Added a `tee`-with-
  no-visible-target branch to `_is_unanalyzable_write_shape`, scoped so
  a `tee` that DOES name a target (`tee docs/x` or `tee /tmp/x`) is
  unaffected — those are already either caught by `own_hits` (docs/-
  shaped) or are genuine non-board writes (not masked), not this gap.
  scope-gate.sh already covered this shape (`\btee\b` matches
  `xargs tee` regardless of indirection) — no change needed there.
- Added red tests reproducing both shapes to both suites before/while
  fixing, then confirmed green:
  `core/hooks/tests/run-board-gate-tests.sh` — `ifs-fused-inline-c-mask-bypass`
  (deny), `ifs-fusion-unrestricted-session-unaffected` (allow),
  `indirect-tee-via-xargs` (deny), `direct-tee-visible-target` (deny,
  unaffected by this fix — regression guard).
  `core/hooks/tests/run-scope-gate-tests.sh` — `ifs-fused-inline-c-write-shape-denied`
  (deny), `ifs-fusion-unrestricted-session-unaffected` (allow).

## Why

Both gaps are instances of the same underlying issue-225 lesson: a
write-capable command whose real target (or even its own interpreter
head) is not visible in the text the gate can see must fail closed, not
fall through a "nothing found, allow" default. `$IFS` fusion defeats the
whitespace-based head/flag detection both gates already rely on;
indirect `tee` defeats board-gate's target-extraction window for `tee`
specifically. Neither shape has a legitimate reason to appear in a
gated write — deny-by-default costs nothing real.

## Upstream / basis

- Issue #227 (this issue), citing core#226's adversarial review of #225
  as the source of both residuals.
- `docs/issue-225/reports/implementation.md` and
  `docs/issue-225/proposals/2026-08-16-close-script-heredoc-write-masking-bypass.md`
  — the prior fix this one extends (same call sites, same
  `_is_unanalyzable_write_shape`/`UNANALYZABLE_WRITE_SHAPE` mechanisms).
- `core/hooks/board-gate.sh`, `warrant/hooks/scope-gate.sh`, and their
  test suites as they stood at `cac1049` (branch base), read in full
  before writing this fix.

## What did not work

The first `tee` fix (unconditional `if head == "tee": return True` in
`_is_unanalyzable_write_shape`) broke a pre-existing passing test,
`bash-tee-comment-not-target` (`echo "see docs/.../review.md" | tee
/tmp/notes.txt`, expected allow): it treated every `tee`, including one
with a visible non-docs target, as unanalyzable. Narrowed to only fire
when `tee` has no visible non-flag trailing word at all (the indirect/
`xargs`-fed case) — expected: catch only the invisible-target shape;
actual (first pass): caught every `tee` regardless of a visible target.

The first `${IFS}`-fusion red test for board-gate's unrestricted-session
case used deeply nested JSON/shell quoting for a Python `open(...)`
call and produced a malformed JSON payload (parsed as an unreadable
PreToolUse payload, denied instead of the expected allow) — expected:
exercise the same shape as the restricted-session test; actual: JSON
quoting broke and the gate denied on "unreadable payload" instead of
standing down for lack of role/board. Rewritten with the issue's own
minimal reproduction shape (`python3${IFS}-c${IFS}'open(1)'`, single
quotes only, no nested double-quote escaping) instead.

## Open findings

None.

## Amendment: PR #228 adversarial review (both findings fixed)

`gh pr view 228 --comments` surfaced an independent adversarial review
with two blocking findings against the commit above. Both addressed in
`core/hooks/board-gate.sh`, `warrant/hooks/scope-gate.sh`, and their two
test suites.

- **Finding 1 — FALSE POSITIVE.** `IFS_TOKEN_RE`/the scope-gate `$IFS`
  alternative had no boundary after `IFS`, so `$IFSHOME`, `${IFS_DIR}`
  (distinct variable names merely starting with the letters IFS) tripped
  the same deny as an actual `$IFS`/`${IFS}` fusion. Anchored both:
  `\$IFS(?![A-Za-z0-9_])|\$\{IFS(?=[:}])` — matches `$IFS`/`${IFS}`/
  `${IFS:0:1}` but not `$IFSHOME`/`${IFS_DIR}`. Added red-then-green
  regression tests to both suites for the exact reads the review
  demonstrated (`cat "$IFSHOME/notes.md"`, `cat "${IFS_DIR}/x"` — now
  allow).
- **Finding 2 — token-fusion class survives via other spellings.** Fixed
  all four spellings the review demonstrated:
  - `$(...)`/backtick fusion (`python3$(printf " ")-c '...'`,
    `` python3`printf " "`-c '...' ``): added `FUSED_INTERP_RE` (board-
    gate) / an inline alternative (scope-gate) matching an interpreter
    name immediately followed by `$(` or a backtick.
  - Variable-indirected interpreter head (`P=python3; $P -c '...'`):
    added `VAR_INTERP_RE` — a backreference pattern requiring the same
    variable be assigned an interpreter name earlier in the same command
    text. In board-gate this needed a signature change
    (`_is_unanalyzable_write_shape` gained a `full_cmd` parameter) because
    the gate splits on `;` into per-segment `stripped` text before this
    check runs, so the assignment and the indirected call are never in
    the same segment; scope-gate's check runs over the whole raw command
    already, no signature change needed there.
  - `awk`/`gawk`/`nawk`/`mawk`/`ed`/`ex` writes: added to board-gate's
    new `WRITE_UNSAFE_HEADS` tuple (alongside `dd`) and to scope-gate's
    `UNANALYZABLE_WRITE_SHAPE` as a head alternative — these write from
    inside their program/script text (`BEGIN{print > "f"}`, `ed`'s `w`
    command), which the gates don't parse, so their mere invocation
    while a write-set is enforced is now itself unanalyzable/denied
    (same fail-closed posture as `dd`), never over-blocking any other
    read command.
  - Scope kept at what the review demonstrated (real masked writes with
    reproductions): did not additionally chase `process substitution`
    (review flagged this non-blocking, consistent with the existing
    decline-to-vouch posture) or every conceivable further indirection
    spelling — those remain open ground for a future review round, not
    silently declared closed.
- Added 7 new regression tests to each suite (board-gate and scope-gate):
  2 false-positive-reads (allow) + 5 fusion/write-capable-class cases
  (deny) — see Test evidence below for exact names and counts.

## Test evidence

derived: `bash core/hooks/tests/run-board-gate-tests.sh`
```
== 126 passed, 0 failed ==
```
(119 pre-existing + 7 new: ifs-lookalike-var-ifshome-read (allow),
ifs-lookalike-var-ifsdir-read (allow), dollar-paren-fused-inline-c
(deny), backtick-fused-inline-c (deny), var-indirected-interpreter-head
(deny), awk-begin-block-write (deny), ed-script-write (deny) — all
passing, no SKIPPED lines, no regressions.)

derived: `bash core/hooks/tests/run-scope-gate-tests.sh`
```
== 42 passed, 0 failed ==
```
(35 pre-existing + 7 new: same names as above, adapted to scope-gate's
write set — all passing, no SKIPPED lines, no regressions.)

derived: `bash core/hooks/tests/run-all.sh`
```
ALL OK
```
(board gate, scope gate/warrant, approval gate, gh guard, role-agnostic
gates, and sibling-plugin test suites all pass clean; no SKIPPED lines,
no regressions.)

## Amendment 2: PR #228 second adversarial re-review (3 blocking fixed)

`gh pr view 228 --comments` surfaced a second independent adversarial
review of head `44bbab5`. It found the prior "closed" claim overstated —
the same fusion/write-unsafe class remained open at two spots the tests
never exercised, plus a new over-block the second amendment itself
introduced. Correcting the record: Amendment 1 above should NOT have
been read as closing the awk/gawk-family and variable-indirection class
in full — B1/B2/d below were live gaps in that same code at the time.

- **B1 — brace-form indirection `${P}`/`${B}` survived both gates.**
  `VAR_INTERP_RE` (board-gate) and scope-gate's matching alternative both
  used `\$\1\b`, which matches `$P` but never `${P}` — the brace form
  sailed through as an unrecognized shape. Fixed in both by widening the
  reference match to `(?:\$\{\1\}|\$\1\b)`. Red tests added and now
  green: `var-indirected-brace-interpreter-head`
  (`P=python3; ${P} -c '...'`),  `var-indirected-brace-bash-head`
  (`B=bash; ${B} -c 'echo hi > ...'`) — both suites.
- **B2 — awk/gawk `system()` writes survived BOARD-gate.**
  `_segment_is_failing` classified awk/gawk as read-only unless `-i` or a
  literal `>` was present in the segment text, so a `system("touch
  ...")` call — a shell escape with no redirect syntax of its own — never
  even reached `_is_unanalyzable_write_shape`'s (already-correct)
  `WRITE_UNSAFE_HEADS` check, because that check only runs on segments
  already flagged failing. The existing `awk-begin-block-write` test only
  passed because its own program text also carried a literal `>` for an
  unrelated reason (failing test for the wrong reason, per the review).
  Fixed by adding `SYSTEM_CALL_RE` (`\bsystem\s*\(`) as a second write
  trigger alongside `FILE_REDIR` inside the awk/gawk branch of
  `_segment_is_failing`. scope-gate was never affected here — its
  `UNANALYZABLE_WRITE_SHAPE` regex denied all awk-family invocations
  unconditionally already (see finding d). New red test now green:
  `awk-system-call-write` (board-gate suite; command has no `>`, no `-i`,
  only `system(...)`).
- **Finding d — NEW over-block, scope-gate only.** Amendment 1's
  unconditional `(?:awk|gawk|nawk|mawk|ed|ex)\b` alternative in
  `UNANALYZABLE_WRITE_SHAPE` hard-denied every awk-family invocation,
  including a plain read (`awk '{print $1}' file.txt`) — a real
  regression for the dominant safe use of these tools, and inconsistent
  with board-gate's own conditional (`READ_UNLESS_INPLACE`) treatment of
  the same heads. Fixed by keeping `ed`/`ex` unconditional (they write
  via script commands this gate cannot parse out of the invocation text
  at all, same posture as `tee`/`dd`) but scoping `awk`/`gawk`/`nawk`/
  `mawk` to a lookahead requiring one of `system(`, a literal `>`, or
  `-i` somewhere in the command text — same three markers board-gate's
  fixed `_segment_is_failing` now checks. A read with none of those falls
  through to the ordinary decline-to-vouch `allow()`, same as any other
  unlisted read command. New red test now green (scope-gate suite):
  `awk-pure-read-not-overblocked` (want=allow; was deny before this fix).
  Added the equivalent regression guard to board-gate's suite too
  (`awk-pure-read-not-overblocked`) confirming the board-gate fix for B2
  did not also widen awk into an unconditional write-unsafe head.
- Non-blocking items from the first review round (`eval 'python3 -c
  ...'` bypassing board-gate; an interpreter given a script FILE argument,
  e.g. `sh -x file.sh`, being unanalyzable) are explicitly **left open,
  out of scope for this amendment** — not fixed, not claimed fixed. They
  match the standing decline-to-vouch/process-substitution posture the
  first review itself called non-blocking. A follow-up issue should track
  them; this record does not claim them closed.
- 3 new tests added to each suite (board-gate and scope-gate): 2 deny
  (B1's two indirection spellings) + 1 allow (finding d's pure-read
  guard) for scope-gate; board-gate gets the same 3 plus B2's
  `awk-system-call-write` deny (board-gate needed this test, scope-gate
  did not — its awk clause already covered `system()` unconditionally
  pre-fix).

derived: `bash core/hooks/tests/run-board-gate-tests.sh`
```
== 130 passed, 0 failed ==
```
(126 pre-existing + 4 new: var-indirected-brace-interpreter-head (deny),
var-indirected-brace-bash-head (deny), awk-system-call-write (deny),
awk-pure-read-not-overblocked (allow) — all passing, no SKIPPED lines,
no regressions.)

derived: `bash core/hooks/tests/run-scope-gate-tests.sh`
```
== 46 passed, 0 failed ==
```
(42 pre-existing + 4 new: var-indirected-brace-interpreter-head (deny),
var-indirected-brace-bash-head (deny), awk-system-call-write (deny),
awk-pure-read-not-overblocked (allow) — all passing, no SKIPPED lines,
no regressions.)

derived: `bash core/hooks/tests/run-all.sh`
```
ALL OK
```
(same full sweep as Amendment 1, re-run clean after this amendment's
changes; no SKIPPED lines, no regressions.)
