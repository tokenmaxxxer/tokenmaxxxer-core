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

`record-fields-gate.sh` accumulates every §20 violation on a write (missing
sections, sha placeholder, bare-sha `code_under_review`, missing
next-steps/resolution-path) into one list and denies once with the complete
set, instead of exiting on the first violation found (issue-140 — a
sequential-deny staircase measured at 8,157s across 337 refusals). The deny
message also names the literal accepted strings for each missing section
(e.g. `"what was done"`, `"what i did"`), not just the abstract label, so
the requirement is discoverable from the message alone.

`RECORD_FIELDS_TERMINAL_STATES` defaults to
`landed complete closed done delivered phase-2-complete` (widened from the
former lone `landed`, issue-140). Before the terminal-state membership
test, `-`/`_` are normalized to `-`, and a `-` is also inserted across
every letter/digit boundary (`phase2` -> `phase-2`), so
`phase_2_complete`, `phase-2_complete`, `phase-2-complete`,
`phase2-complete`, and `phase2_complete` all normalize to the same
terminal state (PR #143 feedback on issue-140 — the digit-boundary gap
left `phase2-complete`/`phase2_complete` misclassified as non-terminal).

For `CLAUDE_ROLE` in `{"coding", "implementation"}` (the repo's known
coding/implementation naming double), `record-fields-gate.sh` additionally
denies a write to that role's own record when `code_under_review:`'s
value, stripped, matches a bare single commit-sha token
(`^[0-9a-f]{7,40}$`, nothing else on the line) instead of a file list —
the record is committed in the same commit as the code it describes, so a
sha it would cite does not exist yet when the file is written. See
`docs/issue-100/decisions/2026-08-03-record-citation-format-and-kind-convention.md`.

`record-fields-gate.sh` also runs a second, independently-scoped check
(issue-128, tightened to an allow-list by issue-133) against both a role's
own `reports/<role>.md` write and any `docs/issue-<n>/proposals/*.md`
write (a proposal is a different artifact kind, so it does not run the
five §20 checks above — only this narrower check applies to it): a `sha:`
line's value is allowed only when it is exactly the literal `same-commit`
or exactly a 40-character lowercase hex commit sha; every other value —
a bracket placeholder (`sha: <set at commit>`), a bare unresolved spelling
(`sha: HEAD`, `sha: TBD`), or a bracket with trailing prose
(`sha: <set at commit> -- fix later`) — is denied. Per contract §1's
same-commit convention, an `upstream` entry whose `path` lands in the same
commit as the citing record or proposal is written as the literal
`sha: same-commit` instead.

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
