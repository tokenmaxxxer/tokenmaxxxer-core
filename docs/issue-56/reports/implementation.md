---
kind: coding-record
subject: issue-56
produced_by: implementation
code_under_review: `core/contract/role-handoff-contract.md`, `core/hooks/approval-gate.sh`, `docs/decisions/2026-08-01-s19-no-pr-refusal-retired.md`
loop_state: landed
upstream:
  - path: docs/issue-56/proposals/s19-no-pr-refusal-tradeoff.md
    sha: 34749823e063a761ea43e1c7920070959c6d4191
---

# Implementation record — issue-56

## Why

Phase 2, approved via issue-level comment `APPROVE issue-56/implementation`
(exact string, posted 2026-08-04T07:32:15Z by an approvers.md account,
jjongkwann — also this PR's own author, so single-account mode applies per
contract v3 s19; `docs/specs/approvers.md` lists `JiwonJung94` and
`jjongkwann`). Delivering the approved proposal's three `## What will be
done` clauses verbatim: retire `s19`'s "no PR exists at all ... enforced
rather than customary" claim (Option 2 — amend the sentence to state the
trade-off — over Option 1, restoring an equivalent "branch has ever had a
PR" precondition), mirror the same statement in `approval-gate.sh`'s
header comment, and record the choice under `docs/decisions/` per `s21`.

No rebase was needed at phase-2 start: `git merge-base issue-56/
implementation origin/main` already equals `origin/main`'s tip
(`1cbbabb`), confirming the branch's own prior rebase commit
(`3474982`, phase 1) already sits on top of current `main`.

## What was done

1. `core/contract/role-handoff-contract.md:798-816` — replaced the "What
   the gate blocks, mechanically" bullet with the proposal's Clause 1 text
   verbatim: states the no-PR refusal is retired once the single-account
   signal is a live issue comment, why (the comment path resolves from
   the issue alone; the branch's two-PR practice makes a temporary no-PR
   gap between phase 1's merge and phase 2's PR creation expected, not a
   denial), and what bounds a role's work in that gap instead (the
   approved proposal's own frozen `files:`/scope, and the unconditional
   per-PR merge decision).
2. `core/hooks/approval-gate.sh:7-13` — replaced the header-comment
   duplicate of the same claim with the proposal's Clause 2 text verbatim;
   no edit to the executable `python3` heredoc below it or to
   `core/hooks/tests/run-approval-gate-tests.sh`.
3. `docs/decisions/2026-08-01-s19-no-pr-refusal-retired.md` (new;
   `docs/decisions/` did not exist before this commit) — Clause 3:
   states chosen (amend `s19`/`approval-gate.sh` to state the trade-off)
   over rejected (restore an "ever had a PR" precondition), why (cost
   disproportionate to a severity the issue itself rates "moderate, not a
   hole"; would flip a test issue #53 shipped and passed days earlier from
   allow to conditional; the residual risk is a human-process choice
   `s19`'s own "human's seat" framing already leaves to human judgment),
   and the same failure signal the proposal names.
4. This record.

## What did not work

The proposal's own "How you'll know it worked" checklist includes `rg -n
"enforced rather than customary" core/` → 0 hits, but the same proposal's
Clause 1 blockquote — which item 1 above delivers verbatim, as the frozen
`## What will be done` text — itself contains that exact phrase, inside
the sentence retiring the claim ("This retires an earlier claim that
'open the proposal PR first' was mechanically enforced rather than
customary; it no longer is, ..."). Delivering Clause 1 as approved
therefore leaves one `rg` hit
(`core/contract/role-handoff-contract.md:810`), not zero — a mechanical
contradiction between two sections of the same approved proposal, not a
build defect: the surviving occurrence negates the claim in the same
clause rather than asserting current enforcement, and a same-scope
rewrite to force a literal 0-hit result was not made, since the quoted
Clause 1 text is the frozen scope this session delivers, not a target for
independent rewording. The other named check —
`rg -n "including while no PR exists at all" core/` → 0 hits — passes
clean (confirmed below), as does every other acceptance item.

## Doc-placement ladder

- [x] `docs/decisions/2026-08-01-s19-no-pr-refusal-retired.md` — the
  hard-to-reverse-choice decision record, per `s21` and the proposal's
  own Clause 3 (repo-standing `docs/decisions/`, not
  `docs/issue-56/decisions/`, per the proposal's Constraints note on the
  `s21`-vs-role-directive-prose discrepancy already flagged elsewhere).
- [x] `docs/issue-56/reports/implementation.md` (this file) — the
  phase-2 record, per contract `s11`/`s19`.
- [x] No `docs/handbooks/` entry — no env var, config key, dependency, or
  migration was introduced; this is a doc-text trade-off statement only.
- [x] No `docs/reports/` entry — no benchmark, measurement, or
  investigation numbers were produced; the verification below is a
  pass/fail confirmation, not a measurement.

## Hunt

`warrant-hunter` is not among this session's available `Agent`-tool
subagent types (same absence noted in prior implementation records for
this repo, e.g. issue-124, issue-128). In its place, adopted two stances
directly by inspection.

### Stance: assume this edit left the retired claim standing in some other habitat the proposal's own file list didn't cover

Verdict: NO FINDING
Seed: the two retired phrases themselves (`"enforced rather than
customary"`, `"including while no PR exists at all"`), swept across the
whole repository, not just `core/`.
Started/ended: this session, after making both text edits.

`rg -n "enforced rather than customary|including while no PR exists at
all" --hidden -g '!.git' .` finds exactly four sites: (1) this session's
own new `role-handoff-contract.md:810` occurrence, inside the
retiring sentence discussed under "What did not work" above; (2) this
session's own new decision doc, quoting the original sentence as
historical context inside a `## Context` section (not a live claim); (3)
`docs/issue-56/proposals/s19-no-pr-refusal-tradeoff.md` and
`docs/issue-56/reports/implementation/survey.md` — this issue's own
phase-1 documents, quoting the original text as the subject under
discussion, not asserting it as current gate behavior; (4)
`docs/issue-14/proposals/comment-approval-s19.md` — a pre-#53, historical
proposal quoting the then-current sentence, out of scope for this issue
and not a live claim either. No other habitat (handbook, spec, other
role's record, other contract section) restates the retired enforcement
claim as current. No finding.

### Stance: assume the approval-gate.sh header-comment edit drifted into the executable logic it claims not to touch

Verdict: NO FINDING
Seed: `core/hooks/approval-gate.sh`'s own Constraints note (proposal:
"header-comment edit only ... no change to the executable `python3`
heredoc").
Started/ended: this session, after making the edit.

`git diff -- core/hooks/approval-gate.sh` (reproduced in full above)
shows only lines 7-13 (the `#`-prefixed header comment block) touched;
the diff contains no line outside a `#` comment. `bash
core/hooks/tests/run-approval-gate-tests.sh` → `44 passed, 0 failed`,
identical count and identical per-case results (including
`issue-comment-approved-no-pr → allow` and `no-pr-yet → deny`, the two
cases this issue's substance bears on most directly) to the pre-edit
baseline implied by issue #53's own shipped test matrix. No finding.

### Closed checks (for verify)

closed_checks:
- name: both retired-phrase strings swept repo-wide, no other habitat found
  ref: rg -n "enforced rather than customary|including while no PR exists at all" --hidden -g '!.git' . (four sites, all accounted for above)
- name: approval-gate.sh diff touches only the header-comment block, no executable logic
  ref: core/hooks/approval-gate.sh:7-13 (git diff)
- name: full approval-gate test matrix unchanged pass count after the comment-only edit
  ref: core/hooks/tests/run-approval-gate-tests.sh (44 passed, 0 failed)
- name: full repo hook suite unaffected by the contract/gate/decision-doc edits
  ref: core/hooks/tests/run-all.sh (ALL OK: role-gates 24/24, stub-check 3/3, compliance-check 4/4, terse/freelunch/scout sibling suites all pass)

## Next steps

None open. This delivery completes all three `## What will be done`
clauses from the approved proposal. The proposal's own `## Out of scope`
list (Option 1's gate-logic/test-matrix changes, `run-approval-gate-
tests.sh` edits, `on-the-record`'s own docs, contract sections 8/10, the
`docs/decisions/` vs. `docs/issue-<n>/decisions/` discrepancy) is
deliberately not touched here, per that list.

## Resolution path

No open finding is raised against another role's record from this
delivery; both hunt stances above closed with no finding. The one
mechanical discrepancy recorded under "What did not work" is this
session's own observation about its own approved proposal's internal
acceptance criteria, not a finding against another role — left for a
human reviewer (or a later role reading this record) to judge whether it
needs its own follow-up.

## Verify

`rg -n "including while no PR exists at all" core/` → 0 hits (proposal
acceptance item, passes).

`rg -n "enforced rather than customary" core/` → 1 hit
(`role-handoff-contract.md:810`, the frozen Clause 1 text's own retiring
sentence — see "What did not work"; proposal acceptance item, does not
mechanically pass as literally stated).

`bash core/hooks/tests/run-approval-gate-tests.sh` → `44 passed, 0
failed`.

`bash core/hooks/tests/run-all.sh` → `ALL OK` (role-gates 24/24,
stub-check 3/3, compliance-check 4/4, plus terse/freelunch/scout sibling
suites all pass) — confirms the doc-only edits made no behavioral change.

`git diff --stat` (tracked files) →
`core/contract/role-handoff-contract.md | 23 ++++++++++++++++++-----`,
`core/hooks/approval-gate.sh | 9 ++++++---`; plus
`docs/decisions/2026-08-01-s19-no-pr-refusal-retired.md` (new/untracked)
and this record — matching the proposal's three-item `files:` write set.
