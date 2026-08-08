# Canon rollout: per-rulebook transition (issue-66)

Companion to `docs/handbooks/canon-scripts.md`'s "referenced, never copied"
rule. That doc states the rule; this doc is the per-rulebook checklist for
actually landing it in one of the 43 sibling rulebook repos. This repo has
no write access to those repos — the checklist runs *there*, driven by
whoever owns that repo's own transition.

## Preconditions

- The four role-agnostic gates (`trailer-gate.sh`, `record-fields-gate.sh`,
  `handbook-trigger-gate.sh`, `parse-check.sh`) and `directive.sh`'s
  boilerplate half are already core canon (`core/hooks/`,
  `core/hooks/lib/role-directive.sh`) and registered in
  `core/hooks/hooks.json` — done, issue-66 PRs #67/#68.
- `core/hooks/tests/stub-check.sh` and
  `core/hooks/tests/compliance-check.sh --canon-duplication` exist as the
  two drift-detection entry points (this ADR,
  `docs/issue-66/decisions/2026-08-08-role-agnostic-canon-boundary.md`).

## Steps, per sibling rulebook repo

1. Delete the five vendored files if present: `trailer-gate.sh`,
   `record-fields-gate.sh`, `handbook-trigger-gate.sh`, `parse-check.sh`,
   and any local copy of `stub-check.sh`/`compliance-check.sh`.
2. Remove the rulebook's own `hooks.json` entries for those four gates —
   core already fires them globally for every plugin install; a
   rulebook-local entry is redundant, not additive.
3. Reduce the rulebook's own `directive.sh` to: shebang, the local
   trap/`set -uo pipefail` (kept local — a trap inside a sourced function
   does not catch the sourcing script's own abnormal exit), the `source
   .../core/hooks/lib/role-directive.sh` line, and one
   `core_role_directive` call carrying the four role-unique values.
4. Run, from the rulebook's own test harness:
   - `stub-check.sh` against the rulebook's own tree (detects reintroduced
     copies and a malformed `directive.sh` stub).
   - `compliance-check.sh --canon-duplication <rulebook-path>` (detects
     any manifest-listed canon file still vendored anywhere under the
     rulebook's tree, run from core's own copy of the script — the
     literal acceptance-check surface issue-66 names).
   Both must exit 0 before the transition is considered landed.
5. **Batch with issue-63.** Issue-63's warrant-hunter canon promotion
   touches the same 43 repos with the same reference-not-vendor mechanism
   (vendored-copy removal + core-path pointer). Land steps 1–4 above in
   the same commit/PR as issue-63's rollout for that repo, once #63 ships
   its own canon payload — this is a scheduling efficiency (one 43-repo
   touch instead of two), not a scope merge; see the ADR's "#63 stays
   separate" decision for why #63's content is not folded into this
   checklist.

## What this repo does NOT do

This repo (`core`) has no write access to the 43 sibling rulebook repos.
Nothing above is executed from here — this doc is the transition
specification each rulebook's own maintainer/session follows. This repo's
role stops at: canon existing, being registered, and being scannable
(`stub-check.sh`, `compliance-check.sh --canon-duplication`) against an
arbitrary rulebook path.
