---
status: proposed
files:
  - docs/issue-263/reports/conformance-review.md
---

## Request

Conformance-review issue #263 (phase-4b-4 record-shape-gate fold): render
a per-requirement verdict (Present|Surface|Absent|Incorrect|Unverifiable)
for the two acceptance checks in the issue body, against the delivered
implementation record and its underlying code, without re-judging code
quality or fixing anything found.

## Constraints

- Verdicts only — no edits to `core/hooks/*`, `scripts/*`, or the
  implementation record itself.
- Work from the artifact and the spec only, not the builder's stated
  intent (contract v3 phase-2 review discipline) — but every claim in the
  record must still be independently re-executed, not read and trusted.
- Record lands at `docs/issue-263/reports/conformance-review.md` per this
  role's fixed record path.

## Rationale

Considered treating the implementation record's own prose (the
disposition table, the quoted command outputs) as sufficient evidence
without re-running anything — rejected: the record-shape-directive and
contract v3 both require conformance review to independently verify
count claims and command outputs, not transcribe the builder's report.
A record that merely restates what `implementation.md` already says
would add no verification value; the survey phase already re-executed
the extractor, the config-sum check, and the fast tier, and phase 2 is
where those live results turn into Present/Absent verdicts per
requirement rather than a pass/fail on the whole PR.

Considered scoring on the disclosed "59 of 145 rows not individually
hand-verified" gap as an automatic Absent/Incorrect on R1 — rejected: the
acceptance check's literal text is "disposition/extraction table ... 
summing to 145, plus the extractor command executed-live," which the
survey confirmed is met exactly as written; the hand-verification gap is
a deviation the record itself discloses against the *proposal's* stated
method, not against the *issue's* acceptance text, so it becomes a
distinct finding (likely Surface or a noted caveat) rather than folding
into R1's verdict silently.

## What will be done

- Re-confirm the five live checks from the survey (extractor total,
  disposition-table row count, config JSON row sum, fast-tier run,
  coverage — role/check_type counts) hold at review time.
- Write `docs/issue-263/reports/conformance-review.md` with frontmatter
  (`code_under_review`, `loop_state`, `type`, `breaking`, `verdict`) and
  a per-requirement verdict table for R1a/R1b/R2a/R2b/R2c (see survey.md),
  each verdict citing the actual command run and its output.
  A `## Rationale for deviations` section is added only if a re-run at
  review time surfaces a divergence from what the survey found (none
  expected, since the survey already ran the same commands).
- Include the disclosed hand-verification gap (59/145 low-confidence rows)
  as an explicit finding addressed to the implementation role, distinct
  from the R1/R2 verdicts, with severity left unclassified unless the
  optional severity-classification skill is invoked separately.
- `## What did not work` heading present (content "None." unless a
  re-run surfaces a discrepancy).

## Out of scope

- Hand-verifying the 59 low-confidence config rows against their source
  hooks individually — that is implementation-role remediation work, not
  a conformance-review verdict-writing task.
- Any code fix, including the Bash fail-closed behavior already fixed in
  the reviewed commit.
- Re-reviewing #254/#257/#260's prior folds; scope is #263 only.

## How you'll know it worked

- `docs/issue-263/reports/conformance-review.md` exists with the required
  frontmatter fields, a `## What did not work` heading, a verdict per
  requirement (R1a/R1b/R2a/R2b/R2c), each citing a re-executed command
  and its literal output, and the hand-verification-gap finding recorded
  and addressed to the implementation role.
- `loop_state` reflects the record's true state (`landed` if the review
  is complete and no further action is owed by this role).
