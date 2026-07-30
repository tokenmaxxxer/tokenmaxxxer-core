---
kind: build-proposal
subject: issue-53
produced_by: coding
upstream: []
loop_state: scope-proposed
---

# Proposal: make the issue comment the canonical approval location

files:
- core/contract/role-handoff-contract.md
- core/hooks/approval-gate.sh
- core/hooks/tests/run-approval-gate-tests.sh

## Request (paraphrased intent)

Issue #53: the contract text (`role-handoff-contract.md`), the
enforcement gate (`approval-gate.sh`), and observed practice (`0800649`,
issue-46/PR#47) already disagree about where a single-account Approve
signal lives — PR comment per the contract's own text, PR-only per the
gate, issue comment per practice. The PR-only reading cannot survive the
measured two-PR-per-issue workflow: phase 1's proposal PR merges and
closes, phase 2 opens a new PR on the same branch, and a `gh pr view
<branch>` lookup at that point resolves to the new PR, which never saw
the old PR's approval comment. Move the canonical single-account signal
to the issue (the one anchor stable across both PRs), update the gate to
read it, and — the requirement this proposal treats as its core
deliverable — state explicitly what scope one such comment authorizes and
how a human revokes it, rather than leaving that to the gate's incidental
behavior.

## Constraints

- Two-account mode (PR review Approve) is unchanged — still PR-scoped,
  still requires an approver account different from the PR author.
- `gh` failing or being unreachable still denies (fail-closed, unchanged
  from today's header-comment invariant).
- No change to `core/contract/role-handoff-contract.md` sections 3, 4, 5,
  7, or 15 — that text is core issues #36/#38's own territory (wake-
  routing prose); this proposal touches only section 10's "Human
  decisions are GitHub acts" bullet and section 19's "Single-account
  mode" bullet, and neither #36 nor #38 has an open PR as of this survey
  (`gh pr list --state open` → `[]`), so there is nothing to rebase
  against yet — recorded as a coordination note, not resolved here, since
  merge order between these issues isn't this proposal's call.
- `on-the-record`'s `run.md`/`README.md`/`protocol.md` are out of this
  write set entirely — different repository, not reachable from this
  branch (see survey.md's unknowns).
- The write set does not widen beyond the three files above.

## What will be done

**1. `core/contract/role-handoff-contract.md`, section 10** (replacing
lines 324-331, the sentence starting "The one structural exception..."
through "...an issue comment is never approval provenance."):

> The one structural exception is section 19's single-account path: an
> issue-level comment — posted on the subject's issue (`issue-<n>`), not
> on any PR — whose entire body is the exact string `APPROVE
> issue-<n>/<role>`, posted by an `approvers.md` account, is a mechanical
> string match, not textual inference — free-text approval commentary of
> any other shape remains categorically rejected. This is the one signal
> that lives on the issue rather than the PR: contract v3's own practice
> produces two PRs per subject/role (phase 1's proposal PR, then phase
> 2's build PR, opened after phase 1's PR has already merged and closed —
> section 19), and the issue is the one anchor stable across both.
> Feedback, acceptance, and refusal comments stay attached to the PR
> under review, exactly as before; only this one Approve signal is
> issue-attached.

**2. `core/contract/role-handoff-contract.md`, section 19** (replacing
the "Single-account mode" bullet, lines 670-685):

> - **Single-account mode.** When the PR author and the approver are the
>   same GitHub account (the default setup — section 10 — under which
>   GitHub structurally forbids a review Approve on your own PR), an
>   issue-level comment — posted on issue `<n>` itself, never on a PR —
>   whose entire body is the exact string `APPROVE issue-<n>/<role>` —
>   this role's own subject and role name, verbatim, nothing else in the
>   comment — posted by an account listed in `docs/specs/approvers.md`,
>   is a valid phase-2 approval. The issue, not the PR, is the anchor:
>   this role's own two-PR-per-subject practice (phase 1's proposal PR
>   merges and closes before phase 2's build PR opens) means a PR-scoped
>   comment on PR A is invisible to a gate resolving PR B once A is
>   closed; the issue survives both PRs, so it is the only location one
>   comment can authorize both phases from. String equality, never prose
>   interpretation; an agent account's comment never counts, listed or
>   not, since agent accounts are never in `approvers.md` (section 8).
>   This closes the comment-vs-review discrepancy recorded in the muster
>   issue-31 and issue-38 rounds, and the PR-vs-issue location discrepancy
>   recorded in issue-53: verify's strict review-only reading,
>   coding/qa/review's comment-accepting reading, and on-the-record's
>   issue-canonical reading now converge on this text.
>
>   **Scope.** One `APPROVE issue-<n>/<role>` comment authorizes every PR
>   opened on the `issue-<n>/<role>` branch, past and future, for as long
>   as the comment stands — not only the PR open at the moment the
>   comment was posted (phase 2's PR typically does not exist yet when
>   phase 1 is approved), and not a separate approval per phase (section
>   19 defines one gate transition, `scope-proposed` -> `scope-approved`;
>   a per-phase split would add a second human judgment point this
>   contract does not otherwise require). This is deliberately
>   branch-wide rather than PR-specific: `issue-<n>/<role>` already names
>   exactly one role working exactly one issue (section 10, never
>   shared), so "every PR on the branch" is the same unit of work the
>   human already approved, not a wider one.
>
>   **What this does and does not authorize.** A role opening a later PR
>   on an already-approved branch does not need a human to have seen that
>   PR's specific diff before starting the work — unchanged from the
>   PR-scoped model's own "later entries are unaffected" rule (below);
>   moving the signal to the issue does not create this, it only lets it
>   survive the branch's second PR. What still bounds the work is (i) the
>   approved proposal's own stated scope (`files:`, `## What will be
>   done` / `## Out of scope`) — a role exceeding it is a violation of
>   its own rulebook's scope discipline, not something this gate checks
>   mechanically — and (ii) the merge decision on every PR, unconditional
>   and separate from the Approve, where the human reviews the actual
>   diff before accepting it. The Approve authorizes doing the work; the
>   merge accepts its result — that division, not a second approval, is
>   this contract's answer to a changed artifact needing a fresh look.
>
>   **Revocation.** Deleting or editing the `APPROVE issue-<n>/<role>`
>   comment away ends the authorization for any gate check after that
>   point (unchanged from the PR-comment model, re-anchored to the
>   issue). Closing the issue ends it unconditionally and independently
>   of the comment — mechanically, not just as a stated norm: the gate
>   checks the issue's open/closed state before either approval path (see
>   `approval-gate.sh` below), so a closed issue denies phase-2 work of
>   any kind regardless of any standing comment or PR review.
>
>   A role recording provenance for this signal must cite the issue
>   comment (its URL or comment id), never a PR — a PR comment is never
>   approval provenance for the single-account path.

**3. `core/hooks/approval-gate.sh`.** Replace the single `gh pr view
<branch> --json reviews,comments` call (current lines 202-255) with an
issue-state precondition and two independent approval lookups:

- **Issue-state precondition (closes a hunt finding — see below): `gh
  issue view <issue-num> --json state,comments` — checked FIRST, before
  either approval path.** If this call fails (gh unreachable, auth
  broken), hard deny: the issue is the canonical anchor now, so its own
  unavailability cannot be waved through. If it succeeds and `state !=
  "OPEN"`, deny unconditionally — a closed issue's board is not live for
  any role (section 8/9), and this must hold regardless of which
  approval path would otherwise satisfy the gate, not only the
  single-account one. This is what makes the contract text's "closing
  the issue ends it unconditionally" claim (item 2 below) an actual
  mechanical guarantee instead of prose the gate doesn't implement — a
  warrant-hunter pass on this proposal caught exactly this gap: the
  originally-drafted gate design fetched comments only, never state, so
  a closed issue with an untouched `APPROVE` comment would have still
  evaluated `approved = True`.
- **Two-account path (unchanged in spirit), run only once the issue-open
  check passes:** `gh pr view <branch> --json reviews` — if this
  resolves (a PR is currently open), the existing "last review per
  author wins" logic decides `approved` exactly as today. If no PR is
  open right now, this path is simply unavailable (not itself a denial)
  — the branch's two-PR practice makes "no PR open at this instant" an
  expected state between phase 1's merge and phase 2's PR creation.
- **Single-account path (the fix):** derive the issue number from the
  branch regex already in use (`^issue-([0-9]+)/(.+)$`, capturing both
  groups instead of today's issue-number-discarding `[0-9]+`), then scan
  the `comments` field already fetched in the issue-state call above for
  an `approvers.md` author whose comment body is exactly `APPROVE
  issue-<n>/<role>` — no second `gh issue view` call needed, since
  `state` and `comments` are fetched together.
- `approved = <two-account result> or <single-account result>`, only
  reached once the issue-open precondition has passed; deny when both
  are false, with a message naming both surfaces checked and both
  approver-account and branch/issue identifiers, mirroring today's
  existing deny-message style.
- Update the header comment (lines 22-27) to describe the issue-state
  precondition and both approval `gh` calls instead of the current
  single-call description.

**4. `core/hooks/tests/run-approval-gate-tests.sh`.** The `stub_gh`
helper currently emits one static response regardless of the arguments
`gh` is invoked with, because only one gh call site exists. It must
become argument-aware (branch on whether it's invoked as `pr view ...
--json reviews` vs `issue view ... --json comments`, e.g. by reading
`"$@"` inside the generated stub script) so PR-review outcome and
issue-comment outcome can be set independently per test case. New cases
to add, alongside the existing matrix:
- `issue-comment-approved-no-pr`: `nopr` PR state + a valid issue comment
  → allow (the core two-PR-workflow fix: this is the scenario that fails
  under today's code).
- `pr-review-approved-no-issue-comment`: two-account path alone → allow
  (regression guard: two-account mode must keep working unmodified).
- `issue-comment-agent`, `issue-comment-prose`: issue-side equivalents of
  the existing `comment-challenge-agent`/`comment-prose` PR-side cases →
  deny.
- `neither-surface`: no PR review, no issue comment → deny.
- `closed-issue-with-comment`: issue `state: CLOSED` + an otherwise-valid
  `APPROVE issue-<n>/<role>` comment present → deny (the issue-state
  precondition added after the warrant-hunt finding; without this case
  the gap the hunter found would go unregressed by the test suite too).
- `closed-issue-with-pr-review`: issue `state: CLOSED` + a valid
  two-account PR review APPROVED → deny (the precondition applies to
  both paths equally, not just the single-account one).
- Existing `comment-challenge`/`comment-challenge-agent`/`comment-prose`
  cases (currently PR-comment-based) move to the issue-comment stub path,
  since the single-account signal no longer lives on the PR at all; the
  stub's default issue `state` for every existing case is `OPEN` unless a
  case says otherwise, so the precondition doesn't change any existing
  case's expected outcome.

## Out of scope

- `on-the-record`'s `run.md`, `README.md`, `protocol.md` — a different
  repository; flagged for that repo's own follow-up, not touched here.
- Sections 3, 4, 5, 7, 15 wake-routing prose — core issues #36/#38's own
  target text; no overlap in lines with this proposal's edits (see
  Constraints). If either lands first, this proposal's diff still applies
  cleanly since it never touches their lines; if this lands first, same
  in reverse.
- Two-account PR-review-Approve semantics: unchanged, still PR-scoped.
- Any new revocation *mechanism* beyond documenting the two paths that
  already exist structurally (comment deletion/edit, issue closure) —
  no new hook, no new state field.
- A `docs/decisions/<date>-issue-comment-approval-scope.md` (or
  `docs/issue-53/decisions/...` — see survey.md's unknowns) record of
  the scope-model choice itself, per contract section 21's hard-to-
  reverse-choice rule: added in phase 2 alongside the code, not decided
  down to the exact path in phase 1.

## Alternatives considered

1. **Keep both PR-comment and issue-comment as valid single-account
   locations (superset, not a move).** Rejected: the issue's own title
   asks for *the canonical* location (singular), and with zero PRs
   currently open repo-wide (confirmed in survey.md), nothing in flight
   depends on the old PR-comment path — keeping both would maintain two
   parallel signals with independent revocation semantics for no
   compensating benefit.
2. **Scope models (b) "only PRs open at comment time" and (c) "a
   separate approval per phase."** (b) is rejected because phase 2's PR
   does not exist yet when phase 1's Approve is posted — a comment-time-
   only scope would make phase 2 permanently unapprovable, which is the
   exact failure this issue exists to fix. (c) is rejected because
   section 19 already defines exactly one gate transition
   (`scope-proposed` -> `scope-approved`); splitting it into two
   per-phase approvals adds a second human judgment point the contract
   does not otherwise have, where the human's actual per-diff check
   already exists independently at merge time (see "What this does and
   does not authorize" above).

## Failure signal

If this proposal is wrong, the signal is: a role's phase-2 PR (the
second PR on a two-PR issue) still gets denied by `approval-gate.sh`
even though the issue carries a valid `APPROVE issue-<n>/<role>` comment
from a listed approver — i.e. the exact bug #53 reports reproduces again
after this lands.

## How success will be judged

- `rg -n "never the issue" core/contract/` → 0 hits.
- `approval-gate.sh` allows when the issue carries the exact-string
  comment and no PR is open (new test: `issue-comment-approved-no-pr`).
- `approval-gate.sh` allows when a PR review is APPROVED and no issue
  comment exists (new test: `pr-review-approved-no-issue-comment`,
  guards two-account mode against regression).
- `approval-gate.sh` denies when neither surface carries the signal, and
  when the issue comment is agent-authored or free-text prose (new
  tests, mirroring existing PR-side deny cases).
- `approval-gate.sh` denies when the issue is closed, regardless of a
  valid PR review or a valid issue comment (new tests
  `closed-issue-with-comment` / `closed-issue-with-pr-review` — this is
  the fix for the warrant-hunt finding recorded in
  `docs/reports/2026-07-30-hunt-issue-comment-approval-scope.md`).
- The scope model (branch-wide, until the comment is deleted/edited or
  the issue is closed) is stated in section 19's own text, and the
  issue-closed half of it is mechanically enforced by the gate, not left
  to the gate's behavior to imply.
- `bash core/hooks/tests/run-all.sh` passes.

## Warrant hunt (phase 1)

A warrant-hunter pass against this proposal's original draft found that
the described gate design fetched issue comments but never issue state,
so the contract text's "closing the issue ends it unconditionally" claim
was not actually mechanically true of the design as first written — see
`docs/reports/2026-07-30-hunt-issue-comment-approval-scope.md`. Resolved
in this revision by adding the issue-state precondition (`--json
state,comments` fetched together, checked before either approval path)
and two new test cases; both are reflected in "What will be done" item 3
and "How success will be judged" above.
