#!/usr/bin/env bash
# warrant/hooks/hunt-guard.sh + hunt-state.sh, exercised as real subprocesses.
#
# issue-200: the count/lock pair used to live at the worktree root
# (.warrant-hunt.count / .warrant-hunt.lock), so parallel branches committed
# divergent counter values and conflicted. This asserts the relocation to
# .git/warrant/ holds — worktree-clean after a dispatch/release cycle — plus
# the empty-state case (no prior run) and that issue-scoped hunt-report paths
# for two concurrent issues can never collide.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
. "$HERE/../../../core/hooks/tests/_tmp.sh"
GUARD="$HERE/../hunt-guard.sh"
STATE="$HERE/../hunt-state.sh"
CORE_ROOT="$(cd "$HERE/../../../core" && pwd -P)"

pass=0
fail=0

report() {
  if [ "$2" = "$1" ]; then
    pass=$((pass + 1)); printf 'ok     %-34s %s\n' "$3" "$2"
  else
    fail=$((fail + 1)); printf 'FAIL   %-34s want=%s got=%s\n' "$3" "$1" "$2"
  fi
}

dispatch_payload='{"tool_name":"Agent","tool_input":{"subagent_type":"warrant-hunter","prompt":"probe"}}'

# --- worktree-clean: dispatch, then release, leaves nothing under the worktree ---
mktd
git init -q "$td"
printf '%s' "$dispatch_payload" | env CLAUDE_PROJECT_DIR="$td" CLAUDE_PLUGIN_ROOT_CORE="$CORE_ROOT" \
    /bin/bash "$GUARD" >/dev/null 2>&1
dispatch_rc=$?
report 0 "$dispatch_rc" worktree-clean-dispatch-allowed

worktree_hits="$(find "$td" -maxdepth 1 -name '.warrant-hunt.*' 2>/dev/null | wc -l | tr -d ' ')"
report 0 "$worktree_hits" worktree-clean-no-root-state-file

gitdir_hits="$(find "$td/.git/warrant" -maxdepth 1 -name '.warrant-hunt.*' 2>/dev/null | wc -l | tr -d ' ')"
report 2 "$gitdir_hits" worktree-clean-lock-and-count-under-gitdir

env CLAUDE_PROJECT_DIR="$td" CLAUDE_PLUGIN_ROOT_CORE="$CORE_ROOT" /bin/bash "$STATE" release >/dev/null 2>&1
lock_after_release="$(find "$td/.git/warrant" -maxdepth 1 -name '.warrant-hunt.lock' 2>/dev/null | wc -l | tr -d ' ')"
report 0 "$lock_after_release" release-clears-lock-under-gitdir

git_status_root_hits="$(git -C "$td" status --porcelain | grep -c '\.warrant-hunt' || true)"
report 0 "$git_status_root_hits" worktree-clean-git-status-silent

rm -rf "$td"

# --- disjoint paths: two concurrent issues never produce the same hunt-report path ---
# Mirrors the derivation rule stated in warrant/agents/warrant-hunter.md and
# warrant/hooks/directive.sh: docs/issue-<n>/proposals/... -> issue-scoped
# docs/issue-<n>/reports/hunt-<slug>.md; no issue segment -> unchanged
# docs/reports/<date>-hunt-<slug>.md.
hunt_report_path() {
  proposal_path="$1"; date="$2"; slug="$3"
  case "$proposal_path" in
    docs/issue-*/proposals/*)
      n="${proposal_path#docs/issue-}"
      n="${n%%/*}"
      echo "docs/issue-${n}/reports/hunt-${slug}.md"
      ;;
    *)
      echo "docs/reports/${date}-hunt-${slug}.md"
      ;;
  esac
}

path_a="$(hunt_report_path "docs/issue-5/proposals/same-topic.md" 2026-08-11 same-topic)"
path_b="$(hunt_report_path "docs/issue-9/proposals/same-topic.md" 2026-08-11 same-topic)"
[ "$path_a" != "$path_b" ] && disjoint=yes || disjoint=no
report yes "$disjoint" disjoint-report-paths-same-date-slug

path_flat_a="$(hunt_report_path "docs/proposals/2026-08-11-same-topic.md" 2026-08-11 same-topic)"
path_flat_b="$(hunt_report_path "docs/proposals/2026-08-11-same-topic.md" 2026-08-11 same-topic)"
report "$path_flat_a" "$path_flat_b" flat-layout-path-unchanged

# --- empty state: never run before, no crash, cap check falls through to 0 used ---
mktd
git init -q "$td"
in_hunt_payload='{"tool_name":"Bash","tool_input":{}}'
printf '%s' "$in_hunt_payload" | env CLAUDE_PROJECT_DIR="$td" CLAUDE_PLUGIN_ROOT_CORE="$CORE_ROOT" \
    WARRANT_IN_HUNT=1 /bin/bash "$GUARD" >/dev/null 2>&1
empty_state_rc=$?
report 0 "$empty_state_rc" empty-state-no-crash-no-cap-hit

no_lock_created="$(find "$td" "$td/.git" -maxdepth 2 -name '.warrant-hunt.lock' 2>/dev/null | wc -l | tr -d ' ')"
report 0 "$no_lock_created" empty-state-holds-no-lock

rm -rf "$td"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
