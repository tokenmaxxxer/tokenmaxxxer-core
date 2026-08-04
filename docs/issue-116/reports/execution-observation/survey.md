---
kind: current-state-survey
subject: issue-116
produced_by: execution-observation
loop_state: surveyed
---

# Survey: issue-116 step 2 — current state of the artifact under observation

## Scope (who / what / which session / which PR)

Under observation: the **`implementation` role's session on branch
`issue-116/implementation`**, delivered as **PR #117**
(https://github.com/tokenmaxxxer/tokenmaxxxer-core/pull/117), title
`propose(implementation): repair 3 approval-rule follow-up gaps`, author
`jjongkwann`, base `main`, state `MERGED` at `2026-08-04T05:40:14Z`,
landed on `main` as merge commit `c94cb33`. That session is issue #116's
execution plan **step 1**; this survey opens **step 2**
(`execution-observation`), whose own branch is
`issue-116/execution-observation`.

The observed session carries exactly two commits:

- `97f8ce63183574dd1a6e411e953bc88576850a53` — phase 1, authored
  `2026-08-04T04:54:03Z`, +566 lines across three files
  (`docs/issue-116/proposals/2026-08-04-approval-rule-gap-repairs.md`,
  `docs/issue-116/reports/implementation/survey.md`,
  `docs/issue-116/reports/implementation/scout-brief.md`), no rule text.
- `f991220b1f6b56717f17bff84f00e972e9130ebf` — phase 2, authored
  `2026-08-04T05:34:31Z`, 8 files changed, 489 insertions / 10 deletions
  (`core/contract/role-handoff-contract.md` +12/-?,
  `core/hooks/directive.sh`, `core/hooks/tests/run-all.sh`,
  `docs/handbooks/freelunch-observe-tests.md` (new, 31 lines),
  `docs/issue-116/reports/implementation.md` (new, 306 lines),
  `freelunch/hooks/observe.sh`,
  `freelunch/hooks/tests/run-observe-tests.sh` (new, 88 lines),
  `warrant/hooks/directive.sh`).

This observing session is itself headless/single-shot (`claude -p`-class,
no later turn available) — the same session class the observed delivery's
carve-out is written for. Noted as a fact about this observer, not as a
licence to test the carve-out by running it: re-executing the observed
role's code is prohibited for this role, so the carve-out's behavior is
judged from the landed diff, its test file's own assertions, and the
observed record — never from a re-run.

## What was read this session (the whole evidence base)

- `gh issue view 116` — the issue's `## 배경` (3 numbered gaps),
  `## 요구사항` (3 numbered requirements), `## 제약` (2 constraints), and
  the `## 실행 계획` checklist naming step 1 `implementation` / step 2
  `execution-observation`.
- `gh pr view 117 --json ...` — number, title, state, author, base/head,
  `mergedAt`, `mergeCommit`, both commit objects with SHAs and full
  messages, and the PR body.
- `gh pr view 117 --json reviews,reviewDecision` → `reviewCount: 0`,
  `reviewDecision: ""` (empty). PR #117 carries **no** PR review of any
  kind; it carries one PR comment by `jjongkwann` (`MEMBER`) summarizing
  the phase-2 delivery.
- `gh api repos/tokenmaxxxer/tokenmaxxxer-core/issues/116/comments` — a
  single issue comment, body exactly `APPROVE issue-116/implementation`,
  by `jjongkwann` (`MEMBER`), `created_at 2026-08-04T05:03:44Z`
  (https://github.com/tokenmaxxxer/tokenmaxxxer-core/issues/116#issuecomment-5174824813).
- `git show f991220` — the full phase-2 diff of all five code/contract
  files (`freelunch/hooks/observe.sh`,
  `freelunch/hooks/tests/run-observe-tests.sh`,
  `core/hooks/tests/run-all.sh`, `warrant/hooks/directive.sh`,
  `core/hooks/directive.sh`, `core/contract/role-handoff-contract.md`),
  read hunk by hunk.
- `docs/issue-116/reports/implementation.md` (lines 1-307) — the observed
  role's own record, read in full: `## Why`, `## What was done` (9
  items), `## What did not work` (3 entries), `## Doc-placement ladder`,
  `## Rationale for deviations` (3 entries), `## Hunt` (one FINDING),
  `## Next steps`, `## Resolution path`, `## Verify`.
- `docs/issue-116/proposals/2026-08-04-approval-rule-gap-repairs.md`
  (lines 1-241) — the approved proposal, read in full including its
  `files:` write set (line 1), `## What will be done` items 1-6,
  `## Out of scope`, `## How you'll know it worked`, and its phase-1
  `## Warrant hunt` pre-mortem finding + disposition (`:210-241`).
- `git show 97f8ce6:core/hooks/tests/run-all.sh` — the **pre-image** of
  the edited runner, to establish pre-existing context rather than
  attribute it to the observed role: line 3 is `set -uo pipefail`.
- `git show --stat` on both observed commits; `git log --oneline
  origin/main..HEAD` (empty — this observer's branch is at `c94cb33`,
  identical to `origin/main`, with no commits of its own yet);
  `gh pr list --head issue-116/execution-observation` (empty — no PR yet
  for this role).
- `docs/specs/approvers.md` → two accounts: `JiwonJung94`, `jjongkwann`.
- Format precedent only (not evidence about issue-116):
  `docs/issue-106/proposals/2026-08-04-independent-observation-of-pr-111.md`
  head, and `docs/issue-106/reports/execution-observation/survey.md` head.

## Deliberately not read, and why

- `docs/issue-116/reports/implementation/survey.md` and
  `scout-brief.md` beyond their existence and diffstat in `97f8ce6`.
  Phase 2 will read them where trajectory turns on their content
  (survey-before-proposal, scout-brief presence); they are named here as
  known-unread rather than silently omitted.
- `on-the-record`'s `run.md` / `protocol.md`. Different repository, out
  of this issue's scope by the issue's own `## 제약`; the observed
  delivery's cross-reference claim against it is checked from this
  repo's landed text alone, or recorded as uncheckable-from-here.
- The observed role's edited files **as they now exist on `main`** were
  not taken as evidence of what that role did. The current-state read of
  `freelunch/hooks/observe.sh` that was performed served only to confirm
  the merge landed the diff unchanged; every verdict-bearing citation in
  phase 2 will name `f991220`'s diff, the record, or the proposal.

## The observed role's own claims, recorded unjudged

Stated here as *what the artifact asserts*, not as findings:

1. `freelunch/hooks/observe.sh` now reads `CLAUDE_CODE_ENTRYPOINT`;
   `session_is_interactive = (entrypoint == "cli")`; `sync_agent_dispatch`
   is stripped from the enforceable set when the session is not clearly
   interactive; `non_sonnet_worker` untouched (`f991220`, `observe.sh`
   hunks at `@@ -45,11 +49,27 @@` and `@@ -80,7 +100,15 @@`).
2. That `CLAUDE_CODE_ENTRYPOINT` "is set by the harness before the
   session's own conversation begins, so it is not a signal a running
   session could spoof to dodge `sync_agent_dispatch` at will" (inline
   comment landed by `f991220`; same claim in
   `docs/issue-116/reports/implementation.md:31-34`, "a value the harness
   sets before the session's own conversation begins, so it is not
   conversation-writable").
3. That the headless value is empirically `sdk-cli` and the interactive
   one `cli` (same inline comment; record `:34-35`).
4. That tty state was evaluated and rejected as non-discriminating for
   this hook because the hook's own stdout is harness-captured in every
   invocation mode (inline comment; record `:47-53`).
5. Nine test cases in `freelunch/hooks/tests/run-observe-tests.sh`
   (record `:54-62`), against the proposal's three required cases
   (proposal `:131-138`). Enumerated from the landed file in `f991220`:
   `headless-sync-dispatch-not-enforced` (sdk-cli, bg=false, sonnet →
   allow), `interactive-sync-dispatch-still-denied` (cli → deny),
   `ambiguous-entrypoint-sync-dispatch-not-enforced` ("" → allow),
   `headless-violation-still-logged` (row assertion),
   `interactive-violation-enforced-true` (row assertion),
   `non-sonnet-worker-denied-headless`, `non-sonnet-worker-denied-interactive`,
   `sonnet-worker-allowed-headless`, `freelunch-worker-agent-type-allowed`.
   Every `run` invocation in that file sets `FREELUNCH_ENFORCE=1` and
   `tool_name: "Agent"`.
6. That the full suite is green — `bash core/hooks/tests/run-all.sh` →
   `ALL OK`, "new `freelunch observe.sh enforcement` entry 9/0" (record
   `:288-292`).
7. Three deviations beyond the proposal's literal cited scope, each with
   a stated justification (record `:159-201`): the top-of-file header
   comment fix, the new `row["session_entrypoint"]` log field, and the
   new file `docs/handbooks/freelunch-observe-tests.md` outside the
   proposal's `files:` list.
8. One before-landing hunt FINDING — `freelunch/README.md:79-89`/`:86`
   still describes enforcement as unconditional — carried to
   `## Next steps` rather than fixed (record `:218-284`).

## Write surfaces this role owns, and their unknowns

Phase 1 (this session): `docs/issue-116/reports/execution-observation/survey.md`
(this file), `.../scout-brief.md`,
`docs/issue-116/proposals/2026-08-04-independent-observation-of-pr-117.md`.
Phase 2 only, after an `APPROVE issue-116/execution-observation` issue
comment or a qualifying PR review Approve:
`docs/issue-116/reports/execution-observation.md`.

Open unknowns — these are the gaps the scout sweep aims at, and the
questions phase 2 must settle:

- **U1 — what would actually settle claim 2 (conversation-non-manipulability).**
  The proposal's own warrant-hunt disposition (`:232-240`) made this a
  binding build-time constraint: "whichever exact signal phase 2 lands on
  must be harness-set, not conversation-writable, or this finding
  re-opens." The landed artifact asserts the property; neither the record
  nor the proposal names a channel-by-channel check behind it. Unknown:
  the enumerable set of in-session channels that can change what a
  `PreToolUse` subprocess inherits (settings-file `env` blocks, plugin
  config, per-session settings overrides, shell-state persistence), and
  whether any is reachable from the conversation. Evidence that will
  settle it must come from repo-side configuration surfaces and
  documented harness precedence — never from re-running `observe.sh`.
- **U2 — whether the nine cases are effective, not merely nine.**
  Unknown: whether each case discriminates (would fail if the carve-out
  were wrong), and whether the nine cover the risk surface the change
  introduces. Uncovered-on-their-face dimensions, to be checked in phase
  2 against the landed file: the `FREELUNCH_ENFORCE` unset (observe-only)
  path, the `Workflow` tool branch, ambiguous entrypoint values other
  than `""` (e.g. `sdk-py`, `remote`, `vscode`), the deny reason text's
  own content, and whether the `run-all.sh` wiring propagates a failure.
  Context already established unjudged: the runner's pre-image carries
  `set -uo pipefail` (`97f8ce6:core/hooks/tests/run-all.sh:3`), which is
  what the new `| tail -2` entry's exit-status propagation turns on.
- **U3 — outcome coverage.** Issue #116's three `## 요구사항` and two
  `## 제약`, each read against the `f991220` diff. Unknown until read
  side by side.
- **U4 — trajectory ordering.** Gathered but unweighed: phase-1 commit
  `04:54:03Z` → approval comment `05:03:44Z` → phase-2 commit
  `05:34:31Z` → merge `05:40:14Z`; zero PR reviews, single-account
  approval path.
- **U5 — the three deviations.** Whether each stays inside the scope
  discipline this repo's contract imposes, or whether any is a write-set
  widening that needed a stop-and-report instead.
- **U6 — the hunt finding's disposition.** Whether carrying the
  `freelunch/README.md` staleness to `## Next steps` (rather than fixing
  it, or raising it as a blocking finding) matches this repo's own rules.

## No verdict here

This document contains no verdict, provisional or otherwise. Every claim
above is either a fact about what exists and what was read, or an
explicitly-labelled restatement of what the observed artifact asserts.
Weighing belongs to phase 2 and only opens on a real human Approve.
