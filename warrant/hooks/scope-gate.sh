#!/usr/bin/env bash
# PreToolUse hook (Write|Edit|NotebookEdit|Bash): enforces the two mechanical
# halves of the protocol.
#
#   1. While a proposal is approved and in progress, edits land only in paths
#      its frontmatter froze.
#   2. While one is in progress, a commit carries the `Proposal:` trailer.
#
# Both read the TOOL INPUT — a path, a command string — before anything happens.
# Neither reads generated content, and neither judges the work: which bucket, or
# whether the change is any good, is the directive's business.
#
# Inert unless exactly one proposal is `status: approved`. No open unit, none
# approved, or several at once (ambiguous) — the gate stands down rather than
# guessing.
#
# Fails open on a missing python3, unreadable payload, or unexpected schema.
# Kill switch: export WARRANT_OFF=1

. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)}/hooks/lib/gate-lib.sh" || { echo "scope-gate.sh: cannot source gate-lib.sh" >&2; exit 2; }
gate_trap_fail_closed
set -uo pipefail
gate_kill_switch_active "${WARRANT_OFF:-}" || { trap - EXIT; exit 0; }

command -v python3 >/dev/null 2>&1 || {
  # F4 (issue-305): fail-open here is deliberate (see file header) but was
  # completely silent — the whole scope-enforcement mechanism went dark
  # with no signal on either stream. Keep the fail-open exit 0; add the
  # message so the gap is visible instead of indistinguishable from "no
  # write-set violation."
  echo "scope-gate.sh: python3 not found; write-set enforcement is not evaluated for this call (fails open by design)." >&2
  trap - EXIT
  exit 0
}

payload="$(cat)"

# issue-323: the payload logic used to be a `python3 <<'PY' ... PY` heredoc.
# Bash spools a heredoc's body to a temp file under $TMPDIR before python3
# ever runs, so a disk/inode-exhausted $TMPDIR failed the heredoc creation
# itself -- surfacing as the same fail-closed EXIT trap (gate-lib.sh's
# gate_trap_fail_closed) as any other abort, indistinguishable from an
# ordinary gate refusal. Loading a real file has no temp file to create.
SCOPE_GATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
WARRANT_PAYLOAD="$payload" python3 "$SCOPE_GATE_DIR/lib/scope-gate.py"

exit $?
