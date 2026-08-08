---
code_under_review:
  - core/hooks/tests/stub-check.sh
  - tests/test_side_effect_round.py
loop_state: landed
---

## What was done
Fixed `stub-check.sh`'s `CANON_GATES` filename-hit loop false-flagging
core's own canon-source files as vendored copies when scanned against
`core/hooks` itself:
- `core/hooks/tests/stub-check.sh`: computed `repo_root`/`canon_home`
  the same way `compliance-check.sh` already does, and filtered each
  `find` hit's resolved real path, dropping any hit under
  `$repo_root/core/hooks/` before flagging the rest as vendored.
  `directive.sh`'s structural check branch is untouched.
- `tests/test_side_effect_round.py`: flipped
  `test_attempt5_stub_check_false_positives_on_its_own_canon_source_tree`
  to assert the `CANON_GATES` loop scans clean against `core/hooks`
  (asserted per-name, since `directive.sh`'s separate structural FAIL
  on `core/hooks/directive.sh` is pre-existing and out of scope — see
  below), and added
  `test_attempt5_stub_check_still_flags_real_vendored_copy` asserting a
  fixture copy placed outside `core/hooks/` still flags.

## Why
Upstream basis: `docs/issue-183/proposals/2026-08-08-stub-check-canon-source-exclusion.md`.
`stub-check.sh` had no self-path exclusion, unlike `compliance-check.sh`;
a path-prefix check against the script's own canonical `core/hooks/`
home fixes the false positive without content-hashing every hit against
every canonical copy (rejected alternative, see proposal Rationale).

## What did not work
- Initial exclusion used a broad prefix match (`case "$real" in "$canon_home"/*)`),
  which the before-landing warrant hunt found excludes ANY hit nested
  anywhere under `core/hooks/` from vendoring detection, not only the
  file's own literal canonical location — a drifted copy stashed at a
  reachable nested path (e.g. `core/hooks/vendor/trailer-gate.sh`)
  bypassed detection. Fixed by narrowing to exact-match against
  `$name`'s three actual canonical locations (`core/hooks/`,
  `core/hooks/tests/`, `core/hooks/lib/`) instead of a prefix.

## Rationale for deviations
None — build matched the approved proposal.

## Doc placement
No env var, config key, dependency, migration, or setup step was added;
no library/format decision was made over a named alternative; no public
signature or wire format changed. Doctrine ladder: not applicable, no
placement required.

## How it was confirmed (actually run)
- `bash core/hooks/tests/stub-check.sh core/hooks`: `CANON_GATES` loop
  now prints `ok — no vendored '<name>'` for every entry (previously
  FAILed on `trailer-gate.sh` etc.). The script's overall exit is
  non-zero only because of the pre-existing, unrelated
  `directive.sh` structural FAIL on `core/hooks/directive.sh` itself
  (confirmed present identically on pre-fix HEAD via `git stash`) —
  #180's in-flight write set, not this issue's scope.
- `python3 -m pytest tests/test_side_effect_round.py -k attempt5 -v`:
  2 passed (the flipped false-positive test and the new
  still-flags-real-copy test).
- `bash core/hooks/tests/run-role-gates-tests.sh`: 78 passed, 1 failed
  (`stub-check: real stub directive.sh passes want=allow got=deny`) —
  reproduced identically on pre-fix HEAD via `git stash`, confirming it
  predates this change (matches the proposal's noted #180 dependency,
  not a regression introduced here).

## closed_checks
- CANON_GATES filename-hit loop clean scan against core/hooks —
  code_sha: fd3c3c14d429019b22975fe3d49ebdafe450c976 (base commit this
  work started from)
- real vendored copy outside core/hooks still flags — code_sha:
  fd3c3c14d429019b22975fe3d49ebdafe450c976
- pre-existing directive.sh structural FAIL unaffected by this change
  (module-scope regression check) — code_sha:
  fd3c3c14d429019b22975fe3d49ebdafe450c976

## Open findings
None. Before-landing warrant hunt (stance 0, bypass hunt) found the
broad-prefix exclusion bypass noted above under "What did not work" —
resolved in this same delivery, re-verified by direct reproduction
(mkdir/cp fixture at `core/hooks/vendor/trailer-gate.sh`, confirmed
FAIL) before commit. Full hunt record:
`docs/reports/2026-08-08-hunt-stub-check-canon-source-exclusion.md`.

Proposal's out-of-scope caveat still stands: other rulebooks' own
sanctioned canonical copies (e.g. `terse/hooks/tests/parse-check.sh`)
remain filename-flagged by `stub-check.sh`, pre-existing and separate
from this issue's core-tree-only Acceptance.
