---
subject: issue-66
role: implementation
loop_state: scope-proposed
---

# Proposal: promote role-agnostic rulebook plugin files to core canon

## Request (paraphrased intent)

Four role-agnostic files are vendored (copy-pasted, not referenced) into
every rulebook, and have already drifted: `trailer-gate.sh`,
`record-fields-gate.sh`, `handbook-trigger-gate.sh` (43 copies each, 43
distinct hashes per the issue's full-repo scan), `parse-check.sh` (10
copies, 10 hashes), and `directive.sh` (45 copies, common boilerplate
mixed with role-unique content in every file). The issue asks for: (1)
promote the role-agnostic gates/scripts to core canon, role name injected
via config/env rather than baked into per-copy content, (2) split
`directive.sh`'s boilerplate from its role-unique part so only the
unique part stays in each rulebook, (3) a transition path documented so
it can batch with #63's warrant rollout, (4) a drift-recurrence
detector.

## Constraints

- Phase-1 only — no code or hook changes ship in this PR. See
  `docs/issue-66/reports/implementation/survey.md` for the drift
  evidence and the boilerplate/unique split evidence this proposal is
  built on.
- Scouting is skipped (survey.md, "Scope note") — this is an internal
  architecture decision with issue-63 as the only relevant precedent,
  used directly as the transition template.
- This repo does not own the 43 rulebook repos; it cannot itself delete
  their vendored copies. This proposal defines what canon looks like and
  what each rulebook's replacement stub looks like; the per-rulebook
  edit is a tracked follow-up, same constraint issue-63 already stated.
- Order constraint from the issue: this must land before the 43
  rulebook-maturation issues' phase 2 starts, to avoid 43x duplicated
  gate edits. This proposal does not block on those issues; it is
  designed to be approved and executed ahead of them.

## What will be done (phase 2 only — not applied yet)

### 1. Canon promotion: gates parameterize on `CLAUDE_ROLE`, not on content

Move `trailer-gate.sh`, `record-fields-gate.sh`,
`handbook-trigger-gate.sh`, and `parse-check.sh` into `core/hooks/` as
single canonical files. Per the survey, every existing inter-copy diff
is role-name substitution only (env var prefixes like `PRODUCT_CYCLE_OFF`
/ `CODING_CYCLE_OFF`, and message-prefix strings like `"product: refused"`
/ `"coding: refused"`) — no role has gate logic that actually differs.
The promoted files:

- Read role identity from `CLAUDE_ROLE` at runtime (the convention
  `core/hooks/board-gate.sh` and `core/hooks/approval-gate.sh` already
  use), instead of having the role name substituted into the file at
  copy time.
- Use one generic, non-role-prefixed kill switch per gate (e.g.
  `TRAILER_GATE_OFF`, `RECORD_FIELDS_GATE_OFF`,
  `HANDBOOK_TRIGGER_GATE_OFF`), matching the existing `CORE_OFF` /
  `ORCHESTRATE_OFF` pattern already used by canon files in this repo —
  gate identity does not need per-role scoping since `CLAUDE_ROLE`
  already scopes the session.
- Derive the message-prefix label from `CLAUDE_ROLE` directly
  (`"${CLAUDE_ROLE}: refused — ..."`) rather than a literal string, so
  no template step is needed at all — this makes the gates truly
  role-blind code, identical on every rulebook by construction, not
  merely "generated to look the same."

`parse-check.sh` is already role-blind by design (per its own header
comment) and needs no `CLAUDE_ROLE` parameterization — it is promoted
as-is, byte-identical, closing the 5-unique-hash drift the survey found
on a file that should never have varied at all.

Each rulebook's copy becomes a one-line reference stub (the pattern
`core`, `scout`, `terse`, `freelunch` already use, and the same pattern
issue-63 proposes for `warrant-hunter.md`): a marketplace dependency
declaration, not a vendored file.

### 2. `directive.sh`: split boilerplate from role-unique content

Add `core/hooks/lib/role-directive.sh`, a sourceable library exposing
one function, `core_role_directive`, that takes four role-unique values
(as positional args or env vars: `YOU_DECIDE`, `USE_WHEN`, `PRODUCES`,
`HAND_OFF`) and internally handles everything the survey found
identical-by-structure across all 43 copies:

