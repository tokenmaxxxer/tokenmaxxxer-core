---
proposal: docs/proposals/2026-08-08-fix-163-defects.md
---

# Hunt record — fix-163-defects

## before-landing — stance: assume the gate just touched is bypassable -- find the bypass (trailer-gate.sh quote-collapse)

Verdict: FINDING -- trailer-gate.sh's new quote-collapse (re.sub over paired empty quotes, applied before the git-commit regex match) only strips adjacent *empty* quote pairs, so single-char split quoting like `git c'o'mmit` still shell-executes as `git commit` but is not recognized by the gate's commit-word regex, letting a trailer-less commit of issue-tree work through undetected.
Kind: silent-failure
Seed: core/hooks/trailer-gate.sh diff adding the empty-quote-collapse regex before the git-commit regex match
cap_seconds: 120
tier: default
diff_stat_lines: single-line quote-collapse addition
started_at: 2026-08-08T00:00:00Z
ended_at: 2026-08-08T00:02:00Z

### Reproduce
```
D=$(mktemp -d); cd "$D"
git init -q; git config user.email a@b.com; git config user.name a
mkdir -p ISSUE_TREE/reports        # ISSUE_TREE = docs/issue-999 (a valid issue-tree path)
echo x > ISSUE_TREE/reports/file.txt
git add ISSUE_TREE/reports/file.txt
PAYLOAD='{"tool_name":"Bash","tool_input":{"command":"git c'"'"'o'"'"'mmit -m \"no trailer here\""}}'
echo "$PAYLOAD" | CLAUDE_ROLE=tester CLAUDE_PROJECT_DIR="$D" bash <repo>/core/hooks/trailer-gate.sh
echo "GATE EXIT: $?"
```
Also confirms shell semantics: `bash -c "echo git c'o'mmit -m foo"` prints `git commit -m foo`.

### Observed
`GATE EXIT: 0` — the gate allows the commit even though it stages the issue tree and its message has no `Subject:` trailer.

### Expected
The gate should deny (exit 2) with the "message lacks the required `Subject:` trailer" error, same as it does for `git commit -m "no trailer here"` without the split quoting.
