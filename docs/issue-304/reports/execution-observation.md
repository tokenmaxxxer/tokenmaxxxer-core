---
issue: 304
role: execution-observation
loop_state: landed
upstream:
  - path: issue-304/implementation (PR #307, commit e9b4299b57e41fec5cbe1484a8f754937efd6472)
    sha: e9b4299b57e41fec5cbe1484a8f754937efd6472
  - path: docs/issue-304/reports/implementation.md
    sha: e9b4299b57e41fec5cbe1484a8f754937efd6472
subject: PR #307 — propagate gate_kill_switch_active into role-directive.sh, proposal-shape-directive.sh, record-shape-directive.sh, survey-order-directive.sh (F19/F20)
test: core/hooks/tests/run-directive-shape-tests.sh (issue's named gate); cross-checked core/hooks/tests/compliance-check.sh, run-gate-lib-tests.sh, run-role-gates-tests.sh, run-approval-gate-tests.sh
result: passed
assertedBy: execution-observation (independent re-execution against a worktree pinned to PR #307's commit e9b4299, not PR #307's own pasted output)
---

# issue-304 — execution-observation record

## What was done

Independently re-derived and re-executed PR #307's central claims against a
git worktree pinned to its actual commit
(`e9b4299b57e41fec5cbe1484a8f754937efd6472` on `issue-304/implementation`,
still open as of this record), rather than trusting the PR's own narration
or pasted test output.

**1. Helper propagation, read from source.** `git diff` against the PR's
true merge-base (`8db5b856`, not `origin/main`, which has since advanced
with unrelated docs commits from PR #308/#309 and made a naive
`origin/main..e9b4299` diff show spurious deletions) confirms the scoped
change is exactly 6 files, 306 insertions / 25 deletions — matching
`gh pr view 307`'s stat line exactly:

```
core/hooks/lib/role-directive.sh              |   7 +-
core/hooks/proposal-shape-directive.sh        |  10 +-
core/hooks/record-shape-directive.sh          |  10 +-
core/hooks/survey-order-directive.sh          |   9 +-
core/hooks/tests/run-directive-shape-tests.sh |  80 ++++++++++
docs/issue-304/reports/implementation.md      | 215 ++++++++++++++++++++++++++
6 files changed, 306 insertions(+), 25 deletions(-)
```

Read each of the 4 hook files at `e9b4299`: all four now call
`gate_kill_switch_active` (the three top-level scripts source
`core/hooks/lib/gate-lib.sh` via the canonical `||`-guarded line and call
`gate_kill_switch_active "${X_OFF:-}" || exit 0`; `role-directive.sh`
sources it from its own directory and calls
`gate_kill_switch_active "$off_val" || return 0` inside
`core_role_directive`, using `return` since it's a sourced-library
function, not a standalone script). None of the four retains the old
inline `case "$v" in ""|0|false|no|off) ;; *) exit 0 ;; esac` shape. Each
file sources `gate-lib.sh` exactly once — no double-source.

**2. Behavior re-executed live**, both via the new test file and by hand,
against the pinned worktree (not the PR's pasted numbers):

```
$ bash core/hooks/tests/run-directive-shape-tests.sh
--- issue-304: kill-switch drift, executed live ---
ok     proposal-shape-directive.sh: kill-switch unset (empty state) — hook active present
ok     proposal-shape-directive.sh: typo value in $PROPOSAL_SHAPE_OFF keeps hook ACTIVE (was: disabled) present
ok     proposal-shape-directive.sh: exact '1' in $PROPOSAL_SHAPE_OFF disables hook absent
ok     record-shape-directive.sh: kill-switch unset (empty state) — hook active present
ok     record-shape-directive.sh: typo value in $RECORD_SHAPE_OFF keeps hook ACTIVE (was: disabled) present
ok     record-shape-directive.sh: exact '1' in $RECORD_SHAPE_OFF disables hook absent
ok     survey-order-directive.sh: kill-switch unset (empty state) — hook active present
ok     survey-order-directive.sh: typo value in $SURVEY_ORDER_OFF keeps hook ACTIVE (was: disabled) present
ok     survey-order-directive.sh: exact '1' in $SURVEY_ORDER_OFF disables hook absent
ok     role-directive.sh: kill-switch unset (empty state) — hook active present
ok     role-directive.sh: typo value in $IMPLEMENTATION_CYCLE_OFF keeps hook ACTIVE (was: disabled) present
ok     role-directive.sh: exact '1' in $IMPLEMENTATION_CYCLE_OFF disables hook absent
ok     proposal-shape-directive.sh: no hand-rolled '*) exit|return 0 ;;' off-spelling branch (drift guard) absent
ok     proposal-shape-directive.sh: calls gate_kill_switch_active   present
ok     record-shape-directive.sh: no hand-rolled '*) exit|return 0 ;;' off-spelling branch (drift guard) absent
ok     record-shape-directive.sh: calls gate_kill_switch_active     present
ok     survey-order-directive.sh: no hand-rolled '*) exit|return 0 ;;' off-spelling branch (drift guard) absent
ok     survey-order-directive.sh: calls gate_kill_switch_active     present
ok     role-directive.sh: no hand-rolled '*) exit|return 0 ;;' off-spelling branch (drift guard) absent
ok     role-directive.sh: calls gate_kill_switch_active             present

directive-shape: 31 passed, 0 failed
```

31 passed / 0 failed, matching PR #307's claim exactly. The issue's own
Acceptance section demands this exact gate and this exact provenance
("executed-live... for each of the 4 files: typo value keeps the hook
ACTIVE (was: disabled), exact '1' disables") — the table above is the
file-by-file breakdown backing the aggregate count.

Independently, by hand (not via the test harness's own assertions), for
each of the 3 standalone scripts directly:

```
--- core/hooks/proposal-shape-directive.sh ---
[empty] 1 lines
[typo=xyz] 1 lines
[exact=1] 0 lines
--- core/hooks/record-shape-directive.sh ---
[empty] 1 lines
[typo=xyz] 1 lines
[exact=1] 0 lines
--- core/hooks/survey-order-directive.sh ---
[empty] 1 lines
[typo=xyz] 1 lines
[exact=1] 0 lines
```

(1 line = the hook printed its directive text = active; 0 lines =
disabled.) And for `role-directive.sh`, sourced and called directly since
it is a library, not a script:

```
$ CLAUDE_ROLE=implementation bash -c '. core/hooks/lib/role-directive.sh; core_role_directive x y z w' | wc -l
13
$ CLAUDE_ROLE=implementation IMPLEMENTATION_CYCLE_OFF=xyz bash -c '. core/hooks/lib/role-directive.sh; core_role_directive x y z w' | wc -l
13
$ CLAUDE_ROLE=implementation IMPLEMENTATION_CYCLE_OFF=1 bash -c '. core/hooks/lib/role-directive.sh; core_role_directive x y z w' | wc -l
0
```

Empty and typo both print the full 13-line directive (active); exact `1`
prints nothing (disabled). All 4 files independently confirmed: typo
keeps the hook ACTIVE where the pre-fix code disabled it; exact `1` still
disables.

**3. Regression suites cross-checked**, run live rather than trusted from
the PR body:

```
$ bash core/hooks/tests/compliance-check.sh core/hooks
compliance-check: ok — core/hooks/directive.sh
compliance-check: ok — core/hooks/pretooluse-dispatcher.sh
compliance-check: ok — core/hooks/proposal-shape-directive.sh
compliance-check: ok — core/hooks/record-shape-directive.sh
compliance-check: ok — core/hooks/survey-order-directive.sh

$ env -u CORE_BUILD_NOW bash core/hooks/tests/run-gate-lib-tests.sh
... FAIL record-fields-gate.sh: missing §20 fields still denied post-migration want=deny got=allow
... FAIL record-fields-gate.sh: RECORD_FIELDS_GATE_OFF=banana stays active (issue-72 fix) want=deny got=allow
... ok compliance-check.sh: core's own migrated gates pass clean allow
gate-lib: 64 passed, 2 failed

$ bash core/hooks/tests/run-role-gates-tests.sh
role-gates: 83 passed, 0 failed

$ env -u CORE_BUILD_NOW bash core/hooks/tests/run-approval-gate-tests.sh
== 66 passed, 0 failed ==
```

All four numbers match PR #307's pasted test plan exactly (64/2, 83/0,
66/0, compliance-check clean on all 5 hooks.json-wired scripts).

PR #307 additionally claims the gate-lib count "improved from 63/3
pre-fix." This is a claim about a state that no longer exists in the
tree, so it was re-derived rather than taken on faith: checked out the
PR's parent commit (`8db5b856`, verified via `git rev-parse
e9b4299^` to be identical to the PR's actual merge-base with
`origin/main`) into a second worktree and ran the identical command:

```
$ env -u CORE_BUILD_NOW bash core/hooks/tests/run-gate-lib-tests.sh   # at 8db5b856, pre-fix
... FAIL compliance-check.sh: core's own migrated gates pass clean want=allow got=deny
gate-lib: 63 passed, 3 failed
```

Confirmed 63/3 pre-fix, and confirmed which specific assertion flips:
`compliance-check.sh: core's own migrated gates pass clean` goes from
`want=allow got=deny` (pre-fix — 3 of the 4 hooks it scans still carried
hand-rolled kill-switches) to `allow` (post-fix). The other 2 failures
(`record-fields-gate.sh`, both pre-existing) are byte-identical at both
commits — genuinely unrelated to this fix, as PR #307 states.

**4. Operator-frozen constraint check** (systemic scope; no added
overhead/load; no new conflict/stall surfaces; no consumer-tree residue):
the diff is exactly the 6 files above — 4 hook files each gaining one
`||`-guarded `.`-source line plus a one-line helper call (replacing a
5-line inline `case`), one new test file, one new record. No other file
changed. `role-directive.sh` is the shared library every consumer repo's
own `directive.sh` stub sources; fixing it once here is precisely the
"systemic" fix the constraint calls for, and since consumer repos only
*source* this file (never copy it), no residue is left in any consumer
tree. Each hook now does one extra `.`-source of a small, already-loaded
function-only file per invocation — not a new subprocess, not measurable
added load. No new inter-hook conflict surface: `gate-lib.sh` was already
being sourced by `core/hooks/directive.sh`, `scout/hooks/directive.sh`,
and `warrant/hooks/directive.sh` before this PR: the 4 files are being
brought in line with an existing idiom, not introducing a new one.

## Why

Direct source inspection plus independent re-execution (rather than
re-reading PR #307's own text) is the only way this record adds
information beyond restating the PR: the issue's Acceptance explicitly
requires "executed-live... paste real output," and the proposal's Rationale
already declined a separate survey file on the grounds that the subject
here is a closed set of artifacts to cross-check, not a design space —
this record is that cross-check. Re-deriving the "63/3 pre-fix" baseline
from a second worktree (rather than accepting it as asserted) was the one
part of PR #307's claims that pointed at a state no longer present in the
tree; everything else was checkable directly against the commit already
cited.

## Upstream basis

- `issue-304/implementation` (PR #307), commit
  `e9b4299b57e41fec5cbe1484a8f754937efd6472` — the PR is open, unmerged;
  this record observes that exact commit, matched against
  `gh pr view 307 --json headRefOid` at observation time. Per the
  approved proposal's stated fallback, if this commit changes materially
  before this record lands, that is a new basis, not a silent re-read.
- `docs/issue-304/reports/implementation.md` (same commit,
  `same-commit` relative to that commit — cited here as `e9b4299b57e41fec5cbe1484a8f754937efd6472`
  since this record's own commit differs).
- `core/hooks/lib/gate-lib.sh`'s `gate_kill_switch_active`, fixed under
  issue-72 (unchanged by PR #307; this record confirmed its current
  semantics by reading it directly at `e9b4299`, not by trusting either
  PR #307's or issue-304's description of it).

## Open findings

- **Not a finding against PR #307; scope note for a future issue.**
  While confirming no other files in the tree carry the same
  fail-open-on-typo shape, two adjacent files surfaced, neither matching
  F19/F20's actual bug pattern, so neither is filed as a defect here:
  - `freelunch/hooks/freelunch.sh` and `freelunch/hooks/observe.sh` use
    their own hand-rolled `case` (not the shared helper) but are already
    behaviorally correct — their `*)` branch explicitly treats an
    unrecognized value as "not off" (with a stderr warning), matching
    `gate_kill_switch_active`'s fixed semantics. Not a drift instance;
    just not using the shared helper. Out of scope for issue #304, which
    names exactly 4 files.
  - `warrant/hooks/hunt-tier.sh` uses `if [ "${WARRANT_OFF:-}" = "1" ]`
    — an exact-match-only check. This has the opposite shape from
    F19/F20 (it never fails open on a typo; it also never recognizes
    `true`/`yes`/`on` as a valid on-spelling), so it is not the bug this
    issue tracks. Noted for awareness only, not actioned — out of scope
    per the proposal ("any gate or hook code change" is out of scope for
    this role).
- None of the above are blocking or contradict PR #307's claims; no open
  finding against the subject of this record.

## Next steps

None — loop_state: landed. PR #307 remains open pending its own
merge decision, which is outside this role's scope.
