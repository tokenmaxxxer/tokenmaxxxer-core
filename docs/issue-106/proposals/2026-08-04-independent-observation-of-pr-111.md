---
kind: proposal
subject: issue-106
produced_by: execution-observation
loop_state: phase-1
upstream:
  - path: docs/issue-106/reports/execution-observation/survey.md
  - path: docs/issue-106/reports/execution-observation/scout-brief.md
---

# Proposal — independent execution observation of PR #111 (issue-106 step 2)

## Subject

Issue #106, execution plan step 2. The artifact under observation is PR
**#111** (`propose(implementation): headless delegation carve-out for
role-handoff contract`, head `issue-106/implementation`, merged
`2026-08-04T02:03:50Z` as `f4b158f`), its two commits — `2e3e248`
(propose: proposal + survey + scout brief) and `ce4e81c` (deliver:
contract §22, `core/hooks/directive.sh` bullet, `freelunch/hooks/freelunch.sh`
subordination line, plus the observed role's record) — and the observed
role's own record `docs/issue-106/reports/implementation.md`. PR #111
carries no review and no comment (`gh pr view 111 --json reviews,comments`
returns both lists empty); the approval it cites is the issue-level
comment `APPROVE issue-106/implementation`.

All of the above were read this session.
`docs/issue-106/reports/execution-observation/survey.md` lists exactly
what was read and what was deliberately not read.

This document contains no verdict, provisional or otherwise. It states
which verdict levels phase 2 will check, which evidence each will rest
on, and stops there. Where evidence already gathered is quoted below, it
is quoted as an unjudged fact — the weighing belongs to phase 2.

## Which verdict levels will be checked, and against what

Phase 2 will address **all three** levels required of this role, and will
write "not applicable, because X" for any level that turns out not to
apply rather than omitting it silently.

- **Outcome** — did PR #111 land what issue #106 asked. Evidence: issue
  #106's three numbered `## 요구사항` and two `## 제약` read one by one
  against the `ce4e81c` diff of `core/contract/role-handoff-contract.md`,
  `core/hooks/directive.sh`, and `freelunch/hooks/freelunch.sh`, plus the
  observed record's own `## What was done` items 1-5
  (`docs/issue-106/reports/implementation.md:28-61`) and its explicit
  hand-off of requirement 3 to step 2 (`:192-195`).
- **Trajectory** — was the phase-1→phase-2 path sound: did it survey
  before proposing, scout, and open phase 2 on a real human approval.
  Evidence: `2e3e248`'s three phase-1 files and their diffstat
  (proposal + survey + scout-brief, +404 lines, no rule text); the
  issue-level comment body `APPROVE issue-106/implementation` read from
  `gh issue view 106 --comments` and its author/association; the ordering
  of that comment against `ce4e81c`'s author date, for which phase 2 will
  fetch comment timestamps explicitly (`gh api` on the issue's comments
  endpoint) — the survey records that ordering as not yet established.
- **Step** — which specific artifact, if any, is deficient. The four
  check points below are where phase 2 will look; each names the artifact
  it examines and the evidence that decides it.

## The four check points this invocation names, and the evidence each will rest on

