---
kind: current-state-survey
subject: issue-128
produced_by: execution-observation
phase: 1
---

# Current-state survey — issue-128, step 2 (execution-observation)

## Scope under observation

- **Role observed:** `implementation`, on subject `issue-128`.
- **Session observed:** the implementation role's two headless sessions,
  transcripts at
  `~/.claude/projects/-Users-jk--tokenmaxxxer-work-tokenmaxxxer-core-issue-128-implementation/8a50b3a6-d7d1-4518-a7bd-d0a6ca014e4f.jsonl`
  (mtime 2026-08-04 15:48 KST) and `8b531272-4c69-4c5d-956d-2843db8a64eb.jsonl`
  (mtime 2026-08-04 15:58 KST) — `ls -la` this session. Their mtimes bracket
  the two commits below; the transcripts themselves are listed here as
  available evidence and are **not** read as of this survey.
- **Issue:** #128 — "upstream[].sha 규약이 같은-커밋 인용에서 이행 불가능 —
  3회 재발의 구조 원인 해소" (`gh issue view 128`), three numbered
  requirements under `## 요구사항`, two constraints under `## 제약`, and a
  two-step execution plan whose step 1 is `implementation` and step 2 is
  this role.
- **PR:** #129 — <https://github.com/tokenmaxxxer/tokenmaxxxer-core/pull/129>,
  state `MERGED`, `additions: 720`, `deletions: 2`, `baseRefName: main`,
  `headRefName: issue-128/implementation`, created `2026-08-04T06:47:51Z`,
  merged `2026-08-04T06:59:26Z` as merge commit `d588e95`
  (`gh pr view 129 --json createdAt,mergedAt,mergeCommit,...`).
- **Commits under observation:** `6963e3b` (phase 1: proposal + survey +
  scout brief, 3 files, +450) and `6486c4b` (phase 2 delivery, `core/` diff
  +79/−2 across 3 files plus `docs/handbooks/role-gates-tests.md` and the
  record) — `git show --stat` on each, this session.
- **Not in scope:** the 16+ pre-existing `<set at commit>` placeholder
  instances the issue's `## 제약` excludes from retroactive fixing;
  `code_under_review` and `closed_checks[].code_sha`, which both issue #128's
  constraint list and the proposal's `## Out of scope`
  (`docs/issue-128/proposals/2026-08-04-build-same-commit-upstream-sha-convention.md:44-45,155-157`)
  place outside this subject.

## What was read this session, first-hand

| Artifact | How read |
| --- | --- |
| Issue #128 body | `gh issue view 128` — full body incl. `## 요구사항` 1-3, `## 제약`, `## 실행 계획` |
| Issue #128 comments | `gh issue view 128 --comments`, `gh api .../issues/128/comments` — exactly one comment |
| PR #129 body, state, metadata | `gh pr view 129`, `gh pr view 129 --json commits,mergedAt,mergeCommit,author,baseRefName,headRefName,reviews,comments,createdAt` |
| Commit `6963e3b` (phase-1 propose) | `git show --stat 6963e3b` — full message + 3-file stat |
| Commit `6486c4b` (phase-2 deliver) | `git show 6486c4b -- core/` — full diff of all three `core/` files + full message |
| The observed role's record `docs/issue-128/reports/implementation.md` | read in full, frontmatter through `## Verify` (193 lines) |
| The observed role's proposal `docs/issue-128/proposals/2026-08-04-build-same-commit-upstream-sha-convention.md` | read in full (178 lines) |
| Contract §19 (approval gate), §20 (per-role record minimum content) | `core/contract/role-handoff-contract.md:672-730`, `:827-870` |
| `docs/specs/approvers.md` | read in full — two accounts: `JiwonJung94`, `jjongkwann` |
| Prior execution-observation phase-1 artifacts (issue-122) | `docs/issue-122/reports/execution-observation/survey.md`, `.../scout-brief.md`, `docs/issue-122/proposals/2026-08-04-observe-pr-123-trailer-mirror.md` — read for this role's own established phase-1 shape |

