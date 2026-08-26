---
proposal: docs/issue-305/proposals/2026-08-25-execution-observation-verify-pr313.md
---

# Hunt record — execution-observation-verify-pr313

## after-proposal — stance 0: assume the gate just touched is bypassable — find the bypass

Verdict: FINDING — approval-gate.sh treats every `git ...` Bash command with no `>`, `|`, backtick, or `$(` as unconditionally read-only, so a git command that writes to the execution surface (e.g. `git checkout <other-branch> -- src/foo.txt`, which restores a file from another branch into the working tree) is allowed with no approval check at all, while the equivalent non-git write (`cp otherfile src/foo.txt`) is correctly denied.
Kind: composition
Seed: core/hooks/approval-gate.sh (the phase-1/phase-2 gate this proposal's split relies on for enforcement); proposal diff itself is docs-only (docs/issue-305/proposals/2026-08-25-execution-observation-verify-pr313.md, +115 insertions, commit ec25a46)
cap_seconds: 60
tier: docs-only (per warrant/hooks/hunt-tier.sh HEAD~1 HEAD)
diff_stat_lines: 115 (1 file added)
started_at: 2026-08-25T00:00:00Z (approx, session-local)
ended_at: 2026-08-25T00:10:00Z (approx, session-local)

### Reproduce

approval-gate.sh, python judge (excerpt):
READ_ONLY_HEADS = ("ls", "cat", "head", "tail", "grep", "rg", "find", "wc",
                   "diff", "stat", "file", "git", "cd")
elif tool == "Bash":
    cmdline = ti.get("command")
    head = gate_lib.gate_head_of(cmdline)
    if head in READ_ONLY_HEADS and not gate_lib.gate_outside_quotes(cmdline, r"[>|`]|\$\("):
        allow()              # reading the tree is phase-agnostic

Test 1: git command that WRITES to the execution surface, no approval present:
echo JSON_PAYLOAD_1 | CLAUDE_ROLE=implementation bash core/hooks/approval-gate.sh
  where JSON_PAYLOAD_1 = {"tool_name":"Bash","tool_input":{"command":"git checkout some-other-branch -- src/foo.txt"}}
echo "EXIT=$?"

Test 2 (control): the equivalent non-git write, same role, same repo state:
echo JSON_PAYLOAD_2 | CLAUDE_ROLE=implementation bash core/hooks/approval-gate.sh
  where JSON_PAYLOAD_2 = {"tool_name":"Bash","tool_input":{"command":"cp otherfile src/foo.txt"}}
echo "EXIT=$?"

### Observed

Test 1 (git checkout ... -- src/foo.txt): the script prints nothing to stderr and exits 0 (allow) -- the write to src/foo.txt is let through with no approval check performed at all, because head == "git" is in READ_ONLY_HEADS and the command contains none of the four special characters (redirect, pipe, backtick, command-substitution open).

Test 2 (cp otherfile src/foo.txt, same missing-approval state): the script denies with exit 2 and:
approval-gate: execution-surface writes happen only on this role's own issue branch (issue-<n>/implementation; current: issue-305/execution-observation). Check out the branch, submit phase 1, and get the Approve first. (contract v3 s19)

So two Bash commands with the identical practical effect (write bytes into src/foo.txt on a role session with no Approve signal) get opposite verdicts purely because one is spelled with a git head. The same shortcut also unconditionally allows git apply <patch>, git stash pop, git merge, git cherry-pick, git reset --hard, git clean -f, git restore src/foo.txt, etc. -- any git subcommand that mutates the working tree without needing shell redirection, pipe, backtick, or command substitution in its invocation.

### Expected

READ_ONLY_HEADS including bare "git" should only fast-path allow() for git subcommands that cannot mutate the working tree (e.g. git status, git log, git show, git diff, git cat-file) -- not for the whole git verb family, several of whose subcommands (checkout -- <path>, apply, restore, stash pop, merge, reset --hard, clean -f, cherry-pick, pull) write files exactly like cp/Write/Edit do and should hit the same execution_surface check that cp correctly hits. As written, any role session blocked from editing src/** directly can still land arbitrary content there -- sourced from any other local branch/commit/patch -- via a same-repo "git checkout <ref> -- src/..." (or git apply, etc.) with no redirect/pipe/backtick/command-substitution in the command, defeating the phase-1/phase-2 split this proposal's whole plan is meant to be enforced by.

## before-landing — stance 1: assume the execution-observation record's positive verdict on PR #313 is wrong — check F23's OTR_DISPATCH_ONLY fail-closed fix for a composition regression not mentioned in the record

Verdict: FINDING — F23's fix turns any stray/leftover OTR_DISPATCH_ONLY value into a global, unconditional deny of every PreToolUse tool call (not just the misconfigured test), a session-wide fail-closed path the record's "no mechanism flipped from advisory to blocking outside the one file the PR names" claim does not disclose or examine.
Kind: composition
Seed: docs/issue-305/reports/execution-observation.md (the record being landed) + commit 9e0758a (core/hooks/pretooluse_dispatcher.py, F21/F23) on origin/issue-305/implementation, commit 183e2d3
cap_seconds: a few minutes
tier: default
diff_stat_lines: 1 file changed, 49 insertions(+), 8 deletions(-) (pretooluse_dispatcher.py, within the 16-file/543+/39- PR total the record cites)
started_at: 2026-08-26T00:00:00Z
ended_at: 2026-08-26T00:20:00Z

### Reproduce
```
git worktree add /tmp/pr313-wt 183e2d3
cd /tmp/pr313-wt
echo '{"tool_name":"Read","tool_input":{"file_path":"/tmp/x"},"cwd":"/tmp"}' \
  | OTR_DISPATCH_ONLY="record-felds-gate.sh" CLAUDE_ROLE=core python3 core/hooks/pretooluse_dispatcher.py
echo "rc=$?"
```
(`record-felds-gate.sh` is the exact typo used in commit 9e0758a's own message as its worked example for F23.)

### Observed
```
pretooluse_dispatcher.py: OTR_DISPATCH_ONLY='record-felds-gate.sh' does not match any registered gate (approval-gate.sh, board-gate.sh, gh-guard.sh, ordering-gate.sh, record-shape-gate.sh, citation-gate.sh, facet-keyword-gate.sh, handbook-trigger-gate.sh, proposal-shape-gate.sh, record-fields-gate.sh, survey-order-gate.sh, trailer-gate.sh); refusing rather than silently returning as if it had run and found nothing.
rc=2
```
A harmless `Read` of an arbitrary file, with no gate ever inspecting it, is denied — because OTR_DISPATCH_ONLY (a test-harness-only env seam per the commit's own comment) held any value that doesn't exact-match a registered gate name. Before F23, the identical situation returned 0 (silent full bypass — the bug F23 targets); after F23, it unconditionally exit-2's *every* tool call for the rest of the session, for every tool, regardless of what that tool touches. This is a second advisory→blocking flip (the whole dispatcher, gated only by an env var nothing scopes to tests) beyond the one exception (facet-keyword-gate.sh's bash-level check) the execution-observation record names as the sole disposition change in the entire 15-file sweep. Nothing in core/hooks unsets or scopes OTR_DISPATCH_ONLY per-test-process; if it is exported in a shell (e.g. left over from a manual `OTR_DISPATCH_ONLY=... bash run-x-test.sh` invocation) rather than passed inline, every subsequent tool call in that shell's Claude Code session blocks with this message until the variable is unset.

### Expected
The record's diff-scope claim ("the fail-open/fail-closed decision for every mechanism is unchanged... No mechanism was flipped from advisory to blocking or vice versa outside the one file the PR itself names as inconsistent") should have named this as a second, broader exception — the F23 fix converts the dispatcher's own typo-handling from non-blocking (return 0) to blocking (return 2) for literally every tool call, scoped only by an easily-leaked env var, and the record's operator-frozen-constraint assessment (§6, "no new... stall surface") should have weighed this global block against that constraint rather than only weighing the 5 narrowly-scoped python3-missing sites and the ordering-gate malformed-input cases.
