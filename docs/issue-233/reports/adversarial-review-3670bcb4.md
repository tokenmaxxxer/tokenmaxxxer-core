---
issue: 233
role: adversarial-review-3670bcb4
author: adversarial-review-3670bcb4
skills: adversarial-review (skill-repository(c05de12))
verifies_subject: true
loop_state: complete
upstream:
  - path: docs/issue-233/reports/adversarial-review-84d72503.md
    sha: c2e8769f5d6c99e663a18144f82192e157778cb0
  - path: PR #372 (issue-233: close interpreter-head-via-single-token-expansion class generically)
    sha: ce0c55dfed601d1821dd4fe97494926183ccca54
  - path: PR #367 (issue-233: drop perl from -c/-e give-back, re-derive rest by execution (round 6))
    sha: 644443ab110e37f004ec2e477e1eddbd4e9fe003
---

# issue-233 — adversarial-review-3670bcb4 record

skill-verdict: adversarial-review — applied: invoked; called the Skill tool
before starting the investigation and followed its protocol in substance —
this session receives PR #372 as the artifact and is structurally
independent of the session that produced it (separate spawn, no shared
context), and every claim below was re-derived by executing real
subprocesses against a checked-out copy of the PR branch rather than
trusting PR #372's own body/record prose.
skill-verdict: work-in-english — applied: invoked; this record, all
commits, and the PR are written in English per the skill, with only the
final user-facing turn summary in Korean.
other mounted skills: hypothesis-testing not triggered — no go/kill/pivot
decision with an unregistered metric/threshold is open here; this round is
verification against an already-stated acceptance criterion, not a product
direction being tested.

## What was done

Independent re-verification of PR #372 (commit `ce0c55d`, branch
`issue-233/secure-coding-input-validation-injection-defense-bcd7fd6a`, not
merged), which claims to close issue-233 generically by adding
`EXPANSION_HEAD_C_FLAG_RE` to `core/hooks/board-gate.sh` and an equivalent
alternative to `UNANALYZABLE_WRITE_SHAPE` in `warrant/hooks/lib/scope-gate.py`.
Built in a fresh git worktree (`git worktree add /tmp/pr372-wt pr372-local`
against `origin/pull/372/head`, and `/tmp/main-wt` against `origin/main` at
`c2e8769` as the before/after baseline) so every test ran against real code,
not restated from PR #372's own record.

