# Current-state survey — issue-212 (build-now single-phase delivery)

## Scope reviewed

Every surface the eventual change touches:

- `core/contract/role-handoff-contract.md` section 19 (`core/contract/role-handoff-contract.md:685-862`)
  — the propose→build two-phase rule. No existing bypass clause for a
  spawn-task-authorized delivery-only mode.
- `core/hooks/approval-gate.sh` (374 lines) — the mechanical gate. Reads
  `CLAUDE_ROLE` and (fast path) `CORE_GH`/`CORE_OFF`; no other env var is
  consulted (`grep -n CLAUDE_ approval-gate.sh` and `env | grep CORE_`
  confirm only `CORE_OFF`, `CORE_GH` exist as gate-facing seams —
  `core/hooks/lib/gate-lib.sh:gate_kill_switch_active`). It denies any
  execution-surface write (`src/**`, `test/**`,
  `docs/issue-<n>/**` minus `proposals/**` and `reports/<role>/**`) unless
  a PR review Approve or an issue-comment `APPROVE issue-<n>/<role>` from
  a `docs/specs/approvers.md` account exists. No spawn-task-level
  override exists today — confirmed by reading the full 374-line file top
  to bottom.
- `core/hooks/directive.sh` (179 lines) — the informing half. Its
  SessionStart heredoc states the two-phase flow as unconditional; no
  build-now branch.
- `core/hooks/tests/run-approval-gate-tests.sh` (273 lines, verdict
  matrix at lines ~104-125) and `core/hooks/tests/run-directive-shape-tests.sh`
  (test-file precedent: asserts named bullets are present via `awk`
  bullet-block extraction and absent from empty-state fixtures — this is
  the pattern issue-204 used to add rules to the directive and the pattern
  this change should reuse).

## What already exists that's adjacent

`role-handoff-contract.md:763-777` ("Later entries are unaffected") already
covers "approved proposal already merged" — a subsequent role-entry on an
already-Approved subject proceeds without re-clearing the gate. So half of
issue-212's Ask ("approved proposal already merged, or task marked
build-now") is already true today; only the "task marked build-now" half
is a gap.

## Prior art for env-var-gated spawner authorization

`CLAUDE_ROLE` is the existing precedent: a variable the spawner sets
before the role session starts, never settable by the session on its own
initiative in a way that grants itself new authority — `approval-gate.sh`
already trusts `CLAUDE_ROLE` this way (`core/hooks/approval-gate.sh:45`).
No other repo-internal mechanism for spawner-to-session authorization
exists (`CORE_OFF` is a blanket kill switch, not a per-task grant).

## Unknowns

- Which concrete spawner (on-the-record or another orchestrator) will set
  the new variable, and its exact task-spec field name upstream — out of
  this repo's control per the issue's own cross-repo-blocked basis; this
  repo can only define and honor the env-var contract, not the spawner's
  internal task-spec schema.

## Skip-condition check (scout directive)

Scouting (external field/exemplar research) does not apply: this is an
internal rulebook/gate mechanism change with no product-facing or
competitive-category surface to scout — the spec (issue-212's Ask) leaves
no external-facing design decision open, only an internal mechanism
choice (env var vs. some other signal), which is addressed in the
proposal's Rationale instead.
