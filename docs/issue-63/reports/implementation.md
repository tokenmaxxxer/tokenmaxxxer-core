---
subject: issue-63
role: implementation
loop_state: delivered
---

# Implementation record — warrant-hunt canon promotion + proportional efficiency protocol

Approved via issue comment (single-account mode): `APPROVE issue-63/implementation`, with the unconfirmed fourth catch class ("watch 오탐 근본원인") accepted as unverified in this checkout — the approver's comment names it as already root-fixed in issues #129/#142.

## What shipped

1. **Canon promotion** — `warrant/` added as a fifth plugin directory
   (`warrant/README.md`, `warrant/.claude-plugin/plugin.json`,
   `warrant/hooks/{directive.sh,hunt-guard.sh,hunt-state.sh,scope-gate.sh,
   state.sh,hooks.json}`, `warrant/agents/warrant-hunter.md`), registered in
   `.claude-plugin/marketplace.json` alongside `core`/`terse`/`freelunch`/
   `scout`. Content is a byte-identical import of the 0.4.1 cached source
   except for the cadence and record-shape changes below — pure relocation
   plus the proposal's section-2 additions, not a rewrite. Plugin version
   bumped to 0.5.0 to mark the cadence change.
   - The 43 vendored rulebook copies are outside this repo's write
     authority (separate repos) — per the proposal, that conversion to a
     reference stub is a follow-up tracked per-rulebook, not done here.
     The standalone `warrant` plugin repo re-pointing or deprecating in
     favor of this copy is likewise a linked issue in that repo, out of
     scope for this checkout.

2. **Proportional, bounded hunt protocol** — `warrant/hooks/directive.sh`'s
   hunt section now specifies: a three-tier wall-clock cap keyed off
   `git diff --stat` size (<=20 lines/docs-only -> 60s; 21-200 -> 120s
   default; >200 lines or >5 files -> 180s, may split into two sequential
   stances); a docs-only fast path that skips the before-landing dispatch
   with a mandatory skip line; and an adaptive-miss-streak rule that drops
   the next dispatch's tier by one step after 3 consecutive `NO FINDING`
   records, resetting to the size-derived default the moment a `FINDING`
   lands. Detection power is trimmed on a streak, never removed outright,
   per the issue's item-4 requirement.

3. **Measurement instrumentation** — `warrant/agents/warrant-hunter.md`'s
   record template now carries `cap_seconds`, `tier`, `diff_stat_lines`,
   `started_at`, `ended_at` on every section, including `NO FINDING` ones,
   and a `before-landing — skipped: docs-only, ...` shape for the fast
   path. This is the minimum needed for the delivery-size-bucketed
   time/token table the issue's item 2 asks for; no such table exists yet
   because no real records under the new frontmatter have accumulated —
   the proposal was explicit this PR instruments, it does not fabricate a
   number.

## What was deliberately not built

- Retroactive aggregation of past hunt time/token cost — no historical
  records carry the new fields, so there is nothing to aggregate yet.
- Editing the 43 vendored rulebooks or the standalone `warrant` plugin
  repo — both outside this repo's write authority.

## Side-effect check (issue item 4, carried from the proposal)

The three confirmed catches (proposal-vs-mechanism design error,
`isMinimized` silent failure, repo-wide stale-vocabulary residue) all sit
on non-docs-only diffs, so before-landing dispatch still fires for all
three at their size-derived default tier — none is a first-3-of-a-streak
case, so no tier reduction applies to any of them under the new protocol.
The fourth class is accepted unconfirmed per the approver's comment above.

## How this was judged

- `warrant/` mirrors `scout/`'s directory shape and is registered in
  `.claude-plugin/marketplace.json`.
- `directive.sh` states the three-tier cap, the docs-only skip, and the
  adaptive-miss-streak rule as directive text (this plugin's enforcement
  layer is prompt text plus the existing mechanical guards in
  `hunt-guard.sh`/`scope-gate.sh`, which are unchanged and still bound
  single-flight, session cap, and nesting exactly as before).
- The hunt record template carries the five new frontmatter fields on
  every outcome, including misses and skips.
