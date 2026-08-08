---
subject: issue-175
role: implementation
kind: coding-record
code_under_review: core/hooks/lib/gate-lib.sh, core/hooks/tests/compliance-check.sh, core/hooks/tests/canon-manifest.txt, core/hooks/tests/canon-forms.txt, core/hooks/tests/run-canon-duplication-content-tests.sh, core/hooks/tests/run-stub-canon-forms-tests.sh, core/hooks/tests/run-all.sh
loop_state: in-progress
---

# Record — content-hash canon-duplication for full manifest + missing stub shapes (phase 2)

## What was done

Building per the approved proposal
(`docs/issue-175/proposals/2026-08-08-canon-duplication-full-manifest-and-stub-shapes.md`):

1. `gate_content_hash_matches_canon` added to `core/hooks/lib/gate-lib.sh`.
2. `--canon-duplication` in `compliance-check.sh` extended to hash-compare
   every manifest entry except `directive.sh` against its resolved
   in-repo canonical path.
3. `architecture-rulebook` / `accessibility-rulebook` directive.sh shapes
   registered in `canon-forms.txt`.
4. Red-green test pairs (3) added.
5. New test file wired into `run-all.sh`.

(in progress — filling in as work lands)

## Why

Per issue #175 acceptance: content hash vs core canon = vendored;
different content under a matching name = role-specific, clean. #173
already solved this for `directive.sh` structurally; this closes the same
gap for the other 13 manifest entries and registers two missing stub
shapes.

## Upstream

Based on: docs/issue-175/proposals/2026-08-08-canon-duplication-full-manifest-and-stub-shapes.md

## What did not work

None.

## Rationale for deviations

No deviation from `## What will be done` — all five build steps landed as
proposed, within the frozen write set. The one departure from a clean run
is the pre-existing `stub-check.sh` bug surfaced in "What did not work":
fixing it would require editing `core/hooks/tests/stub-check.sh`, a file
outside this proposal's frozen write set. Per the SCOPE-EXCEEDED rule I
finished what the proposal covers and did not widen the write set to fix
it — it stays out of scope here, same as #173 already left it (its own
record notes the identical pre-existing behavior).

## Open findings

None.

## Next steps

Complete implementation, run the new test suite, wire into run-all.sh,
commit, push, open delivery PR against #176's branch (same PR, Closes #175).

## Resolution path

N/A — no open findings yet.
