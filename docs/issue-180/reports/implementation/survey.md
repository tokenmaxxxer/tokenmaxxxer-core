# Survey — issue-180 (directive.sh line classifier)

## Current mechanism (canon-forms.txt + gate_is_role_directive_stub)

`core/hooks/lib/gate-lib.sh:126-208` (`gate_is_role_directive_stub`) is the
sole classifier for a rulebook's `directive.sh`, called from
`stub-check.sh` and `compliance-check.sh --canon-duplication`. Flow:

1. Require the file to contain something matching
   `role-directive\.sh["']?[[:space:]]*$|role-directive\.sh"` (sources
   `role-directive.sh`) — else fail.
2. Require `core_role_directive` literal — else fail.
3. Collect "other" lines: everything except blank/comment lines, the
   shebang, any line mentioning `role-directive.sh` or
   `core_role_directive`, and bare `VAR=value` assignment lines.
4. Each "other" line is tried in order against
   `core/hooks/tests/canon-forms.txt` (`name:pattern` rows, parsed at
   runtime into parallel arrays). Two rows currently exist, both added in
   #177 from architecture-rulebook's real bytes:
   - `gate-lib-source`: `^[[:space:]]*\.[[:space:]]+"[^"]*gate-lib\.sh"(...)?[[:space:]]*$`
   - `gate-call`: `^[[:space:]]*gate_[A-Za-z_][A-Za-z0-9_]*[[:space:]]...`
   Plus older rows (`single-call`, `fragment-loop` x6) from #78/#173.
   `gate-lib-source`/`gate-call` are capped to one match each (issue-177
   uncapped-repetition hunt fix), and any physical line containing more
   than one `gate_<name>` token is rejected outright regardless of regex
   match (issue-177 semicolon-chain hunt fix, commit `3c6f44d`).
5. Any line matching nothing ⇒ fail ("looks like regrown boilerplate").

`canon-forms.txt` (`core/hooks/tests/canon-forms.txt`) holds only
directive.sh shape rows — nothing else consumes it. Other canon-drift
checks (trailer-gate.sh, record-fields-gate.sh, etc.) use a *different*,
unconditional filename-manifest mechanism (`canon-manifest.txt`) that is
out of this issue's scope.

Red/green tests for this classifier live in
`core/hooks/tests/run-stub-canon-forms-tests.sh` (not
`run-fleet-scan-tests.sh`, despite the issue text naming the latter —
`run-fleet-scan-tests.sh` only exercises `compliance-check.sh
--canon-duplication` with two synthetic fixtures unrelated to
canon-forms.txt shape rows; the actual per-shape pass/fail suite is
`run-stub-canon-forms-tests.sh`, added in #78/#173/#177). Current fixture
set: `fragment-loop` (pass), `regrown-boilerplate` (fail), `single-call`
(pass), architecture-rulebook's real gate-lib/gate-call shape (pass), an
uncapped vendored gate_* chain (fail), a non-gate-lib `.`-source line
(fail). No fixture yet covers either gap from this issue.

## Why #177 didn't close the four Batch-1 repos (docs/issue-171 record,
`origin/issue-171/implementation:docs/issue-171/reports/implementation.md`
Session 4, lines 383-478)

Two structural gaps, confirmed against real bytes fetched this session
(`gh repo clone` + `git show <sha>:<path>`, all four repos, exact SHAs
from `docs/issue-177/reports/implementation/survey.md`):

**architecture-rulebook** @ `da8565d615d9fb6c18487c9b338fa8b60bdf1120`,
`architecture/hooks/directive.sh` (byte-exact, fetched):
```
#!/usr/bin/env bash
# ...7 comment lines...
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh" || { echo "architecture/directive.sh: cannot source gate-lib.sh" >&2; exit 0; }
gate_kill_switch_active "${ARCHITECTURE_CYCLE_OFF:-}" || exit 0
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/role-directive.sh" || { echo "architecture/directive.sh: cannot source role-directive.sh" >&2; exit 0; }
core_role_directive "..." "..." "..." "..."
```
This is the shape #177's two canon-forms.txt rows were transcribed from
— it still fails today because `run-fleet-scan.sh`'s real-world re-scan
(docs/issue-171 Session 4) found the `gate-lib-source` regex's
`"[^"]*gate-lib\.sh"` anchor breaks the moment the path expression itself
contains a `"` (which it does: `$(dirname "${BASH_SOURCE[0]}")`), so the
`[^"]*` class terminates at the first inner quote and the pattern never
reaches `gate-lib.sh"` at the end of line. Line 16's direct
`role-directive.sh` source (following the gate-lib.sh source) is a
second, structurally identical failure — no registered row tolerates
nested quotes for either target file.

