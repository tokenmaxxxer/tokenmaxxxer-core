---
kind: current-state-survey
subject: issue-153
produced_by: execution-observation
phase: 1
---

# Current-state survey — issue-153, step 2 (execution-observation)

## Scope under observation

- **Role observed:** `implementation`, on subject `issue-153`.
- **Session observed:** the two-phase `issue-153/implementation` session —
  phase 1 (proposal commit `7036f95`, committed `2026-08-08T01:54:37Z`) and
  phase 2 (delivery commit `3f67436`, committed `2026-08-08T02:43:12Z`),
  both authored by `jjongkwann` (`gh pr view 154 --json commits`).
- **Issue:** #153 — "record-fields-gate sha 검사 후속 — 스캔 범위
  과대(인용 거부)와 빈 값 carve-out 미인도·오진 메시지 (#133 관찰
  Finding 1·2)", state `OPEN`, 1 comment (`gh issue view 153`).
- **PR observed:** #154 —
  <https://github.com/tokenmaxxxer/tokenmaxxxer-core/pull/154>, head
  `issue-153/implementation`, base `main`, author `jjongkwann`, state
  `MERGED` at `2026-08-08T02:44:54Z`, merge commit `6fd3b29`
  (`gh pr view 154 --json number,author,mergedAt,mergeCommit,state`).
  PR-level reviews: none (`gh pr view 154 --json reviews` → `{"reviews":[]}`).
  PR-level comments: none (`gh pr view 154 --json comments` → `{"comments":[]}`).
- **Commits observed:** exactly two on that branch
  (`gh pr view 154 --json commits`):
  - `7036f95` — `propose(implementation): narrow record-fields-gate sha
    scan scope, deliver empty-value carve-out (issue-153)`, 3 files, +586.
  - `3f67436` — `deliver(implementation): bound sha check to frontmatter,
    fix newline-swallowing carve-out (issue-153)`, 5 files, +392/−10.
- **Not in scope:** the landed whitelist semantics from PR #134
  (issue-133) — `same-commit` or 40-lowercase-hex — which issue #153's own
  `## 제약` and the observed proposal's `## Constraints`
  (`docs/issue-153/proposals/2026-08-08-narrow-sha-scan-scope-and-empty-value-carveout.md:42-44`)
  both fix as unchanged; and the correctness of PR #134 itself, already
  observed under issue-133.

## What was read this session (evidence base)

Read directly, this session, on branch `issue-153/execution-observation`
at merge commit `6fd3b29`:

1. Issue #153 body and its single comment (`gh issue view 153`,
   `gh issue view 153 --json comments`): comment by `jjongkwann`,
   `2026-08-08T01:57:10Z`, body exactly `APPROVE issue-153/implementation`,
   <https://github.com/tokenmaxxxer/tokenmaxxxer-core/issues/153#issuecomment-5223954819>.
2. PR #154's metadata, body, both commit messages, review list, and comment
   list (`gh pr view 154 --json …`; creation time `2026-08-08T01:55:59Z`
   from `gh pr list --state all`).
3. `docs/issue-153/proposals/2026-08-08-narrow-sha-scan-scope-and-empty-value-carveout.md`
   (241 lines, landed by `7036f95`) — read in full.
4. `docs/issue-153/reports/implementation/survey.md` (252 lines, landed by
   `7036f95`) — read in part: the scout skip record (`:9-22`), the
   requirement-3 class census (`:141-180`), and a `grep -n` index of its
   census / adjacent-track / frontmatter hits.
5. `docs/issue-153/reports/implementation.md` (168 lines, landed by
   `3f67436`) — the observed role's own record, read in full.
6. `docs/reports/2026-08-08-hunt-issue-153-narrow-sha-scan-scope-and-empty-value-carveout.md`
   (236 lines, landed across both commits) — both hunt sections, read in
   full.
7. The delivered diff of `3f67436`, read as diff (never as current-tree
   source): `core/hooks/record-fields-gate.sh` (+25/−4 inside
   `placeholder_shas`), `core/hooks/tests/run-role-gates-tests.sh`
   (+55/−8), `docs/handbooks/role-gates-tests.md` (+12).
8. `docs/specs/approvers.md` — two accounts, `JiwonJung94` and
   `jjongkwann`.
9. Convention exemplars from the previous observation cycle, read only to
   fix this role's artifact shape:
   `docs/issue-132/reports/execution-observation/survey.md`,
   `.../scout-brief.md`,
   `docs/issue-132/proposals/2026-08-04-observe-pr-135-wrapper-class-closeout.md`,
   and the head of `docs/issue-132/reports/execution-observation.md`.

Not read yet, and deliberately deferred to phase 2 because they are
verification targets rather than scope inputs: the remainder of
`docs/issue-153/reports/implementation/survey.md`,
`docs/issue-133/reports/execution-observation.md` (the two findings this
issue descends from), and the pre-fix state of
`core/hooks/tests/run-role-gates-tests.sh` at `f976bcc`.

