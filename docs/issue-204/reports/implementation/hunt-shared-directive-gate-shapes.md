---
proposal: docs/issue-204/proposals/shared-directive-gate-shapes.md
---

# Hunt record — shared-directive-gate-shapes

## after-proposal — stance 4: assume the write set cannot carry this work — find the path the build will need that the proposal does not list.

Verdict: NO FINDING
Seed: docs/issue-204/proposals/shared-directive-gate-shapes.md (new file, frozen write set: core/hooks/directive.sh, core/hooks/tests/run-directive-shape-tests.sh)
cap_seconds: 60
tier: default
diff_stat_lines: 1 file added, ~90 lines (proposal doc)
started_at: 2026-08-11T00:00:00Z
ended_at: 2026-08-11T00:01:30Z

Checked whether the proposal's frozen write set omits a path the described
work will actually need: confirmed no `docs/specs/reconciled-index.md` or
`gates/spec_index.py` exists in this repo (correctly external, per the
proposal's own out-of-scope note); confirmed no `coding` rulebook
`directive.sh` exists in this repo (only `scout/hooks/directive.sh`,
`core/hooks/directive.sh`, `warrant/hooks/directive.sh` — the referenced
`implementation`/`coding` rulebook directives genuinely live in another
repo, so the phase-split duplication called out in Rationale cannot be
deduplicated here, matching the proposal's claim); confirmed
`run-role-directive-staging-tests.sh` (the cited precedent) really is
absent from `core/hooks/tests/run-all.sh`, so the new test file's
same omission is a documented, consistent choice, not a silent gap; and
confirmed no CI workflow file references either test script, so nothing
outside the two-file write set needs updating to wire the new test in.
Found no third path (fixture file, registry, workflow entry) the proposed
work would need but the write set fails to list.
