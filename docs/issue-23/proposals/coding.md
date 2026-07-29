# Proposal: two-stage scout protocol — parallel sweep, then observe-and-deepen (issue #23)

## files

- `scout/hooks/directive.sh` (lines 33-53, the `THE PROTOCOL` / `NEVER`
  blocks of the heredoc-injected `<scout-directive>`)
- `scout/README.md` (the "## The protocol" section, which restates the
  same steps in prose for humans reading the plugin)

No other file needs a change. The survey
(`docs/issue-23/reports/coding/survey.md`) confirms `directive.sh` is the
only enforcement/injection site for the protocol's step structure, and
`scout/README.md` is the only prose restatement of it.

## Request

Issue #23: `scout`'s directive currently mandates strict sequencing (one
identification round, one extraction round) and explicitly bans parallel
fan-out research. Breadth doesn't need judgment, so serializing it costs
speed and coverage for no benefit — judgment is only needed when deciding
where to dig deeper. Restructure into two stages inside the same phase-1
research step (no new role): (1) sweep — several search angles run
concurrently, no judgment interleaved; (2) observe-and-deepen — judge the
combined sweep results, then run focused deepening (snowballing) only on
decision-relevant hits, saturation as the stop rule. Hard budget: sweep +
deepening ≤ 5 stages total. Soft budget: whole pass ~2 minutes
wall-clock, measured via `date`.

Phase-1 measurement (survey.md) found: parallel `Agent` dispatch and
parallel `WebSearch` calls both work in this headless session (spawn.py
settings) — two 8s-sleep subagents launched in one turn returned within
~14s total (not ~16s+ sequential), and three `WebSearch` calls issued in
one turn returned together in ~12s. A 5-stage pass built from batched
parallel calls per stage is estimated at ~50-75s wall-clock, inside the
2-minute soft budget, provided each stage batches its calls in one turn
rather than looping one call per turn.

## Constraints

- Phase-1-only session (contract v3 s19): this proposal does not touch
  `scout/hooks/directive.sh` or `scout/README.md`. Only
  `docs/issue-23/reports/coding/survey.md` and
  `docs/issue-23/proposals/coding.md` are written in this phase.
- Preserve everything the current directive already gets right per its
  own doctrine and this issue's explicit list: judgment gates (moved to
  the observe point and deepening, not removed), finiteness (the new
  stage/time budgets replace, not add to, the old two-judge-point cap),
  steering-not-verification (still no post-build comparison, still not a
  report generator), the existing skip conditions (fully-specified
  implementation / pure bugfix / user says skip), and the ≤10-line brief
  that feeds the proposal.
- The hard budget is count-based and must be mechanically checkable from
  the text alone: sweep = stage 1, deepening ≤ 4 further stages, total
  ≤ 5. Total search/fetch call cap: 12 (3-4 angles per stage x up to 3
  stages of meaningful deepening before saturation typically stops it
  earlier — sized from the measured ~10-15s per batched stage so 5
  stages of that size land under the 2-minute soft budget with margin
  for dispatch overhead).
- The soft time budget is advisory, not gating: the role measures elapsed
  time and cuts deepening short when spent, but a slow environment
  (parallelism unavailable) does not make the role fail phase 1 — it
  falls back to batched-sequential and says so, per the issue's explicit
  requirement to report which was measured.
- `scout/hooks/tests/parse-check.sh` must still pass unmodified (it only
  checks that the hook emits parseable/well-formed output, not step
  count), so the edit must keep the heredoc a single valid here-doc block.

## What will be done

In phase 2 (after Approve), replace `scout/hooks/directive.sh` lines
33-53 (the `THE PROTOCOL` through `NEVER` blocks) with:

