---
kind: current-state-survey
subject: issue-124
produced_by: execution-observation
phase: 1
---

# Current-state survey — issue-124, step 2 (execution-observation)

## Scope under observation

- **Role observed:** `implementation`, on subject `issue-124`.
- **Issue:** #124 — "래퍼 파서-차동 클래스 잔여 서식지 R1·R2·R3 일괄 종료
  (#114 관찰 Verdict 4 전수 조사)", state `OPEN` (`gh issue view 124`).
- **PR observed:** #126 —
  <https://github.com/tokenmaxxxer/tokenmaxxxer-core/pull/126>, head
  `issue-124/implementation`, base `main`, author `jjongkwann`, state
  `MERGED` at `2026-08-04T06:46:00Z`, merge commit `43bd873`
  (`gh pr view 126 --json ...`).
- **Commits observed:** exactly two on that branch
  (`gh pr view 126 --json commits`):
  - `7fcd4cd` — `propose(implementation): …` (phase 1), 2 files, +490.
  - `fdb620d` — `deliver(implementation): …` (phase 2), 9 files,
    +537/−11.
- **Not in scope of this observation:** the `warrant/` plugin trees that
  neither commit touches; `core/hooks/gh-guard.sh`, which issue #124's own
  `## 제약` and the observed proposal's `## Constraints`
  (`docs/issue-124/proposals/2026-08-04-close-remaining-wrapper-parser-differential-habitats-r1-r2-r3.md:49-51`)
  both fix as unchanged; and the `_cd_target` / `_git_subcommand`
  skeletons landed by #107/#114, which the same constraint declares
  untouched.

## What was read this session, first-hand

| Artifact | How read |
| --- | --- |
| Issue #124 body | `gh issue view 124` — background, 3 numbered requirements, 3 constraints, 2-step execution plan |
| Issue #124 comments (all 1) | `gh issue view 124 --comments` and `--json comments` — single comment, body `APPROVE issue-124/implementation`, author `jjongkwann`, `2026-08-04T06:20:10Z`, [issuecomment-5175349028](https://github.com/tokenmaxxxer/tokenmaxxxer-core/issues/124#issuecomment-5175349028) |
| PR #126 metadata | `gh pr view 126 --json number,title,author,headRefName,baseRefName,mergedAt,mergeCommit,createdAt,reviews,state,url` — `createdAt: 2026-08-04T06:11:15Z`, `reviews: []` |
| Commit `7fcd4cd` | `git show --stat 7fcd4cd` — full message + file list |
| Commit `fdb620d` | `git show fdb620d -- core/hooks/…` and `git show fdb620d -- core/hooks/tests/` — full source and test diff, plus `--stat` |
| The observed role's record `docs/issue-124/reports/implementation.md` | read in full, all 409 lines (frontmatter → `## Verify`) |
| The observed role's proposal `docs/issue-124/proposals/2026-08-04-close-remaining-wrapper-parser-differential-habitats-r1-r2-r3.md` | read in full, all 238 lines |
| `docs/issue-114/reports/execution-observation.md` `## Verdict 4` | `sed -n '225,310p'` — the enumeration table and R1/R2/R3 prose this issue formalizes |
| `core/contract/role-handoff-contract.md` §19, §20 | `awk` range extraction — the two-phase gate, the survey rigor floor, and §20 item 6 (defect class + other habitats) |
| `docs/specs/approvers.md` | `cat` — two accounts, `JiwonJung94` and `jjongkwann` |

**Not read as evidence, deliberately:** the present working-tree contents
of `core/hooks/approval-gate.sh`, `core/hooks/board-gate.sh`, and
`core/hooks/lib/gate-lib.py`. Working-tree source shows what exists now,
not what the observed session did; the diff of `fdb620d` is the admissible
record of that. (The separate class-enumeration question of `## Unknowns`
item 4 is about what exists now, not about what the role did — it is
planned against pinned blobs at `43bd873`, not the working tree, and the
proposal states that distinction.)

## Phase state of this role, established by evidence

- The `issue-124/execution-observation` branch carries **no commits of its
  own**: `git status -sb` reports `## issue-124/execution-observation...origin/main`
  with no ahead/behind divergence, and `git log --oneline -1` is `43bd873`,
  main's own head.
- **No PR exists for this branch** (`gh pr list --state all --limit 15`
  lists PRs 105–127; none has head `issue-124/execution-observation`), so
  the two-account path of contract §19 has nothing to approve.
- Issue #124's **only** comment is `APPROVE issue-124/implementation`
  ([issuecomment-5175349028](https://github.com/tokenmaxxxer/tokenmaxxxer-core/issues/124#issuecomment-5175349028)).
  Contract §19's single-account path requires the entire body to be the
  exact string `APPROVE issue-<n>/<role>` naming *this role's own* role
  name; `issue-124/implementation` is a different role's subject-role pair,
  not a near-match on this role's string. This role's phase 2 is therefore
  not open, and this session writes only the two phase-1 homes.
- Precedent for the shape of that string on a sibling subject: issue #118
  carries both `APPROVE issue-118/implementation` and a separate `APPROVE
  issue-118/execution-observation` (`gh issue view 118 --comments`) — i.e.
  each role's phase-2 approval is posted as its own comment on this board.

## Write surfaces this role owns, and their current state

| Surface | Current state (evidence) | This session |
| --- | --- | --- |
| `docs/issue-124/reports/execution-observation/survey.md` | Does not exist — `git ls-tree -r --name-only origin/main -- docs/issue-124` lists exactly 3 paths, none under `reports/execution-observation/` | Created (this file) |
| `docs/issue-124/reports/execution-observation/scout-brief.md` | Does not exist, same listing | Created |
| `docs/issue-124/proposals/` | Holds exactly one file, the observed role's `2026-08-04-close-remaining-wrapper-parser-differential-habitats-r1-r2-r3.md` (same listing) | A **new sibling file** is added; the observed role's file is not opened for edit |
| `docs/issue-124/reports/execution-observation.md` | Does not exist, same listing | **Not written this session** — phase-2 output, gated on the Approve above |

No surface under `core/`, `warrant/`, `core/hooks/tests/`, or
`docs/handbooks/` is written by this role at any phase.

## Current state of the observed delivery (facts only, no judgment)

Established from `git show fdb620d` and the record, both read this session.
Each line is a fact to be checked in phase 2, not a judgment:

1. **R1** — `core/hooks/approval-gate.sh` line 122 changes from
   `head = cmdline.strip().split()[0].rsplit("/", 1)[-1] if cmdline.strip() else ""`
   to `head = gate_lib.gate_head_of(cmdline)`. One line, `-1/+1`.
2. **R2** — `core/hooks/board-gate.sh` gains
   `GIT_GLOBAL_VALUE_FLAGS = ("-C", "-c")` and `_git_subcommand`'s loop is
   rewritten from `for w in gate_lib.gate_trailing_words(segment)` to an
   indexed `while` that advances `i += 2` on a member of that tuple.
   Docstring rewritten in the same hunk.
3. **R3** — `core/hooks/lib/gate-lib.py` gains
   `TRANSPARENT_FLAG_TAKES_ARG = {"nice": ("-n","--adjustment"), "env": ("-u","--unset"), "timeout": ("-s","--signal"), "xargs": ("-I",)}`
   and a 3-line branch at the head of `_resolve_transparent`'s inner loop.
4. **Tests** — 6 new cases across 3 harnesses: 2 in
   `run-approval-gate-tests.sh` (`bash-wrapper-timeout-grep-read` allow,
   `bash-wrapper-timeout-write` deny), 2 in `run-board-gate-tests.sh`
   (`bash-git-c-flag-log-foreign-issue` allow,
   `bash-git-c-flag-rm-foreign-issue` deny), 4 `headof` cases in
   `run-gate-lib-tests.sh` (`timeout -s KILL 30 git log`, `nice -n 10 git
   log`, `env -u FOO git log`, `xargs -I fmt git log`). Note the asymmetry:
   the harness totals are 2+2+4 = 8 added cases, while the record's
   `## Verify` prose says "the six new cases (2 per habitat)"
   (`docs/issue-124/reports/implementation.md:321`) — a count to reconcile
   in phase 2, not resolved here.
5. **Record claims** the red→green table 43→44, 90→91, 53→57 and a
   post-fix full run of 44/0, 91/0, 57/1
   (`docs/issue-124/reports/implementation.md:304-317`), with the single
   remaining failure attributed to a pre-existing sandbox condition
   already documented in `docs/issue-118/reports/implementation.md`.
6. **Record claims** a post-fix re-run of issue-114's exact enumeration
   method and "Zero remaining habitats of this class"
   (`docs/issue-124/reports/implementation.md:346-408`).
7. **Timeline**, from commit dates and the GitHub API, all read this
   session: `7fcd4cd` authored 2026-08-04 15:10:30 +0900 (= 06:10:30Z) →
   PR #126 opened 06:11:15Z → approval comment 06:20:10Z → `fdb620d`
   authored 15:45:04 +0900 (= 06:45:04Z) → merged 06:46:00Z.

## Unknowns — stated, not papered over

1. **Whether an `APPROVE issue-124/execution-observation` comment will
   ever be posted.** It does not exist now; this session cannot know
   whether it will. All phase-2 planning below is conditional on it.
2. **Whether the record's numeric test counts are true.** This role is
   prohibited from re-running the observed role's suites, so `43→44`,
   `90→91`, `53→57` cannot be verified by execution. What *can* be checked
   is internal consistency: added-case count vs. claimed delta, and
   whether a claimed pre-fix failure is mechanically implied by the pre-fix
   code visible in the diff's `-` side. The limit of that check is stated
   rather than hidden.
3. **Whether the observed proposal met §19's enumerable-clause-checklist
   requirement.** §19 requires proposal commitments "expressed as an
   enumerable clause checklist (one line per commitment), not prose alone",
   and requires phase 2 to mark per clause which commit fulfilled it. The
   observed proposal's `## What will be done`
   (`docs/issue-124/proposals/2026-08-04-close-remaining-wrapper-parser-differential-habitats-r1-r2-r3.md:119-189`)
   is a 6-bullet list of multi-sentence prose bullets; whether that
   satisfies the clause-checklist floor is a phase-2 judgment, unresolved
   here.
4. **Whether the class is genuinely exhausted.** Issue-114's own
   observation stated its coverage limit outright: the enumeration "cannot
   rule out a habitat that constructs a command-start decision by some
   idiom neither grep matched (e.g. a regex that happens to encode
   positional assumptions)"
   (`docs/issue-114/reports/execution-observation.md`, `## Verdict 4`,
   "Statement of coverage"). The observed record re-runs that same two-grep
   method and inherits the same residue. Whether an independent
   enumeration that widens beyond those two greps finds anything is
   unknown at survey time and is the central open question this
   observation exists to answer (issue #124 requirement 3, contract §20
   item 6).
5. **Whether the four `TRANSPARENT_FLAG_TAKES_ARG` entries are the right
   closure boundary.** The proposal scopes the table to four wrappers and
   declares the other four `TRANSPARENT` members
   (`time`, `command`, `builtin`, `nohup`) out of scope
   (`…-r1-r2-r3.md:193-199`). Whether "no documented value-taking flag in
   common use" holds for those four is an external-fact question the
   survey has not settled.
6. **Whether the delivered test shape matches the proposed one.** The
   proposal names `xargs -I{} git log`-equivalent (`…-r1-r2-r3.md:169`);
   the diff of `fdb620d` adds `xargs -I fmt git log`. Both are listed
   here as read; which is the correct shape for `-I`'s space-separated
   value grammar, and whether the substitution counts as drift from a
   frozen contract, is deferred to phase 2.
