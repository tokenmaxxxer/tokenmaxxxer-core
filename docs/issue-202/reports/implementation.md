---
code_under_review:
  - warrant/hooks/directive.sh
  - warrant/agents/warrant-hunter.md
  - warrant/hooks/tests/run-directive-hunt-path-tests.sh
type: fix
breaking: false
verdict: pass
loop_state: landed
---

# Implementation record — issue-202

## What was done

Edited `warrant/hooks/directive.sh`'s hunt-dispatch instructional text and
`warrant/agents/warrant-hunter.md`'s Output section so that, before naming a
hunt-record path, the dispatching model (or a standalone hunter with no
dispatcher-supplied path) checks whether the session is issue-scoped and
role-scoped — `CLAUDE_ROLE` set AND the session's own current branch resolves
as exactly `issue-<n>/<CLAUDE_ROLE>` (the same check board-gate's R4
performs). When that holds, the hunt record is named
`docs/issue-<n>/reports/<role>/<date>-hunt-<slug>.md`, landing inside the
role's own subtree so board-gate's R5 admits it on the first write attempt.
Otherwise the existing rule stands unchanged: `docs/issue-<n>/reports/hunt-<slug>.md`
when the proposal path carries an issue segment, or
`docs/reports/<date>-hunt-<slug>.md` when it does not. Added
`warrant/hooks/tests/run-directive-hunt-path-tests.sh`, which renders
`directive.sh`'s static stdout and asserts the role-subtree template is
present and gated behind the role-scope condition, and that both prior
fallback templates remain present and unchanged.

## Why

Every role session that reached its post-PR hunt dispatch was stranding
(`progressed-dirty-tree`) because `directive.sh` named a hunt-record path
board-gate's R5 rejects as belonging to another role. The rule is derived
from the same signals R4 already keys on (`CLAUDE_ROLE`, current branch),
not a re-encoded copy of board-gate's glob, per the proposal's constraint.

## Upstream

docs/issue-202/proposals/hunt-record-role-scope-path.md

## What did not work

None.

## Doc placement

- No new env var, config key, dependency, migration, or setup step —
  nothing to add to a handbook.
- No library/format choice or changed public signature/wire format —
  nothing to add to docs/issue-202/decisions/.
- No benchmark/investigation numbers produced.

## Open findings

None.

## Test run

derived: `bash warrant/hooks/tests/run-directive-hunt-path-tests.sh`
```
ok     role-scoped-hunt-path-present            1
ok     role-scope-condition-matches-R4-check    1
ok     standalone-fallback-path-present         1
ok     issue-segment-fallback-path-present      1
ok     old-templates-conditioned-not-unconditional 1

pass=5 fail=0
```

derived: `bash warrant/hooks/tests/run-hunt-guard-tests.sh`
```
9 passed, 0 failed
```

## Hunt

Prior hunt record (after-proposal, phase 1):
docs/issue-202/reports/implementation/hunt-hunt-record-role-scope-path.md.
Before-landing dispatch: this transition is docs-adjacent code but not
docs-only (touches warrant/hooks/directive.sh, warrant/agents/warrant-hunter.md,
warrant/hooks/tests/run-directive-hunt-path-tests.sh — none under docs/), so
the docs-only fast path does not apply; a before-landing warrant-hunter
dispatch was run and its section is appended to the same hunt record file
above.
