---
kind: current-state-survey
subject: issue-122
produced_by: execution-observation
phase: 1
---

# Current-state survey — issue-122, step 2 (execution-observation)

## Scope under observation

- **Role observed:** `implementation`, on subject `issue-122`.
- **Session observed:** the implementation role's headless session recorded at
  `~/.claude/projects/-Users-jk--tokenmaxxxer-work-tokenmaxxxer-core-issue-122-implementation/e688cc52-f7ad-43cf-bce8-f58e4fc89e99.jsonl`
  (transcript timestamps `2026-08-04T06:07:07.847Z`–`06:07:53.472Z` UTC; the
  session's own commits are timestamped 14:59–15:09 KST).
- **Issue:** #122 — "directive.sh 에 계약 §13 커밋 트레일러 규칙 미러 —
  세션 트레일러-누락 마찰 제거".
- **PR:** #123 — <https://github.com/tokenmaxxxer/tokenmaxxxer-core/pull/123>,
  state `MERGED`, +558/−0, merged as `6070c70` at 2026-08-04 15:13:17 +0900.
- **Not in scope:** the `warrant/` and `scout/` plugin directives, which PR
  #123's own `## Out of scope` names and declines; and `trailer-gate.sh`,
  which issue #122's own `## 제약` fixes as unchanged.

## What was read this session, first-hand

| Artifact | How read |
| --- | --- |
| Issue #122 body + its single comment | `gh issue view 122`, `gh issue view 122 --comments` |
| PR #123 body and merge state | `gh pr view 123` |
| Commit `7fba271` (phase-1 propose) | `git show --stat 7fba271` — 3 files, +406 |
| Commit `8995fe6` (phase-2 deliver) | `git show 8995fe6` — full diff, 2 files, +152 |
| Merge commit `6070c70` | `git show --stat 6070c70` — 5 files, +558 |
| The observed role's own record `docs/issue-122/reports/implementation.md` | read in full (frontmatter through `## Verify`) |
| The observed role's phase-1 survey `docs/issue-122/reports/implementation/survey.md` | read (log-evidence lines 164-166) |
| Session transcripts under `~/.claude/projects/*tokenmaxxxer-core*` | `grep`/`stat` sweep, see `## Requirement-3 evidence` |

Not read as evidence, deliberately: the present contents of
`core/hooks/directive.sh` and `core/hooks/trailer-gate.sh`. Working-tree
source shows what exists now, not what the observed session did; the diff
of `8995fe6` is the admissible record of that.

## Write surfaces this role owns

- `docs/issue-122/reports/execution-observation/` — phase-1 only (this
  survey, the scout brief).
- `docs/issue-122/proposals/` — phase-1 proposal.
- `docs/issue-122/reports/execution-observation.md` — phase-2 record; not
  written before an Approve.

Nothing under `core/`, `src/`, `test/`, or another role's record area is
written by this role.

## Approval state (read this session)

Issue #122 carries exactly one comment, body `APPROVE issue-122/implementation`,
author `jjongkwann` (listed in `docs/specs/approvers.md` alongside
`JiwonJung94`). That string approves the *implementation* role, not this
one. No `APPROVE issue-122/execution-observation` comment exists on issue
#122 as of this session, and no PR for branch
`issue-122/execution-observation` existed before it (`gh pr list --state all`
shows #123 as the newest). This session is therefore phase 1.

## Requirement-3 evidence: availability, instrument, and its limits

Issue #122's requirement 3 asks step 2 to judge friction reduction by
**trailer-gate firing frequency in sessions opened after the landing**.
What the survey established about that measurement:

**The corpus exists.** Role-session transcripts live under
`~/.claude/projects/<slugged-worktree>/*.jsonl`, one directory per
issue×role worktree; 166 such directories match `tokenmaxxxer`.

**The firing signature is identifiable.** A real denial arrives as a
`"type":"user"` record whose `tool_result` content is
`PreToolUse:Bash hook error: [${CLAUDE_PLUGIN_ROOT}/hooks/trailer-gate.sh]: <role>: refused — trailer-gate: …`,
with `"is_error":true` and a `toolDenialKind` field. Three distinct
denial branches appear in the corpus: message lacks the required
`Subject: issue-<n>` trailer; commit carries no inline `-m` message; and
commit stages work for multiple issues.

**Pre-landing baseline, measured.** Restricting to
`*tokenmaxxxer-core*` project directories, 31 transcript files contain a
substituted (non-`%s`) firing signature; one of those 31 is this
observer session itself and is contamination, not a firing (its 10
signature lines are the output of the greps above). The remaining 30
files span 2026-07-29 13:35 through 2026-08-04 15:09 KST and carry 35
signature-bearing records, 27 of them in the tool-result shape above.
Eleven of the 30 are dated 2026-08-04 alone — the same order of
magnitude as the issue's own "오늘 하루 로그만으로 10회 이상" claim,
which the observed role's survey (`docs/issue-122/reports/implementation/survey.md:164-166`)
recorded as not independently re-derived for lack of log access.

**The observed session is itself in the baseline.** The implementation
session that authored PR #123 carries two firing records of its own,
both in the tool-result shape, at `2026-08-04T06:07:07.847Z` (missing
`Subject: issue-122` trailer) and `06:07:53.472Z` (no inline `-m`
message) — both before its deliver commit `8995fe6` (15:09:28 KST) and
before the merge that made the new bullet live (`6070c70`, 15:13:17 KST).
Whether that pair is one retry chain or two independent denials, and what
it means for requirement 3, is a phase-2 question this survey does not
answer.

**The post-landing window is the binding constraint.** The mirror bullet
reaches a session only through `directive.sh`'s `SessionStart` output,
so it applies only to sessions started after `6070c70` landed at
2026-08-04 15:13:17 KST. This survey ran at 15:15–15:22 KST the same
day. The post-landing population is therefore n=1: this session, whose
own injected `[core]` protocol does carry the new bullet verbatim
("A commit that stages any docs/issue-<n>/** work must use git commit -m
and carry a Subject: issue-<n> trailer …"). A frequency comparison over
n=1 is not a frequency comparison.

## Unknowns carried into the proposal

1. **Sample-size gap.** How a three-level verdict should report requirement
   3 when the post-landing window is minutes wide — what is measurable now
   versus what must be deferred, and how to say so without either
   overclaiming a reduction or silently dropping the requirement.
2. **Event-level precision.** Line-level greps approximate denial events;
   separating retry chains from independent denials, and excluding
   observer-session contamination systematically, needs a per-record parse
   pass rather than `grep -c`.
3. **Confound.** Sessions differ in role, issue, and length; a raw
   per-session denial rate does not by itself isolate the bullet's effect
   from ordinary variation across those axes.
4. **Mechanism versus outcome.** Whether the bullet is *delivered* to a
   live session (verifiable at n=1, now) is a different claim from whether
   it *reduces* denials (needs the population). Which of these the step-2
   verdict is entitled to make is the proposal's central decision.
