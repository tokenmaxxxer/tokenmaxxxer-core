# Survey — issue-146 (gate-literal ↔ injected-prose coverage check)

## Write set under consideration

- `core/hooks/tests/gate-prose-coverage-check.py` (new) — the check itself.
- `core/hooks/tests/run-gate-prose-coverage-tests.sh` (new) — unit tests for
  the check against small synthetic fixtures, following the existing
  `run-*-tests.sh` convention in `core/hooks/tests/`.
- `docs/handbooks/gate-prose-coverage-check.md` (new) — how to run it, what
  it reports, how to read a violation.

## Current state

This checkout (`tokenmaxxxer-core`) holds only `core`, `freelunch`, `scout`,
`terse`, `warrant` — five of the "44 units" the issue counts; the other 39
rulebooks (api-design, marketing, localization, observability, ...) live in
sibling checkouts under `/home/jwjung/tokenmaxxxer/rulebooks/*`, outside this
repo's git tree. This repo's write set cannot include files in those trees.

Two directory conventions were confirmed by reading actual files:

1. **This repo (`core`)**: gates live flat in `core/hooks/*-gate.sh`; the
   injected directive is `core/hooks/directive.sh` (a single heredoc). Needle
   pattern observed in `core/hooks/record-fields-gate.sh:198-222`:
   `has_any("what was done", "what i did", ...)` — literal strings compared
   against `new_text.lower()`.
2. **Rulebook repos** (checked `api-design-rulebook`, confirmed live at
   `/home/jwjung/tokenmaxxxer/rulebooks/`): a plugin's directive is
   `<plugin>/hooks/directive.sh`, sourcing `core_role_directive(...)` from
   core canon with the prose passed as literal string arguments (this IS the
   injected prose — it becomes the SessionStart heredoc). Sub-gates live at
   `<plugin>/plugins/<gate-name>-gate/hooks/gate.sh`. Confirmed
   `adr-section-gate/hooks/gate.sh:118-124` builds
   `sections = {"context": re.compile(...), "decision": re.compile(...), ...}`
   — dict keys are the needles — while
   `api-design/hooks/directive.sh`'s `core_role_directive` call states the
   ADR norm is "enforced by PR review ... not by this directive or a
   field-presence gate" — the literal "alternatives considered" that the
   gate demands is not in the directive prose at all. This is the shape-2
   case the issue names as representative.

So gate needle-literals appear in exactly the patterns already used in this
repo's own `record-fields-gate.sh` (`has_any(...)` argument lists) and the
rulebook's `adr-section-gate` (`{"key": re.compile(...)}` dict literals), plus
a third pattern seen by grep across sub-gates: `re.search(r'^\s*(name):`
field-key regexes (e.g. `loop_state`, `sha`, `code_under_review` in
`record-fields-gate.sh:216,234`). These three syntactic shapes are what a
generic extractor can reliably target without executing the gate's Python.

`core/hooks/lib/gate-lib.py` is the one sourceable helper gates already
share; the new check does not modify it — it is a read-only auditor, not a
gate, so it does not hook into `gate_reconstruct_write` etc.

## Alternatives considered (for the proposal's Rationale)

- **Execute each gate against synthetic inputs and observe deny messages**
  (behavioral extraction instead of static literal extraction): more
  faithful to what the gate actually enforces, but requires a live
  `CLAUDE_PROJECT_DIR`/git repo per gate, `gh` auth for the auth-gates
  (`approval-gate.sh`), and enumerating a combinatorial input space per gate
  to find every needle — far more code and far slower, and the auth-gates
  are structural (git/gh state) rather than needle-based, so most of that
  cost buys nothing. Rejected in favor of static extraction over the three
  observed syntactic shapes, which covers the needle-based gates the issue
  is actually about (shape 2/3) at a fraction of the complexity.
- **Hand-maintain a mapping file of gate → expected prose location**: would
  need updating by hand every time a gate or a directive changes, which is
  exactly the drift mechanism the issue reports (`RECORD_FIELDS_TERMINAL_STATES`
  is this same problem in config form — inert because nothing verifies the
  channel works). Rejected — a check that itself rots by hand-maintenance is
  not a fix.

## Unknowns / risks flagged for the proposal

- Needle extraction is necessarily heuristic (three regex shapes derived
  from files actually read, not a full Python parse) — it will not catch
  every gate shape in 39 repos this session cannot open. The proposal scopes
  the check's self-test to this repo's own gates plus one read-only run
  against 2-3 sibling rulebook repos already on disk, to sanity-check the
  extractor's shapes generalize, without writing anything outside this
  repo's tree.
