---
proposal: docs/issue-202/proposals/hunt-record-role-scope-path.md
---

# Hunt record — hunt-record-role-scope-path

## after-proposal — stance 0: assume the gate just touched is bypassable — find the bypass.

Verdict: NO FINDING
Seed: docs/issue-202/proposals/hunt-record-role-scope-path.md (232 insertions, docs-only), proposed CLAUDE_ROLE/branch-derived hunt-record path rule vs core/hooks/board-gate.sh R3/R4/R5 (lines ~553-614)
cap_seconds: 60
tier: default (size:docs-only)
diff_stat_lines: 232 insertions (docs-only)
started_at: 2026-08-11T00:00:00Z
ended_at: 2026-08-11T00:05:00Z

I ran `core/hooks/board-gate.sh` directly (bypassing the live PreToolUse
wrapper, which itself denied my first probe attempt for the same reason
the proposal describes — confirming the problem is real) against synthetic
Write payloads with `CLAUDE_ROLE=implementation` on the actual current
branch `issue-202/implementation`:

- `docs/issue-202/reports/hunt-foo.md` (old flat rule) -> rc=2, denied by
  R5 ("belongs to another role"). Confirms the proposal's stated defect.
- `docs/issue-202/reports/implementation/2026-08-11-hunt-foo.md` (proposed
  role-subdirectory template) -> rc=0, allowed. R5's `tail[0] == role`
  branch matches regardless of filename, so the proposed derivation is
  correct for R5.
- `docs/issue-999/reports/implementation/...` (wrong issue number, same
  role/branch) -> rc=2, correctly denied by R4 (branch mismatch) — no
  false-positive role-subtree write across issues.
- Non-role session (`CLAUDE_ROLE` unset) writing
  `docs/issue-202/reports/hunt-foo.md` -> rc=2, denied by R3 (no role at
  all under a board repo). This shows the proposal's third branch (`no
  CLAUDE_ROLE` -> keep the old flat `docs/issue-<n>/reports/hunt-<slug>.md`
  rule "unchanged") names a path that is categorically unwritable in any
  real board repo regardless of shape — but this is pre-existing behavior
  the proposal explicitly leaves untouched (Constraints: "the non-role-session
  path ... must be unchanged"), not a regression this diff introduces, and
  I could not construct a reproduction where the proposal's own change
  (the role-subdirectory branch) produces a denied or misrouted write.
  Considered but did not reproduce: ambiguity over which issue number
  ("n") backs the role-subdirectory template when a dispatching session's
  branch issue differs from the proposal's own issue segment — every real
  dispatch path (directive.sh dispatches hunts for proposals living under
  the session's own issue tree) keeps these identical, so I have no
  concrete input that exercises a mismatch.
