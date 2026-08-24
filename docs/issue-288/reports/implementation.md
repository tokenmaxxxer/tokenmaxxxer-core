---
issue: 288
role: implementation
loop_state: landed
upstream:
  - path: core/hooks/approval-gate.sh
    sha: same-commit
code_under_review: same-commit
type: fix
breaking: false
verdict: pass
---

# issue-288 — implementation record

## What was done

Fixed the `gh --json` field-name typo in `core/hooks/approval-gate.sh`
that made every real approval-state check fail closed:

- `core/hooks/approval-gate.sh:258` — the `gh issue view ... --json
  "state,comments,state_reason"` call now requests the real camelCase
  field `stateReason` (gh's actual schema, confirmed live via `gh issue
  view --help`'s JSON FIELDS list). `state_reason` is not a real gh
  field name; every invocation of this line previously made `gh` exit
  non-zero with `Unknown JSON field: "state_reason"`, which trips
  `approval-gate.sh`'s own `if issue_out.returncode != 0: deny(...)` —
  i.e. the gate was permanently fail-closed for every role, on every
  repo, against a real `gh`, before this fix.
- `core/hooks/approval-gate.sh:276` — the downstream Python dict read
  `issue_parsed.get("state_reason")` updated to
  `issue_parsed.get("stateReason")` to match gh's corrected JSON key.
- `docs/handbooks/approval-gate-tests.md` — prose references to
  `state_reason` corrected to `stateReason` to match the code.
- Swept `core/hooks/*.sh` (the only other file with a `gh ... --json`
  call is `board-gate.sh`, requesting `body`) for the same
  snake_case/camelCase mismatch class; `body`, `state`, `comments`, and
  `reviews` — the other fields requested across both files — are all
  valid single-word field names already, so no sibling fix was needed.
- Added `gh_json_schema_check` to
  `core/hooks/tests/run-approval-gate-tests.sh`: it greps the field
  lists `approval-gate.sh`'s two `gh ... --json` calls (issue view, pr
  view) actually request, fetches the real schema from `gh issue view
  --help` / `gh pr view --help`'s JSON FIELDS section (no live
  issue/PR needed — `--help` works offline), and fails if any
  requested field is absent from that real schema. This is the
  regression guard the issue asked for: the existing verdict-matrix
  tests use a stub `gh` that ignores requested field names entirely
  (always answers with `state`/`comments`/`reviews` regardless of what
  was asked), so they could not and did not catch this typo — this new
  check reads the real CLI's schema instead of a stub.

## Why

The issue's own live reproduction (`gh issue view <n> --json
state_reason` fails; `--json stateReason` succeeds) was reconfirmed
during this session against the real issue #288
(`gh issue view 288 --json state,comments,stateReason` → `rc=0`,
`{"comments":[],"state":"OPEN","stateReason":""}`). The one-line
field-name swap is the direct fix; the schema-check test exists
because the issue explicitly asked for a test that would have caught
this typo, and the existing test suite's `gh` stub structurally cannot
(it doesn't read the requested field names at all) — a golden-schema
check against `gh --help`'s real, offline-available field list closes
that gap without requiring network/live-issue access in CI.

## Upstream basis

- Issue #288 body (live reproduction: `gh issue view <n> --json
  state_reason` fails with "Unknown JSON field"; `--json stateReason`
  succeeds).
- `core/hooks/approval-gate.sh` at `e60a12a` (HEAD of
  `issue-288/implementation` at session start) — same-commit basis,
  this session's own fix lands on top of it.

## Open findings

None. A background `warrant-hunter` (stance 0: assume the gate just
touched is bypassable) ran before landing against this diff and
returned NO FINDING — see
`docs/issue-288/reports/implementation/2026-08-24-hunt-approval-gate-state-reason.md`.
It also traced that `issue_state_reason` is read-only/reporting-only
(never an enforcement input, matching the code's own design-decision-4
comment), so the corrected field's value cannot flip an allow/deny
outcome, and confirmed the new schema-check test fails loud (not a
false "ok") if `gh --help`'s output format ever changes.

## What did not work

None — this was a direct field-name correction with no false starts.

## Skill verdicts

skill-verdict: implementation-blueprint — not-applicable: single-file
field-name typo fix plus one test-file addition, no multi-module
structure decision (blueprint's own classify step explicitly excludes
one-line fixes)
skill-verdict: implementation-complexity-coupling-management —
not-applicable: no coupling/cohesion metric, accessor chain, or
cross-module import direction involved
skill-verdict: implementation-design-pattern-selection —
not-applicable: no GoF-pattern introduction/removal decision involved
skill-verdict: implementation-performance-data-structure-choice —
not-applicable: no data structure, algorithm, or communication-scheme
choice involved
other mounted skills: not triggered

## Next steps

None — loop_state is terminal (`landed`). Acceptance evidence below.

## Acceptance evidence

Live `gh` call using the exact corrected field list, against the real
issue #288:
```
$ python3 -c "
import subprocess
out = subprocess.run(['gh','issue','view','288','--json','state,comments,stateReason'], capture_output=True, text=True)
print('rc=', out.returncode); print(out.stdout[:300])
"
rc= 0
{"comments":[],"state":"OPEN","stateReason":""}
```

Full approval-gate test suite, clean environment (`CORE_BUILD_NOW`
unset, since this session's own ambient `CORE_BUILD_NOW=1` — set by
the spawner for this delivery-only session — leaks into two unrelated
tests' subprocess `env` calls and is not something the diff under
review touches or causes; the warrant-hunter traced this and confirmed
it predates and is unrelated to this fix):
```
$ env -u CORE_BUILD_NOW bash core/hooks/tests/run-approval-gate-tests.sh
...
ok     gh-json-field-schema               ok
== 58 passed, 0 failed ==
```
