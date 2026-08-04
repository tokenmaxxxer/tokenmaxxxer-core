---
kind: proposal
subject: issue-122
produced_by: execution-observation
phase: 1
observed_pr: 123
observed_role: implementation
---

# Proposal — step 2 independent observation of PR #123 (issue-122)

## What this proposal covers

Issue #122's execution plan lists two steps. Step 1 (`implementation`)
landed as PR #123, merged `6070c70`. Step 2 is this role's independent
observation of that execution. This document states, before any judgment
is formed, which verdict levels the phase-2 record will check and what
evidence each will be checked against. It renders no judgment itself.

Inputs already read first-hand this session are listed in
`docs/issue-122/reports/execution-observation/survey.md` (`## What was read
this session, first-hand`). Direction inputs are in
`docs/issue-122/reports/execution-observation/scout-brief.md`.

## Verdict levels to be checked, and against what

All three levels of the contract's execution judgment will be addressed;
none is skipped, and a level that does not apply will say so and why.

### 1. Outcome — did PR #123 land what issue #122 asked

Checked against the issue's three numbered requirements, one at a time,
each against a named artifact:

- **Requirement 1** (a §13 mirror bullet in `directive.sh`'s printed
  protocol): the diff of commit `8995fe6`, plus this session's own
  injected `[core]` `SessionStart` protocol text as the delivered-form
  evidence that the bullet reaches a live session. Not the working-tree
  file.
- **Requirement 2** (the anti-bloat criterion recorded in one line): the
  same diff's header-comment hunk, and whether the recorded criterion is
  the one the issue asked for ("mirror only what a gate is observed
  repeatedly catching").
- **Requirement 3** (friction judged by post-landing gate-firing
  frequency): the session-transcript corpus, per `## Requirement-3
  measurement plan` below.
- **Both `## 제약` constraints** (`trailer-gate.sh` untouched; no
  auto-attach): the file list of `8995fe6` and `6070c70`.

### 2. Trajectory — was the phase-1 → phase-2 path sound

Checked against the process artifacts, not the code:

- Whether a survey and scout brief preceded the proposal — commit
  `7fba271`'s file list and dates versus `8995fe6`'s.
- Whether the approval was real and correctly typed — issue #122's single
  comment, its exact body, its author, and `docs/specs/approvers.md`;
  including whether single-account mode was correctly identified.
- Whether phase-2 output stayed inside the approved proposal's scope —
  the proposal's `## What will be done` versus what `8995fe6` actually
  changed, and whether declined scope was disclosed rather than dropped.

### 3. Step — which specific artifact, if any, is deficient

Checked per artifact: the `directive.sh` hunk as delivered in `8995fe6`,
the record `docs/issue-122/reports/implementation.md`, and the
verification claims in that record's `## Verify` section. Where the record
asserts a check (e.g. a `grep` result, a test-suite line), the assertion is
compared against the diff and against the corpus — never by re-running the
observed role's task.

## Requirement-3 measurement plan

The scout brief's must-be is that delivery and effect are two claims, and
that an under-powered effect claim states its n.

- **Metric:** count of real trailer-gate denial records per role session,
  where a real denial is a `"type":"user"` transcript record whose
  `tool_result` carries
  `PreToolUse:Bash hook error: [...trailer-gate.sh]: <role>: refused —`
  with `"is_error":true`. Textual mentions and observer-session grep output
  are excluded; the exclusion of this session's own contamination is stated
  explicitly rather than silently applied.
- **Population:** `~/.claude/projects/*tokenmaxxxer-core*/**/*.jsonl`.
- **Pre-landing segment:** sessions up to `6070c70` (2026-08-04 15:13:17
  KST). Already enumerated in the survey: 30 files, 2026-07-29 → 15:09 KST.
- **Post-landing segment:** sessions started after that timestamp.
- **Decision rule, fixed now, before the count is taken:** with fewer than
  3 post-landing sessions the record will report requirement 3 as *not yet
  measurable*, give the exact n and window, and state the pre-landing
  baseline it would be compared against — rather than reading a reduction
  out of a single session or omitting the requirement. At n ≥ 3 the record
  compares per-session denial rates across the two segments and names the
  confounds (role mix, session length) the comparison does not control.
- **What is separately checkable at n=1:** whether the bullet is actually
  delivered into a post-landing session's protocol text. That is a
  delivery claim, and the record will label it as such, not as evidence of
  reduced friction.

## What will be written

One file, `docs/issue-122/reports/execution-observation.md`, written as the
first act of phase 2, with `loop_state` updated at each transition. Its
independence statement (this role did not author or edit PR #123's
artifacts) precedes any verdict language in the document. Every
verdict-bearing sentence carries its citation — commit SHA, `file:line`, or
PR/issue comment URL — adjacent to the verdict.

Any deficiency finding will carry the four-part blameless shape (impact,
timeline, root cause, action item), scaled to the single finding. Findings
stay in this record on this role's own PR; no issue is filed, and nothing
under `core/`, `src/`, `test/`, or the implementation role's record area is
edited.

## Out of scope

- The `warrant/` and `scout/` plugin directives. PR #123 disclosed them as
  declined scope; whether to extend the mirror there is a separate
  decision this observation does not make.
- `trailer-gate.sh`'s own behaviour, fixed as unchanged by issue #122.
- Any re-execution of step 1's task, in whole or in part.
