# Survey: gate-lib fail-open source guard + gate_bash_write_targets py parity (issue-75)

## Write surfaces

- `core/hooks/lib/gate-lib.sh` — usage-comment preamble (top-of-file docblock, lines 11-13) and
  the single unguarded source line pattern it documents.
- `core/hooks/lib/gate-lib.py` — has `gate_parse_json_or_deny`, `gate_normalize_path`,
  `gate_reconstruct_write`. No `gate_bash_write_targets` — confirmed absent (grep of the file
  above shows only these four `def`s).
- `core/hooks/*.sh` (7 gates: directive.sh, gh-guard.sh, trailer-gate.sh,
  handbook-trigger-gate.sh, approval-gate.sh, board-gate.sh, record-fields-gate.sh) — every one
  sources gate-lib.sh with the **unguarded** one-liner:
  `. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd ... && pwd -P)}/hooks/lib/gate-lib.sh"`
  followed directly by `set -uo pipefail`, no `|| { ... }` after the source. Confirmed via
  `grep -n "gate-lib.sh\"" -A2 core/hooks/trailer-gate.sh` (survey command above): line 25 is the
  bare source, line 26 is `set -uo pipefail`, nothing between them.
- `core/hooks/tests/compliance-check.sh` — two structural checks today (kill-switch hand-roll
  detection, `.replace()` reconstruction detection). No check for an unguarded `gate-lib.sh`
  source line.
- `core/hooks/tests/run-gate-lib-tests.sh` — six mandatory case groups (replace_all Edit,
  MultiEdit mixed replace_all, malformed JSON, kill-switch unrecognized-value, absolute/`./`
  path, Bash-write-target). No group for "gate-lib.sh fails to source" (missing-core case).
- `docs/handbooks/gate-house-standard.md` — documents the six mandatory test groups, the
  compliance-check's two structural checks, and the per-repo migration checklist. Says nothing
  about a source guard being mandatory, nor lists `gate_bash_write_targets` as Python-side.

## Confirmed defect mechanics

**Defect 1 — fail-open on missing core.** The documented usage (gate-lib.sh's own top comment,
and all 7 real call sites) sources gate-lib.sh with no `||` fallback. If
`CLAUDE_PLUGIN_ROOT_CORE` is unset AND the relative fallback path
(`$(dirname .../..)/hooks/lib/gate-lib.sh`) doesn't resolve to a real core checkout (a plausible
deploy topology where a rulebook plugin is not colocated with core, or core hasn't been synced),
bash's `.` fails with a non-fatal (in `set -uo pipefail` terms, before `set -u` even runs)
non-zero status, but the script does **not** exit — bash's `source`/`.` failure is not caught by
anything at that point (no `trap`, no `set -e`), so execution falls through to line 26
(`set -uo pipefail`) and beyond. Every gate function called afterward — `gate_trap_fail_closed`,
`gate_kill_switch_active`, `gate_deny` — is now an undefined shell function; calling it returns
exit 127 ("command not found"), which most `||`-chained call sites (per gate-lib.sh's own usage
example: `gate_kill_switch_active CORE_OFF || { trap - EXIT; exit 0; }`) interpret as "kill
switch says disable," i.e. **silent allow**. No `trap` was ever installed (gate_trap_fail_closed
itself is undefined too), so there's no fail-closed backstop either. Net effect: the entire gate
is bypassed with no stderr output pinning the cause. issue-75 cites `interaction-design` and
`technical-feasibility` repos (external to this codebase — 2 of the 43 downstream rulebooks, not
present here) as already carrying the verified fix shape:
`. "$path" || { echo ... >&2; exit 2; }` — guard the source itself, fail closed on guard
failure, independent of everything gate-lib.sh defines.

**Defect 2 — `gate_bash_write_targets` missing from gate-lib.py.** Confirmed by reading the full
file: gate-lib.py defines exactly `gate_parse_json_or_deny`, `gate_normalize_path`,
`_apply_replace` (private), `gate_reconstruct_write` — no `gate_bash_write_targets`. Any
Python-payload gate that follows the documented `importlib` loading pattern and then calls
`gate_lib.gate_bash_write_targets(...)` hits `AttributeError: module 'gate_lib' has no attribute
'gate_bash_write_targets'` on every Bash tool_input, i.e. crashes on every Bash call. Whether that
crash reads as fail-open or fail-closed depends on the caller's own exception handling; issue-75
reports the observed case (pr-communications, external repo) is a bare crash with no handler,
which fails closed but denies *every* Bash command, not just the ones touching guarded paths — a
usability/availability failure, not a security one, but still a house-standard violation (sh/py
semantic parity was gate-lib's whole premise per gate-house-standard.md's opening paragraph).

## Existing test/detection machinery to extend (not replace)

- `compliance-check.sh`'s two checks are both regex-absence checks against a single gate file —
  the same shape fits a third check: unguarded source line (`. ".../gate-lib.sh"` with no `||`
  on the same logical line, and no `deny`/`exit` reachable if the source fails).
- `run-gate-lib-tests.sh`'s six group markers (`mark <name>`) are the harness's own
  "six groups mandatory" self-check — a seventh `mark missing-core` group fits the same pattern:
  invoke a gate script (or a minimal harness sourcing gate-lib.sh) with
  `CLAUDE_PLUGIN_ROOT_CORE` pointed at a nonexistent path and no relative fallback available,
  assert deny (exit 2), not silent allow (exit 0).

## Alternatives visible from this state (feeds proposal Rationale)

- Guard could live *inside* gate-lib.sh (e.g. a self-check function) vs. at *every call site*
  (the interaction-design/technical-feasibility precedent, which guards the source line itself).
  Only the call-site form is possible in bash: a failed `source` never runs any code inside the
  sourced file, so gate-lib.sh cannot defend its own loading — the guard is necessarily
  call-site, which the precedent already confirms.
- `gate_bash_write_targets`'s sh implementation is `grep -oE` token-scan over the raw command
  string — a `re.findall`-based Python port is the direct equivalent; alternative designs
  (shlex-based tokenization) were considered and rejected in the Rationale below.
