---
issue: 343
role: architecture-interface-contract-shape+silent-failure-audit-076c9768
author: architecture-interface-contract-shape+silent-failure-audit-076c9768
skills: architecture-interface-contract-shape (skill-repository(297e350)), silent-failure-audit (skill-repository(297e350))
verifies_subject: false  # flip to true only if this record is an independent verification of this subject's own deliverable -- see docs/handbooks/observer-verification.md
loop_state: landed
upstream:
  - path: core/hooks/approval-gate.sh
    sha: same-commit
  - path: core/hooks/tests/run-approval-gate-tests.sh
    sha: same-commit
---

# issue-343 — architecture-interface-contract-shape+silent-failure-audit-076c9768 record

## What was done

Removed the `OBSERVER_ROLES = ("execution-observation", "conformance-review")`
tuple and its runtime membership test (`role in OBSERVER_ROLES`) from
`core/hooks/approval-gate.sh`, along with the paired
`impl_branch = "issue-%s/implementation" % issue_num` hard-coded branch
literal and the `closedByPullRequestsReferences` fetch/loop that only
existed to evaluate that literal. The closed-issue precondition is now a
single unconditional check: `if issue_state != "OPEN":` deny, for every
role, no exemption.

canonical: `grep -n 'OBSERVER_ROLES\|execution-observation\|conformance-review' core/hooks/approval-gate.sh` — 8 hits, all inside comments (lines 32, 299, 302, 303, 306, 329, 357, 362-363); no `OBSERVER_ROLES` symbol and no `role in OBSERVER_ROLES` membership test remain on a live code path.

canonical: `grep -n 'issue-%s/implementation\|impl_branch' core/hooks/approval-gate.sh` — 1 hit, inside a comment (line 306); no `impl_branch` variable or `issue-%s/implementation` literal remains on a live code path.

Test file `core/hooks/tests/run-approval-gate-tests.sh` updated: the two
`observer-completed-close-*` cases that used to `run allow` on a
merge-closed issue now `run deny` (capability removed), one new
`run allow observer-open-issue-with-pr-review` case added as the open-issue
control for the same previously-exempted role, and the regression-guard
case (`observer-completed-close-no-merge-closer`, a manual re-close with no
new merge) still `run deny`, unchanged.

Before/after verdict matrix, demonstrated live against both the pre-change
gate (`git show HEAD:core/hooks/approval-gate.sh`, the commit this session
started from) and the new gate, using role `execution-observation` (one of
the two retired names) on branch `issue-7/execution-observation`:

```
=== OLD approval-gate.sh (pre-issue-343) ===
1. issue OPEN                                  allow
2. CLOSED via implementation-branch merge      allow
3. CLOSED, no merge-closer (manual re-close)   deny
4. CLOSED NOT_PLANNED (no merge)               deny

=== NEW approval-gate.sh (issue-343) ===
1. issue OPEN                                  allow
2. CLOSED via implementation-branch merge      deny   <- capability removed
3. CLOSED, no merge-closer (manual re-close)   deny   <- issue-295 guard unchanged
4. CLOSED NOT_PLANNED (no merge)               deny   <- unchanged
```
derived: ad hoc harness at `/tmp/before-after/demo.sh`, built from the same `stub_gh`/fixture shapes already in `core/hooks/tests/run-approval-gate-tests.sh`, run against a copy of the pre-change gate (`git show HEAD:core/hooks/approval-gate.sh`) and the working-tree gate, for the four state combinations named in the issue's acceptance bullet (issue open/closed x close-came-from-an-implementation-merge or not).

Row 2 is the stated capability loss: an execution-observation/
conformance-review session used to be allowed to act after its issue
auto-closed via the implementation role's own merged PR; it is now denied
like every other role. Row 3 is the issue-295 regression guard (a human's
manual re-close with nothing newly merged must still deny everyone) — it
held before this change and still holds after, as a strict superset (every
closed state now denies every role, so the guard's old special case is
just one instance of the new unconditional rule).

Replacement-works-without-the-name check: the new precondition reads only
`issue_state`, never a branch name or role name, so it behaves identically
for a subject whose branch is not `issue-<n>/implementation`:

