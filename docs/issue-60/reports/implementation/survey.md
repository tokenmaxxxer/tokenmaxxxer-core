---
kind: coding-record
subject: issue-60
produced_by: implementation
loop_state: proposed
upstream: []
---

# Current-state survey — issue-60

## 1. Issue trace, re-derived against the live code

Re-ran `_reads_only()` from `core/hooks/board-gate.sh` (lines 140-155) by
hand and by direct execution against `git rm -r docs/issue-49/reports`:

- `DEVNULL_REDIR.sub(" ", cmdline)` — no `/dev/null` in the string, no
  change.
- `SUBSHELL.search(probe)` — no backtick, no `$(` — no match.
- `FILE_REDIR.search(probe)` — no bare `>` — no match. Both guards clear,
  so `_reads_only` proceeds into the segment loop instead of returning
  `False` immediately.
- `SEGMENT.split(probe)` — no `|`, `;`, `&&`, or `||` — one segment.
- `_head_of(seg)` — `words[0].rsplit("/", 1)[-1]` = `"git"`; `"git"` is not
  in `TRANSPARENT`, so it is returned as-is.
- `"git" in READ_ONLY_HEADS` (line 96) — true — `continue`. The loop has
  no more segments, so `_reads_only` returns `True`.
- Back in the `Bash` branch (line 167): `if _reads_only(cmdline): allow()`
  — `sys.exit(0)` fires here. Execution never reaches the candidate
  extraction at line 171, so R1 (layout), R4 (branch), and R5 (ownership)
  never run for this command.

The issue body's walkthrough matches the code exactly at every step.
Confirmed by direct execution, not just re-reading — see the
`_reads_only` probe below, run against the full set the issue names plus
`apply`/`mv`/`stash`/`clean`:

```
READ-ONLY (bypasses board-gate write scan) :: git rm -r docs/issue-49/reports
READ-ONLY (bypasses board-gate write scan) :: git checkout -- docs/issue-49/reports/x.md
READ-ONLY (bypasses board-gate write scan) :: git restore docs/issue-49/reports/x.md
READ-ONLY (bypasses board-gate write scan) :: git clean -fd docs/issue-49
READ-ONLY (bypasses board-gate write scan) :: git apply patch.diff
READ-ONLY (bypasses board-gate write scan) :: git mv docs/issue-49/a docs/issue-49/b
READ-ONLY (bypasses board-gate write scan) :: git stash push -- docs/issue-49
```
(`git log`/`git diff`/`git show` also report `READ-ONLY`, correctly —
that half of the classification is not what's broken.)

## 2. Does approval-gate independently block this? No — same defect, unpatched

The issue asked, before proposing, whether `approval-gate.sh` closes this
gap on its own (in which case issue-60 would shrink to a tests-only
change). It does not: `core/hooks/approval-gate.sh` carries the identical
root cause.

- Line 84: `READ_ONLY_HEADS = ("ls", "cat", "head", "tail", "grep", "rg",
  "find", "wc", "diff", "stat", "file", "git")` — `"git"` again present,
  whole-command, no subcommand awareness.
- Line 85: `WRITEISH = re.compile(r"[>|`]|\$\(")` — this is the exact
  pre-fix pattern `board-gate.sh` itself used before PR #59 (issue-55);
  it flags `>`, `|`, backtick, `$(`, and nothing else. `rm`, `checkout`,
  `restore`, `clean`, `apply`, `mv`, `stash` contain none of those
  characters.
- Lines 118-120: `head = cmdline.strip().split()[0]...; if head in
  READ_ONLY_HEADS and not WRITEISH.search(cmdline): allow()`. For `git rm
  -r docs/issue-49/reports`, `head == "git"`, `WRITEISH` does not match →
  `allow()` fires before `execution_surface()` (lines 94-107) is ever
  consulted.

Verified by executing approval-gate's own `READ_ONLY_HEADS`/`WRITEISH`
check against the same command set used above — every one of them prints
`ALLOW (bypasses execution-surface adjudication)`.

Consequence: even a role with no Approve on record — the exact case
approval-gate exists to stop — can `git rm -r docs/issue-<foreign>/...`
today. The issue body's "이미 막힌다면 이 이슈는 테스트 추가로 축소된다"
branch does not apply; the full fix (code change + regression tests)
stands as scoped.

Separately, and only as context (not a blocker for this issue):
`approval-gate.sh`'s `execution_surface()` gates `src/**`, `test/**`
(via `CODE_RE = re.compile(r"(^|/)(src|test)/")`) and `docs/issue-<n>/`
outside the phase-1 homes. `core/hooks/board-gate.sh` and
`core/hooks/tests/run-board-gate-tests.sh` match neither `CODE_RE` (no
`src/` or `test/` path segment — `hooks/tests/` is not `hooks/test/`) nor
the `docs/issue-<n>/` pattern, so approval-gate does not gate writes to
the hook scripts themselves. That's orthogonal to today's finding (the
gap is in the *read-classification* logic, not in whether the hook file
itself is protected) and does not change what this issue needs to fix.

## 3. `approval-gate.sh` needs the identical fix — out of scope here

`approval-gate.sh`'s `READ_ONLY_HEADS`/`WRITEISH` pair (lines 83-85) has
the same subcommand-blindness as the one this issue fixes in
`board-gate.sh`, guarding a different concern (the phase-2 Approve gate,
not board layout/ownership) with its own test harness
(`run-approval-gate-tests.sh`). Folding both fixes into one PR would mix
two gates' regression surfaces into a single diff against the "minimal
diff" convention this board already follows (see
`docs/issue-12/proposals/2026-07-29-board-gate-mkdir-rm-fix.md`).
Recommend filing it as its own follow-up issue once this one lands, so
its own test harness gets its own regression coverage.

