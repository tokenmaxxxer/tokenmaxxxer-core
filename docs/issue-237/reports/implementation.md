---
code_under_review:
  - core/hooks/arch-sequence-gate.sh
  - core/hooks/content-design-phase1-basis-gate.sh
  - core/hooks/devrel-phase-order-gate.sh
  - core/hooks/incident-response-order-gate.sh
  - core/hooks/interaction-design-stage-order-gate.sh
  - core/hooks/issue-retrospective-proposal-order-gate.sh
  - core/hooks/security-threat-model-sequence-gate.sh
  - core/hooks/hooks.json
  - tests/test_ordering_gates_237.py
loop_state: landed
type: feature
breaking: "false"
verdict: pass
---

## What was done

Per the approved phase-1 proposal
(`docs/issue-237/proposals/2026-08-21-disposition-7-ordering-gates.md`,
approved via `APPROVE issue-237/implementation`), all 7 sweep-reclassified
rulebook hooks (`docs/reports/ordering-norm-sweep.md` on
`tokenmaxxxer/on-the-record`, issue on-the-record#1753) are dispositioned
`promoted`. Each source script was fetched live from its rulebook repo,
promoted verbatim into `core/hooks/`, with only the `gate-lib.sh` source
path changed to the one-level-up form every existing `core/hooks/*-gate.sh`
already uses (`$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)`), and
wired into `core/hooks/hooks.json`'s existing `PreToolUse` array. No
`UserPromptSubmit` directive scripts were added — none of the 7 source
rulebooks pair a directive script with these gates. 21 tests (3 per gate:
allow, refuse, empty-state) were added in
`tests/test_ordering_gates_237.py`, subprocess-invoking each promoted
script exactly as `tests/test_promoted_hooks.py` does for core#234's trio.

### Disposition table

| # | rulebook | source hook | disposition | new core hook | equivalence argument |
|---|---|---|---|---|---|
| 1 | architecture-rulebook | `arch-sequence-gate/hooks/sequence-gate.sh` | promoted | `core/hooks/arch-sequence-gate.sh` | Not equivalent to core's `survey-order-gate.sh`: that gate's survey path is hardcoded to role `implementation` (core#234's own deliberate non-generalization), so it provides zero coverage for an `architecture`-role proposal. This gate is additionally additive: it also gates the phase-2 record write (`docs/issue-<n>/reports/architecture.md`) requiring both `survey.md` and `scout-brief.md`, a surface core's gate never checks at all. |
| 2 | content-design-rulebook | `content-design-phase1-basis/hooks/phase1-basis-gate.sh` | promoted | `core/hooks/content-design-phase1-basis-gate.sh` | Different verification *mechanism* from core's `survey-order-gate.sh`: this checks that the resulting proposal *text itself* cites a survey/scout-brief path or skip phrase (regex over reconstructed content), not file-existence on disk. A proposal can pass core's check while failing this one (survey.md exists but is never cited) and vice versa — not behaviorally equivalent. |
| 3 | devrel-rulebook | `phase-order/hooks/phase-order-gate.sh` | promoted | `core/hooks/devrel-phase-order-gate.sh` | Same shape as core's proposal-side check (sibling `survey.md` existence gate on the same `docs/issue-<n>/proposals/*.md` surface) but keyed to `docs/issue-<n>/reports/devrel/survey.md`. Under core#234's own precedent of not generalizing the `implementation`-hardcoded path, core's gate never inspects this path — zero actual coverage for a devrel proposal today. |
| 4 | incident-response-rulebook | `incident-response-proposal-order-gate/hooks/order-gate.sh` | promoted | `core/hooks/incident-response-order-gate.sh` | Additive relative to core's gate: requires BOTH `current-state-survey.md` AND `scout-brief.md` to exist (core checks only one survey file), with a tighter section/window-scoped skip-record heuristic (negation-aware) rather than core's whole-file substring scan. Different surface (`docs/issue-<n>/proposals/incident-response*.md`) and different required file set — not equivalent. |
| 5 | interaction-design-rulebook | `interaction-design/plugins/id-stage-order/hooks/stage-order-gate.sh` | promoted | `core/hooks/interaction-design-stage-order-gate.sh` | Additive: checks BOTH the proposal-side (survey+scout-brief precondition, only on first creation) AND the phase-2 record-side (proposal-existence precondition) — core's gate covers neither the two-file precondition nor any record-side surface. Also maintains a `.status.json` state cache core's gate has no equivalent of. |
| 6 | issue-retrospective-rulebook | `proposal-order-gate/hooks/proposal-order-gate.sh` | promoted | `core/hooks/issue-retrospective-proposal-order-gate.sh` | Gates a different surface entirely: the phase-2 record write (`docs/issue-<n>/reports/issue-retrospective.md`), by reading the subject's own phase-1 proposal off disk and requiring it to name a survey path plus (scout-brief path or explicit skip). Core's gate never inspects the phase-2 record surface at all — not equivalent. |
| 7 | security-threat-model-rulebook | `security-threat-model/hooks/sequence-gate.sh` | promoted | `core/hooks/security-threat-model-sequence-gate.sh` | Same shape as devrel (#3): proposal-side `survey.md` existence check, but scoped to `docs/issue-<n>/reports/security-threat-model/survey.md` on proposals matching `*security-threat-model*.md`. Same zero-actual-coverage finding as devrel under core#234's non-generalization precedent. |

## Why

The on-the-record sweep reclassified all 7 as `promote` (pure
phase/stage-ordering gates with zero domain content). The phase-1 survey
(`docs/issue-237/reports/implementation/survey.md`) read all 7 source
scripts in full against core's already-promoted `survey-order-gate.sh`
(core#234) and found none of them actually covered: core's gate's survey
path is hardcoded to role `implementation`, a deliberate prior decision
(core#234's own Rationale) never generalized to other roles — so a
same-abstract-norm argument would be decoration, not real coverage, given
that precedent. 5 of the 7 are additionally substantively additive
(extra required files, extra gated surfaces, or a different verification
mechanism). All 7 therefore promote as their own role-scoped core hooks,
mirroring core#234's own "verbatim source, path-scoped" approach, keeping
each candidate's actual check intact rather than folding into one lossy
generalized gate.

## Upstream basis

`docs/issue-237/proposals/2026-08-21-disposition-7-ordering-gates.md`
(approved via `APPROVE issue-237/implementation`), built from
`docs/issue-237/reports/implementation/survey.md`, itself grounded in
`docs/reports/ordering-norm-sweep.md` on `tokenmaxxxer/on-the-record`
(issue on-the-record#1753, PR #1754) and core#234's precedent
(`docs/issue-234/proposals/2026-08-21-promote-7-rulebook-hooks.md`).

## Test evidence

```
$ python3 -m pytest tests/ -q
.......................................                                  [100%]
39 passed in 5.18s
```

`tests/test_ordering_gates_237.py` contributes 21 of the 39 (3 cases —
allow, refuse, empty-state — per each of the 7 promoted gates), invoked
as subprocesses against a temp git tree, matching
`tests/test_promoted_hooks.py`'s existing pattern.

## git diff file list

```
$ git diff --stat main...HEAD
 core/hooks/arch-sequence-gate.sh                    | new file
 core/hooks/content-design-phase1-basis-gate.sh       | new file
 core/hooks/devrel-phase-order-gate.sh                | new file
 core/hooks/hooks.json                                | modified
 core/hooks/incident-response-order-gate.sh           | new file
 core/hooks/interaction-design-stage-order-gate.sh    | new file
 core/hooks/issue-retrospective-proposal-order-gate.sh | new file
 core/hooks/security-threat-model-sequence-gate.sh    | new file
 docs/issue-237/proposals/2026-08-21-disposition-7-ordering-gates.md | new file (phase-1, prior commit)
 docs/issue-237/reports/implementation.md             | new file (this record)
 docs/issue-237/reports/implementation/survey.md      | new file (phase-1, prior commit)
 tests/test_ordering_gates_237.py                     | new file
```

Touches only `core/`, `tests/`, `docs/issue-237/` — no rulebook file
modified, satisfying acceptance criterion 2 verbatim.

## Doc-placement ladder

- [x] No env var / config key / new dependency / migration / setup step
  introduced — no handbook update needed.
- [x] No library-or-format choice over a named alternative, and no
  changed public signature/wire format beyond what's already recorded in
  the approved proposal's Rationale — no new `docs/issue-237/decisions/`
  entry needed.
- [x] No benchmark or investigation numbers produced — no
  `docs/issue-237/reports/` entry beyond this record needed.

## What did not work

None.

## Open findings

None.
