files:
  - core/hooks/arch-sequence-gate.sh
  - core/hooks/content-design-phase1-basis-gate.sh
  - core/hooks/devrel-phase-order-gate.sh
  - core/hooks/incident-response-order-gate.sh
  - core/hooks/interaction-design-stage-order-gate.sh
  - core/hooks/issue-retrospective-proposal-order-gate.sh
  - core/hooks/security-threat-model-sequence-gate.sh
  - core/hooks/hooks.json
  - tests/test_ordering_gates_237.py
  - docs/issue-237/reports/implementation.md

## Request

Per on-the-record's ordering-norm sweep (`docs/reports/ordering-norm-sweep.md`,
issue on-the-record#1753, PR #1754), 7 more rulebook hooks were
reclassified `promote` — ordering/sequence gates with zero domain
content, same filename shape as core#234's already-promoted trio.
Disposition each of the 7 as `covered-by-core` (named covering core gate
+ equivalence argument) or `promoted` (new core hook + tests), promoting
first — rulebook-side removal stays out of scope, no rulebook file is
touched.

## Constraints

- No rulebook file modified; `git diff` may only touch `core/`, `tests/`,
  `docs/issue-237/`.
- Each disposition needs a real equivalence argument, not an assumption —
  the survey (`docs/issue-237/reports/implementation/survey.md`) already
  read all 7 source scripts in full and compared them against core's
  existing `survey-order-gate.sh`.
- Promoted gates need allow/refuse/empty-state tests runnable under the
  repo's fast tier (`python3 -m pytest tests/ -q`), matching
  `tests/test_promoted_hooks.py`'s existing subprocess pattern.
- bash 3.2 target, fail-closed, deny-only conventions already governing
  every `core/hooks/*-gate.sh` apply unchanged.
- all-7-covered-by-core is a valid outcome per the issue's stated empty
  state — but the survey's finding does not support it here.

## Rationale

Considered dispositioning all 7 `covered-by-core`, on the theory that
core's `survey-order-gate.sh` already promotes "the same ordering norm"
(contract v3 s19 survey-before-proposal) and the 7 candidates are just
role-specific restatements of that one norm. Rejected: core's gate
hardcodes its survey path to `docs/issue-<n>/reports/implementation/survey.md`
— a deliberate, previously-considered-and-rejected choice (core#234's own
Rationale explicitly declined to generalize this to `${CLAUDE_ROLE}`).
None of the 7 candidates target the `implementation` role; core's gate
literally never inspects their survey path, so it provides zero actual
coverage for any of them today. Treating "same abstract norm" as
equivalence would contradict the very precedent that makes core's
current gate narrow by design, and would leave a real, exercisable gap
(a devrel or architecture proposal written with no survey on disk passes
core's gate silently).

Considered generalizing `survey-order-gate.sh` itself into one
role-parameterized `ordering-norm-gate.sh` (the sweep report's own
suggested core target, "fold into an existing core phase-order gate")
covering all 7 roles' survey-before-proposal check in a single file.
Rejected for this issue: 5 of the 7 candidates (architecture,
content-design, incident-response, interaction-design,
issue-retrospective — see survey items 1, 2, 4, 5, 6) check something
beyond a bare survey-before-proposal sibling-file test — an extra
required file (scout-brief.md), a second gated surface (the phase-2
record write), or a different verification mechanism entirely
(text-citation instead of file-existence). A single generalized proposal
gate would silently drop that behavior for those 5, which is a real
regression relative to what their source scripts already do — not
behavior-preserving promotion. Per-role promoted scripts (mirroring
core#234's own "verbatim source, path/role-scoped" approach) keep every
candidate's actual check intact.

## What will be done

1. For each of the 7 candidates, promote its source script verbatim into
   `core/hooks/` under a `<rulebook-short-name>-<hook-name>.sh` filename,
   changing only the `gate-lib.sh` source path to the one-level-up form
   every existing `core/hooks/*-gate.sh` already uses (same adjustment
   core#234 made).
2. Add all 7 new gate scripts to `core/hooks/hooks.json`'s existing
   `PreToolUse` array (no new `UserPromptSubmit` directives — none of the
   7 source repos ship a paired directive script in the sweep's table).
3. Write `tests/test_ordering_gates_237.py`: one allow case, one refuse
   case, and one empty-state case per promoted gate (21 cases total),
   invoking each script as a subprocess against a temp git tree,
   matching `tests/test_promoted_hooks.py`'s pattern.
4. Write `docs/issue-237/reports/implementation.md` with the required
   7-row disposition table (all `promoted`, each naming its new
   `core/hooks/*.sh` file and the equivalence/non-equivalence argument
   from the survey) and the `git diff` file list.
5. Run `python3 -m pytest tests/ -q` once before committing to confirm
   the new tests pass.

## Out of scope

- Rulebook-side removal of the 7 source files from their respective
  rulebook repos — explicitly deferred per the issue text.
- Folding the 7 into one generalized `ordering-norm-gate.sh` (see
  Rationale) — a possible follow-up once role-parameterization itself is
  in scope for a future issue.
- Any change to `core/hooks/survey-order-gate.sh`,
  `proposal-shape-gate.sh`, or `record-shape-gate.sh` (core#234's
  trio) — this issue adds new gates, it does not touch the existing
  ones.
- Any change to `core/hooks/lib/gate-lib.sh` — the survey found all 7
  source scripts use only functions it already exports (same functions
  core#234's trio already relies on).

## How you'll know it worked

- `git diff main...HEAD` (once landed) touches only paths under `core/`,
  `tests/`, and `docs/issue-237/`.
- `python3 -m pytest tests/test_ordering_gates_237.py -q` passes,
  exercising each of the 7 promoted gates' allow, refuse, and
  empty-state cases (21 cases).
- `docs/issue-237/reports/implementation.md` carries the 7-row
  disposition table and the git diff file list, satisfying both
  acceptance checks verbatim.
- `core/hooks/hooks.json` remains valid JSON
  (`python3 -m json.tool core/hooks/hooks.json`) and lists all 7 new gate
  scripts under `PreToolUse`.
