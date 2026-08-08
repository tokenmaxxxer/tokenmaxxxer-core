---
status: proposed
files:
  - core/hooks/lib/gate-lib.sh
  - core/hooks/tests/compliance-check.sh
  - core/hooks/tests/canon-manifest.txt
  - core/hooks/tests/canon-forms.txt
  - core/hooks/tests/run-compliance-scan-scope-tests.sh
  - core/hooks/tests/run-canon-duplication-content-tests.sh
  - core/hooks/tests/run-stub-canon-forms-tests.sh
---

## Request

`compliance-check.sh --canon-duplication` still matches every manifest entry
except `directive.sh` by filename alone, misclassifying a role-specific gate
(e.g. pricing-rulebook's own `scope-gate.sh`) as a vendored core copy.
Separately, `gate_is_role_directive_stub` has no registered pattern for two
real directive.sh combination shapes (architecture-rulebook,
accessibility-rulebook), so both fail as "regrown boilerplate." Extend #173's
content-based approach to the rest of the manifest, and register the two
missing shapes.

## Constraints

- `directive.sh` keeps its existing structural path
  (`gate_is_role_directive_stub`) unchanged — its content legitimately
  differs from core's canon file on every sanctioned stub, so hash-equality
  is never the right test for it (confirmed in survey).
- Every other manifest entry gets a content-hash compare against its one
  resolvable canonical source inside this repo's `core/` tree: identical
  content = vendored (flag); different content under the matching filename =
  role-specific, clean (per the issue's acceptance wording verbatim).
- `canon-manifest.txt`'s flat-filename format and `canon-forms.txt`'s
  `name:pattern` format (issue-78/83) stay as-is — no new manifest schema.
- No access to the two real repos (architecture-rulebook,
  accessibility-rulebook) named in the issue; their literal directive.sh
  bytes are unavailable. Fixtures for both are constructed from the issue's
  own gap descriptions ("unregistered stub shape", "no layered-directive
  allowlist"), following the same shape as the existing `single-call`/
  `fragment-loop` entries — stated here as an assumption, not hidden.

## Rationale

Considered generalizing `gate_is_role_directive_stub` to cover all 14
manifest entries instead of adding a separate content-hash path, so there'd
be one classifier, not two. Rejected: that function's contract is "structural
match against a sanctioned-customization allowlist" — appropriate for
`directive.sh`, which is explicitly supposed to vary per rulebook. Files like
`trailer-gate.sh` or `gate-lib.sh` carry no such customization contract; the
issue's acceptance criterion is a hash compare ("content hash vs core canon =
vendored"), a strictly tighter bar than a structural allowlist would give —
loosening every other canon file to "close enough to boilerplate" would
regress the exact vendoring class this check exists to catch.

## What will be done

1. Add `gate_content_hash_matches_canon <hit-file> <canon-file>` to
   `gate-lib.sh` (sha256 compare, reused by compliance-check.sh so the
   comparison logic isn't independently re-derived — same reuse rationale as
   #173's extraction of `gate_is_role_directive_stub`).
2. In `compliance-check.sh --canon-duplication`, for every manifest name
   other than `directive.sh`: resolve its one canonical path inside this
   repo's own `core/` tree (bounded lookup, not the scanned target), hash-
   compare each hit against it, and only flag hits that match. `directive.sh`
   keeps its current `gate_is_role_directive_stub` branch untouched.
3. Register `architecture-rulebook` and `accessibility-rulebook` directive.sh
   shapes in `canon-forms.txt`, built from the issue's gap descriptions and
   the existing `single-call`/`fragment-loop` pattern precedent (see
   Constraints — stated assumption).
4. Add red-green pairs (3, per acceptance) to new/existing test files under
   `core/hooks/tests/`, following the `run-stub-canon-forms-tests.sh` /
   `run-compliance-scan-scope-tests.sh` synthetic-`$td`-repo idiom already in
   use:
   - pricing-rulebook-shaped `scope-gate.sh` (different content, same
     filename as a manifest entry) scans clean; a byte-identical copy of the
     real canon file still flags.
   - architecture-rulebook stub shape scans clean.
   - accessibility-rulebook stub shape scans clean.
5. Wire the new test file into whatever currently invokes
   `run-compliance-scan-scope-tests.sh` / `run-stub-canon-forms-tests.sh`
   (the pre-existing run-all.sh/run-fleet-scan-tests.sh wiring gap #173's
   hunt already flagged stays out of scope — noted there, not respawned
   here).

## Out of scope

- The pre-existing run-all.sh/run-fleet-scan-tests.sh wiring gap (#173's
  hunt finding) — unrelated to this issue's manifest/stub-shape gaps.
- `parse-check.sh`'s multi-plugin duplication (core/terse/freelunch/scout
  each carry a copy) — those are core's own plugins, not the rulebook-repo
  scan target `--canon-duplication` exists to check.
- Any change to `canon-manifest.txt`'s or `canon-forms.txt`'s file format.

## How you'll know it worked

`core/hooks/tests/run-fleet-scan-tests.sh`-style red-green pairs (3, per
acceptance) pass: pricing-rulebook's own `scope-gate.sh` scans clean while a
byte-identical vendored copy still flags, and both the architecture-rulebook
and accessibility-rulebook stub shapes scan clean.
