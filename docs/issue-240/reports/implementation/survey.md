# Survey — issue-240: consolidate role-scoped ordering gates

## Write surface today

`core/hooks/hooks.json`'s `PreToolUse` array runs 8 role-scoped ordering
gates unconditionally on every `Write|Edit|MultiEdit` tool call; each
gate self-filters by regex-matching the target path and no-ops (exit 0)
when the path isn't its own surface:

1. `survey-order-gate.sh` (core#234) — role hardcoded to `implementation`.
2. `arch-sequence-gate.sh` (core#237)
3. `content-design-phase1-basis-gate.sh` (core#237)
4. `devrel-phase-order-gate.sh` (core#237)
5. `incident-response-order-gate.sh` (core#237)
6. `interaction-design-stage-order-gate.sh` (core#237)
7. `issue-retrospective-proposal-order-gate.sh` (core#237)
8. `security-threat-model-sequence-gate.sh` (core#237)

A 9th script, `record-fields-gate.sh`, is a field-completeness gate (§20),
not an ordering gate — the issue text explicitly asides it ("survey-order,
proposal-shape/record-shape aside"), so it stays out of scope here.
`proposal-shape-gate.sh` / `record-shape-gate.sh` are likewise asided by
the issue text — different concern (document shape, not write order).

## Per-gate behavior (from #237's equivalence table + direct read)

| gate | surface(s) | required file(s) | mechanism |
|---|---|---|---|
| survey-order | proposal (any `docs/issue-<n>/proposals/*.md`) | `reports/implementation/survey.md` | file-existence; role hardcoded, no filename scoping |
| arch-sequence | proposal (any) **and** `reports/architecture.md` | `reports/architecture/{survey,scout-brief}.md` (both); record-side requires proposal dir non-empty | two-file existence, both directions (phase-1 and phase-2), plus a Bash `>`/`tee` write-path scan |
| content-design-phase1-basis | proposal, filename-scoped (`*content-design*.md`) | any `reports/<role>/survey.md` (regex, not role-fixed) | **content-citation regex** over reconstructed resulting text, not file-existence |
| devrel-phase-order | proposal (any) | `reports/devrel/survey.md` | file-existence |
| incident-response-order | proposal, filename-scoped (`*incident-response*.md`) | `reports/incident-response/{current-state-survey,scout-brief}.md` (both) | two-file existence, window-scoped skip-heuristic |
| interaction-design-stage-order | proposal (new-file only) **and** `reports/interaction-design.md` | `reports/interaction-design/{survey,scout-brief}.md` + `.status.json` cache | two-file + record-side reverse precondition + JSON state cache |
| issue-retrospective-proposal-order | `reports/issue-retrospective.md` only (record-side, no proposal-side check) | sibling proposal must exist and cite survey path | reads a *different* file (the proposal) than the one being written |
| security-threat-model-sequence | proposal, filename-scoped (`*security-threat-model*.md`) | `reports/security-threat-model/survey.md` | file-existence |

Real per-role variation, confirmed by direct read (not just #237's table):
surface direction (proposal-only vs. proposal+record vs. record-only),
filename scoping (none vs. role-substring regex), required-file count (one
vs. two), and verification mechanism (file-existence vs. content-citation
regex vs. cross-file lookup vs. JSON-cache-backed two-way precondition).
None of this is copy-paste divergence (unlike record-fields-gate.sh's
prefix bug, issue-66) — every difference traces to a real
authoring-flow difference recorded in each gate's own header comment and
in #237's disposition table.

## Shared plumbing (identical across all 8)

- `__fc` fail-closed EXIT trap, installed as the first statement.
- Kill-switch pattern: `gate_kill_switch_active "${<ROLE>_GATE_OFF:-}"`,
  one distinct env var name per gate.
- Sources `gate-lib.sh` the same way; several use
  `gate_lib.gate_parse_json_or_deny` / `gate_lib.gate_reconstruct_write`
  from a heredoc'd `python3 <<'PY'` block.
- `_plausible` / project-root resolution: byte-identical shell function
  duplicated verbatim in 5 of the 8 scripts.
- All emit `"<prefix>: refused — <message>"` to stderr and exit 2 on deny,
  exit 0 on allow/no-op.

## Test surface

`tests/test_promoted_hooks.py` (core#234 trio: proposal-shape, record-shape,
survey-order — 9 tests) and `tests/test_ordering_gates_237.py` (7 gates x
3 cases = 21 tests) both invoke gates as **subprocesses by filename**:
`run_gate("<gate-filename>.sh", payload, cwd)`. This is the load-bearing
fact for consolidation: the harness takes a gate filename as a parameter
already, not a hardcoded path — swapping every `run_gate("X-gate.sh", ...)`
call to `run_gate("ordering-gate.sh", ...)` while leaving every payload
and `assert` line untouched is a mechanical rename, not an assertion
change, satisfying the acceptance criterion's "assertions unchanged...
mechanical path updates" clause verbatim.

## hooks.json

`PreToolUse` currently lists each of the 8 gates as its own `command`
entry, each firing on every tool call and self-filtering by path regex.
Nothing in the hooks.json schema requires one command per concern — an
array with fewer commands, each doing more internal dispatch, is a valid
replacement structure with no schema change.

## Alternatives visible from this surface

- Keep 8 files, extract only the shared plumbing (`_plausible`, root
  resolution, fail-closed trap) into `gate-lib.sh`. Reduces duplication
  but leaves the accumulation pattern the issue calls out (one file per
  role, unbounded growth) untouched — doesn't hit "net hook-file count
  under core/hooks decreases" per role added going forward.
- One script, per-role behavior expressed as a Python dict/table keyed by
  role, dispatched by matching the target path against each role's
  surface regex(es) in turn (first match wins, or all non-matches fall
  through as no-op like today). This is the only option that actually
  reduces file count while preserving every gate's own mechanism verbatim
  — carried into the proposal's Rationale.
