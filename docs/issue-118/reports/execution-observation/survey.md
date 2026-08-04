---
kind: current-state-survey
subject: issue-118
produced_by: execution-observation
observed_role: implementation
observed_pr: 120
loop_state: surveyed
---

# Survey — issue-118 step 2: current state of the artifacts PR #120 left behind

## Scope of this observation

This session observes **one** target, named exactly:

- **Role**: `implementation`, on branch `issue-118/implementation`.
- **Issue**: #118 — "관찰 기록 관례에 '결함 클래스 식별 + 다른 서식지' 표준
  질문 추가 — 반복 사이클 수렴책", state `OPEN`, author `jjongkwann`,
  execution plan step 1 `implementation` / step 2 `execution-observation`.
- **PR**: **#120**, "propose(implementation): add defect-class +
  other-habitats question to record norm (#118)", base `main`, head
  `issue-118/implementation`, state `MERGED`, merge commit
  `a167f117a75dcfc94cc4d2549477bb36378508f2`.
- **Session under observation**: that PR's two commits —
  `caed0b13b9f5d17f7ba76ebe306a764acf7810ef` (phase 1) and
  `1b1056578d85c8f5c63b47d540bc00296d1f2124` (phase 2).

Anything outside that PR — issue #116/PR #117, issue #122/PR #123, PR #121,
and every earlier issue's delivery — is context only (format precedent, or
input to the class question below), never the observation target.

## What was read this session, and how

Read directly, in this session, by this role:

| artifact | how it was read |
|---|---|
| issue #118 body + execution plan | `gh issue view 118` |
| issue #118's one comment, byte-exact body + `created_at` + author | `gh api repos/tokenmaxxxer/tokenmaxxxer-core/issues/118/comments` |
| PR #120 metadata (author, state, `reviews`, `mergedAt`, `mergeCommit`, both commits' authored/committed dates, body) | `gh pr view 120 --json …` |
| PR #120's full diff | `gh pr diff 120` |
| `caed0b1` — message, author, date, `--stat` | `git show --stat caed0b1` |
| `1b10565` — message, author, date, `--stat` | `git show --stat 1b10565` |
| `docs/issue-118/reports/implementation.md` (the observed role's own record, 188 lines) | full read |
| `docs/issue-118/proposals/2026-08-04-add-defect-class-and-other-habitats-question-to-record-norm.md` (169 lines) | full read |
| `docs/issue-118/reports/implementation/survey.md` (head, lines 1–60) + targeted grep over the whole file | `sed -n '1,60p'`, `grep -n -i "scout\|skip"` |
| `docs/specs/approvers.md` | full read |
| `docs/issue-118/reports/implementation/` directory listing (what phase-1 artifacts exist) | `ls -R docs/issue-118` |
| PR/branch ledger (which PRs exist, which are merged) | `gh pr list --state all`, `git log --oneline` |

Read as format precedent only, not as evidence about this delivery:
`docs/issue-114/reports/execution-observation/survey.md`,
`docs/issue-114/reports/execution-observation/scout-brief.md`,
`docs/issue-114/proposals/2026-08-04-independent-observation-of-pr-115.md`.

Nothing about this delivery is taken from a secondhand summary. Nothing was
re-executed — no test suite, no hook, no gate invocation. No subagent was
used to read any artifact this survey cites: the role's citation rule
("never state a verdict about an artifact not read this session") makes
delegated reading inadmissible, so every row above is a direct call from
this session.

## The delivery, described

**Phase-1 commit `caed0b1`** (authored 2026-08-04T05:15:26Z), `--stat`: two
files, 341 insertions, zero deletions —
`docs/issue-118/proposals/2026-08-04-add-defect-class-and-other-habitats-question-to-record-norm.md`
(169) and `docs/issue-118/reports/implementation/survey.md` (172). No file
under `core/` appears in that stat. Its `committedDate` is
2026-08-04T05:52:20Z, later than its `authoredDate` — the observed record
(`docs/issue-118/reports/implementation.md:28-34`) states the branch was
rebased onto `origin/main` at phase 2, which is consistent with a rewritten
committer date on the phase-1 commit.

**Phase-2 commit `1b10565`** (authored and committed 2026-08-04T05:55:39Z),
`--stat`: two files, 196 insertions, zero deletions —
`core/contract/role-handoff-contract.md` (+9) and
`docs/issue-118/reports/implementation.md` (+187).

The contract change itself, from `gh pr diff 120` (hunk header
`@@ -836,6 +836,15 @@`, one file, 9 insertions / 0 deletions): after §20's
existing item 5, a new lead-in paragraph — "Additionally, whenever the
role's record states a confirmed `finding` entry (section 2's `finding`
kind, any `verdict` other than `Unverifiable`), the record must state:" —
followed by a new numbered item 6, "**Defect class and other habitats** —
(a) which defect class the finding belongs to, and (b) whether that class
was checked for elsewhere in the codebase outside the observed scope,
recording either the sweep's result or the reason a sweep was not
possible." No gate script, no test file, and no other section appears in
either stat.

