#!/usr/bin/env bash
# Drift-recurrence detector (issue-66 item 4; canon-pinned per issue-69).
#
# CANON EXECUTION MODEL: this script itself is core canon and is never
# vendored into a rulebook. A rulebook invokes it by a path resolved
# against core's own plugin install root (the same
# ${CLAUDE_PLUGIN_ROOT}/hooks/<name>.sh shape core/hooks/hooks.json already
# uses for the four registered gates), passing the rulebook's own directory
# as the scan target — e.g.
#   "${CORE_PLUGIN_ROOT:-$CLAUDE_PLUGIN_ROOT/../core}/hooks/tests/stub-check.sh" "$(dirname "$0")/.."
# A rulebook's test-harness record notes only the invocation and its
# result; it never carries a second copy of this file. See
# docs/handbooks/role-gates-tests.md for the documented invocation line and
# docs/handbooks/canon-scripts.md for the general reference-not-vendor rule
# this enforces (issue-69).
#
# The four role-agnostic gates (trailer-gate.sh, record-fields-gate.sh,
# handbook-trigger-gate.sh) plus parse-check.sh are registered as core
# canon hooks (core/hooks/hooks.json fires them for every plugin install —
# issue-66's approver decision). A rulebook no longer needs its OWN copy of
# any of these four files or its own hooks.json entry for them at all: core
# already fires them globally. Once a rulebook's vendored copy is removed
# (the per-rulebook follow-up issue-66 tracks but does not execute), the
# presence of any of these filenames back under a rulebook's own hooks/ tree
# is itself the drift signal — a locally-reintroduced copy is exactly the
# shape that produced today's 38/40-unique-hash drift (issue-66 survey).
# stub-check.sh checks for a copy of itself too (issue-69 item 2): the
# detector vendored 43 times was itself the drift it exists to catch.
#
# directive.sh is different: every role still needs its own small file (the
# four role-unique values), so its check is structural, not
# absence-based — it must be the "source core/hooks/lib/role-directive.sh,
# set four values, call core_role_directive" form, nothing else. A stub
# that has grown a local copy of the boilerplate this promotion factored out
# (the trap/kill-switch/guard/opening-closing lines) fails this check.
#
# Usage: stub-check.sh [hooks-dir]
set -uo pipefail

dir="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." 2>/dev/null && pwd -P)}"
[ -d "$dir" ] || { echo "stub-check: no such directory: $dir" >&2; exit 2; }
rc=0

# CANON_GATES is derived from canon-manifest.txt (one filename per line,
# next to this script) rather than hardcoded, so a future promotion (a new
# core/hooks.json entry, or a new promoted test-harness script) adds one
# manifest line instead of an edit to this detection logic (issue-69 item
# 2, general-rule half).
manifest="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/canon-manifest.txt"
if [ -f "$manifest" ]; then
  CANON_GATES="$(grep -v '^[[:space:]]*$' "$manifest" | grep -v '^[[:space:]]*#' | tr '\n' ' ')"
else
  echo "stub-check: WARN — canon-manifest.txt not found at $manifest, falling back to built-in list" >&2
  CANON_GATES="trailer-gate.sh record-fields-gate.sh handbook-trigger-gate.sh parse-check.sh stub-check.sh"
fi

for name in $CANON_GATES; do
  # -mindepth 1 -maxdepth 3: a rulebook's own hooks/ (depth 1) or hooks/tests/
  # (depth 2, where parse-check.sh's rulebook copy lives today) — not core's
  # own repo tree, which this script is never run against directly (core is
  # canon by definition and is excluded by callers pointing $dir at a
  # rulebook's plugin root, not at this repo).
  hits="$(find "$dir" -maxdepth 3 -name "$name" -type f 2>/dev/null || true)"
  if [ -n "$hits" ]; then
    echo "stub-check: FAIL — vendored copy of core canon file '$name' found:" >&2
    printf '%s\n' "$hits" >&2
    echo "  This file is now a core hook (core/hooks/hooks.json), fired for" >&2
    echo "  every plugin install. A local copy is drift, not a stub — delete" >&2
    echo "  it and drop the file's own hooks.json entry, if any (issue-66)." >&2
    rc=1
  else
    echo "stub-check: ok — no vendored '$name' under $dir"
  fi
done

# --- directive.sh: structural check, not absence-based ---------------------
# CANON_FORMS is derived from canon-forms.txt (name:pattern-description
# lines, next to this script): one or more registered directive.sh
# combination shapes, each a set of extended-regex patterns any of which,
# in addition to the built-in source/assignment/core_role_directive lines,
# marks a line as sanctioned rather than regrown boilerplate (issue-78).
# Missing manifest falls back to the single-call-only shape (no extra
# patterns), matching CANON_GATES's own missing-manifest fallback pattern.
forms_manifest="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/canon-forms.txt"
CANON_FORM_PATTERNS=()
if [ -f "$forms_manifest" ]; then
  while IFS= read -r line; do
    case "$line" in
      ''|'#'*) continue ;;
    esac
    CANON_FORM_PATTERNS+=("${line#*:}")
  done < "$forms_manifest"
else
  echo "stub-check: WARN — canon-forms.txt not found at $forms_manifest, falling back to single-call-only shape" >&2
fi

directive_hits="$(find "$dir" -maxdepth 3 -name 'directive.sh' -type f 2>/dev/null || true)"
if [ -z "$directive_hits" ]; then
  echo "stub-check: ok — no directive.sh under $dir (nothing to check)"
else
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    fail_reason=""
    grep -qE 'role-directive\.sh["'"'"']?[[:space:]]*$|role-directive\.sh"' "$f" \
      || fail_reason="does not source core/hooks/lib/role-directive.sh"
    if [ -z "$fail_reason" ]; then
      grep -q 'core_role_directive' "$f" \
        || fail_reason="never calls core_role_directive"
    fi
    if [ -z "$fail_reason" ]; then
      # Structural cap: every non-blank/non-comment/non-shebang line in a
      # real stub is either the source line, a plain variable assignment,
      # or the one core_role_directive call. Anything else (a case
      # statement, a guard test, a raw echo/cat, control flow) is exactly
      # the boilerplate this promotion factored out regrowing locally.
      other="$(grep -vE '^[[:space:]]*(#.*)?$|^#!|role-directive\.sh|core_role_directive|^[A-Za-z_][A-Za-z0-9_]*=' "$f" 2>/dev/null || true)"
      if [ -n "$other" ] && [ "${#CANON_FORM_PATTERNS[@]}" -gt 0 ]; then
        # A registered combination shape (e.g. the fragment-array for-loop)
        # is not boilerplate — filter out any remaining "other" line that
        # matches at least one registered pattern before failing.
        still_other=""
        while IFS= read -r oline; do
          [ -n "$oline" ] || continue
          matched=0
          for pat in "${CANON_FORM_PATTERNS[@]}"; do
            if printf '%s' "$oline" | grep -qE "$pat"; then
              matched=1
              break
            fi
          done
          [ "$matched" = 1 ] || still_other="${still_other}${still_other:+$'\n'}${oline}"
        done <<< "$other"
        other="$still_other"
      fi
      if [ -n "$other" ]; then
        fail_reason="has non-stub line(s), looks like regrown boilerplate: $(printf '%s' "$other" | head -1)"
      fi
    fi
    if [ -n "$fail_reason" ]; then
      echo "stub-check: FAIL — $f: $fail_reason" >&2
      rc=1
    else
      echo "stub-check: ok — $f is a role-directive stub"
    fi
  done <<< "$directive_hits"
fi

exit "$rc"
