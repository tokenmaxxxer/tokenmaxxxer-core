---
issue: 343
role: adversarial-review+silent-failure-audit-7994c7ed
author: adversarial-review+silent-failure-audit-7994c7ed
skills: adversarial-review (skill-repository(297e350)), silent-failure-audit (skill-repository(297e350))
verifies_subject: true  # independent re-verification of PR tokenmaxxxer-core#345 against issue #343
loop_state: reported
upstream:
  - path: core/hooks/approval-gate.sh
    sha: 682b9af9c8e215394a60a3e2b41520543f564126
  - path: docs/issue-343/reports/architecture-interface-contract-shape+silent-failure-audit-c770f4e0.md
    sha: 682b9af9c8e215394a60a3e2b41520543f564126
---

# issue-343 — adversarial-review+silent-failure-audit-7994c7ed record

## What was done

Independent adversarial re-verification of PR tokenmaxxxer-core#345
("issue-343: remove OBSERVER_ROLES closed-set exemption from
approval-gate.sh") against issue #343's Acceptance section. Everything
below was re-derived from a fresh `git worktree` at `origin/main`
(`af40daf`) plus the fetched PR head (`682b9af`, single commit) — the
PR body and its own record
(`docs/issue-343/reports/architecture-interface-contract-shape+silent-failure-audit-c770f4e0.md`)
were read only as a map of what to check, never as evidence.

**Bullet 1 — no fixed set of names decides closed-issue access.**
Present.
```
canonical: `grep -n 'OBSERVER_ROLES\|execution-observation\|conformance-review' core/hooks/approval-gate.sh` on pr345-tip (682b9af)
31:# every role, no exemption (issue-343: the former execution-observation/
32:# conformance-review closed-issue exemption from issue-295 is removed;
299:# two named roles (execution-observation, conformance-review), verifying
301:# auto-closed via that role's PR merge, implemented as OBSERVER_ROLES =
302:# ("execution-observation", "conformance-review") membership-tested at
303:# runtime (`role in OBSERVER_ROLES`) plus a hard-coded second identity,
325:# CAPABILITY REMOVED: execution-observation and conformance-review
```
7 hits (not the 5 the PR body and its record claim — see Open findings),
all 7 on `#`-prefixed lines. Confirmed these lines are inert two ways:
`bash -n core/hooks/approval-gate.sh` passes, and the embedded Python
block (the heredoc between `<<'PY'` at line 108 and `PY` at line 540)
parses clean under `ast.parse()` when extracted and run standalone —
both re-run directly by this session, not read from the PR's claim.
`grep -n 'closedByPullRequestsReferences\|issue_closers\|impl_branch\|issue-%s/implementation' core/hooks/approval-gate.sh`
returns exactly one hit, itself a comment (line 304) documenting the
removed literal. No runtime identifier remains anywhere in the file.

**Bullet 2 — the four combinations, before and after.** Present.
Re-derived directly against both gate binaries (`main`'s
`approval-gate.sh` as "before", `682b9af`'s as "after"), using a stub
`gh` fixture built independently from the PR's own (cross-checked
against `core/hooks/tests/run-approval-gate-tests.sh`'s `stub_gh`
shape, not copy-pasted from it) — see the six-case matrix below, each
run against both gate files:

| case | before | after |
|---|---|---|
| issue OPEN, observer role, real Approve | allow | allow |
| issue CLOSED via merge of `issue-<n>/implementation`, `execution-observation` | allow | **deny** |
| issue CLOSED via merge of `issue-<n>/implementation`, `conformance-review` | allow | **deny** |
| issue CLOSED, NOT via merge (manual re-close, standing PR review), observer role | deny | deny |
| issue CLOSED, `stateReason=NOT_PLANNED`, observer role | deny | deny |
| issue CLOSED via merge, non-observer role (`coding`) | deny | deny |

Only the merge-closed + named-role quadrant flips; every other cell is
identical before/after. This matches the PR's claim exactly.

One process note from re-deriving this: my first pass at the
stand-alone harness returned "allow" for every case on both gate
versions, including cases that should deny. Root cause: this session's
own environment carries `CORE_BUILD_NOW=1` (the build-now bypass this
task itself was authorized under), and my harness's `env` invocation
did not strip it before invoking the gate subprocess, so the gate's
own build-now bypass (`approval-gate.sh` line ~186) fired before
reaching the issue-state check on every run — a false "everything
allows" result with a mundane cause, not a gate defect. Fixed with
`env -u CORE_BUILD_NOW -u CORE_CHECKPOINT`; re-ran and got the table
above. Recorded here because it is exactly the kind of environment
leak this task's re-derivation posture exists to catch, including in
my own tooling.

**Bullet 3 — the issue-295 regression guard.** Present. The
"manual re-close, standing PR review, no merged-implementation-branch
closer" state (`stateReason=COMPLETED`, a standing PR-review APPROVED,
`closedByPullRequestsReferences` empty) was constructed directly and
denies on both gate versions (see table above, row 4) — i.e. the guard
already held before this PR (the pre-existing regression protection
issue-295 put in place) and continues to hold after, now as an
unconditional consequence of "any closed issue denies every role,"
not because the merge-closer check still runs. This is the case the
issue itself calls out: the exemption's removal makes this specific
guard's own branch of logic vacuous (there is no longer a
merge-closer check for it to guard), but the guard's *effect* — a
human's manual re-close with nothing newly merged denies everyone —
still holds, and holds for a strictly larger set of roles than before
(observer roles included, where before this PR they were the one
carve-out). Stated plainly per the issue's own framing: this is "a
guard that survives only because its subject disappeared," not a
guard that still actively discriminates the two closer shapes for
observer roles — because there is no longer any shape it needs to
discriminate for them.