**Check point 1 — the obligation the `directive.sh` mirror is justified
by.** The observed record justifies the `core/hooks/directive.sh` edit by
citing that file's own header as an obligation binding "it and the
contract" to "describe the same rules"
(`docs/issue-106/reports/implementation.md:42-48`). Evidence phase 2 will
weigh, already gathered: the header sentence at
`core/hooks/directive.sh:3-4` reads "This is the informing half of core —
board-gate.sh is the enforcing half; the two must describe the same rules
(contract v3 s10)", i.e. the pair it binds is `directive.sh`↔`board-gate.sh`;
and a whole-file search of the pre-change contract
(`git show 2e3e248:core/contract/role-handoff-contract.md`) returns zero
occurrences of `same rules`, `informing`, `directive`, `directive.sh`,
`SessionStart`, `in sync`, `consistent with`, and `inject*`, with §10
itself ("Where records live") containing no such pairing requirement,
and §11/§14 stating the opposite for their own subject matter ("This
table is the normative rule, not a description of what warrant already
enforces"; "No mechanical check in this contract enforces it"). Phase 2
will state what this does and does not establish about the mirror edit
itself, separately from what it establishes about the record's citation.

**Check point 2 — requirement 2's conflict resolution, prose layer and
mechanical layer.** Requirement 2 asks that the priority of the new rule
over the delegation-mandating directive be made explicit. Evidence phase
2 will weigh: on the prose layer, contract §22's second bullet naming
`freelunch`'s `priority="absolute"` directive and quoting its
unconditional-dispatch string, and `freelunch/hooks/freelunch.sh:39`,
which sits 9 lines and ~1,336 characters before the unconditional
`"YES → DELEGATED, always … never run_in_background: false"` at
`freelunch/hooks/freelunch.sh:48`, with nothing in lines 40-47
re-asserting unconditional dispatch. On the mechanical layer, unamended
by `ce4e81c` and unexamined by the observed record:
`freelunch/hooks/observe.sh`, registered `PreToolUse` on matcher
`"Agent|Task|Workflow"` (`freelunch/hooks/hooks.json:13-22`), whose deny
reason at `observe.sh:101-107` reads "synchronous Agent dispatch
(`run_in_background: false`) is blocked … Re-issue the SAME Agent call
with `run_in_background: true`; you will be notified on completion, which
is semantically equivalent to waiting", and whose header comment states
the same premise at `observe.sh:14-16` ("a background dispatch +
completion notification is semantically equivalent to waiting
synchronously"). The deny fires only when `FREELUNCH_ENFORCE == "1"`
(`observe.sh:34,38,83,117`); that variable is unset in this session's
environment, which is why this session's four synchronous dispatches were
logged with `"enforced": false` in `~/.claude/freelunch-observe.jsonl`
rather than denied. `observe.sh` contains zero occurrences of `headless`,
`s22`, `contract`, or `same-turn`. Phase 2 will decide what weight this
carries — including whether it belongs to this delivery's frozen write
set at all — and will apply the same test to `warrant/hooks/directive.sh:60,79`
("dispatch ONE background agent … and carry on without waiting for it" /
"Never wait on it"), which the observed record already raised itself as a
`Hunt` finding and carried forward as a follow-up
(`docs/issue-106/reports/implementation.md:111-165, 169-177`).

**Check point 3 — requirement 3, recurrence after landing.** The
population is every role session started after `2026-08-04T02:03:50Z`
(unix 1785809030). From `/Users/jk/.tokenmaxxxer/work/*.events.jsonl`
that is five sessions, one of which is this observing session itself
(excluded), leaving **four completed sessions**:
`tokenmaxxxer-core-issue-107-execution-observation`,
`on-the-record-issue-224-execution-observation`,
`on-the-record-issue-227-execution-observation`,
`on-the-record-issue-262-implementation` — all four `session-end`
`progressed`, no `failed-no-commit`. Evidence phase 2 will weigh, per
session, from its `*.session.*.log` stream-json (tool-call records, not
assistant prose): the count of `Agent`/`Task` `tool_use` blocks and their
`run_in_background` values; whether each dispatch has a matching
`tool_result` in the same log; and whether the final assistant record
follows the last `tool_result`. Already gathered: only
`issue-107-execution-observation` delegated (3 `Agent` calls, records
227/233/243, all `run_in_background: false`, all three results consumed
at records 283/286/289, followed by 10 further parent tool calls ending
in commit `2b769e6` and PR #112); the other three delegated to no
subagent at all, and each committed inside its own session window
(`ca62a84`+`9d076e0`, `14cbe9ae`, `4ca10d1c`). Phase 2 will also record
the sample's limits explicitly (see `## Method and its limits`).

**Check point 4 — does the landed text actually reach a role session.**
Design evidence that the mirror is delivered, not merely committed.
Evidence phase 2 will weigh: `core/hooks/directive.sh:103-110` sits
inside the single unquoted heredoc `cat <<EOF` (`:58`-`:113`) with no
independent env gate and no role branching after the `CLAUDE_ROLE` check
at `:15-16`, so it cannot be suppressed for one role while the rest of
the block prints; the block is skipped wholesale only when `CORE_OFF` is
truthy (`:13`) or the git/`gh` precondition probe fails (`:23-55`). The
loaded plugin copy is this repo's working tree, not the stale marketplace
copy at `/Users/jk/.claude/plugins/marketplaces/tokenmaxxxer-core/` (HEAD
`33bcb20`, which lacks the §22 text entirely); and all four post-landing
session logs carry the clause in their `hook_response` record at line 12
(`issue-262` also at line 7). Phase 2 will additionally note that
`core/hooks/tests/` contains no test asserting the *content* of either
directive — `parse-check.sh:44-52` is `bash -n` only, and
`compliance-check.sh:36-43` scopes itself to `PreToolUse` and skips
`SessionStart`/`UserPromptSubmit` — so the mirror's continued presence is
unguarded by the suite the delivery ran.

## Method and its limits

- **No re-execution.** The observed role's code is not run: this session
  will not invoke `core/hooks/tests/run-all.sh`, `directive.sh`,
  `freelunch.sh`, `observe.sh`, or any gate. Every claim rests on a diff,
  a `git show <sha>:<path>` at a pinned SHA, a GitHub artifact, or an
  already-written log/record file. Reads of hook files are textual reads
  of the merged artifact, cited as such.
- **No edits to the observed artifact.** This session's entire write
  surface is `docs/issue-106/reports/execution-observation.md`,
  `docs/issue-106/reports/execution-observation/`, and this proposal.
- **Design evidence and operating evidence are reported separately**, per
  the scout brief's adopted pattern. Check points 1, 2 and 4 are design
  questions answerable from one point-in-time artifact each; check point 3
  is an operating question and will be labelled with its actual sample
  size and window rather than blurred into the design finding.
- **Stated limit on check point 3.** The four post-landing sessions all
  started within about three minutes of the landing and all finished
  within roughly thirty minutes of it. That is a sample, not an operating
  window; phase 2 will say so in those terms and will not present n=4
  over ~30 minutes as evidence that the pattern is durably gone.
- **Behavior evidence over narration.** For check point 3, a session's own
  assistant text claiming it followed the rule is not accepted as
  evidence; only tool-call records and their ordering are. (One session,
  `on-the-record-issue-224-execution-observation`, does cite the rule in
  its own text at record 30 — that citation will be reported as an
  artifact, not treated as compliance evidence.)
- **Independence.** This role did not author, edit, or contribute to PR
  #111 or any file it touched. The phase-2 record will carry that
  statement before any verdict language, per this role's ordering rule.

## Phase-2 deliverable

One file: `docs/issue-106/reports/execution-observation.md` — the
independence statement first, then the three-level verdict (outcome,
trajectory, step), every verdict-bearing sentence carrying its citation
adjacent (commit SHA, `file:line`, or PR/issue comment URL), and any
deficiency finding in the four-part blameless shape (impact, timeline,
root cause, action item), scaled to the finding. `loop_state` updated at
each transition. Written as the first act of phase 2 and committed on
this branch.

## Out of scope

- Editing, fixing, or proposing edits to `core/`, `freelunch/`,
  `warrant/`, or the observed role's record. A confirmed deficiency
  returns as a finding in this role's own record, on this role's own PR;
  the human judges it there and files any issue themselves.
- Filing issues. Under contract v3, issues are user-authored only.
- Re-running or re-deriving issue #106's own implementation work, or
  proposing an alternative §22 wording.
- Judging `on-the-record` PR #256's respawn design, which issue #106's
  own `## 제약` puts out of scope.
- Extending the recurrence sample by waiting for or triggering further
  role sessions. This session is headless and single-shot; the sample is
  whatever exists at read time, reported with its size.
