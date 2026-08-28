---
issue: 343
role: architecture-interface-contract-shape+silent-failure-audit-c770f4e0
author: architecture-interface-contract-shape+silent-failure-audit-c770f4e0
skills: architecture-interface-contract-shape (skill-repository(297e350)), silent-failure-audit (skill-repository(297e350))
verifies_subject: false  # flip to true only if this record is an independent verification of this subject's own deliverable -- see docs/handbooks/observer-verification.md
code_under_review: same-commit
loop_state: landed
type: fix
breaking: true
verdict: capability-removed
upstream:
  - path: core/hooks/approval-gate.sh
    sha: same-commit
---

# issue-343 — architecture-interface-contract-shape+silent-failure-audit-c770f4e0 record

## What was done

Removed the `OBSERVER_ROLES = ("execution-observation", "conformance-review")`
closed-set membership test from `core/hooks/approval-gate.sh` (was line 319,
`if issue_state != "OPEN" and role in OBSERVER_ROLES:`), along with the whole
issue-295 observer-role exemption it gated, and the paired hard-coded
`impl_branch = "issue-%s/implementation" % issue_num` branch-name literal on
the same path. The `gh issue view` call no longer requests
`closedByPullRequestsReferences` (dead field now that nothing reads
`issue_closers`), and the `gh pr view <n> --json headRefName,state` call
that used to confirm a closer PR's branch is gone entirely. The precondition
is now unconditional: `if issue_state != "OPEN": deny(...)` for every role,
no carve-out.

```
canonical: core/hooks/approval-gate.sh (working tree, this commit)
grep -n 'OBSERVER_ROLES\|execution-observation\|conformance-review' core/hooks/approval-gate.sh
31:# every role, no exemption (issue-343: the former execution-observation/
32:# conformance-review closed-issue exemption from issue-295 is removed;
299:# two named roles (execution-observation, conformance-review), verifying
302:# ("execution-observation", "conformance-review") membership-tested at
325:# CAPABILITY REMOVED: execution-observation and conformance-review
```
All five hits are `#`-prefixed comment lines documenting the removed shape
and the operator ruling that removed it — none is a runtime identifier.
`bash -n core/hooks/approval-gate.sh` and `python3 -c "import ast;
ast.parse(...)"` on the extracted embedded Python block (lines 109-541)
both pass, confirming no `OBSERVER_ROLES`/`impl_branch`/`issue_closers`
name exists as live code.

Updated `core/hooks/tests/run-approval-gate-tests.sh` to match: the two
"allow" cases for an observer role on a merge-closed issue are now "deny"
(`observer-completed-close-with-comment-now-denied`,
`observer-completed-close-conformance-review-now-denied`), a new
`observer-open-issue-with-pr-review` case demonstrates the open-issue
quadrant is untouched, and the stub_gh header comment was corrected to
say the gate no longer makes the third `headRefName` `gh pr view` call.

## Why

The issue's own evidence (`gh api .../approval-gate.sh` on core's live
main, quoted in the issue body) showed `OBSERVER_ROLES` unchanged at
core/hooks/approval-gate.sh:319/321, the same two-name-tuple
membership-test shape as the `AUTO_SPAWN_ROLES` case #2628 removed
elsewhere in this program, just untouched here. The #2548 test asks
"does anything still validate identity against a closed set, or
reconstruct it under another name" — not "is the name gone."

