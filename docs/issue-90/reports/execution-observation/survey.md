---
kind: execution-observation-survey
subject: issue-90
produced_by: execution-observation
loop_state: proposed
upstream: []
---

# Current-state survey — issue-90 execution observation

## 0. Scope: exactly what is under observation

- **Observed role**: `implementation`.
- **Observed session**: its issue-90 pass, 2026-08-03 (propose commit
  authored 10:00:56 +0900, deliver commit 10:17:26 +0900).
- **Issue**: #90, "board-gate 판정 실패 시 언급된 docs 경로 전부를 쓰기
  후보로 수집 + approval-gate의 쌍둥이 결함(cd 부재·따옴표 무시)",
  state OPEN (reopened), author `jjongkwann`.
- **PR**: **#91**, head `issue-90/implementation` → base `main`, state
  MERGED at 2026-08-03T01:21:15Z, mergeCommit `1df0147`.
- **Commits**: `d52d1e6` (propose), `c66aecc` (deliver).
- **Observed record**: `docs/issue-90/reports/implementation.md` at
  `c66aecc`.

This document is a survey, not a judgment: it inventories what exists and
what is still unresolved. No verdict is rendered here; verdict language
belongs to phase 2.

## 1. Evidence actually read this session

| # | Artifact | Read as |
|---|---|---|
| E1 | Issue #90 body + both comments | `gh issue view 90`, `--comments` |
| E2 | `docs/specs/approvers.md` | worktree file |
| E3 | PR #91 metadata, body, reviews, comments | `gh pr view 91 --json ...` |
| E4 | `c66aecc` full stat + `board-gate.sh` / `approval-gate.sh` diffs | `git show` |
| E5 | `c66aecc^` pre-change blobs of both gates | `git show c66aecc^:...` |
| E6 | `c66aecc` test-harness diffs (both harnesses) | `git show` |
| E7 | `docs/issue-90/reports/implementation.md` (147 lines) | `git show c66aecc:...` |
| E8 | `d52d1e6` stat; `docs/issue-90/` tree at `c66aecc` | `git show --stat`, `git ls-tree` |
| E9 | `git log --oneline -- core/hooks/tests/run-approval-gate-tests.sh` | full file history |
| E10 | `docs/issue-12/reports/review.md` frontmatter (record-convention comparator) | worktree file |

Not read, deliberately: nothing was re-executed. Neither gate nor either
harness was run in this session — the observed role's artifacts are the
only admissible evidence for this role.

## 2. Surface A — board-gate write-candidate scoping (`c66aecc`)

- `core/hooks/board-gate.sh:208-240` (`c66aecc`) is the new
  `_write_candidate_segments(cmdline)`; `_reads_only()` at
  `board-gate.sh:243-245` is now `return not _write_candidate_segments(cmdline)`.
- The `Bash` candidate builder at `board-gate.sh:256-268` computes
  `failing_segments` once (`:257`), early-`allow()`s when it is empty
  (`:258-259`), and runs the pre-existing `docs/`-token `re.findall`
  over `scan_text = "\n".join(failing_segments)` (`:264-265`) instead of
  the raw `cmdline`.
- Pre-change comparator: `c66aecc^:core/hooks/board-gate.sh:208-227`
  (`_reads_only` returning a bool) and `:243` (the `re.findall` over the
  whole `cmdline`).
- One structural difference beyond "same rules, finer granularity":
  pre-change, `SUBSHELL`/`FILE_REDIR` were tested **once against the
  entire probe** (`c66aecc^:211-212`, early `return False`); post-change
  they are tested **per segment** (`c66aecc:226`). Unresolved — see G1.
- Regression cases added by `c66aecc` at
  `core/hooks/tests/run-board-gate-tests.sh:269` (allow
  `bash-unresolved-head-then-read`) and `:273` (deny
  `bash-unresolved-head-real-write`).
- Harness assertion mechanism: `run-board-gate-tests.sh:22-28`
  (`report()`) compares only `want` vs `got`; `got` is derived purely
  from the gate's exit code, and the gate's stdout/stderr are discarded
  at `:42` (`>/dev/null 2>&1`). **No deny-reason string is asserted
  anywhere in this harness.**
- Case count independently recomputed from the harness at `c66aecc`:
  47 `run` + 10 `runb` + 5 `drifted` + 1 `noRole` + 1 `noremote` +
  1 `fastpath` + 2 `garbage` = **67 registrations**, matching the
  denominator in the `c66aecc` commit message. A registration count is
  not a pass count.

## 3. Surface B — approval-gate `cd` + quote recognition (`c66aecc`)

- `core/hooks/approval-gate.sh:84-85` adds `"cd"` to `READ_ONLY_HEADS`;
  `:96` replaces `WRITEISH` with the quote-span-first, `(?<!\\)`-guarded
  alternation; `:101-107` is the new `_writeish()`; the call site at
  `:139` becomes `if head in READ_ONLY_HEADS and not _writeish(cmdline):`.
