---
issue: 233
role: secure-coding-input-validation-injection-defense-bcd7fd6a
author: secure-coding-input-validation-injection-defense-bcd7fd6a
skills: secure-coding-input-validation-injection-defense (skill-repository(c05de12))
verifies_subject: false
loop_state: landed
upstream:
  - path: docs/issue-233/reports/adversarial-review-a814c155.md
    sha: ea8c498f8ca6b4c16eb41ebfb10d29e6dfc3ed48
  - path: docs/issue-233/reports/adversarial-review-5c3fbc55.md
    sha: 7d4fea2e23439b8f3591f905af57d3a04f109361
code_under_review:
  - core/hooks/board-gate.sh
  - core/hooks/tests/run-board-gate-tests.sh
  - warrant/hooks/lib/scope-gate.py
  - core/hooks/tests/run-scope-gate-tests.sh
type: fix
breaking: "false"
verdict: pass
---

# issue-233 — secure-coding-input-validation-injection-defense-bcd7fd6a record

## What was done

`CORE_BUILD_NOW=1` was set by the spawner (build-now bypass, contract v3
s19a) — delivered directly, no phase-1 proposal round.

Closed the interpreter-head-via-single-token-expansion class generically
in both `core/hooks/board-gate.sh` and `warrant/hooks/lib/scope-gate.py`,
per the issue's own fix direction: a command head reached through ANY
single-token expansion (`${...}` including `:-`/`:=` defaults, `$(...)`,
backticks), when immediately followed by a `-c`/`-e`-shaped flag, is now
treated as an unanalyzable write-capable shape — the same bucket the
existing literal-interpreter-name check (`INTERPRETER_HEADS` in
board-gate.sh, the interpreter alternative of `UNANALYZABLE_WRITE_SHAPE`
in scope-gate.py) already denies unconditionally, regardless of what the
`-c`/`-e` string actually contains.

This is deliberately NOT the approach PR #367 took (per its own record
file, named secure-coding-input-validation-injection-defense-8c25e36e.md
under docs/issue-233/reports/ on PR #367's own unmerged branch — not
present on this branch, since #367 never merged; read via `git show`
against the fetched remote ref, not this working tree):
that PR narrowed `INLINE_FLAG_WORDS`/the flag regex to a per-head
allowlist of "the one flag each interpreter actually uses for inline
code", which round 5's independent adversarial review (PR #369,
`docs/issue-233/reports/adversarial-review-a814c155.md`) found
reintroduced a live false-allow: `perl -c` executes `BEGIN`/`UNITCHECK`/
`CHECK` blocks during its syntax check, so treating literal `perl -c` as
safe-to-allow is wrong. This delivery never touches `INLINE_FLAG_WORDS`,
`INTERPRETER_HEADS`, or the flag-letter regex for a LITERAL interpreter
head at all — the existing unconditional "any literal interpreter head +
`-c`/`-e` is unanalyzable" posture is left exactly as it was before PR
#367 (i.e. as it stands on `origin/main` today). The only new surface is
heads produced by an expansion, which is strictly additive and cannot
reopen the literal-head perl-c gap PR #367 introduced.

Added, in both files:
- `EXPANSION_HEAD_C_FLAG_RE` (board-gate.sh) / a new
  `UNANALYZABLE_WRITE_SHAPE` alternative (scope-gate.py): matches a
  segment/command position where the command head is entirely one of
  `${...}` (any inner form — `:-`, `:=`, `:+`, plain), `$(...)` (with one
  level of nested parens), a backtick span, or a bare `$VAR`, optionally
  wrapped in `"..."` (only single quotes make an expansion literal, so
  double-quoted expansions still need catching), immediately followed by
  a `-[A-Za-z]*[ce]`-shaped flag word.
