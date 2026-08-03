---
kind: proposal
subject: issue-99
produced_by: execution-observation
loop_state: phase-1
upstream:
  - path: docs/issue-99/reports/execution-observation/survey.md
  - path: docs/issue-99/reports/execution-observation/scout-brief.md
---

# Proposal — independent execution observation of PR #102 (issue-99 step 2)

## Subject

Issue #99, execution plan step 2. The artifact under observation is PR
**#102** (`propose(implementation): fix board-gate dead fallback +
cd-relative write-verb gap (#99)`, head `issue-99/implementation`, merged
`2026-08-03T08:19:00Z` as `27fd5fe`), its three commits — `e163815`
(propose), `aa3f206` (merge of `origin/main`), `232e2aa` (deliver) — and
the observed role's own record `docs/issue-99/reports/implementation.md`.
PR #102 carries no review and no comment (`gh pr view 102 --comments
--json reviews,comments` returns both lists empty); the approval it cites
is the issue-level comment `APPROVE issue-99/implementation`. All of the
above were read this session; `docs/issue-99/reports/execution-observation/survey.md`
lists exactly what was read and what was deliberately not read.

This document contains no verdict, provisional or otherwise. It states
which verdict levels phase 2 will check and against which evidence, and
stops there.

## Which verdict levels will be checked, and against what

Phase 2 will address **all three** levels required of this role, and will
write "not applicable, because X" for any level that turns out not to
apply rather than omitting it silently.

- **Outcome** — did PR #102 land what issue #99 asked. Evidence: issue
  #99's five numbered `## 요구사항` read one by one against the `232e2aa`
  diff (`core/hooks/board-gate.sh`, `core/hooks/tests/run-board-gate-tests.sh`,
  `docs/handbooks/board-gate-tests.md`), plus `git show --stat 232e2aa`
  for requirement 5 (handbook touched in the same commit).
- **Trajectory** — was the phase-1→phase-2 path sound: did it scout,
  survey before proposing, and open phase 2 on a real human approval.
  Evidence: `e163815`'s three phase-1 files (survey, scout brief,
  proposal) and their ordering claims; the issue-level comment body read
  via `gh issue view 99 --comments` checked for exact string equality
  against `APPROVE issue-99/<role>`; and the `aa3f206` merge, taken
  between propose and deliver, as the point where the plan met a changed
  `main`.
- **Step** — which specific artifact, if any, is deficient. Candidate
  artifacts already identified by the survey as needing adjudication:
  `232e2aa`'s commit message body, the record's `closed_checks`
  (`docs/issue-99/reports/implementation.md:151-175`), the proposal's
  `## How you'll know it worked`
  (`…-cd-write-verb-gap.md:176-185`), and the record's `## Open findings`
  (`:177-189`).

## The three check points this invocation names, and the evidence each will rest on

**(1) Did the landing code avoid the unreachable-branch trap?** Issue
#99's requirement 4 forbids shipping a branch whose reachability is not
empirically shown. Phase 2 will enumerate every branch the `232e2aa`
diff adds to the `Bash` candidate builder — the `own_hits` branch, the
`elif cd_tail` branch, the implicit "neither" fall-through, and the
`cd_tail` assignment path inside the read-only arm — and for each one
name the test case *in the same diff* that enters it, or record it as
unproven. The scout brief's must-be applies here: a reachability claim
must carry an inspectable path, and branch coverage alone can pass while
hiding the defect. Sources of evidence: the `232e2aa` diff hunks and the
`run-board-gate-tests.sh` hunk in the same commit; the record's own
requirement-4 argument (`docs/issue-99/reports/implementation.md:144-147`)
will be treated as a claim to check, not as evidence. No test suite will
be re-run.

**(2) Post-merge interaction with real sessions — did the silent-allow
failure mode recur?** Phase 2 will rest on recorded live gate events in
other roles' merged records, since no runtime log or gate-event artifact
directory exists in this repo. Two candidate events are already located:
the U6 addendum at `docs/issue-98/reports/execution-observation/survey.md:148-159`
(added by `e062d4a`), whose refusal happened while committing the files
that became `850a99c` — authored `17:07:51`, i.e. *before* `27fd5fe`
merged at `17:19:00` — and a second refusal at
`docs/issue-98/reports/execution-observation.md:535-540` (committed at
`99d94aa`, `17:32:12`), which that record itself labels "the current
`main` gate (post-issue-99)". Phase 2 will separate the two by timestamp
before drawing anything from either, and will state plainly that a
search of all merged records after `27fd5fe` for a recorded silent allow
returned nothing — including what that absence can and cannot support,
given that only one PR (#104) landed sessions in that window.

**(3) Combination with core issue #98's observation Finding 1.** That
finding (`docs/issue-98/reports/execution-observation.md:388-432`) reports
that `e51bc09` extended `TRANSPARENT` to include `timeout`/`nohup` while
the proposal and the record both stated no board-gate behaviour change.
Phase 2 will check the seam the scout brief flags — two changes to
functionally related regions of one file, merged twenty minutes apart
(`9cd8a20` at `16:58:36`, `27fd5fe` at `17:19:00`), which git cannot
detect a conflict between. The specific mechanism to adjudicate is
visible in the two diffs: `232e2aa`'s new `_segment_is_failing` calls
`gate_lib.gate_head_of(stripped)` — the resolver `e51bc09` relocated and
extended — and `232e2aa`'s `cd_tail` walk calls it a second time to test
`== "cd"`. Phase 2 will determine, from the two diffs only, whether the
composition is exercised by any case in `232e2aa`'s test hunk, and in
which direction (stricter or more permissive) any unexercised
composition would move the gate. Whether the answer amounts to a
deficiency, and against which of the two sessions, is exactly what phase
2 decides; nothing is decided here.

## Method and its limits

- Admissible evidence: the commit diffs (`232e2aa`, `e51bc09`,
  `e163815`), the observed role's own documents, merged records of other
  roles, and GitHub state (`gh issue view 99`, `gh pr view 102`).
- Inadmissible, and not used: re-running `run-board-gate-tests.sh` or any
  gate; reading `core/hooks/**` in its current working-tree state as
  evidence of what the observed session did. The scout brief's two
  "skip" entries (coverage tooling, re-scan-with-the-same-tool
  validation) follow from this prohibition, with diff-plus-case
  inspection as the substitute.
- Nothing under `docs/issue-99/reports/implementation*`,
  `core/hooks/**`, or `core/hooks/tests/**` will be edited. This role's
  entire write surface is `docs/issue-99/reports/execution-observation.md`
  and `docs/issue-99/reports/execution-observation/`, plus this proposal.
- No issue will be filed. Any confirmed deficiency returns as a finding
  in this role's record, in the four-part blameless shape (impact,
  timeline, root cause, action item), for the human to judge on this PR.

## Phase-2 deliverable

`docs/issue-99/reports/execution-observation.md`, written as the first
act of phase 2, with `loop_state` updated at every transition, the
independence statement placed before any verdict language, and every
verdict-bearing sentence carrying its citation adjacent to it.

## Out of scope

- Re-executing, re-testing, or re-implementing issue #99's fix.
- Judging issue #98's own delivery — PR #103 was already observed under
  PR #104. Finding 1 enters here only as the neighbouring change whose
  seam with `232e2aa` nobody has checked.
- The R5 residual the observed proposal names Out of scope, except to
  judge whether the record's "confirmed still present by construction …
  not re-verified live" (`docs/issue-99/reports/implementation.md:182-189`)
  is an adequate standard for a residual that role chose to carry.
