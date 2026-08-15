Subject: issue-189

---
status: proposed
files:
  - core/hooks/approval-gate.sh
  - core/contract/role-handoff-contract.md
  - warrant/hooks/state.sh
  - warrant/README.md
  - warrant/hooks/directive.sh
  - core/hooks/tests/run-role-gates-tests.sh
  - core/hooks/tests/deny-only-check.sh
  - docs/issue-189/reports/architecture.md
---

## Request

Design (phase-1 proposal; phase 2 builds after human Approve) the four
items the operator's 2026-08-16 issue comment re-graded as the
remaining, narrow negative-lifecycle scope, after confirming candidates
1-3 of the original four already shipped in PR #220 and this branch's
current tree (see `docs/issue-189/reports/architecture/survey.md`'s
2026-08-16 addendum for the confirming greps):

(a) consume the `state_reason` already fetched in `approval-gate.sh`
plus a permitted write path for a role to recommend one; (b) `WITHDRAW`
and `DEFER` canonical acts, composed from the already-shipped `REJECT`
token, not reinvented; (c) auto-expiry of stale open units to
`deferred` only, never `rejected`; (d) refresh the stale
`proposed -> approved -> landed` lifecycle comments in
`warrant/README.md:18` and `warrant/hooks/directive.sh:30`.

## Constraints

- Ride the existing comment-scan (`comment_matches`/`issue_comments` in
  `approval-gate.sh`) and existing object fields (`state_reason`,
  `updatedAt` from the `gh issue view --json` call already made) —
  **zero new polling**: no new background process, cron, or extra `gh`
  call beyond widening a field list already requested.
- **Lenient `state_reason` parsing**: an unrecognized or absent
  `state_reason` value is read as "no signal," never as an error or a
  denial — mirrors the fail-closed-only-on-genuine-unreadability
  posture `scope-gate.sh` already uses for unknown proposal statuses.
- Compose with what already shipped, don't reinvent: `WITHDRAW`/`DEFER`
  reuse `REJECT`'s exact-match/`approvers.md`-gated/`isMinimized`-skip
  machinery (the same `comment_matches` function, a third and fourth
  challenge string) — no new trust boundary, no new parsing surface
  class.
- `gh-guard.sh`'s human-only posture for `gh issue close/edit` and its
  raw-API equivalents is unchanged — no role session gains a new GitHub
  write capability. The "permitted write path" in (a) is a write to a
  role's own already-permitted record surface
  (`docs/issue-<n>/reports/<role>.md`, `write_scope`-routed), never a
  new `gh` call.
- Auto-expiry is read-only classification for reporting, never a status
  mutation — no gate may write `deferred` into a proposal file's
  `status:` field or a role's `loop_state` on a stale unit's behalf;
  only the acting role or the human triggers an actual state change.

## ADR

### Context

PR #220's step-1 discovery and this branch's own decisions 1-3 (survey
addendum) closed three of the original four gaps: proposal status
vocabulary, the canonical rejection token, and a `refused` `loop_state`
value with a mandatory finding pointer. Two things remain live: the
issue's own close-reason data is fetched and thrown away, and two
role-initiated acts symmetric to rejection — voluntary withdrawal and
postponement — have no token at all, unlike rejection's now-shipped
`REJECT`. Separately, two lifecycle-vocabulary comments in shipped docs
went stale the moment `withdrawn`/`rejected` landed and were never
updated to match.

### Decision

**1. `state_reason` consumption — reporting only, plus a recommendation
write path.**

`approval-gate.sh` already computes `issue_state_reason` (line 254) but
only ever uses `issue_state` for the hard `!= "OPEN"` denial (line
~240); that denial fires on closure regardless of reason and stays
unconditional — closing an issue for any reason ends the board, and
that check is correct as-is and is not touched. What changes:

- The denial message, when `issue_state != "OPEN"`, interpolates
  `issue_state_reason` when present (`"issue #%s is not open (state:
  %s, reason: %s)"`), so a session or human reading the refusal
  immediately knows shipped-vs-abandoned instead of parsing GitHub by
  hand. Absent/unrecognized `state_reason` (lenient parsing) falls back
  to the current message verbatim — no new failure mode on old data.
- `warrant/hooks/state.sh`'s `SessionStart` report adds `state_reason`
  to the same `gh issue view --json` field list it (or a sibling call)
  already makes, and labels a closed-with-`not_planned` subject
  distinctly from closed-with-`completed` in its open/closed-units
  summary (extends decision 5 of the already-merged full design:
  `docs/issue-189/proposals/2026-08-10-rejection-withdrawal-lifecycle-design.md`,
  which this narrow proposal's item (a) completes rather than
  restates).
- **The write path**: a role cannot post a close reason (`gh-guard.sh`
  unchanged), but it can — same as any other finding — write a
  `recommended_close_reason: completed|not_planned` line into its own
  record file, inside the `finding` block it already writes for a
  `verdict: contradicts`/`no-go`-shaped conclusion (contract §5's
  existing `finding` object gains one optional field, not a new kind).
  The orchestrator's conversational session (not gated by `gh-guard`,
  same relay pattern as `APPROVE`/`REJECT` today) reads that
  recommendation and, if the human agrees, issues the actual `gh issue
  close --reason` itself. No role ever calls `gh issue close`, with or
  without a reason, directly or via API — the write path is a record
  field, not a new tool grant.

