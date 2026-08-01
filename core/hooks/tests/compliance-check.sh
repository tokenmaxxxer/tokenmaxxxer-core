#!/usr/bin/env bash
# Gate-house standard compliance detector (issue-72). Modeled on
# stub-check.sh's two-mode pattern: absence-based checks for anything a
# gate should call through gate-lib.sh instead of hand-rolling, plus a
# structural check (source line + expected function calls present) for
# gate-lib.sh consumers, the same shape stub-check.sh already uses for
# directive.sh/role-directive.sh.
#
# CANON EXECUTION MODEL: this script is core canon, referenced (never
# vendored) exactly like stub-check.sh — invoked against a rulebook's own
# hooks/ directory:
#   "${CORE_PLUGIN_ROOT:-$CLAUDE_PLUGIN_ROOT/../core}/hooks/tests/compliance-check.sh" "$(dirname "$0")/.."
#
# Usage: compliance-check.sh [hooks-dir]
set -uo pipefail

dir="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." 2>/dev/null && pwd -P)}"
[ -d "$dir" ] || { echo "compliance-check: no such directory: $dir" >&2; exit 2; }
rc=0

# Scope by registration, not by filename (issue-78): scan every script
# actually wired into a hooks.json's PreToolUse array, not files whose name
# happens to match a glob. A filename rule is always one un-anticipated
# name away from missing the next wired script (confirmed: hunt-guard.sh
# and gh-guard.sh are both PreToolUse-wired but neither matches
# '*-gate.sh').
gates=""
hooks_jsons="$(find "$dir" -maxdepth 3 -type f -name 'hooks.json' 2>/dev/null || true)"
while IFS= read -r hj; do
  [ -n "$hj" ] || continue
  hj_dir="$(cd "$(dirname "$hj")" && pwd -P)"
  # Extract command strings inside the PreToolUse block only. hooks.json
  # here is small and flat enough that a line-scoped grep is sufficient
  # (compliance-check.sh already relies on grep-based structural checks
  # elsewhere in this file rather than a JSON parser dependency).
  in_pretooluse=0
  while IFS= read -r line; do
    case "$line" in
      *'"PreToolUse"'*) in_pretooluse=1; continue ;;
      *'"SessionStart"'*|*'"SubagentStop"'*|*'"UserPromptSubmit"'*|*'"Stop"'*|*'"PostToolUse"'*)
        in_pretooluse=0; continue ;;
    esac
    [ "$in_pretooluse" = 1 ] || continue
    case "$line" in
      *'"command"'*)
        cmd="${line#*:}"
        cmd="${cmd#*\"}"
        cmd="${cmd%\"*}"
        cmd="${cmd%%\"*}"
        # Strip a leading ${CLAUDE_PLUGIN_ROOT}/ or bash-invocation prefix,
        # leaving the script's path relative to the hooks.json's directory
        # (hooks.json lives at <plugin>/hooks/hooks.json; commands are
        # written as ${CLAUDE_PLUGIN_ROOT}/hooks/<name>.sh, i.e. relative
        # to <plugin>, one level above hooks.json itself).
        script="${cmd#\$\{CLAUDE_PLUGIN_ROOT\}/}"
        script="${script#bash }"
        case "$script" in
          *.sh)
            candidate="$hj_dir/../$script"
            if [ -f "$candidate" ]; then
              resolved_path="$(cd "$(dirname "$candidate")" && pwd -P)/$(basename "$candidate")"
              gates="${gates}${gates:+$'\n'}${resolved_path}"
            fi
            ;;
        esac
        ;;
    esac
  done < "$hj"
done <<< "$hooks_jsons"
gates="$(printf '%s\n' "$gates" | grep -v '^[[:space:]]*$' | sort -u || true)"

if [ -z "$gates" ]; then
  echo "compliance-check: no PreToolUse-wired scripts found under $dir — nothing to check"
  exit 0
fi

while IFS= read -r f; do
  [ -n "$f" ] || continue
  reasons=()

  # A gate that reads a kill switch from an env var but does not source
  # gate-lib.sh's gate_kill_switch_active is either hand-rolling the
  # off-spelling case statement (the issue-72-confirmed fail-open shape:
  # "case ... in \"\"|0|false|no|off) ;; *) exit 0 ;; esac", which disables
  # on ANY unrecognized value) or has no kill switch at all — this check
  # only fires when the file plausibly has one (mentions "_OFF" as an env
  # var read).
  if grep -qE '\$\{[A-Z_]+_OFF:-' "$f" && ! grep -q 'gate_kill_switch_active' "$f"; then
    reasons+=("reads a *_OFF kill-switch env var but does not call gate_kill_switch_active — likely a hand-rolled case statement with the confirmed fail-open bug (unrecognized value disables the gate)")
  fi

  # A gate that reconstructs Edit/MultiEdit content (does its own
  # old_string.replace(...,1)-shaped substitution in Python) without
  # sourcing gate-lib.py's gate_reconstruct_write is very likely ignoring
  # replace_all — the issue-72-confirmed bug.
  if grep -qE '\.replace\([A-Za-z_][A-Za-z0-9_]*,\s*[A-Za-z_][A-Za-z0-9_]*(,\s*1)?\)' "$f" \
     && ! grep -q 'gate_reconstruct_write' "$f"; then
    reasons+=("reconstructs Edit/MultiEdit content via its own .replace(...) call instead of gate_lib.gate_reconstruct_write — likely ignores replace_all")
  fi

  # A gate that sources gate-lib.sh with no `||` fallback on the same
  # statement is fail-open on a missing core (issue-75-confirmed): a
  # failed source runs no code, so gate_kill_switch_active is undefined
  # afterward, returns 127, and every documented
  # "gate_kill_switch_active ... || { exit 0; }" call site reads that as
  # the kill switch being off — silently allowing everything.
  if grep -q 'gate-lib\.sh"$' "$f" && ! grep -qE 'gate-lib\.sh"[[:space:]]*\|\|' "$f"; then
    reasons+=("sources gate-lib.sh with no || guard on the same line — fail-open when core is unreachable (missing CLAUDE_PLUGIN_ROOT_CORE)")
  fi

  if [ "${#reasons[@]}" -gt 0 ]; then
    echo "compliance-check: FAIL — $f:" >&2
    for r in "${reasons[@]}"; do echo "  - $r" >&2; done
    rc=1
  else
    echo "compliance-check: ok — $f"
  fi
done <<< "$gates"

exit "$rc"
