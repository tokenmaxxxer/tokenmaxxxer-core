---
status: proposed
files:
  - warrant/hooks/scope-gate.sh
  - core/hooks/approval-gate.sh
  - warrant/hooks/state.sh
  - core/contract/role-handoff-contract.md
  - core/hooks/tests/run-role-gates-tests.sh
  - core/hooks/tests/deny-only-check.sh
  - core/hooks/tests/run-scope-gate-tests.sh
  - docs/issue-189/reports/implementation.md
---

## Request

Build the rejection/withdrawal lifecycle design approved in PR #192
(`docs/issue-189/proposals/2026-08-10-rejection-withdrawal-lifecycle-design.md`):
`rejected` proposal state, a `REJECT issue-<n>/<role>` token symmetric
with `APPROVE`, the `CHANGES_REQUESTED`-as-rejection vs
`DISMISSED`-as-revoked read producing one contract §5 finding shape, a
shared `refused` loop_state value in contract §2's preamble, and the
`state.sh` closed-negative-units reporting fix, plus test coverage for
all of it.

## Constraints

- Every constraint from the approved design doc holds unchanged: reuse
  contract §5's one `finding` shape (never a second shape); `withdrawn`
  is not reopened; `gh-guard.sh`'s human-only write posture for GitHub
  acts is unchanged (this build only adds read-path parsing); `refused`
  is a contract §2 preamble edit, not a
  `record-fields-terminal-states.json` override.
- `REJECT`/`CHANGES_REQUESTED` recognition is read-only: it produces a
  `finding` block for a downstream reader to act on, never a write or an
  auto-deny of anything itself (design's explicit deferred item).

## Rationale

The design doc already resolved the architecture questions (finding
shape, vocabulary placement, token symmetry) after considering and
rejecting three alternatives (per-kind `refused` variants, a JSON
override for new vocabulary, a standalone `rejection` artifact kind).
This proposal's own choice is about build sequencing: land all five
write-set files in one phase-2 pass rather than splitting into
per-decision proposals. Alternative considered: one proposal per design
decision (5 proposals for 5 decisions). Rejected because the five edits
are mutually load-bearing in the same way #573's on-the-record noted for
verdict/finding — `refused`'s mandatory finding-pointer needs the
`REJECT`/`CHANGES_REQUESTED` finding-producing path to exist to be
testable at all, and `state.sh`'s closed-negative pass needs `rejected`
in `KNOWN_STATES` first; splitting would leave every proposal but the
first temporarily un-testable in isolation, adding review overhead
(4 more phase-1/phase-2 round trips) without changing what ships.

## What will be done

1. `warrant/hooks/scope-gate.sh:39` — add `"rejected"` to `KNOWN_STATES`.
2. `core/hooks/approval-gate.sh`:
   - Add `reject_challenge = "REJECT issue-%s/%s" % (issue_num, role)`,
     matched via the same exact-match/`approvers.md`-gated/
     `isMinimized`-skip function `comment_approved` already uses,
     parameterized by challenge string.
   - Use the existing `last[login]` state map: a login whose last state
     is `CHANGES_REQUESTED` and is in `approvers` is a rejection act
     (review body -> `rationale`); `DISMISSED` is read as revoked, no
     rejection asserted. Either path emits one contract §5 `finding`
     block (`verdict: contradicts`, `addressed_to: <role>`,
     `severity: blocking`), never a second finding shape.
     `last` (line ~275) is defined only inside `if pr_out.returncode ==
     0:` (line 267) — the new `CHANGES_REQUESTED`/`DISMISSED` read must
     be written inside that same guarded block (or against a `last =
     {}` default bound before the branch), never as an unconditional
     reference, so the no-PR-open case (line ~285's existing comment:
     "no PR open right now ... an expected gap, not itself a denial")
     stays a no-op instead of a `NameError` that the script's fail-
     closed EXIT trap would turn into a blanket deny of the still-valid
     comment-only `APPROVE`/`REJECT` path (after-proposal hunt finding,
     docs/reports/2026-08-10-hunt-implement-rejection-withdrawal-lifecycle.md).
   - Add `state_reason` to the existing `gh issue view --json` field
     list; read-only, used for reporting/routing only.
3. `warrant/hooks/state.sh` — add a second pass over
   `docs/proposals/` collecting `status in ("withdrawn", "rejected")`
   into a labeled "closed (withdrawn/rejected) — history" SessionStart
   section, alongside the existing open-units pass.
4. `core/contract/role-handoff-contract.md` §2 preamble — add the shared
   `refused` loop_state value (any kind, mandatory finding pointer, text
   as specified in the design's decision 3).
5. Test coverage: one red/green pair each in `run-role-gates-tests.sh`
   (`refused` terminal-state case), `deny-only-check.sh` (`REJECT`-token
   / `rejected`-state forged-write probe), `run-scope-gate-tests.sh`
   (`rejected` state handling).
6. Run all touched suites (plus the existing approval-gate test suite,
   read-only reference) before writing the phase-2 record.
7. Write `docs/issue-189/reports/implementation.md` per contract §20/
   record-shape-directive, dispatch the warrant-hunter per contract
   cadence, and reference this proposal + PR #192 as upstream.

## Out of scope

- Auto-enforcement off `CHANGES_REQUESTED` (design's own deferred item —
  left as an open question for phase 2 follow-up or a new issue).
- Any GitHub write act (issue close, PR merge) — stays human-only,
  unchanged.
- Re-litigating the merged `withdrawn` emergency fix (PR #191) or the
  architecture design itself (PR #192, already approved/merged).
- `#573`'s own repository/code — unreachable from here, per the design's
  own scope note.

## How you'll know it worked

- `scope-gate.sh` accepts a proposal with `status: rejected` the same
  way it accepts `withdrawn` (non-warrant, no enforcement branch).
- `approval-gate.sh`'s new red/green pair shows: an exact-match
  `REJECT issue-<n>/<role>` comment from an `approvers.md` account
  produces a rejection outcome; a near-match or unlisted-account comment
  does not; a `CHANGES_REQUESTED` review from an approver produces a
  `finding` block with `verdict: contradicts`; a `DISMISSED` review does
  not.
- `state.sh`'s SessionStart output shows a "closed (withdrawn/rejected)
  — history" section when such proposals exist on the branch, and shows
  nothing extra when none do.
- All three named test suites pass after the additions, run in this
  session before the record is written.
