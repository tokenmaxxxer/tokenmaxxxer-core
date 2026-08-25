---
status: proposed
files:
  - docs/issue-304/reports/execution-observation.md
---

# Proposal: execution-observation record verifying issue-304/implementation (PR #307)

## Request

Fill the pre-written execution-observation record skeleton at
`docs/issue-304/reports/execution-observation.md` (issue #2135 skeleton)
with an independent verification of the work landed on
`issue-304/implementation` and opened as PR #307 ("issue-304: propagate
fixed kill-switch helper into 4 directive hooks (F19/F20)"): that PR's
claim is that `gate_kill_switch_active` (already fixed under issue-72
to fail-active on unrecognized values) was propagated from
`gate-lib.sh` into `role-directive.sh` and the three sibling
`*-directive.sh` hooks (proposal-shape, record-shape, survey-order),
replacing each hook's pre-fix inline case statement, plus a new drift
test added to `core/hooks/tests/run-directive-shape-tests.sh`.

## Constraints

- Write only `docs/issue-304/reports/execution-observation.md` this
  phase — no code, no other role's record, no other issue's tree.
- The record must use the pre-written skeleton's frontmatter (`issue`,
  `role`, `loop_state`, `upstream`, `subject`, `test`, `result`,
  `assertedBy`) and its five section headings, in the skeleton's own
  order — this proposal does not introduce a new record shape.
- PR #307 was delivered under the build-now bypass (`CORE_BUILD_NOW=1`,
  contract v3 s19a) with no phase-1 proposal round of its own — this
  record's basis is the PR's actual diff/commit and its own
  `docs/issue-304/reports/implementation.md`, not a phase-1 proposal
  that doesn't exist.
- Issue #304 carries an operator-frozen constraint (2026-08-25):
  systemic scope for every consumer session, no added overhead/load, no
  new conflict/stall surfaces, no consumer-tree residue, unavoidable
  trade-offs measured and stated — this record must check the
  implementation against that constraint too, not only the named
  acceptance gate.
- PR #307 is still open, not yet merged to main; this record observes
  the PR's content as of its current commit (`e9b4299`); if that commit
  changes materially before phase-2 work starts, that basis is stated
  explicitly rather than silently re-read.

## Rationale

Considered writing a full current-state survey
(`docs/issue-304/reports/execution-observation/survey.md`) before this
proposal, per the standard survey-before-proposal ordering. Rejected:
there is no open design decision here to survey toward. The record's
structure is fixed by a pre-written skeleton (issue #2135), and the
subject matter — PR #307's diff across 5 files, its own implementation
record, and issue #304's already-fixed acceptance gate — is a closed,
already-written set of artifacts to read and cross-check, not a space
of implementation alternatives to weigh. Writing a survey file here
would restate the same diff read the record itself performs, adding a
file without adding information. This falls under the
survey-order-directive's own "the spec leaves no design decision open"
skip condition, named here per that directive's requirement that the
skip be stated, not left implicit.

## What will be done

Re-derive, from the actual hook source on `issue-304/implementation`
(not just PR #307's own narration), whether
`core/hooks/lib/role-directive.sh` and the three
`core/hooks/*-directive.sh` siblings (proposal-shape, record-shape,
survey-order) now call the shared `gate_kill_switch_active` helper
instead of carrying an inline case statement; confirm the new drift
test in `core/hooks/tests/run-directive-shape-tests.sh` actually
asserts the claimed behavior (a typo keeps the hook active where the
old code disabled it; an exact `1` still disables it); execute the
issue's own named acceptance gate
(`bash core/hooks/tests/run-directive-shape-tests.sh`) directly rather
than trusting PR #307's pasted pass count; cross-check the regression
numbers PR #307 claims for `run-gate-lib-tests.sh`,
`run-role-gates-tests.sh`, and `run-approval-gate-tests.sh`; check the
operator-frozen constraint (no added overhead/load, no new
conflict/stall surfaces, no consumer-tree residue) against the actual
diff shape; record a concrete verdict (pass/fail per claim, evidenced
with pasted command output) in the skeleton's `## What was done`,
`## Why`, `## Upstream basis`, `## Open findings`, and `## Next steps`
sections; set `result:` and `assertedBy:` frontmatter and move
`loop_state` to this record kind's terminal value once verification is
complete.

## Out of scope

- Re-opening or re-litigating PR #307's fix approach itself — that call
  belongs to issue #304/PR #307, not to this observation.
- Any gate or hook code change.
- Anything outside `docs/issue-304/reports/execution-observation.md`.

## How you'll know it worked

`docs/issue-304/reports/execution-observation.md` is filled in per the
skeleton with a stated, evidenced verdict on PR #307's central claims
(helper propagated into all 4 hooks; drift test behaves as claimed;
acceptance gate passes; operator-frozen constraint held), citing actual
source lines and pasted command output rather than only restating PR
#307's own text, frontmatter `result:`/`assertedBy:` set, and
`loop_state` at this record kind's terminal value.
