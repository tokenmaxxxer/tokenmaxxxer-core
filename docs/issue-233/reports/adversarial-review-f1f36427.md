---
issue: 233
role: adversarial-review-f1f36427
author: adversarial-review-f1f36427
skills: adversarial-review (skill-repository(c05de12))
verifies_subject: true
loop_state: complete
upstream:
  - path: docs/issue-233/reports/secure-coding-input-validation-injection-defense-bcd7fd6a.md
    sha: a4912b153c6a56eda0545b5b7078bb1a410f4e00
  - path: docs/issue-233/reports/adversarial-review-84d72503.md
    sha: c2e8769f5d6c99e663a18144f82192e157778cb0
---

# issue-233 — adversarial-review-f1f36427 record

skill-verdict: adversarial-review — applied: invoked; called the Skill tool
and followed its protocol in substance — this session did not read PR
#372's own record's prose as ground truth, built an independent isolated
harness against a checked-out worktree of the PR branch, and re-derived
every claim (the 3 issue-named shapes, the over-refusal question, the
#367 conflict, the 4 standing invariants) by real subprocess execution
rather than restating what the PR body or its record claims.
skill-verdict: work-in-english — applied: invoked; this record, all
scratch harness scripts, and all commit/PR text are in English; only the
final user-facing turn summary is in Korean.
other mounted skills: not triggered (implementation-audit and
hypothesis-testing do not fit an independent-verification-of-a-PR task —
no builder/evaluator claim-extraction protocol was set up, and there is
no go/kill/pivot decision with a metric to pre-register).

## What was done

Independent verification of PR #372 ("issue-233: close
interpreter-head-via-single-token-expansion generically", commit
`ce0c55d` on branch `issue-233/close-interpreter-head-via-single-...`),
re-derived from scratch rather than restated from its own record
(`docs/issue-233/reports/secure-coding-input-validation-injection-defense-bcd7fd6a.md`
on that branch).

1. **Checked out isolated worktrees**: `derived: git fetch origin
   pull/372/head:pr-372 && git worktree add /tmp/wt372 pr-372` (PR #372
   at `ce0c55d`) and `derived: git worktree add /tmp/wtmain origin/main`
   (`c2e8769`, current `origin/main` HEAD, itself PR #373's round-7
   verification record) as the before/after comparison base.

2. **Built an isolated harness that removes the `cd_tail` confound PR
   #373's round-7 review found** (`/tmp/probe233/iso_test.sh`,
   `/tmp/probe233/scope_iso_test.sh`): every board-gate payload supplies
   the gate's required literal `docs` substring
   (`core/hooks/board-gate.sh` skips its whole analysis branch,
   allow-by-default, unless the raw command text contains `docs`) via a
   read-only decoy segment (`echo docs/issue-3/reports/decoy.md ; `,
   `echo` is in `READ_ONLY_HEADS`) instead of a preceding `cd`, so no
   `cd_tail` write-candidate is set and the payload's own `-c`/`-e` body
   never contains `docs` text of its own — the same isolation PR #373's
   `/tmp/probe/expansion_isolated_test.sh` used. Confirmed accounted for
   in every board-gate probe below; scope-gate.py does not gate on a
   `docs` substring at all (it is write-set based, not board-layout
   based), so its probes needed no decoy.

3. **Re-derived the 3 issue-named shapes on the isolated harness**,
   against PR #372's branch:
   ```
   derived: bash /tmp/probe233/iso_test.sh /tmp/wt372/core/hooks/board-gate.sh
   OK   python3-dflt-iso    want=deny got=deny | echo docs/issue-3/reports/decoy.md ; ${x:-python3} -c 'import os'
   OK   python3-asgn-iso    want=deny got=deny | echo docs/issue-3/reports/decoy.md ; ${x:=python3} -c 'import os'
   OK   python3-cmdsub-iso  want=deny got=deny | echo docs/issue-3/reports/decoy.md ; $(echo python3) -c 'import os'
   ```
   All 3 genuinely deny under isolation — the fix works for the shapes
   the issue names, not only under the confounded `cd`-prefixed shape.

