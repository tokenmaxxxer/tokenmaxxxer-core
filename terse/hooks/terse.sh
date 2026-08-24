#!/usr/bin/env bash
# UserPromptSubmit hook: injects the output-compression directive into context on every prompt.
#
# Design notes (v0.1.0, 2026-07-19): companion to freelunch, not a fork of Caveman.
# Caveman compresses everything the model says; terse compresses only the main
# session's conversational prose. Tool inputs — worker prompts, Workflow scripts,
# frozen contracts — are exempt because freelunch's fan-out correctness depends on
# their precision, and Caveman-style fragment compression there would corrupt the
# contract a worker receives. Safety-critical messages stay in full prose for the
# same reason Caveman exempts them: fragments are misreadable exactly where
# misreading is most expensive.
#
# State: one word in ~/.claude/terse.level (off | lite | full | ultra).
# Missing file means "full". The /terse command writes this file.
# Kill switch: export TERSE_OFF=1 (mirrors FREELUNCH_OFF).

. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)}/hooks/lib/gate-lib.sh" || { echo "terse.sh: cannot source gate-lib.sh" >&2; exit 2; }
gate_trap_fail_closed
set -uo pipefail
gate_kill_switch_active "${TERSE_OFF:-}" || { trap - EXIT; exit 0; }

STATE_FILE="${HOME}/.claude/terse.level"
LEVEL="full"
if [ -f "$STATE_FILE" ]; then
  LEVEL="$(tr -d '[:space:]' < "$STATE_FILE")"
fi

NOTE=""
case "$LEVEL" in
  off) exit 0 ;;
  lite)  STYLE="lite: full grammar; cut pleasantries and zero-information sentences" ;;
  ultra) STYLE="ultra: telegraphic fragments, one line per point, prefer tables" ;;
  full|"") STYLE="full: no pleasantries, preamble, restating, or follow-up offers; fragments fine; keep Korean case/negation particles" ;;
  *) STYLE="full: no pleasantries, preamble, restating, or follow-up offers; fragments fine; keep Korean case/negation particles"
     NOTE=" NOTE: terse.level is unrecognized; full is in effect — tell the user." ;;
esac
ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)}"
cat <<EOF
[terse-directive] style for conversational prose only; orchestration wins. LEVEL ${STYLE}. Cut filler, never information; never compress code, tool inputs, mandated protocol output, repo file content, or safety text.${NOTE} Read ${ROOT}/directive/terse-style.md for the full rules.
EOF
exit 0
