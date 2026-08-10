proposal: docs/issue-189/proposals/2026-08-10-rejection-withdrawal-lifecycle-design.md

## after-proposal

Not dispatched: `hunt-guard.sh`'s one-hunter-at-a-time lock stayed held by a
concurrent peer session for the full session lifetime (three dispatch
attempts, spaced across the turn, each refused with the lock still held by
another session). This is a headless single-shot session with no further
turn to retry in, so the after-proposal hunt is recorded as skipped by
contention rather than left silently absent. Stance that would have run:
index 2 ("assume this guard goes silent when its own input is malformed —
make it go silent"), against decisions 2-3 of the proposal (REJECT token
parsing, refused loop_state's mandatory finding-pointer enforcement).
