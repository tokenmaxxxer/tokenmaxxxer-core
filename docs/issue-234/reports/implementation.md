---
code_under_review:
  - core/hooks/proposal-shape-directive.sh
  - core/hooks/proposal-shape-gate.sh
  - core/hooks/record-shape-directive.sh
  - core/hooks/record-shape-gate.sh
  - core/hooks/survey-order-directive.sh
  - core/hooks/survey-order-gate.sh
  - core/hooks/hooks.json
  - tests/test_promoted_hooks.py
loop_state: landed
type: feature
breaking: "false"
verdict: pass
---

## Summary of work

Promoted the 3 hook pairs (proposal-shape, record-shape, survey-order —
directive.sh + gate.sh each) named by on-the-record#1746's audit
(docs/reports/rulebook-hook-audit.md) from
`tokenmaxxxer/implementation-rulebook` into `core/hooks/`, per the
approved proposal
`docs/issue-234/proposals/2026-08-21-promote-7-rulebook-hooks.md`. Bound
all 6 in `core/hooks/hooks.json`: a new `UserPromptSubmit` array for the
3 `*-directive.sh` scripts, and the 3 `*-gate.sh` scripts appended to the
existing `PreToolUse` array. Wrote `tests/test_promoted_hooks.py` with
allow, refuse, and empty-state cases per gate (9 tests total), invoking
each promoted gate script as a subprocess. The customer-support ->
`record-fields-gate.sh` row from the audit needed no file change (already
core) and is not part of this issue's write set. No `implementation-rulebook`
file was modified.

## Why

Per the audit, these hook bindings encode role-handoff contract v3 norms
(phase-1 proposal shape, phase-2 record shape, survey-before-proposal
write order) rather than role-specific invariants, so they belong in
`core/hooks/` and should apply to every session, not just roles that
happen to have shipped them in a rulebook. Promote-first: rulebook-side
removal is explicitly out of scope for this issue (no enforcement gap
today — removal is a later phase after core-side verification).

## Basis

docs/issue-234/proposals/2026-08-21-promote-7-rulebook-hooks.md

## Upstream

Approved via issue-level comment "APPROVE issue-234/implementation"
(single-account mode, listed approver JiwonJung94).

## What did not work

None.

## Open findings

None.