## Current state of the observed delivery, as landed

- **F1 (scan-scope narrowing)** — landed. `3f67436`'s
  `core/hooks/record-fields-gate.sh` hunk replaces the whole-document
  `re.finditer` scan inside `placeholder_shas` with a scan over a region
  extracted by an anchored leading-frontmatter regex, preceded by a
  one-character leading-mark strip.
- **F2 (empty-value carve-out + newline swallowing)** — landed in the same
  hunk: the post-field-name whitespace class is narrowed to horizontal
  only, a trailing-comment strip runs before validation, and an empty
  captured value takes a `continue` branch instead of being appended to
  the violation list.
- **Tests** — `3f67436`'s `core/hooks/tests/run-role-gates-tests.sh` hunk
  adds six `run_rf` cases plus one inline message-assertion case, and
  rewrites the fixture strings of 5 pre-existing issue-128/133 cases to
  wrap their field block in a `---` fence.
- **Handbook** — `3f67436` appends one paragraph to
  `docs/handbooks/role-gates-tests.md` (after `:58`) stating the scan
  region, the empty-value allowance, and the comment strip.
- **Record** — `docs/issue-153/reports/implementation.md`, landed by
  `3f67436`, reports `56 passed, 0 failed` plus a `run-all.sh` `ALL OK`,
  a directly-observed red→green on 3 of the new cases, a `## What did not
  work` entry about the 5 reshaped fixtures, and a `## Rationale for
  deviations` section for the before-landing hunt's addition.
- **Deviation from the approved plan** — the approved proposal's `## What
  will be done` (`…-carveout.md:139-196`) does not list the leading-mark
  strip; the record argues it as an in-scope addition rather than a
  scope-exceeded stop (`docs/issue-153/reports/implementation.md:82-96`).

## Unknowns and thin surfaces this survey found

These are the gaps the phase-1 sweep is aimed at, and the phase-2 evidence
plan must decide what evidence settles each.

- **U1 — deviation legitimacy.** The before-landing hunt's leading-mark
  fix was added to the delivery without a second approval. Whether the
  warrant directive's frozen unit is the *write set* (paths — unchanged
  here) or the proposal's *stated work list* (changed here), and whether
  the record's argument at `docs/issue-153/reports/implementation.md:82-96`
  matches the directive's own SCOPE-EXCEEDED wording, is unverified.
- **U2 — anchor fragility as a class, not an instance.** The delivered
  anchor is `re.match`-based, so it binds to byte offset 0 of the
  reconstructed text; the delivery closes exactly one leading-byte shape
  (the mark) and one trailing shape (no newline after the closing fence).
  Whether other leading shapes reach the same empty-region fallback, and
  whether the empty-region fallback direction is itself the right default
  for this gate, is unverified — and is the question both hunt findings
  are instances of. The same anchor's other direction — a region captured
  *shorter* than the author's frontmatter rather than empty — is equally
  unverified; this observation's own after-proposal hunt
  (`docs/reports/2026-08-08-hunt-observe-pr-154-sha-scan-scope.md`) raised
  it against an earlier draft of the evidence plan, which now covers both
  directions.
- **U3 — regression coverage after the fixture reshape.** 5 pre-existing
  issue-128/133 fixtures were rewritten by `3f67436`, against the approved
  proposal's own item-3 wording that those cases "keep their current
  verdicts unchanged" (`…-carveout.md:189-191`). Whether the reshape
  preserves what those cases were pinning, or silently retires a
  behavior nobody now covers, is unverified.
- **U4 — issue Acceptance mapping.** Issue #153 lists three `check:`
  items. Whether each maps onto a specific landed test case in `3f67436`
  — rather than onto the record's prose alone — is unverified.
- **U5 — requirement 3 (class census) sufficiency.** The issue asks for a
  전수 조사 of the same class's other habitats; the record defers entirely
  to phase 1 (`docs/issue-153/reports/implementation.md:100-104`) and the
  survey's census (`…/implementation/survey.md:141-180`) states its own
  method as a grep over `core/hooks/*.sh` for four regex-call names.
  Whether that method's stated scope covers what the issue asked, and
  whether the accepted-limitation judgment is recorded where a human will
  find it, is unverified.
- **U6 — trajectory mechanics.** Approval is an issue-level comment in
  single-account mode; its exact-string, author-listing, and ordering
  properties against contract v3 s19's two paths are read but not yet
  checked. Likewise the phase-1 write set (whether `7036f95` contains any
  code or record content) and the scout skip record's admissibility
  (`…/implementation/survey.md:9-22`) are unchecked.

## Verdict language

None here by design: verdicts belong to phase 2 of this observation and
appear only in `docs/issue-153/reports/execution-observation.md` after a
human `APPROVE issue-153/execution-observation`.
