---
code_under_review: HEAD
loop_state: delivered
---

# Implementation record — issue-146

Proposal: docs/issue-146/proposals/2026-08-07-gate-prose-coverage-check.md

## What was done

Built the gate-literal <-> injected-prose coverage check per the approved
proposal:

- `core/hooks/tests/gate-prose-coverage-check.py` — static extractor over
  the three needle shapes (`has_any(...)` args, `{"key": re.compile(...)}`
  dict keys, `re.search(r'^\s*(name):` field-key names), matched against
  each unit's injected prose corpus (`hooks/directive.sh`, `SKILL.md`
  under the unit, files `directive.sh` names by relative path). Excludes
  README/handbook files unless directive.sh literally references them.
- `core/hooks/tests/run-gate-prose-coverage-tests.sh` — 4 synthetic-fixture
  cases (needle in directive.sh: pass; needle absent: violation; needle
  only in unreferenced handbook: still a violation; needle covered via
  SKILL.md: pass). Ran: `bash core/hooks/tests/run-gate-prose-coverage-tests.sh`
  -> `4 passed, 0 failed`.
- `docs/handbooks/gate-prose-coverage-check.md` — usage doc, violation-line
  reading guide, three known extraction limits.

Confirmation run (no-mock, single run each):
- `python3 core/hooks/tests/gate-prose-coverage-check.py .` (this repo) ->
  exit 1, 19 violations, all in `core/hooks/record-fields-gate.sh` (needles
  like `what i did`, `## done`, `reason:`, `resolution-path` absent from
  `core/hooks/directive.sh`) — a real, previously-undocumented mismatch in
  this repo's own canon gate, consistent with the issue's "core's own
  three mismatches" line naming this file's class of drift (count differs
  from the issue's "three" because that figure predates this check's
  literal-level granularity).
- Read-only against 3 sibling rulebook repos already on disk under
  `/home/jwjung/tokenmaxxxer/rulebooks/`:
  - `api-design-rulebook`: exit 1, 5 violations, all in
    `adr-section-gate/hooks/gate.sh` (`alternatives considered`,
    `rationale`, `consequences`, ... missing from its directive.sh) —
    matches the issue's own api-design example.
  - `marketing-rulebook`: exit 1, 21 violations across 3 gates.
  - `localization-rulebook`: exit 0, 0 violations found — its
    `record-fields-localization-gate.sh` needles are heading regexes
    (`re.compile(r'^#{1,6}\s*target locale\b')`), a fourth needle shape
    not among the three named in the approved proposal; this is the
    documented "needle forms not yet observed" extraction limit, not a
    false claim of coverage — the handbook names it explicitly.
  - Total across the 2 non-clean sibling repos: 26 violations found vs. the
    issue's ~70/108 estimate; the gap is attributable to (a) only 2 of the
    39 sibling repos sampled being checked, and (b) the fourth needle shape
    (heading regexes) this build does not extract, both named as
    known limits in the handbook rather than silently undercounted.
  - No writes made to any sibling repo (read-only per proposal constraint).

## Why

Rationale: approved phase-1 proposal (basis: PR #148,
docs/issue-146/proposals/2026-08-07-gate-prose-coverage-check.md), approved
via `APPROVE issue-146/implementation` (single-account mode).

## What did not work

None.

## Open findings

None currently open.

### resolved_findings

- before-landing hunt (stance 0, docs/reports/2026-08-07-hunt-2026-08-07-gate-prose-coverage-check.md):
  case-insensitive plain-substring matching let a short needle (e.g. `"ip"`)
  false-clean-pass by matching inside an unrelated word (`skip`) in the
  prose corpus. Fixed by requiring non-word-character boundaries around
  the needle match (`needle_covered()` in gate-prose-coverage-check.py,
  `(?<![A-Za-z0-9_])...(?![A-Za-z0-9_])`). Re-ran
  `run-gate-prose-coverage-tests.sh` (4/4 pass) and the confirmation run
  (this repo: 19 violations, unchanged; api-design-rulebook: 5,
  unchanged; marketing-rulebook: 21, unchanged; localization-rulebook: 0,
  unchanged) — the fix does not regress any prior true violation.

## Next steps

- Write `core/hooks/tests/gate-prose-coverage-check.py`.
- Write `core/hooks/tests/run-gate-prose-coverage-tests.sh`.
- Write `docs/handbooks/gate-prose-coverage-check.md`.
- Run confirmation pass against this repo and sibling rulebook repos on
  disk, then set loop_state to a terminal state.

## Resolution path

N/A — no open findings blocking progress.
