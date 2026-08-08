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

## `OP_PATTERNS` trigger set for `handbook-trigger-gate.sh` (contract §21)

A commit that stages any of the following without also touching a
`docs/handbooks/*.md` file is refused: `package.json`, `package-lock.json`,
`pyproject.toml`, `requirements*.txt`, `go.mod`, `Cargo.toml`, `Gemfile`,
`Dockerfile`, `docker-compose.yml`, `.env*`, `migrations/`,
`.github/workflows/`, or a `(deploy|setup|run|install)*.sh` script.
