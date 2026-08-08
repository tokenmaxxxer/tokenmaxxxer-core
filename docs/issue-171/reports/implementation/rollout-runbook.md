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
| Batch 0 | 2026-08-08 | content-design-rulebook (clean, post-#173) | — |
| Batch 1 (partial) | 2026-08-08 | market-analysis-rulebook, requirements-engineering-rulebook (already clean); pricing-rulebook (no action needed — flagged file is not a duplicate) | accessibility-rulebook: layered-directive `wcag-em-directive/hooks/directive.sh` still misclassified after #175 (registered `layered-directive` shape in canon-forms.txt does not match this file's actual `.` source line); architecture-rulebook: `architecture/hooks/directive.sh` still misclassified after #175 (registered `unregistered-stub` shape does not match this file's actual two-`.`-source + `gate_kill_switch_active` shape — #175's shapes were constructed from a stated assumption, not the real repo bytes); localization-rulebook, capacity-planning-rulebook: canon-duplication still firing (same directive.sh class, unconfirmed per-file) plus each has its own mktemp-footgun finding, out of this rollout's canon scope |
| Batch 1 (partial, post-#177 re-scan) | 2026-08-08 | none newly clean | architecture-rulebook, accessibility-rulebook, localization-rulebook, capacity-planning-rulebook: all four still fail canon-duplication on `directive.sh` after #177's real-bytes `canon-forms.txt` patterns landed (PR #178, merged to main). Root cause confirmed by reading each repo's real `directive.sh` bytes directly (fresh `--depth 1` clone, same commit `da8565d615d9fb6c18487c9b338fa8b60bdf1120` for architecture-rulebook that #177 transcribed from): (1) architecture-rulebook's `directive.sh` line 14 sources `gate-lib.sh` via a path expression containing NESTED double quotes (`"${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh"`) — the registered `gate-lib-source` pattern's `"[^"]*gate-lib\.sh"` cannot match past the inner quotes, so the line is unrecognized; (2) the same file's line 16 sources `role-directive.sh` directly (a second `.` line, separate from the gate-lib.sh source on line 14) — no canon-forms.txt shape covers a direct role-directive.sh source line at all, registered or not; (3) accessibility-rulebook's own `accessibility/hooks/directive.sh` (distinct from the already-known-mismatched `wcag-em-directive/hooks/directive.sh` layered file) sources `role-directive.sh` directly with the same nested-quote path expression and no gate-lib.sh involved — same unregistered-source-line gap as (2); (4) localization-rulebook and capacity-planning-rulebook each have *multiple* per-facet `directive.sh` files (4 and 5 respectively, one per sub-plugin under `hooks.json`), consistent with the same layered/multi-source class, still unconfirmed line-by-line but same fix class expected. None of this is a canon-forms.txt content error to patch with another literal string — the gap is structural: no registered shape covers (a) a `.`-source line whose path expression itself contains nested double quotes, or (b) a direct `role-directive.sh` source line issued without a preceding `gate-lib.sh` source. Fix lives in `core/hooks/tests/canon-forms.txt` and/or `core/hooks/lib/gate-lib.sh`'s stub-shape matcher, outside issue-171's frozen write set — same class of blocker as sessions 2-3, now with the specific structural gap identified instead of a wrong guessed literal. |
| Batch 1 (post-#180/#183 re-scan) | 2026-08-08 | market-analysis-rulebook, requirements-engineering-rulebook (confirmed still clean); pricing-rulebook (still no action needed); **architecture-rulebook (newly clean — #180's structural line classifier now recognizes its nested-quote gate-lib.sh source plus its direct role-directive.sh source line)**; user-discovery-rulebook, observability-rulebook, legal-compliance-rulebook (canon-duplication now clean under #180's classifier; each still carries its own pre-existing six-signal finding, out of this rollout's canon scope: user-discovery-rulebook `fail-open-on-internal-error`, observability-rulebook `fail-open-on-internal-error`, legal-compliance-rulebook `mktemp-footgun`) | accessibility-rulebook, localization-rulebook, capacity-planning-rulebook: still fail canon-duplication, but the root cause has changed class from sessions 2-4's structural line-shape diagnosis (now fixed by #180) to a new one: each repo's own canonical `directive.sh` is correctly recognized as a stub, but each also carries one or more *layered, additional* SessionStart hook files that are also literally named `directive.sh` and deliberately do NOT call `core_role_directive` by design (per `docs/issue-7/proposals/methodology-enforcement.md` section 1, "composes alongside via hooks.json ordering") — accessibility-rulebook's `wcag-em-directive/hooks/directive.sh` (its own header comment states "does NOT call core_role_directive... a second, independent SessionStart hook"); localization-rulebook's 3 files (`localization/plugins/{mqm-tagging,verdict-axis,proposal-gate}/hooks/directive.sh`); capacity-planning-rulebook's 4 files (`capacity-{order-enforcement,threshold-decomposition,headroom-costnote,forecast-method}/hooks/directive.sh`). `compliance-check.sh`'s canon-duplication check treats every file literally named `directive.sh` as binary (recognized stub, or vendored canon copy), with no third category for a deliberately custom, non-canon file that only shares the filename — a false positive, not a rollout gap: these three repos need no rollout action on these specific files. Fix lives in `core/hooks/tests/compliance-check.sh`'s `directive.sh` branch of its canon-duplication check, outside issue-171's frozen write set. |

## Exit criterion

Rollout is complete when a full `run-fleet-scan.sh` run shows, for all
43 rows, either `clean` or a `FINDING` line carrying a justification
recorded in that repo's own PR/record — never an unexplained finding
surviving past the batch that was supposed to close it. This restates
issue-171's own acceptance text; no new criterion is introduced.
