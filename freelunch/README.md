# freelunch ⚡

*"The free lunch is over" — so said Herb Sutter in 2005: no more speed for
free, go parallel. This plugin takes the deal literally.*

Parallel-execution steering for every tokenmaxxxer role session. It freezes
the task's shared contract, estimates its *width* — the count of
independently-producible deliverable units given that frozen contract — and
then branches: a lean solo pass for narrow tasks (delegated to a single
background worker unless the turn needs no repo tool call at all), or a
lean fan-out of concurrent background Sonnet agents when width is 2+ with
~100+ expected lines per unit. It optimizes wall-clock time only and skips
quality-verification passes by design.

Shipped in the tokenmaxxxer-core marketplace because the policy is
role-agnostic: every role now runs a research phase (contract v3 §19 phase
1) whose independent search angles fan out the same way build units do, and
every role's session benefits from staying a thin, interruptible
orchestrator instead of accumulating tool output inline.

**Scope of evidence, honestly:** every rule in this plugin was tuned and
ablation-tested on coding-task benchmarks in
[coding-agent-rulebook](https://github.com/tokenmaxxxer/coding-agent-rulebook),
where the measurement records live. Application to the other roles is
unmeasured as of this promotion (2026-07-28). Per stack policy, a rule that
loses a future ablation comes out.

## How it works

- `hooks/freelunch.sh` — `UserPromptSubmit` hook that injects the forcing
  directive into context on every prompt.
- `agents/freelunch-worker.md` — Sonnet-pinned worker agent that finishes
  one chunk with no verification pass.
- `workflows/site-fanout.js`, `workflows/code-fanout.js` — reusable fan-out
  scripts; dispatch passes only compact per-task specs via `args`.

The directive's core rules:

1. **Contract split, then width**: first identify any shared contract
   (schema, interface, vocabulary, style guide) freezable upfront in
   roughly a page, then count independently-producible units ASSUMING it
   is frozen. Units merge only under non-freezable coupling: shared
   mutable state (the same *lines* — distinct self-contained symbols in
   one file count separately when each unit's export-signature line is
   frozen verbatim), sequential dependency, or an interface still being
   co-designed. Sharing a freezable contract is NOT a merge reason.
   Research tasks count independent search angles instead of the single
   final report, gated so quick lookups stay solo; their integration step
   allows one semantic synthesis pass.
2. Width below threshold (width < 2, or units too small to amortize
   dispatch) → **lean solo**: single pass, no self-verification, no
   re-reading finished units. If finishing the turn needs any repo or
   environment tool call, the whole unit goes to ONE background worker and
   the session stays orchestrator-only; only turns answerable from context
   already present run inline.
3. Width 2+ with ~100+ expected lines per unit → **lean fan-out**: freeze
   the contract verbatim, partition by file- or symbol-level ownership
   into roughly equal-duration groups packed to ~100-200 expected lines
   each, never more groups than the width count. Symbol-level groups are
   assembled by fixed-order concatenation and each such worker starts from
   its frozen export-signature line.
4. Every fan-out worker runs on Sonnet, launched in the background in a
   single batch — never synchronous. Workers on mechanical contract-pinned
   groups run at low reasoning effort; default effort where the unit needs
   judgment beyond the contract.
5. Worker prompts are minimal: owned path(s), requirements, and the frozen
   shared contract. Workers are told explicitly to skip verification.
6. Fan-outs of 4+ workers dispatch via a Workflow script built from a
   shared contract template, so the contract is emitted once.
7. Hedging is reactive only — a straggler at ~2x median finish time (or
   ~2x the dispatch estimate, for a single delegated worker) gets one
   liveness probe, then one replacement if it is looping rather than
   advancing; never a pre-race of every chunk. The probe reads progress,
   never the worker's output, and retries are capped at one.
8. Integration is mechanical assembly: each group's output goes to its
   slot, no rewriting, no cross-checking workers against each other, no
   review pass, under either mode.

## Telemetry & optional enforcement

A `PreToolUse` hook (`hooks/observe.sh`) logs every Agent/Task/Workflow
dispatch to `~/.claude/freelunch-observe.jsonl` (override:
`FREELUNCH_OBSERVE_LOG`), flagging the syntactically checkable rules —
synchronous agent dispatch (`run_in_background: false`) and off-Sonnet
workers. Default is observe-only: nothing is ever blocked. With
`FREELUNCH_ENFORCE=1` a flagged call is denied with a corrective reason and
the model re-issues it corrected. Known blind spot: `agent()` calls inside
a Workflow script are SDK-internal and don't pass through PreToolUse, so
the Sonnet pin there rests on the scripts' own `model: 'sonnet'` default.

## Install

    claude plugin marketplace add tokenmaxxxer/tokenmaxxxer-core
    claude plugin install freelunch@tokenmaxxxer-core

on-the-record enables it per role; nothing else needs to.

## Temporarily disable

    export FREELUNCH_OFF=1   # hook injects nothing, observer logs nothing

## Caveats

- Skipping verification is by design. When a contract is wrong, seam bugs
  ship. Turn the plugin off for work where you need to trust the result
  without a downstream reviewer — in this stack, review/verify roles and
  the human's PR review are the verification layer.
- Width, not task size, drives the branch: a long but coupled task counts
  as narrow and runs lean solo; a short but decomposable task counts as
  wide and fans out.
