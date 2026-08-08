---
subject: issue-66
role: architecture
loop_state: scope-proposed
---

# Proposal — architecture record for the role-agnostic canon boundary (issue-66)

See `docs/issue-66/reports/architecture/survey.md` for the full current-state
survey this proposal is built on.

## Context

Implementation (PRs #67/#68, merged) already promoted the four role-agnostic
files (`trailer-gate.sh`, `record-fields-gate.sh`, `handbook-trigger-gate.sh`,
`directive.sh`'s boilerplate half) to `core/hooks/`, wired them core-side in
`hooks.json`, and shipped a drift detector (`stub-check.sh`). What is missing
is (a) the architecture-level record of that boundary decision — a
rulebook's own tree should never re-derive role-agnostic gate logic, only
supply role-unique config/values — and (b) closing the acceptance-criterion
gap the survey found: the issue's check names `compliance-check.sh` gaining
a canon-duplication scan "runnable against an arbitrary rulebook path," and
that scan does not exist yet as specified (`stub-check.sh` is a different,
narrower script, invoked per-rulebook rather than from this repo).

## Decision (to record as ADR in phase 2)

1. **Component boundary**: core canon owns all role-agnostic gate/hook
   *logic*; a rulebook owns only role identity (`CLAUDE_ROLE` env) and its
   four `directive.sh` role-unique values. No rulebook-local file may
   re-implement logic that already has a core canon home — presence of such
   a file is itself the defect, not a stylistic choice.
2. **Dependency direction**: rulebooks depend on core canon (via
   `${CLAUDE_PLUGIN_ROOT}/hooks/*` resolution and `source
   core/hooks/lib/role-directive.sh`), never the reverse. Core canon carries
   no per-rulebook branching beyond the `CLAUDE_ROLE` string itself.
3. **Close the acceptance gap**: extend `core/hooks/tests/compliance-check.sh`
   with a canon-duplication scan callable as
   `compliance-check.sh --canon-duplication <rulebook-path>`, reusing
   `canon-manifest.txt` (already the source of truth for `stub-check.sh`'s
   gate list) so the two scripts cannot drift against each other. This
   satisfies the issue's literal acceptance check from this repo, rather
   than relying solely on `stub-check.sh` being invoked per-rulebook.
4. **#63 stays separate**: per the survey verdict, #63 is not absorbed. Its
   canon promotion (warrant-hunter definition + hunt-cadence protocol) is
   its own component with its own payload; only the *rollout batching*
   (touching the same 43 repos once instead of twice) is shared, and that
   is a scheduling note for the rollout doc, not a scope merge. #63 keeps
   its own issue, its own phase-1/phase-2 cycle.

## Rollout path (documentation deliverable, phase 2)

Add `docs/handbooks/canon-rollout.md` (or extend the existing
`docs/handbooks/canon-scripts.md` referenced by `stub-check.sh`) describing,
per sibling rulebook repo:
1. Delete the five vendored files if present.
2. Point `hooks.json` at core (remove any local entry for the four
   registered gates; core fires them globally already).
3. Reduce local `directive.sh` to source + `core_role_directive` call.
4. Run `stub-check.sh` and the new `compliance-check.sh
   --canon-duplication` scan against the rulebook to confirm zero divergent
   copies.
5. Batch step 1–4 together with issue-63's warrant-hunter rollout when #63
   ships, since both touch the same 43 repos with the same
   reference-not-vendor mechanism (scheduling efficiency only — see
   decision 4 above for why this is not scope absorption).

## Alternatives considered

- **Leave `compliance-check.sh` gap unaddressed, treat `stub-check.sh` as
  sufficient**: rejected — the issue's acceptance text explicitly names
  `compliance-check.sh` as the check surface; `stub-check.sh` alone leaves
  the literal acceptance criterion unmet and gives no single-command way
  for this repo to audit an arbitrary external rulebook path.
- **Merge #63 into #66's write scope now to shortcut the "batch rollout"
  note into one issue**: rejected — #63 has undelivered scope of its own
  (time/token measurement, an efficiency-protocol redesign, a side-effect
  catch-class audit) that #66 never touched; forcing it under #66 would
  either drop that scope or scope-creep #66 past what was asked.
- **Per-rulebook config file (e.g. a canon-version pin) instead of
  file-presence/structure detection**: rejected at this stage — adds a new
  artifact type to maintain across 43 repos for a problem `stub-check.sh`
  already solves by absence/structure convention; revisit only if that
  convention proves insufficient in practice.

## Consequences

- Positive: single source of truth for role-agnostic gate logic; the
  acceptance criterion becomes literally satisfiable from this repo;
  drift detection has two independent entry points (`stub-check.sh` inside
  a rulebook's own harness, `compliance-check.sh` from core) rather than
  one.
- Negative / cost: `canon-manifest.txt` becomes a shared dependency read by
  two scripts instead of one — a manifest edit must keep both in sync
  (mitigated by both reading the same file, not by hand-copied lists).
- Risk carried forward: the 43-repo rollout itself remains unexecuted from
  this repo (no write access) until batched with #63; canon and vendored
  copies coexist until each rulebook's own rollout lands, so drift is
  *detectable* but not yet *eliminated* repo-wide.

## Hand-off

Interface-shape detail for `compliance-check.sh --canon-duplication`'s CLI
surface, if it needs anything beyond a path arg, → api-design is out of
scope for this boundary decision and not needed here (single positional
arg, no interface design surface). No performance budget is implicated.
Phase 2 (ADR + C4 diagram under `docs/issue-66/decisions/**`, and the
`compliance-check.sh` extension) opens on Approve.
