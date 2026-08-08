---
kind: current-state-survey
subject: issue-146
produced_by: architecture
---

# Current-state survey — issue-146

## What exists in this repo (core) already

- `core/hooks/lib/gate-lib.sh` / `gate-lib.py` — the "gate-house standard"
  (issue-72): a sourceable library every gate calls into instead of
  hand-rolling trap/kill-switch/deny machinery. Precedent for "one shared
  implementation, referenced by every consumer, never copied."
- `core/hooks/tests/stub-check.sh` — canon drift detector (issue-66/69).
  **Execution model is the direct precedent for #146's check**: it is
  never vendored; a rulebook invokes it by a path resolved against core's
  install root, passing its own hooks dir as the scan target
  (`"${CORE_PLUGIN_ROOT:-$CLAUDE_PLUGIN_ROOT/../core}/hooks/tests/stub-check.sh" "$(dirname "$0")/.."`).
  `core/hooks/tests/canon-manifest.txt` lists the filenames it treats as
  canon-pinned.
- `core/hooks/tests/compliance-check.sh` — scopes by **registration**, not
  filename: parses each `hooks.json`'s `PreToolUse` block to find which
  scripts are actually wired, then checks those. Direct precedent for how
  #146's check must find "the gates" without guessing filenames.
- `core/hooks/record-fields-gate.sh`, `core/hooks/handbook-trigger-gate.sh`
  — the two gates issue-147 (C1/C3) names as core's own mismatches; both
  deny on literal substrings/needles with no shared source of truth against
  injected prose.
- `core/hooks/directive.sh` (+ `core/hooks/lib/role-directive.sh`) — the
  injected SessionStart prose every role receives. This is the "prose
  surface" side of the tie for core; each rulebook's own
  `hooks/directive.sh` is the equivalent per-role surface, per issue-146's
  audit.
- `core/contract/role-handoff-contract.md` — authority document, but
  **issue-147 confirms 0 of 43 rulebook repos carry a copy**; it cannot be
  the prose surface the check verifies against, since role sessions in
  rulebook repos never read it.

## Prior fix precedent in this repo

`docs/issue-140/proposals/2026-08-07-accumulate-record-fields-violations.md`
fixed the *staircase shape* (deny once with the full violation set, not
N times) and widened `RECORD_FIELDS_TERMINAL_STATES`. It did **not** touch
the deeper problem #146/#147 name: the literals a gate denies on are still
absent from the injected directive text itself — #140 made the existing
mismatch cheaper to discover per-session (fewer refusal rounds), not
closed.

## Gap this proposal must fill

1. No existing script extracts a gate's literal needles (the accepted
   strings/spellings it string-matches on) as data.
2. No existing script extracts "the prose surface a role session actually
   receives" as data — `directive.sh`'s heredoc, injected fragments, and
   (per #147's fix direction, not yet built) any handbook/SKILL.md a
   `handbook-trigger-gate.sh`-class gate points a role at.
3. Nothing joins these two extractions and fails on the gap. This is
   exactly the class of tool the "documentation drift" literature calls a
   structural/anchor check (pairs a code anchor with a doc anchor, flags
   absence) as opposed to a semantic-consistency check (out of reach for a
   mechanical check, and out of scope here — confirmed by external
   scouting, see scout-brief.md).

## Constraint the design must satisfy

Per issue-146 acceptance: "runnable per-repo." The 43 rulebook repos are
**separate repos** from core, each installing core as a plugin. A per-repo
CI check therefore cannot be new code living only in core's own test
suite — it must be invocable the same way `stub-check.sh` and
`compliance-check.sh` already are: referenced from a rulebook's own CI
step, resolved against core's plugin-install path, run against that
repo's own `hooks/` and prose-surface files.
