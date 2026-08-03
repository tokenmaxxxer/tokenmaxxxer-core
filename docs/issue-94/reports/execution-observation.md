---
kind: observation-record
subject: issue-94
produced_by: execution-observation
observed_role: implementation
observed_pr: 96
observed_commits: 74c790d00d6ee802af92671f3240216b4be4da41, c9a63b49fb68eeb47196d0b74729022fa58a6ad2
loop_state: landed
upstream:
  - path: docs/issue-94/proposals/2026-08-03-independent-observation-of-pr-96.md
    sha: ec404fc2ff2f75e531e0b3439db73382ca5b4b45
---

# Execution observation record — issue-94 / implementation (PR #96)

## Independence

This role did not author or edit the observed artifact, in this session or
any other. PR #96, its commits `74c790d` (propose) and `c9a63b4` (deliver),
its tests, and the implementation role's own record
`docs/issue-94/reports/implementation.md` were produced by the
implementation role; nothing under `core/`, under `core/hooks/tests/`, or
under another role's report or proposal path was written or modified here.
The observed role's code was not re-executed: no gate was invoked, no test
harness was run. Evidence is committed artifacts only — commit diffs and
pre-image blobs read through `git show`/`git diff`, the PR and issue JSON
read through `gh`, and the observed role's own record. Every verdict below
follows this statement, none precedes it.

## Why

