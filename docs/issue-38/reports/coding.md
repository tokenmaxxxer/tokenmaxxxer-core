---
kind: coding-record
subject: issue-38
produced_by: coding
upstream:
  - path: docs/issue-38/proposals/2026-07-30-build-strip-residual-wake-routing.md
    sha: 674444b
loop_state: landed
---

## What was done

Audited every WAKES-ON/wake/routing mention in
`core/contract/role-handoff-contract.md` outside #36's write set (section
3, section 15), per `docs/issue-38/reports/coding/survey.md`. Stripped
role-summoning detail at the four flagged sites and repointed to
`docs/specs/wake-routing.md`, mirroring #36's own pattern:

- Line ~150 (ux-design DEPENDS-ON entry): dropped "after product" and
  "feeds coding on reaching `loop_state: reviewed`"; kept the structural
  requirement (a `ux-design-record` exists per subject and carries a
  WAKES-ON edge), now repointed.
- Lines ~162-163 (verify DEPENDS-ON entry): dropped "a blocking-finding
  channel back to coding"; kept "carries its own WAKES-ON edges" and
  "emits its blocking-finding channel per section 5", repointed.
- Line ~171 (reflect DEPENDS-ON entry): dropped "after verify/review
  conclude"; kept "carries its own WAKES-ON edge", repointed.
- Line ~187 (finding back-edge, section 5): dropped the stale citation to
  section 3's now-deleted per-role rows; restated as "findings addressed
  to a role are part of that role's WAKES-ON triggers", repointed.

## Proposal clause checklist

All five clauses from the build-proposal fulfilled by commit
(pending — see this record's own `loop_state`/commit sha once pushed):

- [x] Line 150 edit
- [x] Line 162-163 edit
- [x] Line 171 edit
- [x] Line 187 edit
- [x] Verification re-grep (see below)

## Why

Alternatives considered and rejected are recorded in the proposal
(`docs/issue-38/proposals/2026-07-30-build-strip-residual-wake-routing.md`):
a wholesale section-4 rewrite was rejected as broader than the four sites
the survey actually found; a generic "see the host's routing doc" phrasing
was rejected in favor of the concrete `docs/specs/wake-routing.md` path
#36 already established.

## Verification

`grep -n "WAKES-ON\|wakes\|Wakes\|wake"
core/contract/role-handoff-contract.md` re-run after the edit: every
remaining hit is either a repoint to `docs/specs/wake-routing.md`
(lines ~91-93, ~150, ~163, ~172, ~189, ~522) or pure record/visibility
semantics with no destination role named (the rest) — matches the
survey's classification table with no new gaps introduced. No other file
touched.

## What did not work

Nothing — the four sites matched the survey's prediction exactly; no
false starts.

## Basis for a next reader

- Upstream: this record's own proposal and survey (shas above).
- `loop_state: landed` — no open findings on this subject.
- No next-steps backlog: the audit is complete per the proposal's "how
  you'll know it worked" criterion, self-checked above.
