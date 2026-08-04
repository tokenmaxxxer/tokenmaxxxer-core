---
kind: build-proposal
subject: issue-118
produced_by: implementation
loop_state: proposed
upstream:
  - path: docs/issue-118/reports/implementation/survey.md
    sha: <set at commit>
---

files: `core/contract/role-handoff-contract.md`

## Request

Issue #118: two days of defect cycles turned out to be instances of three
recurring classes (parser differential #99→#107→#114; incomplete
inspection surface across otr #245/#262/#266; lifetime/ordering coupling
#266/#245-F3/otr #221). Only one observation cycle
(`docs/issue-107/reports/execution-observation.md` Finding 1) explicitly
asked "does this class live anywhere else?", and that single question
immediately found `_git_subcommand` (→ #114); cycles that skipped the
question stayed blind to the next occurrence until the next incident.
Three requirements:

1. Add a standard question to the observation-record norm — the document
   in this repo defining the record requirements of the contract's
   §20-series (exact location to be settled by research) — asking, for
   every confirmed Finding: (a) which defect class it belongs to, and (b)
   whether that class was checked for elsewhere in the codebase outside
   the observed scope, recording either the sweep's result or the reason a
   sweep wasn't possible.
2. Land it as documented norm only — no `record-fields-gate` or other
   mechanical check; mechanization is deferred to a future issue, and only
   if the norm is observed being ignored in practice.
3. Where the observation role's own rulebook (owned in a separate repo)
   would also need this question and this repo cannot reach it, record
   that reflection need rather than attempt the edit here (issue #106's
   precedent).

## Constraints

- `record-fields-gate.sh` and `record-shape-gate` unchanged. (Survey:
  `record-shape-gate` does not exist anywhere in this repo or its git
  history — only `record-fields-gate.sh` is real here. Since this proposal
  touches no gate script at all, both names are satisfied regardless.)
- No retroactive edits to any existing record (issue #100's decision:
  `docs/issue-90/reports/implementation.md` / `docs/issue-94/reports/implementation.md`
  precedent applies the same way here — no past
  `docs/issue-<n>/reports/execution-observation.md` gets rewritten to add
  the new question after the fact).
- Stay inside what this repo owns: `core/contract/role-handoff-contract.md`.
  `tokenmaxxxer/execution-observation-rulebook` (the observation role's own
  record-shape rulebook — confirmed via `gh repo list tokenmaxxxer` to be
  a separate, real repo) is not reachable from this branch; editing it is
  out of scope here and gets recorded as follow-up instead, per the #106
  precedent this issue's own requirement 3 names.

## Rationale

**Chosen: append a new item to `core/contract/role-handoff-contract.md`
§20 ("Per-role record minimum content"), scoped specifically to `finding`
entries rather than the whole record.** §20 is the section
`record-fields-gate.sh` cites by name as its enforcement source
(`core/hooks/record-fields-gate.sh:4`), and the survey confirms it is the
*only* document in this repo that defines record-content requirements by
that section number — matching the issue's own "계약 §20 계열" framing
exactly. Critically, the survey also confirms `record-fields-gate.sh`'s
checks are a fixed, hardcoded list (a what-was-done section, a why
section, an upstream-basis token, `loop_state:`, open-findings, and
conditionally next-steps/resolution-path) that does not dynamically parse
§20's numbered list — so a new §20 item cannot be silently picked up by
the existing gate, satisfying requirement 2's "no mechanical check"
without needing to touch the gate to prove it.

**Alternative considered and rejected: extend §2's `finding` kind row
(`core/contract/role-handoff-contract.md:70`) with two new required
fields instead of adding to §20.** §2 is the artifact kind table — the
schema other decisions in this repo already treat as literal,
mechanizable source-of-truth (`docs/issue-100/reports/implementation/survey.md:64-68`
cites this same table, a sibling row, as sanctioning an exact `kind:`
value). Adding "defect class" and "other habitats" as required §2 fields
would read as a structural requirement a future gate would naturally check
for presence — directly against requirement 2's explicit instruction to
keep this a documented question, not a machine-checked field. §20's own
text already frames itself as pairing with §18 gate B's *qualitative,
after-the-fact* measurement rather than field-presence checking, which is
the right register for "consider and record this," not "this field must
exist."

**Alternative considered and rejected: a brand-new, observation-specific
contract section (e.g. §23) instead of extending §20.** The survey found
zero observation-specific sections anywhere in the contract (`grep -in
observation` returns only two unrelated hits) — the contract is
deliberately role-agnostic, with role-specific rulebook content living
entirely outside this repo (`tokenmaxxxer/execution-observation-rulebook`,
per the #106 precedent this issue's requirement 3 itself invokes).
Inventing a new observation-only section here would cross that boundary
and duplicate the numbered "record must state" structure §20 already
provides for exactly this purpose; scoping the new §20 item's *wording* to
`finding` entries achieves the same precision without the boundary
violation.

**Alternative considered and rejected: a standalone decision document under
`docs/issue-118/decisions/` in addition to the contract edit.** Issue #100
used that shape because its citation-format convention had multiple
consumers to keep in sync (a gate check, a test case, a handbook entry,
two existing records). This issue's rule has exactly one artifact — the
new §20 prose itself — and its rationale is fully carried by this
proposal, matching issue #106's structurally identical contract-amendment
case, which used no separate decision doc. Adding one here would be a
second home for the same single fact with nothing to keep it in sync
against.

## What will be done

1. `core/contract/role-handoff-contract.md`, §20: append one new numbered
   item to the "A role record must state, at minimum" list, worded to
   apply specifically when a role's record states a confirmed `finding`
   entry (§2's `finding` kind, any `verdict` other than `Unverifiable`) —
   requiring the record to additionally state (a) which defect class the
   finding belongs to, and (b) whether that class was checked for
   elsewhere in the codebase outside the observed scope, recording either
   the sweep's outcome or the reason a sweep wasn't possible. No other
   §20 item, and no other section, changes.
2. (Phase 2 only, in `docs/issue-118/reports/implementation.md` per this
   repo's phase-gating.) Record that
   `tokenmaxxxer/execution-observation-rulebook`'s own record-shape
   instructions (the `### Finding N` block template used across every
   `docs/issue-<n>/reports/execution-observation.md`) are unreachable from
   this repo and recommend a follow-up issue there so the rulebook's own
   text carries the same question — discharging requirement 3 the same
   way issue #106's record discharged its equivalent gap.

## Out of scope

- Editing `tokenmaxxxer/execution-observation-rulebook` directly —
  unreachable from this branch; recorded as a follow-up recommendation
  instead.
- `record-fields-gate.sh`, `core/hooks/tests/run-role-gates-tests.sh`, or
  any other gate/test file — requirement 2 asks for a documented norm
  only; mechanization is explicitly deferred to a future issue, and only
  if the norm is observed being ignored.
- §2's `finding` kind row — the rejected alternative location; not
  touched.
- `core/hooks/directive.sh` — confirmed (survey) not to mirror any of
  §20's existing five items today, so the new item needs no matching
  mirror there.
- Retroactive edits to any existing
  `docs/issue-<n>/reports/execution-observation.md` — #100's
  no-retroactive-edits decision applies here the same way.
- A new `docs/issue-118/decisions/` document — the rejected alternative
  shape; this issue's rule has one artifact and is carried by this
  proposal's own Rationale, per the #106 model.

## How you'll know it worked

- `core/contract/role-handoff-contract.md` §20 contains the new item,
  grep-able (e.g. for "defect class" and "other habitats" or equivalent
  wording), positioned among the existing numbered list without
  renumbering or altering items 1–5.
- `git diff` for this proposal's phase-2 execution touches exactly one
  file, `core/contract/role-handoff-contract.md`.
- `bash core/hooks/tests/run-role-gates-tests.sh` and `bash
  core/hooks/tests/run-gate-lib-tests.sh` both pass unchanged (no new
  case, no modified assertion), confirming the addition landed as
  unmechanized prose exactly as requirement 2 asked.
- `docs/issue-118/reports/implementation.md` (phase 2) names the specific
  follow-up-issue recommendation for
  `tokenmaxxxer/execution-observation-rulebook`.
