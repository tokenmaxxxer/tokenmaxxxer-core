---
status: proposed
files:
  - core/hooks/lib/role-directive.sh
  - core/hooks/tests/run-role-directive-staging-tests.sh
---

## Request

`core/hooks/lib/role-directive.sh`'s `core_role_directive` heredoc tells
every role session "a commit that stages any docs/issue-<n>/** work must
use `git commit -m`" but never says to *stage* new files first. `git
commit -am`/`git commit -m` after no `git add` only picks up
modifications to already-tracked paths — a brand-new (untracked) file a
role creates is silently left out, producing an empty or incomplete
commit and a `gh pr create` "No commits between main and branch"
failure. Field instance: issue-341 (consumer repo, 2026-08-11) wrote a
25KB new test file, committed with `-m`, PR came up empty, session ended
`uncommitted-work` twice.

## Constraints

- Text-only change inside the existing heredoc in
  `core/hooks/lib/role-directive.sh`; no new gate script, no new wiring
  beyond a unit test for the text itself.
- Keep the existing `git commit -m` (not `-F`/editor) requirement intact
  — `trailer-gate.sh` depends on that commit form to check the trailer.
- Role-agnostic: applies regardless of `$CLAUDE_ROLE`, same as the rest
  of the heredoc.
- Staging instruction must be scoped ("stage the write set", not "stage
  everything") — no blanket `git add -A`/`git add .` advice, per the
  issue's own fix direction.
- `core/hooks/tests/parse-check.sh`'s bash-3.2 parse check must keep
  passing.

## Rationale

Considered adding a new mechanical pre-commit gate (parallel to
`trailer-gate.sh`) that diffs `git status --porcelain` against a role's
declared write set and refuses the commit if an untracked in-scope file
isn't staged. Rejected for this issue: the issue's Acceptance check is
scoped to the *directive text* ("unit test renders the core commit
directive and asserts it instructs staging of new files"), not a new
gate; and a mechanical staging gate would need the role's write set in
machine-readable form, which doesn't exist today — that's separate,
larger scope worth its own follow-up issue, not a silent scope-creep
here. Editing the heredoc in place matches the issue-195 precedent
(`docs/issue-195/proposals/2026-08-10-record-format-contract-in-role-directive.md`),
which fixed a sibling defect in the same function the same way: append
instructional text after the relevant bullet, no new plumbing.

## What will be done

Extend the existing bullet in `core_role_directive`'s heredoc (the "A
commit that stages any docs/issue-<n>/** work must use git commit -m..."
line) with an explicit staging step, e.g.:

```
- A commit that stages any docs/issue-<n>/** work must use git commit -m
  and carry a Subject: issue-<n> trailer naming that issue (contract v3
  s13), one commit per subject — the same requirement trailer-gate.sh
  already enforces mechanically at commit time. Before committing, stage
  the full intended change set INCLUDING new files: git commit -a/-am
  only stages modifications to already-tracked paths, never untracked
  ones, so a newly created file needs an explicit git add of its path
  (or of the write set's directories) before commit — omitting this
  step leaves the new file out of the commit and produces "No commits
  between main and branch" at PR-create time.
```

Add `core/hooks/tests/run-role-directive-staging-tests.sh`, following
the `report()`/pass/fail idiom used by
`core/hooks/tests/run-role-gates-tests.sh`: source or invoke
`core_role_directive` (via `core/hooks/directive.sh` with `CLAUDE_ROLE`
set, matching how other role directive.sh scripts already call it) and
assert the rendered output mentions staging of new/untracked files (a
`git add` instruction) in addition to `git commit -m`, failing if the
output mentions only `git commit -m`/`-am` with no new-file staging
step — matching the issue's Acceptance check verbatim.

## Out of scope

- A new mechanical staging gate that inspects the diff between the
  role's write set and git status (flagged above as a plausible
  follow-up issue, not built here).
- Any change to `trailer-gate.sh` or other existing gates.
- Any change to the per-role `hooks/directive.sh` wrapper files — they
  already source the shared function and need no edits.

## How you'll know it worked

- `core/hooks/tests/run-role-directive-staging-tests.sh` passes: the
  rendered directive text names staging of new/untracked files before
  `git commit -m`.
- `core/hooks/tests/parse-check.sh` still passes (no bash-4-only syntax
  introduced).
- Manual read of the rendered heredoc (e.g. `CLAUDE_ROLE=implementation
  bash core/hooks/directive.sh` from a role's plugin dir) shows the new
  staging line alongside the unchanged `git commit -m` requirement.