Phase 2, opened by the issue-level comment whose entire body is the exact
string `APPROVE issue-94/execution-observation` (38 bytes, no trailing
text), posted by `jjongkwann` — an account listed in
`docs/specs/approvers.md` — at 2026-08-03T05:52:55Z
(https://github.com/tokenmaxxxer/tokenmaxxxer-core/issues/94#issuecomment-5162801680).
PR #97's author is the same account, so this is single-account mode and the
exact-string issue comment is the correct approval path. The verdict levels
and their evidence were fixed before any evidence work in the phase-1
proposal committed at `ec404fc`
(`docs/issue-94/proposals/2026-08-03-independent-observation-of-pr-96.md`,
"Which verdict levels this observation will check, and against what"); this
record renders exactly those three levels against exactly that evidence.

## Method, and the limit carried over from phase 1

The phase-1 proposal (`ec404fc`, "Method, and the limit this role accepts")
declared that this role does not re-run the observed role's code, so every
before/after determination is **analytic** — the pre-image pattern text and
the case input, reasoned through — and is labelled as such rather than
presented as an execution result. That limit is honoured here. Statements
marked **(analytic)** are derived from the committed pattern text and the
committed case input; statements marked **(artifact)** are direct readings
of a blob, diff or API record.

## Verdict — outcome

**Landed, with two scope narrowings that were declared before approval and
one coverage regression that was not.** (artifact)

Against issue #94's four numbered requirements:

1. **Requirement 1 (board-gate write-ish judgment ignores quoted
   characters, reusing the approval-gate quote-span approach rather than
   reimplementing it) — met for `FILE_REDIR`, deliberately not met for
   `SUBSHELL`.** `c9a63b4:core/hooks/board-gate.sh:230` now reads
   `SUBSHELL.search(seg) or gate_lib.gate_outside_quotes(seg, FILE_REDIR.pattern)`,
   against `74c790d:core/hooks/board-gate.sh:226`'s
   `SUBSHELL.search(seg) or FILE_REDIR.search(seg)`. The quote-span text was
   centralized, not re-typed: `GATE_QUOTE_SPAN`
   (`c9a63b4:core/hooks/lib/gate-lib.py:174`) is character-identical to the
   quote-span prefix of `board-gate.sh`'s `SEGMENT`
   (`c9a63b4:core/hooks/board-gate.sh:140`) and to the pre-image
   `WRITEISH`'s first two alternatives (`74c790d:core/hooks/approval-gate.sh:96`).
   `SUBSHELL` stays quote-blind by design, with the rationale stated in the
   PR body and pinned by a test (see Requirement 4).
2. **Requirement 2 (gh-guard splits the command into segments and excludes
   quoted spans) — met only in part: quote exclusion applied to 3 of 11
   rules, segmentation not implemented at all.** `git show c9a63b4:core/hooks/gh-guard.sh | grep -c "_split_segments\|SEGMENT"`
   returns `0` (verified in this session), and the delivered loop is
   `dq = gate_lib.gate_dequote(cmd)` / `for pat, why, dequote in RULES` at
   `c9a63b4:core/hooks/gh-guard.sh:128-130`. The narrowing is not
   undeclared: the reuse question the requirement demands be asked first was
   asked and answered in phase 1 — PR #96's body records the warrant-hunt
   conclusion that segmentation "can split a real single invocation apart" —
   and the approval comment postdates that body by 50 minutes (see
   Trajectory). The residual is also kept visible in the suite as
   `gap-f-api-merge-in-quote-still-fires`
   (`c9a63b4:core/hooks/tests/run-gh-guard-tests.sh:87`).
3. **Requirement 3 (regression cases must actually fail on the pre-change
   code, including the issue's two measured commands plus negative-space
   cases) — met for both measured commands.** (analytic; see next section
   for the per-case derivation)
4. **Requirement 4 (the relaxation must not miss real acts) — met for the
   cases the delivery anticipated, not met for the wrapper-command class.**
   Real unquoted acts are pinned by `bash-real-redirect-then-quote` and
   `quote-real-merge-after-quote`
   (`c9a63b4:core/hooks/tests/run-board-gate-tests.sh:281`;
   `c9a63b4:core/hooks/tests/run-gh-guard-tests.sh:81`), and live command
   substitution inside double quotes is pinned by `bash-quoted-subshell-write`
   (`c9a63b4:core/hooks/tests/run-board-gate-tests.sh:290`). A real act
   wrapped in `bash -c "…"` / `eval "…"` is no longer caught — Finding 1.

Against the issue's constraint ("gather the judgment helper in one place"):
partly met. Three production call sites now share one primitive
(`c9a63b4:core/hooks/approval-gate.sh:123`, `board-gate.sh:230`,
`gh-guard.sh:128`) where `74c790d` had zero
(`git grep "gate_dequote\|gate_outside_quotes\|GATE_QUOTE_SPAN" 74c790d`
returns nothing), but one byte-identical copy of the quote-span alternation
survives inside `SEGMENT` at `c9a63b4:core/hooks/board-gate.sh:140` with no
mechanism guarding the two against drift — Finding 4.

### (a) Do the new cases fail on the pre-change code?

Sixteen assertions were added — 4 in `run-board-gate-tests.sh`, 5 in
`run-gh-guard-tests.sh`, 7 in `run-gate-lib-tests.sh` (5 `dequote` + 2
`outquotes` calls) — with zero deleted lines in all three files
(`c9a63b4`, `--numstat` = `17 0`, `14 0`, `40 0`) and no pre-existing case
modified. (artifact)

**Four fail on the pre-change code (analytic):**

- `bash-quoted-redirect-in-grep` (`c9a63b4:core/hooks/tests/run-board-gate-tests.sh:279`,
  input `grep -n "A > B" docs/issue-3/x.md`, wants allow). At `74c790d` the
  check is `FILE_REDIR.search(seg)` on the raw segment with
  `FILE_REDIR = re.compile(r">>?(?!&)")` (`74c790d:core/hooks/board-gate.sh:112`);
  the `>` inside the quoted grep pattern is present in that raw text, so the
  segment is classed a write candidate and refused. Wants allow, pre-image
  denies → fails before. This is the issue's first measured command.
- `quote-gh-pr-merge-in-grep`, `quote-review-approve-in-grep`,
  `quote-issue-create-in-grep` (`c9a63b4:core/hooks/tests/run-gh-guard-tests.sh:78-80`,
  all want allow). At `74c790d` the loop is `for pat, why in RULES: if re.search(pat, cmd)`
  on the whole raw command (`74c790d:core/hooks/gh-guard.sh:110-111`), so
  rules 1–3 (`74c790d:core/hooks/gh-guard.sh:71,75,79`) match the text inside
  the quoted grep patterns and deny. Wants allow, pre-image denies → fail
  before. The first of these is byte-identical to the issue's second
  measured command.

**Twelve do not, and by construction cannot:** the five deny-cases
(`bash-real-redirect-then-quote`, `bash-escaped-quote-then-redirect`,
`bash-quoted-subshell-write`, `quote-real-merge-after-quote`,
`gap-f-api-merge-in-quote-still-fires`) assert the verdict the pre-image
already produced — they are negative-space guards, exactly what requirement
3's second half asks for, and correctly so; the seven `gate-lib` assertions
exercise `gate_dequote`/`gate_outside_quotes`, which do not exist at
`74c790d` at all (`git grep` at that sha returns zero hits tree-wide), so
they are new-unit tests rather than regressions. (analytic + artifact) No
deficiency is claimed here: the delivery does carry the two commands the
issue named, each failing beforehand for the reason the issue gave.

### (b) Are the three no-change claims true?

- **`SUBSHELL` byte-identical — true.** (artifact) `SUBSHELL = re.compile(r"[`]|\$\(")`
  hashes identically at `74c790d:core/hooks/board-gate.sh:118` and
  `c9a63b4:core/hooks/board-gate.sh:122` (`aedf3ea75edbab13e33e2abdeaa98e0c7803b201`
  at both); the line does not appear in `c9a63b4`'s diff for that file in
  any form. The record's closed-check 1 (`c9a63b4:docs/issue-94/reports/implementation.md:129-137`)
  is accurate.
- **The 8 unchanged gh-guard rules identical, order preserved, no
  segmentation — true.** (artifact) The concatenated pattern lines of the
  `RULES` block hash identically across the two commits
  (`7d4365a2bab64bb3453d08abdf5adb5059c1fd66`, 16 pattern lines at each);
  the diff at `c9a63b4:core/hooks/gh-guard.sh:74-126` shows, for each of the
  8 `False`-tagged rules, only the tuple's closing punctuation changing plus
  an added `False)` line, with every `why` message line unchanged and no
  reordering; and the `grep -c` for `_split_segments|SEGMENT` returns `0`,
  verified in this session. The record's closed-check 2
  (`c9a63b4:docs/issue-94/reports/implementation.md:138-149`) is accurate.
- **approval-gate behaviour unchanged — true as far as artifacts can carry
  it.** (analytic) `74c790d:core/hooks/approval-gate.sh:96-107` defines
  `WRITEISH` as `quote-span alternatives | [>|`] | \$\(` scanned with
  `finditer`, skipping matches that begin with a quote character;
  `c9a63b4:core/hooks/approval-gate.sh:123` calls
  `gate_lib.gate_outside_quotes(cmdline, r"[>|`]|\$\(")`, which blanks the
  same quote spans (`GATE_QUOTE_SPAN` is the same two alternatives, in the
  same order) and then searches the same remaining fragment. Skipping a
  quote-span match and blanking it to a space are equivalent for a
  subsequent search of the non-quote fragment, so no input distinguishing
  the two was found. What cannot be checked from artifacts is the claimed
  `42 passed, 0 failed` run itself; no assertion was added to
  `run-approval-gate-tests.sh` (the file is absent from `c9a63b4`'s change
  list), so the equivalence rests on reading, not on a new pinning case.

### (c) Was the protection scope exceeded?

- **Command substitution inside double quotes, board-gate: not exceeded.**
  (artifact) `SUBSHELL` remains raw on the left of the `or` at
  `c9a63b4:core/hooks/board-gate.sh:230`, so `grep -n "$(touch …)" README.md`
  still denies, and `bash-quoted-subshell-write`
  (`c9a63b4:core/hooks/tests/run-board-gate-tests.sh:290`) pins it with an
  inline comment naming the hazard.
- **Command substitution inside double quotes, approval-gate: unchanged, and
  unchanged in the permissive direction.** (analytic) Both the pre-image
  `_writeish` and the delivered `gate_outside_quotes` call treat `$(` inside
  a double-quoted span as non-write-ish, so `grep -n "$(…)" f` takes the
  `READ_ONLY_HEADS` fast path at `c9a63b4:core/hooks/approval-gate.sh:120-123`
  and skips the phase check. PR #96 did not introduce this and requirement 4
  does not reach it — nothing was relaxed there — but the delivery's own
  board-gate rationale ("command substitution stays live inside double
  quotes") is the exact argument against the treatment it left standing one
  file over, and neither the record nor the handbook entry names the
  asymmetry. Recorded as an observation, not charged as a defect.
- **Dequote combination: exceeded, at the wrapper-command class.** Finding 1.
- **Escaped-quote combination: not exceeded.** (analytic) `GATE_QUOTE_SPAN`'s
  `(?<!\\)` guards mean a backslash-escaped quote character does not open a
  span, so `ls \" > docs/issue-3/x.md #"` keeps its real `>` visible and
  still denies; `bash-escaped-quote-then-redirect`
  (`c9a63b4:core/hooks/tests/run-board-gate-tests.sh:286`) pins exactly this.

### Suite-count recomputation

The per-suite **deltas** reconcile exactly; the **absolute totals do not,
and cannot from artifacts alone.** (artifact) Neither commit contains any
stored expected total — `grep -iE 'total|expected'` across
`core/hooks/tests/` at both shas finds only one unrelated comment, and the
summary lines are dynamic (`printf '\n== %d passed, %d failed ==\n' "$pass" "$fail"`,
byte-identical before and after in both shell suites). Counting assertion
sites directly in this session: `run` lines go 47 → 51 in
`run-board-gate-tests.sh` (+4) and 31 → 36 in `run-gh-guard-tests.sh` (+5),
matching the added-case counts the record claims at
`c9a63b4:docs/issue-94/reports/implementation.md`. The claimed absolutes do
not follow a one-assertion-per-site model, however: 36 `run` sites plus the
one hand-rolled `gap-d` check reconcile with gh-guard's claimed `37 passed`,
but board-gate's 51 sites do not reconcile with its claimed `71 passed`, and
`run-gate-lib-tests.sh`'s statically-visible `report` sites (13 → 15) do not
reconcile with the claimed 37 assertions either, because the new group calls
`report` from inside two helper functions invoked 5 and 2 times. Since this
role does not re-run the suites, the absolute figures in the record and
commit message are neither confirmed nor contradicted here; they are simply
not checkable from the committed artifacts, and no stored total exists that
a future drift would break. That is a property of the harness, not a defect
of this delivery.

## Verdict — trajectory

**Sound, with one closing-keyword defect at the end of the path.**

- **Survey before proposing: yes.** (artifact) `74c790d` is docs-only — 2
  files, +560/−0, `docs/issue-94/reports/implementation/survey.md` and the
  proposal — committed at 2026-08-03T03:58:04Z, 39 seconds before PR #96 was
  opened at 03:58:43Z. No source file is touched until `c9a63b4`.
- **The reuse question requirement 2 demands was asked before deciding: yes.**
  (artifact) PR #96's body records the warrant-hunt against the first-draft
  design (blanket dequoting + reuse of board-gate's segment splitter) and the
  three concrete regressions that killed it, and it names the narrowed scope
  — "three of gh-guard eleven rules" — in the same body, before approval.
- **Real human approval, in the right mode, in the right order: yes.**
  (artifact) PR #96 carries no PR-level review (`reviews` is `[]`), so the
  single-account path applies; the issue comment whose entire body is the
  31-byte exact string `APPROVE issue-94/implementation` was posted by
  `jjongkwann`, an approvers.md account, at 2026-08-03T04:49:02Z
  (https://github.com/tokenmaxxxer/tokenmaxxxer-core/issues/94#issuecomment-5162414768) —
  after the propose commit (03:58:04Z) and 31 minutes before the deliver
  commit `c9a63b4` (05:20:28Z). Verified byte-exactly in this session via the
  comments API: length 31, no trailing text. No phase-2 work precedes the
  approval.
- **One defect on the path: the delivery closed its own issue while the
  issue's plan still had a step outstanding.** Finding 5.

## Verdict — step

Deficient artifacts, each named at file:line, are Findings 1–6 below. The
artifacts checked and found sound at this level are: the four source files
(`gate-lib.py:174-191`, `board-gate.sh:230`, `approval-gate.sh:123`,
`gh-guard.sh:74-130` at `c9a63b4`); the three test files, whose additions are
purely additive and whose two headline cases reproduce the issue's own
measured commands; and the four handbook entries, all four confirmed touched
in `c9a63b4`'s `--stat`. The record's four `closed_checks` results are
substantively accurate as written — checks 1, 2 and 4 verified against the
diff in this session, check 3 verified analytically — while the frontmatter
they hang from carries Finding 3.

## Open findings

### Finding 1 — dequoting the three verb rules opens the wrapper-command path

**Artifact:** `c9a63b4:core/hooks/gh-guard.sh:74-86` (the three `True`-tagged
rules) with the loop at `:128-130`; the same class at
`c9a63b4:core/hooks/board-gate.sh:230`.

**Impact.** `gate_dequote` treats quoted text as inert data, but `bash -c`,
`sh -c` and `eval` execute it. `bash -c "gh pr merge 5"` is denied by the
pre-image (raw `re.search` over the whole command matches rule 2 at
`74c790d:core/hooks/gh-guard.sh:75`) and is **not** denied after the change:
the quoted span is blanked, leaving `bash -c  `, which no rule matches, and
the RULES loop is the only deny path in the file. The same wrapper applied
to a board write — `bash -c "echo hi > docs/issue-3/x.md"` — no longer
registers at the `FILE_REDIR` half of the write-candidate check; whether
another board-gate branch still catches it cannot be determined from this
diff alone, so that half of the impact is stated as bounded. No added case
covers the wrapper class: the closest, `quote-real-merge-after-quote`
(`c9a63b4:core/hooks/tests/run-gh-guard-tests.sh:81`), places the real act
*outside* the quotes.

**Timeline.** Introduced in `c9a63b4` (2026-08-03T05:20:28Z), merged with
PR #96 at 05:36:18Z; present on the board since.

**Root cause.** The phase-1 warrant-hunt asked the right question about
quoted content and answered it for one direction only. Per PR #96's body it
asked which rules "legitimately need to see inside quoted `gh`/`curl`
arguments" — i.e. where quoted text is *data that the rule is looking for* —
and kept those 8 raw. It did not ask where quoted text is *code that will
run*, which is what a `-c`/`eval` wrapper makes it. The board-gate `SUBSHELL`
decision shows the session held the "quoted text can still execute" concept
at the same time; it was simply not carried across to the dequoted rules.

**Action item (for the human to judge; this role files nothing).** Either
restore the raw match as a second, additive test for the three verb rules
(deny if the pattern matches raw **and** the raw hit is inside a quoted span
belonging to a wrapper head such as `bash -c`/`sh -c`/`eval`), or exclude
commands whose head is a shell-wrapper from the dequoting path entirely, and
pin whichever is chosen with a case of the `bash -c "…"` shape in
`run-gh-guard-tests.sh`.

### Finding 2 — the record's `code_sha` citations point at a commit that predates the code they describe (recurrence)

**Artifact:** `c9a63b4:docs/issue-94/reports/implementation.md:5` and
`:130, :139, :150, :161`.

**Impact.** `code_under_review` and all four `closed_checks` entries carry
`code_sha: 74c790d…`. `74c790d` is docs-only — 2 files, both under
`docs/issue-94/`, per its own `--numstat`. None of the code those checks
describe exists at that sha: `board-gate.sh:230`, `gate-lib.py:174-191`,
`gh-guard.sh:128-130` and the deletion of `WRITEISH` all first exist at
`c9a63b4`. Contract §16 (`core/contract/role-handoff-contract.md:557-559`)
makes `code_sha` load-bearing — a downstream role may cite-and-skip a closed
check "only when the closing entry's `code_sha` equals the code sha
currently under review" — so as written, these four checks are not validly
citable by any downstream role, and an auditor who follows the sha finds
nothing to audit. Two smaller divergences ride along: the entries use
`name:`/`result:` where §16's template specifies `check:`.

**Timeline.** Written in `c9a63b4` (05:20:28Z), merged 05:36:18Z. The
identical defect was recorded one issue earlier as Finding 2 of
`docs/issue-90/reports/execution-observation.md:351-386` (merged with PR #91
at 2026-08-03T01:21:15Z) — roughly four hours before this record was
written, with an action item that was not actioned in between.

**Root cause.** The same structural bind the earlier finding named, not
carelessness: the record is committed in the same commit as the code it
describes, so the sha it wants to cite does not exist when the file is
written, and the proposal sha is the only real one available. What makes
this a recurrence rather than a repeat of an unavoidable constraint is that
the prior observation had already published the finding and two viable
alternatives, and nothing in the handoff carried it to this session.

**Action item (for the human to judge; this role files nothing).** Settle
the convention once, in the contract rather than per-record: either define
`code_sha` as resolved post-merge (written by the merge, not the author), or
restore the file-list form for `code_under_review` that
`docs/issue-88/reports/implementation.md:5` and
`docs/issue-20/reports/implementation.md:4` use and drop `code_sha` from
`closed_checks`. Until it is settled, the recurrence rate is one per issue.

### Finding 3 — the centralized quote-span primitive still has an unguarded second copy

**Artifact:** `c9a63b4:core/hooks/board-gate.sh:140` (`SEGMENT`) against
`c9a63b4:core/hooks/lib/gate-lib.py:174` (`GATE_QUOTE_SPAN`).

**Impact.** The two carry the same alternation text
(`(?<!\\)'[^']*'|(?<!\\)\"(?:[^\"\\]|\\.)*\"`), `SEGMENT` embedding it inline
inside a larger alternation. Nothing enforces that they stay equal: no test
in the three changed suites asserts the two texts match, and `c9a63b4`'s
file list contains no lint or CI configuration at all. The only artifact
asserting the equality is prose in the record itself
(`c9a63b4:docs/issue-94/reports/implementation.md:160-162`), which fixes the
claim at one point in time rather than guarding it. A future edit to either
copy — precisely the drift the issue's constraint was written to prevent —
would pass every suite.

**Timeline.** `SEGMENT`'s copy predates PR #96 (byte-identical at
`74c790d:core/hooks/board-gate.sh:136`); PR #96 is the change that made
single-sourcing available and stopped one line short of it.

