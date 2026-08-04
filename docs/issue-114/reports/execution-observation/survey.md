---
kind: current-state-survey
subject: issue-114
produced_by: execution-observation
observed_role: implementation
observed_pr: 115
loop_state: surveyed
---

# Survey — issue-114 step 2: current state of the artifacts PR #115 left behind

## Scope of this observation

This session observes **one** target, named exactly:

- **Role**: `implementation`, on branch `issue-114/implementation`.
- **Issue**: #114 — "`_git_subcommand` 가 래퍼 접두 세그먼트에서 서브커맨드를
  오독 — #107 클래스의 남은 형제 (#107 관찰 Finding 1)", state `OPEN`,
  author `jjongkwann`, execution plan step 1 `implementation` / step 2
  `execution-observation`.
- **PR**: **#115**, "propose(implementation): fix board-gate wrapper
  git-subcommand extraction (issue-114)", base `main`, head
  `issue-114/implementation`, state `MERGED`, merge commit
  `451439e49eaa9ccf69db997e85e7bf8631383bd1`.
- **Session under observation**: that PR's two commits —
  `71f11040f221277293be46ec7474c51fd3a1598b` (phase 1) and
  `e51b3019a4cfa4cd1d2ac5d893d30c34f1de3d73` (phase 2).

Anything outside that PR — issue #116, issue #117/PR #117, issue #118, and
every earlier issue's delivery — is context for the class question only
(section "The class ledger" below), never the observation target.

## What was read this session, and how

Read directly, in this session, by this role:

| artifact | how it was read |
|---|---|
| issue #114 body + its one comment | `gh issue view 114`, `gh api .../issues/114/comments` |
| PR #115 metadata (author, state, reviews, timestamps, commits, merge commit) | `gh pr view 115 --json …` |
| `71f1104` — message, author, date, `--stat` | `git show --stat 71f1104` |
| `e51b301` — message, author, date, `--stat`, full diff of `core/hooks/board-gate.sh`, `core/hooks/tests/run-board-gate-tests.sh`, `docs/handbooks/board-gate-tests.md` | `git show e51b301 -- <paths>` |
| `451439e` — merge commit metadata | `git log 451439e -1` |
| `docs/issue-114/reports/implementation.md` (the observed role's own record, 219 lines) | full read |
| `docs/issue-114/proposals/2026-08-04-fix-board-gate-wrapper-git-subcommand-extraction.md` (199 lines) | full read |
| `docs/issue-114/reports/implementation/survey.md` (219 lines) | full read |
| `docs/specs/approvers.md` | full read |
| `451439e:core/hooks/lib/gate-lib.py:190-238` (`TRANSPARENT`, `TRANSPARENT_TAKES_ARG`, `_resolve_transparent`) | `git show 451439e:… | sed -n '190,240p'` — a blob **not** touched by `e51b301` |

Not read as a substitute for the above: nothing about this delivery is
taken from a secondhand summary. Nothing was re-executed — no test suite,
no hook, no gate invocation.

Read indirectly (assistant-derived inventory, tier-marked, to be
re-verified against pinned blobs before any phase-2 use): a repo-wide
inventory of raw-text command-parsing sites and a cross-issue ledger of
prior execution-observation findings, produced by read-only search
subagents in this session. Every line of that material that phase 2
relies on will be re-read at a pinned SHA first; nothing from it is
carried as established fact here.

## The delivery, described

**Phase-1 commit `71f1104`** (2026-08-04T03:08:05Z), `--stat`: two files,
418 insertions, zero deletions —
`docs/issue-114/proposals/2026-08-04-fix-board-gate-wrapper-git-subcommand-extraction.md`
(199) and `docs/issue-114/reports/implementation/survey.md` (219). No file
under `core/` appears in that stat.

**Phase-2 commit `e51b301`** (2026-08-04T04:40:42Z), `--stat`: four files,
270 insertions / 2 deletions — `core/hooks/board-gate.sh` (+10/-2),
`core/hooks/tests/run-board-gate-tests.sh` (+14),
`docs/handbooks/board-gate-tests.md` (+28),
`docs/issue-114/reports/implementation.md` (+218).

The code change itself, from the diff of `e51b301`: `_git_subcommand`'s
two lines `words = segment.split()[1:]` / `for w in words:` become the
single line `for w in gate_lib.gate_trailing_words(segment):`, with eight
docstring lines added above. The test change adds three `run` lines —
`bash-wrapper-timeout-git-log-foreign-issue` (`allow`),
`bash-wrapper-command-git-log-foreign-issue` (`allow`),
`bash-wrapper-timeout-git-rm-foreign-issue` (`deny`) — plus an eight-line
comment block. No other file in the repository appears in either stat.

## Timeline, from artifact timestamps only

| when (UTC) | what | source |
|---|---|---|
| 2026-08-04T03:08:05Z | `71f1104` authored and committed (docs only) | `git show --stat 71f1104` |
| 2026-08-04T03:08:38Z | PR #115 opened | `gh pr view 115 --json createdAt` |
| 2026-08-04T04:30:35Z | issue #114 comment, body exactly `APPROVE issue-114/implementation`, user `jjongkwann` | `gh api repos/…/issues/114/comments` |
| 2026-08-04T04:40:42Z | `e51b301` authored and committed (code + tests + handbook + record) | `git show --stat e51b301` |
| 2026-08-04T05:03:41Z | PR #115 merged as `451439e` | `gh pr view 115 --json mergedAt,mergeCommit` |

PR #115's `reviews` array is empty (`gh pr view 115 --json reviews` →
`"reviews":[]`); its author is `jjongkwann`;
`docs/specs/approvers.md` lists `JiwonJung94` and `jjongkwann`. Which
contract v3 §19 approval path this configuration selects, and whether the
observed timeline satisfies it, is a phase-2 question, not settled here.

