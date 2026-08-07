#!/usr/bin/env bash
# trailer-gate.sh, exercised as a real subprocess against real payloads
# (issue-141). Covers D1 (resolved-effect judging of the `-m` message
# instead of shlex-tokenizing the raw command string) and D3 (deny
# messages name a concrete, openable gate path).
#
# want: "allow" (exit 0) | "deny" (exit 2)
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
. "$HERE/../../core/hooks/tests/_tmp.sh"
GATE="$HERE/../../core/hooks/trailer-gate.sh"

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
# Repo staged with one file under docs/issue-141/reports/implementation/
# (so the trailer requirement gates), commit command supplied verbatim.
run() {
  want="$1"; name="$2"; cmdstr="$3"
  mktd
  git init -q "$td"
  git -C "$td" config user.email t@t.com
  git -C "$td" config user.name t
  mkdir -p "$td/docs/issue-141/reports/implementation"
  : > "$td/docs/issue-141/reports/implementation/x.md"
  git -C "$td" add docs/issue-141/reports/implementation/x.md
  payload="$(python3 -c 'import json,sys; print(json.dumps({"tool_name":"Bash","tool_input":{"command":sys.argv[1]}}))' "$cmdstr")"
  out="$(printf '%s' "$payload" | env CLAUDE_ROLE=implementation CLAUDE_PROJECT_DIR="$td" /bin/bash "$GATE" 2>&1)"
  rc=$?
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  last_out="$out"
  rm -rf "$td"
  report "$want" "$got" "$name"
}

# --- D1: heredoc/`$(...)` message resolution ------------------------------

# issue-280 idiom: real message carries the trailer, includes an embedded
# double quote that broke shlex before this fix. Must be ALLOWED — the
# resolved effect carries the trailer.
run allow heredoc-cat-with-trailer 'git commit -m "$(cat <<'"'"'EOF'"'"'
Fix widget "quoting" bug

Subject: issue-141
EOF
)"'

# issue-30 shape: the trailer string appears only in unresolved source
# text around the heredoc, never in what the expression actually
# resolves to. Must be DENIED — the bypass is closed.
run deny heredoc-source-text-only-trailer 'git commit -m "$(cat <<'"'"'EOF'"'"'
Fix bug, no trailer inside the resolved message
EOF
)"
# trailing comment mentions Subject: issue-141 but is not part of the message'

# `cat` with a file operand is a read primitive, not a heredoc reader —
# must be DENIED via the allowlist branch; the gate must never open the
# named file.
run deny cat-with-file-operand 'git commit -m "$(cat /etc/hostname)"'

# `printf`/`echo` are allowlisted only argument-shape-checked: a `-`
# flag (e.g. `echo -e`) must be DENIED, not silently executed.
run deny echo-with-flag-denied 'git commit -m "$(echo -e '"'"'Subject: issue-141'"'"')"'

# printf allowlist happy path: resolves and is judged on the resolved text.
run allow printf-with-trailer 'git commit -m "$(printf '"'"'Fix thing\n\nSubject: issue-141\n'"'"')"'

# A construct invoking a command outside cat/printf/echo (e.g. git) must
# never be executed by the gate — it falls to the same
# cannot-verify-statically deny as any other unresolvable construct.
run deny disallowed-command-in-substitution 'git commit -m "$(git log -1)"'

# --- unchanged plain-`-m` path (no $(...)/backtick/<<) --------------------
run allow plain-message-with-trailer 'git commit -m "docs(issue-141): plain message

Subject: issue-141"'
run deny plain-message-without-trailer 'git commit -m "docs(issue-141): plain message, no trailer"'

# --- D3: no deny message contains an unexpanded ${...} --------------------
unexpanded_found=0
DENY_LOG="$(mktemp -p "${TMPDIR:-/tmp}")"
capture() { # <command-string>
  mktd
  git init -q "$td"
  git -C "$td" config user.email t@t.com
  git -C "$td" config user.name t
  mkdir -p "$td/docs/issue-141/reports/implementation"
  : > "$td/docs/issue-141/reports/implementation/x.md"
  git -C "$td" add docs/issue-141/reports/implementation/x.md
  payload="$(python3 -c 'import json,sys; print(json.dumps({"tool_name":"Bash","tool_input":{"command":sys.argv[1]}}))' "$1")"
  printf '%s' "$payload" | env CLAUDE_ROLE=implementation CLAUDE_PROJECT_DIR="$td" /bin/bash "$GATE" >>"$DENY_LOG" 2>&1
  rm -rf "$td"
}
capture 'git commit -m "docs(issue-141): plain message, no trailer"'
capture 'git commit -m "$(cat /etc/hostname)"'
capture 'git commit -m "$(echo -e '"'"'x'"'"')"'
if grep -qF '${' "$DENY_LOG"; then
  unexpanded_found=1
fi
rm -f "$DENY_LOG"
if [ "$unexpanded_found" = 0 ]; then
  pass=$((pass + 1)); printf 'ok     %-34s %s\n' "no-unexpanded-dollar-brace" "pass"
else
  fail=$((fail + 1)); printf 'FAIL   %-34s %s\n' "no-unexpanded-dollar-brace" "found unexpanded \${ in deny output"
fi

# --- shadow-cat: a `cat` shadowed earlier on the session PATH must not --
# fool the resolved-trailer check (resolution uses the load-time-resolved
# absolute path, never a PATH lookup).
mktd
git init -q "$td"
git -C "$td" config user.email t@t.com
git -C "$td" config user.name t
mkdir -p "$td/docs/issue-141/reports/implementation"
: > "$td/docs/issue-141/reports/implementation/x.md"
git -C "$td" add docs/issue-141/reports/implementation/x.md

# A passthrough shadow: it forwards to the real /bin/cat unchanged (so the
# gate's own payload-read `cat` call, unrelated to D1's resolution, still
# works) but logs every invocation. D1's `-m` resolution runs the
# allowlisted command with PATH cleared and `cat` substituted for its
# load-time-resolved absolute path, so it should never invoke this shadow
# at all — only the gate's single payload-read call should appear in the
# log.
fakebin="$(mktemp -d -p "${TMPDIR:-/tmp}")"
shadow_log="$(mktemp -p "${TMPDIR:-/tmp}")"
printf '#!/bin/sh\necho "SHADOW_CAT_INVOKED args=$*" >> %s\nexec /bin/cat "$@"\n' "$shadow_log" > "$fakebin/cat"
chmod +x "$fakebin/cat"

payload="$(python3 -c 'import json; print(json.dumps({"tool_name":"Bash","tool_input":{"command":"git commit -m \"$(cat <<'"'"'EOF'"'"'\nSubject: issue-141\nEOF\n)\""}}))')"
out="$(printf '%s' "$payload" | env CLAUDE_ROLE=implementation CLAUDE_PROJECT_DIR="$td" PATH="$fakebin:$PATH" /bin/bash "$GATE" 2>&1)"
rc=$?
invocations="$(wc -l < "$shadow_log" | tr -d ' ')"
rm -rf "$td" "$fakebin"
rm -f "$shadow_log"
case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
if [ "$got" = allow ] && [ "$invocations" = 1 ]; then
  pass=$((pass + 1)); printf 'ok     %-34s %s\n' "shadowed-cat-not-trusted" "allow, resolution bypassed shadow (1 unrelated invocation)"
else
  fail=$((fail + 1)); printf 'FAIL   %-34s got=%s invocations=%s out=%s\n' "shadowed-cat-not-trusted" "$got" "$invocations" "$out"
fi

echo "-- trailer-gate: $pass passed, $fail failed --"
[ "$fail" = 0 ]
