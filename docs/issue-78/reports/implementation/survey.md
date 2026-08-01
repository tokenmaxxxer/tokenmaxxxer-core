---
issue: 78
stage: survey
---

# Current-state survey (issue-78)

## Problem 1 — stub-check.sh has no canon combination format

`core/hooks/tests/stub-check.sh` has two check modes today:
1. absence-based: `CANON_GATES`, sourced from `canon-manifest.txt` (one
   filename per line) — a rulebook must not vendor a copy of any listed file.
2. structural, hardcoded to `directive.sh` only: every non-blank/non-comment
   line must be the `role-directive.sh` source line, a plain
   `VAR=value` assignment, or the one `core_role_directive` call
   (`stub-check.sh:88-96`). Anything else fails as "regrown boilerplate."

The issue's failure: sales-rulebook's approved `for frag in ...` fragment
loop (issue-10, external repo) needs a `directive.sh` shape with an array
declaration + a `for` loop calling `core_role_directive` per fragment —
structurally different from the single-call form stub-check currently
allows, so it fails the "has non-stub line(s)" branch even though the
combination pattern itself was already approved.

There is exactly one structural pattern hardcoded in bash
(`stub-check.sh:82-96`); nothing here is presently table-driven the way
`CANON_GATES` is. Confirmed by scout angle 1: the repo already has a
data-driven allowlist mechanism (`canon-manifest.txt`) but only wired to
the absence-mode check, not the structural-mode check.

## Problem 2 — compliance-check.sh scans by filename glob, not by wiring

`core/hooks/tests/compliance-check.sh:24` scopes its scan with
`find "$dir" -maxdepth 3 -type f -name '*-gate.sh'`. Cross-checked against
every hooks.json in the repo:

| script | matches `*-gate.sh`? | PreToolUse-wired? |
|---|---|---|
| `core/hooks/board-gate.sh` | yes | yes |
| `core/hooks/approval-gate.sh` | yes | yes |
| `core/hooks/gh-guard.sh` | **no** | yes |
| `core/hooks/trailer-gate.sh` | yes | yes |
| `core/hooks/record-fields-gate.sh` | yes | yes |
| `core/hooks/handbook-trigger-gate.sh` | yes | yes |
| `warrant/hooks/scope-gate.sh` | yes | yes |
| `warrant/hooks/hunt-guard.sh` | **no** | yes |

`gh-guard.sh` and `hunt-guard.sh` are both PreToolUse-registered in their
plugin's `hooks.json` but never scanned by compliance-check, because
neither filename ends in `-gate.sh`. This matches the issue's confirmed
observation for `hunt-guard.sh` exactly, and shows the same hole is not
unique to that one file — `gh-guard.sh` has the identical exposure.
`freelunch/hooks/observe.sh` is also PreToolUse-wired (matcher
`Agent|Task|Workflow`) and would hit the same hole if it grew a kill-switch
or gate-lib-shaped defect later.

Every `hooks.json` in the repo (`core`, `warrant`, `scout`, `freelunch`,
`terse`) uses the same JSON shape: `hooks.PreToolUse[].hooks[].command`,
where `command` is a literal `${CLAUDE_PLUGIN_ROOT}/hooks/<name>.sh` (or,
for `observe.sh`, `bash ${CLAUDE_PLUGIN_ROOT}/hooks/observe.sh`) string.
Resolving the scan set from these `command` fields, per scout angle 2's
adopted pattern, replaces the glob without needing any new dependency
(the existing scripts are bash + `find`/`grep`; `python3` is already a
compliance-check.sh non-dependency — everything is POSIX-shell text
processing, no JSON parser required for this literal-shape command field).

## Write set implied by the above

- `core/hooks/tests/stub-check.sh` — add a manifest-driven structural-form
  registry (parallel to `CANON_GATES`) so `directive.sh` can match any
  *registered* structural shape, not only the single hardcoded one.
- `core/hooks/tests/canon-manifest.txt` or a new sibling manifest file —
  home for the registered combination shape(s). (Decision: extend the
  existing manifest format vs. add a second file — see proposal Rationale.)
- `core/hooks/tests/compliance-check.sh` — replace the `*-gate.sh` glob
  with a hooks.json-driven scan (walk every `hooks.json` under the target
  dir, extract `PreToolUse[].hooks[].command` script paths).
- `docs/handbooks/gate-house-standard.md` — record whichever canon-form
  choice is made, per the issue's explicit requirement ("어느 쪽이든
  gate-house-standard에 기록").
- Regression tests: `core/hooks/tests/run-role-gates-tests.sh` or a new
  test file exercising (a) a fragment-loop `directive.sh` now passing
  stub-check, (b) a still-invalid `directive.sh` still failing, (c)
  compliance-check now catching a `hunt-guard.sh`-shaped
  PreToolUse-wired-but-non-`-gate.sh`-named fixture.

No new external dependency, no new env var, no schema/migration — pure
bash-script logic changes plus one manifest/doc addition.
