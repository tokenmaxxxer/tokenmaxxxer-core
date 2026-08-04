---
kind: observation-record
subject: issue-114
produced_by: execution-observation
observed_role: implementation
observed_pr: 115
loop_state: landed
upstream:
  - path: docs/issue-114/reports/execution-observation/survey.md
    sha: 05fc069d14f1f2d705e09608a9c11b27f23061cd
  - path: docs/issue-114/reports/execution-observation/scout-brief.md
    sha: 05fc069d14f1f2d705e09608a9c11b27f23061cd
  - path: docs/issue-114/proposals/2026-08-04-independent-observation-of-pr-115.md
    sha: 05fc069d14f1f2d705e09608a9c11b27f23061cd
---

# Execution observation — issue-114, step 2

## Independence

This role did not author, edit, or contribute to PR #115, to its commits
`71f1104` / `e51b301`, or to the `implementation` role's own record
`docs/issue-114/reports/implementation.md`. It did not re-run that role's
task: `run-board-gate-tests.sh`, `run-gate-lib-tests.sh`,
`run-gh-guard-tests.sh`, `board-gate.sh`, and the Hunt's scratch probe
harness were never invoked in this session. This session's only write
surface is this file plus the three phase-1 paths named in
`docs/issue-114/proposals/2026-08-04-independent-observation-of-pr-115.md:189-203`.
Nothing under `core/`, nothing under `docs/issue-114/reports/implementation*`.

**No verdict language appears above this line.** Everything below it is
verdict-bearing and carries its citation adjacent to the claim.

## Why

Issue #114's execution plan, step 2 — independent observation of step 1's
delivery. The observation target is fixed by the phase-1 survey
(`docs/issue-114/reports/execution-observation/survey.md:12-31`): the
`implementation` role on branch `issue-114/implementation`, delivered as
PR #115 (`https://github.com/tokenmaxxxer/tokenmaxxxer-core/pull/115`,
state `MERGED`, merge commit `451439e`), commits `71f1104` (phase 1) and
`e51b301` (phase 2), plus that role's own record.

Phase 2 opened under contract v3 §19's single-account path: PR #115's
author is `jjongkwann`
(`gh pr view 115 --json author` → `"login":"jjongkwann"`), `reviews` is
`[]`, `docs/specs/approvers.md:1-2` lists `JiwonJung94` and `jjongkwann`,
and issue #114 carries a comment whose entire body is the exact string
`APPROVE issue-114/execution-observation`, posted by `jjongkwann`
(`type: User`, not a bot) at 2026-08-04T05:21:12Z —
`https://github.com/tokenmaxxxer/tokenmaxxxer-core/issues/114#issuecomment-5174945571`,
read byte-exact via `gh api repos/…/issues/114/comments`. String equality,
not prose interpretation. No near-miss approval-shaped comment exists on
this issue: the only other comment is `APPROVE issue-114/implementation`
(`…#issuecomment-5174628003`), which is the *other* role's approval and
is exact for its own subject.

The user's step-2 framing adds one scope item beyond the three-level
verdict: whether the wrapper parser-differential class traced
#99 → #107 → #114 is exhausted. That is answered in
`## Verdict 4 — the class question`.

## What was done

Every artifact below was read directly in this session, at a pinned SHA
or through the GitHub API; nothing is carried from a secondhand summary.