**2. `WITHDRAW` and `DEFER` tokens, composed from `REJECT`.**

`approval-gate.sh` gains two more challenge strings built exactly like
`reject_challenge` (line 282):
```
withdraw_challenge = "WITHDRAW issue-%s/%s" % (issue_num, role)
defer_challenge = "DEFER issue-%s/%s" % (issue_num, role)
```
matched with the same `comment_matches()` (exact string, `approvers.md`
login, `isMinimized` skipped) already used for `challenge` and
`reject_challenge` — no new function, no new trust boundary. Semantic
distinction from `REJECT`, all three now symmetric:

| token | who acts | intent | contract §5 verdict |
|---|---|---|---|
| `REJECT` | reviewer | refuses the unit | `contradicts` (unchanged) |
| `WITHDRAW` | the role's own author-side act, posted by the human on the role's behalf when the role itself asks to stop (mirrors a human editing a proposal file to `status: withdrawn`, but for a role's *unit*, not a proposal file) | voluntary stop, no defect asserted | new: `withdrawn` |
| `DEFER` | either reviewer or author-side | postpone, resumable later | new: `deferred` |

Both produce a `finding`-shaped record exactly like `REJECT` does
today (same `requirement`/`evidence`/`rationale`/`addressed_to` shape),
with `severity: advisory` (not `blocking`) — withdrawal and deferral
are not defects being flagged, so they must not read as blocking
findings the way a `REJECT`'s `contradicts` does. `loop_state` gains
two more shared values in contract §2's preamble, next to `refused`:
`withdrawn` (terminal, paired with a `finding` pointer, same rule as
`refused`) and `deferred` (**not** terminal — a `deferred` unit is
explicitly resumable; a role or a later session may pick it back up,
unlike `withdrawn`/`refused`, which close the unit for good). This is
the one place this design adds new terminal-state test coverage
(`run-role-gates-tests.sh`, `deny-only-check.sh`) beyond what decision
3 of the already-merged full design already scoped for `refused` —
`withdrawn` needs the same red/green pair; `deferred` explicitly does
**not**, since it is non-terminal and terminal-spelling tests do not
apply to it.

**3. Auto-expiry — reporting-only, always to `deferred`, never
`rejected`.**

No new polling process: `state.sh`'s existing `SessionStart` open-units
pass already runs on every session start and already has (per decision
1 above) `updatedAt` available from widening the same `gh issue view`
call it already makes (or, for a proposal with no linked issue
activity, the file's last commit timestamp via `git log -1 --format=%ct
-- <path>`, already-available data, no new git call class). A unit
whose `status`/`loop_state` is still `proposed`/`approved`/in-flight
and whose most recent signal is older than a configured staleness
threshold (a `docs/specs/` config value, not hardcoded, mirroring
`hunt-guard.sh:85`'s `STALE_SECONDS` pattern for a different kind of
staleness in the same repo) is reported in `state.sh`'s output as
**`deferred (auto, stale since <timestamp>)`** — a report-only label
attached to the SessionStart message, never a write to the unit's own
`status:`/`loop_state` field. The one-way rule is deliberate: staleness
is evidence of "nobody has acted," which is exactly what `deferred`
means (postponable, resumable, no verdict reached) — it is never
evidence of a reviewer's refusal or an author's withdrawal, both of
which require an actual human act (decision 2's tokens, or a human
editing the proposal file). Auto-classifying a stale unit as `rejected`
would assert an intent nobody stated; `deferred` asserts only "no
recent activity," which is true by construction.

**4. Refresh the stale lifecycle comments.**

`warrant/README.md:18` and `warrant/hooks/directive.sh:30` both change
from:
```
status: approved          # proposed -> approved -> landed
```
to (README) and the matching one-line change in `directive.sh`'s
heredoc:
```
status: approved          # proposed -> approved -> landed
                           #   (or: withdrawn, rejected — see warrant/hooks/scope-gate.sh KNOWN_STATES)
```
Kept intentionally short and pointing at the source of truth
(`scope-gate.sh`'s `KNOWN_STATES` tuple) rather than inlining the full
five/six-state list a second place that can go stale again — the
original staleness (gap #8) was exactly two prose copies of a state
list drifting from the code that actually enforces it. `deferred` is
**not** added to this comment: it is a `loop_state` value (decision 2),
never a proposal `status:` value — the two vocabularies stay visibly
distinct in the doc that explains proposal status, matching the survey
addendum's "where vocabulary lives" finding that proposal `status` and
role `loop_state` are separate mechanisms and must not be conflated in
prose either.

### Consequences

- `state_reason` stops being dead data without granting any role a new
  GitHub write — the recommendation travels through the same
  record-then-relay path `APPROVE`/`REJECT` already use.
- `WITHDRAW`/`DEFER` complete the token family REJECT started, at the
  cost of two more string constants and two more `comment_matches()`
  calls in `approval-gate.sh` — no new machinery class.
- Auto-expiry adds one report line to an existing SessionStart message
  and one config value; it cannot regress into an enforcement path
  because it never writes, matching this design's explicit constraint.
- The doc refresh is two one-line edits; `KNOWN_STATES` remains the one
  place the full state list is spelled out.

### Alternatives considered

- **Let a role call `gh issue close --reason` directly, gated by an
  allowlist check similar to `APPROVE`'s.** Rejected: `gh-guard.sh`'s
  human-only posture for issue closure is a deliberate two-account
  boundary (contract v3 s8), not an oversight to route around; carving
  an exception for close-reason specifically reopens exactly the trust
  boundary decision 2's `REJECT` token was careful not to touch
  (`gh-guard.sh:85` unchanged, per that design's constraints). The
  record-then-relay path costs one more human step and keeps the
  boundary intact.
- **Auto-expiry writes `deferred` directly into the proposal file's
  `status:` or the role's `loop_state`.** Rejected: violates "state
  lives in the repository" as a *human/role* decision — an automated
  process silently rewriting a unit's recorded status is exactly the
  "null results read as failure" class of harm the whole issue is
  about, just inverted (a false status instead of a missing one). Kept
  strictly reporting-only.
- **One `EXPIRE` token instead of a passive stale-report.** Rejected:
  a token models a human or role *act*; staleness is the absence of
  one. Forcing a human to explicitly post `EXPIRE` on every unit that
  simply went quiet adds a step nobody asked for and duplicates what
  `state.sh` can already compute for free from data it fetches anyway.
- **A single `WITHDRAW_OR_DEFER` token disambiguated by trailing text.**
  Rejected: `REJECT`'s exact-match contract (whole comment body, no
  parsing beyond string equality) is the "measured lesson from the
  retired mint design" cited in `approval-gate.sh`'s own comments —
  reintroducing free-text disambiguation on top of a token is the same
  mistake in a new place. Two separate exact-match tokens keep that
  lesson intact.

## C4 boundary note

No container or component boundary moves. Everything here is vocabulary
and read-paths added inside two already-existing containers
(`core/hooks/` gates, `warrant/hooks/` gates), one already-existing
document (the contract), and two already-existing README/directive
files. The one "new" data flow — a role's own record file carrying a
`recommended_close_reason` field the orchestrator reads — reuses the
write_scope-routed record surface every role already writes to; no new
file kind, no new service, no new external dependency. The `updatedAt`
field used for auto-expiry comes from the same `gh` CLI call already
made for `state_reason`/`state`.

## Accumulation

This is the fourth vocabulary-extension pass on the same two enums
(`KNOWN_STATES`, `loop_state`) across this issue's own lifecycle
(emergency fix, decisions 1-3, now decisions 2/3 of this proposal). Each
pass adds a bounded, small number of fixed strings (this pass: 2 tokens,
2 `loop_state` values, 1 optional record field, 0 new files, 0 new
gates) — there is no per-instance growth (no per-role or per-kind
variants, per "alternatives considered" above), so the accumulation is
in enum *width*, not in file count or gate count. Current width after
this proposal: `KNOWN_STATES` stays at 5 (unchanged by this proposal —
`deferred` is deliberately a `loop_state` value only, per decision 4);
shared `loop_state` terminal-or-tracked values grow from 1 (`refused`)
to 3 (`refused`, `withdrawn`, `deferred`, the last non-terminal).
Bound: this proposal's decision 2 table is the last planned addition to
this family per the issue's own stated scope (WITHDRAW/DEFER complete
the REJECT/APPROVE-symmetric set the issue asked for); any further
token would need its own issue and its own gap evidence, not an
open-ended extension of this one.

## Out of scope

- Implementing the code changes above (phase 2, after human Approve).
- Re-litigating decisions 1-3 of the merged full design (status
  vocabulary, `REJECT` token, `refused` loop_state) — confirmed shipped,
  not reopened.
- Enforcement off `DEFER`/`WITHDRAW` (e.g. auto-pausing a role) beyond
  recognizing and recording the act — same deferral the original full
  design made for `CHANGES_REQUESTED` auto-enforcement, for the same
  reason: larger blast radius than this issue's acceptance criteria ask
  for.
- Configuring the actual staleness threshold value — a `docs/specs/`
  config decision left to phase 2 / the implementing role, not fixed
  here.
- #573's own repo/code — unreachable from here, unchanged from the
  original design's note.

## Effectiveness

Rides the same pre-registered hypothesis and metric step-1 already
registered (`docs/issue-189/reports/product-discovery/survey.md`'s
Acceptance section) — this proposal adds no new metric. What it adds to
that measurement's inputs: a `state_reason`-aware denial message and
`WITHDRAW`/`DEFER` tokens give step-4's 20-session measurement window
two more legible negative-outcome shapes to count against zero-false-
positive-brickings, instead of those sessions falling back to free-text
comments the existing metric can't parse.
