---
issue: 361
role: adversarial-review-c564956c
author: adversarial-review-c564956c
skills: adversarial-review (skill-repository(c05de12))
verifies_subject: true  # independent verification of PR #374's deliverable
loop_state: landed
upstream:
  - path: core/hooks/board-gate.sh
    sha: e1dcbb0279a91f3b66d5a29e5ced7098d2da2a76
  - path: core/hooks/tests/run-board-gate-tests.sh
    sha: e1dcbb0279a91f3b66d5a29e5ced7098d2da2a76
  - path: docs/handbooks/board-gate-tests.md
    sha: e1dcbb0279a91f3b66d5a29e5ced7098d2da2a76
  - path: docs/issue-361/reports/secure-coding-input-validation-injection-defense-a072264b.md
    sha: e1dcbb0279a91f3b66d5a29e5ced7098d2da2a76
---

# issue-361 — adversarial-review-c564956c record

## What was done

Independent verification of PR #374 (`issue-361/secure-coding-input-validation-injection-defense-a072264b`,
head `e1dcbb0279a91f3b66d5a29e5ced7098d2da2a76`), all re-derived live against
two worktrees (`/tmp/main-check` = `origin/main`, `/tmp/pr374-check` = PR
head), not restated from the builder's own record.

**Verdict: BLOCKING. The PR's central soundness claim is false, and the
bypass class the issue names stays open — one level up, at the interpreter
head instead of the write target.**

1. **The scan is not sound — CONFIRMED, and this is issue-361's own class,
   not issue-357's.** The PR argues the new `UNANALYZABLE_HEAD_RE` /
   `UNANALYZABLE_FLAG_RE` shell-level scan is sound because "an interpreter
   head and its `-c`/`-e` flag must be spelled literally for the shell to
   invoke them." Tested directly: a payload that computes the interpreter
   name at Bash runtime, from octal escapes via `printf`, into a variable,
   then invokes `"$H" -c ...` — never spelling `python3` (or any head in
   `UNANALYZABLE_HEAD_RE`/`UNANALYZABLE_WRITE_HEAD_RE`) as a literal
   substring anywhere in the command text — reaches the real, unshadowed
   `python3` binary and performs the same `chr()`-assembled write PR #360's
   reproduction used, on **both** `origin/main` and the PR branch:

   ```
   $ cat /tmp/build_payload2.py   # builds the payload, see full text below
   $ TINPUT=$(cat /tmp/tinput.json)
   $ bash /tmp/probe_test.sh /tmp/main-check/core/hooks/board-gate.sh "$TINPUT" main
   [main] rc=0 got=allow
   $ bash /tmp/probe_test.sh /tmp/pr374-check/core/hooks/board-gate.sh "$TINPUT" pr374
   [pr374] rc=0 got=allow
   ```

   The exact command under test (JSON-decoded from `tool_input.command`):

   ```sh
   H=$(printf '\160\171\164\150\157\156\063'); "$H" -c "import pathlib;pathlib.Path(bytes([100,111,99,115,47,105,115,115,117,101,45,51,47,114,101,112,111,114,116,115,47,112,119,110,101,100,50,46,109,100]).decode()).write_text(chr(120))"
   ```

   Functional proof this really invokes `python3` (not a hypothetical):
   the same command, retargeted to `/tmp/pwned_func_check.md`, actually ran
   and wrote the file:

   ```
   $ rm -f /tmp/pwned_func_check.md && bash /tmp/probe_cmd_func.sh
   $ cat /tmp/pwned_func_check.md
   x
   $ ls -la /tmp/pwned_func_check.md
   -rw-rw-r-- 1 jwjung jwjung 1 8월 30 12:03 /tmp/pwned_func_check.md
   ```

   Why this is exactly issue-361's own class: `UNANALYZABLE_HEAD_RE` scans
   for literal head *words* in the raw payload text, the same trust model
   the closed `*docs*` fast path used for the write *target* — a value
   computed at Bash runtime never has to appear as that literal text. The
   PR's fix mirrors the python judge's `INTERPRETER_HEADS` vocabulary but
   still trusts that a head reaching execution must be spelled out; it need
   only be spelled out *somewhere* the shell resolves it from, and a shell
   variable populated by `printf` octal-decoding satisfies that without
   ever writing the interpreter's name as text.

   **Why this is not issue-357.** #357 is "a head whose *meaning* comes
   from shell state the gate cannot read" — a shell function (`pywrap`) or
   a `PATH` entry (`run`) where the head **word itself is a plain,
   unremarkable identifier** that resolves via persistent shell state (a
   function table entry, a `PATH` mutation) the gate would have to model
   across command boundaries or environment state. My payload does neither:
   no `PATH` mutation, no function/alias definition, nothing persisted
   outside the single command. The head position in the text is `"$H"` — an
   inline variable expansion, computed and consumed in the same command via
   ordinary shell substitution — not a plain word hiding behind external
   binding. It is the write-target bypass issue-361 names, applied to the
   token that gates the shape-scan itself, and it survives the PR's fix
   unchanged on both branches.

