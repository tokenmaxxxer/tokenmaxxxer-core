---
code_under_review:
  - core/hooks/approval-gate.sh
  - core/contract/role-handoff-contract.md
  - warrant/hooks/state.sh
  - warrant/README.md
  - warrant/hooks/directive.sh
  - core/hooks/tests/run-role-gates-tests.sh
  - core/hooks/tests/deny-only-check.sh
  - docs/handbooks/role-gates-tests.md
  - docs/handbooks/board-gate-tests.md
  - docs/handbooks/approval-gate-tests.md
type: feature
breaking: false
verdict: n/a
loop_state: landed
---

## What was done

Implemented the frozen write set from
`docs/issue-189/proposals/2026-08-16-narrow-negative-lifecycle-remainder.md`
(approved via issue comment `APPROVE issue-189/implementation`):

1. `core/hooks/approval-gate.sh` — decision 1: the `issue_state != "OPEN"`
   denial message now interpolates the already-fetched `issue_state_reason`
   when present, falling back to the original message verbatim when absent
   (lenient parsing, no new failure mode). Decision 2: added
   `withdraw_challenge`/`defer_challenge`, matched with the existing
   `comment_matches()`, no new function. When the write is refused for lack
   of approval, a `WITHDRAW`/`DEFER` token now surfaces its own
   `severity: advisory` finding (no `verdict` field — contract §5's schema
   defines none) in the deny message, distinct from `REJECT`'s existing
   `severity: blocking` finding.
2. `core/contract/role-handoff-contract.md` — §2 preamble gains
   `withdrawn` (terminal, paired with an advisory finding pointer, same
   rule as `refused`) and `deferred` (non-terminal, resumable) as shared
   `loop_state` values. §5 gains the optional `recommended_close_reason:
   completed|not_planned` field on a `finding` block, read by the
   orchestrator's session and relayed to the human — no role gains a new
   `gh` write.
