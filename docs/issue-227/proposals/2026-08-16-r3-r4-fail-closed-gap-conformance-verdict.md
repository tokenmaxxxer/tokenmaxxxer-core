---
status: proposed
files:
  - docs/issue-227/reports/conformance-review.md
---

## Request

Subject issue-227 cites requirements R3 and R4 (board-gate.sh's "no role,
no board writes" and "the role's own issue branch" checks). Its own text
notes the two write-gate holes it fixes (`${IFS}`/`$IFS` token fusion,
board-gate's indirect-tee miss) "also affect R3/R4 path detection" —
because both gates key R3/R4 (and scope-gate's write-set check) off
`hits`, the set of docs/-shaped paths the token scanner finds in the
visible command text. A masked write produces an empty `hits`, so the
call falls through `if not hits: allow()` before R3/R4 ever run, silently
bypassing them rather than tripping them.

Board condition (issue-521's conformance-review role spec) fired: commit
`1a2d393` landed on `issue-227/implementation` (PR #228, open, not yet
merged to main) and no conformance-review record exists yet for that sha.

Survey/scout skip: this is a fidelity check against two already-diagnosed,
already-fixed gap requirements in one already-read commit (full diff of
`core/hooks/board-gate.sh`, `warrant/hooks/scope-gate.sh`, and both test
files read in full; both test suites re-run against the commit in an
isolated checkout). No open design decision — the scout-directive's "pure
bugfix" / "spec leaves no design decision open" skip condition applies.

## Plan (phase 2, on Approve)

Record a per-requirement verdict in `docs/issue-227/reports/conformance-review.md`
for R3 and R4, based on re-running `core/hooks/tests/run-board-gate-tests.sh`
and `core/hooks/tests/run-scope-gate-tests.sh` against commit `1a2d393` and
reading the diff against the specific R3/R4 bypass path (the `if not hits:
allow()` fall-through) described above — not a holistic quality judgment of
the fix.

Preliminary finding (subject to phase-2 re-verification): both new
`_is_unanalyzable_write_shape` branches (indirect `tee`, `$IFS`/`${IFS}`
token fusion) and the new `UNANALYZABLE_WRITE_SHAPE` regex alternative in
scope-gate fire *before* the `hits`-derived flow reaches R3/R4's own
checks or scope-gate's write-set check, denying the previously-bypassing
shapes outright. Confirmed against the commit in an isolated checkout:
`run-board-gate-tests.sh` 119/119 pass (4 new cases:
`ifs-fused-inline-c-mask-bypass`, `ifs-fusion-unrestricted-session-unaffected`,
`indirect-tee-via-xargs`, `direct-tee-visible-target`), `run-scope-gate-tests.sh`
35/35 pass (2 new: `ifs-fused-inline-c-write-shape-denied`,
`ifs-fusion-unrestricted-session-unaffected`) — matching PR #228's stated
counts. Expected verdict direction: Present for both R3 and R4 (the
bypass that undermined their enforcement is closed; R3/R4's own logic is
otherwise untouched by this commit).

## Rationale

Two-phase flow (role-handoff contract v3 s19) applies — no
`CORE_BUILD_NOW=1` in this session's environment — so the verdict record
itself is phase-2 output and waits for a human Approve on this PR.
