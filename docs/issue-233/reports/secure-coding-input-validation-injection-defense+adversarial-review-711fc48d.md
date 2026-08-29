---
issue: 233
role: secure-coding-input-validation-injection-defense+adversarial-review-711fc48d
author: secure-coding-input-validation-injection-defense+adversarial-review-711fc48d
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
  - path: docs/issue-233/reports/adversarial-review-31f68317.md
    sha: b4c568312a7d5e32e19921e905132adfabe76c1a
---

# issue-233 — secure-coding-input-validation-injection-defense+adversarial-review-711fc48d record

## What was done

Re-delivered PR #354's fix for issue-233 after it came back CHANGES
(review: `gh pr view 354 --json comments` — canonical, comment id
`IC_kwDOTk3ZJs8AAAABRbUHjQ`). Rebased PR #354's two commits
(`a18a530`, `6e53b58`) onto current `origin/main` (`b4c5683`, which
already contains the merged independent verification record
`docs/issue-233/reports/adversarial-review-31f68317.md`) via
`git cherry-pick a18a530 6e53b58` — canonical: the cherry-pick applied
with only an automerge on `core/hooks/board-gate.sh`/
`run-board-gate-tests.sh`, no conflict, confirming the verification
record's Finding 6 (the apparent `"role"`-key reintroduction was a
raw-diff artifact of a stale base, not a real conflict).

That review named two live, reproduced counterexamples to PR #354's
"generic, no enumeration needed" claim (brace expansion with null-field
removal, quote-splicing) and asked this session to pick one of two
resolutions explicitly. **Resolution chosen: widen the structural check
from expansion to shell WORD FORMATION**, not narrow the genericity
claim — the issue's own fix direction already commits to closing this
class by structure rather than by enumerating spellings, and the two
reported counterexamples are still single-token word-formation
mechanisms, not a fundamentally different class (unlike the
shell-function-shadowing/PATH-indirection finding, correctly ruled out
of scope).

Three code commits landed the widening, each driven by a fresh
adversarial hunt round before moving to the next:

1. `0c60a55` — PR #354's original fix, unchanged: `$`/backtick
   structural check (`EXPANDED_HEAD_RE`), `eval` added to the
   unconditional unanalyzable-heads bucket, 12+10 new tests.
