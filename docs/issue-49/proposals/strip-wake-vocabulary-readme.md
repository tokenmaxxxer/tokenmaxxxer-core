# Proposal — strip remaining "wakes" vocabulary from README (#49)

files: `README.md`

## Request (paraphrased)

Issue #46's hunt found README.md:26 still says "A role wakes on an
issue"; #46's approved proposal explicitly left README out of scope.
Fix that line to match the orchestrator-judgment phrasing already
adopted in `core/contract/role-handoff-contract.md` (#46, commit
0800649).

## Constraints

- No structural/behavioral change — wording only.
- Match the established replacement idiom (opened, not "woken").

## What will be done

Reword README.md:26 from:

> A role wakes on an issue, works on branch `issue-<n>/<role>` ...

to:

> A role is opened for an issue, works on branch `issue-<n>/<role>` ...

## Out of scope

Any other README section; any code or contract file (already handled
in #46).

## How it will be verified

`grep -rni wake README.md` returns nothing after the change.
