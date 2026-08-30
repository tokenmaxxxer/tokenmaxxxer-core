---
issue: 233
role: secure-coding-input-validation-injection-defense+adversarial-review-746ed714
author: secure-coding-input-validation-injection-defense+adversarial-review-746ed714
skills: secure-coding-input-validation-injection-defense (skill-repository(c05de12)), adversarial-review (skill-repository(c05de12))
verifies_subject: false  # flip to true only if this record is an independent verification of this subject's own deliverable -- see docs/handbooks/observer-verification.md
loop_state: landed
code_under_review:
  - core/hooks/board-gate.sh
  - warrant/hooks/lib/scope-gate.py
  - core/hooks/tests/run-board-gate-tests.sh
  - core/hooks/tests/run-scope-gate-tests.sh
type: fix
breaking: false
verdict: pass
upstream:
  - path: core/hooks/board-gate.sh
    sha: same-commit
  - path: warrant/hooks/lib/scope-gate.py
    sha: same-commit
---

# issue-233 — secure-coding-input-validation-injection-defense+adversarial-review-746ed714 record

## What was done

Closed the interpreter-head masking class board-gate.sh and
warrant/hooks/lib/scope-gate.py were still leaking on — reached via
single-token shell expansion, then `-c`/`-e` — generically, per the
issue's own fix direction, instead of enumerating more spellings:

- **board-gate.sh** (`_is_unanalyzable_write_shape`): added
  `EXPANDED_HEAD_RE = re.compile(r"[`$]")`, searched (not anchored)
  against the already-resolved `head` token
  (`gate_lib.gate_head_of(stripped)`), alongside the existing
  `head in INTERPRETER_HEADS` check that feeds the `INLINE_FLAG_WORDS`
  (`-c`/`-e`) lookup. Because `head` is the one token `gate_head_of`
  actually decided is this segment's head — never argument text — a
  `$`/backtick anywhere inside it is always suspect, regardless of which
  program name the expansion produces. Added `eval` to
  `WRITE_UNSAFE_HEADS` (unconditional, same bucket as `ed`/`ex`: `eval`
  runs its argument as fresh shell text with no `-c`/`-e` flag involved
  at all).
