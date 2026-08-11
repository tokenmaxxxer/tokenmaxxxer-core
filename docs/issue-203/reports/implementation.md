---
code_under_review:
  - core/hooks/directive.sh
  - core/hooks/tests/run-role-directive-staging-tests.sh
type: fix
breaking: false
verdict: pass
loop_state: landed
---

## What was done

Extended the existing "A commit that stages any docs/issue-<n>/** work
must use git commit -m ..." bullet in `core/hooks/directive.sh`'s
core interaction-protocol heredoc (~line 116) with an explicit
instruction to stage the full intended change set INCLUDING new/untracked
files before committing — `git commit -a`/`-am` only stages
modifications to already-tracked paths, never untracked ones, so a
newly created file needs an explicit scoped `git add` of its path (or
the write set's directories) before commit. Added
`core/hooks/tests/run-role-directive-staging-tests.sh`, following the
`report()`/pass-fail idiom of `core/hooks/tests/run-role-gates-tests.sh`,
asserting the rendered directive text (via `CLAUDE_ROLE=... bash
core/hooks/directive.sh`) mentions new-file staging (`git add`)
alongside the unchanged `git commit -m` requirement, and fails if only
`git commit -m`/`-am` is present with no staging step.

## Rationale for deviations

The approved proposal's `files:` list named
`core/hooks/lib/role-directive.sh` as the edit target. That file only
defines `core_role_directive`, a helper sourced by per-plugin rulebook
`directive.sh` wrappers — it does not contain the bullet text in
question. The "A commit that stages any docs/issue-<n>/** work must
use git commit -m" bullet the issue and proposal quote verbatim lives
directly in `core/hooks/directive.sh`'s own heredoc (confirmed via
`grep -n "commit -m" core/hooks/directive.sh core/hooks/lib/role-directive.sh`
— only `core/hooks/directive.sh:116` matches). Edited the actual file
containing the bullet instead of the proposal's named path; the test
file path is unchanged from the proposal.

## What did not work

None.

## Why

Issue #203: `git commit -am`/`git commit -m` without a prior `git add`
silently drops newly-created untracked files from a commit, producing
an empty/incomplete commit and a `gh pr create` "No commits between
main and branch" failure — reproduced in the issue's field instance
(issue-341, consumer repo). Fix scope, per the approved proposal, is
directive text only (advisory), not a new mechanical gate.

## Upstream

Based on: docs/issue-203/proposals/2026-08-11-stage-new-files-in-commit-directive.md

## Tests

derived: bash core/hooks/tests/run-role-directive-staging-tests.sh
```
ok     renders the git commit -m requirement                        present
ok     renders a new-file staging (git add) instruction             present
ok     empty-state fixture (git commit -m/-am only) has no staging step absent
ok     explicitly rules out a blanket git add -A/.                  present

role-directive-staging: 4 passed, 0 failed
```

derived: bash core/hooks/tests/run-all.sh
```
ALL OK
```
(includes run-role-directive-staging-tests.sh, run-role-gates-tests.sh
81/81, and parse-check.sh over all hook scripts — 0 failures)

## Doc placement

- Advisory-only limitation already recorded in the phase-1 proposal's
  "Known limitation" paragraph
  (docs/issue-203/proposals/2026-08-11-stage-new-files-in-commit-directive.md)
  — no new decisions/ or handbooks/ entry needed; no env var, dependency,
  or migration introduced.

## Open findings

None.

## Next steps

Run the new and existing test suites to 0 failures, then flip
loop_state to landed and commit/push/open the PR.

## Resolution path

N/A — no open findings to resolve.

## closed_checks

- run-role-directive-staging-tests.sh: new-file staging text present in
  rendered directive — code_under_review: core/hooks/directive.sh