**accessibility-rulebook** @ `ce5cbe5c4c55622001812ed18d8302221c2f5b21`,
`accessibility/hooks/directive.sh` (byte-exact, fetched):
```
#!/usr/bin/env bash
# ...3 comment lines...
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/role-directive.sh"

YOU_DECIDE="..."
USE_WHEN="..."
PRODUCES="..."
HAND_OFF="..."

core_role_directive "$YOU_DECIDE" "$USE_WHEN" "$PRODUCES" "$HAND_OFF"
```
No `gate-lib.sh` source at all — `role-directive.sh` is sourced directly,
first line of substance, with the same nested-quote path expression. This
is gap (b): every registered row assumes a `gate-lib.sh` source precedes
the `core_role_directive` call (architecture-rulebook's shape); nothing
covers a bare direct source. (The `VAR="..."` assignment lines already
pass today via the existing `^[A-Za-z_][A-Za-z0-9_]*=` bare-assignment
exclusion in `gate_is_role_directive_stub` — not part of this gap.)

**localization-rulebook** @ `da7144369f31800c8e4af3008a1379affc6daf0c`,
`localization/hooks/directive.sh` (byte-exact, fetched — 4 total
directive.sh files exist in this repo; only the top-level one checked
against this issue's two gaps, matching docs/issue-171's own scope):
```
#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/role-directive.sh"
core_role_directive "..." "..." "..." "..."
```
Same shape as accessibility-rulebook's: direct nested-quote
`role-directive.sh` source, no `gate-lib.sh`, `core_role_directive`
called inline with string-literal args (not `$VAR` refs).

**capacity-planning-rulebook** @
`00273632123750aa3c5cff608729fa93f042b419`,
`capacity-planning/hooks/directive.sh` (byte-exact, fetched — 5 total
directive.sh files exist; only the top-level one checked):
```
#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/role-directive.sh" || { echo "directive.sh: cannot source role-directive.sh" >&2; exit 2; }
core_role_directive "..." $'...' $'...'
```
Same direct-source, no-gate-lib shape, plus an `|| { ...; exit 2; }`
fallback on the source line (architecture-rulebook's fallback exits 0;
this one exits 2 — the fallback's exit code is not itself a
classification signal and should not be pattern-matched).

All four therefore share: no `gate-lib.sh` source, a `role-directive.sh`
source whose path expression contains nested double quotes. This
confirms both gaps from the issue text and gives four real, byte-exact,
cited fixtures plus the still-passing architecture-rulebook shape (which
also needs the nested-quote tolerance despite having a `gate-lib.sh`
source, since its own path expression is the same nested form).

## What "sanctioned" already excludes today (kept, not touched)

- Non-`role-directive.sh`-sourcing, non-`core_role_directive`-calling
  standalone print hooks (`wcag-em-directive/hooks/directive.sh`,
  capacity-planning's 4 sub-plugin files) fail at the *prerequisite*
  checks (step 1/2 above), before any per-line classification is
  consulted. Issue #180's line-classifier requirement is scoped to what
  happens to the "other" lines once those two prerequisites already
  hold — it does not touch this class, consistent with the issue text
  (which names only the nested-quote and no-preamble gaps).
- `sales-rulebook`'s fragment-array for-loop shape (`fragment-loop` rows,
  #78/#173) is a currently-registered canon-forms.txt shape with no
  reported real-world regression. The issue requires "no per-repo shape
  registrations for directive.sh remain" in canon-forms.txt — this shape
  must be re-expressed as bona fide line-classifier categories (for/do
  loop body lines are themselves `.`-source-of-sibling-`*-directive.sh`
  lines plus loop syntax) rather than dropped, or the fixture regresses.

## gate_* function inventory (`core/hooks/lib/gate-lib.sh`)

`gate_trap_fail_closed`, `gate_kill_switch_active`, `gate_deny`,
`gate_allow`, `gate_bash_write_targets`, `gate_budget_exceeded`,
`gate_is_role_directive_stub`, `gate_content_hash_matches_canon`. No
separate export manifest — all top-level `gate_*` functions in this file
are equally callable from a rulebook's own gate scripts by convention.

## Write set this proposal will need

- `core/hooks/lib/gate-lib.sh` — replace `gate_is_role_directive_stub`'s
  canon-forms.txt-driven "other line" loop with a structural line
  classifier (source-of-{gate-lib.sh,role-directive.sh,sibling
  `*-directive.sh`} any-quoting / gate_* call / shebang-`set -e`
  preamble), keeping the existing gate_* one-token-per-line cap (issue-177
  hunt fix) and the two prerequisite checks as-is.
- `core/hooks/tests/canon-forms.txt` — delete the directive.sh shape rows
  (both the #177 gate-lib-source/gate-call rows and the #78/#173
  single-call/fragment-loop rows); nothing else reads this file, so it
  either becomes empty (header comment only) or is removed outright.
- `core/hooks/tests/run-stub-canon-forms-tests.sh` — new fixtures: the
  four repos' real directive.sh bytes above (nested-quote,
  gate-lib+direct-source combo, no-preamble direct-source), a vendored
  full-copy fail case, a stub-plus-extra-logic fail case, re-verify
  existing fragment-loop/single-call/malformed cases still pass under the
  new classifier; assert (grep) that canon-forms.txt carries no
  directive.sh shape rows.
- `docs/handbooks/fleet-scan-tests.md` — update the coverage description
  to describe the line classifier instead of canon-forms.txt shapes, and
  correct/confirm which test file actually owns this suite.

No new dependency, env var, or migration.
