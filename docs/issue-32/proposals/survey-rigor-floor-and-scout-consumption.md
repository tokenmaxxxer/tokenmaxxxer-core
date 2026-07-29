---
subject: issue-32
role: coding
loop_state: scope-proposed
---

# Proposal: survey rigor floor + scout consumes the survey

## Request (paraphrased intent)

Two coupled phase-1 gaps found while validating the two-stage scout: (1)
contract v3 s19's current-state survey has no depth requirement, so
survey quality depends on whichever rulebook happens to bring its own
discipline; (2) scout's directive never reads the survey, so its sweep
angles are aimed only at the issue text and never contrasted with what
the survey found already exists. Add a minimal rigor floor to the
contract (evidence pointers, full write-surface coverage, unknowns
listed) following the issue-14 amendment precedent, and make scout
consume the survey (survey-first order, gap-derived sweep angles, a gap
line in the brief, exemplar fit judged against the surveyed state).

## Constraints

- Contract diff stays minimal, additive to s19's existing phase-1
  bullet — no rewording of what already works, per the issue-14
  precedent style (explicit new sentence/paragraph naming what changed).
- scout's two files (`directive.sh`, `README.md`) must stay in sync with
  each other, as they already are today.
- `parse-check.sh` must still pass (shell-file syntax only — README.md
  is not a shell file, so only `directive.sh` is checked, but it must
  keep parsing under bash 3.2).
- No new skip condition, no change to the two existing skip conditions
  or the 5-stage/3min budget — this only reorders and re-aims the
  existing protocol, per the issue's exact scope.

## What will be done (exact wording, phase 2 only — not applied yet)

**File 1: `core/contract/role-handoff-contract.md`**, s19, immediately
after the existing phase-1 bullet (after "...The role opens the PR at
this point and stops."), insert a new bullet:

> - **Current-state survey rigor floor.** The survey's quality depended
>   entirely on which rulebook happened to bring its own discipline, absent
>   any floor here — this closes that gap with a minimum, not a template:
>   every factual claim in the survey carries a pointer to its evidence
>   (a file path/line, a board record, a PR/issue number — something the
>   next reader can open and check); the survey MUST cover the current
>   state of every surface the proposal intends to write to, not a subset
>   chosen for convenience; and unknowns are listed as unknowns, stated
>   plainly, never silently omitted because no evidence was found for them.

**File 2: `scout/hooks/directive.sh`**, three edits to the heredoc body:

1. Insert a new paragraph immediately before "THE PROTOCOL, two stages...":

> SURVEY-FIRST ORDER: the current-state survey (contract v3 s19's rigor
> floor) runs BEFORE scout's sweep, never after and never in parallel with
> it. The survey names the write surfaces and their unknowns; scout then
> aims its sweep angles AT those gaps, instead of guessing angles from the
> issue text alone. A scout pass that fires before the survey exists has
> nothing to aim at and must wait.

2. Replace the STAGE 1 paragraph's opening clause — current: "run several
   search angles concurrently in one turn" — with: "derive the search
   angles from the current-state survey's gaps and unknowns first — which
   surfaces the survey found thin, unknown, or contested — then round
   those out with the issue text itself. Run several such angles
   concurrently in one turn".

3. JUDGE POINT 1: append ", judged against the surveyed current state
   (not just the issue's wording)" after "are these actually top-tier /
   same segment as this deliverable".

4. SCOUT BRIEF paragraph: insert ", a GAP LINE (which of the field's
   must-bes the current state already meets, and which are missing —
   this is what makes adopt/skip decisions target the gap instead of the
   whole field)," after "one line on segment fit judged against the
   surveyed current state" (segment-fit phrase itself amended per item 3
   above) and before "and which stage count / which mode...".

**File 3: `scout/README.md`**, mirroring the same three changes in prose
form under "## The protocol": a lead-in sentence on survey-first order,
the sweep bullet's angle-derivation clause, the deepen bullet's
judge-against-current-state clause, and the scout-brief bullet's gap
line — kept textually parallel to `directive.sh` since the two already
restate each other today (confirmed in the survey).

## Out of scope

- No change to the 5-stage/3min budget, the two skip conditions, or the
  re-scout trigger — issue #32 asks only for ordering and aim, not new
  limits.
- No new file under `docs/issue-<n>/reports/<role>/` beyond what already
  exists (`scout-brief.md`) — the gap line is a line inside that existing
  file, not a new artifact.
- No change to `scout/hooks/tests/parse-check.sh` — it is read-only
  context for this issue, not a write surface.
- No retroactive fix to issue-14's coding record missing an explicit
  skip line (flagged as an unknown in the survey) — out of this issue's
  scope, belongs to whichever subject touches issue-14 again.

## How success will be judged

- s19 gains exactly one new bullet, additive, naming the three rigor-floor
  requirements (evidence pointers, full write-surface coverage, unknowns
  listed) without altering the existing phase-1 bullet's text.
- `scout/hooks/directive.sh` and `scout/README.md` both state, in the same
  order: survey-first ordering, gap-derived sweep angles, judge-point-1
  fit against the surveyed state, and a gap line in the brief — checked
  by diffing the two files' protocol sections for continued parallelism.
- `bash scout/hooks/tests/parse-check.sh` exits 0.
