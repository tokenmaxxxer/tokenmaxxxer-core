---
proposal: docs/issue-189/proposals/2026-08-16-narrow-negative-lifecycle-remainder.md
---

# Hunt record — narrow-negative-lifecycle-remainder

## after-proposal — stance 1: WITHDRAW/DEFER composition with an approval already present

Verdict: FINDING — `approved = pr_approved or comment_approved` short-circuits before WITHDRAW/DEFER/REJECT are ever consulted, so a WITHDRAW (or REJECT) comment posted by the very same approver alongside an APPROVE comment is silently ignored and the gate allows the write.
Kind: composition
Seed: core/hooks/approval-gate.sh (WITHDRAW/DEFER token addition, issue-189 decision 2)
cap_seconds: 180
tier: default
diff_stat_lines: n/a (given files list, not a diff)
started_at: 2026-08-16T00:00:00Z
ended_at: 2026-08-16T00:20:00Z

### Reproduce
```
mkdir -p /tmp/wgtest/repo/docs/specs /tmp/wgtest/repo/src
cd /tmp/wgtest/repo && git init -q && git remote add origin https://example.com/x.git
printf -- "- approver1\n" > docs/specs/approvers.md
git checkout -q -b issue-189/implementation
git add -A && git commit -q -m init

cat > /tmp/wgtest/gh <<'GHEOF'
#!/usr/bin/env bash
if [ "$1" = "issue" ]; then
cat <<'JSON'
{"state":"OPEN","state_reason":null,"comments":[
 {"author":{"login":"approver1"},"body":"APPROVE issue-189/implementation","isMinimized":false},
 {"author":{"login":"approver1"},"body":"WITHDRAW issue-189/implementation","isMinimized":false}
]}
JSON
exit 0
fi
if [ "$1" = "pr" ]; then echo '{"reviews":[]}'; exit 1; fi
exit 1
GHEOF
chmod +x /tmp/wgtest/gh

cd /tmp/wgtest/repo
CLAUDE_ROLE=implementation CLAUDE_PROJECT_DIR=/tmp/wgtest/repo CORE_GH=/tmp/wgtest/gh \
  bash core/hooks/approval-gate.sh <<< '{"tool_name":"Write","tool_input":{"file_path":"src/foo.txt"}}'
echo "exit=$?"
```

### Observed
`exit=0` — the write is allowed. The gate never inspects `comment_withdrawn`/`comment_rejected` because `approved` (True from `comment_approved`) short-circuits the `if not approved:` block entirely.

### Expected
A WITHDRAW (or REJECT) comment from a listed approver, present alongside an APPROVE comment on the same issue, should deny the write (or at minimum be surfaced) — the design's own commentary frames WITHDRAW/REJECT as revocation-capable signals ("voluntary stop", "was withdrawn, not merely unapproved"), but the code path that reports that message is unreachable whenever any approval (PR review or comment) also exists, regardless of which comment/review is more recent. The same gap pre-existed for REJECT and is unchanged by this commit, but WITHDRAW/DEFER inherit it verbatim.
