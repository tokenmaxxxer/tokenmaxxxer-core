---
issue: 99
stage: scout-brief
produced_by: execution-observation
---

# Scout brief (issue-99, execution-observation)

Mode: **parallel WebSearch fan-out, 4 angles, 1 round**, aimed at the
survey's U1/U2/U4/U5. Stopped at judge point 1 — all four angles
converge on the same two must-bes below, so no deepening round (2
stages used of 5).

## Category must-bes (what a strong observation of this change-class checks)
- **Reachability claims carry an inspectable path, not a verdict.** Zero
  coverage does not prove unreachable, and reachable-but-untested is a
  distinct case; the field's complaint about weak tools is exactly "a
  verdict with no evidence: no call chain you can inspect" [1][2].
  Branch coverage in particular can pass while hiding the defect [3].
- **Red-green is the evidence standard for a regression case**:
  previously-failing now passes AND previously-passing still passes,
  documented per case [4][5].
- **A merged control is not a verified control.** Remediation is
  "execute, verify, stabilize", not "apply and hope"; a control counts as
  effective when it demonstrably changes behaviour and leaves an audit
  trail, not when it merges [6][7].
- **Two PRs touching functionally related regions of one file can both
  merge cleanly and still break** — git detects no logical conflict;
  detection needs behaviour-level reasoning [8][9].

## Performance axes this observation competes on
1. Citation density per verdict (SHA / file:line adjacency).
2. Diff-only evidence discipline — no re-execution, no current-`src/` reads.
3. Coverage of the cross-change (issue-98 × issue-99) seam, which neither
   session's own record is positioned to check.

## Adopt / skip
- **Adopt**: per-branch reachability inspection on the `232e2aa` diff —
  for each branch the diff adds, name the test case in the *same diff*
  that enters it, or record it as unproven [1][3].
- **Adopt**: read the record's red-green claim as a claim, and check its
  internal arithmetic against the commit message and the test hunk [4].
- **Skip**: coverage tooling / mutation testing — requires re-execution,
  which this role is prohibited from doing; substitute is diff-plus-case
  inspection.
- **Skip**: any "re-scan with the same tool" post-fix validation [6] —
  same prohibition; substitute is other roles' *recorded* live gate events.

## Gap line
Already met by the observed session: red-green fail-first evidence
(`docs/issue-99/reports/implementation.md:152-162`) and an explicit
requirement-4 reachability argument (`:144-147`). Missing, and therefore
where this observation must aim: (a) whether that reachability argument
holds against the diff rather than against its own prose, (b) the
logical-conflict seam with `e51bc09` in the same file [8], (c) any
post-merge behavioural evidence at all [6][7] — the record's evidence
all predates the merge.

Sources:
1. https://www.endorlabs.com/learn/reachability-analysis
2. https://www.aikido.dev/code-quality/rules/how-to-identify-and-remove-unreachable-dead-code
3. https://blog.regehr.org/archives/872
4. https://www.browserstack.com/guide/regression-testing
5. https://leapwork.com/blog/regression-testing/
6. https://reclaim.security/blog/why-security-fixes-break-production/
7. https://nhimg.org/faq/how-can-organisations-tell-whether-devsecops-controls-are-actually-working/
8. https://medium.com/@elischleifer/what-is-a-logical-merge-conflict-c6525acead85
9. https://spgroup.github.io/papers/semantic-conflicts-testing.html
