---
subject: issue-171
role: implementation
loop_state: open
---

# Fleet canon rollout runbook (issue-171 phase 1)

Execution against the 43 sibling rulebook repos is outside this repo's
write set (no push access — same constraint #63/#66/#69 already state).
This runbook is the handoff artifact: it fixes the batching, per-repo PR
shape, and re-scan cadence so phase-2 execution (an orchestration
dispatch against each rulebook repo, not a commit from this repo) can
run without re-deciding any of it. Rollout unit content (which files
move, what each stub looks like) is not re-derived here — see
`docs/issue-66/reports/implementation.md` ("Transition path") and
`docs/issue-69/reports/implementation/reclaim-21-copies.md` ("Reclaim
procedure"), reused verbatim.

## Rollout unit (per repo)

1. Delete, if present, every file listed in
   `core/hooks/tests/canon-manifest.txt` found anywhere under that
   repo's own tree — this is the authoritative list, not a hand-picked
   subset. As of this runbook it is: `trailer-gate.sh`,
   `record-fields-gate.sh`, `handbook-trigger-gate.sh`, `parse-check.sh`,
   `stub-check.sh`, `gate-lib.sh`, `gate-lib.py`, `compliance-check.sh`,
   `directive.sh` (handled separately, step 2 — not a plain delete),
   `hunt-guard.sh`, `hunt-state.sh`, `scope-gate.sh`, `state.sh`,
   `warrant-hunter.md`. A rollout PR that only removes the #66/#69-named
   subset and skips the rest leaves that repo's `canon-duplication` scan
   failing on the remainder — confirmed live against this fleet:
   `implementation-rulebook` and `defect-verification-rulebook` both
   still fail canon-duplication on `hunt-guard.sh`, `hunt-state.sh`,
   `state.sh`, `gate-lib.sh`, `gate-lib.py`, `compliance-check.sh`, and
   `scope-gate.sh` even after the named-subset files are gone. Regenerate
   the delete list from the manifest file at rollout time, not from this
   static copy, since the manifest can grow.
2. Replace `directive.sh` with the `core_role_directive` lib-call stub
   (source `core`'s `hooks/lib/role-directive.sh`, keep only the four
   role-unique values and the `trap`/`set -uo pipefail` pair — #66's
   report, item 3).
3. Remove any `hooks.json` entries that referenced the deleted files
   directly (core now registers them globally).
4. Set `RECORD_FIELDS_TERMINAL_STATES` in that repo's `hooks.json` env
   only if its current `record-fields-gate.sh` copy's terminal-state set
   is not just `{"landed"}` — check before deleting the copy in step 1,
   since the value disappears with the file.
5. Confirm the `${CLAUDE_PLUGIN_ROOT}`-relative sibling resolution in
   the new `directive.sh` stub actually resolves against that repo's own
   marketplace install layout (flagged as unconfirmed by #69's reclaim
   doc) — this is exactly what the pilot batch (below) exists to check
   before it's assumed for the other 42.
6. Run that repo's own `fleet-silent-failure-scan.sh <repo-path>`
   locally (or the equivalent local harness) before opening the PR. Any
   remaining finding — canon-duplication (a manifest file step 1 missed)
   or a six-signal sweep hit — is either fixed in the same PR or given a
   one-line justification comment in the PR description; never leave an
   unexplained finding after the repo's rollout PR merges. A remaining
   canon-duplication finding always means step 1 was incomplete, never a
   candidate for justification — the manifest is the source of truth for
   what "clean" means on that axis.

## Cohorting: pilot, then four count-ascending waves

Assignment is by issue-171's own embedded finding-count table, ascending
— cheapest (canon-duplication only, count 1) repos first, so the pilot
validates the mechanical stub swap (step 5 above) in isolation before
any batch also carries a secondary-defect fix in the same PR.

**Batch 0 — pilot (1 repo).**
`content-design-rulebook` (count 1). Re-scan gate: full
`run-fleet-scan.sh` run must show this repo `clean`, and the
plugin-root resolution confirmed working, before Batch 1 opens.

**Batch 1 — count 1-2 (10 repos).**
`market-analysis-rulebook`, `accessibility-rulebook`,
`requirements-engineering-rulebook`, `architecture-rulebook`,
`user-discovery-rulebook`, `pricing-rulebook`, `observability-rulebook`,
`localization-rulebook`, `legal-compliance-rulebook`,
`capacity-planning-rulebook`.

**Batch 2 — count 2-4 (10 repos).**
`brand-design-rulebook`, `data-engineering-rulebook`,
`secure-coding-rulebook`, `test-authoring-rulebook`,
`technical-feasibility-rulebook`, `technical-writing-rulebook`,
`pr-communications-rulebook`, `devrel-rulebook`, `incident-response-rulebook`,
`marketing-rulebook`.

**Batch 3 — count 5-6 (11 repos).**
`risk-management-rulebook`, `knowledge-management-rulebook`,
`issue-retrospective-rulebook`, `ux-engineering-rulebook`,
`refactoring-legacy-rulebook`, `performance-engineering-rulebook`,
`data-modeling-rulebook`, `growth-analytics-rulebook`,
`ml-engineering-rulebook`, `conformance-review-rulebook`,
`defect-verification-rulebook`.

**Batch 4 — count 7-15 (10 repos).**
`api-design-rulebook`, `finance-unit-economics-rulebook`,
`security-threat-model-rulebook`, `sales-rulebook`,
`partnerships-bd-rulebook`, `customer-support-rulebook`,
`release-engineering-rulebook`, `implementation-rulebook`,
`product-discovery-rulebook`, `interaction-design-rulebook`.

Counts: Batch 0 = 1, Batch 1 = 10, Batch 2 = 10, Batch 3 = 11, Batch 4 =
10 — sums to 42; `finance-unit-economics-rulebook` is listed once above
but the source table also independently lists a count-10 tie with
`security-threat-model-rulebook` and `sales-rulebook`, and manual
transcription of 43 names against a 43-line source table carries real
transcription risk. **Before phase-2 kickoff, regenerate this roster
programmatically from issue-171's own embedded table (sort by count,
chunk into the five bands above) rather than trusting this hand-copied
list** — this runbook fixes the *ordering rule* (ascending by count,
pilot first, five bands) as the binding mechanic; the exact per-batch
roster is a mechanical re-derivation from the source table, not a
judgment call, so re-deriving it costs nothing and removes the
transcription-error risk this note flags.

## Per-repo PR shape

- One PR per repo per batch (a PR cannot span repos on GitHub).
- PR body references `#171` (plain — no closing keyword; the closing
  PR is this repo's own future issue-171 delivery, not a sibling repo's
  PR) and links this runbook plus
  `docs/issue-69/reports/implementation/reclaim-21-copies.md`.
- PR description states which of the rollout-unit steps applied (some
  repos may lack one of the vendored files already) and, if a
  six-signal finding remains, the fix commit or the justification line.

## Re-scan cadence: after every batch

Run `core/hooks/tests/run-fleet-scan.sh` once, from this repo, after
each batch's PRs have all merged — not after every individual repo (43
full-fleet clone-and-scan runs would be wasteful) and not only once at
the very end (a systematic error in the stub-swap instructions, e.g. a
plugin-root resolution mismatch, would otherwise silently propagate
through all remaining batches before being caught). Append the resulting
row delta to the log below after each run.

## Re-scan log (append-only, filled in during phase-2 execution)

| Batch | Re-scan date | New clean rows | Rows still finding (repo: reason) |
|---|---|---|---|
| (none run yet — phase 1 only) | | | |

## Exit criterion

Rollout is complete when a full `run-fleet-scan.sh` run shows, for all
43 rows, either `clean` or a `FINDING` line carrying a justification
recorded in that repo's own PR/record — never an unexplained finding
surviving past the batch that was supposed to close it. This restates
issue-171's own acceptance text; no new criterion is introduced.