- Pre-change comparator: `c66aecc^:core/hooks/approval-gate.sh:84-86`
  (11-member tuple ending at `"git"`, `WRITEISH = re.compile(r"[>|`]|\$\(")`)
  and `:120` (the `WRITEISH.search` call site).
- Structural fact that differs from board-gate: `approval-gate.sh` has
  **no segment splitting at all**. `head` is the first word of the whole
  line (`approval-gate.sh:138`), so `cd X && <anything>` classifies as
  head `cd` for the entire line, and the only thing standing between a
  `cd`-headed write and the early `allow()` is `_writeish()` over the
  whole line. Unresolved — see G3.
- Regression cases added by `c66aecc` at
  `core/hooks/tests/run-approval-gate-tests.sh:166, 169, 176, 177, 180, 186`
  (2 allow / 1 deny for `cd`; 2 allow / 2 deny for quoting).
- Harness mechanism: `run-approval-gate-tests.sh:96-100` builds the
  `Bash` payload with `printf '{"command":"%s"}' "$cmd"` — **no JSON
  escaping**; `:103` discards stdout/stderr; `:105` maps exit code
  0→allow / 2→deny / other→`exit-$rc`; `:21-27` `report()` does plain
  string equality. Same as board-gate: **exit code only, no reason
  assertion.**
- Case count independently recomputed at `c66aecc`: 39 `run` lines +
  `noremote` + `norole` + `kill_switch` = **42 registrations**, matching
  the denominator in the commit message.

## 4. Surface C — the observed role's own record

- `docs/issue-90/reports/implementation.md:56-59` asserts `67 passed,
  0 failed` and `42 passed, 0 failed`; `:146-147` repeats them under
  `## Verify`.
- `:61-81` (`## What did not work`) reports that three approval-gate
  cases initially carried an unescaped `"`, produced invalid JSON, and
  were denied through the unrelated unreadable-payload path — two of
  them coincidentally matching `want deny` without exercising
  `_writeish`.
- Corroboration status of that episode: `git log --oneline --
  core/hooks/tests/run-approval-gate-tests.sh` shows `c66aecc` as the
  only commit touching those lines, and its diff is **add-only** (no `-`
  lines). The broken intermediate state is therefore not in version
  control; what is observable is the surviving escaping in the committed
  literals (`:176`, `:180`, `:186`) and the in-file note at `:170-175`.
- `implementation.md:5` sets `code_under_review: d52d1e68...` — the
  **propose** commit — and all five `closed_checks` entries cite
  `code_sha: d52d1e68...` (`:101, :107, :112, :117, :122`), i.e. the
  proposal sha rather than the delivered code `c66aecc`. Comparator:
  `docs/issue-12/reports/review.md` frontmatter carries
  `code_under_review: 380c263...` alongside a separate `upstream.sha`.
  Unresolved — see G6.

## 5. Surface D — process trajectory artifacts

- Approval path: PR #91's `reviews` and `comments` are both empty
  arrays; the approval signal is issue comment #1 on #90, body exactly
  `APPROVE issue-90/implementation`, author `jjongkwann`, who is listed
  in `docs/specs/approvers.md`. PR author is the same account →
  single-account mode.
- PR #91's body still reads "No code changes in this PR — phase 1 only.
  Phase 2 (implementation) opens after an approvers.md human Approves."
  after `c66aecc` landed 7 files including both gates.
- `c66aecc`'s message contains `Closes #90` while the issue's plan had
  `step 2 execution-observation` unchecked; issue comment #2 records the
  human reopening #90 for exactly that reason.
- `d52d1e6` touched only `docs/issue-90/proposals/2026-08-03-...md` (214
  lines) and `docs/issue-90/reports/implementation/survey.md` (200
  lines) — no code, consistent with a phase-1-only commit.

## 6. This role's own current state

- Branch `issue-90/execution-observation` is at `1df0147`, identical to
  `origin/main`; working tree clean at session start.
- No PR exists for head ref `issue-90/execution-observation` (checked
  across all 50 PRs in the repo).
- No comment on #90 equals the exact string
  `APPROVE issue-90/execution-observation`. Under single-account mode
  that is the only phase-2 opener for this role, so **phase 2 is not
  open in this session**; `docs/issue-90/reports/execution-observation.md`
  must not be written yet.
- No `execution-observation` record or directory exists anywhere in the
  repo yet — this is the first instance of the role, so there is no
  in-repo precedent for its record shape; `kind:`/filename conventions
  above are inferred from `review-record` and `implementation-survey`.

## 7. Unknowns the observation must resolve (gaps → phase 2)

- **G1** — Did moving `SUBSHELL`/`FILE_REDIR` from whole-probe to
  per-segment narrow R4's reach? Depends on whether `_split_segments`
  keeps a redirect operator and its target inside one segment. Neither
  new board-gate case discriminates this: `date > docs/...` is a single
  segment.
- **G2** — Do `bash-unresolved-head-then-read` / `-real-write` actually
  discriminate the change, or would they produce the same verdict under
  `c66aecc^`?
- **G3** — Same question for each of the six approval-gate cases, and
  specifically: with no segment splitting, does `bash-cd-then-write-src`
  deny *because of* the write-ish check, or via the later
  `CODE_RE`/`ISSUE_RE` token loop that would have denied it anyway?
- **G4** — Because both harnesses assert exit code only, does each deny
  case reach the `deny()` call the case name claims, rather than an
  unrelated one (unreadable payload, no-remote, wrong-branch)?
- **G5** — Is the record's vacuous-JSON episode traceable in artifacts,
  and does any *pre-existing* case in either harness still construct
  invalid JSON (the `run()` builder at `:96-100` was left unchanged)?
- **G6** — Does `code_under_review: d52d1e6` (a docs-only commit) match
  this repo's record convention and contract v3?
- **G7** — Trajectory: was the propose → human-approve → deliver order
  actually honoured, and what is the standing of the stale PR body and
  the `Closes #90` keyword against the unexhausted plan?

## 8. Scout record

Scouting is **not** skipped: neither skip condition applies — this is
not a bugfix, and the deliverable (what an execution observation checks
and what counts as admissible evidence) has open design decisions. Per
SURVEY-FIRST order the scout sweep runs after this survey and its brief
lands at `docs/issue-90/reports/execution-observation/scout-brief.md`;
its angles are aimed at G1-G5 (how strong audits establish that a green
suite and its negative cases mean what they claim) and G4 in particular.
