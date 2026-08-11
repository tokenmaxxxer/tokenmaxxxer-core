---
proposal: docs/issue-203/proposals/2026-08-11-stage-new-files-in-commit-directive.md
---

# Hunt record — stage-new-files-in-commit-directive

NOTE: the dispatcher-specified path
`docs/issue-203/reports/hunt-2026-08-11-stage-new-files-in-commit-directive.md`
is refused by board-gate.sh's R5 ownership rule (contract v3 s11): under
`docs/issue-203/reports/`, role `implementation` may write only
`implementation.md` or `implementation/**`, never a bare top-level
`hunt-*.md` file. This record is filed at the nearest role-owned path
instead (`.../reports/implementation/hunt-...md`).

## after-proposal — stance 0: assume the gate just touched is bypassable — find the bypass

Verdict: FINDING — trailer-gate.sh allows a commit that stages a valid
`Subject: issue-<n>` trailer while leaving new/untracked issue-tree files
out of the staged set entirely; the proposed fix (advisory heredoc text +
a rendered-text unit test) has no mechanism to prevent this, so the
underlying gap issue-203 describes (commit "lands" but omits new files)
remains fully open after the proposal ships.
Kind: composition
Seed: git diff --stat HEAD~1 HEAD (docs/issue-203/proposals/2026-08-11-stage-new-files-in-commit-directive.md, docs/issue-203/reports/implementation/survey.md — 204 insertions, docs-only)
cap_seconds: 180
tier: size:>200-lines (docs-only diff, 204 insertions across 2 files)
diff_stat_lines: 204
started_at: 2026-08-11T00:00:00Z
ended_at: 2026-08-11T00:12:00Z

### Reproduce
```
rm -rf /tmp/tg-test && mkdir -p /tmp/tg-test/docs/issue-999/proposals && cd /tmp/tg-test
git init -q
printf orig > docs/issue-999/proposals/tracked.md
git add docs/issue-999/proposals/tracked.md
git commit -qm init
printf modified > docs/issue-999/proposals/tracked.md
printf "brand new untracked content" > docs/issue-999/proposals/new-file.md
git add docs/issue-999/proposals/tracked.md   # new-file.md is deliberately left unstaged

export CLAUDE_ROLE=implementation
export CLAUDE_PROJECT_DIR=/tmp/tg-test
GATE=core/hooks/trailer-gate.sh
PAYLOAD='{"tool_name":"Bash","tool_input":{"command":"git commit -m \"Subject: issue-999\n\nupdate tracked file\""}}'
echo "$PAYLOAD" | bash "$GATE"
echo "exit code: $?"
```

### Observed
`git status --porcelain` shows the new file as untracked
(`?? docs/issue-999/proposals/new-file.md`) and `git diff --cached --name-only`
shows only `docs/issue-999/proposals/tracked.md` staged. Feeding
trailer-gate.sh the exact `git commit -m "Subject: issue-999..."` command
that would actually run next produces `exit code: 0` — the gate allows the
commit. The resulting commit would carry a correctly formed trailer and
pass every mechanical check, yet silently omit `new-file.md` from history,
reproducing the exact "No commits between main and branch" / lost-work
failure mode issue-203 exists to close.

### Expected
Either trailer-gate.sh (the one mechanical enforcement point in this flow)
refuses commits that leave working-tree-untracked files under the same
issue tree unstaged, or the proposal should not claim to close the gap:
it explicitly puts a mechanical staging gate out of scope, and its
acceptance test only asserts the *rendered directive text* mentions
`git add` — it never runs a real commit and never checks that anything
actually rejects the exact bypass reproduced above. A role satisfies the
new instruction "in form only" merely by having been shown wording that
mentions `git add`; the mechanical path that lets `git commit -m` land an
incomplete, trailer-valid commit is untouched by this change.
