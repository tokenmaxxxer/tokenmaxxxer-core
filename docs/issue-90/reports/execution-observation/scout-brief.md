---
kind: execution-observation-scout-brief
subject: issue-90
produced_by: execution-observation
loop_state: proposed
upstream: []
---

# Scout brief — what a strong audit of "gate fix + regression cases" checks

Deliverable kind scouted: an **independent execution observation** of a
merged gate-hardening PR, judged from artifacts only. Angles were aimed
at survey gaps G1-G5 (do the new cases discriminate; do denies deny for
the named reason; did the mitigation narrow protection).

## Category must-bes

- A regression test only counts if it would **fail against the
  pre-change code** — the mutation-testing "kill the mutant" criterion:
  a test that passes on both old and new code proves nothing about the
  fix. [1][2]
- A test that passes without exercising the intended assertion is a
  **vacuous pass**, a recognised defect class, not a nitpick. [3]
- Exit-code-only assertion is a known **false-pass generator**: the
  Linux kernel selftest harness carries a dedicated patch series for
  "avoid false negatives if test has no ASSERTs", and shell-harness
  practice is that a negative case must assert *the right error*, not
  merely non-zero. [4][5]
- Claim admissibility: a "N passed, 0 failed" line is **not** evidence
  that those tests correspond to the merged code; audits verify claims
  against the underlying artifacts instead of the self-report. [6]
- Security-filter fixes are checked for **scope regression** — whether
  the reordering that fixed a false positive also moved a check past
  something it used to cover; changing two things at once obscures which
  one moved the boundary. [7]

## Performance axes this observation competes on

1. Discrimination — per new case, would the verdict differ under `c66aecc^`.
2. Reason-reachability — which `deny()` each deny case actually reaches.
3. Protection-scope delta — did any pre-change guarantee narrow.

## Adopt / skip

- **Adopt**: static mutant-kill trace (old code vs new code, per case
  literal) plus a deny-path trace, both done by reading `c66aecc` /
  `c66aecc^` blobs — no execution required, which matches this role's
  prohibition on re-running the observed work. [1][4]
- **Skip**: running a mutation tool, or re-running either harness. The
  field's tooling assumes you own the code; this role does not, and
  re-execution is inadmissible evidence here.

## Gap line

Already met by the observed work: negative-space siblings exist for
every new allow case (`c66aecc` harness diffs), and the record names its
own vacuous-test episode. **Missing**: nothing in either harness asserts
a deny *reason* (`run-board-gate-tests.sh:22-28,42`;
`run-approval-gate-tests.sh:21-27,103`), and no artifact demonstrates
that any new case fails on `c66aecc^`. Those two are exactly what this
observation must supply by static trace.

## Segment fit

Same segment: post-merge, artifact-only verification of a self-reported
green suite — the "evidence, not the log line" pattern. [6]

## Pass shape

2 stages (1 parallel sweep of 4 angles + 1 judge point), **parallel
mode** (4 concurrent `WebSearch` calls in one turn). Saturation reached
at judge point 1: no further round would change the adopt/skip decision.

Sources:
1. https://en.wikipedia.org/wiki/Mutation_testing
2. https://dl.acm.org/doi/10.1145/3530786
3. https://www.researchgate.net/publication/220958334_Vacuity_in_Testing
4. https://lkml.iu.edu/hypermail/linux/kernel/2201.3/04549.html
5. https://github.com/shellspec/shellspec/issues/60
6. https://arxiv.org/html/2607.14890
7. https://www.penligent.ai/hackinglabs/cve-2026-59083/
