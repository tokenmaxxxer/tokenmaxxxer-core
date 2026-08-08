---
kind: current-state-survey
subject: issue-157
produced_by: execution-observation
phase: 1
---

# Current-state survey — issue-157, step 2 (execution-observation)

## Scope under observation

This survey is scoped to exactly one execution, named in full so the scope
cannot be read as "recent work":

- **Issue**: #157 — "sha 검사 후속 2 — frontmatter-부재 문서의 무검사 통과
  외 3건 (#153 관찰 Finding 1~4)", created `2026-08-08T03:13:46Z`
  (`gh issue view 157 --json createdAt,url`), whose `## 실행 계획` lists two
  steps: step 1 `implementation`, step 2 `execution-observation`.
- **Observed role**: `implementation`.
- **Observed session**: that role's step-1 session on branch
  `issue-157/implementation`, run as two phases — phase 1 (survey +
  proposal + after-proposal hunt) and phase 2 (delivery).
- **Observed PR**: **#158**, "issue-157: frontmatter fallback, F2
  discriminator, F3 census, F4 handbook (phase 1)", created
  `2026-08-08T03:39:16Z`, **MERGED** `2026-08-08T03:55:20Z`, merge commit
  `01d5a8fb7ddab7dd76a373b7ee8ed8983fb1d966`
  (`gh pr view 158 --json number,title,state,createdAt,mergedAt,mergeCommit`).
- **Observed commits**: the phase-1 commit
  `cdbe166e003d4c8c31a66e05427ce33e1132cfff` and the phase-2 commit
  `7cd6392e5fc0d3509bd3228232c2ba0b43b58f4d`
  (`gh pr view 158 --json commits`).

This session's own working tree is at
`01d5a8fb7ddab7dd76a373b7ee8ed8983fb1d966` (`git rev-parse HEAD`), i.e. the
merge state of the observed PR.

## What was read, first-hand, this session, to arrive at that scope

Nothing below is relayed from a summary; each item was opened this session.

1. Issue #157 body in full (`gh issue view 157`) — background, four
   requirements, two constraints, four `check:` acceptance items, execution
   plan.
2. Issue #157's single comment, fetched verbatim through the API
   (`gh api repos/tokenmaxxxer/tokenmaxxxer-core/issues/157/comments`):
   `jjongkwann`, `2026-08-08T03:41:06Z`,
   <https://github.com/tokenmaxxxer/tokenmaxxxer-core/issues/157#issuecomment-5224334825>,
   body exactly `APPROVE issue-157/implementation`.
3. PR #158 metadata in full — number, title, body, author, state,
   `createdAt`, `mergedAt`, `mergeCommit`, `commits`
   (`gh pr view 158 --json …`), and its review list
   (`gh pr view 158 --json reviews` → `{"reviews":[]}`).
4. `git show --stat cdbe166e003d4c8c31a66e05427ce33e1132cfff` — the
   phase-1 write set (3 files, 780 insertions, 0 deletions, all under
   `docs/`) and the full commit message including its `Subject:` trailer.
5. `git show --stat 7cd6392e5fc0d3509bd3228232c2ba0b43b58f4d` — the
   phase-2 write set (5 files, 315 insertions, 2 deletions) and its full
   commit message.
6. `git show 7cd6392e5fc0d3509bd3228232c2ba0b43b58f4d -- core/hooks/record-fields-gate.sh docs/handbooks/role-gates-tests.md`,
   read as diff.
7. `git show 7cd6392e5fc0d3509bd3228232c2ba0b43b58f4d -- core/hooks/tests/run-role-gates-tests.sh`,
   read as diff (the whole added block).
8. `docs/issue-157/reports/implementation.md` (193 lines) — the observed
   role's own phase-2 record, in full, frontmatter included.
9. `docs/issue-157/proposals/2026-08-08-frontmatter-fallback-f2-discriminator-f3-census-f4-handbook.md`
   (285 lines) — the observed role's approved proposal, in full.
10. `docs/issue-157/reports/implementation/survey.md` (399 lines) — the
    observed role's phase-1 survey, in full, including its scout skip
    record.
11. `docs/reports/2026-08-08-hunt-issue-157-frontmatter-fallback-f2-discriminator-f3-census-f4-handbook.md`
    (140 lines) — both hunt sections, in full.
12. `docs/specs/approvers.md` — two accounts, `JiwonJung94` and
    `jjongkwann`.
13. `docs/issue-153/reports/execution-observation.md` (622 lines) — the
    upstream observation record that authored Findings 1–4, i.e. the
    source text of what issue #157 asks to be closed.
14. `docs/issue-153/proposals/2026-08-08-observe-pr-154-sha-scan-scope.md`
    and `docs/issue-153/reports/execution-observation/scout-brief.md` —
    this role's own precedent artifacts for the same deliverable kind.
15. `git ls-tree -r --name-only HEAD -- docs/issue-153 docs/reports docs/proposals docs/handbooks docs/specs`
    — the document buckets that exist at the merge state.
16. `git log --format='%H %cI %s' -- docs/reports/2026-08-08-hunt-issue-157-…md`
    — which commits introduced and amended the observed hunt record.

**Deliberately not read**: `core/hooks/record-fields-gate.sh` and
`core/hooks/tests/run-role-gates-tests.sh` as current-tree source, and no
suite, gate, or reproduction belonging to the observed delivery was
executed. The role directive admits only the observed role's produced
artifacts as evidence, so those two files are read only through
`git show 7cd6392… -- <path>` in diff form. Note that the observed role's
own survey quotes the pre-change function body verbatim
(`docs/issue-157/reports/implementation/survey.md:29-44`), so the pre-image
is available from an observed artifact without reading current-tree source.

## Write surfaces this role will touch

Phase 1 (this commit), all under `docs/`:

- `docs/issue-157/reports/execution-observation/survey.md` — this file.
- `docs/issue-157/reports/execution-observation/scout-brief.md`.
- `docs/issue-157/proposals/2026-08-08-observe-pr-158-issue-157-execution.md`.
- `docs/reports/2026-08-08-hunt-observe-pr-158-issue-157-execution.md` —
  this role's own hunt record.

Phase 2 (after a human `APPROVE issue-157/execution-observation`):

- `docs/issue-157/reports/execution-observation.md` — the sole phase-2
  artifact.

Nothing under `core/`, `test/`, `docs/handbooks/`,
`docs/issue-157/reports/implementation*`,
`docs/issue-157/proposals/2026-08-08-frontmatter-fallback-*`, or
`docs/reports/2026-08-08-hunt-issue-157-*` is a write surface for this
role.

## Gate-safety constraint on this role's own documents

This role's proposal and record are themselves inputs to the very check
under observation, and the observed change *widens* that check for one
document shape. Two consequences, both binding on the documents this
branch writes:

1. Every document this role writes opens with a `---` frontmatter block at
   byte 0, so the observed fallback branch is never reached for it and the
   scanned region is the frontmatter block only.
2. No non-conforming sha spelling is ever reproduced in field shape
   (a line whose stripped form begins with `sha:`) anywhere in these
   documents — such values are named in prose with backticks instead, and
   commit identities are cited as 40-character hex or as prose.

## Baseline: what issue #157 asks, restated as checkable items

Requirements (issue #157 `## 요구사항`): **1** decide and implement the
intended semantics for a frontmatter-less document, comparing the
trade-offs in the proposal, and judge the disposition of the `:92` allow
fixture, with a red-green pin; **2** replace or add a discriminating
message-accuracy case, proving it actually fails against the pre-fix gate;
**3** extend the census to the 11 unrecorded files **or** record the
boundary rationale; **4** one handbook sentence for the region-boundary
rule.

Acceptance (issue #157 `## Acceptance`): four `check:` lines — fence-less +
non-conforming red-green case in the suite with the pre-fix red
reproduction recorded; discriminating message-accuracy case proven to fail
against the pre-fix gate *in the record*; census extension result or
boundary rationale stated in the record; handbook boundary sentence
present.

Constraints (issue #157 `## 제약`): #154's landed frontmatter-scoping,
newline fix, comment strip and carve-out semantics unchanged; no
retroactive edits.

## Unknowns and thin surfaces — what phase 2 must settle

These are stated as open questions, not as judgments. No verdict is formed
here.

- **U1 — does the delivered `lstrip()` anchor stay inside issue #157's
  "무변경" constraint?** The delivered hunk changes the anchor's input from
  `text` to `text.lstrip()`
  (`git show 7cd6392… -- core/hooks/record-fields-gate.sh`). For a document
  whose conforming frontmatter is preceded by whitespace, that reclassifies
  it from "fence-less" to "fenced", which is a change in which region #154's
  scoping selects — not only in the fallback branch. Open question: is that
  inside "fallback 의미론" (permitted by the issue) or a change to #154's
  landed frontmatter-scoping (forbidden by the constraint)? Evidence: the
  diff, the issue's `## 제약`, the proposal's `## Constraints`.
- **U2 — is Acceptance check 2's "수정 전 게이트에서 실패함을 기록으로
  증명" discharged by a hand trace?** The record states plainly that no
  production-code change backs the F2 case
  (`docs/issue-157/reports/implementation.md:30-33`), so the case cannot be
  demonstrated to fail by reverting this issue's own change; the proof
  offered is a by-hand regex trace of the pre-#154 pattern
  (`docs/issue-157/reports/implementation/survey.md:189-225`). Open
  question: which pre-image the issue's wording means, and whether the
  offered evidence form meets "기록으로 증명" for it. This is the highest-
  value unknown because it is the one acceptance check whose evidence form,
  not merely existence, is in question.
- **U3 — is the before-landing hunt's FINDING adequately dispositioned?**
  The hunter returned a composition FINDING that the fallback denies a
  fence-less document quoting a bad spelling in prose
  (`docs/reports/2026-08-08-hunt-issue-157-…md:100-139`); the record
  dispositions it as an already-accepted trade-off, re-verified against 239
  corpus files with 0 affected
  (`docs/issue-157/reports/implementation.md:34-62`). Open questions: (a)
  whether the corpus glob the re-verification used
  (`docs/issue-*/{reports,proposals}/**/*.md`) covers the same path set the
  gate itself evaluates — the record's own sentence describing that scope
  says a `proposals/*.md` file matches, and the repository also carries a
  standing `docs/proposals/` bucket outside every `docs/issue-*` tree
  (`git ls-tree -r --name-only HEAD -- docs/proposals`); (b) whether the
  five fence-less, section-20-complete record fixtures the observed survey
  itself identifies at `run-role-gates-tests.sh:75-92`
  (`docs/issue-157/reports/implementation/survey.md:76-89`) are the live
  instance class the "0 affected" number does not count.
- **U4 — is the scout skip admissible?** The observed survey records a skip
  under the "pure bugfix" condition
  (`docs/issue-157/reports/implementation/survey.md:9-22`), while issue
  #157's requirement 1 explicitly asks the proposal to compare trade-offs
  and choose. Open question: whether an issue that names an open design
  choice can still satisfy the scout directive's "pure bugfix" skip
  condition, and whether the mandatory skip record's reasoning holds on its
  own terms.
- **U5 — are the hunt record's audit-trail fields internally consistent?**
  The after-proposal section carries `started_at: 2026-08-08T01:57:00Z` /
  `ended_at: 2026-08-08T02:04:30Z` and the before-landing section
  `started_at: 2026-08-08T00:00:00Z` / `ended_at: 2026-08-08T00:20:00Z`
  (`docs/reports/2026-08-08-hunt-issue-157-…md:15-16`, `:108-109`), while
  issue #157 itself was created `2026-08-08T03:13:46Z` and the phase-1
  commit landed `2026-08-08T03:38:50Z`. Open question: whether these
  fields, which exist to make the cadence auditable, are accurate, and what
  weight the ordering claims that rest on them can carry.
- **U6 — do the four added assertions pin what they claim, and is the
  red-green report internally consistent?** The record claims exactly one
  FAIL under a gate-only `git stash`
  (`docs/issue-157/reports/implementation.md:13-23`) and a 56 → 60 count.
  Open question: whether the four added assertions visible in
  `git show 7cd6392… -- core/hooks/tests/run-role-gates-tests.sh` are each
  non-vacuous, and whether the claimed one-FAIL outcome is consistent with
  what those four fixtures must produce against the stated pre-image. To be
  settled by reading the diff, never by re-running the suite.
- **U7 — does the handbook paragraph describe the delivered code
  accurately?** The added paragraph says the tolerance covers "one
  incidental leading blank line or byte-order mark"
  (`git show 7cd6392… -- docs/handbooks/role-gates-tests.md`), while the
  delivered call is `text.lstrip()`. Open question: whether the prose
  overstates or understates the landed behavior, and whether the F4
  sentence matches the anchor's actual non-greedy shape.
- **U8 — PR-level hygiene and title accuracy.** PR #158's title still ends
  "(phase 1)" although the merged PR carries the phase-2 delivery, and the
  body's phase-2 paragraph was appended (`gh pr view 158 --json title,body`).
  Open questions: whether any GitHub closing keyword appears in the title,
  body, or either commit message; whether both commits carry the
  `Subject: issue-157` trailer; whether the title/body describe the merged
  content accurately.
- **U9 — trajectory ordering and phase-1 write-set purity.** The timestamps
  gathered above (`cdbe166…` at `2026-08-08T03:38:50Z` → PR created
  `03:39:16Z` → approval `03:41:06Z` → `7cd6392…` at `03:53:59Z` → merge
  `03:55:20Z`) and the phase-1 `--stat` (3 files, all `docs/`) are the raw
  material; the open question is whether the record file correctly waited
  for the approval and whether any phase-2 surface appears in the phase-1
  commit.
- **U10 — frozen write-set conformance.** The proposal's `files:` line
  (`docs/issue-157/proposals/2026-08-08-frontmatter-fallback-…md:11`) names
  three code/handbook paths; the phase-2 commit touched five. Open
  question: whether the two extra paths are the `docs/` exemption the
  warrant directive grants, or a scope-exceeded event owed a stop.

## Thin-surface summary for the scout sweep

The unknowns cluster on four surfaces the sweep should aim at, rather than
at the issue's wording: (a) **acceptance-evidence form** — when a test
proves a *historical* fix rather than the current change, what does a
strong audit accept as proof (U2, U6); (b) **fail-open → fail-closed
inversion** — how audits judge a fix that closes a permissive gap by
widening a scan, and what they demand of the "0 live instances" defence
(U1, U3); (c) **audit-trail integrity** — how much weight an audit puts on
self-reported process metadata whose fields are internally inconsistent
(U5); (d) **doc-vs-code drift** — how audits check that documentation
landed in the same change actually describes the landed behavior (U7).
