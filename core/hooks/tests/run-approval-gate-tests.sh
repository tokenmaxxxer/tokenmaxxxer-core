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
. "$HERE/_tmp.sh"
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

# stub_gh <dir> <mode> [role]: modes set the issue's state/comments and the
# PR's reviews independently. The generated gh stub is argument-aware — it
# branches on $1 ("issue" vs "pr") so the two gh calls approval-gate.sh
# makes (issue view --json state,comments,stateReason; pr view --json
# reviews) get independent, mode-controlled responses. issue_closers and
# closer_json remain as fixture fields (some modes still set them for
# their own historical-shape documentation) but approval-gate.sh no
# longer makes a third `gh pr view <number> --json headRefName,state`
# call to consume them — issue-343 removed the closedByPullRequestsRef-
# erences-driven observer-role exemption that call existed for. [role]
# (default "coding") fills the APPROVE-comment challenge string for modes
# that need to match a non-default role's own issue-<n>/<role> subject.
stub_gh() {
  issue_state='OPEN'; issue_comments='[]'; issue_state_reason=''
  issue_closers='[]'; closer_json='{}'
  pr_ok=1; reviews='[]'
  stub_role="${3:-coding}"
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
    # issue-295: closed via the implementation role's own merged PR
    # (closedByPullRequestsReferences names PR #301, confirmed MERGED on
    # issue-7/implementation) -- the legitimate observer-exemption shape.
    closed-completed-with-comment)
      issue_state='CLOSED'; issue_state_reason='COMPLETED'; pr_ok=0
      issue_comments='[{"author":{"login":"jw-human"},"body":"APPROVE issue-7/'"$stub_role"'"}]'
      issue_closers='[{"number":301}]'
      closer_json='{"headRefName":"issue-7/implementation","state":"MERGED"}'
      ;;
    closed-not-planned-with-comment) issue_state='CLOSED'; issue_state_reason='NOT_PLANNED'; pr_ok=0; issue_comments='[{"author":{"login":"jw-human"},"body":"APPROVE issue-7/'"$stub_role"'"}]' ;;
    # same legitimate closer shape as closed-completed-with-comment, but
    # no APPROVE signal anywhere -- the exemption must not grant approval
    # by itself, only lift the closed-issue precondition.
    closed-completed-no-approval)
      issue_state='CLOSED'; issue_state_reason='COMPLETED'; pr_ok=0
      issue_closers='[{"number":301}]'
      closer_json='{"headRefName":"issue-7/implementation","state":"MERGED"}'
      ;;
    # warrant-hunt regression (issue-295): stateReason COMPLETED with a
    # standing PR-review APPROVED but NO merged-implementation-branch PR
    # in closedByPullRequestsReferences -- e.g. a human closed the issue
    # as completed directly, with nothing new merged. stateReason alone
    # cannot tell this apart from the legitimate merge-close shape above;
    # only the closer-PR check can, so this must still deny.
    closed-completed-no-merge-closer-with-pr-review)
      issue_state='CLOSED'; issue_state_reason='COMPLETED'
      reviews='[{"author":{"login":"jw-human"},"state":"APPROVED"}]'
      ;;
  esac
  cat > "$1/gh" <<SCRIPT
#!/bin/sh
case "\$1" in
  issue) printf '%s' '{"state":"$issue_state","comments":$issue_comments,"stateReason":"$issue_state_reason","closedByPullRequestsReferences":$issue_closers}' ;;
  pr)
    case "\$*" in
      *headRefName*) printf '%s' '$closer_json' ;;
      *)
        if [ "$pr_ok" = 1 ]; then
          printf '%s' '{"reviews":$reviews}'
        else
          echo "no pull requests found" >&2
          exit 1
        fi
        ;;
    esac
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
  approvers="yes"; buildnow=""; checkpoint=""
  for o in "$@"; do
    case "$o" in
      noapprovers) approvers="no" ;;
      emptyapprovers) approvers="empty" ;;
      branch=*) branch="${o#branch=}" ;;
      role=*) role="${o#role=}" ;;
      cmd=*) tool="Bash"; cmd="${o#cmd=}" ;;
      buildnow) buildnow="1" ;;
      checkpoint) checkpoint="1" ;;
    esac
  done
  mktd
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
  stub_gh "$td/stub" "$mode" "$role"
  if [ "$tool" = "Bash" ]; then
    tinput="$(printf '{"command":"%s"}' "$cmd")"
  else
    tinput="$(printf '{"file_path":"%s","content":"x"}' "$fp")"
  fi
  printf '{"tool_name":"%s","tool_input":%s,"cwd":"%s"}' "$tool" "$tinput" "$td" \
    | env CLAUDE_PROJECT_DIR="$td" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" \
      CLAUDE_SKILL="$role" CORE_GH="$td/stub/gh" CORE_BUILD_NOW="$buildnow" \
      CORE_CHECKPOINT="$checkpoint" /bin/bash "$GATE" >/dev/null 2>&1
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

