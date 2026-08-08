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

. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd -P)/gate-lib.sh"

dir="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." 2>/dev/null && pwd -P)}"
[ -d "$dir" ] || { echo "stub-check: no such directory: $dir" >&2; exit 2; }
rc=0

# repo_root, computed the same way compliance-check.sh does (three levels
# up from core/hooks/tests/), used below to exclude hits that are already
# living at their own canonical core/hooks/ location — a real hit there is
# this repo's canon source, not a vendored copy (issue-183).
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)"
canon_home="$repo_root/core/hooks"

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
    filtered=""
    while IFS= read -r hit; do
      [ -n "$hit" ] || continue
      real="$(cd "$(dirname "$hit")" 2>/dev/null && pwd -P)/$(basename "$hit")"
      # Exact-match only, against $name's actual canonical location(s) —
      # a nested subtree under core/hooks/ (e.g. a vendored copy stashed
      # at core/hooks/vendor/some-rulebook/hooks/$name) is a real drift
      # hit, not this file's own canon source, so a broad prefix match
      # would wrongly exclude it (issue-183 before-landing hunt).
      case "$real" in
        "$canon_home/$name"|"$canon_home/tests/$name"|"$canon_home/lib/$name") ;;
        *) filtered="$filtered
$real" ;;
      esac
    done <<< "$hits"
    hits="$(printf '%s\n' "$filtered" | grep -v '^[[:space:]]*$' || true)"
  fi
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
# Classification is delegated to gate_is_role_directive_stub (gate-lib.sh,
# issue-173): compliance-check.sh's --canon-duplication mode needs this
# exact same check for its own directive.sh hits, so the logic lives in
# one shared place both scripts call instead of two independently
# maintained copies.
forms_manifest="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/canon-forms.txt"
if [ ! -f "$forms_manifest" ]; then
  echo "stub-check: WARN — canon-forms.txt not found at $forms_manifest, falling back to single-call-only shape" >&2
fi

directive_hits="$(find "$dir" -maxdepth 3 -name 'directive.sh' -type f 2>/dev/null || true)"
if [ -z "$directive_hits" ]; then
  echo "stub-check: ok — no directive.sh under $dir (nothing to check)"
else
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    if fail_reason="$(gate_is_role_directive_stub "$f")"; then
      echo "stub-check: ok — $f is a role-directive stub"
    else
      echo "stub-check: FAIL — $f: $fail_reason" >&2
      rc=1
    fi
  done <<< "$directive_hits"
fi

exit "$rc"
