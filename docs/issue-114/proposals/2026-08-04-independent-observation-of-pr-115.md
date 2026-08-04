---
kind: proposal
subject: issue-114
produced_by: execution-observation
loop_state: phase-1
upstream:
  - path: docs/issue-114/reports/execution-observation/survey.md
  - path: docs/issue-114/reports/execution-observation/scout-brief.md
---

# Proposal — independent observation of PR #115 (issue-114 step 2)

## Subject

Issue #114's execution plan step 2. The observation target is the
`implementation` role's session on branch `issue-114/implementation`,
delivered as **PR #115** (merged `451439e`), commits `71f1104` (phase 1)
and `e51b301` (phase 2), together with that role's own record
`docs/issue-114/reports/implementation.md`. The user's step-2 framing adds
one scope item beyond the ordinary three-level judgment: whether the
wrapper parser-differential class traced #99 → #107 → #114 is exhausted by
this delivery, or whether the same class still has other habitats — a
whole-population question, to be answered from measured evidence only.

This proposal names what will be checked and against what. It renders
nothing about the target. No judgment of PR #115 — provisional, partial,
or otherwise — appears in this document.

## Which verdict levels will be checked, and against what

All three contract levels will be addressed; a level that turns out not to
apply will be written as "not applicable, because X" rather than dropped.

1. **Outcome** — did PR #115 land what issue #114 asked. Evidence: the
   issue body's three numbered `## 요구사항` and two `## 제약` items, each
   adjudicated against (a) the `e51b301` diff of
   `core/hooks/board-gate.sh` and `core/hooks/tests/run-board-gate-tests.sh`,
   (b) the `git show --stat` of both commits for the untouched-files
   constraints (`gate_trailing_words`, `_cd_target`, the `TRANSPARENT`
   tuple), and (c) the `closed_checks[]` entries of
   `docs/issue-114/reports/implementation.md:142-181` for the red→green
   requirement, which is a claim about a test run this role does not
   re-execute and therefore assesses as a record claim, tier-marked as
   such.

2. **Trajectory** — was the phase-1 → approval → phase-2 path the one
   contract v3 §19 prescribes. Evidence: the five timestamps tabulated in
   the survey (`71f1104` stat proving the phase-1 commit carried no code;
   PR #115 `createdAt`; the issue-#114 comment body, author, and
   `created_at` from the GitHub API; `e51b301` commit date; `mergedAt`),
   plus `gh pr view 115 --json reviews` → `[]`, plus
   `docs/specs/approvers.md`, read against contract v3 §19's two approval
   paths. Ordering will be established from timestamps, never inferred
   from document order. Also checked at this level: whether a survey
   preceded the proposal (`71f1104` contains both) and whether the
   proposal's scout-directive skip record states a condition §19 admits.

3. **Step** — which specific artifact, if any, is deficient. Candidate
   artifacts, each read at a pinned SHA: the record
   (`docs/issue-114/reports/implementation.md`), the proposal
   (`71f1104:docs/issue-114/proposals/2026-08-04-fix-board-gate-wrapper-git-subcommand-extraction.md`),
   the survey (`71f1104:docs/issue-114/reports/implementation/survey.md`),
   the test additions and the handbook entry (both in the `e51b301` diff).
   Survey unknowns U1, U2, U4, U5 enter here. Any confirmed deficiency is
   written in the four-part blameless shape (impact / timeline / root cause
   / action item), one charge per artifact defect, with the action item
   left to the human — this role files no issues.

## The five check points, and the evidence each rests on

**Check point 1 — requirement coverage.** Each of issue #114's three
requirements and two constraints, one at a time, against the `e51b301`
diff and `--stat`. Requirement 2 (red→green, including one pre-#98
argument-less wrapper and the reverse write direction) is checked in two
halves: the *cases* exist and have the stated shapes (verifiable from the
diff), and the *run results* were as recorded (a record claim, not
independently verifiable here — tier-marked).

**Check point 2 — approval typing and ordering.** Whether the approval
that opened phase 2 is the kind §19 admits given `reviews: []`, a PR
author of `jjongkwann`, and an approvers.md containing both `jjongkwann`
and `JiwonJung94`; and whether the phase-2 commit followed it. Evidence:
the byte-exact comment body from the API, `docs/specs/approvers.md`, and
the timestamp table. The comment string will be compared for exact
equality, not read for intent.

**Check point 3 — record self-consistency.** Whether the record's own
statements hold against the artifacts it cites: `## Open findings: None`
(`:183-185`), `## Next steps` (`:187-196`), the deviation rationale for the
handbook touch (`:59-76`), the `closed_checks[]` refs (`:142-181`), and
the issue-100 citation canon (U5). Evidence: the record read against the
`e51b301` diff and against
`docs/issue-100/decisions/2026-08-03-record-citation-format-and-kind-convention.md`
at a pinned SHA.

**Check point 4 — U1, the Hunt's generalization evidence.** Whether the
probe shapes the record's `## Hunt` (`:111-140`) and its fifth
`closed_checks` entry (`:173-181`) rely on actually exercise the branch
they were chosen to exercise. Evidence: a hand-trace of
`451439e:core/hooks/lib/gate-lib.py:203-235` (already read this session)
against each probe shape the record names, plus a pinned read of
`451439e:core/hooks/board-gate.sh`'s `_segment_is_failing` to establish
which branch each resolved head reaches. Static reasoning over pinned
blobs only — the probes are not re-run.

