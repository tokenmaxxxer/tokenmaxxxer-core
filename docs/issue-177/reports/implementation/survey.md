# issue-177 survey

Scout skip: pure defect-fix against an existing classifier (#173/#175's
`gate_is_role_directive_stub` + `canon-forms.txt`), no new product-facing
surface, no external category to benchmark against — the "field" here is
the four real rulebook repos themselves, not a market. Skip condition:
this is closer to a bugfix (replace guessed literals with real bytes) than
a design-decision task; the one open design point (how to express a
"sanctioned source line" structurally) is settled by the issue's own
suggested rule (b).

## What was cloned and inspected

Shallow-cloned the four Batch-1 blocking repos named in
`docs/issue-171/reports/implementation/rollout-runbook.md`'s partial-batch
row (that file lives only on the still-open issue-171/implementation
branch, not main — read via `git show origin/issue-171/implementation:...`):

- `architecture-rulebook` @ `da8565d615d9fb6c18487c9b338fa8b60bdf1120`
- `accessibility-rulebook` @ `ce5cbe5c4c55622001812ed18d8302221c2f5b21`
- `localization-rulebook` @ `da7144369f31800c8e4af3008a1379affc6daf0c`
- `capacity-planning-rulebook` @ `00273632123750aa3c5cff608729fa93f042b419`

Every `directive.sh` in each repo was read directly (not assumed):

- `architecture-rulebook/architecture/hooks/directive.sh` — real shape has
  **two** additional lines beyond `single-call`, neither matching
  `unregistered-stub` (which assumed a bare `<role>_directive_extra` call):
  line 14 sources `gate-lib.sh` with an `|| { echo ...; exit 0; }` fallback,
  line 15 calls the exported `gate_kill_switch_active` function with an
  `|| exit 0` fallback. Line 16 (sourcing `role-directive.sh`) is already
  excluded from the "other" check by `gate_is_role_directive_stub`'s own
  `grep -vE ...role-directive\.sh...` regex (gate-lib.sh:151), so only
  lines 14-15 are unregistered.
- `accessibility-rulebook/accessibility/hooks/directive.sh` — plain
  `single-call` shape already, scans clean.
- `accessibility-rulebook/wcag-em-directive/hooks/directive.sh` — **not a
  stub of core_role_directive at all**. It never sources
  `role-directive.sh` and never calls `core_role_directive`; it is a
  second, independent SessionStart hook (own `hooks.json` entry) that
  guards on `WCAG_EM_DIRECTIVE_OFF`/`CLAUDE_ROLE` and prints its own
  methodology text via `cat <<'EOF'`. It fails
  `gate_is_role_directive_stub` at the very first check ("does not source
  core/hooks/lib/role-directive.sh", gate-lib.sh:143-144) — no
  `canon-forms.txt` pattern addition can pass this file, since
  `canon-forms.txt` only affects the third check (collateral-line
  matching), never reached here. The `layered-directive` shape #175
  registered (a `.` source line pulling in a sibling directive fragment)
  does not exist anywhere in this file's real bytes — it was built from
  the issue-175 gap wording ("no layered-directive allowlist"), not the
  actual repo content.
- `localization-rulebook/localization/hooks/directive.sh` — plain
  `single-call`, scans clean.
- `localization-rulebook/localization/plugins/{mqm-tagging,verdict-axis,proposal-gate}/hooks/directive.sh`
  — not inspected in depth (repo's canon-duplication row in the runbook
  was "same directive.sh class, unconfirmed per-file", not attributed to a
  specific unmatched shape); out of this issue's cited scope.
- `capacity-planning-rulebook/capacity-planning/hooks/directive.sh` — plain
  `single-call` (source-with-fallback + one `core_role_directive` call),
  scans clean.
- `capacity-planning-rulebook/capacity-{threshold-decomposition,headroom-costnote,forecast-method,order-enforcement}/hooks/directive.sh`
  (4 files) — same "not a stub at all" shape as `wcag-em-directive`: a
  `trap`-based fail-closed guard, `set -uo pipefail`, and a `cat <<'EOF'`
  print block; none source `role-directive.sh` or call
  `core_role_directive`. Same categorical rejection at
  `gate_is_role_directive_stub`'s first check, same reason
  `canon-forms.txt` cannot fix it.

## Write surfaces this proposal can actually reach

- `core/hooks/tests/canon-forms.txt` — the file issue-177 names directly.
  Can fix `architecture-rulebook`'s real shape (structural rule per the
  issue's suggested wording: additional lines that only source
  `gate-lib.sh` or call one of its exported `gate_*` functions are
  sanctioned). Cannot fix the five standalone-hook files above by
  construction — canon-forms.txt patterns are never consulted for a file
  that fails `gate_is_role_directive_stub`'s first two checks.
- `core/hooks/tests/run-stub-canon-forms-tests.sh` — add/replace fixtures
  built from the real transcribed bytes (architecture-rulebook), drop the
  now-falsified `layered-directive` fixture/pattern (no real repo bytes
  support it), citing repo+sha per the acceptance.

## What is out of this proposal's reach, named honestly

The five standalone print-only directive.sh files (accessibility's
`wcag-em-directive`, capacity-planning's four methodology-framing plugins)
are a structurally distinct class — not a `core_role_directive` stub
variant at all — that `gate_is_role_directive_stub` rejects at the file
level before `canon-forms.txt` is ever consulted. Fixing them needs a
function-level decision in `gate-lib.sh` (e.g., recognize "never sources
role-directive.sh AND never calls core_role_directive AND contains no
canon-manifest-listed content" as a distinct sanctioned
"standalone-methodology-hook" shape), not a pattern registration. That is
a different write surface and a real design decision — out of this
proposal's frozen write set; flagged here rather than silently expanded
into, or silently left for the live re-scan to rediscover.
