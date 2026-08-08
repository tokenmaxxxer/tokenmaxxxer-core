---
proposal: docs/issue-147/proposals/2026-08-08-announce-gate-literals-and-per-kind-terminal-states.md
---

# Hunt record — announce-gate-literals-and-per-kind-terminal-states

## before-landing — stance 0: assume the gate just touched is bypassable — find the bypass

Verdict: FINDING — record-fields-gate.sh derives the per-kind terminal-state set from the record's own self-declared `kind:` frontmatter field with no check that the declared kind matches the acting role, letting a session pick whichever kind's terminal vocabulary is most permissive for its actual loop_state value and bypass the next-steps/resolution-path requirement entirely.
Kind: composition
Seed: git diff HEAD~1 HEAD -- core/hooks/record-fields-gate.sh (the new `m_kind = re.search(r'^\s*kind:\s*([A-Za-z0-9_-]+)', new_text, ...)` / `KIND_TERMINAL_DEFAULTS` / `ROLE_TO_KIND` block)
cap_seconds: 180
tier: default
diff_stat_lines: 419 insertions(+), 32 deletions(-) across 6 files (record-fields-gate.sh: 106 lines)
started_at: 2026-08-08T00:00:00Z
ended_at: 2026-08-08T00:09:00Z

### Reproduce
Run record-fields-gate.sh directly (fake project root, CLAUDE_ROLE=qa) against a Write to a qa record whose path matches this role's own record pattern (`docs/issue-<n>/reports/qa.md`), once with `kind: qa-record` and once with `kind: coding-record`, both with `loop_state: landed` and no next-steps/resolution-path section:

```
export CLAUDE_ROLE=qa
export CLAUDE_PROJECT_DIR=<fake project root with docs/specs/role-handoff-contract.md>
# record.md frontmatter: kind: coding-record / loop_state: landed / sha: same-commit
PAYLOAD=$(python3 -c "import json;print(json.dumps({'tool_name':'Write','tool_input':{'file_path':'<issue-report-path-for-qa-role>','content':open('record.md').read()}}))")
printf '%s' "$PAYLOAD" | bash core/hooks/record-fields-gate.sh
```

### Observed
With `kind: coding-record` (spoofed — the record is qa's own, filed under this role's own report path): exit 0, no denial. The gate accepted `loop_state: landed` as terminal (coding-record's terminal set is `{"landed"}`) and never asked for next-steps or an open-finding resolution path.

With `kind: qa-record` (honest) and the identical body/loop_state otherwise unchanged: exit 2, denied — "next-steps (required because loop_state 'landed' is non-terminal — accepted terminal states: not-a-defect, verified-fixed, wont-fix); open-finding-resolution-path (...)".

### Expected
The gate should determine `kind` from something the acting role's own session cannot choose (e.g. the role->kind mapping, contract-fixed), or at minimum verify the self-declared `kind:` is consistent with CLAUDE_ROLE before trusting it — not accept an arbitrary attacker/session-controlled `kind:` value that widens or changes which loop_state values count as terminal for that role's record.
