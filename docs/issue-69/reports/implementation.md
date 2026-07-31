---
subject: issue-69
role: implementation
loop_state: landed
---

# Record — pin stub-check to core, ban rulebook copies, reclaim 21 duplicates

Phase 2, approved via `APPROVE issue-69/implementation` (single-account
mode) with scope note: item (c)'s 21-copy deletion is executed by
orchestration batch-spawn against the affected rulebook repos, not by this
role; core phase 2 delivers (a), (b), (d), and the reclaim procedure
documentation.

## Why

Fixes a self-defeating drift: the detector built to catch rulebooks
vendoring canon files was itself designed to be vendored 43 times. Pinning
it to core plus a manifest-driven ban makes the detector immune to the
recurrence it exists to catch. Upstream basis: the approved proposal
`docs/issue-69/proposals/issue-69-implementation.md`, built on
`docs/issue-69/reports/implementation/survey.md`.

## Scout: skipped

Design decisions for this delivery were already resolved in the approved
phase-1 proposal (invocation shape, manifest format, clause wording); phase
2 is implementation of an already-approved design with no open decision
left to scout.

## What was done

1. **(a) stub-check pinned to core.** `core/hooks/tests/stub-check.sh`'s
   header now states the core-referenced invocation model
   (`${CLAUDE_PLUGIN_ROOT}/hooks/<name>.sh`-shaped, resolved against core's
   own install root) instead of "every rulebook copies this file verbatim."
   `docs/handbooks/role-gates-tests.md` gained a "Canon invocation from a
   rulebook" section with the concrete invocation line and a note that the
   `${CLAUDE_PLUGIN_ROOT}` sibling-resolution expression needs pilot
   verification against a real marketplace install before rollout.

2. **(b) copy ban, manifest-driven.** `core/hooks/tests/canon-manifest.txt`
   (new) lists the five canon filenames stub-check enforces, including
   `stub-check.sh` itself. `stub-check.sh` now derives `CANON_GATES` from
   this manifest (falling back to a hardcoded list with a warning if the
   manifest is missing) instead of a hardcoded four-file string. A future
   promotion adds one manifest line, not a script edit.
   `core/hooks/tests/run-role-gates-tests.sh` gained a test asserting
   stub-check catches a vendored copy of itself.

3. **(c) reclaim procedure.** `docs/issue-69/reports/implementation/reclaim-21-copies.md`
   documents the enumerate → delete-and-reference → verify → batch-sequence
   rollout for the 21 existing copies. No deletion executed by this role
   (scope note above); this is the handoff artifact for orchestration's
   batch spawn.

4. **(d) recurrence clause.** `docs/handbooks/canon-scripts.md` (new)
   states "canon scripts are referenced, never copied" as a standing clause
   for future transition/maturation directives, generalizing `warrant`'s
   existing marketplace-description precedent, and points at the mechanical
   enforcement in (b).

## Verification

`bash core/hooks/tests/run-role-gates-tests.sh` — 17 passed, 0 failed
(16 pre-existing assertions plus the new self-copy detection case), run
against this branch after the above changes.

## Open findings

The `${CLAUDE_PLUGIN_ROOT}` sibling-resolution expression in the canon
invocation line is flagged, not finalized — needs a pilot check against one
real rulebook marketplace install before the 21-copy reclaim rollout
applies it at scale. Resolution path: orchestration's pilot run against one
rulebook repo, per `reclaim-21-copies.md`'s "Verification" section, before
the reclaim rollout applies the line to the remaining repos. This role's
own deliverable (a)/(b)/(d) plus the documented procedure is otherwise
complete; loop_state is `landed` because nothing further is required of
this role — the open item is for the orchestration-executed rollout, not a
gap in what this phase-2 delivery shipped.
