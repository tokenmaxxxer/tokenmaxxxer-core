# core handbook

## `docs/specs/record-fields-terminal-states.json` — per-kind terminal-state override (issue-147 C2)

`record-fields-gate.sh` (contract §20) requires a role's own record to name
`next steps` and an `open-finding resolution path` whenever its `loop_state`
is non-terminal for that record's contract §2 `kind`. The gate derives the
per-kind terminal-state defaults from contract §2 verbatim (e.g.
`verify-record` -> `cleared`, `ops-record` -> `steady`). A repo that needs a
kind to treat an additional `loop_state` as terminal — a genuine per-role
deviation from the contract default, not a workaround for a role that just
hasn't reached the contract's own terminal state yet — overrides it here.

**What the file is.** A JSON object at `docs/specs/record-fields-terminal-
states.json`, repo-root relative, read directly by `record-fields-gate.sh`
off the same `root` the gate already resolves. It replaces the retired
`RECORD_FIELDS_TERMINAL_STATES` env var, which never reached the gate's own
process (`SessionStart` and `PreToolUse` are separate OS processes) and
failed silently in all seven repos that tried it.

**Schema.** `{"<kind>": ["<state>", ...], ...}` — each key must be one of
contract §2's record kinds (`product-record`, `coding-record`, `qa-record`,
`feasibility-record`, `ux-design-record`, `review-record`, `verify-record`,
`ops-record`, `reflect-record`); each value is a non-empty list of
`loop_state` strings ( `[A-Za-z0-9_-]+` ). A named kind's list REPLACES that
kind's default terminal-state set for records of that kind; a kind not
named in the file keeps its contract-derived default.

**What it defaults to when absent.** No file present: every kind uses its
contract §2 default terminal-state set (see the table above), and a role
whose record path does not resolve to a known contract kind falls back to
the legacy flat set (`landed complete closed done delivered
phase-2-complete`), preserved only for backward compatibility with
rulebooks whose role name predates contract §2's kind table.

**What breaks, loudly, on malformed content.** The gate denies the write
(never a silent fallback to the default) when the file:
- is not valid JSON,
- is valid JSON but not a top-level object,
- names a `kind` key not in contract §2's record-kind list,
- gives a kind a non-list, empty-list, or non-string-list value, or
- names a state spelling outside `[A-Za-z0-9_-]+`.

Each of these produces a distinct denial message naming the specific
problem.

**To add or change a kind's terminal-state override:** create or edit
`docs/specs/record-fields-terminal-states.json` at the repo root, add or
edit the entry for the kind in question, and commit it. No hooks.json entry,
env var, or other wiring is required — the gate reads the file directly on
every write to a role's own record.

**The `kind` used for terminal-state resolution is CLAUDE_ROLE-derived, not
self-declared.** For a role contract §2 names, the gate ignores a record's
own `kind:` frontmatter field for this purpose and uses the role->kind
mapping instead — a record's own `kind:` field was found (before-landing
hunt, issue-147) to be attacker/session-controlled in the same write the
gate is judging, so trusting it let a role borrow another kind's
terminal-state set. `kind:` is consulted only as a fallback for a role
contract §2 does not name.

## `OP_PATTERNS` trigger set for `handbook-trigger-gate.sh` (contract §21)

A commit that stages any of the following without also touching a
`docs/handbooks/*.md` file is refused: `package.json`, `package-lock.json`,
`pyproject.toml`, `requirements*.txt`, `go.mod`, `Cargo.toml`, `Gemfile`,
`Dockerfile`, `docker-compose.yml`, `.env*`, `migrations/`,
`.github/workflows/`, or a `(deploy|setup|run|install)*.sh` script.

## `facet-keyword-gate.sh` — parameterized facet-keyword-family gate (issue #254)

Folds the 8 `facet-keyword`-family PreToolUse hooks (content-design's
tone-axis gate; customer-support's escalation-path, five-whys, kcs,
playbook-scenario, and sla-tier gates; finance-unit-economics'
sensitivity-scenario gate; sales' playbook gate) into one core gate,
`core/hooks/facet-keyword-gate.sh`, driven by
`core/hooks/facet-keyword-config.json`. Promote-first: none of the 8
source hooks were removed or modified — they keep running unmodified in
their own rulebooks; this core gate is an additional, behavior-equivalent
check, not a replacement wired into any rulebook yet.

**Dispatch.** The gate reads `CLAUDE_ROLE` and looks up that key in the
config file (one entry per rulebook: `content-design`, `customer-support`,
`finance-unit-economics`, `sales`); a role with no entry, or a missing/
unreadable config file, passes through silently (exit 0). Each config
entry is a list of facet rows (`customer-support` carries 5); every row
whose `target_path_regex` matches the write's normalized path is checked
independently against the same reconstructed content, and the first
row that denies wins.

**Config schema, per row:** `hook` (name), `kill_switch_env` (a
per-row kill switch, checked the same way as the gate-wide
`FACET_KEYWORD_GATE_OFF`), `target_path_regex`, `check_type` (one of
`header_present_or_skip`, `trigger_required_elements`, `trigger_count`,
`marker_required_elements`, `table_header_columns`,
`heading_scenario_min_labels`, `heading_sections_required`), and that
check type's own fields (required-element `{tag, regex}` lists, deny
message templates, etc.) — transcribed from the 8 source hooks' actual
regexes and message text, not the phase-4a classification report's
`{keyword_regex, claim_context_regex}` guess.

**Tests.** `core/hooks/tests/run-facet-keyword-gate-tests.sh`
(live-fire, real subprocess invocations), run as part of
`core/hooks/tests/run-all.sh`.
