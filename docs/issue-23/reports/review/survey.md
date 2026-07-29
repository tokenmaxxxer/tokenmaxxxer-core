# Survey: review of issue #23's two-stage scout protocol (review role)

code_under_review: `d90ace5b9ff81fc0ebbbbdd9b45145b70313ba18` (main HEAD,
merge of PR #24 `issue-23/coding` -> `main`)

Scouting skipped: this is a fidelity audit against a spec (issue #23) and
a fully-specified diff, not product-shaped work with a field of exemplars
to scout — falls under directive.sh's own skip condition ("the spec
already encodes the bar").

## Spec extracted from issue #23 (verbatim source, closed 2026-07-29)

Requirement line items, numbered for the review record:

1. Restructure the scout protocol into **two stages**, run inside the
   existing role session (**no new role** created).
2. **Stage 1 (Sweep)**: several search angles run genuinely
   **concurrently** (parallel subagents or parallel tool calls in one
   turn), not a serialized loop dressed up as fan-out. No judgment
   interleaved in this stage.
3. **Stage 2+ (Observe-and-deepen)**: judge the sweep's combined results
   (overlap across angles signals where to dig); then run **focused
   deepening** (e.g. snowballing) only on decision-relevant hits.
   Saturation stays the stop rule.
4. **Hard budget, count-based**: sweep + deepening <= 5 stages total
   (sweep = stage 1, deepening <= 4 further stages). **Total
   search/fetch calls capped; phase-1 proposes the number.**
5. **Soft budget, time-based**: whole pass ~2 min wall-clock; the role
   measures elapsed time (e.g. via `date`) and cuts deepening short when
   the budget is spent.
6. **Preserve** from the prior protocol: judgment gates (may move to the
   observe point and deepening, not removed), finiteness (the new
   budgets replace, not stack on, the old two-judge-point cap),
   steering-not-verification, the existing skip conditions, and the
   **<=10-line brief** that feeds the proposal.
7. **Phase-1 must measure, not assume**:
   a. Whether a headless role session can actually run parallel
      subagents (Agent/Task tool) or parallel WebSearch calls.
   b. **Wall-clock of a full 5-stage pass**; report whether the 2-minute
      target is realistic and **set the query cap to fit**. If
      parallelism is unavailable, the sweep falls back to
      batched-sequential, and the proposal must say which was measured.

This is a complete extraction of every distinct obligation stated in the
issue body — 7 top-level items, 2 with sub-parts (4 has two clauses, 7 has
2a/2b).

## Artifact under review

Two files changed by PR #24 (`git diff main~2 main -- scout/hooks/directive.sh scout/README.md`):
- `scout/hooks/directive.sh` — the injected `<scout-directive>` heredoc
  (enforcement site).
- `scout/README.md` — human-readable restatement (documentation site).

Also present on `main` from the same PR (phase-1 deliverables of the
*coding* role, not re-derived here, cited by sha):
- `docs/issue-23/reports/coding/survey.md` — coding role's own
  measurements for requirement 7a/7b.
- `docs/issue-23/proposals/coding.md` — coding role's proposal, including
  a stated "Total search/fetch call cap: 12" constraint.

## closed_checks disposition

No prior `docs/issue-23/reports/review.md` exists (first review pass for
this subject) — nothing to cite-and-skip. `scout/hooks/tests/parse-check.sh`
re-run this session against `code_under_review` sha `d90ace5`: passes
(`ok directive.sh`, `ok tests/parse-check.sh`) — re-derived, not cited,
since no prior closed_check record exists for this sha.

## Verification plan (phase 2, per requirement)

- 1, 2, 3, 5, 6: text-comparable against `scout/hooks/directive.sh` /
  `scout/README.md` at `code_under_review` — direct read, cite file:line.
- 4: split into two independently checkable clauses — stage-count cap
  (grep for "5 stage" / "<= 5") and call-count cap (grep for any numeric
  search/fetch call limit in the shipped text). Preliminary grep this
  session (`grep -n "cap\|call" scout/hooks/directive.sh scout/README.md`)
  found the stage cap present but no numeric call-count cap anywhere in
  either shipped file — flagged for a per-clause verdict rather than one
  merged verdict, since a single Present/Absent call would hide that one
  clause landed and the other didn't.
- 7a: check `docs/issue-23/reports/coding/survey.md` measurements 1-2
  (dated 2026-07-29, this same repo/environment) — Present if the
  measurement was actually run and reported, regardless of outcome.
- 7b: check `docs/issue-23/reports/coding/survey.md` measurement 3 against
  the spec's literal ask ("wall-clock of **a full 5-stage pass**") —
  preliminary read shows the survey explicitly states it did *not* run a
  literal 5-stage pass and extrapolated from smaller measurements instead;
  this is a candidate finding, verdict deferred to phase 2 per contract
  (no findings written before Approve).