2. **Fast-path overhead — CONFIRMED, close to the PR's own number.**
   Independently re-measured (not restated), interleaved single-call timing
   alternating `origin/main` and PR-branch `board-gate.sh` on the *same*
   `git status` payload, 200 calls per branch per trial, 3 trials:

   ```
   kind=ordinary N=200  main=20668us/call  pr374=21601us/call  delta=933us/call
   kind=ordinary N=200  main=20563us/call  pr374=21063us/call  delta=500us/call
   kind=ordinary N=200  main=16883us/call  pr374=17602us/call  delta=719us/call
   ```

   Delta +500-933us/call, i.e. **+0.5-0.9ms**, matching the PR's claimed
   "+0.7-0.9ms" within measurement noise. Full-analysis path
   (`docs`-write payload forcing python judge on both branches, 100
   calls/branch/trial, 2 trials):

   ```
   kind=docswrite N=100  main=51251us/call  pr374=50985us/call  delta=-266us/call
   kind=docswrite N=100  main=51490us/call  pr374=51056us/call  delta=-434us/call
   ```

   No regression from removing the redundant python-layer `if DOCS in
   cmdline:` gate — PR374 is marginally *faster* on this path in both
   trials. Cost of deleting the shell pre-check entirely (forcing full
   analysis unconditionally): fast-path (~17-21ms/call) vs full-analysis
   (~51ms/call) ≈ **30ms/call**, matching the PR's "~30ms/call" claim and
   confirming the pre-check is worth keeping.

   (Absolute per-call times of 17-51ms are dominated by `bash`/`env`
   process-start and `gate-lib.sh` sourcing on this shared machine — much
   higher than the PR's own reported absolute numbers, but the *delta*
   between branches, measured on the same machine in the same interleaved
   run, is the number that matters and it agrees with the PR's claim.)

3. **Redundant python-layer gate removal — CONFIRMED safe.** Read
   `core/hooks/board-gate.sh` around the removed `if DOCS in cmdline:`
   guard (line ~651 on the PR branch): the removal un-indents the same
   segment/candidate-classification block to run unconditionally instead of
   only when `docs` is a literal substring of `cmdline` — a strict
   *widening* (every command the old code classified, the new code still
   classifies; commands the old code silently skipped now get classified
   too). A strict widening of a security check cannot depend on anything
   the narrower version provided — the only behavior change is that some
   previously-silently-allowed commands may now be examined, which is the
   intended fix, not a regression. Confirmed on the `else: allow()` at
   (post-fix) line 729 belongs to the outer `if tool == "Write"/"Edit" ...
   elif tool == "Bash": ... else:` non-Bash-tool branch, not to the removed
   `DOCS` guard — nothing else in the file branches on that guard.
   Full-analysis-path timing (item 2 above) shows no regression, if
   anything a small improvement.

## Why

Findings ranked hardest-first per the reviewing instructions: the
soundness-claim test came first because a false soundness claim voids the
PR's stated purpose (closing issue-361's own bypass class) regardless of
how well the rest measures out.

## What did not work

None.

## Upstream basis

PR #374, branch `issue-361/secure-coding-input-validation-injection-defense-a072264b`,
head `e1dcbb0279a91f3b66d5a29e5ced7098d2da2a76`. Builder's own record at
`docs/issue-361/reports/secure-coding-input-validation-injection-defense-a072264b.md`
was read only after all live re-derivation above was complete, to avoid
restating its claims as my own.

## Test-harness-trap disclosure (this issue's own subject)

Every payload used above is labeled with which layer actually denied or
allowed it, per the task's own warning that a payload without a literal
`docs` substring silently took the *old* fast path and could be misread:

- The `chr()`-assembled bypass (item 1): **shell-level fast path** on both
  branches — `rc=0`/`allow` means `board-gate.sh` exited before python3
  ever started; the python judge (and its unanalyzable-write-shape deny)
  was never reached on either branch. This is the fast-path bypass itself,
  not a python-judge miss.
