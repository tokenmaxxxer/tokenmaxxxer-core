---
status: proposed
kind: build-proposal
files:
  - core/contract/role-handoff-contract.md
  - docs/issue-155/reports/implementation.md
---

## Request

Issue #155 asks for two contract-text norms, both sourced from
`docs/issue-132/reports/execution-observation.md` Findings 1-2:

1. **F1** — before a phase-1 proposal freezes a `docs/issue-<n>/` path
   outside its own issue tree into its `files:` write set, the role must
   check whether its own branch (`issue-<n>/<role>`) can actually write
   that path under R4 (`core/hooks/board-gate.sh`'s branch rule), and if
   not, design a routing alternative in the proposal instead of freezing
   a path it cannot deliver.
2. **F2** — the phase-2 execute step must refresh the PR's title and body
   to describe what actually landed, for non-final delivery steps and for
   the title generally (the `#441`-series Closes-trailer norm already
   forces a body edit on the final step).

Whether either norm gets mechanical enforcement (a gate script) or stays
prose-only is left to this proposal's own cost judgment, per the issue's
Acceptance clause 3.

## Constraints

- Minimize collision with the landed `#441`-series gates
  (acceptance/pr_reference/contract-guard) and the open `#146` prose-vs-gate
  track — this proposal's write set is a single contract file plus this
  role's own record; no `core/hooks/*.sh` file is touched.
- No retroactive fix (issue-100 precedent, contract v3 §12 staleness
  rule) — issue-132's F2 delivery gap is not reopened or repaired here.

## Rationale

**Chosen approach: prose-only amendments to contract v3 §19, no new gate
script.**

Alternative 1 considered and rejected — mechanize F1 as a
`proposal-shape`-style PreToolUse gate that simulates R4 against every
`docs/issue-<m>/` entry in a proposal's frozen `files:` list at commit
time. Rejected because: the survey found this is only the class's 2nd
occurrence (issue-100, then issue-132); the issue's own acceptance
criterion explicitly permits a prose-plus-cost-judgment path instead of
mechanization; and a duplicate R4 simulation living in a second script
creates a drift risk (two places encoding the same branch-match rule)
that a single prose sentence in the same section as the proposal step
does not. Cost/shape recorded in `survey.md` under "Mechanization cost"
for a future proposal if the human wants it built instead.

Alternative 2 considered and rejected — mechanize F2 as a gate that reads
the live PR title/body via `gh pr view` at push or commit time and denies
if it still matches a phase-1-only shape. Rejected because every existing
hook in `core/hooks/` is a local-file gate (confirmed in the survey); a
network-calling hook is a new capability class for this repo's hook
layer, and the issue text itself narrows F2's live gap to the PR title
plus non-final delivery steps (the Closes-trailer norm already forces a
body edit on the final step) — a narrow prose requirement addresses the
actual remaining gap without adding that capability class.

**Failure signal if this proposal turns out wrong:** a third occurrence
of F1 (a phase-1 proposal freezing a foreign-issue path that R4 then
denies at execution time) after this section-19 sentence lands, or a
phase-2 delivery PR merging with an unrevised phase-1 title/body on a
non-final step after this section-19 sentence lands — either recurrence
is the signal that prose alone was insufficient and mechanization should
be revisited.

## What will be done

- [ ] Amend `core/contract/role-handoff-contract.md` §19's phase-1
  "propose" bullet (`:677-693`) to add a branch-writability check: before
  a proposal freezes any `docs/issue-<m>/` path where `m` differs from
  the subject issue `n`, the role checks that path against R4
  (`core/hooks/board-gate.sh`'s branch rule) and, if the branch cannot
  write it, designs a routing alternative in the proposal rather than
  freezing an undeliverable path. Text will be a fixed, grep-able phrase
  so the issue's own Acceptance check ("계약 phase-1 절에 write set
  브랜치-쓰기 검사 규범 문장이 존재") is satisfiable.
- [ ] Amend `core/contract/role-handoff-contract.md` §19's phase-2
  "execute" bullet (`:786-790`) to add a PR-description-refresh
  requirement: on landing, the role updates the PR's title and body to
  describe what phase 2 actually delivered, for every delivery step —
  the final step's Closes-trailer norm already forces the body; this
  closes the title and the non-final-step gap. Text will likewise be a
  fixed, grep-able phrase for the issue's second Acceptance check.
- [ ] Record the cost judgment for not mechanizing either norm in this
  proposal's own Rationale (above) and cross-reference it from
  `docs/issue-155/reports/implementation.md`'s doc-placement list once
  phase 2 opens, per Acceptance clause 3's "채택하지 않으면 제안
  Rationale 에 비용 판단 기록" branch.

## Out of scope

- Building the F1 or F2 gate script (see Rationale — deferred, shape
  recorded in `survey.md`).
- Reopening or repairing issue-132's own undelivered F2 (the count
  correction at `docs/issue-124/reports/implementation.md:321`) — that
  remains routed by issue-132's own record.
- Any change to `#441`-series or `#146`-track files.

## How you'll know it worked

- `grep -n` for the new fixed phrases in
  `core/contract/role-handoff-contract.md` §19 returns a hit for both F1
  and F2 — this is the exact check the issue's own Acceptance section
  specifies.
- `docs/issue-155/reports/implementation.md` exists at phase-2 landing,
  carries the mechanization-cost rationale, and cites the two amended
  line ranges.
