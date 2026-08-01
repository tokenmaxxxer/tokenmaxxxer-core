---
issue: 78
stage: scout-brief
---

# Scout brief (issue-78)

Mode: parallel WebSearch fan-out, 2 angles, 1 round. Stopped at judge point 1 —
both hits converge on the same direction the current-state survey already
suggested, so no deepening round needed.

## Angle 1 — extensible structural allowlist (analog: ESLint restricted-syntax)
- Must-be: an allowlist, not a denylist, for "which shapes are permitted" —
  users specifically request allowlist-of-permitted-patterns over
  denylist-of-forbidden-patterns so legitimate variants aren't blocked by
  default. ESLint's own escape hatch for restricted patterns
  (`no-restricted-syntax`) is itself config-driven (list of AST selectors),
  not a single hardcoded shape.
- Adopt: register permitted *shapes* as data (a manifest/config entry), the
  same pattern this repo already uses for `canon-manifest.txt`'s absence-list
  — extend that same data-driven registration to stub-check's structural
  check instead of hardcoding a second literal pattern in bash.
- Skip: full AST-selector matching (eslint-grade) — overkill for a bash
  regex-based structural gate; the repo's existing "line-classification"
  technique (source line / assignment / one known call) is the right altitude.
- Source: https://eslint.org/docs/latest/rules/no-restricted-syntax

## Angle 2 — hook scan scope by registration, not filename
- Must-be: scope hooks by how they're *wired* (matcher/event registration)
  rather than by filename convention — practitioner guidance for Claude Code
  hooks describes matcher-based registration (event + matcher regex) as the
  mechanism that determines what actually fires, independent of the script's
  own name.
- Adopt: compliance-check's scan scope should walk hooks.json's PreToolUse
  entries and resolve `${CLAUDE_PLUGIN_ROOT}/hooks/<name>.sh` command lines
  directly, instead of a `*-gate.sh` filename glob — this is exactly what the
  survey found missing (hunt-guard.sh, gh-guard.sh, observe.sh all wired but
  unmatched).
- Source: https://ranjankumar.in/hooks-policy-as-code-agent-enforcement

## Gap line
Current state already has the data-driven-manifest pattern (canon-manifest.txt)
but only for stub-check's absence-mode, not its structural mode; and
compliance-check has zero hooks.json-awareness (filename-glob only). Both
gaps are exactly where the two adopted must-bes point.
