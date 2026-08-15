---
code_under_review:
  - warrant/hooks/scope-gate.sh
  - core/hooks/tests/run-scope-gate-tests.sh
  - docs/handbooks/board-gate-tests.md
type: fix
breaking: false
verdict: pass
loop_state: landed
---

## Summary of work

Fixed `readonly_allowed()` in `warrant/hooks/scope-gate.sh`:

- `SHELL_CHAIN` no longer rejects a bare `|`; it now rejects `;`, `&`,
  backtick, `$(`, `||`, `<`, `>`, and embedded newlines.
- `readonly_allowed()` splits the command on `|` and vouches only when
  every segment independently matches `READONLY_ALLOW`.
- `SAFE_ARG`'s char class excludes `<`/`>` in addition to its previous
  exclusions.
- Added a `find`-specific guard (`FIND_EXEC_FLAGS`) refusing the vouch
  when a `find` segment carries `-exec`/`-execdir`/`-ok`/`-okdir`/
  `-delete`/`-fprint`/`-fprintf`/`-fls`.

Added regression cases to `core/hooks/tests/run-scope-gate-tests.sh`
covering the issue's acceptance list: piped read-only allow/deny pairs,
redirection-write deny, newline-smuggling deny, `find -exec` deny (all in
the malformed-frontmatter branch), and a piped-all-read-only allow case
in the approved-unit branch.

## Why

core#218: the prior `SHELL_CHAIN` blanket-rejected any `|`, so common
read-only inspection pipelines (`grep ... | head`) fail-closed instead of
being vouched, while `SAFE_ARG` admitted `<`/`>` as ordinary argument
characters, letting a redirection write (`cat a > b`) match the read-only
allowlist. `find`'s exec-capable flags were also unguarded despite `find`
being in the plain-command allowlist.

## Upstream / basis

Based on: #218 (fix direction and acceptance list given in the issue
body). `docs/reports/consult-log.md` cited by the issue does not exist in
this repo (checked project-wide) — see
`docs/issue-218/reports/implementation/survey.md` for that note; the
issue's own acceptance list was treated as authoritative in its absence.

## Test run

derived: `bash core/hooks/tests/run-scope-gate-tests.sh`
```
== 26 passed, 0 failed ==
```

derived: `bash core/hooks/tests/run-all.sh`
```
ALL OK
```
(all sub-suites reported 0 failed; full output reviewed, no SKIPPED lines.)

## What did not work

None — the fix direction in the issue mapped directly onto
`readonly_allowed()`'s existing structure with no dead ends.

## PR #219 review follow-up

Blocking finding: `FIND_EXEC_FLAGS`'s `fprint\b` matched `-fprint` but
not `-fprint0` — `0` is a word char, so no boundary exists between `t`
and `0`, and `find . -fprint0 out` (a file write) still received the
read-only vouch. Fixed by widening the alternative from `fprint` to
`fprint0?` in `warrant/hooks/scope-gate.sh`. Added
`malformed-find-fprint0-denied` to `run-scope-gate-tests.sh` (`deny`).
Both test suites re-run above, all green.

## Open findings

None.

## Doc placement

- Decision/rationale content lives in this record's Why/Upstream
  sections and `docs/issue-218/proposals/2026-08-16-scope-gate-readonly-pipe-fix.md`
  (a regex-shaped bugfix; no new env var, dependency, migration, or
  setup step was introduced).
- The PR #219 review follow-up touched `run-scope-gate-tests.sh`, an
  operational-surface test script, so its `docs/handbooks/board-gate-tests.md`
  entry (the `issue-218 follow-up (PR #219 review)` paragraph) lands in
  the same commit per contract §21.
