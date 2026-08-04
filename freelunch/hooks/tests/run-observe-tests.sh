#!/usr/bin/env bash
# observe.sh's sync_agent_dispatch/non_sonnet_worker enforcement, exercised
# as a real subprocess with a synthetic PreToolUse payload.
#
# The rule under test (contract v3 s22 vs. freelunch's own enforcement,
# docs/issue-116 proposal "What will be done" item 1): under
# FREELUNCH_ENFORCE=1, a synchronous Agent/Task dispatch
# (run_in_background: false) is denied only when the hook's own inherited
# CLAUDE_CODE_ENTRYPOINT signal clearly marks the session interactive
# ("cli"). Anything else — the confirmed headless value "sdk-cli", an
# unset/unrecognized value — fails toward NOT denying, so a headless
# session obeying contract v3 s22 is never blocked from the one call shape
# s22 requires. The violation is still logged either way (full audit
# trail); non_sonnet_worker is untouched and denies in every session type.
#
# want: "allow" (no deny JSON on stdout) | "deny" (deny JSON on stdout)
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
OBS="$HERE/../observe.sh"
pass=0
fail=0

report() {
  if [ "$2" = "$1" ]; then
    pass=$((pass + 1)); printf 'ok     %-42s %s\n' "$3" "$2"
  else
    fail=$((fail + 1)); printf 'FAIL   %-42s want=%s got=%s\n' "$3" "$1" "$2"
  fi
}

# run <want> <name> <entrypoint> <background> <model> [subagent_type]
# Sets globals $got and $row as a side effect (last-run) — never call this
# inside `$(...)`: that forks a subshell, and this function's `report` call
# updates $pass/$fail in that subshell only, silently dropping the count in
# the parent (the exact `cd ""` class of sandbox-only bug _tmp.sh documents
# for mktemp; caught here in review before landing).
run() {
  want="$1"; name="$2"; entrypoint="$3"; bg="$4"; model="$5"; agent_type="${6:-}"
  # -p "${TMPDIR:-/tmp}" is not optional on macOS: bare `mktemp` ignores
  # $TMPDIR and resolves through confstr(_CS_DARWIN_USER_TEMP_DIR) to
  # /var/folders/.../T, a path a role session's sandbox denies writing to
  # (core/hooks/tests/_tmp.sh's own note, issue-53/#57).
  log="$(mktemp -p "${TMPDIR:-/tmp}")"
  input='{"run_in_background":'"$bg"',"model":"'"$model"'","subagent_type":"'"$agent_type"'"}'
  payload='{"tool_name":"Agent","tool_input":'"$input"',"session_id":"t1"}'
  out="$(printf '%s' "$payload" \
    | CLAUDE_CODE_ENTRYPOINT="$entrypoint" FREELUNCH_ENFORCE=1 FREELUNCH_OBSERVE_LOG="$log" \
      /bin/bash "$OBS" 2>/dev/null)"
  case "$out" in
    *'"permissionDecision":"deny"'* | *'"permissionDecision": "deny"'*) got=deny ;;
    *) got=allow ;;
  esac
  row="$(cat "$log" 2>/dev/null)"
  rm -f "$log"
  report "$want" "$got" "$name"
}

# --- requirement 1: headless carve-out on sync_agent_dispatch -------------
run allow headless-sync-dispatch-not-enforced sdk-cli false sonnet
row_headless="$row"
run deny interactive-sync-dispatch-still-denied cli false sonnet
row_interactive="$row"
run allow ambiguous-entrypoint-sync-dispatch-not-enforced "" false sonnet

# full audit trail: even when not enforced, the row still records the
# violation and the entrypoint signal that suppressed enforcement.
case "$row_headless" in
  *'"sync_agent_dispatch"'*'"enforced": false'*|*'"sync_agent_dispatch"'*'"enforced":false'*)
    pass=$((pass + 1)); printf 'ok     %-42s %s\n' headless-violation-still-logged yes ;;
  *)
    fail=$((fail + 1)); printf 'FAIL   %-42s %s\n' headless-violation-still-logged "row=$row_headless" ;;
esac
case "$row_interactive" in
  *'"enforced": true'*|*'"enforced":true'*)
    pass=$((pass + 1)); printf 'ok     %-42s %s\n' interactive-violation-enforced-true yes ;;
  *)
    fail=$((fail + 1)); printf 'FAIL   %-42s %s\n' interactive-violation-enforced-true "row=$row_interactive" ;;
esac

# --- non_sonnet_worker: unchanged in every session type --------------------
run deny  non-sonnet-worker-denied-headless    sdk-cli true haiku
run deny  non-sonnet-worker-denied-interactive cli     true haiku
run allow sonnet-worker-allowed-headless       sdk-cli true sonnet
run allow freelunch-worker-agent-type-allowed  sdk-cli true "" freelunch:freelunch-worker

printf '\n== %d passed, %d failed ==\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
