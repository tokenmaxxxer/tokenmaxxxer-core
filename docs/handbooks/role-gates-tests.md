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
passes, a reintroduced vendored copy of any of the four canon files (the
three gates plus `parse-check.sh`) is caught, a real lib-call stub
`directive.sh` passes, and a `directive.sh` that has regrown boilerplate
(a case statement, a role guard, raw output beyond the
`core_role_directive` call) is caught.

Wired into `core/hooks/tests/run-all.sh`.
