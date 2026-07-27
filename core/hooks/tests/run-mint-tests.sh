#!/usr/bin/env bash
# Runs mint.sh as a real subprocess against real prompts and asserts on what it
# left behind — the token's `kind` and `subject`, never its filename alone.
#
# The rejected cases are not hypothetical. Every one of them minted a valid,
# consumable token against some earlier version of this hook, measured
# 2026-07-27. They are kept as the record of what "contains an approval" costs.
set -uo pipefail

HOOK="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/../mint.sh"
KIND="scope-proposed--scope-approved"
SUB="2026-07-27-laundry-drying-time"
LINE="APPROVE $KIND $SUB"
pass=0
fail=0

# want: "reject" | "mint:<kind>/<subject>"
check() {
  want="$1"; name="$2"; prompt="$3"
  td="$(mktemp -d)"
  git init -q "$td"
  payload="$(python3 -c '
import json, sys
print(json.dumps({"prompt": sys.argv[1], "cwd": sys.argv[2]}))' "$prompt" "$td")"
  printf '%s' "$payload" | CLAUDE_PROJECT_DIR="$td" /bin/bash "$HOOK" >/dev/null 2>&1
  tok="$(find "$td" -name '*.token' -type f | head -1)"
  if [ -n "$tok" ]; then
    got="mint:$(python3 -c '
import re, sys
t = open(sys.argv[1], encoding="utf-8").read()
def f(k):
    m = re.search(r"^" + k + r":\s*(.*)$", t, re.M)
    return m.group(1).strip() if m else "?"
print(f("kind") + "/" + f("subject"))' "$tok")"
  else
    got=reject
  fi
  rm -rf "$td"
  if [ "$got" = "$want" ]; then
    pass=$((pass + 1)); printf 'ok     %-26s %s\n' "$name" "$got"
  else
    fail=$((fail + 1)); printf 'FAIL   %-26s want=%s got=%s\n' "$name" "$want" "$got"
  fi
}

# --- the one thing that mints ------------------------------------------
check "mint:$KIND/$SUB" exact              "$LINE"
check "mint:$KIND/$SUB" exact-trailing-nl  "$LINE
"
check "mint:$KIND/$SUB" exact-leading-ws   "   $LINE   "

# --- prose approvals: the entire class that leaked before ---------------
check reject prose-en           "I approve the scope for subject $SUB."
check reject prose-ko           "subject $SUB 의 scope 를 승인한다."
check reject reported-speech    "The reviewer asked me to approve the scope for subject $SUB."
check reject conditional        "Once CI is green, approve the scope for subject $SUB."
check reject past-tense         "Last week I approved the scope for subject $SUB."
check reject negation-then-yes  "Do not approve. Actually, approve the scope for subject $SUB."
check reject asking-how         "Tell me how to approve the scope for subject $SUB."
check reject retraction         "Cancel that. I approve the scope for subject $SUB was a mistake."
check reject refusal-ko         "subject $SUB 승인 못 한다."
check reject state-mention      "subject $SUB 는 아직 scope-approved 가 아니다."
check reject contract-quote     "Section 19 makes subject $SUB reaching scope-approved a human-owned edge."

# --- the line, but not alone: containment is not equality ---------------
check reject line-with-preamble  "Send this to approve: $LINE"
check reject line-with-suffix    "$LINE -- but only after the review lands."
check reject line-in-fence       "To approve, reply:

