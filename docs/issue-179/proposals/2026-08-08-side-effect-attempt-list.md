---
status: landed
files:
  - docs/issue-179/reports/defect-verification.md
  - tests/test_side_effect_round.py
---

## Intent

Verify today's core landings (#141, #142, #146, #147, #155, #167, #168, #63,
#173, #175, #177) as a SET for gate-interaction side effects, over four
hunt areas the issue names, rather than re-checking any one PR in
isolation.

## Constraints

- Never re-litigate review's per-requirement verdict; never propose a fix.
- Every attempt below names its source verbatim (a qa defect report, a
  review requirement marked Present, or a self-devised path) per the
  defect-verification role contract.
- code_under_review: `bb0d197aa80782a124c8318ab5d6fed123bbca3e`.

## Attempt list (phase 1 — proposed, not yet exercised)

1. **[self-devised]** Compound commit tool-call carrying a trailer-gate
   violation (missing `Subject:` trailer) simultaneously with a
   handbook-trigger condition (staged operational-surface file, e.g.
   `package.json`, without a matching `docs/handbooks/` touch) and a
   record-fields violation (non-terminal `loop_state` on a `docs/issue-179`
   record) in one commit — check whether core's independently-registered
   `PreToolUse` gates (`trailer-gate.sh`, `handbook-trigger-gate.sh`,
   `record-fields-gate.sh`) all fire, or whether one gate's deny short-
   circuits the tool call before a later gate in `hooks.json` order ever
   runs, silently masking the other violations.
   - closed_checks re-derived: none cite this cross-gate ordering; no
     review.md exists for #146/#155 to cite.

2. **[self-devised]** Same compound commit, but also crossing the plugin
   boundary: does warrant's `hunt-guard.sh` budget-cap check
   (`gate_budget_exceeded`, `core/hooks/lib/gate-lib.sh:97-112`) interact
   with, or run fully independent of, core's chain when both plugins'
   `hooks.json` register `PreToolUse .*` on the same tool call — specifically
   whether a budget-exceeded deny from warrant's chain can be bypassed by a
   tool-call shape that core's chain allows through first (ordering is
   plugin-registration order, not explicit).
   - closed_checks cited: `docs/issue-63/reports/*` budget-cap
     implementation is Present per that issue's own closure — cited, not
     re-derived; only the cross-plugin ordering is re-derived.

3. **[qa defect report — reconfirm, not re-litigate]** `#163` finding A7
   (`docs/issue-163/reports/defect-verification.md:262`, Low/advisory,
   accepted out of scope for #167): `core/hooks/gh-guard.sh` renamed-binary
   /PATH-shadowing bypass. Re-run the existing repro
   (`tests/test_silent_failure_repros.py::test_A7_gh_guard_renamed_binary_bypass_still_holds`)
   against current `HEAD` to confirm it still holds unchanged after today's
   set, since none of today's PRs touch `gh-guard.sh` directly but #167
   restructured adjacent trailer-gate parsing.
   - closed_checks cited: A7's existing reproduced/Low verdict — cited
     verbatim, not re-litigated; only whether it still reproduces on new sha
     is re-derived.

4. **[self-devised]** `warrant/hooks/scope-gate.sh`'s narrowed read-only
   Bash allowlist (the #167 A4 fix) exercised against a `warrant-hunter`
   agent's actual hunt flow from #63/#168 (budget-bounded dispatch, fleet
   scan driver) — check whether the narrowed allowlist blocks a command
   pattern the fleet-scan driver (`core/hooks/tests/fleet-silent-failure-scan.sh`)
   or a legitimate hunt-guard-approved worker path legitimately needs,
   i.e. whether the A4 fix is over-broad against the newly-landed hunt
   machinery it wasn't tested against.
   - closed_checks cited: A4 fix Present per `docs/issue-167/reports/implementation.md`
     — cited; interaction with #63/#168 machinery re-derived (neither
     record mentions the other).

5. **[self-devised]** `compliance-check.sh --canon-duplication` and
   `stub-check.sh` run with `$dir`/`$target` pointed at `core/hooks/` itself
   (this repo, not a downstream target repo) — `compliance-check.sh` claims
   explicit self-exclusion (lines 29-30, 85-86) but `stub-check.sh` has no
   code-level self-path exclusion, only a caller-convention comment. Check
   whether `stub-check.sh` run against `core/hooks/tests/canon-forms.txt`'s
   own listed canon sources produces false-positive drift flags on core's
   own tree.
   - closed_checks re-derived: no #142/#173/#175/#177 record addresses
     self-scan; all closures are against target-repo scans.

