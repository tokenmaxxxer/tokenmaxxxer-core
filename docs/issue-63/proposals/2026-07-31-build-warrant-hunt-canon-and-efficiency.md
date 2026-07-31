---
subject: issue-63
role: implementation
loop_state: scope-proposed
---

# Proposal: warrant-hunt canon promotion + proportional efficiency protocol

## Request (paraphrased intent)

Hunt runs in full on every delivery and eats disproportionate session
time; its definition lives in a separate `warrant` plugin, vendored
(copy-pasted, not referenced) into 43 rulebooks with no single source of
truth — the survey confirms 35 distinct content hashes among the ~43
vendored copies today. The issue asks for four things: (1) promote
warrant-hunter + hunt cadence to a single canonical source with a
reference path for rulebooks, (2) measure hunt's actual time/token share
by delivery size before changing anything, (3) propose a scout-style
proportional/bounded hunt protocol, (4) enumerate what hunt has actually
caught and check the new protocol still catches each class.

## Constraints

- This is phase-1 only — no code or hook changes ship in this PR; see
  `docs/issue-63/reports/implementation/survey.md` for what was found and
  `scout-brief.md` for the comparable-system pass.
- `warrant` is not owned by this repo's checkout — it is a separate
  plugin (`~/.claude/plugins/cache/tokenmaxxxer/warrant/`). This proposal
  cannot itself move that plugin's source; it proposes where the
  canonical hunt-cadence text should live *relative to this repo* and
  what change request follows for `warrant`'s own repo.
- No time-series measurement data exists in this checkout (survey,
  "Measured hunt cost"). This proposal does not fabricate a number; it
  proposes the instrumentation needed and states clearly that the
  efficiency budget below is a structural transplant from scout, pending
  real measurement, not a fitted constant.
- Detection-power parity with today's hunt is a hard requirement per the
  issue's own item 4 — the side-effect table below must show each
  confirmed catch class still reachable under the new protocol before
  this is approved.

## What will be done (phase 2 only — not applied yet)

### 1. Canon promotion

Add `warrant/` as a fifth plugin directory in this repo's
`.claude-plugin/marketplace.json`, mirroring `scout/`'s existing
structure: `warrant/README.md`, `warrant/hooks/{directive.sh,hunt-guard.sh,
hunt-state.sh,state.sh}`, `warrant/agents/warrant-hunter.md`. Content
starts as the current 0.4.1 source (byte-identical import), not a
rewrite, so this step is pure relocation plus the cadence changes in
section 2. `warrant-hunter.md` and the hook set become the single
original; the existing standalone `warrant` plugin repo is asked (via a
linked issue there, out of this repo's authority) to either re-point its
own marketplace entry at this copy or be deprecated in favor of it.
Each of the 43 rulebooks' `agents/warrant-hunter.md` is replaced by a
one-line reference stub (the same pattern `core`, `scout`, `terse`,
`freelunch` already use: declared as a marketplace dependency, not a
vendored file) — enumerated as a follow-up tracked per-rulebook, since
this repo cannot write into rulebook repos itself.

### 2. Proportional, bounded hunt protocol (added to `directive.sh`)

Scout's shape does not transplant literally (scout-brief.md's "skip"
line) because hunt has two fixed dispatch points, not an open-ended
search. Instead:

- **Per-dispatch wall-clock cap**: each of the two dispatches (after-
  proposal, before-landing) gets a self-measured cap via `date`, tiered
  by delivery size: diff <= 20 lines or docs-only -> 60s / one stance;
  diff 21-200 lines -> 120s / one stance (today's default); diff > 200
  lines or touches >5 files -> 180s / may split into two stances run
  sequentially, still one dispatch. Size is read from `git diff --stat`
  against the proposal's frozen write set, the same source `scope-gate.sh`
  already reads.
- **docs-only fast path**: a delivery whose diff touches only `docs/`
  (no `src/`, `core/hooks/`, or other executable surface) runs the
  after-proposal dispatch only, skipping before-landing, with a mandatory
  skip line in the hunt record naming the reason ("docs-only, no
  before-landing dispatch") — mirroring scout's mandatory skip record.
- **Adaptive cadence on repeated misses**: if the last 3 consecutive
  hunt dispatches *for this role's session* returned no finding, the
  next dispatch's cap drops one tier (120s -> 60s, 180s -> 120s) rather
  than being skipped outright — detection power is never removed
  entirely by a streak, only its budget is trimmed, since the issue's
  item 4 forbids silently losing a catch class. Tier drops reset to the
  session default the moment a finding lands.
- **Mandatory hunt record on every dispatch, including empty ones**
  (already warrant's stated design in README.md — this proposal keeps it
  and makes the cap/tier explicit inside the record's frontmatter:
  `cap_seconds`, `tier`, `diff_stat_lines`) so future measurement (below)
  has real data instead of needing a new instrumentation pass later.

### 3. Measurement (instrumentation this proposal adds, not a number it invents)

`hunt-state.sh`'s lock file already records a start time; extend the
persisted hunt record (section 2's frontmatter addition) with
`started_at`/`ended_at` and `diff_stat_lines`/`files_touched`. This is
the minimum needed to later run `git log --grep "Proposal:"` joined
against hunt records and produce the delivery-size-bucketed time/token
table the issue asks for in item 2 — that aggregation itself is a
follow-up once enough real records accumulate post-merge; this PR cannot
retroactively produce it from data that was never recorded.

### 4. Side-effect check (issue item 4)

| Confirmed catch (survey) | Stance kind | Still reachable under new protocol? |
|---|---|---|
| Proposal-prose-vs-mechanism design-error (`issue-comment-approval-scope`) | after-proposal | Yes — after-proposal dispatch is never skipped (only docs-only skips before-landing), full stance budget retained at default tier since this was a first dispatch, not a repeated-miss streak. |
| `isMinimized` field silent-failure (`approval-gate.sh`) | before-landing, code-diff stance | Yes — code diff > docs-only, so before-landing still fires; diff size here (single hook file) sits in the 21-200 line default tier, same budget as today. |
| Repo-wide stale-vocabulary residue (`README.md` "wakes") | before-landing, grep-reach-beyond-diff | Yes — the grep-follows-the-pattern-across-the-repo behavior is unchanged by this proposal; only wall-clock/tier changes, not the hunter's reach or anti-anchoring rules. |
| "watch 오탐 근본원인" (unconfirmed in-repo, per survey) | unknown | Cannot verify — no record found in this checkout. Flagged to the user rather than assumed caught or missed. |

No confirmed catch class is skipped or capped below its original budget
by this protocol; the only new skip is before-landing on genuinely
docs-only deliveries, which by definition cannot produce a code-level
silent-failure or design-error finding the way the three confirmed catches
did.

## Open question for the human approver

The unconfirmed fourth defect class ("watch 오탐 근본원인") — is there a
session/PR to point at (issue-20 / issue-60?) so the side-effect table
can be completed with a fourth confirmed row before phase 2, or should
phase 2 proceed with it flagged unconfirmed as above?

## How success will be judged

- `warrant/` exists in this repo with byte-identical-at-import content,
  registered in `.claude-plugin/marketplace.json`.
- `directive.sh` implements the three-tier cap, docs-only skip, and
  adaptive-miss-streak rule, each independently testable the way
  `scope-gate.sh`'s decision table is tested today.
- Every hunt record gains `cap_seconds`/`tier`/`diff_stat_lines`/
  `started_at`/`ended_at` frontmatter.
- The side-effect table's three confirmed rows are re-verified against
  the new protocol by replaying the two real historical diffs through it
  in phase 2 and confirming each still dispatches at a budget that would
  not have truncated the original stance.

## Files (write set, once approved)

- `warrant/README.md`, `warrant/hooks/*.sh`, `warrant/agents/warrant-hunter.md` (new)
- `.claude-plugin/marketplace.json`
- `docs/issue-63/reports/implementation.md` (phase-2 record)