2. `68181aa` — closes the two review-reported findings (brace
   expansion, quote-splicing) by widening `EXPANDED_HEAD_RE`/
   `EXPANDED_HEAD_FUSED_FLAG_RE` (board-gate.sh) and the two matching
   `UNANALYZABLE_WRITE_SHAPE` alternatives (scope-gate.py) from a
   `` [`$] `` character class to `` [`$'"{}] ``. 6 new tests per gate
   (12 total): 3 DENY reproductions of the two findings, 3 negative
   controls (quoted/braced head with no `-c`/`-e` flag; braces in an
   `awk` PROGRAM ARGUMENT, not the head).
3. `736b957` — a background adversarial hunt agent (round 3, blind to
   this fix's rationale, told only the two source files plus
   `gate-lib.py` and the specific class to test) found two MORE live
   bypasses of the round-2 fix: a mid-word backslash escape
   (`p\y\t\h\o\n3 -c ...`) and a backslash-newline line continuation
   (`pyth\`-newline-`on3 -c ...`), both confirmed with real execution
   (a marker file actually written) before being reported. Rather than
   enumerate a sixth character, this commit flips the check from a
   DENYLIST of suspicious characters to an ALLOWLIST-complement of safe
   path/word characters (`[^A-Za-z0-9_./+=@:-]` in board-gate.sh,
   applied to the already-tokenized `head`), which is provably terminal
   against the whole class of "a single unsafe character in the head"
   rather than the next enumerable spelling. The backslash-newline case
   additionally required a structural fix, not just a wider character
   class: board-gate.sh's own segment splitter (`_split_segments`)
   treated every literal `\n` as a hard separator regardless of a
   preceding backslash, mis-splitting the continued line into two
   segments before the head-safety check ever ran, so it never saw the
   `-c` flag and the tainted head in the same segment. Fixed with an
   odd/even trailing-backslash count (mirroring real bash's own
   line-continuation rule) in the splitter; scope-gate.py has no
   segmenter at all, so it gets an equivalent `_splice_line_continuations()`
   preprocessing step ahead of its regex scan instead. 5 new tests per
   gate: 2 DENY reproductions (backslash-escape, backslash-newline), 1-2
   negative controls (a functionless backslash-escaped head, no `-c`).

A fourth round (background `warrant:warrant-hunter` agent, dispatched
before landing per the warrant protocol, prompted specifically to hunt
for a silent failure or composition regression at this exact
work-unit transition rather than a full re-hunt of the security class)
was in flight at record-assembly time; see Next steps / Open findings
for its outcome if it lands after this record's initial write.

## Why

The issue's own fix direction is explicit: close the interpreter-head
masking class "generically instead of enumerating more spellings" — the
same lesson issue-2600/issue-2670/issue-349 already applied to the
retired role/역할 axis, cited in the code's own comments. The review on
PR #354 offered two legitimate resolutions (widen to word formation, or
keep the narrower check and withdraw the genericity claim) and was
explicit that delivering the SAME pairing again (a genericity claim plus
a live counterexample) would not be accepted. Narrowing the claim was
considered and rejected: the two reported counterexamples (brace
expansion, quote-splicing) are not a structurally different class from
what issue-233 already names (`${...}`, `$(...)`, backticks) — all of
them are single-token shell WORD FORMATION producing a resolvable
interpreter head the gate cannot read literally. Narrowing the claim
here would have meant re-opening this exact issue again on the next
adversarial round, the same closed-set trap the issue exists to retire.

The `secure-coding-input-validation-injection-defense` skill's rule 2
(a denylist filter proposed as the SOLE defense against injection should
not remain the primary control) directly informed the round-3 pivot from
an enumerated character denylist to a safe-character allowlist: after
two rounds each found one more special character an enumeration missed
(quotes/braces round 2, then backslash round 3), continuing to add
characters one at a time is the same denylist-as-sole-defense anti-
pattern rule 2 warns against, just one level of abstraction up from
enumerating interpreter NAMES. An allowlist of what a plain word/path
character set actually is (`[A-Za-z0-9_./+=@:-]`) is provably closed
against this specific failure mode: a plain word cannot, by definition,
contain a character outside its own alphabet, so no future single-
character-based hunt round can repeat this exact pattern a fourth time.

The `adversarial-review` skill's core mechanism (a fresh, independent
evaluator with no stake in the builder's own reasoning finds what
self-review structurally cannot) was applied twice in this session: once
via a general-purpose hunt agent given only the two source files, the
specific class definition, and a live-execution verification requirement
(round 3, found the two backslash bypasses), and once via the dedicated
`warrant:warrant-hunter` agent focused on silent-failure/composition-
regression risk at this specific work-unit transition rather than
re-running the same security hunt a fifth time.

False-refusal cost of the allowlist-complement widening (explicitly
requested by the review): a head token quoted, braced, escaped, or
otherwise decorated with a character outside `[A-Za-z0-9_./+=@:-]` for
no functional reason (e.g. `"python3" -c ...`, `~/bin/tool -c ...`) now
also denies where it previously fell through unrecognized when combined
with `-c`/`-e` — but such a head was never reaching the literal
`head in INTERPRETER_HEADS`/`python3\b` alternatives either (the
decorating character makes it not equal to the bare name), so this is
not a new over-block on any PREVIOUSLY-ALLOWED plain interpreter
invocation, only on ones already falling through unrecognized before
this fix existed at all. No name in `INTERPRETER_HEADS`/
`WRITE_UNSAFE_HEADS`/`TRANSPARENT`, and no fixture in either test suite,
uses a character outside the safe set — the cost is real but has zero
measured hits across the existing corpus. Pure reads are structurally
unaffected in every commit: the widened checks only ever fire when
combined with a separate `-c`/`-e`-shaped flag on the same head-token's
run; a decorated head with no code flag (`"cat" reports/x.md`,
`{cat} reports/x.md`, `\cat reports/x.md`) falls through untouched in
both gates, verified by explicit negative-control tests added in every
commit.

## What did not work

The first hunt-round-3 candidate (widening `EXPANDED_HEAD_FUSED_FLAG_RE`
to `[^A-Za-z0-9_./+=@:-\s]`, ordering the trailing `\s` after `-`)
crashed the whole gate at Python regex-compile time: `re.error: bad
character range :-\s` — inside a bracket expression, `-` immediately
before a non-single-character token (`\s`) is parsed as an attempted
range, not a literal hyphen. Every board-gate.sh test failed (163
passed dropping to 101 passed / 64 failed) because the crash happens at
module load, before any tool-specific logic runs, fail-closing every
call regardless of tool_name — caught immediately by running the full
suite right after the edit rather than only the new tests. Fixed by
moving `-` to the very end of the bracket expression
(`[^A-Za-z0-9_./+=@:\s-]`), the position where it is always treated as
a literal character.

Considered and rejected for the backslash-newline fix: widening
`EXPANDED_HEAD_RE`/the scope-gate.py character classes to include `\`
directly (matching the round-2 pattern of adding characters to the
denylist/complement). Verified this does NOT close the finding by
itself: the actual defect is not that `\` fails to register as an
unsafe character in the head (it already does, correctly denying the
plain mid-word backslash-escape case) — it is that board-gate.sh's own
segment splitter mis-splits a backslash-continued line into two
segments BEFORE the head-safety check ever sees the combined text, so
the tainted head and the `-c` flag land in different segments and never
get compared together. Confirmed by testing the widened-character-class
version alone against the `backslash-newline-splice` reproduction: it
still returned `allow`. Fixed at the segmentation layer instead (see
What was done, commit `736b957`).

Considered and tested, ruled out as not composing into a live bypass of
this specific class: a backslash-escaped `;`/`|` (`python3 \; -c
'...'`). Real bash does treat an escaped `;`/`|` as a literal argument
character rather than a separator (confirmed: `echo a \; echo b` prints
literal `a ; echo b`, one command), which is the same "the gate's own
segment splitter would over-split relative to what bash actually
executes" shape as the backslash-newline case in principle — but
concretely, inserting a literal `;` before `-c` breaks the interpreter's
own argument parsing (`python3 \; -c '...'` makes `python3` treat the
literal semicolon as its first positional argument — a script filename —
never reaching `-c` as the first flag at all; live-tested, produced
`python3: can't open file '/tmp/;'`, exit 2, not a working `-c`
invocation). Not fixed: no live reproduction of this composing into a
working code-execution bypass of the `-c`/`-e` class was found. Left as
a narrower, unconfirmed, out-of-this-issue's-scope observation rather
than widened into (see Open findings).

The `run-board-gate-tests.sh` commits each triggered a non-blocking
`handbook-trigger-gate.sh` advisory (an operational-surface test-script
change with no matching `docs/handbooks/*.md` update in the same
commit, contract §21) — deliberately not addressed, matching PR #354's
own prior precedent for the same advisory: this role's mandated write
area is the one record path under `docs/issue-233/reports/`, and
touching a handbook file outside that area is out of this session's
write set, not merely deferred.

## Upstream basis

- Issue #233 (this issue) — canonical: `gh issue view 233` output.
- PR #354 and its review comment — canonical: `gh pr view 354`,
  `gh pr view 354 --json comments` output (comment id
  `IC_kwDOTk3ZJs8AAAABRbUHjQ`, author `JiwonJung94`, "CHANGES.
  Independent verification confirmed two bypasses...").
- `docs/issue-233/reports/adversarial-review-31f68317.md` (merged to
  `origin/main` at `b4c5683`, the independent verification record that
  produced the CHANGES review) — read in full; sha `b4c5683`.
- PR #354's own two commits, `a18a530`/`6e53b58` (branch
  `issue-233/secure-coding-input-validation-injection-defense+adversarial-review-746ed714`,
  base `8f95622`) — cherry-picked onto this branch unchanged at
  `origin/main` (`b4c5683`); read in full before and after the
  cherry-pick.
- `core/hooks/board-gate.sh`, `warrant/hooks/lib/scope-gate.py`,
  `core/hooks/lib/gate-lib.py` as they stood after the cherry-pick, read
  in full before each of the two additional fix commits.

## Open findings

- **Backslash-escaped `;`/`|` composing with segment mis-splitting** —
  tested (see What did not work), confirmed the escape itself is real
  (bash treats it as a literal argument character) but did NOT find a
  live reproduction that turns this into a working `-c`/`-e` bypass in
  the time available. Not fixed, not claimed closed either way. A future
  adversarial round should specifically try to compose it with a
  different flag-ordering or a wrapper (`env`, `timeout`) before ruling
  it out definitively.
- **Shell-function shadowing / PATH-based indirection**
  (`pywrap() { python3 -c "$1"; }; pywrap '...'`; a PATH-shadowed plain
  name) — confirmed out of scope by the independent verification record
  (Finding 3) and agreed with in the CHANGES review; not addressed here,
  matching that agreement. A text-based gate with no shell state cannot
  resolve a locally-defined function or a PATH-shadowed binary name.
- **Quoted `-c`/`-e` flag on a literally-named interpreter**
  (`python3 '-c' "..."`) and **leading `VAR=value` assignment prefix**
  (`FOO=1 python3 -c "..."`) — PR #354's own disclosed open findings,
  independently re-verified as out of this issue's scope by the
  verification record (Findings 4-5); untouched by this session's three
  commits, consistent with that agreement.
- A fourth adversarial hunt round (`warrant:warrant-hunter`, dispatched
  before landing) was in flight when this record was assembled,
  targeting silent-failure/composition-regression risk from this exact
  round of edits (rather than re-hunting the security class a fifth
  time) — its result, if it lands after this initial commit, will be
  folded into a follow-up commit/comment on the PR rather than blocking
  this delivery indefinitely, per the headless single-turn session
  constraint on this role (background work not yet returned by the time
  a turn must close cannot be waited on indefinitely).

## Test evidence

All four commands from the CHANGES review, live-reproduced against a
real board fixture (role `secure-coding-input-validation-injection-defense+adversarial-review-711fc48d`,
own record subtree) before and after the fix:

```
brace-expansion-bypass   {python3,} -c ...          pre-fix: allow -> post-fix: deny
quote-splice-single      pyt''hon3 -c ...            pre-fix: allow -> post-fix: deny
quote-splice-double      pyt"hon"3 -c ...            pre-fix: allow -> post-fix: deny
backslash-escape         p\y\t\h\o\n3 -c ...         pre-fix: allow -> post-fix: deny
backslash-newline-splice pyth\<newline>on3 -c ...    pre-fix: allow -> post-fix: deny
```

Real-execution confirmation (outside the gate, plain bash, `/tmp`) that
every shape above genuinely runs `python3 -c` and writes a file — e.g.:

```
$ cd /tmp && {python3,} -c 'open("notes_direct.txt","w").write("brace-expansion-worked")'
$ cat notes_direct.txt
brace-expansion-worked
$ cd /tmp && p\y\t\h\o\n3 -c 'open("bs1.txt","w").write("backslash-escape-worked")'
$ cat bs1.txt
backslash-escape-worked
```

derived: `bash core/hooks/tests/run-board-gate-tests.sh` (fresh
`git worktree add` of this branch's HEAD, `736b957`):
```
== 166 passed, 2 failed ==
```
The 2 failures (`feasibility-spikes`, `ops-postmortems`) are
pre-existing — checked: identical failing-test-NAME set against a fresh
`git worktree add origin/main` (`b4c5683`).

derived: `bash core/hooks/tests/run-scope-gate-tests.sh`:
```
== 69 passed, 0 failed ==
```

derived: `python3 -m pytest -q`:
```
3 failed, 79 passed
```
checked: identical failing-test-NAMEs
(`test_proposal_shape_gate_refuses_missing_sections`,
`test_survey_order_gate_refuses_proposal_without_survey_or_skip`,
`test_A5_trailer_gate_quote_split_commit_is_detected`) against the same
fresh `origin/main` worktree.

derived: `bash core/hooks/tests/run-approval-gate-tests.sh`:
```
== 65 passed, 2 failed ==
```
checked: identical failing-test-NAMEs (`checkpoint-refusal-names-await-approval`,
`execute-without-remote`) against the `origin/main` worktree.

derived: `bash core/hooks/tests/run-gh-guard-tests.sh`:
```
== 54 passed, 0 failed ==
```

derived: `bash core/hooks/tests/run-dispatcher-equivalence-tests.sh`:
```
dispatcher-equivalence: 24 passed, 1 failed
```
checked: identical failing-test-NAME (`approval-gate: execution write, no
approvers.md -> deny`) against the `origin/main` worktree.

derived: `bash core/hooks/tests/run-ups-diet-tests.sh` (fresh worktree,
no accumulated live-session state):
```
combined UPS bytes/turn: 2486
ups-diet: 36 passed, 0 failed
```
board-gate.sh/scope-gate.py are not among the 7 UPS-injected hook
scripts this suite measures (`proposal-shape-directive.sh`,
`record-shape-directive.sh`, `survey-order-directive.sh`, `terse.sh`,
`freelunch.sh`, `scout/directive.sh`, `warrant/directive.sh`) — an
initial in-place run inside this session's own long-lived working
directory showed a false "over budget" (3312 bytes) caused entirely by
this session's own accumulated hook-invocation state, not by this diff;
re-confirmed clean (2465-2486 bytes, within budget) in three separate
fresh `git worktree add` checkouts of both this branch and `origin/main`
(2451 bytes there) — an artifact of testing inside a live, heavily-used
session directory, not a real regression, noted here for transparency
rather than silently discarded.

derived: `bash core/hooks/tests/run-fleet-scan-tests.sh`:
```
pass=26 fail=1
```
checked: same pre-existing flake count/shape as `origin/main`.

derived: overhead re-measurement (100x board-gate.sh subprocess
invocations, own timing harness, fresh worktree, real board fixture):
this branch's HEAD averaged ~44.9ms; a fresh `origin/main` worktree
under the identical harness averaged ~45.8ms in the same session — the
~1ms delta is subprocess/bash-startup noise, not a measurable
regression from the added regex/comment content.

derived: `git diff origin/main HEAD -- core/hooks/board-gate.sh
warrant/hooks/lib/scope-gate.py core/hooks/tests/run-board-gate-tests.sh
core/hooks/tests/run-scope-gate-tests.sh | grep "^+" | grep -in
"role\|역할"` — no output; no return of the retired role/역할 axis in
any reshaped form.

## Standing invariants (per this session's spawn instructions)

- **No return of the retired role axis**: checked above, zero hits.
- **No new bug** (failing-test sets vs `origin/main`, as sets of NAMES,
  not counts): checked above for pytest, board-gate, scope-gate,
  approval-gate, gh-guard, dispatcher-equivalence, ups-diet,
  fleet-scan-tests — every failing-test-NAME set is identical to
  `origin/main`'s; ups-diet's byte-count metric was re-confirmed clean
  in a fresh worktree (see Test evidence).
- **No overhead increase**: re-measured above (~44.9ms this branch vs.
  ~45.8ms `origin/main`, within noise).
- **Monitor/watch machinery unbroken and not quieter**:
  `run-fleet-scan-tests.sh` pass/fail count and shape identical to
  `origin/main` (26/1, same pre-existing flake); this diff touches
  neither `fleet-silent-failure-scan.sh` nor its test suite.

## Next steps

None blocking — this record is terminal (`loop_state: landed`); all
three code commits are pushed as part of this PR. The `warrant-hunter`
round dispatched before landing may surface a follow-up if it returns
after this record's initial assembly (see Open findings); if it does,
this session will fold the result into an additional commit/PR comment
rather than leaving it unrecorded, but does not block delivery on it
indefinitely per the headless single-turn constraint on this role.

skill-verdict: secure-coding-input-validation-injection-defense —
applied: invoked; rule 2 (a denylist proposed as sole defense should not
remain the primary control) directly motivated the round-3 pivot from
an enumerated-character denylist to a safe-character allowlist for the
interpreter-head check, described in Why above.
skill-verdict: adversarial-review — applied: invoked; used as the
structuring mechanism for two independent hunt passes in this session
(a general-purpose background agent for round 3, and the dedicated
`warrant:warrant-hunter` agent before landing), each blind to this
session's own reasoning and required to verify any candidate with real
command execution before reporting it, rather than trusting this
session's own self-review of its fix.
other mounted skills: work-in-english — this record, all commit
messages, all test comments, and all commands/output produced by this
session are in English; only the final turn-ending summary to the user
is in Korean.
