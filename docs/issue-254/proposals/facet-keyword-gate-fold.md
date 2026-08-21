---
status: proposed
files:
  - core/hooks/facet-keyword-gate.sh
  - core/hooks/facet-keyword-config.json
  - core/hooks/hooks.json
  - core/hooks/tests/test_facet_keyword_gate.py
---

files:
  - core/hooks/facet-keyword-gate.sh
  - core/hooks/facet-keyword-config.json
  - core/hooks/hooks.json
  - core/hooks/tests/test_facet_keyword_gate.py

## Request

Fold the 8 `facet-keyword` hooks identified by the phase-4a classification
(`docs/reports/keep-role-family-classification.md`, on-the-record
issue #1764) — content-design's tone-axis gate, customer-support's
escalation-path/five-whys/kcs/playbook-scenario/sla-tier gates,
finance-unit-economics' sensitivity-scenario gate, and sales' playbook
gate — into one parameterized `core/hooks/facet-keyword-gate.sh`, driven
by a config table, behavior-equivalent to each source hook under its
role's config row. Smallest family first, to validate the
config-extraction fold pattern before the 145-hook
`record-section-shape` fold. Promote-first: no rulebook file is edited
in this pass.

## Constraints

- Behavior-equivalent per hook: each source hook's allow/refuse verdict
  on realistic content must be reproduced by the core gate under that
  hook's config row (per [[survey.md]]'s per-hook table).
- Live-fire tests only (issue #248's lesson) — tests invoke the gate
  entrypoint with real PreToolUse JSON on stdin, not unit-test the
  Python helpers in isolation.
- bash-3.2-safe: no heredoc inside command substitution (issue #245's
  guard test must stay green).
- Promote-first: none of the 8 rulebooks' hook files or `hooks.json`
  entries are modified or removed in this pass.
- No new dependency; reuse `core/hooks/lib/gate-lib.sh` and its existing
  `gate_reconstruct_write`/`gate_normalize_path` helpers, already used by
  all 8 source hooks and by the already-landed `record-fields-gate.sh`/
  `record-shape-gate.sh` folds.

## Rationale

**Config shape: reproduce the real per-hook logic (target-path regex +
optional trigger regex + section-scope regex + ordered required-element
list + deny template), not the classification report's proposed
`{facets: [{name, keyword_regex, claim_context_regex}]}` shape.**
Considered adopting the report's shape verbatim, since it's the frozen
family definition and reusing it exactly would need no new design
discussion. Rejected: the report's shape was written at the
family-*boundary* stage (matching on filename/plugin name to sort hooks
into families), not from reading the 8 full bodies for config design —
reading them (per [[survey.md]]) shows most hooks check 3-5 named
required elements within a scoped section (e.g. kcs: issue/environment/
resolution/cause/metadata; escalation-path: trigger/owner/timeout), and
several key off a section-heading match rather than a keyword-adjacent-
to-claim pair. A single `keyword_regex`/`claim_context_regex` pair per
facet cannot express "5 required tags, collect all missing, not
first-fail" without either omitting hooks (breaking check 1's
per-hook-equivalence acceptance criterion) or overloading `keyword_regex`
into an ad hoc mini-language — worse than naming the fields directly.

**Config-table dispatch keyed by `rulebook/hook-slug`, mirroring
`record-shape-gate.sh`'s existing pattern.** Considered inlining all 8
hooks' logic as a bash `case` statement instead of a JSON config file
plus a generic Python interpreter loop. Rejected: the two already-landed
folds in this repo (`record-fields-gate.sh`, `record-shape-gate.sh`)
both use the JSON-config-plus-interpreter shape, and issue #254 itself
asks to "validate the config-extraction pattern" ahead of the 145-hook
fold — a bash `case` per hook would validate nothing reusable and would
not generalize to the next, much larger fold.

## What will be done

1. Write `core/hooks/facet-keyword-config.json`: one entry per
   `rulebook/hook-slug` (8 entries) carrying `kill_switch_env`,
   `target_path_regex`, `trigger_regex` (nullable), `section_scope_regex`
   (nullable — tone-axis instead uses a per-section header split, kept
   as a documented special case since it is the only hook whose section
   unit is "one copy string," not "one named heading"), an ordered
   `required_elements: [{tag, regex}]` list (empty list + trigger-only
   covers tone-axis/five-whys's present-or-skip shape), and a
   `deny_message_template`.
2. Write `core/hooks/facet-keyword-gate.sh`: sources `gate-lib.sh`,
   reads its own payload via `payload="$(cat)"` (issue #245-safe — no
   heredoc-in-command-substitution), loads the config JSON, and for a
   Write/Edit/MultiEdit/Bash tool call: resolves the acting role from
   `CLAUDE_ROLE`/config lookup, finds that role's config row(s), checks
   target-path match, trigger match, section-scope extraction, and the
   required-element list exactly as the 8 source hooks do — denying with
   the per-hook message shape on any missing element, passing silently
   (exit 0) when no row exists for the acting role/rulebook (empty
   state) or the config file itself is absent (no-op).
3. Register the new gate as a PreToolUse hook in `core/hooks/hooks.json`.
4. Write `core/hooks/tests/test_facet_keyword_gate.py`: live-fire cases
   invoking the gate binary with real PreToolUse JSON on stdin — one
   allow + one refuse case per configured role (8 hooks across the 4
   rulebooks that carry this family: content-design, customer-support,
   finance-unit-economics, sales), one empty-state case (an
   unconfigured role/rulebook passes through silently), and one
   no-config-file case (gate absent config → no-op), run via the fast
   tier.
5. Diff scope check: `git diff --stat` limited to `core/` and
   `docs/issue-254/` — no rulebook file touched.

## Out of scope

- Removing/demoting the 8 source hooks from their rulebooks (a later,
  separate demotion issue once the core gate has landed and been
  verified — this issue is fold-only, promote-first).
- The other 5 families from the same classification report
  (`record-section-shape`, `ordering-methodology`, `citation-sourcing`,
  `role-directive`, `field-format-numeric`) — each is its own fold/demote
  issue.
- Any change to `gate-lib.sh` itself; the fold reuses its existing
  helpers unmodified.

## How you'll know it worked

- `pytest core/hooks/tests/test_facet_keyword_gate.py` (fast tier)
  green, with one live-fire allow case and one refuse case per
  configured role (8 hooks, 4 rulebooks) plus the empty-state and
  no-config-file cases — output pasted in the phase-2 record.
- `git diff --stat main...HEAD` in the phase-2 record showing only
  `core/` and `docs/issue-254/` paths touched, no rulebook file.
- The existing #245 heredoc-in-command-substitution guard test still
  passes (part of the fast tier run).