**Check point 5 — U3, class exhaustion (the population question).** Whether
the wrapper parser-differential class — two different command-start models
inside one decision path — still has habitats outside the site #114 fixed.
Method: enumerate every site in the repository that locates a positional
word by re-splitting raw command text; for each, read the pinned blob,
state whether a `TRANSPARENT` wrapper prefix can actually reach it, and
state the misread direction (fail-closed over-block vs. fail-open
bypass). Sites already nominated by this session's search pass, each to be
re-read at a pinned SHA before it is cited: `core/hooks/approval-gate.sh`,
`core/hooks/trailer-gate.sh`, `warrant/hooks/scope-gate.sh`,
`board-gate.sh`'s own `INPLACE`/`FILE_REDIR`/`SED_WRITE_CMD` scans, the
documented wrapper-own-value-flag limitation in
`core/hooks/lib/gate-lib.py`, and the `git -C <dir>` global-flag gap both
the observed proposal and record already name. The output is a
per-site table with a direction column, and an explicit statement of
whether the population was covered exhaustively or only partially — with
the uncovered remainder named if partial. This check point is scoped
deliberately: a habitat outside PR #115's write set is a finding about the
*codebase*, reported for the human to judge, never a charge against the
observed delivery unless issue #114's own text placed it in scope.

## Method and its limits

- **No re-execution.** `run-board-gate-tests.sh`, `run-gate-lib-tests.sh`,
  `run-gh-guard-tests.sh`, and `board-gate.sh` itself are not invoked. The
  record's counts (`87 passed / 2 failed` red, `89 passed / 0 failed`
  green, `53/1` gate-lib, `52/0` gh-guard) are treated as record claims and
  labelled as such wherever they are used.
- **Pinned reads only.** Every code citation is `<sha>:<path>:<line>` at
  `451439e` or at the commit that introduced the line, never a working-tree
  read and never a floating `origin/main`.
- **Source code is not evidence of conduct.** `core/` files are read for
  two purposes only: checking the internal consistency of a claim the
  observed record itself makes (check point 4), and the population question
  (check point 5). What the observed role did and decided is established
  from the diff, the commit messages, the PR metadata, and that role's own
  record — never from the current contents of a source file.
- **Evidence tiers.** Each claim in the record is marked *artifact* (direct
  read of a blob, diff, or GitHub API record), *analytic* (derived by
  reasoning over committed text), or *out of reach* (stated as unjudged).
- **Independence.** This role did not author, edit, or contribute to PR
  #115, its commits, or the `implementation` record. The phase-2 record
  will carry that statement before any verdict language, and this session's
  write surface stays inside the three phase-1 paths named in the survey
  plus `docs/issue-114/reports/execution-observation.md`.

## Alternatives considered and rejected

1. **Re-run the board-gate suite to confirm the 89/0 claim independently.**
   Rejected: this role's standing prohibition is that the observed role's
   produced artifacts are the only admissible evidence and its task is
   never re-executed. The red→green claim is therefore adjudicated as a
   record claim with an explicit tier mark, and the loss of certainty is
   stated rather than hidden.
2. **Scope the observation to outcome only, treating the class-exhaustion
   question as a separate exercise.** Rejected: the three-level verdict is
   mandatory, and the user's step-2 framing names the population question
   explicitly. Deferring it would leave the level-3 (step) judgment
   answering a narrower question than the one asked.

## Failure signal

If a claim cannot be pinned to a named-SHA blob, a diff, or a GitHub API
artifact read in this session, it is recorded as out of reach and left
unjudged — it is never asserted at a lower confidence. Specifically: if
check point 5's enumeration cannot be shown to be exhaustive (for example
because a habitat class exists that no static read can enumerate), the
record states "the population could not be closed, because X" and lists
what was covered, rather than reporting exhaustion it did not establish.
Likewise, if U1's hand-trace and the record's probe account cannot be
reconciled from pinned blobs alone, that is written as an unreconciled
discrepancy with both readings shown, not as a charge.

## Phase-2 deliverable

One file: `docs/issue-114/reports/execution-observation.md`, written as the
first act of phase 2, with `loop_state` updated at each transition, the
independence statement ahead of all verdict language, the three verdict
levels, the five check points above, any findings in the four-part
blameless shape, an explicit "what is not deficient" section, and the
method-limits section. Committed on this branch and delivered through this
PR. No other path is written.

## Out of scope

- Any edit to `core/`, to `docs/issue-114/reports/implementation*`, or to
  any artifact of the observed role. Findings return only in this role's
  own record.
- Filing any GitHub issue. Under contract v3 issues are user-authored; a
  confirmed deficiency is recorded here for the human to judge and file.
- Judging issue #116, PR #117, or issue #118 — all outside PR #115. Issue
  #118 is noted only because it names the same class lineage; it is not
  observed, assessed, or acted on by this session.
- Re-observing PR #108 (issue #107) or PR #102 (issue #99). Their records
  are read as ledger input for check point 5 and as format exemplars, not
  as observation targets.
- The merge decision itself. PR merge is the human's act of acceptance;
  this role reports, it does not ratify.
