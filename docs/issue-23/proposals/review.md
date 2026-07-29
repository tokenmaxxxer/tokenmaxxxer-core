# Proposal: review of issue #23's two-stage scout protocol (review role)

## Scope

Audit whether the merged change (PR #24, `code_under_review:
d90ace5b9ff81fc0ebbbbdd9b45145b70313ba18`) to `scout/hooks/directive.sh`
and `scout/README.md` satisfies every requirement stated in issue #23,
verbatim. Per-requirement verdict only (Present / Surface / Absent /
Incorrect / Unverifiable) — no holistic code-quality judgment, no fix, no
patch.

## Spec audited against

GitHub issue #23 (closed, "scout: two-stage protocol — parallel fan-out
sweep, then observe-and-deepen (max 5 stages, ~2min)"), full text
extracted in `docs/issue-23/reports/review/survey.md` into 7 top-level
requirement line items (2 with sub-parts). No sampling: full audit of a
~25-line issue body and a ~25-line diff — under the 100-300 line/session
pacing guidance, so exhaustive coverage, not sampling; no derivation
needed since nothing is skipped.

## Requirement list (carried from survey.md)

1. Two-stage restructure, no new role.
2. Stage 1 sweep: genuinely concurrent, no judgment interleaved.
3. Stage 2+ observe-and-deepen: judge combined results, focused
   deepening/snowballing, saturation stop rule.
4. Hard budget: (a) <=5 stages total, count-based; (b) total
   search/fetch calls capped, number set by phase-1.
5. Soft budget: ~2min wall-clock, measured via `date`, cuts deepening
   short.
6. Preservation of: judgment gates, finiteness, steering-not-verification,
   skip conditions, <=10-line brief.
7. Phase-1 measurement obligation: (a) parallel dispatch capability
   measured; (b) full 5-stage wall-clock measured, 2-min target assessed,
   query cap set to fit, fallback stated if parallelism unavailable.

## closed_checks: cite vs re-derive

No prior review record exists for this subject — nothing available to
cite. `scout/hooks/tests/parse-check.sh` was re-derived this session
(re-run, not cited) against `code_under_review` sha `d90ace5`, since no
prior closed_check entry exists at that sha to cite.

## What phase 2 will do

Write `docs/issue-23/reports/review.md` as the first act of phase 2 (per
role directive), one verdict per requirement above, each with a
file:line/hunk pointer or an explicit access-gap statement for
Unverifiable, no fixes proposed. The candidate finding flagged in
survey.md (requirement 7b: full 5-stage wall-clock not actually measured,
only extrapolated) gets its verdict and, if it clears the bar, a severity
via the severity-classification skill — not written now, since phase 2 is
gated on human Approve per contract v3 s19.

## Out of scope

- Any edit to `scout/hooks/directive.sh`, `scout/README.md`, or other
  roles' files.
- Holistic quality opinions on the protocol design (readability, prose
  style) beyond what a requirement literally demands.
- Re-litigating requirements not stated in issue #23 (e.g. no requirement
  audits performance/latency beyond the 2-min soft budget's own text).
