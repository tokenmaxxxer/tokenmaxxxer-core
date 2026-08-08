#!/usr/bin/env bash
# Sourceable library: the gate-house standard (issue-72). A rulebook's own
# PreToolUse gate sources this file and calls its gate_* functions instead
# of hand-rolling the trap/kill-switch/path-normalize/reconstruct/deny
# machinery every core/hooks/*.sh gate independently re-derived (issue-72
# survey: same shapes, 2-3 different idioms each, one confirmed live bug).
# Reference only, never copy (docs/handbooks/canon-scripts.md) — added to
# core/hooks/tests/canon-manifest.txt so stub-check.sh catches a vendored
# copy.
#
# Usage, from a gate script. The source line MUST carry an `||` guard
# (issue-75-confirmed defect: an unguarded source that fails when core is
# unreachable runs no code — including no gate_* function definition —
# after which every documented `gate_kill_switch_active ... || { exit 0; }`
# call site reads the resulting "command not found" (127) as the kill
# switch being off, silently allowing everything). Fail closed instead:
#
#   . "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)}/hooks/lib/gate-lib.sh" || { echo "<gate-name>.sh: cannot source gate-lib.sh" >&2; exit 2; }
#   gate_trap_fail_closed
#   set -uo pipefail
#   gate_kill_switch_active CORE_OFF || { trap - EXIT; exit 0; }
#   ...
#   gate_deny "some-gate" "reason text"     # writes to stderr, exit 2
#   gate_allow                              # exit 0
#
# GATE_LIB_PY resolves to this file's sibling gate-lib.py so a gate's own
# Python payload can load it:
#
#   import importlib.util, os
#   _spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
#   gate_lib = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(gate_lib)

GATE_LIB_SH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
export GATE_LIB_PY="$GATE_LIB_SH_DIR/gate-lib.py"

# gate_trap_fail_closed — install the one canonical fail-closed EXIT trap.
# Claude Code treats any hook exit other than 0/2 as non-blocking
# (fail-open); this remaps every other exit to 2. Call this as the very
# first statement in a gate script, before `set -uo pipefail`, so a syntax
# error or unset-variable abort on the next line is still caught.
gate_trap_fail_closed() {
  trap 'rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then
    echo "fail-closed: gate aborted (rc=$rc)" >&2
    exit 2
  fi' EXIT
}

# gate_kill_switch_active <value> — the house kill-switch convention:
# unrecognized value = ACTIVE (the fixed default; issue-72 survey section 2
# found every kill switch in core's own canon did the opposite). The
# original idiom, `case ... in ""|0|false|no|off) ;; *) exit 0 ;; esac`,
# treated empty/"0"/"false"/"no"/"off" as "stay active" (correct) but
# treated EVERY other value — including the intended on-spellings
# (1/true/yes/on) AND any unrecognized garbage like a typo — identically as
# "disable." That conflated "the switch was deliberately turned on" with
# "the switch holds an unrecognized value," which is the fail-open bug: a
# stray typo in an env var silently disabled the gate. The fix narrows the
# disabling set to only the recognized on-spellings; every other value,
# recognized-off or unrecognized, stays active.
#
# Returns 0 (true, "stay active") for empty/unset, a recognized
# off-spelling, or anything unrecognized. Returns 1 (false, "disable")
# only for a recognized on-spelling (1/true/yes/on, case-insensitive).
#
#   gate_kill_switch_active "${CORE_OFF:-}" || { trap - EXIT; exit 0; }
gate_kill_switch_active() {
  local v
  v="$(printf '%s' "${1:-}" | tr '[:upper:]' '[:lower:]')"
  case "$v" in
    1|true|yes|on) return 1 ;;
    *) return 0 ;;
  esac
}

# gate_deny <role-or-gate-name> <message> — stderr-only deny protocol
# (issue-72 survey section 4: already-uniform in core, codified here).
gate_deny() {
  echo "${1:-gate}: refused — $2" >&2
  exit 2
}

gate_allow() {
  exit 0
}

