---
subject: issue-32
role: coding
loop_state: scope-proposed
---

# Survey: how briefs/surveys interact today (issue #32)

## Scout skip

Skip condition: neither applies — this is contract/directive wording work
with real design choices open (exact phrasing, ordering, where the gap
line lives), not a pure bugfix and not a spec with zero open decisions.
Scouting was NOT skipped; see the scout-brief companion note below —
scout is this issue's own subject, so scouting the field of "how do
rulebook amendments in this project reason about precedent" collapses
to the same in-repo precedent search this survey already had to do
(issue-14's amendment), so no separate web/agent sweep was run. This
is stated as the scouting record for this subject: field = this
repo's own prior contract-amendment precedent, method = grep + read,
no external field exists for "this project's own contract text".

## Surface 1: `core/contract/role-handoff-contract.md` s19, phase-1 bullet

Current text (`core/contract/role-handoff-contract.md:642-649`, read at
sha `db5fda2` — this branch's base):

> - **Phase 1 — propose.** The role's FIRST commits on `issue-<n>/<role>`
>   are, before any execution work: its research (what is known about the
>   problem), its current-state survey (what exists today and how this issue
>   meets it), and its proposal (what this role intends to do, the intended
>   write surface, what is out of scope, and how success will be judged).
>   Research and survey live under `docs/issue-<n>/reports/<role>/`; the
>   proposal under `docs/issue-<n>/proposals/`. The role opens the PR at
>   this point and stops.

This is the ONLY place in the contract that defines what the survey must
contain — "what exists today and how this issue meets it" — with no depth
criteria. Grepped `core/contract/role-handoff-contract.md` for `survey`:
it appears at line 645 (this bullet) and nowhere else in the 820-line
file. No other section imposes evidence-pointer, coverage, or
unknowns-listed requirements on any role's survey. This confirms issue
#32's claim #1: the rigor floor is currently absent, not merely thin.

## Surface 2: `scout/hooks/directive.sh` and `scout/README.md`

Grepped both files for `survey`: `directive.sh` mentions it exactly once,
in the opening sentence ("Scout output is phase-1 material... it lands
under `docs/issue-<n>/reports/<role>/`" — same directory the survey also
lives in, but the directive never reads or references the survey's
content). `README.md` mentions `survey` twice: once in the "skip" section
("the phase-1 survey must record the skip") and once in the intro
paragraph pointing to where the brief lands. Neither file's protocol body
(directive.sh lines 35-45, README.md lines 31-64) ever tells scout to
open, read, or derive anything from the survey — sweep angles are framed
purely against "the field" / "the issue's wording" (directive.sh line 55
NEVER list: "the issue's wording"), and judge point 1 checks fit against
"this deliverable," not against any surveyed current state. This confirms
issue #32's claim #2: survey and scout currently run in the same
directory but have no data dependency on each other — a scout pass today
could run before the survey file exists at all, since nothing gates or
orders it.

## Existing docs/issue-*/reports/*/ pairs in this repo (how they interact today, in practice)

Searched `docs/issue-*/reports/*/` for existing survey + scout-brief pairs
to see whether any role has already improvised an interaction between
them:

- `docs/issue-14/reports/coding/survey.md` — a full current-state survey
  (grep for the prior "never an approval" wording, precedent search). No
  `scout-brief.md` alongside it in that directory (issue #14 is a
  contract-text amendment with a closed decision space, matching scout's
  own bugfix-shaped skip condition — though issue #14's coding record
  does not carry an explicit skip line; this is an unknown, not verified
  further, since issue #14 is not this issue's subject to fix).
- `docs/issue-18/`, `docs/issue-21/`, `docs/issue-23/` — present under
  `docs/` (per `ls docs/` above) but not opened in this survey; out of
  this issue's write surface and not needed to establish the two gaps
  above, which are fully demonstrated by the absent-requirement grep on
  the contract and the absent-reference grep on scout's two files.

**Unknown, stated plainly:** whether any role OTHER than coding has ever
produced both a survey and a scout-brief in the same subject directory
with actual cross-referencing (as opposed to just co-location) was not
checked beyond the issue-14 case above — no evidence found either way for
other subjects, so this is left as an unknown rather than assumed absent.

## Write surface this proposal will touch

Per section 19's rigor floor being added by this very issue, every
surface the proposal intends to write to must be surveyed above:

1. `core/contract/role-handoff-contract.md` — s19 phase-1 bullet,
   surveyed above (current text quoted in full).
2. `scout/hooks/directive.sh` — protocol body, surveyed above (grep
   results for `survey` and the NEVER list's issue-text-only framing).
3. `scout/README.md` — "The protocol" section, surveyed above (grep
   results, same absence).

No other surface is touched; `scout/hooks/tests/parse-check.sh` is read
(to know what it checks) but not written to.
