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

# Off means off: `X_OFF=0` and `X_OFF=false` read as "not off" to a user and
# to most tooling, but any non-empty value used to disable the hook — the
# kill switch silently killed it on exactly the spelling meant to keep it
# alive.
case "${RECORD_SHAPE_OFF:-}" in
  ""|0|false|no|off) ;;
  *) exit 0 ;;
esac

ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)}"
cat <<EOF
[record-shape-directive] phase-2 records carry code_under_review:, loop_state:, type:, breaking:, verdict: frontmatter and a What did not work heading even when empty; deviations section only on actual divergence. Read ${ROOT}/directive/record-shape.md first.
EOF
exit 0
