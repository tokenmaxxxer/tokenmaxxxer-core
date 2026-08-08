---
subject: issue-142
---

# Current-state survey — issue #142 fleet drift sweep

Scope note first: this working tree holds only the **core repo** (plugins
`core`, `freelunch`, `scout`, `terse`, `warrant`). The 43 rulebook repos the
issue names are separate repositories not checked out here, so this survey
and the proposal it feeds cover only what is reachable in this tree: C1
inside core's own plugins, C4 inside core's own test harness, and the
structural canon check (compliance-check.sh) that the issue asks be made to
catch C1/C2/C3/C4 wherever they recur, including in a rulebook that runs it.
C2, C3, and C5's *named instances* (erm-order-gate.sh,
contributing-factors-gate.sh, survey-order-gate.sh, the 9 repos' install.sh)
live in rulebook repos outside this tree and are out of scope for this
proposal's write set.

## C1 — old fail-open kill-switch idiom

Confirmed live, by direct read, in:
- `warrant/hooks/scope-gate.sh:23-26`
- `warrant/hooks/hunt-guard.sh:26-29`
- `warrant/hooks/state.sh:12-15`
- `warrant/hooks/hunt-state.sh:24-27`
- `terse/hooks/terse.sh:20-23`

All five carry the exact buggy shape:
`case "${X_OFF:-}" in ""|0|false|no|off) ;; *) exit 0 ;; esac` — the comment
directly above each one correctly *describes* the intended fix (unrecognized
value should stay active) but the code implements the opposite.

A repo-wide grep for the literal `*) exit 0 ;;` idiom additionally found it
in **two files the issue's list omits**:
- `warrant/hooks/directive.sh:17-20` — same plugin, same bug, not in the
  issue's enumerated list but present.
- `scout/hooks/directive.sh:22-25` — a different core plugin, not mentioned
  in the issue at all.

Both meet the acceptance criterion ("zero occurrences of each pattern
across core") so both are in scope for the fix, not just the four+one the
issue names.

`freelunch/hooks/{freelunch,observe}.sh` were checked and are **already
compliant** — they hand-roll the correct semantics directly (treat
unrecognized as not-off) rather than using `gate_kill_switch_active`, which
satisfies the intent even though it doesn't route through gate-lib.sh.

The canonical replacement already exists: `gate_kill_switch_active` in
`core/hooks/lib/gate-lib.sh`, used correctly by `core/hooks/{gh-guard,
handbook-trigger-gate,record-fields-gate,approval-gate,directive,
board-gate,trailer-gate}.sh` via the guarded source line documented at the
top of gate-lib.sh. warrant and terse/scout do not currently source
gate-lib.sh at all (they hand-roll the idiom instead) — the fix adds the
same guarded source line plus `gate_trap_fail_closed` + `gate_kill_switch_active`
call, matching the pattern core's own gates already use.

## C2 — runtime mktemp in a gate path

`risk-management-rulebook/.../erm-order-gate.sh` is a separate repo, not
present here — out of scope for this write set. Checked core's own
PreToolUse-wired gates (`approval-gate.sh`, `board-gate.sh`, `gh-guard.sh`,
`handbook-trigger-gate.sh`, `record-fields-gate.sh`, `trailer-gate.sh`,
warrant's `scope-gate.sh`/`hunt-guard.sh`) for a runtime `mktemp` call in
their own request-time path: none found — all pass their judge payload to
python3 via heredoc/stdin already. No core-repo instance to fix.

## C3 — Bash-write coverage gap

`issue-retrospective-rulebook` and `implementation-rulebook` are separate
repos, not present here — out of scope for this write set. Checked core's
own Write/Edit-scoped gates for Bash-tool blindness: `record-fields-gate.sh`
explicitly documents (comment, lines 133-136) that it punts Bash writes to
board-gate.sh/scope-gate.sh by design — a considered division of labor, not
a gap. `board-gate.sh` and `approval-gate.sh` both branch on `tool_name ==
"Bash"` explicitly. No core-repo instance to fix.

## C4 — mktemp -d test footgun

core's own `core/hooks/tests/_tmp.sh` already ships the canonical `mktd`
helper (issue-57 fix). A repo-wide grep for `mktemp -d` found it already
migrated to `mktd` in `run-approval-gate-tests.sh`, `run-board-gate-tests.sh`,
`run-compliance-scan-scope-tests.sh`, `run-role-gates-tests.sh`,
`run-stub-canon-forms-tests.sh`, `deny-only-check.sh` (comment only) — but
still raw, unmigrated, in:
- `core/hooks/tests/run-gate-lib-tests.sh` — 4 occurrences (lines 291, 322,
  338, 348), never sources `_tmp.sh`.
- `core/hooks/tests/run-gh-guard-tests.sh` — 1 occurrence (line 144), never
  sources `_tmp.sh`.
- `core/hooks/tests/run-approval-gate-tests.sh` — 1 remaining occurrence
  (line 259, a second scratch dir for a stubbed `python3`) even though the
  file already sources `_tmp.sh` and uses `mktd` elsewhere in the same file.
- `core/hooks/tests/run-board-gate-tests.sh` — same shape, 1 remaining
  occurrence (line 432).

## Structural half — compliance-check.sh

`core/hooks/tests/compliance-check.sh` already exists (issue-72) and already
mechanically flags C1 (absence of `gate_kill_switch_active` when a `*_OFF`
var is read) and the gate-lib.sh unguarded-source bug (issue-75). It does
**not** yet check: C2 (runtime `mktemp` in a gate's own path), C3
(Write/Edit-only gate blind to Bash), or C4 (raw `mktemp -d` in a test
script) — the three gaps issue #142 asks be closed so the checker actually
covers all four defect classes, not just one.

Also found, by running the existing test suite before any change: 
`run-gate-lib-tests.sh`'s own "compliance-check.sh: flags a hand-rolled
kill-switch + replace shape" case was **already failing** on `main`
(reproduced via `git stash` before touching anything) — the fixture writes
a bare `fixture-gate.sh` into a temp dir with no `hooks.json`, and
compliance-check.sh's registration-scoped design (issue-78) reads "no
hooks.json" as "nothing to scan" and exits 0 (allow) instead of catching the
fixture. This is a real gap in the canon checker's own reliability,
directly relevant to the issue's "make the canon enforceable" ask, and sits
in the same file the issue already names for extension.

## Alternatives considered (for the proposal's Rationale)

- **Extend `compliance-check.sh` in place** (chosen) vs. **write a new,
  separate canon-check script** for C2-C4: a second script would duplicate
  the file-walking/registration-scoping logic compliance-check.sh already
  has, and the issue explicitly says "extend core/hooks/tests/
  compliance-check.sh (or a new canon check)" — extending in place keeps
  one canon entry point a rulebook wires into CI, instead of two.
- **Fix the hooks.json-less fallback narrowly** (only scan `*.sh` one level
  deep when no `hooks.json` exists at all) vs. **broaden registration
  scoping generally** (e.g. recurse into any `.sh` regardless of
  registration): the broad version reintroduces exactly the issue-78 bug
  compliance-check.sh's registration-scoped design was built to avoid (a
  filename-glob approach missing an oddly-named wired script, or now the
  opposite failure — flagging scripts that were never wired to anything).
  The narrow fallback only activates when there is no hooks.json to read at
  all, which is the fixture/bare-tree case, not the real-plugin case.
