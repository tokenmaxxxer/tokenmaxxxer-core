---
kind: scout-brief
subject: issue-132
produced_by: execution-observation
phase: 1
---

# Scout brief — issue-132, step 2 (execution-observation)

Pass: 1 stage (sweep only), **parallel** mode — 4 `WebSearch` angles issued
concurrently in one turn, aimed at the survey's U1–U5 gaps. Judge point 1:
angles 1/2/4 returned decision-relevant material with overlap on one theme
(claims must be checked against primary sources, not against the claimant's
summary of them); angle 3 returned no on-point standard. Judge point 2:
another round would not change any evidence-plan decision — stopped at
saturation, well inside the 5-stage / 3-min budget.

## Category must-bes for an audit of a "partly delivered, partly carried forward" change

1. **Zero-assumption citation verification** — every cited source is treated
   as unverified until the original is retrieved and read; the check is
   whether the source *structurally supports* the claim, not whether the
   reference is well-formed. [1]
2. **Non-vacuity of new tests** — a review confirms a new test would
   actually fail if the behavior broke; assertions that cannot fail look
   thorough and prove nothing. Seeing a test fail for the expected reason
   is the standard practice this replaces. [2][3]
3. **Carry-forward is not exoneration** — a documented, owned, dated action
   item is the honest form; "action items nobody completes are a form of
   theater," so an audit checks whether a carried item has a real owner and
   route, not merely a paragraph. [4]

## Performance axes this observation competes on

- **Traceability**: verdict → primary artifact (SHA / file:line / comment URL).
- **Independence**: no re-execution of the observed role's suites; landed
  artifacts only.

## Adopt / skip

- **Adopt**: retrieve-the-original citation checks (must-be 1) against the
  record's `docs/issue-100/...` precedent claim; non-vacuity reasoning about
  the new deny case read from the diff (must-be 2); owner/route check on the
  F2 carry-forward (must-be 3).
- **Skip**: running the harnesses to reproduce pass counts — the role
  directive forbids re-executing the observed role's code, so pass-count
  claims are assessed for internal consistency and diff support only, and
  any residual uncertainty is stated as such rather than closed by a rerun.

## Gap line

Current state already meets must-be 2 partly (the observed record itself
argues the case is fail-closed-by-design and pairs it with a resolver-level
red-green, `docs/issue-132/reports/implementation.md:50-75`) and must-be 3
partly (F2 has a written route in `## Next steps:208-220`). **Missing**:
must-be 1 — the record's central precedent claim about issue-100 has not
been checked against issue-100's own record by anyone but its author, and
the same is true of its R4-denial claim. That gap is what the phase-2
evidence plan aims at first.

## Assumptions (no source found)

- That a merged PR's title/body should still describe what it merged is
  stated here as an **assumption**, not a finding: the sweep surfaced no
  standard requiring PR-description freshness at merge (angle 3 returned
  only stale-*approval* and merge-content rules [5]).

Sources:
1. <https://arxiv.org/html/2511.04683v1>
2. <https://qaskills.sh/blog/reviewing-ai-generated-tests-checklist-2026>
3. <https://blog.ploeh.dk/2019/10/21/a-red-green-refactor-checklist/>
4. <https://incident.io/blog/sre-incident-postmortem-best-practices>
5. <https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets>
