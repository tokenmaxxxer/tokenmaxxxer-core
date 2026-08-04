---
kind: coding-record
subject: issue-118
produced_by: implementation
code_under_review: `core/contract/role-handoff-contract.md`
loop_state: landed
upstream:
  - path: docs/issue-118/proposals/2026-08-04-add-defect-class-and-other-habitats-question-to-record-norm.md
    sha: caed0b13b9f5d17f7ba76ebe306a764acf7810ef
---

# Implementation record — issue-118

## Why

Phase 2, approved via issue-level comment `APPROVE issue-118/implementation`
(exact string, posted by an approvers.md account, jjongkwann — also this
PR's author, so single-account mode applies per contract v3 s19). Delivering
the approved proposal's `## What will be done` items: append one new §20
item so a role's record must state, for every confirmed `finding` entry,
which defect class it belongs to and whether that class was checked for
elsewhere in the codebase, plus this record's own note on the
`execution-observation-rulebook` follow-up (proposal item 2 / issue #118
requirement 3).

## What was done

1. Rebased the branch onto `origin/main` (which had moved to `c94cb33`,
   merging #116/PR #117's approval-rule follow-up repairs, since this
   branch's phase-1 commit). Confirmed first that #116's contract-file
   diff (11 insertions, 1 deletion around §19's near-match handling,
   `git diff 451439e..c94cb33 -- core/contract/role-handoff-contract.md`)
   does not touch §20 (which sits at lines 801-834 pre-rebase, 811-844
   post-rebase) — the rebase applied clean with no conflict.
2. `core/contract/role-handoff-contract.md`, §20 — appended item 6,
   "Defect class and other habitats," after the existing item 5 and its
   own lead-in sentence ("Additionally, whenever the role's record states
   a confirmed `finding` entry..."), mirroring the section's existing
   two-tier structure (items 1-3 unconditional, items 4-5 conditional on
   "leaves work open") rather than folding into either tier. Items 1-5 are
   untouched — confirmed by `git diff --stat` showing 9 insertions, 0
   deletions, one file. The wording cites §2's `finding` kind and its
   `Unverifiable` verdict value verbatim (grepped `core/contract/role-handoff-contract.md:70`
   to confirm the exact enum before writing the reference).
3. Verified no other in-repo `directive.sh` (`core/hooks/`, `warrant/hooks/`,
   `scout/hooks/` — the three that exist in this checkout) mirrors §20's
   item list or count (`grep -n "record minimum\|What was done\|next-steps
   backlog\|record must state"` across all three: no hits), so no sibling
   file needed a matching edit — same conclusion the phase-1 survey
   reached for `core/hooks/directive.sh` alone, now confirmed for all
   three.
4. Ran `bash core/hooks/tests/run-role-gates-tests.sh` (19/19 passed,
   unchanged) and `bash core/hooks/tests/run-gate-lib-tests.sh` (53/54
   passed) — see `## Verify` for the one gate-lib failure and why it is
   pre-existing, not caused by this change.
5. This record, including the `execution-observation-rulebook` follow-up
   note — see `## Next steps`.

## What did not work

None. The §20 edit landed as drafted on the first attempt; the rebase
applied with no conflict.

## Doc-placement ladder

- [x] No `docs/issue-118/decisions/` entry. The proposal document itself
  (`docs/issue-118/proposals/2026-08-04-add-defect-class-and-other-habitats-question-to-record-norm.md`,
  `## Rationale`) already carries the required alternative-and-reason
  record for the one real choice this issue makes (§20 vs. §2's `finding`
  row vs. a new observation-specific section vs. a standalone decision
  doc) — this delivery executes that already-decided choice, per the
  proposal's own `## Out of scope` item naming this exact alternative as
  rejected.
- [x] No `docs/handbooks/<component>.md` entry. No environment variable,
  config key, dependency, migration, or run/setup/deploy step was
  introduced or changed — contract §21's handbook trigger does not fire.
- [x] `docs/issue-118/reports/implementation.md` (this file) — the
  phase-2 record, per contract §11/§19.

## Hunt

`warrant-hunter` is not among this session's available `Agent`-tool
subagent types (same absence noted in issue-88/90/93/94/98/100/106's
records). In its place, adopted each stance directly by inspection,
following the same local precedent.

### after-proposal (retroactive) — stance: assume the rule as drafted cannot hold — find the state nothing maintains

Verdict: NO FINDING
Seed: `docs/issue-118/proposals/2026-08-04-add-defect-class-and-other-habitats-question-to-record-norm.md` (the docs-only phase-1 diff, commit `caed0b1`)
Started/ended: this session, before and after drafting the §20 item.

Checked whether the new item references anything that does not exist as
drafted: `finding`'s kind name and its `Unverifiable` verdict value are
grepped verbatim from §2's table (`core/contract/role-handoff-contract.md:70`)
rather than assumed from memory, so the cross-reference cannot drift from
the schema it points to. No finding.

### before-landing — stance: assume this change and another plugin's rule cancel each other — find the pair

Verdict: NO FINDING
Seed: `git diff` of this transition (`core/contract/role-handoff-contract.md`
only) against sibling plugin directives and the gate that cites §20.
Started/ended: this session, after drafting the §20 item.

Checked whether `record-fields-gate.sh` (the one mechanical consumer that
cites §20 by number) hardcodes an item count or list that the new item 6
would silently break: its checks (`grep -n "§20" core/hooks/record-fields-gate.sh`)
are a fixed set of named sections/tokens (what-was-done, why,
upstream-basis, `loop_state:`, open-findings, next-steps/resolution-path),
none of them an enumerated "5 items" count — confirmed matching the
phase-1 survey's own reading of the same script. Also checked the three
in-repo `directive.sh` files (`core/hooks/`, `warrant/hooks/`,
`scout/hooks/`) for any mirrored §20 item list that would now be
one-short — none mirror §20 at all (`## What was done` item 3). No
finding.

### Closed checks (for verify)

closed_checks:
- name: record-fields-gate.sh does not derive from §20 item count
  ref: core/hooks/record-fields-gate.sh:4,8,81,99,101,106,145,157,182,206
- name: no in-repo directive.sh mirrors §20's item list
  ref: core/hooks/directive.sh, warrant/hooks/directive.sh, scout/hooks/directive.sh

## Next steps

- **`tokenmaxxxer/execution-observation-rulebook` per-role directive
  reflection (cross-repo, not reachable from this branch).** Per proposal
  item 2 / issue #118 requirement 3 and the #106 precedent
  (`docs/issue-106/reports/implementation.md` `## Next steps`): the
  observation role's own record-shape template (the `### Finding N`
  sub-block structure — `Impact`, `Timeline`, `Root cause`, `Action item`
  — used across every `docs/issue-<n>/reports/execution-observation.md`)
  lives in the separate repo `tokenmaxxxer/execution-observation-rulebook`,
  confirmed by the phase-1 survey to exist but be unreachable from this
  working tree. This record recommends filing a follow-up issue against
  that repo to add a labeled field mirroring §20 item 6 — "which defect
  class" and "other habitats checked" — to the `### Finding N` template
  itself, so the question is prompted structurally rather than relying on
  a role reading the core contract's §20 unprompted (the gap the phase-1
  survey's `docs/issue-107/reports/execution-observation.md` example
  illustrates: the one instance that asked this did so only inside
  free-form `Root cause` prose, not as a repeatable field).
- Whether the new §20 item 6 is in practice followed or skipped by future
  `execution-observation` records — and whether that recurrence pattern
  eventually warrants mechanizing it into `record-fields-gate.sh` (issue
  #118 requirement 2's own stated future-work trigger) — is an
  observation-role and future-issue question, not decided or answered by
  this delivery.

## Resolution path

No open finding is raised against another role's record from this
delivery; both hunt stances above closed with no finding. The one
cross-repo gap (`execution-observation-rulebook` reflection) is carried
forward as a `## Next steps` follow-up recommendation, exactly as issue
#118 requirement 3 itself anticipated ("관찰 역할 룰북이 별도 레포 소유라
여기서 못 고치는 부분이 있으면... 룰북 반영 필요성을 기록에 남긴다"), not a
blocking `finding:` block.

## Verify

`bash core/hooks/tests/run-role-gates-tests.sh` → `role-gates: 19 passed,
0 failed`, unchanged from pre-edit.

`bash core/hooks/tests/run-gate-lib-tests.sh` → `gate-lib: 53 passed, 1
failed`. The one failure (`compliance-check.sh: flags a hand-rolled
kill-switch + replace shape want=deny got=allow`) is a pre-existing
sandbox artifact, not caused by this change: confirmed by `git stash`-ing
this delivery's own diff and re-running the same suite against unmodified
`origin/main` — identical `53 passed, 1 failed` result, with the same
`mktemp: mkdtemp failed ... Operation not permitted` /
`mkdir: /docs: Operation not permitted` / `mkdir: /hooks: Operation not
permitted` lines preceding it in both runs (this session's sandbox denies
writes to `/docs`, `/hooks`, and some `mkdtemp` paths outside the
allow-listed set, which several `run-gate-lib-tests.sh` cases need to
build fixture trees). Then restored this delivery's diff (`git stash
pop`).

`git diff --stat` (this delivery) → `core/contract/role-handoff-contract.md
| 9 +++++++++`, one file, matching the proposal's "How you'll know it
worked" checklist ("git diff for this proposal's phase-2 execution touches
exactly one file").

`grep -n "defect class\|other habitats" core/contract/role-handoff-contract.md`
→ one hit, the new item 6 heading, grep-able as the proposal specified.
