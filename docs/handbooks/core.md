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
contract §2 default terminal-state set (see the table above). `kind` itself
is resolved solely from the record's own self-declared `kind:` frontmatter
field (issue-341 removed the `ROLE_TO_KIND` role->kind closed-set map this
used to consult first — see issue-341's record for what stopped being
checked); a record naming no `kind:`, or one contract §2 does not
recognize, falls back to the legacy flat set (`landed complete closed done
delivered phase-2-complete`).

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

## `ordering-norm-gate.sh` — parameterized ordering-methodology-family gate (issue #257)

Folds the 18 classification-report rows / 15 distinct source files of the
`ordering-methodology` family (11 rulebooks: conformance-review,
customer-support, defect-verification, execution-observation,
issue-retrospective, observability, performance-engineering,
pr-communications, risk-management, user-discovery, ux-engineering) into
one core gate, `core/hooks/ordering-norm-gate.sh`, driven by
`core/hooks/ordering-norm-config.json`. Promote-first: none of the 15
source hooks were removed or modified.

**Dispatch.** Reads `CLAUDE_ROLE` and looks up that key in the config
file (one entry per rulebook, each a list of rows — observability carries
3); a role with no entry, or a missing/unreadable config file, passes
through silently (exit 0). Each row carries `mode` (`gate` or `tracker`)
and `event` (`PreToolUse`, `SessionStart`, or `PostToolUse`/`SessionStart+PostToolUse`).

**`mode: gate` rows** (9 of 15 files — PreToolUse deniers): `target_path_regex`
match on the reconstructed write, then an ordered `step_sequence:
[{label, marker_regex}]` position compare when non-empty, then a list of
named `extra_checks` (`distinct_pair`, `adjacency_required`,
`heading_before_forbidden`, `artifact_exists_before`,
`citation_adjacency`, `needle_any_missing`, `conditional_race_sequence`,
`hypothesis_state_or_marker`, `sources_or_paths_required`) reproducing
each hook's bundled non-order sub-checks — transcribed from the 15
source hooks' actual regexes and message text, not the classification
report's flat `{step_sequence, marker_regex}` guess (only 5 of 15 files
are a clean step-sequence check at all; per-hook detail lives in
`docs/issue-257/reports/implementation/survey.md`).

**`mode: tracker` rows** (6 of 15 files — SessionStart/PostToolUse
siblings that never deny): a named `tracker_action`
(`context_informer`, `loop_state_rank_bump`, `marker_file_reset_or_touch`,
`needle_state_record`, `hypothesis_state_sync`) that best-effort
reads/derives state and writes it to the same on-disk location the
source hook used (e.g. `.claude/verify-state-issue-<n>.json`,
`.observability-phase1-methods/<n>.json`); any internal failure is
swallowed silently, matching every source tracker's own "never crash or
block the session" contract.

**Tests.** `core/hooks/tests/run-ordering-norm-gate-tests.sh`
(live-fire, real subprocess invocations, 27 cases), run as part of
`core/hooks/tests/run-all.sh`.

## `citation-gate.sh` — parameterized citation-sourcing-family gate (issue #260)

Folds the 11 `citation-sourcing`-family hooks (9 rulebooks: api-design,
architecture, capacity-planning, conformance-review,
finance-unit-economics, interaction-design x2, requirements-engineering,
security-threat-model, technical-feasibility, test-authoring) into one
core gate, `core/hooks/citation-gate.sh`, driven by
`core/hooks/citation-config.json`. Promote-first: none of the 11 source
hooks were removed or modified.

**Dispatch.** Reads `CLAUDE_ROLE` and looks up that key in the config
file (one entry per rulebook, each a list of rows — interaction-design
carries 2); a role with no entry, or a missing/unreadable config file,
passes through silently (exit 0). Each row's `target_path_regex` is
matched against the reconstructed write's normalized path, then
dispatched to its `check_type` handler.

