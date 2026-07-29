---
kind: review-record
subject: issue-18
produced_by: review
upstream:
  - path: core/hooks/directive.sh
    sha: f4cc6ab0814730ed9b791beb48783dc375100d4c
loop_state: reported
closed_checks: []
code_under_review: f4cc6ab0814730ed9b791beb48783dc375100d4c
---

## What was done

Audited the merged fix for issue #18 against the approved phase-1 plan
(`docs/issue-18/proposals/review.md`). Read `core/hooks/directive.sh` at
`code_under_review` in full, diffed it against
`core/contract/role-handoff-contract.md` section 19, and ran a repo-wide
`grep -rn "A comment is never an approval" docs core src` sweep for R3.
All three requirements verify `Present`; no findings raised, none
addressed to any other role.

Requirement list extracted from `docs/issue-18/reports/review/survey.md`
and issue #18's Symptom/Fix/Acceptance text. Full audit, no sampling —
single-paragraph diff plus a repo-wide grep sweep for R3.

`closed_checks` is empty: no `verify-record` exists for subject issue-18,
so no check is cited; all three requirements below are re-derived
directly against `code_under_review`.

---
requirement: R1. directive.sh states the amended two-path approval rule (two-account Approve; single-account exact-string `APPROVE issue-<n>/<role>` comment).
verdict: Present
evidence: core/hooks/directive.sh:82-96 (paragraph beginning "Human decisions are GitHub acts only") — "Phase 2 opens through exactly two paths (contract v3 s19): a PR review Approve from an approvers.md account different from the PR's author (two-account mode); or, in single-account mode ... an issue-level comment whose entire body is the exact string APPROVE issue-<n>/<role>, posted by an approvers.md account."
rationale: This text is a verbatim match to the amended two-path rule in `core/contract/role-handoff-contract.md` section 19, and to the exact replacement text specified in `docs/issue-18/proposals/coding.md`'s "What will be done" section; both paths (two-account Approve, single-account APPROVE comment) are present.
---
requirement: R2. All other original clauses of the paragraph survive (PR merge = acceptance, closed-unmerged = refusal, bot/agent approvals excluded, no prose inference, role never self-approves/merges/relays).
verdict: Present
evidence: core/hooks/directive.sh:82-96 — "PR merge = acceptance of the delivered work, issue/PR closed unmerged = refusal." (line 82-83); "String equality only, never prose interpretation: any other comment ... is feedback, not approval" (line 89-91); "A bot's or another agent's Approve or APPROVE-shaped comment is never a human's — agent accounts are never listed in approvers.md." (line 92-94); "Never read approval out of prose, and never approve, merge, or relay an approval yourself." (line 95-96)
rationale: Each of the five original clauses named in the acceptance criteria (merge=acceptance, closed-unmerged=refusal, bot exclusion, no-prose-inference, never-self-approve/merge) has a corresponding, intact sentence in the current paragraph; none was dropped or weakened in the rewrite.
---
requirement: R3. No other live stale restatement of the pre-amendment single-path rule remains in the repo; grep evidence required.
verdict: Present
evidence: 'grep -rn "A comment is never an approval" docs core src' at code_under_review returns zero matches in core/ (including core/hooks/directive.sh and core/contract/role-handoff-contract.md); the only remaining occurrences of the phrase are inside docs/issue-18/proposals/coding.md, docs/issue-18/reports/coding.md, and docs/issue-18/reports/coding/survey.md, all quoting the old sentence as historical/before-text within this issue's own phase-1 documentation of the fix, not a live restatement of the rule.
rationale: The acceptance criterion asks for "no other live stale restatement" — the three docs hits are the coding role's own record of what it changed and why (before/after quoting), not an operative instruction any session would read as current rule text; core/ (the operative surface) is clean.
---