4. **Hunted for spellings outside PR #372's own enumeration** (braced,
   `:-`/`:=`/`:+`, `$(...)`, backtick, bare `$VAR`, quoted, nested), per
   this round's brief: arithmetic expansion, `${x@P}`, process
   substitution, ANSI-C quoting, a line-continuation split, and a
   doubly-nested expansion. 5 of 7 close cleanly; 2 are live,
   reproducible bypasses — see "Open findings".
   ```
   derived: bash /tmp/probe233/iso_test.sh /tmp/wt372/core/hooks/board-gate.sh (full run)
   OK   arith-expansion-head      want=deny got=deny  | ...; $((1)) -c 'import os'
   OK   param-at-P-head           want=deny got=deny  | ...; ${x@P} -c 'import os'
   FAIL process-sub-head          want=deny got=allow | ...; <(echo python3) -c 'import os'
   FAIL ansi-c-quote-head         want=deny got=allow | ...; $'python3' -c 'import os'
   FAIL line-continuation-head    want=deny got=allow | ...; ${x:-python3} \<newline>-c 'import os'
   OK   nested-expansion-head     want=deny got=deny  | ...; ${x:-$(echo python3)} -c 'import os'
   OK   double-expansion-head     want=deny got=deny  | ...; $($(echo echo) python3) -c 'import os'
   OK   param-expansion-pure-read want=allow got=allow | ${HOME}/x
   OK   awk-pure-read             want=allow got=allow | awk '{print}' file
   ```
   `derived: bash /tmp/probe233/scope_iso_test.sh /tmp/wt372` (mirrors
   the same set against `warrant/hooks/lib/scope-gate.py`; identical
   FAIL set on `ansi-c-quote-head`/`line-continuation-head`, but
   `process-sub-head` denies there — see "Open findings" for the
   per-gate table).

5. **Confirmed the 2 surviving bypasses execute for real**, not only
   inside the gate harness — see "Open findings" item 1 for the exact
   `derived:` commands and write proof.

6. **Tested over-refusal**: built `/tmp/probe233/overreach_test.sh`,
   probing ordinary non-interpreter commands reached via the same
   single-token-expansion + `-c`/`-e` shape the fix now blankly denies,
   isolated the same way as step 3. See "Open findings" item 2.

7. **Checked the PR #367 relationship**: fetched PR #367
   (`derived: git fetch origin pull/367/head:pr-367`, `644443a`), diffed
   it against PR #372, and test-merged both onto `origin/main` in a
   throwaway worktree to see whether landing both produces a real
   conflict or just adjacent additions. See "Open findings" item 3.

