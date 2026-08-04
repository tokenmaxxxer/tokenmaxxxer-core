---
kind: observation-record
subject: issue-106
produced_by: execution-observation
observed_role: implementation
observed_pr: 111
observed_commits: 2e3e248, ce4e81c
observed_merge_commit: f4b158f
loop_state: landed
upstream:
  - path: docs/issue-106/proposals/2026-08-04-independent-observation-of-pr-111.md
    sha: 5236a418536a822fbd70b2da8e6d739568fbfb3b
  - path: docs/issue-106/reports/execution-observation/survey.md
    sha: 9c61454ad2d6f318f6ad31420999cad4493794f0
  - path: docs/issue-106/reports/execution-observation/scout-brief.md
    sha: 5a6707da2e1c153f159f12da6489205ec862b66e
---

# Observation record — issue-106 step 2: independent judgment of PR #111

## Independence

This role did not author, edit, or contribute to PR #111, to either of its
commits (`2e3e248`, `ce4e81c`), or to any file either commit touched. It
did not edit the observed role's record
(`docs/issue-106/reports/implementation.md`), and it has not edited
`core/`, `freelunch/`, or `warrant/` at any point in this session or the
phase-1 session on this branch. This session's entire write surface is
`docs/issue-106/reports/execution-observation.md` (this file),
`docs/issue-106/reports/execution-observation/`, and
`docs/issue-106/proposals/2026-08-04-independent-observation-of-pr-111.md`.

The observed role's task was not re-executed. `core/hooks/tests/run-all.sh`
was not run this session; no hook (`directive.sh`, `freelunch.sh`,
`observe.sh`, any gate) was invoked to probe behavior. Every claim below
rests on a diff, a `git show <sha>:<path>` read at a pinned SHA, a GitHub
API artifact, or a log file written by some other session before this one
started. Where a hook file is cited, it is cited as a textual read of the
merged artifact at `f4b158f`, not as a re-run.

No verdict language appears above this point.

## Why

