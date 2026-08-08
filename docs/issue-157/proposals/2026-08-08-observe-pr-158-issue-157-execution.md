---
kind: proposal
subject: issue-157
produced_by: execution-observation
phase: 1
loop_state: proposed
observed_pr: 158
observed_role: implementation
upstream:
  - path: docs/issue-157/reports/execution-observation/survey.md
    sha: same-commit
  - path: docs/issue-157/reports/execution-observation/scout-brief.md
    sha: same-commit
---

files: `docs/issue-157/reports/execution-observation.md` (phase-2 record only)

# Proposal — step 2 independent observation of PR #158 (issue-157)

## What this proposal covers

Issue #157's `## 실행 계획` lists two steps. Step 1 (`implementation`)
landed as PR #158, created `2026-08-08T03:39:16Z`, merged
`2026-08-08T03:55:20Z`, merge commit
`01d5a8fb7ddab7dd76a373b7ee8ed8983fb1d966`, over two commits —
`cdbe166e003d4c8c31a66e05427ce33e1132cfff` (phase-1 survey + proposal +
hunt record) and `7cd6392e5fc0d3509bd3228232c2ba0b43b58f4d` (phase-2
delivery). Step 2 is this role's independent observation of that
execution.

This document states, **before any judgment is formed**, which verdict
levels the phase-2 record will address and what evidence settles each. It
renders no verdict, provisional or otherwise, on any of them; verdict
language belongs to `docs/issue-157/reports/execution-observation.md` and
appears there only after a human `APPROVE issue-157/execution-observation`.
Everything below is stated as a question to be settled and the artifact
that will settle it.

The scope, the full first-hand read list behind it, and the ten open
unknowns this plan aims at are in
`docs/issue-157/reports/execution-observation/survey.md`; the four audit
lenses adopted from the scout sweep are in
`docs/issue-157/reports/execution-observation/scout-brief.md`. This
proposal does not restate them, it allocates them.

## Verdict levels to be checked, and the evidence for each

The phase-2 record will address **all three** levels of this role's verdict
shape — outcome, trajectory, step. All three are addressed even if a level
turns out not to apply, in which case it is written as "not applicable,
because X" rather than omitted.

### Level 1 — outcome (did PR #158 land what issue #157 asked)

Issue #157 states four requirements and four `check:` acceptance items.
Evidence per item, all of it landed artifacts, no re-execution:

- **Requirement 1 (F1, frontmatter-less semantics)** —
  `git show 7cd6392e5fc0d3509bd3228232c2ba0b43b58f4d -- core/hooks/record-fields-gate.sh`,
  read as diff, against the issue's requirement-1 wording (decide the
  semantics, compare the trade-offs in the proposal, judge the `:92`
  fixture's disposition, pin red-green) and against the approved proposal's
  frozen item 1
  (`docs/issue-157/proposals/2026-08-08-frontmatter-fallback-f2-discriminator-f3-census-f4-handbook.md:187-202`).
  The trade-off comparison the issue demands is checked where it is
  recorded (that proposal's `## Rationale`, `:69-131`, including the
  rejected fail-closed alternative and the `:92`-fixture disposition), not
  merely for its conclusion.
- **Requirement 1's constraint boundary (survey U1)** — the same diff's
  change of the anchor input to a leading-whitespace-stripped copy, read
  against issue #157's `## 제약` ("#154 가 랜딩한 frontmatter 한정 …
  무변경") and against the approved proposal's own `## Constraints`
  (`…-f4-handbook.md:40-65`). The question phase 2 answers is which of the
  two the delivered behavior change falls under; the answer is not
  presumed here.
- **Requirement 2 (F2 discriminator)** —
  `git show 7cd6392… -- core/hooks/tests/run-role-gates-tests.sh` for the
  landed inline probe, against `docs/issue-157/reports/implementation.md:24-33`
  and the trace the observed survey offers as proof
  (`docs/issue-157/reports/implementation/survey.md:162-234`).
- **Requirement 3 (census)** — `docs/issue-157/reports/implementation.md:126-146`
  against `docs/issue-157/reports/implementation/survey.md:236-315`, on
  whether the extension result is stated *in the record* as the issue's
  acceptance check requires, and whether the recorded scope is the one the
  census claims.
- **Requirement 4 (handbook sentence)** —
  `git show 7cd6392… -- docs/handbooks/role-gates-tests.md`, read as diff.
