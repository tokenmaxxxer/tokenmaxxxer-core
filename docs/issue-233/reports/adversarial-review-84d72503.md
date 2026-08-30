---
issue: 233
role: adversarial-review-84d72503
author: adversarial-review-84d72503
skills: adversarial-review (skill-repository(c05de12))
verifies_subject: true
loop_state: complete
upstream:
  - path: docs/issue-233/reports/secure-coding-input-validation-injection-defense-bcd7fd6a.md
    sha: 644443ab110e37f004ec2e477e1eddbd4e9fe003
  - path: docs/issue-233/reports/secure-coding-input-validation-injection-defense-8c25e36e.md
    sha: d80b7c547549de437886b612e804c4452d5731dd
  - path: docs/issue-233/reports/adversarial-review-5c3fbc55.md
    sha: 7d4fea2e23439b8f3591f905af57d3a04f109361
  - path: docs/issue-233/reports/adversarial-review-a814c155.md
    sha: ea8c498f8ca6b4c16eb41ebfb10d29e6dfc3ed48
---

# issue-233 — adversarial-review-84d72503 record

skill-verdict: adversarial-review — applied: invoked; called the Skill tool
early in this session and followed its protocol in substance — this
session is structurally independent of the round-6 session that produced
PR #367 (no shared context, no access to round 6's reasoning), received
the artifact (PR #367's diff plus its own record) and re-derived every
claim in it by executing real subprocesses against a checked-out copy of
the PR branch rather than trusting the record's prose, exactly the
mechanism the skill's "core mechanism" section describes for why
same-session self-review fails and a separate evaluator does not.

## What was done

Round 7 of issue-233's adversarial review loop: an independent,
from-scratch re-verification of PR #367 as it stands after round 6
(commit `644443ab110e37f004ec2e477e1eddbd4e9fe003` on branch
`issue-233/secure-coding-input-validation-injection-defense-8c25e36e`),
built in a separate git worktree (`git worktree add /tmp/pr367-wt
FETCH_HEAD` against that branch) so every test ran against the PR's
actual code, not restated from its record.

1. **Re-verified round 6's five give-back entries by real execution**,
   independently of round 6's own claimed execution (not by reading its
   prose): `bash -e`/`sh -e` (dash), `node -c`/`nodejs -c`, `ruby -c` (no
   local ruby — ran in a `ruby:3-alpine` container), `python3 -e`/`python
   -e` (`python` tested in a `python:2.7-alpine` container, since this
   session's host has no bare `python` binary), and `perl -c`/`perl -e`
   (both, to confirm they now stay denied). Every entry was tested with a
   script that writes a marker file if and only if the flag executes
   code, run for real as a subprocess, output captured directly — the
   `derived:` commands and outputs are in "Open findings" below and were
   run from `/tmp/probe` (a scratch directory outside this repo).

2. **Ran both of PR #367's own test suites as real subprocesses** against
   the checked-out PR branch:
   `derived: cd /tmp/pr367-wt && bash core/hooks/tests/run-board-gate-tests.sh`
   → `155 passed, 2 failed` (matching round 6's own claim), and
   `derived: cd /tmp/pr367-wt && bash core/hooks/tests/run-scope-gate-tests.sh`
   → `62 passed, 0 failed`.

3. **Enumerated all ten interpreter heads** (`python3`, `python`,
   `python2`, `bash`, `sh`, `zsh`, `perl`, `ruby`, `node`, `nodejs`) in
   `INLINE_FLAG_HEADS` (`core/hooks/board-gate.sh:574-579` on the PR
   branch) against all four single-token-expansion forms the issue names
   (`${x:-head}`, `${x:=head}`, `$(echo head)`, backtick), each followed
   by that head's real inline-exec flag and a write target under
   `docs/issue-3/reports/`, built as a real-subprocess harness
   (`/tmp/probe/harness.sh` + `/tmp/probe/enum_test.sh`) run against
   `core/hooks/board-gate.sh`. Every payload contained the literal
   substring `docs` (the harness trap this round's brief named: this
   gate's whole Bash branch is skipped, allow-by-default, unless
   `DOCS in cmdline` — `core/hooks/board-gate.sh:675` on the PR branch —
   so a payload without a literal `docs` substring tests nothing).

4. **Found that step 3's 44/44 "deny" result is not evidence the
   single-token-expansion class is closed** — it passes only because
   every payload in that shape (matching this repo's own existing test
   convention, e.g. `dollar-paren-fused-inline-c` in
   `core/hooks/tests/run-board-gate-tests.sh`) prefixes the interpreter
   call with `cd docs/issue-3 &&`, which sets `cd_tail` and makes
   `board-gate.sh` supply `docs/issue-3` as the write-target candidate
   for ANY unrecognized-and-not-provably-read-only segment that follows —
   independently of whether the interpreter head was actually resolved.
   Built a second, isolated harness
   (`/tmp/probe/expansion_isolated_test.sh`,
   `/tmp/probe/scope_isolated_test.sh`) that supplies the required
   literal `docs` substring through a separate, provably-read-only decoy
   segment (`echo docs/issue-3/reports/decoy.md ; `, `echo` is in
   `READ_ONLY_HEADS`) instead of a preceding `cd`, so no `cd_tail` is set
   and the payload's own `-c`/`-e` body carries no `docs` text at all.
   Under this isolation, `${x:-python3} -c '...'`, `${x:=python3} -c
   '...'`, and `$(echo python3) -c '...'` (and the `bash`/`perl`
   equivalents) all came back `allow` on both `core/hooks/board-gate.sh`
   and `warrant/hooks/lib/scope-gate.py`, on the PR #367 branch. Full
   commands and outputs are in "Open findings" below. This is a live,
   reproducible bypass of exactly the class issue-233's acceptance
   criteria names, still present on PR #367 after round 6.

5. **Traced the bypass to its root cause via git history**, rather than
   guessing: rounds 1-4 of this same review loop DID build a generic,
   structural fix for this exact class —
   `EXPANDED_HEAD_RE = re.compile(r"[\`$]")` plus
   `EXPANDED_HEAD_FUSED_FLAG_RE`, added in commit `c4a2d1659389fdccbab05ec3a3536a6dfd7e8429`
   ("fix(issue-233): close interpreter-head-via-expansion + -c/-e
   generically") and mirrored again as `UNRESOLVED_SUBSTITUTION_WORD_RE`
   in the branch round 4 reviewed (referenced in round 4's own
   verification record commit `580af981f6c98621e9d865eb885019d76e13f81d`
   as "the round-4 fix that mirrors `EXPANDED_HEAD_RE`'s structural
   rule"). Neither fix is an ancestor of `origin/main`:
   `derived: git merge-base --is-ancestor c4a2d1659389fdccbab05ec3a3536a6dfd7e8429 origin/main`
   exits non-zero (not an ancestor). Round 4's own verification
   (`580af981f6c98621e9d865eb885019d76e13f81d`) found PR #363 (the
   branch actually carrying the mirrored fix) insufficient — a live,
   confirmed ANSI-C `$'\x2dc'` escape-decoding bypass — and recommended
   **"Advances #233"**, not closing it. PR #363 was never landed: `git
   show origin/main:core/hooks/board-gate.sh | grep -n
   "EXPANDED_HEAD\|UNRESOLVED_SUBSTITUTION"` returns nothing, and PR
   #367 (round 5) branched from `580af981f6c98621e9d865eb885019d76e13f81d`
   without either fix. Round 5's own PR body states it "does not touch
   the single-token-expansion bypass class those rounds tracked" — true
   in the sense that round 5 didn't edit that code, but the class was
   never actually closed on this branch's ancestry in the first place;
   round 5's framing reads as if it were already handled.
   `derived: git show origin/main:core/hooks/board-gate.sh | grep -c
   "EXPANDED_HEAD\|UNRESOLVED_SUBSTITUTION"` → `0`.

6. **Confirmed the bypass is pre-existing on `origin/main`, not a round
   5/6 regression**: ran the identical isolated payloads (step 4) against
   `origin/main`'s `core/hooks/board-gate.sh` and
   `warrant/hooks/lib/scope-gate.py` (checked out at
   `/tmp/main-wt`, `git worktree add /tmp/main-wt origin/main`) and got
   the identical `allow` results for the identical payloads. This does
   not make PR #367 landable as "Closes #233" — the issue's own
   acceptance criterion is that no such bypass remains, and one does,
   regardless of which round introduced it.

7. **Demonstrated the bypass end-to-end, live, in this very session**,
   not only inside the isolated test harness: from a scratch directory
   with a real `docs/issue-3/reports/` subtree,
   `derived: cd /tmp/probe/e2e/docs && ${x:-python3} -c "open('issue-3/reports/pwn.md','w').write('REAL WRITE via expansion bypass')"`
   ran to completion with **no PreToolUse hook denial from this
   session's own live, currently-enforcing `board-gate.sh`** (role
   `adversarial-review-84d72503`, branch
   `issue-233/adversarial-review-84d72503`), and the file was written:
   `derived: test -f /tmp/probe/e2e/docs/issue-3/reports/pwn.md && cat
   /tmp/probe/e2e/docs/issue-3/reports/pwn.md` → `REAL WRITE via
   expansion bypass`. (For contrast, the same payload wrapped as `bash -c
   '${x:-python3} -c "..."'` WAS denied by this session's board-gate,
   because that literal outer `bash -c` — not the expansion — is what
   the gate actually recognizes.)

8. **Re-ran the four standing invariants** against the PR #367 worktree
   and `origin/main` worktree side by side:
   - retired-role-axis check:
     `derived: cd /tmp/pr367-wt && git diff origin/main -- core/hooks/board-gate.sh core/hooks/tests/run-board-gate-tests.sh core/hooks/tests/run-scope-gate-tests.sh warrant/hooks/lib/scope-gate.py | grep -E "^\+" | grep -iE "\brole\b" | wc -l`
     → `0`. ("The retired role axis" is the identifier-rename class
     issue-349 retired — see commit `8f95622` "issue-349: retire
     role/역할 Python and shell identifiers in core (slice 4)" in this
     repo's own log — checked for its return the same way round 6's own
     record checked it.)
   - no-new-bug (failing-test-name sets, not just counts), both suites,
     both checkouts:
     `derived: cd /tmp/pr367-wt && python3 -m pytest -q 2>&1 | tail -6`
     → `3 failed, 79 passed`, names
     `test_proposal_shape_gate_refuses_missing_sections`,
     `test_survey_order_gate_refuses_proposal_without_survey_or_skip`,
     `test_A5_trailer_gate_quote_split_commit_is_detected`;
     `derived: cd /tmp/main-wt && python3 -m pytest -q 2>&1 | tail -6`
     → identical `3 failed, 79 passed`, identical three names. Board-gate
     and scope-gate suites: PR branch `155 passed, 2 failed` /
     `62 passed, 0 failed` (both pre-existing `feasibility-spikes`/
     `ops-postmortems` failures, unrelated to this round); `origin/main`
     `143 passed, 2 failed` / `46 passed, 0 failed` (fewer cases only
     because the PR branch adds round-5/6 test cases `origin/main`
     doesn't have yet — the two failing names are identical on both).
   - overhead:
     `derived: python3 /tmp/probe/overhead.py /tmp/pr367-wt/core/hooks/board-gate.sh`
     → `47.13ms/call avg over 30`;
     `derived: python3 /tmp/probe/overhead.py /tmp/main-wt/core/hooks/board-gate.sh`
     → `46.98ms/call avg over 30` — within subprocess-startup noise, no
     increase.
   - monitor/watch machinery (this repo's fleet-scan suite):
     `derived: cd /tmp/pr367-wt && bash core/hooks/tests/run-fleet-scan-tests.sh 2>&1 | tail -3`
     → `pass=26 fail=1` (`live fleet run produces 43 repo rows` want=43
     got=44); `derived: cd /tmp/main-wt && bash
     core/hooks/tests/run-fleet-scan-tests.sh 2>&1 | tail -3` → identical
     `pass=26 fail=1`, identical failing case name. Fires and logs
     identically on both checkouts — not quieter, and not a new failure.

## Why

The brief for this round was explicit that documented/man-page semantics
are not evidence and that round 5's `perl -c` mistake (accepting the
documented "syntax-check-only" meaning of `-c` without running it) is
the exact failure mode to avoid repeating. I therefore re-executed every
give-back entry myself rather than reading round 6's table and trusting
its "checked by execution" column — including entries round 6 tested
locally (`bash -e`, `node -c`, `perl -c`/`-e`), using containers for the
two interpreters this session's host lacks (`ruby`, `python2`), so no
entry was accepted on citation alone.

The same standard applied to the deny side, not just the give-back
side. The task brief asked for a full head enumeration, not a sample,
because "a per-head allowlist means an omitted head is a silent hole." I
initially ran that enumeration the way this repo's own test suite
already does (`cd docs/issue-3 && ${x:-head} -c '...'`) and got 44/44
deny — which would have been a clean, closable result. But that shape
recycles the same `cd`-then-write pattern the existing regression tests
use, and reasoning through `core/hooks/board-gate.sh`'s decision logic
(`_is_unanalyzable_write_shape`, and the `cd_tail` fallback at
`core/hooks/board-gate.sh:701-735` on the PR branch) showed the deny in
that shape can come from `cd_tail` alone, independent of whether the
interpreter head was ever actually recognized. Rather than report the
44/44 number as if it settled the question, I built a second harness
that isolates the two confounds (`cd_tail`, and own_hits reading the
`docs` text straight out of the `-c`/`-e` body) and found the
recognition itself does not hold for the parameter-default-expansion and
command-substitution forms the issue names by example. This is the kind
of result the adversarial-review skill's "surface-mock pattern" warning
is about: a test that returns the right verdict for the wrong reason
looks identical to a real pass until it's decomposed.

I did not stop at "board-gate.sh has a gap" — I traced it to a specific,
citable root cause (rounds 1-4's structural fix living only on abandoned
branches, never merged to `origin/main`) rather than leaving it as an
unexplained regex miss, because the brief for this round asked whether
PR #367 is actually complete, and "the fix exists somewhere in this
repo's history but not on the branch being landed" is a different,
more actionable finding than "the fix was never written."

## What did not work

The first head-enumeration pass (`cd docs/issue-3 && ${x:-head} -c
'...'`, 44/44 deny) was not wrong as a result, but it was not the right
test for the question the brief actually asked ("does head resolution
of a single-token expansion get denied", not "does *some* candidate
under docs/ get denied when a `cd` into docs/ precedes it"). I built the
isolated harness (`/tmp/probe/expansion_isolated_test.sh`,
`/tmp/probe/scope_isolated_test.sh`) once the confound was clear and
used that as the basis for the reported result instead of the first
pass. The 44/44 numbers are reported above (step 3) for completeness,
labeled as confounded, not withheld.

Separately, my first scope-gate harness
(`/tmp/probe/scope_harness.sh`) set `CLAUDE_PLUGIN_ROOT_CORE` to the
worktree root instead of `<worktree>/core` (the actual `core/` plugin
root scope-gate.sh's own `. "${CLAUDE_PLUGIN_ROOT_CORE:-...}"` sourcing
line expects — matching `core/hooks/tests/run-scope-gate-tests.sh:17`'s
own `CORE_ROOT="$(cd "$HERE/../.." && pwd -P)"`). Every scope-gate.py
probe under that misconfiguration failed closed on a "cannot source
gate-lib.sh" error (`rc=2`) before doing any real analysis — which
would have read as "everything denies" and produced a false-clean
result for exactly the class this round most needed to test honestly.
Caught by manually inspecting one gate's raw output
(`derived: bash /tmp/probe/scope_debug_single.sh /tmp/pr367-wt` →
`/tmp/pr367-wt/warrant/hooks/scope-gate.sh: line 20:
/tmp/pr367-wt/hooks/lib/gate-lib.sh: No such file or directory`) rather
than accepting the deny verdicts at face value; fixed
(`CLAUDE_PLUGIN_ROOT_CORE="$ROOT/core"`) and every scope-gate result in
this record is from the corrected harness.

## Upstream basis

- `docs/issue-233/reports/secure-coding-input-validation-injection-defense-bcd7fd6a.md`
  (round 6 record, sha `644443ab110e37f004ec2e477e1eddbd4e9fe003`) — the
  give-back re-derivation table and the disclosed bundled-short-flag
  finding this round re-verified rather than restated.
- `docs/issue-233/reports/secure-coding-input-validation-injection-defense-8c25e36e.md`
  (round 5 record, sha `d80b7c547549de437886b612e804c4452d5731dd`) — the
  per-head `-c`/`-e` allowlist and jurisdiction-limit statement round 6
  built on.
- `docs/issue-233/reports/adversarial-review-5c3fbc55.md` (round 5
  verification, sha `7d4fea2e23439b8f3591f905af57d3a04f109361`) and
  `docs/issue-233/reports/adversarial-review-a814c155.md` (round 5
  verification, blocking finding on `perl -c`, sha
  `ea8c498f8ca6b4c16eb41ebfb10d29e6dfc3ed48`) — the two prior
  independent verifications of PR #367 this round did not restate but
  re-derived past (both concerned round 5's give-back list, not the
  expansion class this round found still open).
- `core/hooks/board-gate.sh` and `warrant/hooks/lib/scope-gate.py` on
  PR #367's branch (`git worktree add /tmp/pr367-wt FETCH_HEAD` from
  `issue-233/secure-coding-input-validation-injection-defense-8c25e36e`
  at commit `644443ab110e37f004ec2e477e1eddbd4e9fe003`), read in full
  before constructing any probe.
- `origin/main`'s `core/hooks/board-gate.sh` and
  `warrant/hooks/lib/scope-gate.py` (`git worktree add /tmp/main-wt
  origin/main` at commit `ea8c498f8ca6b4c16eb41ebfb10d29e6dfc3ed48`),
  used as the before/after comparison base for every invariant and for
  confirming the expansion-class bypass predates this PR.
- Round 4's verification record commit
  `580af981f6c98621e9d865eb885019d76e13f81d` ("issue-233: independent
  adversarial verification of PR #363 (round 4)") and commit
  `c4a2d1659389fdccbab05ec3a3536a6dfd7e8429` ("fix(issue-233): close
  interpreter-head-via-expansion + -c/-e generically") — read via `git
  show` to trace the expansion-class fix's actual merge history, not
  assumed from round 5/6's framing.

## Open findings

**Blocking: the single-token-expansion interpreter-head bypass issue-233
names in its own acceptance criteria is still open on PR #367 after
round 6, on both gates.** Concretely, on the PR #367 branch
(`/tmp/pr367-wt`), isolated from the `cd_tail`/own-hits confounds
described in "Why":

```
derived: bash /tmp/probe/expansion_isolated_test.sh /tmp/pr367-wt/core/hooks/board-gate.sh
FAIL python3-dflt-iso want=deny  got=allow | echo docs/issue-3/reports/decoy.md ; ${x:-python3} -c 'import os'
FAIL python3-asgn-iso want=deny  got=allow | echo docs/issue-3/reports/decoy.md ; ${x:=python3} -c 'import os'
FAIL python3-cmdsub-iso want=deny  got=allow | echo docs/issue-3/reports/decoy.md ; $(echo python3) -c 'import os'
OK   python3-backtick-iso want=deny  got=deny  | echo docs/issue-3/reports/decoy.md ; `echo python3` -c 'import os'
FAIL bash-dflt-iso want=deny  got=allow | echo docs/issue-3/reports/decoy.md ; ${x:-bash} -c 'import os'
FAIL bash-asgn-iso want=deny  got=allow | echo docs/issue-3/reports/decoy.md ; ${x:=bash} -c 'import os'
FAIL bash-cmdsub-iso want=deny  got=allow | echo docs/issue-3/reports/decoy.md ; $(echo bash) -c 'import os'
OK   bash-backtick-iso want=deny  got=deny  | echo docs/issue-3/reports/decoy.md ; `echo bash` -c 'import os'
FAIL perl-dflt-iso want=deny  got=allow | echo docs/issue-3/reports/decoy.md ; ${x:-perl} -e 'import os'
FAIL perl-asgn-iso want=deny  got=allow | echo docs/issue-3/reports/decoy.md ; ${x:=perl} -e 'import os'
FAIL perl-cmdsub-iso want=deny  got=allow | echo docs/issue-3/reports/decoy.md ; $(echo perl) -e 'import os'
OK   perl-backtick-iso want=deny  got=deny  | echo docs/issue-3/reports/decoy.md ; `echo perl` -e 'import os'
```

The two backtick "deny" results are also not evidence of real head
recognition: adding a single trailing space inside the backtick span
defeats them too —

```
derived: bash /tmp/probe/backtick_coincidence_test.sh /tmp/pr367-wt/core/hooks/board-gate.sh
FAIL backtick-trailing-space want=deny  got=allow | echo docs/issue-3/reports/decoy.md ; `echo python3 ` -c 'import os'
OK   backtick-printf-trailing want=deny  got=deny  | echo docs/issue-3/reports/decoy.md ; `printf '%s ' python3` -c 'import os'
```

(the second case still denies only because "python3" happens to be the
literal token immediately before the closing backtick again). The root
cause is `core/hooks/board-gate.sh:637-639` on the PR branch:

```python
    if head in INLINE_FLAG_HEADS:
        if any(w in INLINE_FLAG_HEADS[head] for w in gate_lib.gate_trailing_words(stripped)):
            return True
```

`head` here is `gate_lib.gate_head_of(stripped)`
(`core/hooks/lib/gate-lib.py:254-261`), which resolves a segment's head
by `segment.split()` and a literal dictionary/tuple membership test —
for a segment starting with `${x:-python3}` or `$(echo python3)`, `head`
is that literal expansion text, never the string `"python3"`, so `head
in INLINE_FLAG_HEADS` is always `False` for every expansion form except
the coincidental "name directly abuts a `` ` `` or `$(`" case
`FUSED_INTERP_RE` (`core/hooks/board-gate.sh:602-603`) already covers by
accident, not by design (`FUSED_INTERP_RE` was written for
`python3$(printf " ")-c` — fusion of a wrapper directly onto a
substitution — and its `\S*(?:\$\(|`)`` tail only fires here when
nothing but non-space characters sit between the name and the
substitution boundary).

`warrant/hooks/lib/scope-gate.py` has the analogous gap for the same two
forms (`${x:-head}`, `${x:=head}`), confirmed after fixing the
`CLAUDE_PLUGIN_ROOT_CORE` harness bug described in "What did not work":

```
derived: bash /tmp/probe/scope_isolated_test.sh /tmp/pr367-wt
FAIL python3-dflt want=deny  got=allow | ${x:-python3} -c 'import os'
FAIL python3-asgn want=deny  got=allow | ${x:=python3} -c 'import os'
OK   python3-cmdsub want=deny  got=deny  | $(echo python3) -c 'import os'
OK   python3-backtick-trailing-space want=deny  got=deny  | `echo python3 ` -c 'import os'
FAIL bash-dflt want=deny  got=allow | ${x:-bash} -c 'import os'
FAIL bash-asgn want=deny  got=allow | ${x:=bash} -c 'import os'
FAIL perl-dflt want=deny  got=allow | ${x:-perl} -e 'import os'
FAIL perl-asgn want=deny  got=allow | ${x:=perl} -e 'import os'
```

(scope-gate.py's `$(echo head)` case denies for the same
regex-coincidence reason as board-gate.sh's — its
`UNANALYZABLE_WRITE_SHAPE` clause at
`warrant/hooks/lib/scope-gate.py:176` requires only that the interpreter
name appear as a whitespace-bounded word somewhere before a same-clause
`-c`, which `$(echo python3)` satisfies by construction since "python3"
is `echo`'s own, whitespace-preceded argument — not because the
expansion's head is recognized.)

This is not a round 5/6 regression — the identical isolated payloads
against `origin/main`'s current gates return the identical `allow`
results:

```
derived: bash /tmp/probe/expansion_isolated_test.sh /tmp/main-wt/core/hooks/board-gate.sh
(same FAIL/OK pattern as the PR-367 run above, verified identical)
derived: bash /tmp/probe/scope_isolated_test.sh /tmp/main-wt
(same FAIL/OK pattern as the PR-367 run above, verified identical)
```

and the generic structural fix that would close it
(`EXPANDED_HEAD_RE`/`UNRESOLVED_SUBSTITUTION_WORD_RE`, see "What was
done" step 5) exists only on two abandoned branches
(`issue-233/secure-coding-input-validation-injection-defense+adversarial-review-8bab0cf8`
and PR #363's branch), neither of which is an ancestor of `origin/main`
or of PR #367. Resolution path: land the structural
`EXPANDED_HEAD_RE`-equivalent fix (or a fresh equivalent, since PR #363
itself had its own live-confirmed bypass per round 4's verification) on
`origin/main` before this issue can close — not a further narrowing of
the `-c`/`-e` give-back list, which is what rounds 5/6 both worked on
while this class sat unaddressed underneath. Given this, PR #367 as it
stands should **not** merge as "Closes #233": the specific acceptance
criterion this issue states (interpreter-head-via-single-token-expansion
followed by `-c`/`-e` denied) is demonstrably not met.

All other checks in this round came back clean, no findings:

- The five give-back entries round 6 kept (`bash -e`/`sh -e`, `node
  -c`/`nodejs -c`, `ruby -c`, `python3 -e`/`python -e`/`python2 -e`) are
  genuinely harmless by real execution, independently re-confirmed this
  round (see "What was done" step 1; raw commands/outputs are the
  Bash-tool transcript of this session, not restated in full here since
  every one matched round 6's own claimed result).
- `perl -c` and `perl -e` are both denied by the gate
  (`round6-perl-c-denied` in both `core/hooks/tests/run-board-gate-tests.sh`
  and `core/hooks/tests/run-scope-gate-tests.sh`, confirmed passing on
  the PR branch — see "What was done" step 2) and both genuinely execute
  code on real invocation:
  `derived: perl -c t5.pl` (script containing a `BEGIN { open(...) }`
  block) → `t5.pl syntax OK`, exit 0, and the `BEGIN`-block marker file
  was created; `derived: perl -e "open(F,'>marker'); ..."` → exit 0,
  marker file created.
- The bundled-short-flag gap round 6 disclosed (`perl -wc`, `bash -xc`,
  etc.) was not re-litigated this round — round 6 already disclosed it
  as pre-existing and out of round-6 scope, and this round's brief
  scoped the hunt to the single-token-expansion class specifically. Not
  independently re-verified here; carried forward as still-open per
  round 6's own disclosure.
- All four standing invariants hold (see "What was done" step 8):
  retired-role-axis grep returns 0 hits; failing-test-NAME sets are
  identical between the PR branch and `origin/main` on both `pytest -q`
  (3 identical names) and both gate test suites (2 identical board-gate
  names, 0 scope-gate failures either side); overhead is flat
  (47.13ms vs 46.98ms per call, 30-call average); the fleet-scan
  monitor suite fires and fails identically on both checkouts (`pass=26
  fail=1`, same case name), not quieter.

## Next steps

`loop_state: complete` for this record — the investigation is finished
and its result (a blocking finding) is reported. Issue-233 itself
remains open: the next unit of work is a round 8 that lands a
structural, expansion-aware head check (an `EXPANDED_HEAD_RE`-equivalent
covering `${x:-...}`/`${x:=...}`/`$(...)`/backtick forms, closing the
gap this record demonstrates, and re-hunted the way round 4 hunted PR
#363 before landing it, since PR #363's own attempt at this had its own
live bypass per round 4) on `origin/main`, ahead of or alongside any
further `-c`/`-e` give-back narrowing. This record does not attempt that
fix itself — it was scoped to verification, not remediation, and the
task brief for this round explicitly ruled out adding flag spellings,
substitution matching, or moving the gate to PostToolUse; a structural
head-resolution fix is a different, larger unit of work than any of
those three ruled-out options, matching the same "not in this round's
scope" boundary round 5/6 already drew around the give-back narrowing
itself.