**Bullet 4 — the `issue-%s/implementation` literal and
`closedByPullRequestsReferences` fetch.** Present.
`grep -n "closedByPullRequestsReferences\|issue_closers\|impl_branch\|issue-%s/implementation" core/hooks/approval-gate.sh`
on `682b9af` returns one hit (line 304, a comment). The `gh issue view`
call requests `state,comments,stateReason` only (confirmed by reading
the call site at line ~274-276); the third `gh pr view <n> --json
headRefName,state` call that used to resolve a closer PR's branch is
gone from the file (`grep -c 'headRefName' core/hooks/approval-gate.sh`
→ 0). Checked that nothing else in the file reads `issue_parsed`
beyond `state`, `comments`, `stateReason` (`grep -n 'issue_parsed\.'
core/hooks/approval-gate.sh` → only the three `.get(...)` calls at
lines 288/289/293) — the field removal did not silently starve any
other decision. This bullet's "read the replacement and show it works
on a subject whose branch does not use that name" is the deny path
itself: the replacement is "no branch name is read at all" — the
matrix row for `issue-7/execution-observation` (a subject branch that
never matches `issue-<n>/implementation`) already demonstrates this
denies identically to a subject that would have matched, since the
new code never inspects any branch name for this decision.

**Must-not clause (no renaming/relocating/sharding/env-config
read-back of the same names).** Re-ran
`scripts/audit_removal_claim.py` from `$ON_THE_RECORD/scripts/` myself
(not read from the PR's classification) against
`{"removed_names": ["OBSERVER_ROLES", "impl_branch"],
"member_samples": ["execution-observation", "conformance-review"],
"min_coloc": 2}`, `--root` on the fresh worktree:
```
verdict: RESHAPE_DETECTED
q1.live_hits: [(OBSERVER_ROLES, ./core/hooks/approval-gate.sh), (impl_branch, ./core/hooks/approval-gate.sh)]
q2.colocated_files: [(./core/hooks/approval-gate.sh, 2)]
q3.still_branches: false
```
Hand-classified both q1 live-hit lines and both q2 co-location lines
myself by reading `core/hooks/approval-gate.sh` directly: all are the
same `#`-prefixed comment lines identified in bullet 1, documenting
the removed shape and the operator ruling, none is a runtime
identifier or membership test. q3 (`still_branches: false`) means the
tool itself found no `role in (...)`/`==`/dict-dispatch shape touching
either name outside docs/tests — independently consistent with the
direct read of the file. The PR's own record additionally reports
`.git/FETCH_HEAD` and `.git/index` hits under q2 that this run did not
reproduce; traced this to environment, not substance —
`git worktree add` makes `.git` a redirect file, not a directory, so
this worktree has no `.git/index`/`.git/FETCH_HEAD` for the tool's
recursive grep to find. Either way both are non-executable git
plumbing (a worktree's index and a fetch log), consistent
classification, doesn't change the verdict.

**Test suite claim.** Present. `bash
core/hooks/tests/run-approval-gate-tests.sh` on `682b9af`: 65 passed,
2 failed (`checkpoint-refusal-names-await-approval`,
`execute-without-remote`). Same command on `main`'s own gate + test
file (checked out into the same worktree): 64 passed, 2 failed — the
same two names. The count differs (64 vs 65) because the PR's diff
adds one net new test case to the suite (2 removed `allow` cases for
the flipped quadrant, 3 added: the same 2 as `deny` plus one new
open-issue control case) — expected, not a discrepancy. The 2 failures
are identical by name on both sides and unrelated to this diff by
inspection (`checkpoint-refusal-names-await-approval` is about
checkpoint-mode await-approval wording; `execute-without-remote` is
about a missing git remote) — genuinely pre-existing on `main`.

**#344 vs #345 comparison.** No substantive difference found beyond
comment wording and test/handbook prose, consistent with the prior
finding that prompted this task. `git diff pr344-tip pr345-tip --
core/hooks/approval-gate.sh` shows only reworded comments; the
executable line `if issue_state != "OPEN":` and everything below it is
character-for-character identical between the two. #344's own grep for
`OBSERVER_ROLES\|execution-observation\|conformance-review` returns 8
hits (one more than #345's 7, all still comments) — a different
prose length, not a different capability.

## Why

Per the adversarial-review skill: this session is structurally
independent of the session that produced PR #345 (fresh worktree,
fresh context, no access to the builder's reasoning), and the value of
that independence is destroyed by inheriting the builder's own command
output as fact. Every check above was re-run rather than read,
including the ones where the PR's own claim turned out to be correct
(matrix, regression guard, field removal, test counts) — a review that
only re-runs the checks it suspects are wrong is not independent, it's
spot-checking. The one substantive miscount (bullet 1's hit count) was
only caught because the full command was re-run and diffed byte-for-
byte against the record's shown output, not because it looked
suspicious in isolation — it reads identically plausible either way in
prose.

## What did not work

My first pass at the four-combination harness (bullet 2) returned
"allow" for every case, including ones that should deny, because this
session's own `CORE_BUILD_NOW=1` leaked into the gate subprocess's
environment unstripped. Diagnosed and fixed by explicitly unsetting
`CORE_BUILD_NOW`/`CORE_CHECKPOINT` in the harness's `env` invocation;
documented in the bullet-2 write-up above rather than silently
discarded, since it is itself an instance of the class of bug this
whole task exists to catch.

## Upstream basis

- `core/hooks/approval-gate.sh` @ `682b9af` (PR #345 head) — the
  subject under review; diffed against `main`'s `af40daf`.
- `docs/issue-343/reports/architecture-interface-contract-shape+silent-failure-audit-c770f4e0.md`
  @ `682b9af` — the PR's own record; used only to identify which
  claims to independently re-check, never as the evidence for any
  verdict above.
- `core/hooks/tests/run-approval-gate-tests.sh` @ `682b9af` and @
  `af40daf` — re-executed on both, not read for its assertions.
- PR tokenmaxxxer-core#344 (`9ac6356`, closed as duplicate) — diffed
  against PR #345 for the #344-vs-#345 comparison above.
- issue tokenmaxxxer-core#343 — the Acceptance section this review
  checks against.

## Open findings

1. **PR #345's body and its own record undercount the bullet-1 grep
   hits: they claim "5 hits, all comment lines" and show a 5-line
   excerpt of the grep output, but the actual command against the
   committed file returns 7 hits — the shown excerpt silently drops
   lines 301 and 303, both of which contain `OBSERVER_ROLES` and match
   the stated grep pattern.** Substance is unaffected: all 7 hits are
   still `#`-prefixed comments, and the capability-removed verdict
   does not change. But the shown output is not what the command
   actually produces on the cited commit, which is exactly the shape
   `record-claim-guard.sh`'s `derived:`/code-fence requirement exists
   to prevent. Resolution path: not blocking — this is a documentation
   accuracy issue in an already-open PR, not a functional defect; the
   PR author (or a follow-up edit) should correct the count and the
   shown excerpt from 5 to 7 lines. Left unresolved by this record
   since this review has no write access to PR #345's branch or
   record.

## Next steps

None — this record is terminal. Acceptance verdict for issue #343,
as embodied by PR #345: all four Acceptance bullets are Present, the
must-not clause holds (RESHAPE_DETECTED with every contributing hit
independently hand-classified as inert), the test-suite claim holds,
and the #344/#345 duplicate comparison surfaces no missed capability.
The one open finding (grep-count discrepancy) is cosmetic and does not
change the verdict.
