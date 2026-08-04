---
kind: coding-record
subject: issue-106
produced_by: implementation
code_under_review: `core/contract/role-handoff-contract.md`, `core/hooks/directive.sh`, `freelunch/hooks/freelunch.sh`
loop_state: landed
upstream:
  - path: docs/issue-106/proposals/2026-08-03-build-headless-delegation-clause.md
    sha: 2e3e248c3a71ccf56da67cf7efd37d26c3868bdb
---

# Implementation record — issue-106

## Why

Phase 2, approved via issue-level comment `APPROVE issue-106/implementation`
(exact string, posted by an approvers.md account, jjongkwann, on issue #106).
Delivering the approved proposal's four `## What will be done` items: a new
contract section closing the gap identified by `repo-status-board` issue #29
phase 2 / `on-the-record` issue #247 — a headless role session must not end
a turn having delegated work it has not consumed within that same turn —
mirrored in `core/hooks/directive.sh`'s printed protocol text and noted
inside `freelunch/hooks/freelunch.sh`'s own `priority="absolute"` text, plus
this record's own note on the `implementation-rulebook` follow-up (proposal
item 4, requirement 2's fallback). All four items landed as approved, inside
the proposal's frozen write set.

## What was done

1. `core/contract/role-handoff-contract.md:893-931` — new `## 22. Headless
   execution: delegation requires same-turn consumption`, appended after
   the existing section 21 (no concurrent section-22 race; confirmed the
   document ended at section 21 before this edit). States the rule (wait
   for a delegated result and act on it, through commit where applicable,
   before the turn ends — or do not delegate that unit at all), its
   explicit priority over any delegation-mandating directive (naming
   `freelunch`'s `priority="absolute"` directive by name and quoting its
   own unconditional-dispatch text), its scope (headless/single-shot
   sessions only — interactive sessions are unaffected), and what it does
   not do (does not prohibit delegation outright; does not alter or
   replace `on-the-record`'s auto-respawn safety net, PR #256).
2. `core/hooks/directive.sh:103-110` — mirrored the rule as a new bullet
   in the printed `[core] Interaction protocol for role '${role}'` text,
   between the output-layout bullet and the "board is what is MERGED"
   bullet, cross-referencing `contract v3 s22` and naming `freelunch`'s
   `priority="absolute"` directive by name — consistent with the file's
   own stated obligation (line 2-4) that it and the contract "must
   describe the same rules."
3. `freelunch/hooks/freelunch.sh:39` — added a `SUBORDINATE TO CONTRACT
   v3 s22 IN HEADLESS/SINGLE-SHOT SESSIONS` paragraph directly inside the
   `<freelunch-directive priority="absolute">` heredoc, immediately after
   the directive's own opening scope-claim line and before `STEP 1`, so a
   session reading freelunch's text top-to-bottom sees the carve-out
   before it reaches the unconditional `"YES → DELEGATED, always"`
   instruction (line ~48, unchanged) rather than after it.
4. Ran `bash core/hooks/tests/run-all.sh` (below, `## Verify`) — full
   suite green, including `directive.sh` and `freelunch.sh` parse-checks,
   confirming the heredoc edits did not break shell syntax or any
   existing gate/canon-form test.
5. This record — including the `implementation-rulebook` follow-up note
   (proposal item 4) — see `## Next steps`.

## What did not work

None. All three write-set edits landed as drafted on the first attempt;
`run-all.sh` was green on the first run with no fix-up needed.

## Doc-placement ladder

- [x] No `docs/decisions/` entry. The proposal document itself
  (`docs/issue-106/proposals/2026-08-03-build-headless-delegation-clause.md`,
  `## Rationale`) already carries the required alternative-and-reason
  record for the one hard-to-reverse choice this issue makes (anchoring
  the rule in the contract vs. patching `freelunch.sh` alone) — this
  delivery is that already-decided choice's execution, not a second,
  separate decision needing its own `docs/issue-106/decisions/` file.
- [x] No `docs/handbooks/<component>.md` entry. No environment variable,
  config key, dependency, migration, or run/setup/deploy step was
  introduced or changed — contract §21's handbook trigger does not fire.
- [x] `docs/issue-106/reports/implementation.md` (this file) — the
  phase-2 record, per contract §11/§19.

## Hunt

`warrant-hunter` is not among this session's available `Agent`-tool
subagent types (same absence noted in issue-88/90/93/94/98/100's
records). In its place, adopted each stance directly by inspection,
following the same local precedent.

### after-proposal (retroactive) — stance: assume the rule as drafted cannot hold — find the state nothing maintains

Verdict: NO FINDING
Seed: `docs/issue-106/proposals/2026-08-03-build-headless-delegation-clause.md` (the docs-only phase-1 diff: proposal + survey + scout-brief, commit `2e3e248`)
Started/ended: this session, before drafting the contract section.

Checked whether the proposed rule assumes any mechanically-maintained
state it does not have (e.g. a `CLAUDE_HEADLESS`-style signal a session
could read to know its own mode). Grepped the whole repository (`grep
-rn "headless" --include="*.sh"`) — no such signal exists anywhere in
`core/hooks`, `warrant/hooks`, `freelunch/hooks`, `scout/hooks`, or
`terse/hooks`; every existing reference to "headless" in the repo is
prose in a role record (issue-20/23/78/83/93/94/98's own records), the
same self-assessed, non-mechanical judgment this proposal's rule also
relies on. This matches the proposal's own explicit `## Out of scope`
("Building or wiring any mechanical detection/enforcement... issue #106's
own requirement 3 assigns recurrence-detection to step 2") — the rule
being prose-judged rather than mechanically gated is a stated, deliberate
property of this delivery, not an undocumented gap the drafted section
introduces. No finding.

### before-landing — stance: assume this change and another plugin's rule cancel each other — find the pair

Verdict: FINDING — `warrant/hooks/directive.sh`'s own printed directive
text still unconditionally instructs background-dispatch-without-waiting,
with no pointer to the new contract §22, unlike `freelunch.sh` and
`core/hooks/directive.sh` (both amended by this delivery).
Kind: composition
Seed: `git diff` of this transition (`core/contract/role-handoff-contract.md`,
`core/hooks/directive.sh`, `freelunch/hooks/freelunch.sh`) against sibling
plugin directives (`warrant/hooks/directive.sh`, `scout/hooks/directive.sh`,
`terse/hooks/terse.sh`).

#### Reproduce

```
grep -n "run_in_background\|carry on without waiting" warrant/hooks/directive.sh
```
→ `warrant/hooks/directive.sh:60`: `"...dispatch ONE background agent —
`subagent_type: warrant-hunter`, `model: sonnet`, `run_in_background: true`
— and carry on without waiting for it... Never wait on it, never
interrupt work for it..."` (line 79 repeats "Never wait on it").

```
grep -n "s22\|contract v3" warrant/hooks/directive.sh
```
→ no output: zero occurrences.

#### Observed

`warrant/hooks/directive.sh` (priority="high", injected on every prompt
same as `freelunch.sh`) carries the identical shape this issue's proposal
found in `freelunch.sh` before this delivery — an unconditional
delegate-and-do-not-wait instruction, with nothing pointing a reader at
the new headless carve-out. New contract §22's own text ("This rule takes
priority over any directive that recommends or mandates delegation") is
worded generically and does legally/textually cover `warrant.sh` too
without needing to name it — but the proposal's own stated reason for
also editing `freelunch.sh` directly ("so a session reading freelunch's
own text sees the carve-out in the same place it currently sees the
unconditional delegate instruction," proposal `## Rationale`) applies
with equal force to `warrant.sh` and was not extended there, because
`warrant/hooks/directive.sh` was outside this proposal's frozen `files:`
write set.

#### Expected

A session reading only `warrant/hooks/directive.sh`'s injected text (a
real, separate injection point from `freelunch.sh` and `core/hooks/directive.sh`)
has no local signal that headless mode changes its "dispatch and carry on
without waiting" hunter instruction — it would need to have already read
and connected `core/contract/role-handoff-contract.md` §22 on its own.
Per this role's own build discipline — finish what the approved proposal
covers, stop, and report rather than widen the write set mid-build —
`warrant/hooks/directive.sh` is not edited by this delivery; the fix is
recorded below as a follow-up.

## Next steps

- **`warrant/hooks/directive.sh` subordination note (this repo, in scope
  for a future proposal).** File a follow-up issue/proposal to add the
  same one-line `SUBORDINATE TO CONTRACT v3 s22` pointer used in
  `freelunch/hooks/freelunch.sh:39` to `warrant/hooks/directive.sh`'s own
  hunter-dispatch instruction (line 60), for the same reason: a session
  reading `warrant.sh` alone currently sees zero indication that headless
  mode changes its unconditional "dispatch and carry on without waiting"
  text. Unlike the item below, this file is directly reachable and
  editable from this repo.
- **`implementation-rulebook` per-role directive reflection (cross-repo,
  not reachable from this branch).** Per proposal item 4 / issue #106
  requirement 2's own fallback: the role-specific "[implementation] Role
  directive" text this very session's own `SessionStart` hook printed
  lives in `implementation-rulebook`, a separate repo not present in or
  reachable from this working tree (confirmed in the phase-1 survey,
  `docs/issue-106/reports/implementation/survey.md`). The equivalent
  headless-delegation carve-out this issue lands in `role-handoff-contract.md`
  §22 should be reflected in that repo's own directive text too; this
  record recommends filing a separate issue against
  `tokenmaxxxer/implementation-rulebook` to do so. Whether other
  `*-rulebook` repos (`gh repo list tokenmaxxxer` shows roughly 40) share
  the same gap is not decided here — flagged as an open question for
  whoever files that follow-up, not answered by this proposal.
- Recurrence detection (issue #106 requirement 3 — whether the
  "delegate then end-turn-waiting" pattern recurs in role sessions opened
  after this section lands) is step 2's own job
  (execution-observation), not this delivery's.

## Resolution path

No open finding is raised against another role's record from this
delivery. The one `Hunt` finding above (`warrant/hooks/directive.sh`
composition gap) is carried forward as a `## Next steps` follow-up
recommendation, not a blocking `finding:` block against another role —
resolving it is a future, separately-filed proposal on this same repo,
kept outside this delivery's frozen write set rather than folded in here.

## Verify

`bash core/hooks/tests/run-all.sh` → `ALL OK`: board gate 84/0, approval
gate 42/0, gh guard 52/0, role-agnostic gates (trailer/record-fields/
handbook-trigger) 19/0, stub-check canon forms 3/0, compliance-check
scan-scope 4/0; `terse`/`freelunch`/`scout` sibling-plugin parse-checks
(including the two edited files, `core/hooks/directive.sh` and
`freelunch/hooks/freelunch.sh`) all `ok`.

`grep -n "s22\|section 22\|## 22\." core/contract/role-handoff-contract.md
core/hooks/directive.sh freelunch/hooks/freelunch.sh` → all three files
cross-reference the new section, satisfying the proposal's own "How
you'll know it worked" checklist item 2.