## Timeline, from artifact timestamps only

| when (UTC) | what | source |
|---|---|---|
| 2026-08-04T05:15:26Z | `caed0b1` authored (docs only: proposal + survey) | `gh pr view 120 --json commits`, `git show --stat caed0b1` |
| 2026-08-04T05:15:43Z | PR #120 opened | `gh pr list --state all` (`createdAt`) |
| 2026-08-04T05:21:11Z | issue #118 comment id `5174945342`, body exactly `APPROVE issue-118/implementation`, user `jjongkwann` | `gh api …/issues/118/comments` |
| 2026-08-04T05:52:20Z | `caed0b1` re-committed (rebase onto `origin/main`) | `gh pr view 120 --json commits` (`committedDate`) |
| 2026-08-04T05:55:39Z | `1b10565` authored and committed (contract edit + record) | `git show --stat 1b10565` |
| 2026-08-04T06:00:18Z | PR #120 merged as `a167f11` | `gh pr view 120 --json mergedAt,mergeCommit` |

PR #120's `reviews` array is empty (`gh pr view 120 --json reviews` →
`"reviews":[]`); its author is `jjongkwann`; `docs/specs/approvers.md` lists
`JiwonJung94` and `jjongkwann`. Which contract v3 §19 approval path this
configuration selects, and whether the observed ordering satisfies it, is a
phase-2 question, not settled here.

## This role's own approval state (stated, not judged)

Issue #118 carries exactly one comment (`gh api …/issues/118/comments`
returns a single object), and its body is `APPROVE issue-118/implementation`
— the observed role's string, not this role's. No comment whose entire body
is `APPROVE issue-118/execution-observation` exists, and PR #121/#123 are
other branches' PRs. This is not a near-miss or an approval-shaped
ambiguity: it is a valid approval addressed to a different role. This
session therefore stops at phase 1 after committing the three artifacts
named under "Write surface" below.

## Unknowns carried into phase 2

Stated as questions. None is answered here; each names the evidence that
will settle it.

- **U1 — is there a scout pass or a scout skip record in the observed
  phase-1?** `ls -R docs/issue-118` shows
  `docs/issue-118/reports/implementation/` contains `survey.md` only — no
  `scout-brief.md`. `grep -n -i "scout\|skip"` across the observed survey,
  proposal, and record returns five hits, all of which are either the word
  "skipped" in unrelated prose
  (`…proposals/2026-08-04-add-defect-class…md:21`,
  `docs/issue-118/reports/implementation.md:145`) or the literal path
  `scout/hooks/directive.sh`
  (`docs/issue-118/reports/implementation.md:46,114,124`). Whether a scout
  pass was owed for a norm-text change with an open placement decision, and
  whether its absence is chargeable against this delivery at all, is a
  phase-2 question. Evidence needed: the directory listing and grep above,
  read against the scout directive's own two skip conditions.
- **U2 — the proposal's `upstream[].sha` placeholder.**
  `docs/issue-118/proposals/2026-08-04-add-defect-class-and-other-habitats-question-to-record-norm.md:8`
  reads `sha: <set at commit>` and is unchanged at `a167f11`, while the
  record's own frontmatter
  (`docs/issue-118/reports/implementation.md:9`) does carry a real SHA
  (`caed0b13b9f5d17f7ba76ebe306a764acf7810ef`). Whether that field state is
  chargeable here, and whether it is the same class a prior observation
  record already charged, is a phase-2 question — the prior record must be
  read at a pinned SHA before it is cited.
