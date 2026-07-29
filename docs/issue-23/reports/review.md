# Review: two-stage sweep/observe-deepen scout protocol (issue #23)

code_under_review: `297965a38b0c029eb363c2c5b655918eefb3690f` (feat commit,
merged to `main` as `d90ace5b9ff81fc0ebbbbdd9b45145b70313ba18` via PR #24
`issue-23/coding` -> `main`)
spec: GitHub issue #23, "scout: two-stage protocol — parallel fan-out
sweep, then observe-and-deepen (max 5 stages, ~2min)" (closed)
loop_state: reported

Scope: fidelity-to-spec verdicts only, per requirement, against
`scout/hooks/directive.sh` and `scout/README.md` at the sha above. No
fixes proposed, no holistic code-quality opinion.

## What was done

Phase 2 of the review role's audit of issue #23: every requirement line
item extracted in `docs/issue-23/reports/review/survey.md` (carried
unchanged into `docs/issue-23/proposals/review.md`, both approved via the
"APPROVE issue-23/review" comment on PR #25) was checked against the
merged diff and assigned exactly one verdict from
{Present, Surface, Absent, Incorrect, Unverifiable}, each with a
file:line/hunk evidence pointer, per the `review:finding-record` skill's
format. Requirement 7b additionally incorporates the measured wall-clock
data from PR #25's review comment (four full passes, 20-82s, all under
the 2-minute soft budget) as evidence. No code was edited; no fixes
proposed.

## Upstream basis

