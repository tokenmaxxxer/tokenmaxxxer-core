---
code_under_review: `core/hooks/directive.sh`, `core/hooks/record-fields-gate.sh`, `core/hooks/handbook-trigger-gate.sh`, `core/hooks/tests/run-role-gates-tests.sh`, `docs/handbooks/core.md`
loop_state: landed
---

# Implementation record — issue #147

## What was done

Delivered C1/C2/C3 per the approved proposal
(`docs/issue-147/proposals/2026-08-08-announce-gate-literals-and-per-kind-terminal-states.md`),
approved via `APPROVE issue-147/implementation` (single-account mode).

- **C1** — `core/hooks/directive.sh` now states, in its injected §20 prose,
  every accepted spelling `record-fields-gate.sh`'s `has_any()` checks for
  (what-was-done, why, upstream-basis, open-findings, next-steps,
  resolution-path) and the `sha:` placeholder rule.
- **C2** — `record-fields-gate.sh` now derives terminal `loop_state` per
  contract §2 `kind` (parsed from the record's own `kind:` field, falling
  back to a role->kind map, falling back to the legacy flat set for a role
  contract §2 does not name) instead of one flat global list. The broken
  `RECORD_FIELDS_TERMINAL_STATES` env-var override channel is retired and
  replaced by a repo-committed `docs/specs/record-fields-terminal-
  states.json` file the gate reads directly off its own resolved `root` —
  malformed JSON, an unrecognized kind, or an unrecognized state spelling
  denies loudly rather than silently no-oping. `docs/handbooks/core.md`
  documents the new file's schema, defaults, and failure shapes (contract
  §21 doc-placement ladder).
- **C3** — `handbook-trigger-gate.sh`'s `OP_PATTERNS` reshaped from a tuple
  list into a `{"literal": re.compile(...)}` dict so #146's dict-key
  extractor picks up every trigger filename/pattern automatically;
  `directive.sh` now states the full trigger set and the `docs/handbooks/`
  commit-blocking obligation.
- Updated `core/hooks/tests/run-role-gates-tests.sh`: retired the
  `RECORD_FIELDS_TERMINAL_STATES` env-var fixture in favor of the new
  override-file mechanism (allow + 3 distinct malformed-shape denies);
  added an allow/deny fixture pair for every one of contract §2's 9
  record-writing kinds (product/coding/qa/feasibility/ux-design/review/
  verify/ops/reflect); corrected the PR #143 legacy-spelling fixtures —
  `complete`/`closed`/`done`/`delivered`/`phase-2-complete` are NOT
  contract-defined terminal states for `coding-record` and are now
  correctly pinned as denied (non-terminal, requiring next-steps), which
  is the C2 bug this issue reports, not a regression; added 4 fixtures
  pinning the C3 `OP_PATTERNS` reshape changed no matching behavior.

## Why

Core's own gates (`record-fields-gate.sh`, `handbook-trigger-gate.sh`) deny
every role session's first record write and first operational-surface
commit on rules the injected `directive.sh` prose never stated (C1/C3), and
`record-fields-gate.sh`'s terminal-state notion had empty intersection with
contract §2's real per-kind vocabulary while its only override channel
failed silently in all seven repos that tried it (C2) — confirmed live by
the issue-147 approval comment, which found #140's own "fix" widened the
flat list without ever intersecting the contract.

## Upstream basis

- Issue #147 (C1/C2/C3) and its Acceptance criteria.
- Approved proposal:
  `docs/issue-147/proposals/2026-08-08-announce-gate-literals-and-per-kind-terminal-states.md`.
- `core/contract/role-handoff-contract.md` section 2 (the per-kind
  `loop_state` vocabulary table C2's defaults are copied from verbatim).
- Approval comment on the issue (2026-08-08): `APPROVE issue-147/implementation`.

## Doc-placement ladder

- Handbook (env var/config key/new dep/migration/setup step) —
  `docs/handbooks/core.md` added, documenting the new
  `docs/specs/record-fields-terminal-states.json` config file (schema,
  defaults, failure shapes) and the C3 `OP_PATTERNS` trigger set.
- Decision record — none: no new library-or-format choice over a named
  alternative and no changed public signature/wire format beyond what the
  approved proposal's own `## Rationale` already recorded in phase 1.
- Report (benchmark/investigation numbers) — none produced this phase.

## Verification actually run

- `python3 core/hooks/tests/gate-prose-coverage-check.py .` — exit 0, zero
  violations (was 19 violations, all in `record-fields-gate.sh`, before the
  `directive.sh` edit).
- `bash core/hooks/tests/run-role-gates-tests.sh` — 78 passed, 0 failed.
- `bash core/hooks/tests/run-gate-prose-coverage-tests.sh` — 4 passed, 0
  failed (unchanged; the generic dict-key-shape fixture already covers the
  C3 reshape's extractor shape).
- `bash core/hooks/tests/run-all.sh` — ALL OK (parse-check across the
  changed shell files).
- Ran every other `core/hooks/tests/*.sh` suite (`run-approval-gate-tests.sh`,
  `run-board-gate-tests.sh`, `run-gate-lib-tests.sh`, `run-gh-guard-tests.sh`,
  `compliance-check.sh`, `deny-only-check.sh`,
  `run-compliance-scan-scope-tests.sh`, `run-stub-canon-forms-tests.sh`) —
  all pass unchanged. `stub-check.sh` run with no target argument against
  core's own tree fails identically before and after this change (it is
  designed to scan a rulebook's copy for vendored core files, not to be
  invoked bare against core itself) — not a regression, confirmed via
  `git stash`.

## What did not work

None — the direct approach in the approved proposal (per-kind terminal
states from a `kind:`-keyed table, a file-based override channel,
`OP_PATTERNS` reshaped to a dict) worked on the first implementation. One
correction was needed to the plan while writing tests: my first override-
file fixture used `CLAUDE_PROJECT_DIR=/tmp` like the suite's other
`run_rf` fixtures, which intermittently resolves the gate's project root to
`/tmp` itself in a sandbox where a stray `/tmp/.git` exists — not a
production-code defect, but the fixture needed a dedicated `run_rf_root`
helper pinning `CLAUDE_PROJECT_DIR` to this repo's own checkout so the
override file lands where the gate actually looks for it.

## Open findings

None open. `resolved_findings:` — n/a, no findings were addressed to this
role this phase.
