---
proposal: docs/issue-63/proposals/2026-08-08-mechanize-warrant-hunt-budget-and-manifest.md
---

# Hunt record — mechanize-warrant-hunt-budget-and-manifest

## after-proposal — stance: assume this change and another plugin's rule cancel each other

Verdict: FINDING — the proposed per-hunter budget refusal in hunt-guard.sh is silently cancelled by that same hook's existing early-return, which unconditionally allows every tool call except Agent/Task/Workflow before the WARRANT_IN_HUNT check is ever reached
Kind: composition
Seed: docs/issue-63/proposals/2026-08-08-mechanize-warrant-hunt-budget-and-manifest.md item (3): "have warrant/hooks/hunt-guard.sh store a cap alongside its existing lock timestamp and refuse (exit 2) a hunter's own next tool call once elapsed > cap, active only when WARRANT_IN_HUNT=1"
cap_seconds: 60
tier: default
diff_stat_lines: docs-only
started_at: 2026-08-08T00:00:00Z
ended_at: 2026-08-08T00:06:00Z

### Reproduce

    export CLAUDE_PLUGIN_ROOT_CORE="$(pwd)/core"
    export WARRANT_IN_HUNT=1
    echo '{"tool_name":"Bash","tool_input":{"command":"ls"}}' | bash warrant/hooks/hunt-guard.sh
    echo "exit=$?"

Current warrant/hooks/hunt-guard.sh structure (unchanged by this docs-only diff):

    tool = event.get("tool_name") or ""
    if tool not in ("Agent", "Task", "Workflow"):
        allow()
    ...
    if os.environ.get("WARRANT_IN_HUNT") == "1":
        print("warrant: a hunter may not dispatch agents...", file=sys.stderr)
        sys.exit(2)

### Observed
`exit=0` — the Bash call is allowed unconditionally, regardless of WARRANT_IN_HUNT or elapsed time, because the `tool not in ("Agent","Task","Workflow")` early-return fires first and the script never reaches the WARRANT_IN_HUNT / budget logic for a hunter's actual (non-dispatch) tool calls such as Bash, Read, Write.

### Expected
Per the proposal, a hunter's own next tool call (which, since a hunter "may not dispatch agents", must be a Bash/Read/Write/etc. call) should be refused with exit 2 once elapsed > cap while WARRANT_IN_HUNT=1. The existing nesting-guard's early allow() for all non-Agent/Task/Workflow tools makes that refusal unreachable dead code unless the early-return is restructured — the two rules ("allow anything that isn't a dispatch" and "refuse a hunter's own next call past budget") cancel each other as currently composed in the same hook.
