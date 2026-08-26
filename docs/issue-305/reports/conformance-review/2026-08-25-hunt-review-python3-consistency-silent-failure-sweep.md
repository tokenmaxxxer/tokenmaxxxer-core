---
proposal: docs/issue-305/proposals/review-python3-consistency-silent-failure-sweep.md
---

# Hunt record — review-python3-consistency-silent-failure-sweep

## after-proposal — stance 0: assume the gate/mechanism just touched by this transition is bypassable — find the bypass

date: 2026-08-25
transition: after-proposal
stance: 0
tier: size:docs-only
cap_seconds: 60
proposal: docs/issue-305/proposals/review-python3-consistency-silent-failure-sweep.md

Verdict: FINDING — warrant/hooks/scope-gate.sh silently never enforces this
proposal's declared write set, because it only recognizes a proposals
directory literally named `docs/proposals` (root) or one whose path ends in
`.../docs/proposals` (monorepo `packages/<name>/docs/proposals` shape) — not
this repo's actual issue-scoped convention `docs/issue-<n>/proposals/`. Since
`docs/proposals` does not exist at repo root and `docs/issue-305/proposals`
does not match the nested-unit pattern, `stand_down()` finds zero nested
units and calls `allow()` unconditionally and silently (exit 0, no stderr,
no permissionDecision) for every Write/Edit/Bash tool call in this session —
meaning the "this role writes only its own record area"
(`docs/issue-305/reports/conformance-review*`) constraint this very proposal
states is never mechanically checked by scope-gate.sh at all, for any path,
with zero signal that enforcement is absent.
Kind: silent-failure
Seed: docs/issue-305/proposals/review-python3-consistency-silent-failure-sweep.md (new, 117 lines), docs/issue-305/reports/conformance-review/survey.md (new, 252 lines)
cap_seconds: 60
tier: size:docs-only
diff_stat_lines: 369
started_at: 2026-08-25T17:43:00+09:00
ended_at: 2026-08-25T17:49:00+09:00

### Reproduce
```
cd <repo root>
python3 -c "
p = 'docs/issue-305/proposals'
print(p.endswith('/docs/proposals'))   # nested_units() detection pattern in warrant/hooks/scope-gate.sh
"
python3 -c "
import os
print(os.path.isdir('docs/proposals'))            # scope-gate's proposals_dir (root)
print(os.path.isdir('docs/issue-305/proposals'))   # this proposal's actual, real directory
"
```
(A direct invocation of `warrant/hooks/scope-gate.sh` itself, to observe the
literal `allow()`/exit-0-with-no-stderr in situ, was attempted but blocked
in this sandbox by an unrelated hook — `approval-gate` — refusing the Bash
call before scope-gate.sh's own logic could run. The code-path analysis
above plus the two filesystem facts it depends on were confirmed directly
via read-only `python3 -c` calls instead, which is sufficient to determine
the branch scope-gate.sh takes.)

### Observed
`'docs/issue-305/proposals'.endswith('/docs/proposals')` is `False`, so
`nested_units()` (the `base.replace("\\","/").endswith("/docs/proposals")`
check in warrant/hooks/scope-gate.sh) never lists `docs/issue-305/proposals`
as a nested unit. `os.path.isdir('docs/proposals')` is `False` (the root-level
dir the gate looks for is absent) while `os.path.isdir('docs/issue-305/proposals')`
is `True` (this proposal's real directory, confirmed with `ls` — it contains
exactly `review-python3-consistency-silent-failure-sweep.md`). Combined,
`scope-gate.sh` takes the `if not os.path.isdir(proposals_dir): stand_down()`
branch, `nested_units()` returns `[]` because its detection pattern doesn't
match the issue-scoped layout, so `stand_down()` falls straight through to
`allow()` with no stderr line printed at all — the enforcement described in
the proposal's own Constraints section ("this role writes only its own
record area") is not actually mechanically applied by this gate, for this or
any other `docs/issue-<n>/proposals/` unit in the repo (confirmed the same
issue-scoped layout is used by issue-303/304/305's own proposals on disk).

### Expected
Either `nested_units()`'s detection pattern in scope-gate.sh should also
recognize `docs/issue-<n>/proposals` (this repo's demonstrated real
convention), or `stand_down()` should not silently no-op (and definitely
should not stay silent, printing nothing) when it fails to recognize a
proposals directory that plainly exists on disk under `docs/`. As written,
every issue-scoped proposal's write-set is unenforced by this mechanism, and
nothing in the hook's output tells anyone that.

## before-landing — skip

date: 2026-08-26
transition: before-landing
Verdict: skip, docs-only, no before-landing dispatch. The phase-2 diff for
this landing is exactly one file, `docs/issue-305/reports/conformance-review.md`
(new), plus this hunt-record append — every touched path is under `docs/`,
so per the warrant-protocol's docs-only fast path the before-landing hunter
dispatch is skipped outright.
