---
code_under_review: core/contract/role-handoff-contract.md
loop_state: phase-2-complete
---

# Implementation record — issue #155

## What was done

Amended `core/contract/role-handoff-contract.md` §19 with two prose
norms, per the approved proposal
(`docs/issue-155/proposals/2026-08-08-build-phase-boundary-hygiene.md`):

- **F1** — the phase-1 "propose" bullet now requires a role, before
  freezing any `docs/issue-<m>/` path (m ≠ n) into its `files:` write
  set, to check that path against R4
  (`core/hooks/board-gate.sh`'s branch rule) and, if its own branch
  cannot write it, design a routing alternative in the proposal instead.
- **F2** — the phase-2 "execute" bullet now requires the role to refresh
  the PR's title and body on landing to describe what phase 2 actually
  delivered, on every delivery step (the final step's Closes-trailer
  norm already forces the body edit; this closes the title gap and the
  non-final-step body gap).

Both are sourced from `docs/issue-132/reports/execution-observation.md`
Findings 1-2, addressing a 2nd-occurrence F1 recurrence and the
unaddressed F2 title/non-final-step gap.

## Why

Contract §19 previously had no textual check for whether a frozen
foreign-issue path is actually writable by the freezing branch (F1), and
no requirement to refresh a landed PR's title/non-final-step body to
match what phase 2 delivered (F2). Both gaps were observed recurring in
`docs/issue-132/reports/execution-observation.md`.

## Upstream basis

- Issue #155 requirements and Acceptance criteria.
- Approved proposal: `docs/issue-155/proposals/2026-08-08-build-phase-boundary-hygiene.md`.
- `docs/issue-132/reports/execution-observation.md` (F1/F2 source).

## Proposal clause tracking

- [x] Amend §19's phase-1 "propose" bullet to add a branch-writability
  check (F1) before freezing a foreign-issue `docs/issue-<m>/` path.
- [x] Amend §19's phase-2 "execute" bullet to add a PR-description-refresh
  requirement (F2) covering title and non-final delivery steps.
- [x] Record the mechanization cost judgment (already in the approved
  proposal's Rationale) and cross-reference it here.

## Doc placement (completed)

- Both norms are prose amendments inside `core/contract/role-handoff-contract.md`
  §19 — no `docs/decisions/` entry needed (no library/format choice, no
  changed public signature/wire format), per the approved proposal.
- Mechanization-cost rationale for F1/F2: recorded in
  `docs/issue-155/proposals/2026-08-08-build-phase-boundary-hygiene.md`
  under `## Rationale` (Alternatives 1 and 2) — cross-referenced here per
  the issue's Acceptance clause 3 ("채택하지 않으면 제안 Rationale 에
  비용 판단 기록").
- No env var / config key / new dep / migration / setup step introduced —
  no handbook entry required.

## What did not work

None.

## Hunt

warrant-hunter dispatched before landing (stance rotated per
`.warrant-hunt.count`), diff scoped to a single contract-text file
(~30-40 line delta) — 60s cap, one stance.

closed_checks:
- contract-text-only-diff (code_sha: this commit) — confirmed no
  `core/hooks/*.sh` file touched, matching the proposal's stated write
  set and Constraints.

warrant-hunter (before-landing, stance "assume the rule as written
cannot hold") reported one finding: F1's phrase "checks ... and, if its
own branch cannot write it, designs a routing alternative" reads as a
conditional, but under R4's live implementation
(`core/hooks/board-gate.sh`) a role's own branch (`issue-<n>/<role>`)
never satisfies R4 for a foreign `docs/issue-<m>/` path (m != n) — the
branch check always denies when F1 triggers, so the "if" is never false
in practice. Assessed and left as-is: the sentence still describes a
real role action (look up R4 before freezing the path, rather than
assuming), and the routing-alternative clause is what actually matters
operationally regardless of whether the antecedent condition is
deterministic; no contract-text change made. Full record:
`docs/reports/2026-08-08-hunt-build-phase-boundary-hygiene.md`.

## Open findings

None outstanding.

## Next steps

None — delivery is complete pending PR merge (human decision).

## How it was verified

`grep -n` for the fixed phrases below in
`core/contract/role-handoff-contract.md` §19 returns a hit for both F1
and F2 (run and confirmed locally before commit):

- F1 phrase: "branch-writability check"
- F2 phrase: "PR-description-refresh"
