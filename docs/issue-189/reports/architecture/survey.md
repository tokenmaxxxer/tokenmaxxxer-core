Subject: issue-189

# Current-state survey — architecture step (rejection/withdrawal lifecycle)

Builds directly on the merged step-1 audit
(`docs/issue-189/reports/product-discovery/survey.md`), which confirmed all
four candidate gaps plus three additional findings with file:line evidence.
This survey does not re-derive that evidence; it reads the same surface
for the one question step-1 explicitly deferred: what shape closes the
gaps, and how does that shape compose with on-the-record #573's merged
architecture.

## Where contract-level vocabulary actually lives

`core/contract/role-handoff-contract.md` §2's kind table is not the only
place `loop_state` legality is enforced. `core/hooks/tests/deny-only-
check.sh` and `record-fields-gate.sh` derive **terminal** states per kind
from §2, and a repo may override that terminal set via
`docs/specs/record-fields-terminal-states.json` (a `{kind: [states]}`
object) — but that override file governs which *already-valid* states
count as terminal, not which states are valid loop_state values at all.
Adding a new value to a kind's vocabulary (e.g. `refused`) is a §2 edit,
not a JSON override; the override mechanism is for repos that want to
mark a contract-recognized-but-non-default state terminal for their own
process, not for inventing new vocabulary.

Consequence for design: a shared `refused` value added once to §2's
preamble and referenced by every kind's vocabulary column is a **contract
change**, in the same document and same review path as every other §2
edit — not a side-channel JSON file. `record-fields-terminal-states.json`
is the right lever for a *repo* to promote `refused` to terminal early,
never the lever for defining `refused` in the first place.

## The approval/rejection asymmetry, read again for shape

`core/hooks/approval-gate.sh:258-283` already distinguishes three PR
review states (`APPROVED`, `CHANGES_REQUESTED`, `DISMISSED`) when
computing `pr_approved`, but collapses `CHANGES_REQUESTED` and
`DISMISSED` into one bucket ("not currently approved") and discards the
review body. The single-account path already has a canonical string
contract (`APPROVE issue-<n>/<role>`, exact-match, human-posted,
role-session denied from posting it via `gh-guard.sh:85`). Both facts
matter for the rejection design: the *token spelling* pattern is proven
and battle-tested (the "measured lesson from the retired mint design"
comment at approval-gate.sh's challenge line), and the *two-path*
structure (PR review vs. issue comment) already exists for approval and
should not be reinvented for rejection.

## #573's consumption surface, as stated in the issue and step-1's survey

Neither this repo nor step-1's survey can read #573's merged code directly
(different repo, not fetchable from here). Both this survey and the
architecture decision therefore treat #573's shape as given by the issue
body and step-1's alignment-constraint section: a `verdict: contradicts`
result carries an actionable `finding` object (contract §5's shape:
`requirement`, `verdict`, `evidence`, `rationale`, `spec_vs_built`,
`addressed_to`, `severity`), routed through write_scope to a remediation
record, and surfaced as an issue-timeline event. The constraint step-1
already recorded stands: whatever this step defines must be nameable from
`verdict: contradicts` without #573 inventing a parallel state or a second
finding-shaped record living beside contract §5's.

## Re-scout trigger check

No new product-facing decision surfaced during this design pass beyond
what step-1's survey already scoped (the four candidates plus findings
#5-#7); scouting stays skipped per step-1's skip record (no external
field to compare an internal contract-vocabulary decision against). No
re-scout fired.
