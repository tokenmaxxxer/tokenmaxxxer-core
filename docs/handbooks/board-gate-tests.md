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

Also covers two read-classification false positives (issue-88):
quoted-`|` segment-split blindness — `SEGMENT` used to split on any bare
`|`/`;` with no quote-awareness, so a quoted BRE OR pattern like
`grep -n "A\|B" docs/x.md` cut into fake segments whose second fragment's
head was an arbitrary word, denied as a write (`bash-quoted-pipe-grep`,
`bash-quoted-pipe-classtest`, `bash-single-quoted-pipe`, plus the
negative-space `bash-quoted-pipe-then-redirect` proving a real unquoted
`|` later in the line still denies); and `cd` absent from
`READ_ONLY_HEADS` — a `cd`-prefixed read (`cd docs/issue-3 && cat x.md`)
was denied outright even though the identical read without the `cd`
prefix was allowed (`bash-cd-then-cat`, plus the negative-space
`bash-cd-then-write-foreign` proving a `cd`-prefixed write into a
foreign tree still denies).

`bash-escaped-quote-then-write` pins a bypass a warrant-hunt found in the
quoted-span regex itself: a backslash-escaped quote CHARACTER outside any
real shell quote (e.g. `ls \" ; rm -rf docs/issue-1/x #"`) must not open a
quoted-span match — otherwise it runs to an unrelated later quote (here,
one inside a `#` comment) and swallows the real `;` between two real
commands as if it were quoted content, hiding a write in the second real
command from the per-segment head check entirely (`_reads_only()` then
returns `True` and `allow()` skips R1-R5). Fixed with a `(?<!\\)`
negative lookbehind on both quote alternatives in `SEGMENT`.
