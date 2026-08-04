---
kind: observation-record
subject: issue-118
produced_by: execution-observation
observed_role: implementation
observed_pr: 120
loop_state: landed
upstream:
  - path: docs/issue-118/reports/execution-observation/survey.md
    sha: fa8aed6d277254beb1502397cbfa26a0e5a9eda0
  - path: docs/issue-118/reports/execution-observation/scout-brief.md
    sha: fa8aed6d277254beb1502397cbfa26a0e5a9eda0
  - path: docs/issue-118/proposals/2026-08-04-independent-observation-of-pr-120.md
    sha: fa8aed6d277254beb1502397cbfa26a0e5a9eda0
---

# Execution observation — issue-118, step 2

## Independence

This role did not author, edit, or contribute to PR #120, to its commits
`caed0b13b9f5d17f7ba76ebe306a764acf7810ef` / `1b1056578d85c8f5c63b47d540bc00296d1f2124`,
to the merge commit `a167f117a75dcfc94cc4d2549477bb36378508f2`, or to the
`implementation` role's own record `docs/issue-118/reports/implementation.md`,
survey, or proposal. It did not re-run that role's task: neither
`core/hooks/tests/run-role-gates-tests.sh` nor
`core/hooks/tests/run-gate-lib-tests.sh` nor `record-fields-gate.sh` nor any
other hook was invoked in this session. Every `core/` file opened was read as
a blob at a pinned SHA (`git show a167f11:<path>`), never executed. This
session's only write surface is this file plus the three phase-1 paths named
in `docs/issue-118/proposals/2026-08-04-independent-observation-of-pr-120.md`
under `## Phase-2 deliverable` and `## Out of scope`. Nothing under `core/`,
nothing under `docs/issue-118/reports/implementation*`, nothing under any
other issue's tree.

**No verdict language appears above this line.** Everything below it is
verdict-bearing and carries its citation adjacent to the claim.

## Why

Issue #118's execution plan, step 2 — independent observation of step 1's
delivery. The observation target is fixed by the phase-1 survey
(`docs/issue-118/reports/execution-observation/survey.md`, `## Scope of this
observation`): the `implementation` role on branch `issue-118/implementation`,
delivered as PR #120 (https://github.com/tokenmaxxxer/tokenmaxxxer-core/pull/120),
state `MERGED`, merge commit `a167f11` (`gh pr view 120 --json state,mergeCommit`,
read this session).

Phase 2 opened under contract v3 §19's single-account path: PR #125's author is
`jjongkwann` and `docs/specs/approvers.md` lists `JiwonJung94` and `jjongkwann`,
so author and approver are the same account; issue comment `5175301021`
(https://github.com/tokenmaxxxer/tokenmaxxxer-core/issues/118#issuecomment-5175301021,
`gh api …/issues/118/comments`) has body exactly `APPROVE issue-118/execution-observation`,
`user: jjongkwann`, `type: User`, `created_at: 2026-08-04T06:13:20Z` — posted
after PR #125's `createdAt` of `2026-08-04T06:08:07Z`. String equality, not
prose reading. No near-match or approval-shaped non-approval was found on this
issue: the only other comment, `5174945342`, is byte-exactly
`APPROVE issue-118/implementation`, a valid approval addressed to the other
role.

## What was done

Five check points, each named in the approved proposal
(`docs/issue-118/proposals/2026-08-04-independent-observation-of-pr-120.md`,
`## The five check points`), executed against artifacts read directly by this
session. Artifacts read: issue #118 body and both comments (`gh issue view`,
`gh api …/issues/118/comments`); PR #120 metadata including `commits`,
`reviews`, `mergedAt`, `createdAt` (`gh pr view 120 --json …`); PR #120's full
diff (`gh pr diff 120`); both commits' messages and `--stat` (`git show
--stat`); `docs/issue-118/reports/implementation.md` in full (187 lines);
`a167f11:docs/issue-118/proposals/2026-08-04-add-defect-class-and-other-habitats-question-to-record-norm.md`
lines 100–169; `a167f11:docs/issue-118/reports/implementation/survey.md`
lines 40–60 plus a full-file `scout|skip` grep; `a167f11:core/hooks/record-fields-gate.sh`
in full (221 lines); `a167f11:core/contract/role-handoff-contract.md` §2's kind
table (lines 54–80) and §20 (lines 805–865); `a167f11:docs/issue-106/reports/implementation.md`
`## Next steps`; `a167f11:docs/issue-114/reports/execution-observation.md`
lines 1–40 and 350–385; `docs/specs/approvers.md`; PR #125 metadata. No
subagent read anything cited here; no artifact is taken from a secondhand
summary.

