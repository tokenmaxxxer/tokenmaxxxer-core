---
kind: current-state-survey
subject: issue-128
produced_by: implementation
---

# Current-state survey — issue-128

## Where `upstream[].sha` is defined today

`core/contract/role-handoff-contract.md:16-38` (§1, "Common header") is the
sole normative definition. The yaml block at lines 21-32 states:

```
upstream:
  - path: <repo-root-relative path>
    sha: <commit SHA the artifact was read at>
    acknowledged_sha: <optional; see section 4>
```

`sha:` has exactly one documented shape today — a real commit SHA — with no
carve-out for "the path and the citing document land in the same commit."
The only existing exemption is the **chain-root** case (lines 34-38,
466-469): `upstream: []` for a record derived from nothing, which states its
own sha and is trivially non-stale against itself. That exemption covers
"nothing to cite"; it does not cover "something to cite that doesn't have a
sha yet," which is issue #128's actual problem.

## The staleness rule that reads `sha:`

`core/contract/role-handoff-contract.md:452-491` (§12) is the sole consumer
of `upstream[].sha`: a role compares the recorded `sha` against `git log -1
--format=%H -- <path>` before acting on a handed-over artifact, and stops to
ask the user if they differ. No mechanical gate implements this comparison —
`grep -rln staleness --include="*.sh" .` (repo-wide) returns no script; §12
is prose describing a role's own manual process. This matters for candidate
(a): a `same-commit` literal sha would never equal a real git hash, but
since no automated comparison runs today, nothing breaks mechanically; a
role reading it and computing this comparison itself would need the
contract to tell it `same-commit` is exempt, the same way the chain-root
case already is.

## The `<set at commit>` placeholder is a live, repo-wide pattern

