---
proposal: docs/issue-323/proposals/2026-08-26-execution-observation-verify-pr324.md
---

# Hunt record — execution-observation-verify-pr324

## after-proposal — stance 0: assume the gate just touched is bypassable — find the bypass.

Verdict: FINDING — proposal-shape-gate.sh always exits 0 (allow) regardless of its own verdict, so any phase-1 proposal write bypasses the seven-section shape check unconditionally.
Kind: silent-failure
Seed: docs/issue-323/proposals/2026-08-26-execution-observation-verify-pr324.md (121-line new proposal file, phase-1 shape)
cap_seconds: 60
tier: default
diff_stat_lines: 121
started_at: 2026-08-26T10:14:39+09:00
ended_at: 2026-08-26T10:16:00+09:00

### Reproduce
```
cd /home/jwjung/.tokenmaxxxer/work/tokenmaxxxer-core-issue-323-execution-observation
GATE=/home/jwjung/.claude/plugins/marketplaces/tokenmaxxxer/runs/rulebooks/tokenmaxxxer-core/core/hooks/proposal-shape-gate.sh
export CLAUDE_PROJECT_DIR="$(pwd)"
payload=$(python3 -c '
import json
print(json.dumps({"tool_name":"Write","tool_input":{"file_path":"docs/issue-323/proposals/2026-08-26-bogus.md","content":"garbage no sections at all"}}))
')
echo "$payload" | bash "$GATE"
echo "EXIT CODE: $?"
```

### Observed
Gate prints a full "missing or misshapen required element(s)" denial listing all seven markers absent, then exits 0 (`EXIT CODE: 0`). Per the code's own `deny()` in both the shell prelude (`exit 0 # issue-282 DEMOTE: advisory, not blocking`) and the Python judge (`sys.exit(0)` after emitting the denial JSON), the gate never returns a PreToolUse-blocking exit code (2) for a shape failure — only internal/parse errors (rc=2, fail-closed) block. A completely malformed proposal file (no frontmatter, no sections, no order) is written through unimpeded; the gate's refusal is advisory context only, not enforcement.

### Expected
Given the task framing that this is "one of the gate(s) that adjudicated this write" enforcing "the seven required sections... in order," and that PreToolUse hooks normally use exit 2 to block, a shape violation on a phase-1 proposal write should either block the write (exit 2) or the mechanism (a human/agent downstream) must independently guarantee the advisory is actually acted upon — nothing in this hook path enforces that. Since exit 0 is indistinguishable from "shape verified OK," any caller not reading stderr/systemMessage sees ordinary success.
