---
code_under_review:
  - core/hooks/directive.sh
  - core/hooks/tests/run-directive-shape-tests.sh
type: feature
breaking: false
verdict: shipped
loop_state: landed
---

# Implementation record — issue-204

## What was done

Promoted three gate-enforced shapes (on-the-record #726 rows 3, 4/14, 20)
into `core/hooks/directive.sh`'s shared interaction-protocol heredoc, per
the approved proposal `docs/issue-204/proposals/shared-directive-gate-shapes.md`:

1. **Spec-index regeneration** (row 3): a commit staging any
   `docs/specs/*` change must also regenerate and stage
   `docs/specs/reconciled-index.md` (`python3 gates/spec_index.py
   --update`) — mirrors `spec-index-preflight.sh`.
2. **PR trailer phase split** (rows 4/14): phase-1 proposal PRs carry a
   plain `#<issue>`; `Closes`/`Fixes`/`Resolves #<issue>` is forbidden
   until the phase-2 delivery PR — mirrors `pr-preflight.sh`'s
   `check_body`, promoted from the `coding`-only rulebook into the shared
   text every role receives.
3. **Test-claim fidelity** (row 20): a clean pytest pass claim must not
   omit pasted `SKIPPED` lines, and a hand-typed pass count must equal
   the pasted summary's count — mirrors `role-test-claim-guard.sh`.

Added `core/hooks/tests/run-directive-shape-tests.sh`, following
`run-role-directive-staging-tests.sh`'s precedent shape: renders
`directive.sh` with `CLAUDE_ROLE=implementation`, asserts each of the
three bullets' key phrases co-occur within their own bullet block (not
merely anywhere in the heredoc — see What did not work below), includes
one empty-state fixture per bullet, and one bypass fixture reproducing
the before-landing hunt's disconnected-bullets finding.

## Why

why: The #726 audit found these three shapes are currently learned only
from a gate refusal, because no role-independent directive text states
them — the same authoring-time-omission root cause as core#203. Promoting
them into the shared heredoc (rather than a single rulebook's own
directive, or `lib/role-directive.sh`'s boilerplate-only helper) puts the
rule where every role session actually reads it, matching where core
already put the branch-per-issue and new-file-staging bullets for
issue-203.

## Upstream basis

basis: docs/issue-204/proposals/shared-directive-gate-shapes.md

## What did not work

- Wrote the phase-split and test-claim assertions as two independent
  `case` wildcard checks (`*"phrase A"* ... *"phrase B"*`) against the
  whole rendered heredoc, expecting that to prove the rule is stated.
  The before-landing warrant hunt (stance 0, "assume the gate just
  touched is bypassable") showed this passes even when the actual bullet
  text is replaced by two disconnected, meaningless bullets that merely
  happen to each contain one of the phrases. Fixed by isolating each
  bullet's own text block with `awk` before matching, and added a
  bypass-fixture test reproducing the hunter's exact case.

## Doc-placement ladder outcomes

- [x] No env var/config key/new dep/migration/setup step introduced —
  no handbook update required.
- [x] No library-or-format choice over a named alternative and no
  changed public signature/wire format beyond what the phase-1 proposal
  already recorded — no new `docs/issue-204/decisions/` entry.
- [x] Hunt findings recorded in
  `docs/issue-204/reports/implementation/hunt-shared-directive-gate-shapes.md`
  (after-proposal: NO FINDING; before-landing: FINDING, resolved — see
  `resolved_findings` in that file).

## Verified

derived: bash core/hooks/tests/run-directive-shape-tests.sh
```
ok     names spec-index regeneration before docs/specs edits        present
ok     names the Closes/Fixes phase split for non-coding roles      present
ok     names the pytest skip/count fidelity rule                    present
ok     empty-state fixture (no spec-index rule) has no spec_index.py mention absent
ok     empty-state fixture (no phase-split rule) has no plain #<issue> mention absent
ok     empty-state fixture (no test-claim rule) has no SKIPPED mention absent
ok     bypass fixture (disconnected bullets) is not accepted as the phase-split rule absent

directive-shape: 7 passed, 0 failed
```

derived: bash core/hooks/tests/run-role-directive-staging-tests.sh
```
ok     renders the git commit -m requirement                        present
ok     renders a new-file staging (git add) instruction             present
ok     empty-state fixture (git commit -m/-am only) has no staging step absent
ok     explicitly rules out a blanket git add -A/.                  present

role-directive-staging: 4 passed, 0 failed
```
No SKIPPED lines in either run; both hand-typed counts above equal the
pasted summaries.

## Open findings

open findings: none open — the before-landing hunt's finding was resolved
in the same commit (see resolved_findings in the hunt record) and the
hunter has not yet re-cleared it (headless single-shot session, no later
turn to relay the re-check). Flagging this explicitly: the hunter's
re-clear is still outstanding at PR-open time.
