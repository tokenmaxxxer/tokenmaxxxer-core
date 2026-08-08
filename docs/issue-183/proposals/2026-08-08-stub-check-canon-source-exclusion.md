---
status: proposed
files:
  - core/hooks/tests/stub-check.sh
  - tests/test_side_effect_round.py
---

## Request
Fix `stub-check.sh` flagging its own canon-source files as "vendored
copies" when run against `core/hooks` itself (#179 attempt-5,
Low/advisory), while a real vendored copy elsewhere still flags.

## Constraints
- Do not touch `core/hooks/lib/gate-lib.sh` or
  `core/hooks/tests/canon-forms.txt` — #180's in-flight write set for the
  `directive.sh` line-classifier.
- `directive.sh`'s structural check branch (lines 78-102) is out of
  scope; only the filename-hit `CANON_GATES` loop (lines 59-76) changes.
- Skip condition: pure bugfix, per scout-directive — no design decision
  open (see survey.md).

## Rationale
Considered reusing `compliance-check.sh`'s full content-hash comparison
(`gate_content_hash_matches_canon`) for `stub-check.sh` too, since it
already solves this generally. Rejected: that function content-hashes a
hit against every canonical copy in the repo, which is the right model
for `compliance-check.sh`'s repo-root-wide scan but overkill for
`stub-check.sh`'s narrower, `-maxdepth 3`-bounded, single-`$dir` scan —
`stub-check.sh` only needs to know "is this hit already living at its
own canonical `core/hooks/` location," a path-prefix check, not a
content hash. Path-prefix also avoids a false negative content-hash
would newly introduce: an edited (non-byte-identical) canon file under
`core/hooks/` would still resolve correctly by path but would fail a
hash match and re-trigger the same false positive.

## What will be done
In `stub-check.sh`, compute `repo_root` the same way
`compliance-check.sh` already does (three levels up from
`core/hooks/tests/`), then filter each `name`'s `find` hits: drop any
hit whose resolved real path lives under `$repo_root/core/hooks/` (this
repo's own canonical home for every `CANON_GATES` entry) before
flagging what remains as vendored. Flip
`tests/test_side_effect_round.py::test_attempt5_stub_check_false_positives_on_its_own_canon_source_tree`
to assert a clean scan (`rc=0`, no FAIL lines) against `core/hooks`, and
add a companion case in the same test asserting a fixture copy placed
outside `core/hooks/` (e.g. a temp dir) still flags.

## Out of scope
- `directive.sh`'s structural stub check and #180's line-classifier
  replacement work.
- `compliance-check.sh` itself (already correct, unaffected).
- Any change to `canon-manifest.txt`.

## How you'll know it worked
- `bash core/hooks/tests/stub-check.sh core/hooks` exits 0 with no FAIL
  lines.
- A fixture directory with a real vendored copy (outside `core/hooks/`)
  still exits non-zero with a FAIL line.
- `python3 -m pytest tests/test_side_effect_round.py -k attempt5` passes
  on the flipped assertions.
- `core/hooks/tests/run-role-gates-tests.sh` runs green (module scope: no
  regression introduced by this change — the pre-existing failure noted
  in #179 finding 3 is #180's write set, not fixed here).
