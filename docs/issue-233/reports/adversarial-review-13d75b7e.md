---
issue: 233
role: adversarial-review-13d75b7e
author: adversarial-review-13d75b7e
skills: adversarial-review (skill-repository(c05de12))
verifies_subject: true  # flip to true only if this record is an independent verification of this subject's own deliverable -- see docs/handbooks/observer-verification.md
loop_state: landed
upstream:
  - path: core/hooks/lib/gate-lib.py
    sha: 83c6b1717b3540aa8baae61553cd1add4df0c8aa
  - path: core/hooks/board-gate.sh
    sha: 83c6b1717b3540aa8baae61553cd1add4df0c8aa
  - path: warrant/hooks/lib/scope-gate.py
    sha: 83c6b1717b3540aa8baae61553cd1add4df0c8aa
---

# issue-233 — adversarial-review-13d75b7e record

## What was done

freelunch tally: 1 unit (this review), sequential and non-parallelizable
— each probe's construction depends on reading the prior probe's live
result (oracle diff finding informs which gate-level reproduction to try
next, which informs the live-execution follow-up). Width 1 -> solo, no
fan-out. All tool calls this session were direct Bash/Read/Write in this
same foreground turn, per contract v3 s22 (this is a headless,
single-shot session; s22 outranks the general repo/env-call delegation
default when a background worker's result could not be consumed before
the turn ends) and per the warrant-directive's own explicit statement
that s22 is higher priority than that default here.

Independently verified PR #360 (`issue-233: word-formation-aware head
tokenizer (re-delivery after PR #358 CHANGES)`, head `83c6b17`, base
`main`), the third delivery on issue-233 after PR #354 (CHANGES) and PR
#358 (CHANGES). The fix under review replaces `gate_lib.
_resolve_transparent`'s naive `segment.split()` with a new `_shell_split`
tokenizer aware of backslash-escaped whitespace, quoted spans (`'...'`,
`"..."`, `$'...'`, `$"..."`), and backslash-newline splicing, so word
formation is legible to the analyzer before `EXPANDED_HEAD_RE`/
`INTERPRETER_HEADS` ever inspect a "head" word.

canonical: `gh pr view 360` (state: OPEN, base `main`, head `83c6b17`,
`Closes #233`)

