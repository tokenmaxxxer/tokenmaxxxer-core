# Survey: coding (issue-21)

Grepped the repo case-insensitively for `muster` to find stale mentions left over from the
on-the-record rename. Outside of historical citations (e.g. `core/contract/role-handoff-contract.md:665`,
and prior issue-14/issue-18/issue-12 report/proposal docs, which record what actually happened at
the time and must not be rewritten), five live prose sites still say "muster" where the current
terminology is "on-the-record": `README.md:137`, `freelunch/README.md:96`, `scout/README.md:77`,
`core/hooks/directive.sh:6` (comment), and `core/hooks/board-gate.sh:20` (comment). Write set for
this task is exactly those five files, each a single-word literal substitution
(`muster` -> `on-the-record`); no other file or line is touched.
