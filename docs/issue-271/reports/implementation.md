---
code_under_review:
  - core/hooks/survey-order-gate.sh
  - core/hooks/tests/run-survey-order-gate-tests.sh
  - core/hooks/tests/run-all.sh
loop_state: landed
type: bugfix
breaking: false
verdict: pass
---

## What was done

Implemented exactly the approved phase-1 proposal
(`docs/issue-271/proposals/2026-08-23-survey-order-gate-role-aware-path.md`):

1. `core/hooks/survey-order-gate.sh`: the bash wrapper now exports
   `SOG_ROLE="${CLAUDE_ROLE:-}"` and passes it to the embedded Python via
   `PG_ROLE`, mirroring `record-shape-gate.sh`'s `RS_ROLE` env-passthrough
   pattern. The embedded Python reads `PG_ROLE`; when non-empty it builds
   `docs/issue-<n>/reports/<role>/survey.md`, otherwise it keeps the
   existing hardcoded `reports/implementation/survey.md` fallback. No
   accept-any-glob was added — the path is built from the acting role only,
   never matched against any role's tree.
2. Added `core/hooks/tests/run-survey-order-gate-tests.sh`, following the
   sibling `run-record-shape-gate-tests.sh` convention (plain bash driving
   the gate script with a JSON PreToolUse payload on stdin, real
   subprocess). Covers: implementation-role behavior unchanged with
   `CLAUDE_ROLE` unset and with `CLAUDE_ROLE=implementation` (both allow
   with survey present, deny with it absent); a non-implementation role
   (`product-discovery`) is denied when only `reports/implementation/survey.md`
   exists (proves no accept-any-glob) and allowed once its own
   `reports/product-discovery/survey.md` exists; and the scout-skip-marker
   text still permits the write when no survey is on disk at all.
3. Wired the new test file into `core/hooks/tests/run-all.sh` (this repo's
   fast test tier — no `.on-the-record/test-tiers.json` exists in this
   repo; `run-all.sh` is the closest equivalent and was extended per the
   Acceptance's fast-tier check).

## Why

board-gate.sh (contract v3 s11) restricts a non-implementation role to
writing only under its own `docs/issue-<n>/reports/<role>/` tree, but
survey-order-gate.sh hardcoded `reports/implementation/survey.md` as the
survey it looks for regardless of acting role — making a non-implementation
role's real, board-gate-compliant survey invisible to the gate. This
resolves the acting role from `CLAUDE_ROLE`, the standing role-identity
channel every sibling gate already reads the same way.

## Upstream / basis

docs/issue-271/proposals/2026-08-23-survey-order-gate-role-aware-path.md
(approved phase-1 proposal); docs/issue-271/reports/implementation/survey.md.

## Verification

`bash core/hooks/tests/run-survey-order-gate-tests.sh`: 7 passed, 0 failed.
`bash core/hooks/tests/run-all.sh`: ALL OK (all sibling gate suites,
including the new survey-order-gate suite, pass with no regressions).

## What did not work

None.

## Open findings

None.

## skill-verdicts

- implementation-complexity-coupling-management — not-applicable: single hardcoded-path substitution behind an existing env-read pattern; no coupling/cohesion threshold, accessor chain, or check-ordering decision involved.
- implementation-design-pattern-selection — not-applicable: no GoF-pattern-vs-procedural choice; the fix mirrors an existing env-passthrough idiom already used by a sibling gate.
- implementation-performance-data-structure-choice — not-applicable: no data structure, algorithm, or performance-sensitive path is touched; this is a single string substitution.
- implementation-blueprint — not-applicable: change is a same-file, single-responsibility bugfix (~10 lines) with no multi-module structure to decide; the classify step's own veto (single-file, non-architectural) applies.
- test-derivation — not-applicable: the approved phase-1 proposal already fully enumerated the required regression cases (a/b/c) verbatim; no additional technique-selection or requirements-to-tests derivation was needed beyond transcribing the proposal's own list.
