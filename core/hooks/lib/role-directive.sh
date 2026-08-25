#!/usr/bin/env bash
# Sourceable library: the boilerplate every rulebook's own SessionStart
# `directive.sh` repeated byte-for-byte except for role-token substitution
# (issue-66 survey: preamble, kill-switch case, CLAUDE_ROLE guard, opening
# and closing lines were identical in shape across all 43 copies). A
# rulebook's directive.sh now sources this file and calls
# core_role_directive with its four genuinely role-unique values; every
# unique bit of shell logic below lives in exactly one place.
#
# Usage, from a rulebook's own hooks/directive.sh:
#
#   #!/usr/bin/env bash
#   . "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/role-directive.sh"
#   core_role_directive \
#     "YOU DECIDE: ..." \
#     "USE WHEN: ..." \
#     "PRODUCES: ..." \
#     "HAND-OFF: ..."
#
# core_role_directive <you_decide> <use_when> <produces> <hand_off>
#
# Reads CLAUDE_ROLE from the environment (no role -> silent no-op, same as
# core's own directive.sh). Kill switch, per role, via
# <ROLE>_CYCLE_OFF=1 (role name uppercased with `tr`, not bash 4's
# `${var^^}`, to stay inside parse-check.sh's bash-3.2 compatibility
# floor), tested via gate-lib.sh's shared gate_kill_switch_active so this
# file carries no hand-rolled off-spelling case of its own (issue-304).
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/gate-lib.sh" || { echo "role-directive.sh: cannot source gate-lib.sh" >&2; return 1; }

core_role_directive() {
  local you_decide="$1" use_when="$2" produces="$3" hand_off="$4"
  local role="${CLAUDE_ROLE:-}"
  [ -n "$role" ] || return 0

  local role_upper
  role_upper="$(printf '%s' "$role" | tr '[:lower:]-' '[:upper:]_')"
  local off_var="${role_upper}_CYCLE_OFF"
  eval "local off_val=\"\${${off_var}:-}\""
  gate_kill_switch_active "$off_val" || return 0

  cat <<EOF
[${role}] Role directive (on top of core's protocol):

${you_decide}
${use_when}
${produces}
${hand_off}

RECORD: docs/issue-<n>/reports/${role}.md, phase-gated per contract v3 s19
RECORD FORMAT: code_under_review: is a file list (- path per reviewed/
changed file), never a commit sha. Any count claim cites an actual
code-fenced command output, preceded by a derived: <command or path>
line. When the change is accumulation-cost-shaped, fill the proposal's
## Accumulation section with real content.
EOF
}
