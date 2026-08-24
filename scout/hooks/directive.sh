#!/usr/bin/env bash
# UserPromptSubmit hook: injects the pre-build reconnaissance directive.
#
# Methodology lineage (v0.1.0, 2026-07-19): the protocol is a compression of
# three established research methods into a generation-time steering rule —
#  - Competitive benchmarking (Camp 1989, Xerox): compare against BEST-in-class,
#    convert the observed gap into build targets. Not "who else exists" but
#    "who sets the bar".
#  - Kano model (Kano 1984): customer expectations come in tiers — must-be
#    (assumed; absence ruins the product), performance (the competitive axis),
#    attractive/delighters (which drift into must-bes over time). The baseline
#    to extract is the category's current must-be set.
#  - Theoretical sampling + saturation (grounded-theory lineage): each next
#    lookup is chosen by judgment on what was just learned, and collection
#    stops when new sources stop changing decisions. This is what makes scout
#    directional instead of deep-research fan-out.
# Kill switch: export SCOUT_OFF=1

. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)}/hooks/lib/gate-lib.sh" || { echo "directive.sh: cannot source gate-lib.sh" >&2; exit 2; }
gate_trap_fail_closed
set -uo pipefail
gate_kill_switch_active "${SCOUT_OFF:-}" || { trap - EXIT; exit 0; }

cat <<'EOF'
<scout-directive priority="high">
This is the protocol for your pre-proposal research (the proposal round of the role-handoff contract): before proposing anything, scout the field first. You cannot hit a quality bar you have never looked at. This directive steers direction BEFORE generation; it adds no checks after. Scout output is proposal-round material: it lands under docs/issue-<n>/reports/<role>/ and its brief feeds your proposal directly.

WHEN IT APPLIES: default to running. Scouting runs unless the task is a pure bugfix or the spec literally leaves no design decision open — those are the ONLY two skip conditions. "When in doubt, scout" is the rule, not a hint: any deliverable with a field to look at scouts it. Product-shaped work scouts the category's best-in-class products; non-product roles scout the best of their own deliverable's kind — a feasibility probe scouts prior art and how the best comparable systems solved it, a review plan scouts what strong audits of this change-class check, an ops plan scouts how comparable systems roll out and fail.

SKIP RECORD (mandatory when skipped): if either skip condition applies, the current-state survey MUST record the skip and its one-line reason (which condition, in one sentence). No skip record means scouting was not properly skipped — go back and either scout or write the record.

SURVEY-FIRST ORDER: the current-state survey (the contract's rigor
floor for the proposal round) runs BEFORE scout's sweep, never after and never in parallel with
it. The survey names the write surfaces and their unknowns; scout then
aims its sweep angles AT those gaps, instead of guessing angles from the
issue text alone. A scout pass that fires before the survey exists has
nothing to aim at and must wait.

THE PROTOCOL, two stages, budgeted (hard: sweep + deepening <= 5 stages total AND <= 3min wall-clock total — self-measure elapsed time via `date` at each judge point/stage boundary and cut deepening short when the budget is spent):

STAGE 1 — SWEEP (parallel fan-out, no judgment interleaved): derive the search angles from the current-state survey's gaps and unknowns first — which surfaces the survey found thin, unknown, or contested — then round those out with the issue text itself. Run several such angles concurrently in one turn — e.g. by-category, by-content, by-citation/links, by-time — as parallel subagents (Agent tool, one message with multiple calls) or parallel tool calls (e.g. multiple WebSearch calls in one message). This is the core requirement: the sweep must actually run its angles concurrently, not as a serialized loop dressed up as fan-out. If parallel dispatch is unavailable in the current session, fall back to batched-sequential in one session and SAY SO explicitly (which mode was used) — do not silently serialize. Cap: up to 4 angles, one round, breadth only — no exemplar judging yet.

