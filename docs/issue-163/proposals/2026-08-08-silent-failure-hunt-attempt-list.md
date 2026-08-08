---
status: landed
files:
  - docs/issue-163/reports/defect-verification/survey.md
  - docs/issue-163/proposals/2026-08-08-silent-failure-hunt-attempt-list.md
  - docs/issue-163/reports/defect-verification.md
  - tests/test_silent_failure_repros.py
---

## Intent

Independently attempt to reproduce silent-failure and fail-open defects
across core's hooks/gates and the plugin hooks (warrant/terse/scout/
freelunch), and, where reachable, the 43 sibling rulebook checkouts —
per issue-163's own scope, "error paths that swallow failures... checks
that pass when their input is missing or malformed... deny paths that
never fire... anything that renders as success while the work did not
happen."

## Constraints so far

- code_under_review: `6d695bc66e2ec64bca44fdefee3a4239650efab9`
  (origin/main). No coding/qa/review record exists for issue-163 (it is a
  direct hunt subject, not a build-then-verify pipeline subject) —
  therefore no closed_checks exist to cite; every attempt below is
  self-devised, sourced from the issue text plus this session's own scan
  (`docs/issue-163/reports/defect-verification/survey.md`).
- The 43 rulebook repos are not present in this working tree and are not
  reachable from this session's GitHub identity (single public repo:
  `tokenmaxxxer-core`) — confirmed independently and consistent with
  issue-142's own scope note that the fleet is out of reach from core's
  checkout. Fleet attempts are recorded as `blocked: needs-repro-access`
  at phase 2, not skipped silently.
- Per role protocol: outcomes are exactly `reproduced` / `not-reproduced`
  / `blocked: needs-repro-access`; a `reproduced` finding requires an
  evidence pointer (repro steps, sha, run output, log excerpt), never a
  paraphrase; severity is assigned by deterministic band lookup only.
- This proposal fixes the **attempt list**. It does not fix code, does not
  re-litigate any review verdict (none exists here), and does not rank
  fix urgency.

## Attempt list (phase 2)

Each attempt names its source verbatim. All are self-devised, since no
qa/review record exists for this subject; each cites the survey line it
came from.

1. **A1 — `freelunch/hooks/observe.sh:159` swallowed exception.**
   Source: self-devised, from issue text category "error paths that
   swallow failures (empty except / `|| true` / rc ignored / output
   discarded)" plus survey finding #1. Attempt: feed the hook a payload
   that makes its python step raise (e.g. malformed stdin JSON), confirm
   whether `2>/dev/null; exit 0` masks the exception and the caller sees a
   clean pass with no enforcement effect.

2. **A2 — `warrant/hooks/hunt-guard.sh` fail-open on bad python3/JSON.**
   Source: self-devised, from issue text "kill-switch/fail-open idioms
   the #142 canon sweep may have missed" plus survey finding #2. Attempt:
   simulate `python3` unavailable or malformed JSON input, confirm hunter
   dispatch caps are bypassed rather than blocked.

3. **A3 — `warrant/hooks/scope-gate.sh` fail-open on bad python3/JSON.**
   Source: self-devised, from issue text same category plus survey
   finding #3. Same attempt shape as A2, applied to scope-gate.sh's
   documented-as-deliberate fail-open path — deliberate does not mean
   verified-safe under current inputs, hence still attempted.