- **U3 — placement fidelity between the approved proposal and the landed
  text.** The proposal's `## What will be done` item 1 (`:116-124`) says
  "append one new numbered item to the 'A role record must state, at
  minimum' list", and `## How you'll know it worked` (`:157-160`) says the
  item is "positioned among the existing numbered list without renumbering
  or altering items 1–5". The landed diff places item 6 under a **new
  conditional lead-in paragraph** of its own, i.e. a third tier alongside
  the unconditional items 1–3 and the "leaves work open" items 4–5. Whether
  the landed shape is what the approved proposal said would be done is a
  phase-2 question. Evidence: the diff hunk and both proposal passages,
  already read.
- **U4 — binding scope of the landed norm.** Issue #118 requirement 1 asks
  for the addition to the *observation*-record norm ("관찰 기록 규범"); the
  landed sentence binds "the role's record" for any role, because §20 is
  role-agnostic. The observed survey
  (`docs/issue-118/reports/implementation/survey.md:47-55`) argues from
  `grep -in observation core/contract/role-handoff-contract.md` that no
  observation-specific section exists to host it. Whether the delivered
  scope is what the issue asked, over-broad, or the only available home, is
  a phase-2 question. Evidence: the issue body, the diff text, and a
  re-verification of that grep claim at pinned SHA `a167f11`.
- **U5 — the "no mechanization" constraint (issue requirement 2 /
  `## 제약` item 1).** The record claims
  (`docs/issue-118/reports/implementation.md:106-116`, `closed_checks`
  `:120-124`) that `core/hooks/record-fields-gate.sh`'s checks are a fixed
  hardcoded list that does not derive from §20's item count, so item 6
  cannot be silently mechanized. This is checkable statically at pinned SHA
  without re-execution. Evidence needed: `a167f11:core/hooks/record-fields-gate.sh`
  read directly, plus the `--stat` of both commits for the "gate unchanged"
  half.
- **U6 — requirement 3 (cross-repo rulebook reflection).** The record's
  `## Next steps` (`:128-144`) recommends a follow-up issue against
  `tokenmaxxxer/execution-observation-rulebook` rather than editing it.
  Whether that discharges requirement 3's "룰북 반영 필요성을 기록에
  남긴다", and whether the #106 precedent it invokes has the same shape, is
  a phase-2 question. Evidence needed: pinned read of
  `docs/issue-106/reports/implementation.md`'s `## Next steps`.
- **U7 — the population question for this delivery's own class.** The
  record's `## What was done` item 3 (`:45-51`) reports a grep over three
  `directive.sh` files as its "other habitats" sweep. Whether that
  enumerates the population of in-repo documents that state record-content
  requirements — and would therefore now be one question short of §20 — is
  a phase-2 question. Evidence needed: an enumeration at pinned SHA of
  every in-repo file that states record-content requirements, each read
  before it is cited.
- **U8 — frontmatter dialect of the observed survey.**
  `docs/issue-118/reports/implementation/survey.md:1-5` carries `kind`,
  `subject`, `produced_by` and no `loop_state:`, while the same session's
  proposal (`:5`) and record (`:6`) both carry one. Whether a survey owes a
  `loop_state` under the contract, and whether `record-fields-gate.sh`'s
  scope reaches survey files at all, is a phase-2 question — settled from
  `a167f11:core/hooks/record-fields-gate.sh` and the contract's §2 table,
  not from this observation's preference.

## Write surface of this session

This role writes exactly three paths, all new:

- `docs/issue-118/reports/execution-observation/survey.md` (this file)
- `docs/issue-118/reports/execution-observation/scout-brief.md`
- `docs/issue-118/proposals/2026-08-04-independent-observation-of-pr-120.md`

and, only after a contract v3 §19 approval,
`docs/issue-118/reports/execution-observation.md`. Nothing under `core/`,
nothing under `docs/issue-118/reports/implementation*`, nothing under
`docs/issue-118/proposals/2026-08-04-add-defect-class…md`, nothing under any
other issue's tree.