6. **[self-devised]** Content-hash canon-duplication
   (`gate-lib.sh:210-234`, issue-175) exercised against `directive.sh`,
   which the code explicitly routes to a *different*, structural check
   (`gate_is_role_directive_stub`) instead of the hash path — construct a
   `directive.sh` variant that is structurally stub-shaped but has
   content-hash-divergent bytes (edited comment/whitespace only) and check
   whether the structural-check carve-out lets a real behavioral copy
   through undetected because it never reaches the hash comparison.
   - closed_checks cited: issue-173's stub-distinction fix Present — cited;
     the carve-out's interaction with issue-175's hash logic is re-derived.

7. **[self-devised]** Terminal-state derivation
   (`record-fields-gate.sh:352-404`, issue-147) exercised end-to-end with an
   actual `docs/specs/record-fields-terminal-states.json` override file
   created for the first time in this repo (it currently does not exist,
   so this code path is untested live) — malformed JSON, unrecognized kind
   key, and a valid override, to confirm the fail-closed paths actually
   fail closed rather than silently falling back to `KIND_TERMINAL_DEFAULTS`
   on a parse path nobody has exercised against real bytes.
   - closed_checks cited: issue-147's validation logic marked Present in its
     proposal/hunt record — cited; live behavior against a real override
     file is re-derived since none exists to have been tested against.

8. **[self-devised]** Kind resolution precedence fix
   (`record-fields-gate.sh:352-359`, role→kind authoritative over
   self-declared `kind:`) exercised against a record whose role IS in
   `ROLE_TO_KIND` but whose self-declared `kind:` names a *different* kind
   with a longer/looser terminal-state list — confirm the fallback-only
   rule actually ignores the self-declared value rather than merging or
   preferring it in some code path.
   - closed_checks cited: issue-147 before-landing hunt finding (self-
     declared kind previously trusted unconditionally, now fixed) — cited;
     this specific role-present + kind-mismatch shape is re-derived, since
     the hunt record's repro used a role absent from `ROLE_TO_KIND`.

## Out of scope

- Any new fix or patch to the above scripts — findings, if any, are
  addressed to coding.
- #163's A8 (`blocked: needs-repro-access`) — not re-attempted here; access
  constraint unchanged.
- Re-litigating any review verdict as if the verdict itself were an attempt.

## How we'll know it worked

Every attempt above gets exactly one outcome
(`reproduced`/`not-reproduced`/`blocked: needs-repro-access`) recorded in
`docs/issue-179/reports/defect-verification.md` in phase 2, with any
`reproduced` outcome carrying a runnable evidence pointer and a severity
band. `tests/test_side_effect_round.py` will hold any reproduced repro as a
runnable test. All gate suites
(`core/hooks/tests/run-gate-lib-tests.sh`,
`run-role-gates-tests.sh`, `run-fleet-scan-tests.sh`, `test/hooks/*.sh`)
stay green at the end.

## What did not work

- Expected `run-role-gates-tests.sh` to be green going in (issue's acceptance
  wording implies it should be) — it is not: 1/79 pre-existing failure
  (`stub-check: real stub directive.sh passes`), traced to
  `canon-manifest.txt` listing `directive.sh` in `stub-check.sh`'s generic
  absence-based loop even though the file has its own later, correct
  structural check. Recorded as attempt 9 (self-devised, surfaced by the
  acceptance check itself) rather than silently working around it.
- First pass at attempt 5's repro test asserted on `proc.stdout`;
  `stub-check.sh`'s FAIL lines go to stderr (`>&2`), not stdout — assertion
  failed until switched to `proc.stderr`.
- Attempt 6's original hypothesis (comment/whitespace-only edits defeating
  a content-hash comparison) doesn't apply: `directive.sh` never reaches a
  hash comparison at all (routed to the structural check unconditionally,
  by design). Found a stronger, more directly reachable variant instead: an
  assignment-line (`VAR=$(...)`) is unconditionally excluded from scrutiny
  regardless of its right-hand side, so a `curl | bash` disguised as an
  assignment passes clean.
