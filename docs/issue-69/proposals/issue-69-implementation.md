---
subject: issue-69
role: implementation
loop_state: scope-proposed
---

# Proposal — pin stub-check to core, ban rulebook copies, reclaim 21 duplicates

Phase 1 proposal only. Nothing below is applied in this phase; it describes
what phase 2 would build/change, pending `APPROVE issue-69/implementation`.
See `docs/issue-69/reports/implementation/survey.md` for the current-state
findings this responds to.

## (a) Pin stub-check to run from core, not a vendored copy

**Proposed mechanism**: replace the "copy `stub-check.sh` into every
rulebook" instruction (issue-66 report, transition step 2) with a
core-referenced invocation, the same shape `core/hooks/hooks.json` already
uses for the four promoted gates (`${CLAUDE_PLUGIN_ROOT}/hooks/<name>.sh`).
Concretely:

1. Each rulebook's own test harness (its `run-all.sh` equivalent) calls
   `stub-check.sh` by a path resolved against the **core plugin's own
   install root**, not a path inside the rulebook: e.g.
   `"${CORE_PLUGIN_ROOT:-$CLAUDE_PLUGIN_ROOT/../core}/hooks/tests/stub-check.sh" "$(dirname "$0")/.."`
   — the first argument stays a rulebook-relative directory (what to scan),
   the script binary itself is never copied. The exact root-resolution
   expression needs a phase-2 spike against how `${CLAUDE_PLUGIN_ROOT}`
   actually resolves for a sibling plugin at install time (this repo's own
   test run happens from a single checkout where core and the rulebook are
   siblings, e.g. `core/` and `warrant/` here — the marketplace-install case
   for the 43 external repos may resolve differently and needs verifying
   before the wording is finalized).
2. `docs/handbooks/role-gates-tests.md` gets a documented canon invocation
   line for rulebook authors, replacing "drop this file into every
   rulebook" language wherever it appears (issue-66's own report text is a
   record, left as historical; the actionable instruction lives in the
   handbook and the maturation directive template per item (d) below).
3. `stub-check.sh`'s own header comment (lines 22-25 currently) gets
   rewritten to drop the "every rulebook copies this file verbatim" framing
   and state the core-referenced-invocation model instead.

**Why this resolves the item**: the detector script has exactly one
physical copy (`core/hooks/tests/stub-check.sh`), matching the four gates it
already protects. There is nothing left to drift.

## (b) Ban future rulebook copies of canon scripts

**Proposed mechanism**, two parts:

1. **Extend `stub-check.sh`'s own `CANON_GATES` list to include itself.**
   Today: `CANON_GATES="trailer-gate.sh record-fields-gate.sh
   handbook-trigger-gate.sh parse-check.sh"`. Proposed:
   `CANON_GATES="trailer-gate.sh record-fields-gate.sh
   handbook-trigger-gate.sh parse-check.sh stub-check.sh"`. Once (a) lands
   and no rulebook vendors `stub-check.sh` anymore, this makes the detector
   catch its own recurrence — a rulebook that copies `stub-check.sh` back in
   fails its own test run. This is the direct fix for issue #69's item 2.
2. **A general rule, not just a hardcoded list.** The hardcoded
   `CANON_GATES` string requires a person to remember to add a new filename
   every time a script gets promoted to `core/hooks/`. Proposed:
   `stub-check.sh` derives its check list from `core/hooks/hooks.json` (the
   promoted gates) plus a fixed set of promoted test-harness scripts
   (`parse-check.sh`, `stub-check.sh` itself) declared once in a small
   manifest (e.g. `core/hooks/tests/canon-manifest.txt`, one filename per
   line) rather than inline in the script body — so a future promotion (like
   issue-66's four gates, or issue-63's warrant-hunt promotion) adds one
   line to a manifest instead of editing detection logic. This turns
   "did we remember to update stub-check.sh" into "did we remember to
   update the manifest," a smaller and more auditable surface, and is what
   makes the ban durable rather than a one-time patch.

## (c) Reclaim plan for the 21 existing copies

