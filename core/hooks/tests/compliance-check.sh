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
# actually wired into a hooks.json, not files whose name happens to match
# a glob. A filename rule is always one un-anticipated name away from
# missing the next wired script (confirmed: hunt-guard.sh and gh-guard.sh
# are both PreToolUse-wired but neither matches '*-gate.sh').
#
# Every event type, not PreToolUse only (issue-142 review): the kill-switch
# checks below apply to any hook script with an *_OFF escape hatch, and a
# SessionStart/UserPromptSubmit script (state.sh, directive.sh) is exactly
# as exposed to the fail-open case-statement bug as a PreToolUse gate is —
# restricting collection to PreToolUse left those scripts entirely
# unscanned, so a re-introduced kill-switch idiom there passed silently
# (verified: appending the old idiom to warrant/hooks/state.sh, a
# SessionStart hook, did not change compliance-check's rc under the prior
# PreToolUse-only scope).
gates=""
hooks_jsons="$(find "$dir" -maxdepth 3 -type f -name 'hooks.json' 2>/dev/null || true)"
while IFS= read -r hj; do
  [ -n "$hj" ] || continue
  hj_dir="$(cd "$(dirname "$hj")" && pwd -P)"
  # Extract every command string regardless of which event block it's in.
  # hooks.json here is small and flat enough that a line-scoped grep is
  # sufficient (compliance-check.sh already relies on grep-based structural
  # checks elsewhere in this file rather than a JSON parser dependency).
  while IFS= read -r line; do
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

# No hooks.json at all (a bare hooks/ directory, or a fixture/test-only tree)
# is not the same as "registered and found to be empty" — falling through to
# exit 0 in that case would let a script sit un-scanned forever simply because
# nobody wired a hooks.json next to it yet. Fall back to every *.sh file
# directly under $dir (non-recursive: this is the "no registration to read"
# case, not a license to walk an arbitrary tree).
if [ -z "$gates" ] && [ -z "$hooks_jsons" ]; then
  gates="$(find "$dir" -maxdepth 1 -type f -name '*.sh' 2>/dev/null | sort -u || true)"
fi

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

  # issue-142 review: the check above only fires when gate_kill_switch_active
  # is ABSENT from the file, so a re-introduced idiom sitting next to an
  # already-migrated call (e.g. appended below the canonical
  # `gate_kill_switch_active ... || { trap - EXIT; exit 0; }` line) passed
  # silently — verified live: rc stayed 0 after appending the old case block
  # to an already-migrated warrant hook. Match the literal fail-open branch
  # shape itself, independent of what else the file also does. Joined onto
  # one line first (warrant-hunter finding, issue-142 review round 2): the
  # branch marker, `exit 0`, and `;;` are just as often written across
  # separate physical lines (`*)` / `exit 0` / `;;` each on their own line)
  # as on one — a single-line-anchored regex silently missed that shape.
  if tr '\n' ' ' < "$f" | grep -qE '\*\)[[:space:]]*exit[[:space:]]+0[[:space:]]*;;'; then
    reasons+=("contains a hand-rolled '*) exit 0 ;;' case branch — the issue-72-confirmed fail-open kill-switch idiom (any unrecognized value silently disables the hook), even alongside a canonical gate_kill_switch_active call elsewhere in the file; remove the hand-rolled case statement and rely on gate_kill_switch_active (gate-lib.sh) exclusively")
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

  # issue-142/C2: a gate that writes scratch state to disk at request time
  # (mktemp in its own hot path, not a test harness) false-DENIES every call
  # under a sandbox whose platform tmp dir is unwritable — the erm-order-gate
  # class. The canonical fix is to keep the gate's judge in-memory (stdin/heredoc
  # to python3, as scope-gate.sh/hunt-guard.sh already do) instead of a scratch file.
  if grep -qE '(^|[^A-Za-z_#])mktemp\b' "$f"; then
    reasons+=("calls mktemp in the gate's own request-time path — false-DENIES under a sandbox with an unwritable platform tmp dir; pass the payload to python3 in-memory (heredoc/stdin) instead of a scratch file")
  fi

  # issue-142/C3: a gate that only recognizes tool_name Write/Edit/MultiEdit/
  # NotebookEdit and never even mentions Bash is blind to the same target
  # written through the Bash tool (echo/redirect, tee, sed -i) — verified live
  # as an ALLOW on a gated path. gate_bash_write_targets (gate-lib.sh) is the
  # canonical token-scan a gate adds to also see a Bash-based write; a gate
  # that deliberately punts Bash writes to another gate says so in a comment,
  # which this check treats as evidence of a considered decision, not a gap.
  if grep -qE '"(Write|Edit|MultiEdit|NotebookEdit)"' "$f" \
     && ! grep -q 'gate_bash_write_targets' "$f" \
     && ! grep -qi 'bash' "$f"; then
    reasons+=("recognizes Write/Edit/MultiEdit/NotebookEdit but never mentions Bash at all — likely bypassable via a Bash echo/redirect, tee, or sed -i onto the same gated path; add gate_bash_write_targets (gate-lib.sh) coverage or document why Bash writes are out of this gate's scope")
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
