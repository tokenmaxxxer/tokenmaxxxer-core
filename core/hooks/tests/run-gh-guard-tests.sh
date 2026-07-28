#!/usr/bin/env bash
# gh-guard.sh as a real subprocess. want: allow(0) | deny(2)
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
GATE="$HERE/../gh-guard.sh"
pass=0; fail=0
run() { # want name role cmd
  printf '{"tool_name":"Bash","tool_input":{"command":%s}}' \
    "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$4")" \
    | { if [ -n "$3" ]; then env CLAUDE_ROLE="$3" /bin/bash "$GATE"; else env -u CLAUDE_ROLE /bin/bash "$GATE"; fi; } >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  if [ "$got" = "$1" ]; then pass=$((pass+1)); printf 'ok     %-34s %s\n' "$2" "$got"; else fail=$((fail+1)); printf 'FAIL   %-34s want=%s got=%s\n' "$2" "$1" "$got"; fi
}
run deny  role-approve       coding 'gh pr review 7 --approve'
run deny  role-request-ch    coding 'gh pr review 7 --request-changes -b "x"'
run deny  role-merge         coding 'gh pr merge 7 --merge'
run deny  role-close-pr      coding 'gh pr close 7'
run deny  role-issue-create  qa     'gh issue create --title bug'
run deny  role-issue-close   qa     'gh issue close 3'
run deny  role-api-review    coding 'gh api repos/o/r/pulls/7/reviews -f event=APPROVE'
run deny  role-api-merge     coding 'gh api -X PUT repos/o/r/pulls/7/merge'
run deny  role-push-main     coding 'git push origin main'
run deny  role-approve-comment coding 'gh pr comment 7 --body "APPROVE issue-7/coding"'
run deny  role-approve-api-cm  coding 'gh api repos/o/r/issues/7/comments -f body="APPROVE issue-7/coding"'
run allow role-plain-comment   coding 'gh pr comment 7 --body "phase 1 ready for review"'
run allow role-push-branch   coding 'git push -u origin issue-7/coding'
run allow role-pr-create     coding 'gh pr create --title x --body y'
run allow role-pr-view       coding 'gh pr view 7 --json reviews'
run allow role-issue-view    coding 'gh issue view 3'
run allow role-plain-git     coding 'git commit -m "x"'
run allow norole-approve     ""     'gh pr review 7 --approve'
run allow norole-merge       ""     'gh pr merge 7 --merge'
printf '\n== %d passed, %d failed ==\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
