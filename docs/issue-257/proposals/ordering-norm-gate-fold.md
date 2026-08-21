---
status: proposed
files:
  - core/hooks/ordering-norm-gate.sh
  - core/hooks/ordering-norm-config.json
  - core/hooks/hooks.json
  - core/hooks/tests/test_ordering_norm_gate.py
---

files:
  - core/hooks/ordering-norm-gate.sh
  - core/hooks/ordering-norm-config.json
  - core/hooks/hooks.json
  - core/hooks/tests/test_ordering_norm_gate.py

## Request

Second fold of skill-axis phase-4b, following the validated #254
pattern. Fold the `ordering-methodology` family (18 hook instances / 15
distinct files across 11 rulebooks, per
`docs/reports/keep-role-family-classification.md` on-the-record
main) — hooks enforcing a named domain methodology's step/phase order
(RACE, ISO 31000, Double Diamond, Customer Development,
blameless-postmortem timeline-first) — into one parameterized
`core/hooks/ordering-norm-gate.sh`, behavior-equivalent to each source
hook under its own config row. Per hook, determine whether it is
already covered by the existing contract-phase `core/hooks/
ordering-gate.sh` (#248) instead of duplicating. Promote-first: no
rulebook file modified.

## Constraints

- Behavior-equivalent per hook: each source hook's allow/refuse verdict
  on realistic content, and each state-tracker's recorded-state
  behavior, must be reproduced by the core gate under that hook's
  config row (per [[survey.md]]'s per-hook table).
- Live-fire tests only (issue #248's lesson) — tests invoke the gate
  entrypoint with real PreToolUse/SessionStart/PostToolUse JSON on
  stdin, not unit-test the Python helpers in isolation.
- bash-3.2-safe: no heredoc inside command substitution (issue #245's
  guard test must stay green).
- Promote-first: none of the 11 rulebooks' hook files or `hooks.json`
  entries are modified or removed in this pass.
- No new dependency; reuse `core/hooks/lib/gate-lib.sh` and its existing
  `gate_reconstruct_write`/`gate_normalize_path` helpers, already used
  by all 15 source files and by the landed `record-fields-gate.sh`/
  `record-shape-gate.sh`/`facet-keyword-gate.sh` folds.

## Rationale

**Config shape: `{rulebook/hook-slug: {mode, event, target_path_regex,
step_sequence: [{label, marker_regex}], extra_checks: [...],
kill_switch_env}}`, not the classification report's flat
`{rulebook: {step_sequence: [...], marker_regex: {...}}}`.**
Considered adopting the report's guessed shape verbatim — it is the
frozen family definition and would need no new design discussion.
Rejected: per [[survey.md]], only 5 of the 15 source files are a clean
step-sequence check at all, and even those 5 bundle at least one
unrelated sub-check (race-sequence's conditional-on-`loop_state:landed`
gating plus 4 field checks; erm-order-gate's sub-markers and a
labeled-pair-must-differ check; phase1-structure-gate's Sources-block
and on-disk-path checks). The other 10 files are state-trackers,
cross-file-state-conditioned checks, or naming/selection checks with no
order relationship at all — none expressible as a bare marker list. A
flat shape would force either dropping those hooks from the fold
(breaking check 1's per-hook-disposition acceptance criterion, which
requires every hook end up `promoted-into-config` or
`covered-by-core` — dropping doesn't yield either) or stuffing
unrelated logic into `marker_regex` as an ad hoc mini-language, which
#254 already rejected for the same reason. Naming the extra fields
(`mode`, `event`, `extra_checks`) directly is the same lesson #254
drew: a config shape earns its rows from reading full bodies, not from
the family-boundary guess.

**`mode: gate|tracker` and `event: PreToolUse|SessionStart|PostToolUse`
fields, rather than treating the 5 state-tracker siblings as out of
scope.** Considered scoping this fold to the 10 PreToolUse gates only
and filing the 5 state-trackers as a separate follow-up issue, mirroring
how #240's ordering-gate build explicitly excluded `survey-order-gate.sh`
as an 8th case. Rejected: the classification report's own family
description explicitly includes "SessionStart/PostToolUse state-tracker
siblings" as part of the 18-hook count, and the issue's acceptance
criterion requires *each of the 18* dispositioned — carving 5 out
silently would misreport the count in the disposition table. The
`mode`/`event` fields let one dispatcher script register under all
three hook events in `hooks.json` and skip the deny path entirely for
`mode: tracker` rows, which is a small, bounded extension of the
already-validated config-table-dispatch shape (`record-shape-gate.sh`,
`facet-keyword-gate.sh`) rather than a new mechanism.

## What will be done

1. Write `core/hooks/ordering-norm-config.json`: 15 entries (one per
   distinct source file; the 3 duplicate-role rows from the
   classification count collapse onto their single file's entry with a
   documented note, since a JSON config can't have two rows for one
   physical dispatch target), each carrying `kill_switch_env`, `mode`
   (`gate` for the 10 PreToolUse deniers, `tracker` for the 5
   SessionStart/PostToolUse recorders), `event`, `target_path_regex`,
   an ordered `step_sequence: [{label, marker_regex}]` list (empty for
   the non-sequence checks in survey category B), and an `extra_checks`
   list carrying each hook's bundled non-order logic (field-presence,
   conditional trigger, state-file OR, labeled-pair-differ, Sources-
   block, on-disk-path) with enough shape to reproduce it — named per
   hook, not generalized into one mini-language.
2. Write `core/hooks/ordering-norm-gate.sh`: sources `gate-lib.sh`,
   reads payload via `payload="$(cat)"` (issue #245-safe), loads the
   config JSON, and for each incoming hook event: resolves the acting
   rulebook/role, finds matching config row(s), and for `mode: gate`
   rows runs target-path match -> step_sequence position compare (when
   non-empty) -> extra_checks, denying on any failure with the
   per-hook message shape; for `mode: tracker` rows performs the same
   read/derive-state logic without ever denying. Passes silently (exit
   0) when no row matches the acting rulebook/role (empty state) or the
   config file is absent (no-op).
3. Register the new gate in `core/hooks/hooks.json` under PreToolUse,
   SessionStart, and PostToolUse as appropriate per each row's `event`.
4. Write `core/hooks/tests/test_ordering_norm_gate.py`: live-fire cases
   invoking the gate binary with real event JSON on stdin — one allow +
   one refuse case per configured `mode: gate` role (10), one
   state-recorded case per `mode: tracker` role (5), one empty-state
   case (unconfigured role passes through silently), and one
   no-config-file case, run via the fast tier.
5. Diff scope check: `git diff --stat` limited to `core/` and
   `docs/issue-257/` — no rulebook file touched.

## Out of scope

- Removing/demoting the 15 source hook files from their rulebooks (a
  later, separate demotion issue, promote-first per this issue's own
  text).
- `customer-support-phase1-order/hooks/phase1-order-gate.sh`'s bundled
  5 facet-citation sub-checks are reproduced as `extra_checks` entries
  for behavior-equivalence, but are not re-generalized into the
  `facet-keyword-gate.sh` config landed by #254 — that would be a
  cross-family refactor beyond this issue's scope.
- The other families from the same classification report
  (`record-section-shape`, `citation-sourcing`, `role-directive`,
  `field-format-numeric`) — each is its own fold/demote issue.
- Any change to `gate-lib.sh` itself or to `core/hooks/ordering-gate.sh`
  (the existing, unrelated contract-phase gate) — the fold reuses
  `gate-lib.sh`'s helpers unmodified and leaves `ordering-gate.sh` as
  is, since [[survey.md]] confirms no overlap.

## How you'll know it worked

- `pytest core/hooks/tests/test_ordering_norm_gate.py` (fast tier)
  green, with one live-fire allow case and one refuse case per
  configured `mode: gate` role (10), one tracker-state case per
  `mode: tracker` role (5), plus the empty-state and no-config-file
  cases — output pasted in the phase-2 record.
- A disposition table in the phase-2 record naming, for each of the 18
  classification-report rows, `promoted-into-config` (naming its
  config row) or `covered-by-core` (naming the covering check) — per
  [[survey.md]], all 18 are expected `promoted-into-config`, none
  `covered-by-core`.
- `git diff --stat main...HEAD` in the phase-2 record showing only
  `core/` and `docs/issue-257/` paths touched, no rulebook file.
- The existing #245 heredoc-in-command-substitution guard test still
  passes (part of the fast tier run).
