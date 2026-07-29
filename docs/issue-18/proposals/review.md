# Proposal: phase-1 audit plan for issue-18 (review)

## Scope

Audit the merged fix for issue #18 (`core/hooks/directive.sh`'s
human-decisions paragraph, commit `f4cc6ab0814730ed9b791beb48783dc375100d4c`,
merged to `main` at `42c75dc` via PR #19) against:

- Issue #18's Symptom/Fix/Acceptance text, verbatim.
- `core/contract/role-handoff-contract.md` section 19 (amended) as the
  ground truth the fix is required to track.

## Requirement list (from `docs/issue-18/reports/review/survey.md`)

- R1. `directive.sh` states the amended two-path approval rule (two-account
  Approve; single-account exact-string `APPROVE issue-<n>/<role>` comment).
- R2. All other original clauses of the paragraph survive (PR merge =
  acceptance, closed-unmerged = refusal, bot/agent approvals excluded,
  no prose inference, role never self-approves/merges/relays).
- R3. No other live stale restatement of the pre-amendment single-path
  rule remains in the repo; grep evidence required.

No sampling — full audit (single-paragraph diff; R3's grep sweep is run
in full regardless of diff size).

## code_under_review

`f4cc6ab0814730ed9b791beb48783dc375100d4c`

## closed_checks disposition

No verify-role record exists for subject issue-18. Nothing will be cited
from `closed_checks`; all three requirements are re-derived directly in
phase 2.

## What phase 2 will produce

`docs/issue-18/reports/review.md`, `loop_state` transitioning through this
work, containing one verdict per requirement (R1-R3) from
{Present, Surface, Absent, Incorrect, Unverifiable}, each with an
evidence pointer into the diff/repo (file:line), not a paraphrase. No
fixes or patches proposed — findings addressed to the coding role if any
survive. Severity, if a finding is recorded, follows the
severity-classification skill's table lookup, not an averaged score.

## Out of scope

- Re-litigating issue #14 / PR #15's contract amendment itself.
- Re-reviewing `approval-gate.sh` or `gh-guard.sh` (survey found no
  connection between issue #18's scope and those files; they were not
  touched by the fix).
- Writing the actual verdicts now — this is phase 1; `review.md` is
  phase-2 output gated behind a human Approve per contract v3 s19.
