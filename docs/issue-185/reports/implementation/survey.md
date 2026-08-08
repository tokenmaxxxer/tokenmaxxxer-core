# Survey — issue-185 (canon-duplication third category: custom-by-convention)

## Current mechanism (binary stub|vendored via gate_is_role_directive_stub)

`core/hooks/lib/gate-lib.sh:168-271` (`gate_is_role_directive_stub`, from
#180) is the sole classifier for a `directive.sh` hit, called from both
`stub-check.sh:118-135` (directive.sh structural block) and
`compliance-check.sh:59-73` (`--canon-duplication` mode). It returns 0
("sanctioned stub") only when the file both (a) sources
`role-directive.sh` and (b) calls `core_role_directive`, and every
remaining "other" line falls into a narrow structural whitelist (source
lines for `gate-lib.sh`/`role-directive.sh`, `gate_*` calls, `set -e`
preamble, the sales-rulebook fragment-loop shapes). Anything that fails
either requirement — including a file that never sources
`role-directive.sh` at all — returns 1 and both callers print "FAIL —
vendored copy of core canon file 'directive.sh' found". There is no
distinct "not a stub, but also not vendored" outcome: not-a-stub always
reads as vendored.

`gate_content_hash_matches_canon` (gate-lib.sh:284-299) is the hash
comparator compliance-check.sh's non-directive.sh manifest entries use
(identical hash ⇒ vendored). It is explicitly NOT applied to
`directive.sh` today (compliance-check.sh:74-79 comment): a sanctioned
stub's content is supposed to differ per role by design, so hash-equality
was never the right test for it. This survey confirms that reasoning
still holds and extends it: hash-equality also isn't the right test for
distinguishing custom-by-convention from a byte-edited vendored copy,
since a copy with one byte changed still hash-mismatches. The issue's own
bypass argument names this directly and asks for a needle check instead.

## The false-positive: real custom-by-convention files

Three real Batch-1 repos (issue-171 session 5 record, on the PR #172
branch) carry `directive.sh` files that are deliberate, hand-written,
per-facet SessionStart hooks layered additionally via `hooks.json`
ordering — never intended to be role-directive.sh stubs at all. Read
byte-for-byte from the checked-out repos on disk:

- `accessibility-rulebook` @ `ce5cbe5c4c55622001812ed18d8302221c2f5b21`,
  path `wcag-em-directive/hooks/directive.sh` (97 lines). Opens with
  `#!/usr/bin/env bash`, a comment block explaining it layers "ADDITIONALLY
  on top of accessibility/hooks/directive.sh's own core_role_directive
  call" and "does NOT call core_role_directive", a
  `WCAG_EM_DIRECTIVE_OFF` kill-switch `case`, a `CLAUDE_ROLE` guard, then
  a `cat <<'EOF' ... EOF` heredoc of WCAG-EM methodology text. No
  `role-directive.sh` source, no `gate-lib.sh` source, no `gate_*` call,
  no `core_role_directive` call anywhere in the file (only mentioned
  inside comments/heredoc prose, never invoked).
- `localization-rulebook` @ `2c9f76b8b6ebc212845409413de7bb61c2de50c6`,
  path `localization/plugins/mqm-tagging/hooks/directive.sh` (26 lines).
  Same shape: shebang, a one-line purpose comment + kill-switch comment,
  `set -uo pipefail`, a `LOCALIZATION_MQM_TAGGING_DIRECTIVE_OFF`
  kill-switch `case`, a `CLAUDE_ROLE` guard, a heredoc body. No canon
  source lines, no canon function calls.
- `capacity-planning-rulebook` @ `00273632123750aa3c5cff608729fa93f042b41`,
  path `capacity-forecast-method/hooks/directive.sh`. Same shape: a
  `__fc`/`trap ... EXIT` fail-closed preamble (its OWN local helper, not
  `gate_trap_fail_closed`), `set -uo pipefail`, a heredoc body of
  forecast-method framing text. No canon source lines, no canon function
  calls.

All three currently scan dirty under `stub-check.sh`/`compliance-check.sh
--canon-duplication`: they fail requirement (a) (no `role-directive.sh`
source at all) and are reported as "vendored copy of core canon file
'directive.sh' found" — a false positive on files that were never meant
to be stubs.

## The non-bypass requirement (why a plain "doesn't source canon" test is unsafe alone)

The issue names the risk directly: a genuinely vendored copy edited by
one byte still hash-mismatches core canon, so a hash-only or
source-line-only test can be defeated by copying `role-directive.sh`'s or
`gate-lib.sh`'s actual body into a file named `directive.sh` without a
literal `.`/`source` line pointing at either filename (e.g. inlining
`core_role_directive`'s function body under a different wrapper, or
copying a `gate_*` function definition in). Both existing helper
functions in `gate-lib.sh` already define the vocabulary needed to close
this: `core_role_directive` is a literal, distinctive canon function name
(defined once, in `role-directive.sh`), and `gate_[A-Za-z_]+` is the
naming convention every canon helper in `gate-lib.sh` follows
(`gate_trap_fail_closed`, `gate_kill_switch_active`, `gate_deny`,
`gate_allow`, `gate_bash_write_targets`, `gate_budget_exceeded`,
`gate_is_role_directive_stub`, `gate_content_hash_matches_canon`). A
needle test for either name surviving in the file (as a definition or a
call, not merely a comment/heredoc mention — the three real fixtures
above already prove comments/heredocs alone must not trip it) closes the
renamed-vendoring gap the issue describes, without re-opening the
comment/heredoc false-positive the real fixtures show is a live risk
(WCAG-EM's own file *mentions* `core_role_directive` in an explanatory
comment).

## Existing test fixture that will need re-basing

`core/hooks/tests/run-fleet-scan-tests.sh`'s current "vendored full
directive.sh" fixture (`vendored_repo`, added in #173) is a synthetic
5-line script (`set -euo pipefail`, a `DIRECTIVE_OFF` case, an `echo`)
that contains no canon source line and no canon function name — under
today's binary check it still fails (anything that isn't a sanctioned
stub reads as "vendored"), but under the new three-way rule it has
neither a canon needle nor a hash match, so it would newly read as
custom-by-convention. This fixture is not actually representative of a
"vendored copy" in the three-way sense — it never claimed to embed canon
internals. It needs replacing with fixtures that are genuinely
representative of the two categories that must still flag: a
byte-copy of `role-directive.sh`'s `core_role_directive` function body
with one byte changed (still not a sanctioned stub, still not custom —
carries the needle), and a file containing a `gate_*` call/definition
with no source line at all (canon-function-containing but not
byte-vendored). The existing sanctioned-stub fixture (`stub_repo`) is
unaffected and stays as the clean/stub case.

