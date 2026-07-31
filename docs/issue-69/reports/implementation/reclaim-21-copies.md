---
subject: issue-69
role: implementation
loop_state: open
---

# Reclaim procedure — 21 vendored `stub-check.sh` copies

Documented rollout procedure only. Execution is out of this role's scope
(no write access to the 43 external rulebook repos, per the approver's
phase-2 scope note and issue-66's own precedent for the same constraint) —
execution is handled by orchestration batch-spawn against each affected
rulebook repo.

## Steps

1. **Enumerate.** In each of the 43 rulebook repos, run:

       find . -maxdepth 3 -name stub-check.sh -type f

   against that repo's own checkout. The 21-count from issue #69's
   background is the expected total across all 43; this repo cannot
   produce the concrete path list (confirmed in
   `docs/issue-69/reports/implementation/survey.md`, item (c) — no
   `stub-check.sh` add outside `core/hooks/tests/stub-check.sh` appears in
   this checkout's history).

2. **Delete-and-reference.** For each repo where step 1 finds a copy:
   - delete the vendored `hooks/tests/stub-check.sh`;
   - update that rulebook's own test-harness entry point to the
     core-referenced invocation documented in
     `docs/handbooks/role-gates-tests.md` ("Canon invocation from a
     rulebook"):

         "${CORE_PLUGIN_ROOT:-$CLAUDE_PLUGIN_ROOT/../core}/hooks/tests/stub-check.sh" "$(dirname "$0")/.."

3. **Verify per-repo.** Re-run that rulebook's own harness after deletion;
   passing means the core-referenced call resolves and runs correctly with
   the vendored file gone — same verification shape issue-66's report used
   for its own four-gate promotion.

4. **Batch sequencing.** Stays batched with issue-63's warrant-hunt stub
   rollout and issue-66's own per-rulebook follow-up (deleting the four
   gate files / shrinking `directive.sh`) — one coordinated per-rulebook
   change, not three separate touches to the same 43 repos. Per issue-69's
   explicit ordering constraint, this reclaim is a precondition for every
   rulebook's maturation phase 2.

## Verification that step 2's invocation line is correct before rollout

`docs/handbooks/role-gates-tests.md` flags that the exact
`${CLAUDE_PLUGIN_ROOT}` sibling-resolution expression needs confirming
against a real marketplace install (this repo's own test run is a
same-checkout sibling layout, which may not match the external repos'
install layout). Confirm the resolved path against one pilot rulebook repo
before applying step 2 to all 21.

## Status

Not started. This document is the handoff artifact; core's
manifest-driven detection (`core/hooks/tests/canon-manifest.txt`,
`core/hooks/tests/stub-check.sh`) already catches any reintroduced copy
once a rulebook's test harness runs stub-check post-reclaim.
