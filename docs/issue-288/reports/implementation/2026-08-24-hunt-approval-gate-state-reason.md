---
proposal: docs/proposals/2026-08-24-approval-gate-state-reason.md
---

# Hunt record — approval-gate-state-reason

## before-landing — stance 0: assume the gate just touched is bypassable — find the bypass

Verdict: NO FINDING
Seed: git diff HEAD -- core/hooks/approval-gate.sh (state_reason -> stateReason, 2 lines) and core/hooks/tests/run-approval-gate-tests.sh (new gh_json_schema_check function)
cap_seconds: 180
tier: default
diff_stat_lines: 2 changed in approval-gate.sh, +~48 in run-approval-gate-tests.sh, ~2 in docs/handbooks/approval-gate-tests.md
started_at: 2026-08-24T00:00:00Z
ended_at: 2026-08-24T00:20:00Z

### What was checked
- Confirmed with a live `gh` call (`gh issue view 288 --json "state,comments,state_reason"` against
  tokenmaxxxer/tokenmaxxxer-core) that the pre-fix field name makes `gh` exit non-zero
  ("Unknown JSON field: state_reason"), which trips
  `if issue_out.returncode != 0: deny(...)` unconditionally — i.e. before this fix the gate was
  permanently fail-closed for every role on every repo with a real `gh`, never fail-open. The fix
  only restores reachability of the normal approve/deny logic; it does not relax any check.
- Traced every use of `issue_state_reason` (`grep -n "issue_state_reason\|stateReason"
  core/hooks/approval-gate.sh`): it is read once (line 276) and referenced only inside the
  message-formatting branch of the `issue_state != "OPEN"` deny (lines 284-290), matching the
  code's own "design decision 4: read-only, reporting/routing only... never an enforcement input"
  comment. It never appears in the `approved = pr_approved or comment_approved` computation or any
  other branch condition, so a GitHub-supplied `stateReason` value cannot flip a deny to an allow.
- Verified the new `gh_json_schema_check` test in
  core/hooks/tests/run-approval-gate-tests.sh actually calls the real, live `gh issue view --help`
  / `gh pr view --help` (not a stub) and greps their "JSON FIELDS" section
  (confirmed present in installed `gh version 2.96.0`, includes `stateReason`).
- Checked the fail-mode of that test's own parser: if the "JSON FIELDS" regex fails to match,
  `schema()` returns `[]`; `bad = [f for f in issue_fields if f not in issue_schema]` then makes
  every requested field register as missing (nothing is "in" an empty list), so a parse failure
  in the future (`gh --help` format change) prints "FAIL:<fields>", not "ok" — it fails loud, not
  as a false pass. Same for `requested()` returning `[]`: caught explicitly by
  `if not issue_fields or not pr_fields: print("FAIL:no-fields-found")`.
- Ran `bash core/hooks/tests/run-approval-gate-tests.sh` twice: once inheriting this hunt
  session's own `CORE_BUILD_NOW=1` (58-test suite showed 2 failures — `execute-without-remote`
  want=deny got=allow, and `checkpoint-refusal-names-await-approval`), once with
  `env -u CORE_BUILD_NOW bash ...` (0 failures, 58/58 pass). This confirmed the 2 failures are
  caused by this session's own ambient `CORE_BUILD_NOW=1` leaking into the test harness's `env ...
  /bin/bash "$GATE"` subprocess invocations (which do not clear it), not by anything in the diff
  under hunt — the `CORE_BUILD_NOW` bypass branch and its ordering (before the remote/branch/gh
  checks) are unchanged by this diff and predate it (contract v3 s19a, issue-212). Not reported as
  the finding: it is not attributable to the reviewed change, and reproducing it required only
  this session's own dispatch environment, not a defect in the diff's field-name fix.

No path exists where the corrected `stateReason` field name (or its downstream read) changes an
allow/deny outcome, and the new schema-check test fails loud rather than false-passing on a
`gh --help` format change.
