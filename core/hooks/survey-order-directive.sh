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

# Off means off: `X_OFF=0` and `X_OFF=false` read as "not off" to a user and to
# most tooling, but any non-empty value used to disable the hook — the kill switch
# silently killed it on exactly the spelling meant to keep it alive.
case "${SURVEY_ORDER_OFF:-}" in
  ""|0|false|no|off) ;;
  *) exit 0 ;;
esac

ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)}"
cat <<EOF
[survey-order-directive] the survey file exists on disk before any proposal body; a skip (pure bugfix, or no open design decision) is stated in the proposal. Never zero alternatives. Read ${ROOT}/directive/survey-order.md first.
EOF
exit 0