## Verdict — outcome

**PASS.** PR #120 landed what issue #118 asked, on all three requirements and
both constraints.

**Requirement 1 (add the standard question to the record norm) — met.** The
landed text at `a167f11:core/contract/role-handoff-contract.md:839-846` states
both halves the issue named: a lead-in at `:839-841` ("Additionally, whenever
the role's record states a confirmed `finding` entry (section 2's `finding`
kind, any `verdict` other than `Unverifiable`), the record must state:") and
item 6 at `:843-846` giving "(a) which defect class the finding belongs to,
and (b) whether that class was checked for elsewhere in the codebase outside
the observed scope, recording either the sweep's result or the reason a sweep
was not possible." That maps one-to-one onto the issue's `## 요구사항` item 1
(a)/(b) including its "조사 불가 사유를 기록한다" clause. On *location*: the
issue itself deferred the exact home to research ("계약 §20 계열의 기록 요건을
정의하는 이 레포 문서 — 정확한 위치는 조사로 확정"), and §20 is titled
"Per-role record minimum content" at `a167f11:core/contract/role-handoff-contract.md:811`
and is named as its own enforcement source by
`a167f11:core/hooks/record-fields-gate.sh:4` ("PreToolUse gate (Write|Edit|MultiEdit)
— contract §20"). The cross-reference the new text makes is accurate: §2's
kind table at `a167f11:core/contract/role-handoff-contract.md:70` defines the
`finding` kind with `verdict` values `Present|Surface|Absent|Incorrect|Unverifiable`,
so "any `verdict` other than `Unverifiable`" names a value that exists.

**Requirement 2 (documented norm only, no mechanization) — met, and verified
statically rather than by re-execution.** `record-fields-gate.sh` appears in
neither commit's `--stat` (`git show --stat caed0b1` → two docs files, 341
insertions; `git show --stat 1b10565` → `core/contract/role-handoff-contract.md`
+9 and `docs/issue-118/reports/implementation.md` +187, nothing else). And the
gate cannot pick the new item up implicitly: its required-field set at
`a167f11:core/hooks/record-fields-gate.sh:166-178` is a literal list of string
probes (`what was done`, `why`, `upstream`, a `loop_state:` regex,
`open findings`) with no derivation from §20's item count or numbering
anywhere in the file. The record's own claim to this effect
(`docs/issue-118/reports/implementation.md:106-116`, `closed_checks` at
`:120-124`) is confirmed against the script text.

**Requirement 3 (record the cross-repo rulebook need) — met.** The record's
`## Next steps` at `docs/issue-118/reports/implementation.md:128-144` names
the specific follow-up: adding a labeled defect-class / other-habitats field
to the `### Finding N` template in `tokenmaxxxer/execution-observation-rulebook`,
stated as unreachable from this working tree. The #106 precedent it invokes
has the same shape — `a167f11:docs/issue-106/reports/implementation.md:178-179`
carries "**`implementation-rulebook` per-role directive reflection (cross-repo,
not reachable from this branch).**" as a `## Next steps` entry rather than an
edit. Requirement 3's own wording ("여기서 못 고치는 부분이 있으면… 룰북 반영
필요성을 기록에 남긴다") asks for exactly that.

**Constraint 1 (`record-fields-gate` / `record-shape-gate` unchanged) — met**,
by the two `--stat`s above: no gate script, no test file appears in either.

