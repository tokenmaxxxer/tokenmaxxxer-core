---
subject: issue-34
role: coding
loop_state: scope-proposed
---

# Proposal: contract s19 — clause checklist + phase-2 traceability, alternatives, failure signal

## Request (paraphrased intent)

s19's phase-1 proposal bullet requires intent/write-surface/out-of-scope/
success-judgment but has three gaps: (1) proposal commitments are prose,
so clauses get lost in transcription to shipped files with no mechanical
way to catch it — issue-23's review found exactly this (requirement 4b:
a proposed 12-call cap never reached `directive.sh`); (2) proposals are
single-option, so the approver judges completeness but never sees what
else was considered; (3) success criteria are often circular for
doc-shaped work ("human approves" = success), with no distinct signal
for "this was wrong." Add three additive, minimal requirements to the
phase-1 proposal bullet, following the issue-14/issue-32 amendment
precedent (explicit new sentence naming what changed, no rewording of
what already works).

## Constraints

- Single file, single section: `core/contract/role-handoff-contract.md`
  s19, the existing phase-1 bullet (`:642-649`) only. No other bullet in
  s19 is touched.
- Additive only — the existing four elements (intent, write surface,
  out-of-scope, success judgment) keep their current wording verbatim;
  new requirements are appended, not interleaved into existing sentences.
- Checklist replaces prose, not adds to it (issue's explicit instruction):
  the new wording states that proposal commitments are *expressed as* an
  enumerable checklist, not that a checklist is added on top of a prose
  commitment list.
- No new file, no new bucket, no change to any other section (18, 20,
  21) or to any role's directive.sh/README — this is a contract-text-only
  amendment, same footprint class as issue-32's.

## Considered alternatives

- A separate `docs/specs/proposal-template.md` file the contract
  references, instead of inline contract text — rejected: no such file
  exists today (survey confirmed), and creating one adds a second
  document to keep in sync with s19 itself, the exact drift class s19
  already exists to prevent for role output.
- Automated CI validation of proposal structure (scout brief's PR-template
  finding: some org templates fail a build on missing sections) —
  rejected: this repo's phase gate is human-review-based (contract s19's
  Approve mechanism), not CI-based; wiring a bot check is a materially
  larger, separate proposal, not an additive wording change.

## What will be done (exact wording, phase 2 only — not applied yet)

In `core/contract/role-handoff-contract.md`, s19, append to the existing
phase-1 bullet (after "...how success will be judged).", still inside the
same bullet, before "Research and survey live under..."):

> Proposal commitments are expressed as an enumerable clause checklist
> (one line per commitment), not prose alone; phase 2 marks, per clause,
> the commit or hunk that fulfilled it, or states the clause was dropped
> and requires re-approval before the drop stands. The proposal also
> names 1-2 alternatives it considered, one line each stating why it was
> not chosen, and one line stating the failure signal — a check that
> would fail, a behavior that would regress, or a complaint that would
> recur — if this proposal turns out wrong. A proposal missing any of the
> three is incomplete and not ready for the human's Approve.

## Out of scope

- Retrofitting a checklist/alternatives/failure-signal section onto any
  merged proposal (issue-14/23/30/32 or others) — this amends the
  requirement going forward only, per the issue-14/32 precedent of
  additive-not-retroactive amendments.
- Any change to the Approve mechanism itself (two-account/single-account
  modes, `APPROVE issue-<n>/<role>` string) — untouched.
- Any change to section 20 (per-role record minimum content) or section
  21 — phase-2 traceability marking happens inside the proposal's own
  checklist, not as a new record-section requirement.
- CI/bot enforcement of the new fields (see alternatives above) — a
  future proposal's scope if ever wanted.

## How success will be judged

- `core/contract/role-handoff-contract.md`'s phase-1 bullet contains the
  new paragraph verbatim, appended after the existing four-element
  sentence with no edit to that sentence's own text (`git diff` shows a
  pure addition hunk to the bullet, zero deleted lines from the
  pre-existing sentence).
- The new paragraph names all three requirements: per-clause checklist +
  phase-2 traceability marker (commit/hunk or drop+re-approve), 1-2
  alternatives with one-line rejection reasons, one-line failure signal.
- No other section of the contract, and no file outside
  `core/contract/role-handoff-contract.md`, changes.

## Failure signal

If this amendment is wrong, the signal is: a future proposal (this
role's own next subject, or another role's) ships a checklist item with
no phase-2 commit/hunk marker and no drop+re-approve note, and a
downstream review still has to reconstruct the spec-vs-built gap by hand
— i.e., the exact issue-23-4b pattern recurs even after this wording
exists, showing the checklist requirement didn't actually change
behavior.