## Write set implied by the above

- `core/hooks/lib/gate-lib.sh` — add the classification helper(s); the
  existing `gate_is_role_directive_stub` signature/callers stay
  unchanged (still the stub/not-stub test), a new function layers the
  custom-by-convention + needle test on top.
- `core/hooks/tests/stub-check.sh` — directive.sh block gains the third
  branch (ok stub / ok custom-by-convention / FAIL).
- `core/hooks/tests/compliance-check.sh` — `--canon-duplication`
  directive.sh block gains the same third branch.
- `core/hooks/tests/run-fleet-scan-tests.sh` — red/green fixtures for all
  three categories, including the three real byte-exact custom fixtures
  and the re-based vendored/corrupted fixtures.
- `core/hooks/tests/run-gate-lib-tests.sh` — unit coverage for the new
  gate-lib.sh helper directly (existing file already unit-tests
  `gate_is_role_directive_stub`/`gate_content_hash_matches_canon`
  alongside the fleet-level tests).

No new dependency, no new env var, no schema/migration. Skip conditions
(scout directive) do not apply — this is a design decision, not a pure
bugfix (the classification test itself is new logic), and I ran the scout
sweep across the three real repos above as the field research this
category change is drafted from; no external product category applies
(internal detector, not a product-shaped surface), so no scout-brief.md
is produced — the field for this build is the codebase and the three
cited real repos, per scout's own scope note for non-product roles ("the
best of their own deliverable's kind" — for a drift detector, that is
existing real-repo bytes, already gathered above, not a category of
external product to benchmark against).