# gate_bash_write_targets <command> — extract path-shaped tokens from a
# Bash tool_input.command string, the token-scan technique already used by
# approval-gate.sh/board-gate.sh (issue-72 survey section 7), so a gate
# that only matched Write/Edit/MultiEdit/NotebookEdit (like
# record-fields-gate.sh before this migration) can also see a Bash-based
# file write. Prints one candidate token per line; caller applies its own
# path pattern to each.
gate_bash_write_targets() {
  printf '%s\n' "$1" | grep -oE '[[:alnum:]_./~$-]+' || true
}

# gate_budget_exceeded <started_epoch> <cap_seconds> [<now_epoch>] —
# returns 0 (true, exceeded) when now - started > cap, 1 otherwise.
# now_epoch defaults to `date +%s` when omitted (the optional third arg
# exists solely so tests can pass fixed timestamps instead of racing the
# real clock). Malformed numeric input (non-integer) returns 1
# (not-exceeded / fail-open), matching this file's fail-open convention.
gate_budget_exceeded() {
  local started="${1:-}" cap="${2:-}" now="${3:-}"
  case "$started" in ''|*[!0-9]*) return 1 ;; esac
  case "$cap" in ''|*[!0-9]*) return 1 ;; esac
  if [ -z "$now" ]; then
    now="$(date +%s)"
  else
    case "$now" in ''|*[!0-9]*) return 1 ;; esac
  fi
  [ $((now - started)) -gt "$cap" ]
}

