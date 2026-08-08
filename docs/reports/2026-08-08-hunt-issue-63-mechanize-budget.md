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

## before-landing — stance 2: assume this change's own guard goes silent when its own input is malformed — make it go silent.

Verdict: FINDING — hunt-guard.sh's budget check silently no-ops (allows unbounded hunter turns with zero stderr warning) when the `.warrant-hunt.lock` cap field is non-numeric, because `gate_budget_exceeded` fail-opens on malformed input and the guard never distinguishes "malformed cap" from "not exceeded".
Kind: silent-failure
Seed: core/hooks/lib/gate-lib.sh (+gate_budget_exceeded), warrant/hooks/hunt-guard.sh (+budget-check block reading `.warrant-hunt.lock`'s second field)
cap_seconds: 120
tier: default
diff_stat_lines: 61
started_at: 2026-08-08T18:23:29+09:00
ended_at: 2026-08-08T18:44:00+09:00

### Reproduce
```
source core/hooks/lib/gate-lib.sh
now=$(date +%s); started=$(( now - 999999 ))
printf "%s notanumber some hunt prompt\n" "$started" > lock
read -r s c _ < lock
gate_budget_exceeded "$s" "$c"; echo $?   # -> 1 (not-exceeded)
```
And end-to-end through the real hook (with CLAUDE_PROJECT_DIR pointed at a
throwaway git repo containing only `.warrant-hunt.lock` with content
`"<9999999-seconds-old-epoch> notanumber some hunt prompt"`):
```
WARRANT_IN_HUNT=1 CLAUDE_PLUGIN_ROOT_CORE=<repo>/core \
  bash <repo>/warrant/hooks/hunt-guard.sh <<< '{"tool_name":"Bash","hook_event_name":"PreToolUse","tool_input":{"command":"echo hi"},"transcript_path":"x"}'
```

### Observed
`gate_budget_exceeded` returns 1 (not exceeded) whenever the lock's second
field is non-numeric, regardless of how old `started` actually is (tested at
999999s = ~11.5 days). The end-to-end hook call exits 0 with **no stderr
output at all** — the hunter is silently allowed to continue past any real
cap, and nothing in the transcript or logs indicates the budget check ever
ran or was skipped. This is reachable in practice: the lock's second field
is `${WARRANT_HUNT_CAP_SECONDS:-0}` written verbatim by the Agent/Task
dispatch path with no numeric validation, so any caller that sets
`WARRANT_HUNT_CAP_SECONDS` to an empty string, a path, or any non-digit
value (a plausible mistake in whatever orchestration wires this env var)
poisons the lock for the entire hunt and the guard never says so.

### Expected
A malformed cap in the guard's own lock file — the guard's own record of its
own state — should not be treated the same as "budget not exceeded yet". At
minimum it should fail closed (treat malformed cap as exceeded, since a
budget that cannot be read cannot be trusted) or emit a visible warning
before falling back to fail-open, matching the file's stated convention only
for genuinely absent/untrusted external input, not for its own corrupted
bookkeeping.
