---
status: proposed
files:
  - core/hooks/survey-order-gate.sh
  - core/hooks/tests/run-survey-order-gate-tests.sh
---

## Request

`core/hooks/survey-order-gate.sh` hardcodes the phase-1 survey path it
checks for as `docs/issue-<n>/reports/implementation/survey.md`,
regardless of which role's session is writing a phase-1 proposal.
board-gate.sh (contract v3 s11) requires a non-implementation role to
write only under its own `docs/issue-<n>/reports/<role>/` tree, so a
non-implementation phase-1 author's real survey
(`reports/<role>/survey.md`) is invisible to survey-order-gate, while
the path survey-order-gate demands is one board-gate itself refuses that
session to write. Fix: resolve the expected survey path from the
session's own role (`CLAUDE_ROLE`), falling back to the current
`implementation` path when role is unset; reject any accept-any-glob
shortcut; add regression coverage for a non-implementation role's
phase-1 proposal write.

**Scout-skip condition, stated per the scout directive:** this is a pure
bugfix aligning one gate's hardcoded path with an already-adopted
convention (board-gate.sh's per-role `reports/<role>/` tree, in use
throughout this repo) — no design decision is left open. See
`docs/issue-271/reports/implementation/survey.md` for the survey
supporting this.

## Constraints

- Must not change behavior for the existing `implementation`-role caller
  when `CLAUDE_ROLE=implementation` or unset — both currently resolve to
  `reports/implementation/survey.md`.
- Must not accept any role's survey as satisfying any other role's
  proposal write (no accept-any-glob).
- Fail-closed posture of the gate (trap-at-top `__fc`, deny-on-internal-error)
  must be preserved unchanged.
- No new external dependency; python3 usage stays inline as today.
- Regression test must follow this directory's existing sibling-gate test
  convention (`core/hooks/tests/run-<gate-name>-tests.sh`, plain bash
  driving the gate script with a JSON payload on stdin, per
  `run-record-shape-gate-tests.sh`).

## Rationale

**Chosen approach:** resolve the survey path from `os.environ.get("CLAUDE_ROLE", "")` inside the gate's embedded Python (mirroring `record-shape-gate.sh`'s `RS_ROLE` env-passthrough pattern), building `docs/issue-<n>/reports/<role>/survey.md` when role is a non-empty string, else falling back to the current hardcoded `reports/implementation/survey.md`.

**Alternative considered and rejected — accept-any-glob (`docs/issue-<n>/reports/*/survey.md`, any match satisfies the gate):** rejected because it defeats the ordering check's actual purpose. A stale survey left on disk by a long-abandoned session under a different role's tree would satisfy the gate for an unrelated role's proposal write, even though that acting session never surveyed anything itself. The issue explicitly calls this out ("Reject accept-any-glob") precisely because the survey's evidentiary value depends on it being *this session's own* work, not merely *some* file existing at *some* role path.

**Alternative considered and rejected — pass role explicitly via tool-input/payload instead of `CLAUDE_ROLE` env:** rejected because `CLAUDE_ROLE` is already the standing role-identity channel this repo's hooks read uniformly (`record-shape-gate.sh`, `trailer-gate.sh`, `board-gate.sh`, `handbook-trigger-gate.sh`, `directive.sh`, `proposal-shape-gate.sh` all read it the same way) — introducing a second, payload-based channel for this one gate would diverge from that convention for no behavioral gain, since the PreToolUse hook's own process already inherits `CLAUDE_ROLE` from the session environment exactly like its siblings.

## What will be done

1. In `core/hooks/survey-order-gate.sh`'s embedded Python block, read
   `CLAUDE_ROLE` from the environment (exported by the bash wrapper
   before the heredoc, matching `record-shape-gate.sh`'s `export
   RS_ROLE="${CLAUDE_ROLE:-}"` pattern).
2. Replace the hardcoded `survey_rel = "docs/issue-%s/reports/implementation/survey.md" % issue_n` with: if role is a non-empty string, `docs/issue-<n>/reports/<role>/survey.md`; else the existing hardcoded `reports/implementation/survey.md` fallback.
3. Leave every other check (existence test, scout-skip-marker text scan, deny messages referencing the resolved `survey_rel`) unchanged — they already operate generically on whatever `survey_rel`/`survey_abs` resolve to.
4. Add `core/hooks/tests/run-survey-order-gate-tests.sh` covering: (a) existing implementation-role behavior unchanged (with and without `CLAUDE_ROLE` set); (b) a non-implementation role (e.g. `product-discovery`) phase-1 proposal write is allowed once `reports/product-discovery/survey.md` exists, and denied when only `reports/implementation/survey.md` exists (proves no accept-any-glob); (c) scout-skip-marker text still permits the write for a role with no survey on disk.
5. Run the repo's fast test tier and confirm the new test passes alongside existing gate tests.

## Out of scope

- Changing board-gate.sh, record-shape-gate.sh, or any other gate.
- Changing the phase-1 survey file's required content/shape.
- Adding a config-driven per-role dispatch table (unlike record-shape-gate.sh's `CHECKERS` extension) — this fix only needs role-name substitution into one path, not multi-role rule variation.

## How you'll know it worked

- New `core/hooks/tests/run-survey-order-gate-tests.sh` passes, covering both the implementation-role-unchanged case and the non-implementation-role case described above.
- Manually piping a synthetic PreToolUse payload with `CLAUDE_ROLE=product-discovery` targeting `docs/issue-271/proposals/x.md` is denied when only `reports/implementation/survey.md` exists, and allowed once `reports/product-discovery/survey.md` exists.
- Repo's fast test tier run clean (no regressions in sibling gate tests).
