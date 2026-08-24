#!/usr/bin/env bash
# warrant/hooks/directive.sh's rendered hunt-record-path instruction.
#
# issue-202: directive.sh used to tell the hunter to name its hunt record
# docs/issue-<n>/reports/hunt-<slug>.md unconditionally whenever the proposal
# path carried an issue segment — inside a role session governed by
# on-the-record's board-gate.sh, that path's first segment after reports/ is
# hunt-<slug>.md, which matches none of R5's allowed shapes and every
# implementation session stranded on its post-PR hunt dispatch. This asserts
# the rendered directive now names the role-subdirectory template
# (docs/issue-<n>/reports/<role>/...) for a role-scoped session, and still
# states the unchanged standalone fallback (docs/reports/<date>-hunt-<slug>.md)
# for the no-CLAUDE_ROLE empty state.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
DIRECTIVE="$HERE/../directive.sh"
CORE_ROOT="$(cd "$HERE/../../../core" && pwd -P)"

pass=0
fail=0

report() {
  if [ "$2" = "$1" ]; then
    pass=$((pass + 1)); printf 'ok     %-40s %s\n' "$3" "$2"
  else
    fail=$((fail + 1)); printf 'FAIL   %-40s want=%s got=%s\n' "$3" "$1" "$2"
  fi
}

# issue-278: the per-turn injection is now a byte-stable index; the protocol
# prose lives verbatim in warrant/directive/warrant-protocol.md. The hunt-path
# instruction assertions run against the corpus = rendered index + section
# file, mirroring on-the-record #2106. grep -c counts matching LINES, so the
# single-occurrence assertions hold unchanged over the corpus.
SECTION="$(cd "$HERE/../.." && pwd -P)/directive/warrant-protocol.md"
rendered="$(CLAUDE_PLUGIN_ROOT_CORE="$CORE_ROOT" /bin/bash "$DIRECTIVE" 2>&1; cat "$SECTION")"

# --- role-session context: names the board-gate-in-scope role-subtree path ---
role_scope_hits="$(printf '%s' "$rendered" | grep -c 'docs/issue-<n>/reports/<role>/<date>-hunt-<proposal-slug>\.md' || true)"
report 1 "$role_scope_hits" role-scoped-hunt-path-present

role_check_hits="$(printf '%s' "$rendered" | grep -c 'CLAUDE_ROLE.*is set AND this session.*own current branch resolves as exactly `issue-<n>/<CLAUDE_ROLE>`' || true)"
report 1 "$role_check_hits" role-scope-condition-matches-R4-check

# --- empty state: standalone (no CLAUDE_ROLE) still names the unchanged fallback ---
standalone_hits="$(printf '%s' "$rendered" | grep -c 'docs/reports/<date>-hunt-<proposal-slug>\.md' || true)"
report 1 "$standalone_hits" standalone-fallback-path-present

issue_segment_hits="$(printf '%s' "$rendered" | grep -c 'docs/issue-<n>/reports/hunt-<proposal-slug>\.md' || true)"
report 1 "$issue_segment_hits" issue-segment-fallback-path-present

# --- prohibition: the old unconditional rule must not remain unconditional ---
# ("otherwise, fall back" gates the old templates behind the role-scope check)
fallback_gate_hits="$(printf '%s' "$rendered" | grep -c 'Otherwise, fall back to the existing rule unchanged' || true)"
report 1 "$fallback_gate_hits" old-templates-conditioned-not-unconditional

echo
echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