8. **Re-ran PR #372's own claimed test suites** as real subprocesses
   against the checked-out branch (not restated from its record):
   `derived: cd /tmp/wt372 && bash core/hooks/tests/run-board-gate-tests.sh`
   → `155 passed, 2 failed` (matches PR #372's claim); `derived: cd
   /tmp/wt372 && bash core/hooks/tests/run-scope-gate-tests.sh` → `58
   passed, 0 failed` (matches PR #372's claim).

9. **Re-ran the four standing invariants**, PR #372 branch vs.
   `origin/main`, side by side — see "Open findings" item 4 for full
   commands/output (all 4 hold; not a finding, included for
   completeness per this round's brief).

## Why

The brief for this round named a specific, concrete trap this issue's
history has hit twice already: (a) the `cd docs/issue-3 &&`-prefixed
test shape this repo's own suite uses, and PR #372's own record uses for
its before/after board-gate repro, is confounded by `cd_tail` — a deny
can come from that fallback alone, independent of whether the
expansion's head was ever actually resolved — exactly what PR #373's
round-7 review found made an earlier round's "44/44 deny" meaningless.
Re-running the same confounded shape and reporting a clean result would
have repeated that exact mistake, so this round built the isolation
first and used it as the basis for every deny/allow claim below, the
same way PR #373's round did.

(b) The board-gate.sh test-harness trap named in the brief — the whole
Bash analysis branch is skipped, allow-by-default, unless the raw
command text contains the literal substring `docs` — is a second,
independent way to produce a bogus `rc=0`/allow result that has nothing
to do with the shape under test. Every board-gate probe in this record
carries that substring through the isolating decoy segment, never
through the payload body itself (which would reopen the `cd_tail`-style
confound in a different guise: the decoy's `docs` text and the payload's
`-c`/`-e` body are in genuinely separate `;`-delimited segments).

Enumeration on this issue has been wrong four consecutive rounds
(rounds naming a spelling set, then an independent review finding one
outside it), so the brief asked for spellings likely to fall outside any
regex written by pattern-matching on the issue's own 4 named examples
plus the round-that-fixed-it's own 4 hunt-round additions (quoted,
nested-cmdsub, backtick, `-e`-flag) — all 8 of which PR #372 does close.
Arithmetic expansion, `${x@P}`, process substitution, ANSI-C quoting, a
line-continuation split, and a doubly-nested expansion were chosen
because each is a distinct *mechanism* by which bash can produce a
single-token command head, not a re-spelling of a mechanism the fix's
regex (`EXPANSION_HEAD_C_FLAG_RE`/the mirrored `UNANALYZABLE_WRITE_SHAPE`
clause) already targets: `${...}`, `$(...)`, and backtick spans. ANSI-C
quoting (`$'...'`) and a backslash-newline continuation are both outside
that three-way enumeration by construction — `$'...'` is not a `${`,
`$(`, or `` ` `` span at all, and a line continuation defeats the
regex's `\s+` requirement between the expansion and the flag (a literal
`\` byte sits where the regex expects only whitespace). Both were
confirmed to genuinely execute, not just to defeat the gate's text
match, before being reported as findings — the same standard PR #373's
round applied to `perl -c` after round 5's documented-semantics mistake.

The over-refusal direction was tested with equal effort because the
brief was explicit that this fix "makes the gate deny MORE" and that
"a fix that quietly re-broadens it is not an improvement" — round 3's
own history in this issue's git log is exactly a fix landing without
that cost being weighed. `${TAR:-tar} -c`, `${CURL:-curl} -c`,
`${GREP:-grep} -c`, `${EDITOR:-vim} -c`, `${SED:-sed} -e`, and
`$(which ls) -c` were chosen as the six most common `-c`/`-e`-using
non-interpreter CLI tools reachable through a real, idiomatic shell
tool-selection pattern (`${TOOL:-default}`, `$(which tool)`), not
synthetic examples.

## What did not work

An unexplained anomaly, not a build failure: `/tmp/probe233/overhead.py`
(a scratch harness under `/tmp`, outside this repository, used only for
this record's overhead measurement) was found rewritten on disk
mid-session — different `N`, a different payload (the
`ansi-c-quote-head` bypass command instead of a neutral `echo hi`), and
missing the temp-dir cleanup this session's own version had. This
session did not make that edit. `/tmp/probe233` is a generic scratch
path this session chose (not one of the known env-var-provided
directories), so the most likely explanation is a name collision with
some other concurrent process on the same host writing to the same
`/tmp` path, not an attack on this session specifically — but it was not
possible to confirm the actor from inside this session. The overhead
number reported below (see "Open findings" item 4) is this session's own
clean `N=100`, neutral-payload run, captured before the file changed;
the rewritten script's output was not used for any claim in this record.

## Upstream basis

- `docs/issue-233/reports/secure-coding-input-validation-injection-defense-bcd7fd6a.md`
  (PR #372's own record, commit `a4912b1` on branch `pr-372`) — the
  deliverable this record independently re-derives rather than restates;
  specifically its board-gate before/after repro (using the confounded
  `cd docs/issue-3 &&` shape) and its "58/155 passed" test-suite claims.
- `docs/issue-233/reports/adversarial-review-84d72503.md` (PR #373's
  round-7 verification, merged to `origin/main` at `c2e8769`) — the
  source of the `cd_tail` confound methodology and the docs-substring
  test-harness trap this round's isolated harness was built to avoid
  repeating; also the source of the 4-standing-invariant commands this
  round re-ran (retired-role-axis grep, `pytest -q` failing-name set,
  `overhead.py` shape, `run-fleet-scan-tests.sh`).
- `core/hooks/board-gate.sh` and `warrant/hooks/lib/scope-gate.py` on PR
  #372's branch (`git worktree add /tmp/wt372 pr-372` at `ce0c55d`) and
  on `origin/main` (`git worktree add /tmp/wtmain origin/main` at
  `c2e8769`), read in full before constructing any probe.
- `core/hooks/board-gate.sh` and `warrant/hooks/lib/scope-gate.py` on PR
  #367's branch (`git fetch origin pull/367/head:pr-367` at `644443a`),
  read and diffed against PR #372 to assess the conflict question this
  round's brief asked about.

## Open findings

**1. Blocking — two live, reproducible single-token-expansion bypasses
remain after PR #372, on both gates.** Isolated from the `cd_tail`
confound (see "What was done" step 2-4):

```
derived: bash /tmp/probe233/iso_test.sh /tmp/wt372/core/hooks/board-gate.sh
FAIL ansi-c-quote-head        want=deny got=allow | echo docs/issue-3/reports/decoy.md ; $'python3' -c 'import os'
FAIL line-continuation-head   want=deny got=allow | echo docs/issue-3/reports/decoy.md ; ${x:-python3} \
-c 'import os'

derived: bash /tmp/probe233/scope_iso_test.sh /tmp/wt372
FAIL ansi-c-quote-head        want=deny got=allow | $'python3' -c 'open("src/other.py","w")'
FAIL line-continuation-head   want=deny got=allow | ${x:-python3} \
-c 'open("src/other.py","w")'
```

Both confirmed to genuinely execute, not merely to defeat the gate's
text match — run directly, outside any gate, in a scratch directory:

```
derived: cd /tmp/probe233/e2e && bash -c "\$'python3' -c 'open(\"pwn_ansi.md\",\"w\").write(\"REAL WRITE ansi-c\")'" && cat pwn_ansi.md
REAL WRITE ansi-c

derived: cd /tmp/probe233/e2e && bash -c "\${x:-python3} \
-c 'open(\"pwn_linecont.md\",\"w\").write(\"REAL WRITE linecont\")'" && cat pwn_linecont.md
REAL WRITE linecont
```

Root cause: `EXPANSION_HEAD_C_FLAG_RE`
(`core/hooks/board-gate.sh:566-567` on PR #372's branch) and the mirrored
clause in `warrant/hooks/lib/scope-gate.py:200-201` both enumerate the
head as `\$\{[^{}]*\}|\$\((?:...)*\)|`[^`]*`|\$[A-Za-z_]\w*` — three
expansion forms plus a bare variable, none of which is `\$'...'`
(ANSI-C quoting is a distinct bash word-expansion mechanism, not a
parameter/command/backtick expansion) — and the same regex requires
literal `\s+` immediately before the flag, which a backslash-newline
line continuation defeats (the byte between the closing `}` and the
flag is `\`, not whitespace, even though the shell itself treats
`X \<newline>-c` as equivalent to `X -c`). This is not a confound
artifact — the "genuinely execute" reproductions above ran completely
outside any gate.

This is not a PR #372 regression — the identical isolated payloads
against `origin/main`'s current gates (which lack even the 3
issue-named-shape fix) return the identical `allow` result:
`derived: bash /tmp/probe233/iso_test.sh /tmp/wtmain/core/hooks/board-gate.sh`
→ same 2 FAILs among a larger FAIL set (12/14 fail on `origin/main` vs.
2/14 on PR #372's branch — PR #372 does close 10 of the 12 new probes,
just not these 2). But PR #372's own acceptance criterion 2 ("an
adversarial hunt round finds no remaining single-token-expansion
interpreter-head bypass") is not met by this round's hunt — it found
two. Resolution path: extend `EXPANSION_HEAD_C_FLAG_RE`'s alternation to
also match `\$'[^']*'` (ANSI-C quoting) as a head form, and change the
flag-adjacency requirement from `\s+` to something that also accepts a
backslash-newline continuation (e.g. `(?:\s|\\\n)+`) before landing this
as a closing fix for #233.

**2. Non-blocking, undisclosed — the fix denies more than interpreter
heads.** Because `EXPANSION_HEAD_C_FLAG_RE` cannot resolve what an
expansion head actually names, it denies ANY single-token-expansion head
followed by a `-c`/`-e`-shaped flag, including ordinary non-interpreter
tools reached through the same shell tool-selection idiom the issue's
own examples use (`${TOOL:-default}`, `$(which tool)`):

```
derived: bash /tmp/probe233/overreach_test.sh /tmp/wt372/core/hooks/board-gate.sh
FAIL tar-create-via-expansion     want=allow got=deny | echo docs/issue-3/reports/decoy.md ; ${TAR:-tar} -c -f out.tar .
FAIL curl-cookiejar-via-expansion want=allow got=deny | echo docs/issue-3/reports/decoy.md ; ${CURL:-curl} -c cookies.txt https://example.com
FAIL grep-count-via-expansion     want=allow got=deny | echo docs/issue-3/reports/decoy.md ; ${GREP:-grep} -c foo file.txt
FAIL vim-exmode-via-expansion     want=allow got=deny | echo docs/issue-3/reports/decoy.md ; ${EDITOR:-vim} -c ':wq' file.txt
FAIL ls-via-expansion             want=allow got=deny | echo docs/issue-3/reports/decoy.md ; $(which ls) -c .
FAIL sed-inplace-via-expansion    want=allow got=deny | echo docs/issue-3/reports/decoy.md ; ${SED:-sed} -e 's/a/b/' file.txt
```

`derived: bash /tmp/probe233/overreach_test.sh /tmp/wtmain/core/hooks/board-gate.sh`
→ all 6 `OK   ... want=allow got=allow` on `origin/main` — every one of
these is a genuine new denial PR #372 introduces, not a pre-existing
restriction. This is not necessarily wrong: the shape truly is
statically unanalyzable (the gate cannot tell `${TAR:-tar}` from
`${x:-python3}` any more than a human reading only the text can), and
this repo already denies a *literal* interpreter head's `-c`/`-e`
regardless of script content, so extending the same "unanalyzable, so
deny" posture to an unresolvable head is a consistent generalization,
not a new severity class. But PR #372's own test plan and record do not
mention this cost anywhere, and this is exactly the "quietly
re-broadens" pattern the brief for this round warned about (the pattern
that sent round 3 back). Judgment: proportionate as a security default,
but should have been named as a deliberate tradeoff in the PR body
rather than landing silently — a maintainer reading only the PR
description would not know `${SED:-sed} -e '...'` now denies.

**3. Non-blocking, factual — landing both PR #372 and PR #367 produces a
real merge conflict, not just adjacent additions, and PR #372's "Closes
#233" does not carry what PR #367 still carries.** Test-merged both
onto `origin/main` in a throwaway worktree:

```
derived: git worktree add /tmp/mergetest origin/main && cd /tmp/mergetest \
  && git merge --no-ff pr-372 && git merge --no-ff pr-367
자동 병합: core/hooks/board-gate.sh
충돌 (내용): core/hooks/board-gate.sh에 병합 충돌
자동 병합: core/hooks/tests/run-board-gate-tests.sh
자동 병합: core/hooks/tests/run-scope-gate-tests.sh
충돌 (내용): core/hooks/tests/run-scope-gate-tests.sh에 병합 충돌
자동 병합: docs/handbooks/board-gate-tests.md
충돌 (내용): docs/handbooks/board-gate-tests.md에 병합 충돌
자동 병합: docs/issue-233/reports/secure-coding-input-validation-injection-defense-bcd7fd6a.md
충돌 (추가/추가): ...에 병합 충돌
자동 병합: warrant/hooks/lib/scope-gate.py
충돌 (내용): warrant/hooks/lib/scope-gate.py에 병합 충돌
```

Both gate-code conflicts are on the exact same `VAR_INTERP_RE`
definition (`core/hooks/board-gate.sh:563` on PR #372's branch,
`core/hooks/board-gate.sh:611` on PR #367's branch), not adjacent lines:
PR #372 keeps the pre-existing uniform `-[ce]` mapping for the
variable-assignment-indirection clause and adds a new, separate
`EXPANSION_HEAD_C_FLAG_RE` block beside it; PR #367 changes that same
`VAR_INTERP_RE` definition itself to a per-head split (`-c` only for
`python3?|bash|sh|zsh`, `-e` only for `perl|ruby|node|nodejs`) and
states a jurisdiction limit plus drops `perl` from the `-c`/`-e`
give-back list. Landing order does not remove the conflict — whichever
PR lands second needs a human to decide how the two designs compose
(does the per-head narrowing apply to the new expansion-head clause
too, or only to the old literal/variable-indirection clauses?), not a
mechanical rebase.

Confirmed via diff that PR #372 does not itself state a jurisdiction
limit, does not narrow the `-c`/`-e` give-back to a per-head allowlist,
and does not touch the `perl` give-back at all
(`derived: git diff origin/main..pr-372 -- core/hooks/board-gate.sh
warrant/hooks/lib/scope-gate.py` shows only the new
`EXPANSION_HEAD_C_FLAG_RE`/mirrored-clause additions, no changes to
`INTERPRETER_HEADS`/`INLINE_FLAG_WORDS`/`VAR_INTERP_RE`'s existing
mapping). PR #372's summary itself says this is deliberate ("does not
touch the literal-interpreter-head -c/-e handling at all"). Given that,
"Closes #233" is a claim about the expansion-class bypass specifically,
not about PR #367's separate per-head-narrowing/jurisdiction work — the
issue's own acceptance criteria (quoted at the top of this record's
task) never mention a per-head allowlist or a jurisdiction statement, so
PR #372 not carrying those is not itself dishonest. What makes "Closes
#233" not currently honest is finding 1 above: the class is not fully
closed on PR #372's own branch, independent of PR #367 entirely.

**4. Standing invariants — all 4 hold, no finding, included for
completeness per this round's brief:**

```
derived: cd /tmp/wt372 && git diff origin/main -- core/hooks/board-gate.sh core/hooks/tests/run-board-gate-tests.sh core/hooks/tests/run-scope-gate-tests.sh warrant/hooks/lib/scope-gate.py | grep -E "^\+" | grep -iE "\brole\b" | wc -l
0
```
retired-role-axis: 0 hits, no return.

```
derived: cd /tmp/wt372 && python3 -m pytest -q 2>&1 | tail -6
FAILED tests/test_promoted_hooks.py::test_proposal_shape_gate_refuses_missing_sections
FAILED tests/test_promoted_hooks.py::test_survey_order_gate_refuses_proposal_without_survey_or_skip
FAILED tests/test_silent_failure_repros.py::test_A5_trailer_gate_quote_split_commit_is_detected
3 failed, 79 passed in 7.29s
derived: cd /tmp/wtmain && python3 -m pytest -q 2>&1 | tail -6
(identical 3 names, 3 failed, 79 passed in 7.37s)
```
no-new-bug: identical failing-test-NAME set (3 names, both checkouts).
Gate suites: `bash core/hooks/tests/run-board-gate-tests.sh` → PR #372
`155 passed, 2 failed` / `origin/main` `143 passed, 2 failed`, both
failing on the identical 2 names (`feasibility-spikes`,
`ops-postmortems`); `bash core/hooks/tests/run-scope-gate-tests.sh` → PR
#372 `58 passed, 0 failed` / `origin/main` `46 passed, 0 failed` — fewer
cases only, `origin/main` lacks the new test cases PR #372 adds.

```
derived: python3 /tmp/probe233/overhead.py /tmp/wt372/core/hooks/board-gate.sh (N=100, neutral "echo hi" payload)
9.67ms/call avg over 100
derived: python3 /tmp/probe233/overhead.py /tmp/wtmain/core/hooks/board-gate.sh (N=100, same payload)
8.52ms/call avg over 100
```
overhead: ~1.15ms difference at N=100, well within the 4-18ms swing
observed between repeated runs at N=30 on the same unchanged binary
(subprocess-startup noise) — no meaningful increase. (See "What did not
work" for why `overhead.py`'s later, differently-configured state was
not used for this number.)

```
derived: cd /tmp/wt372 && bash core/hooks/tests/run-fleet-scan-tests.sh 2>&1 | tail -3
pass=26 fail=1
derived: cd /tmp/wtmain && bash core/hooks/tests/run-fleet-scan-tests.sh 2>&1 | tail -3
pass=26 fail=1
```
monitor/watch: identical `pass=26 fail=1`, identical failing case name
(`live fleet run produces 43 repo rows`, `want=43 got=44`) on both
checkouts — fires and fails identically, not quieter, not broken.

**Minor, non-blocking — board-gate.sh/scope-gate.py disagree on process
substitution, but it is not exploitable.** `<(echo python3) -c 'import
os'` denies on `scope-gate.py` (its broader `UNANALYZABLE_WRITE_SHAPE`
pattern already catches it) but allows on `board-gate.sh` (its
`EXPANSION_HEAD_C_FLAG_RE` alternation has no `<(...)` form). Confirmed
this is not a live bypass, only a gate-text-match gap: process
substitution resolves to a `/dev/fd/N` path backed by a pipe, not an
executable, and running it directly fails —
`derived: bash -c "<(echo python3) -c 'import os'"` →
`bash: 줄 1: /dev/fd/63: 허가 거부` (Permission denied), exit 126, no
write occurred. Not reported as a blocking finding; noted for
completeness since board-gate and scope-gate diverging on the same
shape is itself worth tightening for consistency.

## Next steps

`loop_state: complete` for this record — the verification is finished
and its result (a blocking finding plus 3 non-blocking findings) is
reported. Issue-233 itself remains open: PR #372 should not land as
"Closes #233" as it stands. The concrete next unit of work is extending
`EXPANSION_HEAD_C_FLAG_RE` (`core/hooks/board-gate.sh`) and its mirrored
clause (`warrant/hooks/lib/scope-gate.py`) to also match `$'...'`
(ANSI-C quoting) as a head form and to accept a backslash-newline
continuation before the flag, then re-hunting before landing — the same
"fix, then re-hunt before landing" sequence PR #372's own record
followed for its 4 hunt-round additions, just not far enough. Separately
(not blocking #233's closure, but relevant to whoever lands next): PR
#367 and PR #372 need a human decision on how their two `VAR_INTERP_RE`
designs compose before either merges, since the conflict is on identical
lines with different designs, not a mechanical rebase.
