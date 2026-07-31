---
subject: issue-63
role: implementation
---

# Scout brief — warrant-hunt canon promotion

Mode: single-session desk research, one round (issue text names the
comparable system directly — scout — so sweep angles collapsed to
reading scout's own source plus warrant's own source and the repo's real
hunt records; no external web search needed). Stages used: 1 (below
budget); no re-scout trigger fired.

Comparable system (in-repo, same audience, higher canon maturity):
**scout** (`scout/hooks/directive.sh`, `scout/README.md`).

Must-bes scout enforces that hunt currently lacks:
- Hard total budget (stage cap + wall-clock cap), self-measured via `date`.
- Mandatory brief/record artifact whenever the protocol actually ran.
- Mandatory skip record with a named reason when the protocol is skipped.
- Saturation/stop rule judged against decision relevance, not a fixed count.
- Single canonical source referenced by every consumer, not vendored copies.

Performance axes hunt and scout compete on: (1) cost proportionality to
delivery size, (2) detection power retained after any budget cut, (3)
auditability of what ran vs. was skipped.

Adopt: budget expressed as (stage-equivalent, wall-clock) pair, mirroring
scout's 5-stage/3min shape but re-derived for hunt's two-dispatch shape
(see proposal); mandatory record-or-skip-record symmetry.

Skip (deliberately not copying): scout's sweep/deepen staging model
itself — hunt's two fixed dispatch points (after-proposal, before-landing)
are a different shape driven by warrant's proposal/build lifecycle, not a
multi-round search, so importing scout's "up to 5 stages" literally would
misfit. Proposal instead scales *within* each of the two dispatch points
by diff size/kind, not by adding stages.

Gap line: hunt already has scout's single-flight/cap mechanics
(`hunt-guard.sh`) and an anti-anchoring stance rule — those must-bes are
met. Missing: proportional budget, mandatory record/skip-record symmetry,
adaptive cadence on repeated misses, and canonical single-source
distribution (scout ships from this repo; hunt ships from a separate
`warrant` plugin never vendored-vs-referenced here).

Sources: scout/hooks/directive.sh, scout/README.md,
~/.claude/plugins/cache/tokenmaxxxer/warrant/0.4.1/{README.md,agents/warrant-hunter.md,hooks/*.sh}
(local plugin cache, not web), docs/reports/2026-07-30-hunt-issue-comment-approval-scope.md,
docs/reports/2026-07-30-hunt-strip-wake-vocabulary.md.
