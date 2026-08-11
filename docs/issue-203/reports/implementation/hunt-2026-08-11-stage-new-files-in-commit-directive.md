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

## before-landing — stance 1: assume this change and another plugin's/gate's rule cancel each other out — find the pair

Verdict: NO FINDING
Seed: core/hooks/directive.sh commit-guidance bullet now instructs scoped `git add` of new/untracked files before `git commit -m`; checked against handbook-trigger-gate.sh, trailer-gate.sh, record-fields-gate.sh, scope-gate.sh for a contradicting or cancelling rule.
cap_seconds: 120
tier: default
diff_stat_lines: 179
started_at: 2026-08-11T13:40:00+09:00
ended_at: 2026-08-11T13:42:30+09:00

Checked whether the new "stage new files, scoped, no blanket add" advice
is silently cancelled by handbook-trigger-gate.sh's staged-set judgment
(the gate that fired on this very commit's new run*.sh file). It is not:
handbook-trigger-gate.sh's D2/issue-141 comment block (lines ~90-145)
already explicitly projects the staged set forward for the exact
`git add <paths> && git commit ...` composition the new directive text
recommends, via `git add --dry-run --` on each preceding `git add`
segment, and its own deny message even suggests "Stage explicit paths,
or run `git add` as a separate step first" — the same pattern the new
directive bullet teaches. trailer-gate.sh requires `git commit -m` with
an inline message (denying `-a`/editor-based commits when the message
isn't inline), which is consistent with the new bullet: it tells sessions
to `git add` then `git commit -m`, never to rely on `-a`/`-am` alone.
No gate advises or requires a blanket `git add -A`/`.` that the new
scoped-add instruction would contradict; grepped `git add -A|add \.` and
`-am\b` across core/hooks/*.sh and core/hooks/lib/*.sh — no other rule
text recommends unscoped staging. No reproduction of a cancelling pair
found within the cap.
