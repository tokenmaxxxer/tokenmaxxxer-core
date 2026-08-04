---
kind: scout-brief
subject: issue-128
produced_by: execution-observation
phase: 1
---

# Scout brief — judging a landed convention + mechanical-check change (issue-128, step 2)

Mode: **parallel** — stage 1 ran 4 concurrent `WebSearch` angles in one turn
(rule-audit, requirements traceability, audit-evidence sufficiency,
defect-class sweep), aimed at survey unknowns 1-4. Angle 1 came back
off-segment (compliance/security audit checklists, not static-analysis rule
review) and was swapped at judge point 1 for a software-terminology retry;
stage 2 ran that retry plus one snowball from stage 1's cognate-defect hit,
2 calls concurrently. **2 stages**, then saturated: the remaining angles
converged on the same four must-bes and another round would not change a
verdict-design decision. Segment fit: the deliverable is a post-landing
conformance judgment on a convention plus its enforcing check — the same
kind as an audit of a control's design *and* operating effectiveness, not a
code review of a feature.

## Category must-bes (what strong work of this kind assumes)

- **Both traceability directions.** Forward: each requirement maps to a
  delivered artifact. Backward: anything delivered that traces back to no
  approved requirement is surfaced — backward traceability is specifically
  what protects scope integrity and catches implementation added without
  approval. [1][2]
- **The evidence tier is named.** Testing tiers run inquiry → observation →
  inspection of documentation → re-performance, weakest to strongest; when
  re-performance is unavailable, inspection of documentation is admissible
  evidence, but only when the documentation meets the "experienced auditor"
  bar — detailed enough that another auditor could re-perform and reach the
  same result. [3][4]
- **A new static rule is judged on false negatives, not only false
  positives.** Rule review practice = read the rule's specification and
  implementation, check it against historical issues/fixes, and apply
  mutations to inputs to manifest FN/FP. Linters conventionally aim at zero
  false negatives while minimizing false positives. [5][6]
- **One fixed instance triggers a class sweep.** Defect analysis clusters by
  class and treats a single-instance fix as symptom treatment; the systemic
  move is scanning for cognate instances elsewhere — the same premise
  behind auto-generating rules from a patch to find its cognate defects
  across a codebase. [7][8]

## Performance axes the field competes on

1. **Traceability completeness in both directions** — requirement↔artifact,
   plus the unasked-for delta. [1][2]
2. **Evidence-tier honesty** — stating which tier each claim rests on rather
   than presenting inspection as if it were re-performance. [3][4]
3. **False-negative reach of the new rule** — mutation-style probing of
   inputs the rule should have caught. [5]

## Adopt / skip

- **Adopt:** mutation-style FN probing performed *by reading* — construct
  candidate inputs on paper against the delivered regex as it appears in the
  diff, never by executing the observed role's suite (execution is barred
  for this role, so the probe stays inspection-tier and says so). [5][3]
- **Adopt:** the class sweep as a `grep`-level survey of cognate habitats,
  feeding contract §20's defect-class-and-other-habitats question directly.
  [7][8]
- **Skip:** auto-generated rule synthesis from the patch (Patch2QL-style) —
  right idea, wrong scale for a one-regex change; the manual cognate sweep
  captures the same signal here. [8]
- **Skip:** re-performance as an evidence tier at all; substitute an
  explicit statement of which tier each verdict rests on. [3]

## Gap line

Already met by the current state: forward-traceability inputs exist and are
readable — the issue's three numbered requirements, the proposal's
five-clause `## What will be done`, and the record's item-by-item
`## What was done` with a `## Verify` block quoting suite output
(`docs/issue-128/reports/implementation.md:24-72,164-193`), which is
documentation at roughly the experienced-auditor bar for the delivery
claims. **Missing:** (a) the backward direction — nothing yet checks whether
what landed (contract §1/§12) is what the requirement asked for (§20
family), or whether anything landed that no requirement asked for; (b) any
false-negative probe of the new regex beyond the five happy/deny cases the
delivery itself wrote; (c) any cognate-habitat sweep for the placeholder
class outside `sha:` under `docs/issue-<n>/proposals/`. Those three are
exactly what the proposal's verdict design targets.

Sources:
- [1] https://www.perforce.com/resources/alm/requirements-traceability-matrix
- [2] https://www.trace.space/blog/what-is-requirements-traceability
- [3] https://www.graduateschool.edu/learn/audit/evidence-tests
- [4] https://pcaobus.org/oversight/standards/auditing-standards/details/Auditing_Standard_13
- [5] https://arxiv.org/pdf/2408.13855
- [6] https://medium.com/codacy/7-drawbacks-of-linting-tools-for-static-analysis-ac0cb70e73fa
- [7] https://bug0.com/knowledge-base/defect-analysis
- [8] https://arxiv.org/abs/2401.12443
