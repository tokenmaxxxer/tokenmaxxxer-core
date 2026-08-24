---
issue: 285
role: implementation
loop_state: landed
upstream:
  - path: docs/issue-282 (survey-order-gate precedent, same defect class)
    sha: same-commit
code_under_review:
  - core/hooks/record-shape-gate.sh
  - tests/test_promoted_hooks.py
commit_sha: same-commit
type: fix
breaking: "false"
verdict: pass
---

# issue-285 — implementation record

## What was done

Extended `core/hooks/record-shape-gate.sh`'s hardcoded implementation-role
check (`docs/issue-<n>/reports/implementation.md` writes) with a trivial-diff
exemption, per the issue's scope:

- Added `_workspace_diff_is_trivial(root)`: runs `git -C <root> diff HEAD
  --numstat` and classifies the current workspace diff as trivial when it is
  docs-only (every changed path starts with `docs/`) or totals `<=5` changed
  lines (added+deleted summed across all files). Any git failure (no HEAD
  yet, git missing, unreadable root) makes the size unknowable and is treated
  as **not** trivial — the full-record floor is never silently skipped when
  the check can't run.
- `breaking:` frontmatter key: no longer in the required set when the diff
  is trivial (defaults false, per the issue text).
- `## What did not work` heading: no longer mandatory-by-literal-heading
  when the diff is trivial, provided the record states elsewhere that there
  was nothing to report (matched via a small phrase set: "nothing to
  report", "nothing went wrong", "no issues", or a bare "None." line) — some
  acknowledgment stays required; only the fixed heading name is relaxed.
- `code_under_review:`, `loop_state:`, `type:`, `verdict:` stay mandatory
  unconditionally. The pre-existing conditional check requiring a separate
  rationale heading when a record signals it departed from its approved
  phase-1 plan is untouched — both per "Full requirement unchanged above
  that floor" in the issue.

Extended `tests/test_promoted_hooks.py` with 3 new cases (a real git repo
with a committed HEAD, since the trivial check reads `git diff HEAD`):
allow on a trivial diff missing `breaking:`/the heading but stating "nothing
to report"; deny on a trivial diff whose record states nothing at all (no
acknowledgment survives the exemption); deny on a non-trivial (>5 line) diff
still missing `breaking:` (regression guard, matches the issue's acceptance
bullet verbatim).

## Why

Same class as core#282 (survey-order-gate): a flat, size-blind record-shape
requirement makes a 1-3 line docs fix pay the same full-record tax as a
large change. The issue explicitly scoped the fix narrowly — only
`breaking:` and the literal heading relax, and only below a docs-only/`<=5`
line floor — to keep the gate's non-advisory stance and its core fields
(`code_under_review:`/`loop_state:`/`type:`/`verdict:` plus some "nothing
went wrong" acknowledgment) intact. `git diff HEAD --numstat` was chosen
over sizing the record write itself, because the record documents a code
change elsewhere in the tree, not itself — `record-fields-gate.sh` already
reads `git diff --name-only HEAD` from this same root for an unrelated
purpose (suggesting `code_under_review:` values), so `--numstat` against the
same commit reference extends an idiom already accepted in this codebase,
not a new one.

## Upstream basis

- `core/hooks/record-shape-gate.sh` at commit `80fb8c2` (this branch's
  base) — the hardcoded implementation-role check this issue targets.
- `core/hooks/record-fields-gate.sh:331-344` — precedent for a gate reading
  `git diff --name-only HEAD` from the resolved project root, best-effort,
  no gating decision hinging on git succeeding (there: a suggestion only).
  This change extends the same idiom to `--numstat` and does make a gating
  decision on it, defaulting to the stricter (non-trivial) branch whenever
  the read fails.
- `docs/issue-52/proposals/2026-07-31-implementation-domain-norms.md`
  section (b) — the original full-record shape this issue narrows.

## What did not work

None.

## Acceptance evidence

Executed at landing time, this branch, working tree as committed:

```
$ python3 -m pytest tests/test_promoted_hooks.py -q -k record_shape
......                                                                   [100%]
6 passed, 7 deselected in 0.61s
```

(2 pre-existing failures in the same file — `test_proposal_shape_gate_
refuses_missing_sections`, `test_survey_order_gate_refuses_proposal_
without_survey_or_skip` — confirmed present on clean `HEAD` via `git stash`
before this work started; both are issue-282's advisory-demotion of
proposal-shape-gate/survey-order-gate, unrelated to this change, not
regressed by it.)

```
$ bash core/hooks/tests/run-record-shape-gate-tests.sh
...
record-shape-gate (issue-263 fold): 53 passed, 0 failed
```

Unchanged from clean `HEAD` (53/53 before and after) — the config-driven
CHECKERS dispatch this suite covers is untouched by this change, which only
touches the hardcoded implementation-role check above it in the same file.

## Open findings

None.

## Next steps

None — loop_state is terminal (`landed`).

## Skill check

- skill-verdict: implementation-complexity-coupling-management —
  not-applicable: single-function extension of an existing gate script, no
  class/module coupling or cohesion boundary involved
- other mounted skills: not triggered
