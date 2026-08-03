---
kind: observation-record
subject: issue-98
produced_by: execution-observation
observed_role: implementation
observed_pr: 103
observed_commits: 27a0c8aaeba542400f7c3c43828b89c94ffa2d9a, e51bc09a4ea10965027e692edd5d7f1408a73951
observed_merge_commit: 9cd8a20f1779a180a42e431d1ae07d6ad797c71b
loop_state: landed
upstream:
  - path: docs/issue-98/proposals/2026-08-03-independent-observation-of-pr-103.md
    sha: f9604cdd0d258cbb4671a284c15fe908c2342c74
  - path: docs/issue-98/reports/execution-observation/survey.md
    sha: e62b8004511c3ec4319cc71d6914563cdda87633
  - path: docs/issue-98/reports/execution-observation/scout-brief.md
    sha: f473ca05eaf4c9808138ff8e57cf3850361c75d4
---

# Execution observation record — issue-98 / implementation (PR #103)

## Independence

This role did not author or edit the observed artifact, in this session or
any other. PR #103, its commits `27a0c8a` (propose) and `e51bc09` (deliver),
its tests, and the implementation role's own record under
`docs/issue-98/reports/` were produced by the implementation role; nothing
under `core/`, under `core/hooks/tests/`, or under another role's report or
proposal path was written or modified here. The observed role's code was not
re-executed: no gate was invoked, no test harness was run, no wrapper payload
was fired at a live hook. Evidence is committed artifacts only — commit
diffs and pre-image blobs read through `git show`/`git diff`, PR and issue
metadata read through `gh`, and the observed role's own record read at its
pinned blob `9f833bbbf25d19b913a5155ace428dc3c3b7d02c`. Every verdict below
follows this statement, none precedes it.

## Why

