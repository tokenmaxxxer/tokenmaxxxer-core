---
kind: coding-record
subject: issue-53
produced_by: coding
loop_state: landed
upstream:
  - path: docs/issue-53/reports/coding/survey.md
    sha: 6d47a1157b5833c8336c422e0060183cdf3a396d
  - path: docs/issue-53/reports/coding/scout-brief.md
    sha: 6d47a1157b5833c8336c422e0060183cdf3a396d
  - path: docs/issue-53/proposals/issue-comment-approval-scope.md
    sha: 6d47a1157b5833c8336c422e0060183cdf3a396d
code_under_review: 6d47a1157b5833c8336c422e0060183cdf3a396d
closed_checks:
  - name: never-the-issue-language-removed
    code_sha: 6d47a1157b5833c8336c422e0060183cdf3a396d
  - name: issue-state-precondition-blocks-closed-issue
    code_sha: 6d47a1157b5833c8336c422e0060183cdf3a396d
  - name: isminimized-comment-does-not-authorize
    code_sha: 6d47a1157b5833c8336c422e0060183cdf3a396d
  - name: hooks-run-all-passes
    code_sha: 6d47a1157b5833c8336c422e0060183cdf3a396d
---

# Coding record — issue-53, phase 2

Approved via issue-level comment `APPROVE issue-53/coding` (single-account
mode) on issue #53 (jjongkwann, 2026-07-30), and via a PR review Approve on
PR #54.

## Why

The contract's own text (`s8`, `s19`), `approval-gate.sh`'s implementation,
and observed practice (on-the-record) disagreed on where the single-account
Approve signal lives. The PR-only reading cannot survive this role's own
measured two-PR-per-issue workflow: phase 1's proposal PR merges and closes
before phase 2's build PR opens, so a PR-comment approval on PR A is
invisible to a gate resolving PR B. The issue is the one anchor stable
across both PRs — see `docs/issue-53/proposals/issue-comment-approval-scope.md`,
whose alternative of keeping both PR-comment and issue-comment valid was
rejected there (superset with no compensating benefit once zero PRs were
open repo-wide).

## What was done (clause checklist, proposal "What will be done", commit `6d47a11`)

1. **Contract s10 rewrite** — DONE. Hunk: the "one structural exception"
   paragraph now describes an issue-level comment instead of a PR-level
   one, states the two-PR rationale, and drops "never the issue."
2. **Contract s19 rewrite** — DONE. Hunk: the "Single-account mode" bullet
   now anchors to the issue, plus new **Scope**, **What this does and does
   not authorize**, and **Revocation** paragraphs (the proposal's own core
   deliverable per its item 3 open design question).
3. **`approval-gate.sh` rewrite** — DONE. Hunks: header comment (issue-state
   precondition + two `gh` calls described); branch regex now captures
   `issue_num` and `role` separately (`^issue-([0-9]+)/(.+)$`); new
   issue-state precondition block (`gh issue view --json state,comments`,
   denies before either approval path when the issue is not `OPEN`);
   two-account path tolerant of "no PR open"; single-account path scans
   the issue's own comments. Extended one hunk beyond the proposal's literal
   text: the comment-matching loop skips `isMinimized` comments — a
   phase-2 warrant-hunt finding, not in the original proposal text, closed
   in the same commit (see Hunt below).
