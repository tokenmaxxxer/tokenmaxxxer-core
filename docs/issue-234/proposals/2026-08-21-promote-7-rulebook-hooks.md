files:
  - core/hooks/proposal-shape-directive.sh
  - core/hooks/proposal-shape-gate.sh
  - core/hooks/record-shape-directive.sh
  - core/hooks/record-shape-gate.sh
  - core/hooks/survey-order-directive.sh
  - core/hooks/survey-order-gate.sh
  - core/hooks/hooks.json
  - tests/test_promoted_hooks.py

## Request

Per on-the-record#1746's audit (docs/reports/rulebook-hook-audit.md on
tokenmaxxxer/on-the-record main), 7 hook bindings classified `promote`
encode role-handoff contract v3 norms rather than role-specific
invariants. Promote them into `core/hooks/` and wire `core/hooks/hooks.json`
to bind them for every session, with behavior-equivalence tests. Promote
FIRST — no rulebook file is touched this issue.

## Constraints

- No rulebook file modified — `implementation-rulebook`'s
  `proposal-shape/`, `record-shape/`, `survey-order/` plugin dirs are
  read-only sources for this issue, never write targets.
- `git diff` may only touch `core/` and `tests/` (acceptance #2).
- Promoted behavior must be equivalent to the rulebook source, not merely
  similar — allow/refuse cases per gate, matching what the source script
  already does.
- bash 3.2 target, fail-closed, deny-only conventions already governing
  every existing `core/hooks/*-gate.sh` file apply unchanged.

## Rationale

Considered generalizing `record-shape-gate.sh`/`survey-order-gate.sh`'s
hardcoded `docs/issue-<n>/reports/implementation.md` /
`.../implementation/survey.md` target paths to `${CLAUDE_ROLE}` at
promotion time (mirroring how `record-fields-gate.sh` already
role-parameterizes its own record path), so every role's phase-1/phase-2
artifacts would be covered, not just `implementation`'s. Rejected: the
acceptance bar for this issue is behavior EQUIVALENCE to the rulebook
source (before/after diff test), not behavior expansion — and the
audit's own promote note explicitly says "no per-role parameterization
needed" for these rows, because the two-phase proposal/record artifact
shape these gates check is a real, narrower thing than "the contract
applies to every role": today only `implementation` produces a
`docs/issue-<n>/proposals/*.md` + `docs/issue-<n>/reports/implementation.md`
pair in the two-phase shape these gates parse. Widening scope to other
roles is a design decision belonging to whichever future issue actually
extends the two-phase flow to another role, not a promote-first
migration whose job is copying working checks into core unchanged.

Also considered adding the 6 promoted scripts to
`core/hooks/tests/run-all.sh`'s bash-harness suite instead of a new
top-level `tests/*.py` file (matching how `record-fields-gate.sh` etc.
are tested). Rejected: the issue's frozen scope line names `core/hooks/`,
`core/hooks/hooks.json`, and `tests/` only — `core/hooks/tests/` is a
distinct directory outside that list, and editing `run-all.sh` (also
outside the list) to invoke a new suite would violate acceptance #2's
git-diff-scope check. A `tests/*.py` pytest file, runnable directly via
`python3 -m pytest tests/test_promoted_hooks.py -q`, is both in-scope and
an existing convention in this repo (`tests/test_side_effect_round.py`,
`tests/test_silent_failure_repros.py`).

## What will be done

1. Fetch the 6 rulebook source files verbatim from
   `tokenmaxxxer/implementation-rulebook` (`proposal-shape/hooks/{directive.sh,proposal-shape-gate.sh}`,
   `record-shape/hooks/{directive.sh,record-shape-gate.sh}`,
   `survey-order/hooks/{directive.sh,survey-order-gate.sh}`) and place
   them at `core/hooks/{proposal-shape,record-shape,survey-order}-directive.sh`
   and `core/hooks/{proposal-shape,record-shape,survey-order}-gate.sh`,
   changing only the `gate-lib.sh` source path from the rulebook's
   two-levels-up form to the one-level-up form every existing
   `core/hooks/*-gate.sh` file already uses (survey finding: a file
   living directly in `core/hooks/` is one level from `core/`, not two).
2. Add a `UserPromptSubmit` array to `core/hooks/hooks.json` binding the
   3 new `*-directive.sh` scripts (first `UserPromptSubmit` entry in this
   file), and add the 3 new `*-gate.sh` scripts to the existing
   `PreToolUse` array alongside the current 6 hooks.
3. Write `tests/test_promoted_hooks.py`: for each of the 3 promoted
   gates, one allow case and one refuse case invoking the gate script as
   a subprocess (matching `tests/test_side_effect_round.py`'s existing
   subprocess pattern), plus an empty-state case per gate (no
   proposal/record staged passes through silently) confirming the
   acceptance's stated empty-state requirement.
4. Run `python3 -m pytest tests/test_promoted_hooks.py -q` once before
   committing to confirm the new tests actually pass against the
   promoted scripts.

## Out of scope

- Rulebook-side removal of the 6 promoted files from
  `implementation-rulebook` — explicitly deferred per the issue text
  ("no enforcement gap; removal is a later phase").
- Generalizing the record/survey-order target paths beyond
  `implementation` (see Rationale).
- The `customer-support` -> `record-fields-gate.sh` row — already done,
  no file changes needed, noted in the survey only.
- Any change to `core/hooks/lib/gate-lib.sh` — the survey confirmed the 3
  gate scripts use only functions it already exports.

## How you'll know it worked

- `git diff main...HEAD` (once landed) touches only paths under `core/`
  and `tests/`.
- `python3 -m pytest tests/test_promoted_hooks.py -q` passes, exercising
  each of the 3 promoted gates' allow, refuse, and empty-state cases.
- `core/hooks/hooks.json` remains valid JSON
  (`python3 -m json.tool core/hooks/hooks.json`) and lists all 3 new
  directive scripts under `UserPromptSubmit` and all 3 new gate scripts
  under `PreToolUse`.