# --- issue-343: the issue-295 observer-role exemption is REMOVED -----------
# issue-295 used to lift the closed-issue precondition for exactly two
# named roles (execution-observation, conformance-review) when the issue
# closed via a MERGED PR on the implementation role's own branch --
# OBSERVER_ROLES, a hard-coded two-name tuple membership-tested at
# runtime, the same retired identity-keyed-exemption shape issue-2593
# already removed elsewhere in this codebase. issue-343 removed that
# capability rather than reintroduce the closed set (operator ruling,
# 2026-08-27): no role gets a closed-issue exemption anymore, period.
# The four cases below are the full 2x2 matrix from the issue (issue
# open/closed x close-came-from-an-implementation-merge or not),
# demonstrated for the previously-exempted role -- denied in every
# quadrant where the issue is not open, including the legitimate
# merge-close shape that used to be allowed; allowed on the open-issue
# quadrant, unaffected by any of this.
run deny  observer-completed-close-with-comment-now-denied closed-completed-with-comment src/app.py role=execution-observation branch=issue-7/execution-observation
run deny  observer-completed-close-conformance-review-now-denied closed-completed-with-comment src/app.py role=conformance-review branch=issue-7/conformance-review
run deny  observer-completed-close-no-approval  closed-completed-no-approval  src/app.py role=execution-observation branch=issue-7/execution-observation
# regression guard: a genuinely rejected/not-planned close still denies
# observer roles exactly like any other role.
run deny  observer-not-planned-close-with-comment closed-not-planned-with-comment src/app.py role=execution-observation branch=issue-7/execution-observation
# a non-observer role on the SAME merge-closed shape was already denied
# before issue-295 existed and stays denied now -- unaffected either way.
run deny  non-observer-completed-close-with-comment closed-completed-with-comment src/app.py role=coding
# issue-295's own regression guard (a human's manual re-close with
# nothing newly merged must deny everyone) still holds, now as a strict
# superset: with no exemption left at all, this denies too, same as
# before.
run deny  observer-completed-close-no-merge-closer closed-completed-no-merge-closer-with-pr-review src/app.py role=execution-observation branch=issue-7/execution-observation
# open-issue control (the other half of the 2x2 matrix): an observer
# role with a real Approve on an OPEN issue is unaffected by any of
# this -- the removed exemption only ever touched the closed-issue
# precondition. (mode "human" is a PR-review APPROVED, not
# role-text-matched, so it authorizes any role/branch pair the same
# way.)
run allow observer-open-issue-with-pr-review human src/app.py role=execution-observation branch=issue-7/execution-observation

# --- build-now bypass (contract v3 s19a, issue-212) ------------------------
# CORE_BUILD_NOW=1, set only by the spawner, skips the whole Approve chain
# even with no PR, no approvers file, and no issue comment at all.
run allow build-now-bypass-no-pr       nopr  src/app.py buildnow
run allow build-now-bypass-no-approvers nopr src/app.py buildnow noapprovers
run allow build-now-bypass-bash-write  nopr  x buildnow cmd='echo hi > src/app.py'
# empty state: the default (no CORE_BUILD_NOW) keeps section 19's gate.
run deny  build-now-unset-still-gated  nopr  src/app.py

