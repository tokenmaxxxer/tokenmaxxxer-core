# scout

Know the field before you propose. The failure this targets: an agent
proposes and builds in a field it never looked at — so the result competes
with nothing, misses what everyone in the field assumes, and aims at no
quality bar. scout injects a bounded reconnaissance protocol that runs in
the research stage of phase 1 (role-handoff contract v3 §19), before any
proposal is written, and feeds its result straight into the proposal.

Shipped in the tokenmaxxxer-core marketplace because every role now has a
phase-1 research stage, and scout is its method: product-shaped work scouts
the category's best-in-class products; a feasibility probe scouts prior art
and comparable systems; a review plan scouts what strong audits of this
change-class check; an ops plan scouts how comparable systems roll out and
fail. The scout brief lands under `docs/issue-<n>/reports/<role>/` and
feeds the role's proposal directly.

**scout is steering, not verification.** It never compares the finished
work against exemplars, and it is not a research-report generator. One
`UserPromptSubmit` directive; no gates, no sniffers. `SCOUT_OFF=1`
disables it.

## When it runs

Default to running. Scouting is skipped only for a pure bugfix or when the
spec literally leaves no design decision open — those are the only two skip
conditions. "When in doubt, scout" is the rule, not a hint. When skipped, the
phase-1 survey must record the skip and its one-line reason; a skip with no
recorded reason isn't a proper skip.

## The protocol

Two stages, budgeted (hard cap: 5 stages total and 3min wall-clock total,
self-measured via `date` at each judge point), then propose:

1. **Sweep** (stage 1, parallel fan-out, no judgment interleaved) — up
   to 4 search angles (by-category, by-content, by-citation, by-time,
   ...) run genuinely concurrently in one turn, as parallel subagents or
   parallel tool calls. Breadth only, no exemplar judging yet. If
   parallel dispatch isn't available, fall back to batched-sequential
   and say so explicitly — never silently serialize.
2. **Observe and deepen** (stages 2-5, judgment lives here) — judge the
   combined sweep results together (actually top-tier? same segment?
   swap mismatches), then run focused deepening only on
   decision-relevant hits (snowballing from promising sources, not fresh
   top-level searches), one stage per round: extract must-bes, the 2-3
   performance axes, one pattern to adopt and one to skip, and
   praise/complaints where reachable. Stop rule (checked after every
   round): would another round change a decision? If no, stop even with
   budget left; hitting the 5-stage cap or the 3min wall-clock
   budget also stops deepening regardless.
3. **Scout brief** — mandatory whenever scouting ran: write
   `docs/issue-<n>/reports/<role>/scout-brief.md`. A scout pass that
   produces no file counts as not having scouted, regardless of how much
   searching happened. Size guide (soft): roughly within a page (~30
   lines including the Sources list) that feed the proposal and any
   worker contracts, plus which stage count and mode (parallel or
   batched-sequential fallback) the pass actually used. It remains a
   steering input — findings and decisions, not narrative: no
   battlecards, no SWOT, no matrix, not a research report. Every
   web-sourced claim (exemplar names, must-bes, praised/complained
   patterns) needs a source: append a `Sources:` list of the URLs
   actually consulted, counted within the ~30-line guide. No source, no
   claim: state it as an assumption instead.

Scouting is not a one-shot: whenever a new decision surfaces mid-work that
the brief doesn't cover, one micro-round re-aims that decision and extends
the brief. The trigger is always a new decision appearing — never a timer,
and never finished output; re-scout steers what is about to be made, it
does not re-examine what was made.

## Methodology lineage

The protocol compresses three established methods into a generation-time
rule:

- **Competitive benchmarking** (Robert Camp, Xerox, 1989): benchmark
  against the *best-in-class*, not the average competitor, and convert the
  observed gap into targets.
- **Kano model** (Noriaki Kano, 1984): expectations are tiered — must-be
  (assumed; absence reads as broken), performance (the competitive axis),
  attractive (delighters, which drift into must-bes as fields mature).
  scout extracts the current must-be set as the floor and picks
  performance axes as the direction.
- **Theoretical sampling and saturation** (grounded-theory lineage, Glaser
  & Strauss): the next lookup is chosen by judgment on what was just
  learned, and collection stops when new sources stop changing decisions.
  This is what makes scout directional — judgment-interleaved, finite —
  rather than a deep-research fan-out.

**Scope of evidence, honestly:** the lineage is established methodology,
but this compression of it was validated only on a small product-task A/B
in [coding-agent-rulebook](https://github.com/tokenmaxxxer/coding-agent-rulebook)
(where the measurement records live), and application to the other roles'
research stages is unmeasured as of this promotion (2026-07-28). One
transferable finding from that run: the directive worked without live web
search — by invoking trained knowledge of the field — so fast-moving
fields may still need live search.

## Install

    claude plugin marketplace add tokenmaxxxer/tokenmaxxxer-core
    claude plugin install scout@tokenmaxxxer-core

on-the-record enables it per role; nothing else needs to.

## Temporarily disable

    export SCOUT_OFF=1