Set up two worktrees for direct, live comparison: `/tmp/pr360-wt` (PR
#360 head, `83c6b17`) and `/tmp/main-wt` (`origin/main`, `8f82765`). Built
a standalone oracle harness (`/tmp/probe233/run_probe.sh`) that feeds an
identical raw segment string to (a) real bash, via `set -- <segment>;
for a in "$@"; do printf '<%s>\n' "$a"; done` (bash's own word-splitting
applied to literal text, the same operation `_shell_split` claims to
replicate), and (b) a byte-for-byte extracted copy of `_shell_split`
(`_WORD_TOKEN_RE` plus its driving loop), so every claim below is a
direct bash-vs-tokenizer diff, not a read of the source alone.

Since the task named that the previous round found both an over-refusal
and an under-refusal, both directions were re-probed at two levels: the
tokenizer in isolation (oracle harness) and the actual `board-gate.sh`
subprocess (`env CLAUDE_SKILL=qa /bin/bash core/hooks/board-gate.sh` fed
a real JSON payload, exit 0 = allow / exit 2 = deny), because a
tokenizer-level mismatch only matters if it flips a real verdict.

### Probe matrix (oracle harness: real bash vs `_shell_split`)

| case | segment | bash | `_shell_split` | match |
|---|---|---|---|---|
| nested quotes | `"foo'bar'baz"` | `foo'bar'baz` | `foo'bar'baz` | yes |
| unclosed quote | `python3 'unclosed -c evil` | syntax error, never runs | `[python3, unclosed, -c, evil]` | n/a (bash never executes this line at all, so no live divergence is reachable) |
| adjacent quote/unquote concat | `foo"bar"baz` | `foobarbaz` | `foobarbaz` | yes |
| backslash in single quotes | `'\n'` | `\n` (literal, not an escape) | `\n` | yes |
| backslash in double quotes, non-special char | `"\n"` | `\n` (backslash preserved, `n` isn't escapable) | `\n` | yes |
| backslash in double quotes, a special char (`"`) | `"\""` | `"` (backslash consumed, quote survives alone) | `\"` (backslash NOT consumed) | **no** |
| `$"..."` locale string | `$"hello world"` | `hello world` | `hello world` | yes |
| odd backslash run before a quote (3) | `foo\\\'bar` | `foo\'bar` | `foo\'bar` | yes |
| even backslash run before a quote (2), quote protects a space | `foo\\'bar baz'qux` | `foo\bar bazqux` (ONE word) | `foo\bar`, `bazqux` (TWO words) | **no** |
| even backslash run before a quote (4) | `foo\\\\'bar baz'qux` | `foo\\bar bazqux` (ONE word) | `foo\\bar`, `bazqux` (TWO words) | **no** |
| adjacent double-quoted spans, space inside both | `"a b"c"d e"` | `a bcd e` | `a bcd e` | yes |
| backtick command substitution | `` `echo -c` `` | `-c` (one word, substitution output) | `` `echo``, ``-c` `` (two words, backtick untokenized) | **no** |
| here-string | `cat <<< "hi"` | `cat` (redirection, not an argument) | `[cat, <<<, hi]` | n/a — `<<<` is a redirection operator, not a word-formation mechanism `_shell_split` is meant to model; expected divergence, outside this issue's threat model |

derived: `bash /tmp/probe233/run_probe.sh <case> <segfile>` for each row
(oracle script: `set -- <segment>` then `for a in "$@"; do printf
"<%%s>\n" "$a"; done`, against `python3 /tmp/probe233/shell_split.py`
loaded with the exact `_WORD_TOKEN_RE`/driving-loop body from
`core/hooks/lib/gate-lib.py` at `83c6b17`)

Root cause of the two "no" rows that matter (double-quote-special-escape,
even-backslash-before-quote): `_shell_split`'s quote-open alternatives use
`(?<!\\)` to detect "is this quote escaped" — a negative lookbehind
against the raw source string. That lookbehind only sees "is there a
literal backslash character immediately before this position," not "is
that backslash still live after an odd/even number of backslashes paired
off before it." An ODD backslash run before a quote works by accident:
the regex's own `\\.` alternative consumes the last backslash together
with the quote character as one token before the quote is ever considered
as a separate match-start position, so the lookbehind is never consulted.
An EVEN run does not get that accident: after the pairs are consumed two
at a time, the position immediately before the quote still holds a raw
backslash character in the source text (from the last pair), so
`(?<!\\)` fires and refuses to open the quote — even though bash, having
fully paired off that run, treats the quote as live. The double-quote
"backslash before a special char" mismatch is a related but distinct gap:
`_shell_split` matches the whole `"..."` span as one token and then just
does `token[1:-1]` to strip the outer quotes, without walking the
interior to collapse a backslash against one of the five bash-recognizes
double-quote specials (`$`, `` ` ``, `"`, `\`, newline) the way real bash
does; the outer regex's own `\\.` alternative inside the quoted-span
character class exists only to keep the span parser from ending early at
an escaped quote, not to un-escape the content afterward.

### Under-refusal: command-substitution-produced FLAG word (new, confirmed live)

`_WORD_TOKEN_RE` has a dedicated alternative for `'...'`, `"..."`,
`$'...'`, and `$"..."` — every quoting form is tokenized as one word
regardless of internal whitespace — but **no alternative for `$(...)` or
`` `...` `` at all**. Both fall through to the generic `\S` alternative,
so a command-substitution span is split at any internal whitespace like
plain unquoted text. This does not defeat interpreter-*head* detection
(`EXPANDED_HEAD_RE`'s `[^A-Za-z0-9_./+=@:-]` complement fires on the
literal `$`/backtick character in the fragment regardless of what the
substitution evaluates to), but it does defeat the **flag-word** check,
because `INLINE_FLAG_WORDS` is exact-string membership
(`w in ("-c", "-e")`) applied to `gate_trailing_words`, which shares the
same `_shell_split` fragmentation. When a substitution PRODUCES the flag
word itself (rather than the head), the resulting fragment
(`` `echo`` + `` -c` `` in the tokenizer) never equals the literal string
`"-c"`, so the flag check never fires — while real bash, evaluating the
substitution first, passes plain `-c` as its own word.

Confirmed live (real execution, not just the oracle harness) with both
substitution syntaxes and both flags issue-233 cares about:

```
derived: rm -f /tmp/pwn_test.txt; bash -c 'python3 `echo -c` "open(\"/tmp/pwn_test.txt\",\"w\").write(\"BACKTICK\")"'; cat /tmp/pwn_test.txt
BACKTICK
derived: rm -f /tmp/pwn_test.txt; bash -c 'python3 $(echo -c) "open(\"/tmp/pwn_test.txt\",\"w\").write(\"DOLLARPAREN\")"'; cat /tmp/pwn_test.txt
DOLLARPAREN
derived: rm -f /tmp/pwn_test.txt; bash -c 'perl `printf %s -e` "open(FH,\">/tmp/pwn_test.txt\");print FH \"PERLBACKTICK\""'; cat /tmp/pwn_test.txt
PERLBACKTICK
derived: rm -f /tmp/pwn_test.txt; bash -c 'perl $(printf %s -e) "open(FH,\">/tmp/pwn_test.txt\");print FH \"PERLDOLLARPAREN\""'; cat /tmp/pwn_test.txt
PERLDOLLARPAREN
```

(the `echo -c` form works because `echo` has no `-c` option and prints it
literally; `echo -e` would be swallowed as echo's own escape flag, so the
`-e` variants use `printf %s -e` instead — a test-harness detail, not a
gate behavior difference.)

And confirmed at the actual `board-gate.sh` level, using the same
CLAUDE_SKILL=qa / `docs/issue-3` fixture convention the PR's own test
file uses for the sibling shapes it fixed:

```
derived: env CLAUDE_SKILL=qa /bin/bash /tmp/pr360-wt/core/hooks/board-gate.sh <<< payload, tool_input.command = 'cd docs/issue-3 && python3 `echo -c` open("reports/qa/pwn.md","w").write("1")'
exit 0 (ALLOW)
derived: same harness, command = 'cd docs/issue-3 && python3 $(echo -c) open("reports/qa/pwn.md","w").write("1")'
exit 0 (ALLOW)
derived: same harness, command = 'cd docs/issue-3 && perl $(printf %s -e) "open(FH,\">reports/qa/pwn.md\");print FH 1"'
exit 0 (ALLOW)
derived: same harness, command = 'cd docs/issue-3 && perl `printf %s -e` "open(FH,\">reports/qa/pwn.md\");print FH 1"'
exit 0 (ALLOW)
```
(full harness at `/tmp/probe233/probe_gate.sh`; the identical fixture
with `$(echo python3) -c ...` — substitution producing the HEAD instead
of the flag — correctly DENIES, confirming the gap is specific to the
flag position)

No existing test in `run-board-gate-tests.sh` or `run-scope-gate-tests.sh`
covers a substitution-produced flag word (`grep -n "produces.flag" ...`
on both PR #360 files: no hits) — this is not a re-report of a disclosed,
accepted gap. Command substitution (`$(...)`, `` `...` ``) is one of the
three single-token-expansion mechanisms the issue names by title
(`${...}`, `$(...)`, backticks); this PR closes it generically for the
head position but not for the flag position it feeds into the same `-c`/
`-e` check.

### Other tokenizer mismatches probed, not shown to change a verdict

The even-backslash-before-quote word-split corruption (table above) is a
real, reproducible bug in the same tokenizer this issue hardens, but
every construction tried that fed it into an actual `-c`/`-e` gate
decision produced a word that ALSO differs from a literal `-c`/`-e` in
real bash's own resolution (e.g. `python3 -c\\' ' open(...)` resolves in
real bash to the word `-c\ ` (`derived: bash -c 'for a in python3 -c\\'"'"' '"'"' "open(1)"; do printf "<%s>\n" "$a"; done'`
→ `<python3>`, `<-c\ >`, `<open(1)>`) — not the literal flag `-c` either
way, so the gate's ALLOW there is correct, not a bypass. Not chased
further as a standalone finding; recorded because the task asked for
"what bash produces versus what `_shell_split` produces" on this exact
shape and the mismatch is real even though it isn't independently
exploitable in the constructions tried.

### ANSI-C `$'-c'` fix (this PR's own disclosed before-landing hunt catch)

Re-verified fixed: `_WORD_TOKEN_RE`'s `$'...'`/`$"..."` alternatives are
ordered before the bare-`'`/`"` and generic `\S` alternatives, so the `$`
is consumed as part of the quote-opening token rather than fused onto it
as a bare character.

```
derived: env -u CLAUDE_PLUGIN_ROOT_CORE bash /tmp/pr360-wt/core/hooks/tests/run-board-gate-tests.sh 2>&1 | grep ansi-c
ok     ansi-c-quoted-flag-word            deny
ok     ansi-c-quoted-head-no-flag-not-overblocked allow
```

Hunted sibling forms: `$"-c"` (the locale-string sibling of the fixed
`$'-c'` ANSI-C form) — correctly denied, since `_WORD_TOKEN_RE` gives
`$"..."` the same dedicated alternative as `$'...'`:

```
derived: probe_gate.sh localestr-produces-flag: command 'cd docs/issue-3 && python3 $"-c" open("reports/qa/pwn.md","w").write("1")'
got=deny (matches want=deny)
```

### Over-refusal direction: the PR #354-allowed / PR #358-denied case

Re-derived (not re-stated) that this PR's own claimed fix holds, against
the exact shapes the prior round's review reported live:

```
derived: probe_gate.sh sanity-cmdsub-produces-head: 'cd docs/issue-3 && $(echo python3) -c open("reports/qa/pwn.md", "w")'
got=deny
derived: probe_gate.sh sanity-quoted-path-spaces: 'cd docs/issue-3 && "/opt/My Python/python3" -c open("reports/qa/pwn.md", "w").write("1")'
got=deny
```

Both DENY (the escaped-space/quoted-path interpreter-head-with-flag
shapes are correctly caught now), and the full test suite's own
`escaped-space-interpreter-path-no-flag-not-overblocked` /
`quoted-path-with-spaces-no-flag-not-overblocked` /
`safe-set-unusual-char-path-no-flag-not-overblocked` cases all pass
(`174 passed, 2 failed` — see Standing invariants), so the same paths
without a `-c`/`-e` flag are not over-blocked. No new over-refusal
regression was found in this round: the full `run-board-gate-tests.sh`
suite's failing-name SET is identical to `origin/main`'s (see below), so
no previously-passing case (including every PR #354/#358 case folded
into this same file) newly fails under PR #360.

## Why

The task specified probing exactly where a shell-quoting parser's
correctness claims are most likely to be wrong: nested/unbalanced quotes,
concatenation boundaries, and backslash-parity edge cases, in both
directions (over- and under-refusal), verified at the real gate level
rather than the tokenizer in isolation — because a tokenizer bug only
matters operationally if it flips an actual allow/deny verdict on a live,
executable command. Building a bash-oracle harness rather than reasoning
from the regex alone was necessary because several of the mismatches
(the even-backslash lookbehind gap, the double-quote escape-collapse gap)
are non-obvious from reading `_WORD_TOKEN_RE` cold and only surface by
diffing against real bash's own parse.

## What did not work

- Constructed `python3 -c\\' ' open(...)` expecting the even-backslash
  word-split bug to hide a live `-c` bypass; it does not — real bash
  itself resolves that word to `-c\ ` (with a trailing backslash-space),
  not the literal flag `-c`, so the gate's ALLOW verdict there is correct
  behavior, not a finding. Caught before reporting by re-deriving the
  oracle's own word-split for that exact string rather than trusting the
  gate-level ALLOW alone.
- First attempt at a live `perl -e` command-substitution reproduction
  used `` `echo -e` ``/`$(echo -e)`; both produced an empty string at
  runtime because `-e` is `echo`'s OWN flag (enable backslash-escape
  interpretation) when it is the sole argument, not literal output text —
  a test-harness artifact, not a gate behavior difference. Switched to
  `printf %s -e` to get a literal `-e` string from the substitution, which
  reproduced the live bypass correctly.

## Standing invariants

1. **No return of the retired role/역할 axis**: `git diff origin/main
   pr-360 -- core/hooks warrant/hooks | grep -E '^\+' | grep -iE
   '\brole\b|역할'` returns exactly one line, a prose comment (`a
   `qa`-role call denied nothing while writing outside `qa`'s own
   write-set`) using "role" as an English word describing the `qa`
   `CLAUDE_SKILL` identity used throughout this test suite already — not
   a reintroduced `role`/`역할` code identifier or persisted key.

2. **No new bug — failing-test-name SETS vs `origin/main`, not counts**:
```
derived: env -u CLAUDE_PLUGIN_ROOT_CORE bash core/hooks/tests/run-board-gate-tests.sh
pr-360 (83c6b17): 174 passed, 2 failed — {feasibility-spikes, ops-postmortems}
main   (8f82765): 143 passed, 2 failed — {feasibility-spikes, ops-postmortems}
derived: env -u CLAUDE_PLUGIN_ROOT_CORE bash core/hooks/tests/run-scope-gate-tests.sh
pr-360: 76 passed, 0 failed
main:   46 passed, 0 failed
derived: env -u CLAUDE_PLUGIN_ROOT_CORE python3 -m pytest -q
pr-360: 3 failed, 79 passed — {test_proposal_shape_gate_refuses_missing_sections, test_survey_order_gate_refuses_proposal_without_survey_or_skip, test_A5_trailer_gate_quote_split_commit_is_detected}
main:   3 failed, 79 passed — identical name set
```
   All three suites' failing-name sets are byte-identical to
   `origin/main`; PR #360 adds tests (board-gate: 174 vs 143, scope-gate:
   76 vs 46) but introduces zero new failures.

3. **No overhead increase**:
```
derived: 100x subprocess timing, `cat review.md` payload, CLAUDE_SKILL=qa
main   (8f82765):  4891ms / 100 = 48ms/call
pr-360 (83c6b17):  4968ms / 100 = 49ms/call
```
   1ms/call difference over 100 runs is noise, consistent with the PR's
   own claimed ~50ms vs ~46ms.

4. **Monitor/watch machinery unbroken and not quieter**:
```
derived: bash core/hooks/tests/run-fleet-scan-tests.sh
main:   pass=26 fail=1 — "live fleet run produces 43 repo rows" want=43 got=44
pr-360: pass=26 fail=1 — identical failing case, identical want/got
```
   Same pass count, same single pre-existing flake, not quieter.

## Out-of-scope disclosures — confirmed accurate, left alone per task instruction

- **`board-gate.sh`'s `*docs*`-substring fast-path (core#361)**:
```
derived: gh issue view 361 --repo tokenmaxxxer/tokenmaxxxer-core
title: board-gate's *docs* substring fast-path skips the entire gate, including #225's unanalyzable-write deny
state: OPEN
derived: grep -n 'case "\$payload"' -A3 /tmp/main-wt/core/hooks/board-gate.sh
case "$payload" in
  *'\u'*) ;;
  *docs*) ;;
  *) trap - EXIT; exit 0 ;;
```
   Pre-existing on `origin/main` (not introduced by PR #360), matches
   issue #361's description exactly. Confirmed accurate; not chased, per
   the task's explicit instruction and because it predates and is
   orthogonal to issue-233's word-formation class.

- **`warrant/hooks/lib/scope-gate.py` has no flag-word tokenizer**:
```
derived: env -u CLAUDE_PLUGIN_ROOT_CORE bash core/hooks/tests/run-scope-gate-tests.sh 2>&1 | grep preexisting-gap
ok     absolute-path-interpreter-c-flag-not-caught-preexisting-gap allow
ok     ansi-c-quoted-flag-word-not-caught-preexisting-gap allow
```
   Both disclosed-gap tests pass with `allow` (the gap is real and
   present), and the surrounding comments in
   `core/hooks/tests/run-scope-gate-tests.sh:397-424` correctly attribute
   this to PR #354's original disclosure, extended to the `$'...'` form.
   Confirmed accurate; left alone.

## Upstream basis

- `core/hooks/lib/gate-lib.py` @ `83c6b17` (PR #360 head) — `_shell_split`,
  `_WORD_TOKEN_RE`, `_resolve_transparent`
- `core/hooks/board-gate.sh` @ `83c6b17` — `EXPANDED_HEAD_RE`,
  `INTERPRETER_HEADS`, `INLINE_FLAG_WORDS`, the deny branch at the
  `head in INTERPRETER_HEADS or EXPANDED_HEAD_RE.search(head)` check
- `warrant/hooks/lib/scope-gate.py` @ `83c6b17` — disclosed-gap coverage
  only, not independently re-derived beyond the test-suite check above
- `gh pr view 360`, `gh issue view 233`, `gh issue view 361` (canonical,
  read live during this session)

## Open findings

1. **BLOCKING — under-refusal: a command substitution (`$(...)` or
   `` `...` ``) that PRODUCES the `-c`/`-e` flag word evades
   `INLINE_FLAG_WORDS` entirely, while the identical mechanism producing
   the HEAD is correctly denied.** `_WORD_TOKEN_RE` has no dedicated
   token form for `$(...)`/backtick spans (unlike its four quote forms),
   so a substitution is split at internal whitespace like plain text; the
   resulting fragment never equals the literal string `"-c"`/`"-e"`.
   Confirmed live with real command execution (`python3` + `-c` via both
   substitution syntaxes, `perl` + `-e` via both syntaxes) and confirmed
   at the actual `board-gate.sh` subprocess level using the PR's own test
   fixture conventions. This is one of the three single-token-expansion
   mechanisms the issue names by title, on the flag side rather than the
   head side the PR fixed — a residual, same-class survivor, meaning the
   issue's second acceptance criterion ("an adversarial hunt round finds
   no remaining single-token-expansion interpreter-head bypass") is not
   met. Resolution path: give `_WORD_TOKEN_RE` a balanced-paren/backtick
   token form (or, more conservatively, treat ANY unresolved `$(`/`` ` ``
   appearing in a trailing word as itself unsafe/unanalyzable, the same
   structural complement `EXPANDED_HEAD_RE` already applies to the head,
   rather than trying to evaluate what the substitution produces). Not
   fixed by this session — this session's role is verification, and PR
   #360's branch is not this session's write scope.

2. **Non-blocking — two further `_shell_split` correctness bugs, not
   shown to change a live verdict.** (a) An even-length backslash run
   immediately preceding a quote character is misclassified as "escaped"
   by the `(?<!\\)` lookbehind (which checks raw adjacency, not
   backslash-run parity), so the quote fails to open where real bash
   would open it — corrupts word *boundaries* (one bash word becomes two
   tokenizer words). (b) Inside a double-quoted span, a backslash before
   one of bash's five double-quote-specials (`$`, `` ` ``, `"`, `\`,
   newline) is preserved verbatim by `token[1:-1]` instead of being
   collapsed the way real bash collapses it. Both are genuine deviations
   from bash's real quoting semantics in code this issue specifically
   hardens against exactly this class of deviation, but no construction
   tried in this session turned either into an interpreter-head/flag
   verdict flip — see "What did not work" for the closest attempt and why
   it doesn't qualify. Recommend a regression test for each so a future
   round doesn't have to re-derive the oracle diff from scratch, but not
   blocking against this issue's literal acceptance criteria.

3. **Standing invariants**: all four (role axis, failing-test-name-set
   parity, overhead, monitor/watch machinery) hold — see Standing
   invariants above for full derivations. Both out-of-scope disclosures
   (board-gate.sh docs fast-path / core#361, scope-gate.py's missing
   flag-word tokenizer) are accurate and correctly left alone.

## Next steps

None from this session for the invariant/disclosure checks — those are
settled (`loop_state: landed`). **Recommendation to whoever lands or
re-reviews PR #360**: finding 1 (command-substitution-produced flag word)
is a live, confirmed bypass reachable on the exact enforced-write-set
path issue-233's acceptance criteria target, in the same class the issue
names by title — it should be closed before this issue is treated as
safely resolved, the same way the prior two rounds' findings were. Do not
merge PR #360 as closing #233 as-is; a fourth delivery addressing finding
1 is warranted. Finding 2 is a correctness/regression-coverage
recommendation, not a blocker.

skill-verdict: adversarial-review — applied: invoked; this session is
structurally independent of PR #360's builder session (separate role
session, no access to the builder's own reasoning trace), and every
load-bearing claim above was re-derived rather than restated: the bash-
vs-tokenizer oracle diff for 13 distinct quoting/escaping shapes, the new
command-substitution-flag bypass (live-executed, not inferred from
reading the regex), the ANSI-C-fix re-verification, the four standing
invariants (as failing-test-name sets, not restated counts), and both
out-of-scope disclosures (independently confirmed via `gh issue view 361`
and the disclosed-gap test outputs) — satisfying the skill's Step 5
argument-evidence requirement (every finding cites a `derived:`
reproduction or `canonical:` read).
other mounted skills: work-in-english — its guidance was followed anyway
(this record, all commands, and the PR description are written in
English throughout) without a separate Skill tool call, matching the
prior adversarial-review-e95fc262 record's precedent for this skill.
model-routing — not-applicable: this is a single-session, sequential
investigative review where each probe's construction depends on the
prior probe's result (oracle diff -> targeted gate-level reproduction ->
live execution); there is no independent, parallelizable unit of work to
route to a separate executor tier.