**`check_type` vocabulary** (transcribed from the 11 source hooks' real
regexes and message text, not the classification report's flat
`{claim_patterns, citation_markers, adjacency_window}` guess — only 3 of
11 hooks are that clean claim-adjacent-to-marker shape; per-hook detail
lives in `docs/issue-260/reports/implementation/survey.md`):
`claim_adjacent_marker` (paragraph or section/window scope),
`claim_adjacent_marker_phase_scoped` (technical-feasibility's phase-1/
phase-2 split plus cross-file carry-forward exemption),
`whole_doc_metric_source_and_paragraph_pair`,
`section_required_fields`, `whole_doc_keyword_and_ref_plus_branch`,
`table_req_membership` (with an optional reference-shape + Status-column
check), `sequencing_filename_anchor`, `anti_pattern_section`,
`bullet_adjacent_plus_doc_sources`, and
`verdict_field_required_plus_list_shape`. A `bash_write_refuses` row
flag reproduces the source hooks (conformance-review,
technical-feasibility) that refuse a Bash-tool write to their own
governed path as unverifiable rather than silently passing it through.

**Tests.** `core/hooks/tests/run-citation-gate-tests.sh` (live-fire,
real subprocess invocations, 24 cases), run as part of
`core/hooks/tests/run-all.sh`.

## `record-shape-gate.sh` — parameterized record-section-shape-family dispatch REMOVED (issue #341)

Issue #263 (phase-4b-4) extended `core/hooks/record-shape-gate.sh` with a
config-driven `CHECKERS` dispatch that folded 145 `record-section-shape`-
family hooks across 43 rulebooks into `core/hooks/record-shape-config.json`,
keyed by `CLAUDE_ROLE` (`config.get(role)`). Issue #331's role-axis removal
left that lookup live as a closed-set identity validation against a
40-role roster that no longer matches current session role naming; issue
#341 (operator ruling, 2026-08-27) removed the dispatch, its `PG_ROLE`/
`PG_CONFIG`/`RS_ROLE`/`RS_CONFIG` plumbing, and `record-shape-config.json`
itself, rather than re-expressing the same role-keyed lookup under another
name. **Capability dropped, not preserved elsewhere:** none of the 145
folded per-role record-shape checks (the 43 rulebooks' own methodology/
section/token checklists on their own proposal or report paths) run any
more. The 145 original per-rulebook hooks this dispatch had folded were
themselves never removed by issue #263 (promote-first), so their own
`hooks.json` entries, if still registered, are the only remaining
enforcement of that shape — see `docs/issue-263/reports/implementation/
survey.md` for the per-hook source list.

`record-shape-gate.sh`'s hardcoded `implementation`-role phase-2 record
check (issue #52, matches the single fixed path
`docs/issue-<n>/reports/implementation.md`, never a role-keyed dict) is
unaffected and still runs unconditionally.

**Tests.** `core/hooks/tests/run-record-shape-gate-tests.sh` now covers
only the hardcoded `implementation`-role check (issue #285/#297 trivial-
diff exemption cases), run as part of `core/hooks/tests/run-all.sh`.

## `survey-order-gate.sh` — role-aware survey path (issue #271)

`survey-order-gate.sh` (research-before-proposal ordering, see
`docs/specs/role-handoff-contract.md`) previously hardcoded the survey
path it checked for a phase-1 proposal write as
`docs/issue-<n>/reports/implementation/survey.md`, regardless of which
role's session was writing. `board-gate.sh` (contract v3 s11) restricts a
non-implementation role to writing only under its own
`docs/issue-<n>/reports/<role>/` tree, so a non-implementation role's real
survey was invisible to this gate while the path it demanded was one
`board-gate.sh` itself refused that role's session to write.

**Fix.** The bash wrapper exports `SOG_ROLE="${CLAUDE_ROLE:-}"` and passes
it into the embedded Python as `PG_ROLE` (mirroring
`record-shape-gate.sh`'s `RS_ROLE` env-passthrough pattern). The expected
survey path is now `docs/issue-<n>/reports/<role>/survey.md` when
`CLAUDE_ROLE` is a non-empty string, else the original hardcoded
`reports/implementation/survey.md` fallback (preserves existing
implementation-role behavior with `CLAUDE_ROLE` unset). No
accept-any-glob: the path is built solely from the acting role, never
matched against any role's tree, so a survey under a different role's
`reports/` does not satisfy this role's gate.

**Tests.** `core/hooks/tests/run-survey-order-gate-tests.sh` (live-fire,
real subprocess invocations, 7 cases: implementation-role unchanged with
`CLAUDE_ROLE` unset and set, a non-implementation role denied when only
the implementation survey exists, that same role allowed once its own
survey exists, and the scout-skip-marker text still permitting the write
with no survey on disk), run as part of `core/hooks/tests/run-all.sh`.