- the `trap`/`set -uo pipefail` preamble
- the kill-switch case statement, keyed off `CLAUDE_ROLE` (uppercased
  via `tr`, not bash 4's `${var^^}`, to stay inside `parse-check.sh`'s
  bash-3.2 compatibility floor) plus a fixed `_CYCLE_OFF` suffix — still
  effectively per-role since the role name flows from `CLAUDE_ROLE`, but
  no longer requires a distinct file per role to get there
- the `CLAUDE_ROLE` role guard
- the opening `[<role>] Role directive (on top of core's protocol):`
  line and the closing `RECORD: docs/issue-<n>/reports/<role>.md,
  phase-gated per contract v3 s19` line

Each rulebook's `directive.sh` shrinks to: source the library, set the
four role-unique values, call `core_role_directive`. This is the
"reference the common part, keep only the unique part" split the issue
asks for in item 2 — it is a shared function, not a second file to keep
in sync, because `directive.sh` (unlike the four gates) still needs a
small role-specific per-rulebook file to exist at all.

### 3. Transition path (batches with #63)

Same rollout shape issue-63 already proposed, applied to five files
instead of one:

1. This repo adds the five canon files (`core/hooks/{trailer-gate.sh,
   record-fields-gate.sh,handbook-trigger-gate.sh,parse-check.sh,
   lib/role-directive.sh}`) plus `core/hooks/tests/` coverage exercising
   the `CLAUDE_ROLE`-driven behavior directly (assert two different
   `CLAUDE_ROLE` values produce correctly-labeled output and correctly-
   namespaced kill switches from the one file).
2. `core/hooks/hooks.json` registers the four promoted gates as core
   `PreToolUse`/hook entries the same way `board-gate.sh` and
   `approval-gate.sh` are registered today — but this proposal does
   **not** decide unilaterally whether these become core-side hooks
   (always active for every plugin) or stay rulebook-side hooks (must
   still be registered per-rulebook's own `hooks.json`, just pointing at
   core's file via `${CLAUDE_PLUGIN_ROOT}` resolution against the core
   plugin's install path). This is the one open design question in this
   proposal — flagged for the human approver below, not decided here.
3. Per-rulebook follow-up (tracked, not executed by this repo): replace
   each of the 43 rulebooks' five vendored files with the reference
   stub / library-call form. Batched into the same wave as issue-63's
   warrant-hunter stub rollout, since both are "43x mechanical edit,
   same shape, same repos" — one coordinated change per rulebook instead
   of two.
4. Sequencing: both this promotion and #63's must land and their
   per-rulebook stubs apply *before* any of the 43 rulebook-maturation
   issues' phase 2 starts, per this issue's own 순서 제약 — otherwise a
   maturation phase-2 that touches `directive.sh` or a gate file
   duplicates work this promotion was meant to prevent.

### 4. Drift-recurrence detection

Add `core/hooks/tests/stub-check.sh`, distributed to every rulebook the
same way `parse-check.sh` already is (per `parse-check.sh`'s own header:
"distributed to every rulebook the way deny-only-check.sh is"). It
checks, for each of the five canon files, that the rulebook's local copy
is *exactly* the expected reference-stub/library-call form — not "close
to it," not "still parses" (which `parse-check.sh` already covers and
would not catch a locally-patched stub), but byte-equal to a pinned stub
template for gates and structurally-checked (source line + the four
`core_role_directive` args, nothing else) for `directive.sh`. A stub
that has grown a local copy of gate logic — the exact shape of today's
38/40-unique-hash drift — fails this check immediately rather than
silently accumulating for another 43-repo hash scan to eventually catch.
Wired into the same test harness `core/hooks/tests/run-all.sh` already
runs, so it executes on every core change and is available for each
rulebook to run in its own CI the same way `parse-check.sh` is today.

## Open question for the human approver

Should the four promoted gates be wired as **core-side hooks** (registered
once in `core/hooks/hooks.json`, active for every plugin install
automatically, since they are genuinely role-blind logic) or remain
**rulebook-side hook registrations** that merely point at core's file
(each rulebook's own `hooks.json` still lists them, but the command path
resolves into the core plugin's install directory instead of a vendored
local file)? The first fully eliminates the per-rulebook `hooks.json`
entry too; the second is a smaller diff per rulebook and keeps each
rulebook's hook list self-documenting without needing to open core's
`hooks.json` to know what fires. This proposal defaults to recommending
the first (core-side) given these gates have no per-role logic left once
`CLAUDE_ROLE`-driven, but defers the final call to the approver since it
changes how every rulebook's `hooks.json` reads.