- **warrant/hooks/lib/scope-gate.py** (`UNANALYZABLE_WRITE_SHAPE`): added
  a boundary-anchored alternative —
  `(?:^|;|&&|\|\||\||\n)\s*\S*[`$]\S*[^\n|;&]*\s-[A-Za-z]*[ce](?:\s|=|$)`
  — requiring the `$`/backtick to sit in the whitespace-delimited word
  immediately after a genuine command boundary (start-of-command, `;`,
  `&&`, `||`, `|`, newline), not merely after any whitespace (which would
  also match inside a later, unrelated argument — this gate has no real
  tokenizer). Added `eval` to the existing unconditional `ed`/`ex`
  alternative for the same reason as board-gate.
- **Adversarial hunt round, pass 1** (a fresh subagent, blind to this
  session's reasoning, given only the two source files and gate-lib.py):
  found the first-pass fix still missed two spellings — a QUOTED
  expansion head (`"$SHELL" -c ...`, `` "`cmd`" -c ... ``, `"$0" -c
  ...`), and a whitespace-fusion variable that is not literally named
  `$IFS` (`python3${X}-c` where `X` holds a space — issue-227's `$IFS`
  fix only checked that one enumerated name). Fixed both: dropped the
  `^` anchor on `EXPANDED_HEAD_RE` (a quote before `$`/backtick no longer
  hides it) and added `EXPANDED_HEAD_FUSED_FLAG_RE =
  re.compile(r"^\S*[`$]\S*-[A-Za-z]*[ce]\b")` for the case where `-c`/
  `-e` is fused directly onto the same head token (so `-c` never appears
  as its own trailing word for `INLINE_FLAG_WORDS` to find). Mirrored
  both fixes into scope-gate.py's regex (a second, fused-flag
  alternative alongside the spaced one).
- **Adversarial hunt round, pass 2** (a second fresh subagent, told what
  pass 1 already fixed, asked to find a third kind of gap): found zero
  further single-token-expansion bypasses after genuinely trying arrays,
  brace expansion, arithmetic expansion, ANSI-C quoting, and nested
  indirection. It did surface two DIFFERENT-class, pre-existing gaps
  (quoting the `-c` flag word itself on a literally-named interpreter,
  e.g. `python3 '-c' "..."`; and a leading `VAR=value` prefix defeating
  `gate_head_of`'s head resolution, e.g. `FOO=1 python3 -c "..."`) —
  logged under Open findings below, not fixed: neither is a
  single-token-expansion-produced head (both heads are the literal,
  resolvable name `python3`), so both are out of this issue's scope,
  matching the acceptance criterion's own wording ("single-token-
  expansion interpreter-head bypass").
- Added 7 new tests to each of `run-board-gate-tests.sh` (5 core
  reproductions + 1 negative control + 1 unrestricted-session control,
  plus 5 more from the hunt rounds + 1 calibration control = 12 total)
  and `run-scope-gate-tests.sh` (10 total) — see Test evidence.

## Why

The issue named three residual spellings of one masking class (parameter-
default expansion `${x:-python3}`/`${x:=bash}`, and a command
substitution `$(echo python3)` that produces the head outright) that
three consecutive adversarial review rounds on issue-227/#228 had already
shown leak through a name-enumeration strategy (`FUSED_INTERP_RE`,
`VAR_INTERP_RE`) one spelling at a time. The issue's own fix direction
was explicit: close the class by structure, not by naming a fourth/fifth
spelling — "an enumeration of shells and interpreters is the closed-set
shape this program spent a month removing" (matching the identifier-
axis retirement work in issue-2600/issue-2670/issue-349, cited in the
diff's own comments as the same lesson on a different axis). The
structural invariant used here: this gate can only vouch for a write
shape whose interpreter identity it can actually read from the command
text. A head token that begins with, or contains, `$`/a backtick is
never such a token — it does not matter which of countless possible
programs the expansion resolves to at runtime, so no enumeration of
"known interpreters" is needed to refuse it once it also carries a
`-c`/`-e` code-execution flag. `eval` was added unconditionally (not
flag-gated) because its whole purpose is running unparsed text as fresh
shell input, the same posture as the pre-existing unconditional `ed`/`ex`
entries.

Two full adversarial hunt rounds (per the `adversarial-review` skill's
core mechanism — a fresh, independent evaluator with no stake in the
builder's reasoning finds what self-review structurally cannot) were run
specifically to satisfy the issue's second acceptance check before
declaring the class closed; the two additional bypasses pass 1 found
were fixed in the same commit rather than left for a fourth review round.
Per the `secure-coding-input-validation-injection-defense` skill's rule
2 ("a denylist filter proposed as the sole defense against injection
should be removed as the primary control, kept only as a supplementary
layer"), the pre-existing enumeration-based checks (`FUSED_INTERP_RE`,
`VAR_INTERP_RE`, `INTERPRETER_HEADS`) were left in place but are no
longer the primary defense for this class — the new structural checks
are broader and subsume every case those enumerations already caught,
so the enumerations are now redundant, defense-in-depth, not load-
bearing. Fail-closed calibration: the new checks only fire when
combined with an actual `-c`/`-e` flag, verified not to over-block
`${HOME}/x`-style path reads, `awk '{print}' file`, or a `grep
"$PATTERN" file -e extra` read that merely happens to have a `$`-bearing
EARLIER argument (the scope-gate boundary anchor exists specifically to
keep that read allowed).

## What did not work

The first `EXPANDED_HEAD_FUSED_FLAG_RE` design attempt folded the fused-
flag case into the existing `INLINE_FLAG_WORDS`/`gate_trailing_words`
check instead of adding a separate regex — expected: `-c` fused onto
`python3${X}-c` would still surface as a distinguishable trailing token;
actual: `gate_trailing_words` splits on whitespace only, so a fused `-c`
is never its own word at all, and the check silently never fired. Fixed
by adding a second, independent regex checked directly against the raw
segment text (`EXPANDED_HEAD_FUSED_FLAG_RE`, anchored to the segment
start so it can only match the head token, never a later argument).

The first `scope-gate.py` alternative for the parameter-default/cmdsub
class anchored on a balanced `${...}`/`$(...)`/`` `...` `` span
(`\$\{[^{}]*\}|\$\([^()]*\)|` `[^`]*` ``) — expected: covers every
parameter-expansion/command-substitution spelling; actual: a bare
`$0`/`$VAR` head (no closing bracket to anchor on) and a nested
expansion `${x:-${y:-python3}}` (the inner `{` breaks the `[^{}]*`
class) both slipped through — caught by the hunt-round-1 agent before
landing. Replaced with the boundary-then-contains-`$`/backtick approach
described above, matching board-gate.sh's simpler and strictly more
robust "search anywhere in the resolved head token" design (board-gate
has a real tokenizer via `gate_head_of` and never had this specific
bracket-balancing problem).