| artifact | how read |
|---|---|
| issue #114 body, and both comments byte-exact | `gh issue view 114`, `gh api …/issues/114/comments` |
| PR #115 metadata: author, state, `createdAt` 2026-08-04T03:08:38Z, `mergedAt` 2026-08-04T05:03:41Z, `mergeCommit` `451439e`, `reviews: []`, both commit objects | `gh pr view 115 --json …` |
| PR #119 metadata (this role's own PR): `reviews: []`, `comments: []` | `gh pr view 119 --json …` |
| `71f1104` message, author, date, `--stat` | `git show --stat 71f1104` |
| `e51b301` message, author, date, `--stat`, full diff of `core/hooks/board-gate.sh` and `core/hooks/tests/run-board-gate-tests.sh` | `git show e51b301 -- <paths>` |
| `docs/issue-114/reports/implementation.md` (219 lines, full) | full read |
| `451439e:docs/issue-114/proposals/2026-08-04-fix-board-gate-wrapper-git-subcommand-extraction.md:1-11` (frontmatter) | pinned read |
| `451439e:docs/issue-114/reports/implementation/survey.md:196-218` (scout skip record) | pinned read |
| `451439e:core/hooks/lib/gate-lib.py:190-300` (`TRANSPARENT`, `_resolve_transparent`, `gate_head_of`, `gate_trailing_words`, `gate_wrapper_head_before` docstring) | pinned read |
| `451439e:core/hooks/board-gate.sh:180-275` (`_git_subcommand`, `_segment_is_failing`, `_write_candidate_segments`, `_cd_target`) | pinned read |
| `451439e:core/hooks/approval-gate.sh:88-135` | pinned read |
| `451439e:core/hooks/trailer-gate.sh:79-110`, `451439e:warrant/hooks/scope-gate.sh:210-245` | pinned read |
| `e51bc09` diff of the `TRANSPARENT` tuple (issue-98 boundary) | `git show e51bc09 -- core/hooks/…` |
| `docs/issue-98/reports/execution-observation.md:494-511` (Finding 4) | full read of that finding |
| `451439e:docs/issue-100/decisions/2026-08-03-record-citation-format-and-kind-convention.md:1-80` | pinned read |
| every resolver call site in the repo | `git grep -n "gate_head_of\|gate_trailing_words\|gate_wrapper_head_before" 451439e -- core warrant` |
| every raw-`split()` site in the hook trees | `git grep -n "split()" 451439e -- core/hooks warrant/hooks` |

The first write of this file, attempted as the opening act of phase 2 with
`loop_state: phase-2-opened` and only the independence statement filled in,
was refused by `core/hooks/record-fields-gate.sh` for missing the required
`what-was-done` / `why` / `open-findings` sections. The file therefore
lands complete rather than incrementally, with `loop_state: landed`; no
verdict was written before the independence statement in either attempt.

## Verdict 1 — outcome

**PR #115 landed what issue #114 asked. All three requirements and both
constraints are met.**

**Requirement 1 — unify `_git_subcommand`'s argument extraction onto the
same command-start model as head resolution.** Met. The `e51b301` diff of
`core/hooks/board-gate.sh` replaces `words = segment.split()[1:]` /
`for w in words:` with the single line
`for w in gate_lib.gate_trailing_words(segment):`; the pinned post-merge
blob confirms it at `451439e:core/hooks/board-gate.sh:204`, reached from
the head decision at `451439e:core/hooks/board-gate.sh:222-224`
(`head = gate_lib.gate_head_of(stripped)` then `if head == "git"`). Both
now read the same `_resolve_transparent` output
(`451439e:core/hooks/lib/gate-lib.py:203-256`). The function's signature
and its sole call site are unchanged, as the diff shows.

**Requirement 2 — red→green regression proof, including one pre-#98
wrapper shape and the reverse write direction.** Met on case shapes,
directly verified; met on run results as a record claim only.

- The three cases exist with the required shapes at
  `e51b301`'s diff of `core/hooks/tests/run-board-gate-tests.sh:241-253`:
  `bash-wrapper-timeout-git-log-foreign-issue`
  (`timeout 30 git log --oneline -1 -- docs/issue-49`, want `allow`),
  `bash-wrapper-command-git-log-foreign-issue`
  (`command git log …`, want `allow`),
  `bash-wrapper-timeout-git-rm-foreign-issue`
  (`timeout 30 git rm -r docs/issue-49/reports`, want `deny`).
