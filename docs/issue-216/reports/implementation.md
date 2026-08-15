---
code_under_review:
  - warrant/hooks/scope-gate.sh
  - core/hooks/tests/run-scope-gate-tests.sh
type: fix
breaking: false
verdict: pass
loop_state: landed
---

## Summary of work

warrant/hooks/scope-gate.sh's malformed-frontmatter branch (`len(approved)
!= 1` with a non-empty `malformed` list) degrades to warn-and-allow for
read-only tool calls instead of hard-blocking every tool call. A read tool
(`Read`, `Grep`, `Glob`, `NotebookRead`) or a `Bash` command that passes the
existing `readonly_allowed()` allowlist now gets the same stderr warning as
before, but exits 0 instead of 1 (which the fail-closed trap remaps to 2).
Write/Edit/NotebookEdit and any non-allowlisted Bash command still hit the
hard block, unchanged. `SHELL_CHAIN`, `SAFE_ARG`, `READONLY_ALLOW`, and
`readonly_allowed()` were moved earlier in the script (they were previously
defined after the malformed-frontmatter branch that now needs them) and a
`call_is_readonly()` helper was added to classify the current tool call.

## Why

The gate's malformed branch exits 1 unconditionally, which the script's
fail-closed EXIT trap remaps to exit 2 — blocking every tool call in the
session, including pure reads, whenever any `docs/proposals/*.md` in the
target repo has no closing `---` or an unrecognized `status`. That includes
Read/Grep and read-only Bash entirely unrelated to the broken file, and it
blocks the only path to even inspecting the file the gate is complaining
about. A gate that cannot enforce a write-set (no single approved unit) has
nothing to protect from a read, so only observation is exempted; the
fail-closed posture for writes is unchanged.

## Upstream basis

Issue #216, observed as on-the-record#1581.

## What did not work

None.

## Open findings

None.

## Doc-placement ladder

- No env var, config key, dependency, or migration introduced — handbook
  update not applicable.
- No library/format choice over a named alternative and no public
  signature/wire-format change beyond the gate's own internal control flow
  — no docs/issue-216/decisions/ entry.
- No benchmark/investigation numbers produced — no docs/issue-216/reports/
  entry beyond this record itself.

## Rationale for deviations

None — this is a pure bugfix (issue text: "defect fix in gate machinery;
no R-id applies") and the implementation matches the issue's stated fix
shape and acceptance criteria exactly; phase-1 proposal round was skipped
per the pure-bugfix skip condition.

## Test evidence

derived: `bash core/hooks/tests/run-scope-gate-tests.sh`
```
ok     hook-write-sanctioned-content      allow
ok     hook-edit-sanctioned-content       allow
ok     hook-multiedit-sanctioned          allow
ok     hook-write-piped-shell             deny
ok     hook-write-rm-rf                   deny
ok     hook-write-sudo                    deny
ok     hook-write-disables-trap           deny
ok     hook-write-standard-early-exit     allow
ok     hook-edit-piped-shell              deny
ok     nonhook-outside-writeset           deny
ok     hook-inside-writeset               allow
ok     withdrawn-proposal-stands-down     allow
ok     rejected-proposal-stands-down      allow
ok     malformed-readonly-bash-allowed    allow
ok     malformed-read-tool-allowed        allow
ok     malformed-grep-tool-allowed        allow
ok     malformed-write-still-blocked      deny
ok     malformed-nonreadonly-bash-still-blocked deny

== 18 passed, 0 failed ==
```

derived: `bash core/hooks/tests/run-gate-lib-tests.sh`
```
gate-lib: 66 passed, 0 failed
```

derived: `bash core/hooks/tests/run-role-gates-tests.sh`
```
role-gates: 81 passed, 0 failed
```
