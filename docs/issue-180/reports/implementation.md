---
code_under_review: core/hooks/lib/gate-lib.sh, core/hooks/tests/canon-forms.txt, core/hooks/tests/run-stub-canon-forms-tests.sh, docs/handbooks/fleet-scan-tests.md
loop_state: landed
---

# Implementation record — issue-180 (directive.sh line classifier)

## What was done

Replaced `gate_is_role_directive_stub`'s canon-forms.txt-driven "other
line" regex-table loop with a structural per-line classifier per the
approved proposal (`docs/issue-180/proposals/2026-08-08-directive-line-classifier.md`,
approved via `APPROVE issue-180/implementation` on issue #180).

- `core/hooks/lib/gate-lib.sh`: `gate_is_role_directive_stub` now
  classifies each remaining "other" line into one of four structural
  categories (basename-anchored `.`/source of `gate-lib.sh` or
  `role-directive.sh`, tolerant of arbitrary nested quoting; a single
  `gate_<name>` call once a `gate-lib.sh` source line has matched
  earlier in the file; a `set -e`-family preamble line; sales-rulebook's
  narrow `for`/`do`/`done` fragment-loop syntax) instead of matching
  against `canon-forms.txt` rows. The issue-177 gate_* one-token-per-
  physical-line cap and the two prerequisite checks (sources
  `role-directive.sh`, calls `core_role_directive`) are unchanged.
- `core/hooks/tests/canon-forms.txt`: both directive.sh shape blocks
  (the #177 gate-lib-source/gate-call rows and the #78/#173
  single-call/fragment-loop rows) deleted; file is now a header comment
  only, kept as a placeholder home per the proposal's write set.
- `core/hooks/tests/run-stub-canon-forms-tests.sh`: added byte-exact
  fixtures for accessibility-rulebook (@`ce5cbe5c4c55622001812ed18d8302221c2f5b21`),
  localization-rulebook (@`da7144369f31800c8e4af3008a1379affc6daf0c`),
  and capacity-planning-rulebook (@`00273632123750aa3c5cff608729fa93f042b419`),
  plus a vendored-full-copy and a stub-plus-extra-logic fail fixture, and
  a grep assertion that `canon-forms.txt` carries no directive.sh shape
  rows. `run_case` now calls `gate_is_role_directive_stub` directly
  instead of going through `stub-check.sh` — see `## Rationale for
  deviations`.
- `docs/handbooks/fleet-scan-tests.md`: added an issue-180 section
  describing the line classifier and confirming
  `run-stub-canon-forms-tests.sh` (not `run-fleet-scan-tests.sh`) as the
  suite that owns this coverage.

## Why

canon-forms.txt regex rows failed three rounds running (#78, #173,
#175, #177) against real Batch-1 repo bytes; the issue forbids a fourth
literal-pattern patch and requires a structural classifier instead. See
proposal `## Rationale`.

## Upstream basis

`docs/issue-180/proposals/2026-08-08-directive-line-classifier.md`,
`docs/issue-180/reports/implementation/survey.md`.

## Closed checks

- `run-stub-canon-forms-tests.sh` (12/12 pass): fragment-loop,
  single-call, architecture-rulebook, accessibility-rulebook,
  localization-rulebook, capacity-planning-rulebook shapes accepted;
  regrown boilerplate, chained gate_* calls beyond the one-line-each
  cap, non-gate-lib source line, vendored full copy, and stub-plus-
  extra-logic all still rejected; canon-forms.txt confirmed to carry no
  directive.sh shape rows. code_sha: `a41bb165575a9b49874ae29cfdafdddceff97786`
  (pre-build tree; classifier + fixtures added on top in this session).
- `run-fleet-scan-tests.sh` (13/13 pass, unmodified — confirms the
  proposal's "how you'll know it worked" clause that this suite's own
  coverage is unaffected). code_sha: same as above.
- Before-landing warrant hunt (stance 1: cross-consumer cancellation) —
  see `## Open findings`.

## What did not work

Initially wrote `run_case` in `run-stub-canon-forms-tests.sh` to invoke
`stub-check.sh` (matching the pre-existing test shape) — every "pass"-
expected fixture came back `deny` because `stub-check.sh`'s
`canon-manifest.txt` absence-check unconditionally flags any file
literally named `directive.sh` as a vendored core-canon copy, before its
own later structural check runs (confirmed pre-existing on `main` via
`git stash`, not introduced by this change; also independently
reproduced by `run-role-gates-tests.sh`'s "stub-check: real stub
directive.sh passes" case, which fails the same way on `main`).
`canon-manifest.txt` is outside this issue's write set, so the fix was
to call `gate_is_role_directive_stub` directly in the test harness
instead — this is `## Rationale for deviations` below, not a further
edit to `stub-check.sh` or `canon-manifest.txt`.

## Rationale for deviations

1. **Dropped the standalone "sibling `*-directive.sh` basename"
   acceptance from category 1.** The approved proposal's `## What will
   be done` names a bare `.`/source of a sibling `*-directive.sh` file
   as a top-level category-1 target, independent of the fragment-loop
   context. Implementing it literally would flip the pre-existing
   `run-stub-canon-forms-tests.sh` regression fixture "non-gate-lib
   source line still rejected" (issue-177) from fail to pass — that
   fixture sources `accessibility-wcag/hooks/layered-directive.sh`
   specifically to prove the classifier stays narrow and does not admit
   an arbitrary sibling source as a substitute for the approved
   `gate-lib.sh`/`role-directive.sh` architecture. Generalizing category
   1 to any `*-directive.sh` basename would silently reopen exactly the
   shape the after-proposal warrant hunt (stance 0, closed in commit
   `a41bb16`) had already flagged as a lookalike-target bypass class.
   Sales-rulebook's one real shape that sources a sibling fragment (the
   `for`/`do`/`done` loop) is unaffected: its body line is
   `[ -f "$frag" ] && . "$frag" 2>/dev/null`, a variable-based
   test-and-source that never needs a literal sibling filename, and is
   covered by category 4. Documented at the point of divergence in
   `gate_is_role_directive_stub`'s own comment
   (`core/hooks/lib/gate-lib.sh`).
2. **`run-stub-canon-forms-tests.sh`'s `run_case` calls
   `gate_is_role_directive_stub` directly instead of going through
   `stub-check.sh`.** See `## What did not work` above — `stub-check.sh`
   itself is outside this issue's write set, so the pre-existing
   contradiction between its unconditional `canon-manifest.txt`
   absence-check and its own directive.sh structural-check carve-out
   (already documented as a known, unfixed gap in
   `docs/handbooks/fleet-scan-tests.md` since issue-173) could not be
   fixed here. Testing the classifier directly is still faithful to the
   proposal's "how you'll know it worked" clause, which names
   `run-stub-canon-forms-tests.sh` passing, not any particular
   call path through it.

## Open findings

Before-landing warrant hunt (stance 1, cross-consumer cancellation)
found: `core/hooks/tests/stub-check.sh`'s `canon-forms.txt`
existence-WARN (lines ~78-84) still describes a "single-call-only shape"
fallback that `gate_is_role_directive_stub` no longer implements post-
rewrite — the function never reads `canon-forms.txt` any more, so the
WARN is now stale and its `forms_manifest` variable is dead code. No
behavioral effect (the WARN is inert; classification results are
identical with or without `canon-forms.txt` present), but the message
text is misleading. `stub-check.sh` is outside this issue's frozen write
set (only `core/hooks/lib/gate-lib.sh`, `core/hooks/tests/canon-forms.txt`,
`core/hooks/tests/run-stub-canon-forms-tests.sh`, and
`docs/handbooks/fleet-scan-tests.md` are), so not fixed in this PR per
the scope-exceeded rule — full detail in
`docs/reports/2026-08-08-hunt-canon-forms-real-bytes.md` (before-landing
section). Resolution path: a follow-up issue removing
`stub-check.sh`'s dead `forms_manifest`/WARN block, filed as the next
open item after this PR lands.

## Pre-existing, out-of-scope failure noted (not this issue's regression)

`run-role-gates-tests.sh`'s "stub-check: real stub directive.sh passes"
case fails on `main` before this change (confirmed via `git stash`) —
same `canon-manifest.txt`/structural-check contradiction as above, not
introduced or worsened by this build.
