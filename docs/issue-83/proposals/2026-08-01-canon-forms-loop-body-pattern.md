files: core/hooks/tests/canon-forms.txt, core/hooks/tests/run-stub-canon-forms-tests.sh, docs/handbooks/gate-house-standard.md

## Request

core #78's `canon-forms.txt` registers `directive.sh`'s fragment-loop
header (`FRAGMENTS=(`, `for ... do`) and footer (`done`) as sanctioned
shapes, but no pattern for a line living *inside* the loop body.
sales-rulebook's approved (issue-10) fragment-loop still fails
stub-check at `sales/hooks/directive.sh:16-23` because its body row
takes a shape the built-in exclusion (bare `core_role_directive`
substring / bare assignment) doesn't cover. Add a `canon-forms.txt`
body-row pattern and regression-test it against the real sales shape.

## Constraints

- `sales-rulebook` is a separate repo, not present in this workspace —
  the exact body-row text cannot be read here in phase 1; it must be
  read from the real file at phase-2 build time (via `gh` cross-repo
  access or a copy the user supplies), not guessed.
- Per `docs/handbooks/canon-scripts.md`'s reference-not-vendor rule, the
  real file is never copied wholesale into core's tree — the regression
  fixture reproduces the row's *structural shape* (a generalized
  pattern), not a verbatim excerpt.
- The fix stays inside `canon-forms.txt`'s existing registry mechanism
  (issue-78) — a manifest line addition, not new `stub-check.sh` logic.

## Rationale

**Chosen: add one new `fragment-loop:` pattern line to `canon-forms.txt`
for the body row**, keyed off the actual shape read from
`sales/hooks/directive.sh:16-23` in phase 2, plus a fixture in
`run-stub-canon-forms-tests.sh` that mirrors that shape (not the current
`core_role_directive "$frag"` toy line, which already passes through the
built-in exclusion and therefore regression-tests nothing about the
registry mechanism for body rows).

**Alternative considered and rejected: widen the built-in exclusion in
`stub-check.sh`** (e.g. loosen the assignment/substring match so more
line shapes pass automatically, without a `canon-forms.txt` entry).
Rejected because it re-opens the exact hole issue-78 closed: a
structural check that quietly accepts more shapes than are explicitly
registered stops being auditable — every future sanctioned combination
shape must be a manifest line, visible in `canon-forms.txt`, not a
broadened regex buried in `stub-check.sh`'s logic (per
`docs/handbooks/gate-house-standard.md:152-156`'s already-recorded
"config-driven registry over hardcoded regex" rule).

## What will be done

1. Read `sales/hooks/directive.sh:16-23` (the real file, cross-repo) to
   identify the exact body-row shape stub-check currently classifies as
   "other" (regrown boilerplate).
2. Add one new `fragment-loop:` pattern to `canon-forms.txt` generalizing
   that row's structure (not a literal-string match), following the
   existing `name:pattern-description` convention and inline comment
   style already used for the header/footer entries.
3. Update `run-stub-canon-forms-tests.sh`'s fragment-loop fixture to
   include a body row of that same generalized shape (replacing or
   augmenting the current `core_role_directive "$frag"` line), so the
   suite actually exercises the new registry entry instead of passing
   via the pre-existing built-in exclusion.
4. Add one line to `docs/handbooks/gate-house-standard.md` (next to the
   existing issue-78 fragment-loop paragraph) noting the body-row
   pattern and why it was needed.
5. Run `core/hooks/tests/run-all.sh` and, if cross-repo access to
   sales-rulebook is available, `stub-check.sh` directly against its
   real `hooks/` directory.

## Out of scope

- Any change to `sales-rulebook` itself (separate repo, separate role).
- Any other `stub-check.sh` structural rule or `canon-forms.txt` shape
  besides the one loop-body row this issue names.
- Re-litigating the split-file alternative already deferred in
  issue-78's record.

## How you'll know it worked

- `run-stub-canon-forms-tests.sh` passes with a fixture body row that
  mirrors the real sales shape (not the old toy line).
- `core/hooks/tests/run-all.sh` stays green.
- If sales-rulebook is reachable in phase 2: `stub-check.sh` run
  directly against its `hooks/` directory returns rc=0 for
  `directive.sh` (currently RED per the issue).