```
=== NEW gate: branch name never referenced (no issue-<n>/implementation literal anywhere) ===
5. CLOSED, non-canonical branch/role name      deny
6. OPEN, non-canonical branch/role name        allow
```
derived: same harness, role/branch set to this session's own name (`architecture-interface-contract-shape+silent-failure-audit-076c9768`), which never appears in `impl_branch`'s retired literal — verdicts match rows 2 and 1 exactly, confirming the branch-name literal was never load-bearing for the post-change behavior.

acceptance: `bash core/hooks/tests/run-approval-gate-tests.sh` — result: 65 passed, 2 failed (same 2 pre-existing failures — `checkpoint-refusal-names-await-approval`, `execute-without-remote` — reproduced against the pre-change commit `af40daf` via `git stash` before this session's edits; unrelated to this change, out of scope per the issue's Non-goals).

## Why

The issue and its linked history (#2615, #2628, #2593, #2548) establish
that a fixed tuple of role names membership-tested at runtime is the
closed-set-identity shape the operator ruling of 2026-08-27 requires
removed, not renamed or relocated. `approval-gate.sh` has no structural
(non-identity) signal that means "this role's job is specifically post-hoc
verification of already-merged work" as distinct from any other role — the
role's own name was the only candidate signal, and matching on it by any
other container (config file, env var, different variable name) is the
same closed-set test in disguise.

A widening alternative was considered and rejected: dropping the role-name
check entirely but keeping the merge-branch check (i.e., "any role is
exempt on a closed issue if the close came from a MERGED PR on some other
branch than the reader's own") would need no role name at all. It was
rejected because issue-295's own comment documented "non-observer roles
are unaffected ... exactly as before issue-295" as a deliberate
restriction to those two roles, not an incidental byproduct of the branch
check — silently widening the exemption to every role would hand out a new
capability nobody asked for and nobody reviewed, which is not "preserving"
the old exemption, and the issue's own must-not list forbids weakening the
guard as a way of removing the tuple. Per the operator ruling, the correct
resolution when a capability cannot be preserved without reintroducing a
closed identity set is to remove the capability and say plainly what stops
working — done here, both in the code comment left in place of the removed
block and in this record.

The `issue-%s/implementation` literal fell out naturally: it was only ever
read inside the loop that tested `role in OBSERVER_ROLES`, so removing the
tuple's runtime test removed its only caller. There was no independent
"replacement" needed for it — the issue's fourth acceptance bullet
("resolved without a historical name, or its removal is stated as a
capability loss") is satisfied by the fact that it is simply gone, along
with the capability-loss statement inline in the new code comment. The
`closedByPullRequestsReferences` field is correspondingly dropped from the
`gh issue view --json` field list, since it was fetched only to feed that
now-removed loop.

## What did not work

None.

## Upstream basis

- `core/hooks/approval-gate.sh` (this commit) — the file the issue names
  directly; lines 319-321 in the issue's own quote correspond to the
  removed `OBSERVER_ROLES` tuple and its membership test.
- `core/hooks/tests/run-approval-gate-tests.sh` (this commit) — existing
  issue-295 fixture shapes (`closed-completed-with-comment`,
  `closed-completed-no-merge-closer-with-pr-review`, etc.) reused as-is to
  build the before/after demonstration; only the `run` lines' expected
  verdicts and comments changed.
- Prior related work cited in the issue: #2615, #2628 (on-the-record's
  `AUTO_SPAWN_ROLES`, the same tuple under a different name, actually
  removed), #2593 (removed a different hard-coded `issue-<n>/...` branch
  literal from `subject_deliverable_record()`), #2548 (the closed-set
  membership test this issue calls "the same test").

## Open findings

None.

## Next steps

None — issue-343's four acceptance bullets are satisfied and the branch is
ready for its phase-2 delivery PR (CORE_BUILD_NOW=1 bypass, per the
spawning prompt).

## Skill verdicts

skill-verdict: work-in-english — applied: invoked; repo-bound content (this record, code comments, commit/PR text) written in English per the skill, final user-facing summary in Korean
other mounted skills: not triggered (implementation-audit, conformance-review-finding-record, adversarial-review, parallel-decomposition, product-discovery-guardrail-metrics — none apply to a single-session bugfix delivery: no two-session audit, no conformance-review record to write, no independent-evaluator request, no multi-agent fan-out, no product-discovery hypothesis in scope)