**Constraint 2 (no retroactive edits to existing records) — met**, by the same
two `--stat`s: no `docs/issue-<n>/reports/execution-observation.md` and no
prior issue's tree appears in either commit.

## Verdict — trajectory

**PASS on the contract path; one deficiency on the scout path.**

**Phase ordering — sound.** `caed0b1`'s `--stat` (`git show --stat caed0b1`)
is docs-only — the proposal (169 lines) and the survey (172 lines), zero files
under `core/` — so the phase-1 commit carried no execution work, which is what
contract v3 §19 requires. PR #120 was opened at `2026-08-04T05:15:43Z`
(`gh pr view 120 --json createdAt`), 17 seconds after `caed0b1`'s `authoredDate`
of `05:15:26Z`.

**Approval typing — sound.** `gh pr view 120 --json reviews` returns `[]`, and
the PR's author is `jjongkwann`, who is also one of the two accounts in
`docs/specs/approvers.md`; that is §19's single-account mode, whose only
admissible path is an issue-level comment of exact string. Comment `5174945342`
(https://github.com/tokenmaxxxer/tokenmaxxxer-core/issues/118#issuecomment-5174945342)
has body byte-exactly `APPROVE issue-118/implementation`, `user: jjongkwann`,
`type: User`, `created_at: 2026-08-04T05:21:11Z`. The phase-2 commit `1b10565`
is authored and committed `2026-08-04T05:55:39Z` (`git show --stat 1b10565`),
after the approval. Ordering established from timestamps, not document order.

**The post-approval rebase does not disturb that ordering.** `caed0b1`'s
`committedDate` is `2026-08-04T05:52:20Z` while its `authoredDate` is
`05:15:26Z` (`gh pr view 120 --json commits`), i.e. the approved phase-1
commit was rewritten 31 minutes *after* the approval. This is not a defect:
the approval string names a branch and role, never a SHA, and the rebase left
the approved content identical — `docs/issue-118/reports/implementation.md:28-34`
states the rebase applied clean with §20 untouched by #116's contract diff,
and the phase-1 `--stat` still shows the same two files at the same
insertion counts. Recorded because a reader reconstructing the timeline from
`committedDate` alone would read the phase-1 commit as postdating its own
approval.

**Survey-before-proposal — not establishable from commit timestamps, and not
charged.** Both artifacts land in the single commit `caed0b1`, so their
relative authoring order leaves no artifact trace. What is on the record is
the declared dependence: the proposal's frontmatter at
`a167f11:docs/issue-118/proposals/2026-08-04-add-defect-class-and-other-habitats-question-to-record-norm.md:6-8`
names `docs/issue-118/reports/implementation/survey.md` as its `upstream`, and
the proposal's `## Out of scope` at `:145-147` argues from a conclusion it
attributes to the survey ("confirmed (survey) not to mirror any of §20's
existing five items today"). That is consistent with survey-first but does not
prove it; it is stated as analytic, not as an artifact finding.

**Scout — deficient.** See Finding 1.

## Verdict — step

**One artifact is deficient: the observed phase-1 tree
`docs/issue-118/reports/implementation/`, for the absent scout brief and
absent skip record (Finding 1).** A second, lower-severity charge attaches to
`a167f11:docs/issue-118/proposals/2026-08-04-add-defect-class-and-other-habitats-question-to-record-norm.md:8`
(Finding 2), which is the third recorded recurrence of a class two prior
observation records already diagnosed.

Not deficient at this level, each checked and each cleared below in `## What
is not deficient`: the landed §20 text, the record
`docs/issue-118/reports/implementation.md`, and the survey
`docs/issue-118/reports/implementation/survey.md`'s substantive claims.

## Open findings

Two, both open for the human to judge; neither is raised against another
role's live work, and this role files no issue for either (contract v3:
issues are user-authored).

### Finding 1 — the observed phase 1 has neither a scout brief nor a scout skip record

- **Impact.** `git ls-tree -r --name-only a167f11 -- docs` filtered for
  `scout-brief` returns 17 paths, and none is under
  `docs/issue-118/reports/implementation/`; the observed survey contains zero
  occurrences of either "scout" or "skip"
  (`git show a167f11:docs/issue-118/reports/implementation/survey.md | grep -i "scout\|skip"`
  → no output), as does the observed proposal. Under
  `a167f11:scout/hooks/directive.sh:31` scouting runs by default and skips
  only for a pure bugfix or a spec with no open design decision, and `:33`
  makes a one-line skip record mandatory when it is skipped — "No skip record
  means scouting was not properly skipped." Neither branch of that rule is
  evidenced here. Severity: **low**. The delivery's one real design decision
  (which document hosts the norm) was not made blind — the proposal at
  `a167f11:…-add-defect-class-and-other-habitats-question-to-record-norm.md:103-111`
  argues the §20-vs-decision-doc choice from issue #100's and issue #106's
  in-repo precedent. What is missing is the wider look, and — more concretely
  — the artifact that would let a reader tell "scouted and found nothing new"
  apart from "did not scout."
- **Timeline.** `caed0b1` authored `2026-08-04T05:15:26Z` carrying survey +
  proposal only (`git show --stat caed0b1`); PR #120 opened `05:15:43Z`
  (`gh pr view 120 --json createdAt`); no scout artifact appears in either
  commit's `--stat`, and none exists at the merge commit per the `ls-tree`
  above.
- **Root cause.** The obligation lives in `a167f11:scout/hooks/directive.sh:33`
  as session-time hook prose with no artifact-time check: nothing asserts that
  a phase-1 tree contains either a `scout-brief.md` or a skip line, so the
  omission produces no signal at commit time, at PR time, or at merge time.
  Whether the scout hook was even loaded in the observed session cannot be
  established from committed artifacts — that limit is stated, not guessed
  around; what the artifacts do establish is that the same role produced the
  brief in eight other issues' phase-1 trees (see habitats below), so the
  norm is not inapplicable to it.
- **Action item.** The human's, not this role's. Two independent decisions:
  (a) whether an absent scout brief with no skip record is worth an
  artifact-time check at all, given issue #118's own stated ordering
  convention (prose norm first, mechanize only once the norm is observed being
  ignored — `## 요구사항` item 2); and (b) whether the two habitats below that
  this session could not sweep are worth checking before deciding (a).
- **(a) Defect class.** *Documented norm whose only compliance evidence is a
  file's existence, with no mechanical check.* Same family as issue #118's own
  thesis: a norm stated in prose, invisible when skipped. Note this is the
  class the delivery under observation *creates another instance of* — §20
  item 6 is itself such a norm, deliberately so per requirement 2.
- **(b) Other habitats — swept in-repo, partially.** The 17 `scout-brief.md`
  paths at `a167f11` sit under issues #34, #53, #63, #72, #78, #90, #94, #98,
  #99, #100, #106, #107, #114, #116. Cross-referencing against issue trees
  that have a phase-1 `reports/implementation/` directory: **#107, #114 and
  #118 have one with no `scout-brief.md`**, while #116 — the immediately
  preceding `implementation` cycle — has one. So the class has at least three
  habitats in this repo. Whether #107's and #114's surveys carry a skip record
  instead **could not be checked from this branch**: `git show
  a167f11:docs/issue-114/…` piped to `grep` was refused by
  `core/hooks/board-gate.sh` ("board-gate: writing docs/issue-114/ requires
  branch issue-114/execution-observation"), which reads a pathspec mentioning
  a foreign issue tree as a write. Those two are therefore recorded as
  **unswept**, not as violations. The sweep is partial and is stated as such.

### Finding 2 — the approved proposal's `upstream[].sha` was never resolved (third recorded recurrence)

- **Impact.**
  `a167f11:docs/issue-118/proposals/2026-08-04-add-defect-class-and-other-habitats-question-to-record-norm.md:8`
  reads `sha: <set at commit>` and is unchanged through the merge, while the
  same session's record does carry a real SHA at
  `docs/issue-118/reports/implementation.md:9`
  (`caed0b13b9f5d17f7ba76ebe306a764acf7810ef`). A reader cannot tell from the
  field which revision of the survey the proposal was approved against.
  Severity: **low** — both files land in `caed0b1`, so the answer is
  recoverable from git, but by inference rather than from the field that
  exists to state it.
- **Timeline.** Written at `caed0b1` (`2026-08-04T05:15:26Z`), unchanged at
  `a167f11`. The identical field state was charged as Finding 4 of
  `docs/issue-98/reports/execution-observation.md` and again as Finding 2 of
  `a167f11:docs/issue-114/reports/execution-observation.md:359-384`, one
  observed cycle earlier.
- **Root cause.** Unchanged from what that prior record diagnosed
  (`a167f11:docs/issue-114/reports/execution-observation.md:373-378`): a
  self-reference problem — the survey's SHA does not exist when the proposal
  citing it is written, and no post-commit amend step exists. Structural, not
  carelessness.
- **Action item.** The human's. The structural fix pattern already exists in
  this repo — issue #100's decision replaced a SHA with a write-time-knowable
  value for `code_under_review`, and `a167f11:core/hooks/record-fields-gate.sh:187-195`
  now enforces that replacement for `coding`/`implementation` records —
  whether to extend the same treatment to `upstream[].sha` is the open
  question, unchanged since #98.
- **(a) Defect class.** *Frontmatter forward-reference that cannot be resolved
  at write time.*
- **(b) Other habitats — swept in-repo, partially.**
  `git grep -rn "set at commit" a167f11 -- docs` truncated at its first 20
  hits spans issues #38, #46, #49, #100, #107, #109, #114 and #118, across
  both `proposals/` (`upstream[].sha`) and `reports/` (`code_sha`,
  `code_under_review`). The class is therefore repo-wide and long-standing,
  not introduced by PR #120. The enumeration is **partial** — it was truncated
  by the `head -20` this session ran, so the real population is larger than
  the eight issues named.

## What is not deficient

Each of these was a phase-1 unknown, checked and cleared:

- **Placement fidelity (survey U3) — reconciled, no charge.** The proposal's
  `## What will be done` item 1
  (`a167f11:…-add-defect-class-and-other-habitats-question-to-record-norm.md:116-124`)
  asks for "one new numbered item… worded to apply specifically when a role's
  record states a confirmed `finding` entry", and `## How you'll know it
  worked` (`:157-160`) asks for it "positioned among the existing numbered
  list without renumbering or altering items 1–5." The landed shape satisfies
  both: the numbering is continuous 1–6 in one list
  (`a167f11:core/contract/role-handoff-contract.md:821-846`), items 1–5 are
  byte-unchanged (9 insertions / 0 deletions, `gh pr diff 120` hunk
  `@@ -836,6 +836,15 @@`), and the conditional lead-in at `:839-841` is the
  mechanism item 1 itself demanded ("worded to apply specifically when…") —
  mirroring the section's pre-existing conditional lead-in for items 4–5 at
  `:831`. The two proposal passages are not in conflict.
- **Binding scope (survey U4) — as the issue authorized.** The landed norm
  binds any role's record rather than only observation records, but issue #118
  requirement 1 explicitly deferred the location to research, and the survey's
  grep claim is confirmed: `git show a167f11:core/contract/role-handoff-contract.md
  | grep -in observation` returns only lines 135–136, about direct system
  observation — the contract has no observation-specific section to host it.
  The binding is also narrower in practice than "every role", since it fires
  only on a confirmed `finding` entry.
- **The non-mechanization claim (survey U5) — confirmed**, at
  `a167f11:core/hooks/record-fields-gate.sh:166-178`, as set out under
  Requirement 2 above.
- **Requirement 3's #106 precedent (survey U6) — confirmed** structurally
  identical at `a167f11:docs/issue-106/reports/implementation.md:167,178-179`.
- **The population question turned on this delivery (survey U7) — closed, and
  it comes out clean.** `git grep -ln "record must state\|must state, at
  minimum\|record minimum\|required fields" a167f11 -- core docs/handbooks
  docs/specs freelunch scout warrant` returns exactly one file:
  `core/contract/role-handoff-contract.md`. The prose norm has a single
  in-repo home, so no sibling document now trails §20 by one question. The
  mechanical homes that cite §20 — `core/hooks/record-fields-gate.sh`,
  `core/hooks/tests/run-role-gates-tests.sh`,
  `docs/handbooks/role-gates-tests.md` — trail it deliberately, which is
  requirement 2. This is a wider enumeration than the record's own sweep
  (`docs/issue-118/reports/implementation.md:45-51`, three `directive.sh`
  files) and reaches the same conclusion, so the record's narrower sweep is
  not charged.
- **The observed survey's missing `loop_state` (survey U8) — no contract
  requirement behind it, no charge.** `record-fields-gate.sh`'s record regex
  at `a167f11:core/hooks/record-fields-gate.sh:109`
  (`^docs/issue-[0-9]+/reports/<role>\.md$`) does not reach survey files at
  all, and §2's artifact-kind table at
  `a167f11:core/contract/role-handoff-contract.md:56-73` defines no
  `current-state-survey` kind, so no `loop_state` vocabulary is specified for
  one. That the survey kind is unsanctioned by §2 is a standing repo-wide
  convention gap — this role's own phase-1 survey uses the same unsanctioned
  `kind:` — and is not attributable to PR #120.

## Method and its limits

- **No re-execution.** No test suite, hook, or gate was invoked. The record's
  test counts (19/0 role-gates; 53/1 gate-lib with its pre-existing-sandbox
  explanation at `docs/issue-118/reports/implementation.md:167-179`) are
  treated as *record claims* and are not independently confirmed here; nothing
  in the verdicts above rests on them.
- **Pinned reads.** Every `core/` and cross-issue citation is a blob read at
  `a167f11` or at a named commit, never a floating working-tree read.
- **Evidence tiers.** All verdict claims above are *artifact* (a direct read
  of a blob, diff, or GitHub API record) except two, marked in place as
  *analytic*: survey-before-proposal ordering, and the reconciliation argument
  under placement fidelity.
- **Out of reach, stated as such.** (1) `tokenmaxxxer/execution-observation-rulebook`
  is not present in this checkout; requirement 3's cross-repo half is judged
  only on whether the record *recorded* the need, never on the rulebook's
  state. (2) #107's and #114's implementation surveys, for Finding 1's habitat
  sweep — blocked by `board-gate.sh` on this branch, as recorded there.
  (3) Whether the scout hook was active in the observed session.
- **Self-application.** Both findings above carry §20 item 6's (a) and (b) —
  the norm this observed delivery landed, applied to this record's own
  findings. Where a sweep was partial, the partiality is stated rather than
  the sweep being claimed complete.

## Next steps

- The human judges Finding 1 and Finding 2 and files (or declines to file) any
  issue. This role files none.
- Merging this PR is the human's act of acceptance. Nothing in this record
  ratifies PR #120 — that PR was already merged as `a167f11` before this
  observation opened.

## Resolution path

Both findings are recorded here for the human, per contract v3: neither is
raised as a blocking `finding:` against another role's live record, and this
role does not edit the observed artifacts. Finding 2's resolution path already
exists in the repo as a pattern (issue #100's decision, now enforced for
`code_under_review` at `a167f11:core/hooks/record-fields-gate.sh:187-195`);
extending it to `upstream[].sha` is the standing open question, unchanged
since it was first recorded two observed cycles ago. Finding 1 has no
in-repo resolution path yet, by design — issue #118's own `## 요구사항` item 2
sets the convention that a prose norm is mechanized only after it is observed
being ignored, and this record is one such observation.