- The "pre-#98 wrapper" clause is satisfied by `command`, and this is
  checkable rather than asserted: `e51bc09` (the issue-98 delivery) shows
  the tuple changing from
  `TRANSPARENT = ("xargs", "env", "time", "nice", "command", "builtin")`
  to the eight-member tuple that adds `"timeout", "nohup"` — so `command`
  predates #98 and `timeout` does not. The delivery covers one of each.
- The red→green *numbers* (`87 passed / 2 failed` pre-fix, both
  `want=allow got=deny`; `89 passed / 0 failed` post-fix) come from
  `docs/issue-114/reports/implementation.md:142-156`. Evidence tier:
  **record claim**. This role does not re-execute the observed role's
  suite, so the numbers are reported as that record's claim, not as an
  independently confirmed fact. What *is* independently confirmed is that
  the claim is mechanically coherent: pre-fix,
  `gate_trailing_words("timeout 30 git log …")` is unreachable and
  `segment.split()[1:]` yields `["30", "git", …]`, whose first non-flag
  word `"30"` is not in `GIT_READ_SUBCOMMANDS`
  (`451439e:core/hooks/board-gate.sh:180-185`), so the segment becomes a
  write candidate — the `want=allow got=deny` the record reports is the
  arithmetic the pinned blobs predict.

**Requirement 3 — no regression in existing negative space or in the
#99/#107 landed cases.** Met as a record claim
(`docs/issue-114/reports/implementation.md:151-163`, `:164-172`: 86
pre-existing cases still passing, `gate-lib` 53/1 with the one failure a
pre-existing macOS `mktemp -d` artifact, `gh-guard` 52/0). Same tier as
above. Structurally corroborated without re-execution: `e51b301 --stat`
touches four files and none of them is `core/hooks/lib/gate-lib.py` or
`core/hooks/gh-guard.sh`, so the two suites the record reports on could
not have been affected by this write set.

**Constraint A — `gate_trailing_words` and `_cd_target` unchanged (#107's
property).** Met. `git show --stat e51b301` lists exactly
`core/hooks/board-gate.sh`, `core/hooks/tests/run-board-gate-tests.sh`,
`docs/handbooks/board-gate-tests.md`,
`docs/issue-114/reports/implementation.md` — `gate-lib.py` is absent, and
the board-gate diff's only hunk is `_git_subcommand`'s docstring and body.
`_cd_target` at `451439e:core/hooks/board-gate.sh:267-280` is untouched.

**Constraint B — `TRANSPARENT` tuple unchanged.** Met, by the same
`--stat`: the tuple lives in `gate-lib.py`
(`451439e:core/hooks/lib/gate-lib.py:194-200`), which this commit does not
touch.

**One deviation, declared and justified.** `e51b301` also touches
`docs/handbooks/board-gate-tests.md` (+28), outside the proposal's named
write set. The record declares it and gives the cause at
`docs/issue-114/reports/implementation.md:59-76`:
`handbook-trigger-gate.sh` classifies `run-board-gate-tests.sh` as an
operational surface and mechanically refuses a commit that changes it
without a same-commit handbook touch. A gate-forced, declared, in-record
deviation is not a scope breach — and the observed proposal's own
`## Out of scope` had already named this exact possibility. Not charged.

## Verdict 2 — trajectory

**The phase-1 → approval → phase-2 path is the one contract v3 §19
prescribes. No ordering defect.**

Every row below is a timestamp read from an artifact in this session, not
inferred from document order:

| when (UTC) | what | source |
|---|---|---|
| 2026-08-04T03:08:05Z | `71f1104` authored + committed | `git show --stat 71f1104`; `gh pr view 115 --json commits` |
| 2026-08-04T03:08:38Z | PR #115 opened | `gh pr view 115 --json createdAt` |
| 2026-08-04T04:30:35Z | issue comment, body exactly `APPROVE issue-114/implementation`, user `jjongkwann`, `type: User` | `…/issues/114#issuecomment-5174628003` |
| 2026-08-04T04:40:42Z | `e51b301` authored + committed (code + tests + handbook + record) | `git show --stat e51b301` |
| 2026-08-04T05:03:41Z | PR #115 merged as `451439e` | `gh pr view 115 --json mergedAt,mergeCommit` |

