#!/usr/bin/env bash
# gh-guard.sh as a real subprocess. want: allow(0) | deny(2)
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
GATE="$HERE/../gh-guard.sh"
. "$HERE/_tmp.sh"
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

# --- issue #98: wrapper-headed commands (bash -c/sh -c/eval/-lc variants,
# including through TRANSPARENT) still execute their quoted argument, so
# gate_dequote's blanking must not blind the three dequote=True rules to
# them. One case per issue-named variant, spread across all three in-scope
# rules (merge, review --approve, issue create) rather than all merge. ----
run deny  wrapper-bash-c            coding 'bash -c "gh pr merge 5"'
run deny  wrapper-bash-lc           coding 'bash -lc "gh pr merge 7 --merge"'
run deny  wrapper-timeout-bash-c    coding 'timeout 30 bash -c "gh pr merge 7 --merge"'
run deny  wrapper-env-bash-c        coding 'env bash -c "gh pr review 7 --approve"'
run deny  wrapper-xargs-bash-c      coding 'xargs -I{} bash -c "gh pr merge 7 --merge"'
run deny  wrapper-nohup-bash-c      qa     'nohup bash -c "gh issue create --title bug"'
run deny  wrapper-python3-c         coding 'python3 -c "import os; os.system('"'"'gh pr merge 7 --merge'"'"')"'
run deny  wrapper-sh-c              coding 'sh -c "gh pr merge 5"'
run deny  wrapper-eval              coding 'eval "gh pr merge 5"'
# hunt-confirmed (docs/issue-98/reports/implementation.md, Hunt): a
# TRANSPARENT wrapper's OWN value-taking flag (nice -n N, env -u NAME,
# timeout -s SIG, xargs -I fmt with a space instead of xargs -I{})
# defeated the first design (which walked gate_head_of's hop-by-hop
# TRANSPARENT skip), landing on the flag's value token instead of the
# real wrapper head -- fixed by scanning local words directly for the
# rightmost WRAPPER_HEADS word instead of depending on that walk.
run deny  wrapper-timeout-flag-arg  coding 'timeout -s KILL 30 bash -c "gh pr merge 5"'
run deny  wrapper-nice-flag-arg     coding 'nice -n 10 bash -c "gh pr merge 5"'
run deny  wrapper-env-flag-arg      coding 'env -u FOO bash -c "gh pr merge 5"'
run deny  wrapper-xargs-space-flag  coding 'xargs -I {} bash -c "gh pr merge 5"'
# hunt-confirmed: perl's own code-argument flag is -e, not -c (-c means
# "check syntax, don't run" for perl) -- the -c-only flag check missed
# perl entirely despite perl being a named WRAPPER_HEADS member.
run deny  wrapper-perl-e            coding 'perl -e "system('"'"'gh pr merge 5'"'"')"'
# accepted over-block residual (proposal Rationale, docs/issue-98/proposals/
# 2026-08-03-wrapper-head-class-fix-for-dequote-bypass.md): the per-span
# resolver denies on the wrapper head firing, whatever the wrapper's own
# quoted argument actually contains -- a real bash -c wrapping a
# LEGITIMATE nested grep still denies, kept visible rather than silently
# accepted (mirrors the gap-c-*/gap-f-* convention).
run deny  wrapper-bash-c-plain-grep coding 'bash -c "grep -n '"'"'gh pr merge'"'"' x.py"'
# the three existing quote-* negative-space cases above (lines 78-80) are
# re-run unchanged by this same suite run -- still allow, confirming the
# wrapper-head class fix adds a new detection path without undoing #94's
# dequoting for non-wrapper heads.

# --- issue-138: fail-closed trap must survive rc propagation --------------
# empty stdin (delivery failure) must deny, not silently fall through the
# fast path and exit 0.
empty_payload() {
  printf '' | env CLAUDE_ROLE=coding /bin/bash "$GATE" >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  if [ "$got" = deny ]; then pass=$((pass+1)); printf 'ok     %-34s %s\n' "empty-payload" "$got"; else fail=$((fail+1)); printf 'FAIL   %-34s want=deny got=%s\n' "empty-payload" "$got"; fi
}
empty_payload

# a python3 that dies with an internal error (rc=1, e.g. an import/compat
# failure) must remap to exit 2 (deny), not exit 1 (Claude Code's
# non-blocking code) — the fail-closed promise the header makes.
internal_error() {
  mktd; stubdir="$td"
  cat > "$stubdir/python3" <<'SH'
#!/usr/bin/env bash
exit 1
SH
  chmod +x "$stubdir/python3"
  printf '{"tool_name":"Bash","tool_input":{"command":"gh pr merge 7"}}' \
    | env CLAUDE_ROLE=coding PATH="$stubdir:$PATH" /bin/bash "$GATE" >/dev/null 2>&1
  rc=$?; rm -rf "$stubdir"
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  if [ "$got" = deny ]; then pass=$((pass+1)); printf 'ok     %-34s %s\n' "python3-internal-error" "$got"; else fail=$((fail+1)); printf 'FAIL   %-34s want=deny got=%s\n' "python3-internal-error" "$got"; fi
}
internal_error

printf '\n== %d passed, %d failed ==\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
