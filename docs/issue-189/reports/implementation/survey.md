---
kind: survey
subject: issue-189
produced_by: coding
upstream:
  - path: docs/issue-189/proposals/2026-08-10-rejection-withdrawal-lifecycle-design.md
    sha: same-commit
  - path: docs/issue-189/reports/architecture/survey.md
    sha: same-commit
---

# Current-state survey: implementation of the approved rejection/withdrawal design (issue-189)

Skip condition: does not apply — this is a scout-eligible build with an
already-frozen upstream design (PR #192, merged). Per scout-directive,
scouting for this step is satisfied by the architecture step's own
scout/prior-decisions pass; this survey only needs to pin the exact
current-state lines each proposed edit touches, since the design (not
the pattern to imitate) is already fully specified.

## Write set and current state

1. `warrant/hooks/scope-gate.sh:39`
   `KNOWN_STATES = ("proposed", "approved", "landed", "withdrawn")`.
   Design decision 1 adds `"rejected"` to this tuple, same treatment as
   `withdrawn` (never eligible for the `approved` enforcement branch).

2. `core/hooks/approval-gate.sh`
   - Line 258: `challenge = "APPROVE issue-%s/%s" % (issue_num, role)`,
     matched exact-string against non-minimized issue comments from
     `approvers.md` accounts (~line 288-298, `comment_approved`).
   - Line 281-283: `last[login] = state` already captures
     `APPROVED`/`CHANGES_REQUESTED`/`DISMISSED` per login, but only
     `state == "APPROVED"` is consumed (line 283, `pr_approved`) —
     `CHANGES_REQUESTED` and `DISMISSED` are computed and then dropped.
   - Line 234-243: issue state check reads `issue_parsed.get("state")`
     only; `state_reason` is not in the `gh issue view --json` field
     list this script calls, nor read anywhere in the file.
   - No `REJECT` challenge string exists anywhere in the file today.
   Design decisions 2 and 4 land here: a `reject_challenge` string
   mirroring `challenge` verbatim (parameterized, same match function);
   reading (not discarding) the existing `last[login]` distinction
   between `CHANGES_REQUESTED` and `DISMISSED`; adding `state_reason` to
   the existing `gh issue view --json` field list already called at line
   ~234's callsite.

3. `warrant/hooks/state.sh`
   - Line 48-65: `open_units` collects only `status in ("proposed",
     "approved")` proposals under `docs/proposals/` and reports them;
     `withdrawn`/`rejected` proposals are read by nothing in this file —
     confirms survey finding #5 (closed-negative units produce no
     SessionStart signal at all, not even a "history" line).
   Design decision 5 adds a second pass collecting `withdrawn`/`rejected`
   proposals into a labeled "closed (withdrawn/rejected) — history"
   section, and decision 4's `state_reason` read (reporting-only, per
   the design's constraint that closing an issue stays human-only).

4. `core/contract/role-handoff-contract.md`
   - §2 (line 57-87) is the per-kind `loop_state` vocabulary table; no
     shared cross-kind terminal value exists there today — every
     terminal spelling is per-kind (`landed`, `wont-fix`, `no-go`, etc).
   Design decision 3 adds one shared preamble value, `refused`, usable
   by any kind's `loop_state` column, paired mandatorily with a finding
   pointer (contract §5/§6 already define the `finding` block and
   consumption rule this reuses — no new artifact kind).

5. `core/hooks/tests/run-role-gates-tests.sh`, `deny-only-check.sh`,
   `core/hooks/tests/run-scope-gate-tests.sh`
   - `run-role-gates-tests.sh`: existing `run_kind` harness iterates
     per-kind terminal-state coverage; has no `refused` case today.
   - `deny-only-check.sh`: forged-write probe; has no `REJECT`-token or
     `rejected`-state probe today.
   - `run-scope-gate-tests.sh`: exercises `KNOWN_STATES` handling
     (`withdrawn` already covered); has no `rejected` red/green pair.
   These three get one red/green pair each, per the design's explicit
   scoping of step-1 findings #6/#7 into phase 2's file list.

## `gh-guard.sh` posture (unchanged, verified)

`core/hooks/gh-guard.sh:81,85` blocks role-session `gh issue close` /
`gh pr merge`-class writes; nothing in this write set touches
`gh-guard.sh` or adds a write capability — decisions 2 and 4 are read-path
additions only (`approval-gate.sh` already reads issue/PR state via `gh`
today; this adds fields to an existing read call, not a new write call).

## Where vocabulary lives (why §2, not the JSON override)

`docs/specs/record-fields-terminal-states.json` (checked: not present in
this repo yet — no override file exists) promotes an *existing* kind
vocabulary value to terminal early; it has no mechanism to introduce a
value that isn't in §2 at all. `refused` is new vocabulary, so it must
land in §2's preamble directly, matching the design doc's own
"Alternatives considered" rejection of the override-file path.

## Test-running note

`core/hooks/tests/run-role-gates-tests.sh`, `deny-only-check.sh`, and
`run-scope-gate-tests.sh` are runnable shell suites; phase 2 will run all
three (plus any existing approval-gate suite) before the record is
written, per the phase-2 task's explicit instruction.