Issue #106 execution plan step 2. Phase 2 opened on the contract v3 §19
single-account path: issue-level comment whose entire body is the exact
string `APPROVE issue-106/execution-observation`, posted by `jjongkwann`
(`type: User`, listed in `docs/specs/approvers.md:2`) at
`2026-08-04T02:46:51Z`
(https://github.com/tokenmaxxxer/tokenmaxxxer-core/issues/106#issuecomment-5174018077).
This session started at `2026-08-04T02:47:03Z`
(`/Users/jk/.tokenmaxxxer/work/tokenmaxxxer-core-issue-106-execution-observation.events.jsonl`,
`session-start`), i.e. after the approval.

The approved evidence plan is
`docs/issue-106/proposals/2026-08-04-independent-observation-of-pr-111.md`
(committed `e380dad`, PR #113). It named the three verdict levels to be
checked and four check points; all four were executed and are reported
below.

## What was done

Executed the approved evidence plan's four check points against PR #111's
artifacts, then rendered the three-level verdict below. Concretely: read
the issue and its comment timeline, PR #111's metadata and both commits,
the observed role's own record in full, the merged rule text and its
neighbouring hook surfaces at the pinned merge SHA, and the operating
logs of every role session started after the merge; from those, answered
check points 1-4 and wrote this record as the sole phase-2 artifact. No
observed-role file was edited and no observed-role code was run.

Read this session, first-hand:

1. `gh issue view 106` and
   `gh api repos/tokenmaxxxer/tokenmaxxxer-core/issues/106/comments` — the
   issue body (3 `## 요구사항`, 2 `## 제약`, 2-step plan) and all three
   comments with their timestamps and authors.
2. `gh pr view 111 --json ...` — `state: MERGED`, `createdAt`
   `2026-08-04T01:28:42Z`, `mergedAt` `2026-08-04T02:03:50Z`, author
   `jjongkwann`, `reviews: []`, `comments: []`, both commit OIDs.
3. `git show ce4e81c -- core/contract/role-handoff-contract.md
   core/hooks/directive.sh freelunch/hooks/freelunch.sh` — the full
   rule-text diff, and `git show --stat` for `2e3e248`, `ce4e81c`,
   `f4b158f`.
4. `docs/issue-106/reports/implementation.md` — the observed role's own
   record, all 219 lines.
5. Pinned-SHA reads of the merged artifact:
   `f4b158f:core/contract/role-handoff-contract.md`,
   `f4b158f:core/hooks/directive.sh`, `f4b158f:freelunch/hooks/freelunch.sh`,
   `f4b158f:freelunch/hooks/observe.sh`, `f4b158f:freelunch/hooks/hooks.json`,
   `f4b158f:warrant/hooks/directive.sh`,
   `f4b158f:core/hooks/tests/parse-check.sh`,
   `f4b158f:core/hooks/tests/compliance-check.sh`; and pre-change reads
   `2e3e248:core/hooks/directive.sh`,
   `2e3e248:core/contract/role-handoff-contract.md`.
6. Operating artifacts written by other sessions:
   `/Users/jk/.tokenmaxxxer/work/*.events.jsonl` (all 44 files,
   `session-start` / `session-end` records), the nine
   `*.session.<ts>.log` stream-json logs whose filename timestamp is at or
   after `20260804T110350` (KST of the merge), and
   `~/.claude/freelunch-observe.jsonl` (134 rows).

## Verdict — outcome

**Landed, on all requirements PR #111 was responsible for.** Requirement
3 was not delivered by PR #111 and was not supposed to be; it is
answered by this record.

**Requirement 1 (계약 조항 추가) — landed.** `ce4e81c` appends `## 22.
Headless execution: delegation requires same-turn consumption` to
`core/contract/role-handoff-contract.md`; in the merged tree the section
spans `f4b158f:core/contract/role-handoff-contract.md:910-953`. Its text
carries every element requirement 1 asks for: the scope ("headless/
single-shot — `claude -p` and equivalent non-interactive invocations",
`:912-913`), the prohibition ("must not end its turn having delegated
work … whose result it has not yet consumed within that same turn",
`:915-917`), and the fallback ("the role must not delegate that unit of
work at all; it does the work itself, in the foreground, inside the
turn", `:929-931`).

**Requirement 2 (위임 권장 지시문과의 충돌 해소 + 우선순위 명시) —
landed on the prose layer, both surfaces.** (a) Contract §22's second
bullet is titled "**Priority over delegation-mandating directives.**"
and names the conflicting directive explicitly, quoting its own
unconditional string (`f4b158f:core/contract/role-handoff-contract.md:932-941`:
"naming `freelunch`'s `priority=\"absolute\"` directive specifically,
since its own text … instructs unconditional background dispatch …
(\"YES → DELEGATED, always ... never `run_in_background: false`\")").
(b) `f4b158f:freelunch/hooks/freelunch.sh:39` carries the reciprocal
pointer inside the directive's own heredoc, nine lines above the
unchanged unconditional instruction at
`f4b158f:freelunch/hooks/freelunch.sh:48`. Requirement 2's own fallback
clause ("지시문 파일이 implementation-rulebook 레포 소유라면 … 지시문
반영이 별도 이슈로 필요함을 기록에 남긴다") is discharged at
`docs/issue-106/reports/implementation.md:178-191`, which states that
repo is unreachable from this working tree and recommends a separate
issue there. **Not landed on the mechanical layer** — see Finding 1;
that gap is why this level reads "landed on the prose layer" rather than
"landed" flat.

**Requirement 3 (재발 확인) — correctly deferred, and now answered
here.** `docs/issue-106/reports/implementation.md:192-195` states
recurrence detection "is step 2's own job (execution-observation), not
this delivery's". That matches issue #106's own text, which assigns
requirement 3 to "step 2 관찰". Deferring it is therefore compliance,
not omission. This session's answer, with its sample stated: across every
role session started after the merge at `2026-08-04T02:03:50Z`, the
"delegate then end the turn waiting" pattern did **not** recur — see
`## Check point 3` for the sample and its limits.

**Both `## 제약` respected.** `on-the-record` PR #256's respawn design is
untouched: `ce4e81c`'s diffstat is four files, all in this repo
(`core/contract/role-handoff-contract.md`, `core/hooks/directive.sh`,
`freelunch/hooks/freelunch.sh`, `docs/issue-106/reports/implementation.md`),
273 insertions, 0 deletions, and §22's closing bullet preserves that
mechanism in words
(`f4b158f:core/contract/role-handoff-contract.md:948-953`: "It does not
alter or replace `on-the-record`'s own after-the-fact safety net …
that mechanism recovers the outcome after the fact; this section is the
prevention half"). Delegation itself is not prohibited:
`f4b158f:core/contract/role-handoff-contract.md:946-948` ("does not
prohibit delegation or subagent use outright — only the pattern of
delegating and then ending the turn still waiting on the result").

## Verdict — trajectory

**Sound.** The phase-1 → approval → phase-2 ordering is established by
timestamp, not inferred; the phase-1 commit contains no rule text; the
approval is a real human act by an `approvers.md` account.

| when (UTC) | what | source |
| --- | --- | --- |
| `2026-08-04T01:28:18Z` | phase-1 commit `2e3e248` — 3 files, +404 lines, all under `docs/issue-106/{proposals,reports/implementation}/`, zero lines of rule text | `git show --stat 2e3e248` |
| `2026-08-04T01:28:42Z` | PR #111 opened, 24s later | `gh pr view 111 --json createdAt` |
| `2026-08-04T01:34:24Z` | approval — issue comment body exactly `APPROVE issue-106/implementation`, author `jjongkwann` (`type: User`) | https://github.com/tokenmaxxxer/tokenmaxxxer-core/issues/106#issuecomment-5173574621 |
| `2026-08-04T01:47:15Z` | phase-2 delivery `ce4e81c` — first appearance of any rule text | `git show --stat ce4e81c` |
| `2026-08-04T02:03:50Z` | merged as `f4b158f` | `gh pr view 111 --json mergedAt` |

The phase-1 survey left the approval-versus-delivery ordering explicitly
unestablished (`docs/issue-106/reports/execution-observation/survey.md:129-134`);
the `gh api` comment timestamps close it. The approval precedes the
delivery commit by 12m51s, and the delivery commit is the first commit on
the branch containing any of the three rule surfaces — so no rule text
was written before the gate opened.

The gate used is contract v3 §19's single-account path, correctly:
`jjongkwann` is both PR author and approver, `jjongkwann` is listed at
`docs/specs/approvers.md:2`, the comment body is the exact string with no
surrounding prose, and `gh pr view 111 --json reviews` returns `[]`,
consistent with the comment path rather than a PR-review Approve having
been the gate.

Scouting and survey ran before proposing: `2e3e248` contains
`docs/issue-106/reports/implementation/survey.md` (197 lines) and
`docs/issue-106/reports/implementation/scout-brief.md` (59 lines)
alongside the proposal, in the same commit — so the survey and brief were
not backfilled after the proposal landed.

The observed session also self-reported its own limits rather than
papering over them: `docs/issue-106/reports/implementation.md:85-88`
states `warrant-hunter` was unavailable as a subagent type and that the
hunt stances were adopted by direct inspection instead. That is a
disclosed substitution, not a silent skip.

## Verdict — step

Two artifacts carry a deficiency, plus one accuracy note. The delivered
rule text itself (`core/contract/role-handoff-contract.md` §22,
`core/hooks/directive.sh:103-110`, `freelunch/hooks/freelunch.sh:39`) is
**not** deficient — see `## What is not deficient`.

- **Finding 1 — `freelunch/hooks/observe.sh` (confirmed, not disclosed by
  the observed record).** The mechanical half of the same plugin the
  delivery amended still enforces the exact premise §22 was written to
  refute. Blocking? No — enforcement is off in practice. Substantive?
  Yes: it is the one surface that could actively push a headless session
  back into the incident pattern.
- **Finding 2 — `warrant/hooks/directive.sh` (confirmed, and already
  self-disclosed).** Independently confirmed at the merged SHA. Because
  the observed record raised and carried it forward itself
  (`docs/issue-106/reports/implementation.md:111-165, 169-177`), it is
  recorded here as *confirmed as stated*, not as a missed defect.
- **Finding 3 — `docs/issue-106/reports/implementation.md:42-48`
  (confirmed, minor).** The mirror edit is justified by citing an
  obligation that the cited text does not contain.

## Check point 1 — the obligation the `directive.sh` mirror is justified by

`docs/issue-106/reports/implementation.md:42-48` justifies the
`core/hooks/directive.sh` edit as "consistent with the file's own stated
obligation (line 2-4) that it and the contract 'must describe the same
rules.'"

The cited header, read at the pre-change SHA
(`2e3e248:core/hooks/directive.sh:2-4`), reads: "This is the informing
half of core — board-gate.sh is the enforcing half; the two must describe
the same rules (contract v3 s10)." The pair it binds is
`directive.sh` ↔ `board-gate.sh`, not `directive.sh` ↔ the contract.

A whole-file search of the pre-change contract
(`2e3e248:core/contract/role-handoff-contract.md`) for `same rules`,
`informing`, `enforcing half`, `directive.sh`, `SessionStart`, and
`in sync` returns zero matches; the only `mirror`-family hits are `:403`
and `:845`/`:863`, all about record-path grain and `<component>`
derivation, neither imposing a contract↔directive mirroring duty.

**What this establishes:** the *record's citation* is inaccurate — no
contract↔`directive.sh` "same rules" obligation exists in the text cited.
**What it does not establish:** that the mirror edit was wrong. Check
point 4 shows the mirror is in fact the surface through which the rule
actually reaches a role session, so the edit is load-bearing on its
merits regardless of the citation that was offered for it. This is
recorded as Finding 3, a record-accuracy defect, not a code defect.

## Check point 2 — requirement 2's conflict resolution, prose layer and mechanical layer

**Prose layer — sufficient.** `f4b158f:freelunch/hooks/freelunch.sh:39`
places the carve-out inside the same `cat <<'EOF'` heredoc as the
directive itself, nine lines and roughly 1,300 characters *above* the
unconditional "- YES → DELEGATED, always. … never run_in_background:
false" at `f4b158f:freelunch/hooks/freelunch.sh:48`. Lines 40-47 contain
nothing that re-asserts unconditional dispatch. A session reading the
directive top to bottom therefore meets the carve-out before the
instruction it qualifies. This session is itself an instance: the
subordination line arrived in this session's own injected directive text.

**Mechanical layer — the gap.** `freelunch/hooks/observe.sh` is
registered `PreToolUse` on matcher `"Agent|Task|Workflow"`
(`f4b158f:freelunch/hooks/hooks.json:13-23`, matcher at `:15`). Under
`FREELUNCH_ENFORCE=1` (`f4b158f:freelunch/hooks/observe.sh:83`,
`row["enforced"] = bool(enforce and row["violations"])`), a call flagged
`sync_agent_dispatch` — defined at
`f4b158f:freelunch/hooks/observe.sh:7` as "Agent/Task called with
run_in_background: false" — is emitted as
`"permissionDecision": "deny"` (`f4b158f:freelunch/hooks/observe.sh:117-125`)
with the reason at `f4b158f:freelunch/hooks/observe.sh:101-107`:
"synchronous Agent dispatch (run_in_background: false) is blocked …
Re-issue the SAME Agent call with run_in_background: true; you will be
notified on completion, **which is semantically equivalent to waiting**."
The same premise is asserted in the file header at
`f4b158f:freelunch/hooks/observe.sh:13-15`. `observe.sh` at `f4b158f`
contains zero occurrences of `headless`, `s22`, or `contract`.

That premise is precisely what contract §22 exists to deny: in a
headless/single-shot session there is no later turn for the completion
notification to land in, which is the causal chain §22 spells out at
`f4b158f:core/contract/role-handoff-contract.md:917-924`.

**Operating evidence.** `~/.claude/freelunch-observe.jsonl` holds 134
rows; every one records `"enforced": false`, so no deny has ever fired.
Nine rows post-date the merge (KST `2026-08-04T11:09:57`→`11:21:55`),
every one flagged `sync_agent_dispatch`: three from session
`3f447bdc-e0b0-43b6-81ff-d181a49589a7` and six from
`3aea9f17-1a82-42b3-aa2e-4bf32f68c856`. Those are exactly the
§22-compliant dispatches identified in check point 3 — every one of them
would have been denied had enforcement been on.

Sibling surface, same shape: `f4b158f:warrant/hooks/directive.sh:60`
("dispatch ONE background agent … `run_in_background: true` — and carry
on without waiting for it") and `:79` ("Never wait on it"), with zero
occurrences of `s22` or `contract v3` in that file. Confirmed exactly as
the observed record described it at
`docs/issue-106/reports/implementation.md:126-137`.

## Check point 3 — requirement 3, did the pattern recur after landing

**No recurrence in the observed sample.**

*Outcome vocabulary, whole history.* Across all 44
`/Users/jk/.tokenmaxxxer/work/*.events.jsonl` files, `session-end`
carries five distinct outcomes: `progressed` (75), `errored` (5),
`failed-no-commit` (3), `refused` (3), `progressed-dirty-tree` (2). All
three `failed-no-commit` events precede the merge:
`on-the-record-issue-189-implementation` at `2026-08-02T06:23:27Z`,
`repo-status-board-issue-29-implementation` at `2026-08-03T06:32:48Z`
(the incident issue #106 names in its `## 배경`), and
`repo-status-board-issue-34-execution-observation` at
`2026-08-03T12:26:16Z`. Zero occur after `2026-08-04T02:03:50Z`.

*Behavior, not narration.* Nine role sessions started at or after the
merge. Excluding this session and this branch's own phase-1 session,
five completed (`session-end: progressed`) and two were still running at
read time. Per-session, from `tool_use`/`tool_result` records in the
stream-json logs:

| session (log) | Agent/Task dispatches | same-turn consumption |
| --- | --- | --- |
| `tokenmaxxxer-core-issue-107-execution-observation.session.20260804T110434` | 3, all `run_in_background: false` (recs 227/233/243) | all 3 consumed at recs 283/286/289, followed by 62 further records ending in a `result success` naming PR #112 |
| `on-the-record-issue-224-execution-observation.session.20260804T110437` | 0 | n/a |
| `on-the-record-issue-227-execution-observation.session.20260804T110447` | 0 | n/a |
| `on-the-record-issue-262-implementation.session.20260804T110658` | 0 | n/a |
| `tokenmaxxxer-core-issue-107-execution-observation.session.20260804T114121` | 0 | n/a |
| `on-the-record-issue-227-execution-observation.session.20260804T114126` | 0 | still running at read time |
| `on-the-record-issue-266-implementation.session.20260804T114137` | 0 | still running at read time |

The one session that delegated used synchronous dispatch and consumed
every result inside the turn, then continued to further tool calls and a
commit — the shape §22 prescribes, and the opposite of the incident
shape. No post-merge session ended with an unconsumed dispatch.

*This branch's own phase-1 session, reported separately because it is not
independent evidence.*
`tokenmaxxxer-core-issue-106-execution-observation.session.20260804T111133`
dispatched six `Agent` calls (recs 145/157/187/226/658/682), all
`run_in_background: false`, all consumed (recs 621/633/630/504/1004/1146),
with 83 further records after the last `tool_result` ending in commit
`e380dad` and PR #113.

**Stated limits.** n = 5 completed sessions plus 2 in flight, over a
window of about 43 minutes from the merge to read time. Five of the seven
delegated to nothing at all, so they cannot demonstrate compliant
delegation — only the absence of the failure. This is a sample, not an
operating window; it does not establish that the pattern is durably gone.
One session (`on-the-record-issue-224-execution-observation`) cites the
rule in its own prose; per this observation's method that citation is
reported as an artifact and was not counted as compliance evidence.

## Check point 4 — does the landed text actually reach a role session

**Yes, and this is the delivery's load-bearing surface.**

Structurally: the mirror at `f4b158f:core/hooks/directive.sh:103-110`
sits inside the single unquoted `cat <<EOF` heredoc opened at `:58` and
closed at `:113`, with no independent env gate and no role branching
after the `CLAUDE_ROLE` check at `:15`. It therefore cannot be suppressed
for one role while the rest of the block prints; the block is skipped
only wholesale, via `CORE_OFF` at `:13`.

Empirically: every one of the nine post-merge session logs carries the
clause text "Headless/single-shot (no later turn for an async completion
notification to land in)" in its record 12 — the `SessionStart`
`hook_response` — including all five completed sessions, both in-flight
sessions, and both of this branch's own sessions. The rule is being
delivered to live role sessions, not merely committed.

This is also why the contract file alone would not have sufficed: no hook
prints `role-handoff-contract.md`. The `directive.sh` mirror is what puts
§22 in front of a session. That justifies the edit on its merits — see
Finding 3, which concerns only the reason the record gave for it.

**Unguarded, though.** `f4b158f:core/hooks/tests/parse-check.sh:44-52`
runs `"$BASH32" -n "$f"` — syntax only, no content assertion. And
`f4b158f:core/hooks/tests/compliance-check.sh:32-40` extracts command
strings "inside the PreToolUse block only", explicitly falling out of
scope on `"SessionStart"` and `"UserPromptSubmit"` (`:39-40`). So no test
in the suite the delivery ran (`docs/issue-106/reports/implementation.md:208-213`)
would fail if the §22 bullet were deleted from `directive.sh` or the
subordination line from `freelunch.sh` tomorrow. Stated as a property of
the delivered state, not as a defect of this delivery: no requirement in
issue #106 asked for a content test, and the proposal did not promise one.

## Open findings

### Finding 1 — `freelunch/hooks/observe.sh` enforces the premise §22 refutes

**Impact.** With `FREELUNCH_ENFORCE=1`, a headless role session obeying
contract §22 cannot dispatch a subagent at all: §22 requires same-turn
consumption, the only same-turn mechanism is
`run_in_background: false`, and `f4b158f:freelunch/hooks/observe.sh:117-125`
denies exactly that, instructing the session to re-issue with
`run_in_background: true` on the stated ground that a completion
notification "is semantically equivalent to waiting"
(`f4b158f:freelunch/hooks/observe.sh:104-106`) — the proposition
`f4b158f:core/contract/role-handoff-contract.md:917-924` was written to
deny. A session that complies with the deny is placed back in the
incident posture; a session that complies with §22 is blocked. Currently
latent only: all 134 rows in `~/.claude/freelunch-observe.jsonl` record
`"enforced": false`, so no session has yet hit the deny. Nine post-merge
rows were flagged `sync_agent_dispatch` and would all have been denied
under enforcement.

**Timeline.** `observe.sh` predates this delivery and was not in PR
#111's write set (`git show --stat ce4e81c` — four files, `observe.sh`
not among them). `ce4e81c` at `2026-08-04T01:47:15Z` amended the prose
half of `freelunch` (`freelunch.sh:39`) and left the enforcing half
unexamined. Both halves are in the same plugin directory, and
`hooks.json` registers both (`f4b158f:freelunch/hooks/hooks.json`).

**Root cause.** Requirement 2 is phrased about "지시문" — directive text
— and the proposal's frozen write set was drawn on that reading, so the
delivery's conflict search stopped at prose surfaces. Neither the
proposal nor the record
(`docs/issue-106/reports/implementation.md:111-165`, whose `before-landing`
hunt swept sibling *directive* files: `warrant/hooks/directive.sh`,
`scout/hooks/directive.sh`, `terse/hooks/terse.sh`) examined the
`PreToolUse` gate that mechanically enforces the same rule the directive
states. The stance the hunt adopted — "assume this change and another
plugin's rule cancel each other" — was the right stance; its search
surface was directive text only, and the cancelling rule lives in a hook
that enforces rather than instructs.

**Action item (for the human to judge and file, per contract v3 — this
role does not file issues).** Consider a follow-up on this repo adding a
headless carve-out to `freelunch/hooks/observe.sh`'s
`sync_agent_dispatch` check — either suppressing the deny when the
session is headless, or amending the deny reason at `:101-107` so it no
longer asserts a premise contract §22 rejects. Practically this is the
same class of follow-up as the record's own `warrant/hooks/directive.sh`
item and could reasonably ride the same issue.

### Finding 2 — `warrant/hooks/directive.sh` carries the unqualified shape (confirmed as self-reported)

**Impact.** A session reading `warrant/hooks/directive.sh`'s injected
text alone sees "dispatch ONE background agent … and carry on without
waiting for it" (`f4b158f:warrant/hooks/directive.sh:60`) and "Never wait
on it" (`:79`), with zero occurrences of `s22` or `contract v3` anywhere
in the file, so it has no local pointer to the carve-out that
`freelunch.sh:39` now provides for its own text. Narrower than Finding 1:
warrant dispatches are hunter probes whose findings are advisory, and
§22's generic wording (`f4b158f:core/contract/role-handoff-contract.md:932-934`,
"any directive that recommends or mandates delegation") textually covers
this file without naming it.

**Timeline.** Found by the observed session itself before landing and
recorded with reproduction steps at
`docs/issue-106/reports/implementation.md:111-165`, then carried forward
as a follow-up at `:169-177` rather than folded into the delivery.

**Root cause.** `warrant/hooks/directive.sh` was outside the approved
proposal's frozen write set; the role declined to widen the write set
mid-build (`docs/issue-106/reports/implementation.md:162-165`,
`:197-204`).

**Action item.** None owed by PR #111. Recorded here only as independent
confirmation that the self-reported finding is real at the merged SHA —
the disclosure and the decision to defer were both correct.

### Finding 3 — the record's justification for the `directive.sh` mirror cites an obligation that text does not contain

**Impact.** Low, and confined to the record. Anyone auditing why
`core/hooks/directive.sh` — a file no requirement in issue #106 names —
was edited is pointed at
`docs/issue-106/reports/implementation.md:42-48` and from there at
`directive.sh:2-4`, which binds `directive.sh` to `board-gate.sh`, not to
the contract. The pre-change contract contains no contract↔directive
mirroring obligation at all (whole-file search of
`2e3e248:core/contract/role-handoff-contract.md`). The edit itself is
well-founded on other grounds, established in check point 4.

**Timeline.** Written into the record as part of `ce4e81c`
(`2026-08-04T01:47:15Z`).

**Root cause.** The header sentence at `directive.sh:3-4` reads naturally
as a general "informing half must match the rules" duty when quoted in
isolation; its actual referent, `board-gate.sh`, is in the same sentence
but drops out of the quotation.

**Action item.** No code change. Noted for accuracy; a future record
citing the same header should quote the `board-gate.sh` pairing, or cite
check point 4's runtime-delivery argument instead, which is the reason
that actually holds.

## Minor note — line-span citation precision

`docs/issue-106/reports/implementation.md:30` cites the new section as
`core/contract/role-handoff-contract.md:893-931`. At `ce4e81c` the
section header is indeed at line 893, but the section runs to the file's
last line, 936 — the cited end is five lines short. After the merge the
span shifted again, to `:910-953` at `f4b158f`, because `f6d6983`
(issue-107) had already advanced the file. Not a finding: line spans in
a branch-local record are inherently pre-merge, and this one was
substantially right. Recorded so that anyone following the citation from
`main` finds the section.

## What is not deficient

- **The §22 text itself.** Every element requirement 1 asks for is
  present and scoped (`f4b158f:core/contract/role-handoff-contract.md:910-953`),
  including the two things easiest to omit: the fallback for when
  same-turn consumption is impossible (`:930-932`) and the explicit
  non-goal preserving `on-the-record` PR #256 (`:947-953`).
- **Deferring requirement 3.** Issue #106's own execution plan assigns it
  to step 2; `docs/issue-106/reports/implementation.md:192-195` says so
  and hands it over cleanly.
- **Not editing `warrant/hooks/directive.sh`.** Holding the frozen write
  set and reporting the finding is the behavior this contract asks for,
  not a shortfall.
- **The `core/hooks/directive.sh` mirror as an edit.** Beyond the letter
  of the requirements, but it is the only surface that actually delivers
  §22 to a running session (check point 4), verified in nine independent
  session logs.
- **Prose-only, mechanically unenforced.** The record's `after-proposal`
  hunt establishes there is no `headless` signal anywhere in the repo's
  hooks (`docs/issue-106/reports/implementation.md:96-109`), and the
  proposal declared the rule self-assessed by design. A stated, deliberate
  property is not a hidden gap.

## Method and its limits

- **No re-execution.** No hook or test was run; every artifact claim is a
  pinned-SHA read, a diff, a GitHub API result, or a pre-existing log.
- **No edits to the observed artifact.** Nothing under `core/`,
  `freelunch/`, `warrant/`, or `docs/issue-106/reports/implementation*`
  was touched by this session.
- **Design evidence and operating evidence reported separately.** Check
  points 1, 2 and 4 answer design questions from point-in-time artifacts;
  check point 3 is an operating question and carries its own sample size
  and window rather than being blurred into the design result.
- **Behavior over narration.** For check point 3, only `tool_use` /
  `tool_result` records and their ordering were counted; a session's own
  prose claim of compliance was not.
- **This session is inside its own subject population.** It is headless
  and single-shot, i.e. exactly the class §22 governs. It is reported in
  check point 3 as first-hand but non-independent evidence, kept out of
  the n.

## Next steps

- Finding 1 (`freelunch/hooks/observe.sh`) is the one item warranting a
  new issue. It belongs to the human to file, per contract v3.
- Findings 2 and 3 need no new action beyond what the observed record
  already carries.

## Resolution path

No `finding:` block is raised against another role's record. All three
findings return through this role's own record on this role's own PR, for
the human to judge and to file as they see fit. Nothing in the observed
role's tree was edited to accommodate them.

## What did not work

The phase-1 survey left the approval-versus-delivery ordering open
(`docs/issue-106/reports/execution-observation/survey.md:129-134`) because
`gh issue view --comments` does not print timestamps; `gh api` on the
issue's comments endpoint returned them directly and closed it. Also,
the recurrence sample grew between phase 1 and phase 2 — the proposal
counted four post-landing sessions
(`docs/issue-106/proposals/2026-08-04-independent-observation-of-pr-111.md:117-125`),
this record finds five completed and two in flight. The finding is
unchanged; the n is stated as read at phase-2 time.
