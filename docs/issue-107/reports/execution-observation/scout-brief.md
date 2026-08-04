---
kind: scout-brief
subject: issue-107
produced_by: execution-observation
loop_state: scouted
---

# Scout brief — issue-107 / execution-observation

Pass shape: **2 stages, parallel mode** (stage 1 sweep = 3 concurrent
subagents, one message; stage 2 = judge point 1, saturation reached — a
further deepening round would not change any check in the proposal, so
deepening stopped inside budget). Angles were aimed at the survey's own
unknowns: U5 (spec-vs-gate scope), U2/U3 (claimed-but-unlogged evidence),
and the defect class itself.

## Category must-bes (what strong reviews of this change-class assume)

- The fixed question has exactly **one** canonical parser; no sibling path may
  re-derive the same answer from raw input. "Parser differential" is a named
  bug class and its prescribed remedy is consolidation, not a point-fix.
  <https://iterasec.com/blog/understanding-parser-differential-vulnerabilities/>
- The reviewer explicitly sweeps for **other call sites with the same defect
  class**, not just the flagged one. <https://amplify.security/blog/code-review-security-checklist>
- The regression test is **shown to fail pre-fix**, not assumed to; a test
  added alongside a fix that never ran red is treated as false coverage.
  <https://cleancodeguy.com/blog/tdd-red-green-refactor>
- A tool-forced deviation is acceptable only when **scoped to exactly what the
  gate mandated** — anything beyond that reverts to an ordinary reviewable
  scope change. <https://www.atlassian.com/work-management/project-management/scope-creep>
- A broad regex/pattern gate hit is a **prompt for judgment, not proof of
  policy intent**; policy-as-code practice records the reason at the point of
  occurrence rather than treating pattern-match as compliance.
  <https://rallyhealth.github.io/conftest-policy-packs/exceptions/> · <https://golangci-lint.run/docs/linters/false-positives/>
- A claim about an execution that left no artifact sits at the **assertion
  tier** of the evidence hierarchy; the verdict must label the tier and lean on
  internal-consistency cross-checks, never present it as reperformed.
  <https://cpcongroup.com/types-of-audit-evidence/> · <https://www.agwa.name/blog/post/verifying_go_reproducible_builds>

## Performance axes this observation will compete on

1. **Sibling-site sweep depth** — point-fix accepted vs. same-defect-class
   siblings named. 2. **Evidence-tier honesty** — which verdicts rest on
   reperformable artifacts vs. on the observed role's assertion, stated as
   such. 3. **Deviation minimality** — was the tool-forced write exactly the
   gate's minimum.

## Adopt / skip

- **Adopt:** explicit evidence-tier labels per verdict (assertion vs.
  artifact-derived), and a named sibling-call-site check for the parser-
  differential class.
- **Skip:** attestation/provenance machinery (SLSA, signed run records) — real
  practice for this gap, but out of scope for a judgment record and not
  something this role may build.

## Gap line

Already met by the current state (this role's merged records for issue-98 and
issue-99): red-green scrutiny, citation adjacency, four-part blameless
findings. **Missing:** the evidence-tier label for unrepeatable claims (survey
U2/U3), and an explicit sibling-call-site sweep for the same index-assumption
defect class the fix removed from one function.

## Segment fit

Same segment: an independent post-merge judgment of a security-gate parser
fix, judged against audit-evidence and change-control practice rather than
product-review practice.

Sources: the seven URLs inline above, plus
<https://langsec.org/papers/langsec-cwes-secdev2016.pdf> (shotgun-parsing
anti-pattern) and <https://simplerqms.com/change-control/> (deviation from an
approved baseline is a change-control event, not a silent absorption).