- Code under review: `scout/hooks/directive.sh` and `scout/README.md` at
  commit `297965a38b0c029eb363c2c5b655918eefb3690f` (merged to `main` as
  `d90ace5b9ff81fc0ebbbbdd9b45145b70313ba18` via PR #24).
- Spec: GitHub issue #23 (closed), full text re-verified this session via
  `gh issue view 23` against the extraction already on record in
  `docs/issue-23/reports/review/survey.md`.
- Phase-1 records for this review consulted: `docs/issue-23/reports/review/survey.md`,
  `docs/issue-23/proposals/review.md` (both this role's own prior phase).
- Builder-side artifacts read (not re-derived, cited only): `docs/issue-23/reports/coding/survey.md`,
  `docs/issue-23/proposals/coding.md`.
- External measurement basis for requirement 7b: PR #25 review comment
  (fetched via `gh api repos/tokenmaxxxer/tokenmaxxxer-core/issues/25/comments`),
  body beginning "Reference data for req 7b (wall-clock): four full
  passes...".

---

requirement: 1 — Restructure the scout protocol into two stages, run
inside the existing role session (no new role created).
verdict: Present
evidence: `scout/hooks/directive.sh:33` ("THE PROTOCOL, two stages,
budgeted...") and `:35`/`:37` ("STAGE 1 — SWEEP" / "STAGE 2+ — OBSERVE AND
DEEPEN"); no new hook, role directory, or `hooks.json` entry appears in
`git diff 4b80112 297965a --stat` (only `scout/README.md` and
`scout/hooks/directive.sh` changed, plus a docs report file).
rationale: The heredoc injected at every role session's
`UserPromptSubmit` (the existing injection site, unchanged) now contains
two named stages instead of three sequential moves; no new role/hook file
was added anywhere in the diff.

---

requirement: 2 — Stage 1 (Sweep): several search angles run genuinely
concurrently (parallel subagents or parallel tool calls in one turn), not
a serialized loop dressed up as fan-out. No judgment interleaved in this
stage.
verdict: Present
evidence: `scout/hooks/directive.sh:35`, verbatim: "run several search
angles concurrently in one turn ... as parallel subagents (Agent tool,
one message with multiple calls) or parallel tool calls (e.g. multiple
WebSearch calls in one message) ... Cap: up to 4 angles, one round,
breadth only — no exemplar judging yet."
rationale: The text names the concurrency mechanism explicitly (one
message, multiple calls) rather than just asserting "parallel," matches
the issue's own phrasing test ("not a serialized loop dressed up as
fan-out" appears near-verbatim), and explicitly defers judgment
("no exemplar judging yet") to stage 2. This is a textual/directive
requirement (instructs a future session's behavior) and is checked as
such — whether a session actually obeys it each run is separately covered
by requirement 7a/7b's measurement evidence, not by this line.

---

requirement: 3 — Stage 2+ (Observe-and-deepen): judge the sweep's
combined results (overlap across angles signals where to dig); then run
focused deepening (e.g. snowballing) only on decision-relevant hits.
Saturation stays the stop rule.
verdict: Present
evidence: `scout/hooks/directive.sh:37-41` — "STAGE 2+ — OBSERVE AND
DEEPEN ... JUDGE POINT 1: look at the sweep's combined results together —
overlap across angles signals where the field's real signal is" (:38);
"run focused deepening only on decision-relevant hits (e.g. snowballing
from promising sources...)" (:39); "JUDGE POINT 2 (saturation rule...):
would another round change any build decision? If no, STOP" (:41).
rationale: All three sub-clauses (judge combined results incl. overlap
signal, focused/snowball deepening restricted to decision-relevant hits,
saturation as stop rule) are present near-verbatim from the issue text.

---

requirement: 4a — Hard budget, count-based: sweep + deepening <= 5 stages
total (sweep = stage 1, deepening <= 4 further stages).
verdict: Present
evidence: `scout/hooks/directive.sh:33` ("hard: sweep + deepening <= 5
stages total"); `:37` ("STAGE 2+ ... up to 4 further stages"); `:50`
("Exceeding 5 total stages ... " listed under NEVER).
rationale: The stage-count cap is stated three times (protocol header,
stage-2 label, NEVER list) and is mechanically checkable — matches the
proposal's own "how we'll know it worked" grep target
(`grep -n "STAGE 1 — SWEEP"`), independently re-run this session with the
same result (match found).

---

requirement: 4b — Hard budget: total search/fetch calls capped;
phase-1 proposes the number.
verdict: Incorrect
evidence: `docs/issue-23/proposals/coding.md:54` states the constraint
"Total search/fetch call cap: 12 (3-4 angles per stage x up to 3 stages
...)" as the phase-1-proposed number; but `grep -n "cap\|call"
scout/hooks/directive.sh scout/README.md` (re-run this session) finds
only the *stage*-count cap language (`scout/hooks/directive.sh:33,41,50`;
`scout/README.md:25,42`) — no occurrence of "12" or any other numeric
total-call limit in either shipped file. `scout/hooks/directive.sh:35`
caps only sweep-stage angles ("up to 4 angles"), not total calls across
all 5 stages.
rationale: verdict is Incorrect rather than Absent because phase-1 did
produce the required number (12, in the proposal) — the spec's full
clause is "capped; phase-1 proposes the number," and that half was
honored — but the shipped enforcement text never carries the cap
forward, so what got built (stage-count cap only) contradicts what the
spec required (both a stage cap and a total-call cap).
spec_vs_built: spec requires "total search/fetch calls capped (phase-1
proposes the number)" as a distinct hard-budget clause alongside the
5-stage cap; what was built enforces only the 5-stage cap — the
proposed numeric call cap (12) exists in
`docs/issue-23/proposals/coding.md:54` but was never transcribed into
`scout/hooks/directive.sh` or `scout/README.md`, so no session reading
the shipped directive is ever told a total-call number exists.

---

requirement: 5 — Soft budget, time-based: whole pass ~2 min wall-clock;
the role measures elapsed time (e.g. via `date`) and cuts deepening short
when the budget is spent.
verdict: Present
evidence: `scout/hooks/directive.sh:33` — "soft: ~2min wall-clock, cut
deepening short when spent — measure elapsed time, e.g. via `date`, at
stage boundaries"; `:41` — "Hitting the 5-stage cap or the ~2min soft
budget also stops deepening regardless of saturation."
rationale: Both the measurement instruction (`date`, at stage boundaries)
and the cut-short behavior on budget exhaustion are stated, matching the
issue's clause verbatim in mechanism and intent.

---

requirement: 6 — Preserve from the prior protocol: judgment gates (may
move to the observe point and deepening, not removed), finiteness (new
budgets replace, not stack on, the old two-judge-point cap),
steering-not-verification, existing skip conditions, and the <=10-line
brief.
verdict: Present
evidence: judgment gates — `scout/hooks/directive.sh:38,41` (JUDGE POINT
1 and 2, both retained, now positioned at stage 2+); finiteness — old cap
language ("at most two judge points, then build") no longer present
(confirmed by `grep -n "at most two judge points"
scout/hooks/directive.sh` returning no match this session) and is
textually replaced by the 5-stage/2min budget at `:33`, not stacked
alongside it; steering-not-verification — `:48-49` NEVER-list retains
"Post-build comparison against the exemplars ... it is not a review
pass" and "Cloning the exemplar ... Copy the expectation level, not the
product" verbatim from the pre-change text; skip conditions — `:31`
(WHEN IT APPLIES paragraph, unchanged in the diff — `git diff 4b80112
297965a -- scout/hooks/directive.sh` shows no hunk touching this line);
brief length — `:43` "compress into at most 10 lines."
rationale: Every named preservation target is independently traceable
either to an unchanged line (skip conditions) or a same-meaning
relocated line (judgment gates, finiteness), satisfying "preserve" as
distinct from "keep verbatim."

---

requirement: 7a — Phase-1 must measure (not assume) whether a headless
role session can actually run parallel subagents (Agent/Task tool) or
parallel WebSearch calls.
verdict: Present
evidence: `docs/issue-23/reports/coding/survey.md:23-54` ("Measurement 1:
parallel subagent dispatch..." and "Measurement 2: parallel WebSearch
calls...") — two Agent calls dispatched in one turn with sleep(8)
markers, timestamped start/end (`:29-31`); three WebSearch calls in one
turn, wall-clock ~12s (`:43-46`).
rationale: Both sub-obligations (subagent parallelism, WebSearch
parallelism) were actually executed with recorded timestamps/evidence,
not asserted from prior knowledge — satisfies "measure, not assume" on
its own terms regardless of the (positive) outcome.

---

requirement: 7b — Wall-clock of a full 5-stage pass; report whether the
2-minute target is realistic and set the query cap to fit. If parallelism
is unavailable, the sweep falls back to batched-sequential, and the
proposal must say which was measured.
verdict: Incorrect
evidence: `docs/issue-23/reports/coding/survey.md:56-74` ("Measurement 3:
full-pass wall-clock feasibility") states explicitly: "Not run as a
literal 5-stage pass ... but extrapolated from measurements 1-2" (`:58`)
and reasons to "around 50-75s wall-clock" (`:67`) by arithmetic, not
direct timing. Independent evidence from PR #25's review comment
(`gh api repos/tokenmaxxxer/tokenmaxxxer-core/issues/25/comments`,
comment body: "four full passes of the new scout protocol were measured
on 2026-07-29 in headless sessions with production spawn settings —
product 63s (4 searches), feasibility 32s (13 searches, 4 parallel
agents), review 82s (11 searches, 3 parallel agents), coding skip-case
20s (0 searches). All under the 2-minute soft budget.") shows that a real
full-pass measurement was both possible and, in fact, later obtained (all
4 real passes land at 20-82s, under the target) — meaning the spec's
literal ask ("wall-clock of a full 5-stage pass") was answerable directly
and was not answered directly in the phase-1 artifact that fed this
build.
rationale: verdict is Incorrect, not Absent, because phase-1 did measure
something (parallel dispatch timing) and did report a number and a
target-realism conclusion — but the spec's literal subject is "a full
5-stage pass," and survey.md itself concedes (`:71-74`) it substituted
extrapolation for that measurement. The later PR #25 comment's real
4-pass data (20-82s, all under budget) confirms the target was in fact
achievable and measurable at the time of PR #25's review — underscoring
that the extrapolation-instead-of-measurement was an avoidable gap, not
an infeasible ask.
spec_vs_built: spec requires "wall-clock of a full 5-stage pass" reported
directly; what was built/reported (survey.md Measurement 3) is an
arithmetic extrapolation from two shorter, differently-shaped
measurements (2 agents x 8s sleep; 3 WebSearches), explicitly flagged by
its own author as not a literal 5-stage timing. Real full-pass data
existed by the time of PR #25 (4 measured passes, 20-82s) but was not
part of the phase-1 deliverable this verdict is scoped to.

---

requirement: 7b (fallback statement clause) — "If parallelism is
unavailable, the sweep falls back to batched-sequential, and the
proposal must say which was measured."
verdict: Present
evidence: `docs/issue-23/proposals/coding.md:59-63` states: "The soft time
budget is advisory... a slow environment (parallelism unavailable) does
not make the role fail phase 1 — it falls back to batched-sequential and
says so, per the issue's explicit requirement to report which was
measured"; and `scout/hooks/directive.sh:35` carries the same fallback
instruction forward into the shipped directive ("If parallel dispatch is
unavailable in the current session, fall back to batched-sequential in
one session and SAY SO explicitly").
rationale: This sub-clause is separable from the wall-clock-measurement
sub-clause above (see survey.md's own split of 7b into "which was
measured" framing) and is satisfied independently — the fallback
statement requirement is met at both the proposal and shipped-directive
level, even though the full-pass-timing sub-clause above is Incorrect.

---

## Summary

| req | verdict |
|---|---|
| 1 | Present |
| 2 | Present |
| 3 | Present |
| 4a | Present |
| 4b | Incorrect |
| 5 | Present |
| 6 | Present |
| 7a | Present |
| 7b (wall-clock) | Incorrect |
| 7b (fallback statement) | Present |

9 of 10 line items Present; 2 Incorrect (4b: proposed 12-call total cap
never transcribed into shipped enforcement text; 7b: phase-1 extrapolated
a full 5-stage wall-clock instead of measuring it directly, though later
real data in PR #25's review comment shows the target was in fact
achievable and directly measurable at the time).
