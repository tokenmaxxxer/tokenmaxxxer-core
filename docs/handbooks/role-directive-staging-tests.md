# role-directive new-file-staging test

`core/hooks/tests/run-role-directive-staging-tests.sh` renders
`core/hooks/directive.sh`'s interaction-protocol heredoc
(`CLAUDE_ROLE=implementation bash core/hooks/directive.sh`) and asserts
the rendered text names staging of new/untracked files (`git add`)
before `git commit -m`, not `git commit -m`/`-am` alone (issue-203):
`git commit -a`/`-am` only stages modifications to already-tracked
paths, so a role that creates a new file and commits without an
explicit scoped `git add` produces an empty/incomplete commit and a
`gh pr create` "No commits between main and branch" failure.

Run it directly, no setup required:

    bash core/hooks/tests/run-role-directive-staging-tests.sh

Also asserts the empty-state case (a directive mentioning only
`git commit -m`/`-am` fails the check) and that the rendered text rules
out a blanket `git add -A`/`.` in favor of scoped staging, per the
issue's own fix direction.
