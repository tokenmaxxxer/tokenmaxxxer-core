---
kind: current-state-survey
subject: issue-99
produced_by: execution-observation
loop_state: surveyed
---

# Survey: issue-99 step 2 — current state of the artifact under observation

## Scope (who/what/which session/which PR)

Under observation: the **`implementation` role's session on branch
`issue-99/implementation`**, delivered as **PR #102**
(https://github.com/tokenmaxxxer/tokenmaxxxer-core/pull/102), state
`MERGED` at `2026-08-03T08:19:00Z`, author `jjongkwann`, merged into
`main` as merge commit `27fd5fe`. That session is issue #99's execution
plan **step 1**; this survey opens **step 2** (`execution-observation`),
whose own branch is `issue-99/execution-observation`.

The session under observation ran in two phases on one branch:

| commit | date (author) | what it is |
| --- | --- | --- |
| `e163815` | 2026-08-03 15:40:15 +0900 | phase-1 commit — survey + scout brief + proposal, 3 files, +461 lines, no code |
| `aa3f206` | 2026-08-03 17:01:10 +0900 | merge of `origin/main` into the branch, taken before phase-2 work |
| `232e2aa` | 2026-08-03 17:11:47 +0900 | phase-2 delivery — `core/hooks/board-gate.sh` (+160/-49 region), `core/hooks/tests/run-board-gate-tests.sh` (+24), `docs/handbooks/board-gate-tests.md` (+54), `docs/issue-99/reports/implementation.md` (+218); 4 files, 407 insertions, 49 deletions |

(commit list and dates: `git log --format='%h %ad %s' --date=iso
27fd5fe^1..27fd5fe^2`; diffstat: `git show --stat --format='' 232e2aa`.)

## What was read this session, to arrive at that scope

- Issue #99 in full, including its `## 요구사항` 1–5 and its `## 실행 계획`
  (`gh issue view 99`), and its single comment — body exactly
  `APPROVE issue-99/implementation`, author `jjongkwann`
  (`gh issue view 99 --comments`).
- PR #102 metadata (`gh pr view 102 --json …`): number, state, head ref,
  merge time, author, URL.
- PR #102 reviews and comments (`gh pr view 102 --comments --json
  reviews,comments`): **both lists are empty** — no PR review of any
  state, no PR comment.
- The three commits above, by SHA: `git show --stat` and the full commit
  messages of `232e2aa` and `e163815`.
- The observed role's own record: `docs/issue-99/reports/implementation.md`
  (218 lines, all of it).
- The observed role's phase-1 artifacts:
  `docs/issue-99/proposals/2026-08-03-fix-board-gate-dead-fallback-and-cd-write-verb-gap.md`
  (185 lines, all), `docs/issue-99/reports/implementation/scout-brief.md`
  (51 lines, all), `docs/issue-99/reports/implementation/survey.md`
  (225 lines; sections 1–2 read verbatim, remainder by heading).
- Branch/PR inventory of the repo: `git log --oneline -15`,
  `gh pr list --state all --limit 25`.

Not read as evidence, deliberately: any file under `core/hooks/` in its
**current** state. `src/`-equivalent working-tree files show what exists
now, not what the observed session did; the admissible substitutes are
the commit diffs, which is what the commit-level reads above cover.

## Current state of the board (what is merged to `main`)

1. **Step 1 has landed.** `27fd5fe` merged PR #102 into `main`; issue
   #99's `## 실행 계획` checkbox for step 1 is nonetheless still unticked
   in the issue body as read this session (`gh issue view 99`).
2. **The observed session's own account of the landing** is
   `docs/issue-99/reports/implementation.md`, `loop_state: landed`
   (`:6`), naming `core/hooks/board-gate.sh`,
   `core/hooks/tests/run-board-gate-tests.sh`,
   `docs/handbooks/board-gate-tests.md` as `code_under_review` (`:5`)
   and the phase-1 proposal at `sha: e1638153…` as upstream (`:7-9`).
3. **Approval path used.** The record states phase 2 opened via the
   issue-level comment `APPROVE issue-99/implementation`
   (`docs/issue-99/reports/implementation.md:16-18`, citing
   `…/issues/99#issuecomment-5163202866`); PR #102 itself carries no
   review, matching contract v3 s19's single-account path rather than
   the two-account Approve path.
4. **Two neighbouring sessions bracket this one on `main`**: issue-98's
   implementation (`e51bc09`, merged as `9cd8a20`, PR #103) touching the
   same gate file's wrapper-head classification, and issue-98's
   execution-observation (`99d94aa`, merged as `428ebe7`, PR #104) whose
   record carries the Finding 1 this step-2 invocation names.

## Unknowns this survey cannot settle, and what would settle each

- **U1 — did the landing code avoid the unreachable-branch trap?** Issue
  #99 requirement 4 forbids any branch whose reachability is not
  empirically proven; the record claims the one new "no token, no
  `cd_tail`" branch is exercised live by `bash-unresolved-head-then-read`
  (`docs/issue-99/reports/implementation.md:144-147`). Settled by reading
  the `232e2aa` diff hunks themselves against the test cases the same
  diff adds — not by re-running the suite.
- **U2 — the record's own regression arithmetic disagrees with its
  commit message.** `232e2aa`'s message says "5 new regression cases
  confirmed failing (want=deny got=allow) against the pre-fix code";
  the record's `closed_checks` says "exactly 4 FAILs … (80 passed, 4
  failed)" with `bash-cd-relative-write-own-issue` passing pre-fix
  (`docs/issue-99/reports/implementation.md:152-162`). Settled by reading
  both texts side by side and the test hunk in the diff; both are already
  in hand, the discrepancy's significance is not yet assessed.
- **U3 — proposal-to-delivery count drift.** The proposal's "How you'll
  know it worked" predicts "71+6 passed" (`…-cd-write-verb-gap.md:185`)
  and lists six `run` lines (`:145-150`) of which one is explicitly "no
  change"; the record reports 79 pre-existing + 5 new = 84
  (`docs/issue-99/reports/implementation.md:163-167`) after the
  `aa3f206` merge of `main`. Settled by reconciling the baselines the
  two documents used.
- **U4 — post-merge interaction.** Whether any session running after
  `27fd5fe` landed actually met the changed gate, and whether the
  silent-allow failure mode recurred. Settled only by recorded live gate
  events in other roles' merged records — not by invoking the gate.
- **U5 — combination with issue-98's Finding 1.** Whether the
  `TRANSPARENT` wrapper behaviour change that issue-98's observation
  reported as unannounced interacts with the `cd_tail` walk `232e2aa`
  introduces. Settled by the two commit diffs (`e51bc09`, `232e2aa`) and
  `docs/issue-98/reports/execution-observation.md`, plus the fact that
  `aa3f206` merged `main` **before** `232e2aa` was written.
- **U6 — residual scope named but not re-verified.** The record's `##
  Open findings` (`:177-189`) says the same-issue cross-role R5 gap is
  "confirmed still present by construction … not re-verified live this
  session". Whether "by construction" is an adequate standard here is a
  judgement for phase 2, on the diff.

## Evidence sources available for phase 2, ranked

1. The `232e2aa` and `e51bc09` diffs (primary; the only admissible view
   of what the observed session actually changed).
2. The observed session's record, proposal, survey, scout brief (its own
   account, checkable against 1).
3. `docs/issue-98/reports/execution-observation.md` Finding 1 (merged
   via `428ebe7`; the neighbouring observation this step must combine
   with).
4. Other roles' merged records dated after `27fd5fe`, for U4.