Phase 2, opened by the issue-level comment whose entire body is the exact
string `APPROVE issue-98/execution-observation`, posted by `jjongkwann` — an
account listed in `docs/specs/approvers.md:2` — at 2026-08-03T08:19:03Z
(https://github.com/tokenmaxxxer/tokenmaxxxer-core/issues/98#issuecomment-5163954111).
PR #104's author is that same account, so this is single-account mode and the
exact-string issue comment is the correct approval path
(`9cd8a20:core/contract/role-handoff-contract.md:675-690`). The verdict
levels and their evidence were fixed before any evidence work, in the phase-1
proposal committed at `850a99c` (blob `f9604cd`, "Which verdict levels will
be checked, and against what"); this record renders exactly those three
levels against exactly that evidence, and nothing else.

## What was done

Five evidence lines (a)–(e), declared in advance at `f9604cd:51-89`, were
answered by reading pinned artifacts: the two commits of PR #103, the
observed role's own record at blob `9f833bb`, the pre-image blobs at
`e51bc09^`, the issue-100 decision document at `a339ad9`, and the issue/PR
metadata. Three verdicts (outcome, trajectory, step) follow, then five
findings in the four-part blameless shape and one observation charged to
nobody. No file outside this role's own report path was written.

## Method, and the limit carried over from phase 1

The phase-1 proposal (`f9604cd:91-104`, "Method, and its limits") declared
that this role does not re-run the observed role's code, so every
before/after determination is **analytic** — the pre-image text and the case
input, reasoned through — and is labelled as such rather than presented as an
execution result. That limit is honoured here. Statements marked
**(analytic)** are derived from committed pattern text and committed case
input; statements marked **(artifact)** are direct readings of a blob, diff
or API record.

Blob pinning, per the invoking instruction: issue #99's delivery merged after
PR #103 and changed `core/hooks/board-gate.sh` again on `main` — blob
`928f7494af070791ecfcbcb4b5ca806d58ba7d6b` at `origin/main` versus
`70de08dd040817a206f7e1e57eae42aecfc3e861` at `9cd8a20`. Every board-gate
reading below is therefore resolved through `git show <commit>:<path>` at
`e51bc09^`, `e51bc09` or the merge commit `9cd8a20`, never at `origin/main`
HEAD and never from the working tree. `core/hooks/lib/gate-lib.py`
(`7e630d2162474f8ccf7c0b84be2e1784d5246a43`) and `core/hooks/gh-guard.sh`
(`0734383a8335629552b64fd3e0d933e89cc8bd05`) happen to be byte-identical at
`9cd8a20` and `origin/main`; they are still cited at `9cd8a20`.

## Verdict — outcome

**Landed. All four of issue #98's numbered requirements are met in
`e51bc09`, with one requirement (3) met on evidence that is weaker for 5 of
its 14 cases than the requirement's own wording asks, and one behavior change
in board-gate that the PR's own artifacts twice describe as absent.**
(artifact)

Against issue #98's four numbered requirements
(https://github.com/tokenmaxxxer/tokenmaxxxer-core/issues/98):

1. **Requirement 1 ("래퍼 클래스를 클래스로 막을 것 — 문자열 몇 개 추가가
   아니라"), with its explicit reuse check — met.** The fix is two reusable
   primitives, not phrase patterns: `WRAPPER_HEADS` as a 10-element tuple at
   `9cd8a20:core/hooks/lib/gate-lib.py:248-249` and
   `gate_wrapper_head_before(cmdline, span_start)` at `:258`, consumed from
   exactly one production call site, `9cd8a20:core/hooks/gh-guard.sh:147`.
   The reuse-before-reimplementation check the requirement demands was
   performed and acted on: `TRANSPARENT`/`_head_of` were **removed** from
   `board-gate.sh` (the deletion hunk is visible in
   `git diff e51bc09^ 9cd8a20 -- core/hooks/board-gate.sh`, and
   `git show 9cd8a20:core/hooks/board-gate.sh | grep -n TRANSPARENT` returns
   nothing) and relocated to `gate-lib.py:194-245`, with `board-gate.sh:223`
   now calling `gate_lib.gate_head_of(stripped)`. No second copy was grown.
2. **Requirement 2 (board-gate's own `READ_UNLESS_INPLACE` `awk`/`sed`
   quoted-redirect check) — met.** `9cd8a20:core/hooks/board-gate.sh:231-241`
   replaces `if head in READ_UNLESS_INPLACE and not INPLACE.search(stripped)`
   with a three-way write test adding a **raw** `FILE_REDIR.search(stripped)`
   for `awk`/`gawk` and a new `SED_WRITE_CMD = re.compile(r"\b[wW]\s+\S")`
   (`:175`) for `sed`; the two cases are pinned as `deny` at
   `9cd8a20:core/hooks/tests/run-board-gate-tests.sh:306-307`
   (`awk-quoted-redirect-foreign`, `sed-w-cmd-foreign`).
3. **Requirement 3 (regression cases must fail on pre-change main; negative
   space must survive) — met for the negative space and for 9 of the 14
   wrapper deny cases on cited evidence; the remaining 5 are asserted against
   pre-change main but evidenced against a different baseline.** See (a) and
   (c) below; charged as Finding 2.
4. **Requirement 4 (handbook updated in the same commit) — met.**
   `git show e51bc09 --stat` shows `docs/handbooks/board-gate-tests.md`
   (+40), `docs/handbooks/gate-house-standard.md` (+31) and
   `docs/handbooks/gh-guard-tests.md` (+53) in the delivery commit itself,
   not a follow-up.

### (a) Do the 14 wrapper deny cases pin a pre-change failure?

**Yes for the 9 issue-named cases on the record's own cited run, and yes
analytically for all 14 — but the record's cited evidence for the 5
hunt-found cases is a different baseline than requirement 3 names.**

- The 14 deny cases exist and I counted them at the pinned blob:
  `9cd8a20:core/hooks/tests/run-gh-guard-tests.sh:94-102` (9 issue-named:
  `wrapper-bash-c`, `-bash-lc`, `-timeout-bash-c`, `-env-bash-c`,
  `-xargs-bash-c`, `-nohup-bash-c`, `-python3-c`, `-sh-c`, `-eval`) and
  `:110-113` plus `:117` (5 hunt-found: `wrapper-timeout-flag-arg`,
  `-nice-flag-arg`, `-env-flag-arg`, `-xargs-space-flag`, `-perl-e`). A
  15th `wrapper-*` case at `:124` (`wrapper-bash-c-plain-grep`) is a
  deliberate over-block, not a bypass case. (artifact)
- Pre-change failure for the 9: the record at blob `9f833bb:221-231` reports
  a `git stash` of the three source files with the new cases left in the
  tree, re-running the suite, and getting "10 FAILs (all 9 original wrapper
  cases plus `wrapper-bash-c-plain-grep`) … all `want=deny got=allow`",
  then `git stash pop` returning to 0 failed. That is a real pre-change
  measurement, reported by the role that ran it. (artifact)
- Pre-change failure for the 5: the same entry states plainly that "the 5
  hunt-driven cases were added after this stash/pop cycle, against the
  already-hunt-fixed code" (`9f833bb:228-230`), and the next entry
  (`9f833bb:232-243`) evidences them against "the gh-guard.sh committed at
  that point in this session (the first `gate_wrapper_head_before` design)",
  not against pre-issue-98 `main`. Its `name:` line nonetheless claims "not
  just against pre-issue-98 main" (`9f833bb:232`), and the preceding entry's
  `name:` claims "all 15 new gh-guard wrapper/hunt cases fail … on the
  pre-issue-98 code" (`9f833bb:221`) while its own `result:` documents 10.
  (artifact)
- The substantive claim is nevertheless true. (analytic) At `27a0c8a` the
  whole of gh-guard's matching is `dq = gate_lib.gate_dequote(cmd)` /
  `for pat, why, dequote in RULES: if re.search(pat, dq if dequote else cmd)`
  (`27a0c8a:core/hooks/gh-guard.sh:128-130`) — there is no wrapper branch at
  all. For every one of the 5, the `gh pr merge` payload sits inside the
  quoted span that `gate_dequote` blanks, so no `dequote=True` rule can
  match, and the 8 `dequote=False` rules match different verbs; the verdict
  is `allow` against a `want=deny` case. So all 14 would have failed on
  pre-change `main`. The defect is in the citation, not the fix.

### (b) Did the `TRANSPARENT` relocation change board-gate behavior?

**Yes — in the permissive direction, for `timeout`/`nohup`-prefixed
read-only commands under `docs/`, and no test in this PR pins it.** This
contradicts the proposal's "no behavior change for board-gate's own
`_write_candidate_segments`" (`27a0c8a:docs/issue-98/proposals/2026-08-03-wrapper-head-class-fix-for-dequote-bypass.md`,
"What will be done", bullet 2) and the record's "`gate_head_of`/`TRANSPARENT`
themselves are unchanged, still used as-is by `board-gate.sh`"
(`9f833bb:96-98`). Charged as Finding 1.

- `TRANSPARENT` grew from 6 entries to 8:
  `("xargs", "env", "time", "nice", "command", "builtin")` at
  `27a0c8a:core/hooks/board-gate.sh:172` became
  `("xargs", "env", "time", "nice", "command", "builtin", "timeout",
  "nohup")` at `9cd8a20:core/hooks/lib/gate-lib.py:194-195`, plus
  `TRANSPARENT_TAKES_ARG = ("timeout",)` at `:200`. (artifact)
- `gate_head_of`'s only production call site in the whole `core/hooks` tree
  at `9cd8a20` is `board-gate.sh:223` — `git grep -n gate_head_of 9cd8a20 --
  core/hooks` returns that one line plus the definition, one docstring
  mention and test files. gh-guard reaches the wrapper class through
  `gate_wrapper_head_before`, which the docstring at
  `9cd8a20:core/hooks/lib/gate-lib.py:267-270` says is "deliberately not via
  gate_head_of's TRANSPARENT hop-by-hop walk". (artifact)
- Consequence: `timeout 30 cat docs/<foreign record>` resolved to head
  `timeout` before the change — not in `READ_ONLY_HEADS`
  (`9cd8a20:core/hooks/board-gate.sh:100-103`), not `git`, not
  `READ_UNLESS_INPLACE` — so it reached `failing.append(seg)` and was
  judged as a write candidate against R1–R5. After the change,
  `_resolve_transparent` (`9cd8a20:core/hooks/lib/gate-lib.py:203-236`) hops
  past `timeout`, consumes its one bare DURATION word, and returns `cat`,
  which hits `if head in READ_ONLY_HEADS: continue`
  (`board-gate.sh:229-230`); with no failing segment left the gate takes
  `allow()` at `board-gate.sh:261-263`. Same for any `nohup`-prefixed
  read-only head. (analytic, from the two pinned blobs)
- Direction and blast radius: the change **loosens**, and only toward reads.
  Every member of `READ_ONLY_HEADS` writes only through a redirection, and a
  redirection outside quotes is caught earlier at `board-gate.sh:220`
  (`gate_outside_quotes(seg, FILE_REDIR.pattern)`); `bash`/`tee`-shaped heads
  are not in the list, so `timeout 30 bash -c "… > …"` still fails closed.
  The loosening is in the same direction as the gate's own documented intent
  ("Reading a FOREIGN record is sanctioned (s4 READ-broad)",
  `board-gate.sh:104-108`). It is not a security hole; it is an undeclared,
  untested change. (analytic)
- Nothing pins it: the 8 new board-gate cases at
  `9cd8a20:core/hooks/tests/run-board-gate-tests.sh:297-320` are three
  `bash -c`-payload foreign-record denies (`bash-wrapper-bash-c-foreign`,
  `-timeout-foreign`, `-nohup-foreign`), one own-record allow, the two
  `awk`/`sed` denies, the `gap-awk-comparison-over-block` deny and
  `sed-plain-read-foreign` allow. All four wrapper cases resolve to head
  `bash` and stay `deny` on both sides — the record confirms as much at
  `9f833bb:244-252` ("the 4 wrapper-headed foreign-record cases … already
  passed pre-fix"). No case exercises a `timeout`/`nohup` prefix in front of
  a `READ_ONLY_HEADS` head, which is exactly where the verdict flips.
  (artifact)
- The other two board-gate touches are genuinely behavior-neutral.
  `SEGMENT` is now built from `gate_lib.GATE_QUOTE_SPAN.pattern`
  (`9cd8a20:core/hooks/board-gate.sh:140`), and that pattern at
  `9cd8a20:core/hooks/lib/gate-lib.py:174` is
  `(?<!\\)'[^']*'|(?<!\\)"(?:[^"\\]|\\.)*"` — character-for-character the
  prefix the deleted inline literal carried before `|\|\||&&|[|;\n]`, as the
  removal hunk shows. The `awk`/`sed` additions only add write triggers, so
  no previously-failing segment can start passing through them. (artifact)

### (c) Is the negative space intact?

**Yes, with two over-blocks that are declared rather than hidden.**
(artifact + analytic)

- The three issue-94 negative-space cases are present and unmodified at
  `9cd8a20:core/hooks/tests/run-gh-guard-tests.sh:78-80`
  (`quote-gh-pr-merge-in-grep`, `quote-review-approve-in-grep`,
  `quote-issue-create-in-grep`), all `run allow`, and the suite they belong
  to is reported `0 failed` in the record (`9f833bb:213-220`). (artifact)
- Structurally they cannot regress: the new detection is a second branch,
  `if dequote and re.search(pat, cmd)` … `and
  gate_lib.gate_wrapper_head_before(cmd, span.start())`
  (`9cd8a20:core/hooks/gh-guard.sh:144-148`), which denies only when a
  `WRAPPER_HEADS` word with a code-shaped flag precedes the span. For
  `grep -n "gh pr merge" spawn.py` the preceding words are `grep`, `-n` —
  no wrapper head — so the helper returns `""` and the allow stands.
  (analytic, from `gate-lib.py:258-300`)
- The board-gate side keeps its read: `sed-plain-read-foreign` is `run allow`
  at `9cd8a20:core/hooks/tests/run-board-gate-tests.sh:320`. (artifact)
- Two deliberate over-blocks are pinned as `deny` with the reason written
  next to them, per the file's own `gap-*` convention:
  `wrapper-bash-c-plain-grep` (`run-gh-guard-tests.sh:124`, a legitimate grep
  nested inside a real `bash -c`) and `gap-awk-comparison-over-block`
  (`run-board-gate-tests.sh:319`, `awk '$1 > 5 {print}'`'s comparison read as
  a redirect). Both were named as accepted costs in the approved proposal's
  Rationale and "Out of scope" before approval, so neither is a silent
  narrowing. (artifact)

### (d) Is the recorded out-of-scope limit real, and how risky?

**The limit is real and correctly scoped — but it is not the class the
invoking prompt named.** The value-taking-flag wrapper class
(`nice -n 10 bash -c …`, `env -u FOO …`, `timeout -s KILL 30 …`,
`xargs -I fmt …`) is the class this PR **closed**, not the one it left open:
the record lists it under Hunt as "fixed" (`9f833bb:185-188`) and pins it
with five deny cases at
`9cd8a20:core/hooks/tests/run-gh-guard-tests.sh:110-113,117`. (artifact)

The actual residual is different: adjacent-quoted-string shell concatenation
— `bash -c "gh pr mer""ge 5"`, or `"…"` next to `'…'` with no separator —
which splits one real shell word across two `GATE_QUOTE_SPAN` matches and so
defeats both the new per-span check and the pre-existing raw-`cmd` prefilter
(`9f833bb:192-204`, restated as the single open finding at `:265-277`).
(artifact)

Risk, judged from the artifacts: **real but bounded, and correctly left out
of this issue's write set.** It requires deliberate obfuscation, which is
inside this gate's threat model (the gate exists to stop an agent session
from performing human-only acts), so it is not merely theoretical. Against
that: it is a property of `GATE_QUOTE_SPAN`/`gate_dequote` themselves
(`9cd8a20:core/hooks/lib/gate-lib.py:174`), predates issue-98 (it arrived
with issue-94's dequoting), affects all three gates' quote-aware matching
regardless of any wrapper class, and is neither introduced nor worsened by
`e51bc09` — the new branch only ever adds denials. Fixing it means a real
shell tokenizer, which is a different issue than "close the wrapper class".
Recording it as an open finding rather than quietly fixing or quietly
dropping it is the right call; the record's own framing at `9f833bb:272-277`
says exactly this. (analytic)

One consequence worth stating plainly: because `gate_wrapper_head_before`
scans local words directly instead of walking `TRANSPARENT`
(`gate-lib.py:267-282`), the `timeout`/`nohup` entries added to
`TRANSPARENT` are not needed by the delivered gh-guard design at all — the
justification given for the extension in the approved proposal ("gh-guard's
new per-span resolver does need to see through them") was voided by the hunt
redesign described at `9f833bb:82-98`, but the extension stayed. That is the
mechanism behind Finding 1.

### (e) Was issue-100's citation convention honoured here?

**No.** `9f833bb:5` is `code_under_review: 27a0c8aaeba542400f7c3c43828b89c94ffa2d9a`
— a bare 40-hex token, which Decision 1 of
`a339ad9:docs/issue-100/decisions/2026-08-03-record-citation-format-and-kind-convention.md:25-29`
forbids ("cites the reviewed write set as a file list …, never a bare commit
sha"). All five `closed_checks[]` entries use `code_sha:`
(`9f833bb:215,222,233,245,254`) where Decision 2 (`:51-55`) requires
`ref: <file>:<line>`. Every one of those seven values is the same sha,
`27a0c8a` — the propose commit, whose `--stat` is three doc files and zero
code — so the record's code citations point at a commit containing none of
the code they describe, which is the exact defect issue #100 was authored to
end. `kind: coding-record` (`9f833bb:2`) does match Decision 4 (`:92-103`).
(artifact) Charged as Finding 3, with its exculpating chronology stated
there.

## Verdict — trajectory

**Sound.** The phase-1→phase-2 path is correct at every gate, on the
artifacts. (artifact)

- **Scouted before proposing.** `27a0c8a --stat` is exactly three files:
  the proposal, `docs/issue-98/reports/implementation/scout-brief.md` (+50)
  and `.../survey.md` (+159) — 507 insertions, zero code. The survey
  pre-dates the proposal in the same commit and carries live measurements
  (the "all … issue-named wrapper variants bypass" table) rather than
  assertions.
- **Surveyed before proposing, and the survey aimed the proposal.** The
  proposal's Rationale repeatedly decides against the survey's findings —
  e.g. board-gate's `FILE_REDIR` half needs no fix because `_head_of`
  already fails closed there, which is why requirement 2 was narrowed to
  `READ_UNLESS_INPLACE` and not to `FILE_REDIR`.
- **Stopped at the phase boundary.** Propose commit `27a0c8a` authored
  2026-08-03T06:43:40Z; PR #103 opened 06:44:20Z (`gh pr view 103`,
  `createdAt`); no code in the tree at that point.
- **Real human approval, correct path, before any execution work.** Issue
  #98 carries exactly two comments; the first is authored by `jjongkwann`
  at 2026-08-03T06:49:31Z with entire body `APPROVE issue-98/implementation`
  (https://github.com/tokenmaxxxer/tokenmaxxxer-core/issues/98#issuecomment-5163202727).
  `jjongkwann` is listed at `docs/specs/approvers.md:2`; PR #103's author is
  the same account and its `reviews` array is empty, so single-account mode
  applies and the exact-string issue comment is the right act. The delivery
  commit `e51bc09` is authored 07:38:40Z — 49 minutes **after** the
  approval, never before it. Merged 07:58:36Z as `9cd8a20`.
- **Delivery stayed inside the approved scope.** `gh pr diff 103
  --name-only` lists 13 files; every code and handbook path among them
  appears in the proposal's own `files:` header, and nothing outside it was
  touched — notably `core/hooks/approval-gate.sh` and
  `core/hooks/tests/run-approval-gate-tests.sh` stayed untouched, which the
  proposal had explicitly placed out of scope (issue-94 Finding 5).
- **The mid-build widening that did happen was pre-declared.** The hunt
  redesign (`9f833bb:82-105`) changed `gate_wrapper_head_before`'s internals
  and added 5 cases after the first design was already written; that is
  inside the approved write set and inside the proposal's own "How you'll
  know it worked" clause, not a scope exception. The one thing the hunt
  found and did **not** fix was declared as an open finding rather than
  absorbed silently (`9f833bb:265-277`).
- **One gap against contract §19 as written, not a violation of it.** §19
  (`9cd8a20:core/contract/role-handoff-contract.md:649-651`) asks that
  "phase 2 marks, per clause, the commit or hunk that fulfilled it". The
  proposal's checklist is 9 `- [ ]` clauses; the record answers them as 5
  numbered prose items under `## What was done` (`9f833bb:28-105`) plus 5
  `closed_checks`, all still `- [ ]` in the proposal at `9cd8a20`. Every
  clause is in fact covered by the prose, so this is a formatting gap in a
  requirement whose purpose is met, not a missing step. Recorded here, not
  charged as a finding.

## Verdict — step

Five artifacts are deficient, none fatal. In severity order:

1. `9cd8a20:core/hooks/lib/gate-lib.py:194-195` (+ `:200`) — the
   `TRANSPARENT` extension, whose board-gate effect is undeclared and
   unpinned → Finding 1.
2. `9f833bb:221-243` — the two `closed_checks` entries whose `name:` lines
   claim more than their own `result:` text evidences → Finding 2.
3. `9f833bb:5,215,222,233,245,254` — issue-100's citation convention not
   honoured, third consecutive recurrence → Finding 3.
4. `9cd8a20:docs/issue-98/proposals/2026-08-03-wrapper-head-class-fix-for-dequote-bypass.md:8,10`
   — `sha: <set at commit>` placeholders never resolved → Finding 4.
5. `27a0c8a` commit message and
   `27a0c8a:docs/issue-98/reports/implementation/survey.md` heading — "8"
   issue-named variants where the same PR's other artifacts say 9 →
   Finding 5.

No deficiency was found in the delivered code's behavior against the
requirements: the wrapper class is closed as a class, the `awk`/`sed` gap is
closed independently, and the negative space survives.

## Open findings

### Finding 1 — extending `TRANSPARENT` for a consumer that no longer uses it changed board-gate, undeclared and untested

- **Impact.** `board-gate.sh` now classifies `timeout …`/`nohup …` prefixed
  commands by the head they wrap instead of by the wrapper itself
  (`9cd8a20:core/hooks/lib/gate-lib.py:194-195` reached from
  `9cd8a20:core/hooks/board-gate.sh:223`). A command such as
  `timeout 30 cat docs/<another role's record>` was a write candidate before
  `e51bc09` and is an outright `allow` after it
  (`board-gate.sh:229-230` then `:261-263`). The direction is permissive and
  confined to reads — `READ_ONLY_HEADS` (`board-gate.sh:100-103`) contains no
  command that writes except through a redirection, and an unquoted
  redirection is caught first at `board-gate.sh:220` — so this is a
  false-positive reduction, not a hole. But it is a behavior change that the
  approved proposal describes as absent ("no behavior change for
  board-gate's own `_write_candidate_segments`",
  `27a0c8a:docs/issue-98/proposals/…-wrapper-head-class-fix-for-dequote-bypass.md`,
  "What will be done" bullet 2), that the record describes as absent
  (`9f833bb:96-98`), and that no case in
  `9cd8a20:core/hooks/tests/run-board-gate-tests.sh:297-320` pins in either
  direction.
- **Timeline.** Declared at `27a0c8a` with the rationale "board-gate doesn't
  need them today (an unrecognized head already fails closed there), but
  gh-guard's new per-span resolver does need to see through them". The hunt
  during phase 2 then rebuilt `gate_wrapper_head_before` to scan local words
  directly, "deliberately not via gate_head_of's TRANSPARENT hop-by-hop
  walk" (`9cd8a20:core/hooks/lib/gate-lib.py:267-270`,
  `9f833bb:82-98`) — after which the only production consumer of
  `TRANSPARENT` is board-gate itself
  (`git grep -n gate_head_of 9cd8a20 -- core/hooks` → `board-gate.sh:223`).
  The extension shipped in `e51bc09` regardless.
- **Root cause.** The pre-approval rationale reasons only about the
  fail-closed direction: an unrecognized head is *stricter*, so adding a
  head to `TRANSPARENT` looks free. It is not — moving a word into
  `TRANSPARENT` lets resolution continue to a head that may be in
  `READ_ONLY_HEADS`, flipping a deny to an allow. The redesign then removed
  the reason for the change without anyone re-asking whether the change
  should stay, because the hunt's own review question was "does the
  imprecision hurt board-gate?" (answered: no, it fails closed) rather than
  "does the extension still have a consumer?".
- **Action item (for the human to judge, not for this role to do).** Decide
  whether the loosening is wanted. If yes, pin it with one `run allow` case
  of the shape `timeout 30 cat <foreign record>` in
  `core/hooks/tests/run-board-gate-tests.sh` and correct the two "no
  behavior change" statements. If no, drop `timeout`/`nohup` from
  `TRANSPARENT` — the delivered gh-guard design does not read it.

### Finding 2 — two `closed_checks` names claim a baseline their own results do not show

- **Impact.** Requirement 3 of issue #98 asks that regression cases fail "변경
  전(현 main)". A reader auditing that requirement from the record's
  `closed_checks` names — "all 15 new gh-guard wrapper/hunt cases fail
  (wrong verdict) on the pre-issue-98 code" (`9f833bb:221`) and "…(not just
  against pre-issue-98 main)" (`9f833bb:232`) — would believe 15 cases were
  measured against pre-issue-98 `main`. The `result:` texts show 10 measured
  that way (`9f833bb:223-231`) and 5 measured against an intermediate,
  in-session `gate_wrapper_head_before` (`9f833bb:234-243`). The claim
  happens to be true — at `27a0c8a:core/hooks/gh-guard.sh:128-130` there is
  no wrapper branch at all, so all 14 deny cases resolve `allow` pre-change
  (analytic) — so the defect is evidentiary precision, not a false verdict.
- **Timeline.** Both entries were written in `e51bc09`, after the hunt added
  the 5 cases to a tree that already carried the fix; the honest sequencing
  note is present in the same entry (`9f833bb:228-230`), which is why this is
  a naming defect rather than a concealment.
- **Root cause.** The `name:` field was written as the check's *intent*
  ("all N cases pin a pre-change failure") and the `result:` field as what
  was actually run; when the case count grew mid-session the name was
  updated to 15 and the result was not re-measured.
- **Action item.** Either re-word the two `name:` fields to the baseline each
  result actually used, or add one stash/pop measurement covering the 5
  hunt-found cases against `27a0c8a`. Neither changes any verdict.

### Finding 3 — the record's code citations point at a code-free commit again (third consecutive recurrence)

- **Impact.** `9f833bb:5` gives `code_under_review` as the bare sha
  `27a0c8a…` and all five `closed_checks` give `code_sha: 27a0c8a…`
  (`9f833bb:215,222,233,245,254`). `git show 27a0c8a --stat` is three
  documentation files and zero code, so every code citation in this record
  points at a commit that contains none of the code it describes. Decision 1
  (`a339ad9:docs/issue-100/decisions/2026-08-03-record-citation-format-and-kind-convention.md:25-29`)
  requires a file list; Decision 2 (`:51-55`) requires
  `ref: <file>:<line>` in `closed_checks`. This is the same defect the
  issue-90 and issue-94 observations each recorded once, and issue #100 was
  authored to end.
- **Timeline.** Issue #100's delivery merged as `a339ad9` at
  2026-08-03T07:17:31+09:00; `e51bc09` was authored at 07:38:40+09:00 — 21
  minutes later, so the convention was on the board first. But
  `git merge-base --is-ancestor a339ad9 e51bc09` exits **1** (measured this
  session): the `issue-98/implementation` branch was cut before `a339ad9`
  and never rebased, so neither the decision document nor the mechanical
  check added by it was in that session's tree.
- **Root cause.** The one mechanical check issue #100 installed is
  `core/hooks/record-fields-gate.sh:187-195` (at blob
  `021e60bb8e5a9b6a950dd8f615b53745b671a0fb`), which denies a bare-sha
  `code_under_review` for `role in ("coding","implementation")`. A hook that
  lives in the worktree cannot fire on a branch that predates it, so the
  gate was structurally unable to catch this instance — the convention
  landed on `main` between this branch's cut and its delivery. Not
  inattention by the observed role; a race between a convention and a
  long-lived branch.
- **Action item.** For the human: this recurrence is *not* evidence that
  issue #100's fix failed, and re-filing it as a repeat of #100 would
  misdiagnose it. What it shows is that a worktree-resident gate has no
  effect on branches cut before it — the candidate follow-up is a
  merge-time or CI-side check, or a rebase-before-deliver rule, not another
  hook in the same place.

### Finding 4 — the approved proposal's `upstream` shas were never filled in

- **Impact.** `9cd8a20:docs/issue-98/proposals/2026-08-03-wrapper-head-class-fix-for-dequote-bypass.md:8,10`
  both read `sha: <set at commit>`. Contract §1's common header
  (`9cd8a20:core/contract/role-handoff-contract.md:16-32`) defines
  `upstream[].sha` as "commit SHA the artifact was read at", so the
  proposal's basis is unpinned: a reader cannot tell which revision of the
  survey and scout brief the proposal was approved against.
- **Timeline.** Written at `27a0c8a` and unchanged through `e51bc09` and the
  merge — `git diff 27a0c8a e51bc09` touches this file not at all.
- **Root cause.** The placeholder is a self-reference problem the author
  could not resolve at write time (the survey's own sha does not exist until
  the commit that contains both is made) and no post-commit amend step
  exists for it — the same structural cause as Finding 3, in a different
  field.
- **Action item.** None for this role. If the human wants it closed, the
  general fix is the same one Finding 3 points at: resolve
  self-referential shas at merge time rather than at write time.

### Finding 5 — the PR's own artifacts disagree on how many wrapper variants the issue named

- **Impact.** Documentary only. `27a0c8a`'s commit message says "all 8
  issue-named wrapper variants" and
  `27a0c8a:docs/issue-98/reports/implementation/survey.md` carries the same
  "8" in its heading, while `9f833bb:214` says "all 9 issue-named wrapper
  variants" and `9cd8a20:core/hooks/tests/run-gh-guard-tests.sh:94-102`
  contains 9 cases. A later reader reconciling the PR against issue #98's
  repro list has to re-count to find which number is right (it is 9).
- **Timeline.** "8" written at `27a0c8a`, "9" written at `e51bc09`; neither
  document was corrected.
- **Root cause.** The issue's prose names its variants in two places and the
  survey counted one of them; the count was not re-derived when the test
  cases were enumerated.
- **Action item.** None material. Worth a one-word fix only if some later
  artifact is built on the "8".

### Observation (not charged as a finding)

Twice during this session — once while committing the phase-1 files
(recorded as U6 in `docs/issue-98/reports/execution-observation/survey.md` at
commit `e062d4a`) and once during read-only evidence collection — a `git`
command was refused by the live `board-gate.sh` because a *foreign record's
path appeared as text on the command line*, not as a write target: in the
second case the shell redirect went to `$TMPDIR` and the doc path was an
argument to `git show <sha>:<path>`. This is the current `main` gate
(post-issue-99), not the artifact under observation, and it is the same
path-token false-positive class the issue-94 observation already recorded.
Reported here so the human has the second data point; it is not charged
against PR #103, whose delivery neither introduced nor worsened it.

## Next steps

None for this role. The five findings and the observation stand in this
record on PR #104 for the human to judge; this role files no issues, opens no
follow-up, and does not touch the observed role's artifacts.

## Resolution path

Each finding is resolved by the human judging it on PR #104 and, if valid,
authoring the issue themselves (contract v3: issues are user-authored only).
A finding the human rejects needs no artifact change. If a finding is
accepted and fixed by a later role, that role's own record cites this
record's finding number; this file is not amended by another role.

## What did not work

Nothing blocking. Three frictions worth recording. First, the live
`board-gate.sh` refused two read-only `git` invocations for the path-token
reason described in the Observation above; both were reissued in a plainer
form (addressing the record's blob sha rather than its path) with no loss of
evidence. Second, `git show <blob>` on the observed record had to be used in
place of `git show <commit>:<path>` for the same reason, which is why this
record cites `9f833bb:<line>` rather than a path for the observed role's own
record. Third, two `Bash` calls that chained commands with `;` were refused
by the harness and were reissued as separate calls — no evidence was
affected.

## loop_state

- `phase-1` — survey, scout brief and proposal committed at `850a99c`; PR
  #104 opened; stopped for approval.
- `phase-2-opened` — approval comment verified byte-exact
  (issuecomment-5163954111); this record created as the first act of phase 2,
  before any verdict was rendered.
- `landed` — three-level verdict rendered against exactly the evidence lines
  the phase-1 proposal declared, five findings recorded with impact /
  timeline / root cause / action item, record committed on
  `issue-98/execution-observation` and delivered through PR #104.

## Verify

What was read, in this session, to support the verdicts above — no artifact
is cited that was not read here:

- `gh issue view 98` (body and both comments, with exact bodies and
  timestamps); `gh issue view 100` (body); `gh pr view 103 --json
  number,title,author,state,createdAt,mergedAt,mergeCommit,headRefName,
  baseRefName,url,reviews,comments,commits` (empty `reviews`, empty
  `comments`); `gh pr view 104`; `gh pr diff 103 --name-only`.
- `git show 27a0c8a --stat` and `git show 27a0c8a:` for the observed
  proposal in full (298 lines) and `…/implementation/survey.md`;
  `git show e51bc09 --stat` and the full patch of `e51bc09`.
- `git diff e51bc09^ 9cd8a20 -- core/hooks/board-gate.sh` (full patch); blob
  shas at `e51bc09^` / `9cd8a20` / `origin/main` for `board-gate.sh`,
  `gate-lib.py`, `gh-guard.sh`.
- Pinned blob reads at `9cd8a20`: `core/hooks/board-gate.sh:56-59,95-120,
  137-141,175,199-241,256-263`; `core/hooks/lib/gate-lib.py:174,194-300`;
  `core/hooks/gh-guard.sh:144-148`;
  `core/hooks/tests/run-gh-guard-tests.sh:74-128`;
  `core/hooks/tests/run-board-gate-tests.sh:288-325`. Pre-image reads at
  `27a0c8a`: `core/hooks/gh-guard.sh` rule loop (`:128-131`),
  `core/hooks/board-gate.sh:172`.
- The observed role's own record in full at blob
  `9f833bbbf25d19b913a5155ace428dc3c3b7d02c` (312 lines), including
  `## What was done`, `## Hunt`, `closed_checks`, `## Open findings`.
- `a339ad9:docs/issue-100/decisions/2026-08-03-record-citation-format-and-kind-convention.md`
  (Decisions 1–4); `record-fields-gate.sh` at blob
  `021e60bb8e5a9b6a950dd8f615b53745b671a0fb`;
  `9cd8a20:core/contract/role-handoff-contract.md:639-720`;
  `docs/specs/approvers.md`; this role's own phase-1 proposal
  (`f9604cd`), survey and scout brief.
- Measured directly here: `git merge-base --is-ancestor a339ad9 e51bc09`
  (exit 1); `git grep -n gate_head_of 9cd8a20 -- core/hooks` (one production
  call site); `git show 9cd8a20:core/hooks/board-gate.sh | grep -n
  TRANSPARENT` (no matches); the wrapper deny-case count at
  `run-gh-guard-tests.sh` (9 + 5, plus one over-block case).
- Evidence collection was fanned out to four read-only subagents, each
  required to return the citation coordinate plus a verbatim quote and no
  judgment; every coordinate a verdict above rests on was then read directly
  in this session at the pinned blob, and every verdict is my own.

No gate was invoked and no test harness was run at any point.