- **Phase-1 commit carried no execution work.** `git show --stat 71f1104`
  is two files, 418 insertions, zero deletions, both under
  `docs/issue-114/` — the proposal and the survey. No file under `core/`
  appears. The commit message says so too ("Phase 1 only: survey +
  proposal, no code change"), and the stat confirms it independently.
- **A survey preceded the proposal.** Both land in `71f1104`, and the
  proposal's `upstream[0].path` is
  `docs/issue-114/reports/implementation/survey.md`
  (`451439e:docs/issue-114/proposals/2026-08-04-fix-board-gate-wrapper-git-subcommand-extraction.md:6-8`),
  so the dependency direction is declared in the artifact itself.
- **The approval is real, human, exact, and correctly typed.** Single-account
  mode applies (`reviews: []`, PR author `jjongkwann` also being the only
  plausible approver); the issue-level comment body is byte-exact
  `APPROVE issue-114/implementation`, its author `jjongkwann` is in
  `docs/specs/approvers.md:1-2`, and `type` is `User`, not `Bot`.
- **Phase 2 followed the approval, not the other way round.** 04:40:42Z >
  04:30:35Z — 10 minutes after, from the commit's own author date.
- **The scout skip is recorded and admissible.**
  `451439e:docs/issue-114/reports/implementation/survey.md:196-205` carries
  an explicit `## Scout-directive skip record` stating **Skipped** with the
  reason "pure bugfix to internal command-parsing logic", which is one of
  the two conditions the directive admits. No `scout-brief.md` exists in
  `71f1104`'s stat, consistent with the recorded skip rather than a silent
  omission.

## Verdict 3 — step

**Two step-level deficiencies, both in the observed role's *record*, none
in its shipped code or tests.** They are Findings 1 and 2 below. The code
change, the three test cases, the handbook entry, the proposal, and the
survey are not deficient — see `## What is not deficient`.

Finding 1 is the substantive one: the record's `## Hunt` cites a probe
shape that provably cannot exercise the branch it was chosen to exercise,
so one of the fourteen probes does not support the generalization claim it
is offered for. Finding 2 is a recurrence of a structural defect a prior
observation record already charged and already declared un-fixable at the
role level.

## Verdict 4 — the class question (was #99 → #107 → #114 exhausted?)

**No. The wrapper parser-differential class is not exhausted by PR #115.**
Three habitats remain, each named with its pinned line and its misread
direction. None of them is a charge against PR #115 — issue #114's text
scoped that delivery to `_git_subcommand` alone, and two of the three are
explicitly declared as knowingly-untouched by the observed role itself.

Method: every resolver call site and every raw-`split()` site in `core/`
and `warrant/` was enumerated mechanically at the pinned merge SHA
(`git grep -n "gate_head_of\|gate_trailing_words\|gate_wrapper_head_before" 451439e -- core warrant`
and `git grep -n "split()" 451439e -- core/hooks warrant/hooks`), then each
production hit was read at `451439e` before being cited here.

| site (`451439e`) | command-start model | wrapper prefix reaches it? | direction |
|---|---|---|---|
| `core/hooks/board-gate.sh:222` (`_segment_is_failing` head) | resolver `gate_head_of` | yes | canonical — no differential |
| `core/hooks/board-gate.sh:204` (`_git_subcommand`) | resolver `gate_trailing_words` | yes | **closed by #114** |
| `core/hooks/board-gate.sh:278` (`_cd_target`) | resolver `gate_trailing_words` | yes | closed by #107 |
| `core/hooks/board-gate.sh:341` (in-order `cd` walk) | resolver `gate_head_of` | yes | canonical |
| `core/hooks/gh-guard.sh:147` → `gate_wrapper_head_before` | deliberately *not* the resolver walk | yes | documented design choice, not a defect (`core/hooks/lib/gate-lib.py:281-296` states the reason: the walk would misresolve here, and this call site's failure direction is fail-**open**, so it scans directly instead) |
| **`core/hooks/approval-gate.sh:122`** | raw `cmdline.strip().split()[0]` | **yes — nothing resolves `TRANSPARENT` here** | **R1, fail-closed (over-block)** |
| `core/hooks/lib/gate-lib.py:217` | the canonical model itself | — | — |
| `core/hooks/lib/gate-lib.py:308` | inside `gate_wrapper_head_before` | — | deliberate, as above |
| `core/hooks/record-fields-gate.sh:110`, `warrant/hooks/hunt-guard.sh:98` | not command parsing (env-var and file-content splits) | no | out of class |
| `core/hooks/trailer-gate.sh:83`, `warrant/hooks/scope-gate.sh:226` | regex over the whole command (trailer-gate: `\bgit\b[^\n;&\|]*\bcommit\b`; scope-gate: `GIT_COMMIT.search(command)`), no positional head model | n/a — a prefix does not shift a regex search | out of class |

**R1 — `approval-gate.sh:122`.** `head = cmdline.strip().split()[0].rsplit("/", 1)[-1]`
takes word 0 of the raw command line with no `TRANSPARENT` resolution, and
`451439e:core/hooks/approval-gate.sh:123` uses it for a read-only early
`allow()` ("reading the tree is phase-agnostic",
`451439e:core/hooks/approval-gate.sh:124`). A wrapper prefix
(`timeout 30 grep -rn foo src/`) resolves `head` to `"timeout"`, which is
not in `READ_ONLY_HEADS` (`451439e:core/hooks/approval-gate.sh:88-89`), so
the read-only shortcut is skipped and the command falls through to the
candidate scan — the same fail-closed over-block direction #114 just fixed
in `board-gate.sh`, in a different gate. Tier: **analytic** (static read of
the pinned blob; not exercised, since this role re-executes nothing).

**R2 — `git -C <dir> <subcommand>`, at the very site #114 fixed.** With the
fix in place, `gate_trailing_words("git -C /tmp log")` is
`["-C", "/tmp", "log"]`, and `_git_subcommand`'s first-non-flag-word loop
(`451439e:core/hooks/board-gate.sh:204-207`) returns `"/tmp"`, which is not
in `GIT_READ_SUBCOMMANDS` — write candidate, fail-closed. This is not a
regression: the shipped docstring names it
(`451439e:core/hooks/board-gate.sh:191-194`, "preceded only by
argument-taking global flags (e.g. `-C <dir>`) this function does not
special-case … the safe direction, not a new hole"), and both the observed
proposal and the observed record declare it out of scope
(`docs/issue-114/reports/implementation.md:192-194`).

**R3 — a `TRANSPARENT` wrapper's own value-taking flag.**
`_resolve_transparent`'s flag-skip loop
(`451439e:core/hooks/lib/gate-lib.py:217-234`) treats every `-`-prefixed
token as self-contained, so for `timeout -s KILL 30 git log` it skips `-s`
as a flag, spends the single `TRANSPARENT_TAKES_ARG` slot on `KILL`, and
stops at `30` — resolving the head to `"30"` rather than `"git"`.
`gate-lib.py`'s own docstring states this outright at
`451439e:core/hooks/lib/gate-lib.py:283-291`, listing `nice -n 10`,
`env -u FOO`, `timeout -s KILL 30`, and `xargs -I fmt` as exactly the
shapes the walk misresolves. In `board-gate.sh` the direction is
fail-closed (an unresolved head falls to `return True` at
`451439e:core/hooks/board-gate.sh:238`, i.e. write candidate); in
`gh-guard.sh` it would be fail-open, which is why that caller does not use
the walk at all. R3 is untouched by PR #115 and is the reason Finding 1
exists.

**Statement of coverage.** The enumeration above is exhaustive over what a
static read can enumerate: every call site of the three resolver functions
and every `split()` in the two hook trees at `451439e`. It cannot rule out
a habitat that constructs a command-start decision by some idiom neither
grep matched (e.g. a regex that happens to encode positional assumptions);
that residue is stated rather than papered over.

## Findings

### Finding 1 — the Hunt's `timeout -s KILL 30 git log` probe cannot exercise the branch it is cited for

- **Impact.** `docs/issue-114/reports/implementation.md:116-123` lists "a
  wrapper-own flag-with-separate-value shape (`timeout -s KILL 30 git
  log`)" among the probes said to show that "over-block resolved for the
  whole `TRANSPARENT` class", and `:173-181` reports the whole probe set as
  `allow` post-fix and `deny` pre-fix. That shape cannot produce that
  transition. `_git_subcommand` is called only from the `head == "git"`
  branch at `451439e:core/hooks/board-gate.sh:222-224`, and for this shape
  `gate_head_of` returns `"30"`, not `"git"` (trace of
  `451439e:core/hooks/lib/gate-lib.py:217-234`: `-s` skipped as a flag,
  `KILL` consumes the one `TRANSPARENT_TAKES_ARG` slot, `30` breaks the
  loop — corroborated by the same file's own docstring at `:283-291`, which
  names `timeout -s KILL 30 bash -c` as a shape this walk misresolves).
  `_resolve_transparent` is untouched by `e51b301` (`git show --stat
  e51b301` does not list `gate-lib.py`), so this shape's verdict is
  identical before and after the fix. Either reading of the probe's actual
  text contradicts the recorded result: with a `docs/issue-49` token like
  its siblings, the head falls through to `return True`
  (`451439e:core/hooks/board-gate.sh:238`) and the post-fix verdict is
  `deny`, not the reported `allow`; without such a token, the pre-fix
  verdict is `allow`, not the reported `deny`. The blast radius is bounded
  and does not reach the shipped artifact: the code change, the three
  committed test cases, and the other thirteen probes are unaffected — what
  is overstated is one line of the record's generalization evidence, and
  with it the scope of the sentence "over-block resolved for the whole
  `TRANSPARENT` class".
- **Timeline.** The probes ran before `e51b301` (2026-08-04T04:40:42Z) via
  "a scratch script not committed"
  (`docs/issue-114/reports/implementation.md:111-114`); the claim landed in
  `e51b301` and merged at `451439e` (2026-08-04T05:03:41Z). Raised here on
  2026-08-04, at the first independent read of the record.
- **Root cause.** The probe shape was chosen to test a wrapper-own
  value-flag case, but that case is blocked one layer upstream in
  `gate_head_of` — which this delivery deliberately did not change — so the
  probe never reaches `_git_subcommand` at all. The harness recorded a
  process-level verdict (`allow`/`deny`) without establishing which branch
  the input actually took, and because the scratch script is not committed,
  no reader can re-derive the probe's exact text or its per-branch path from
  the repository. The survey's own trace table had already flagged
  `TRANSPARENT_TAKES_ARG` handling as delicate; the Hunt inherited that
  delicacy without pinning it.
- **Action item.** The human's, not this role's. Two decisions are
  available and independent: (a) whether
  `docs/issue-114/reports/implementation.md`'s `## Hunt` and its fifth
  `closed_checks` entry warrant a `resolved_findings:` amendment under
  contract v3 §16, and (b) whether R3 above — the wrapper-own value-taking
  flag residue at `451439e:core/hooks/lib/gate-lib.py:217-234`, fail-closed
  in `board-gate.sh` — is worth its own issue. Under contract v3 this role
  files neither; both are recorded here for the human to judge.

### Finding 2 — the approved proposal's `upstream[].sha` was never resolved (recurrence of issue-98 Finding 4)

- **Impact.**
  `451439e:docs/issue-114/proposals/2026-08-04-fix-board-gate-wrapper-git-subcommand-extraction.md:8`
  reads `sha: <set at commit>` and is unchanged through the merge. A reader
  cannot tell which revision of
  `docs/issue-114/reports/implementation/survey.md` the proposal was
  approved against. Low severity: both files land in the same commit
  (`71f1104`), so the answer is recoverable from git — but it is recoverable
  by inference, not from the field that exists to state it.
- **Timeline.** Written at `71f1104` (2026-08-04T03:08:05Z), unchanged at
  `e51b301`, merged at `451439e`. The identical field state was charged as
  Finding 4 of `docs/issue-98/reports/execution-observation.md:494-511`,
  two observed cycles earlier.
- **Root cause.** Unchanged from what that prior record diagnosed
  (`docs/issue-98/reports/execution-observation.md:504-508`): a
  self-reference problem — the survey's sha does not exist when the proposal
  citing it is written, and no post-commit amend step exists. It is
  structural, not carelessness, and the prior record's own action item was
  explicitly "None for this role". Recording it again is what makes the
  recurrence visible; issue #100's decision doc
  (`451439e:docs/issue-100/decisions/2026-08-03-record-citation-format-and-kind-convention.md:24-51`)
  solved the *same shape* for `code_under_review` by replacing the sha with
  a write-time-knowable value, and rejected merge-time backfill for reasons
  that apply here verbatim.
- **Action item.** The human's. The structural fix pattern already exists in
  this repo (issue-100 Decision 1); whether to extend it to
  `upstream[].sha` is a decision, not a correction, and this role files no
  issue for it.

## What is not deficient

Stated explicitly, because a verdict that only lists faults misrepresents
the delivery:

- **The code change.** One function body, minimal, reusing the existing
  primitive rather than growing a second copy — `451439e:core/hooks/board-gate.sh:204`.
  Signature and sole call site unchanged, as the `e51b301` diff shows.
- **The test additions.** Three cases, both directions pinned (two
  `want=allow`, one `want=deny`), with the reverse-direction case proving
  the fix does not open a write path —
  `e51b301` diff of `core/hooks/tests/run-board-gate-tests.sh:241-253`.
  The pre-#98 wrapper requirement is met by `command` rather than by
  another `timeout` variant, which is the harder and correct reading of
  issue #114's requirement 2.
- **The declared deviation.** The handbook touch is gate-forced, declared
  at `docs/issue-114/reports/implementation.md:59-76`, and pre-named as a
  possibility by the proposal itself. Not a scope breach.
- **The `## What did not work` and `## Next steps` sections.**
  `docs/issue-114/reports/implementation.md:78-80` and `:187-196` hold
  against the artifacts: the write set matches the stat, and the
  `git -C <dir>` gap the record leaves open is genuinely out of issue
  #114's scope (R2 above). Survey unknown U4 resolves as **no recurrence**
  of `docs/issue-107/reports/execution-observation.md`'s Finding 2 — the
  handbook entry and the record's account of it are consistent here.
- **Citation-canon compliance (survey unknown U5).** Met.
  `docs/issue-114/reports/implementation.md:5` uses a file list for
  `code_under_review`, matching issue-100 Decision 1
  (`451439e:docs/issue-100/decisions/2026-08-03-record-citation-format-and-kind-convention.md:24-51`),
  and `:144, :152, :158, :165, :174` use `ref: <file>:<line>`, matching
  Decision 2 (`:53-64`).
- **The record's self-correction.** `docs/issue-114/reports/implementation.md:124-137`
  records the author's own first-pass misreading of the survey's trace
  table and the re-verification that corrected it. Recording a corrected
  misreading rather than silently fixing it is the behavior the contract
  wants; it is noted here as a strength, not a fault.

## Evidence tiers

- **Artifact** (direct read of a blob, diff, or GitHub API record):
  everything in `## What was done`'s table; the requirement-1, constraint-A,
  constraint-B, and pre-#98-wrapper judgments; the whole trajectory table;
  Finding 2's field state; the habitat enumeration's line citations.
- **Analytic** (derived by reasoning over pinned committed text, no
  execution): Finding 1's branch trace; R1's and R3's direction calls; R2's
  `["-C", "/tmp", "log"]` walk; the coherence check under requirement 2.
- **Record claim** (asserted by the observed role, not independently
  verified here): `87/2` red, `89/0` green, `53/1` gate-lib, `52/0`
  gh-guard, and the thirteen probes other than the one Finding 1 concerns.
- **Out of reach**: the Hunt's exact probe strings and per-probe results.
  The scratch harness is not committed
  (`docs/issue-114/reports/implementation.md:111-114`), so Finding 1 is
  stated as a contradiction between the record's claim and the pinned
  blobs' behavior, not as a reproduction of the probe. Also out of reach:
  any habitat of the class that neither grep pattern in
  `## Verdict 4` would match.

## Open findings

Two, both above and both against the observed role's record, neither
against its shipped code or tests:

1. Finding 1 — the `timeout -s KILL 30 git log` probe cannot exercise the
   branch it is cited for (`docs/issue-114/reports/implementation.md:116-123`,
   `:173-181`).
2. Finding 2 — unresolved `upstream[].sha` placeholder, recurrence of
   `docs/issue-98/reports/execution-observation.md:494-511`.

Separately, and not a finding against PR #115: the class question is
answered **not exhausted**, with residues R1
(`451439e:core/hooks/approval-gate.sh:122`), R2 (`git -C <dir>`, declared
out of scope by the delivery), and R3
(`451439e:core/hooks/lib/gate-lib.py:217-234`) named in `## Verdict 4`.

## Resolution path

This role neither edits the observed artifacts nor files issues (contract
v3: issues are user-authored). Each finding above is resolved by the human
either accepting it as recorded, or — for Finding 1 — by the
`implementation` role amending its own record with a `resolved_findings:`
entry referencing this file, per contract v3 §16. R1 and R3 are codebase
observations for the human to file or decline as they judge.

## Verify

Every citation in this record is re-checkable without running anything:

- `git show --stat 71f1104` → two docs files, no `core/`.
- `git show --stat e51b301` → four files; `core/hooks/lib/gate-lib.py`
  absent (constraints A and B).
- `git show e51b301 -- core/hooks/board-gate.sh` → the one-line iteration
  source change plus docstring.
- `git show e51bc09 -- core/hooks/lib/gate-lib.py | grep TRANSPARENT` →
  the six-member pre-#98 tuple gaining `timeout`, `nohup` (the pre-#98
  wrapper judgment rests on this).
- `git show 451439e:core/hooks/lib/gate-lib.py | sed -n '216,234p;283,291p'`
  → the flag-skip loop and the docstring naming `timeout -s KILL 30` as a
  misresolved shape (Finding 1, R3).
- `git show 451439e:core/hooks/approval-gate.sh | sed -n '88,124p'` → the
  raw `split()[0]` head and its `READ_ONLY_HEADS` early allow (R1).
- `git grep -n "gate_head_of\|gate_trailing_words\|gate_wrapper_head_before" 451439e -- core warrant`
  and `git grep -n "split()" 451439e -- core/hooks warrant/hooks` → the
  habitat enumeration of `## Verdict 4`.
- `gh api repos/tokenmaxxxer/tokenmaxxxer-core/issues/114/comments --jq '.[].body'`
  → the two byte-exact `APPROVE` strings.
