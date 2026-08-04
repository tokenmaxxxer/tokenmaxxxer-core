---
kind: current-state-survey
subject: issue-107
produced_by: execution-observation
observed_role: implementation
observed_pr: 108
loop_state: surveyed
---

# Survey: issue-107 — current state of the artifact to be observed

## Scope

The target of this observation is exactly one session's work: the
**`implementation` role** on branch **`issue-107/implementation`**, subject
**issue #107**, delivered as **PR #108** (state `MERGED`, merged
2026-08-04T02:03:47Z, merge commit `f6d6983`). That session's two commits are
`67eb71e` (phase 1: survey + proposal, no code) and `ace7dda` (phase 2:
delivery). Its own record is `docs/issue-107/reports/implementation.md`.

Issue #107's `## 실행 계획` lists two steps — `step 1 implementation`,
`step 2 execution-observation`. This session is step 2. Nothing outside PR
#108's commits, its own phase-1 and phase-2 documents, the governing contract
text, and the governing hook scripts is in scope.

## What was read this session

Every item below was read in this session; none of it is a secondhand summary.

- `gh issue view 107` (full body: 배경, 3 requirements, 2 constraints, 실행 계획)
  and `gh issue view 107 --comments` (one comment, author `jjongkwann`,
  entire body `APPROVE issue-107/implementation`).
- `gh pr view 108 --json number,title,author,state,mergedAt,body,commits,reviews,comments`
  — PR #108, author `jjongkwann`, `reviews: []`, `comments: []`, body stating
  it was "Opened by on-the-record on behalf of the implementation role session
  (sandbox egress relay); the branch content is the role's own work."
- `git show --stat 67eb71e` and `git show --stat ace7dda`; `git show ace7dda`
  restricted to `core/hooks/board-gate.sh`, `core/hooks/lib/gate-lib.py`,
  `core/hooks/tests/run-board-gate-tests.sh`,
  `docs/handbooks/board-gate-tests.md` (the full delivery diff, all four
  code/doc files).
- `docs/issue-107/reports/implementation.md` (223 lines, the observed role's
  own record), `docs/issue-107/proposals/2026-08-03-fix-board-gate-wrapper-cd-argument-extraction.md`
  (its phase-1 proposal) and `docs/issue-107/reports/implementation/survey.md`
  (its phase-1 survey).
- `docs/issue-99/reports/execution-observation.md` — the upstream record whose
  Finding 1 issue #107 formalizes (Finding 1 block read at `:385-433`).
- `core/contract/role-handoff-contract.md:840-900` — section 21's
  operational-surface / handbook obligation, including its `<component>`
  derivation and same-turn-sync maintenance rule.
- `core/hooks/handbook-trigger-gate.sh` (`:4-13` intent header, `:90-126`
  `OP_PATTERNS` and the deny path) and `core/hooks/hooks.json:39` (its
  registration). These are governing rules, not the observed role's output:
  `git log -- core/hooks/handbook-trigger-gate.sh` shows its last change is
  `52bdc15` (2026-08-01 18:02:46 +0900), and `git merge-base --is-ancestor
  52bdc15 ace7dda` returns true, so the version read here is the version in
  force when `ace7dda` was committed.
- `git show 'ace7dda:core/hooks/tests/run-board-gate-tests.sh'` and the same
  path at `ace7dda~1` — the landed and pre-delivery blobs of the test file,
  read for a static case tally (below).

Deliberately **not** read as evidence of what the observed session did: the
working-tree state of `core/hooks/**`, which shows what exists now rather than
what that session produced. Deliberately **not** run: the board-gate suite,
`gate-lib`'s suite, `gh-guard`'s suite, `handbook-trigger-gate.sh`, or the live
gate on any probe command. No re-execution of the observed task took place.

## The artifact, as read

`ace7dda` changes five files (`git show --stat ace7dda`): `board-gate.sh`
(+6/-1), `gate-lib.py` (+15), `run-board-gate-tests.sh` (+8),
`docs/handbooks/board-gate-tests.md` (+21), and
`docs/issue-107/reports/implementation.md` (+223, the record itself).

- `core/hooks/lib/gate-lib.py` — new `gate_trailing_words(segment)` returning
  `_resolve_transparent(segment)[1]`, placed after `gate_head_of`; the diff
  shows no hunk touching `gate_head_of` itself.
- `core/hooks/board-gate.sh` — inside `_cd_target`, the single line
  `for w in stripped.split()[1:]:` becomes
  `for w in gate_lib.gate_trailing_words(stripped):`, plus four docstring
  lines. No other hunk in that file.
- `core/hooks/tests/run-board-gate-tests.sh` — two `run deny` rows added next
  to the `bash-cd-*-foreign` block, `bash-wrapper-timeout-cd-relative-foreign`
  (`timeout 30 cd docs/issue-49 && date > x.md`) and
  `bash-wrapper-command-cd-relative-foreign` (`command cd docs/issue-49 &&
  date > x.md`), plus a six-line comment.