4. **A4 — `warrant/hooks/scope-gate.sh:183-220` string-judged withhold
   list.** Source: self-devised, from issue text "string-judged commands
   (the #141 family) surviving anywhere" plus survey finding #4. Attempt:
   construct a dangerous command using quoting/`$(...)`/variable
   substitution that the regex list does not match, confirm it passes
   through withhold.

5. **A5 — `core/hooks/trailer-gate.sh:86` string-judged commit
   detector.** Source: self-devised, from issue text "string-judged
   commands (the #141 family)" plus survey finding #5. Attempt: reach a
   `git commit` invocation via a form the top-level regex does not match
   (alias, wrapper, indirect invocation), confirm the §13 trailer check is
   skipped entirely rather than enforced.

6. **A6 — `core/hooks/lib/role-directive.sh:30` absent-`CLAUDE_ROLE`
   no-op.** Source: self-devised, from issue text "checks that pass when
   their input is missing or malformed (absent file ⇒ allow)" plus survey
   finding #6. Attempt: unset `CLAUDE_ROLE`, confirm whether this is
   cosmetic (banner disappears, no enforcement change) or whether any
   downstream gate treats the silent no-op as an allow signal — severity
   turns on which.

7. **A7 — `core/hooks/gh-guard.sh` string-judged bypass (self-admitted
   gap).** Source: self-devised, from issue text "string-judged commands
   (the #141 family) surviving anywhere" plus survey finding #7, which
   notes the gap is already named in-repo
   (`core/hooks/tests/run-gh-guard-tests.sh`'s `gap-c-*` cases). Attempt:
   confirm the renamed-binary / indirect-wrapper bypass still reproduces
   against current `gh-guard.sh`, i.e. that the self-admitted gap has not
   silently widened or narrowed since it was last documented.

8. **A8 — fleet scan, 43 rulebook repos.** Source: issue text directly
   ("run the same signature scan against each sibling rulebook checkout...
   report per-repo divergences from core canon"). Attempt: for each of the
   43 repos, run `compliance-check.sh` (and the other canon scanners) and
   record a per-repo row. Outcome fixed in advance by the Constraints
   section above: `blocked: needs-repro-access` for all 43, since none are
   reachable from this session — recorded as 43 explicit rows per the
   issue's own acceptance criterion ("zero findings is a row, not an
   omission"), not folded into a single blanket note.

## What will be done (phase 2, on approval)

Work A1–A7 in this checkout; record A8 as 43 `blocked: needs-repro-access`
rows. For each of A1–A7: attempt, record outcome via
`verify:finding-record`, and on `reproduced` write a finding addressed to
coding with an evidence pointer and a `verify:severity-classification`
band. All outcomes land in `docs/issue-163/reports/defect-verification.md`
per contract v3 s19 (phase-2-only file). A runnable repro for every
`reproduced` finding is added to `tests/test_silent_failure_repros.py`,
and that file asserts the fleet table lists all 43 repos (satisfying both
of the issue's Acceptance checks).

## Out of scope

- Fixing any reproduced defect — follow-up issues are the operator's, per
  the issue text.
- Re-scanning the categories the survey already found clean in this
  checkout (fail-open in the five primary gates, mktemp footguns, dead
  deny branches, `set +e`, absent-input-allows in approval/board-gate) —
  listed in the survey so phase 2 doesn't redo them from zero; re-derive
  only if a phase-2 attempt surfaces a reason to doubt one specifically.
- Actually obtaining access to the 43 rulebook repos — that's an
  infrastructure/access decision outside this role's write set.

## How it will be verified

`tests/test_silent_failure_repros.py` passes: every `reproduced` finding's
repro runs and exhibits the claimed behavior, and the fleet table lists
43 rows.

## What did not work

- A3 and A6's hypothesized silent-failure defects did not reproduce as
  defects: both fail-open/no-op behaviors are explicitly documented
  in-file as deliberate, and neither shows a downstream enforcement
  effect on this checkout's other gates. Recorded as `not-reproduced`,
  not dropped silently.
- A2's original hypothesis (fail-open on missing `python3` / malformed
  JSON in `hunt-guard.sh`) turned out to work as designed for those two
  cases; the actual reproducible bypass found under the same source line
  was a different one — an exact-string `subagent_type` match that never
  matches the real, plugin-namespaced `warrant:warrant-hunter` agent type
  this session's own registry uses. Recorded the real finding rather than
  forcing the original hypothesis.
