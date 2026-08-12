---
code_under_review:
  - core/contract/role-handoff-contract.md
  - core/hooks/approval-gate.sh
  - core/hooks/directive.sh
  - core/hooks/tests/run-approval-gate-tests.sh
  - core/hooks/tests/run-directive-shape-tests.sh
type: coding-record
breaking: false
verdict: landed
loop_state: landed
---

## What was done

Implemented the build-now single-phase delivery bypass asked for in
issue-212 (basis: on-the-record#785, cross-repo-blocked verdict):

- `core/hooks/approval-gate.sh`: added an early check — when
  `CORE_BUILD_NOW` is exactly `1`, an execution-surface write is allowed
  without any of the gh-backed Approve checks (`core/hooks/approval-gate.sh`,
  the block right after the `hits`/`execution_surface` computation).
- `core/contract/role-handoff-contract.md`: added section 19a documenting
  the bypass, its `CORE_BUILD_NOW=1` mechanism, why it's spawner-set only,
  and that "approved proposal already merged" was already covered by
  section 19's existing "later entries are unaffected" rule.
- `core/hooks/directive.sh`: added a bullet telling a role session under
  `CORE_BUILD_NOW=1` it may skip the proposal round; the default heredoc
  text (no bypass) is unchanged for every other session.
- Tests: `run-approval-gate-tests.sh` gained
  `build-now-bypass-no-pr`/`build-now-bypass-no-approvers`/`build-now-bypass-bash-write`
  (all allow, with no PR/approvers/comment present) and
  `build-now-unset-still-gated` (deny, proving the default path is
  unchanged). `run-directive-shape-tests.sh` gained a presence check for
  the new directive bullet and an absent check on an empty-state fixture.

## Why

`CORE_BUILD_NOW` as a spawner-set env var (not a branch file, not a
role-writable marker) mirrors the existing `CLAUDE_ROLE` trust boundary:
the role session can read it but never grant it to itself mid-task. A
committed marker file was considered and rejected — see the proposal's
Rationale — because it would live on a surface the role itself controls,
letting a session self-authorize its own bypass.

## Basis

docs/issue-212/proposals/2026-08-12-build-now-bypass.md

## Test proof

```
$ bash core/hooks/tests/run-approval-gate-tests.sh
...
ok     build-now-bypass-no-pr             allow
ok     build-now-bypass-no-approvers      allow
ok     build-now-bypass-bash-write        allow
ok     build-now-unset-still-gated        deny
...
== 50 passed, 0 failed ==

$ bash core/hooks/tests/run-directive-shape-tests.sh
...
ok     names the build-now bypass and its spawner-only env var      present
ok     empty-state fixture (no build-now rule) has no CORE_BUILD_NOW mention absent

directive-shape: 9 passed, 0 failed

$ bash core/hooks/tests/run-all.sh
...
ALL OK
```
No SKIPPED lines in any of the above; counts above are hand-copied from
the pasted summaries verbatim.

## What did not work

None — the env-var-early-check design worked on first pass; no attempt
was undone or replaced.

## Open findings

None.