- `docs/handbooks/board-gate-tests.md` — one 21-line paragraph appended,
  following the file's per-issue-paragraph shape.

**Static case tally (measured this session, no suite run).** Counting
invocations of the file's own case helpers (`run`, `runb`, `drifted`,
`noremote`, `fastpath`, `garbage`, `noRole`; helper definitions excluded, and
the two bare argument-less invocations `noremote` at `:156` and `fastpath` at
`:189` counted separately): `ace7dda~1` → 82 + 2 = **84**; `ace7dda` → 84 + 2 =
**86**. Each helper body ends in exactly one `report`/`pass`/`fail` emission
(`:22-29`, `:44`, `:63`, `:105`, `:155`, `:184-188`, `:132`, `:367`), so
invocation count is case count. Whether these numbers match the counts the
observed record states is a phase-2 comparison, not made here.

## The deviation this observation must judge

Two documents from the same session disagree about one file, and the record
says so itself:

- The phase-1 proposal's `## Out of scope`
  (`docs/issue-107/proposals/2026-08-03-fix-board-gate-wrapper-cd-argument-extraction.md:152-157`)
  names `docs/handbooks/board-gate-tests.md` as a file whose update "does not
  clearly apply" under the doctrine ladder, "Left to phase-2 judgment rather
  than committed to here, so the write set stays exactly what the survey found
  necessary." Its frozen `files:` line (`:11`) lists three paths and does not
  include the handbook. The phase-1 survey says the same thing at `:103-109`.
- The delivery `ace7dda` touches the handbook anyway (+21 lines), and the
  record's `## Rationale for deviations`
  (`docs/issue-107/reports/implementation.md:57-79`) attributes this to the
  repo's own `handbook-trigger-gate.sh` refusing the commit at commit time,
  because it classifies `core/hooks/tests/run-board-gate-tests.sh` as an
  operational surface.

Facts read this session that bear on that attribution, stated without
adjudication:

- `core/hooks/handbook-trigger-gate.sh:103` carries the pattern
  `(^|/)(deploy|setup|run|install)[^/]*\.sh$` labelled `"run/setup/deploy
  script"`; `:114` exits 0 when no `OP_PATTERNS` entry matches; `:116-117`
  exits 0 when any staged path matches `^docs/handbooks/.+`; `:119-126` denies
  otherwise. Its header comment (`:11-13`) states the derivation is
  "Conservative … the gate enforces STRUCTURE — that a handbook was touched
  alongside operational" change.
- `core/contract/role-handoff-contract.md:855-860` states the substantive
  trigger as "an environment variable, a config key, a dependency, a
  migration, or a run/setup/deploy step in the target project", and
  `:895-900` states the same-unit-of-work maintenance rule.

## Open unknowns for the proposal to route

- **U1 — approval artifact granularity.** The `APPROVE issue-107/implementation`
  comment's author (`jjongkwann`, listed in `docs/specs/approvers.md`) and
  exact body were read this session via `gh issue view 107 --comments`, but no
  allowed `gh` spelling in this session returned its timestamp or URL
  (`gh issue view 107 --json comments --jq …` required approval; the raw
  `gh api …/pulls/108/reviews` spelling was refused by `gh-guard` as a
  review-shaped call for this role). The record cites the comment as
  `issues/107#issuecomment-5173547264`. Ordering evidence available without
  the timestamp: `67eb71e` (2026-08-03 21:34:09 +0900), PR #108 created
  2026-08-03T12:35:37Z, `ace7dda` (2026-08-04 10:37:57 +0900), merge
  `f6d6983` (2026-08-04 11:03:46 +0900).
- **U2 — the refusal event leaves no repository artifact.** Whether
  `handbook-trigger-gate.sh` actually fired on the observed session's commit
  attempt is asserted only by the record. Static reading can establish what the
  in-force gate does with a given staged set; it cannot establish that the
  event occurred. The proposal must state which of the two it will judge on.
- **U3 — the red half of the red-green proof is unrepeatable here.** The
  pre-fix `want=deny got=allow` run is a claim about an execution this role is
  forbidden to reproduce. Only static cross-checks (case tally above, diff
  shape, ordering) are admissible.
- **U4 — PR #108 carries no PR-level review** (`gh pr view 108 --json reviews`
  → `[]`), and its body states it was opened by a relay account on the role
  session's behalf. Which contract v3 s19 path was in play, and whether the
  read artifacts satisfy it, is a phase-2 question.
- **U5 — spec-vs-gate scope for section 21.** The contract's substantive list
  (`:855-860`) and the gate's conservative regex (`:103`) do not obviously
  cover the same set for a test-runner script. Judging the deviation requires
  saying which one governs.
- **U6 — citation drift inside the observed session's own documents.** The
  proposal cites `_cd_target`'s call site as `board-gate.sh:330` and
  `gate_head_of`'s as `:329` (`proposal:70`, `:93`, `:121`); the record cites
  `:334` and `:333` (`implementation.md:33`, `:37`). The delivery adds four
  docstring lines above them in the same file.
