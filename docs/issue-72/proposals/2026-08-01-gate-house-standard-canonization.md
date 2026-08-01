---
subject: issue-72
role: implementation
loop_state: scope-proposed
files:
  - core/hooks/lib/gate-lib.sh
  - core/hooks/lib/gate-lib.py
  - core/hooks/tests/run-gate-lib-tests.sh
  - core/hooks/tests/gate-lib-cases/*
  - core/hooks/tests/compliance-check.sh
  - core/hooks/tests/canon-manifest.txt
  - docs/handbooks/gate-house-standard.md
  - docs/issue-72/reports/implementation.md
---

# Proposal — gate-house standard canonization

Phase 1 proposal only. Nothing below is applied in this phase; it describes
what phase 2 would build/change, pending `APPROVE issue-72/implementation`.
See `docs/issue-72/reports/implementation/survey.md` for the current-state
findings this responds to and `docs/issue-72/reports/implementation/
scout-brief.md` for the comparable-system pass (web search unavailable in
this environment; that brief is assumption-labeled, not sourced).

## Request

A 2026-08-01 audit of the 43 downstream rulebook repos' merged gates found
repo-wide structural defects, not isolated bugs: (1) relative-path anchors
that cannot match an absolute `file_path` (e.g. `^docs/...` against an
absolute path), plus `./`-prefix bypasses, leave gates production-inert in 6+
repos, hidden because tests only exercise relative-path fixtures; (2)
fail-open holes — missing trap-at-top, dead fail-closed code, malformed-JSON
silently allowed through, and a kill-switch that defaults to *disabled* on an
unrecognized value instead of *active* — inconsistent per repo; (3)
`Edit`/`MultiEdit` content reconstruction ignores `replace_all` repo-wide,
`MultiEdit` is often uncovered, and test coverage on this path is near zero;
(4) every gate matches only `Write`/`Edit`-family tool calls, so a
`Bash`-based file write bypasses them entirely; (5) some repos write their
deny-reason JSON to stdout on exit 2 instead of stderr, so the model never
sees why it was denied; (6) `directive.sh`'s dependency on a relative path
into `core` breaks depending on install environment, and README
"ghost-documentation" (describing behavior the code does not actually have)
is widespread. The issue asks for four deliverables: a shared gate library
(`core/hooks/lib/gate-lib.sh` plus a Python helper if needed) that rulebook
gates *reference*, never copy, per the existing `canon-scripts.md`
convention; a standard test harness making the six defect-class cases
(`Edit`/`MultiEdit`/`replace_all`/malformed-JSON/kill-switch/absolute-path)
mandatory; a `stub-check.sh`-style compliance detector that mechanically
finds house-standard violations in a rulebook's own gates; and documentation
of the 43-repo migration path, paired with each repo's own A+ remediation
issue. This issue is an explicit prerequisite: the 43 per-repo remediation
issues will reference this standard, so it must land first.

## Constraints

- Build on existing canon, do not redesign it. `core/hooks/lib/
  role-directive.sh` is the one existing precedent for a genuine sourced
  shared library in this repo (a rulebook's stub sources it and calls one
  function with role-specific arguments) — `gate-lib.sh` follows the same
  shape: functions a rulebook gate sources and calls, not a rewrite of any
  of the seven `core/hooks/*.sh` gates' own control flow.
- Reference, never copy, per `docs/handbooks/canon-scripts.md`'s existing
  clause and the `role-directive.sh` precedent it already generalizes from.
  `gate-lib.sh` and any new test-harness/compliance-detector scripts must be
  added to `core/hooks/tests/canon-manifest.txt` so `stub-check.sh` catches a
  rulebook that vendors a copy instead of sourcing/invoking the canon path —
  the same mechanism that already protects the five files listed there
  today (survey section 9).
- Order dependency: this issue must land (phase 1 approved, phase 2 merged)
  before any of the 43 per-repo A+ remediation issues can cite it as their
  standard. This proposal's phase 2 therefore explicitly excludes touching
  any of the 43 external repos (see "Out of scope").
- Must not break the seven existing `core/hooks/*.sh` gates or their
  passing tests. Survey section 1, 4, and 5 found trap-at-top, stderr-deny,
  and malformed-JSON-deny are already correct and consistent across all
  seven — `gate-lib.sh` codifies these, it does not need to "fix" them, and
  phase 2 must show the existing `run-*-tests.sh` suites still pass
  unchanged (or updated in place, never weakened) after core's own gates are
  migrated to source the library.
- The kill-switch and `replace_all` fixes this survey found live *in core's
  own canon today* (survey sections 2 and 6, not just a hypothetical for the
  43 rulebooks) are real bugs, not merely "gate-lib.sh should prevent this
  going forward" — phase 2's write set therefore necessarily touches the
  affected existing files (`core/hooks/*.sh`) to migrate them onto the fixed
  shared behavior, not only adds new files.

## Rationale

**Rejected alternative 1 — fix each rulebook's path-matching/fail-open bugs
independently, per repo, without a shared library.** This is the status quo
approach and is what produced the drift the issue's audit found in the first
place: `stub-check.sh`'s own header (survey section 9) already documents that
the *previous* pattern — "every rulebook copies `parse-check.sh`/
`stub-check.sh` verbatim and maintains its own copy" — produced 35-38 distinct
content hashes among ~43 nominally-identical files (issue-63's and issue-66's
own surveys, cited in `docs/handbooks/canon-scripts.md`). A per-repo fix
applied 43 times, by 43 different sessions or people, at different times,
regenerates exactly that divergence: repo A's fix for the kill-switch default
will not automatically become repo B's fix, and the next audit two months
later would likely find some repos already re-regressed. A shared library
that repos *reference* (not vendor) means one fix in `core/hooks/lib/
gate-lib.sh` is live for every repo that sources it, the same guarantee
`role-directive.sh` already gives the directive boilerplate today.

**Rejected alternative 2 — ship a linter that flags the six defect classes,
instead of a runtime-loaded shared library.** A pure linter (static analysis
over each rulebook's gate source, no runtime dependency) has real appeal: it
cannot itself introduce a new runtime failure mode, and it matches the
shellcheck-style precedent the scout brief names. It was rejected as the
*primary* mechanism, though kept as a secondary layer (the compliance
detector below), for two reasons grounded in this survey: first, several of
the found defects (survey sections 2 and 6 — the kill-switch default, and
`replace_all` reconstruction) are not just missing checks a linter could flag
from source text; they are logic that must actually *run correctly* at
tool-call time, and a linter cannot substitute for correct runtime behavior,
only detect its absence after the fact. Second, `stub-check.sh` is already
exactly this kind of linter for the five already-promoted files, and its own
existence did not retroactively fix any of the four already-promoted gates'
internal logic — it only stops a *new* vendored copy from reappearing. A
linter-only approach for `gate-lib.sh`'s six defect classes would tell every
one of the 43 rulebooks "you have this bug" without giving them the fixed
code to adopt, which does not remove the ordering-constraint problem the
issue names (the 43 remediation issues need something to *reference*, not
just something that flags what's wrong). The shared library plus a
compliance detector modeled on `stub-check.sh` (linting for un-sourced,
hand-rolled reimplementations of what the library already provides) combines
both: a fix consumers can adopt, and a mechanical check that they did.

**Failure signal, if this proposal turns out wrong**: if, after `gate-lib.sh`
lands and 2-3 of the 43 rulebooks migrate onto it, their own gate tests still
show the same six defect classes reproducing (e.g. a migrated gate's
kill-switch still defaults to disabled on an unrecognized value, or its
`Edit` reconstruction still ignores `replace_all`) — that would mean the
library's functions themselves are wrong or the migration guidance is
unclear, and phase 2's own acceptance criteria (below) would have already
failed before any of the 43 repos got there.

## What will be done (phase 2 only — not applied yet)

### 1. `core/hooks/lib/gate-lib.sh` (+ `gate-lib.py` if the Python payload
logic grows large enough to warrant its own sourced/imported file rather than
inline heredocs, mirroring the heredoc-Python pattern all seven existing
gates already use)

Functions exposed, each addressing one survey-confirmed gap or one
issue-named defect class:

- `gate_kill_switch_active <var-name>` — the fixed kill-switch convention:
  only a recognized off-spelling (`0`, `false`, `no`, `off`, and empty/unset
  staying at whatever the gate's own default is) disables; every other value,
  including an unrecognized one, returns "active." Replaces the `case ... in
  ""|0|false|no|off) ;; *) exit 0 ;; esac` idiom found identically in all
  seven existing gates (survey section 2) with one function the seven core
  gates themselves migrate onto, fixing core's own live bug as part of this
  phase, not just providing it for future rulebook use.
- `gate_trap_fail_closed` — installs the one canonical fail-closed EXIT trap,
  collapsing the two idioms found in survey section 1 (inline trap vs. `__fc`
  function) into one sourced call.
- `gate_normalize_path <root> <path>` — absolute/relative/`./`-prefix
  normalization, generalizing the most defensive of the three techniques
  survey section 3 found (`record-fields-gate.sh`'s realpath-then-
  strip-root), so a rulebook gate gets correct absolute-path scope matching
  by calling one function instead of re-deriving one of the three shapes
  found in core's own gates today.
- `gate_deny <message>` / `gate_allow` — stderr-only deny (exit 2) / allow
  (exit 0), codifying the already-uniform convention from survey section 4.
- `gate_parse_json_or_deny <payload>` — malformed-JSON deny, codifying
  survey section 5's already-uniform convention.
- `gate_reconstruct_write <tool_name> <tool_input> <current_content>` — full
  `Write`/`Edit`/`MultiEdit`/`NotebookEdit` reconstruction, **honoring
  `replace_all`** (`text.replace(o, n)` with no count when `replace_all` is
  true, `text.replace(o, n, 1)` otherwise) and adding `NotebookEdit` cell
  reconstruction, which `record-fields-gate.sh` does not attempt today
  (survey section 6). This is the direct fix for the confirmed
  `record-fields-gate.sh` bug, applied to `record-fields-gate.sh` itself as
  part of migrating it onto the library, not left as a "the library will do
  this correctly for new adopters" gap.
- `gate_bash_write_targets <command>` — the token-scan-over-command-string
  technique already used by `approval-gate.sh`/`board-gate.sh` (survey
  section 7), extracted so `record-fields-gate.sh` (which explicitly does not
  cover Bash writes today, per its own comment) and any rulebook gate can
  adopt the same Bash-write coverage `approval-gate.sh`/`board-gate.sh`
  already have, closing the specific bypass survey section 7 found.

### 2. Standard test harness

`core/hooks/tests/run-gate-lib-tests.sh` plus a `core/hooks/tests/
gate-lib-cases/` directory of fixture pairs (input tool-call JSON, expected
allow/deny + stderr substring). Six case groups are made **mandatory** — a
harness run that does not exercise all six fails the harness itself, not
just the individual gate:

1. `Edit` with `replace_all: true` against a multiply-occurring
   `old_string`.
2. `MultiEdit` with a mix of `replace_all: true`/`false` edits in one call.
3. Malformed JSON payload (truncated, non-object, and non-UTF8 cases).
4. Kill-switch set to an unrecognized value (e.g. `banana`) — must assert
   the gate stays **active**, the inverse of today's behavior (survey
   section 2).
5. Absolute `file_path` matching the same scope a relative-path fixture
   already matches, plus a `./`-prefixed variant.
6. A `Bash`-tool file write to the same target a `Write`-tool call would hit,
   asserting equivalent deny/allow.

Every existing `run-*-tests.sh` (`run-approval-gate-tests.sh`,
`run-board-gate-tests.sh`, `run-gh-guard-tests.sh`,
`run-role-gates-tests.sh`) is re-run unchanged as part of phase 2's
acceptance check (see below) to confirm the `gate-lib.sh` migration did not
regress any currently-passing assertion.

### 3. Compliance detector

`core/hooks/tests/compliance-check.sh`, modeled directly on
`core/hooks/tests/stub-check.sh`'s existing two-mode pattern (survey section
9): absence-based checks for anything fully replaceable by a `gate-lib.sh`
call (e.g. a rulebook gate containing its own inline kill-switch `case`
statement instead of calling `gate_kill_switch_active` is flagged the same
way a vendored copy of `trailer-gate.sh` is flagged today), plus a
structural check in the shape `stub-check.sh` already uses for
`directive.sh` (grep for "sources `gate-lib.sh`," "calls the expected
`gate_*` functions," "no non-stub control-flow lines regrown locally") for
gates that legitimately need role-specific logic around the shared calls.
`gate-lib.sh` and this detector script are both added to `core/hooks/tests/
canon-manifest.txt` so `stub-check.sh` itself catches a rulebook vendoring a
copy of either, per the Constraints section's reference-not-copy
requirement.

### 4. Migration path documentation

`docs/handbooks/gate-house-standard.md`: what `gate-lib.sh` provides, the
six mandatory test cases, how `compliance-check.sh` is invoked (mirroring
`stub-check.sh`'s existing "resolved against core's own plugin install root,
scan target is the rulebook's own directory" invocation model, per
`docs/handbooks/canon-scripts.md`/`role-gates-tests.md` precedent), and a
per-repo checklist: (1) run `compliance-check.sh` against the rulebook's
current gates and record the violation list, (2) migrate each flagged gate
to source `gate-lib.sh` and call the relevant `gate_*` functions instead of
its own hand-rolled logic, (3) re-run the rulebook's own gate tests plus the
new mandatory six-case suite, (4) re-run `compliance-check.sh` clean, (5)
file that rulebook's own A+ remediation issue referencing this standard's
handbook and citing the now-clean `compliance-check.sh` output as evidence.
This document is what each of the 43 A+ remediation issues is expected to
link to, satisfying this issue's fourth requirement and the stated ordering
constraint.

## Out of scope

- No `gate-lib.sh` implementation, test harness, or compliance detector code
  ships in this PR — phase 1 is proposal-only, per contract v3 s19.
- No changes to any of the 43 external rulebook repos. This repo's role has
  no write access to them (same constraint issue-66's and issue-69's reports
  already recorded for structurally identical asks) — the migration path
  document is the deliverable for those repos, not an executed migration.
- No APPROVE, self-approval, or execution-phase work of any kind happens in
  this PR. This proposal stops at requesting `APPROVE issue-72/
  implementation`.
- No retroactive fix is applied to any of the 43 rulebooks' already-merged
  gates found broken by the audit — this issue is explicitly the
  prerequisite standard, not the remediation itself; each rulebook's own A+
  issue (paired per this proposal's migration doc) does that work.
- No change to `core/hooks/hooks.json`'s registration list in this phase
  beyond what migrating the seven existing gates onto `gate-lib.sh` requires
  (their registrations stay the same scripts at the same paths; only their
  internal implementation sources the library).

## How you'll know it worked

- `core/hooks/lib/gate-lib.sh` exists, is sourced (not copied) by all seven
  `core/hooks/*.sh` gates, and every one of the seven still passes its
  existing `run-*-tests.sh` suite unchanged.
- The kill-switch bug found in survey section 2 is fixed in `gate-lib.sh` and
  demonstrably fixed in all seven core gates post-migration: a test asserting
  `CORE_OFF=banana` (or equivalent per-gate switch) leaves the gate active is
  green where it did not exist before.
- The `replace_all` bug found in survey section 6 is fixed in
  `record-fields-gate.sh` via `gate-lib.sh`'s reconstruction function, with a
  passing test case for a multiply-occurring `old_string` + `replace_all:
  true`.
- `core/hooks/tests/run-gate-lib-tests.sh` exists and its six mandatory case
  groups all pass.
- `core/hooks/tests/compliance-check.sh` exists, runs clean against `core/`'s
  own seven post-migration gates, and correctly flags a synthetic
  fixture gate that hand-rolls one of the six defect classes instead of
  calling `gate-lib.sh`.
- `gate-lib.sh` and `compliance-check.sh` are both listed in
  `core/hooks/tests/canon-manifest.txt`, and `stub-check.sh` flags a
  synthetic vendored copy of either.
- `docs/handbooks/gate-house-standard.md` exists with the five-step
  per-repo migration checklist, ready to be linked from each of the 43
  per-repo A+ remediation issues once they are filed.
