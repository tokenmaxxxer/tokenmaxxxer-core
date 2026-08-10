---
status: proposed
files:
  - core/contract/role-handoff-contract.md
  - core/hooks/approval-gate.sh
  - warrant/hooks/scope-gate.sh
  - warrant/hooks/state.sh
  - core/hooks/tests/run-role-gates-tests.sh
  - core/hooks/tests/deny-only-check.sh
  - core/hooks/tests/run-scope-gate-tests.sh
  - docs/issue-189/reports/architecture.md
---

## Request

Design (not yet build — this is the phase-1 proposal; build lands in
phase 2 after human Approve) the full rejection/withdrawal lifecycle
across the deployed surface, addressing step-1's four confirmed gaps and
findings #5/#7, aligned with on-the-record #573's merged verdict/finding
substrate. Phase-2 work will implement this design against the files
listed above.

## Constraints

- Must compose with #573's shapes, not parallel them: contract §5's
  `finding` object (`requirement`, `verdict`, `evidence`, `rationale`,
  `spec_vs_built`, `addressed_to`, `severity`) is the one finding shape;
  this design produces acts that *emit* that shape, never a second one.
- The `withdrawn` emergency fix (PR #191, already merged) is not
  reopened; `rejected` is added alongside it in the same tuple/enum
  style.
- No role session may itself post the rejection token or close an issue
  — `gh-guard.sh:81,85`'s human-only posture for GitHub write acts is
  unchanged; only *reading* surfaces (approval-gate.sh, state.sh) gain
  new parsing.
- New loop_state vocabulary is a contract §2 edit, not a
  `record-fields-terminal-states.json` override (see architecture
  survey's "where vocabulary lives" section) — that override file stays
  reserved for a repo promoting an existing state to terminal early.

## ADR

### Context

Step-1's audit (`docs/issue-189/reports/product-discovery/survey.md`)
confirmed the deployed surface encodes only the positive lifecycle path
in four places — proposal `status`, the approval token, `loop_state`, and
issue closure — plus three related gaps in reporting and PR-review
granularity. #573's rejection-issuing consumer (`verdict: contradicts` +
brokered remediation) is about to call into this substrate and needs a
rejection vocabulary to attach to.

### Decision

**1. Proposal status vocabulary — add `rejected`.**
`warrant/hooks/scope-gate.sh:39`'s `KNOWN_STATES` gains `rejected`
alongside the already-shipped `withdrawn`:
`KNOWN_STATES = ("proposed", "approved", "landed", "withdrawn",
"rejected")`. Same non-warrant treatment as `withdrawn` (readable,
known, never eligible for the `approved` write-set/trailer enforcement
branch). Distinction from `withdrawn`: `withdrawn` is author-initiated
(voluntary), `rejected` is reviewer-initiated (refused) — both are
proposal-file-level terminal states, and the file's own `## What did not
work`-adjacent prose or a reason line carries why; this design does not
require a new frontmatter field for the reason (see decision 2's `REJECT`
token, which is the machine-readable reason carrier for the case that
needs one — a role-session rejection, not a human editing their own
proposal file).

**2. Canonical rejection act — a `REJECT` token mirroring `APPROVE`, plus
reading `CHANGES_REQUESTED` as a first-class rejection.**
`core/hooks/approval-gate.sh` gains a second challenge string built the
same way as the existing one:
`reject_challenge = "REJECT issue-%s/%s" % (issue_num, role)`, matched
against issue comments the same way `comment_approved` is computed today
(exact-match, `approvers.md`-gated, `isMinimized` skipped) — this is the
single-account path, symmetric with `APPROVE`. For the two-account path,
the existing `last[login] = state` computation (line ~279) already
distinguishes `CHANGES_REQUESTED` from `DISMISSED`; the fix is to *use*
that distinction instead of discarding it: a login whose last state is
`CHANGES_REQUESTED` is a rejection act with the review body as its
`rationale`; a login whose last state is `DISMISSED` is a revoked opinion
with no rejection asserted (addresses step-1 finding #7 — these are
different human intents and were previously collapsed). Either path,
once recognized, is *not* a second record — it is the trigger that
produces one contract §5 `finding` block: `verdict: contradicts`,
`addressed_to: <role>`, `severity: blocking`, `rationale:` the review
body or the token's trailing reason text, `requirement`/`evidence`
filled from the artifact under review. This is the explicit composition
point with #573: the `REJECT` act (or `CHANGES_REQUESTED`) is the human
act that *produces* the finding #573 consumes; #573 never needs to
invent its own rejection-detection path — it reads the same `finding`
block contract §5 already defines.

**3. Board `loop_state` refusal vocabulary — one shared `refused` value.**
Contract §2 gains, in its preamble (not per-row duplication), a single
shared terminal value `refused`, usable in any kind's `loop_state`
column: "a role's `loop_state` may additionally be set to `refused` when
an external act — a `REJECT` token, a `CHANGES_REQUESTED` review, or an
equivalent human refusal — closes the role's current unit without the
role's own success-path terminal being reached. `refused` is always
paired with a pointer to the `finding` block (decision 2) that caused
it — a bare `refused` with no pointer is not a valid consumption of the
refusal (contract §6)." This is deliberately distinct from a role's own
negative verdict reached through its own judgment (e.g. feasibility's
`verdict: no-go`, qa's `wont-fix`) — those are the role concluding
something itself, not being refused by someone else, and keep their
existing terminal spellings unchanged. `refused` closes step-1 finding
#3 (the #476 "null results read as failure" class): a role stopped
because it was refused now has an exact vocabulary word for that, not
silence or an ad hoc value downstream gates won't recognize.
`run-role-gates-tests.sh`'s terminal-spelling coverage and
`deny-only-check.sh`'s forged-write probe both need a `refused` red/green
pair added in phase 2 (step-1 finding #6, confirmed as a coverage gap
here, not newly discovered).

**4. Issue `state_reason` — read, never written, by role-session gates.**
`approval-gate.sh`'s issue-state check (`issue_state != "OPEN"`, line
~240) and `warrant/hooks/state.sh`'s reporting both add `state_reason` to
the `gh issue view --json` field list they already call. `state_reason:
not_planned` on a closed issue is read as "this subject was rejected, not
shipped" — used only for reporting/routing (e.g. a gate refusing to treat
a `not_planned` issue's board as ever having been accepted), never as an
enforcement input, since closing an issue stays exclusively human
(`gh-guard.sh:85`, unchanged). This closes step-1 finding #4 without
granting any role a new write capability.

**5. `state.sh` reports closed-negative units, not just open ones**
(step-1 finding #5). The `open_units` filter
(`if status in ("proposed", "approved")`) stays as the *open*-unit
definition, but a new pass over the same directory collects `withdrawn`/
`rejected` proposals into a second, clearly-labeled section ("closed
(withdrawn/rejected) — history") in the SessionStart message. A fresh
session on a branch that already saw a withdrawal/rejection sees that
history instead of bare silence.

### Consequences

- Positive and negative lifecycle paths become symmetric across all four
  surfaces step-1 audited: proposal status, the approval/rejection token
  pair, `loop_state`, and issue closure semantics.
- `refused` is one new word added to an existing contract mechanism
  (§2's loop_state vocabulary, §6's consumption rule) — no new artifact
  kind, no new gate script, no new file layout.
- The `REJECT` token reuses `APPROVE`'s exact-match/allowlist/
  `isMinimized`-skip machinery verbatim (same function, parameterized by
  challenge string) — no new trust boundary, no new parsing surface
  class.
- Test debt named by step-1 (findings #6/#7) is scoped explicitly into
  phase 2's file list rather than left implicit.
- Downstream cost: every existing `loop_state` reader that pattern-matches
  a closed enumerated list (rather than checking "is this the kind's
  success terminal") must add `refused` to what it tolerates as
  terminal-and-known; `run-role-gates-tests.sh`'s existing per-kind
  `run_kind` harness (contract's terminal-state test pattern) is the
  right place, per decision 3.

### Alternatives considered

- **A rejected-state JSON override file instead of a contract §2 edit.**
  Rejected: `docs/specs/record-fields-terminal-states.json` promotes an
  *existing* vocabulary value to terminal; it has no mechanism for
  introducing a new value. Using it here would mean the value is
  "terminal" without ever having been declared valid — a gate parsing §2
  directly would still reject it. Survey section "where vocabulary lives"
  documents why this path doesn't actually work.
- **Per-kind `refused` variants (e.g. `feasibility-refused`,
  `coding-refused`) instead of one shared value.** Rejected: multiplies
  nine near-identical spellings for the same concept ("this role's unit
  was refused, not concluded"), and #573's consumer would need to match
  nine values instead of one. A shared value with a mandatory
  finding-pointer (decision 3) carries the same information — which kind
  it belongs to is already implicit in which record it appears on.
- **A new standalone `rejection` artifact kind (own file, own path),
  mirroring `finding`'s inline-block placement instead of reusing it.**
  Rejected: this is exactly the "second finding-shaped record living
  beside contract §5's" step-1's alignment-constraint section warned
  against avoiding. The `REJECT` token/`CHANGES_REQUESTED` read is the
  *act*; the `finding` block already defined by §5 is the *record*. No
  new kind needed.
- **Making `CHANGES_REQUESTED` auto-deny board writes the same way
  `scope-gate.sh` enforces `approved`.** Deferred out of this design:
  step-1's audit found no evidence this repo currently enforces anything
  off PR review state beyond `pr_approved`/deny, and adding enforcement
  (versus just recognizing/reporting the rejection) is a larger blast
  radius than this issue's stated acceptance criteria ask for. Left as an
  open question for phase 2 or a follow-up issue, not silently decided
  here.

## C4 boundary note

No container or component boundary moves. This design adds vocabulary and
read-paths inside two existing containers (`core/hooks/` gates,
`warrant/hooks/` gates) and one existing document (the contract) — no new
service, no new external dependency, no new data store. The one new
external-system read (`state_reason` field) is already exposed by the
`gh` CLI these gates already call; no new integration boundary is drawn.

## Out of scope

- Implementing the code changes above (phase 2, after human Approve).
- Auto-enforcement off `CHANGES_REQUESTED` (see alternatives-considered,
  last bullet) — left open, not decided.
- Re-litigating the already-merged `withdrawn` emergency fix.
- #573's own repo/code — unreachable from here; this design states the
  composition contract only, per step-1's own note that verification
  against #573's actual merged code is out of this repo's reach.

## Effectiveness (pre-registered, per step-1's hypothesis/metric)

Step-1's registered acceptance criterion: "Rejection gains a canonical
machine-readable act... with the alignment stated explicitly in the
design" (this document, decision 2) and a gate test parsing it (phase 2).
Step-4's measurement (out of this step's scope) checks: does a
`REJECT`/`CHANGES_REQUESTED` act, once phase 2 ships, produce a `finding`
block a downstream gate can parse without free-text triage — pass/fail
against the pre-registered threshold in step-1's Acceptance section,
measured against the empty-state rule already stated there (no
rejections yet → "no rejections", never an error).
