#!/usr/bin/env bash
# UserPromptSubmit hook: injects the phase-2 record-shape steering directive.
#
# Mechanizes the phase-2 deliverable norm adopted in issue-52
# (docs/issue-52/proposals/2026-07-31-implementation-domain-norms.md,
# section (b)): every phase-2 record at
# docs/issue-<n>/reports/implementation.md carries `code_under_review:`,
# `loop_state:`, `type:`, `breaking:`, and `verdict:` frontmatter (the four
# implementation.spec.json deliverable fields plus loop_state; `commit_sha`
# is realized as `code_under_review:`), a `## What did not work` heading
# present even when empty, and a `## Rationale for deviations` section
# required only when execution diverged from the approved phase-1 proposal.
# Kill switch: export RECORD_SHAPE_OFF=1

. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)}/hooks/lib/gate-lib.sh" || { echo "record-shape-directive.sh: cannot source gate-lib.sh" >&2; exit 2; }
gate_kill_switch_active "${RECORD_SHAPE_OFF:-}" || exit 0

ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)}"
cat <<EOF
[record-shape-directive] phase-2 records carry code_under_review:, loop_state:, type:, breaking:, verdict: frontmatter and a What did not work heading even when empty; deviations section only on actual divergence. Read ${ROOT}/directive/record-shape.md first.
EOF
exit 0
