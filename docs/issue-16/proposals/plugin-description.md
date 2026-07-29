---
kind: build-proposal
subject: issue-16
produced_by: coding
upstream: []
loop_state: scope-proposed
---

# Proposal: rewrite `core/.claude-plugin/plugin.json`'s stale description

files:
- core/.claude-plugin/plugin.json

## Request

`core/.claude-plugin/plugin.json:3`'s `description` field still advertises
a single-use approval-token-minting mechanism that was deleted in commit
`1a69a08` ("Replace token machinery with the issue/PR interaction model
(contract v3)") together with `core/hooks/mint.sh`, `core/hooks/
lib/consent.py`, and `core/hooks/lib/judge.py`. The description was
written one day before that deletion (commit `8696dd5`) and was never
revisited, so it is the first thing a plugin installer reads and it
describes something that no longer exists. Rewrite the description to
match what `core` actually ships today — the canonical role-handoff
contract (v3) plus its four hooks — while keeping the missing `version`
field exactly as it is, rationale sentence included, unchanged.

## Constraints

- **No `version` field is added.** Its absence is deliberate: *"No
  version field on purpose: for a git-distributed plugin the commit SHA
  is the version, so every commit is an update."* This sentence (or one
  materially identical to it — see "What will be done" for the exact
  text carried forward) must remain present in the rewritten description,
  unchanged in meaning, since `README.md:146-148` independently states
  the same rationale and the two must not contradict each other.
- **Phase-2 execution waits for a human Approve.** This document is phase
  1 (research + survey + proposal) only. No edit to `plugin.json` happens
  in this PR; it lands only after an approver listed in
  `docs/specs/approvers.md` submits a PR review Approve (or, in
  single-account mode, posts the exact comment `APPROVE issue-16/coding`
  — contract v3 s19).
- **The write set does not widen.** Exactly the one file listed in
  `files:` above. `README.md`, `.claude-plugin/marketplace.json`, and
  `core/contract/role-handoff-contract.md` are not touched — see
  `docs/issue-16/reports/coding/current-state.md`'s "Projected write set"
  section for why none of them need to move in lockstep with this edit.
- The rewritten string must not claim anything `core` doesn't ship (no
  token/mint/challenge-line language survives) and must not omit the
  version-field rationale.

## What will be done

Replace the `description` value in `core/.claude-plugin/plugin.json`
(currently 419 characters, quoted in full in `current-state.md`) with:

```
Shared interaction-protocol machinery for every tokenmaxxxer role. Ships the canonical role-handoff contract (v3) and four hooks — directive.sh, board-gate.sh, approval-gate.sh, gh-guard.sh — the SessionStart briefing plus deny-only PreToolUse gates for docs layout, PR-Approve execution gating, and GitHub-act ownership. Gates refuse but never permit. No version field on purpose: for a git-distributed plugin the commit SHA is the version, so every commit is an update.
```

(473 characters — 8% longer than the phrase-for-phrase register observed
across the marketplace's four plugin descriptions, 233-447 chars, and
close to `core`'s own historical high end of that range at 419-447.)

This is the recommended string over a shorter, filename-free fallback
that stays fully inside the observed register:

```
Shared interaction-protocol machinery for every tokenmaxxxer role. Ships the canonical role-handoff contract (v3): a SessionStart briefing hook plus three deny-only PreToolUse gates for docs layout/contract sync, PR-Approve execution gating, and GitHub-act ownership. Approval is a GitHub act, not a minted token; gates refuse but never permit. No version field on purpose: for a git-distributed plugin the commit SHA is the version, so every commit is an update.
```

(463 characters, no hook filenames named.)

**Recommendation: the first (named) string.** Reasoning: the task
explicitly asks the rewritten description to enumerate the four hooks "by
their real names as found on disk," and the whole point of issue #16 is
that a vague, unenumerated description is what let staleness go
unnoticed for a full day-then-never — naming the four files makes any
*future* staleness (a hook renamed or removed without the description
being touched) far more visibly wrong on inspection than a purely
functional description would be. The overshoot past the observed register
is modest (473 vs. a 447-char precedent already set by this exact
plugin's own marketplace listing) and `core`'s description has always run
longer than its siblings' since it's the foundational protocol plugin, so
this is consistent with, not a break from, the existing pattern.

Both candidate strings:
- Preserve the version-field rationale sentence verbatim:
  *"No version field on purpose: for a git-distributed plugin the commit
  SHA is the version, so every commit is an update."*
- Drop every reference to minting, tokens, and challenge lines.
- State that gates refuse but never permit (the design invariant restated
  from `README.md`'s "Rules" section, still true today).
- Name the canonical contract as "the role-handoff contract (v3)."

## Out of scope

- No change to `core/contract/role-handoff-contract.md`, `README.md`, or
  `.claude-plugin/marketplace.json` — see Constraints.
- No change to any hook's behavior, `hooks.json` bindings, or tests.
  `core/hooks/tests/run-all.sh` is expected to pass unmodified before and
  after this edit (see "How you'll know it worked").
- No `version` field is introduced.
- No sibling plugin's (`terse`/`scout`/`freelunch`) `plugin.json` is
  touched.
- Choosing between the two candidate strings above beyond the stated
  recommendation is left open for the human approver to override in
  review; either is compatible with every constraint in this document.

## How you'll know it worked

1. **The manifest still parses.** After the phase-2 edit:
   `jq . core/.claude-plugin/plugin.json` (or
   `python3 -c "import json; json.load(open('core/.claude-plugin/plugin.json'))"`)
   exits 0 — valid JSON, `name`/`description`/`author` keys intact, no
   `version` key introduced.
2. **The description no longer names the deleted mechanism.** `grep -iE
   "mint|token|challenge.line" core/.claude-plugin/plugin.json` returns no
   match.
3. **The description names what ships.** `grep -c "role-handoff contract"
   core/.claude-plugin/plugin.json` and a check that all four hook
   filenames (`directive.sh`, `board-gate.sh`, `approval-gate.sh`,
   `gh-guard.sh`) appear in the string (only if the recommended, named
   variant is the one landed).
4. **The version-field rationale survives verbatim.** `grep -F "No
   version field on purpose: for a git-distributed plugin the commit SHA
   is the version, so every commit is an update." core/.claude-plugin/
   plugin.json` matches, and `jq 'has("version")'
   core/.claude-plugin/plugin.json` prints `false`.
5. **Nothing else regresses.** `bash core/hooks/tests/run-all.sh` passes
   — expected to be a no-op confirmation since no test in that suite
   reads the `description` field (confirmed by `grep -rn description
   core/hooks/tests/` returning no matches today), but it is the issue's
   own stated "done when" condition and costs nothing to re-run.