# gate_is_role_directive_stub <file> — extracted from stub-check.sh's
# directive.sh structural check (issue-173) so compliance-check.sh's
# --canon-duplication filename-match scan can distinguish a sanctioned
# per-repo directive.sh stub (source role-directive.sh, call
# core_role_directive, nothing else beyond a small set of structural line
# categories) from a genuinely vendored full copy, without a second,
# independently-maintained copy of this classification. Returns 0 (is a
# sanctioned stub) or 1 (not); prints the fail reason to stdout on a 1
# return, prints nothing on a 0 return.
#
# issue-180: replaces the earlier canon-forms.txt regex-table approach
# (three rounds of literal per-repo pattern rows — #78, #173, #175,
# #177 — each still left real Batch-1 repos scanning dirty; see
# docs/issue-180/reports/implementation/survey.md) with a structural
# line classifier. Every remaining "other" line (after the existing
# blank/comment/shebang/role-directive.sh-mention/core_role_directive-
# mention/bare-assignment exclusions) must fall into one of:
#   1. a `.`/`source` line whose argument's basename (after stripping
#      the directory portion, tolerating arbitrary nested quoting and
#      $(...) command substitution before the final path component) is
#      exactly gate-lib.sh or role-directive.sh — with an optional
#      trailing `|| { ...; exit N; }` or `|| exit N` fallback.
#      Basename-anchored, not a substring-anywhere test, so a lookalike
#      target such as gate-lib.sh.backdoor/inject.sh fails
#      (after-proposal warrant-hunt finding,
#      docs/reports/2026-08-08-hunt-canon-forms-real-bytes.md). Capped
#      to one gate-lib.sh match and one role-directive.sh match per file
#      (issue-177's shape: at most one of each). Deviation from the
#      approved proposal text (docs/issue-180/reports/implementation.md
#      "## Rationale for deviations"): the proposal also names a
#      standalone "sibling *-directive.sh basename" acceptance in this
#      category; dropped here because a bare `. "<name>-directive.sh"`
#      source line with no preceding gate-lib.sh/loop context is exactly
#      the shape the pre-existing "non-gate-lib source line still
#      rejected" regression fixture exists to catch, and generalizing it
#      would silently reopen that gap. The one real shape needing a
#      sibling-directive.sh source (sales-rulebook's fragment loop)
#      still passes via category 4's variable-based test-and-source
#      line, which never needs a literal sibling filename.
#   2. a line calling exactly one gate_<name> function (the gate_*
#      word-count cap below still applies — issue-177 semicolon-chain
#      hunt fix), optionally followed by `|| exit N` — accepted only
#      once a category-1 gate-lib.sh source line has already matched
#      earlier in the file, since a gate_* call before anything defines
#      it cannot be a real export (closes the second half of the same
#      hunt finding: an attacker-defined gate_evil sourced from a
#      non-canon file can no longer piggyback on a call-site-only test).
#   3. a set -e / set -euo pipefail-family preamble line.
#   4. for/do/done/in loop-syntax keyword lines (sales-rulebook's
#      fragment-loop shape, #78/#83) — narrow: only these four keyword
#      lines, not a generic loop-body allowance.
# Any line matching none of these ⇒ fail, same "regrown boilerplate"
# message shape as before.
gate_is_role_directive_stub() {
  local f="$1"
  [ -f "$f" ] || { echo "no such file: $f"; return 1; }

  local fail_reason=""
  grep -qE 'role-directive\.sh["'"'"']?[[:space:]]*$|role-directive\.sh"' "$f" \
    || fail_reason="does not source core/hooks/lib/role-directive.sh"
  if [ -z "$fail_reason" ]; then
    grep -q 'core_role_directive' "$f" \
      || fail_reason="never calls core_role_directive"
  fi
  if [ -z "$fail_reason" ]; then
    local other
    other="$(grep -vE '^[[:space:]]*(#.*)?$|^#!|role-directive\.sh|core_role_directive|^[A-Za-z_][A-Za-z0-9_]*=' "$f" 2>/dev/null || true)"
    if [ -n "$other" ]; then
      local still_other="" oline gate_word_count basename_part
      local gate_lib_hits=0 role_directive_hits=0 saw_gate_lib_source=0 gate_call_hits=0
      while IFS= read -r oline; do
        [ -n "$oline" ] || continue

        # Category 3: set -e family preamble.
        if printf '%s' "$oline" | grep -qE '^[[:space:]]*set[[:space:]]+-[a-zA-Z]*e[a-zA-Z]*([[:space:]]|$)'; then
          continue
        fi

        # Category 4: narrow fragment-loop syntax (sales-rulebook's
        # approved shape, #78/#83) — for/in header (optionally
        # backslash-continued), quoted sibling-path continuation lines,
        # do/done keyword lines, and the var-based test-and-source body
        # line. Kept minimal: these five line shapes only, not a
        # generic loop-body allowance.
        if printf '%s' "$oline" | grep -qE '^[[:space:]]*for[[:space:]]+[A-Za-z_][A-Za-z0-9_]*[[:space:]]+in([[:space:]].*)?\\?[[:space:]]*$'; then
          continue
        fi
        if printf '%s' "$oline" | grep -qE '^[[:space:]]*(do|done)[[:space:]]*$'; then
          continue
        fi
        if printf '%s' "$oline" | grep -qE '^[[:space:]]*"[^"]+"[[:space:]]*\\?[[:space:]]*$'; then
          continue
        fi
        if printf '%s' "$oline" | grep -qE '^[[:space:]]*\[[[:space:]]+-f[[:space:]]+"\$[A-Za-z_][A-Za-z0-9_]*"[[:space:]]+\][[:space:]]+&&[[:space:]]+\.[[:space:]]+"\$[A-Za-z_][A-Za-z0-9_]*"([[:space:]]+2>/dev/null)?[[:space:]]*$'; then
          continue
        fi

        # Category 1: `.`/source line, basename-anchored target check.
        # Extract the final /<name>.sh (or bare <name>.sh with no
        # leading slash) component of the line's non-fallback portion,
        # ignoring everything up to and including the last `/` inside
        # the quoted-or-unquoted argument — this is what tolerates
        # nested quoting/$(...) in the directory portion while still
        # anchoring on the actual filename, not a substring match
        # anywhere in the line.
        if printf '%s' "$oline" | grep -qE '^[[:space:]]*\.[[:space:]]+'; then
          basename_part="$(printf '%s' "$oline" | grep -oE '[A-Za-z0-9_-]+\.sh' | tail -1)"
          case "$basename_part" in
            gate-lib.sh)
              gate_lib_hits=$((gate_lib_hits + 1))
              if [ "$gate_lib_hits" -le 1 ] \
                && printf '%s' "$oline" | grep -qE '^[[:space:]]*\.[[:space:]]+.*gate-lib\.sh["'"'"']?([[:space:]]*\|\|[[:space:]]*(\{[^}]*\}|exit[[:space:]]+[0-9]+))?[[:space:]]*$'; then
                saw_gate_lib_source=1
                continue
              fi
              ;;
            role-directive.sh)
              role_directive_hits=$((role_directive_hits + 1))
              if [ "$role_directive_hits" -le 1 ] \
                && printf '%s' "$oline" | grep -qE '^[[:space:]]*\.[[:space:]]+.*role-directive\.sh["'"'"']?([[:space:]]*\|\|[[:space:]]*(\{[^}]*\}|exit[[:space:]]+[0-9]+))?[[:space:]]*$'; then
                continue
              fi
              ;;
          esac
          still_other="${still_other}${still_other:+$'\n'}${oline}"
          continue
        fi

        # Category 2: exactly one gate_<name> call, only once a
        # gate-lib.sh source line has already matched earlier in the
        # file. A semicolon-joined chain of gate_* calls on one
        # physical line (e.g. `gate_a x; gate_b y`) would hide an
        # unbounded chain from a per-line cap, so count gate_<name>
        # word occurrences directly and reject a line with more than
        # one (issue-177 before-landing hunt finding).
        gate_word_count="$(printf '%s' "$oline" | grep -oE '\bgate_[A-Za-z_][A-Za-z0-9_]*\b' | wc -l)"
        if [ "$gate_word_count" = 1 ] && [ "$saw_gate_lib_source" = 1 ] && [ "$gate_call_hits" = 0 ] \
          && printf '%s' "$oline" | grep -qE '^[[:space:]]*gate_[A-Za-z_][A-Za-z0-9_]*([[:space:]].*)?(\|\|[[:space:]]*exit[[:space:]]+[0-9]+)?[[:space:]]*$'; then
          gate_call_hits=$((gate_call_hits + 1))
          continue
        fi

        still_other="${still_other}${still_other:+$'\n'}${oline}"
      done <<< "$other"
      other="$still_other"
    fi
    if [ -n "$other" ]; then
      fail_reason="has non-stub line(s), looks like regrown boilerplate: $(printf '%s' "$other" | head -1)"
    fi
  fi

  if [ -n "$fail_reason" ]; then
    echo "$fail_reason"
    return 1
  fi
  return 0
}