## The class ledger — what issue #114 sits inside

Issue #114's own body frames the delivery as the remaining sibling of a
class: `#99` (wrapper-prefixed `cd`, Finding 1 of
`docs/issue-99/reports/execution-observation.md`) → `#107` (fix for
`_cd_target`, whose own observation record raised Finding 1 against
`_git_subcommand`) → `#114` (this delivery). The user's step-2 framing
asks additionally whether the class is **exhausted** by #114.

The current-state facts relevant to that question, and where each is
still unpinned:

- `451439e:core/hooks/lib/gate-lib.py:194-200` carries
  `TRANSPARENT = ("xargs", "env", "time", "nice", "command", "builtin",
  "timeout", "nohup")` and `TRANSPARENT_TAKES_ARG = ("timeout",)`;
  `_resolve_transparent` (`:203-235`) skips a wrapper's own flags and,
  for `timeout` only, one bare positional word. **Read directly this
  session.**
- The same file's own docstring for `gate_wrapper_head_before` is cited by
  the derived inventory as documenting wrapper-own value-taking flags
  (`nice -n 10`, `env -u FOO`, `timeout -s KILL 30`, `xargs -I fmt`) as
  shapes the resolver walk misresolves. **Not yet read directly at a
  pinned SHA** — phase 2 must read it before relying on it.
- The derived inventory names further candidate habitats of the
  "two different command-start models in one decision path" shape outside
  `board-gate.sh` — in `core/hooks/approval-gate.sh`,
  `core/hooks/trailer-gate.sh`, and `warrant/hooks/scope-gate.sh` — and
  names `board-gate.sh`'s own `INPLACE`/`FILE_REDIR`/`SED_WRITE_CMD` raw
  scans as same-shape-lower-severity. **None of these are established
  here**; each is a line phase 2 must read at a pinned SHA before the
  exhaustion question can be answered either way.
