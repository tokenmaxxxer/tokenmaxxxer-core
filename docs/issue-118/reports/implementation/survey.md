---
kind: current-state-survey
subject: issue-118
produced_by: implementation
---

# Current-state survey — issue-118

## Requirement 1's location, resolved

`core/contract/role-handoff-contract.md`, `## 20. Per-role record minimum
content` (lines 801–834 in the current tree) is the exact document issue
#118 calls "관찰 기록 규범(계약 §20 계열의 기록 요건을 정의하는 이 레포
문서)". It is the only document anywhere in this repo that defines
record-content requirements by that section number:

```
## 20. Per-role record minimum content

Every role record (`docs/issue-<n>/reports/<role>.md`, per section
11) must, at every point it is read by another role or a human, contain
enough for a next reader to pick the work up cold. ...

A role record must state, at minimum:

1. **What was done** — ...
2. **Why** — ...
3. **The concrete basis the next reader needs to continue** — ...

Additionally, whenever the role leaves work open, the record must state:

4. **A next-steps backlog** — ...
5. **An open-finding resolution path** — ...

This is a minimum, not a template — role-specific required fields (section
2's table) are additional, not replaced by this list. This section pairs
with section 18 gate B: gate B measures, after a round, whether a
zero-context reader can reconstruct and continue from the records alone;
this section is what each role does at write time so that measurement
passes instead of failing on records that only show completion, not basis.
```

It is confirmed as the enforcement source by `core/hooks/record-fields-gate.sh:4`
(`# PreToolUse gate (Write|Edit|MultiEdit) — contract §20.`) and by prior
work in this repo: `docs/issue-100/reports/implementation/survey.md:81-84`
independently names the same section (at its then-current line numbers,
784–817) as "what `record-fields-gate.sh` enforces today."

