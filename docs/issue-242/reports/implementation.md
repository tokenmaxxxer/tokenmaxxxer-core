---
code_under_review:
  - core/hooks/arch-sequence-gate.sh
  - core/hooks/devrel-phase-order-gate.sh
  - core/hooks/interaction-design-stage-order-gate.sh
  - tests/test_ordering_gates_237.py
loop_state: landed
type: fix
breaking: false
verdict: pass
---

# Implementation record — issue-242

## What was done

Scoped the 3 unscoped ordering gates promoted in #239
(`arch-sequence-gate.sh`, `devrel-phase-order-gate.sh`,
`interaction-design-stage-order-gate.sh`) to their own role's proposal
filename pattern, mirroring the already-scoped gates
(`content-design-phase1-basis-gate.sh`, `security-threat-model-sequence-gate.sh`,
`issue-retrospective-proposal-order-gate.sh`):

- `arch-sequence-gate.sh`: `PROPOSAL_RE` now
  `^docs/(issue-[0-9]+)/proposals/.*architecture.*\.md$` (was: any
  `proposals/*.md`).
- `devrel-phase-order-gate.sh`: `TARGET_RE` now
  `^(docs/issue-[^/]+)/proposals/.*devrel.*\.md$` (was: any
  `proposals/*.md`).
- `interaction-design-stage-order-gate.sh`: `PROPOSAL_RE` now
  `^docs/issue-([0-9]+)/proposals/.*interaction-design.*\.md$` (was: any
  `proposals/*.md`).

Each gate's phase-2 record-side check (matching a fixed filename like
`reports/architecture.md`) was already role-specific by construction and
needed no change.

`tests/test_ordering_gates_237.py`: updated the 3 gates' existing
allow/refuse fixtures to use role-scoped filenames
(`architecture-thing.md`, `devrel-thing.md`,
`interaction-design-thing.md`) so they still exercise in-scope behavior,
and added one new test per gate asserting a foreign-role
`docs/issue-<n>/proposals/consolidation.md` write passes with none of
that role's phase-1 artifacts present.

## Why

Basis: #241 (docs/issue-240/reports/implementation/survey.md), which
documented and reproduced the deadlock: these 3 gates fired on ANY
`docs/issue-<n>/proposals/*.md` write regardless of acting role, while
board-gate correctly refuses creating another role's artifacts — net,
no role could write any new proposal. The 4 gates that already
filename-scope their proposal-side regex (content-design,
security-threat-model, issue-retrospective, plus incident-response)
were unaffected; this hotfix brings the remaining 3 in line with that
existing pattern.

Direct delivery (no proposal PR) is authorized by issue #242's own text
("this issue authorizes a DIRECT delivery ... scoped to this hotfix
only") because the phase-1 proposal step is itself the thing the bug
blocks.

## Verification

```
$ python3 -m pytest -q tests/test_ordering_gates_237.py
........................                                                 [100%]
24 passed in 1.40s
```

Live reproduction of the previously-refused write, now succeeding
(gate scripts invoked as subprocesses against an isolated tmp project
root, `docs/issue-242/proposals/consolidation.md`, exactly the
foreign-role proposal shape from #241's survey):

Before fix (scripts at HEAD, pre-hotfix):
```
--- arch-sequence-gate.sh ---
arch-sequence-gate: refused — docs/issue-242/proposals/*.md is being written but docs/issue-242/reports/architecture/survey.md does not exist yet. Per contract v3 s19's rigor floor, the survey runs before the proposal.
exit: 2
--- devrel-phase-order-gate.sh ---
phase-order-gate: refused — docs/issue-<n>/proposals/*.md written before docs/issue-242/reports/devrel/survey.md exists — write survey.md first (phase-1 order: survey -> scout -> proposal).
exit: 2
--- interaction-design-stage-order-gate.sh ---
id-stage-order: refused — no project root could be determined; failing closed (stage-order check cannot run).
exit: 2
```

After fix (same payload, same 3 scripts, post-hotfix):
```
--- arch-sequence-gate.sh ---
exit: 0
--- devrel-phase-order-gate.sh ---
exit: 0
--- interaction-design-stage-order-gate.sh ---
exit: 0
```

## Doc-placement ladder

- [x] No new env var, config key, dependency, or migration introduced —
  handbook update not applicable.
- [x] No library/format choice over a named alternative, no changed
  public signature/wire format — decisions/ entry not applicable
  (regex-scoping mirrors the existing 4-gate pattern verbatim; no new
  alternative was weighed).
- [x] No benchmark/investigation numbers produced — reports/ entry not
  applicable beyond this record itself.

## What did not work

None.

## Open findings

None.

## Upstream

Basis: #241 / docs/issue-240/reports/implementation/survey.md; issue #242.
