---
kind: scout-brief
subject: issue-118
produced_by: execution-observation
loop_state: scouted
---

# Scout brief — issue-118 step 2

**Pass shape.** 2 of the 5 allowed stages, well inside the 3-minute budget. Stage 1: a
genuinely **parallel** 4-angle sweep — four `WebSearch` calls issued in one message
(docs-as-code review of policy-only PRs / policy-as-prose vs. enforced policy / postmortem
defect-class practice / cross-repo requirement mirroring). Stage 2: one judge point, which
found three angles converging on the same two checks and stopped deepening (saturation).
Angles were aimed at the survey's gaps U1, U3–U7, not at the issue text alone. In-repo
exemplars (`docs/issue-114/reports/execution-observation/`, `docs/issue-107/…`) were read
as format precedent alongside the web sweep, not in place of it.

**Category must-bes** for judging a norm-text-only change: the change is reviewed as code
would be — versioned, peer-reviewed, traceable in the PR [konghq, justwriteclick]; the
enforcement register is stated explicitly, because a policy that lives only as prose is a
known drift class ("policies without enforcement are documentation") [devsecopsschool,
spacelift, noopsschool]; the corrective action separates *mitigative* (this instance) from
*preventative* (the whole class) [sre.google, incident.io]; and a requirement mirrored into
a second home is tracked as drift-prone, with one home named authoritative [cinfinity,
paligo].

**Performance axes** to compete on here: (1) fidelity between the approved proposal's
stated placement and the landed text (U3); (2) explicit enforcement-register verification —
the delivery *claims* non-mechanization, so the claim is checked statically at a pinned SHA
rather than accepted (U5); (3) population coverage of the norm's own class — which other
in-repo record-norm homes now trail §20 (U7).

**Adopt**: the mitigative/preventative split as the shape of any action item; naming the
authoritative home explicitly when a rule is mirrored cross-repo (U6). **Skip**:
recommending mechanization or a policy-as-code gate — issue #118 requirement 2 forbids it,
and the field's default pull toward CI enforcement is exactly the pressure the issue
deliberately resists; the brief records that tension rather than acting on it.

**Gap line.** Already met by the current state: the change is PR-reviewed and versioned,
its enforcement register is stated in the record and PR body, and the cross-repo mirror is
named as follow-up. Missing, and therefore what this pass aims at: (a) no independent
check that the non-mechanization claim holds at the gate script itself, (b) no stated
population of *other* record-norm homes in this repo, and (c) no reconciliation between the
proposal's "among the existing numbered list" wording and the landed third-tier placement.

**Segment fit.** Same segment as the six prior execution-observation records in this repo;
the difference is that the observed artifact is norm prose, so the external corpus (policy
governance, postmortem practice) is genuinely applicable here where issue-114's code-fix
observation had none.

Sources (consulted this session as search-result summaries, not full-page fetches):
- https://sre.google/sre-book/postmortem-culture/
- https://incident.io/blog/sre-incident-postmortem-best-practices
- https://spacelift.io/blog/policy-as-code-tools
- https://devsecopsschool.com/blog/policy-as-code/
- https://noopsschool.com/blog/policy-enforcement/
- https://justwriteclick.com/2022/02/13/git-and-github-for-technical-documentation-reviews/
- https://konghq.com/blog/learning-center/what-is-docs-as-code
- https://www.cinfinitysolutions.com/insights/limitless/version-drift-doc-chaos
- https://paligo.net/blog/content-reuse/what-is-single-source-of-truth-ssot/
