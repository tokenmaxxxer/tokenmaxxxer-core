#!/usr/bin/env bash
# issue-280: top-denier friction.
#
# Part A -- record-fields-gate actionable refusals, against a synthetic
# workspace whose git diff is readable:
#   - a bare-sha code_under_review stays refused, and the refusal message
#     carries the expected field shape AND the actual changed-file list
#     from `git diff --name-only HEAD` as the suggested value
#   - the combined form (sha line + indented file list) is accepted
#   - a plain file list keeps being accepted
#
# Part B -- fixture replay of the tm-dicequest#83 shape: a docs-only
# amendment (one doc + the record) driven through its full landing command
# sequence -- edit doc, write record with file list, git add/commit,
# gh pr create with a quoted-heredoc body -- asserting ZERO denials from
# board-gate and record-fields-gate. gh is never actually invoked on the
# allow path; CORE_GH points at a mock anyway so any accidental call is a
# harmless no-op.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
. "$HERE/_tmp.sh"
HOOKS="$(cd "$HERE/.." && pwd -P)"
PLUGIN_ROOT="$(cd "$HERE/../.." && pwd -P)"

pass=0
fail=0
report() { # <want> <got> <name>
  if [ "$2" = "$1" ]; then
    pass=$((pass + 1)); printf 'ok     %-52s %s\n' "$3" "$2"
  else
    fail=$((fail + 1)); printf 'FAIL   %-52s want=%s got=%s\n' "$3" "$1" "$2"
  fi
}

# --- Part A: record-fields actionable refusals ---------------------------

# synthetic workspace: a git repo with one commit and two uncommitted
# changed files, so `git diff --name-only HEAD` has real content.
mk_workspace() { # sets $td
  mktd
  git init -q "$td"
  ( cd "$td" \
    && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init \
    && mkdir -p docs/issue-9/reports docs/issue-9/proposals \
    && echo doc > docs/issue-9/proposals/amend.md \
    && echo rec > docs/issue-9/reports/coding.md \
    && git add -A )
}

RECORD_OK_FIELDS='loop_state: landed\n\n## what was done\nx\n\n## why\ny\n\nupstream: docs/issue-9\n\n## open findings\nnone\n'

run_rf() { # <want> <name> <content-json-string>; sets $out
  want="$1"; name="$2"; content="$3"
  mk_workspace
  payload="$(printf '{"tool_name":"Write","tool_input":{"file_path":"%s/docs/issue-9/reports/coding.md","content":%s}}' "$td" "$content")"
  out="$(printf '%s' "$payload" | env CLAUDE_ROLE=coding CLAUDE_PROJECT_DIR="$td" \
      CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" /bin/bash "$HOOKS/record-fields-gate.sh" 2>&1)"
  rc=$?
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"
  report "$want" "$got" "$name"
}

# 1. bare sha only: still refused (contract unweakened) ...
run_rf deny  "rf: bare-sha code_under_review still refused" \
  '"'"$RECORD_OK_FIELDS"'code_under_review: abc1234def\n"'
# ... and the refusal carries the expected shape and the suggested value
# built from the workspace's own changed-file list.
case "$out" in
  *"Expected shape"*) report yes yes "rf: refusal names the expected field shape" ;;
  *) report yes no "rf: refusal names the expected field shape" ;;
esac
case "$out" in
  *"git diff --name-only HEAD"*"docs/issue-9/proposals/amend.md"*) report yes yes "rf: refusal suggests the actual changed-file list" ;;
  *) report yes no "rf: refusal suggests the actual changed-file list" ;;
esac

# 2. combined form: sha line + indented file list -> accepted.
run_rf allow "rf: combined sha + indented file list accepted" \
  '"'"$RECORD_OK_FIELDS"'code_under_review: abc1234def\n  - docs/issue-9/proposals/amend.md\n  - docs/issue-9/reports/coding.md\n"'

# 3. plain file list on the field line keeps being accepted.
run_rf allow "rf: plain file-list value accepted" \
  '"'"$RECORD_OK_FIELDS"'code_under_review: docs/issue-9/proposals/amend.md docs/issue-9/reports/coding.md\n"'

