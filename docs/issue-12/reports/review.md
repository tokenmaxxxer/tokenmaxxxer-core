---
kind: review-record
subject: issue-12
upstream:
  - path: docs/issue-12/proposals/2026-07-29-review-issue-12.md
    sha: ba5ecc2c2470c202d89c81d0d52fa74e884a1906
code_under_review: 380c263b7e8000a487665f451589b4ad5ed1096b
loop_state: done
---

## Pointer

Governing `build-proposal`: `docs/issue-12/proposals/2026-07-29-review-issue-12.md`.
Approve comment: "APPROVE issue-12/review".

## What was done

Auditing GitHub issue #12 ("board-gate: Bash mkdir/rm on a role's own
record subpath falsely blocked as 'belongs to another role'") as spec,
against the landed fix `380c263b7e8000a487665f451589b4ad5ed1096b`
(PR #13, `issue-12/coding` -> `main`, merge `b0d5c27`). Stub written as
first act; verdicts to follow per requirement below.

Sampling: none. Diff is 9 non-doc lines (`core/hooks/board-gate.sh`
1 line, `core/hooks/tests/run-board-gate-tests.sh` 4 lines added), read
in full. Full audit, not sampled — per the approved phase-1 proposal.

Requirement list (4 items, extracted verbatim from issue #12's "Root
cause" / "Fix" sections in phase-1):

1. R1 — R5 own-role allow condition: `tail[0] == role and len(tail) > 1`
   -> `tail[0] == role`.
2. R2 — Foreign-role paths stay denied (fail-closed).
3. R3 — Regression test for the original false positive (own bare dir
   mkdir/rm -> allow).
4. R4 — Regression test for the foreign-role denial (foreign bare dir
   mkdir/rm -> deny).

Verdicts: all four requirements checked below. All `Present`. No
findings opened against `coding`.

## Per-requirement verdicts

---
requirement: R1 — R5 own-role allow condition: `tail[0] == role and len(tail) > 1` -> `tail[0] == role` (drop the `len(tail) > 1` requirement)
verdict: Present
evidence: core/hooks/board-gate.sh:278 (at code_under_review 380c263, R5 loop) reads `if tail[0] == role:` — diff hunk `-    if tail[0] == role and len(tail) > 1:` / `+    if tail[0] == role:` in commit 380c263, file core/hooks/board-gate.sh
rationale: The condition text after the change matches the spec's required condition verbatim; the `len(tail) > 1` clause is gone and no other clause was added in its place.
---

---
requirement: R2 — Foreign-role paths must remain denied (fail-closed preserved)
verdict: Present
evidence: core/hooks/tests/run-board-gate-tests.sh:169-170 (at 380c263) — `run deny bash-mkdir-foreign-dir Bash '{"command":"mkdir -p $BOARD/reports/review"}'` and `run deny bash-rm-foreign-dir Bash '{"command":"rm -rf $BOARD/reports/review"}'`, run from a `qa`-role fixture targeting `reports/review` (not `reports/qa`); independently re-executed at code_under_review sha in an isolated clone (`/tmp/.../verify-tree` checked out to 380c263b7e8000a487665f451589b4ad5ed1096b), full harness output: `== 40 passed, 0 failed ==`, including `ok bash-mkdir-foreign-dir deny` and `ok bash-rm-foreign-dir deny`
rationale: The R5 loop's own-role branch only widens on `tail[0] == role`; by construction a foreign role's `tail[0]` cannot equal `role`, so it still falls through to the untouched `deny()` fallthrough — confirmed empirically, not just by code inspection, via the independent re-run above (not a cite of coding's closed_checks, re-derived directly against code_under_review).
---

---
requirement: R3 — Regression test for the original false positive (own bare dir mkdir/rm -> allow)
verdict: Present
evidence: core/hooks/tests/run-board-gate-tests.sh:166-167 (at 380c263) — `run allow bash-mkdir-own-dir Bash '{"command":"mkdir -p $BOARD/reports/qa"}'` and `run allow bash-rm-own-dir Bash '{"command":"rm -rf $BOARD/reports/qa"}'`, run from `qa`-role fixture targeting its own `reports/qa`; independent re-run at code_under_review sha: `ok bash-mkdir-own-dir allow`, `ok bash-rm-own-dir allow` (see full harness output above, `== 40 passed, 0 failed ==`)
rationale: Both new cases target the role's own bare directory (`len(tail) == 1`) via Bash mkdir/rm, `want allow`, and pass — this is exactly the false-positive scenario from issue #12's symptom, now regression-covered.
---

---
requirement: R4 — Regression test for the foreign-role denial (foreign bare dir mkdir/rm -> deny)
verdict: Present
evidence: core/hooks/tests/run-board-gate-tests.sh:169-170 (at 380c263) — same lines cited under R2; independent re-run confirms `ok bash-mkdir-foreign-dir deny`, `ok bash-rm-foreign-dir deny`
rationale: This is the same test pair that evidences R2's fail-closed behavior, but the requirement here is specifically that a regression test *exists* for it (issue #12's "Fix" section item 4) — it does, and passes.
---

## closed_checks disposition

`coding.md` cites `full hook test harness (core/hooks/tests/run-board-gate-tests.sh)`
at `code_sha: 380c263b7e8000a487665f451589b4ad5ed1096b`. This sha equals
`code_under_review`, so the cite is valid per rule ("a closed_checks cite
from verify is valid ONLY if its code_sha matches code_under_review").
Re-ran it independently anyway, in an isolated clone checked out to
`380c263b7e8000a487665f451589b4ad5ed1096b` (not the working tree, to
avoid disturbing branch `issue-12/review`): result matched exactly —
`== 40 passed, 0 failed ==`, including all four new regression IDs.

## Summary verdict

All 4 extracted requirements (R1-R4): **Present**. No
Surface/Absent/Incorrect/Unverifiable verdicts. No findings opened
against `coding` — the landed fix at `380c263b7e8000a487665f451589b4ad5ed1096b`
matches issue #12's spec exactly, both in the code change and in test
coverage.

## Next steps

None open. This record is terminal (`loop_state: done`).

## Open-finding resolution path

No findings were opened. N/A — nothing pending resolution.
