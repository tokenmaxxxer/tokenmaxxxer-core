---
status: proposed
files:
  - core/hooks/lib/gate-lib.sh
  - core/hooks/tests/stub-check.sh
  - core/hooks/tests/compliance-check.sh
  - core/hooks/tests/run-fleet-scan-tests.sh
  - core/hooks/tests/run-gate-lib-tests.sh
---

files:
  - core/hooks/lib/gate-lib.sh
  - core/hooks/tests/stub-check.sh
  - core/hooks/tests/compliance-check.sh
  - core/hooks/tests/run-fleet-scan-tests.sh
  - core/hooks/tests/run-gate-lib-tests.sh

## Request

canon-duplication's `directive.sh` classification (`gate_is_role_directive_stub`,
used by `stub-check.sh` and `compliance-check.sh --canon-duplication`) is
binary: sanctioned role-directive.sh stub, or FAIL ("vendored copy").
Three real Batch-1 repos (accessibility, localization, capacity-planning)
carry `directive.sh` files that are deliberately custom, per-facet
SessionStart hooks layered on top of the real stub — not stubs, not
vendored copies — and the binary check flags them dirty. Add a third,
non-bypassable "custom-by-convention" category: clean iff the file
neither hash-matches core canon nor sources/embeds core canon internals
at all (a needle check on canon function names closes the
byte-edited-vendored-copy bypass the issue names).

## Constraints

- Must not weaken the existing stub/vendored distinction: a genuinely
  corrupted stub (sources `role-directive.sh` but has regrown
  boilerplate) still fails exactly as today.
- Must not let a renamed/byte-edited vendored copy pass as custom: the
  needle check is the load-bearing anti-bypass mechanism the issue
  requires.
- No change to `gate_is_role_directive_stub`'s existing signature or
  return contract (callers outside this write set, if any, are
  unaffected).
- Byte-exact fixtures from the three cited real repos, not paraphrased
  approximations.

## Rationale

Considered keeping the existing hash-match helper
(`gate_content_hash_matches_canon`) as the sole new test — i.e. treat
`directive.sh` like every other manifest entry and hash it against
`core/hooks/lib/role-directive.sh`. Rejected: `directive.sh` never
literally equals `role-directive.sh` even in a legitimate stub (a stub
sources it and adds four role-specific string arguments), so a hash
compare against that file would never match anything, sanctioned stub or
vendored copy alike — it can't discriminate. Worse, it does nothing for
the actual bypass the issue names: a vendored copy edited by one byte
still hash-mismatches, so hash-only would let a disguised copy read as
custom. A textual needle check on canon function names
(`core_role_directive`, the `gate_[A-Za-z_]+` naming convention every
`gate-lib.sh` helper follows) is what actually survives a one-byte edit,
because the copied function body/call still carries the name. Hash
comparison is kept as a secondary, defense-in-depth test (a literal
byte-identical embed of `role-directive.sh` or `gate-lib.sh` content
inside the file) but the needle check is the one doing the real work.

## What will be done

- Add `gate_directive_custom_by_convention <file>` to `gate-lib.sh`:
  returns 0 (custom-by-convention, clean) only when the file (a) does not
  match the existing `role-directive.sh` source pattern
  `gate_is_role_directive_stub` already uses, (b) does not source
  `gate-lib.sh`, (c) contains no `core_role_directive` or `gate_[A-Za-z_]+`
  token as a real definition/call line (word-boundary match on
  non-comment, non-heredoc-body lines — the three real fixtures below
  prove a heredoc/comment mention alone must not trip this), and (d) does
  not hash-match `core/hooks/lib/role-directive.sh` or
  `core/hooks/lib/gate-lib.sh` via the existing
  `gate_content_hash_matches_canon`. Returns 1 (not custom — either a
  corrupted stub candidate or contains canon internals) otherwise, and is
  silent either way (classification only, no fail_reason string — callers
  already have `gate_is_role_directive_stub`'s reason for the FAIL case).
- `stub-check.sh`'s directive.sh block: for each hit, try
  `gate_is_role_directive_stub` first (ok — sanctioned stub); on failure,
  try `gate_directive_custom_by_convention` (ok — custom-by-convention,
  distinct log line so the two clean outcomes are still distinguishable
  in output); only if both fail, FAIL as today.
- `compliance-check.sh --canon-duplication`'s directive.sh block: same
  three-way branch, same distinct log line for the custom-by-convention
  case.
- `run-fleet-scan-tests.sh`: three new green fixtures using byte-exact
  content copied from the checked-out repos on disk — accessibility-rulebook
  @ ce5cbe5c4c55622001812ed18d8302221c2f5b21
  (`wcag-em-directive/hooks/directive.sh`), localization-rulebook @
  2c9f76b8b6ebc212845409413de7bb61c2de50c6
  (`localization/plugins/mqm-tagging/hooks/directive.sh`), and
  capacity-planning-rulebook @ 00273632123750aa3c5cff608729fa93f042b41
  (`capacity-forecast-method/hooks/directive.sh`) — each asserting exit 0
  and no "vendored copy" flag under both `stub-check.sh` and
  `compliance-check.sh --canon-duplication`. Re-base the existing
  synthetic `vendored_repo` fixture into two red fixtures that must still
  flag: a byte copy of `role-directive.sh`'s `core_role_directive`
  function body with one byte changed (still not a sanctioned stub,
  carries the needle — must FAIL, not read as custom), and a small file
  containing a bare `gate_deny "denied"`-shaped call with no source line
  at all (canon-function-containing, not byte-vendored — must FAIL). The
  existing sanctioned-stub fixture (`stub_repo`) is unchanged.
- `run-gate-lib-tests.sh`: direct unit coverage of
  `gate_directive_custom_by_convention` against the same fixture shapes
  (stub / custom / needle-bypass-attempt / hash-vendored), independent of
  the fleet-scan-level tests.

## Out of scope

- Any change to `gate_is_role_directive_stub`'s existing structural
  categories (source-line shapes, `gate_*` call cap, loop-syntax
  allowances) — issue-180's classifier is untouched.
- Re-scanning or re-classifying manifest entries other than
  `directive.sh` — `gate_content_hash_matches_canon`'s existing behavior
  for the rest of `canon-manifest.txt` is untouched.
- Rolling the three real repos' `directive.sh` files forward into any
  other change (e.g. renaming, relocating) — this proposal only fixes
  how they're classified, not the files themselves.
- The `--canon-duplication` scope-multi-rulebook caveat from issue-183
  (already recorded, unrelated to this classification gap).

## How you'll know it worked

`core/hooks/tests/run-fleet-scan-tests.sh` and
`core/hooks/tests/run-gate-lib-tests.sh` both pass: the three real custom
fixtures scan clean under both `stub-check.sh` and
`compliance-check.sh --canon-duplication`, the pre-existing sanctioned-stub
fixture still scans clean, and both the one-byte-edited vendored-copy
fixture and the canon-function-containing fixture still flag FAIL.
