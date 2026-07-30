#!/usr/bin/env bash
# approval-gate.sh, exercised as a real subprocess with a stubbed gh.
#
# The rule (contract v3 s19): a role session's src//test/ write is refused
# until the role's issue-<n>/<role> subject carries an Approve from an
# account listed in docs/specs/approvers.md — a PR review, or an
# issue-level `APPROVE issue-<n>/<role>` comment, gated first by the
# issue's own open/closed state. CORE_GH is the test seam.
#
# want: "allow" (exit 0) | "deny" (exit 2)
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
GATE="$HERE/../approval-gate.sh"
PLUGIN_ROOT="$(cd "$HERE/../.." && pwd -P)"
CANON="$PLUGIN_ROOT/contract/role-handoff-contract.md"
pass=0
fail=0

report() {
  if [ "$2" = "$1" ]; then
    pass=$((pass + 1)); printf 'ok     %-34s %s\n' "$3" "$2"
  else
    fail=$((fail + 1)); printf 'FAIL   %-34s want=%s got=%s\n' "$3" "$1" "$2"
  fi
}

# stub_gh <dir> <mode>: modes set the issue's state/comments and the PR's
# reviews independently. The generated gh stub is argument-aware — it
# branches on $1 ("issue" vs "pr") so the two gh calls approval-gate.sh
# makes (issue view --json state,comments; pr view --json reviews) get
# independent, mode-controlled responses.
stub_gh() {
  issue_state='OPEN'; issue_comments='[]'
  pr_ok=1; reviews='[]'
  case "$2" in
    human)    reviews='[{"author":{"login":"jw-human"},"state":"APPROVED"}]' ;;
    comment-challenge) issue_comments='[{"author":{"login":"jw-human"},"body":"APPROVE issue-7/coding"}]' ;;
    comment-challenge-agent) issue_comments='[{"author":{"login":"agent-bot"},"body":"APPROVE issue-7/coding"}]' ;;
    comment-prose) issue_comments='[{"author":{"login":"jw-human"},"body":"looks good, approve!"}]' ;;
    bot)      reviews='[{"author":{"login":"security-bot"},"state":"APPROVED"}]' ;;
    agent)    reviews='[{"author":{"login":"tokenmaxxxer-agent"},"state":"APPROVED"}]' ;;
    comment)  reviews='[{"author":{"login":"jw-human"},"state":"COMMENTED"}]' ;;
    revoked)  reviews='[{"author":{"login":"jw-human"},"state":"APPROVED"},{"author":{"login":"jw-human"},"state":"CHANGES_REQUESTED"}]' ;;
    nopr)     pr_ok=0 ;;
    issue-comment-no-pr) pr_ok=0; issue_comments='[{"author":{"login":"jw-human"},"body":"APPROVE issue-7/coding"}]' ;;
    closed-with-comment) issue_state='CLOSED'; pr_ok=0; issue_comments='[{"author":{"login":"jw-human"},"body":"APPROVE issue-7/coding"}]' ;;
    closed-with-pr-review) issue_state='CLOSED'; reviews='[{"author":{"login":"jw-human"},"state":"APPROVED"}]' ;;
    comment-minimized) pr_ok=0; issue_comments='[{"author":{"login":"jw-human"},"body":"APPROVE issue-7/coding","isMinimized":true,"minimizedReason":"OUTDATED"}]' ;;
  esac
  cat > "$1/gh" <<SCRIPT
#!/bin/sh
case "\$1" in
  issue) printf '%s' '{"state":"$issue_state","comments":$issue_comments}' ;;
  pr)
    if [ "$pr_ok" = 1 ]; then
      printf '%s' '{"reviews":$reviews}'
    else
      echo "no pull requests found" >&2
      exit 1
    fi
    ;;
esac
SCRIPT
  chmod +x "$1/gh"
}

# run <want> <name> <gh-mode> <file_path> [opts]
#   opts: noapprovers | emptyapprovers | branch=<b> | role=<r> | tool=Bash cmd=...
run() {
  want="$1"; name="$2"; mode="$3"; fp="$4"; shift 4
  branch="issue-7/coding"; role="coding"; tool="Write"; cmd=""
  approvers="yes"
  for o in "$@"; do
    case "$o" in
      noapprovers) approvers="no" ;;
      emptyapprovers) approvers="empty" ;;
      branch=*) branch="${o#branch=}" ;;
      role=*) role="${o#role=}" ;;
      cmd=*) tool="Bash"; cmd="${o#cmd=}" ;;
    esac
  done
  td="$(cd "$(mktemp -d -p "${TMPDIR:-/tmp}")" && pwd -P)"
  git init -q "$td"
  git -C "$td" remote add origin git@github.com:tokenmaxxxer/probe.git
  git -C "$td" checkout -q -b "$branch"
  mkdir -p "$td/docs/specs" "$td/stub"
  cp "$CANON" "$td/docs/specs/role-handoff-contract.md"
  case "$approvers" in
    yes)   printf -- '- jw-human\n' > "$td/docs/specs/approvers.md" ;;
    empty) printf 'no list lines here\n' > "$td/docs/specs/approvers.md" ;;
    no)    : ;;
  esac
  stub_gh "$td/stub" "$mode"
  if [ "$tool" = "Bash" ]; then
    tinput="$(printf '{"command":"%s"}' "$cmd")"
  else
    tinput="$(printf '{"file_path":"%s","content":"x"}' "$fp")"
  fi
  printf '{"tool_name":"%s","tool_input":%s,"cwd":"%s"}' "$tool" "$tinput" "$td" \
    | env CLAUDE_PROJECT_DIR="$td" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" \
      CLAUDE_ROLE="$role" CORE_GH="$td/stub/gh" /bin/bash "$GATE" >/dev/null 2>&1
  rc=$?
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"
  report "$want" "$got" "$name"
}

