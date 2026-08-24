#!/usr/bin/env bash
# core/hooks/directive.sh's core interaction-protocol heredoc must instruct
# staging of NEW/untracked files before commit, not just `git commit -m`/
# `-am` (issue-203): `-a`/`-am` only stages modifications to already-tracked
# paths, never untracked ones, so a role that never `git add`s a new file
# produces an empty/incomplete commit and a "No commits between main and
# branch" gh pr create failure.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
HOOKS="$(cd "$HERE/.." && pwd -P)"

pass=0
fail=0
report() { # <want> <got> <name>
  if [ "$2" = "$1" ]; then
    pass=$((pass + 1)); printf 'ok     %-60s %s\n' "$3" "$2"
  else
    fail=$((fail + 1)); printf 'FAIL   %-60s want=%s got=%s\n' "$3" "$1" "$2"
  fi
}

# issue-278: staging guidance lives in the corpus = rendered index +
# core/directive/session-protocol.md (the on-demand section file).
SECTION="$(cd "$HOOKS/.." && pwd -P)/directive/session-protocol.md"
out="$(CLAUDE_ROLE=implementation bash "$HOOKS/directive.sh" 2>/dev/null; cat "$SECTION")"

commit_line=""
case "$out" in *"git commit -m"*) commit_line=present ;; esac
report present "${commit_line:-absent}" "renders the git commit -m requirement"

staging_line=""
case "$out" in *"git add"*) staging_line=present ;; esac
report present "${staging_line:-absent}" "renders a new-file staging (git add) instruction"

# empty-state: a directive text mentioning only git commit -m/-am with no
# staging step must be caught as a failure, not silently pass.
fake_directive_no_staging="- A commit that stages any docs/issue-<n>/** work must use git commit -m
  and carry a Subject: issue-<n> trailer naming that issue, one commit
  per subject."
staging_in_fake=""
case "$fake_directive_no_staging" in *"git add"*) staging_in_fake=1 ;; esac
report absent "${staging_in_fake:-absent}" "empty-state fixture (git commit -m/-am only) has no staging step"

# scoping: the instruction must explicitly rule out a blanket git add -A/.
# (not merely be silent about it).
scoped=""
case "$out" in *"never a blanket git add"*) scoped=present ;; esac
report present "${scoped:-absent}" "explicitly rules out a blanket git add -A/."

echo
echo "role-directive-staging: $pass passed, $fail failed"
[ "$fail" = 0 ]
