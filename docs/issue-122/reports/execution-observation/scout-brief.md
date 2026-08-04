---
kind: scout-brief
subject: issue-122
produced_by: execution-observation
phase: 1
---

# Scout brief — judging a landed guardrail-guidance change (issue-122, step 2)

Mode: **parallel** — 3 concurrent `WebSearch` angles in one turn, aimed at the
survey's unknowns 1 and 4 (how to report an intervention verdict when the
post-landing window is minutes wide). **1 stage**, saturated at judge point 1:
all three angles converged on the same three must-bes, so a deepening round
would not change a verdict-design decision. Segment fit: the deliverable is a
post-implementation effectiveness judgment on a process guardrail — the same
kind as an SRE action-item verification, not a lab experiment.

## Category must-bes (what strong work of this kind assumes)

- An effect claim is tied to a **named follow-up window**, not to "since it
  landed"; SRE practice verifies remediation "in a follow-up window" and
  reports a *recurrence rate* over it, and teams pick an explicit window
  (e.g. 90 days) knowing edge cases fall outside it. [1][2]
- The action item carries a **verifiable end state** stated up front, so
  "did it work" is answerable rather than argued. [3]
- **Insufficient data is reported as insufficient**, explicitly. The
  post-implementation-review literature treats premature/thin evidence as a
  named, recognized failure mode and faults reviews that stay silent about
  it; PIRs are normally scheduled 1–3 months out precisely so early results
  can surface. [4][5]
- A minimum post-intervention observation count exists before a
  before/after comparison is called one: 3 points per segment is the
  floor commonly used to even qualify as interrupted time series, with
  10–20 typical. [6]

## Performance axes the field competes on

1. **Separating "shipped" from "worked"** — closing the action item vs.
   demonstrating non-recurrence. [3][2]
2. **Honesty about window and power** — stating n and the window before
   stating the effect. [6][4]

## Adopt / skip

- **Adopt:** the SRE split — verify *delivery* (end state reached, checkable
  now) and *effect* (recurrence rate in a named window) as two separate
  claims, and report the second's n explicitly.
- **Skip:** the 1–3-month PIR schedule as a gate on writing anything. The
  contract fixes step 2 to this issue's cycle; the brief's answer is to
  report the window and its n, not to defer the record.

## Gap line

Already met by the current state: the surveyed corpus gives a real
pre-landing baseline (30 core-repo sessions, 2026-07-29 → 2026-08-04 15:09)
and an identified firing signature — the "verifiable end state" and
"measurable recurrence metric" must-bes are satisfied. **Missing:** the
named follow-up window with a usable n — post-landing population is n=1
(this session, landing +2 min), below even the 3-per-segment floor. That
gap is what the proposal's verdict design must target: claim delivery,
report effect as under-powered with its numbers shown.

Sources:
- [1] https://sreschool.com/blog/action-items/
- [2] https://opsera.ai/knowledge-base/incident-analysis/repeat-incident-rate/
- [3] https://sre.google/workbook/postmortem-culture/
- [4] https://www.gao.gov/products/112925
- [5] https://www.atlassian.com/work-management/project-management/post-implementation-review
- [6] https://academic.oup.com/ije/article/46/1/348/2622842
