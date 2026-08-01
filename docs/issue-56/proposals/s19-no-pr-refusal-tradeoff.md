---
kind: build-proposal
subject: issue-56
produced_by: implementation
upstream: [issue-53]
loop_state: scope-proposed
---

# Proposal: state the trade-off `s19`'s retired no-PR refusal left implicit

files:
- core/contract/role-handoff-contract.md
- core/hooks/approval-gate.sh
- docs/decisions/2026-08-01-s19-no-pr-refusal-retired.md

## Request (paraphrased intent)

Issue #56: `s19`'s "What the gate blocks, mechanically" bullet still claims
that a role's execution-surface write is refused "including while no PR
exists at all, which is what makes 'open the proposal PR first' enforced
rather than customary." Issue #53's approved, merged, tested design
(`approval-gate.sh`'s single-account path) retires that refusal — an issue
comment alone can satisfy `approved` with zero PRs on the branch — and
#53's own PR body says so explicitly, naming this exact clause as left for
issue #56. Pick one of the issue's two options (restore an equivalent
precondition, or amend the sentence to state the trade-off) with reasoning,
and record the choice under `docs/decisions/` per `s21`.

## Constraints

- Phase 1 only: this proposal and its survey/scout-brief are the sole
  output of this session; no code or contract edits happen until a human
  Approve opens phase 2.