- board-gate.sh: the check is applied directly on `stripped` (the
  already-resolved segment text) inside `_is_unanalyzable_write_shape`,
  independent of `gate_head_of`'s own naive `.split()`-based head
  resolution (which returns the whole `${...}` or the pre-space slice of
  `$(...)` as `head` — never a value `INTERPRETER_HEADS` would recognize,
  which is exactly why the bypass existed).
- scope-gate.py: the new alternative is added to the existing
  `UNANALYZABLE_WRITE_SHAPE` regex disjunction, alongside the
  already-present `FUSED_INTERP_RE`/`VAR_INTERP_RE`/IFS-token clauses.

Verified live against the real gate subprocesses (temp git repo,
`docs/specs/approvers.md` planted, branch `issue-3/qa`, `CLAUDE_SKILL=qa`
for board-gate.sh; an approved proposal file under a temp-repo
docs/proposals/ dir, status: approved, files: - src/app.py, for
scope-gate.sh — the same harness both `run()` functions in
`core/hooks/tests/run-board-gate-tests.sh`/`core/hooks/tests/run-scope-gate-tests.sh`
use) — before the fix, the three shapes named in the issue all ALLOWed:

```
derived: /tmp/repro-board.sh, /tmp/repro-scope.sh (this session's own harness,
identical structure to run-board-gate-tests.sh's/run-scope-gate-tests.sh's
own run() helpers), against the pre-fix working tree (git stash)
board: cd docs/issue-3 && ${x:-python3} -c '...'        -> allow (issue: ALLOW)
board: cd docs/issue-3 && ${x:=bash} -c '...'            -> allow (issue: ALLOW)
board: cd docs/issue-3 && $(echo python3) -c '...'       -> allow (issue: board ALLOW)
scope: ${x:-python3} -c '...'                            -> allow
scope: ${x:=bash} -c '...'                                -> allow
scope: $(echo python3) -c '...'                           -> deny (already caught by
  the existing literal-text regex's incidental match on the word "python3"
  appearing anywhere before " -c" — matches the issue's own note that only
  "board" ALLOWed shape 3, not "scope")
```

and after the fix, all three DENY on both gates, while `${HOME}/x` and
`awk '{print}' file` still ALLOW — reproduced with the same harness
against the patched working tree.

An adversarial hunt round (this session, before finalizing) additionally
found and closed: a bare unbraced `$VAR` head (`$x -c '...'`, no braces at
all — the same class with an even lighter spelling); a double-quoted
expansion head (`"${x:-python3}" -c '...'` — only single quotes make an
expansion literal, so wrapping it in double quotes does not defeat the
bypass and must not defeat the check either); a nested command
substitution (`$(printf %s $(echo python3)) -c '...'` — a real invocation
routinely nests one substitution inside another); a plain (non-fused)
backtick-produced head; and the `-e` flag spelling (perl/ruby/node's own
inline-code flag), not just `-c`. All five were confirmed live to ALLOW
before this round's fix and DENY after, on both gates, with no over-block
regression on the same two pure-read controls plus their quoted
equivalents (`cat "${HOME}/x"`, `cat "$(git rev-parse --show-toplevel)/README.md"`).

Test cases added to both `core/hooks/tests/run-scope-gate-tests.sh` and
`core/hooks/tests/run-board-gate-tests.sh`: the 4 shapes named in the
issue (param-default, param-assign, command-substitution-produced,
bare-var), the 4 hunt-round shapes (quoted, nested-cmdsub, backtick,
`-e`-flag), and 2-4 pure-read controls per file (unquoted and quoted
`${HOME}`/`$(...)` forms) — 12 new test cases in scope-gate's suite, 12
new in board-gate's suite (board-gate's set also threads `cd docs/issue-3
&&` and a real docs/-shaped write target through each case, matching that
file's existing test idiom).