3. `warrant/hooks/state.sh` — decision 3: added `STALE_SECONDS` (14 days,
   mirroring `hunt-guard.sh:85`'s pattern) and a `stale_suffix()` helper
   reading the same per-file `git log -1 --format=%ct` this pass already
   runs — no new `gh` call, no new polling. An open unit whose last commit
   predates the threshold gets a `— deferred (auto, stale since
   <timestamp>)` suffix appended to its existing report line. Read-only:
   never writes to a proposal's `status:` or a role's `loop_state`.
4. `warrant/README.md:18`, `warrant/hooks/directive.sh:30` — each gained
   one added comment line pointing at `scope-gate.sh`'s `KNOWN_STATES` as
   the source of truth for the full state list, without inlining it a
   second place that can go stale again.
5. Test coverage: `run-role-gates-tests.sh` gained a `withdrawn` red/green
   pair (bare `withdrawn` denied, paired-with-pointer allowed), symmetric
   to the existing `refused` pair — `deferred` deliberately excluded
   (non-terminal by design, terminal-spelling coverage does not apply).
   `deny-only-check.sh` gained `withdraw_forgery_probe`, symmetric to
   `reject_forgery_probe`, confirming an off-branch forged board write is
   refused regardless of whether its content spells withdrawal.

All touched/reference suites run in this session, all green:

```
$ bash core/hooks/tests/run-role-gates-tests.sh
role-gates: 83 passed, 0 failed

$ bash core/hooks/tests/deny-only-check.sh core/hooks
deny-only-check: ok — no permissionDecision allow under core/hooks
deny-only-check: ok — approval-gate.sh refuses the forged board write
deny-only-check: ok — board-gate.sh refuses the forged board write
deny-only-check: ok — approval-gate.sh refuses the forged rejected-state board write
deny-only-check: ok — board-gate.sh refuses the forged rejected-state board write
deny-only-check: ok — approval-gate.sh refuses the forged withdrawn-state board write
deny-only-check: ok — board-gate.sh refuses the forged withdrawn-state board write

$ bash core/hooks/tests/run-scope-gate-tests.sh
== 33 passed, 0 failed ==

$ bash core/hooks/tests/run-approval-gate-tests.sh
== 50 passed, 0 failed ==
```

`run-scope-gate-tests.sh` and `run-approval-gate-tests.sh` are reference
suites (unchanged by this pass' write set) — run to confirm no regression.

## Why

Closes the two gaps step-1's re-audit (PR #220) graded still-open after
candidates 1-3 shipped in PR #194: `state_reason` was fetched
(`approval-gate.sh:236/:254`) and thrown away, and `REJECT` had no
symmetric acts for voluntary withdrawal or postponement. `WITHDRAW`/
`DEFER` complete the token family the issue asked for
(APPROVE/REJECT/WITHDRAW/DEFER, all issue-comment tokens with identical
trust machinery). Auto-expiry-to-`deferred` gives a stale open unit a
legible label instead of silence, without granting any automated process
a status-mutation capability (the "null results read as failure" class of
harm the issue is about, kept out by construction — reporting only).

## Upstream

Based on:
`docs/issue-189/proposals/2026-08-16-narrow-negative-lifecycle-remainder.md`
(PR #221, merged), which itself confirmed via
`docs/issue-189/reports/architecture/survey.md`'s 2026-08-16 addendum that
candidates 1-3 of the original four gaps already shipped in PR #194/#220.

## What did not work

None — no write attempted-then-reverted, and no held expectation broke
during this build.

## Hunt (before-landing)

Dispatched `warrant:warrant-hunter`, model sonnet, 180s cap, scoped to the
7 touched files. Record:
`docs/issue-189/reports/implementation/2026-08-16-hunt-narrow-negative-lifecycle-remainder.md`.
One finding: `approved = pr_approved or comment_approved` short-circuits
the `if not approved:` block, so an APPROVE comment/review from a listed
approver present alongside a WITHDRAW/DEFER/REJECT comment on the same
issue silently wins — the withdraw/defer/reject finding is never
consulted or surfaced. Confirmed real; also confirmed pre-existing for
REJECT (unchanged by this commit) and inherited verbatim by the new
WITHDRAW/DEFER tokens, since they compose with `REJECT`'s exact
precedence structure per the approved proposal's explicit constraint
("compose with what already shipped, don't reinvent"). Not fixed here:
this is the proposal's own named out-of-scope item — "Enforcement off
DEFER/WITHDRAW... beyond recognizing and recording the act — same
deferral the original full design made for `CHANGES_REQUESTED`
auto-enforcement" — and fixing precedence between simultaneous
conflicting signals is a design decision (which signal wins, and
whether "most recent" is even determinable from `gh`'s comment ordering)
that belongs in a future proposal, not decided silently in this pass.

## closed_checks

- check: run-role-gates-tests.sh full suite | code_sha: cac104981187699e01cd38bd998683db28e766d5
- check: deny-only-check.sh (core/hooks) | code_sha: cac104981187699e01cd38bd998683db28e766d5
- check: run-scope-gate-tests.sh full suite (reference, unchanged) | code_sha: cac104981187699e01cd38bd998683db28e766d5
- check: run-approval-gate-tests.sh full suite (reference, unchanged) | code_sha: cac104981187699e01cd38bd998683db28e766d5

## Open findings

- The before-landing hunt finding above (an APPROVE comment/review
  present alongside a WITHDRAW/DEFER/REJECT comment silently wins, no
  precedence rule decided) is left open, matching the approved
  proposal's explicit deferred scope. Resolution path: a future issue or
  proposal deciding simultaneous-signal precedence (most-recent-wins by
  timestamp, or an explicit conflict-denial), if the human wants that
  blast radius.
- The prior implementation pass' open finding (mixed
  `CHANGES_REQUESTED`/`APPROVED` review auto-enforcement, PR #194) is
  unrelated to this pass' write set and remains tracked there, not
  reopened here.