## Upstream basis

- Issue #233 (this issue), citing the third adversarial review of PR
  #228 (issue-227) as the source of the three named residual spellings.
- `docs/issue-227/reports/implementation.md` (commit `add04ca`) — the
  prior three rounds of fixes this one extends: `$IFS`-specific fusion,
  `$()`/backtick-fused interpreter names, brace-form variable
  indirection (`${P}`), and the awk/gawk write-detection fixes. Read in
  full before writing this fix to confirm the exact call sites
  (`_is_unanalyzable_write_shape` in board-gate.sh,
  `UNANALYZABLE_WRITE_SHAPE` in scope-gate.py) and to confirm eval/
  script-file-argument were explicitly left open there (not silently
  reopened as "still fine to skip" here without re-checking).
- `core/hooks/board-gate.sh`, `warrant/hooks/lib/scope-gate.py`,
  `core/hooks/lib/gate-lib.py`, and their test suites as they stood at
  `8f95622` (branch base), read in full before writing this fix.

## Open findings

- **Quoted `-c`/`-e` flag word on a literally-named interpreter**
  (`python3 '-c' "open(...)"`) — found by hunt round 2. `head` resolves
  correctly to the literal `"python3"`, so this is NOT a single-token-
  expansion bypass (out of this issue's stated scope), but
  `gate_trailing_words`/`gate_lib.gate_trailing_words` never strips
  quote characters, so a quoted `'-c'` never string-equals `-c` in
  `INLINE_FLAG_WORDS`'s membership check (board-gate.sh), and
  scope-gate.py's `\s-[A-Za-z]*[ce]` alternative requires a literal
  space directly before `-`, which a preceding quote character breaks
  too. Not fixed here — resolution path: a future issue scoped to
  "-c/-e flag detection must be quote-aware", touching the same two call
  sites plus (for symmetry) `gate_lib.gate_wrapper_head_before`'s own
  `_WRAPPER_C_FLAG_RE`/`_PERL_E_FLAG_RE` matching, which has the same
  raw-token assumption.
- **Leading `VAR=value` assignment prefix defeats `gate_head_of`**
  (`FOO=1 python3 -c "open(...)"`) — found by hunt round 2.
  `gate_lib._resolve_transparent` returns the FIRST word of a segment
  immediately once it is not a member of `TRANSPARENT`, with no check
  for an `VAR=value` assignment shape — so `gate_head_of` resolves the
  head as the literal string `"FOO=1"`, never reaching `"python3"`, and
  every interpreter/IFS/expansion check that keys off `head` misses.
  This is a gap in the shared `gate_head_of`/`_resolve_transparent`
  primitive itself (`core/hooks/lib/gate-lib.py`), used by board-gate.sh
  AND gh-guard.sh — not a single-token-expansion bypass either (the head
  here is a literal, resolvable name once past the prefix), and fixing
  it touches shared infrastructure with call sites beyond this issue's
  two files. Not fixed here — resolution path: a future issue scoped to
  "`gate_head_of` must skip a leading `VAR=value` assignment the same
  way it already skips `TRANSPARENT` wrapper flags", with its own
  regression suite covering both callers.
- The pre-existing, already-known-open residuals from issue-227
  amendment 2 (an interpreter given a script FILE argument, e.g. `sh -x
  file.sh`; `eval` reached via a further layer of indirection beyond a
  single literal `eval` invocation) remain open, consistent with that
  amendment's own explicit decision not to claim them closed. Verified
  live via reproduction (see Test evidence) that `sh -x file.sh` is
  still allowed on the enforced-write-set path in both gates — this
  issue's acceptance criteria do not name that shape among the 4 to
  close, and it is not a single-token-expansion bypass.

## Test evidence

Before/after reproduction of the issue's exact 3 named shapes plus the
2 "prior non-blocking" ones, run against both gates with a real board
repo (role `qa`, branch `issue-3/qa`, `docs/specs/approvers.md` present)
and a real approved-proposal repo (write set `src/app.py`):

canonical: `bash /tmp/repro_board2.sh` output, BEFORE (`git stash`) vs
AFTER (working tree) —
```
BEFORE                                          AFTER
issue-shape-1-param-default-dash   -> allow     -> deny
issue-shape-2-param-default-equals -> allow     -> deny
issue-shape-3-cmdsub-produces-head -> allow     -> deny
issue-shape-4-eval                 -> allow     -> deny
issue-shape-5-sh-x-file            -> allow     -> allow (unchanged, out of scope)
foreign-bucket-param-default       -> allow     -> deny
```

canonical: `bash /tmp/repro_scope.sh` output, BEFORE vs AFTER —
```
BEFORE                                          AFTER
issue-shape-1-param-default-dash   -> allow     -> deny
issue-shape-2-param-default-equals -> allow     -> deny
issue-shape-3-cmdsub-produces-head -> deny (already, via a loose        -> deny
                                       non-head-anchored pre-existing
                                       match on "python3" anywhere)
issue-shape-4-eval                 -> allow     -> deny
issue-shape-5-sh-x-file            -> allow     -> allow (unchanged)
```

Adversarial hunt round 1 and 2 candidate commands, traced and verified
live against both gates before/after each fix — all now correctly
DENIED (7 candidates: nested command substitution, `${x:+...}`, bare
`${x-...}`, arithmetic-expansion-adjacent head, expanded-head+`$IFS`
combo, `$0` head, nested `${x:-${y:-...}}`, quoted `"$SHELL"`/backtick/
`$0` heads, generic (non-`$IFS`) whitespace-fusion variable) and 3
pure-read controls (`${HOME}/x`, `awk '{print}' file`, `grep "$PATTERN"
file -e extra`) all still correctly ALLOWED — derived: `bash
/tmp/hunt_board.sh`, `bash /tmp/hunt_board2.sh`, `bash /tmp/hunt_scope.sh`,
`bash /tmp/hunt_scope2.sh`.

Gate test suites, this branch, after both fix passes:

derived: `bash core/hooks/tests/run-board-gate-tests.sh`
```
== 157 passed, 2 failed ==
```
The 2 failures (`feasibility-spikes`, `ops-postmortems`) are pre-
existing — checked: identical failing-test-NAME set (not count) with
`git stash` applied (pre-fix) on this branch, and against a fresh
`git worktree add` of `origin/main` (commit `255867b`) — unrelated to
this issue's files.

derived: `bash core/hooks/tests/run-scope-gate-tests.sh`
```
== 60 passed, 0 failed ==
```

derived: `python3 -m pytest -q`
```
3 failed, 79 passed
```
checked: the exact same 3 failing test names
(`test_proposal_shape_gate_refuses_missing_sections`,
`test_survey_order_gate_refuses_proposal_without_survey_or_skip`,
`test_A5_trailer_gate_quote_split_commit_is_detected`) reproduce
identically against a fresh `origin/main` worktree — pre-existing, not
touched by this diff.

derived: `bash core/hooks/tests/run-all.sh`
```
board gate:            157 passed, 2 failed (pre-existing, above)
scope gate (warrant):  60 passed, 0 failed
approval gate:         65 passed, 2 failed (pre-existing: checked
                         identical against origin/main worktree)
gh guard:              54 passed, 0 failed
gate shape:            18 passed, 0 failed
role-agnostic gates:   83 passed, 0 failed
dispatcher-equivalence: 24 passed, 1 failed (pre-existing: checked
                         identical against origin/main worktree)
ups-diet:              35 passed, 1 failed (pre-existing on THIS BRANCH
                         with or without this diff -- checked via
                         `git stash`; origin/main itself shows 36/0
                         because this branch is 1 commit behind
                         origin/main's `255867b`, which trims board-
                         gate.sh's sidecar-read code the ups-diet byte
                         budget measures; that commit never touches
                         anything this issue's diff touches, and
                         run-ups-diet-tests.sh never renders/measures
                         board-gate.sh or scope-gate.py at all -- it
                         measures 7 unrelated UPS directive hooks)
fleet-scan (separately, not part of run-all.sh's own count):
                         26 passed, 1 failed (pre-existing: checked
                         identical against origin/main worktree)
```

No overhead: `bash /tmp/timing_test.sh` (100 board-gate.sh subprocess
runs against a representative call) — BEFORE (`git stash`) 43-44ms avg,
AFTER 43-44ms avg; dominated by python3 interpreter startup cost, no
measurable regex-cost delta. Source file byte growth (board-gate.sh
+1857 bytes, scope-gate.py +2192 bytes, mostly comments) does not affect
runtime and neither file is part of the UPS-injected/token-budget
surface (`run-ups-diet-tests.sh` measures 7 different directive hook
scripts, not these two).

Monitor/watch machinery: `bash core/hooks/tests/fleet-silent-failure-scan.sh`
and `core/hooks/tests/run-fleet-scan-tests.sh`/`run-fleet-scan.sh`
(covering `tests/test_silent_failure_repros.py` too, included in the
pytest run above) all ran clean or with the same pre-existing failure
set as origin/main — none disabled, none newly failing.

skill-verdict: secure-coding-input-validation-injection-defense —
applied: invoked; rule 2 (remove a denylist-as-sole-defense, keep only
as supplementary) informed keeping `FUSED_INTERP_RE`/`VAR_INTERP_RE`/
`INTERPRETER_HEADS` in place but no longer treating them as the primary
defense for this masking class; rule 8 (fail closed rather than a
silent partial-analysis fallback) matches the unconditional-deny design
for the new structural checks.
skill-verdict: adversarial-review — applied: invoked; two independent
fresh-context subagents (no access to this session's reasoning or
diff rationale, only the two source files + gate-lib.py) were used as
the acceptance criterion's required "adversarial hunt round" —
pass 1 found 2 real bypasses (fixed before landing), pass 2 found 0
further single-token-expansion bypasses (surfaced 2 different-class,
out-of-scope findings, logged above).
other mounted skills: work-in-english — not triggered (guidance-only
via core hook enforcement, not invoked directly by this session).

## Next steps

None — issue-233's acceptance criteria are met: all 4 named shapes deny
on the enforced-write-set path (bullet 4's `eval` sub-case fixed; its
`sh -x file.sh` sub-case is a documented, out-of-scope residual matching
issue-227's own precedent), pure-read forms stay allowed, both full
suites are green modulo pre-existing/unrelated failures verified
identical to origin/main, and two independent adversarial hunt rounds
found no remaining single-token-expansion interpreter-head bypass.
</content>
