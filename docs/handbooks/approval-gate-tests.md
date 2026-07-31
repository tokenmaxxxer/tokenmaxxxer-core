# approval-gate test harness

`core/hooks/tests/run-approval-gate-tests.sh` exercises
`core/hooks/approval-gate.sh` as a real subprocess against synthetic git
repos and JSON tool-call payloads (`run` helper; `want allow|deny` maps to
exit 0/2). `CORE_GH` points the gate at a stubbed `gh` binary instead of
the real network call.

Run it directly, no setup required:

    bash core/hooks/tests/run-approval-gate-tests.sh

`stub_gh <dir> <mode>` generates that stub. It is argument-aware: the
generated `gh` script branches on its own `$1` ("issue" vs "pr"), because
`approval-gate.sh` now makes two independent `gh` calls per check —
`gh issue view <n> --json state,comments` (the issue-state precondition,
checked first, plus the issue's own comments for the single-account
path) and `gh pr view <branch> --json reviews` (the two-account path,
tolerant of "no PR open"). Each `mode` sets `issue_state`,
`issue_comments`, `pr_ok`, and `reviews` independently, so a test case
can combine, e.g., a closed issue with an otherwise-valid PR review.

Covers: PR-review approval (two-account), issue-comment approval
(single-account, including the no-PR-open case that motivated moving the
canonical signal off the PR — see issue #53), bot/agent accounts never
satisfying either path, free-text comments never counting as approval, a
minimized/hidden issue comment not counting (GitHub's non-destructive way
to retract a comment), the issue-closed precondition denying both paths
unconditionally, missing/empty `approvers.md`, branch and role
preconditions, the no-remote precondition, and the docs execution-surface
rules (phase-1 homes stay open; the record file and other doc paths wait
for the Approve).
