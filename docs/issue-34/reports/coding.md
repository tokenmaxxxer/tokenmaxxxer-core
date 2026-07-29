# Report: coding (issue-34)

loop_state: landed

## What was done

Applied the approved proposal `docs/issue-34/proposals/coding.md`
verbatim to `core/contract/role-handoff-contract.md`, s19's existing
phase-1 bullet: appended the new paragraph (clause checklist + phase-2
traceability, alternatives, failure signal) immediately after "...how
success will be judged)." and before "Research and survey live
under...", inside the same bullet. Purely additive; no existing bullet
text reworded or deleted (`git diff` shows 9 insertions, 0 deletions).

## Why

Phase-1 survey (issue-34) found three gaps in s19's phase-1 proposal
requirements: proposal clauses drift from shipped files with no
mechanical trace (issue-23 finding 4b, issue-76), proposals are
single-option with no visibility into rejected alternatives, and success
criteria are often circular for doc-shaped work. The approved proposal
closes all three with one additive paragraph.

## Upstream basis

`docs/issue-34/proposals/coding.md` (approved via "APPROVE
issue-34/coding" on issue #34), building on the phase-1 survey at
`docs/issue-34/reports/coding/survey.md` and scout brief at
`docs/issue-34/reports/coding/scout-brief.md`.

## Clause checklist — phase-2 traceability

Per the newly-added discipline itself, each commitment in the proposal's
"What will be done" section is marked below with the commit/hunk that
fulfilled it.

1. **New paragraph appended verbatim after the existing four-element
   sentence, no edit to that sentence's own text.**
   Fulfilled by commit `8d0e91b` ("contract(s19): add clause checklist +
   phase-2 traceability, alternatives, failure signal"), hunk in
   `core/contract/role-handoff-contract.md` at the phase-1 bullet
   (`role-handoff-contract.md:646-654` post-edit): 9 lines inserted, 0
   lines deleted from the pre-existing sentence.
2. **Paragraph names the per-clause checklist + phase-2 traceability
   marker requirement (commit/hunk or drop+re-approve).**
   Fulfilled by the same commit `8d0e91b`, same hunk — sentence
   beginning "Proposal commitments are expressed as an enumerable clause
   checklist...".
3. **Paragraph names the 1-2 alternatives + one-line rejection reason
   requirement.**
   Fulfilled by the same commit `8d0e91b`, same hunk — sentence
   beginning "The proposal also names 1-2 alternatives...".
4. **Paragraph names the one-line failure-signal requirement.**
   Fulfilled by the same commit `8d0e91b`, same hunk — clause "...and
   one line stating the failure signal...".
5. **No other section of the contract, and no file outside
   `core/contract/role-handoff-contract.md`, changes.**
   Fulfilled by commit `8d0e91b` alone touching exactly one file (this
   report file itself is a separate, later commit and lives under
   `docs/`, not the contract).

No clause was dropped; all five items in the proposal's "How success
will be judged" / "What will be done" sections are fulfilled by the
single commit above.

## What did not work

First edit attempt placed the new paragraph after "...The role opens the
PR at this point and stops." instead of after "...how success will be
judged)." — caught before committing by re-reading the proposal's
explicit insertion point ("after '...how success will be judged).'...
before 'Research and survey live under...'"), reverted, and re-applied
at the correct location. No incorrect version was ever committed.

## Open findings

None.

## Closed checks

- `git diff 8d0e91b^ 8d0e91b -- core/contract/role-handoff-contract.md`
  — confirmed 9 insertions, 0 deletions, single file changed.
