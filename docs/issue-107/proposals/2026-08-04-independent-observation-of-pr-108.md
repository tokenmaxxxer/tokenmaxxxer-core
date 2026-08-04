---
kind: build-proposal
subject: issue-107
produced_by: execution-observation
loop_state: proposed
upstream:
  - path: docs/issue-107/reports/execution-observation/survey.md
    sha: <set at commit>
  - path: docs/issue-107/reports/execution-observation/scout-brief.md
    sha: <set at commit>
---

files: `docs/issue-107/reports/execution-observation.md`

## Request

Issue #107's `## 실행 계획` step 2 is `execution-observation`: an independent
judgment of step 1 — the `implementation` role's session on branch
`issue-107/implementation`, delivered as PR #108 (`MERGED`, merge commit
`f6d6983`), commits `67eb71e` (phase 1) and `ace7dda` (phase 2), with its own
record at `docs/issue-107/reports/implementation.md`. The invoking prompt adds
one named sub-question: the single deviation from that session's own approved
proposal — the `docs/handbooks/board-gate-tests.md` entry the record attributes
to `handbook-trigger-gate.sh` (contract §21) — and whether that deviation was
justified.

This document fixes the check points **before** any evidence is weighed. It
renders no judgment of any kind; every question below stays a question until
phase 2 opens. The evidence base is the survey
(`docs/issue-107/reports/execution-observation/survey.md`), which lists exactly
what was read this session and the six unknowns (U1–U6) this plan must route.

## Which verdict levels will be checked, and against what evidence

All three levels of the phase-2 verdict will be addressed; a level that turns
out not to apply will be written as "not applicable, because X" rather than
dropped.

