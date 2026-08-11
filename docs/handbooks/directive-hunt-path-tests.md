# directive hunt-path test harness

`warrant/hooks/tests/run-directive-hunt-path-tests.sh` renders
`warrant/hooks/directive.sh`'s static stdout (no env needed — it is a
`cat <<'EOF'` heredoc) and asserts the rendered hunt-dispatch instruction
text.

Run it directly, no setup required:

    bash warrant/hooks/tests/run-directive-hunt-path-tests.sh

issue-202: `directive.sh` used to instruct the hunter to name its hunt
record `docs/issue-<n>/reports/hunt-<slug>.md` unconditionally whenever the
proposal path carried an issue segment. Inside a role session governed by
`core/hooks/board-gate.sh`, that path's first segment after `reports/` is
`hunt-<slug>.md`, which matches none of R5's allowed shapes
(`<role>.md`, `<role>/**`, or the role's extra subtree), so every
implementation session stranded on its post-PR hunt dispatch. Covers:

- `role-scoped-hunt-path-present` / `role-scope-condition-matches-R4-check`:
  the rendered text names the role-subtree template
  (`docs/issue-<n>/reports/<role>/<date>-hunt-<proposal-slug>.md`) and
  states the same role-scope check as `board-gate.sh`'s R4
  (`CLAUDE_ROLE` set AND the session's own branch resolves as exactly
  `issue-<n>/<CLAUDE_ROLE>`).
- `standalone-fallback-path-present` / `issue-segment-fallback-path-present`:
  the two pre-existing templates (`docs/reports/<date>-hunt-<slug>.md` for
  no issue segment, `docs/issue-<n>/reports/hunt-<slug>.md` for an issue
  segment with no role scope) remain present, unchanged.
- `old-templates-conditioned-not-unconditional`: the old templates are now
  reachable only through the "otherwise, fall back" branch, not stated as
  the unconditional rule.