1. **Removed the confound round 7 (PR #373) found and named as the trap for
   this exact investigation.** `board-gate.sh`'s whole Bash branch is
   skipped, allow-by-default, unless the literal substring `docs` is in
   `cmdline`, and the repo's own test idiom (`cd docs/issue-3 &&
   <payload>`) sets a `cd_tail` that supplies a deny-worthy write-target
   candidate independent of whether the payload's head was ever resolved —
   so a naive `cd docs/... && <payload>` re-run of the issue's four shapes
   would report "deny" for a reason unrelated to head recognition, exactly
   as round 7 documented. Built an isolated harness
   (`/tmp/probe233/board_isolated.sh`, `/tmp/probe233/scope_isolated.sh`)
   that supplies the required `docs` substring through a separate,
   provably-read-only decoy segment (`echo docs/issue-3/reports/decoy.md ;
   <payload>` — `echo` is in `READ_ONLY_HEADS`) instead of a preceding
   `cd`, so no `cd_tail` is set and the payload segment under test carries
   no `docs` text of its own. Sanity-checked the harness against the three
   shapes round 7 found open on PR #367 (`${x:-python3} -c '...'`,
   `$(echo python3) -c '...'`) and confirmed PR #372's fix denies all of
   them under this isolation:
```
derived: bash /tmp/probe233/sanity.sh
OK   sanity-echo                      want=allow got=allow  | echo hi
OK   sanity-known-bypass-cmdsub       want=deny got=deny   | $(echo python3) -c 'import os'
OK   sanity-known-bypass-dflt         want=deny got=deny   | ${x:-python3} -c 'import os'
```
   PR #372's fix for the four issue-named shapes and round 7's isolated
   confirmations is real, not a repeat of the confounded 44/44 result.

2. **Attacked the fix's own enumeration** (`${...}` any inner form,
   `$(...)` one nested level, backtick, bare `$VAR`) with forms the task
   brief named: arithmetic expansion, `${VAR@P}`/indirect (`${!x}`),
   process substitution, ANSI-C quoting, a line-continuation split, and an
   expansion whose result is itself an expansion. Ran each through the
   isolated harness against `EXPANSION_HEAD_C_FLAG_RE` (board-gate.sh) and
   `UNANALYZABLE_WRITE_SHAPE` (scope-gate.py) on PR #372's branch:
```
derived: bash /tmp/probe233/attack.sh   (board-gate.sh, isolated)
OK   arithmetic-expansion-head        want=deny got=deny   | $((1+1)) -c 'import os'
OK   param-transform-P                want=deny got=deny   | ${x@P} -c 'import os'
OK   indirect-expansion               want=deny got=deny   | ${!x} -c 'import os'
OK   double-nested-cmdsub             want=deny got=deny   | $(echo $(echo python3)) -c 'import os'
FAIL nested-param-expansion           want=deny got=allow  | ${x:-${y:-python3}} -c 'import os'
FAIL process-substitution-head        want=deny got=allow  | <(echo python3) -c 'import os'
FAIL ansi-c-quoted-head               want=deny got=allow  | $'python3' -c 'import os'
FAIL ansi-c-hex-escaped-head          want=deny got=allow  | $'\x70\x79\x74\x68\x6f\x6e\x33' -c 'import os'
FAIL line-continuation-split          want=deny got=allow  | ${x:-\<newline>python3} -c 'import os'
FAIL triple-nested-cmdsub             want=deny got=allow  | $(echo $(echo $(echo python3))) -c 'import os'

derived: bash /tmp/probe233/attack_scope.sh   (scope-gate.sh, isolated)
OK   arithmetic-expansion-head        want=deny got=deny
OK   param-transform-P                want=deny got=deny
OK   indirect-expansion               want=deny got=deny
OK   line-continuation-split          want=deny got=deny
OK   triple-nested-cmdsub             want=deny got=deny
OK   double-nested-cmdsub             want=deny got=deny
FAIL nested-param-expansion           want=deny got=allow
FAIL ansi-c-quoted-head               want=deny got=allow
FAIL ansi-c-hex-escaped-head          want=deny got=allow
OK   sanity-known-dflt/asgn/cmdsub    want=deny got=deny   (all three re-confirmed)
```
   Every `FAIL` line was then re-run as a genuine subprocess with no gate
   involved, using a marker file that is written if and only if the flag
   actually executes code, to separate a real live bypass from a harness
   artifact:
```
derived: bash -c 'unset x y; ${x:-${y:-python3}} -c "open(\"marker1\",\"w\").write(1)"'
  -> marker1 written (REAL EXEC)
derived: bash -c "\$'python3' -c \"open('marker3','w').write(1)\""
  -> marker3 written (REAL EXEC)
derived: bash -c "\$'\x70\x79\x74\x68\x6f\x6e\x33' -c \"open('marker4','w').write(1)\""
  -> marker4 written (REAL EXEC)
derived: bash -c 'unset x; ${x:-\<newline>python3} -c "open(\"marker5\",\"w\").write(1)"'
  -> marker5 written (REAL EXEC)
derived: bash -c '$(echo $(echo $(echo python3))) -c "open(\"marker6\",\"w\").write(1)"'
  -> marker6 written (REAL EXEC)
derived: bash -c '<(echo python3) -c "open(\"marker2\",\"w\").write(1)"'
  -> bash: line 1: /dev/fd/63: Permission denied; marker2 NOT written
```
   Five of the six `allow` results are genuine, live, subprocess-confirmed
   bypasses (nested-parameter-expansion-of-expansion, ANSI-C-quoted head,
   ANSI-C hex-escaped head, an expansion split across a real line
   continuation, and a triple-nested command substitution — the last two
   on board-gate.sh only; scope-gate.py's whole-string `.search()` (vs.
   board-gate.sh's per-segment `.match()` at the segment start) happens to
   still catch those two). Process substitution is checked and found
   unverifiable as a live write vector — the kernel refuses to execute a
   `/dev/fd/N` process-substitution path directly (`Permission denied`),
   so the `allow` there is a genuine over-permission by the regex but not
   an exploitable bypass; not counted as a finding.

3. **Attacked the other direction: over-refusal.** The fix's
   `EXPANSION_HEAD_C_FLAG_RE`/`UNANALYZABLE_WRITE_SHAPE` addition denies
   unconditionally on shape (expansion head + a flag word ending in `c`/`e`)
   with no attempt to resolve what the expansion evaluates to — which also
   catches the common portable-tool-selection idiom
   (`${TOOL:-default}` falling back to a binary name) whenever that tool's
   own ordinary, non-code-executing flag happens to end in `c` or `e`
   (`sed -e`, `wc -c`, `grep -e`, `ls -c` all qualify; `date` does not).
   Verified four such commands are genuinely non-writing by direct
   execution, then ran them through the isolated harness on both branches:
```
derived: cd /tmp/real_exec_test && md5sum before/after README.md across
  ${SED:-sed} -e 's/a/b/' README.md, ${WC:-wc} -c README.md,
  ${GREP:-grep} -e test README.md, ${LS:-ls} -c .
  -> md5 identical before/after: CONFIRMED pure reads, no write

derived: bash /tmp/probe233/overrefusal_scope.sh   (scope-gate.sh, PR #372)
FAIL sed-e-portable-idiom   want=allow got=deny | ${SED:-sed} -e 's/a/b/' README.md
FAIL wc-c-portable-idiom    want=allow got=deny | ${WC:-wc} -c README.md
FAIL grep-e-portable-idiom  want=allow got=deny | ${GREP:-grep} -e pattern README.md
FAIL ls-c-portable-idiom    want=allow got=deny | ${LS:-ls} -c .
OK   date-portable-idiom    want=allow got=allow | ${DATE:-date} +%s

derived: bash /tmp/probe233/overrefusal_scope_main.sh   (scope-gate.sh, origin/main)
OK   sed-e/wc-c/grep-e/ls-c/date-portable-idiom   want=allow got=allow (all 5)

derived: bash /tmp/probe233/overrefusal_board.sh   (board-gate.sh, PR #372, isolated)
FAIL sed-e-portable-idiom   want=allow got=deny
FAIL wc-c-portable-idiom    want=allow got=deny

derived: bash /tmp/probe233/overrefusal_board_main.sh   (board-gate.sh, origin/main)
OK   sed-e/wc-c-portable-idiom   want=allow got=allow (both)
```
   Four commands (six counting board-gate's own two) that were genuinely
   read-only and ALLOWed on `origin/main` are newly DENIED by PR #372 on
   both gates — a real over-refusal regression, not a hypothetical one.

4. **Checked whether PR #367 and PR #372 conflict if both land.** PR #367
   (branch `issue-233/secure-coding-input-validation-injection-defense-8c25e36e`,
   commit `644443a`, unmerged) carries the jurisdiction-limit statement,
   the per-head `-c`/`-e` allowlist (`INLINE_FLAG_HEADS` replacing
   `INTERPRETER_HEADS`/`INLINE_FLAG_WORDS`), and the perl drop; PR #372
   does not contain any of that — it is additive only on top of
   `origin/main`'s current, unmodified `INTERPRETER_HEADS`/
   `INLINE_FLAG_WORDS`. Actually merged both onto a fresh `origin/main`
   checkout to check, rather than reasoning about the diffs in isolation:
```
derived: cd /tmp/merge-test && git merge --no-edit origin/pr367-local
  -> clean merge, "Merge made by the 'ort' strategy"
derived: git merge --no-edit origin/pr372-local
  -> CONFLICT (content): core/hooks/board-gate.sh
     CONFLICT (content): core/hooks/tests/run-scope-gate-tests.sh
     CONFLICT (content): docs/handbooks/board-gate-tests.md
     CONFLICT (add/add): docs/issue-233/reports/secure-coding-input-validation-injection-defense-bcd7fd6a.md
     CONFLICT (content): warrant/hooks/lib/scope-gate.py
```
   The two source-code conflicts are both narrowly scoped to one
   regex-definition hunk each — both PRs edit the lines immediately
   surrounding `VAR_INTERP_RE`'s definition (PR #367 narrows it to
   per-head flags; PR #372 leaves it broad and appends
   `EXPANSION_HEAD_C_FLAG_RE` right after it), and the identical shape in
   `scope-gate.py`'s `UNANALYZABLE_WRITE_SHAPE` disjunction. Everywhere
   else in `_is_unanalyzable_write_shape`'s body, git's own auto-merge
   already spliced PR #367's `INLINE_FLAG_HEADS` lookup and PR #372's
   `EXPANSION_HEAD_C_FLAG_RE.match(stripped)` line together with no
   conflict and no visible semantic clash — the two fixes are additive on
   different axes (per-head flag narrowing vs. expansion-shape denial) and
   do not disable each other. Docs conflicts are two records independently
   named `secure-coding-input-validation-injection-defense-bcd7fd6a.md`
   by unrelated sessions (slug collision) plus overlapping handbook
   entries — mechanical, not a design clash. Both PRs would need a human
   or a follow-up session to resolve the `VAR_INTERP_RE`/
   `UNANALYZABLE_WRITE_SHAPE` hunk by hand; they cannot both merge to
   `origin/main` via GitHub's own fast-forward/no-conflict auto-merge.

5. **Re-ran the four standing invariants**, PR #372's worktree against
   `origin/main`'s:
```
derived: cd /tmp/pr372-wt && git diff origin/main -- core/hooks/board-gate.sh core/hooks/tests/run-board-gate-tests.sh core/hooks/tests/run-scope-gate-tests.sh warrant/hooks/lib/scope-gate.py | grep -E "^\+" | grep -iE "\brole\b" | wc -l
  -> 0
derived: cd /tmp/pr372-wt && python3 -m pytest -q 2>&1 | tail -6
  -> 3 failed, 79 passed: test_proposal_shape_gate_refuses_missing_sections,
     test_survey_order_gate_refuses_proposal_without_survey_or_skip,
     test_A5_trailer_gate_quote_split_commit_is_detected
derived: cd /tmp/main-wt && python3 -m pytest -q 2>&1 | tail -6
  -> identical: 3 failed, 79 passed, identical three names
derived: bash core/hooks/tests/run-board-gate-tests.sh (both checkouts)
  -> PR #372: 155 passed, 2 failed (feasibility-spikes, ops-postmortems);
     origin/main: 143 passed, 2 failed, identical two failing names
     (checked: `grep FAIL` output identical on both)
derived: bash core/hooks/tests/run-scope-gate-tests.sh
  -> PR #372: 58 passed, 0 failed; origin/main: 46 passed, 0 failed
     (fewer cases only, no new failures)
derived: python3 /tmp/probe233/overhead.py /tmp/pr372-wt/core/hooks/board-gate.sh
  -> 43.21ms/call avg over 30
derived: python3 /tmp/probe233/overhead.py /tmp/main-wt/core/hooks/board-gate.sh
  -> 42.26ms/call avg over 30 (within subprocess-startup noise, no increase)
derived: cd /tmp/pr372-wt && bash core/hooks/tests/run-fleet-scan-tests.sh 2>&1 | tail -3
  -> pass=26 fail=1
derived: cd /tmp/main-wt && bash core/hooks/tests/run-fleet-scan-tests.sh 2>&1 | tail -3
  -> identical pass=26 fail=1, identical failing case name
```
   All four invariants hold: no retired-role-axis return, identical
   failing-test-name sets (pytest and board-gate's two pre-existing
   failures) on both checkouts, overhead flat, monitor/watch (fleet-scan)
   fires identically and is not quieter.

## Why

The task brief was explicit that the obvious head-enumeration re-run is
CONFOUNDED (round 7/PR #373's own finding) and that trusting it would
mean nothing. I built the isolated harness first and validated it against
round 7's own three named-open shapes before running anything new, so a
`deny` result in this record means the payload's own shape was
recognized, not that a `cd_tail`/decoy artifact produced it. The
`echo docs/... ; <payload>` decoy is a different construction from round
7's own `/tmp/probe/expansion_isolated_test.sh` (a `;`-separated decoy
segment rather than a `cd`), but serves the identical purpose (supply the
`DOCS in cmdline` substring without contributing a `cd_tail` or an
own-hit), and the sanity re-run of round 7's three shapes under it
matched round 7's own before/after results exactly, which is the evidence
the two harnesses agree.

Enumeration on this issue has failed four consecutive rounds (each prior
round's fix left a spelling an independent review then found), so the
brief's instruction to specifically try arithmetic expansion, parameter
operators, process substitution, ANSI-C quoting, line continuation, and
expansion-of-expansion was treated as a floor, not a checklist to clear
and stop — each candidate was pushed to a real, marker-file subprocess
execution rather than accepted on the gate's verdict alone, because a
gate returning "allow" is not evidence a shape is safe, and a gate
returning "deny" for the wrong reason (round 7's whole finding) is not
evidence a shape is closed. This is why process substitution is reported
as checked-and-ruled-out rather than as a finding: the gate's `allow` for
it is real, but real-execution showed it cannot actually run code, so
counting it as a bypass would have been the same category of error round
7's "44/44 confounded deny" mistake was, applied to the allow side.

The over-refusal check used the same standard: rather than construct an
artificial "any expansion head + -c/-e flag" example, it looked for
concrete tools whose own ordinary, non-executing flag happens to end in
the letters the new regex keys on, and confirmed each was non-writing by
direct execution before treating the gate's new `deny` as a regression
rather than a correct catch.

The PR #367/#372 conflict question was answered by actually merging both
branches rather than reasoning from the two diffs side by side, because a
textual reconciliation that looks obvious from two independent diffs can
still hide a real conflict (or, as turned out here, mostly not — most of
the function body auto-merged cleanly).

## What did not work

The first attempt to check the PR #367/#372 merge used
`git fetch up main pull/367/head pull/372/head` in one call followed by
`git merge up/pull/367/head` — `up/pull/367/head` is not a valid
remote-tracking ref name for a slash-containing `refs/pull/...` path
fetched without an explicit local destination, so both merge attempts
failed with "not something we can merge". Replaced with the existing
local branches (`pr367-local`, `pr372-local`) already created by this
session's own earlier `git fetch origin pull/N/head:pr372-local`-style
fetches, mirrored into the clone as `origin/pr367-local`/
`origin/pr372-local`; the merge check reported above used those.

## Upstream basis

- `docs/issue-233/reports/adversarial-review-84d72503.md` (round 7 / PR
  #373, sha `c2e8769f5d6c99e663a18144f82192e157778cb0`, same commit as
  this session's branch base) — the isolated-harness technique and the
  three-shape confound this round's harness was built and sanity-checked
  against.
- PR #372, `core/hooks/board-gate.sh`, `core/hooks/tests/run-board-gate-tests.sh`,
  `core/hooks/tests/run-scope-gate-tests.sh`, `warrant/hooks/lib/scope-gate.py`,
  `docs/handbooks/board-gate-tests.md` (branch
  `issue-233/secure-coding-input-validation-injection-defense-bcd7fd6a`,
  sha `ce0c55dfed601d1821dd4fe97494926183ccca54`) — the artifact under
  review, checked out via `git worktree add /tmp/pr372-wt pr372-local` and
  read in full before constructing any probe.
- `origin/main`'s `core/hooks/board-gate.sh` and
  `warrant/hooks/lib/scope-gate.py` (`git worktree add /tmp/main-wt
  origin/main`, sha `c2e8769f5d6c99e663a18144f82192e157778cb0`), used as
  the before/after baseline for every regression and over-refusal check.
- PR #367, `core/hooks/board-gate.sh`, `warrant/hooks/lib/scope-gate.py`
  (branch `issue-233/secure-coding-input-validation-injection-defense-8c25e36e`,
  sha `644443ab110e37f004ec2e477e1eddbd4e9fe003`), checked out via
  `git worktree add /tmp/pr367-wt pr367-local` — read in full, and merged
  against `origin/main` and against PR #372 in a scratch clone
  (`/tmp/merge-test`) to check the conflict question by execution rather
  than by diff-reading alone.

## Open findings

**Blocking: the single-token-expansion interpreter-head class issue-233's
acceptance criteria name is still open on PR #372, via spellings outside
its own enumeration.** Two forms are live, subprocess-confirmed bypasses
on BOTH `core/hooks/board-gate.sh` and `warrant/hooks/lib/scope-gate.py`:

- **Expansion-of-expansion**: `${x:-${y:-python3}} -c '...'`. Bash's
  nested-parameter-expansion syntax is valid and common (a default value
  that is itself a `${...:-...}` fallback chain), and
  `EXPANSION_HEAD_C_FLAG_RE`'s `\$\{[^{}]*\}` (board-gate.sh) /
  `\$\{[^{}]*\}` alternative (scope-gate.py) explicitly excludes any `{`
  or `}` from the inner content, so it cannot match a head containing a
  nested `${...}` at all — the regex's own "any inner form" claim in its
  comment does not extend to a nested brace expansion, only to a
  non-brace-containing one. Root cause, `core/hooks/board-gate.sh:611-613`
  on the PR #372 branch:
```python
EXPANSION_HEAD_C_FLAG_RE = re.compile(
    r'^"?(?:\$\{[^{}]*\}|\$\((?:[^()]|\([^()]*\))*\)|`[^`]*`|\$[A-Za-z_]\w*)"?'
    r"\s+-[A-Za-z]*[ce]\b")
```
- **ANSI-C quoting**: `$'python3' -c '...'` and, more seriously,
  `$'\x70\x79\x74\x68\x6f\x6e\x33' -c '...'` (hex-escaped — the literal
  text "python3" never appears anywhere in the command). `$'...'` is not
  `${...}`, `$(...)`, a backtick span, or a bare `$name` — it is a fourth,
  distinct bash expansion form (ANSI-C quoting) the regex's alternation
  never lists, so a segment whose head is `$'...'` fails every branch of
  `EXPANSION_HEAD_C_FLAG_RE`/`UNANALYZABLE_WRITE_SHAPE` and also never
  lands in `INTERPRETER_HEADS`/a literal-text scan, since `gate_head_of`'s
  `.split()`-based head is the literal `$'...'` text, and no interpreter
  name appears anywhere in the command text for the hex-escaped case.

Two further forms are live bypasses on `board-gate.sh` only (`scope-gate.py`
denies them, by virtue of its whole-command `.search()` rather than a
per-segment `.match()`-at-start, not by design intent stated anywhere in
its comments):

- **Line continuation inside the expansion**: `${x:-\` + newline +
  `python3} -c '...'`. Bash treats a literal backslash-newline as a line
  continuation (removed before the shell sees it), so the real,
  post-continuation command is the single-line dangerous shape — but
  `board-gate.sh`'s `_split_segments`/`SEGMENT` regex splits on a raw
  `\n` unconditionally (`core/hooks/board-gate.sh:165`,
  `SEGMENT = re.compile(gate_lib.GATE_QUOTE_SPAN.pattern + r"|\|\||&&|[|;\n]")`),
  with no awareness that a preceding backslash makes that `\n` a
  continuation rather than a segment separator. The gate's segment view of
  the command is therefore never the same string bash will actually run;
  segmenting it in two defeats every subsequent pattern that expects the
  expansion and its flag on the same segment.
- **Triple-nested command substitution**: `$(echo $(echo $(echo
  python3))) -c '...'`. The regex's `$(...)` alternative
  (`\$\((?:[^()]|\([^()]*\))*\)`) documents "one level of nested parens
  allowed" but its actual matching power goes one level further than that
  comment claims for `board-gate.sh`'s anchored-at-segment-start
  `re.match` (two levels: the outer `$(` plus exactly one further
  `\(...\)` group with no parens inside it) — at three levels of nesting
  the middle group itself contains parens the `[^()]*` inside
  `\([^()]*\)` cannot match, so the whole alternative fails to consume the
  string from position 0 and `re.match` (anchored) returns no match.

All four were re-confirmed as genuine, live code execution (see "What was
done" step 2 for the exact commands and marker-file results) — not gate
artifacts. **PR #372's own "Closes #233" is not honest against the
issue's second acceptance criterion** ("an adversarial hunt round finds
no remaining single-token-expansion interpreter-head bypass") — this
round is exactly that hunt, and it found four. This finding is
independent of PR #367's status: PR #372 stands alone (it does not
depend on or include PR #367's changes), so whether or not PR #367 ever
lands does not change that PR #372's own delivered code, merged by
itself, would leave the acceptance criterion unmet.

**Non-blocking but material: PR #372 introduces a real over-refusal
regression**, four ordinary, non-writing commands newly denied that
`origin/main` allows today (see "What was done" step 3): `${SED:-sed} -e
's/.../.../ ' file`, `${WC:-wc} -c file`, `${GREP:-grep} -e pattern
file`, `${LS:-ls} -c dir` — the `${TOOL:-default}` fallback-binary idiom
combined with any tool whose own ordinary flag happens to end in `c` or
`e`. This is the same class of cost the issue's own acceptance criterion
warns against ("pure-read forms ... still ALLOWED") and the same failure
mode that sent round 3 back, applied to a fallback-idiom shape the
issue's own two named pure-read controls (`${HOME}/x`, `awk '{print}'
file`) do not happen to cover. Not blocking on its own (the class this
issue is about is the missing-denial direction, and PR #372's design
tradeoff — deny unconditionally rather than resolve the expansion's value
— is the same tradeoff `INTERPRETER_HEADS` already makes for literal
heads, as PR #372's own record argues), but real and should be weighed
against the blocking finding above when deciding whether to widen the
fix's enumeration further or accept a broader over-refusal footprint.

**PR #367 / PR #372 conflict, and Closes #233 honesty relative to PR #367**:
confirmed by a real merge (see "What was done" step 4) that the two PRs
textually conflict in exactly the region both touch
(`VAR_INTERP_RE`/`UNANALYZABLE_WRITE_SHAPE`'s definition, one hunk per
file) and cannot both land on `origin/main` via a clean auto-merge; a
human or a follow-up session must resolve those two hunks by hand before
both can ship. The conflict is narrow and the two fixes are additive on
independent axes (per-head flag narrowing vs. expansion-shape denial;
git's own auto-merge already spliced the rest of
`_is_unanalyzable_write_shape`'s body together with no clash), so this is
a landing-order/merge-mechanics problem, not a design incompatibility.
Separately: PR #372's "Closes #233" wording does not overclaim relative
to PR #367 specifically — PR #372 never claims to carry PR #367's
jurisdiction statement, per-head allowlist, or perl drop, and issue-233's
title and acceptance criteria are specific to the single-token-expansion
class PR #367 explicitly left out of scope. The dishonesty in "Closes
#233" is not about omitting PR #367's content; it is that PR #372's own,
self-contained delivery does not meet the acceptance criterion it claims
to close, per the blocking finding above.

## Next steps

`loop_state: complete` for this record — the investigation is finished
and reported. Issue-233 remains open. The next unit of work is a round 9
that extends `EXPANSION_HEAD_C_FLAG_RE`/`UNANALYZABLE_WRITE_SHAPE` to
cover (a) nested `${...}` inside `${...}` (drop the `[^{}]` exclusion for
one more level, or switch to a balanced-brace matcher), (b) the `$'...'`
ANSI-C quoting form as a fifth alternative (recognizing the syntax, not
attempting to decode its contents — the hex-escaped case means content
inspection cannot be the defense here), (c) board-gate.sh's segment
splitting either respecting a backslash-newline continuation or the
regex being run non-anchored against the raw, unsplit command text the
way scope-gate.py's `.search()` already does, and (d) re-checks whether
widening the enumeration further reintroduces or worsens the over-refusal
regression this round found, rather than trading one for the other
silently. A round 9 should also resolve the `VAR_INTERP_RE`/
`UNANALYZABLE_WRITE_SHAPE` merge hunk against PR #367 before or as part
of landing, since both branches currently target the same acceptance
criteria and neither alone is a clean merge onto the other.