# gate_content_hash_matches_canon <hit-file> <canon-file> (issue-175):
# compliance-check.sh --canon-duplication's content-based test for every
# manifest entry other than directive.sh (which keeps its own structural
# gate_is_role_directive_stub path — its content is SUPPOSED to differ per
# sanctioned stub, so hash-equality is never the right test for it). Per
# the issue's acceptance wording: identical content = vendored (flag);
# different content under a matching filename = role-specific, clean.
# Returns 0 when the two files hash identically (vendored copy), 1
# otherwise (content differs, or either file is unreadable — fail open
# toward "not a match", matching this file's convention of never blocking
# on a comparison it cannot actually make).
gate_content_hash_matches_canon() {
  local hit="$1" canon="$2"
  [ -f "$hit" ] && [ -f "$canon" ] || return 1
  local h1 h2
  if command -v sha256sum >/dev/null 2>&1; then
    h1="$(sha256sum "$hit" 2>/dev/null | awk '{print $1}')"
    h2="$(sha256sum "$canon" 2>/dev/null | awk '{print $1}')"
  elif command -v shasum >/dev/null 2>&1; then
    h1="$(shasum -a 256 "$hit" 2>/dev/null | awk '{print $1}')"
    h2="$(shasum -a 256 "$canon" 2>/dev/null | awk '{print $1}')"
  else
    cmp -s "$hit" "$canon"
    return $?
  fi
  [ -n "$h1" ] && [ -n "$h2" ] && [ "$h1" = "$h2" ]
}
