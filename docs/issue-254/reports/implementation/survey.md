# Survey — issue #254 (phase-4b-1: fold facet-keyword family)

## Repo/scope clarification (real finding, not decorative)

Issue #254 was filed in `tokenmaxxxer-core` (this repo), but its body
references `docs/reports/keep-role-family-classification.md` and
`on-the-record#1764` as if the target were the `on-the-record` repo.
Checked and resolved: `on-the-record` has no `core/` directory at all —
`core/hooks/*-gate.sh` is a *shared plugin* that `on-the-record` and the
43 rulebook repos pin/consume from **this** repo (`tokenmaxxxer-core`).
The classification report (landed on-the-record `main` at commit
`289b42ba`, issue on-the-record#1764/#1765, fetched fresh — the local
on-the-record clone was stale until `git fetch origin` pulled it) names
`core/hooks/facet-keyword-gate.sh` as the fold target, which is squarely
this repo. No cross-repo mismatch remains; work proceeds here.

derived: `git -C /home/jwjung/tokenmaxxxer/on-the-record show origin/main:docs/reports/keep-role-family-classification.md`

## The 8 facet-keyword source hooks (per-hook rows, classification report)

| rulebook | hook path |
|---|---|
| content-design-rulebook | `content-design-tone-axis/hooks/tone-axis-gate.sh` |
| customer-support-rulebook | `customer-support-escalation-path/hooks/escalation-path-gate.sh` |
| customer-support-rulebook | `customer-support-five-whys/hooks/five-whys-gate.sh` |
| customer-support-rulebook | `customer-support-kcs/hooks/kcs-gate.sh` |
| customer-support-rulebook | `customer-support-playbook-scenario/hooks/playbook-scenario-gate.sh` |
| customer-support-rulebook | `customer-support-sla-tier/hooks/sla-tier-gate.sh` |
| finance-unit-economics-rulebook | `finance-sensitivity-scenario/hooks/sensitivity-scenario-gate.sh` |
| sales-rulebook | `sales-playbook/hooks/playbook-gate.sh` |

All 8 cloned live (`gh repo clone --depth 1`) and read in full (not the
audit's header excerpt — the #1750 lesson the classification report
itself names). Each is a PreToolUse gate over `core/hooks/lib/gate-lib.sh`
(gate-house standard, issue-72), fail-closed via `gate_trap_fail_closed`,
with its own `<ROLE>_<HOOK>_GATE_OFF` kill-switch env var.

## What each hook actually checks (real shape, not the report's guess)

The classification report's config shape guess —
`{rulebook: {facets: [{name, keyword_regex, claim_context_regex}]}}` —
was written at the family-boundary stage (filename/plugin-name matching)
and is stated there as an unverified proposal, not a body-read
conclusion. Reading all 8 bodies shows a common mechanical shape richer
than a bare keyword/context pair:

1. **Target-path regex** — the gate only fires on writes whose normalized
   path matches (e.g. `^docs/issue-[0-9]+/reports/sales\.md$`,
   `^customer-support/handbook\.md$|^docs/issue-[0-9]+/reports/customer-support\.md$`).
   Bash-tool writes to an in-scope path are always denied outright
   (unverifiable reconstruction), independent of content.
2. **Trigger regex (optional)** — some hooks only engage when a marker
   phrase appears in the resulting content at all (tone-axis: a
   `## ... string` header; escalation-path: literal "escalation path";
   five-whys: "repeat|recurring"). sla-tier, kcs, playbook-scenario,
   sensitivity-scenario, and sales' playbook-gate instead key off a
   section-heading scan directly (no separate trigger phase).
3. **Section-scoping** — the check runs against the matched section's own
   text slice (`semantic.section_slices`, or a `header_re` split for
   tone-axis), never the whole document — this is what "adjacent to a
   flagged claim" means mechanically for this family.
4. **Required elements** — a list of `(tag, regex)` pairs checked within
   that scope; every missing one is collected (not first-fail) into a
   `missing` list, e.g. kcs: `issue`, `environment`, `resolution`,
   `cause`, `metadata|state|maturity` (5 tags); escalation-path: `trigger`,
   `owner`, `timeout` (3 tags); tone-axis: single axis-word regex OR an
   explicit skip-with-reason marker (present-or-skip, not always-required).
5. **Deny message** — each hook composes a role-specific message naming
   the missing tags and a doc reference (e.g. `docs/issue-1/proposals/
   customer-support.md §2`).

This is the real per-hook equivalence surface the fold must reproduce —
richer than the report's single keyword/context-regex pair. A config
table for the core gate needs, per hook: kill-switch env name, target
path regex, optional trigger regex, optional section-scope heading regex,
an ordered list of `{tag, regex}` required elements (empty list + a bare
trigger/skip check covers tone-axis's present-or-skipped shape), and a
deny-message template.

## Existing core fold pattern to reuse

`core/hooks/record-fields-gate.sh` and `core/hooks/record-shape-gate.sh`
in this repo already establish the proven pattern: one parameterized
bash entrypoint sourcing `gate-lib.sh`, reading a JSON config file
(`core/hooks/<name>-config.json`), keyed by rulebook/role, iterated in
Python via the same `gate_reconstruct_write` / `gate_normalize_path`
helpers the 8 source hooks call directly. `facet-keyword-gate.sh` will
follow this same shape rather than inventing a new one.

## bash-3.2 guard (#245)

`core/hooks/tests/` carries the heredoc-in-command-substitution guard
test (issue #245). The new gate must avoid that pattern (no
`$(cat <<EOF ... EOF)` construct) — the existing fold hooks
(`record-shape-gate.sh`) already demonstrate the safe idiom (`payload="$(cat)"`
then a separate `python3 <<'PYEOF'` reading from an exported env var),
which this build will copy.

## Write set (frozen for the proposal)

- `core/hooks/facet-keyword-gate.sh` (new)
- `core/hooks/facet-keyword-config.json` (new)
- `core/hooks/hooks.json` (register the new PreToolUse entry)
- `core/hooks/tests/` — live-fire test file(s) (new), one case per
  configured role (5 rulebooks) covering allow/refuse/empty-state, plus
  a no-config-file case
- `docs/issue-254/reports/implementation.md` (phase-2 record, not written yet)

No rulebook file is touched (promote-first, per the issue and the
family's `fold` disposition — the source hooks stay in place until a
later demotion issue removes them).
