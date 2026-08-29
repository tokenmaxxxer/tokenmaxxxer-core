#!/usr/bin/env bash
# handbook-trigger-gate.sh, exercised as a real subprocess against real
# payloads (issue-141). Covers D2 (project `git add --dry-run` for
# preceding `git add` segments before judging staged state) and D3 (deny
# messages name a concrete, openable gate path).
#
# want: "allow" (exit 0) | "deny" (exit 2)
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
. "$HERE/../../core/hooks/tests/_tmp.sh"
GATE="$HERE/../../core/hooks/handbook-trigger-gate.sh"

pass=0
fail=0

report() { # <want> <got> <name>
  if [ "$2" = "$1" ]; then
    pass=$((pass + 1)); printf 'ok     %-34s %s\n' "$3" "$2"
  else
    fail=$((fail + 1)); printf 'FAIL   %-34s want=%s got=%s\n' "$3" "$1" "$2"
  fi
}

# run <want> <name> <command-string>
# Repo with requirements.txt (an operational-surface path) already staged
# and docs/handbooks/foo.md present on disk but NOT staged, so each case
# controls whether/how the handbook gets staged via the command itself.
run() {
  want="$1"; name="$2"; cmdstr="$3"
  mktd
  git init -q "$td"
  git -C "$td" config user.email t@t.com
  git -C "$td" config user.name t
  printf 'flask\n' > "$td/requirements.txt"
  git -C "$td" add requirements.txt
  mkdir -p "$td/docs/handbooks"
  printf 'hb update\n' > "$td/docs/handbooks/foo.md"
  payload="$(python3 -c 'import json,sys; print(json.dumps({"tool_name":"Bash","tool_input":{"command":sys.argv[1]}}))' "$cmdstr")"
  out="$(printf '%s' "$payload" | env CLAUDE_SKILL=implementation CLAUDE_PROJECT_DIR="$td" /bin/bash "$GATE" 2>&1)"
  rc=$?
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  last_out="$out"
  rm -rf "$td"
  report "$want" "$got" "$name"
}

# --- D2: git-add projection before the staged-state check -----------------

# Idiomatic add+commit: the handbook update is exactly what the pending
# `git add` would stage. Must be ALLOWED — before the fix, PreToolUse
# denied this unconditionally because `git add` never ran before the
# staged-state read.
run allow addcommit-handbook-satisfies 'git add docs/handbooks/foo.md && git commit -m "chore: add requirements.txt with handbook update"'

# Bare commit, handbook neither staged nor pending: genuine violation,
# must still be DENIED.
run deny bare-commit-no-handbook 'git commit -m "chore: add requirements.txt, no handbook staged"'

# `git add` whose pathspec depends on shell/variable expansion cannot be
# projected statically — must be DENIED with a message distinguishable
# from the genuine-violation message (not "does not touch any
# docs/handbooks").
run deny addcommit-unresolvable-pathspec 'git add "$HBFILE" && git commit -m "chore: add requirements.txt via variable pathspec"'
if ! printf '%s' "$last_out" | grep -q "cannot be projected statically"; then
  fail=$((fail + 1)); printf 'FAIL   %-34s message not distinguishable from genuine violation: %s\n' "addcommit-unresolvable-pathspec-message" "$last_out"
else
  pass=$((pass + 1)); printf 'ok     %-34s %s\n' "addcommit-unresolvable-pathspec-message" "distinguishable"
fi

# warrant-hunt (before-landing, 2026-08-07): a dash-named pathspec (or the
# `--` separator) must not be silently dropped from the `git add`
# projection — a script named e.g. `-setup.sh` staged via
# `git add -- -setup.sh` is still an operational surface and must still
# trigger the handbook obligation.
mktd
git init -q "$td"
git -C "$td" config user.email t@t.com
git -C "$td" config user.name t
mkdir -p "$td/-mydir"
printf 'flask\n' > "$td/-mydir/requirements.txt"
payload="$(python3 -c 'import json; print(json.dumps({"tool_name":"Bash","tool_input":{"command":"git add -- -mydir/requirements.txt && git commit -m \"chore: add dash-prefixed-pathspec dependency manifest, no handbook\""}}))')"
out="$(printf '%s' "$payload" | env CLAUDE_SKILL=implementation CLAUDE_PROJECT_DIR="$td" /bin/bash "$GATE" 2>&1)"
rc=$?
rm -rf "$td"
case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
report deny "$got" addcommit-dash-named-pathspec-still-denied

# --- D3: no deny message contains an unexpanded ${...} --------------------
DENY_LOG="$(mktemp -p "${TMPDIR:-/tmp}")"
capture() { # <command-string>
  mktd
  git init -q "$td"
  git -C "$td" config user.email t@t.com
  git -C "$td" config user.name t
  printf 'flask\n' > "$td/requirements.txt"
  git -C "$td" add requirements.txt
  payload="$(python3 -c 'import json,sys; print(json.dumps({"tool_name":"Bash","tool_input":{"command":sys.argv[1]}}))' "$1")"
  printf '%s' "$payload" | env CLAUDE_SKILL=implementation CLAUDE_PROJECT_DIR="$td" /bin/bash "$GATE" >>"$DENY_LOG" 2>&1
  rm -rf "$td"
}
capture 'git commit -m "chore: add requirements.txt, no handbook"'
capture 'git add "$HBFILE" && git commit -m "chore: variable pathspec"'
unexpanded_found=0
if grep -qF '${' "$DENY_LOG"; then
  unexpanded_found=1
fi
rm -f "$DENY_LOG"
if [ "$unexpanded_found" = 0 ]; then
  pass=$((pass + 1)); printf 'ok     %-34s %s\n' "no-unexpanded-dollar-brace" "pass"
else
  fail=$((fail + 1)); printf 'FAIL   %-34s %s\n' "no-unexpanded-dollar-brace" "found unexpanded \${ in deny output"
fi

echo "-- handbook-trigger-gate: $pass passed, $fail failed --"
[ "$fail" = 0 ]
