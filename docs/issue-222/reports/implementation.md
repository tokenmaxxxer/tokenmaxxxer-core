---
code_under_review:
  - core/hooks/board-gate.sh
  - core/hooks/tests/run-board-gate-tests.sh
  - docs/handbooks/board-gate-tests.md
type: fix
breaking: false
verdict: pass
loop_state: landed
---

## What was done
Implemented the approved phase-1 proposal
(`docs/issue-222/proposals/2026-08-16-r4-maintenance-targets-exception.md`)
exactly: `board-gate.sh`'s R4 block now grants a narrow,
operator-controlled exception. When a role's own issue (`issue-<n>/<role>`
matching `CLAUDE_ROLE`) has an issue-body line
`maintenance-targets: <tree list>`, its branch may also write those
listed other `docs/issue-<m>/` trees. Declaration is read live via
`gh issue view <own-issue> --json body` (CORE_GH test seam, mirroring
`approval-gate.sh`'s issue-state call), lazily and only on a same-issue
mismatch — the ordinary own-issue write path never shells out. Any `gh`
failure/unparseable body yields an empty target set (fail closed,
identical to no declaration). No declaration => today's R4 behavior,
byte-identical.

Added `docs/handbooks/board-gate-tests.md` subsection documenting the
exception's shape and guarantees.

## Why
`board-gate.sh` R4 refused any cross-issue `docs/issue-<n>/` write,
including record-maintenance fixes that legitimately live in a different,
already-closed issue's tree — blocking the patrol remediation lane
(on-the-record#1614/#1620/#1624). Fix per issue #222 / approved proposal.

## Upstream
docs/issue-222/proposals/2026-08-16-r4-maintenance-targets-exception.md

## Doc placement
- [x] `docs/handbooks/board-gate-tests.md` — R4 maintenance-targets
  exception subsection added (handbook, same turn, per doctrine ladder).
- No new env var, dependency, or migration introduced (CORE_GH is an
  existing test seam, reused, not added).

## What did not work
None.

## Test evidence
derived: bash core/hooks/tests/run-board-gate-tests.sh
```
== 110 passed, 0 failed ==
```
New cases: `maint-refused-no-decl` (deny), `maint-permitted-decl` (allow),
`maint-unlisted-refused` (deny), `maint-own-issue-never-calls-gh` (allow).

derived: bash core/hooks/tests/run-all.sh
```
ALL OK
```

## Open findings
None.
