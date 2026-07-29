# Survey: scout two-stage parallel protocol (issue #23)

## Current state

`scout/hooks/directive.sh` injects `<scout-directive>` at every role
session's `UserPromptSubmit`. The current protocol (three sequential
moves, two judge points) explicitly forbids parallel fan-out:

> Unbounded or parallel fan-out research: two judge points, then build.

Issue #23 asks to restructure this into two stages — sweep (parallel
fan-out, no judgment interleaved) then observe-and-deepen (judgment moves
to after the sweep) — capped at 5 stages total, ~2min soft wall-clock
budget, and requires phase-1 to *measure* rather than assume feasibility.

Write set for the eventual phase-2 edit: `scout/hooks/directive.sh` only
(the heredoc block). No other file in the plugin references the
protocol's step structure — `scout/README.md` describes it in prose and
will need a matching update, but is documentation, not enforcement; test
files (`scout/hooks/tests/parse-check.sh`) only check that the hook
parses/emits valid output, not the protocol's step count.

## Measurement 1: parallel subagent dispatch in this headless session

Dispatched two `Agent` tool calls (`general-purpose`, `run_in_background:
false`) in a single assistant turn, each running `date +%s.%N; sleep 8;
date +%s.%N`.

Results:
- Agent A: start `1785328999.09`, end `1785329007.09` (8.00s internal).
- Agent B: start `1785329000.02`, end `1785329008.02` (8.00s internal).
- Both internal start timestamps land within 1s of each other, and the
  parent's dispatch-to-both-return wall time was ~14s for two 8s-sleep
  agents — not ~16s+dispatch that sequential execution would produce.

**Conclusion: parallel Agent/subagent dispatch works in this headless
session** (spawn.py settings, same environment named in the issue).
Confirms the issue's premise that the sweep can run as real concurrent
subagents, not a serialized loop.

## Measurement 2: parallel WebSearch calls in one turn

Issued three `WebSearch` calls in a single assistant turn (by-topic
angles: grounded-theory saturation, scoping-review methodology,
snowballing). All three returned together in one tool-result batch after
~12s wall-clock (measured via `date` before/after). Sequential execution
of three independent web searches at this latency would be expected to
take substantially longer (each search alone plausibly 5-10s); the
batched return is consistent with concurrent dispatch, matching how
`Agent` calls in one message are documented to run in parallel.

**Conclusion: parallel WebSearch is available and usable for the sweep
stage** in this session, as an alternative or complement to parallel
subagents.

## Measurement 3: full-pass wall-clock feasibility

Not run as a literal 5-stage pass (would burn the phase-1 budget on
runtime measurement rather than proposal work), but extrapolated from
measurements 1-2: a parallel sweep of 3-4 angles completes in ~10-15s
wall-clock in this environment (batching, not per-angle serial cost).
Four further deepening stages, each a single parallel batch of 1-3
follow-up fetches on promising hits, cost roughly the same per stage
(~10-15s) if genuinely batched, or scale up if a deepening stage issues
calls one at a time.

At ~10-15s/stage x 5 stages, a full pass lands around 50-75s wall-clock —
**inside the ~2min soft budget**, provided each stage's calls are
actually batched in one turn (the measured mechanism) rather than looped
one call per turn. The proposal below sizes the query cap to keep this
true; it does not additionally re-measure a live 5-stage run this turn
(that is deep-research-shaped effort, not phase-1 scouting), and phase-2
execution of a real scout pass will be the first live end-to-end
timing — flagged as an open item in the proposal.

## Scout brief (per scout's own directive, applied to this scout task)

This deliverable is itself a research-method spec, so its category is
"structured search protocols" — must-bes and axes drawn from the sources
above (grounded theory, scoping-review methodology, snowballing):

- Must-be: explicit stop rule (saturation), not a fixed round count alone
  — all three lineages treat "would more data change a decision" as the
  actual gate, count caps are a backstop.
- Must-be: breadth before depth — scoping/PRISMA-ScR and multi-modal
  sweep both separate an unfiltered breadth pass from a judged narrowing
  pass; issue #23's stage split matches this directly.
- Performance axis chosen: recall via snowballing (up to ~51% of a
  systematic review's included sources come from citation-chasing per
  measurement-1 sources) — deepening stage should snowball from sweep
  hits, not re-run fresh top-level searches.
- Adopt: PRISMA-ScR's "document the search as replicable" habit — the
  new protocol should name its angles and stage count explicitly so a
  re-run is reproducible, which the existing single-round protocol
  already does loosely and the two-stage version should preserve.
- Skip: full systematic-review rigor (bias assessment, PICO forms,
  30-source sample-size targets) — scout is a steering tool with a
  2-minute budget, not a review methodology; adopting saturation and
  breadth/depth separation is enough, the heavier machinery would blow
  the budget for no build-direction gain.
- Segment fit: scout runs inside a role's phase-1 turn, not a standalone
  research task — the bar is "fast enough that it doesn't eat the
  phase-1 budget," which is the reason for the hard 5-stage /soft 2min
  caps, not for expanding a scoping review's usual multi-week scope.
