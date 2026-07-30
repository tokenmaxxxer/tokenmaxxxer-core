---
proposal: docs/issue-46/proposals/2026-07-30-build-strip-wake-vocabulary.md
---

# Hunt record — strip-wake-vocabulary

## after-proposal — stance 1: stale cross-repo reference to stripped wake vocabulary

Verdict: FINDING — README.md still uses the stripped "wakes" vocabulary the edit was meant to remove repo-wide
Kind: silent-failure
Seed: git diff core/contract/role-handoff-contract.md (this branch's edit to strip wake/WAKES-ON vocabulary)

### Reproduce
grep -n "wake" README.md

### Observed
README.md:26:- A role wakes on an issue, works on branch `issue-<n>/<role>` (one branch
  per issue × role), and returns everything as a PR against `main`. No
  role pushes to `main`, files an issue, or merges anything.

role-handoff-contract.md was rewritten throughout to replace "wakes" with
"enters"/"is prompted"/"is the orchestrator's judgment", but README.md — a
top-level document describing the same "role starts work on an issue"
event — was left with the old "wakes on an issue" wording. The rewrite was
scoped to core/contract/role-handoff-contract.md only, so the vocabulary it
set out to strip now exists inconsistently: gone from the contract, still
present in the repo's front-door doc, describing the identical event, with
no explanation for the scoping.

### Expected
Either README.md's "wakes on an issue" phrase should have been swept in the
same change (the proposal's stated goal was removing "wake" vocabulary
because the underlying wake system was deleted upstream), or the
proposal/report should have explicitly noted README.md as out of scope and
why.
