---
status: proposed
files:
  - core/hooks/lib/gate-lib.sh
  - core/hooks/tests/canon-forms.txt
  - core/hooks/tests/run-stub-canon-forms-tests.sh
  - docs/handbooks/fleet-scan-tests.md
---

## Request

Replace `directive.sh`'s canon-forms.txt shape-registration matcher with
a structural line classifier: a `directive.sh` is sanctioned iff every
non-comment/non-blank line is one of {a `.`/`source` of `gate-lib.sh`,
`role-directive.sh`, or a sibling `*-directive.sh`, under any quoting; a
call to an exported `gate_*` function; a shebang/`set -e` preamble
line}. Remove all directive.sh shape rows from canon-forms.txt. Two
structural gaps in the current regex rows (a nested-double-quoted source
path breaks a quote-anchored regex; a direct `role-directive.sh` source
with no preceding `gate-lib.sh` source matches nothing) block all four
Batch-1 fleet-scan repos and must not be patched with more literal rows.

## Constraints

- No per-repo shape registrations for `directive.sh` remain in
  `canon-forms.txt` after this change.
- Fixtures for the four cited repos must be byte-exact and cite repo+sha
  (already fetched this session from the real repos at the SHAs recorded
  in `docs/issue-177/reports/implementation/survey.md`).
- A vendored full copy and a stub-plus-extra-logic file must both still
  flag as non-sanctioned.
- The two prerequisite checks already in `gate_is_role_directive_stub`
  (must source `role-directive.sh`; must call `core_role_directive`) stay
  as-is — this issue only replaces the classification of the remaining
  "other" lines, not those two gates.
- The gate_* one-token-per-physical-line cap (issue-177 semicolon-chain
  hunt fix) must survive the rewrite; it is a correctness property of the
  classifier, not an artifact of the old regex table.

## Rationale

Considered keeping canon-forms.txt as a regex table and adding two more
rows (nested-quote-tolerant gate-lib-source/role-directive-source
variants) — rejected because this is literally the third round of that
approach (#78, #173, #175, #177 each added rows and each round still
left real Batch-1 repos scanning dirty; the issue explicitly forbids
this path: "further literal patches forbidden"). A quote-tolerant regex
for an arbitrarily-nested `$(...)`-containing path expression is also
not expressible as a single anchored pattern in the first place — the
right test for "does this source line target gate-lib.sh" is "does the
line's argument contain `gate-lib.sh` as a substring," not "does the
line match a specific quoting shape," which is a classifier property,
not a pattern-table entry.

Considered making `gate_is_role_directive_stub` shell out to `bash -n`
plus AST-level inspection (e.g. via a real shell parser) instead of
line-oriented classification — rejected as disproportionate: the file
class in question is a 1-15 line stub by construction, every real and
sanctioned shape observed across all five repos surveyed is a single
statement per physical line, and a full parser is new tooling this repo
does not otherwise depend on for a problem line-level substring/regex
classification already solves once the classifier stops trying to match
whole-line shapes and starts asking "which of these mutually exclusive
per-line categories does this line belong to."

## What will be done

