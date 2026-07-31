---
subject: issue-66
role: implementation
loop_state: delivered
---

# Implementation record — promote role-agnostic rulebook gates to core canon

Approved via issue comment (single-account mode): `APPROVE issue-66/implementation`. Approver decision on the proposal's open question: hooks registration is **core-side** — the four promoted gates are wired once in `core/hooks/hooks.json` and fire for every plugin install automatically; no per-rulebook `hooks.json` entry remains.

## What shipped

1. **Canon promotion, CLAUDE_ROLE-parameterized** — `core/hooks/{trailer-gate.sh,
   record-fields-gate.sh, handbook-trigger-gate.sh}` added, each reading role
   identity from `CLAUDE_ROLE` at runtime (the convention `board-gate.sh`/
   `approval-gate.sh` already use) instead of having the role baked into a
   per-copy literal. Each carries its own generic, non-role-scoped kill
   switch (`TRAILER_GATE_OFF`, `RECORD_FIELDS_GATE_OFF`,
   `HANDBOOK_TRIGGER_GATE_OFF`) and derives its message prefix from
   `${CLAUDE_ROLE}` directly. `parse-check.sh` was already promoted to
   `core/hooks/tests/parse-check.sh` in a prior change and needed no work
   here — confirmed byte-identical-in-logic against a rulebook copy (the
   only diff was that copy's own default-directory arg, not gate logic).

2. **Registered core-side** — `core/hooks/hooks.json`'s `PreToolUse` block
   now lists all three new gates alongside `board-gate.sh`/`approval-gate.sh`/
   `gh-guard.sh`. They fire for every plugin install; no rulebook needs its
   own `hooks.json` entry for them.

3. **`directive.sh` boilerplate/unique split** — `core/hooks/lib/role-directive.sh`
   added: a sourceable library exposing `core_role_directive`, taking the
   four role-unique values (`YOU DECIDE`, `USE WHEN`, `PRODUCES`, `HAND-OFF`)
   and rendering the fixed preamble (kill-switch case, `CLAUDE_ROLE` guard,
   opening/closing lines) around them. A rulebook's own `directive.sh`
   shrinks to: shebang, source the lib, call `core_role_directive` with its
   four values. The `trap .../set -uo pipefail` two lines stay at the top of
   each rulebook's own file — a trap installed *inside* a sourced function
   does not catch the sourcing script's own abnormal exit the same way, so
   this pair is the one piece that could not be factored out.

4. **Drift-recurrence detector** — `core/hooks/tests/stub-check.sh` added,
   distributed the way `parse-check.sh` already is (dropped into every
   rulebook, run from its own harness). For the three gates plus
   `parse-check.sh`, it fails on *any* file by that name found under a
   rulebook's `hooks/` tree — since core registers them globally now, their
   very presence is the drift signal, not their content. For `directive.sh`
   it is structural: every non-blank/non-comment line must be the source
   line, a plain variable assignment, or the `core_role_directive` call;
   anything else (a case statement, a guard, raw output) is regrown
   boilerplate and fails. Wired into `core/hooks/tests/run-all.sh` via a new
   `run-role-gates-tests.sh`, which also exercises the three gates directly
   with two distinct `CLAUDE_ROLE` values each, asserting role-correct
   labeling and gate behavior. 16/16 pass; full `run-all.sh` (109 assertions
   across all existing suites plus these) passes.

## Finding that changed the build from the proposal's stated premise

The proposal's premise — "every existing inter-copy diff is role-name
substitution only... no role has gate logic that actually differs" — held
for `trailer-gate.sh` (confirmed by direct diff of two rulebooks' copies)
but **did not hold** for `record-fields-gate.sh` and
`handbook-trigger-gate.sh`, confirmed by diffing a `coding` copy against a
`product` copy read from the marketplace cache:

- Both files' message prefixes had drifted to values unrelated to their own
  rulebook's role — `handbook-trigger-gate.sh` in the `coding` rulebook
  denied under the literal prefix `"warrant:"`, and `record-fields-gate.sh`
  there denied under `"doctrine:"`. Neither matches `coding`. This reads as
  stale copy-paste, not intentional per-role behavior, and is fixed here:
  every canon gate derives its prefix from `CLAUDE_ROLE` unconditionally,
  which by construction cannot drift to an unrelated string again.
- `record-fields-gate.sh`'s two copies disagreed on which `loop_state`
  values count as terminal for the purpose of requiring next-steps/
  resolution-path sections: `{"landed"}` in one, `{"decided",
  "scope-proposed"}` in the other. Unlike the prefix drift, this could be
  genuine per-role semantics (a proposal-shaped role may legitimately treat
  an early state as its own terminal point) rather than a bug — there is no
  way to tell which from two data points, and this repo has no authority to
  decide role semantics for the 43 external rulebooks. Rather than silently
  picking one set for everyone, the canon file makes the terminal-state set
  configurable via `RECORD_FIELDS_TERMINAL_STATES` (space-separated,
  defaulting to `landed`) — a rulebook whose terminal states genuinely
  differ sets that var in its own `hooks.json` `env`, the same
  "role behavior via config, not via file copy" principle the rest of this
  promotion applies. This is called out explicitly rather than folded in
  silently, since it is the one place this promotion could not fully
  collapse 43 diverged copies into one universal behavior.

## Transition path (batches with #63)

Same rollout shape as issue-63's warrant-hunt canon promotion, extended to
five files plus the shared library and the detector:

1. **Done here**: `core/hooks/{trailer-gate.sh,record-fields-gate.sh,
   handbook-trigger-gate.sh}` + `core/hooks/lib/role-directive.sh` +
   `core/hooks/tests/stub-check.sh` added; `parse-check.sh` confirmed
   already canon; all four gates registered core-side in
   `core/hooks/hooks.json`; test coverage added and passing.
2. **Per-rulebook follow-up (tracked, not executed here — no write access
   to the 43 rulebook repos)**:
   - Delete each rulebook's own vendored `trailer-gate.sh`,
     `record-fields-gate.sh`, `handbook-trigger-gate.sh`, `parse-check.sh`
     and any `hooks.json` entry that referenced them directly — core fires
     them globally now.
   - Replace each rulebook's `directive.sh` with the lib-call stub
     (source `core`'s `hooks/lib/role-directive.sh` via
     `${CLAUDE_PLUGIN_ROOT}`-relative resolution against the core plugin's
     install path, then call `core_role_directive` with that role's four
     values).
   - Drop `core/hooks/tests/stub-check.sh` alongside each rulebook's
     existing `parse-check.sh`/`deny-only-check.sh` copies and add it to
     that rulebook's own CI/test harness.
   - Any rulebook whose `record-fields-gate.sh` copy relied on a
     non-`landed` terminal state (per the finding above) sets
     `RECORD_FIELDS_TERMINAL_STATES` in its own `hooks.json` env for the
     gate, or in its `directive.sh`/session env, before deleting its local
     copy — otherwise it silently regresses to the `landed`-only default.
   - Batch into the same wave as issue-63's `warrant-hunter.md` stub
     rollout — both are "43x mechanical edit, same repos," one coordinated
     change per rulebook instead of two.
3. **Sequencing**: both this promotion and #63's must land, and their
   per-rulebook stubs apply, before any of the 43 rulebook-maturation
   issues' phase 2 starts (this issue's own 순서 제약) — a maturation
   phase-2 touching `directive.sh` or a gate file before the stub rollout
   would duplicate work this promotion exists to prevent.

## What was deliberately not built

- The 43-rulebook stub rollout itself — outside this repo's write
  authority, tracked as the follow-up above.
- A universal terminal-state answer for `record-fields-gate.sh` — the
  finding above shows this is a real per-role question this repo cannot
  answer for external rulebooks; the config knob is the honest resolution.

## How this was judged

- Direct diff of two rulebooks' copies of each of the four files
  (read-only, via the marketplace cache) rather than trusting the
  proposal's characterization at face value — this is what surfaced the
  premise mismatch above.
- `core/hooks/tests/run-all.sh` run end-to-end: 52+36+19+16 gate assertions
  plus parse-check (17 files) and deny-only-check, all passing, plus the
  three sibling-plugin parse-checks.
- `run-role-gates-tests.sh` asserts, for each of the three gates, that two
  distinct `CLAUDE_ROLE` values produce role-correctly-labeled denials from
  the one canon file, and that `stub-check.sh` both catches a reintroduced
  vendored gate file and a directive.sh that has regrown boilerplate, while
  passing a clean tree and a real stub.