## 4. Residual risk noted, out of scope here: `--output=<file>`

`git log`, `git show`, and `git diff` (and the `diff-tree`/`diff-index`
family, which share the same diff machinery) accept a documented
`--output=<file>` flag that writes command output to an arbitrary path
instead of stdout — confirmed against the installed `git version 2.50.1`
manpages (`git log --help` and `git diff --help` both list "Output to a
specific file instead of stdout." under the shared diff-options section).
Neither `FILE_REDIR` (matches shell `>`/`>>` only) nor a subcommand
allowlist catches an application-level `--output=` flag. This risk
already exists today — `"git"` is currently trusted whole-command, so
`git log --output=docs/issue-49/x.md` already bypasses — and is not
introduced by the fix below; a subcommand-aware allowlist that still
includes `log`/`diff`/`show` (required to keep the s4 READ-broad
guarantee from PR #59) does not close it either. Recommend a follow-up
issue scoped to output-flag detection across all of `READ_ONLY_HEADS`
(`sort -o` has the same shape), rather than folding it into this one.

## Skip record (scout-directive)

Scouting skipped — bugfix-shaped: the issue names the exact function, the
exact bypass, and the exact acceptance criteria; the fix is a targeted
subcommand-awareness change to one function, with no open design
question about wanted behavior.

## 5. Re-verification addendum (2026-08-01) — this turn's state check

This turn was assigned to (re)do issue-60's phase 1 from scratch. Before
drafting anything new, checked whether that premise still held:

- `docs/issue-60/proposals/2026-07-31-build-git-subcommand-aware-board-gate.md`
  and this survey already exist on `main` — merged via PR #61
  ("propose(implementation): git subcommand-aware read classification
  (issue-60)", `mergedAt: 2026-07-31T07:01:18Z`, author `jjongkwann`).
- Issue #60 carries one comment: body exactly `APPROVE
  issue-60/implementation`, author `jjongkwann`, posted
  `2026-07-31T07:00:47Z` (31s before the PR #61 merge). `jjongkwann` is
  listed in `docs/specs/approvers.md`. PR author and approver are the
  same account → single-account mode → this is a valid phase-2 Approve
  signal per contract v3 s19, independently of the PR merge.
- Three issues merged to `main` after PR #61 (issue-69 → PR #71,
  issue-72 → PR #73/#74, issue-75 → PR #76/#77) touched
  `core/hooks/lib/gate-lib.{sh,py}` (source-guard canonization, a shared
  `gate_bash_write_targets` token-scan helper). Checked whether this
  moved `board-gate.sh`'s `READ_ONLY_HEADS`/`_reads_only()` or
  `approval-gate.sh`'s `READ_ONLY_HEADS`/`WRITEISH` into the shared lib,
  which would have changed this proposal's diff surface: it did not.
  Both gates still carry their own self-contained Python heredoc; neither
  sources `gate_bash_write_targets` or any lib-level read/write
  classification (`grep` for both symbols across `core/hooks/*.sh`
  outside the two gates' own definitions returns nothing). The only
  drift is a ~1-line shift from unrelated edits elsewhere in the same
  heredocs (e.g. `READ_ONLY_HEADS` was at board-gate.sh:95-98 when the
  proposal was written, is at :96-99 now; `_reads_only()` was :145-154,
  is :141-156 now) — cosmetic, not structural. The proposal's checklist
  (files, line anchors read as "near X", the `GIT_READ_SUBCOMMANDS`
  tuple, `_git_subcommand()`, the `_reads_only()` segment-loop insertion,
  the new `run-board-gate-tests.sh` cases) still matches the live code
  exactly. **No amendment needed.**

Conclusion: issue-60's phase 1 is not a fresh task this turn — it is
already complete, merged, and approved for phase 2 delivery. Writing a
second, competing proposal would contradict the one a human already
approved, for no code-surface reason (verified above). This turn's
output is this addendum (confirming the standing proposal still holds
against post-merge changes) rather than new proposal content; see this
PR's description for the full state trace and the recommended next
step (a phase-2 delivery session on this same subject).