- **Acceptance checks 1–4** — each of the issue's four `check:` lines
  mapped onto a specific named landed assertion or record passage in
  `7cd6392…`, or recorded as unmapped. Check 2 ("판별형 message-accuracy
  케이스가 수정 전 게이트에서 실패함을 기록으로 증명", survey U2) is the one
  whose *evidence form* is examined, not only its existence: which
  pre-image "수정 전 게이트" denotes, and whether the by-hand regex trace
  offered discharges "기록으로 증명" for that pre-image. Per scout must-be
  1, the on-paper revert is computed against the pre-image the observed
  survey itself quotes (`…/implementation/survey.md:29-44`), never by
  running anything.
- **Constraint conformance** — the "no retroactive edit" constraint against
  the file list of `7cd6392…` (`git show --stat`), and the #154-semantics
  constraint against the surviving lines in the gate hunk.

### Level 2 — trajectory (was the phase-1 → phase-2 path sound)

- **Approval gate** — the issue-level comment
  <https://github.com/tokenmaxxxer/tokenmaxxxer-core/issues/157#issuecomment-5224334825>
  (`jjongkwann`, `2026-08-08T03:41:06Z`, body fetched verbatim through the
  API), against contract v3 §19's two approval paths, PR #158's empty
  review list (`gh pr view 158 --json reviews`), the PR author
  (`gh pr view 158 --json author`), and `docs/specs/approvers.md`. Both
  which path applies and whether the string-equality test is met are
  checked; any near-miss or affirmative-sounding non-match found in the
  issue's comment list is stated plainly once, in the record.
- **Ordering** — `cdbe166…` (`2026-08-08T03:38:50Z`) → PR #158 created
  (`03:39:16Z`) → approval (`03:41:06Z`) → `7cd6392…` (`03:53:59Z`) →
  merge (`03:55:20Z`), each from the metadata already gathered in the
  survey, checked for whether any phase-2 work precedes the approval.
- **Phase-1 write-set purity** — `git show --stat cdbe166…` (3 files, all
  `docs/`, 780 insertions, 0 deletions) checked for the absence of code and
  of the phase-2 record file, and `git log` on the record path for when it
  first appears.
- **Survey-before-proposal, and scout skip admissibility (survey U4)** —
  `docs/issue-157/reports/implementation/survey.md:9-22` against the scout
  directive's two permitted skip conditions and its mandatory-skip-record
  requirement, read alongside issue #157's requirement 1, which asks the
  proposal to compare trade-offs and choose.
- **Hunt cadence and its audit trail (survey U5, scout must-be 3)** — both
  sections of
  `docs/reports/2026-08-08-hunt-issue-157-frontmatter-fallback-f2-discriminator-f3-census-f4-handbook.md`
  (`:7-16` after-proposal, `:100-109` before-landing) for presence of the
  `tier` / `cap_seconds` / `started_at` / `ended_at` fields, for stance
  rotation between the two dispatches, and for sequence continuity of the
  four timestamps against the issue-creation, commit, and merge clock. The
  after-proposal finding's fold-back is checked for ordering — whether it
  reached the proposal text inside `cdbe166…` itself rather than after it.
- **Deviation and frozen-write-set handling (survey U10)** — the approved
  proposal's `files:` line (`…-f4-handbook.md:11`) against
  `git show --stat 7cd6392…`, on whether the two paths outside that line
  are the warrant directive's `docs/` exemption or a scope-exceeded event,
  and whether the record discloses them where a PR reader meets them.
- **PR hygiene (survey U8)** — PR #158's title and body and both commit
  messages (`gh pr view 158 --json title,body`, `git show` on each commit)
  for GitHub closing keywords, for the `Subject: issue-157` trailer on both
  commits, and for whether the title and body describe the merged content.

### Level 3 — step (which specific artifact, if any, is deficient)

Per-artifact, in this order:

1. **The `placeholder_shas` hunk in `7cd6392…`**, read as diff, on scout
   must-be 2: what the widened branch now rejects that was previously
   accepted, and what the narrowed classification (whitespace-preceded
   frontmatter now counted as fenced) changes on the other side. Assessed
   from the diff text and the landed assertions only.
2. **The four added assertions in `7cd6392…`'s test hunk**, on scout
   must-be 1: for each, which pre-image it goes red against — this change's
   pre-image, #154's pre-image, or neither — and whether the record's
   claim of exactly one FAIL under a gate-only stash
   (`docs/issue-157/reports/implementation.md:13-23`) is consistent with
   what those four fixtures must produce against the pre-image quoted in
   the observed survey. The `56 → 60` count is checked for consistency
   against the number of assertions the diff adds.
3. **The before-landing hunt's FINDING and its disposition (survey U3)** —
   `docs/reports/2026-08-08-hunt-issue-157-…md:100-139` against
   `docs/issue-157/reports/implementation.md:34-62`, on whether the
   disposition's supporting measurement covers the path set the gate itself
   evaluates (the record's own description of that scope, `:46-50`, versus
   the corpus glob the re-verification used, `:43-45`, versus the standing
   `docs/proposals/` bucket visible in
   `git ls-tree -r --name-only HEAD -- docs/proposals`), and whether the
   fence-less record fixtures the observed survey identifies at
   `…/implementation/survey.md:76-89` bear on the "0 affected" number.
4. **The handbook paragraph added by `7cd6392…` (survey U7)**, on scout
   must-be 4: its two concrete claims verified one by one against the gate
   hunk in the same commit.
5. **`docs/issue-157/reports/implementation.md` as a record** — its
   `closed_checks` entries, `loop_state`, `## Doc placement`,
   `## What did not work`, `## Hunt cadence`, and `## Open findings`
   against what the two diffs and the hunt record show.
6. **The approved proposal `cdbe166…` as a plan** — whether its `## What
   will be done` items are the ones that landed, and whether its test list
   foresaw the shapes its own hunts found.
7. **PR #158's title and body at merge time** against the content of the
   merge `01d5a8fb7ddab7dd76a373b7ee8ed8983fb1d966`.

Any finding this level produces carries the four-part blameless shape —
impact, timeline, root cause, action item — scaled to the single finding,
with each verdict-bearing sentence citing its source adjacent to the claim.
Levels that produce no finding are written up as such, with the artifact
that supports the observed role's account cited the same way.

## Constraints this observation binds itself to

- **No re-execution.** `core/hooks/tests/run-role-gates-tests.sh`,
  `core/hooks/tests/run-all.sh`, `core/hooks/record-fields-gate.sh`, and
  every reproduction inside the observed role's hunt record and survey will
  not be run. The `60 passed, 0 failed` figure, the `run-all.sh` result,
  the stash-based red-green claim, and the 239/96/2 corpus counts are
  assessed for internal consistency and diff support only; residual
  uncertainty is stated as residual, never closed by a rerun.
- **`src`-side files are not evidence.** `core/hooks/record-fields-gate.sh`
  and `core/hooks/tests/run-role-gates-tests.sh` are read only through
  `git show 7cd6392e5fc0d3509bd3228232c2ba0b43b58f4d -- <path>`, never as
  current-tree source. Where a pre-image is needed, the one quoted inside
  the observed role's own survey is used.
- **No edits to the observed role's artifacts.** Nothing under `core/`,
  `test/`, `docs/handbooks/`,
  `docs/issue-157/reports/implementation*`,
  `docs/issue-157/proposals/2026-08-08-frontmatter-fallback-*`, or
  `docs/reports/2026-08-08-hunt-issue-157-*` is written by this role.
  Findings return only through
  `docs/issue-157/reports/execution-observation.md` on this branch's PR.
- **No issues filed.** Under contract v3 issues are user-authored only; a
  confirmed deficiency becomes a finding in the record for the human to
  judge, and the human authors any follow-up issue.
- **Gate-safe self-citation.** This role's documents are inputs to the very
  check under observation, and the observed change widens that check for
  one document shape. Every document this branch writes opens with a
  frontmatter fence at byte 0, and no non-conforming sha spelling is
  reproduced anywhere in field shape — such values are named in prose, and
  commit identities are written as 40-character hex.

## Out of scope

- Whether the fallback semantics chosen for F1 are the *best* available
  design. The issue delegated that choice to the proposal and a human
  approved it; this observation addresses whether the choice was compared,
  recorded, and delivered as approved, not whether it should be revisited.
- PR #154 / issue-153's own correctness, and the #154-landed semantics the
  issue fixes as unchanged — already observed under issue-153.
- Any proposal to change the warrant hunt cadence, the scout directive, or
  contract v3 itself; the questions here are only whether this execution
  matched the rules as they stand.
- The three adjacent open tracks (#141 / PR #144, #142 / PR #145, #146 /
  PR #148), read only where the observed survey's coordination claim
  (`docs/issue-157/reports/implementation/survey.md:303-315`, `:381-398`)
  is itself the thing being checked.
- Re-deciding the four findings issue-153's observation authored; the
  question is whether issue #157's four requirements were met, not whether
  the findings were correctly stated in the first place.

## What will be done in phase 2

1. Write `docs/issue-157/reports/execution-observation.md` as the **first**
   act of phase 2, with the independence statement placed **before** any
   verdict language and `loop_state` updated at every transition.
2. Gather the evidence enumerated above from the artifacts named, then
   write the three-level verdict with an adjacent citation on every
   verdict-bearing sentence.
3. Commit on `issue-157/execution-observation` with a `Subject: issue-157`
   trailer via `git commit -m`, and report through this same PR. The
   orchestrator updates the PR body and merges.

## How you'll know it worked

- The phase-2 record addresses outcome, trajectory, and step explicitly,
  none silently omitted, with "not applicable, because X" written out where
  a level does not apply.
- Every verdict-bearing sentence carries a 40-hex commit id, a `file:line`,
  or a comment URL adjacent to it.
- Each of the seven level-1 evidence items, seven level-2 evidence items,
  and seven level-3 artifacts above appears in the record with the artifact
  it was read from — including the ones that turn out to support the
  observed role's account.
- The four scout must-bes each show up as an applied lens, and the one
  deliberately skipped method (actually reverting and re-running) is stated
  as skipped with its residue named.
- No file outside `docs/issue-157/reports/execution-observation.md` (plus
  this phase-1 trio and this role's own hunt record) is modified on this
  branch.
