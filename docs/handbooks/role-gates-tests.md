# role-agnostic gates test harness

`core/hooks/tests/run-role-gates-tests.sh` exercises the three
CLAUDE_ROLE-parameterized canon gates — `trailer-gate.sh`,
`record-fields-gate.sh`, `handbook-trigger-gate.sh` — as real subprocesses,
plus `core/hooks/tests/stub-check.sh`.

Run it directly, no setup required:

    bash core/hooks/tests/run-role-gates-tests.sh

Asserts, for each gate, that two distinct `CLAUDE_ROLE` values produce
role-correctly-labeled refusals from the one canon file (`"${role}: refused
— ..."`), that each gate's own kill switch (`TRAILER_GATE_OFF`,
`RECORD_FIELDS_GATE_OFF`, `HANDBOOK_TRIGGER_GATE_OFF`) disables it, and that
`record-fields-gate.sh`'s `RECORD_FIELDS_TERMINAL_STATES` override changes
which `loop_state` values count as terminal.

`stub-check.sh` is checked against synthetic rulebook trees: a clean tree
passes, a reintroduced vendored copy of any of the five canon files (the
three gates, `parse-check.sh`, and `stub-check.sh` itself) is caught, a real
lib-call stub `directive.sh` passes, and a `directive.sh` that has regrown
boilerplate (a case statement, a role guard, raw output beyond the
`core_role_directive` call) is caught. The checked file list is not
hardcoded in the script — it is read from `core/hooks/tests/canon-manifest.txt`
(one filename per line); promoting a new script to core canon means adding
one manifest line, not editing detection logic.

Wired into `core/hooks/tests/run-all.sh`.

## Canon invocation from a rulebook (issue-69)

`stub-check.sh` is core canon and is never vendored into a rulebook's own
tree. A rulebook's test harness invokes it by a path resolved against
core's own plugin install root — the same shape `core/hooks/hooks.json`
already uses for the four registered gates
(`${CLAUDE_PLUGIN_ROOT}/hooks/<name>.sh`) — passing the rulebook's own
directory as the scan target:

    "${CORE_PLUGIN_ROOT:-$CLAUDE_PLUGIN_ROOT/../core}/hooks/tests/stub-check.sh" "$(dirname "$0")/.."

The first argument stays a rulebook-relative directory (what to scan); the
script binary itself is never copied. The exact `${CLAUDE_PLUGIN_ROOT}`
sibling-resolution expression should be verified against how a real
marketplace install resolves a sibling plugin path before this line is
copied verbatim into a rulebook's own harness — this repo's own test run
happens from a single checkout where `core/` and each rulebook plugin are
siblings, which may not match the external 43-repo marketplace-install
layout. A rulebook's own record notes only the invocation and its pass/fail
result, never a second copy of the file.

See `docs/handbooks/canon-scripts.md` for the general "reference, never
vendor" rule this invocation model follows, and
`docs/issue-69/reports/implementation/reclaim-21-copies.md` for the rollout
procedure retiring the 21 existing vendored copies of `stub-check.sh` in
favor of this invocation.
