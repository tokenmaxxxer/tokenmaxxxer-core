---
subject: issue-60
role: implementation
code_under_review: core/hooks/board-gate.sh, core/hooks/tests/run-board-gate-tests.sh, docs/handbooks/board-gate-tests.md
loop_state: landed
---

# Record — git subcommand-aware board-gate read classification (phase 2)

## What was done

Implemented the approved proposal
(`docs/issue-60/proposals/2026-07-31-build-git-subcommand-aware-board-gate.md`)
checklist exactly, against the live code (line numbers had drifted by ~1
since the proposal was written, per the survey's re-verification
addendum — `READ_ONLY_HEADS` at board-gate.sh:96-99, `_reads_only()` at
:141-156 — content unchanged):

- `core/hooks/board-gate.sh` `READ_ONLY_HEADS`: dropped `"git"` from the
  tuple. The other twenty-six entries are unchanged.
- Added `GIT_READ_SUBCOMMANDS` (`log`, `show`, `diff`, `status`, `blame`,
  `ls-files`, `ls-tree`, `ls-remote`, `cat-file`, `rev-parse`,
  `symbolic-ref`, `describe`, `shortlog`, `reflog`) next to `TRANSPARENT`,
  with a comment on why `git` needed to split off `READ_ONLY_HEADS`.
- Added `_git_subcommand(segment)`: returns the first non-flag token after
  `git`, or `""` when unresolved (bare `git`, or global flags like `-C
  <dir>` this function does not special-case). `""` is not in
  `GIT_READ_SUBCOMMANDS`, so an unresolved subcommand falls through to the
  normal write scan — the safe direction, not a new hole.
- `_reads_only()`'s segment loop: inserted a `head == "git"` branch before
  the existing `READ_ONLY_HEADS` membership check — `continue` when
  `_git_subcommand(seg) in GIT_READ_SUBCOMMANDS`, `return False`
  (judged like any other write-shaped segment) otherwise.
- `core/hooks/tests/run-board-gate-tests.sh`: added six cases after the
  s4 READ-broad block (after the `bash-subshell-write` line), matching the
  proposal's checklist exactly — three foreign-issue-tree denies (`git
  rm`, `git checkout --`, `git restore`), one R5 integration deny
  (`git rm` on a foreign role's own record file, same issue/branch — the
  write scan the bypass used to skip must reach R5, not stop at R4), one
  R5 integration allow (`git rm` on the role's own bare record subtree —
  self-ownership stays legal, matching the issue #12 `rm -rf` precedent
  and the user's explicit "자기 트리에 대한 git rm 은 허용돼야 한다"
  instruction), and one explicit `git show` allow regression case
  (`log`/`diff` were already covered by existing s4 tests; `show` was
  not).

## Why

The issue's own trace (re-confirmed in the survey by direct execution)
showed `READ_ONLY_HEADS` trusting the whole `git` command, so
`_reads_only()` returned `True` for `git rm`/`checkout --`/`restore`/
`clean`/`apply`/`mv`/`stash` on any target — including a foreign issue
tree — before the R1-R5 candidate scan ever ran. The fix makes the git
branch of `_reads_only()` subcommand-aware: only the named read
subcommands short-circuit to `allow()`; everything else (including any
future/unrecognized subcommand) is judged by the normal write scan,
consistent with the file's existing "over-blocking is the safe direction"
rule. Full rationale, including the two rejected alternatives
(deny-listing write subcommands instead; treating `git` as always
write-shaped), is in the phase-1 proposal.

## Upstream basis

`docs/issue-60/proposals/2026-07-31-build-git-subcommand-aware-board-gate.md`,
approved via issue-level comment `APPROVE issue-60/implementation` from
`jjongkwann` (`docs/specs/approvers.md`-listed, single-account path,
2026-07-31T07:00:47Z) and re-verified as still matching the live code by
PR #79 (`docs/issue-60/reports/implementation/survey.md` section 5,
2026-08-01) before this phase-2 session began.

## Doc-placement ladder

- [x] `core/hooks/board-gate.sh` — edited in place, existing gate script.
- [x] `core/hooks/tests/run-board-gate-tests.sh` — edited in place,
  existing test harness for that gate.
- [x] `docs/issue-60/reports/implementation.md` — this record, the role's
  own phase-2 deliverable home.
- [x] `docs/handbooks/board-gate-tests.md` — updated to document the new
  git-subcommand-awareness coverage; triggered by
  `handbook-trigger-gate.sh` on the `run-board-gate-tests.sh` edit
  (contract §21, operational surface: test/setup script).
- No new env var, config key, or dependency was introduced, and no
  migration applies.
- No public signature or wire format changed (this is an internal
  PreToolUse hook's classification logic, not an exposed interface) — no
  `docs/issue-60/decisions/` entry needed.
- No benchmark or investigation numbers produced beyond the test-run
  evidence already captured below.

## Verification run (evidence)

`bash core/hooks/tests/run-board-gate-tests.sh` — 58 passed, 0 failed,
including the six new cases:

```
ok     bash-git-rm-foreign-issue          deny
ok     bash-git-checkout-foreign-issue    deny
ok     bash-git-restore-foreign-issue     deny
ok     bash-git-rm-foreign-record         deny
ok     bash-git-rm-own-subtree            allow
ok     bash-git-show-foreign-issue        allow

