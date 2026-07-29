# Proposal: review of issue #12 (board-gate R5 mkdir/rm false positive)

## Scope

Audit the landed fix against issue #12 as spec, per-requirement verdict
only (Present/Surface/Absent/Incorrect/Unverifiable) — no code-quality
holism, no fix.

code_under_review: `380c263b7e8000a487665f451589b4ad5ed1096b`
(PR #13, `issue-12/coding` -> `main`, merge `b0d5c27`).

## Extracted requirement list (from issue #12 body)

1. R5 own-role allow condition: `tail[0] == role and len(tail) > 1` ->
   `tail[0] == role`.
2. Foreign-role paths stay denied (fail-closed).
3. Regression test for the original false positive (own bare dir
   mkdir/rm -> allow).
4. Regression test for the foreign-role denial (foreign bare dir
   mkdir/rm -> deny).

Full extraction — 4 line items, matching the issue's "Root cause" +
"Fix" sections exhaustively; nothing in the issue body falls outside
these four.

## Sampling

None — diff is 9 non-doc lines, read in full. Full audit, not sampled.

## closed_checks disposition

coding.md cites `full hook test harness ... code_sha:
380c263b7e8000a487665f451589b4ad5ed1096b` — sha equals
code_under_review, so this is cite-eligible. Re-ran it independently
anyway (cheap, 40 cases) to confirm rather than blind-cite; result
matched (`40 passed, 0 failed`).

## Verdict preview

All 4 requirements: Present (see
`docs/issue-12/reports/review/survey.md`). No findings to open against
coding.