`grep -in observation core/contract/role-handoff-contract.md` returns only
two unrelated hits (lines 135–136, about direct system observation vs.
relying on another role's record) — the contract has **no
observation-specific section anywhere**. §20 is role-agnostic ("every role
record"), and is the closest and only norm-carrying home for a rule about
what an observation record's `finding` entries must state.

## Why §20 and not §2's `finding` kind row

`core/contract/role-handoff-contract.md:70` (§2, the artifact kind table)
separately defines a `finding` entry's required fields: `requirement`,
`verdict` (`Present|Surface|Absent|Incorrect|Unverifiable`), `evidence`,
`rationale`, `spec_vs_built`, `addressed_to`, `severity`. This table is
the schema other decisions in this repo already treat as literal,
mechanizable source-of-truth — `docs/issue-100/reports/implementation/survey.md:64-68`
cites this same table (line 63, a sibling row) as sanctioning an exact
`kind:` value. Extending this table with a new required field would read
as a structural requirement, not a documented question to weigh — directly
against requirement 2's "문서화된 규범으로만 한다... 기계 검사에는 태우지
않는다."

§20, by contrast, is prose that "pairs with section 18 gate B" (qualitative,
after-the-fact measurement) rather than field-presence checking. Confirmed
by reading `core/hooks/record-fields-gate.sh` in full: its checks are a
fixed, hardcoded list (a what-was-done section, a why section, an
upstream-basis token, `loop_state:`, open-findings, and — when
`loop_state` is non-terminal — next-steps and a resolution path); it does
not parse §20's numbered list dynamically. Appending a new numbered item to
§20 therefore cannot be picked up by the existing gate at all, matching
requirement 2 exactly.

## The observation-record's detailed shape lives in a separate repo

Every `docs/issue-<n>/reports/execution-observation.md` in this repo (e.g.
issue-90, 94, 98, 99, 106, 107) shares a detailed shape — `## Independence`,
three `## Verdict N` sections, `## Hunt`, `### Finding N` sub-blocks — but
that shape is not defined anywhere in this repo's `docs/` or `core/`. It is
owned by the separate repo `tokenmaxxxer/execution-observation-rulebook`
(confirmed to exist via `gh repo list tokenmaxxxer`, created
2026-08-01T14:45:52Z), mirroring the `implementation`/`implementation-rulebook`
split already documented for issue #106:
`docs/issue-106/proposals/2026-08-03-build-headless-delegation-clause.md:27-33`
states plainly that "per-role rulebook directive text ... lives in separate
repos not reachable from this branch ... editing those is out of scope here
and gets recorded as follow-up instead," and
`docs/issue-106/reports/implementation.md:178-191` records the resulting
follow-up-issue recommendation. This substantiates issue #118 requirement
3's own premise and sets the model for how this issue records the same
gap.

## The ad-hoc precedent the issue cites

`docs/issue-107/reports/execution-observation.md:285-317` (`### Finding 1`)
is the one instance issue #118's background section names. Its four labeled
sub-parts are `Impact`, `Timeline`, `Root cause`, `Action item` — the
"where else does this class live" question appears only inside free-form
`Root cause` prose ("nothing in its own loop asked 'where else does this
class live'"), not as a labeled, repeatable field. No other
execution-observation record checked in this survey
(issue-90/94/98/99/106) carries an equivalent explicit class/other-habitats
statement as a standard, separately labeled item — confirming the issue's
own claim that only one cycle asked this, ad hoc.

## `record-fields-gate` / `record-shape-gate` — the constraint's two named gates

`core/hooks/record-fields-gate.sh` exists (`core/.claude-plugin/plugin.json:3`
lists it among core's seven hooks). `record-shape-gate` does **not** exist
anywhere in this repo — not in the working tree, not in git history
(`git log --all -S"record-shape-gate"` and `git log --all -- '**/*record-shape*'`
both return nothing). It is presumably a hook owned by a different plugin
(e.g. the `coding`/`implementation` rulebook) not present in this checkout.
Since this proposal does not touch any gate script at all, the constraint
("record-fields-gate·record-shape-gate 무변경") is satisfied regardless of
which of the two actually lives in this repo.

## Precedent for the edit shape

Two prior issues model the two ways a contract-adjacent convention has
landed here:

- `docs/issue-106/proposals/2026-08-03-build-headless-delegation-clause.md`
  — a same-shaped case: a new rule added directly as a new numbered section
  in `core/contract/role-handoff-contract.md` (§22), with the rationale
  carried entirely in the proposal itself, no separate decision doc, and a
  same-turn note in the phase-2 record about the unreachable per-role
  rulebook needing separate follow-up.
- `docs/issue-100/proposals/2026-08-03-canonicalize-record-citation-format.md`
  — a different-shaped case: a reusable citation-format/`kind:` convention
  with multiple consumers to sync, given its own
  `docs/issue-100/decisions/` document plus a new gate check.

Issue #118 is structurally closer to #106 (a single rule landing directly
in the contract's own prose, explicitly to stay unmechanized) than to #100
(a multi-consumer format convention needing a standalone decision record
and a gate).

## `directive.sh` does not mirror §20 today

`grep -n "record minimum\|What was done\|next-steps backlog\|record must
state" core/hooks/directive.sh` returns no hits — none of §20's existing
five items are echoed into the `SessionStart` directive text session
transcripts show. This rules out needing a matching edit to `directive.sh`
for the new item; only §22 (issue #106, a `session-must-not-end`
procedural rule) is the kind of content that gets mirrored there, per that
issue's own rationale for including `directive.sh` in its write set. §20's
content-quality guidance is not that kind of rule.

## Write set this survey projects

- `core/contract/role-handoff-contract.md` — one new numbered item
  appended to §20, scoped to `finding` entries specifically (not the whole
  record), stating the two-part question: (a) which defect class a
  confirmed finding belongs to, (b) whether that class was checked for
  elsewhere in the codebase outside the observed scope, with the sweep's
  result or the reason a sweep wasn't possible.
- (phase 2 only) `docs/issue-118/reports/implementation.md` — records that
  `tokenmaxxxer/execution-observation-rulebook`'s own record-shape
  instructions are unreachable from this repo and recommends a follow-up
  issue there, per requirement 3 and the #106 precedent.

No gate, test, or handbook file is projected — requirement 2 asks
explicitly for a documented norm only, and §20's existing enforcement is
confirmed (above) not to derive from the section's prose, so nothing
mechanical needs touching or updating in sync.
