#!/usr/bin/env bash
# Runs mint.sh as a real subprocess against real prompts and asserts on what it
# left behind — the token's `kind` and `subject`, never its filename alone.
#
# Every rejected case here minted a valid, consumable token in at least one
# rulebook on 2026-07-27. Three separate attempts at this logic leaked before
# it became sentence-scoped:
#
#   - the NAME of the target state read as an approval, so quoting the
#     contract, or refusing in a sentence that named the state, minted one
#   - a negation denylist scanned in a character window: it carried
#     `\brefus\b`, which cannot match "refuse", and omitted won't/will not/
#     should not entirely
#   - subject and approval matched independently over the whole prompt, so a
#     turn discussing two subjects approved the wrong one
set -uo pipefail

HOOK="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/../mint.sh"
KIND="scope-proposed--scope-approved"
SUB="2026-07-27-laundry-drying-time"
pass=0
fail=0

# want: "reject" | "mint:<subject>"
check() {
  want="$1"; name="$2"; prompt="$3"
  td="$(mktemp -d)"
  git init -q "$td"
  payload="$(python3 -c '
import json, sys
print(json.dumps({"prompt": sys.argv[1], "cwd": sys.argv[2]}))' "$prompt" "$td")"
  printf '%s' "$payload" | CLAUDE_PROJECT_DIR="$td" /bin/bash "$HOOK" >/dev/null 2>&1
  tok="$(find "$td" -name "$KIND.token" -type f | head -1)"
  if [ -n "$tok" ]; then
    got="mint:$(python3 -c '
import re, sys
t = open(sys.argv[1], encoding="utf-8").read()
m = re.search(r"^subject:\s*(.*)$", t, re.M)
print(m.group(1).strip() if m else "?")' "$tok")"
  else
    got=reject
  fi
  rm -rf "$td"
  if [ "$got" = "$want" ]; then
    pass=$((pass + 1)); printf 'ok     %-24s %s\n' "$name" "$got"
  else
    fail=$((fail + 1)); printf 'FAIL   %-24s want=%s got=%s\n' "$name" "$want" "$got"
  fi
}

check "mint:$SUB" approve-en        "I approve the scope for subject $SUB."
check "mint:$SUB" approve-ko        "subject $SUB 의 scope 를 승인한다."
check "mint:$SUB" approve-ko-range  "subject $SUB 의 범위를 승인한다."
check "mint:$SUB" same-sentence     "subject beta is blocked and stays where it is. Separately, I approve the scope for subject $SUB."

check reject state-mention     "subject $SUB 는 아직 scope-approved 가 아니다."
check reject contract-quote    "Section 19 makes subject $SUB reaching scope-approved a human-owned edge."
check reject agent-explains    "subject $SUB: I cannot write scope-approved myself."
check reject refuse-verb       "subject $SUB: I refuse to approve the scope."
check reject wont-contraction  "For subject $SUB I won't approve the scope."
check reject will-not          "For subject $SUB I will not approve the scope."
check reject should-not        "subject $SUB: you should not approve the scope on my behalf."
check reject wouldnt           "subject $SUB: I wouldn't approve the scope as written."
check reject question-anyone   "subject $SUB - did anyone approve the scope yet?"
check reject third-party       "subject $SUB: the PR comment says QA approved the scope last week."
check reject hedged            "subject $SUB: I think we should approve the scope now."
# Belt-and-braces: bare assent never names a subject either, so this is
# already covered by the subject-required gate, not a dedicated bare-assent
# rule (mint.sh dropped that rule as dead code: reaching it required
# subject != None, and no assent phrase contains one).
check reject bare-assent       "ok"
check reject no-subject        "I approve the scope."

# --- regression cases added 2026-07-27, reproduced by the coordinator ------
#
# Position-anchored rule defeated by a missing space: the sentence splitter
# only breaks where whitespace follows [.!?\n], so "...subject X?Let's..."
# (no space after "?") merges into one sentence, the "?" is no longer at the
# end, and the end-anchored disqualifier never fires. "should I" is not on
# the negation word list, so the "?" was the ONLY guard on this sentence.
check reject qmark-spaced       "Should I approve the scope for subject $SUB? Let's circle back tomorrow."
check reject qmark-unspaced     "Should I approve the scope for subject $SUB?Let's circle back tomorrow."

# Quoted material inside a code fence read as the user's own assertion.
check reject code-fence         "Here is the log:
\`\`\`
I approve the scope for subject $SUB.
\`\`\`"

# Hypothetical/subjunctive framing ("would", "if I were") is not a negation
# and was not on the disqualify list.
check reject hypothetical       "If I were QA I would approve the scope for subject $SUB."

# Korean negation markers matched as bare syllables, so an approval whose
# wording merely CONTAINS one (a pianist, "no less than") was silently
# rejected with no signal to the user that their approval did not register.
check "mint:$SUB" ko-pianist    "subject $SUB 의 범위를 피아니스트인 내가 승인한다."
check "mint:$SUB" ko-notless    "그 못지않게 중요한 subject $SUB 의 범위를 승인한다."

printf '\n== %d passed, %d failed ==\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
