# issue-175 survey

Scout skip: pure extension of an already-approved pattern (#173's content-based
directive.sh check) to the rest of the manifest, plus registering two known
stub shapes into an existing registry format — no new product-facing surface,
no external category to benchmark against. Skip condition: "the spec leaves
no design decision open" beyond the two design points captured under
Constraints below, which are settled by the pattern #173 already established.

## Write surfaces

- `core/hooks/tests/compliance-check.sh` — `--canon-duplication` mode
  (core/hooks/tests/compliance-check.sh:24-72). Currently: filename-only
  `find` match for every manifest entry except `directive.sh`, which alone
  gets `gate_is_role_directive_stub` structural classification
  (compliance-check.sh:46-65).
- `core/hooks/lib/gate-lib.sh` — houses `gate_is_role_directive_stub`
  (gate-lib.sh:126-177), the reusable classifier #173 extracted. A sibling
  content-hash helper belongs here for the same reuse reason (stub-check.sh
  and compliance-check.sh must not independently re-derive the comparison).
- `core/hooks/tests/canon-manifest.txt` — flat list of bare filenames, one
  per manifest entry (14 entries; confirmed one canonical source path each
  inside this repo except `parse-check.sh`, which core/terse/freelunch/scout
  each carry their own copy of — those are core's own plugins, not scan
  targets, so out of scope here).
- `core/hooks/tests/canon-forms.txt` — registered directive.sh combination
  shapes (issue-78/issue-83 format: `name:pattern` lines,
  `gate_is_role_directive_stub` unions all patterns when classifying non-
  boilerplate lines). Currently holds `single-call` and `fragment-loop`
  (sales-rulebook). Needs two more: architecture-rulebook, accessibility-
  rulebook.
- `core/hooks/tests/run-compliance-scan-scope-tests.sh` and/or a new sibling
  test file — existing test harness pattern for compliance-check.sh
  (`report`/synthetic-repo-under-`$td` idiom, same as
  run-stub-canon-forms-tests.sh). The acceptance's "3 red-green pairs" land
  here.

## What #173 already solved, and what's still open

#173 gave `directive.sh` a *structural* pass — content will legitimately
differ from core's canon file every time it's a sanctioned stub, so content-
hash equality was never the right test for that one entry; that's why it
still needs `gate_is_role_directive_stub`, not a hash compare.

For every other manifest entry, the file is meant to be sourced/reused
byte-for-byte (a core canon script, not a customization surface) — the
issue's own acceptance line states the rule: "content hash vs core canon =
vendored; different content under a matching name = role-specific, clean."
That's a plain content-hash test, not a new structural classifier. Two
design points this settles:

1. Each manifest name needs one resolvable canonical source path inside
   `core/`'s own tree to hash against. Confirmed present for 13 of 14
   entries (see filesystem sweep above); `canon-manifest.txt`'s current
   flat-filename format has no path field, so path resolution needs either
   a second column or a fixed `find core -name "$name"` lookup restricted to
   this repo's own core tree (the layout compliance-check.sh already knows,
   vs. an unbounded search of the scanned target).
2. `directive.sh` keeps its existing branch (structural, unchanged); the new
   content-hash path applies to the other 13 entries, replacing their
   filename-only match.

## Stub-shape gap (architecture-rulebook, accessibility-rulebook)

The issue names two concrete real-repo misclassifications against
`gate_is_role_directive_stub`, distinct from the content-hash gap above:

- architecture-rulebook: "an unregistered stub shape" — a sanctioned
  directive.sh combination that doesn't match `single-call` or
  `fragment-loop`, so it currently fails as "regrown boilerplate" at
  gate-lib.sh:167-169.
- accessibility-rulebook: "no layered-directive allowlist" — implies a
  different combination shape again (layered sourcing, not the sales single-
  array fragment-loop), currently also unclassified.

I have no access to the two real repos referenced (10 real repos, per the
issue) to pull their literal directive.sh bytes. `canon-forms.txt`'s existing
entries (issue-78 `single-call`, issue-83 `fragment-loop`) are the only
precedent for how a registered shape's patterns are described; the proposal
below commits to constructing representative fixtures at build time,
following that same precedent and the two gap descriptions verbatim, and
flags this as an explicit assumption (not silently derived).

## Alternatives considered

- Generalize `gate_is_role_directive_stub` itself to cover all 14 entries
  (one classifier, no content-hash path). Rejected: the function's whole
  contract is "sanctioned customization allowed, verified structurally" —
  applying that to files with zero customization contract (e.g.
  `trailer-gate.sh`) would mean accepting arbitrary edits to a core gate as
  long as the diff vaguely resembles boilerplate, which is looser than what
  the issue asks for ("content hash vs core canon = vendored" is a much
  tighter bar than a structural allowlist).