Per the survey, the 21 copies live in the 43 external rulebook repos, which
this repo's role has no write access to (confirmed precedent: issue-66's
own report explicitly declines to execute the per-rulebook rollout for the
same reason). The reclaim plan is therefore a **documented rollout
procedure**, to be executed per-rulebook-repo by whoever has write access
there (the same "batch into the same wave as issue-63's warrant-hunt
rollout" sequencing issue-66's report already calls for):

1. **Enumerate**: for each of the 43 rulebook repos, run
   `find . -maxdepth 3 -name stub-check.sh -type f` (or the equivalent one
   already used by `stub-check.sh` itself) against that repo's own
   checkout. This repo cannot produce the list; the check can be handed to
   whoever holds those checkouts as a one-line command, and the 21-count
   from issue #69's background is the expected total across all 43.
2. **Delete-and-reference**: in each rulebook repo found to have a copy,
   delete the vendored `stub-check.sh` and update that rulebook's own test
   harness entry point to the core-referenced invocation from (a) instead
   of a local file reference.
3. **Verify per-repo**: after deletion, re-run that rulebook's own harness;
   passing means the core-referenced call resolves and runs correctly with
   the vendored file gone. This is the same verification shape issue-66's
   report used for its own four-gate promotion ("52+36+19+16 gate assertions
   ... all passing").
4. **Batch sequencing, unchanged from issue-66's plan**: this rollout stays
   batched with issue-63's warrant-hunt stub rollout and issue-66's own
   per-rulebook follow-up (deleting the four gate files/`directive.sh`
   shrink) — one coordinated per-rulebook change, not three separate
   touches to the same 43 repos. issue-69's own explicit ordering constraint
   ("43룰북 성숙화 phase 2 시작 전에 완료") means this reclaim is a
   precondition for every rulebook's maturation phase 2, same as issue-66's
   sequencing note already states for its own four files.
5. **No deletion happens in this phase.** This proposal documents the
   procedure; execution requires phase-2 approval and, in practice, access
   to the 43 external repos that this implementation role does not have
   from within `tokenmaxxxer-core` alone — flagged here as an open
   coordination question for the approver (see below), not silently assumed
   solvable.

## (d) Recurrence-prevention clause for future transition/maturation directives

**Proposed mechanism**: add a standing clause to whatever handbook or
directive template governs rulebook transition/maturation write-ups
(`docs/handbooks/role-gates-tests.md` is the closest existing home; if a
more general "maturation directive template" doc exists or gets created,
the clause belongs there too). Proposed wording:

> **Canon scripts are referenced, never copied.** Any script that lives
> under `core/hooks/` or `core/hooks/tests/` is invoked by a rulebook
> through a path resolved against the core plugin's own install root. A
> rulebook's own tree never contains a second copy of a core canon file.
> If a script needs to run inside a rulebook's own directory for a genuine
> technical reason (e.g. `parse-check.sh` must parse files that only exist
> in that rulebook — see survey item (c) for why that one script is a
> deliberate, narrow exception), the transition directive making that call
> states the reason explicitly rather than defaulting to "copy it, like the
> last one."

This directly generalizes the one existing precedent
(`warrant`'s marketplace description: "role rulebooks reference it rather
than vendoring a copy") from one plugin's prose into a clause any future
transition/maturation directive is expected to carry, and gives (b)'s
manifest-driven `stub-check.sh` something to enforce it against
mechanically rather than relying on the clause being read and remembered.

## Open question for the approver

This repo's implementation role has no demonstrated write access to the 43
external rulebook repos (confirmed by issue-66's own precedent of declining
to execute its per-rulebook follow-up for the same reason). Item (c)'s
reclaim plan is written as a procedure to hand off, not work this repo can
execute end-to-end. If the approver has a mechanism for cross-repo rollout
(a bot, a scripted PR-per-repo tool, direct access) that this survey missed,
phase 2 should say so up front — otherwise phase 2's own deliverable for
item (c) is necessarily the documented procedure plus the manifest/detection
change in (a)/(b), not 21 closed PRs.

## What this proposal does not do

- Does not delete any of the 21 existing copies (phase 1 is proposal-only,
  and this repo cannot reach the 43 external repos regardless).
- Does not change `core/hooks/hooks.json` or `stub-check.sh`'s executable
  behavior (phase 2, pending approval).
- Does not invent a universal answer for the `${CLAUDE_PLUGIN_ROOT}`
  sibling-resolution question in (a) point 1 — flagged as needing a phase-2
  spike rather than guessed at here.