`grep -rn "sha: <set at commit>\|code_sha: <set at commit>\|code_under_review: <set at commit>" --include="*.md" .`
(current working tree, not history) returns unresolved hits in at least 16
issue trees: #38, #46 (also `code_under_review`), #49, #60, #88, #90, #93,
#94, #98, #99, #100, #107 (x2), #109, #114, #118. All of these are in
**merged** PRs' surviving files — the placeholder was never amended away in
any of them. `docs/issue-118/reports/execution-observation.md:292-298`
independently ran the same grep at an earlier commit and flagged its own
`head -20` truncation, i.e. the true population is at least this large, not
smaller. This is direct evidence for the issue's own claim: "그 2차 수정을
강제하는 장치가 없어 잊힌다" — across every observed instance, the informal
amend-after-commit convention (candidate (c)'s current, undocumented form)
did not happen, not once.

The three recurrences issue #128 cites are documented at
`docs/issue-98/reports/execution-observation.md` (Finding 4),
`docs/issue-114/reports/execution-observation.md:359-384` (Finding 2), and
`docs/issue-118/reports/execution-observation.md:261-298` (Finding 2,
explicitly "third recorded recurrence"). The last of these already names the
#100 precedent (below) as the open question this issue resolves:
"이슈 #100의 결정은 SHA를 write-time-knowable 값으로 대체했고 ... 동일한
처리를 upstream[].sha 에도 확장할지가 미해결 질문" (`execution-observation.md:283-288`).

## Where the placeholder actually lands: proposals, not just records

Of the grep hits above, the great majority are in
`docs/issue-<n>/proposals/*.md` (`upstream[].sha` in a `hypothesis` or
`build-proposal` frontmatter) — the field this issue is about. A smaller
set are in `docs/issue-<n>/reports/coding.md` (issue-46, issue-38's `coding.md:9`),
where the same field appears in a role's own record. **Neither location is
covered by today's mechanical check**: `core/hooks/record-fields-gate.sh:109`
scopes its path match to `^docs/issue-[0-9]+/reports/{role}\.md$` only —
`docs/issue-<n>/proposals/*.md` is never matched at all, so a proposal's
`upstream[].sha` placeholder is invisible to this gate regardless of its
content. And even where the gate does match (a role's own `reports/<role>.md`),
its five checks (`what-was-done`, `why`, `upstream-basis`, `loop_state`,
`open-findings`, read at lines 162-179) test for the *presence* of an
upstream-ish token anywhere in the file (a hex string, "upstream", "based
on", or "docs/issue-" appearing somewhere) — never the *content* of a
specific `sha:` value. A file containing `sha: <set at commit>` already
satisfies "upstream-basis" today because the string `docs/issue-` appears
elsewhere in the same upstream block. Mechanizing requirement 3 needs a new,
narrower check; it cannot ride on the existing one unmodified.

## The #100 precedent: same structural problem, different field

`docs/issue-100/decisions/2026-08-03-record-citation-format-and-kind-convention.md`
(Decision 1, lines 25-49) resolved an analogous self-reference problem for
`code_under_review` (a role's own record cannot cite its own landing commit's
sha, since that record is committed in the same commit it would need to
cite). It replaced the sha with a write-time-knowable value — a file list —
and explicitly rejected "resolve the real sha at merge time" because this
repo has no bot/CI step that could perform that backfill and no role may
edit another role's already-merged record (contract §11). Decision 3 (lines
68-90) gave the convention exactly one mechanical check point,
`record-fields-gate.sh`, after finding that an earlier prose-only version of
the same finding (`docs/issue-90/reports/execution-observation.md:379-386`)
had already been recorded once and not carried forward
(`docs/issue-94/reports/execution-observation.md:347-353`, "recurrence").

This precedent is not a drop-in fix for `upstream[].sha`, because the two
fields serve different purposes: `code_under_review` only needs to name
*what* was reviewed (a file list suffices), while `upstream[].sha` is
consumed by §12's staleness comparison, which needs to identify *which
version* of `path` was read — a file list cannot serve that role, but a
literal marker meaning "the version that lands in this very commit" can.

## How a contract-wide record-norm change has landed here before

Two shapes exist in this repo's history for a change to the shared
contract text:

- **Direct contract edit, no separate decision doc** — `docs/issue-118/proposals/2026-08-04-add-defect-class-and-other-habitats-question-to-record-norm.md`
  landed as a single edit to `core/contract/role-handoff-contract.md` §20
  (commit `1b10565`, `git show --stat 1b10565` touches only that one file),
  with the rationale carried entirely in the phase-1 proposal's own
  `## Rationale`. Same shape at `docs/issue-106/proposals/2026-08-03-build-headless-delegation-clause.md`
  (§22, per `docs/issue-118/reports/implementation/survey.md:124-134`, which
  surveys the same two precedents for issue #118's own choice).
- **Contract-adjacent decision doc + gate** — `docs/issue-100/...` (above):
  a `docs/issue-100/decisions/` file plus a `record-fields-gate.sh` check,
  used because the change had multiple mechanical consumers to keep in sync
  (the gate, the test harness, the handbook, two existing records to fix).

Issue #128 requirement 2 asks to codify the decided convention "계약 §20
계열" (the contract's own record-norm family of sections) — textually
closer to the first shape (§1/§12 are, like §20, sections of
`core/contract/role-handoff-contract.md` itself) — while requirement 3 asks
to *judge* whether to add a mechanical check, which is the second shape's
concern. No prior issue in this repo has needed both halves in a single
proposal; #128 is a new combination, not a repeat of either.

No standing `docs/decisions/` (top-level, not per-issue) file exists yet in
this repo (`ls docs/` lists only `handbooks`, `reports`, `specs`, and
`issue-<n>/` trees at the top level) — every "hard-to-reverse choice"
observed so far used either a direct contract edit or a per-issue
`docs/issue-<n>/decisions/` file (§100's own path), never the standing
bucket.

## Commit-trailer / one-subject-per-commit constraint

`core/hooks/trailer-gate.sh:4-14` requires every commit staging
`docs/issue-<n>/**` work to carry `Subject: issue-<n>` and refuses staging
two issues' trees in one commit. It says nothing about how many commits one
subject's phase 1 must use — candidate (b) (splitting phase 1 into a survey
commit and a proposal commit) is not blocked by this gate, but every
existing phase-1 commit sampled in this survey (issue-90, 94, 98, 99, 100,
106, 107, 109, 114, 118 — all listed by `git log --oneline` as a single
`propose(...)`-tagged commit carrying survey + proposal together) bundles
both into one commit; a two-commit phase 1 would be a first in this repo's
observed practice, not a return to an existing one.

## Unknowns

- Whether every one of the 16+ issues named above actually needed the
  now-unresolved `sha` for anything (i.e. whether any reader was ever
  actually blocked by it) is not established here — this survey confirms
  the placeholder's *persistence*, not a concrete case of a reader being
  misled by it. The three cited findings (issue-98, 114, 118) are the only
  ones this repo has independently confirmed as consequential.
- Whether any role besides `coding`/`implementation` has produced a
  `hypothesis`-kind proposal with the same placeholder is not checked here
  (this survey's grep matched paths, not `produced_by:`); §1's `upstream`
  field is common to all nine roles, so the structural problem is not
  scoped to `coding`/`implementation` the way #100's was, but this survey
  found no non-`coding`/`implementation` instance in the current tree
  either — plausibly because only `coding`/`implementation`'s `hypothesis`-
  and `build-proposal`-kind proposals have shipped so far in this repo's
  history.

## Write set this survey projects

- `core/contract/role-handoff-contract.md` — §1 (the `sha:` field
  definition) and §12 (the staleness rule) gain the decided convention.
- `core/hooks/record-fields-gate.sh` — one additive, narrowly-scoped check
  (existing checks unchanged, per the issue's own constraint).
- `core/hooks/tests/run-role-gates-tests.sh` — test case(s) for the new
  check.
- `docs/handbooks/role-gates-tests.md` — handbook entry, same turn as the
  gate change.
- No existing `docs/issue-<n>/proposals/*.md` or `reports/*.md` file is
  edited — the issue's own constraint forbids retroactive fixes (#100
  precedent).
