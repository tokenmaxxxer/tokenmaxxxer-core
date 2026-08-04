---
kind: scout-brief
subject: issue-106
produced_by: implementation
---

# Scout brief — issue-106

Mode: 2 parallel WebSearch angles in one turn (by-symptom: headless CLI
background-subprocess-exits-before-completion bug reports across other
agent tools; by-vendor: Claude Code's own headless-mode/`run_in_background`
documentation), one round. Judged saturated after round 1 — internal
precedent (four prior sessions in this same repo, see survey) already
converges on the same fix shape as the external hits, so a second round was
judged unlikely to change any build decision; no deepening round run.

Must-bes the field converges on:
- The failure class this issue names is not unique to this stack: other
  agent-CLI issue trackers report the identical shape — a main loop treats
  itself as idle and exits while a dispatched background task is still
  outstanding, because the exit check does not account for it (oh-my-openagent
  issues #3452, #4721: "exits prematurely when background tasks are active",
  "exits before background completion parent wake is processed").
- The general remedy pattern in that field is either (a) the host waits for
  outstanding background work before allowing exit, or (b) the caller is
  required not to leave background work outstanding when it stops driving
  the loop. Claude Code's own headless docs describe (a) as a host-level
  guarantee in current versions ("background subagents and workflows are
  exempt from the five-second grace... `claude -p` waits for them to
  complete", capped at 10 minutes) — but this is host/version-dependent
  behavior, not something a role-level contract can assume for every run,
  and the incident this issue reports (repo-status-board issue #29 phase 2)
  demonstrably did not get that guarantee.

Performance axis this fix competes on: never assume the host will wait
(robustness across host/version variance) vs. convenience of "just delegate
and let the host handle it" — the same tradeoff every hit in the field
lands on the side of explicit caller responsibility, not host trust.

Adopt: state the rule as caller-side (role-session) obligation — delegate
only if the same turn will consume the result before ending, never rely on
an assumed host wait guarantee. This matches this repo's own already-repeated
ad hoc practice (see survey) and the field's (b) remedy.
Skip: proposing or speccing any host-side fix (a stall-watchdog, a
main-loop wait-for-background-tasks patch) — that is explicitly otr's
(on-the-record) territory per issue #247 and PR #256, not this repo's, and
out of scope for issue #106's own stated constraints.

Gap line: the practice already exists informally (four prior sessions in
this repo independently reasoned their way to "run foreground/synchronously,
this is a headless single-shot turn" — see survey) but has never been
written down as a binding rule, and nothing states its priority over
freelunch's own "always delegate, priority=absolute" directive. That is
exactly the gap this issue's requirements 1 and 2 ask to close.

Sources:
- https://github.com/code-yeongyu/oh-my-openagent/issues/3452
- https://github.com/code-yeongyu/oh-my-openagent/issues/4721
- https://code.claude.com/docs/en/headless
