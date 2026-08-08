# Survey: issue-183 stub-check.sh false-positive on canon-source tree

## Scout: skipped
Pure bugfix, no design decision open — the fix pattern (self-exclusion
for a file already living at its canonical repo path) is dictated by
the existing sibling implementation (`compliance-check.sh`), not chosen
from a field of options.

## Current state

`core/hooks/tests/stub-check.sh` (lines 59-76): for each name in
`CANON_GATES` (from `canon-manifest.txt`), it runs
`find "$dir" -maxdepth 3 -name "$name" -type f` and flags every hit as a
"vendored copy". When `$dir` is core's own `core/hooks` (the files'
actual canonical home), every real canon file matches its own name and
is flagged — issue-179 attempt 5's reproduced repro
(`tests/test_side_effect_round.py::test_attempt5_stub_check_false_positives_on_its_own_canon_source_tree`).

`core/hooks/tests/compliance-check.sh` (`--canon-duplication` mode,
lines ~29-95) already solves the general form of this problem: it
computes `repo_root` (three levels up from `core/hooks/tests/`) and,
for `directive.sh`, uses the structural `gate_is_role_directive_stub`
classifier instead of a bare filename hit; for every other manifest
entry it content-hashes each hit against `repo_root`'s own canonical
copies (`gate_content_hash_matches_canon`) rather than flagging on
filename match alone.

`stub-check.sh`'s directive.sh branch (lines 78-102) is unaffected by
this bug — that check is per-file structural classification, not a
filename-hit scan, and is issue-180's in-flight write set
(`core/hooks/lib/gate-lib.sh`'s `gate_is_role_directive_stub`,
`core/hooks/tests/canon-forms.txt`) which this issue does not touch.

## Write set

- `core/hooks/tests/stub-check.sh` — filter the `CANON_GATES` filename-hit
  loop (lines 59-76) so a hit resolving to this repo's own
  `core/hooks/` canonical location is not counted as vendored.
- `tests/test_side_effect_round.py` — flip
  `test_attempt5_stub_check_false_positives_on_its_own_canon_source_tree`
  to demonstrate-the-fix (assert clean scan on `core/hooks`, still add a
  fixture asserting a real violation elsewhere still flags).

## Constraint check

`core/hooks/lib/gate-lib.sh` and `core/hooks/tests/canon-forms.txt`
(issue-180's write set) are not touched — the fix here is scoped to
`stub-check.sh`'s filename-match loop only, not the `directive.sh`
structural branch that shares logic with #180.
