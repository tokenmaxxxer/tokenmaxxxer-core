---
kind: decision
subject: issue-56
produced_by: implementation
loop_state: decided
upstream:
  - path: docs/issue-56/proposals/s19-no-pr-refusal-tradeoff.md
    sha: 34749823e063a761ea43e1c7920070959c6d4191
---

# Decision: `s19`'s no-PR refusal is retired, not replaced (issue-56)

## Context

`s19`'s "What the gate blocks, mechanically" bullet stated that a role's
execution-surface write is refused "including while no PR exists at all,
which is what makes 'open the proposal PR first' enforced rather than
customary." Issue #53's approved, merged, tested design
(`approval-gate.sh`'s single-account path) resolves `approved` from an
issue-level `APPROVE issue-<n>/<role>` comment alone — a valid comment now
authorizes a write with zero PRs on the branch, confirmed by the
passing `issue-comment-approved-no-pr` test. The quoted sentence kept
claiming an enforcement the gate no longer performs; issue #53's own PR
body named this exact clause as left open for issue #56 to resolve.

## Decision — chosen: amend `s19` (and its duplicate in
`approval-gate.sh`'s header comment) to state the trade-off plainly

`core/contract/role-handoff-contract.md`'s `s19` bullet and
`core/hooks/approval-gate.sh`'s header comment now say, in their own
text: the no-PR refusal is retired once the single-account signal is a
live issue comment; why (the comment path resolves from the issue alone,
and the branch's two-PR practice makes a temporary no-PR gap between
phase 1's merge and phase 2's PR creation expected, not a denial); and
what bounds a role's work in that gap instead of a PR precondition — the
approved proposal's own frozen scope (`files:`, "What will be done" /
"Out of scope"), and the unconditional, separate per-PR merge decision a
human still makes before accepting any delivered work.

**Rejected alternative: restore an equivalent precondition** — require
that the branch has *ever* had a PR (`gh pr list --head <branch> --state
all` non-empty), denying a write when the issue carries a valid `APPROVE`
comment but no PR for that subject has ever existed. Rejected because it
is not a flag flip on existing code: `approval-gate.sh` would need a
third `gh` call beyond today's two, `run-approval-gate-tests.sh`'s
`stub_gh` has no way to express "never existed" distinctly from "existed,
now merged" (the exact distinction this option needs), and it would flip
the expected result of `issue-comment-approved-no-pr` — a test issue #53
shipped and passed days earlier — from allow to a conditional case. That
cost is disproportionate to a severity the issue's own body rates
"moderate, not a hole," and it reopens a design issue #53 deliberately
kept simple (its own precondition was added once, in response to a
warrant-hunt finding that a different guarantee — "closing the issue ends
approval" — was not mechanically true; nothing here shows the "ever had a
PR" guarantee is similarly load-bearing). The residual risk this
alternative would close — a human approver posting `APPROVE
issue-<n>/<role>` before any phase-1 PR exists — is a human-process
choice `s19`'s own "human's seat" framing already leaves to human
judgment, not a gap this mechanical gate is positioned to close.

**Also rejected: leaving the sentence as-is.** The issue's own
requirement is explicit — pick one with reasoning, do not leave the
sentence standing while the gate no longer implements it. That would be
the exact drift issue #53 was filed to end, reproduced one clause later.

## Effect

- `core/contract/role-handoff-contract.md`'s `s19` "What the gate blocks,
  mechanically" bullet states the retirement, its reason, and its
  replacement bounds in its own text.
- `core/hooks/approval-gate.sh`'s header comment (lines 7-13) mirrors the
  same statement; no change to the script's executable logic or to
  `core/hooks/tests/run-approval-gate-tests.sh` — this decision makes no
  behavioral change to verify.
- The rejected "branch has ever had a PR" precondition is not implemented;
  it remains available to revisit as its own issue if the failure signal
  below is ever observed.

**Failure signal.** If this decision is wrong, the signal is: a role
reaches phase-2 writes on a subject where a valid `APPROVE
issue-<n>/<role>` comment exists but no proposal PR for that subject has
ever existed, and the role's writes exceed its own (nonexistent) frozen
scope with no human catching it before or at merge time. That would mean
the frozen-scope-plus-merge-review compensating control this decision
relies on is not load-bearing in practice, and the rejected precondition
should be revisited.
