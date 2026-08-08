---
subject: issue-66
role: architecture
loop_state: scope-proposed
---

# Current-state survey — role-agnostic rulebook files vs core canon

## Scout skip record

Skipped. This is an internal architecture audit of code already merged into
this repo (implementation PRs #67/#68) plus a component-boundary judgment
call against sibling issue #63 — there is no external product/category to
benchmark against (skip condition: no comparable external field applies to
a retroactive internal ADR judgment on already-implemented repo structure).

## What issue-66 asked for

Four role-agnostic files were duplicated 10–45x across the 43 sibling
rulebook repos with drift already observed: `trailer-gate.sh`,
`record-fields-gate.sh`, `handbook-trigger-gate.sh` (43 copies each),
`parse-check.sh` (10 copies), and `directive.sh` (45 copies, boilerplate +
role-unique mixed). Ask: promote the role-agnostic logic to core canon,
split `directive.sh` boilerplate from role-unique parts, document the
per-rulebook transition path, and propose drift-recurrence detection.

## What already shipped (implementation, PRs #67/#68, merged 2026-07-31)

- `core/hooks/{trailer-gate.sh,record-fields-gate.sh,handbook-trigger-gate.sh}`
  added, parameterized on `CLAUDE_ROLE` (env-injected role identity) instead
  of a baked-in literal. `parse-check.sh` was already canon pre-issue.
- All four registered core-side in `core/hooks/hooks.json` — zero
  per-rulebook `hooks.json` entry needed; the hook fires for every plugin
  install automatically (this repo's approver decision, recorded in the
  issue comment thread).
- `core/hooks/lib/role-directive.sh` factors `directive.sh`'s fixed
  boilerplate (kill-switch case, `CLAUDE_ROLE` guard, opening/closing
  lines) into a sourceable `core_role_directive` function. A rulebook's own
  `directive.sh` shrinks to: shebang + trap/`set -uo pipefail` (kept local —
  a trap inside a sourced function does not catch the sourcing script's own
  abnormal exit) + source line + `core_role_directive` call with the four
  role-unique values.
- `core/hooks/tests/stub-check.sh` added as the drift-recurrence detector:
  absence-based for the four registered gates (any rulebook-local copy of
  those filenames is itself the drift signal, since core now fires them
  globally) and structure-based for `directive.sh` (must match the
  source+call shape; anything else — a case statement, a guard, raw
  output — fails). Wired into `core/hooks/tests/run-all.sh` via
  `run-role-gates-tests.sh`, 16/16 passing.
- One premise mismatch surfaced during the build (documented in
  `docs/issue-66/reports/implementation.md`): `record-fields-gate.sh`'s
  terminal-`loop_state` set had diverged between two sampled rulebooks in a
  way that reads as possibly-intentional per-role semantics, not pure
  copy-paste drift. Resolved via a config knob
  (`RECORD_FIELDS_TERMINAL_STATES`) rather than collapsing to one universal
  answer — this repo has no authority to decide the 43 rulebooks' role
  semantics for them.

## What is still open (out of this repo's write set)

Per-rulebook rollout — removing each of the 43 sibling repos' vendored
copies of the five files and pointing them at core canon — is explicitly
tracked but **not executed** here (PR #68: "no write access from this
repo"). The PR68 body states this rollout is meant to batch with issue-63's
warrant-hunt canon rollout, since both land the same shape of change
(vendored-copy removal + reference-not-vendor pointer) in the same 43
repos.

## Duplication scan coverage (acceptance criterion 1)

`core/hooks/tests/compliance-check.sh` gaining a canon-duplication scan
(the issue's acceptance check) was not part of PR #67/#68's shipped scope
per its own summary — `stub-check.sh` covers detection of *reintroduced*
copies inside a rulebook's own tree, run per-rulebook via
`run-role-gates-tests.sh`, but is a separate script from
`compliance-check.sh`, and is invoked per-rulebook rather than "runnable
against an arbitrary rulebook path" from this repo's own
`compliance-check.sh` as the acceptance text specifies. This is a real gap
against the acceptance criterion as literally written, not a duplication of
already-shipped work — see the proposal for how phase 2 closes it.

## Verdict: is #63 absorbed by #66?

**No.** #63 (promote `warrant-hunter.md` + hunt-cadence definition to core
canon, plus a separate efficiency-protocol redesign for hunt itself —
time/token budgets, sweep structuring, adaptive cadence) is a distinct
component with a distinct payload from #66's four gate scripts +
`directive.sh` split. #66's implementation explicitly treats #63 as a
sibling, not a subset: PR #68 states its 43-repo rollout is meant to
*batch* with issue-63's rollout (same 43-repo touch, same
reference-not-vendor mechanism) for rollout-efficiency reasons, not because
#63's content is contained in #66's diff. #63 remains open with its own
unshipped scope (the measurement step, the efficiency-protocol proposal,
the side-effect analysis of hunt's existing catch classes) that #66's PRs
never touched. Batching the *rollout* of two independent canon promotions
is a scheduling decision, not an absorption of one issue's scope by the
other.
