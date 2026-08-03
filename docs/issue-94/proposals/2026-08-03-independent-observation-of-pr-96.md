---
kind: proposal
subject: issue-94
produced_by: execution-observation
loop_state: phase-1
upstream:
  - path: docs/issue-94/reports/execution-observation/survey.md
  - path: docs/issue-94/reports/execution-observation/scout-brief.md
---

# Proposal — independent execution observation of PR #96 (issue-94 step 2)

## Subject

The `implementation` role's phase-1→phase-2 execution on issue #94,
delivered as PR #96 (`issue-94/implementation` → `main`, merged
2026-08-03T05:36:18Z), commits `74c790d` (propose) and `c9a63b4`
(deliver), with its own account at
`docs/issue-94/reports/implementation.md`. Everything read to establish
that scope is listed in `docs/issue-94/reports/execution-observation/survey.md`.

## Which verdict levels this observation will check, and against what

Stated before any evidence work, per the role's phase-2 contract. All
three levels will be addressed; if a level turns out not to apply it will
be written as "not applicable, because X" rather than omitted.

1. **Outcome** — whether PR #96 landed what issue #94 asked for.
   Evidence: the issue's four numbered requirements and two constraints
   (`gh issue view 94` body) read against the source diff of `c9a63b4`
   for `core/hooks/lib/gate-lib.py`, `core/hooks/board-gate.sh`,
   `core/hooks/approval-gate.sh`, `core/hooks/gh-guard.sh`, and against
   the test diff for the three changed harnesses.
2. **Trajectory** — whether the phase-1→phase-2 path was sound: did the
   session survey before proposing, did it check the reuse question
   requirement 2 demands *before* deciding against segmentation, and did
   real human approval open phase 2. Evidence: `74c790d`'s two docs
   (`survey.md`, the proposal) versus `c9a63b4`'s delivery; PR #96's
   `reviews` array; the issue-level comment body; `docs/specs/approvers.md`.
3. **Step** — which specific artifact, if any, is deficient. Evidence:
   per-artifact, at file:line within a named blob — the four source
   files, the three test files, the four handbook entries, and the
   record's own front matter and `closed_checks`.

## Evidence plan — the probes, each tied to a survey unknown

- **P1 (U1) — per-case before/after.** For each of the 9 new hook-level
  cases (4 in `run-board-gate-tests.sh`, 5 in `run-gh-guard-tests.sh`),
  determine analytically from the `74c790d` pre-image regexes whether the
  case's input produces the opposite verdict at the pre-image, i.e.
  whether it is a case that flips or a case that re-pins. Report the
  split, and read it against requirement 3, which asks the regression
  cases to fail against pre-change code.
- **P2 (U2) — `gap-f-api-merge-in-quote-still-fires`.** Compare the
  case's own inline comment in the `c9a63b4` test diff against the
  record's description of it at
  `docs/issue-94/reports/implementation.md:80-82`, and determine which
  clause of the command drives the deny. Scout must-be applied: a
  known-gap marker has to fail loudly if the gap closes
  (https://docs.pytest.org/en/stable/how-to/skipping.html).
- **P3 (U4) — relaxation scope on the three dequoted rules.** Take each
  of the three `True`-tagged patterns verbatim from `c9a63b4` and
  determine, for the field's named evasion shapes (a wholly-quoted flag
  such as `gh pr review 5 "--approve"`, and spliced tokens such as
  `--appro"ve"`), what the pre-image and the post-image each match. Where
  a shape is already unmatched at the pre-image, say so — the question is
  whether the change *widened* anything, not whether a denylist has holes
  (https://cwe.mitre.org/data/definitions/184.html).
- **P4 (U5) — command substitution inside double quotes.** Determine
  what `gate_outside_quotes(cmdline, r"[>|`]|\$\(")` at the
  approval-gate call site yields for a double-quoted `$(...)`, and
  compare against the removed `_writeish`'s behavior on the same input,
  against POSIX 2.2.3, which keeps `` ` `` and `$(` live inside double
  quotes
  (https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html).
  Also state whether board-gate's untouched `SUBSHELL` operand covers
  the equivalent path there.
- **P5 (U6) — centralization vs. drift.** Establish from the `c9a63b4`
  diff how many copies of the quote-span alternation exist after the
  change and which of them the three gates consume, and whether the
  structure removes a copy or adds a consumer beside it.
- **P6 (U3) — suite-count reconciliation.** Recount the assertion sites
  in each harness *statically* from the `c9a63b4` blobs — modelling every
  construct that can emit a pass/fail line, not only `^run ` — and
  compare the totals to the record's `71/0`, `42/0`, `37/0`, and the
  deltas to its "+4 / +5 / no new cases". Recount, never re-execution.
- **P7 (U7) — record convention.** Compare
  `docs/issue-94/reports/implementation.md:5` and its four `code_sha`
  entries against what `74c790d` actually contains, and against the prior
  observation's Finding 2 at
  `docs/issue-90/reports/execution-observation.md:351-386`, to establish
  whether the same shape recurs and whether anything in between settled
  it.
- **P8 (U8) — scope narrowing and its approval.** Read requirement 2's
  literal ask against what `c9a63b4` delivers, then follow the approval
  trail: what the human approved (the issue comment, posted against the
  proposal that already contained the narrowing) versus what the issue
  asked. Field norm applied: a narrowing is legitimate when documented,
  evaluated and signed off by a named owner
  (https://blog.asa.team/scope-creep-decision-problem-not-people-problem/).
- **P9 (housekeeping)** — the `Closes #94` keyword in `c9a63b4`'s message
  against the human's reopen comment on issue #94, as a trajectory
  observation about the step-2 plan item.

## Method, and the limit this role accepts

Only artifacts are admissible: the PR, its commits' diffs and blobs, and
the observed role's own record. This role does not re-run the observed
role's code — no harness execution, no gate invocation — so every
before/after determination in P1, P3 and P4 is **analytic**: the
pre-image pattern text and the case input, reasoned through. The scout
sweep found no source that treats static determination as equivalent to
watching the test fail
(https://theaioperator.io/p/every-test-passed-so-i-started-reverting), so
each such determination will be labelled analytic and its confidence
bounded in the record rather than presented as an execution result.
Nothing under `core/`, and nothing under another role's report or
proposal path, is edited.

## What phase 2 will produce

One file: `docs/issue-94/reports/execution-observation.md`, written as
the first act of phase 2, with `loop_state` updated at each transition,
the independence statement placed before any verdict-bearing sentence,
the three verdict levels each carrying a citation adjacent to the
verdict, and any deficiency finding in the four-part blameless shape
(impact / timeline / root cause / action item), scaled to the finding
(https://sre.google/workbook/postmortem-culture/). Committed on this
branch, delivered through this PR.

## Out of scope

Re-executing issue-94's task or its harnesses; recommending an
AST/tokenizer rewrite of the gates; filing issues (user-authored only
under contract v3 s9); the harness's exit-code-only comparison, which
issue #94 itself puts out of scope; and anything about the `gate-lib`
suite's one pre-existing `mktemp` failure beyond noting how the record
handles it.

## Risk this plan carries

The analytic method can mis-model a regex the way a reader mis-models any
code, and there is no execution to catch that. Mitigation: every P1/P3/P4
determination quotes the exact pattern text and the exact case input from
a named blob, so a reader can check the reasoning without trusting it.