# --- the verdict matrix ---------------------------------------------------
run allow human-approved         human   src/app.py
run allow human-approved-test    human   test/test_app.py
run deny  no-pr-yet              nopr    src/app.py
run deny  bot-approve            bot     src/app.py
run deny  agent-approve          agent   src/app.py
run deny  comment-not-approve    comment src/app.py
run deny  approve-then-changes   revoked src/app.py
run allow comment-challenge       comment-challenge src/app.py
run deny  comment-challenge-agent comment-challenge-agent src/app.py
run deny  comment-prose           comment-prose src/app.py
run deny  no-approvers-file      human   src/app.py noapprovers
run deny  empty-approvers-file   human   src/app.py emptyapprovers

# --- issue-comment canonical location (issue #53) --------------------------
run allow issue-comment-approved-no-pr        issue-comment-no-pr     src/app.py
run allow pr-review-approved-no-issue-comment human                  src/app.py
run deny  issue-comment-agent                 comment-challenge-agent src/app.py
run deny  issue-comment-prose                 comment-prose           src/app.py
run deny  neither-surface                     nopr                    src/app.py
run deny  closed-issue-with-comment           closed-with-comment     src/app.py
run deny  closed-issue-with-pr-review         closed-with-pr-review   src/app.py
run deny  issue-comment-minimized             comment-minimized       src/app.py

# --- precondition: no remote, no approvals --------------------------------
noremote() {
  td="$(cd "$(mktemp -d -p "${TMPDIR:-/tmp}")" && pwd -P)"
  git init -q "$td"
  git -C "$td" checkout -q -b issue-7/coding
  mkdir -p "$td/docs/specs" "$td/stub"
  cp "$CANON" "$td/docs/specs/role-handoff-contract.md"
  printf -- '- jw-human\n' > "$td/docs/specs/approvers.md"
  stub_gh "$td/stub" human
  printf '{"tool_name":"Write","tool_input":{"file_path":"src/app.py","content":"x"},"cwd":"%s"}' "$td" \
    | env CLAUDE_PROJECT_DIR="$td" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" \
      CLAUDE_ROLE=coding CORE_GH="$td/stub/gh" /bin/bash "$GATE" >/dev/null 2>&1
  rc=$?
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"
  report deny "$got" "execute-without-remote"
}
noremote

# --- branch and role preconditions ----------------------------------------
run deny  execute-from-main      human   src/app.py branch=main
run deny  wrong-role-branch      human   src/app.py branch=issue-7/qa
run deny  bash-redirect-src      nopr    x cmd='echo hi > src/app.py'
run allow bash-read-src          nopr    x cmd='cat src/app.py'

# --- the docs execution surface (doc-producing roles) ---------------------
run deny  record-before-approve  nopr    docs/issue-7/reports/coding.md
run deny  record-comment-only    comment docs/issue-7/reports/coding.md
run allow record-after-approve   human   docs/issue-7/reports/coding.md
run deny  foreign-area-preapprove nopr   docs/issue-7/specs/design.md
run deny  spikes-before-approve  nopr    docs/issue-7/reports/spikes/probe.md role=feasibility branch=issue-7/feasibility

# --- not this gate's business (phase-1 homes and non-surface paths) -------
run allow proposal-write         nopr    docs/issue-7/proposals/p.md
run allow research-write         nopr    docs/issue-7/reports/coding/survey.md
run allow standing-docs-write    nopr    docs/reports/opportunity-tree.md
run allow readme-write           nopr    README.md

# non-role session: gate stands aside entirely
norole() {
  td="$(cd "$(mktemp -d -p "${TMPDIR:-/tmp}")" && pwd -P)"
  git init -q "$td"
  printf '{"tool_name":"Write","tool_input":{"file_path":"src/app.py","content":"x"},"cwd":"%s"}' "$td" \
    | env -u CLAUDE_ROLE CLAUDE_PROJECT_DIR="$td" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" \
      /bin/bash "$GATE" >/dev/null 2>&1
  rc=$?
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"
  report allow "$got" "no-role-session"
}
norole

# kill switch
kill_switch() {
  td="$(cd "$(mktemp -d -p "${TMPDIR:-/tmp}")" && pwd -P)"
  git init -q "$td"
  printf '{"tool_name":"Write","tool_input":{"file_path":"src/app.py","content":"x"},"cwd":"%s"}' "$td" \
    | env CLAUDE_ROLE=coding CORE_OFF=1 CLAUDE_PROJECT_DIR="$td" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" \
      /bin/bash "$GATE" >/dev/null 2>&1
  rc=$?
  rm -rf "$td"
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  report allow "$got" "kill-switch"
}
kill_switch

printf '\n== %d passed, %d failed ==\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
