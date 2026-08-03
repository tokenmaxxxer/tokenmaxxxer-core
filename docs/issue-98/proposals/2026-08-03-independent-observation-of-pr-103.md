---
kind: proposal
subject: issue-98
produced_by: execution-observation
loop_state: phase-1
upstream:
  - path: docs/issue-98/reports/execution-observation/survey.md
  - path: docs/issue-98/reports/execution-observation/scout-brief.md
---

# Proposal — independent execution observation of PR #103 (issue-98 step 2)

## Subject

Issue #98, execution plan step 2. The artifact under observation is PR
**#103** (`propose(implementation): wrapper-head class fix for the dequote
bypass`, head `issue-98/implementation`, merged as
`9cd8a20f1779a180a42e431d1ae07d6ad797c71b`), its two commits
`27a0c8aaeba542400f7c3c43828b89c94ffa2d9a` (propose) and
`e51bc09a4ea10965027e692edd5d7f1408a73951` (deliver), and the observed role's
own record `docs/issue-98/reports/implementation.md`. All three were read
this session; the survey lists exactly what was read.

This document contains no verdict, provisional or otherwise. It states which
verdict levels phase 2 will check and against which evidence, and stops there.

## Which verdict levels will be checked, and against what

Phase 2 will address **all three** levels required of this role, and will
write "not applicable, because X" for any level that turns out not to apply
rather than omitting it.

- **Outcome** — did PR #103 land what issue #98 asked. Evidence: issue #98's
  four numbered requirements read against the diff at `e51bc09`
  (`core/hooks/lib/gate-lib.py`, `core/hooks/board-gate.sh`,
  `core/hooks/gh-guard.sh`, the two test harnesses) and against PR #103's
  file list for requirement 4 (handbook in the same commit).
- **Trajectory** — was the phase-1→phase-2 path sound. Evidence: the
  propose commit `27a0c8a` and its proposal document versus the deliver
  commit `e51bc09` and the record's `## What did not work` /
  `## Hunt` sections; the approval act itself — issue #98's single comment
  whose entire body is `APPROVE issue-98/implementation`, posted by an
  account listed in `docs/specs/approvers.md`, in single-account mode; and
  whether the delivery stayed inside the approved proposal's stated scope.
- **Step** — which specific artifact, if any, is deficient. Evidence: the
  five evidence lines below, each anchored to a file:line or commit SHA.

Any deficiency this produces will be written in the four-part blameless shape
(impact, timeline, root cause, action item), scaled to the finding.

## Evidence lines (the five questions this observation answers)

Each maps to a survey unknown (U1–U5). Each names, in advance, the artifact
that decides it — so the phase-2 record can cite rather than assert.

1. **(a) Do the 14 wrapper deny cases pin a pre-change failure?** (U1)
   Decided by: `run-gh-guard-tests.sh:94-102` (9 issue-named) and `:110-117`
   (5 hunt-found) against the record's `closed_checks` at
   `docs/issue-98/reports/implementation.md:221-231` and `:232-243`, and
   against the claim in `e51bc09`'s commit message. Judged by reading the
   diff's own logic for whether each case's shape could have been reached by
   the pre-change `gh-guard.sh` (at `27a0c8a`), **not** by re-running any
   harness.
2. **(b) Did the `TRANSPARENT` relocation change board-gate behavior?** (U2)
   Decided by: `board-gate.sh:172` at `27a0c8a` (6-entry tuple) versus
   `gate-lib.py:194-200` at `e51bc09` (8 entries + `TRANSPARENT_TAKES_ARG`),
   traced through `board-gate.sh:220-242` and the head lists at `:99-108`,
   plus whether any of the 8 new cases at `run-board-gate-tests.sh:297-319`
   pins the traced difference.
3. **(c) Is the negative space intact?** (U3) Decided by: the unmodified
   `quote-*` allow cases at `run-gh-guard-tests.sh:78-80`, the guard
   condition at `gh-guard.sh:144` (`if dequote and re.search(pat, cmd)`),
   and the deliberately-denying `wrapper-bash-c-plain-grep` at `:124`, read
   against issue #98 requirement 3.
4. **(d) Is the recorded out-of-scope limit real, and how risky?** (U4)
   Decided by: the record's `## Hunt` and `## Open findings`
   (record:192-204, :265-277) versus what `gate_wrapper_head_before`
   (`gate-lib.py:258-310`) and `_resolve_transparent` (`:203-236`) actually
   do — including whether the `nice -n 10` class named in the invoking
   prompt is the limit the record leaves open or the one it closed at
   `run-gh-guard-tests.sh:110-113`, and what the retained
   `gate_head_of` imprecision means for `board-gate.sh:223`.
5. **(e) Was issue-100's citation convention honoured here?** (U5) Decided
   by: `docs/issue-98/reports/implementation.md:2,5,215,222,233,245,254`
   against
   `docs/issue-100/decisions/2026-08-03-record-citation-format-and-kind-convention.md`
   Decisions 1–4, the gate check added in `85d4e29`, and the measured
   ancestry (`git merge-base --is-ancestor a339ad9 e51bc09`,
   `git log --format=%P -1 e51bc09`).

## Method, and its limits

- Admissible evidence: the PR diff, the commits, PR/issue metadata, and the
  observed role's own record. Reasoning is by reading those artifacts.
- Prohibited and not planned: re-running `run-gh-guard-tests.sh`,
  `run-board-gate-tests.sh`, `run-gate-lib-tests.sh`, or any gate script;
  re-executing the observed role's task in any form; reading the current
  working-tree `core/hooks/*` as evidence of what that role did. The scout
  brief records this as a deliberate skip, with the field's own bypass
  payloads (`$(…)`, `BASH_ENV`, adjacent-quote concatenation) entering as
  record-vs-diff reading only.
- Consequence, stated up front: where a claim can only be settled by
  execution, phase 2 will say so and confine itself to what the artifacts
  show, rather than closing the question on inference.
- Independence: this role authored no part of PR #103 and edits nothing
  under `core/`, `test/`, or another role's `docs/issue-98/` paths. Findings
  return only through this branch's own record and PR.

## Deliverable

`docs/issue-98/reports/execution-observation.md` — written as the first act
of phase 2, opening with the independence statement before any verdict
language, carrying the three-level verdict with a citation adjacent to every
verdict-bearing sentence, and committed on this branch.

## Phase gate

Phase 2 opens only on a review Approve from a `docs/specs/approvers.md`
account other than this PR's author, or — in single-account mode — an
issue-level comment whose entire body is exactly
`APPROVE issue-98/execution-observation`. The existing
`APPROVE issue-98/implementation` comment on issue #98 names a different
role and is not that act.
