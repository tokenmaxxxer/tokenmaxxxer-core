---
kind: proposal
subject: issue-116
produced_by: execution-observation
loop_state: phase-1
upstream:
  - path: docs/issue-116/reports/execution-observation/survey.md
  - path: docs/issue-116/reports/execution-observation/scout-brief.md
---

# Proposal — independent execution observation of PR #117 (issue-116 step 2)

## Subject

Issue #116, execution plan step 2. The artifact under observation is PR
**#117** (`propose(implementation): repair 3 approval-rule follow-up
gaps`, head `issue-116/implementation`, base `main`, author
`jjongkwann`, merged `2026-08-04T05:40:14Z` as `c94cb33`), its two
commits — `97f8ce6` (phase 1: proposal + survey + scout brief, +566
lines, three files) and `f991220` (phase 2: the five code/contract files,
one new handbook, and the observed role's own record; 8 files, +489/-10)
— and the observed role's record
`docs/issue-116/reports/implementation.md`. PR #117 carries **zero** PR
reviews (`gh pr view 117 --json reviews,reviewDecision` →
`reviewCount: 0`, `reviewDecision: ""`) and one PR comment by
`jjongkwann`; the approval it cites is the issue-level comment
`APPROVE issue-116/implementation`
(https://github.com/tokenmaxxxer/tokenmaxxxer-core/issues/116#issuecomment-5174824813,
`created_at 2026-08-04T05:03:44Z`).

All of the above were read this session, first-hand, not summarized
secondhand. `docs/issue-116/reports/execution-observation/survey.md`
lists exactly what was read and what was deliberately left unread.

**This document contains no verdict, provisional or otherwise.** It
states which verdict levels phase 2 will check, which evidence each will
rest on, and stops there. Where evidence already gathered appears below,
it appears as an unjudged fact; the weighing belongs to phase 2 and opens
only on a real human Approve.

## Which verdict levels will be checked, and against what

Phase 2 will address **all three** levels this role owes, and will write
"not applicable, because X" for any level that turns out not to apply
rather than omitting it silently.

- **Outcome** — did PR #117 land what issue #116 asked. Evidence: the
  issue's three numbered `## 요구사항` and two `## 제약`, read one by one
  against `f991220`'s diff hunks in `freelunch/hooks/observe.sh`,
  `warrant/hooks/directive.sh`, `core/contract/role-handoff-contract.md`
  and `core/hooks/directive.sh`, plus the observed record's own
  `## What was done` items 1-9
  (`docs/issue-116/reports/implementation.md:30-94`) and its `## Verify`
  block (`:286-306`).
- **Trajectory** — was the phase-1→phase-2 path sound: survey before
  proposing, scout run, phase 2 opened on a real human approval in the
  right order. Evidence: `97f8ce6`'s three phase-1 files and its
  docs-only diffstat; the issue comment's exact body, author, and
  `author_association`; and the four timestamps already gathered
  (phase-1 commit `04:54:03Z` → approval `05:03:44Z` → phase-2 commit
  `05:34:31Z` → merge `05:40:14Z`), read against contract v3 §19's
  single-account approval path and `docs/specs/approvers.md`'s two
  listed accounts.
- **Step** — which specific artifact, if any, is deficient. The six
  check points below are where phase 2 will look; each names the
  artifact it examines and the evidence that decides it. Any deficiency
  that survives the evidence is written in the four-part blameless shape
  (impact, timeline, root cause, action item), scaled to a single
  finding.

## The six check points, and the evidence each will rest on