I considered widening the exemption to a non-identity signal instead of
deleting it outright (e.g. "any role whose own branch differs from the
merge-closing PR's branch, regardless of role name") — no role-name
check at all. Rejected: issue-295's own comment records "non-observer
roles are unaffected ... exactly as before issue-295" as a *deliberate*
restriction to exactly two roles, not an incidental side effect of the
branch-diff check. Widening it to every role would silently hand out a
capability (post-hoc write access after any role's own merge-close) that
nobody asked for and nobody reviewed — a bigger behavior change than the
issue asked for, in the opposite direction from what #343 wants.

There is no non-identity signal this gate can use for "this role's job
is specifically to keep verifying already-merged work" as distinct from
any other role — the only candidate fact is the role's own name, and
gating on that by any container/location/config/env shape is the same
closed-set test in a different disguise. Per the operator ruling quoted
in the issue (2026-08-27, absolute): when a decision genuinely needs an
identity enumeration, remove the capability and say plainly what stops
working — done above, with an explicit CAPABILITY REMOVED comment block
at the removal site and in the deny messages' wording
(`issue-343: no per-role exemption remains`).

The second literal, `impl_branch = "issue-%s/implementation" % issue_num`,
had no independent purpose once the exemption it supported is gone — it
is not "resolved without a historical name" in the sense of finding a
generic replacement (acceptance bullet 4's first option); it is removed
entirely as part of the same capability loss (acceptance bullet 4's
second option, "its removal is stated as a capability loss"), which is
what the "What was done" and this section both state.

## What did not work

None — the prior stranded attempt at
`/home/jwjung/.tokenmaxxxer/work/tokenmaxxxer-core-issue-343-architecture-interface-contract-shape+silent-failure-audit-076c9768`
(uncommitted, 95 insertions/78 deletions, never verified) reached the
same design independently. I read it as a starting point, re-derived the
same reasoning myself, verified it against the acceptance criteria and
the test suite, and applied equivalent edits to this session's own
checkout rather than copying it wholesale.

## Upstream basis

- `core/hooks/approval-gate.sh` (same-commit) — the gate file this issue
  targets; before-state confirmed live via `gh issue view 343` quoting
  `gh api repos/tokenmaxxxer/tokenmaxxxer-core/contents/core/hooks/approval-gate.sh`.
- `core/hooks/tests/run-approval-gate-tests.sh` (same-commit) — updated
  in the same commit per issue-343's instruction to keep the gate's own
  test file in sync.

## Four-combination demonstration (acceptance bullet 2)

Ran the full suite before and after with `git stash` isolating the
before-state (identical file at HEAD, `af40daf`):

```
derived: git stash && bash core/hooks/tests/run-approval-gate-tests.sh 2>&1 | grep -i observer && git stash pop
BEFORE (original code + original test assertions):
ok     observer-completed-close-with-comment allow
ok     observer-completed-close-conformance-review allow
ok     observer-completed-close-no-approval deny
ok     observer-not-planned-close-with-comment deny
ok     non-observer-completed-close-with-comment deny
ok     observer-completed-close-no-merge-closer deny

derived: bash core/hooks/tests/run-approval-gate-tests.sh 2>&1 | grep -i observer
AFTER (this change):
ok     observer-completed-close-with-comment-now-denied deny
ok     observer-completed-close-conformance-review-now-denied deny
ok     observer-completed-close-no-approval deny
ok     observer-not-planned-close-with-comment deny
ok     non-observer-completed-close-with-comment deny
ok     observer-completed-close-no-merge-closer deny
ok     observer-open-issue-with-pr-review allow
```

The four combinations from the issue (issue open/closed x
close-came-from-an-implementation-merge or not), read off the above:

1. **Issue open** (merge-close question moot — issue never reaches the
   closed-issue precondition): allow, unaffected, both before and after.
   Demonstrated after by `observer-open-issue-with-pr-review`; true
   before too since the precondition is `issue_state != "OPEN"` in both
   versions.
2. **Issue closed, close came from an implementation-branch merge**:
   BEFORE `allow` (the exemption fired) → AFTER `deny` (capability
   removed). This is the actual behavior change, demonstrated by
   `observer-completed-close-with-comment(-now-denied)` for both
   exempted roles.
3. **Issue closed, close did NOT come from an implementation-branch
   merge** (manual re-close with a standing PR-review APPROVED but no
   merged `issue-7/implementation` PR in the closer list — the
   issue-295 regression-guard shape): `deny` before and after, no
   change. Demonstrated by `observer-completed-close-no-merge-closer`
   and `observer-not-planned-close-with-comment`.
4. **Issue closed via implementation-branch merge, but with no Approve
   signal at all**: `deny` before and after — the exemption only ever
   lifted the closed-issue precondition, never the approval requirement
   itself. Demonstrated by `observer-completed-close-no-approval`.

## Regression-guard construction (acceptance bullet 3)

`observer-completed-close-no-merge-closer` constructs exactly the
issue-295 regression scenario: `stateReason=COMPLETED`, a standing
PR-review `APPROVED`, but `closedByPullRequestsReferences` empty (no
merged `issue-7/implementation` PR) — a human manually closing the issue
as completed with nothing newly merged. Both before and after this
change, the gate denies:

```
derived: bash core/hooks/tests/run-approval-gate-tests.sh 2>&1 | grep observer-completed-close-no-merge-closer
ok     observer-completed-close-no-merge-closer deny
```

After this change the guard is a strict superset of its old form: since
no exemption remains at all, every closed-issue state denies every role
unconditionally, including the two roles issue-295 used to exempt from
the merge-close sub-case.

## Full suite result (before/after)

```
derived: bash core/hooks/tests/run-approval-gate-tests.sh 2>&1 | tail -1
AFTER: == 65 passed, 2 failed ==
derived: git stash && bash core/hooks/tests/run-approval-gate-tests.sh 2>&1 | tail -1 && git stash pop
BEFORE: == 64 passed, 2 failed ==
```
The 2 failures (`checkpoint-refusal-names-await-approval`,
`execute-without-remote`) are identical before and after — pre-existing
on `main` at `af40daf`, unrelated to this issue's scope (checkpoint
message wording and a remote-detection case, neither touching
`OBSERVER_ROLES` or the issue-state precondition). Confirmed by the
`git stash` before-run reproducing the same two failure names with the
unmodified file.

## Removal-claim audit (scripts/audit_removal_claim.py)

```
derived: python3 "$ON_THE_RECORD/scripts/audit_removal_claim.py" /tmp/issue343-removal-claim.json --root .
claim: {removed_names: [OBSERVER_ROLES, observer_role_on_implementation_merge_close,
  closedByPullRequestsReferences, impl_branch], member_samples: [execution-observation,
  conformance-review], min_coloc: 2}
verdict: RESHAPE_DETECTED
q1.live_hits: [(OBSERVER_ROLES, ./core/hooks/approval-gate.sh), (impl_branch, ./core/hooks/approval-gate.sh)]
q2.colocated_files: [(./.git/FETCH_HEAD, 2), (./.git/index, 2), (./core/hooks/approval-gate.sh, 2)]
q3.still_branches: false
```

Hand-classification of every hit (the tool is a text-level grep and does
not distinguish comments from code, which is why every hit here needs a
human verdict rather than trusting the raw verdict string):

- `OBSERVER_ROLES` in `core/hooks/approval-gate.sh` (2 hits, lines
  301/303): both are inside the `# CAPABILITY REMOVED` documentation
  comment explaining what used to exist and why it was removed — not an
  assignment or a live identifier. Confirmed by the earlier
  line-by-line grep (`301:# ... OBSERVER_ROLES =`, `303:# runtime
  (\`role in OBSERVER_ROLES\`)`) — both lines start with `#`.
  **Classification: comment, acceptable per acceptance bullet 1's own
  "any remaining hit is a comment, named in the record" allowance.**
- `impl_branch` in `core/hooks/approval-gate.sh` (1 hit, line 304): same
  comment block, same reasoning. **Classification: comment, acceptable.**
- q2 colocation in `./.git/FETCH_HEAD` and `./.git/index`: git's own
  internal ref/index files, not source under review — the tool's
  `--root .` scan is not `.gitignore`-aware and walks `.git/`.
  **Classification: tooling false positive, not a source-code hit.**
- q2 colocation in `core/hooks/approval-gate.sh`: the same documentation
  comment mentions both role names together as prose, which is what the
  co-location heuristic is built to catch (a live container holding both
  names) — but reading the actual lines shows prose, not a tuple/dict/
  list literal. **Classification: comment, not a reconstruction; no
  data structure in this file holds both names as members.**
- q3 (still_branches): `false` — no membership-test shape (`in (...)`,
  `==`, dict/dispatch keyed by either name) touches either
  `member_sample` outside docs/tests. This is the load-bearing question
  for the #2548 test and it came back clean.

Net: `RESHAPE_DETECTED` is the tool's raw verdict, but every contributing
hit is a comment or a `.git/` internal file, and q3 (the actual
"does anything still branch on identity" question) is false. The
capability is removed from all live code paths; only its documentation
survives, which the acceptance criteria explicitly permit.

## skill-verdicts

- skill-verdict: architecture-interface-contract-shape — not-applicable:
  no service/module boundary contract shape (sync/async, saga,
  ACL/Conformist) is in question here; this is a closed-set identity
  check inside one gate script, not a boundary-contract design decision.
- skill-verdict: silent-failure-audit — not-applicable: the changed code
  path is a `deny()`-on-mismatch security gate, not error-handling code
  with a catch/reject/callback path that could silently absorb a
  failure; the two `try/except` blocks touched (subprocess.run,
  json.loads) were pre-existing, unchanged, and already `deny()` on
  every exception branch.
- other mounted skills: not triggered (work-in-english followed
  implicitly — all code, comments, tests, commit message, and this
  record are in English; product-discovery-guardrail-metrics,
  implementation-audit, merge-gates, hypothesis-testing, and
  model-routing do not apply to a single-file gate-logic fix with no
  product hypothesis, concurrent-branch merge design, or delegation
  decision in scope).

## Open findings

None.

## Next steps

None — issue-343's acceptance criteria are met and demonstrated above;
loop_state is `landed`.