acceptance: `bash core/hooks/tests/run-scope-gate-tests.sh` — result: `58
passed, 0 failed`
acceptance: `bash core/hooks/tests/run-board-gate-tests.sh` — result: `155
passed, 2 failed` (the 2 failures, `feasibility-spikes`/
`ops-postmortems`, reproduce identically with this session's changes
stashed — checked: `git stash && bash core/hooks/tests/run-board-gate-tests.sh
2>&1 | grep FAIL` prints the same two names on both the pre-fix and
post-fix tree, i.e. pre-existing and unrelated to this change)
acceptance: `bash core/hooks/tests/run-all.sh 2>&1 | grep -n "passed.*failed"`
— result: identical pass/fail counts on every OTHER suite in the file
before and after this change (checked the same way: `git stash` +
re-run), and the two gate suites this issue targets both show only
additional PASSING cases (46→58 for scope, 143→155 for board), zero new
failures.

## Why

The issue's own fix direction states the class should be closed
generically — "treat an interpreter head reached via ANY single-token
expansion ... followed by -c/-e as unanalyzable-write-shape ... regardless
of separator" — rather than adding a fourth enumerated spelling to
`INTERPRETER_HEADS`/`FUSED_INTERP_RE`/`VAR_INTERP_RE`, each of which is
itself the residue of enumerating one prior spelling (issue-227's
original interpreter-name list, then its fused-token-substitution fix,
then its variable-indirection fix). Three consecutive review rounds
(#227 R3, plus this issue's own opening) found the class leaking via a
new spelling each time specifically because those checks all require a
literal interpreter name to appear at a position the pattern looks at —
and a parameter-default/parameter-assign expansion or a command
substitution that PRODUCES the head never puts one there. The chosen fix
stops checking for named spellings and instead checks the SHAPE: "is the
command head entirely a single-token expansion, with no literal content a
pattern could special-case" — which by construction cannot miss a new
spelling, only a new *category* of expansion (of which bash has exactly
three: parameter expansion `${...}`/`$name`, command substitution
`$(...)`, and the deprecated backtick form — all three covered here).

Denying unconditionally, rather than trying to resolve what the expansion
actually evaluates to and only denying if it MIGHT be an interpreter, is
the same trade-off the existing literal-`INTERPRETER_HEADS` branch
already makes (`bash -c "echo hi"` — a syntactically pure read — is
already denied outright today, on `origin/main`, with no attempt to
parse the `-c` string's safety). Attempting content-aware resolution of
an expansion's value would require actually evaluating shell expansion
semantics (environment lookups, default-value fallback, subprocess
execution for `$(...)`) inside a gate that must stay a static text read —
disproportionate engineering for a check whose existing sibling case
already accepts the same fail-closed conservatism.

Rejected alternative: extending the existing enumerated-spelling
approach with a fifth pattern for parameter-default/assign forms
specifically (e.g. a regex anchored on `:-`/`:=` inside `${...}`).
Rejected because it repeats exactly the failure mode this issue is
about — the next round would find `${x:+python3}` (the fourth parameter-
expansion operator, not just `:-`/`:=`) or some other spelling this
narrower pattern does not cover. The generic any-single-token-expansion
check already subsumes `:-`, `:=`, `:+`, and plain `${x}` for free (it
does not inspect the expansion's inner syntax at all), which is exactly
what the issue asks for and what the adversarial-hunt round in this
delivery confirmed.

No change was made to how a LITERAL interpreter head's `-c`/`-e` is
classified (deliberately preserving the current unconditional-deny
posture PR #367 tried to narrow and that narrowing's own reviewer found
unsafe) — that axis is out of scope for this issue's title and fix
direction, which are both specific to the single-token-expansion class.

`eval '...'` and `sh -x file.sh`, named in the issue text as "prior
non-blocking" (i.e. already-known, already-allowed shapes, not new
findings this issue reports), were left out of scope: neither is a
single-token-expansion bypass — `eval` is a literal wrapper word already
visible in the command text (a different, already-tracked gap, not
"generically unanalyzable via expansion"), and `sh -x` uses the `-x`
trace flag, not `-c`/`-e`, to execute a script file (a different bypass
mechanism entirely: multi-token exec-via-flag, not head-masking). Fixing
either would exceed this issue's stated fix direction and is recorded
here as an explicit, disclosed scope boundary rather than silently
addressed or silently ignored.

skill-verdict: work-in-english — applied: invoked; used throughout this
session — code, tests, comments, commit, and this record are in English;
only this summary's closing user-facing note (none needed here, this is
a headless delivery) would have been Korean.
skill-verdict: test-derivation — applied: invoked; the issue's two
acceptance checks were treated as the requirement set and expressed as
Given-When-Then-style cases (the 4 named shapes + 4 hunt-round shapes as
"Given an approved/enforced write-set, When this command is submitted,
Then it is denied"; the pure-read forms as "..., Then it is allowed"),
now the test cases added to both suites. Classified Low/Medium risk per
the skill's Step 3a (a single boolean allow/deny gate check per input
shape, not a multi-condition business rule or state machine), so the
full decision-table/pairwise/MC/DC machinery was scoped out as
inapplicable depth for this requirement shape — EP/BVA-style shape
enumeration (one case per distinct expansion form, plus explicit
pure-read controls) was the fitting technique and was applied.
skill-verdict: defect-verification-independence-from-upstream-verdicts —
not-applicable: this session is delivering a fresh fix, not re-verifying
a review requirement already marked Present/closed against this same
change; the independent-verification role for this delivery is a
separate downstream adversarial-review session, per this issue's own
established pattern (PRs #355/#356/#359/#362/#364/#365/#368/#369).
other mounted skills: not triggered.

## What did not work

None. The generic single-token-expansion-head check, once shaped as "is
the command head entirely an expansion, followed directly by a
`-c`/`-e`-shaped flag" rather than as another enumerated spelling, closed
all three issue-named shapes plus all four hunt-round shapes found in
this session on the first pass, with no false-allow or over-block
iteration needed on either gate.

## Upstream basis

- Issue #233 (`gh issue view 233`) — the fix direction text this
  delivery follows verbatim ("treat an interpreter head reached via ANY
  single-token expansion ... followed by -c/-e as unanalyzable-write-
  shape ... regardless of separator").
- `docs/issue-233/reports/adversarial-review-a814c155.md` (PR #369,
  merged; sha above) — the perl-`-c` blocking finding against PR #367's
  per-head-allowlist approach, read to confirm this delivery's chosen
  approach (purely additive, no change to literal-head flag handling)
  cannot reopen that same regression.
- `docs/issue-233/reports/adversarial-review-5c3fbc55.md` (PR #368,
  merged; sha above) — round 5's own verification record, read for the
  same reason (confirms what PR #367 changed, so this delivery could
  verify it changes none of that).
- `core/hooks/board-gate.sh` and `warrant/hooks/lib/scope-gate.py`
  (`origin/main` state, i.e. this branch's own pre-change content — PR
  #367/#363 are both unmerged, so `origin/main` carries none of their
  changes), read in full before constructing any probe or edit.
- `core/hooks/tests/run-board-gate-tests.sh` and `core/hooks/tests/
  run-scope-gate-tests.sh`, read in full to match each file's existing
  test idiom (harness shape, `$BOARD` variable, quoting conventions) for
  the new cases added here.

## Open findings

None blocking. `eval '...'`/`sh -x file.sh` (see Why, above) are a
disclosed, deliberate scope boundary, not a gap silently left in this
delivery's own claimed class — tracking either would need a new issue
scoped to that different bypass mechanism (literal-wrapper-word
masking / exec-via-trace-flag), not an extension of this one.

## Next steps

None — `loop_state: landed`. Both suites green (acceptance lines above);
the pre-existing `feasibility-spikes`/`ops-postmortems` board-gate
failures and every other suite in `run-all.sh` are unchanged by this
change (checked via `git stash` comparison, acceptance line above).
