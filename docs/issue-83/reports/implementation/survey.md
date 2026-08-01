# Current-state survey — issue-83 (canon-forms loop-body row pattern)

## Write set (projected)

- `core/hooks/tests/canon-forms.txt` — add one new registered pattern
  line for the fragment-loop's body row (currently only header
  `FRAGMENTS=(`, `for ... do`, and footer `done` are registered).
- `core/hooks/tests/run-stub-canon-forms-tests.sh` — extend/adjust the
  fragment-loop fixture so it regression-tests against the real
  sales-rulebook body-row shape, not only the synthetic
  `core_role_directive "$frag"` toy line already covered.
- `docs/handbooks/gate-house-standard.md` — one line noting the new
  registered shape, same placement basis as issue-78's own entry there.

No other file needs to move; this is a pure canon-forms.txt manifest
addition (issue-78's own extension mechanism), not a stub-check.sh logic
change.

## How classification actually works today (core/hooks/tests/stub-check.sh:110-137)

`stub-check.sh` computes `other` = every non-blank/non-comment/
non-shebang line of a `directive.sh` that does NOT match the built-in
exclusion:

```
^[[:space:]]*(#.*)?$|^#!|role-directive\.sh|core_role_directive|^[A-Za-z_][A-Za-z0-9_]*=
```

This is an unanchored substring match — a line is excused by the
built-in check alone if it merely *contains* `core_role_directive`
anywhere, or if it *starts with* `identifier=`. Only lines matching
neither the built-in exclusion nor any `canon-forms.txt` pattern fail as
"regrown boilerplate".

`canon-forms.txt` currently registers, under `fragment-loop:`:

```
^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*=\(          # e.g. FRAGMENTS=(
^[[:space:]]*for[[:space:]]+[A-Za-z_]...in[[:space:]]+  # the for-header
^[[:space:]]*done[[:space:]]*$                  # the loop footer
```

i.e. only loop *header* and *footer* shapes; no pattern targets a line
that lives *inside* the loop body.

## Why the existing regression test already passes but the real file doesn't

`run-stub-canon-forms-tests.sh`'s current fixture body row is literally
`core_role_directive "$frag"` — a line that already passes via the
built-in `core_role_directive` substring exclusion alone, with zero help
from `canon-forms.txt`. That fixture is therefore not a faithful
regression test of the registered-shape mechanism for the body row at
all; it happens to pass through a different path.

Issue #83 states the real `sales/hooks/directive.sh:16-23` loop body
still fails stub-check. Since a bare `core_role_directive "$frag"` line
would already pass via the built-in exclusion (as the existing fixture
shows), the real body row must take a shape the built-in exclusion does
not cover — most plausibly a *guarded* or *wrapped* invocation (e.g. a
conditional/existence-check before or around the call) rather than a
bare call. `sales-rulebook` is a separate repo not present in this
workspace, so its exact line text cannot be read directly here; this is
confirmed structurally (issue text + sales' own phase-1 investigation
cited in the issue), not by direct inspection.

## Prior art / decisions

- `docs/issue-78/reports/implementation.md` and
  `docs/handbooks/gate-house-standard.md:134-169` — established
  `canon-forms.txt` as the registry extension point for new
  `directive.sh` combination shapes ("a manifest line addition ... not a
  new hardcoded regex block"). This issue is exactly that extension
  mechanism's next use, not a new mechanism.
- `docs/handbooks/canon-scripts.md` — reference-not-vendor rule: a
  rulebook's real file is never copied wholesale into core's tree; a
  regression fixture reproduces the *shape*, not the literal file.

## Skip-condition check (scout-directive)

Scouting was skipped: this is a narrow, spec-bounded manifest-pattern
addition to an existing, already-designed registry (issue-78), not a
product-shaped surface with an external best-in-class category to
survey. The one open design question (what shape the real body row
takes) is answered by reading the real file in phase 2, not by web
research.
