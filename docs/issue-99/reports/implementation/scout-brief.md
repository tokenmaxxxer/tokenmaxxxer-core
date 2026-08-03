---
issue: 99
stage: scout-brief
---

# Scout brief (issue-99)

Mode: parallel WebSearch fan-out, 2 angles, 1 round. Stopped at judge
point 1 — both hits converge on the same direction the current-state
survey's gap (section 4: what discriminates a safe vs. unsafe
empty-candidates case) already pointed at, so no deepening round.

## Angle 1 — how shell-command security gates track `cd`/relative writes
- Must-be: a write-target check needs either (a) per-command argument
  extractors that understand each command's own flag/positional shape
  (`cd` joins its arguments into one path; `cp`/`mv` put the destination
  last; a redirect's target follows `>`), or (b) a deliberately simpler
  model that avoids per-command extraction entirely by disallowing `cd`
  and requiring root-relative paths everywhere.
- Adopt: the simpler model's *shape*, not its `cd`-block choice — track
  only "did a preceding `cd` land under `docs/`" (existential, no
  full relative-path resolution), which needs no per-command argument
  table and reuses this file's existing per-segment classification. This
  matches what the issue itself already suggests as the discriminator.
- Skip: blocking `cd` outright (one exemplar's approach) — board-gate.sh
  already allows `cd` as a read-only head specifically to fix a prior
  false positive (issue-88's `bash-cd-then-cat`); reverting that would
  regress an already-pinned regression case.
- Source: https://deepwiki.com/coleam00/Linear-Coding-Agent-Harness/6.2-bash-command-allowlist

## Angle 2 — AST-based shell parsing (bashlex/tree-sitter) vs. regex for this class of gate
- Must-be: structured (AST) parsing respects shell quoting/nesting/
  operator precedence more accurately than regex, and production systems
  combining both still fail closed on parse failure rather than treating
  an unparseable command as safe.
- Adopt: the fail-closed posture on the specific reachable ambiguity
  (docs/-cd'd context + an unclassifiable write target) — matches
  requirement 1's "fail-closed" ask directly.
- Skip: replacing board-gate.sh's regex/segment model with a real parser
  (bashlex etc.) — a new dependency this repo's own convention avoids
  (issue-90's record: "no new dependency... reuses the segment model");
  disproportionate to two named, narrowly-reproducible defects, and
  discards an already 71-case-verified architecture (issue-88/90/94).
- Source: https://arxiv.org/html/2607.21642v1

## Gap line
Current state (survey section 4) already has per-segment read/fail
classification (issue-90) but no `cd`-target tracking and no notion of
segment *order*. Both search angles point the same direction: extend the
existing lightweight per-segment model with a minimal, existential `cd`
discriminator, not a new parser and not a `cd` ban.