- The `git status` timing payload (item 2, ordinary): shell-level fast path
  on both branches, as intended — confirms the preserved-fast-path
  invariant, not a bypass.
- The `docs`-write timing payload (item 2, full-analysis): the literal
  `docs` substring routes it past the fast path into the python judge on
  both branches — this measures the judge's own cost, unaffected by
  item 1's finding.

## Standing invariants

- **No return of the retired role axis:**
  `derived: cd /tmp/pr374-check && git diff origin/main HEAD -- core/hooks/board-gate.sh warrant/hooks/lib/scope-gate.py core/hooks/tests/run-board-gate-tests.sh core/hooks/tests/run-scope-gate-tests.sh | grep -inE 'role|ROLE|역할'`
  — 2 hits, a `role/slug` comment block moved (removed then re-added
  identically) during reflow, not new code. None found.
- **No new bug, failing-test SETS (not counts) vs `origin/main`:**
  - `derived: bash core/hooks/tests/run-board-gate-tests.sh` (both
    worktrees) — PR: 147 passed/2 failed; main: 143 passed/2 failed;
    failing-name set both `{feasibility-spikes, ops-postmortems}`
    (identical, pre-existing). The +4 passed on PR are the 4 new
    issue-361 test cases, all passing.
  - `derived: bash core/hooks/tests/run-scope-gate-tests.sh` (both) — 46
    passed/0 failed, identical, both branches.
  - `derived: env -u CLAUDE_PLUGIN_ROOT_CORE python3 -m pytest -q` (both)
    — PR: 3 failed/79 passed; main: 3 failed/79 passed; failing-name set
    both `{test_proposal_shape_gate_refuses_missing_sections,
    test_survey_order_gate_refuses_proposal_without_survey_or_skip,
    test_A5_trailer_gate_quote_split_commit_is_detected}` (identical,
    pre-existing).
- **No overhead increase — measured (item 2 above), and this one IS at
  risk by design:** the fast path genuinely costs +0.5-0.9ms/call more
  than `origin/main`, confirmed independently. That increase is the PR's
  own accepted trade (issue-361's acceptance criterion asks for a stated
  number, not zero), and the alternative (no pre-check) costs ~30ms/call
  by the same harness. Flagging it explicitly rather than folding it into
  a plain pass: it is a real, non-zero, deliberate cost, not an
  unaccounted regression.
- **Monitor/watch machinery unbroken and not quieter:**
  `derived: bash core/hooks/tests/run-fleet-scan-tests.sh` (both) — 26
  passed/1 failed both branches, same failing case (`live fleet run
  produces 43 repo rows want=43 got=44`, pre-existing flake), and
  `diff <(names from PR run) <(names from main run)` on the full ok/FAIL
  test-name list — identical set, same order, confirming the suite is not
  quieter on the PR branch.

## Open findings

1. **BLOCKING — the shell-level shape-scan's soundness claim is false; a
   variable-held, `printf`-decoded interpreter head bypasses both the old
   `*docs*` fast path and the PR's new shape scan, on `origin/main` and on
   the PR branch alike.** Belongs to issue-361 (this issue), not #357: no
   PATH mutation, no persisted function/alias — the head token in the
   command text is an inline variable expansion computed in the same
   command, structurally the same "runtime-computed value never spelled as
   literal text" defect the issue itself names, just moved from the write
   target to the interpreter head. Resolution path: the shape-scan (or the
   python judge it feeds into) needs to treat an unresolved head-position
   token — a bare `$VAR`/`${VAR}`/`` `...` ``/`$(...)` in command-word
   position — as unanalyzable in its own right, the same way heredoc and
   `$IFS` fusion already are, rather than only pattern-matching for
   already-known interpreter names in the raw text.
2. None else found; items 2-3 above (overhead, redundant-gate removal)
   both confirm the PR's own claims independently and are not findings.

## Next steps

None — this record is terminal (`loop_state: landed`). Resolution of the
open finding is next-round work for a builder session against issue-361 or
a follow-up issue, not this record.

skill-verdict: adversarial-review — applied: invoked; loaded the skill's
procedure before finalizing verdict/findings shape — this session already
satisfies its Step 2 gate (structurally independent evaluator, no access
to the builder's session or reasoning, artifact-only via PR #374's diff
and its own record read last) by the role-handoff contract's own spawn
setup.
other mounted skills: work-in-english — not triggered as a standalone
invocation (record and all repo-bound artifacts written in English per its
policy regardless); implementation-audit — not-applicable: this is a
targeted adversarial re-verification of a prior PR's specific claims, not
a fresh two-session claim-by-claim audit against the original issue text.