**Root cause.** Centralization was scoped to the call sites the fix needed,
and `SEGMENT` was not one of them. The technique was in hand in the same
commit: `board-gate.sh:230` passes `FILE_REDIR.pattern` rather than a
re-typed literal, and the record names that choice as drift-proofing.

**Action item (for the human to judge; this role files nothing).** Build
`SEGMENT` from `GATE_QUOTE_SPAN.pattern` the way `:230` builds its argument
from `FILE_REDIR.pattern`, or — if composing the regex at import time is
unwanted — add one assertion to `run-gate-lib-tests.sh` comparing the two
pattern texts.

### Finding 4 — `Closes #94` closed an issue whose execution plan had an unstarted step

**Artifact:** PR #96's body and `c9a63b4`'s commit message, both carrying the
`Closes #94` trailer.

**Impact.** Issue #94's body ends with a two-item execution plan — `step 1
implementation`, `step 2 execution-observation` — both unchecked. Merging
PR #96 auto-closed the issue at 2026-08-03T05:36:18Z with step 2 not
started, which discards the tracking state the plan exists to hold. The
human reopened it nine seconds later
(https://github.com/tokenmaxxxer/tokenmaxxxer-core/issues/94#issuecomment-5162701039),
recording it as "the 7th real instance" of the defect on-the-record #228
addresses.

**Timeline.** Written into `74c790d`'s PR body at 03:58:43Z and repeated in
`c9a63b4` at 05:20:28Z; fired at merge 05:36:18Z; corrected by hand at
05:36:27Z.

**Root cause.** A closing keyword states "this PR completes the issue", but
the delivering role only completes its own step of a multi-role plan, and
nothing in the PR template or the gates distinguishes the two. The role
followed the ordinary convention; the convention is what does not fit an
issue with a multi-step plan.

**Action item (for the human to judge; this role files nothing).** Where an
issue body carries an execution plan with more than one step, have the
non-final role reference the issue without a closing keyword (`Subject:
issue-<n>` alone, which both commits already carry), leaving the close to
the human or to the final step.

### Finding 5 — three stale references to a deleted symbol survive in an untouched test file

**Artifact:** `c9a63b4:core/hooks/tests/run-approval-gate-tests.sh:159, :163,
:173`.

**Impact.** Low, and documentary only: all three are comments, and they name
`WRITEISH`/`_writeish`, which `c9a63b4` deletes from
`core/hooks/approval-gate.sh` entirely. A reader of the approval-gate suite
is pointed at a symbol that no longer exists. The record's closed-check 3
(`c9a63b4:docs/issue-94/reports/implementation.md:150-159`) reports "no dead
reference anywhere in the file" — accurate as written, since its `grep` was
scoped to `approval-gate.sh`, but the scope is narrower than the claim reads.

**Timeline.** Created by the deletion in `c9a63b4` (05:20:28Z), merged
05:36:18Z.

**Root cause.** The verification grep was aimed at the file being edited;
the file that *documents* that file was not in scope, and it was not in the
change list either, so no diff review pass would have surfaced it.

**Action item (for the human to judge; this role files nothing).** Reword the
three comments to name `gate_outside_quotes`, and widen the "no dead
reference" check from the edited file to `core/hooks/` when a symbol is
deleted.

### Observation (not charged as a finding)

`c9a63b4:core/hooks/approval-gate.sh:123` continues to classify a live
command substitution inside double quotes as non-write-ish, so a
`READ_ONLY_HEADS` command carrying `"$(…)"` takes the phase-agnostic fast
path. This is unchanged from `74c790d:core/hooks/approval-gate.sh:101-107`
and therefore outside requirement 4, which reaches only what the change
relaxed. It is recorded because the same delivery argues the opposite
position one file over, at `c9a63b4:core/hooks/board-gate.sh:230` and in
`run-board-gate-tests.sh:287-290`, and the asymmetry is documented nowhere.

## Next steps

None for this role. The five findings and the observation stand in this
record on PR #97 for the human to judge; this role files no issues, opens no
follow-up, and does not touch the observed role's artifacts.

## Resolution path

Each finding is resolved by the human judging it on PR #97 and, if valid,
authoring the issue themselves (contract v3: issues are user-authored only).
A finding the human rejects needs no artifact change. If a finding is
accepted and fixed by a later role, that role's own record cites this
record's finding number; this file is not amended by another role.

## What did not work

Nothing blocking. Two mechanical frictions worth recording: the record-fields
gate rejected two drafts of this file before the third, because it matches
section headings on literal substrings (`what was done`, `open findings`) and
requires `loop_state:` to hold a value with no `/` in it — the phase-slug
form `phase-2/opened` fails the field regex outright. And three read-only
evidence commands were refused by the sandbox for shell-shape reasons
(`$VAR` expansion in a `for` loop, process substitution, `sed` regex ranges);
each was reissued in a plainer form with no loss of evidence — the same class
of false positive issue #94 exists to reduce, observed from the other side.

## loop_state

- `phase-1` — survey, scout brief and proposal committed at `ec404fc`; PR #97
  opened; stopped for approval.
- `phase-2-opened` — approval comment verified byte-exact
  (issuecomment-5162801680); this record created as the first act of phase 2.
- `landed` — three-level verdict rendered against the evidence the phase-1
  proposal declared, five findings recorded with impact/timeline/root
  cause/action item, record committed on `issue-94/execution-observation` and
  delivered through PR #97.

## Verify

What was read, in this session, to support the verdicts above — no artifact
is cited that was not read here:

- `gh issue view 94` (body, all three comments) and
  `gh api repos/tokenmaxxxer/tokenmaxxxer-core/issues/94/comments` (exact
  body lengths: 31 / 141 / 38).
- `gh pr view 96` (body, author, timestamps, empty `reviews`/`comments`,
  merge commit) and `gh pr view 97`.
- `git show`/`git diff` for `74c790d`, `c9a63b4` and `19a99ba`: full diffs of
  `core/hooks/lib/gate-lib.py`, `core/hooks/board-gate.sh`,
  `core/hooks/approval-gate.sh`, `core/hooks/gh-guard.sh` and the three
  changed test files, plus pre-image blobs at `74c790d` for each.
- `git show c9a63b4:docs/issue-94/reports/implementation.md` in full.
- `git show ec404fc:` for this role's own phase-1 proposal, survey and scout
  brief; `docs/specs/approvers.md`;
  `core/contract/role-handoff-contract.md:541-563`;
  `docs/issue-90/reports/execution-observation.md:351-386`.
- Direct checks run here: `grep -c "_split_segments\|SEGMENT"` on
  `c9a63b4:core/hooks/gh-guard.sh` (= 0); `grep -n "WRITEISH\|_writeish"` on
  `c9a63b4:core/hooks/tests/run-approval-gate-tests.sh` (lines 159, 163,
  173); `run`-site counts at both shas (47 → 51, 31 → 36) and `report`-site
  counts (13 → 15).

No gate was invoked and no test harness was run at any point.
