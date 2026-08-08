---
status: proposed
files:
  - core/hooks/tests/gate-prose-coverage-check.py
  - core/hooks/tests/run-gate-prose-coverage-tests.sh
  - docs/handbooks/gate-prose-coverage-check.md
---

## Request

Issue #146: ~70 of 108 confirmed prose↔gate mismatches across the rulebook
fleet fall out of one mechanical check — for every gate, extract its literal
needles and assert each appears in at least one *injected* prose surface
(directive.sh, sourced fragments, SKILL.md) the same role actually receives,
never a README/handbook the role is never handed. Build the check; do not fix
the 108 mismatches themselves.

## Constraints

- This repo's write set is `tokenmaxxxer-core` only; the 39 other rulebook
  repos live in sibling checkouts this repo cannot commit into. The check
  must be runnable *against* an arbitrary repo path, not bundled per-repo.
- Injected prose ≠ repo docs: only `hooks/directive.sh` content and
  `SKILL.md` files a role is pointed to count as prose surfaces; README.md
  and `docs/handbooks/*.md` do not, unless literally referenced from
  directive.sh — this is the distinction the issue says was violated and
  caused the drift.
- No behavioral/live execution of target gates (no `CLAUDE_PROJECT_DIR`,
  no `gh` auth) — static, read-only literal extraction only.
- Must produce a count of violations, runnable per-repo, per acceptance.

## Rationale

Considered executing each gate against synthetic tool-call payloads and
reading its deny messages to discover needles behaviorally. Rejected: the
non-needle gates in this repo (`approval-gate.sh`, `board-gate.sh`) are
structural git/gh-state checks, not needle checks, so most of that
complexity (spinning up a real repo + `gh` auth per gate) buys nothing for
the shape-2/shape-3 mismatches the issue targets; static extraction over the
three needle-literal syntactic shapes actually observed in this repo's own
`record-fields-gate.sh` (`has_any(...)` args) and in
`api-design-rulebook`'s `adr-section-gate/hooks/gate.sh` (`{"key":
re.compile(...)}` dict keys, and `re.search(r'^\s*(name):` field-key
regexes) covers the reported cases at a fraction of the cost and needs no
credentials to run in CI.

Also considered a hand-maintained gate→prose mapping file. Rejected: a
mapping that must be updated by hand every time either side changes is the
same failure mode the issue already documents in
`RECORD_FIELDS_TERMINAL_STATES` (an inert, hand-maintained config channel
nothing verifies) — it would rot the same way.

## What will be done

- `core/hooks/tests/gate-prose-coverage-check.py`: given one or more repo
  roots (default: this repo), for each root:
  1. Find every `hooks/directive.sh` — each is one role/unit; its content
     plus any `SKILL.md` under the same unit subtree is the unit's injected
     prose corpus (lowercased for matching). Also honor any file the
     directive text literally names by relative path (e.g. a referenced
     handbook path string) as an extra corpus member — that is what makes
     it "pointed to" rather than merely nearby.
  2. Find every `hooks/*gate*.sh` (excluding `directive.sh`), attribute each
     to the nearest ancestor unit (walk up to the closest `hooks/directive.sh`
     directory; the gate's own top-level plugin dir if none is found, e.g.
     `core` itself).
  3. Extract needles per gate via the three regex shapes from the survey:
     `has_any(...)` argument lists, `{"key": re.compile(...)}` dict keys,
     and `re.search(r'^\s*(name):` field-key names. Dedup per gate.
  4. For each needle, assert it (case-insensitive substring) appears
     somewhere in its unit's prose corpus; missing → one violation
     (gate file:line, needle, unit).
  5. Print each violation, then a summary count (violations, gates with
     ≥1 violation, units with ≥1 violation) and exit 1 if any violation
     exists, else 0.
- `core/hooks/tests/run-gate-prose-coverage-tests.sh`: synthetic-fixture
  tests (own temp dirs, following `_tmp.sh`'s `mktd` convention) covering:
  a needle present in directive.sh (pass), a needle absent (violation
  reported), a needle only in a non-referenced handbook (still a violation
  — proves the README/handbook exclusion holds), a needle covered via
  SKILL.md (pass).
- `docs/handbooks/gate-prose-coverage-check.md`: how to run it
  (`python3 core/hooks/tests/gate-prose-coverage-check.py <repo-root>...`),
  what a violation line means, and its three known extraction limits
  (static regex shapes, not a full parse — may miss needle forms not yet
  observed).
- Confirmation run (no-mock, single run): run the check against this repo,
  and read-only against 2-3 sibling rulebook repos already on disk
  (`api-design-rulebook`, `marketing-rulebook`, `localization-rulebook` if
  present) to sanity-check the extractor generalizes past this repo's own
  gates, and report the violation count found. This is inspection only — no
  writes into those repos.

## Out of scope

- Fixing any of the 108 mismatches (explicit issue instruction).
- Replacing the `substring in lower()` idiom with anchored matching
  (issue's "alongside it" item — separate follow-up).
- Making `RECORD_FIELDS_TERMINAL_STATES` actually work or deleting it
  (separate follow-up named in the issue).
- Wiring the check into CI (depends on on-the-record#290, not this repo).
- Core's own three mismatches (companion issue, not #146).

## How you'll know it worked

- `python3 core/hooks/tests/gate-prose-coverage-check.py .` runs clean
  (exit 0/1, no crash) against this repo and reports a real count.
- `bash core/hooks/tests/run-gate-prose-coverage-tests.sh` passes.
- A confirmation run against 2-3 sibling rulebook repos on disk completes
  and its violation count is reported in the implementation record,
  compared against the issue's ~70/108 estimate.
