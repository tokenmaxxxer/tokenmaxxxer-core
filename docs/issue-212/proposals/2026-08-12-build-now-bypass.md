---
status: landed
files:
  - core/contract/role-handoff-contract.md
  - core/hooks/approval-gate.sh
  - core/hooks/directive.sh
  - core/hooks/tests/run-approval-gate-tests.sh
  - core/hooks/tests/run-directive-shape-tests.sh
  - docs/issue-212/reports/implementation/survey.md
  - docs/issue-212/proposals/2026-08-12-build-now-bypass.md
  - docs/issue-212/reports/implementation.md
---

## Request

on-the-record#785 (cross-repo-blocked): the propose→build two-phase
default is enforced by this repo's rulebook and gate, so a subject
session elsewhere cannot change it. Ask: when a spawn task explicitly
authorizes delivery-only, the role session should skip the proposal round
and deliver directly; the default two-phase flow stays unchanged for
everyone else; back it with a test or live-fire proof.

## Constraints

- Must not weaken the default path: a task without explicit build-now
  authorization keeps today's Approve-gated two-phase flow exactly as is.
- Authorization must come from the spawner, not be self-grantable by the
  role session mid-task (mirrors the existing `CLAUDE_ROLE` trust model).
- Proof must be mechanical (a gate test), not just prose, per the issue's
  acceptance criteria ("gates/ or the phasing directive's own test file").

## Rationale

Chosen approach: a new env var, `CORE_BUILD_NOW=1`, set by the spawner
(same trust boundary as `CLAUDE_ROLE`), checked by
`core/hooks/approval-gate.sh` before its gh-backed Approve checks.

Alternative considered and rejected: a marker *file* committed to the
branch (e.g. `docs/issue-<n>/BUILD_NOW`) that the gate reads instead of an
env var. Rejected because a file lives on the execution surface the role
session itself controls — the session could write it and grant itself the
bypass, breaking the "spawner authorizes, not the role" constraint; an
env var the spawner sets before the session starts has no such
self-service path, matching how `CLAUDE_ROLE` itself is already trusted.

Failure signal if this proposal turns out wrong: `run-approval-gate-tests.sh`'s
`build-now-unset-still-gated` case would start allowing an execution write
with no `CORE_BUILD_NOW` set and no Approve signal — that regression is
exactly what a session self-granting the bypass would look like.

## What will be done

- [x] Add a build-now bypass check to `core/hooks/approval-gate.sh`: when
      `CORE_BUILD_NOW=1` is set, allow execution-surface writes without
      requiring a PR Approve or issue `APPROVE` comment.
- [x] Document the bypass in `core/contract/role-handoff-contract.md` as
      new section 19a, cross-referencing the on-the-record#785 basis.
- [x] Add a directive bullet to `core/hooks/directive.sh` so a role
      session under `CORE_BUILD_NOW=1` is told it may skip phase 1.
- [x] Extend `run-approval-gate-tests.sh` with build-now allow cases (no
      PR, no approvers file, Bash write) and an empty-state deny case
      (unset stays gated).
- [x] Extend `run-directive-shape-tests.sh` with a presence check for the
      new bullet and an absent check on an empty-state fixture.
- [x] Write this issue's phase-2 record.

## Out of scope

- The spawner's (on-the-record's) own task-spec schema for how it decides
  to set `CORE_BUILD_NOW=1` — that lives in the spawning repo, not here.
- Any change to the "approved proposal already merged" path — already
  covered by contract section 19's existing "later entries are
  unaffected" rule; this proposal only adds the new build-now path.
- Other plugins' own phase-shaped gates (scout's survey-order-gate,
  warrant's proposal-shape-gate) — issue-212's basis names this repo's
  phasing directive/rulebook specifically (core), not the sibling
  plugins.

## How you'll know it worked

`bash core/hooks/tests/run-approval-gate-tests.sh` shows
`build-now-bypass-*` cases allow with no PR/approvers/comment present,
and `build-now-unset-still-gated` still denies — proving the default path
is unchanged. `bash core/hooks/tests/run-directive-shape-tests.sh` shows
the new bullet present/absent checks passing.
