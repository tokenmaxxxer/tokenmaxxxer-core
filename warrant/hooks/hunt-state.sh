#!/usr/bin/env bash
# Maintains the two files hunt-guard.sh reads. Without this, the guard's own
# limits are the state nothing maintains: the lock got written and never cleared,
# so the second of the directive's two dispatches was always refused, and the
# count only ever climbed, so WARRANT_HUNT_MAX was a repository-lifetime cap
# wearing the name "session cap".
#
#   release  (SubagentStop)  a subagent finished — drop the lock
#   reset    (SessionStart)  new session — drop the lock and zero the count
#
# `release` is approximate on purpose. SubagentStop does not say WHICH subagent
# stopped, so an unrelated worker finishing can drop a live hunter's lock. That
# degrades single-flight from a guarantee to the common case — it never becomes
# unbounded, because the thing that actually bounds cost is the session cap, and
# that is untouched. An exact release would need the agent's identity in the
# stop payload; claiming exactness without it would be the same kind of lie the
# header of hunt-guard.sh used to tell.
#
# Kill switch: export WARRANT_OFF=1

. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)}/hooks/lib/gate-lib.sh" || { echo "hunt-state.sh: cannot source gate-lib.sh" >&2; exit 2; }
gate_trap_fail_closed
set -uo pipefail
gate_kill_switch_active "${WARRANT_OFF:-}" || { trap - EXIT; exit 0; }

# State-dir resolution is shared with hunt-guard.sh and must stay identical:
# the .git dir (never the worktree, so it is never staged/diffed/committed),
# with a "warrant" subdirectory. A directory that is not a repository still
# gets bounded — the project directory stands in, matching the guard's fallback.
proj="${CLAUDE_PROJECT_DIR:-$PWD}"
gitdir="$(git -C "$proj" rev-parse --git-dir 2>/dev/null)"
if [ -n "$gitdir" ]; then
  case "$gitdir" in
    /*) : ;;
    *) gitdir="$proj/$gitdir" ;;
  esac
  statedir="$gitdir/warrant"
else
  statedir="$proj"
fi
[ -d "$statedir" ] || { trap - EXIT; exit 0; }

case "${1:-release}" in
  release)
    rm -f "$statedir/.warrant-hunt.lock" 2>/dev/null
    ;;
  reset)
    rm -f "$statedir/.warrant-hunt.lock" "$statedir/.warrant-hunt.count" 2>/dev/null
    ;;
esac

exit 0
