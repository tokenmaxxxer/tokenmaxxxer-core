---
kind: current-state-survey
subject: issue-133
produced_by: execution-observation
phase: 1
---

# Current-state survey — issue-133, step 2 (execution-observation)

## Scope under observation

- **Role observed:** `implementation`, on subject `issue-133`.
- **Sessions observed:** the implementation role's two headless sessions,
  transcripts at
  `~/.claude/projects/-Users-jk--tokenmaxxxer-work-tokenmaxxxer-core-issue-133-implementation/99273927-d8d4-41f2-8205-6c6dd4dff7b6.jsonl`
  (mtime 2026-08-04 16:26 KST, 582 989 B) and
  `216005c3-e0e9-4e9e-a054-62c46f2b7348.jsonl` (mtime 2026-08-04 16:35 KST,
  611 745 B) — `ls -la` this session. Their mtimes bracket the two commits
  below. Listed here as **available** evidence; **not read** as of this
  survey.
- **Issue:** #133 — "record-fields-gate 의 sha 검증을 화이트리스트로 —
  same-commit 또는 40-hex 만 허용 (#128 관찰 Finding 1)" (`gh issue view
  133`): three numbered requirements under `## 요구사항`, one constraint
  line under `## 제약`, and a two-step `## 실행 계획` whose step 1 is
  `implementation` and step 2 is this role.
- **PR:** #134 — <https://github.com/tokenmaxxxer/tokenmaxxxer-core/pull/134>,
  state `MERGED`, `+598/−16`, `baseRefName: main`, `headRefName:
  issue-133/implementation`, created `2026-08-04T07:26:23Z`, merged
  `2026-08-04T07:35:51Z` as merge commit `6236f9b5cf93ed880a3b362d892bf53888956b97`
  (`gh pr view 134 --json createdAt,mergedAt,mergeCommit,state,...`).
  `reviews: []` and `comments: []` — the PR carries no review and no
  comment at all.
- **Commits under observation:** `de2b09c59963a1d4b64f3a0ced31513fe52d98d0`
  (phase 1, committed `2026-08-04T07:24:31Z`, 2 files, +347: the proposal
  and the implementation survey) and
  `778b810c0dcca9b300f644d78810e0b1e655e3c2` (phase 2, committed
  `2026-08-04T07:34:46Z`, 4 files, +251/−16: the gate, the test harness,
  the handbook paragraph, and the role record).
- **Not in scope:** the 23 already-landed `<set at commit>` instances and
  the one live unresolved value in
  `docs/issue-20/proposals/2026-07-31-build-gh-guard-endpoint-match.md`,
  both of which issue #133 requirement 3 explicitly excludes from
  retroactive fixing; `code_under_review` and the five §20 field checks,
  which issue #133's `## 제약` and the observed proposal's `## Out of
  scope` (`docs/issue-133/proposals/2026-08-04-build-sha-whitelist-check.md`,
  `## Constraints` and `## Out of scope`) both place outside this subject.

## What was read this session, first-hand

| Artifact | How read |
| --- | --- |
| Issue #133 body | `gh issue view 133` — full body incl. `## 요구사항` 1-3, `## 제약`, `## 실행 계획` |
| Issue #133 comments | `gh api repos/tokenmaxxxer/tokenmaxxxer-core/issues/133/comments` with author, timestamp and `html_url` printed — exactly one comment |
| PR #134 metadata | `gh pr view 134 --json number,title,author,state,mergedAt,mergeCommit,headRefName,baseRefName,body,reviews,comments`, plus a second call for `createdAt,additions,deletions` |
| PR #134 commit list | `gh pr view 134 --json commits` — two commits with `committedDate` |
| PR #134 changed-file list | `gh pr diff 134 --name-only` — 6 paths |
| Commit `de2b09c` | `git show --stat` — message + 2-file stat |
| Commit `778b810` | `git show --stat`; full diff of `core/hooks/record-fields-gate.sh`; full diff of `core/hooks/tests/run-role-gates-tests.sh` and `docs/handbooks/role-gates-tests.md` |
| The gate **as delivered at `778b810`** | `git show 778b810:core/hooks/record-fields-gate.sh`, lines 140-230 — used for control-flow order around the changed helper, never the working tree |
| The observed role's record `docs/issue-133/reports/implementation.md` | `git show 778b810:…` — read in full, frontmatter through `## Verify` |
| The observed role's proposal | `git show de2b09c:docs/issue-133/proposals/2026-08-04-build-sha-whitelist-check.md` — read in full |
| The observed role's survey | `git show de2b09c:docs/issue-133/reports/implementation/survey.md` — read in full |
| Contract §20 (per-role record minimum content, incl. the class question) | `core/contract/role-handoff-contract.md:827-870` |
| `docs/specs/approvers.md` | read in full — two accounts: `JiwonJung94`, `jjongkwann` |
| `docs/issue-128/reports/execution-observation.md` | Finding-1 context and this role's own established record shape (frontmatter through `## What was read`) |
| Prior phase-1 artifacts of this role (issue-128) | `docs/issue-128/reports/execution-observation/survey.md` and `.../scout-brief.md` — read in full, for this role's established phase-1 shape |
| Repo corpus, `sha:` value shapes | `grep -rEn "^[[:space:]]*sha:" --include="*.md" docs/` (89 lines total) and a second grep for empty-valued `sha:` lines (0 hits), read-only |

**Not read as evidence of what happened, deliberately:** the working-tree
contents of `core/hooks/record-fields-gate.sh`,
`core/hooks/tests/run-role-gates-tests.sh`, or
`docs/handbooks/role-gates-tests.md`. The working tree shows what exists
now, not what the observed sessions produced; `778b810`'s diff and blob are
the admissible record of that. Contract §20 was read as the *standard being
applied*, which is a different use than evidence-of-what-happened. No test,
gate, or script from the observed delivery was executed, and none will be —
re-running the observed role's code is prohibited for this role, so every
claim below and in phase 2 rests on inspection, never re-performance.

## Approval state (read this session)

Issue #133 carries exactly **one** comment: body `APPROVE
issue-133/implementation`, author `jjongkwann`, created
`2026-08-04T07:27:17Z`,
<https://github.com/tokenmaxxxer/tokenmaxxxer-core/issues/133#issuecomment-5175895602>.
`jjongkwann` is listed in `docs/specs/approvers.md` and is also PR #134's
author (`gh pr view 134 --json author` → `login: jjongkwann`), so contract
§19's single-account path is the applicable one for the observed role.

For **this** role: no comment whose body is `APPROVE
issue-133/execution-observation` exists on issue #133, and no PR exists for
branch `issue-133/execution-observation` (`git branch -r` shows no
`origin/issue-133/execution-observation`). Phase 2 of this role is
therefore **not open**; this survey, the scout brief, and the proposal are
the only files this session writes.

Stated plainly once, per this role's near-miss duty: the single
approval-shaped comment on issue #133 names the role `implementation`, not
`execution-observation`. It is not a near-match of this role's approval
string and is not being read as one — it is recorded here only so the human
knows this session read it and identified whose approval it is.

## Write surfaces this role owns, and their current state

| Path | Phase | State today |
| --- | --- | --- |
| `docs/issue-133/reports/execution-observation/survey.md` | 1 | did not exist before this commit — `ls docs/issue-133/reports/` showed only `implementation`, `implementation.md` |
| `docs/issue-133/reports/execution-observation/scout-brief.md` | 1 | same — absent before this commit |
| `docs/issue-133/proposals/2026-08-04-observe-pr-134-sha-whitelist.md` | 1 | `docs/issue-133/proposals/` holds exactly one file, the observed role's build proposal; this role adds a second and edits no existing file |
| `docs/issue-133/reports/execution-observation.md` | 2 | absent; not written before an Approve for this role |

Nothing under `core/`, `src/`, `test/`, `docs/handbooks/`, or another
role's record area is written by this role in either phase. The observed
role's `docs/issue-133/reports/implementation.md` and its
`implementation/` subtree are read-only to this session.

**Gate interaction with this role's own write surfaces (relevant, and new
under this delivery).** `docs/issue-133/proposals/…` matches
`PROPOSALS_RE`, and `docs/issue-133/reports/execution-observation.md`
matches `RECORDS_RE` when `CLAUDE_ROLE=execution-observation` — so the very
check under observation runs against two of the four rows above at write
time. The delivered helper collects *every* `^\s*sha:\s*(.*)$` line in the
reconstructed text whose value is not `same-commit` or 40 lowercase hex
(`git show 778b810:core/hooks/record-fields-gate.sh:174-181`), with no
exclusion for fenced code blocks or quoted examples. This survey file is
**not** matched by either pattern (`reports/<role>/survey.md` is a
subdirectory path, not `reports/<role>.md`), which is why the unresolved
spellings can be quoted verbatim here and, factually, cannot be quoted at
line-start in this role's proposal or record. Recorded as a state fact
here; whether it is a defect is a phase-2 question, not this survey's.

## Current state of the change under observation (facts only, no judgment)

- **Requirement 1 (whitelist conversion).** `778b810` replaces
  `placeholder_shas()`'s body: the previous single-expression
  comprehension over `r'^\s*sha:\s*(<[^\n]*>)\s*$'` becomes a loop over
  `r'^\s*sha:\s*(.*)$'` that `continue`s on `v == "same-commit"` or
  `re.match(r'^[0-9a-f]{40}$', v)` and otherwise appends `v` to `bad`
  (`git show 778b810 -- core/hooks/record-fields-gate.sh`, hunk at
  `:169-185`). `deny_placeholder()`'s message text changes from "is a
  bracket placeholder, not a resolvable value (issue-128)" to "is not
  `same-commit` or a 40-character hex commit sha (issue-128/133)" in the
  same hunk.
- **Call sites and path scope.** The same diff shows the two call sites
  (`is_proposal and not is_record` early exit, and the post-§20 record
  path) and `PROPOSALS_RE`/`RECORDS_RE` outside every changed hunk; the
  blob at `778b810:core/hooks/record-fields-gate.sh:190-194,223-225`
  confirms both call sites still invoke the same helper.
- **Requirement 2 (red→green).** `778b810` adds three `run_rf deny` cases
  to `core/hooks/tests/run-role-gates-tests.sh` immediately after the
  existing issue-128 block, on a proposal path
  (`docs/issue-3/proposals/2026-08-04-x.md`), for the values `HEAD`,
  `TBD`, and `<set at commit> -- fix later`. The five existing issue-128
  cases are outside the diff hunks. The "green" half is asserted in the
  test file; the "red" half (that the same three passed *before* the fix)
  is asserted only in prose in the record's `## Verify`, which states the
  pre-fix script was extracted via `git show HEAD:…` and run as a
  subprocess in that session (`docs/issue-133/reports/implementation.md`,
  `## Verify`, final paragraph) — that scratch check is stated as **not
  committed**.
- **Requirement 3 (no retroactive fix).** `gh pr diff 134 --name-only`
  lists exactly six paths: `core/hooks/record-fields-gate.sh`,
  `core/hooks/tests/run-role-gates-tests.sh`,
  `docs/handbooks/role-gates-tests.md`, and three `docs/issue-133/**`
  files. No `docs/issue-20/**` path appears in either commit.
- **The handbook.** `778b810` rewrites the `record-fields-gate.sh`
  paragraph in `docs/handbooks/role-gates-tests.md` (+11/−8 within one
  paragraph) from blacklist prose to allow-list prose, naming all three
  now-denied spellings.
- **Delivery beyond the proposal's four items.** The same diff also
  rewrites the gate's top-of-file comment block (`:12-19`, +7/−4). The
  record discloses this under `## Rationale for deviations` as a
  same-file, same-turn consistency fix.
- **Scouting.** The observed role's survey opens with a `## Scout skip
  record` claiming the "spec leaves no design decision open" condition
  (`git show de2b09c:docs/issue-133/reports/implementation/survey.md`,
  `## Scout skip record`). The proposal committed in the same commit
  carries a `## Rationale` section with two explicitly rejected
  alternatives (a YAML-parser rewrite; a 7-40 hex range instead of exactly
  40) and one `**Failure signal.**` paragraph.
- **Corpus state, this session's own read-only grep.** 89 `^\s*sha:` lines
  exist under `docs/`; zero of them have an empty value. The observed
  survey's own tally reports 51 × 40-hex, 23 × `<set at commit>`, 4 ×
  `same-commit`, 1 × `HEAD`, 1 × contract-template placeholder text, and 5
  × 7-character abbreviated hex in `execution-observation` records
  (issues 90, 107, 116, 122, 124).
- **The record's own §20 shape.** `docs/issue-133/reports/implementation.md`
  at `778b810` carries `loop_state: landed`, an `upstream` entry citing the
  proposal at the full 40-hex `de2b09c…`, `## Why`, `## What was done`,
  `## What did not work`, `## Rationale for deviations`, `## Doc-placement
  ladder`, `## Hunt` (two stances, both `Verdict: NO FINDING`), `## Next
  steps`, `## Resolution path`, and `## Verify`.

## Unknowns (open, stated as unknowns)

1. **False-positive reach of the new allow-list.** The old regex flagged
   only bracket-shaped values; the new one evaluates every `sha:` line in
   the whole reconstructed document, fenced example blocks included. Which
   *legitimate* writes this newly denies — a record quoting an unresolved
   spelling as an example, an abbreviated sha, an uppercase-hex sha, an
   empty value — is unknown until each candidate is traced by hand against
   the delivered regex and cross-checked against the corpus. The observed
   proposal's `## Rationale` addresses exactly one of these (abbreviated
   shas) and names a failure signal for it; the others are unaddressed in
   any artifact read so far.
