---
subject: issue-53
role: coding
loop_state: scope-proposed
---

# Scout brief — issue #53

Category: manual-approval gates in CI/CD and code-review systems (this is
an internal governance-contract deliverable, not a product surface — the
comparable field is engineering-governance mechanisms, not a consumer
category).

**Must-bes (Kano):** approval binds to a specific, verifiable, forgeable
-resistant act (never free text); the artifact an approval covers is
named explicitly, not inferred.

**Performance axis observed: reset-on-artifact-change.** Both exemplars
invalidate/re-require approval when the covered artifact changes rather
than letting one approval cover indefinite future artifacts:
- GitLab merge-request approvals: a new push re-evaluates the MR's
  patch-id, and the project can be configured to remove existing
  approvals when new commits land — approvals are scoped to the
  reviewed diff, not the MR's lifetime by default (Sources #1).
- AWS CodePipeline manual-approval actions: the approval applies to one
  pipeline **execution**; a rejected/failed execution's retry is a new
  execution and needs a fresh approval action (Sources #2).

**Adopt:** keep exactly one human judgment point per issue+role — this
contract's existing design (one Approve, not one per PR) matches
CodePipeline's "one approval per unit of work" simplicity and should not
be abandoned just because the issue-comment move surfaces a scope
question.

**Skip:** automatic reset-on-new-artifact (GitLab/CodePipeline's norm).
This contract does not need a second automated invalidation mechanism to
get the same safety property, because it already has an unconditional,
separate, per-PR human act that plays the same role: the MERGE decision
(section 19) reviews the actual diff before accepting it, every time,
regardless of when Approve was granted. Adding an auto-reset would
duplicate that check with a mechanism issue #53 never asked for.

**Segment fit:** the exemplars are deployment/release gates, not code
"proposal" gates — the closer analogy is intentional: this contract's
gate authorizes *doing the work*, the merge authorizes *accepting the
result*, matching CodePipeline's stage-lock/execution split better than
it matches GitLab's per-diff MR model.

**Gap line:** the current contract already meets the forgery-resistance
and single-judgment-point must-bes (GitHub-authenticated Approve/exact-
string comment, never prose). What it's missing is the durability
property this issue exists to add (surviving two PRs on one branch) and
an explicit statement of what substitutes for reset-on-churn — this
proposal's "what still bounds the work after Approve" text is that
statement.

**Method:** 1 sweep stage, 2 parallel WebSearch queries (batched tool
calls in one turn, not subagents). Judge point 1: both hits converged on
the same reset-per-artifact pattern independently (GitLab's push-based
reset, CodePipeline's execution-based scope) — no disagreement to
reconcile, no further deepening needed; stopped at 1 stage, well inside
the 5-stage/3-minute budget.

Sources:
- [Merge request approval rules | GitLab Docs](https://docs.gitlab.com/user/project/merge_requests/approvals/rules/)
- [Approve or reject an approval action in CodePipeline - AWS CodePipeline](https://docs.aws.amazon.com/codepipeline/latest/userguide/approvals-approve-or-reject.html)
