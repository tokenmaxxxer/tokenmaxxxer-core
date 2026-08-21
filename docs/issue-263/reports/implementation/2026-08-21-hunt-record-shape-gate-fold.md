---
proposal: docs/issue-263/proposals/record-shape-gate-fold.md
---

# Hunt record — record-shape-gate-fold

## after-proposal — stance 1: Bash-tool-write path — fail closed vs silently pass on config-dispatch matched rows

Verdict: FINDING — the config-driven CHECKERS dispatch in record-shape-gate.sh silently ALLOWS (exit 0) a Bash-tool write that matches a governed row's target_path_regex, instead of denying like its two sibling gates (citation-gate.sh, ordering-norm-gate.sh) do for the identical situation.
Kind: composition
Seed: core/hooks/record-shape-gate.sh (CHECKERS dispatch block, lines ~281-332), compared against core/hooks/citation-gate.sh and core/hooks/ordering-norm-gate.sh which record-shape-gate.sh's own header comment says it mirrors
cap_seconds: unknown (not provided by dispatcher)
tier: default
diff_stat_lines: unknown (not provided by dispatcher)
started_at: 2026-08-21T00:00:00Z
ended_at: 2026-08-21T00:20:00Z

### Reproduce
```
export CLAUDE_ROLE=accessibility
export CLAUDE_PROJECT_DIR="$(pwd)"
CMD='echo "no required key here" > docs/issue-10/proposals/gate-remediation.md'
payload=$(python3 -c "import json;print(json.dumps({'tool_name':'Bash','tool_input':{'command':'''$CMD'''}}))")
echo "$payload" | bash core/hooks/record-shape-gate.sh; echo "exit=$?"
```
Contrast with the equivalent Write-tool payload for the same file/content, which is correctly denied (exit 2) by the same gate/row (`wcag-em-gate/hooks/methodology-gate.sh`, check_type `checklist_entry_fields`, required_keys `["fail"]`).

### Observed
`exit=0` — the gate silently allows the Bash write, even though the resulting file content is missing the required `fail` key and would be denied if written via the Write tool.

citation-gate.sh and ordering-norm-gate.sh, for the exact same shape of situation (Bash command matches a governed row's target_path_regex, content unreconstructible), explicitly `deny(...)` with an "unverifiable write" message (see citation-gate.sh lines 122-129, ordering-norm-gate.sh lines 344-348) — i.e. they fail closed.

record-shape-gate.sh's own dispatch instead does:
```python
if tool == "Bash":
    sys.exit(0)  # cannot reconstruct a Bash-written file's content — same fail-open-on-Bash as before dispatch existed
```
unconditionally allowing, regardless of whether any matched row is meant to be a hard content gate. The comment justifies this as "same fail-open-on-Bash as before dispatch existed," but the two sibling folds this file's own header claims to mirror do not fail open here — they fail closed.

### Expected
A Bash-tool command whose write target matches a config row's target_path_regex should be denied (fail closed) with an "unverifiable write" message, consistent with citation-gate.sh and ordering-norm-gate.sh, instead of being silently allowed to bypass the checklist/section/token checks entirely.
