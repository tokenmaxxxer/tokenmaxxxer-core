# Current-state survey (issue-34)

## Write surface

Only one file: `core/contract/role-handoff-contract.md`, section 19
(`core/contract/role-handoff-contract.md:637-719`), specifically the
phase-1 bullet at `:642-649` ("Phase 1 — propose. ... its proposal (what
this role intends to do, the intended write surface, what is out of
scope, and how success will be judged)"). No other file is a target —
proposal templates in this repo are prose, not a separate schema file;
grep confirms no `docs/specs/proposal-template*` or similar file exists
(`find docs/specs -iname '*proposal*'` returns nothing).

## Current proposal requirements (baseline)

s19's phase-1 bullet (`:642-649`) requires exactly four elements: intent,
write surface, out-of-scope, and success judgment. No checklist field,
no alternatives field, no failure-signal field exists today — confirmed
by reading the full bullet text (`:642-649`) and the surrounding
survey-rigor-floor bullet added by issue-32 (`:650-658`), which only
adds evidence-pointer/coverage/unknowns requirements to the *survey*, not
the *proposal*.

## Survey of issue-23/30/32 proposals against the three proposed gaps

**Issue-23** (`docs/issue-23/proposals/coding.md`, `docs/issue-23/reports/review.md`):
- Proposal was single-option, no alternatives section at all.
- Proposal stated a "Total search/fetch call cap: 12" constraint
  (`docs/issue-23/proposals/coding.md:54`) as prose inside `## Constraints`,
  not as a checklist item. Review's requirement 4b
  (`docs/issue-23/reports/review.md:114-138`) found this clause verdict
  **Incorrect**: proposed but never transcribed into the shipped
  `scout/hooks/directive.sh`/`README.md` — exactly the drift issue-34
  names as its motivating incident. Had the proposal carried "clause:
  total-call-cap=12 -> shipped in: [pending]" as an enumerable checklist
  item, phase 2 would have had to either fill in a commit/hunk pointer or
  explicitly drop it (requiring re-approval) *before* review ran, instead
  of the gap surfacing only in review's independent audit two subjects
  later.
  - Requirement 7b (`docs/issue-23/reports/review.md:198-234`) shows the
    same pattern for the wall-clock-measurement clause: proposed as an
    obligation, only partially fulfilled (extrapolated, not measured),
    verdict Incorrect. A per-clause phase-2 traceability line would have
    forced an explicit "extrapolated, not measured — carrying forward as
    a known gap" note instead of silent under-delivery.
  - No failure signal existed beyond "how we'll know it worked" grep
    checks (`docs/issue-23/proposals/coding.md:118-136`), which are
    success checks, not a stated regression/complaint signal.

**Issue-30** (`db5fda2`, commits `328d21d`/`ddefdc1`): no
`docs/issue-30/proposals/` file exists in history at all (`git log --all
-- docs/issue-30` returns nothing) — this subject's diff
(`scout/README.md`, `scout/hooks/directive.sh`) shipped as a direct fix
without a phase-1 proposal doc, consistent with a pure-bugfix-shaped
change predating or exempted from strict phase gating. The three
amendments in issue-34 are additive to the *proposal* artifact and would
not have applied retroactively to a subject that produced no proposal —
noted as an unknown-by-design rather than a gap.

**Issue-32** (`docs/issue-32/proposals/survey-rigor-floor-and-scout-consumption.md`):
- The proposal already lists its edits as an itemized "File 1/2/3" +
  numbered sub-edits structure (`:36-101`) — closer to a checklist in
  spirit than issue-23's prose constraints, but not phrased as a
  traceability checklist: no per-item marker for "which phase-2 hunk
  fulfilled item 2 of File 2," and no explicit drop/re-approve path if an
  item were cut.
- No alternatives section: single approach only.
- "How success will be judged" (`:102-111`) states verification checks
  (grep/diff/`parse-check.sh` exit 0) — these are success/verification
  checks, not a distinct one-line failure signal (what regresses or what
  complaint recurs if the change is wrong).

## Unknowns

- Whether any other subject's proposal (outside 23/30/32, e.g. issue-14)
  used an alternatives section is not surveyed here — out of the issue's
  named scope (23/30/32 only); not claimed either way.
- Whether phase-2 traceability checklists would have caught defects
  *review* itself later found beyond 4b/7b (e.g. subtler prose drift) is
  not verifiable without re-running review under the amended contract —
  stated as an open question, not resolved by this survey.
