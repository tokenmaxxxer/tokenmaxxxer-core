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

# --- issue #20: endpoint+verb match, independent of client binary ---------
# Group A — a non-gh HTTP client hitting the exact REST endpoint the
# gh-spelled rules already cover. Newly denied by the widened RULES.
run deny  gap-a-curl-merge    coding 'curl -X PUT -H "Authorization: token TOK" https://api.github.com/repos/o/r/pulls/7/merge'
run deny  gap-a-wget-merge    coding 'wget --header="Authorization: token TOK" --method=PUT https://api.github.com/repos/o/r/pulls/7/merge'
run deny  gap-a-curl-review   coding 'curl -X POST -H "Authorization: token TOK" https://api.github.com/repos/o/r/pulls/7/reviews -d event=APPROVE'
# Same Group A shape against a literal IP instead of a hostname: the survey
# recorded this as an open Group C gap (Layer 0's *git* check only matched
# by the accident of "github" containing "git"), but the Layer 0 *curl*
# widening below closes it too, since the command still says "curl" and
# "https://" regardless of what host follows — verified here rather than
# assumed.
run deny  gap-a-curl-ip-merge coding 'curl -X PUT -H "Authorization: token TOK" https://140.82.112.6/repos/o/r/pulls/7/merge'

# Group B — `gh` itself, via call shapes the seven original rules never
# enumerated (GraphQL mutations, raw-API PR/issue state writes).
run deny  gap-b-graphql-merge   coding "gh api graphql -f query='mutation{ mergePullRequest(input:{pullRequestId:\"x\"}) }'"
run deny  gap-b-graphql-approve coding "gh api graphql -f query='mutation{ addPullRequestReview(input:{pullRequestId:\"x\", event: APPROVE}) }'"
run deny  gap-b-pr-close        coding 'gh api -X PATCH repos/o/r/pulls/7 -f state=closed'
run deny  gap-b-pr-reopen       coding 'gh api -X PATCH repos/o/r/pulls/7 -f state=open'
run deny  gap-b-issue-close     coding 'gh api -X PATCH repos/o/r/issues/7 -f state=closed'
run deny  gap-b-issue-edit      coding 'gh api -X PATCH repos/o/r/issues/7 -f title=pwned'

# Group C — not closable by widening a single-command-string matcher:
# still ALLOW on purpose, kept visible rather than silently dropped.
run allow gap-c-renamed-bin    coding '/tmp/x/ghcopy pr merge 7 --merge'
run allow gap-c-file-indirect  coding 'bash /tmp/whatever.sh'

# Group D — gh-guard only ever adjudicates Bash calls (gh-guard.sh:35); the
# identical denied text via a non-Bash tool is invisible to it by
# construction. run() always sets tool_name=Bash, so this case is probed
# directly rather than through the helper.
GD_PAYLOAD='{"tool_name":"Write","tool_input":{"file_path":"/tmp/x.sh","content":"curl -X PUT https://api.github.com/repos/o/r/pulls/7/merge"}}'
printf '%s' "$GD_PAYLOAD" | env CLAUDE_ROLE=coding /bin/bash "$GATE" >/dev/null 2>&1
gd_rc=$?; case "$gd_rc" in 0) gd_got=allow ;; 2) gd_got=deny ;; *) gd_got="exit-$gd_rc" ;; esac
if [ "$gd_got" = allow ]; then
  pass=$((pass+1)); printf 'ok     %-34s %s\n' gap-d-write-tool "$gd_got"
else
  fail=$((fail+1)); printf 'FAIL   %-34s want=%s got=%s\n' gap-d-write-tool allow "$gd_got"
fi

# --- issue #94: quote-aware matching for the three pure verb-invocation
# rules (review-verdict, merge/close/reopen, issue create/close/reopen/
# edit/transfer/delete) --------------------------------------------------
run allow quote-gh-pr-merge-in-grep     coding 'grep -n "^def \|gh pr merge\|pr merge" spawn.py'
run allow quote-review-approve-in-grep  coding 'grep -n "gh pr review --approve" notes.py'
run allow quote-issue-create-in-grep    coding 'grep -n "gh issue create" notes.py'
run deny  quote-real-merge-after-quote  coding 'grep -n "gh pr merge" x.py; gh pr merge 5'
# gap-f — an explicit, deliberately-NOT-fixed residual case: one of the
# eight unchanged rules (the raw-API endpoint+verb rule) stays quote-blind
# on purpose; kept visible rather than silently dropped (mirrors gap-c-*).
# Denies correctly here because of the real, unquoted curl call later on
# the line, not because of the quoted "pulls/5/merge" text.
run deny  gap-f-api-merge-in-quote-still-fires coding 'echo "note: pulls/5/merge discussed" ; curl -X PUT https://api.github.com/repos/o/r/pulls/5/merge'

printf '\n== %d passed, %d failed ==\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
