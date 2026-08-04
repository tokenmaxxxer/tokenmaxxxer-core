---
kind: scout-brief
subject: issue-106
produced_by: execution-observation
loop_state: scouted
---

# Scout brief — issue-106 step 2 (observation of PR #111)

**Mode and budget, stated plainly.** Parallel fan-out, not batched-sequential:
stage 1 was 4 `Agent` calls issued concurrently in one message; stage 2 was 2
more, likewise concurrent. **2 of the 5 allowed stages used.** Wall clock from
sweep dispatch to last return was **~20 minutes, well over the 3-minute soft
budget** — the overrun came from stage 2, which resolved a contradiction that
would otherwise have mis-aimed the whole evidence plan (see GAP line 3). Angles
were derived from the survey's five open unknowns, per survey-first order.

**Segment fit.** The deliverable is an audit of a *written control with no
automated enforcement* — the observed §22 is prose the operator is asked to
follow, and this repo has no runtime check for it. So the field scouted is
control-effectiveness testing plus LLM instruction-adherence measurement, not
code review.

**Category must-bes.** (1) Separate *design* effectiveness (the control exists,
point-in-time, one example suffices) from *operating* effectiveness (it operated
consistently over a period, needs dated instances) — design first, since you
cannot test operation of something not shown to exist [linford-design].
(2) Name a population, a sample and a period; type-II style evidence is dated
artifacts across a window, never one snapshot [soc2auditors, konfirmity].
(3) Do not rest on inquiry/self-report — "inquiry alone does not provide
sufficient appropriate evidence of operating effectiveness" [linford-testing];
sharpened for LLM operators by the Compliance Gap result, where models verbally
agree to a process rule and then bypass it, undetectably from text alone
[compliance-gap]. (4) Classify the control explicitly: a prose rule with no
gate is *manual preventive*, the weakest evidentiary class [linford-testing].
(5) Show the control text actually reaches the operator, at a position where it
is used — recall is highest at context start/end and degrades in the middle
[lost-in-middle]. (6) Test the conflict case, not the happy case: instruction
hierarchies are exactly where models fail when directives contradict
[control-illusion, openai-hierarchy].

**Performance axes.** Evidentiary rigor vs. assertion (named population,
sample, period, artifact pointers); separation of "well-written" from "actually
followed"; honest treatment of the detection gap.

**ADOPT — a two-column design/operating verdict, with operating effectiveness
marked by its actual sample size rather than blurred into the design finding**
[linford-design]. Reason: it converts a soft "looks fine" into a scoped,
defensible claim, and requirement 3 is precisely an operating question.
**SKIP — drawing any compliance conclusion from a session's own narration that
it followed the rule** [linford-testing, compliance-gap]. Reason: inquiry-only
evidence, and verbal agreement is empirically decoupled from behavior; the
phase-2 evidence must be tool-call records, not assistant prose.

**GAP line — which must-bes the current state already meets, and which are
missing.** Met: (1) design evidence exists (the §22 diff, `ce4e81c`) and (5)
delivery-to-operator evidence is reachable (the clause appears in the injected
`hook_response` record of every post-landing session log). Missing / thin:
(2) the population is n=4 completed post-landing sessions inside one ~30-minute
window — a period far short of any operating-effectiveness window, which must
be stated rather than papered over; (4) the control's class is unstated in the
observed record; (6) the conflict case is documented in prose but its
*mechanical* counterpart — `freelunch/hooks/observe.sh`, which denies exactly
the same-turn behavior §22 requires — was not amended and is unexamined by the
observed record. Gap (6) is where phase 2's step-level attention goes.

Sources:
- https://linfordco.com/blog/design-vs-operating-effectiveness/ [linford-design]
- https://linfordco.com/blog/audit-procedures-testing/ [linford-testing]
- https://soc2auditors.org/insights/soc-2-type-2-controls/ [soc2auditors]
- https://www.konfirmity.com/blog/soc-2-evidence-requirements [konfirmity]
- https://arxiv.org/abs/2605.01771 [compliance-gap]
- https://cs.stanford.edu/~nfliu/papers/lost-in-the-middle.arxiv2023.pdf [lost-in-middle]
- https://arxiv.org/pdf/2502.15851 [control-illusion]
- https://openai.com/index/the-instruction-hierarchy/ [openai-hierarchy]
- https://arxiv.org/html/2512.14754v1, https://arxiv.org/abs/2311.07911 (instruction-following reliability, IFEval)
