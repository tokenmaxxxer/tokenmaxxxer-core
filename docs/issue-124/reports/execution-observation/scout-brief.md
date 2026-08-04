---
kind: scout-brief
subject: issue-124
produced_by: execution-observation
phase: 1
---

# Scout brief — auditing a "defect class is now exhausted" claim (issue-124, step 2)

Mode: **parallel** — 3 concurrent subagent angles dispatched in one turn
(class-exhaustion practice; judging a self-reported verification without
re-running it; the external flag-grammar facts). **2 stages** (sweep +
judge point 1), saturated: all three angles converged on the same must-be
— a textual sweep is not itself closure evidence — so a deepening round
would not change a verdict-design decision. Segment fit: the deliverable
is an auditor's judgment on someone else's *class-elimination* claim, the
same kind as variant-analysis review, not a bug hunt.

## Category must-bes (what strong work of this kind assumes)

- **A grep/textual sweep alone is explicitly not sufficient** for a
  bug-class claim; the field's standard is a semantic/dataflow query,
  because textual matching misses variants "that could be missed using
  traditional manual techniques". [1]
- **What the sweep covered and what it did not find are first-class
  deliverables**, not implied: Project Zero's own RCA template carries
  dedicated "Areas/approach for variant analysis" and "Found variants"
  fields. [2]
- **An incomplete class fix is the normal failure mode, not the exotic
  one** — CVE-2022-21882 was a bypass of the CVE-2021-1732 patch because
  the earlier fix "was not fixed completely". [3]
- **A self-report of verification is the weakest evidence tier and never
  free-standing**: inquiry of the preparer "does not provide sufficient
  audit evidence" on its own; written representations are supplementary,
  never a substitute for evidence reasonably expected to exist. [4][5]
- **The limits of what the reviewer could and could not verify are
  disclosed**, not silently implied as full assurance. [6]

## Performance axes this field competes on

1. **Sweep breadth vs. sweep semantics** — how much of the class the
   method can see at all, versus how many sites it lists. [1]
2. **Corroboration independence** — evidence the reviewer obtained
   directly outranks evidence relayed by the doer. [4]

## Adopt / skip

- **Adopt:** demand the artifact of the sweep, not the claim — what query
  ran, over what area, and what it structurally cannot see [2]; and
  cross-check the record's numbers against the diff as documentary
  evidence rather than accepting the narrative. [4][6]
- **Skip:** re-running the observed suites to settle the numbers. Barred
  by this role's own independence rule, and the audit standards' answer to
  "cannot re-perform" is corroboration + disclosed limits [5][6], not
  re-performance.

## Gap line

**Already met by the current state:** the observed record does publish its
sweep method verbatim and its full hit list
(`docs/issue-124/reports/implementation.md:346-368`), which satisfies the
"state the method and the negative result" must-be [2].
**Missing:** the sweep is two `git grep` invocations — exactly the textual
tier the field says cannot close a class [1]. And a second axis is not
grep-visible at all: whether the *flag-grammar tables* the fix introduces
are complete against the specs they claim to mirror. Angle 3 returned the
sourced spec facts that make that axis checkable — GNU `env` documents
`-C/--chdir`, `-S/--split-string`, `-a/--argv0` alongside `-u` [7];
`timeout` documents `-k/--kill-after` alongside `-s` [8]; `xargs`
documents `-n`, `-L`, `-P`, `-s`, `-a` alongside `-I` [9]; and git's own
`handle_options()` accepts the space-joined form for `--git-dir`,
`--work-tree`, `--namespace`, `--config-env`, `--attr-source`, not only
for `-C`/`-c` [10][11]. These are field facts recorded here for the phase-2
check to run against; this brief draws no conclusion about the artifact.

Sources:
- [1] https://codeql.github.com/docs/codeql-overview/about-codeql/
- [2] https://cve-north-stars.github.io/docs/Templates/Google-Project-Zero-Template/
- [3] https://projectzero.google/2022/04/the-more-you-know-more-you-know-you.html
- [4] https://pcaobus.org/oversight/standards/auditing-standards/details/AS1105
- [5] https://www.ifac.org/system/files/publications/files/A033%202012%20IAASB%20Handbook%20ISA%20580.pdf
- [6] https://www.isaca.org/resources/it-audit
- [7] https://man7.org/linux/man-pages/man1/env.1.html
- [8] https://man7.org/linux/man-pages/man1/timeout.1.html
- [9] https://man7.org/linux/man-pages/man1/xargs.1.html
- [10] https://raw.githubusercontent.com/git/git/master/git.c
- [11] https://git-scm.com/docs/git