4. **`run-approval-gate-tests.sh` rewrite** — DONE. Hunks: `stub_gh` made
   argument-aware (branches on the stub's own `$1` being `issue` vs `pr`);
   all 7 new cases from the proposal's item 4 added
   (`issue-comment-approved-no-pr`, `pr-review-approved-no-issue-comment`,
   `issue-comment-agent`, `issue-comment-prose`, `neither-surface`,
   `closed-issue-with-comment`, `closed-issue-with-pr-review`); the
   existing `comment-challenge`/`comment-challenge-agent`/`comment-prose`
   cases repointed to the issue-comment stub path per the proposal's final
   bullet. One case added beyond the proposal text:
   `issue-comment-minimized`, covering the `isMinimized` fix above.

## Dropped / not in the frozen write set

- **A `docs/decisions/` (or `docs/issue-53/decisions/`) record of the
  scope-model choice.** The proposal's own "Out of scope" section names
  this and says it is "added in phase 2 alongside the code," but the same
  proposal's frozen `files:` list names exactly the three files above, and
  the invoking task instruction was explicit: implement the frozen write
  surface, the three files, as-is. The proposal's own text disagrees with
  itself here (out-of-scope-for-phase-1 vs. a phase-2 deliverable it never
  added to the write set). Per the scope-exceeded rule, I did not create
  it — recording the discrepancy rather than resolving it unilaterally.
  If a decision record is actually wanted, it needs its own explicit scope.
- **`docs/handbooks/approval-gate-tests.md` (new file, committed anyway).**
  Not in the named write set, but `handbook-trigger-gate.sh` — an existing,
  already-merged commit gate, not something this proposal introduced —
  mechanically refused any commit touching
  `core/hooks/tests/run-approval-gate-tests.sh` (an "operational surface")
  without a matching `docs/handbooks/<component>.md`. No such handbook
  existed for this test harness. This is a hard precondition to landing the
  named three-file diff at all, not a discretionary scope decision, and
  matches the doctrine ladder's own "setup step -> the component's
  handbook, same turn" rule.

## What did not work

Running `bash core/hooks/tests/run-approval-gate-tests.sh` for the first
verification pass triggered a sandbox-specific failure that destroyed the
working tree. macOS's `/usr/bin/mktemp` ignores `$TMPDIR` and resolves via
`confstr(_CS_DARWIN_USER_TEMP_DIR)` to `/var/folders/.../T`, a path this
sandbox denies writing to. The test harness's `td="$(cd "$(mktemp -d)" &&
pwd -P)"` pattern, when `mktemp -d` fails and prints nothing, evaluates
`cd ""` — which in bash stays in the current directory rather than
erroring — so `$td` silently resolved to the actual project root. The
harness's own cleanup, `rm -rf "$td"`, then deleted the real working tree
(everything except sandbox-protected `.git/config` and `.claude`).
Recovered by hand-rebuilding the minimal `.git` skeleton (`HEAD`,
`objects/`, `refs/` — `git init` itself is blocked by the same sandbox rule
against writing `.git/config`), `git fetch origin`, and `git reset --hard
origin/issue-53/coding`: all previously-committed history was intact on the
remote, so only this session's not-yet-committed edits were lost, and were
rewritten from scratch. Fixed going forward within this proposal's write
set by hardening every `mktemp -d` call in `run-approval-gate-tests.sh` to
`mktemp -d -p "${TMPDIR:-/tmp}"`. The identical latent pattern exists in
`run-board-gate-tests.sh` and `deny-only-check.sh` (outside this proposal's
write set) — not fixed here since that would widen the write set beyond
the frozen three files; those were only patched *temporarily* to safely
exercise `run-all.sh` once, then reverted (`git checkout --`) before this
commit, so this PR's diff does not touch them. Flagged under Next steps
for a follow-up.

## Hunt (warrant-hunter)

**Phase 1** (`docs/reports/2026-07-30-hunt-issue-comment-approval-scope.md`,
"after-proposal" stance): found that the proposal's originally-drafted gate
design fetched issue comments but never issue state, so the contract's
"closing the issue ends it unconditionally" claim would not have
mechanically held. Closed in the proposal's own revision (before this
build started) and implemented here as the issue-state precondition block
in `approval-gate.sh` (commit `6d47a11`).

**Phase 2** (same file, "before-landing" stance 2, rotated): found that
`approval-gate.sh`'s issue-comment scan checked only `author`/`body`, never
`isMinimized` — so hiding/minimizing the `APPROVE issue-<n>/<role>` comment
(GitHub's own non-destructive retraction action, distinct from delete/edit)
did not revoke the approval it granted, contradicting the contract's
Revocation text. Closed in the same commit: the comment-matching loop now
skips any comment where `isMinimized` is truthy, with a new
`issue-comment-minimized` test case (deny).

Both fixes were verified by a deliberate break-then-revert of the guarding
code: commenting out the issue-state check flipped exactly
`closed-issue-with-comment` and `closed-issue-with-pr-review` to FAIL (33
passed, 2 failed); commenting out the `isMinimized` check flipped exactly
`issue-comment-minimized` to FAIL (35 passed, 1 failed). Both reverted
immediately after confirming red, restoring the full green suite.

## Acceptance criteria (proposal "How success will be judged")

- `rg -n "never the issue" core/contract/` → 0 hits: PASS.
- Allow: `issue-comment-approved-no-pr`, `pr-review-approved-no-issue-comment`: PASS.
- Deny: `issue-comment-agent`, `issue-comment-prose`, `neither-surface`,
  `closed-issue-with-comment`, `closed-issue-with-pr-review`,
  `issue-comment-minimized`: PASS.
- Scope model (branch-wide; revoked by delete/edit-away or issue closure)
  stated in s19's own text, not left to the gate's behavior: PASS.
- `bash core/hooks/tests/run-all.sh`: PASS — `ALL OK` (approval-gate suite
  36/36, board-gate 40/40, gh-guard 19/19, parse-check and deny-only-check
  across all four plugins).

## Open findings

None open. Both warrant-hunt findings above are closed in this same build;
resolution path: each closed_checks entry above cites the commit sha that
resolved it, and either finding may be cited-and-skipped or re-derived by
verify per contract s16.

## Next steps

None on this subject for coding. Flagged for a human/future issue, not
actioned here (outside this proposal's frozen scope):

- The `mktemp -d` hazard in `run-board-gate-tests.sh` and
  `deny-only-check.sh` — sandbox-specific, but real and reproducible; a
  small, independent fix.
- Whether issue-53's scope-model choice warrants a `docs/decisions/`
  record per contract s21 — the proposal's own text is ambiguous about
  whether that is this PR's job or a follow-up's (see "Dropped" above).