```
THE PROTOCOL, two stages, budgeted (hard: sweep + deepening <= 5 stages total; soft: ~2min wall-clock, cut deepening short when spent — measure elapsed time, e.g. via `date`, at stage boundaries):

STAGE 1 — SWEEP (parallel fan-out, no judgment interleaved): run several search angles concurrently in one turn — e.g. by-category, by-content, by-citation/links, by-time — as parallel subagents (Agent tool, one message with multiple calls) or parallel tool calls (e.g. multiple WebSearch calls in one message). This is the core requirement: the sweep must actually run its angles concurrently, not as a serialized loop dressed up as fan-out. If parallel dispatch is unavailable in the current session, fall back to batched-sequential in one session and SAY SO explicitly (which mode was used) — do not silently serialize. Cap: up to 4 angles, one round, breadth only — no exemplar judging yet.

STAGE 2+ — OBSERVE AND DEEPEN (judgment moves here, up to 4 further stages):
JUDGE POINT 1: look at the sweep's combined results together — overlap across angles signals where the field's real signal is; are these actually top-tier / same segment as this deliverable? Swap out mismatches now.
Then run focused deepening only on decision-relevant hits (e.g. snowballing from promising sources: follow their references/citations, not fresh top-level searches) — one stage per deepening round, each stage batching its calls in one turn the same way the sweep did.
Extract per round: must-bes (Kano) — what do the strong hits therefore assume?; performance axes — 2-3 dimensions they visibly compete on; one pattern to adopt, one to deliberately skip; user expectations if reachable (reviews, complaints).
JUDGE POINT 2 (saturation rule, checked after every deepening stage): would another round change any build decision? If no, STOP — even if stages remain in the budget. If yes and stages remain, run one more deepening stage. Hitting the 5-stage cap or the ~2min soft budget also stops deepening regardless of saturation.

SCOUT BRIEF, then build immediately: compress into at most 10 lines — category must-bes, chosen performance axes, adopt/skip patterns, one line on segment fit, and which stage count / which mode (parallel or batched-sequential fallback) the pass actually used. The brief feeds the build direction and any worker contracts directly. It is a steering input, not a report deliverable: no battlecards, no SWOT, no competitor matrix.

RE-SCOUT TRIGGER (scouting is not a one-shot): the brief covers the direction decisions known at the start. Whenever a NEW product-facing decision surfaces mid-build that the brief does not cover — an added flow or screen, a changed scope, a sub-deliverable nobody anticipated — run ONE micro-round on exactly that decision (treat it as a one-stage deepening round: sweep or snowball on that decision alone, one judge point), extend the brief by a line or two, and continue building. The trigger is a new DECISION appearing, never a timer and never finished output: re-scouting re-aims what is about to be built; it does not re-examine what was built. A decision already made and built stays made unless the user reopens it.

NEVER:
- Post-build comparison against the exemplars — scout steers before generation; it is not a review pass.
- Cloning the exemplar: the reference sets the BAR, the user's intent sets the DIRECTION. Copy the expectation level, not the product.
- Exceeding 5 total stages or blowing well past the ~2min soft budget without cutting deepening short — the budgets exist so scouting stays a steering input, not a deep-research fan-out. If the user wants an actual research report, that is a different task — say so.
- Serializing the sweep and calling it fan-out — stage 1 must be genuinely concurrent (parallel subagents or parallel tool calls in one turn) or the role must state plainly that it fell back to batched-sequential and why.
- Fabricating exemplars or expectations when search is unavailable: state that scouting was skipped and why, then build on stated assumptions.
```

And replace the `## Methodology lineage` / `## The protocol` section of
`scout/README.md` so the human-readable description matches: two stages
(sweep, then observe-and-deepen), the 5-stage hard cap and ~2min soft
cap, and the requirement that the sweep run genuinely concurrently (with
the batched-sequential fallback named when parallelism isn't available).

## Out of scope

- Editing `scout/hooks/directive.sh` or `scout/README.md` themselves —
  phase-1 only; deferred to phase 2 after human Approve.
- Any change to `scout/hooks/hooks.json` or
  `scout/hooks/tests/parse-check.sh` — the hook's trigger wiring and
  parse-validity check are unaffected by a content change to the
  heredoc's protocol text.
- A live, timed 5-stage scout pass as part of this proposal — measurement
  1-3 in the survey extrapolate feasibility from smaller, directly
  measured parallel batches; the first real end-to-end 5-stage timing
  will happen the first time a role session actually runs the new
  protocol in phase 2 of some future issue, not in this proposal.
- Changing the plugin version/marketplace metadata — content-only change
  to the directive text and README, not a packaging change.

## How we'll know it worked

- `grep -n "Unbounded or parallel fan-out research" scout/hooks/directive.sh`
  returns no match after the phase-2 edit (the current ban on parallel
  fan-out is gone).
- `grep -n "STAGE 1 — SWEEP" scout/hooks/directive.sh` matches (the new
  two-stage structure is present).
- `bash scout/hooks/tests/parse-check.sh` (or however that test is
  invoked) still passes — the heredoc remains a single valid block.
- `scout/README.md`'s protocol section describes the same two stages and
  budgets as `directive.sh`'s injected text, so a human reading either
  reaches the same conclusion about what the sweep/deepen split and
  budgets are (the same "informing half describes what the enforcing
  half enforces" property this repo already applies to `directive.sh`
  scripts elsewhere).
- The new text retains every clause issue #23 explicitly asked to
  preserve: judgment gates (now at observe + saturation-recheck), the
  finite budgets (5 stages / ~2min, replacing the old 2-judge-point cap),
  steering-not-verification, the skip conditions, and the ≤10-line brief.
