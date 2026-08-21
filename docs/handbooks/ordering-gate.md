# `core/hooks/ordering-gate.sh`

One PreToolUse script dispatching 7 of the 8 role-scoped write-ordering
rules promoted by core#234/#237, replacing 7 separate per-role scripts
(issue-240). `survey-order-gate.sh` — the 8th, unscoped rule that applies
to any `docs/issue-<n>/proposals/*.md` write regardless of role — stays
its own separate script and its own separate `hooks.json` entry; see
"Why survey-order-gate.sh stays separate" below.

## Per-role table

Inside `ordering-gate.sh`'s Python payload, `ROLES` is a list of
`(kill-switch env var, mechanism function)` pairs, tried in order,
first-match-wins:

| role | kill switch | mechanism |
|---|---|---|
| content-design phase1-basis | `CONTENT_DESIGN_PHASE1_BASIS_GATE_OFF` | content-citation regex |
| devrel phase-order | `PHASE_ORDER_GATE_OFF` | content-citation regex |
| security-threat-model sequence | `SECURITY_THREAT_MODEL_SEQUENCE_GATE_OFF` | content-citation regex |
| incident-response order | `INCIDENT_RESPONSE_PROPOSAL_ORDER_GATE_OFF` | cross-file lookup |
| interaction-design stage-order | `ID_STAGE_ORDER_GATE_OFF` | cross-file lookup |
| arch-sequence | `ARCH_SEQUENCE_GATE_OFF` | JSON-cache two-way precondition |
| issue-retrospective proposal-order | `ISSUE_RETROSPECTIVE_PROPOSAL_ORDER_GATE_OFF` | cross-file lookup |

Each mechanism function is a direct port of the matching original
script's Python logic (variable renames only) — behavior is preserved
byte-for-byte per role.

## Adding a new role's ordering rule

1. Write a `mech_<role>()` function following the pattern of the existing
   ones: return `True` to allow (after the role's own checks pass),
   `None` if the write isn't this role's business (surface doesn't
   match), or call `deny(role, message)` to refuse.
2. Append `("<ROLE>_GATE_OFF", mech_<role>)` to `ROLES`, in whatever
   position keeps first-match-wins correct against the other roles'
   surfaces (most specific first).
3. Add `<ROLE>_GATE_OFF="${<ROLE>_GATE_OFF:-}" \` to the `python3` env
   passthrough near the top of the script.
4. Add tests exercising allow/refuse/foreign-role paths, following
   `tests/test_ordering_gates_237.py`'s pattern.

## Why survey-order-gate.sh stays separate

`survey-order-gate.sh`'s surface regex matches ANY
`docs/issue-<n>/proposals/*.md` write, unscoped by role or filename —
unlike the 7 roles above, which are each scoped to a specific
proposal-file naming pattern. Folding it into `ordering-gate.sh`'s
first-match-wins table makes it fire on every proposal write that
reaches the table with no matching scoped role above it — including the
frozen "foreign role, no survey anywhere" test fixtures in
`tests/test_ordering_gates_237.py` (`test_arch_sequence_gate_allows_foreign_role_proposal_without_survey`
and its devrel/interaction-design equivalents), which assert those exact
payloads return 0. Keeping `survey-order-gate.sh` a separate script and a
separate `hooks.json` entry preserves both rules' original,
independently-tested behavior. See
`docs/issue-240/reports/implementation.md`'s "Rationale for deviations"
for the full reproduction.

## Pitfall: list vs. string return shapes across the sh/Python mirror

#247 crashed on every single Bash tool_input
(`AttributeError: 'list' object has no attribute 'splitlines'`) because
line 101 called `.splitlines()` on `gate_lib.gate_bash_write_targets()`'s
return value. That helper's sh version (`gate-lib.sh`) prints one token
per line to stdout, but its Python mirror
(`core/hooks/lib/gate-lib.py`) already returns the equivalent **list** of
tokens directly — its own docstring says so. Treating a Python helper's
list/dict return as if it still carried its sh sibling's string-output
contract is the exact bug class to watch for when porting or adding a
mechanism function here: check the actual Python return type in
`gate-lib.py` before chaining a string method onto it. The regression
that let this ship past 34 green tests is closed by
`tests/test_ordering_gate_livefire.py`, which invokes
`bash core/hooks/ordering-gate.sh` as a real subprocess with PreToolUse
JSON on stdin for both Bash and Write tool inputs — the same path #247's
internals-only suites never exercised.
