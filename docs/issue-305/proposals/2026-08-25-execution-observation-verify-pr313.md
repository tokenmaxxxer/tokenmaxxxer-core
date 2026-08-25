---
status: proposed
files:
  - docs/issue-305/reports/execution-observation.md
---

# Proposal: execution-observation record verifying issue-305/implementation (PR #313)

## Request

Fill the pre-written execution-observation record skeleton at
`docs/issue-305/reports/execution-observation.md` (issue #2135 skeleton)
with an independent verification of the work landed on
`issue-305/implementation` and opened as PR #313 ("issue-305: sweep
remainder — python3 fail-closed consistency + 15 remaining
silent-failure findings"). PR #313's claim: 19 findings from issue
#301's inventory, not already covered by sibling issues #303 (F15/F17)
or #304 (F19/F20), fixed across 15 files in 13 commits — the issue's
named primary ask (F9/F16/F18/F22: 4 core gates now name a missing-python3
failure instead of failing closed with zero bytes on either stream,
plus `facet-keyword-gate.sh`'s bash-level check demoted to parity) and
15 further single-mechanism findings (F1-F8, F10-F14, F21, F23), each
with live-fire before/after evidence pasted in its own commit and an
existing-test-suite regression check.

## Constraints

- Write only `docs/issue-305/reports/execution-observation.md` this
  phase — no code, no other role's record, no other issue's tree.
- The record must use the pre-written skeleton's frontmatter (`issue`,
  `role`, `author`, `loop_state`, `upstream`, `subject`, `test`,
  `result`, `assertedBy`) and its five section headings, in the
  skeleton's own order — this proposal does not introduce a new record
  shape.
- This session's `approval-gate` blocks reading file content directly
  off the unmerged `issue-305/implementation` branch pre-approval (`git
  show`/`git cat-file` against that ref fail closed with the same
  contract-v3-s19 message that gates phase 2); this proposal is
  therefore based on issue #305's own text, PR #313's title/body/file
  list obtained via `gh pr view`, and the branch's commit-message log
  obtained via `git log` — not a full diff or implementation-record
  read. The deep, line-level read happens in phase 2, once approved.
- PR #313 is still open, not yet merged to main; this record observes
  the PR's content as of its current head commit (`183e2d3`); if that
  commit changes materially before phase-2 work starts, that basis is
  stated explicitly rather than silently re-read.
- Issue #305 carries an operator-frozen constraint (2026-08-25):
  systemic scope for every consumer session that installs
  on-the-record and works against any target repo, no added per-spawn
  overhead or steady-state load, no new conflict/stall surfaces, no
  consumer-tree residue, unavoidable trade-offs measured and stated —
  this record must check the implementation against that constraint
  too, not only the issue's own named acceptance gate.

## Rationale

Considered writing a full current-state survey
(`docs/issue-305/reports/execution-observation/survey.md`) before this
proposal, per the standard survey-before-proposal ordering. Rejected:
there is no open design decision here to survey toward — the same
reasoning the sibling execution-observation proposal for issue #304
used (`docs/issue-304/proposals/2026-08-25-execution-observation-verify-pr307.md`).
The record's structure is fixed by a pre-written skeleton (issue
#2135), and the subject matter — PR #313's 13 commits across 15 files,
its own `docs/issue-305/reports/implementation.md`, and issue #305's
already-named acceptance gate (`core/hooks/tests/run-gate-shape-tests.sh`)
— is a closed, already-written set of artifacts to read and cross-check,
not a space of implementation alternatives to weigh. Writing a survey
file here would restate the same diff read the record itself performs,
adding a file without adding information. This falls under the
survey-order-directive's own "the spec leaves no design decision open"
skip condition, named here per that directive's requirement that the
skip be stated, not left implicit.

## What will be done

Once approved: re-derive, from the actual hook source on
`issue-305/implementation` (not just PR #313's own narration), whether
each of the 19 claimed findings (F1-F14, F16, F18, F21-F23) is present
at its claimed location and actually closes the described silent
failure; execute the issue's own named acceptance gate
(`core/hooks/tests/run-gate-shape-tests.sh`) directly rather than
trusting PR #313's pasted 18/18 byte-identical claim; cross-check the
PATH-without-python3 live-fire evidence PR #313 claims for the 5
affected python3-check sites (the 4 core gates plus
`facet-keyword-gate.sh`) rather than trusting the pasted output;
cross-check the `core/hooks/tests/run-all.sh` full-sweep claim (no new
failures beyond 2 pre-existing/unrelated ones the implementation record
says it confirmed via `git stash` A/B); check the operator-frozen
constraint (systemic scope, no added overhead/load, no new
conflict/stall surfaces, no consumer-tree residue) against the actual
diff shape; record a concrete, evidenced verdict per claim in the
skeleton's `## What was done`, `## Why`, `## Upstream basis`, `## Open
findings`, and `## Next steps` sections; set `result:` and
`assertedBy:` frontmatter and move `loop_state` to this record kind's
terminal value once verification is complete.

## Out of scope

- Re-opening or re-litigating PR #313's fix approach itself — that call
  belongs to issue #305/PR #313, not to this observation.
- Any gate or hook code change.
- Anything outside `docs/issue-305/reports/execution-observation.md`.

## How you'll know it worked

`docs/issue-305/reports/execution-observation.md` is filled in per the
skeleton with a stated, evidenced verdict on PR #313's central claims
(all 19 findings fixed as described; acceptance gate passes 18/18
byte-identical; PATH-without-python3 live-fire holds for all 5 sites;
`run-all.sh` shows no new failures beyond the 2 documented pre-existing
ones; operator-frozen constraint held), citing actual source lines and
pasted command output rather than only restating PR #313's own text,
frontmatter `result:`/`assertedBy:` set, and `loop_state` at this
record kind's terminal value.
