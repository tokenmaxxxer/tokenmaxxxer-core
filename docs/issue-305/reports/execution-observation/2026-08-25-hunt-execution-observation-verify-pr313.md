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
