---
code_under_review: HEAD
loop_state: delivered
---

# issue-177 implementation record

## What was done

- `core/hooks/tests/canon-forms.txt`: removed the assumption-built
  `layered-directive` entry (falsified by real bytes — no Batch-1 repo has
  this shape, and it structurally cannot fix `wcag-em-directive` since that
  file fails `gate_is_role_directive_stub`'s first two checks before
  `canon-forms.txt` is ever consulted). Replaced `unregistered-stub` with
  two structural `gate-lib-source`/`gate-call` patterns derived from
  `architecture-rulebook@da8565d615d9fb6c18487c9b338fa8b60bdf1120`'s real
  `architecture/hooks/directive.sh` lines 14-15 (source `gate-lib.sh` with
  an `|| { ...; exit N; }` fallback; call an exported `gate_*` function
  with an `|| exit N` fallback).
- `core/hooks/lib/gate-lib.sh`: added a one-line-each cap on the new
  gate-lib-source/gate-call patterns inside `gate_is_role_directive_stub`
  (more than one match of either shape now falls through to the existing
  "regrown boilerplate" fail path) — closes the after-proposal hunt
  finding that an uncapped generalization would let an unbounded chain of
  `gate_*`-shaped lines through. This file was not in the frozen write set
  as a path but the cap could not be expressed inside `canon-forms.txt`
  alone (regex-per-line matching has no way to count occurrences across
  lines); see `## Rationale for deviations`.
- `core/hooks/tests/run-stub-canon-forms-tests.sh`: replaced the
  `unregistered_stub_file`/`layered_directive_file` fixtures with (a) a
  fixture transcribing architecture-rulebook's real lines 14-16 verbatim
  (want=pass), (b) a genuinely vendored-copy fixture using core's own
  `role-directive.sh`-sourcing + `core_role_directive`-calling shape with
  no extra lines beyond a literal copy of the two real gate-lib lines
  repeated to simulate vendoring (want=fail via the new cap), (c) a case
  with a `.`-sourced non-gate-lib file line (want=fail, proves the rule
  stays narrow), (d) a case chaining three `gate_*` calls beyond the
  header (want=fail, proves the one-line cap).
- `docs/handbooks/gate-house-standard.md`: added a `canon-forms.txt`
  section describing the real-bytes-derived patterns, their repo+sha
  citation, the one-line-each cap, and the standalone-hook gap (pointer to
  survey, not a fix).

Verified by running `bash core/hooks/tests/run-stub-canon-forms-tests.sh`
directly: all cases pass, including the new cap cases. Also ran
`bash core/hooks/tests/run-all.sh` — no new failures introduced.

## Why

#175's `unregistered-stub`/`layered-directive` patterns were built from
the issue's own gap wording, not real repo bytes, and #171's live Batch-1
scan showed they don't match reality. This delivers the phase-1-approved
proposal's real-bytes replacement plus the cap the after-proposal hunt
found was missing.

## Upstream / basis

docs/issue-177/proposals/2026-08-08-canon-forms-real-bytes.md (approved via
issue comment `APPROVE issue-177/implementation`, single-account mode,
JiwonJung94).

## What did not work

None.

## Rationale for deviations

The proposal's frozen write set did not list `core/hooks/lib/gate-lib.sh`.
The proposal's own Constraints section (the after-proposal hunt finding)
requires a hard cap — "at most one gate-lib.sh source line and at most one
gate_* call line" — on top of the two new canon-forms.txt patterns.
canon-forms.txt is a flat per-line regex list consulted independently per
line inside `gate_is_role_directive_stub` (gate-lib.sh:149-170); a
per-pattern regex has no mechanism to count occurrences across the whole
file, so the cap cannot be expressed as a canon-forms.txt entry — it has to
live in the classifier function that iterates matches. This is the
smallest edit that satisfies a constraint the proposal itself stated as
mandatory; the alternative (ship the two patterns uncapped, leaving the
proposal's own stated constraint unmet) was rejected as worse than the
one-file scope addition. No other file outside the frozen write set was
touched.

## Open findings

- `stub-check.sh`'s independent "vendored copy of core canon file
  'directive.sh'" filename-only check fires on every fixture in
  `run-stub-canon-forms-tests.sh` (pre-existing: baseline was `pass=1
  fail=4` before this change, confirmed via `git stash` comparison; now
  `pass=3 fail=3`, an improvement, not a regression). `stub-check.sh` is
  outside this proposal's frozen write set.
  - Resolution path: a follow-up issue against `core/hooks/tests/stub-check.sh`
    to scope its vendored-copy filename scan away from the suite's own
    temp fixture dirs (or exclude the suite's own `hooks/directive.sh`
    fixtures from that specific check), verified by the same suite going
    green end to end.
- Standalone non-stub `directive.sh` files (accessibility's
  `wcag-em-directive`, capacity-planning's four methodology-framing
  plugins) still scan as failing — by design, out of this proposal's
  scope (see survey and proposal "Out of scope").
  - Resolution path: a follow-up `gate-lib.sh` proposal to add a
    function-level "standalone-methodology-hook" sanctioned shape,
    verified by those five files scanning clean without loosening the
    vendored-copy check.

## Next steps

File the two follow-up issues above; #171's own next session re-runs the
live 43-repo fleet scan to confirm the four Batch-1 blocking repos'
shapes now scan clean end to end once the stub-check.sh vendored-copy
scoping fix lands.