Line counts of the observed role's own phase-1 artifacts, `wc -l` this
session: `docs/issue-128/reports/implementation/survey.md` 186,
`.../scout-brief.md` 86, the proposal 178, the record 193.

**Not read as evidence, deliberately:** the working-tree contents of
`core/hooks/record-fields-gate.sh`, `core/hooks/tests/run-role-gates-tests.sh`,
and `core/contract/role-handoff-contract.md` §1/§12 as a statement of what
the observed session did. Working-tree source shows what exists now, not
what that session produced; the diff of `6486c4b` is the admissible record
of that. §19/§20 were read from the contract as the standard being applied
to the observation, which is a different use than evidence-of-what-happened.
No test suite from the observed delivery was re-run, and none will be —
re-executing the observed role's task is prohibited for this role.

## Approval state (read this session)

Issue #128 carries exactly one comment (`gh api` output above): body
`APPROVE issue-128/implementation`, author `jjongkwann`, created
`2026-08-04T06:48:33Z`. `jjongkwann` is listed in `docs/specs/approvers.md`
and is also PR #129's author (`gh pr view 129 --json author` →
`login: jjongkwann`), so the single-account path of contract §19
(`core/contract/role-handoff-contract.md:707-724`) is the applicable one.
`gh pr view 129 --json reviews,comments` returns `"reviews":[]` and
`"comments":[]` — no PR-level review or comment exists on #129 at all.

For **this** role: no comment whose body is `APPROVE
issue-128/execution-observation` exists on issue #128, and no PR exists for
branch `issue-128/execution-observation` (`git branch -a` shows no
`remotes/origin/issue-128/execution-observation`). Phase 2 of this role is
therefore not open, and this survey, the scout brief, and the proposal are
the only files this session writes.

Stated plainly once, per this role's near-miss duty: the single
approval-shaped comment on issue #128 names the role `implementation`, not
`execution-observation`. It is not a near-match of this role's approval
string and is not being read as one — it is recorded here only so the human
knows this session read it and identified whose approval it is.

## Write surfaces this role owns, and their current state

| Path | Phase | State today |
| --- | --- | --- |
| `docs/issue-128/reports/execution-observation/survey.md` | 1 | did not exist before this commit — `ls docs/issue-128/reports/` showed only `implementation`, `implementation.md` |
| `docs/issue-128/reports/execution-observation/scout-brief.md` | 1 | same — absent before this commit |
| `docs/issue-128/proposals/<date>-observe-pr-129-*.md` | 1 | `docs/issue-128/proposals/` holds exactly one file, the observed role's build proposal; this role adds a second, and edits no existing file |
| `docs/issue-128/reports/execution-observation.md` | 2 | absent; not written before an Approve for this role |

Nothing under `core/`, `src/`, `test/`, `docs/handbooks/`, or another role's
record area is written by this role in either phase. The observed role's
`docs/issue-128/reports/implementation.md` and its `implementation/`
subtree are read-only to this session.

## Current state of the change under observation (facts only, no judgment)

- Issue #128 requirement 1 asks for a decision among three candidates. The
  proposal's `## Rationale` (`…build-same-commit-upstream-sha-convention.md:49-114`)
  selects candidate (a), `sha: same-commit`, and states one rejection
  paragraph each for (b) two-commit phase 1 and (c) gate-enforced
  post-commit amend.
- Issue #128 requirement 2 asks that the decision be codified in
  "기록 관례 문서(계약 §20 계열)". The proposal restates that target as
  "the contract's own record-norm text (§1/§12 family)"
  (`…-convention.md:30-31`), and `6486c4b`'s diff edits §1 (the
  `upstream[].sha` bullet list, `role-handoff-contract.md` +8 lines after
  the chain-root bullet) and §12 (a new "Same-commit exemption" paragraph,
  +8 lines). The diff touches no line of §20.
