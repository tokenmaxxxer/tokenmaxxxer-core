#!/usr/bin/env bash
# UserPromptSubmit hook: steers phase-1 proposal writes toward this repo's
# adopted ADR-style shape (issue-52, section (a)).
#
# This directive is direction, not inspection — but proposal-shape-gate.sh
# (a PreToolUse gate shipped in this same plugin) DOES also check the
# resulting content at write time. Together, the directive sets the target
# and the gate refuses writes that miss it.
#
# Kill switch: export PROPOSAL_SHAPE_OFF=1

# Off means off: `X_OFF=0` and `X_OFF=false` read as "not off" to a user and
# to most tooling, but any non-empty value used to disable the hook — the
# kill switch silently killed it on exactly the spelling meant to keep it
# alive.
case "${PROPOSAL_SHAPE_OFF:-}" in
  ""|0|false|no|off) ;;
  *) exit 0 ;;
esac

ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)}"
cat <<EOF
[proposal-shape-directive] phase-1 proposals carry files:, Request, Constraints, Rationale, What will be done, Out of scope, How you will know it worked, in order; Rationale names a rejected alternative and why. Read ${ROOT}/directive/proposal-shape.md first.
EOF
exit 0
