# Survey — issue-195

## Write set

- `core/hooks/lib/role-directive.sh` — `core_role_directive()`'s heredoc, line 46
  (`RECORD: docs/issue-<n>/reports/${role}.md, ...`), the only place the
  RECORD line is authored. All 43 rulebooks source this file and call the
  function; no rulebook overrides the RECORD line locally (grep: only
  `core/hooks/lib/role-directive.sh` defines `core_role_directive`).

## Current state

- The function is a 48-line sourceable lib (`core/hooks/lib/role-directive.sh:27-48`).
  It builds a heredoc from four caller-supplied strings plus one fixed
  closing line naming the record path and phase-gating rule, but not the
  record's *shape*.
- `core/hooks/tests/parse-check.sh` re-parses every hook `.sh` file under a
  pinned bash 3.2 binary (`BASH32`) to catch bash4-only syntax. The function
  already avoids `${var^^}` (uses `tr` instead, per its own comment at
  line 24-26) — the only 3.2-compat constraint that touches this function.
  A heredoc text-only change carries no new syntax, so this constraint is
  satisfied by not touching anything but the string literals.
- No existing test exercises `core_role_directive`'s heredoc content
  (`grep -rn core_role_directive` under `core/hooks/tests/` returns nothing).
  The issue's own acceptance check (`CLAUDE_ROLE=implementation` capture +
  grep for the three rule strings) is therefore new coverage, not an
  extension of existing coverage.

## Skip condition

Scouting and the alternative-naming Rationale are skipped under the
scout-directive's second mandatory condition: **the spec leaves no design
decision open**. The issue body (`## What will be done`) states the three
rules verbatim — `code_under_review` must be a file list (no sha),
count claims must cite a code fence plus a `derived:` line, and an
Accumulation-shaped change must fill the proposal's `## Accumulation`
section — and names the exact mechanism (append to the existing heredoc,
no new wiring). There is no product-shaped surface, no library choice, and
no alternative implementation approach that is also plausible given this
survey: the only place the RECORD line can be authored is this one heredoc,
and the issue already specifies the exact three rules to add to it.
