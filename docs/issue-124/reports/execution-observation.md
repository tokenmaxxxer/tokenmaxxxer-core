---
kind: observation-record
subject: issue-124
produced_by: execution-observation
observed_role: implementation
observed_pr: 126
loop_state: landed
upstream:
  - path: docs/issue-124/reports/execution-observation/survey.md
    sha: ff9ad98
  - path: docs/issue-124/reports/execution-observation/scout-brief.md
    sha: ff9ad98
  - path: docs/issue-124/proposals/2026-08-04-independent-observation-of-pr-126.md
    sha: ff9ad98
---

# Execution observation — issue-124, step 2

## Independence

This role did not author, edit, or contribute to PR #126, to its commits
`7fcd4cd` / `fdb620d`, to the merge `43bd873`, or to the `implementation`
role's own record `docs/issue-124/reports/implementation.md`. It did not
re-run that role's task: `core/hooks/tests/run-approval-gate-tests.sh`,
`run-board-gate-tests.sh`, and `run-gate-lib-tests.sh` were never invoked
in this session, and no hook under `core/` was executed. The admissible
evidence used below is the commit diffs, the blobs pinned at `43bd873`,
the observed role's own phase-1 and phase-2 documents, the GitHub metadata
of issue #124 and PR #126, and — for the grammar axis — primary tool
synopses obtained directly in this session. This session's only write
surface is this file; nothing under `core/`, `warrant/`,
`docs/handbooks/`, or `docs/issue-124/reports/implementation*` is written
or modified by this role, and no issue is filed for anything found here.

