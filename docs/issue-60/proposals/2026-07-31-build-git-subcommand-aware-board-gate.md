---
kind: build-proposal
subject: issue-60
produced_by: implementation
loop_state: proposed
upstream:
  - path: docs/issue-60/reports/implementation/survey.md
    sha: <set at commit>
---

## Request

`core/hooks/board-gate.sh`'s `READ_ONLY_HEADS` (line 95-98) lists `"git"`
whole-command, so `_reads_only()` trusts every `git` invocation — subcommand
unexamined — as incapable of writing a file. `git rm -r
docs/issue-49/reports`, `git checkout -- <path>`, `git restore <path>`,
`git clean -fd`, `git apply`, `git mv`, and `git stash` all hit
`READ_ONLY_HEADS`'s `"git"` entry and return through `allow()` (line 168)
before the candidate-extraction/R1-R5 scan ever runs, on ANY issue tree —
including one that is not the calling role's own. Fix: make the git branch
of `_reads_only()` subcommand-aware, so only real read subcommands
short-circuit to `allow()` and every other (or unrecognized) subcommand is
judged by the normal candidate scan, same as any other write.

Survey confirmed the issue body's trace matches the live code exactly
(`docs/issue-60/reports/implementation/survey.md` section 1) and confirmed
`approval-gate.sh` does **not** independently block this — it carries the
identical `READ_ONLY_HEADS`-includes-`"git"` /
`WRITEISH`-doesn't-match-subcommands defect (survey section 2), so the
issue's own "이미 막힌다면 테스트만 추가" reduction does not apply and the
full fix stands.

## Constraints

- Fail-closed direction preserved: an unrecognized git subcommand must be
  judged (fall through to the normal write scan), never trusted by
  default — matches this file's existing "over-blocking is the safe
  direction" rule (comment at board-gate.sh:173).
