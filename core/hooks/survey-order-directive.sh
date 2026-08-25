#!/usr/bin/env bash
# UserPromptSubmit hook: injects the research-before-proposal steering directive.
#
# survey-order owns exactly one norm: WRITE ORDER. A phase-1 proposal is
# drafted from a current-state survey, not the other way around — the survey
# file must exist on disk before the proposal body is written, unless the
# proposal itself states one of the two mandatory scout-directive skip
# conditions. Enforcement of the ordering at write time lives in
# survey-order-gate.sh; this directive only sets the default behavior before
# any write happens.
# Kill switch: export SURVEY_ORDER_OFF=1

. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)}/hooks/lib/gate-lib.sh" || { echo "survey-order-directive.sh: cannot source gate-lib.sh" >&2; exit 2; }
gate_kill_switch_active "${SURVEY_ORDER_OFF:-}" || exit 0

ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)}"
cat <<EOF
[survey-order-directive] the survey file exists on disk before any proposal body; a skip (pure bugfix, or no open design decision) is stated in the proposal. Never zero alternatives. Read ${ROOT}/directive/survey-order.md first.
EOF
exit 0
