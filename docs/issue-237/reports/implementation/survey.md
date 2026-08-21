# Survey: issue-237 — disposition the 7 sweep-reclassified ordering gates

## Source

`docs/reports/ordering-norm-sweep.md` on `tokenmaxxxer/on-the-record`
main (issue on-the-record#1753, PR #1754) reclassified 7 `keep-role` rows
to `promote`:

| rulebook | hook file |
|---|---|
| architecture-rulebook | `arch-sequence-gate/hooks/sequence-gate.sh` |
| content-design-rulebook | `content-design-phase1-basis/hooks/phase1-basis-gate.sh` |
| devrel-rulebook | `phase-order/hooks/phase-order-gate.sh` |
| incident-response-rulebook | `incident-response-proposal-order-gate/hooks/order-gate.sh` |
| interaction-design-rulebook | `interaction-design/plugins/id-stage-order/hooks/stage-order-gate.sh` |
| issue-retrospective-rulebook | `proposal-order-gate/hooks/proposal-order-gate.sh` |
| security-threat-model-rulebook | `security-threat-model/hooks/sequence-gate.sh` |

Each script fetched verbatim live via
`gh api repos/tokenmaxxxer/<rulebook>/contents/<path>` and read in full
(not the sweep report's header excerpt).

## Already-promoted core gates (core#234 baseline)

`core/hooks/survey-order-gate.sh` (183 lines): PreToolUse gate on
`Write|Edit|MultiEdit`. Fires only on writes matching
`^docs/issue-([0-9]+)/proposals/.*\.md$`. Denies unless
`docs/issue-<n>/reports/implementation/survey.md` already exists on disk,
OR the resulting proposal text itself contains a scout-skip marker
("skip condition", "scouting was skipped", "pure bugfix", "no design
decision", "skip record"). The survey path is **hardcoded to the
`implementation` role** (`"docs/issue-%s/reports/implementation/survey.md"`).

`core/hooks/proposal-shape-gate.sh` / `record-shape-gate.sh`: shape
checks (section presence/order), not ordering checks — not candidates
for this comparison.

core#234's own proposal (`docs/issue-234/proposals/2026-08-21-promote-7-rulebook-hooks.md`,
`## Rationale`) explicitly considered and **rejected** generalizing this
hardcoded `implementation` path to a role-parameterized
`${CLAUDE_ROLE}` form, reasoning "today only `implementation` produces a
`docs/issue-<n>/proposals/*.md` + `docs/issue-<n>/reports/implementation.md`
pair in the two-phase shape these gates parse." That is the standing
precedent this survey must reconcile against the 7 candidates, which all
target roles other than `implementation`.

## Per-candidate comparison

1. **architecture** (`sequence-gate.sh`, 203 lines) — checks TWO
   surfaces: (a) `docs/issue-<n>/proposals/*.md` write requires
   `docs/issue-<n>/reports/architecture/survey.md` (mirrors core's
   proposal-side check, but for role `architecture`, not
   `implementation`); (b) `docs/issue-<n>/reports/architecture.md`
   (phase-2 record) write requires BOTH `survey.md` and `scout-brief.md`
   to exist, unless a same-issue proposal states a skip. **Core's gate
   has no record-side check at all.** Additive on both role-scope and
   surface coverage.

2. **content-design** (`phase1-basis-gate.sh`, 127 lines) — different
   *mechanism*: it does not check file existence on disk; it checks that
   the **resulting proposal text itself** cites a survey path
   (`docs/issue-[0-9]+/reports/[\w-]+/survey\.md`), a `scout-brief`
   reference, or a skip phrase, scoped to proposals whose path contains
   `content-design`. A proposal could pass core's check (survey.md
   exists) while failing this one (proposal text never names it), and
   vice versa (text names a survey path that isn't actually on disk).
   Not equivalent to core's file-existence check.

3. **devrel** (`phase-order-gate.sh`, 109 lines) — same shape as core's
   proposal-side check (survey.md sibling-existence gate on the same
   `docs/issue-<n>/proposals/*.md` surface), but keyed to
   `docs/issue-<n>/reports/devrel/survey.md`. Given core#234's own
   precedent of deliberately NOT generalizing the role, core's gate
   never fires meaningfully for a devrel proposal (it would check the
   wrong, `implementation`-scoped path). Zero actual coverage today.

4. **incident-response** (`order-gate.sh`, 250 lines) — requires BOTH
   `current-state-survey.md` AND `scout-brief.md` to exist (or a
   section-scoped skip-record heuristic in the survey), gated on
   `docs/issue-<n>/proposals/incident-response*.md`. Core's gate checks
   only a single survey file. Additive (two-file precondition, tighter
   skip-detection than core's whole-file substring scan).

5. **interaction-design** (`stage-order-gate.sh`, 269 lines) — checks
   BOTH surfaces: first-write of `docs/issue-<n>/proposals/*.md` requires
   survey+scout-brief; any write to
   `docs/issue-<n>/reports/interaction-design.md` (phase-2 record)
   requires a proposal to already exist. Maintains a `.status.json`
   cache. Core's gate covers neither the two-file precondition nor the
   record-side check.

6. **issue-retrospective** (`proposal-order-gate.sh`, 165 lines) — gates
   a **different surface entirely**: the phase-2 record write
   (`docs/issue-<n>/reports/issue-retrospective.md`), by reading the
   subject's own phase-1 proposal off disk and requiring it to name a
   survey path plus (scout-brief path or explicit skip). Core's gate
   never inspects the phase-2 record surface. Not equivalent.

7. **security-threat-model** (`sequence-gate.sh`, 137 lines) — same
   shape as devrel: proposal-side survey.md existence check, scoped to
   `docs/issue-<n>/reports/security-threat-model/survey.md`, on proposals
   matching `*security-threat-model*.md`. Same zero-actual-coverage
   finding as devrel (#3), for the same reason.

## Finding

None of the 7 is covered by core's current gates as actually written.
Two (devrel, security-threat-model) are mechanically identical in shape
to core's proposal-side survey check but target a role core's hardcoded
path never checks — under core#234's own established precedent (deliberate
non-generalization), that is a real coverage gap, not decoration. The
other five (architecture, content-design, incident-response,
interaction-design, issue-retrospective) are additionally substantively
additive: extra required files, extra gated surfaces (phase-2 record),
or a different verification mechanism (text-citation vs. file-existence).

This points toward all 7 being dispositioned `promoted`, each as its own
role-scoped core hook mirroring its source rulebook's existing script
(same non-generalization precedent core#234 already set — no `${CLAUDE_ROLE}`
templating), with allow/refuse/empty-state tests per gate.

## Write set expected for phase 2

- `core/hooks/*-gate.sh` — up to 7 new gate scripts (one per candidate,
  role-scoped, mirroring the sweep's per-candidate table)
- `core/hooks/hooks.json` — wire the new gates into the existing
  `PreToolUse` array
- `tests/test_*.py` — allow/refuse/empty-state cases per promoted gate
- `docs/issue-237/reports/implementation.md` — disposition table + git
  diff file list (the delivery record)

No rulebook file is touched (source scripts are read-only references,
fetched live for comparison only).