- The contract edit stays inside `s19`'s "What the gate blocks,
  mechanically" bullet (`role-handoff-contract.md:755-763`) — no edit to
  `s8`, `s10`, or `s19`'s other bullets, which #53 already resolved (`rg -n
  "never the issue" core/contract/` → 0 hits, confirmed unaffected by this
  change).
- `core/hooks/approval-gate.sh` gets a header-comment edit only (lines
  7-11) — no change to the executable `python3` heredoc, no change to
  `core/hooks/tests/run-approval-gate-tests.sh`. The chosen option (below)
  makes no behavioral change, so nothing in the gate's logic or test matrix
  needs to move.
- `docs/decisions/` (repo-standing bucket) is the target for the required
  decision record, per `s21`'s literal text and issue #56's own explicit
  instruction — not `docs/issue-56/decisions/`. The survey notes this
  diverges from this session's own role-directive prose, which names the
  per-issue bucket; that discrepancy predates this issue (already flagged,
  unresolved, in `docs/issue-53/reports/coding/survey.md`) and is not this
  proposal's to fix.

## Rationale

**Chosen: the issue's Option 2 — amend the sentence, state the trade-off.**
Retire the "enforced rather than customary" claim from both sites the
survey found (`role-handoff-contract.md:755-763` and
`approval-gate.sh:7-11`), state plainly why (the single-account path
resolves from the issue alone, with no reference to PR existence; the
branch's two-PR practice makes a temporary no-PR gap expected, not a
denial), and name what bounds phase-2 work instead (the approved
proposal's own frozen scope, and the unconditional per-PR merge decision).

**Rejected: the issue's Option 1 — restore an equivalent precondition**
(`gh pr list --head <branch> --state all` non-empty, i.e. "the branch has
ever had a PR"). The survey (section 5) found this is not a flag flip on
existing code: `approval-gate.sh` would need a third `gh` call beyond
today's two; `run-approval-gate-tests.sh`'s `stub_gh` currently expresses
only one open/closed dimension (`pr_ok`) and has no way to distinguish
"never existed" from "existed, now merged" — the exact distinction Option 1
needs; and it would flip the expected result of
`issue-comment-approved-no-pr`, a specific test #54 shipped and passed two
days ago, from allow to a conditional case. That is disproportionate to a
severity the issue's own body already rates "moderate, not a hole," and it
re-opens a design #53 deliberately kept simple (per the scout-brief: #53
added a precondition only once, in response to a warrant-hunt finding that
an actual guarantee — "closing the issue ends approval" — was not
mechanically true; nothing here shows the "ever had a PR" guarantee is
similarly load-bearing today). Nothing currently depends on it (survey
section 3): the residual risk it would close is a human approver choosing
to post `APPROVE issue-<n>/<role>` before any phase-1 PR exists, which is a
human-process choice `s19`'s own "human's seat" framing already leaves to
human judgment, not a gap this specific mechanical gate is positioned to
close.

**Also rejected: doing nothing.** The issue's requirement is explicit —
"Pick one with reasoning — do not leave the sentence standing while the
gate no longer implements it." Leaving the sentence as-is is the exact
drift #53 was filed to end, reproduced one clause later.

## What will be done

- [ ] **Clause 1** — `core/contract/role-handoff-contract.md:755-763`
  ("What the gate blocks, mechanically"): replace the current bullet with:

  > - **What the gate blocks, mechanically.** The execution surface is
  >   `src/`, `test/`, and everything under `docs/issue-<n>/` EXCEPT the
  >   two phase-1 homes — `proposals/**` and the role's own research
  >   subtree `reports/<role>/**`. A role session's writes to that surface
  >   are refused while its `issue-<n>/<role>` subject lacks one of the two
  >   Approve signals above. Once the single-account signal is live as an
  >   issue comment, this refusal no longer requires a PR to be open, or to
  >   have ever existed at all — the comment path (above) resolves from the
  >   issue alone, and the branch's two-PR practice makes "no PR open right
  >   now" an expected gap between phase 1's merge and phase 2's PR
  >   creation, not a denial (see the two-account path above, and
  >   `core/hooks/approval-gate.sh`). This retires an earlier claim that
  >   "open the proposal PR first" was mechanically enforced rather than
  >   customary; it no longer is, once an Approve signal is live. What
  >   still bounds a role's work in that gap is not a PR precondition: it
  >   is the approved proposal's own frozen scope (`files:`, "What will be
  >   done" / "Out of scope" above) — a role exceeding it is a rulebook
  >   violation this gate does not check mechanically — and the
  >   unconditional, separate merge decision on whatever PR the work
  >   eventually reaches, where a human reviews the actual diff before
  >   accepting it. The record file `reports/<role>.md` is on the
  >   execution surface: a document-producing role's deliverable waits for
  >   the Approve exactly as code does.

- [ ] **Clause 2** — `core/hooks/approval-gate.sh:7-11` (header comment,
  not logic): replace with:

  > \# Deny-only rule: a role session's write to the EXECUTION SURFACE is
  > \# refused while the role's issue-<n>/<role> subject lacks an Approve
  > \# signal authored by an account listed in docs/specs/approvers.md.
  > \# Once the single-account signal is a live issue comment, this
  > \# refusal does not require a PR to be open or to have ever existed —
  > \# the comment path resolves from the issue alone (below); a role's
  > \# frozen proposal scope and the unconditional per-PR merge decision
  > \# bound the work instead (contract v3 s19).

- [ ] **Clause 3** — `docs/decisions/2026-08-01-s19-no-pr-refusal-retired.md`
  (new file, per `s21`'s hard-to-reverse-choice rule and issue #56
  requirement #3): states chosen (Option 2 — amend `s19` to state the
  trade-off) over (Option 1 — restore an ever-had-a-PR precondition), and
  why (per Rationale above: disproportionate cost and regression risk
  against a severity already rated moderate, and no current dependency on
  the retired guarantee).

## Out of scope

- Option 1's gate-logic and test-matrix changes — not implemented under
  this proposal; recorded as the rejected alternative in Clause 3's
  decision doc, available to revisit as its own issue if the failure
  signal below is ever observed.
- `core/hooks/tests/run-approval-gate-tests.sh` — no edit; the chosen
  option makes no behavioral change to verify.
- `on-the-record`'s own docs (`run.md`, `README.md`, `protocol.md`) — a
  separate repository, not reachable from this branch (same boundary
  #53's survey already recorded).
- `core/contract/role-handoff-contract.md` sections 8 and 10 — already
  resolved by #53, zero remaining "never the issue" text; not reopened.
- Resolving the `docs/decisions/` vs. `docs/issue-<n>/decisions/`
  discrepancy between `s21`'s literal text and this session's own
  role-directive prose — pre-existing, flagged in `docs/issue-53/reports/coding/survey.md`,
  not this issue's territory.

## How you'll know it worked

- `rg -n "enforced rather than customary" core/` → 0 hits.
- `rg -n "including while no PR exists at all" core/` → 0 hits.
- `bash core/hooks/tests/run-all.sh` → unchanged pass result (proves the
  doc-only edit made no behavioral change — it did not silently reopen or
  narrow what #54 already shipped and tested).
- `docs/decisions/2026-08-01-s19-no-pr-refusal-retired.md` exists and
  states chosen/over/why.
- The new `s19` bullet states, in its own text, the three things issue #56
  requirement #2 asks for by name: that the no-PR refusal is retired, why
  (the phase-1-merge/phase-2-open gap and the issue-only comment path),
  and what bounds the work instead (frozen proposal scope, unconditional
  merge decision).

**Failure signal.** If this proposal is wrong, the signal is: a role
reaches phase-2 writes on a subject where a valid `APPROVE
issue-<n>/<role>` comment exists but no proposal PR for that subject has
ever existed, and the role's writes exceed its own (nonexistent, since no
proposal was ever reviewed) frozen scope with no human having caught it
before or at merge time. That would mean the frozen-scope-plus-merge-review
compensating control this proposal relies on is not actually load-bearing
in practice, and Option 1's mechanical precondition should be revisited.
