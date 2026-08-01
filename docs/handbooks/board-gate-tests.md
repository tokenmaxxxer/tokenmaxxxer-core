# board-gate test harness

`core/hooks/tests/run-board-gate-tests.sh` exercises `core/hooks/board-gate.sh`
as a real subprocess against synthetic git repos and JSON tool-call
payloads (`run`/`runb` helpers; `want allow|deny` maps to exit 0/2).

Run it directly, no setup required:

    bash core/hooks/tests/run-board-gate-tests.sh

Covers R1 (docs/ layout), R2 (canonical contract), R3 (role required),
R4 (branch matches issue/role), and R5 (reports/ ownership, including
the role's own bare record directory for Bash `mkdir`/`rm`, and the
foreign-role denial).

Also covers `git` subcommand awareness (issue-60): `git` is judged by
its subcommand, not trusted whole-command. Read subcommands
(`log`/`show`/`diff`/`status`/`blame`/`ls-files`/`ls-tree`/`ls-remote`/
`cat-file`/`rev-parse`/`symbolic-ref`/`describe`/`shortlog`/`reflog`)
still short-circuit to allow (s4 READ-broad, unaffected); every other
subcommand (`rm`, `checkout --`, `restore`, `clean`, `apply`, `mv`,
`stash`, ...) is judged by the normal R1-R5 write scan like any other
write — denied on a foreign tree, allowed on the role's own once it
clears R5, same as `rm -rf` already was.
