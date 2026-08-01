# Gate-house standard: the shared gate library (issue-72)

A 2026-08-01 audit of the 43 downstream rulebook repos' merged gates found
six repo-wide structural defect classes, not isolated per-repo bugs (issue
#72's background). `core/hooks/lib/gate-lib.sh` (+ `core/hooks/lib/gate-lib.py`)
is the canon fix every rulebook gate should source instead of re-deriving
its own version of each shape. This handbook is what a rulebook's own A+
remediation issue links to.

## What `gate-lib.sh` / `gate-lib.py` provide

Sourced from a gate script (bash) and loaded via `importlib` from a gate's
own Python payload — see the usage comment at the top of each file for the
exact lines. Functions, one per defect class from the issue's background:

- `gate_trap_fail_closed` — the one canonical fail-closed EXIT trap.
- `gate_kill_switch_active <value>` — **fixed** convention: only a
  recognized on-spelling (`1`/`true`/`yes`/`on`) disables; empty, a
  recognized off-spelling, or any unrecognized value all stay active.
  (Core's own canon had this backwards before issue-72: any unrecognized
  value silently disabled the gate — see "the two bugs this issue fixed"
  below.)
- `gate_deny <name> <msg>` / `gate_allow` — stderr-only deny (exit 2) /
  allow (exit 0).
- `gate_parse_json_or_deny(raw, deny)` (Python) — malformed-JSON deny,
  including empty payload and non-object top level.
- `gate_normalize_path(root, path)` (Python) — absolute/relative/
  `./`-prefixed path normalization to a root-relative tail, or `None` when
  the path resolves outside root.
- `gate_reconstruct_write(tool, tool_input, current_content)` (Python) —
  full `Write`/`Edit`/`MultiEdit`/`NotebookEdit` reconstruction, honoring
  each edit's own `replace_all` flag independently (MultiEdit) and
  returning the edited cell source for `NotebookEdit`.
- `gate_bash_write_targets <command>` (bash) — token-scan a `Bash`
  `tool_input.command` string for path-shaped candidates, the technique
  `approval-gate.sh`/`board-gate.sh` already used, now reusable by any
  gate that currently only matches the `Write`/`Edit`-family tools.

## The two bugs this issue fixed in core's own canon

Not just future-proofing for the 43 rulebooks — core's own seven gates had
these bugs too (issue-72 survey sections 2 and 6), fixed as part of this
migration:

1. **Kill-switch default-on-unrecognized-value.** Every kill switch in this
   repo (`CORE_OFF`, `TRAILER_GATE_OFF`, `RECORD_FIELDS_GATE_OFF`,
   `HANDBOOK_TRIGGER_GATE_OFF`) used
   `case ... in ""|0|false|no|off) ;; *) exit 0 ;; esac` — any value other
   than a recognized off-spelling, including a typo, disabled the gate.
   All seven `core/hooks/*.sh` gates now call `gate_kill_switch_active`
   instead.
2. **`replace_all` ignored.** `record-fields-gate.sh` always did
   `current.replace(old, new, 1)` regardless of the real `Edit`/`MultiEdit`
   call's `replace_all` field, and never reconstructed `NotebookEdit` at
   all. It now calls `gate_lib.gate_reconstruct_write`, which honors
   `replace_all` per-edit and reconstructs `NotebookEdit`'s cell source.

## Standard test harness

`core/hooks/tests/run-gate-lib-tests.sh` makes six case groups mandatory —
a run that skips any of them fails the harness itself:

1. `Edit` with `replace_all: true` against a multiply-occurring
   `old_string`.
2. `MultiEdit` with a mix of `replace_all: true`/`false` edits in one call.
3. Malformed JSON (truncated, non-object, empty).
4. Kill-switch set to an unrecognized value — must assert the gate stays
   **active**.
5. Absolute `file_path` matching the same scope a relative-path fixture
   already matches, plus a `./`-prefixed variant.
6. A `Bash`-tool file write reaching the same target a `Write`-tool call
   would hit.

Run it the same way `run-role-gates-tests.sh` is run today, from
`core/hooks/tests/`: `bash run-gate-lib-tests.sh`.

## Compliance detector

`core/hooks/tests/compliance-check.sh [hooks-dir]`, modeled on
`stub-check.sh`'s pattern: flags a gate that reads a `*_OFF` kill-switch
env var without calling `gate_kill_switch_active` (hand-rolled, likely
fail-open), and a gate that reconstructs `Edit`/`MultiEdit` content via its
own `.replace(old, new[, 1])` call instead of `gate_reconstruct_write`
(likely `replace_all`-ignoring). Invoked the same way `stub-check.sh` is,
against a rulebook's own hooks directory:

```
"${CORE_PLUGIN_ROOT:-$CLAUDE_PLUGIN_ROOT/../core}/hooks/tests/compliance-check.sh" "$(dirname "$0")/.."
```

`gate-lib.sh`, `gate-lib.py`, and `compliance-check.sh` are all listed in
`core/hooks/tests/canon-manifest.txt`, so `stub-check.sh` itself catches a
rulebook vendoring a copy of any of them, per
[`canon-scripts.md`](canon-scripts.md)'s reference-not-copy rule.

## Per-repo migration checklist

For each of the 43 rulebook repos' A+ remediation issue:

1. Run `compliance-check.sh` against the rulebook's current gates and
   record the violation list.
2. Migrate each flagged gate to source `gate-lib.sh` (bash) and load
   `gate-lib.py` (Python payload), replacing its own hand-rolled kill
   switch / path-normalize / reconstruct logic with the equivalent
   `gate_*` call.
3. Re-run the rulebook's own gate tests, plus a copy of the six-case
   `run-gate-lib-tests.sh` suite adapted to that rulebook's gates.
4. Re-run `compliance-check.sh` clean.
5. File the rulebook's own A+ remediation issue referencing this
   handbook, citing the now-clean `compliance-check.sh` output as
   evidence.

This issue (#72) is the prerequisite standard; no retroactive fix to any
of the 43 rulebooks' already-merged gates happens in this repo — each
rulebook's own A+ issue does that work, following the checklist above.
