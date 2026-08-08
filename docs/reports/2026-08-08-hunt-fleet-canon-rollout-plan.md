---
proposal: docs/proposals/2026-08-08-fleet-canon-rollout-plan.md
---

# Hunt record — fleet-canon-rollout-plan

## after-proposal — stance 4: index rotation (write set cannot carry this work — find the path the build will need that the proposal does not list)

Verdict: FINDING — the rollout-unit's file list (step 1-2 of the runbook) omits 7 of the 14 canon files in `core/hooks/tests/canon-manifest.txt`, and step 6's fix-or-justify safety net explicitly excludes canon-duplication findings, so per-repo canon-duplication on those 7 files has no path to `clean`/justified closure.
Kind: design-error
Seed: docs/issue-171/proposals/2026-08-08-fleet-canon-rollout-plan.md, docs/issue-171/reports/implementation/rollout-runbook.md, docs/issue-171/reports/implementation/survey.md
cap_seconds: 120
tier: default
diff_stat_lines: 413 (three new files)
started_at: 2026-08-08T18:47:48+09:00
ended_at: 2026-08-08T19:05:00+09:00

### Reproduce
```
cat core/hooks/tests/canon-manifest.txt
# 14 files: trailer-gate.sh, record-fields-gate.sh, handbook-trigger-gate.sh,
# parse-check.sh, stub-check.sh, gate-lib.sh, gate-lib.py, compliance-check.sh,
# directive.sh, hunt-guard.sh, hunt-state.sh, scope-gate.sh, state.sh,
# warrant-hunter.md

# runbook's rollout unit (step 1+2) only names:
#   trailer-gate.sh, record-fields-gate.sh, handbook-trigger-gate.sh,
#   parse-check.sh, stub-check.sh, warrant-hunter.md, directive.sh
# leaving gate-lib.sh, gate-lib.py, compliance-check.sh, hunt-guard.sh,
# hunt-state.sh, scope-gate.sh, state.sh unaddressed.

# step 6 (fix-or-justify net) reads:
#   "if it still reports a non-canon-duplication finding ... either fix it
#    in the same PR or add a one-line justification" -- canon-duplication is
#    explicitly carved OUT of this net.

bash core/hooks/tests/run-fleet-scan.sh   # real network run against the 43 repos
```

### Observed
Live scan output (this session, gh authenticated) for two of the runbook's
own batched repos:

```
implementation-rulebook | FINDING: canon-duplication: ... 'parse-check.sh' ...;
  canon-duplication: ... 'directive.sh' ...;
  canon-duplication: ... 'hunt-guard.sh' ...;
  canon-duplication: ... 'hunt-state.sh' ...;
  canon-duplication: ... 'state.sh' ...; ...

defect-verification-rulebook | FINDING: canon-duplication: ... 'stub-check.sh' ...;
  canon-duplication: ... 'gate-lib.sh' ...;
  canon-duplication: ... 'gate-lib.py' ...;
  canon-duplication: ... 'directive.sh' ...; ...
```
`hunt-guard.sh`, `hunt-state.sh`, `state.sh`, `gate-lib.sh`, `gate-lib.py`
are real, currently-flagged canon-duplication findings in repos the runbook
schedules for Batch 3/Batch 4, but the rollout unit (steps 1-2) never
deletes or replaces them, and step 6's routing text names canon-duplication
as the one finding type it does *not* catch. Following the runbook exactly
for these repos leaves those rows permanently un-`clean` and un-justified —
the exit criterion ("clean, or a FINDING with justification... never an
unexplained finding surviving past the batch that was supposed to close
it") can never be met for them under the runbook as written.

### Expected
The rollout unit should either enumerate deletion/replacement steps for all
14 `canon-manifest.txt` entries (matching what `compliance-check.sh
--canon-duplication` actually checks), or step 6's fix-or-justify net should
not carve out canon-duplication, so any residual canon-duplication finding
on a file outside the named six still has a route to closure.