# --- checkpoint mode (issue-275; on-the-record #2129) ----------------------
# Detection contract: CORE_CHECKPOINT=1, spawner-set (see the gate header).
# 1) checkpoint session + APPROVE comment on the issue: execution writes
#    proceed (the in-session phase transition after await-approval).
run allow checkpoint-approved-comment  comment-challenge src/app.py checkpoint
run allow checkpoint-approved-record   comment-challenge docs/issue-7/reports/coding.md checkpoint
# 2) checkpoint session with NO approval anywhere: still denied.
run deny  checkpoint-unapproved        nopr    src/app.py checkpoint
run deny  checkpoint-prose-comment     comment-prose src/app.py checkpoint
run deny  checkpoint-agent-comment     comment-challenge-agent src/app.py checkpoint
# 3) non-checkpoint sessions: byte-identical behavior — the existing matrix
#    above runs with CORE_CHECKPOINT unset/empty; additionally the refusal
#    TEXT must not change: no checkpoint wording without the stamp, and the
#    checkpoint wording appears only with it.
checkpoint_wording() {
  mktd
  git init -q "$td"
  git -C "$td" remote add origin git@github.com:tokenmaxxxer/probe.git
  git -C "$td" checkout -q -b issue-7/coding
  mkdir -p "$td/docs/specs" "$td/stub"
  cp "$CANON" "$td/docs/specs/role-handoff-contract.md"
  printf -- '- jw-human\n' > "$td/docs/specs/approvers.md"
  stub_gh "$td/stub" nopr
  payload="$(printf '{"tool_name":"Write","tool_input":{"file_path":"src/app.py","content":"x"},"cwd":"%s"}' "$td")"
  err_default="$(printf '%s' "$payload" \
    | env CLAUDE_PROJECT_DIR="$td" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" \
      CLAUDE_SKILL=coding CORE_GH="$td/stub/gh" /bin/bash "$GATE" 2>&1 >/dev/null)"
  err_ckpt="$(printf '%s' "$payload" \
    | env CLAUDE_PROJECT_DIR="$td" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" \
      CLAUDE_SKILL=coding CORE_GH="$td/stub/gh" CORE_CHECKPOINT=1 /bin/bash "$GATE" 2>&1 >/dev/null)"
  rm -rf "$td"
  got=absent; case "$err_default" in *checkpoint*|*CORE_CHECKPOINT*) got=present ;; esac
  report absent "$got" "default-refusal-has-no-checkpoint-wording"
  got=absent; case "$err_ckpt" in *await-approval*) got=present ;; esac
  report present "$got" "checkpoint-refusal-names-await-approval"
}
checkpoint_wording