- Rewrite `gate_is_role_directive_stub`'s "other line" loop in
  `core/hooks/lib/gate-lib.sh` to classify each remaining line (after the
  existing exclusions: blank/comment, shebang, the `role-directive.sh`
  source line, the `core_role_directive` call line, bare `VAR=value`
  assignments) against three structural categories instead of a
  canon-forms.txt regex table:
  1. a `.`/`source` line whose argument, after stripping the directory
     portion, ends exactly in `/gate-lib.sh`, `/role-directive.sh`, or a
     sibling `/*-directive.sh` basename (`grep -oE` on the trailing
     `[A-Za-z0-9_-]+-directive\.sh$|/(gate-lib|role-directive)\.sh$`
     component of the resolved argument, not a raw substring-anywhere
     test) — tolerates arbitrary nested quoting and `$(...)` command
     substitution in the *directory* portion of the path expression,
     with an optional trailing `|| { ...; exit N; }` or `|| exit N`
     fallback. A lookalike target such as
     `gate-lib.sh.backdoor/inject.sh` fails this test (its basename is
     `inject.sh`, not `gate-lib.sh`) — closes the after-proposal
     warrant-hunt finding (`docs/reports/2026-08-08-hunt-canon-forms-real-bytes.md`,
     "after-proposal — stance 0") against a naive substring-of-argument
     test;
  2. a line calling exactly one `gate_<name>` function (reusing the
     existing gate_word_count > 1 rejection so the semicolon-chain cap
     from issue-177 still holds), optionally followed by `|| exit N` —
     scoped to lines appearing *after* a category-1 line has matched
     `gate-lib.sh` earlier in the same file (a `gate_*` call before any
     `gate-lib.sh` source cannot be a real export, since nothing has
     defined it yet, and is rejected as an "other" line instead of
     silently passing on call-site shape alone). This does not verify
     the callee is one of `gate-lib.sh`'s actual exports (still call-site
     shape, not provenance) but does close the same finding's second
     half: an attacker-defined `gate_evil` sourced from a non-canon file
     can no longer piggyback on category 1's now-basename-anchored test
     to get its defining source line admitted in the first place;
  3. `set -e`/`set -euo pipefail`-family preamble lines (shebang itself
     is already excluded upstream).
  A `for`/`do`/`done` loop body whose only statement lines are category-1
  sibling-directive.sh sources (sales-rulebook's fragment-loop shape)
  classifies under category 1 line-by-line plus the loop keywords
  themselves as a fourth, narrow "loop syntax" allowance — kept minimal
  and only covering `for`/`do`/`done`/`in` keyword lines, so the
  fragment-loop fixture keeps passing without reintroducing a
  shape-specific regex.
  Any line matching none of these ⇒ fail, same "regrown boilerplate"
  message shape as today.
- Delete the two directive.sh shape blocks from
  `core/hooks/tests/canon-forms.txt` (the #177 gate-lib-source/gate-call
  rows and the #78/#173 single-call/fragment-loop rows); nothing else in
  the repo reads this file, and `gate_is_role_directive_stub`'s
  canon-forms.txt-loading code is removed along with the rows it fed.
- Add byte-exact fixtures to `core/hooks/tests/run-stub-canon-forms-tests.sh`,
  each citing repo+sha, covering: architecture-rulebook's
  gate-lib.sh-then-role-directive.sh nested-quote shape (@
  `da8565d615d9fb6c18487c9b338fa8b60bdf1120`), accessibility-rulebook's
  direct nested-quote role-directive.sh source with no gate-lib.sh (@
  `ce5cbe5c4c55622001812ed18d8302221c2f5b21`), localization-rulebook's
  same direct-source shape (@ `da7144369f31800c8e4af3008a1379affc6daf0c`),
  capacity-planning-rulebook's direct-source-with-fallback shape (@
  `00273632123750aa3c5cff608729fa93f042b419`) — all four expected to
  pass; a vendored full copy of `role-directive.sh` (expected fail); a
  sanctioned stub with one extra non-classifiable logic line appended
  (expected fail); re-verify the existing fragment-loop/single-call/
  malformed/uncapped-chain fixtures still pass/fail as before under the
  new classifier. Add a grep assertion in the same file that
  `canon-forms.txt` carries no `directive.sh`-shape rows.
- Update `docs/handbooks/fleet-scan-tests.md`'s coverage description to
  describe the line classifier and correctly name
  `run-stub-canon-forms-tests.sh` as the file owning this suite (the
  issue text cites `run-fleet-scan-tests.sh`, which does not contain
  these tests today — noted here so the delivered PR does not silently
  diverge from the issue's stated check location without saying so).

## Out of scope

- The standalone print-only directive.sh class
  (`wcag-em-directive/hooks/directive.sh`, capacity-planning's 4
  sub-plugin files) — these fail the pre-existing prerequisite checks
  before line classification runs, and the issue text does not name this
  class.
- Confirming localization-rulebook's and capacity-planning-rulebook's
  remaining per-facet directive.sh files (3 and 4 respectively, beyond
  the top-level one already fetched and fixture-cited) line-by-line —
  the top-level file's shape is confirmed and representative of docs/
  issue-171 Session 4's stated gap; a full per-file sweep of every
  sub-plugin directive.sh across all four repos is the next open finding
  in that record, not this issue's stated acceptance criteria.
- Actually pushing any fix into the four sibling rulebook repos, or
  re-running the live fleet scan against them — this issue's acceptance
  is the classifier + local test suite; closing Batch 1 in the fleet
  roster is docs/issue-171's own next-steps item.
- `canon-manifest.txt`'s unconditional filename-drift mechanism (used by
  trailer-gate.sh, record-fields-gate.sh, etc.) — untouched, unrelated
  mechanism.

## How you'll know it worked

- `core/hooks/tests/run-stub-canon-forms-tests.sh` passes locally with
  the four new byte-exact repo fixtures green, the vendored-copy and
  stub-plus-extra-logic fixtures red, and the pre-existing fixtures
  (fragment-loop, single-call, malformed, uncapped-chain) still exercised
  with the same expected outcome as before.
- A grep in that same test file confirms `canon-forms.txt` has zero
  `directive.sh`-shape entries.
- `core/hooks/tests/run-fleet-scan-tests.sh` still passes unmodified
  (its own coverage — the two synthetic `--canon-duplication` fixtures —
  is unaffected by this change).
