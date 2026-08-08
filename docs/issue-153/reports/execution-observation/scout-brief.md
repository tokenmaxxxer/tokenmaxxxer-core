---
kind: scout-brief
subject: issue-153
produced_by: execution-observation
phase: 1
---

# Scout brief — issue-153, step 2 (execution-observation)

Pass: 1 stage (sweep only), **parallel** mode — 4 `WebSearch` angles issued
concurrently in one turn, aimed at the survey's U1–U6 gaps (normalization
completeness, reshaped fixtures, plan deviation, narrowing-induced coverage
loss). Judge point 1: all four returned on-point material, with overlap
between angles 1 and 4 on one theme — a narrowing whose failure branch is
permissive is judged by what stops being enforced, not by what starts being
allowed. Judge point 2: another round would change no evidence-plan
decision — stopped at saturation, inside the 5-stage / 3-min budget.

## Category must-bes for an audit of a "narrow the scan region of a validator" change

1. **Normalize, then validate — and check normalization for completeness,
   not for one patched instance.** Validating before canonicalization
   prevents detecting input that becomes invalid after canonicalization;
   the prescribed order is to normalize (strip invisible control
   characters, unify equivalent representations) and only then apply the
   check. [1][2][3]
2. **A reshaped or regenerated test fixture is the reviewer's first
   suspect.** Updated expected values and regenerated fixtures are "always
   worth questioning — is the new output right, or merely current?", and
   the audit reads whether the modified case would still catch a real
   regression rather than that it exists and passes. [4]
3. **Deviation from an approved change plan is an audit finding unless it
   carries a documented impact assessment and follow-up verification** —
   unapproved changes and incomplete impact assessments are the two named
   recurring change-control findings. [5][6]
4. **A permissive failure branch is a continuity-of-enforcement question.**
   When enforcement narrows, the audit's question is what is no longer
   enforced when the narrowing path fails, quantified, not whether the
   intended case still works. [7]

## Performance axes this observation competes on

- **Traceability**: verdict → primary artifact (SHA / `file:line` / comment URL).
- **Independence**: landed artifacts only; no re-execution of the observed suites.

## Adopt / skip

- **Adopt**: must-be 1 as the lens on U2 (the delivered leading-mark strip
  is read as a normalization step and judged for completeness against its
  own anchor, from the diff of `3f67436` alone); must-be 2 on U3 (read the
  5 reshaped fixtures' before/after in the diff and ask what each still
  pins); must-be 3 on U1 (impact assessment and verification are checked in
  the record's own deviation section); must-be 4 on U2's fallback branch.
- **Skip**: re-running `run-role-gates-tests.sh` or any repro from the hunt
  record to confirm the `56 passed` figure — the role directive forbids
  re-executing the observed role's code, so pass-count claims are assessed
  for internal consistency and diff support only, and residual uncertainty
  is stated as residual rather than closed by a rerun.

## Gap line

Current state already meets must-be 3 (the record carries a dedicated
`## Rationale for deviations` with impact and resolution,
`docs/issue-153/reports/implementation.md:82-96`) and partly must-be 2 (the
reshape is disclosed in `## What did not work`, `:70-80`, though what each
fixture still pins is not stated). **Missing**: must-be 1 and must-be 4 —
nothing in the landed record or proposal states the normalization step as a
class (only the single mark instance) or names what coverage the permissive
empty-region branch drops. That pair is what the phase-2 evidence plan aims
at first.

Sources:
1. <https://wiki.sei.cmu.edu/confluence/spaces/java/pages/88487808/IDS11-J.+Perform+any+string+modifications+before+validation>
2. <https://cheatsheetseries.owasp.org/cheatsheets/Input_Validation_Cheat_Sheet.html>
3. <https://www.cvedetails.com/capec-definition/CAPEC-71>
4. <https://pyor.review/blog/test-rewrite-failure-mode>
5. <https://simplerqms.com/audit-findings/>
6. <https://naraoig.oversight.gov/sites/default/files/reports/2024-02/audit-report-09-09.pdf>
7. <https://www.deepinspect.ai/blog/ai-gateway-fail-open-vs-fail-closed>
