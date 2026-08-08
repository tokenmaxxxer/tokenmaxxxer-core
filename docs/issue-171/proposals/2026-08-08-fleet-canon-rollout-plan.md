---
status: proposed
files:
  - docs/issue-171/reports/implementation/rollout-runbook.md
---

## Request

Issue-171 embeds a real `run-fleet-scan.sh` result: 43/43 rulebooks
scanned, 0 blocked, every repo shows `canon-duplication` (vendored core
canon file) plus assorted per-repo silent-failure signals. It asks to
"execute the canon rollout across the 43 rulebooks per the #66 rollout
doc with the #168 scan as exit gate." Per this session's explicit
instruction, this PR is phase 1 only: plan the rollout mechanics
(per-repo PRs, batching, re-scan cadence) before any repo is touched.

## Constraints

- This repo has no write access to the 43 sibling rulebook repos (stated
  in every prior rollout doc: #63, #66, #69) — this PR cannot push a
  single line to any of them. Its deliverable is a runbook plus the
  batching/cadence decisions, not an executed rollout.
- The stub-swap content itself (which files move, what each stub looks
  like) is already decided — #66's "Transition path" and #69's
  "reclaim procedure" — this proposal must extend that template to all
  43 repos and to #171's specific counts, not re-derive it.
- The #168 scan (`run-fleet-scan.sh`) is the exit gate as the issue
  states, and needs no new code to serve that role — it is already
  re-runnable with zero arguments beyond `--org`.
- Per the survey, per-repo secondary findings beyond canon-duplication
  are not fully enumerable from the issue's truncated table — the plan
  must not assume a fixed defect list per repo; it must route "found
  during that repo's own PR" work back through the fix step.

## Rationale

**Batching: one wave grouping all three canon promotions (#63 + #66 +
#69) per repo, not three separate per-repo PRs.** This is not a new
choice — it is already the standing decision in
`docs/issue-66/decisions/2026-08-08-role-agnostic-canon-boundary.md`
(item 4) and restated in #69's reclaim doc ("stays batched with issue-63
... and issue-66's own per-rulebook follow-up ... one coordinated
per-rulebook change, not three separate touches"). The alternative —
one PR per canon-promotion-issue per repo (129 PRs instead of 43) — was
already rejected in that decision record specifically because it costs
each of the 43 repos three review cycles and three CI runs for changes
that touch the same files (`directive.sh`, `hooks.json`,
`hooks/tests/`). Restating rather than re-deciding it here, since #171
did not reopen that question.

**Rollout cohort ordering: pilot-first, then fan out by finding-count
ascending, not by repo name or all-at-once.** Considered and rejected:
(a) alphabetical/arbitrary order — gives no early signal on whether the
stub-swap instructions actually work against a real external install
layout; (b) all 43 at once — #69's reclaim doc already flags the
`${CLAUDE_PLUGIN_ROOT}` sibling-resolution path as unconfirmed against a
real marketplace install and explicitly calls for a pilot repo before
applying to more than one. Ascending finding-count order (start with the
fifteen 1-finding, canon-duplication-only repos) means the pilot batch
validates the mechanical stub swap in isolation, before any batch also
has to carry a secondary-defect fix in the same PR — cheapest signal
first, same logic as #168's own "no blocked rows" bar being checked
before deeper defect content is trusted.

**Per-repo PRs within a batch, not one PR touching multiple repos.**
Each of the 43 is a separate GitHub repo with its own review/CI surface
— there is no mechanism for one PR to span repos, so this is not really
a chosen alternative so much as a platform constraint; noted because the
issue explicitly asks for "per-repo PRs" as one of the mechanics to
propose.

**Re-scan cadence: after every batch, not after every repo and not only
at the end.** Rejected: re-scanning after each individual repo (43 scan
runs, ~O(n) full-fleet clones each time since `run-fleet-scan.sh` has no
single-repo mode from the orchestrator side) wastes the other 42
untouched clones' bandwidth on every check; re-scanning only once at the
very end gives no mid-rollout signal if a batch's stub-swap instructions
were subtly wrong (e.g. the plugin-root resolution issue #69 flagged),
meaning a systematic error could propagate through all remaining batches
before anyone notices. Per-batch re-scan catches a systematic error at
the pilot or second batch, not the 43rd repo.

## What will be done

Write `docs/issue-171/reports/implementation/rollout-runbook.md`, this
issue's own phase-1 deliverable, containing:

1. **Rollout unit definition** — restate, per repo, the concrete diff:
   delete `hooks/{trailer-gate.sh,record-fields-gate.sh,
   handbook-trigger-gate.sh,parse-check.sh,warrant-hunter.md-vendored-
   copy,stub-check.sh}` where present; replace `directive.sh` with the
   `core_role_directive` lib-call stub; set `RECORD_FIELDS_TERMINAL_STATES`
   in that repo's `hooks.json` env only if its current
   `record-fields-gate.sh` copy relied on a non-`landed` terminal set
   (per #66's report finding); then handle that repo's own secondary
   scan findings (six-signal sweep) as a normal defect fix commit in the
   same PR, or an explicit inline justification comment in the PR/record
   if the finding is a false positive for that repo.
2. **Cohorting** — five batches, ascending by #171's embedded
   finding-count: pilot (one repo, lowest count, e.g.
   `content-design-rulebook`), then four waves of ~10-11 repos each by
   count order. Exact repo-to-batch assignment table, built from the
   issue's own embedded counts.
3. **Per-repo PR shape** — one PR per repo per batch; PR body references
   `#171` (plain, not closing — per-repo PRs live in the sibling repo,
   not this one, so the closing-keyword rule is moot there, but the
   convention is stated for consistency) and links the stub-swap
   instructions in this runbook plus #69's reclaim doc.
4. **Re-scan cadence** — run `run-fleet-scan.sh` once after each of the
   5 batches merges; record the row delta (which repos newly went clean,
   which still show a finding and why) in this runbook's own
   append-only log section.
5. **Exit criterion restated concretely** — rollout is complete when a
   full `run-fleet-scan.sh` run shows, for all 43 rows: `clean`, or a
   `FINDING` line with a justification comment in that repo's own PR/
   record (per issue-171's acceptance text) — never a bare unexplained
   finding after the batch that was supposed to close it.
6. Update `docs/issue-171/reports/implementation.md` is NOT written in
   this PR — that file is phase-2 output per contract v3 s19 and waits
   for Approve.

## Out of scope

- Actually pushing any commit to any of the 43 rulebook repos, or
  dispatching agents/workers against them — that is phase-2 execution,
  gated on Approve, and even then happens as orchestration against
  external repos, not as a write from this repo's own tree.
- Re-deriving the stub-swap file contents — reuses #66/#69's existing,
  already-merged specification verbatim.
- Fixing any specific secondary (six-signal) finding now — the runbook
  states the routing (fix-in-same-PR or justify), not the fix itself,
  since the concrete finding list per repo is not fully readable from
  the issue's truncated table (per the survey).
- Changing `run-fleet-scan.sh` or `fleet-silent-failure-scan.sh` — #168's
  driver is reused unmodified as the exit gate; no new scan code.

## How you'll know it worked

- `docs/issue-171/reports/implementation/rollout-runbook.md` exists,
  assigns all 43 repos (from the issue's embedded table) to one of the 5
  batches, and states the per-batch re-scan step concretely enough that
  a future phase-2 session (or orchestration dispatch) can execute batch
  1 without re-deriving any of the decisions above.
- The runbook cites `run-fleet-scan.sh` as the unmodified exit-gate
  command, with no new scan-driver code proposed.