Phase 2 opened on the issue comment created `2026-08-04T07:03:12Z` by
`jjongkwann`, body exactly `APPROVE issue-124/execution-observation`
(<https://github.com/tokenmaxxxer/tokenmaxxxer-core/issues/124#issuecomment-5175686896>);
`jjongkwann` is listed in `docs/specs/approvers.md:2` and is also the
author of this branch's PR #130, so this is contract v3 §19's
single-account path. This record was written as the first act of phase 2.
No other approval-shaped comment exists on issue #124: the only other
comment is `APPROVE issue-124/implementation`
(<https://github.com/tokenmaxxxer/tokenmaxxxer-core/issues/124#issuecomment-5175349028>),
which names a different subject-role pair and is not a near-miss of this
role's string.

## Why

Issue #124's execution plan has two steps: step 1 `implementation`
(landed as PR #126, merged `43bd873`) and step 2 this independent
observation. The approved phase-1 plan for step 2 — PR #130, proposal
`docs/issue-124/proposals/2026-08-04-independent-observation-of-pr-126.md`
— fixed, before any judgment was formed, which verdict levels would be
checked, against what evidence, and a decision rule for the issue's
requirement 3 (class exhaustion) that was pre-registered before any
enumeration result was seen. This record executes that plan.

## What was done

1. Read the observed role's artifacts first-hand: issue #124 and both of
   its comments, PR #126's metadata (`createdAt` `2026-08-04T06:11:15Z`,
   `reviews: []`, `mergedAt` `2026-08-04T06:46:00Z`), its two commits'
   full messages and full diffs, its file list, and the role's own
   proposal, survey, and record.
2. Read requirement 1 hunk-by-hunk against issue #124's prescribed
   minimum forms and against the approved proposal's frozen
   `## What will be done` text.
3. Read requirement 2 as code — the eight added test cases — plus the
   record's captured RED/GREEN blocks, checked for internal consistency
   against the diff. No suite was run.
4. Ran the pre-registered two-axis re-enumeration (`## Class exhaustion`):
   axis A (site enumeration at `43bd873`, widened past issue-114's two
   patterns) and axis B (grammar completeness of the two landed flag
   tables against primary tool synopses).
5. Wrote this record, the sole phase-2 artifact of this role.

### Evidence read this session

| artifact | pointer |
|---|---|
| issue #124 body and both comments | `gh issue view 124`, comment IDs 5175349028 / 5175686896 |
| PR #126 metadata, file list, reviews | `gh pr view 126` — `reviews: []`, 11 files |
| phase-1 commit | `7fcd4cd` (survey + proposal, +490, no code) |
| phase-2 commit | `fdb620d` (9 files, +537/−11) |
| observed proposal | `docs/issue-124/proposals/2026-08-04-close-remaining-…-r1-r2-r3.md` |
| observed survey | `docs/issue-124/reports/implementation/survey.md` |
| observed record | `docs/issue-124/reports/implementation.md` (408 lines) |
| landed blobs at merge | `43bd873:core/hooks/*`, `43bd873:docs/handbooks/*` |
| approvers list | `docs/specs/approvers.md:1-2` |
| primary specs | local `git --help` synopsis; `git --git-dir <path> log` probe; local `xargs` usage synopsis; man7 pages cited in `scout-brief.md:76-87` |

## Verdict 1 — outcome: did PR #126 land what issue #124 asked

**Requirement 1 (three habitats fixed in one delivery, each in the
minimum form the issue names) — met.** `fdb620d` is a single commit
carrying all three edits, each matching the issue's prescribed minimum:
R1 replaces the raw head derivation with `head =
gate_lib.gate_head_of(cmdline)` (`core/hooks/approval-gate.sh:122`
@`43bd873`), which is exactly the issue's "조기-allow head 판별을
`gate_lib.gate_head_of` 로 통일"; R2 adds `GIT_GLOBAL_VALUE_FLAGS =
("-C", "-c")` and an index-walking skip in `_git_subcommand`
(`core/hooks/board-gate.sh:187-192,212-222` @`43bd873`), the issue's
"값-받는 git 전역 플래그 스킵 추가"; R3 adds `TRANSPARENT_FLAG_TAKES_ARG`
and a consuming branch ahead of the generic bare-flag walk
(`core/hooks/lib/gate-lib.py:202-213,239-241` @`43bd873`), the issue's
"래퍼별 값-받는 플래그 처리 추가". No design deviation from the issue's
named minimum was taken, so the issue's "다른 설계를 고르면 제안에서 사유를
명시할 것" clause was never triggered
(`docs/issue-124/proposals/2026-08-04-close-remaining-…-r1-r2-r3.md:119-189`).

**Requirement 2 (per-habitat red→green plus a write-direction case) —
partially met; R3 carries no write-direction case.** R1's pair is present
and genuinely opposed: `run-approval-gate-tests.sh:174` asserts `allow`
for `timeout 30 grep -rn foo src/app.py` and `:177` asserts `deny` for the
same-wrapper write `timeout 30 sh -c "echo hi > src/app.py"` (@`43bd873`).
R2's pair likewise: `run-board-gate-tests.sh:261` asserts `allow` for
`git -C /tmp log …` and `:264` asserts `deny` for `git -C /tmp rm -r …`
(@`43bd873`) — both siblings route through the same `_git_subcommand`
parse the fix touches, so the negative-space pin is real, not nominal.
R3's four added cases (`run-gate-lib-tests.sh:217-224` @`43bd873`) are all
`headof` assertions on read-shaped lines (`timeout -s KILL 30 git log`,
`nice -n 10 git log`, `env -u FOO git log`, `xargs -I fmt git log`); no
case in any of the three harnesses exercises a wrapper-own-value-flag
*write* line. Detailed as finding F1 below.

**Requirement 3 (post-fix re-enumeration proving zero remaining
habitats) — method met, conclusion overstated.** The record does publish
its enumeration verbatim with its full hit list and a site-by-site
comparison against issue-114's table
(`docs/issue-124/reports/implementation.md:346-402`), which is the
strongest part of the delivery and satisfies the "state the method and
publish the negative result" bar the scout brief recorded
(`docs/issue-124/reports/execution-observation/scout-brief.md:20-27`).
Its closing sentence "**Zero remaining habitats of this class.**"
(`docs/issue-124/reports/implementation.md:404`) is nonetheless broader
than its own evidence supports: the two `git grep` patterns it ran can
enumerate call *sites*, but cannot see whether a landed flag table is
complete against the grammar it claims to mirror. Axis B below finds two
uncovered shapes. Detailed as finding F3; the class-status verdict is in
`## Class exhaustion`.

**The three `## 제약` constraints — all met.** `gh-guard.sh` is absent from
`fdb620d`'s 9-file change set, so the issue's "무변경" constraint holds by
the file list itself; the enumeration at `43bd873` confirms
`core/hooks/gh-guard.sh:147` still calls `gate_lib.gate_wrapper_head_before`
unchanged. The #107 / #114 skeletons are respected: neither
`gate_trailing_words` (`core/hooks/lib/gate-lib.py:264` @`43bd873`) nor
`_cd_target`'s scan (`core/hooks/board-gate.sh:293` @`43bd873`) appears in
`fdb620d`'s hunks — R2's change is confined to `_git_subcommand`'s own
loop. No landed negative-space case was deleted or edited: `fdb620d`'s
test diff is `+27/−0` across the three harnesses, additions only.

## Verdict 2 — trajectory: was the phase-1 → phase-2 path sound

**Sound, on every checkable point.** The ordering is documented by
timestamps that cannot be rearranged after the fact: `7fcd4cd`
(2026-08-04T06:10:30Z) contains only `docs/issue-124/proposals/…` and
`docs/issue-124/reports/implementation/survey.md`, +490 lines, zero code
files; PR #126 was created 06:11:15Z; the approval comment was posted
06:20:10Z; the phase-2 commit `fdb620d` is authored 06:45:04Z; the merge
landed 06:46:00Z. Survey and proposal therefore preceded execution, and
execution followed the approval rather than preceding it.

**The approval was real and correctly typed.** Issue #124's comment
5175349028 has body exactly `APPROVE issue-124/implementation` from
`jjongkwann`, an account listed at `docs/specs/approvers.md:2`; `gh pr
view 126` returns `reviews: []`, so no PR-review path was available and
single-account mode was the correct reading — which the record itself
states with the same reasoning
(`docs/issue-124/reports/implementation.md:16-24`). No prose was
interpreted as approval.

**Scouting was properly skipped, not silently omitted.** No
`docs/issue-124/reports/implementation/scout-brief.md` exists at
`43bd873` (`git ls-tree -r 43bd873 -- docs/issue-124` returns three
paths, none of them a scout brief), and the survey carries the required
skip record with its one-line reason under
`## Scout-directive skip record`
(`docs/issue-124/reports/implementation/survey.md:239-252`), citing the
pure-bugfix condition. The reason is applicable on its face: all three
habitats are internal parser-differential defects in existing gate logic
with no product-facing surface.

**Phase-2 output stayed inside the approved scope.** PR #126's file list
is exactly the set the proposal named — three source files, three test
harnesses, two handbooks, and the role's own three `docs/issue-124/`
documents — with no file outside it. Nothing the proposal promised was
silently dropped; the one place where delivered shape is narrower than a
proposal sentence (R3's write-direction sibling) traces to the proposal's
own text, not to a phase-2 deviation — see F1's root cause.

**One trajectory-level qualification, not a defect.** The `## Hunt`
section substitutes two by-inspection stances for the unavailable
`warrant-hunter` subagent and says so plainly
(`docs/issue-124/reports/implementation.md:219-221`), and its
before-landing stance reaches a conclusion this observation can
corroborate independently: `gate_wrapper_head_before`
(`core/hooks/lib/gate-lib.py:289-299` @`43bd873`) does not call
`_resolve_transparent` — its docstring states it scans words directly,
"deliberately not via gate_head_of's TRANSPARENT hop-by-hop walk"
(`core/hooks/lib/gate-lib.py:299` @`43bd873`) — so neither the R2 nor the
R3 edit is reachable from `gh-guard.sh:147`'s fail-open call site. The
stance's verdict of NO FINDING holds on the artifact.

## Verdict 3 — step: which specific artifact is deficient

- **The three source hunks (`fdb620d`) — no finding.** Each matches the
  approved proposal's frozen text; the byte-level correspondence claimed
  at `docs/issue-124/reports/implementation.md:231-241` is confirmed
  independently by reading the diff against the proposal's code blocks
  (`…-r1-r2-r3.md:119-171`). No drift.
- **The added test cases (`fdb620d`) — deficient in one respect (F1) and
  miscounted in the record (F2).** The cases themselves are well-formed
  and the two allow/deny pairs are genuine opposites; what is missing is
  R3's write-direction pin, and what is wrong is the record's own count.
- **`docs/handbooks/approval-gate-tests.md` — no finding.** The R1
  paragraph landed at `:72` @`43bd873` and names both new cases in the
  file's existing citation voice.
- **`docs/handbooks/board-gate-tests.md` — the stale-sentence correction
  landed as claimed, but a new inaccurate sentence landed with it (F3).**
  The correction is real: the tail that previously asserted the `git -C`
  misread was "untouched" now reads "…is no longer an open gap: it is
  closed by issue-124/R2, below"
  (`docs/handbooks/board-gate-tests.md:227` @`43bd873`) — the record's
  claim at `:180-188` is accurate. In the same edit, `:238-243` asserts
  that git's long global flags exist only in `=`-joined form and
  therefore "already resolved correctly with no code change". That is
  false for the space-joined spelling git also accepts; see F3.
- **The record file itself — structurally complete.** It carries what,
  why, upstream basis (`7fcd4cd`), `loop_state: landed`, an explicit
  open-findings disposition (`## Resolution path`,
  `docs/issue-124/reports/implementation.md:291-297`), next steps, and a
  `## Verify` section with raw captured output — the §20 field set is
  present, and `code_under_review` is a file list, not a bare SHA
  (`:5`). Its defects are accuracy defects (F2, F3), not missing fields.

## Class exhaustion

The decision rule was fixed in the approved proposal before any result
was seen: the class is reported exhausted only if **both** axes come back
empty (`docs/issue-124/proposals/2026-08-04-independent-observation-of-pr-126.md:134-142`).

### Axis A — site enumeration at `43bd873`, widened. Empty.

Issue-114's two patterns were re-run at the pinned merge SHA, then
widened past what those two patterns can match, with five further
patterns (`shlex`, `partition(`, `.startswith(`, `argv[`, and
`re.match`/`re.search`/`re.findall`) across both hook trees. Full hit set,
production files only, out-of-class hits marked:

```
$ git grep -n "gate_head_of\|gate_trailing_words\|gate_wrapper_head_before" 43bd873 -- core warrant
core/hooks/approval-gate.sh:122   head = gate_lib.gate_head_of(cmdline)          [R1, now canonical]
core/hooks/board-gate.sh:212      words = gate_lib.gate_trailing_words(segment)  [R2 loop, canonical source]
core/hooks/board-gate.sh:237      head = gate_lib.gate_head_of(stripped)         [canonical]
core/hooks/board-gate.sh:293      for w in gate_lib.gate_trailing_words(stripped) [_cd_target, canonical]
core/hooks/board-gate.sh:356      if gate_lib.gate_head_of(stripped) == "cd"     [canonical]
core/hooks/gh-guard.sh:147        gate_lib.gate_wrapper_head_before(...)         [documented fail-open, out of scope by the issue's own 제약]
core/hooks/lib/gate-lib.py:254/264/289                                          [the resolver definitions themselves]
(remaining hits are doc comments and test-harness strings)

$ git grep -n "split()" 43bd873 -- core/hooks warrant/hooks
core/hooks/lib/gate-lib.py:230    words = segment.split()                        [the canonical model's own base split]
core/hooks/lib/gate-lib.py:324    words = cmdline[sep_end:span_start].split()    [gate_wrapper_head_before's own non-resolver scan]
core/hooks/record-fields-gate.sh:110  RF_TERMINAL env parsing                    [out of class]
warrant/hooks/hunt-guard.sh:98    file-content parsing                           [out of class]
(board-gate.sh:147 and the two test-harness hits are doc comments)

$ git grep -nE "split\(|shlex|partition\(|\.startswith\(|argv\[" 43bd873 -- core/hooks warrant/hooks   [new, beyond issue-114's method]
core/hooks/trailer-gate.sh:135    tokens = shlex.split(command)                  [commit-message extraction; scans for -m/-F by token, resolves no head — no differential]
core/hooks/board-gate.sh:219/294  if not w.startswith("-")                       [R2's fixed loop and _cd_target — both read gate_trailing_words, canonical]
core/hooks/board-gate.sh:413/438, warrant/hooks/scope-gate.sh:*, core/hooks/record-fields-gate.sh:*, warrant/hooks/state.sh:45
                                                                                 [path/YAML/env parsing, not command-head parsing — out of class]

$ git grep -nE "re\.(match|search|findall)\(" 43bd873 -- core/hooks warrant/hooks   [new, beyond issue-114's method]
core/hooks/trailer-gate.sh:83, core/hooks/handbook-trigger-gate.sh:71             [unanchored `\bgit\b…\bcommit\b` regexes — wrapper-insensitive by construction, no head resolution, no differential]
core/hooks/approval-gate.sh:125, core/hooks/board-gate.sh:363                     [candidate-token scans, not head resolution]
(remaining hits are branch/YAML/SHA parsing, out of class)
```

Axis A returns **no production site** of the head-resolution class beyond
those issue-114 already tabulated, and confirms R1/R2/R3 no longer read as
fail-closed differentials. This corroborates the observed record's own
hit list (`docs/issue-124/reports/implementation.md:346-368`) from an
independently constructed, strictly wider sweep.

### Axis B — grammar completeness of the two landed tables. Not empty.

**B1 — `GIT_GLOBAL_VALUE_FLAGS` (`core/hooks/board-gate.sh:192`
@`43bd873`) covers `-C`/`-c` only, but git also accepts its long global
flags in space-joined form.** Probed directly this session:

```
$ git --git-dir /nonexistent-xyz log --oneline -1
fatal: not a git repository: '/nonexistent-xyz'
```

git consumed `/nonexistent-xyz` as `--git-dir`'s value (had it not, the
error would have been `git: '/nonexistent-xyz' is not a git command`).
The local synopsis prints only the `=`-joined spelling
(`git --help`: `[--git-dir=<path>] [--work-tree=<path>]
[--namespace=<name>] [--config-env=<name>=<envvar>]`), which is exactly
why a synopsis-only reading misses this. Consequence, traced through the
landed code at `43bd873`: for `git --git-dir /tmp/x log`,
`_git_subcommand`'s loop (`core/hooks/board-gate.sh:212-222`) sees
`--git-dir` (starts with `-`, not in `GIT_GLOBAL_VALUE_FLAGS`, `i += 1`),
then returns `/tmp/x` as the subcommand; `/tmp/x` is not in
`GIT_READ_SUBCOMMANDS`, so `_segment_is_failing`
(`core/hooks/board-gate.sh:238`) returns `True` and the segment is a write
candidate. Same shape and same **fail-closed (over-block)** direction as
R2's original defect — not a security hole.

**B2 — `TRANSPARENT_FLAG_TAKES_ARG` (`core/hooks/lib/gate-lib.py:208-213`
@`43bd873`) covers one value-taking flag per wrapper, but three of the
four wrappers document more.** Local `xargs` synopsis, obtained this
session:

```
usage: xargs [-0opt] [-E eofstr] [-I replstr [-R replacements] [-S replsize]]
             [-J replstr] [-L number] [-n number [-x]] [-P maxprocs]
             [-s size] [utility [argument ...]]
```

Eight value-taking flags, of which the table holds only `-I`. The scout
brief records the same shape for the GNU pages: `env` documents
`-C/--chdir`, `-S/--split-string`, `-a/--argv0` alongside `-u`, and
`timeout` documents `-k/--kill-after` alongside `-s`
(`docs/issue-124/reports/execution-observation/scout-brief.md:68-73`,
sources [7][8][9] at `:83-85`). `nice` is complete — `-n` is its only
value-taking flag. Every uncovered shape misreads in the same fail-closed
direction as R3's original defect (`xargs -n 2 git log` resolves its head
to `2`, not `git`).

**Both B1 and B2 fall inside the observed proposal's declared
`## Out of scope`** — "Any `TRANSPARENT` wrapper flag beyond the four the
docstring already names" and "Any git global flag beyond `-C`/`-c`"
(`docs/issue-124/proposals/2026-08-04-close-remaining-…-r1-r2-r3.md:195-206`)
— so per the pre-registered rule they are reported as **class-status facts
about the codebase, not charged against PR #126 as a scope violation**.

### Class-status verdict

Axis A empty, axis B not empty, so under the pre-registered rule the
class is **not reported exhausted**. Precisely: the three named habitats
R1, R2, R3 are closed (`fdb620d`, corroborated by axis A at `43bd873`),
and the *sites* at which this class can live are enumerated and clean;
but the class defined by its grammar — a value-taking flag whose value is
misread as the command head or subcommand — retains at least the shapes
in B1 and B2. The residue is entirely fail-closed. What this enumeration
still could not see: any misread reachable only through shell constructs
the segment splitter itself resolves differently (quoting, expansion,
`eval`), and any behavior difference that only a suite run would reveal.

## Open findings

**F1 — R3 has no write-direction case, so issue #124's requirement 2 is
not fully pinned for that habitat.**
*Impact:* the fail-closed direction of R3 is asserted nowhere in the
landed suites. If a future edit to `_resolve_transparent` were to make a
wrapper-own-flag *write* line resolve to a benign head, no landed case
would fail. The four added cases
(`core/hooks/tests/run-gate-lib-tests.sh:217-224` @`43bd873`) are all
read-shaped (`… git log`).
*Timeline:* the gap enters at the proposal, not at delivery — the
proposal's Tests bullet header promises "one red→green pair plus a
write-direction sibling per habitat" but its own R3 sub-bullet specifies
only `headof` cases for four read shapes
(`docs/issue-124/proposals/2026-08-04-close-remaining-…-r1-r2-r3.md:172-186`);
`fdb620d` implemented the sub-bullet faithfully.
*Root cause:* R3's fix lives in a pure resolver where the read/write
distinction does not exist, so its write-direction pin would have had to
be placed one layer up, in `run-board-gate-tests.sh` (e.g. a
`timeout -s KILL 30 git rm …` deny case). Neither proposal nor delivery
noticed that the layer change was needed to satisfy requirement 2's "각
지점" wording. The record then restated the header's promise as delivered
("one red→green regression pair plus a same-shape write-direction sibling
per habitat", `docs/issue-124/reports/implementation.md:29-30`), which is
accurate for R1 and R2 and not for R3.
*Action item (for the human to scope; no issue is filed by this role):*
add one board-gate deny case on a wrapper-own-value-flag write line, and
correct the record's per-habitat claim.

**F2 — the record's added-case count is wrong: it says six, the diff has
eight.**
*Impact:* low, documentation only, but it is the one number a later
reader would use to reconcile the RED/GREEN totals.
`docs/issue-124/reports/implementation.md:321` reads "the six new cases (2
per habitat) are the only additions", while `fdb620d` adds 2 + 2 + 4 = 8
(`run-approval-gate-tests.sh:174,177`; `run-board-gate-tests.sh:261,264`;
`run-gate-lib-tests.sh:217-224`, all @`43bd873`).
*Timeline:* introduced in `fdb620d`'s record; contradicted within the same
document by its own `## Verify` table, which correctly shows R3 as "4 new
cases" and `53 → 57` (`docs/issue-124/reports/implementation.md:308`).
*Root cause:* the "2 per habitat" convention inherited from #114's
one-pair-per-habitat pattern was carried into the summary sentence after
R3's shape had already diverged to four `headof` cases.
*Action item:* correct the sentence to eight (2 + 2 + 4). The RED/GREEN
counts elsewhere in the record are internally consistent and need no
change: 43→44, 90→91, 53→57 all reconcile with the diff.

**F3 — a factually incomplete grammar claim landed in a durable handbook,
and the record's class-closure sentence is broader than its evidence.**
*Impact:* `docs/handbooks/board-gate-tests.md:238-243` @`43bd873` tells
future readers that git's long global flags are `=`-joined and therefore
"already resolved correctly with no code change". Under B1 that is wrong
for the space-joined spelling git accepts, so the handbook now actively
directs a future maintainer away from a live (fail-closed) misread. The
same reasoning appears in the proposal
(`…-r1-r2-r3.md:104-109`) and underwrites the record's
"**Zero remaining habitats of this class.**"
(`docs/issue-124/reports/implementation.md:404`).
*Timeline:* the claim is first made in the phase-1 proposal `7fcd4cd`,
carried into the handbook and the record by `fdb620d`, and merged at
`43bd873`.
*Root cause:* the sweep instrument could not detect it. Both `git grep`
patterns enumerate call sites; table completeness is not a grep-visible
property, so a method that is sound for "have all sites been converted?"
was used to answer "is the class empty?" — the exact substitution the
scout brief flagged in advance
(`docs/issue-124/reports/execution-observation/scout-brief.md:20-24`).
*Action item (for the human to scope):* correct the handbook sentence to
state that git accepts both spellings and that only the `=`-joined form is
safe today; and narrow the record's closure sentence to "the three named
habitats are closed" rather than the class. Whether to extend the two
tables at all is a scoping decision, not a defect in this delivery — the
residue was named out of scope in advance and is fail-closed throughout.

## Commitments — clause checklist (§19)

| # | clause | status |
|---|---|---|
| 1 | record written as first act of phase 2, `loop_state` maintained | fulfilled — this file, `loop_state: landed` |
| 2 | independence statement precedes all verdict language | fulfilled — `## Independence` |
| 3 | all three verdict levels rendered | fulfilled — Verdicts 1/2/3 |
| 4 | citation adjacent to every verdict-bearing sentence | fulfilled |
| 5 | requirement 1 checked hunk-by-hunk vs issue and frozen proposal | fulfilled — Verdict 1 |
| 6 | requirement 2 checked by reading cases as code, no suite run | fulfilled — Verdict 1, F1 |
| 7 | axis A run at `43bd873`, widened, full hit list published | fulfilled — `## Class exhaustion` |
| 8 | axis B run against primary specs, table-vs-spec diff published | fulfilled — B1, B2 |
| 9 | 8 added cases reconciled against the record's "six" | fulfilled — F2 |
| 10 | record checked against §20 items | fulfilled — Verdict 3, last bullet |
| 11 | four-part blameless shape on every finding | fulfilled — F1, F2, F3 |
| 12 | coverage limit stated explicitly | fulfilled — `## Coverage limits` |
| 13 | no issue filed; nothing outside this record path edited | fulfilled — this PR's file list |

No clause was dropped, so no re-approval is required.

## Coverage limits

- **Not verified: the RED/GREEN and full-suite numbers themselves.**
  `43 → 44`, `90 → 91`, `53 → 57`, and the final `44/0, 91/0, 57/1`
  (`docs/issue-124/reports/implementation.md:304-317`) were checked only
  for internal consistency against the diff and against each other; no
  harness was run, by this role's independence rule. Their arithmetic
  reconciles with the eight added cases; their truth rests on the
  observed role's own capture.
- **Not verified: the pre-existing `compliance-check.sh` failure's
  sandbox attribution** (`docs/issue-124/reports/implementation.md:323-344`).
  Its two supporting arguments are internally coherent and cite
  `docs/issue-118/reports/implementation.md`, but confirming the failure
  is environment-caused would require running the suite.
- **Not verified: no-regression across the pre-existing cases.** The
  additions-only test diff (`+27/−0`) makes deletion-by-edit impossible,
  which is a structural check, not a behavioral one.
- **Axis A's blind spot:** it enumerates textual call sites. A habitat
  reachable only through shell-level constructs (quoting, expansion,
  `eval`) that never appears as one of the searched tokens would not
  surface.
- **Axis B's blind spot:** it compares the two landed tables against the
  synopses of `git` and `xargs` obtained locally this session and the
  GNU man pages recorded in the scout brief. A platform whose `env` /
  `timeout` / `nice` differ from those pages was not enumerated.

## Next steps

None required of this role. F1, F2, and F3 are returned here for the
human to judge on PR #130; under contract v3 issues are user-authored
only, so this role files none and takes no action inside the observed
role's paths.

## Resolution path

The three findings are open against artifacts this role may not edit
(`core/hooks/tests/`, `docs/handbooks/`, `docs/issue-124/reports/implementation.md`).
Their resolution path is the human's judgment on this PR: each finding
above carries the concrete artifact, line, and correction, so a follow-up
issue — if the human decides one is warranted — can be written from F1,
F2, and F3 directly. None of the three blocks the merged state of PR
#126: F1 and F2 are test-coverage and documentation gaps, and F3's live
residue is fail-closed in every shape enumerated.

## Verify

- Independence: no `core/`, `warrant/`, `docs/handbooks/`, or
  `docs/issue-124/reports/implementation*` path is written by this
  session — checkable against PR #130's file list.
- Every verdict-bearing sentence above names a commit SHA, a
  `file:line` at a pinned SHA, or a comment URL adjacent to the verdict.
- Both enumeration axes are published with the commands actually run and
  their raw output; the class-status conclusion follows the decision rule
  fixed in the approved proposal at `:134-142`, which was written before
  any result was seen.
- All three verdict levels are addressed; none was omitted, and none was
  written as "not applicable" — all three had substance on this subject.