- No regression on PR #59's s4 READ-broad guarantee: `git log`, `git
  diff`, `git show` (and the pipelines/pathspecs the existing s4 tests at
  run-board-gate-tests.sh:205-214 already exercise) must keep returning
  `allow`.
- Minimal diff: one function's git-handling logic, plus regression tests,
  in `core/hooks/board-gate.sh` only.
- `approval-gate.sh`'s identical defect (survey section 3) and the
  `--output=<file>` residual risk on `log`/`show`/`diff` (survey section
  4) are explicitly out of scope for this proposal — each needs its own
  scoped fix and its own test coverage, not folded into this diff.

## What will be done

files: `core/hooks/board-gate.sh`, `core/hooks/tests/run-board-gate-tests.sh`

- [ ] `core/hooks/board-gate.sh` line 95-98 (`READ_ONLY_HEADS`): drop
  `"git"` from the tuple. The other twenty-six entries (`ls`, `cat`,
  `sort`, `jq`, `test`, `[`, ...) are all single-behavior commands and stay
  unchanged.
- [ ] `core/hooks/board-gate.sh`, near `TRANSPARENT` (after line 124): add
  a `GIT_READ_SUBCOMMANDS` tuple — `("log", "show", "diff", "status",
  "blame", "ls-files", "ls-tree", "ls-remote", "cat-file", "rev-parse",
  "symbolic-ref", "describe", "shortlog", "reflog")` — with a comment
  stating why `git` needed to split off `READ_ONLY_HEADS` (subcommand
  determines read vs. write; the pre-fix state trusted the whole command).
- [ ] Same location: add `_git_subcommand(segment)` — returns the first
  `segment.split()[1:]` token that does not start with `-` (the
  subcommand), or `""` for a bare `git` or one preceded only by
  argument-taking global flags (e.g. `-C <dir>`) this function does not
  special-case; an unresolved subcommand returns `""`, which is not in
  `GIT_READ_SUBCOMMANDS`, so it is judged — the safe direction, not a new
  hole.
- [ ] `_reads_only()`'s segment loop (lines 145-154): before the existing
  `if head in READ_ONLY_HEADS: continue`, insert a `head == "git"` branch —
  `continue` when `_git_subcommand(seg) in GIT_READ_SUBCOMMANDS`, else
  `return False` (judged like any other write-shaped segment).
- [ ] `core/hooks/tests/run-board-gate-tests.sh`: add a new block after the
  existing "s4 READ-broad" section (after line 221), both directions per
  the acceptance criteria:
  - `run deny  bash-git-rm-foreign-issue       Bash '{"command":"git rm -r docs/issue-49/reports"}'`
  - `run deny  bash-git-checkout-foreign-issue Bash '{"command":"git checkout -- docs/issue-49/reports/x.md"}'`
  - `run deny  bash-git-restore-foreign-issue  Bash '{"command":"git restore docs/issue-49/reports/x.md"}'`
  - `run deny  bash-git-rm-foreign-record      Bash '{"command":"git rm -r '$BOARD'/reports/review.md"}'`
    (R5 integration check: same issue/branch, foreign role's record — the
    write scan the bypass skipped must reach R5, not just R4)
  - `run allow bash-git-rm-own-subtree         Bash '{"command":"git rm -r '$BOARD'/reports/qa"}'`
    (R5 integration check: a role's own bare record dir stays allowed via
    `git rm`, matching the existing `rm -rf` case from issue #12)
  - `run allow bash-git-show-foreign-issue     Bash '{"command":"git show HEAD:docs/issue-49/reports/coding.md"}'`
    (explicit `git show` regression case — not currently exercised by any
    existing test; `log`/`diff` already are, at lines 206-207 and 214)
- [ ] Verify: `bash core/hooks/tests/run-board-gate-tests.sh` — all cases
  pass, `0 failed`.

## Out of scope

- `approval-gate.sh`'s identical `READ_ONLY_HEADS`/`WRITEISH` defect
  (survey section 3) — recommend a follow-up issue; its own test harness
  (`run-approval-gate-tests.sh`) needs its own regression coverage,
  separate from this diff.
- The `--output=<file>` flag on `git log`/`show`/`diff` (and `sort -o`,
  same shape on a different `READ_ONLY_HEADS` member) — a pre-existing,
  separate risk class (application-level output flags, not shell
  redirection), not introduced by this fix and not closed by it either
  (survey section 4). Recommend a follow-up issue scoped to output-flag
  detection.
- Any other `board-gate.sh` rule (R1-R5) or git subcommand not named
  above (e.g. `branch`, `tag`, `remote`, `config`, `stash` stay judged,
  not allowlisted — each has a write-capable form (`git branch <name>`,
  `git config --file <path> ...`) that a bare-subcommand allowlist cannot
  tell apart from its read form without deeper argument inspection, which
  this proposal does not attempt).
- `git -C <dir> ...` and other argument-taking global flags before the
  subcommand: `_git_subcommand` does not special-case them, so such
  invocations fall through to the normal (over-blocking-safe) write scan
  rather than being recognized as reads. Not a regression — no existing
  test uses this form — but noted as a known gap for a future proposal if
  it starts mattering in practice.

## How you'll know it worked

`bash core/hooks/tests/run-board-gate-tests.sh` reports `0 failed`,
including: the three new foreign-issue-tree deny cases for `git
rm`/`checkout --`/`restore` (the issue's literal acceptance criteria), the
foreign-record and own-subtree R5 integration cases, the new explicit
`git show` allow case, and every pre-existing case (s4 READ-broad's
`git log`/`git diff` pipelines, R1-R5, the fast path, the kill switch)
unchanged.

## Alternatives considered

- **Deny-list write subcommands (`rm`, `checkout`, `restore`, `clean`,
  `apply`, `mv`, `stash`, ...) instead of allow-listing read subcommands.**
  Not chosen: git adds subcommands over time and a deny-list silently
  trusts anything not yet named — the opposite of this file's own
  "over-blocking is the safe direction" rule, and the same class of bug
  this issue is fixing (a hand-authored list going stale relative to
  git's actual behavior).
- **Treat `git` as always write-shaped (drop it from any special handling,
  let every `git ...` fall through to the normal candidate scan).** Not
  chosen: this would regress PR #59's s4 READ-broad guarantee — `git log
  -- docs/issue-49` and `git diff -- docs/issue-49` on a foreign issue
  tree would start returning `deny`, the exact false-positive class
  issue-55 was filed to fix, five refusals in one live session
  (board-gate.sh:200-204).

## Failure signal

If a future `git` subcommand needs read-only recognition and someone adds
`"git"` back to `READ_ONLY_HEADS` wholesale instead of extending
`GIT_READ_SUBCOMMANDS`, `bash core/hooks/tests/run-board-gate-tests.sh`
regresses `bash-git-rm-foreign-issue` (and siblings) from `deny` back to
`allow` — the concrete, mechanical re-detection of this exact class of
bug.
