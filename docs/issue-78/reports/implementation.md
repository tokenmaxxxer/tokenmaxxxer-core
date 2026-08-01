---
subject: issue-78
role: implementation
code_under_review: core/hooks/tests/stub-check.sh, core/hooks/tests/canon-forms.txt, core/hooks/tests/compliance-check.sh, core/hooks/tests/run-stub-canon-forms-tests.sh, core/hooks/tests/run-compliance-scan-scope-tests.sh, core/hooks/tests/run-all.sh, docs/handbooks/gate-house-standard.md
loop_state: landed
---

# Record — stub-check canon combination forms + compliance-check hooks.json scan scope (phase 2)

## What was done

Built the two fixes the approved proposal
(`docs/issue-78/proposals/2026-08-01-stub-check-canon-forms-compliance-scan-scope.md`)
specified:

- `core/hooks/tests/canon-forms.txt` — new manifest registering permitted
  `directive.sh` structural shapes: the existing single
  `core_role_directive` call, and sales-rulebook's approved (issue-10)
  fragment-array `for`-loop combination form.
- `core/hooks/tests/stub-check.sh` — the `directive.sh` structural check
  now classifies each non-blank/non-comment/non-assignment line against
  the union of registered shapes from `canon-forms.txt` (falling back to
  the built-in single-call shape if the manifest is missing, mirroring
  `CANON_GATES`'s own fallback), instead of hardcoding one permitted
  shape.
- `core/hooks/tests/compliance-check.sh` — the scan set is now resolved
  by reading every `hooks.json` under `$dir`, extracting each
  `PreToolUse[].hooks[].command` script path, and resolving it relative
  to that `hooks.json`'s directory — replacing the `*-gate.sh` filename
  glob. Catches `hunt-guard.sh`/`gh-guard.sh`-shaped files regardless of
  name.
- `core/hooks/tests/run-stub-canon-forms-tests.sh` (new) — asserts a
  fragment-loop `directive.sh` fixture passes and a malformed one still
  fails.
- `core/hooks/tests/run-compliance-scan-scope-tests.sh` (new) — asserts a
  `hunt-guard.sh`-shaped fixture (PreToolUse-wired, non-`-gate.sh`-named,
  hand-rolled kill switch) is flagged, and a script present on disk but
  not wired in any `hooks.json` is excluded.
- `core/hooks/tests/run-all.sh` — both new suites wired in.
- `docs/handbooks/gate-house-standard.md` — documented both mechanisms
  and why the split-file combination alternative was deferred.

## Why

Issue #78 (2026-08-01 A+ audit follow-up): sales-rulebook's approved
fragment-loop `directive.sh` shape fails stub-check's single-shape
structural check (a canon-format gap, not a rulebook defect), and
compliance-check's `*-gate.sh` filename glob misses `hunt-guard.sh` and
`gh-guard.sh`, both PreToolUse-wired in their own `hooks.json` but
outside the glob — confirmed fail-open exposure the detector exists to
catch. Full rationale, including the rejected alternatives (a second
hardcoded regex block; a split-file directive.sh regulation; a wider
filename glob), is in the phase-1 proposal.

## Upstream basis

`docs/issue-78/proposals/2026-08-01-stub-check-canon-forms-compliance-scan-scope.md`
(approved via issue-level comment `APPROVE issue-78/implementation` from
`JiwonJung94`, a `docs/specs/approvers.md`-listed account — single-account
path).

## Doc-placement ladder

- [x] `core/hooks/tests/stub-check.sh`, `core/hooks/tests/compliance-check.sh` —
  edited in place, existing canon test scripts.
- [x] `core/hooks/tests/canon-forms.txt`,
  `core/hooks/tests/run-stub-canon-forms-tests.sh`,
  `core/hooks/tests/run-compliance-scan-scope-tests.sh` — new files under
  the existing `core/hooks/tests/` tree.
- [x] `core/hooks/tests/run-all.sh` — edited in place to wire both new
  suites.
- [x] `docs/handbooks/gate-house-standard.md` — standing handbook
  bucket, edited in place (registration-mechanism documentation, same
  placement basis as issue-72/75's own mechanism-change entries in this
  file).
- [x] `docs/issue-78/reports/implementation.md` — this record.

## What did not work

None. Both fixes landed as specified in the proposal on the first pass.

## Hunt cadence

No warrant-hunter dispatch performed this session (single-account
headless turn; no background hunter tooling available/invoked). Recorded
per cadence requirement — nothing found because nothing was run.

## Next steps

None — this record is terminal (`loop_state: landed`).

## Open findings

None outstanding.