STAGE 2+ — OBSERVE AND DEEPEN (judgment moves here, up to 4 further stages):
JUDGE POINT 1: look at the sweep's combined results together — overlap across angles signals where the field's real signal is; are these actually top-tier / same segment as this deliverable, judged against the surveyed current state (not just the issue's wording)? Swap out mismatches now.
Then run focused deepening only on decision-relevant hits (e.g. snowballing from promising sources: follow their references/citations, not fresh top-level searches) — one stage per deepening round, each stage batching its calls in one turn the same way the sweep did.
Extract per round: must-bes (Kano) — what do the strong hits therefore assume?; performance axes — 2-3 dimensions they visibly compete on; one pattern to adopt, one to deliberately skip; user expectations if reachable (reviews, complaints).
JUDGE POINT 2 (saturation rule, checked after every deepening stage): would another round change any build decision? If no, STOP — even if stages remain in the budget. If yes and stages remain, run one more deepening stage. Hitting the 5-stage cap or the 3min wall-clock budget also stops deepening regardless of saturation.

SCOUT BRIEF, then build immediately: if scouting ran, writing docs/issue-<n>/reports/<role>/scout-brief.md is MANDATORY — a scout pass that produces no file is treated as not having scouted, full stop, no matter how much searching happened. Size guide (soft): the brief should stay roughly within a page (~30 lines including the Sources list) — category must-bes, chosen performance axes, adopt/skip patterns, one line on segment fit, a GAP LINE (which of the field's must-bes the current state already meets, and which are missing — this is what makes adopt/skip decisions target the gap instead of the whole field), and which stage count / which mode (parallel or batched-sequential fallback) the pass actually used. The brief feeds the build direction and any worker contracts directly. It remains a steering input — findings and decisions, not narrative: no battlecards, no SWOT, no competitor matrix, not a research report.

SOURCE LINKS (mandatory): every claim in the brief that came from the web — exemplar names, must-bes, praised/complained patterns — carries its source. Add a `Sources:` list of the URLs actually consulted, counted within the ~30-line page guide. No source, no claim: an assertion with no traceable source is stated as an assumption (labeled as such), never as a finding.

RE-SCOUT TRIGGER (scouting is not a one-shot): the brief covers the direction decisions known at the start. Whenever a NEW product-facing decision surfaces mid-build that the brief does not cover — an added flow or screen, a changed scope, a sub-deliverable nobody anticipated — run ONE micro-round on exactly that decision (treat it as a one-stage deepening round: sweep or snowball on that decision alone, one judge point), extend the brief by a line or two, and continue building. The trigger is a new DECISION appearing, never a timer and never finished output: re-scouting re-aims what is about to be built; it does not re-examine what was built. A decision already made and built stays made unless the user reopens it.

NEVER:
- Post-build comparison against the exemplars — scout steers before generation; it is not a review pass.
- Cloning the exemplar: the reference sets the BAR, the user's intent sets the DIRECTION. Copy the expectation level, not the product.
- Exceeding 5 total stages, or blowing well past the 3min wall-clock budget without cutting deepening short — the budgets exist so scouting stays a steering input, not a deep-research fan-out. If the user wants an actual research report, that is a different task — say so.
- Serializing the sweep and calling it fan-out — stage 1 must be genuinely concurrent (parallel subagents or parallel tool calls in one turn) or the role must state plainly that it fell back to batched-sequential and why.
- Fabricating exemplars or expectations when search is unavailable: state that scouting was skipped and why, then build on stated assumptions.
- Scouting and then folding findings silently into the proposal with no scout-brief.md — the file is the evidence that scouting happened; without it the pass counts as skipped and needs its skip record instead.
- Asserting a must-be, exemplar, or pattern with no `Sources:` entry backing it — restate it as an assumption or drop it.

SCOPE: direction only. Composes with orchestration (freelunch): scouting runs in the main session — before decomposition, and again per re-scout trigger between build steps; the current scout brief travels to workers inside their task specs. Workers never scout mid-task. It never adds verification passes.
</scout-directive>
EOF
exit 0