# 4. sha followed by indented NON-file prose is not a file list -> refused.
run_rf deny  "rf: sha + indented prose is not a file list" \
  '"'"$RECORD_OK_FIELDS"'code_under_review: abc1234def\n  reviewed carefully\n"'

# --- Part B: docs-only-amendment fixture replay --------------------------
# The tm-dicequest#83 landing sequence, replayed step by step through BOTH
# gates. Every step must allow; a single deny fails the replay.

replay_step() { # <name> <tool> <tool-input-json>
  name="$1"; tool="$2"; tinput="$3"
  payload="$(printf '{"tool_name":"%s","tool_input":%s,"cwd":"%s"}' "$tool" "$tinput" "$fx")"
  bg_out="$(printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$fx" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" \
      CLAUDE_ROLE=coding CORE_GH="$fx/bin/gh" /bin/bash "$HOOKS/board-gate.sh" 2>&1)"
  bg_rc=$?
  rf_out="$(printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$fx" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" \
      CLAUDE_ROLE=coding /bin/bash "$HOOKS/record-fields-gate.sh" 2>&1)"
  rf_rc=$?
  if [ "$bg_rc" = 0 ] && [ "$rf_rc" = 0 ]; then
    got=allow
  else
    got="deny(board=$bg_rc,record-fields=$rf_rc)"
    denials=$((denials + 1))
    echo "  board-gate: $bg_out"
    echo "  record-fields-gate: $rf_out"
  fi
  report allow "$got" "replay: $name"
}

mktd
fx="$td"
git init -q "$fx"
git -C "$fx" remote add origin git@github.com:tokenmaxxxer/probe.git
git -C "$fx" checkout -q -b issue-9/coding
mkdir -p "$fx/docs/specs" "$fx/docs/issue-9/reports" "$fx/docs/issue-9/proposals" "$fx/bin"
printf -- '- jw-human\n' > "$fx/docs/specs/approvers.md"
printf '#!/bin/sh\nexit 0\n' > "$fx/bin/gh"   # gh mocked: never a real call
chmod +x "$fx/bin/gh"
printf 'original doc\n' > "$fx/docs/issue-9/proposals/amend.md"
git -C "$fx" -c user.email=t@t -c user.name=t add -A
git -C "$fx" -c user.email=t@t -c user.name=t commit -q -m base
denials=0

# step 1: edit the doc
replay_step "edit doc" Write \
  '{"file_path":"'$fx'/docs/issue-9/proposals/amend.md","content":"amended doc\n"}'
# step 2: write the record, code_under_review as a file list
replay_step "write record with file list" Write \
  '{"file_path":"'$fx'/docs/issue-9/reports/coding.md","content":"loop_state: landed\n\n## what was done\namended the doc\n\n## why\ndocs-only amendment\n\nupstream: docs/issue-9\n\n## open findings\nnone\n\ncode_under_review: docs/issue-9/proposals/amend.md docs/issue-9/reports/coding.md\n"}'
# step 3: git add + commit with a quoted-heredoc message
replay_step "git add" Bash \
  '{"command":"git add docs/issue-9/proposals/amend.md docs/issue-9/reports/coding.md"}'
replay_step "git commit with quoted heredoc" Bash \
  '{"command":"git commit -m \"$(cat <<'"'"'EOF'"'"'\ndocs: amend docs/issue-9/proposals/amend.md\n\nSubject: issue-9\nEOF\n)\""}'
# step 4: gh pr create with a quoted-heredoc body
replay_step "gh pr create with quoted heredoc body" Bash \
  '{"command":"gh pr create --title \"docs: issue-9 amendment\" --body \"$(cat <<'"'"'EOF'"'"'\n## what\namends docs/issue-9/proposals/amend.md\n\n## record\ndocs/issue-9/reports/coding.md\nEOF\n)\""}'

report 0 "$denials" "replay: zero denials across the landing sequence"
rm -rf "$fx"

printf '\n== %d passed, %d failed ==\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