== 58 passed, 0 failed ==
```

`bash core/hooks/tests/run-all.sh` (full hook suite, all gates + sibling
plugins terse/freelunch/scout) — `ALL OK`, including `run-board-gate-tests.sh`
(58/0), `run-approval-gate-tests.sh` (36/0, unaffected — its identical
defect is explicitly out of scope, see proposal), `run-gate-lib-tests.sh`,
`run-gh-guard-tests.sh` (19/0), `run-role-gates-tests.sh` (17/0),
`compliance-check.sh`, `deny-only-check.sh`, `parse-check.sh` — no
regression anywhere in the suite.

## Acceptance criteria check (issue body)

1. `git rm` / `git checkout -- <path>` / `git restore` targeting a
   **foreign** issue tree deny — confirmed
   (`bash-git-rm-foreign-issue`, `bash-git-checkout-foreign-issue`,
   `bash-git-restore-foreign-issue`).
2. `git log` / `git diff` / `git show` keep allowing (s4 READ-broad, PR
   #59) — confirmed, no regression in the pre-existing `bash-gitlog-*`
   cases, plus the new explicit `bash-git-show-foreign-issue` case.
3. Bidirectional tests attached to
   `core/hooks/tests/run-board-gate-tests.sh` — confirmed, 6 new cases
   (3 deny + 1 R5-integration deny + 2 allow).
4. User's additional instruction — `git rm` on a role's **own** tree must
   stay allowed, because the goal is routing through R1-R5 ownership
   checks, not a blanket `git rm` ban — confirmed
   (`bash-git-rm-own-subtree`: `git rm -r $BOARD/reports/qa` on branch
   `issue-3/qa` as role `qa` allows).

## Hunt cadence

The role directive calls for dispatching `warrant-hunter` at end of
phase 1 and before phase-2 completion. This session's Agent tool
available-agent-types list (from the session's own system reminder) does
not include `warrant-hunter` — only `claude`, `Explore`,
`freelunch:freelunch-worker`, `general-purpose`, `Plan`,
`statusline-setup` are registered, and no `warrant` plugin SessionStart
hook fired for this session (unlike scout/freelunch/terse/no-mock/
record-shape/proposal-shape/survey-order, which did). The `warrant/`
plugin exists as source in this same repository
(`warrant/agents/warrant-hunter.md`) but is not active in this session's
harness configuration, so it could not be dispatched here. In its place,
this record's own direct verification (full `run-board-gate-tests.sh`
and `run-all.sh` execution above, plus the acceptance-criteria mapping)
is what closes the checks for this delivery; no hunt-produced
`closed_checks:` entry exists to cite. Flagging the unavailability here
rather than silently skipping it.

## What did not work

None. The proposal's checklist matched the live code exactly (confirmed
by the survey's re-verification addendum before this session started),
and the implementation passed the full test suite on the first run with
no corrective iteration needed.

## Next steps

None — this record is terminal (`loop_state: landed`). Out-of-scope items
already named in the proposal (`approval-gate.sh`'s identical defect; the
`--output=<file>` residual risk on git's read subcommands) are candidates
for separate follow-up issues, not further work here.

## Open findings

None outstanding.
