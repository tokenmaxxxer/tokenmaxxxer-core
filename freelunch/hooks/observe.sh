#!/usr/bin/env bash
# observe.sh — PreToolUse telemetry (+ optional enforcement) for freelunch
# rule compliance. Reads the tool-call JSON from stdin, appends one JSONL line
# per Agent/Task/Workflow dispatch to $FREELUNCH_OBSERVE_LOG (default
# ~/.claude/freelunch-observe.jsonl), flagging syntactically checkable
# freelunch-NEVER violations:
#   sync_agent_dispatch — Agent/Task called with run_in_background: false
#   non_sonnet_worker   — Agent/Task not on Sonnet (no model: sonnet, and not
#                         subagent_type: freelunch-worker or
#                         freelunch:freelunch-worker with model unset)
# Default mode is observe-only (always allows). With FREELUNCH_ENFORCE=1 a
# flagged call is DENIED with a corrective reason; the logged row records
# "enforced": true. For an interactive session, denial converts the
# dispatch without losing work: a background dispatch + completion
# notification is a fine substitute for waiting synchronously there. That
# substitution is NOT available to a headless/single-shot session bound by
# contract v3 s22 (no later turn for the notification to land in), so
# sync_agent_dispatch is never enforced there — see the headless carve-out
# below. Kill switch: FREELUNCH_OFF=1 (no log, no deny).

# Normalize (lowercase, trim whitespace) before matching so common spelling
# variants (`False`, `OFF`, trailing/leading whitespace) resolve the same as
# their canonical form. An unrecognized value is never silently treated as
# "off": it warns on stderr and falls through to normal operation (logging
# continues) — fail-open to logging, never silent suppression.
_freelunch_off_raw="${FREELUNCH_OFF:-}"
_freelunch_off_norm="$(printf '%s' "$_freelunch_off_raw" | tr '[:upper:]' '[:lower:]' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
case "$_freelunch_off_norm" in
  ""|0|false|no|off) ;;
  1|true|yes|on) exit 0 ;;
  *) echo "freelunch: unrecognized FREELUNCH_OFF value '${_freelunch_off_raw}' — treating as not-off, logging will continue" >&2 ;;
esac
LOG="${FREELUNCH_OBSERVE_LOG:-$HOME/.claude/freelunch-observe.jsonl}"

# Capture the hook payload BEFORE anything else touches stdin.
PAYLOAD="$(cat 2>/dev/null || true)"

OBSERVE_PAYLOAD="$PAYLOAD" FREELUNCH_ENFORCE="${FREELUNCH_ENFORCE:-}" python3 -c '
import json, sys, time, os

log_path = sys.argv[1]
enforce = os.environ.get("FREELUNCH_ENFORCE") == "1"
try:
    payload = json.loads(os.environ.get("OBSERVE_PAYLOAD", ""))
except Exception as exc:
    # F6 (issue-305): a malformed/truncated payload previously left
    # neither a deny decision nor a log line -- the audit trail this file
    # exists to keep gained no row at all, indistinguishable from "nothing
    # was dispatched this turn." Log an anomaly row instead (never a deny
    # -- tool_name is unrecoverable from broken JSON) so the bypass at
    # least leaves a trace, same rationale as the log-unwritable case
    # below.
    try:
        os.makedirs(os.path.dirname(log_path), exist_ok=True)
        with open(log_path, "a") as f:
            f.write(json.dumps({
                "ts": time.strftime("%Y-%m-%dT%H:%M:%S%z"),
                "tool": "unknown",
                "violations": ["unparseable_payload"],
                "enforced": False,
                "parse_error": str(exc),
            }, ensure_ascii=False) + "\n")
    except Exception:
        pass
    sys.exit(0)

tool = payload.get("tool_name", "")
if tool not in ("Agent", "Task", "Workflow"):
    sys.exit(0)

# Headless carve-out (contract v3 s22): CLAUDE_CODE_ENTRYPOINT is set by the
# harness before the session'"'"'s own conversation begins, so it is not a
# signal a running session could spoof to dodge sync_agent_dispatch at will
# (warrant-hunt pre-mortem, docs/issue-116 proposal). Empirically confirmed
# this value is "sdk-cli" for a headless/single-shot invocation; "cli" is
# the interactive-terminal entrypoint. Anything else (a different SDK
# entrypoint, "remote", unset, or unrecognized) is treated as
# non-interactive-or-ambiguous and fails toward NOT denying, per the
# proposal'"'"'s own floor. tty state was evaluated and rejected as a signal
# here: this hook'"'"'s own stdout is captured by the harness to parse the
# permission-decision JSON in every invocation mode, so isatty() on it
# cannot discriminate interactive from headless for this specific hook.
entrypoint = os.environ.get("CLAUDE_CODE_ENTRYPOINT", "")
session_is_interactive = entrypoint == "cli"