**Level 1 — outcome (did PR #108 land what issue #107 asked).** Checked
requirement by requirement against issue #107's own three `## 요구사항` and two
`## 제약`, using only:
- the `ace7dda` diff hunks for `core/hooks/lib/gate-lib.py` and
  `core/hooks/board-gate.sh` (requirement 1: is the `cd` argument now taken
  from the same command-start model head detection uses);
- the two `run deny` rows in `ace7dda:core/hooks/tests/run-board-gate-tests.sh`
  and their command strings (requirement 2's shape coverage: the `timeout`
  form plus one pre-#98 wrapper, `command` or `env`);
- the diff's own control flow plus the landed test file's negative-space rows
  (`bash-unresolved-head-then-read`, `bash-cd-then-cat`) for requirement 3;
- `git show --stat ace7dda` against the two `## 제약` (no change to `cd_tail`,
  the dead-fallback removal, or the `TRANSPARENT` tuple).

**Level 2 — trajectory (was the phase-1 → phase-2 path sound).** Checked
against artifacts, not narrative:
- phase separation: `67eb71e`'s `--stat` (documents only, no code) against
  `ace7dda`'s, plus PR #108's creation time and the two commit timestamps
  recorded in the survey;
- approval: the issue-level comment whose entire body is
  `APPROVE issue-107/implementation`, its author against
  `docs/specs/approvers.md`, and `gh pr view 108 --json reviews` → `[]` —
  i.e. which contract v3 s19 path was available and which was used (survey U1,
  U4). Where the timestamp could not be read through an allowed `gh` spelling,
  the ordering evidence actually available is what the verdict may rest on,
  and the record will say so;
- survey-before-proposal: `67eb71e`'s two files and their internal upstream
  references;
- scouting: the observed session's own skip record
  (`implementation/survey.md:160-168`, proposal `:35-41`) against the
  scout-directive's two skip conditions.

**Level 3 — step (which specific artifact, if any, is deficient).** The named
candidates this plan commits to examining, each against a specific artifact:
1. **The handbook deviation** (the invoking prompt's explicit sub-question):
   the proposal's frozen `files:` line and `## Out of scope`
   (`:11`, `:152-157`) against `ace7dda`'s actual write set, against
   `handbook-trigger-gate.sh:103,114,116-126` and `hooks.json:39` (the gate in
   force, established as unchanged since `52bdc15` by `git merge-base
   --is-ancestor`), and against contract §21's own substantive trigger list
   (`role-handoff-contract.md:855-860`) and same-unit-of-work rule
   (`:895-900`). Three sub-questions, kept separate: (a) does the in-force gate
   mechanically compel a handbook touch for this staged set; (b) does §21's
   substantive text independently require one for a test-runner script
   (survey U5); (c) was the write scoped to the gate's minimum, or did it carry
   content beyond it. Per the scout brief, a broad pattern match is a prompt
   for judgment, not self-justifying compliance.
2. **Sibling call sites of the same defect class** — the scout brief's first
   performance axis. The issue-99 record's Finding 1 root cause
   (`docs/issue-99/reports/execution-observation.md:412-422`) names
   `_git_subcommand` as sharing the same index assumption, and the pre-delivery
   `_cd_target` docstring cited it as the idiom being reused. Checked against
   the `ace7dda` diff and the landed blob of `board-gate.sh` at that commit
   only — whether the delivery's own scope statement addresses the sibling, and
   whether the record says anything about it.
3. **The red-green claim's evidence tier** (survey U3). This role may not
   re-run the suite, so the check is explicitly a static one: the case tally
   already measured in the survey (84 at `ace7dda~1`, 86 at `ace7dda`) against
   the counts the record states (`implementation.md:152-171`), plus the
   internal consistency of the record's own `closed_checks`. The verdict will
   label which tier each supporting fact belongs to — artifact-derived versus
   the observed role's own assertion — and will not present an assertion as a
   reperformed result.
4. **The refusal event itself** (survey U2) — asserted by
   `implementation.md:57-79`, with no repository artifact. The check is
   whether the record's claim is *consistent with* the in-force gate's staged-
   set logic; establishing that the event occurred is out of reach and will be
   stated as such rather than assumed either way.
5. **Citation drift inside the observed session's documents** (survey U6):
   proposal `:70`/`:93`/`:121` (`board-gate.sh:329`, `:330`) versus record
   `:33`/`:37` (`:333`, `:334`), against the `ace7dda` diff's own added line
   count.

## Constraints

- **No re-execution.** `run-board-gate-tests.sh`, `run-gate-lib-tests.sh`,
  `run-gh-guard-tests.sh`, `handbook-trigger-gate.sh`, and the live gate are
  not run, and issue #107's fix is not re-implemented or probed. Admissible
  evidence is limited to commit diffs, blobs at named commits, merged
  documents, GitHub artifacts, and the governing contract and hook text.
- **No working-tree `src/` as evidence of what happened.** `core/hooks/**` in
  its current state shows what exists now, not what the observed session did.
  Where a landed file must be consulted it is read at a named commit
  (`git show <sha>:<path>`).
- **This role never edits the observed artifact.** The entire write surface of
  this session is `docs/issue-107/reports/execution-observation.md`,
  `docs/issue-107/reports/execution-observation/`, and this proposal. Nothing
  under `core/`, `test/`, or `docs/issue-107/reports/implementation*` is
  touched.
- **No issue filing.** Under contract v3 issues are user-authored only; any
  confirmed deficiency lands as a finding in this role's record for the human
  to judge on this PR.
- **Ordering inside the record.** The independence statement precedes all
  verdict language; nothing verdict-shaped appears above it.

## What will be done (phase 2)

1. Write `docs/issue-107/reports/execution-observation.md` as the first act of
   phase 2, opening with the independence statement, then `## Why` /
   `## What was done` (the read-and-not-run list), then the three verdict
   sections in order: outcome, trajectory, step.
2. Adjudicate the five step-level candidates above in that section, each with
   its citation adjacent to the claim.
3. Write any confirmed deficiency in the four-part blameless shape — impact,
   timeline, root cause, action item — scaled to a single finding, with the
   action item addressed to the human rather than performed by this role.
4. Record the evidence tier of each verdict that rests on a non-reproducible
   claim, per the scout brief's second performance axis.
5. Keep `loop_state` current at every transition (`observing` → `landed`) and
   commit the record on this branch; an uncommitted record counts as not
   written.

## Out of scope

- Re-judging issue #99's Findings 2 and 3, which that record left open for the
  human; issue #107 is scoped to its Finding 1 only.
- Any judgment of PR #111 / issue-106 or PR #110 / issue-109, which merged into
  `main` around the same window but are different subjects.
- Proposing, writing, or landing a fix for anything found. A finding is
  reported; the human decides.
- Verifying the observed session's shell-environment narrative
  (`CLAUDE_PLUGIN_ROOT_CORE` contamination, `implementation.md:81-99`) by
  reproducing it — that would be re-execution. It is read as narrative only.

## How you'll know it worked

- All three verdict levels appear in the record, each either adjudicated or
  written as "not applicable, because X"; no level silently omitted.
- Every verdict-bearing sentence carries a commit SHA, `file:line`, or PR/issue
  artifact reference immediately adjacent to it.
- The independence statement appears above the first verdict-shaped sentence in
  the document.
- The handbook deviation is adjudicated on all three of its sub-questions
  (mechanical compulsion, substantive §21 trigger, minimality of the write),
  with the gate's own text cited.
- Each of survey U1–U6 is either resolved in the record or explicitly carried
  forward as unresolvable from artifacts, with the reason stated.
- The record is committed on `issue-107/execution-observation` and pushed to
  the same PR that carries this proposal.