2. **Empty-value handling vs. issue requirement 1.** Requirement 1 says the
   empty-`upstream` case stays "기존 규약대로" (under the existing
   convention). Whether "empty" means an absent `upstream` list (no `sha:`
   line at all, structurally out of the regex's reach) or an empty `sha:`
   value (which the new loop would collect as `bad`, where the old regex
   ignored it) is not resolved by any artifact read so far. This session's
   grep found zero empty-valued `sha:` lines in the current corpus, so the
   question is about future writes, not existing ones.
3. **Requirement-2 evidence tier asymmetry.** The green half is committed
   as three test cases; the red half exists only as the record's own prose
   about an uncommitted scratch run. This role is barred from re-running
   either. How far the committed artifacts alone support a requirement-2
   verdict — and what the honest evidence tier for that verdict is — is an
   open question the proposal must answer, not assume.
4. **Scout-skip validity.** The skip record claims no open design decision,
   while the same commit's proposal records rejecting two alternatives.
   Whether those constitute "design decisions" in the scout directive's
   sense, or are the ordinary rationale any proposal carries, is unresolved
   from the two committed phase-1 files alone; the phase-1 transcript
   listed under `## Scope` is the only further evidence available and is
   unread.
5. **Phase-1 internal ordering.** Whether the observed session wrote its
   survey before its proposal (contract §19 plus the scout directive's
   survey-first order) cannot be read off `de2b09c`, which contains both
   files in one commit. Only the phase-1 transcript could settle it.
6. **The §20 class question, applied to this delivery.** §20's clause 6
   (defect class + other habitats) binds a record that states a *confirmed*
   finding; the observed record states two `NO FINDING` hunt stances, so
   whether clause 6 was owed at all here is itself a question. Separately,
   whether the *class* the issue-128 finding named ("a validator that
   enumerates bad values instead of good ones") has other habitats in this
   repo's gate family — other line-regex content checks in
   `record-fields-gate.sh`, `trailer-gate.sh`, `handbook-trigger-gate.sh`,
   `stub-check.sh` — is unswept as of this survey.