- Both the observed proposal (`:67-71`, `:152-155`) and the observed
  record (`:192-194`) name the `git -C <dir> <subcommand>` global-flag
  misread as a knowingly-untouched neighbouring gap, and the shipped
  docstring says the same (`e51b301` diff of `core/hooks/board-gate.sh`,
  the `-C <dir>` sentence).

## Unknowns carried into phase 2

Stated as questions. None is answered here; each names the evidence that
will settle it.

- **U1 — does the Hunt's `timeout -s KILL 30 git log` probe discriminate?**
  `docs/issue-114/reports/implementation.md:116-123` lists that shape among
  probes proving the fix generalizes, and `:173-181` states all such probes
  resolved `allow` post-fix and `deny` pre-fix. Hand-tracing
  `451439e:core/hooks/lib/gate-lib.py:203-235` (read directly above) on
  `["timeout","-s","KILL","30","git","log"]` walks: `timeout` is
  `TRANSPARENT` with `skip_extra` set, `-s` is skipped as a flag, `KILL`
  consumes the one `TRANSPARENT_TAKES_ARG` slot, `30` breaks the skip loop
  — leaving `30` as the resolved head. Whether that means the probe never
  enters the `head == "git"` branch it was chosen to exercise, and what
  follows for the record's generalization claim, is a phase-2 question.
  Evidence needed: pinned read of `451439e:core/hooks/board-gate.sh`'s
  `_segment_is_failing`, plus the record's own probe text. **No verdict is
  taken here.**
- **U2 — the proposal's `upstream[].sha`.**
  `71f1104:docs/issue-114/proposals/2026-08-04-fix-board-gate-wrapper-git-subcommand-extraction.md:8`
  reads `sha: <set at commit>` and is unchanged at `451439e`. The derived
  ledger reports the identical field state was charged as Finding 4 of
  `docs/issue-98/reports/execution-observation.md`. Whether this instance
  is chargeable, and whether its cause is the same self-reference problem
  that record described, is a phase-2 question; the prior record must be
  read at a pinned SHA first.
- **U3 — is the wrapper parser-differential class exhausted by #114?**
  Evidence needed: pinned reads of each candidate habitat listed above,
  plus a direction call (fail-closed vs fail-open) for each. The user's
  step-2 framing asks for a whole-population view; phase 2 states either a
  population answer with per-site citations, or an explicit
  "could not be established, because X".
- **U4 — record self-consistency on scope closure.**
  `docs/issue-114/reports/implementation.md:183-185` records
  `## Open findings` as "None" and `:187-196` records `## Next steps` as
  "None from this delivery's own scope". Whether those two statements hold
  against the delivery's own artifacts is a phase-2 question. The derived
  ledger reports `docs/issue-107/reports/execution-observation.md` Finding 2
  charged a `## Next steps` / same-commit-handbook inconsistency in the
  immediately preceding cycle; here the handbook entry is in `e51b301` and
  the record addresses it under `## Rationale for deviations` (`:59-76`).
  Whether that class recurs or was closed is to be adjudicated, not
  assumed.
- **U5 — issue-100 citation canon compliance.**
  `docs/issue-114/reports/implementation.md:5` uses a file list for
  `code_under_review:` and `:144,:152,:158,:165,:174` use `ref: <file>:<line>`
  for `closed_checks[]`. Whether that fully matches the canon requires
  reading `docs/issue-100/decisions/2026-08-03-record-citation-format-and-kind-convention.md`
  at a pinned SHA — not yet read this session.

## Write surface of this session

This role writes exactly three paths, all new:

- `docs/issue-114/reports/execution-observation/survey.md` (this file)
- `docs/issue-114/reports/execution-observation/scout-brief.md`
- `docs/issue-114/proposals/2026-08-04-independent-observation-of-pr-115.md`

and, only after a contract v3 §19 approval, `docs/issue-114/reports/execution-observation.md`.
Nothing under `core/`, nothing under `docs/issue-114/reports/implementation*`,
nothing under any other issue's tree.
