---
subject: issue-83
role: implementation
code_under_review: core/hooks/tests/canon-forms.txt, core/hooks/tests/run-stub-canon-forms-tests.sh, docs/handbooks/gate-house-standard.md
loop_state: landed
---

# Record — canon-forms loop-body row pattern (phase 2)

## What was done

Built the fix the approved proposal
(`docs/issue-83/proposals/2026-08-01-canon-forms-loop-body-pattern.md`)
specified:

- Read the real `sales/hooks/directive.sh:16-23` cross-repo (`gh api
  repos/tokenmaxxxer/sales-rulebook/contents/sales/hooks/directive.sh`).
  Its shape differs from the toy fixture the original issue-78 suite
  used: the `for ... in` argument list is spread across backslash-
  continued quoted-path lines, `do` sits on its own line, and the loop
  body is a test-and-source row
  (`[ -f "$frag" ] && . "$frag" 2>/dev/null`) rather than a bare
  `core_role_directive` call.
- `core/hooks/tests/canon-forms.txt` — added three `fragment-loop:`
  pattern lines (continuation-path line, lone `do`, test-and-source body
  row) covering the three physical-line shapes the header/footer-only
  patterns from issue-78 missed. Same registry mechanism (manifest-line
  addition), no `stub-check.sh` logic change.
- `core/hooks/tests/run-stub-canon-forms-tests.sh` — the fragment-loop
  fixture now mirrors the real multi-line sales shape (continuation
  paths, lone `do`, test-and-source body row) instead of the single-line
  `for frag in "${FRAGMENTS[@]}"; do core_role_directive "$frag"; done`
  toy line, which already passed via the built-in single-call exclusion
  and regression-tested nothing about the registry mechanism.
- `docs/handbooks/gate-house-standard.md` — added a paragraph next to
  the existing issue-78 fragment-loop paragraph documenting the body-row
  gap and the three new patterns.

## Why

Issue #83: core #78's `canon-forms.txt` registered only the fragment-
loop's header and footer shapes, not a body-row pattern, so sales-
rulebook's approved (issue-10) fragment-loop still failed `stub-check.sh`
at `sales/hooks/directive.sh:16-23` — a canon-format gap, not a rulebook
defect (mirrors issue-78's own framing). Full rationale, including the
rejected alternative (widening `stub-check.sh`'s built-in exclusion
instead of registering explicit shapes), is in the phase-1 proposal.

## Rationale for deviations

The proposal estimated "one new `fragment-loop:` pattern line" for the
body row, written before the real file was readable in phase 1. Reading
the real file in phase 2 (per the proposal's own Constraints section)
showed three distinct physical-line shapes go unmatched, not one: the
continuation-path lines, a lone `do` line, and the test-and-source body
row itself. The write set, mechanism (manifest-line additions to
`canon-forms.txt`, no `stub-check.sh` change), and approach are
unchanged from the proposal — only the pattern count differs from the
phase-1 estimate, driven by what the real file (unreadable at proposal
time) actually contains.

## Upstream basis

`docs/issue-83/proposals/2026-08-01-canon-forms-loop-body-pattern.md`
(approved via issue-level comment `APPROVE issue-83/implementation` from
`JiwonJung94`, a `docs/specs/approvers.md`-listed account — single-account
path).

## Doc-placement ladder

- [x] `core/hooks/tests/canon-forms.txt`,
  `core/hooks/tests/run-stub-canon-forms-tests.sh` — edited in place,
  existing canon test files (issue-78 lineage).
- [x] `docs/handbooks/gate-house-standard.md` — standing handbook
  bucket, edited in place next to the existing issue-78 entry (same
  placement basis: registration-mechanism documentation).
- [x] `docs/issue-83/reports/implementation.md` — this record.

## What did not work

None.

## Hunt cadence

No warrant-hunter dispatch performed this session (single-account
headless turn; no background hunter tooling available/invoked). Recorded
per cadence requirement — nothing found because nothing was run.

## Closed checks

- `run-stub-canon-forms-tests.sh` (code_sha: HEAD of this record): pass=3
  fail=0, run locally.
- `core/hooks/tests/run-all.sh` (code_sha: HEAD of this record): ALL OK,
  run locally.
- `stub-check.sh` (code_sha: HEAD of this record) run directly against
  the real sales-rulebook `sales/` directory, fetched via `gh api
  repos/tokenmaxxxer/sales-rulebook/contents/sales/hooks/directive.sh`
  into a scratch dir: rc=0 — `directive.sh` now classified as a valid
  role-directive stub (was RED per the issue).

## Next steps

None — this record is terminal (`loop_state: landed`).

## Open findings

None outstanding.
