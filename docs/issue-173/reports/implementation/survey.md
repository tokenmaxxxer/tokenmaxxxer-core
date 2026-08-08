# Survey: issue-173 — content-based stub distinction for --canon-duplication

## Current state

`core/hooks/tests/compliance-check.sh --canon-duplication` (lines 24-53)
walks every name in `canon-manifest.txt` and does a pure `find "$target"
-name "$name" -type f` filename match. Any hit fails the scan. This is
correct for 13 of the 14 manifest entries — those files must never be
vendored at all (deleted per `docs/handbooks/canon-rollout.md` step 1).

`directive.sh` is the one exception. Per `canon-rollout.md` step 3, a
rolled-out rulebook does not delete its own `directive.sh` — it *reduces*
it to a small per-repo stub: shebang, local trap/`set -uo pipefail`,
`source .../core/hooks/lib/role-directive.sh`, and one `core_role_directive`
call with four role-unique strings. `role-directive.sh`'s own header
documents this shape explicitly. A correctly-rolled-out repo therefore
still *has* a file literally named `directive.sh` under its hooks tree —
and the current filename-only check flags it as a "vendored copy of core
canon file 'directive.sh'", which can never pass, confirmed by the #171
pilot blocking finding recorded against this issue.

`core/hooks/tests/stub-check.sh` already solves exactly this
classification problem for `directive.sh`, independently, in its second
half (the "directive.sh: structural check, not absence-based" block,
~line 80 onward):

- it sources `canon-forms.txt` (name:pattern lines) to get the set of
  sanctioned line shapes (`single-call`, `fragment-loop`, and the
  fragment-loop body-row patterns added for issue-83);
- for each `directive.sh` found, it checks: (a) does it source
  `role-directive.sh`, (b) does it call `core_role_directive`, (c) is
  every remaining non-blank/non-comment/non-shebang/non-assignment line
  one of those two, or matched by a registered `canon-forms.txt` pattern;
- a file failing any of those is FAIL ("regrown boilerplate" or "does not
  source .../not call ..."); a file passing all three is "ok — is a
  role-directive stub".

`core/hooks/directive.sh`, `scout/hooks/directive.sh`, and
`warrant/hooks/directive.sh` in *this* repo are full pre-promotion
directive bodies (159/67/89 lines, heredocs, kill-switch case logic) —
they predate the role-directive.sh promotion and are not stubs; they are
core's own hooks, not rulebook-side files subject to this check at all.
The stub shape only appears in *sibling rulebook* repos post-rollout,
which is exactly the `--canon-duplication <rulebook-path>` mode's target
audience — this repo has no local fixture of a rolled-out stub to look at
directly, but `stub-check.sh`'s structural check is the specification.

## Write set implications

- `core/hooks/tests/compliance-check.sh`: the `--canon-duplication` loop
  needs a `directive.sh`-specific branch that runs the same
  source-line/core_role_directive/other-lines classification stub-check.sh
  already runs, instead of an unconditional filename-match FAIL.
- Duplicating stub-check.sh's ~35-line classification block verbatim
  inside compliance-check.sh would create a second, independently
  maintained copy of the exact same logic — the drift class both scripts
  exist to prevent (compliance-check.sh's own header already states this
  concern about canon-manifest.txt itself). The classification block
  belongs in one place both scripts call.
- `core/hooks/lib/gate-lib.sh` is already the shared shell library both
  scripts source elsewhere in this codebase (`gate_kill_switch_active`,
  `gate_bash_write_targets`, `gate_reconstruct_write`) — the natural home
  for a new `gate_is_role_directive_stub <file>` function using
  `canon-forms.txt` the same way stub-check.sh does today.
- `core/hooks/tests/run-fleet-scan-tests.sh` (or a new/adjacent test
  file under `core/hooks/tests/`) needs the red-green pair the issue's
  acceptance names: a correct per-repo stub scans clean under
  `--canon-duplication`, a vendored full copy (e.g. a fixture directive.sh
  with a hand-rolled case/heredoc body) still flags.
- `core/hooks/tests/run-stub-canon-forms-tests.sh` already exercises
  stub-check.sh's classification against canon-forms.txt shapes — worth
  checking it still passes unchanged, since the shared function must
  preserve stub-check.sh's existing pass/fail behavior exactly (no
  behavior change intended for stub-check.sh itself, only reuse).

## Alternatives considered (for the proposal's Rationale)

1. **Extract the classification into `gate-lib.sh` as a shared function**
   called by both stub-check.sh and compliance-check.sh's
   --canon-duplication branch.
2. **Duplicate the classification logic** directly inside
   compliance-check.sh, independent of stub-check.sh.
3. **Size/marker heuristic** (issue text's alternative phrasing): compare
   file size or a marker comment against the canonical stub template,
   without reusing stub-check.sh's structural line-shape check.

## Skip-condition check

Scouting: this is a same-repo consistency fix inside an established,
already-designed detection mechanism (role-directive.sh promotion,
issue-66/69/78/83) — no external product-shaped surface, no design
decision about competitive positioning. The design decision that exists
(how to distinguish stub from vendored copy) is resolved by matching the
codebase's own already-established stub-check.sh mechanism, not by
researching outside best-in-class. Scout sweep skipped: spec/prior
in-repo decisions leave no external-facing design choice open (scout
directive's second skip condition, applied at the mechanism level rather
than the whole-issue level since the issue's acceptance text names a
content-based check but not which one).
