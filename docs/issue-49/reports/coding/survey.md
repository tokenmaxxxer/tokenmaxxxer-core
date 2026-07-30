# Current-state survey — issue #49

## Scope of change

`README.md:26` — "A role wakes on an issue, works on branch
`issue-<n>/<role>` ..." — is the last "wakes" occurrence in the repo
outside historical git log / commit messages.

```
$ grep -rni "wake" --include=*.md . | grep -v docs/issue-46 | grep -v .git
README.md:26:- A role wakes on an issue, works on branch `issue-<n>/<role>` (one branch
```

Issue #46's hunt flagged this line; the issue #46 proposal explicitly
scoped it out (README treated separately). `core/contract/role-handoff-contract.md`
already had its wake/WAKES-ON vocabulary stripped in #46 (commit
0800649), replacing "wakes" with orchestrator-judgment prose ("enters",
"is opened", "prompts the human").

## Write set

- `README.md` — one line (26), reword to drop "wakes on".

No other file references "wake" prose. No schema/interface/env var/dependency
change involved.

## Scout skip record

Pure text-vocabulary fix matching an already-established replacement
pattern (issue #46) — no design decision open. Scouting skipped per the
scout directive's bugfix skip condition.
