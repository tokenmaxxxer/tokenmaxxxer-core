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

printf '\n== %d passed, %d failed ==\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
