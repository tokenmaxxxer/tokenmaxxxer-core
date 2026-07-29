---
subject: issue-18
role: review
loop_state: proposed
code_under_review: f4cc6ab0814730ed9b791beb48783dc375100d4c
---

# Phase-1 survey — issue-18 (review)

## Spec audited against

- Issue #18 (title: "directive.sh: stale pre-amendment approval rule
  contradicts contract s19 single-account mode"), Symptom/Fix/Acceptance
  sections, verbatim.
- `core/contract/role-handoff-contract.md` section 19 (amended, PR #15 /
  issue-14) as the ground truth the fix must track.

## code_under_review

`f4cc6ab0814730ed9b791beb48783dc375100d4c` — the commit on merged PR #19
that edited `core/hooks/directive.sh`. Merged to `main` at `42c75dc`.
No verify-role record exists yet for this subject, so nothing is cited
from `closed_checks`; every check below is re-derived.

## Requirement extraction (from issue #18 acceptance, one line item each)

- R1. `directive.sh`'s text matches the amended contract: the
  human-decisions paragraph must state the two-path rule — (a) PR review
  Approve from an `approvers.md` account different from the PR author
  (two-account mode); (b) single-account mode, an issue-level comment
  whose entire body is the exact string `APPROVE issue-<n>/<role>` from
  an `approvers.md` account, valid only when the PR author and approver
  are the same account.
- R2. The rest of the original paragraph's clauses survive: PR merge =
  acceptance, issue/PR closed unmerged = refusal, a bot's/another agent's
  Approve or APPROVE-shaped comment never counts, no reading approval out
  of free-text prose, and the role never approves/merges/relays approval
  itself.
- R3. No other stale restatement of the pre-amendment single-path rule
  ("a comment is never an approval, however affirmative it reads" as a
  categorical, no-exception statement) remains anywhere live in the repo
  — grep evidence required in the record.

## Sampling

Not sampled — full audit. The changed surface is one paragraph in one
file (`core/hooks/directive.sh` lines ~82-97 per the merged diff); R3
requires a repo-wide grep sweep regardless of diff size, which was run
in full (not sampled) below.

## Evidence gathered this phase (re-derivable in phase 2, not a verdict)

- `git diff 42c75dc~1 42c75dc -- core/hooks/directive.sh scout/hooks/directive.sh`
  shows the paragraph replacement in `core/hooks/directive.sh` only;
  `scout/hooks/directive.sh` has no human-decisions paragraph at all (grep
  for "Human decisions"/"GitHub acts only"/"Phase 2 opens" over both files
  matches only `core/hooks/directive.sh`), so it was never in scope of
  this fix and is not a miss.
- `grep -rn "never an approval\|however affirmative" .` (repo-wide, from
  work-tree root) hits only: `docs/issue-14/proposals/comment-approval-s19.md`,
  `docs/issue-14/reports/coding/survey.md`, `docs/issue-18/reports/coding.md`,
  `docs/issue-18/reports/coding/survey.md`, `docs/issue-18/proposals/coding.md`
  (all historical phase-1/phase-2 records describing the *old* rule as
  something that was found and fixed — not live rule text), and
  `core/contract/role-handoff-contract.md:328`.
- The `role-handoff-contract.md:328` hit reads: "...never textual
  inference by a model. A free-text comment is never an approval, however
  affirmative it reads: deciding what a sentence means is a language
  problem... The one structural exception is section 19's single-account
  path: an issue-level comment whose entire body is the exact string
  `APPROVE issue-<n>/<role>`... is a mechanical string match, not textual
  inference — free-text approval commentary of any other shape remains
  categorically rejected." This sentence already carries the two-path
  exception inline in the same paragraph — it is not the stale
  categorical rule R3 targets; whether it counts as a "restatement" is a
  phase-2 judgment call, not resolved here.
- `core/hooks/directive.sh:82-97` (current, post-merge) text was read in
  full against the contract s19 two-path language quoted in the issue's
  Fix section; a line-by-line wording comparison is the phase-2 R1 check,
  not performed as a verdict here.

## Checks to cite-and-skip vs. re-derive

No verify-role artifact exists for this subject (checked: no
`docs/issue-18/reports/verify*` file, no verify PR/branch). Every check
above will be re-derived from scratch in phase 2; nothing is cited.