- Issue #128 requirement 3 asks for a judgment on mechanical rejection and,
  if yes, its design. `6486c4b` adds to `core/hooks/record-fields-gate.sh`:
  a `PROPOSALS_RE = ^docs/issue-[0-9]+/proposals/.*\.md$` path match
  alongside the existing `RECORDS_RE`, a `placeholder_shas()` helper with
  regex `^\s*sha:\s*(<[^\n]*>)\s*$` (multiline), a `deny_placeholder()`
  message, an early-exit branch for `is_proposal and not is_record`, and one
  call of the same check on the record path after the existing §20 `missing`
  logic.
- `6486c4b` adds five `run_rf` cases to
  `core/hooks/tests/run-role-gates-tests.sh` (three proposal-path, two
  record-path) and the record states `role-gates: 24 passed, 0 failed`
  (`docs/issue-128/reports/implementation.md:166-167`).
- The record states one `run-gate-lib-tests.sh` failure and attributes it to
  a pre-existing sandbox artifact, reporting a `git stash` A/B comparison as
  the basis (`docs/issue-128/reports/implementation.md:173-185`).
- The record's `## Hunt` section states two stances, both `Verdict: NO
  FINDING`, and states that `warrant-hunter` was unavailable as a subagent
  type in that session (`docs/issue-128/reports/implementation.md:95-136`).
- The proposal's own frontmatter carries two `upstream` entries with
  `sha: same-commit` (`…-convention.md:6-10`), i.e. the convention appears
  in the same commit that proposes it; the record's frontmatter carries a
  real 40-hex sha for its upstream proposal
  (`docs/issue-128/reports/implementation.md:7-9`).

## Unknowns (open, stated as unknowns)

1. **Requirement-2 target mismatch.** The issue names "계약 §20 계열" as the
   codification home; the delivered edits are in §1 and §12. Whether §1/§12
   is the same "family" the issue meant, or a different section than asked
   for, is not resolved by any artifact read so far — it needs §20's own
   text and §1's `upstream[].sha` definition compared against the issue
   wording. Unresolved as of this survey.
2. **Placeholder-shape coverage.** The delivered regex denies only
   bracketed values (`<...>`). Whether any non-bracket unresolved-value
   shape (`TBD`, `pending`, an empty value) occurs in this repo's records
   today, and whether the issue's requirement 3 covers those, is unknown
   until a repo-wide sweep is run.
3. **Path-scope coverage (§20 other-habitats question).** `PROPOSALS_RE`
   matches only `docs/issue-<n>/proposals/`. Whether the same placeholder
   class lives in other document homes the contract defines
   (`docs/proposals/`, `docs/decisions/`, `docs/reports/`, per-issue
   `reports/<role>/` subtrees such as a survey or scout brief) is unknown
   until swept.
4. **Verification evidence is single-sourced.** The `24 passed, 0 failed`
   and `ALL OK` figures exist only as text inside the observed role's own
   record. This role is prohibited from re-running that suite, so whatever
   is concluded about them must rest on the test-file diff and the record's
   internal consistency, not on a re-execution. How far that supports a
   verdict is an open question this proposal must answer, not assume.
5. **Phase-1 internal ordering.** Whether the observed session ran its
   survey before its scout pass and its proposal after both — contract §19
   plus the scout directive's SURVEY-FIRST ORDER — cannot be read off a
   single squashed phase-1 commit (`6963e3b` contains all three files). The
   two transcripts listed under `## Scope` are the only evidence that could
   settle it; they are unread as of this survey.
6. **Approval timing.** `6963e3b` is authored `06:47:26Z`, PR #129 created
   `06:47:51Z`, the APPROVE comment `06:48:33Z`, `6486c4b` authored
   `06:58:26Z`. The ordering is recorded here as read; whether the phase-1
   commit contained only phase-1 material (i.e. no execution work landed
   before the Approve) requires the `6963e3b` file list to be checked
   against §19's phase-1 scope, which this survey has stated but not
   evaluated.
