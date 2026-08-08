---
code_under_review:
  - core/hooks/lib/gate-lib.sh
  - core/hooks/tests/stub-check.sh
  - core/hooks/tests/compliance-check.sh
  - core/hooks/tests/run-fleet-scan-tests.sh
  - core/hooks/tests/run-gate-lib-tests.sh
loop_state: landed
---

# Implementation record — issue-185

## Summary of work

Added the third "custom-by-convention" classification category to
canon-duplication's `directive.sh` check, per the approved proposal
(docs/issue-185/proposals/canon-duplication-third-category.md):

- `gate_directive_custom_by_convention` in `core/hooks/lib/gate-lib.sh`:
  clean iff the file is not a sanctioned stub, does not source
  `gate-lib.sh`, contains no `core_role_directive`/`gate_[A-Za-z_]+`
  needle as a real definition/call line (comment/heredoc-body lines
  stripped before the needle check), and does not hash-match
  `role-directive.sh`/`gate-lib.sh`.
- `stub-check.sh` and `compliance-check.sh --canon-duplication`:
  three-way branch (stub / custom-by-convention / FAIL) for directive.sh
  hits, with a distinct log line for the custom-by-convention case.
- `run-fleet-scan-tests.sh`: three byte-exact real-repo fixtures
  (accessibility, localization, capacity-planning) scan clean under both
  stub-check.sh and compliance-check.sh --canon-duplication; re-based the
  synthetic vendored fixture into a needle-carrying one-byte-edited copy
  of `gate_is_role_directive_stub`'s body, plus a new bare-`gate_*`-call
  fixture — both still FAIL.
- `run-gate-lib-tests.sh`: direct unit coverage of the new helper (stub /
  comment-only-mention / bare-call-needle / hash-vendored-copy).

## Why

Closes the false-positive the issue names: three real Batch-1 repos'
deliberately custom, per-facet `directive.sh` SessionStart hooks
currently flag as "vendored copy" under the binary stub|vendored check,
because not-a-stub always reads as vendored today. See the proposal's
Rationale for why hash-only was rejected (can't discriminate a
legitimate stub, and doesn't close the byte-edited-vendored-copy bypass)
in favor of a canon-function-name needle check.

## Upstream / basis

docs/issue-185/proposals/canon-duplication-third-category.md (approved
via issue comment "APPROVE issue-185/implementation"),
docs/issue-185/reports/implementation/survey.md.

## What did not work

None.

## Doc placement

- docs/handbooks/fleet-scan-tests.md — updated with an issue-185 section
  (contract §21: run-fleet-scan-tests.sh is an operational run script,
  so its change carries a same-commit handbook update).
- No new env var/config key/dependency/migration. No library-or-format
  choice or wire-format change — nothing new for
  docs/issue-185/decisions/. No benchmark/investigation numbers —
  nothing for docs/issue-185/reports/ beyond this record itself.

## Verification run

`bash core/hooks/tests/run-fleet-scan-tests.sh` — 27/27 pass, including
the three real byte-exact fixtures scanning clean, the sanctioned-stub
fixture staying clean, and the re-based one-byte-edited-vendored-copy
and bare-gate_*-call fixtures still flagging FAIL.
`bash core/hooks/tests/run-gate-lib-tests.sh` — 66/66 pass, including
the four new gate_directive_custom_by_convention unit cases.

## Rationale for deviations

`docs/handbooks/fleet-scan-tests.md` was not in the proposal's frozen
write set but was touched anyway: contract v3 §21 refuses a commit that
changes `run-fleet-scan-tests.sh` (an operational run script) without a
same-commit `docs/handbooks/` update. Docs are the standing exception to
the write-set freeze (warrant directive), so this is a mechanical
compliance addition, not a scope widening of the code change itself.

## Open findings

None. After-proposal hunt: no finding. Before-landing hunt (stance 1,
"another plugin's rule cancels this one"): no finding. Both recorded in
docs/reports/2026-08-08-hunt-canon-duplication-third-category.md.