\`\`\`
$LINE
\`\`\`"
check reject line-quoted         "You wrote \"$LINE\" but I have not decided yet."
check reject two-lines           "I am not approving this.
$LINE"

# --- malformed lines ----------------------------------------------------
check reject lowercase          "approve $KIND $SUB"
check reject no-subject         "APPROVE $KIND"
check reject no-kind            "APPROVE $SUB"
check reject extra-field        "APPROVE $KIND $SUB now"
check reject bad-subject-chars  "APPROVE $KIND ../../etc/passwd"
check reject bad-kind-chars     "APPROVE ../$KIND $SUB"
check reject empty              ""
check reject bare-assent        "ok"

# --- environment --------------------------------------------------------
check_env() {
  want="$1"; name="$2"; shift 2
  td="$(mktemp -d)"
  git init -q "$td"
  payload="$(python3 -c '
import json, sys
print(json.dumps({"prompt": sys.argv[1], "cwd": sys.argv[2]}))' "$LINE" "$td")"
  printf '%s' "$payload" | env "$@" CLAUDE_PROJECT_DIR="$td" /bin/bash "$HOOK" >/dev/null 2>&1
  tok="$(find "$td" -name '*.token' -type f | head -1)"
  [ -n "$tok" ] && got=mint || got=reject
  rm -rf "$td"
  if [ "$got" = "$want" ]; then
    pass=$((pass + 1)); printf 'ok     %-26s %s\n' "$name" "$got"
  else
    fail=$((fail + 1)); printf 'FAIL   %-26s want=%s got=%s\n' "$name" "$want" "$got"
  fi
}

check_env reject kill-switch  CORE_OFF=1
check_env reject unattended   TOKENMAXXXER_UNATTENDED=1
# An orchestrator-spawned session's prompt is orchestrator-authored text: the
# stdin task arrives verbatim as the UserPromptSubmit prompt (measured
# 2026-07-27), so a spawn task of exactly the challenge line would mint an
# actor:user token with no human involved. muster stamps every spawn with
# TOKENMAXXXER_SPAWNED=1; the mint must be inert under it.
check_env reject spawned      TOKENMAXXXER_SPAWNED=1

# --- boundary and encoding: the equality check itself --------------------
K128="$(python3 -c 'print("k" * 128)')"
K129="$(python3 -c 'print("k" * 129)')"
check "mint:$K128/$SUB" kind-128-chars    "APPROVE $K128 $SUB"
check reject            kind-129-chars    "APPROVE $K129 $SUB"
check "mint:$KIND/$K128" subject-128       "APPROVE $KIND $K128"
check reject            subject-129       "APPROVE $KIND $K129"
check "mint:$KIND/$SUB" crlf              "$(printf 'APPROVE %s %s\r' "$KIND" "$SUB")"
# A separator that only LOOKS like a space is not a space. Zero coverage of
# this class before 2026-07-27; it is the highest-yield attack on equality.
check reject nbsp-separator    "$(python3 -c 'print("APPROVE " + "'"$KIND"'" + " " + "'"$SUB"'")')"
check reject fullwidth-approve "$(python3 -c 'print("ＡＰＰＲＯＶＥ " + "'"$KIND"'" + " " + "'"$SUB"'")')"
check reject cyrillic-a        "$(python3 -c 'print("АPPROVE " + "'"$KIND"'" + " " + "'"$SUB"'")')"
check reject zwsp-prefix       "$(python3 -c 'print("​" + "APPROVE " + "'"$KIND"'" + " " + "'"$SUB"'")')"

# --- malformed payloads: the isinstance guards ---------------------------
payload_check() {
  want="$1"; name="$2"; raw="$3"
  td="$(mktemp -d)"
  git init -q "$td"
  printf '%s' "$raw" | CLAUDE_PROJECT_DIR="$td" /bin/bash "$HOOK" >/dev/null 2>&1
  [ -n "$(find "$td" -name '*.token' -type f | head -1)" ] && got=mint || got=reject
  rm -rf "$td"
  if [ "$got" = "$want" ]; then
    pass=$((pass + 1)); printf 'ok     %-26s %s\n' "$name" "$got"
  else
    fail=$((fail + 1)); printf 'FAIL   %-26s want=%s got=%s\n' "$name" "$want" "$got"
  fi
}
payload_check reject prompt-is-array  '{"prompt": ["APPROVE k s"]}'
payload_check reject prompt-is-null   '{"prompt": null}'
payload_check reject payload-is-list  '["APPROVE k s"]'
payload_check reject payload-garbage  'not json at all'

# --- what the hook leaves behind -----------------------------------------
# The suite's own token glob cannot see .token.XXXXXXXX, so a leaked temp file
# — a COMPLETE valid token body with actor: user — was invisible to it.
leftovers_check() {
  td="$(mktemp -d)"
  git init -q "$td"
  # force os.replace to fail: a directory where the token file must land
  mkdir -p "$td/docs/reports/records/$SUB/tokens/$KIND.token/blocker"
  payload="$(python3 -c '
import json, sys
print(json.dumps({"prompt": sys.argv[1], "cwd": sys.argv[2]}))' "$LINE" "$td")"
  out="$(printf '%s' "$payload" | CLAUDE_PROJECT_DIR="$td" /bin/bash "$HOOK" 2>&1)"
  leaked="$(find "$td" -name '.token.*' -type f | wc -l | tr -d ' ')"
  rm -rf "$td"
  if [ "$leaked" = "0" ]; then
    pass=$((pass + 1)); printf 'ok     %-26s no temp file left\n' "failed-replace"
  else
    fail=$((fail + 1)); printf 'FAIL   %-26s %s temp token(s) leaked\n' "failed-replace" "$leaked"
  fi
  if [ -z "$out" ]; then
    pass=$((pass + 1)); printf 'ok     %-26s silent\n' "no-output"
  else
    fail=$((fail + 1)); printf 'FAIL   %-26s hook spoke: %s\n' "no-output" "$out"
  fi
}
leftovers_check

# --- the token this hook writes is the token consent.py reads ------------
# Nothing asserted this before: the suite parsed tokens with its own regex, so
# mint.sh and consent.py could drift apart silently.
roundtrip_check() {
  td="$(mktemp -d)"
  git init -q "$td"
  payload="$(python3 -c '
import json, sys
print(json.dumps({"prompt": sys.argv[1], "cwd": sys.argv[2]}))' "$LINE" "$td")"
  printf '%s' "$payload" | CLAUDE_PROJECT_DIR="$td" /bin/bash "$HOOK" >/dev/null 2>&1
  got="$(LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd -P)" \
      python3 -c '
import os, sys
sys.path.insert(0, os.environ["LIB"])
import consent
d = os.path.join(sys.argv[1], "docs", "reports", "records", sys.argv[3], "tokens")
try:
    f = consent.consume(d, sys.argv[2], subject=sys.argv[3])
    ok = f["actor"] == "user" and f["kind"] == sys.argv[2]
    second = consent.find(d, sys.argv[2]) is None
    ignored = os.path.isfile(os.path.join(d, ".gitignore"))
    print("ok" if (ok and second and ignored) else "bad")
except Exception as e:
    print("error:%s" % type(e).__name__)' "$td" "$KIND" "$SUB")"
  rm -rf "$td"
  if [ "$got" = "ok" ]; then
    pass=$((pass + 1)); printf 'ok     %-26s consumable, single-use, ignored\n' "roundtrip"
  else
    fail=$((fail + 1)); printf 'FAIL   %-26s %s\n' "roundtrip" "$got"
  fi
}
roundtrip_check

# --- a consumed token must not be restorable by git ----------------------
# Measured 2026-07-27: the records tree is committed by roles, so
# `git checkout -- .` after a consume brought the approval back.
replay_check() {
  td="$(mktemp -d)"
  git init -q "$td"
  git -C "$td" config user.email t@t && git -C "$td" config user.name t
  payload="$(python3 -c '
import json, sys
print(json.dumps({"prompt": sys.argv[1], "cwd": sys.argv[2]}))' "$LINE" "$td")"
  printf '%s' "$payload" | CLAUDE_PROJECT_DIR="$td" /bin/bash "$HOOK" >/dev/null 2>&1
  git -C "$td" add -A >/dev/null 2>&1
  git -C "$td" commit -qm x >/dev/null 2>&1
  tracked="$(git -C "$td" ls-files | grep -c '\.token$' || true)"
  rm -rf "$td"
  if [ "$tracked" = "0" ]; then
    pass=$((pass + 1)); printf 'ok     %-26s not committed\n' "git-replay"
  else
    fail=$((fail + 1)); printf 'FAIL   %-26s %s token(s) tracked by git\n' "git-replay" "$tracked"
  fi
}
replay_check

printf '\n== %d passed, %d failed ==\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
