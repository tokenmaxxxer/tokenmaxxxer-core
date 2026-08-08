---
status: proposed
subject: issue-142
files:
  - warrant/hooks/scope-gate.sh
  - warrant/hooks/hunt-guard.sh
  - warrant/hooks/state.sh
  - warrant/hooks/hunt-state.sh
  - warrant/hooks/directive.sh
  - terse/hooks/terse.sh
  - scout/hooks/directive.sh
  - core/hooks/tests/run-gate-lib-tests.sh
  - core/hooks/tests/run-gh-guard-tests.sh
  - core/hooks/tests/run-approval-gate-tests.sh
  - core/hooks/tests/run-board-gate-tests.sh
  - core/hooks/tests/compliance-check.sh
---

## Request

Issue #142: core fixed four defect classes (C1 fail-open kill-switch idiom,
C2 runtime mktemp in a gate path, C3 gates blind to Bash-tool writes, C4 the
`mktemp -d` test footgun) and canonized the replacements, but nothing
enforces the canon, so each fix decays back into the fleet. Sweep the
pattern out of core's own plugins and its own test harness, and extend
`compliance-check.sh` so a re-introduced occurrence of any of these four
patterns fails the check and names the canonical replacement.

## Constraints

- This working tree holds only the core repo (core/freelunch/scout/terse/
  warrant plugins). The 43 rulebook repos and C2/C3/C5's specific named
  instances (erm-order-gate.sh, contributing-factors-gate.sh,
  survey-order-gate.sh, 9 repos' install.sh) live in separate repositories
  not reachable from this write set — out of scope for this proposal.
- Every gate/hook this proposal touches must keep its existing observable
  behavior identical on every currently-passing test, and pass
  `bash -n` plus its own repo's `run-*-tests.sh`/`parse-check.sh` after the
  change.
- The extended compliance-check.sh must not start flagging any of core's
  own already-migrated, already-compliant gates (false positives break the
  "make the canon enforceable" goal as surely as missed detections do).

## Rationale

**Extend `compliance-check.sh` in place, rather than write a separate new
canon-check script for C2-C4.** A second script would re-derive the same
file-walking and hooks.json-registration-scoping logic
compliance-check.sh already has (issue-78's fix for scanning by wiring, not
filename glob). The issue's own fix direction offers "extend ... (or a new
canon check)" — extending keeps one canon entry point for a rulebook's CI to
invoke, instead of two scripts a rulebook would have to wire in separately
and keep in sync.

**Fix the survey-discovered hooks.json-less scanning gap narrowly (fall
back to a one-level `*.sh` scan only when no hooks.json exists at all),
rather than broaden registration-scoping generally.** A general broadening
(recurse into any `.sh` regardless of registration) reintroduces the
issue-78 bug from the opposite direction — flagging scripts nobody wired to
anything. The narrow fallback only fires for a bare tree with no
hooks.json to read (the case an existing, already-committed test fixture
exercises and was — confirmed via `git stash` before any change here —
already failing on `main` for this exact reason).

## What will be done

- **C1 sweep**: replace the hand-rolled `case "${X_OFF:-}" in
  ""|0|false|no|off) ;; *) exit 0 ;; esac` idiom in
  `warrant/hooks/{scope-gate,hunt-guard,state,hunt-state,directive}.sh`,
  `terse/hooks/terse.sh`, and `scout/hooks/directive.sh` with the canonical
  guarded-source + `gate_trap_fail_closed` + `gate_kill_switch_active` call
  already used by core's own `gh-guard.sh`/`directive.sh`/etc. The last two
  files (warrant's directive.sh, scout's directive.sh) carry the identical
  bug but are not in the issue's enumerated list; included because the
  issue's acceptance criterion is "zero occurrences ... across core" and a
  repo-wide grep found them live.
- **C4 sweep**: convert the remaining raw `mktemp -d` call sites in
  `run-gate-lib-tests.sh` (4), `run-gh-guard-tests.sh` (1),
  `run-approval-gate-tests.sh` (1), `run-board-gate-tests.sh` (1) to the
  canonical `mktd` helper from `_tmp.sh`, sourcing `_tmp.sh` in the two
  files that don't yet.
- **Structural enforcement**: add three checks to `compliance-check.sh`
  alongside its existing C1 check — a gate calling `mktemp` in its own
  request-time path (C2), a Write/Edit-only gate that never mentions "Bash"
  anywhere and has no `gate_bash_write_targets` coverage (C3), and (as a
  scanning-scope fix, not a new pattern check) a fallback so a directory
  with no `hooks.json` is still scanned one level deep instead of silently
  reading as "nothing to check." Each failure message names the offending
  file and the canonical replacement (`gate_kill_switch_active`,
  in-memory stdin/heredoc instead of a scratch file, `gate_bash_write_targets`,
  or `mktd`).
- C2 and C3 checks are added to compliance-check.sh's logic but have no
  live instance to fix in this repo (surveyed and confirmed clean) — the
  check exists so a future regression, here or in a rulebook that runs this
  script, is caught mechanically rather than by another manual sweep.
- Re-run every existing test suite the touched files feed
  (`run-gate-lib-tests.sh`, `run-gh-guard-tests.sh`,
  `run-approval-gate-tests.sh`, `run-board-gate-tests.sh`,
  `run-role-gates-tests.sh`, `run-stub-canon-forms-tests.sh`,
  `run-compliance-scan-scope-tests.sh`, both plugins' `parse-check.sh`) to
  confirm zero regressions and that the previously-failing
  compliance-check fixture case now passes.

## Out of scope

- The 43 rulebook repos themselves — not present in this working tree.
- C2's and C3's specific named external instances (erm-order-gate.sh,
  contributing-factors-gate.sh, survey-order-gate.sh) and C5 (install.sh
  masking update failure in 9 repos) — none exist in this repo.
- Any change to compliance-check.sh's existing C1/gate-lib-source checks
  beyond what's needed to add the three new checks and the scanning-scope
  fallback.
- Wiring compliance-check.sh into any rulebook's own CI — that is each
  rulebook's own change, once it pulls this updated core.

## How you'll know it worked

- `grep -rn '\*) exit 0 ;;' --include='*.sh' .` in this repo returns only
  test-fixture literals and the explanatory comment in gate-lib.sh/
  compliance-check.sh — no live hook uses the idiom.
- `grep -rln 'mktemp -d' --include='*.sh' .` returns only `_tmp.sh` (the
  definition) and `deny-only-check.sh`'s comment.
- `bash core/hooks/tests/compliance-check.sh core/hooks`,
  `... warrant/hooks`, and `... scout/hooks`/`... terse/hooks` (where a
  hooks.json exists) all report every gate "ok" with zero FAILs.
- Every `run-*-tests.sh` under `core/hooks/tests/` and both plugins'
  `hooks/tests/parse-check.sh` exit 0 with their existing pass counts
  unchanged or higher (the previously-failing compliance-check fixture case
  now passes, raising `run-gate-lib-tests.sh`'s count from 57/1 to 58/0).
- A synthetic fixture gate containing `mktemp` in its own body, or matching
  Write/Edit/MultiEdit with no Bash mention and no `gate_bash_write_targets`,
  run through `compliance-check.sh`, is flagged FAIL with a message naming
  the canonical replacement.