inp = payload.get("tool_input") or {}
row = {
    "ts": time.strftime("%Y-%m-%dT%H:%M:%S%z"),
    "session": payload.get("session_id", ""),
    "tool": tool,
    "session_entrypoint": entrypoint,
    "violations": [],
}
if tool in ("Agent", "Task"):
    bg = inp.get("run_in_background")
    model = (inp.get("model") or "").strip().lower()
    agent_type = inp.get("subagent_type", "")
    row["background"] = bg
    row["model"] = inp.get("model", "")
    row["subagent_type"] = agent_type
    row["prompt_chars"] = len(inp.get("prompt", "") or "")
    if bg is False:
        row["violations"].append("sync_agent_dispatch")
    # Sonnet pin. Satisfied two ways: an explicit sonnet model, or the
    # freelunch-worker agent type whose frontmatter supplies sonnet when no
    # model override is passed. Any other agent type still passes as long as
    # it carries model: sonnet — the rule pins the model, not the agent type.
    # "sonnet", "claude-sonnet-5", "us.anthropic.claude-sonnet-…" are all the pin;
    # exact-matching "sonnet" logged legitimate dispatches as violations, which
    # quietly corrupts the record the stack uses to judge its own policies.
    # Same reasoning applies to agent_type: the harness registers this agent
    # under the plugin-namespaced "freelunch:freelunch-worker", but nothing
    # guarantees every context injects that prefix, so both the qualified and
    # legitimate unqualified spellings are recognized — exact-matching only
    # one form mis-flagged the other as non_sonnet_worker.
    if "sonnet" not in model and not (model == "" and agent_type in ("freelunch-worker", "freelunch:freelunch-worker")):
        row["violations"].append("non_sonnet_worker")
else:  # Workflow
    row["script_chars"] = len(inp.get("script", "") or "")
    row["named"] = inp.get("name", "")

# sync_agent_dispatch is always logged (full audit trail preserved above)
# but only ever contributes to enforcement in a session the entrypoint
# signal clearly marks interactive — a headless session obeying contract
# v3 s22 is never denied for making the one call shape s22 requires.
# non_sonnet_worker is untouched: it holds in every session type.
enforceable = list(row["violations"])
if "sync_agent_dispatch" in enforceable and not session_is_interactive:
    enforceable.remove("sync_agent_dispatch")
row["enforced"] = bool(enforce and enforceable)

try:
    os.makedirs(os.path.dirname(log_path), exist_ok=True)
    with open(log_path, "a") as f:
        f.write(json.dumps(row, ensure_ascii=False) + "\n")
except Exception as exc:
    # An empty observation log otherwise reads as "no dispatches happened".
    # Report once per session rather than letting the record go quiet.
    marker = log_path + ".unwritable"
    if not os.path.exists(marker):
        try:
            open(marker, "a").close()
        except Exception:
            pass
        print("freelunch: observation log %s is not writable (%s); dispatches are going "
              "unrecorded." % (log_path, exc), file=sys.stderr)

REASONS = {
    "sync_agent_dispatch": (
        "freelunch: synchronous Agent dispatch (run_in_background: false) is "
        "blocked in this interactive session — a synchronous call is the "
        "orchestrator idling. Re-issue the SAME Agent call with "
        "run_in_background: true; you will be notified on completion. (A "
        "headless/single-shot session bound by contract v3 s22 is not "
        "denied by this check: waiting synchronously is the only way such "
        "a session can consume a delegated result before its turn ends.)"
    ),
    "non_sonnet_worker": (
        "freelunch: every worker runs on Sonnet (measured: an identical 12-worker "
        "fan-out took 78s on Haiku vs 21s on Sonnet; per-request latency dominates). "
        "Re-issue the SAME call with model: sonnet, or with subagent_type: "
        "freelunch:freelunch-worker and no model override. Any agent type is fine as long as "
        "the model is Sonnet."
    ),
}

if row["enforced"]:
    reason = " ".join(REASONS[v] for v in enforceable if v in REASONS)
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": (
                reason + " Do not drop or shrink the task in response to this denial."
            ),
        }
    }))
' "$LOG" 2>/dev/null
exit 0
