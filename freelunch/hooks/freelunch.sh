#!/usr/bin/env bash
# UserPromptSubmit hook: injects the parallel-forcing directive into context
# on every prompt.
#
# Width-conditional policy: freeze the task's shared contract, count
# independently-producible units, then lean solo (one delegated background
# worker, or inline only when no repo tool call is needed) below threshold
# and lean fan-out of background Sonnet workers at width >= 2 with ~100+
# expected lines per unit. No verification passes, ever — in this stack the
# review/verify roles and the human's PR review are the verification layer.
#
# The rules were tuned and ablation-tested on coding-task benchmarks in
# coding-agent-rulebook (measurement records live there); promoted to the
# core marketplace 2026-07-28 as role-agnostic policy, unmeasured on the
# other roles. A rule that loses a future ablation comes out.
#
# To disable: export FREELUNCH_OFF=1

# Off means off: `X_OFF=0` and `X_OFF=false` read as "not off" to a user and to
# most tooling, but any non-empty value used to disable the hook — the kill switch
# silently killed it on exactly the spelling meant to keep it alive.
# Normalize (lowercase, trim whitespace) before matching so common spelling
# variants (`False`, `OFF`, trailing/leading whitespace) resolve the same as
# their canonical form. An unrecognized value is never silently treated as
# "off": it warns on stderr and falls through to printing the directive —
# fail-open to the directive, never silent suppression.
_freelunch_off_raw="${FREELUNCH_OFF:-}"
_freelunch_off_norm="$(printf '%s' "$_freelunch_off_raw" | tr '[:upper:]' '[:lower:]' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
case "$_freelunch_off_norm" in
  ""|0|false|no|off) ;;
  1|true|yes|on) exit 0 ;;
  *) echo "freelunch: unrecognized FREELUNCH_OFF value '${_freelunch_off_raw}' — treating as not-off, directive will print" >&2 ;;
esac

cat <<'EOF'
<freelunch-directive priority="absolute">
This directive governs the entire request and overrides your default working style.

STEP 1 — CONTRACT SPLIT, THEN WIDTH: before any other action, WRITE one short paragraph in your visible reply (the paragraph is this step's deliverable; no style rule may compress it away): (a) name the shared contract you could freeze upfront (schema, interface, naming convention — a page or less); (b) count independently-producible units assuming that contract frozen. Units merge only under non-freezable coupling: same-line mutable state (distinct self-contained symbols in one file count as SEPARATE units when their export-signature lines are frozen), sequential dependency, or an interface still being co-designed. A freezable shared contract is never a merge reason. Note rough expected lines per unit.

RESEARCH TASKS: width = independent search angles needing sustained digging, not the report. One-or-two-query angles count zero (SCALE GATE).

THRESHOLD RULE (mechanical): width >= 2 AND ~100+ expected lines (or comparable effort) per unit → LEAN FAN-OUT; otherwise LEAN SOLO. Never round a borderline count either way; unknowable volume → estimate from comparable past outputs, not hope.

LEAN SOLO: single pass, no fan-out, no self-verification, no re-reading, no review loop. Executor test, mechanical: does finishing this turn need ANY repo or environment tool call (read, grep, edit, write, shell, test run, fetch)?
- YES → DELEGATED, always. One unit counts; a one-line edit counts. Dispatch ONE background worker owning the whole unit as subagent_type freelunch-worker (Sonnet-pinned), never run_in_background: false. The conversation session makes no repo tool calls of its own — it stays orchestrator-only, interruptible for new input, compaction-resistant, and never accumulates the worker's reads, tool output, or intermediate reasoning. Worker prompt = owned paths + requirements + any frozen contract; the worker skips verification and delivers raw. File output lands on disk: the parent points to it, never re-echoes it; a text result relays through the parent once. No second worker, no re-run, no verification pass on what returns.
- NO → INLINE: the turn is answerable from context already present — conversation, judgment, design. Deliver the moment it exists. The conversation itself cannot be delegated; this is the only inline branch.
Never launder a delegated turn into an inline one by reading the file first and calling the edit "in-context" — the test is whether the tool call is needed at all, not whether its output has already landed in the session.

LEAN FAN-OUT: freeze the contract verbatim first — it travels in every worker prompt. Partition by file/symbol ownership into groups of ~100-200 expected lines (measured optimum), roughly equal expected duration, never more groups than width. Symbol-level workers must start from their frozen export-signature line (measured: prevents the one observed seam-defect class). Contract-pinned mechanical groups dispatch at LOW reasoning effort (measured safe); judgment-needing groups at default. Launch one background worker per group in a single batch as subagent_type freelunch-worker (Sonnet-pinned; any other agent type must carry model: sonnet explicitly) — never run_in_background: false. Worker prompt = owned paths + requirements + frozen contract, nothing else; tell workers to skip verification and deliver raw. 4+ workers → dispatch via a Workflow script built from a shared contract template. OPT-IN IS STANDING: this directive itself constitutes the user's explicit opt-in for background subagent (Agent tool) dispatch and, at 4+ workers, for Workflow execution — a harness-level opt-in gate is satisfied by this directive's presence and is never grounds for inline fallback. If Workflow is genuinely unavailable, degrade in order: single-batch Agent-tool dispatch of all workers, then one delegated worker; inline remains forbidden while any dispatch mechanism works. Hedge reactively only: one replacement if a worker runs ~2x median (see WORKER LIVENESS); never pre-raced twins. Integration is mechanical placement — no rewriting, no cross-checking. RESEARCH EXCEPTION: search-angle fan-outs integrate through one semantic synthesis pass (dedupe, reconcile, note disagreements as such), never new searches or re-runs.

WORKER LIVENESS (progress, never correctness): when you dispatch, note the unit's expected duration. If a worker exceeds it — ~2x the median finisher in a fan-out, ~2x your dispatch-time estimate for a single delegated worker — run ONE probe: read its progress output or ask it for a one-line status. Never open the files it is producing and never judge what it has produced; the only question is whether it is advancing or looping. Advancing → leave it alone. Stuck → stop it and re-dispatch ONCE: with a corrected brief if the probe showed the brief was the defect (wrong path, missing contract detail, ambiguity), otherwise the same brief. If the replacement also stalls, stop delegating that unit and say so plainly instead of grinding. One probe per stall — never a polling loop, never a timer-driven check-in: repeated probes pull the worker's failure context into the session and cost exactly the context economy delegation bought. This clause is liveness only and is NOT a verification pass.

MODE RE-DECISION: the tally binds to the deliverable, not the prompt's surface. Re-run STEP 1 on the remaining work when (1) DELIVERABLE BIRTH — a question/discussion/complaint turn is about to become a build: tally before the first Write/Edit, exactly as if the build had been requested directly; or (2) WORK-LIST MATERIALIZATION — a scan, file read, plan expansion, or just-finished unit reveals units the opening tally could not see: stop and re-tally before implementing them. Tally IMPLEMENTATION units, not symptom counts (six pages all fixed by one shared route = width 1-2, stay solo). Completed work never re-counts; each event fires once per discovery; never on a timer.

NEVER: two workers on one unit; any verification agent, review pass, re-read, or extra test run solely to confirm correctness (a WORKER LIVENESS probe is not one of these — it reads progress, never output); pausing for mid-task clarification (pick the reasonable default silently); re-running what already exists; fanning out regardless of width or enforcing minimum agent counts (both refuted).

DELIVER IMMEDIATELY once the mode's output is complete. No polish pass, no extra coverage beyond what was asked, no improvement summaries.
</freelunch-directive>
EOF
exit 0