# --- precondition: no remote, no approvals --------------------------------
noremote() {
  mktd
  git init -q "$td"
  git -C "$td" checkout -q -b issue-7/coding
  mkdir -p "$td/docs/specs" "$td/stub"
  cp "$CANON" "$td/docs/specs/role-handoff-contract.md"
  printf -- '- jw-human\n' > "$td/docs/specs/approvers.md"
  stub_gh "$td/stub" human
  printf '{"tool_name":"Write","tool_input":{"file_path":"src/app.py","content":"x"},"cwd":"%s"}' "$td" \
    | env CLAUDE_PROJECT_DIR="$td" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" \
      CLAUDE_SKILL=coding CORE_GH="$td/stub/gh" /bin/bash "$GATE" >/dev/null 2>&1
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

# --- cd read-classification, and quote-aware WRITEISH (ported from
# board-gate.sh, issue-88/PR #89; issue-90) -------------------------------
# READ_ONLY_HEADS had no "cd" entry, so a cd-prefixed read was denied
# outright even though the identical read without the cd prefix was
# allowed; WRITEISH was quote-blind, so a `>`/`|` inside a quoted string
# (e.g. a grep pattern) was flagged as if it were a real shell write-ish
# character.
run allow bash-cd-then-read-own-reports nopr x cmd='cd docs/issue-7/reports/coding && ls'
# negative-space sibling: a cd-headed line that really writes must still
# deny.
run deny  bash-cd-then-write-src        nopr x cmd='cd docs/issue-7 && echo x > src/app.py'
# issue-124 R1: the read-only early-allow head check used raw
# cmdline.strip().split()[0], with no TRANSPARENT-wrapper resolution, so a
# wrapped read missed the READ_ONLY_HEADS shortcut and fell through to the
# slower candidate scan with no PR to authorize it (over-block only).
run allow bash-wrapper-timeout-grep-read nopr x cmd='timeout 30 grep -rn foo src/app.py'
# negative-space sibling: a same-wrapper write must still deny, unchanged
# before/after -- the misread was fail-closed only, never a hole.
run deny  bash-wrapper-timeout-write     nopr x cmd='timeout 30 sh -c \"echo hi > src/app.py\"'
# NOTE: this harness's run() builds tinput via naive printf '%s' with no
# JSON-escaping, so a cmd= value carrying a literal `"` must pre-escape it
# to `\"` (and any literal `\` to `\\`) here so the constructed JSON stays
# valid and actually reaches _writeish's quote-span logic — an unescaped
# quote would instead break the JSON and deny via the unrelated
# unreadable-payload path, silently not testing the fix.
run allow bash-quoted-redirect-in-grep      nopr x cmd='grep -n \"a > b\" src/app.py'
run allow bash-single-quoted-pipe-grep      nopr x cmd='grep -n '\''a > b'\'' src/app.py'
# negative-space sibling: a real, unquoted pipe later in the same line
# must still deny.
run deny  bash-quoted-redirect-then-real-pipe nopr x cmd='grep -n \"a > b\" x | tee docs/issue-7/reports/coding.md'
# warrant-hunt regression (ported from board-gate's
# bash-escaped-quote-then-write, issue-88): a backslash-escaped quote
# CHARACTER outside any real shell quote must not open a fake quoted span
# that swallows the real `>` between two real tokens. Real command line
# this constructs (post JSON-unescape): ls \" > docs/issue-7/x.md #"
run deny  bash-escaped-quote-then-write nopr x cmd='ls \\\" > docs/issue-7/x.md #\"'

# --- the docs execution surface (doc-producing roles) ---------------------
run deny  record-before-approve  nopr    docs/issue-7/reports/coding.md
run deny  record-comment-only    comment docs/issue-7/reports/coding.md
run allow record-after-approve   human   docs/issue-7/reports/coding.md
run deny  foreign-area-preapprove nopr   docs/issue-7/specs/design.md
run deny  spikes-before-approve  nopr    docs/issue-7/reports/spikes/probe.md role=feasibility branch=issue-7/feasibility

# issue-290: a Bash-native heredoc write to the SAME phase-2 record path
# (docs/issue-<n>/reports/<role>.md) must deny/allow identically to the
# equivalent Write tool call above (record-before-approve/record-after-
# approve) -- the candidate-token scan already covers Bash generally
# (bash-redirect-src et al.), but nothing exercised it against a record
# path specifically until this pair.
run deny  bash-heredoc-record-before-approve nopr  x cmd='cat > docs/issue-7/reports/coding.md <<EOF\nfoo\nEOF'
run allow bash-heredoc-record-after-approve  human x cmd='cat > docs/issue-7/reports/coding.md <<EOF\nfoo\nEOF'

# --- not this gate's business (phase-1 homes and non-surface paths) -------
run allow proposal-write         nopr    docs/issue-7/proposals/p.md
run allow research-write         nopr    docs/issue-7/reports/coding/survey.md
run allow standing-docs-write    nopr    docs/reports/opportunity-tree.md
run allow readme-write           nopr    README.md

# non-role session: gate stands aside entirely
norole() {
  mktd
  git init -q "$td"
  printf '{"tool_name":"Write","tool_input":{"file_path":"src/app.py","content":"x"},"cwd":"%s"}' "$td" \
    | env -u CLAUDE_SKILL -u TOKENMAXXXER_SPAWNED CLAUDE_PROJECT_DIR="$td" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" \
      /bin/bash "$GATE" >/dev/null 2>&1
  rc=$?
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"
  report allow "$got" "no-role-session"
}
norole

# kill switch
kill_switch() {
  mktd
  git init -q "$td"
  printf '{"tool_name":"Write","tool_input":{"file_path":"src/app.py","content":"x"},"cwd":"%s"}' "$td" \
    | env CLAUDE_SKILL=coding CORE_OFF=1 CLAUDE_PROJECT_DIR="$td" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" \
      /bin/bash "$GATE" >/dev/null 2>&1
  rc=$?
  rm -rf "$td"
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  report allow "$got" "kill-switch"
}
kill_switch

# --- issue-138: fail-closed trap must survive rc propagation --------------
# empty stdin (delivery failure) must deny, not fall through the fast path.
empty_payload() {
  mktd; git init -q "$td"
  printf '' | env CLAUDE_SKILL=coding CLAUDE_PROJECT_DIR="$td" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" \
      /bin/bash "$GATE" >/dev/null 2>&1
  rc=$?
  rm -rf "$td"
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  report deny "$got" "empty-payload"
}
empty_payload

# a python3 that dies with an internal error (rc=1) must remap to exit 2
# (deny), not exit 1 — Claude Code treats a non-2 hook exit as non-blocking.
internal_error() {
  mktd; git init -q "$td"
  git -C "$td" remote add origin git@github.com:tokenmaxxxer/probe.git
  git -C "$td" checkout -q -b issue-7/coding
  mkdir -p "$td/docs/specs"
  cp "$CANON" "$td/docs/specs/role-handoff-contract.md"
  printf -- '- jw-human\n' > "$td/docs/specs/approvers.md"
  repo_td="$td"; mktd; stubdir="$td"; td="$repo_td"
  printf '#!/usr/bin/env bash\nexit 1\n' > "$stubdir/python3"
  chmod +x "$stubdir/python3"
  printf '{"tool_name":"Write","tool_input":{"file_path":"src/app.py","content":"x"},"cwd":"%s"}' "$td" \
    | env CLAUDE_SKILL=coding CLAUDE_PROJECT_DIR="$td" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" \
      PATH="$stubdir:$PATH" /bin/bash "$GATE" >/dev/null 2>&1
  rc=$?
  rm -rf "$td" "$stubdir"
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  report deny "$got" "python3-internal-error"
}
internal_error

# --- issue-288: gh --json field names must exist in gh's real schema -----
# stub_gh above ignores the requested --json field names entirely and
# always answers with state/comments/reviews, so a snake_case/camelCase
# typo like state_reason/stateReason denies every real check (fail
# closed) while every verdict-matrix test above still passes against the
# stub. This reads the field lists approval-gate.sh actually requests
# and asserts each one exists in the real `gh ... --help` JSON FIELDS
# list — no live issue/PR needed, so it runs offline.
gh_json_schema_check() {
  if ! command -v gh >/dev/null 2>&1; then
    report skip skip "gh-json-field-schema(gh-not-found)"
    return
  fi
  result="$(python3 - "$GATE" <<'PY'
import re, subprocess, sys

src = open(sys.argv[1]).read()

def requested(anchor):
    m = re.search(anchor + r'.*?"--json",\s*\n?\s*"([a-zA-Z,]+)"', src, re.S)
    return m.group(1).split(",") if m else []

def schema(subcmd):
    out = subprocess.run(["gh"] + subcmd.split() + ["--help"],
                          capture_output=True, text=True).stdout
    m = re.search(r"JSON FIELDS\n(.*?)\n\n", out, re.S)
    return re.findall(r"[A-Za-z]+", m.group(1)) if m else []

issue_fields = requested(r'"issue",\s*"view"')
pr_fields = requested(r'"pr",\s*"view"')
issue_schema = schema("issue view")
pr_schema = schema("pr view")

bad = [f for f in issue_fields if f not in issue_schema]
bad += [f for f in pr_fields if f not in pr_schema]
if not issue_fields or not pr_fields:
    print("FAIL:no-fields-found")
elif bad:
    print("FAIL:" + ",".join(bad))
else:
    print("ok")
PY
)"
  report ok "$result" "gh-json-field-schema"
}
gh_json_schema_check

printf '\n== %d passed, %d failed ==\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
