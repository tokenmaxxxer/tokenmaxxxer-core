#!/usr/bin/env bash
# UserPromptSubmit hook: injects the work-unit protocol.
#
# One gate, at the front. Everything after it runs without interruption — which
# is why the proposal has to carry the decisions that would otherwise become
# mid-build questions. freelunch forbids pausing MID-task; a pre-task gate is a
# different thing and the two compose unchanged.
#
# State lives on disk, not in the conversation: the proposal file's status field
# and the git branch survive session death, so state.sh can rebuild the picture
# at session start.
# Kill switch: export WARRANT_OFF=1

. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)}/hooks/lib/gate-lib.sh" || { echo "directive.sh: cannot source gate-lib.sh" >&2; exit 2; }
gate_trap_fail_closed
set -uo pipefail
gate_kill_switch_active "${WARRANT_OFF:-}" || { trap - EXIT; exit 0; }

ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)}"
cat <<EOF
[warrant-directive] file-touching work starts with a proposal (status + files: frontmatter) — write it, stop the turn. After approval build only inside the frozen write set; log What did not work as it happens; every commit ends with its Proposal: trailer; scope exceeded: finish, stop, report. One background warrant-hunter (model sonnet) after-proposal and before-landing. Read ${ROOT}/directive/warrant-protocol.md when a turn would write repository files.
EOF
exit 0
