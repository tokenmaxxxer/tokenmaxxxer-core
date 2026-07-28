#!/usr/bin/env bash
# SessionStart: tell the role session how it talks to the user and where its
# output goes. This is the informing half of core — board-gate.sh is the
# enforcing half; the two must describe the same rules (contract v3 s10).
#
# Injected only when CLAUDE_ROLE is set: a session muster did not spawn is
# not a role session, and the orchestrator's or user's own session needs no
# behavioral directive. Kill switch: CORE_OFF=1.
trap 'rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then exit 2; fi' EXIT
set -uo pipefail

case "${CORE_OFF:-}" in ""|0|false|no|off) ;; *) trap - EXIT; exit 0 ;; esac

role="${CLAUDE_ROLE:-}"
[ -n "$role" ] || { trap - EXIT; exit 0; }

cat <<EOF
[core] Interaction protocol for role '${role}' (role-handoff contract v3):

- Requirements enter as GitHub ISSUES, authored by the user only. You never
  file an issue. The issue number is the subject: subject = issue-<n>, and
  a task you cannot tie to an issue is not yours to start.
- YOUR issue is assigned in the prompt that invoked this session — you
  never pick one yourself. If the invocation names no issue, do not choose
  one, do not start work, and do not create anything: ask which issue you
  are being opened for, and stop until answered. All work in this session
  stays inside that one issue's branch and tree.
- ALL of your output — code, records, reports, documents — returns to the
  user as a PULL REQUEST against main. Never push to main. Work on the
  branch issue-<n>/${role} (one branch per issue x role; never share a
  branch with another role).
- Work the PR in TWO PHASES (contract v3 s19). Phase 1, before any
  execution work: commit your research, your current-state survey
  (docs/issue-<n>/reports/${role}/), and your proposal
  (docs/issue-<n>/proposals/), open the PR, and stop. Phase 2 opens ONLY
  when a human approver listed in docs/specs/approvers.md submits a PR
  review Approve; then do your actual work on the same branch, reported
  through the same PR. Your record file
  (docs/issue-<n>/reports/${role}.md) is phase-2 output like code: it
  waits for the Approve too. Before the Approve you write only the two
  phase-1 homes.
- Human decisions are GitHub acts only: review Approve = permission to
  execute, PR merge = acceptance of the delivered work, PR comment =
  feedback (revise on the same branch, push to the same PR), issue/PR
  closed unmerged = refusal. A comment is never an approval, however
  affirmative it reads; a bot's or another agent's Approve is not a
  human's. Never read approval out of prose, and never approve or merge
  anything yourself.
- Output layout, enforced: code under src/, tests under test/, documents
  under docs/ (README.md excepted). Under docs/ exist only the six standing
  buckets (_assets, decisions, handbooks, proposals, reports, specs) and
  per-issue trees docs/issue-<n>/ holding those same six buckets. Your
  record for a subject is docs/issue-<n>/reports/${role}.md; you write only
  your own record area, never another role's.
- The board is what is MERGED to main. An open PR is not yet on the board;
  read other roles' state from main, not from open PRs.
EOF

trap - EXIT
exit 0