**Check point 1 — the signal's claimed conversation-non-manipulability.**
Artifact: the inline comment `f991220` lands in
`freelunch/hooks/observe.sh` ("`CLAUDE_CODE_ENTRYPOINT` is set by the
harness before the session's own conversation begins, so it is not a
signal a running session could spoof to dodge `sync_agent_dispatch` at
will"), the same claim in the record (`:31-34`, "not
conversation-writable"), and the phase-1 proposal's disposition of its
own warrant-hunt pre-mortem
(`docs/issue-116/proposals/2026-08-04-approval-rule-gap-repairs.md:232-240`).
That disposition sets the bar phase 2 will measure against, in the
observed role's own words: "whichever exact signal phase 2 lands on must
be harness-set, not conversation-writable, or this finding re-opens."
Evidence phase 2 will weigh: (a) the field must-be that an
env-var-as-trust-signal design requires a who-can-set analysis across the
full process ancestry, not a presence assumption (scout-brief.md, must-be
1); (b) the documented behavior of the `env` key in Claude Code's
settings files — "environment variables applied to every session and to
subprocesses Claude Code spawns from it", with settings files
hot-reloaded mid-session (https://code.claude.com/docs/en/settings) —
against the absence of `CLAUDE_CODE_ENTRYPOINT` from the official
env-vars page (https://code.claude.com/docs/en/env-vars); (c) whether
this repository's own committed configuration surfaces and the declared
sandbox write/deny lists make that channel reachable from a role
session, read from committed files and session-declared policy, never by
attempting a write; (d) whether the record or the proposal documents any
ancestry/channel enumeration behind the claim, or asserts it directly.
Phase 2 states plainly which of those four the evidence supports; it does
not test the claim by running the hook.

**Check point 2 — whether the nine test cases are effective, not merely
nine.** Artifact: `freelunch/hooks/tests/run-observe-tests.sh` as landed
in `f991220` (88 lines), against the proposal's three required cases
(`:131-138`) and the record's claim of nine (`:54-62`) and of "9/0"
(`:288-292`). Evidence: (a) an equivalence-class partition of the landed
predicate `session_is_interactive = (entrypoint == "cli")` — `cli` /
known-non-`cli` (`sdk-cli`) / unknown-non-empty (`sdk-py`, `remote`,
`vscode`, per the observed value set) / unset — mapped against which
partitions the nine cases actually instantiate; (b) a
would-it-fail-if-wrong reading of each case against the landed
enforcement lines (the `enforceable.remove("sync_agent_dispatch")`
branch), applied as a **reading** standard, never as an executed
mutation pass; (c) a tautology check on the two row assertions
(`headless-violation-still-logged`, `interactive-violation-enforced-true`),
which read a log file the same invocation wrote; (d) the dimensions no
case instantiates on its face — `FREELUNCH_ENFORCE` unset (the
observe-only default path), the `Workflow` tool branch, and the deny
reason text's own content, all of which `f991220` also changed; (e)
whether the `run-all.sh` wiring propagates a failure, given the added
entry is piped (`| tail -2 || rc=1`) and the runner's **pre-image**
already carries `set -uo pipefail`
(`97f8ce6:core/hooks/tests/run-all.sh:3`) — the pre-image is cited
precisely so pre-existing behavior is not attributed to the observed
role.

**Check point 3 — outcome coverage against the issue's own text.**
Artifact: `f991220`'s diff hunks. Evidence: requirement 1's floor ("최소한
헤드리스 맥락에서 동기 위임을 거부하지 않을 것") and its boundary clause
("강제 훅의 원 목적이 약해지지 않는 경계") against the landed
`enforceable` logic and the untouched `non_sonnet_worker` path;
requirement 2's "동형의 §22 종속 노트" and its exhaustive
`scout`/`terse` audit demand against the landed
`warrant/hooks/directive.sh` paragraph and the record's `grep`-based
audit result (`:294-302`); requirement 3's "승인 취급 금지 + 기록/안내"
against the landed section-19 and `core/hooks/directive.sh` text; and the
two `## 제약` (section 22's body unchanged; otr files untouched) against
the diff's file list.

**Check point 4 — trajectory ordering and approval validity.** Artifact:
the two commits, the issue comment, and `docs/specs/approvers.md`.
Evidence: the phase-1 commit containing only proposal + survey +
scout-brief and no rule text; the approval comment's body tested for
exact string equality against `APPROVE issue-116/implementation`, its
author's membership in `approvers.md`, and the single-account condition
(PR author and approver are the same account, `jjongkwann`) that makes
the issue-comment path the applicable one; and the timestamp ordering
already gathered in survey.md. Phase 2 also records whether this
observing session encountered any approval-shaped near-miss comment of
its own — the very duty `f991220` adds to §19 — and, per that new duty,
states it plainly once if so.

**Check point 5 — the three declared deviations.** Artifact: the
record's `## Rationale for deviations` (`:159-201`). Evidence: the
proposal's frozen `files:` line (`:1`) and its `## Out of scope` (`:168-189`)
against each deviation — the header-comment fix, the added
`row["session_entrypoint"]` field, and the new file
`docs/handbooks/freelunch-observe-tests.md` outside the frozen write set
— together with the gate the record names as forcing the third
(`core/hooks/handbook-trigger-gate.sh`'s `OP_PATTERNS` match on
`run-all.sh`) and the proposal's own pre-authorization of the literal
predicate as "ordinary implementation detail" (`:179-185`).

**Check point 6 — the hunt finding's disposition.** Artifact: the
record's `## Hunt` FINDING on `freelunch/README.md:79-89`/`:86`
(`:218-261`), its `## Next steps` (`:263-275`), and its
`## Resolution path` (`:277-284`). Evidence: whether carrying a
self-found documentation contradiction forward as a follow-up — rather
than fixing it inside the frozen write set or raising it as a blocking
finding — matches this repo's own scope discipline as the proposal and
contract state it, and whether the `## Next steps` entry that hands
recurrence-detection of the new §19 duty to step 2 (`:271-275`) is a
task this observation can actually discharge from artifacts alone.

## Method, and what phase 2 will not do

- Artifacts only: `f991220` / `97f8ce6` diffs, the record, the proposal,
  the issue, the PR metadata and comments. The observed role's task is
  never re-executed and its hook is never run — including as a
  "quick check" of the carve-out, and including via any test harness it
  authored.
- The observed role's `src/`, `test/`, and record paths are never
  edited. Findings return only through this role's own record on this
  role's own PR; no issue is filed.
- Every verdict-bearing sentence in the record names its source
  (commit SHA, `file:line`, or comment URL) directly adjacent to the
  verdict.
- The record's independence statement precedes any verdict language in
  the document, not merely appears somewhere in it.

## Out of scope

- `on-the-record`'s repository files — a different repo, out of scope by
  issue #116's own `## 제약`. Where the observed delivery's
  cross-reference claim depends on otr text, phase 2 records it as
  uncheckable from this branch rather than guessing.
- `freelunch/README.md`'s staleness itself. Phase 2 judges the observed
  role's **disposition** of that finding (check point 6); it does not fix
  the README, which is another role's write surface.
- Any re-review of `role-handoff-contract.md` §22's body or otr's
  two-comment recipe — both are unchanged by PR #117 by constraint.

## How you'll know it worked

- `docs/issue-116/reports/execution-observation.md` exists on this
  branch, **committed**, carrying all three verdict levels explicitly
  (outcome, trajectory, step), with "not applicable, because X" written
  out for any level that does not apply.
- Its independence statement appears above the first verdict-bearing
  sentence in the file.
- Every verdict-bearing sentence has a citation adjacent to it; a reader
  can check each one against a SHA, a `file:line`, or a URL.
- Check points 1 and 2 — the two the invoking prompt named specifically
  — are each resolved to a stated position with its evidence, not left
  open.
- Any deficiency finding carries impact, timeline, root cause, and action
  item.
