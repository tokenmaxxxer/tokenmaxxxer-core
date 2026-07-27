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

# --- regression cases added 2026-07-27, round 2: coordinator reproduced   ---
# five more gaps against the round-1 fix. Findings A, B, C, D below.

# Finding A: anchoring negation to conjugation ENDINGS made the false-reject
# worse, not better — three unambiguous refusals started minting real
# tokens, because Hangul syllables compose: 아니다 + ㅂ니다 is not a substring
# of the real word 아닙니다 (닙 is one precomposed codepoint), so no ending
# list can enumerate its way to that word at all, and 않는다/못했다 were plain
# gaps. Fixed by matching the connective -지 before 않/못 instead (every
# ending attaches AFTER, so it never needs enumerating) plus complete literal
# words for 아니다's own merged forms (아닌/아님/아닙니다/아닙니까). This is the
# coordinator's exact verification table, both directions.
check reject ko-aux-anh1        "subject $SUB 의 범위를 승인하지 않는다."
check reject ko-aux-anh2        "subject $SUB 의 범위를 승인하지 않았다."
check reject ko-aux-anh3        "subject $SUB 의 범위를 승인하지 않을 것이다."
check reject ko-aux-anh4        "subject $SUB 의 범위를 승인하지 않습니다."
check reject ko-aux-mot1        "subject $SUB 의 범위를 승인하지 못했다."
check reject ko-aux-mot2        "subject $SUB 의 범위를 승인하지 못한다."
check reject ko-aux-mot3        "subject $SUB 의 범위를 승인하지 못합니다."
check reject ko-cop-anida       "subject $SUB 의 범위는 승인된 것이 아니다."
check reject ko-cop-anibnida    "subject $SUB 의 범위는 승인된 것이 아닙니다."
check reject ko-cop-anieossda   "subject $SUB 의 범위는 승인된 것이 아니었다."
check reject ko-cop-anim        "subject $SUB 의 범위는 승인된 것이 아님."
# Coordinator's exact mint side of the table (a third entry, the plain
# baseline "subject X 의 scope 를 승인한다.", is identical wording to
# approve-ko above and is not repeated here).
check "mint:$SUB" ko-tbl-pianist "subject $SUB 의 scope 를 승인한다. 피아니스트가 봐도 문제없다."
check "mint:$SUB" ko-tbl-notless "subject $SUB 의 범위를 승인한다. 지난번 못지않게 꼼꼼하다."

# Finding B: the round-1 zero-width splitter (`\s*`) also split "per section
# 4.2" at the decimal point, tearing the subject from its approving clause.
# Reverted to `\s+`; the bare `\?` from round 1 is what actually closes the
# missing-space hole (qmark-unspaced above), independent of the splitter.
check "mint:$SUB" decimal-point "I approve the scope, per section 4.2, for subject $SUB."
# A sentence carrying a "?" ANYWHERE still disqualifies, even with a clean
# approval elsewhere in the same clause — accepted, not accidental.
check reject qmark-embedded     "I approve (is that clear?) the scope for subject $SUB."

# Finding C: indented-block stripping blanked an ordinary quoted chat reply
# (indentation is how most clients mark one). Removed; only fenced blocks
# are treated as quoted material.
check "mint:$SUB" quoted-reply  "Replying to your message:
    I approve the scope for subject $SUB."

# Finding D: an opening fence with no closing fence left the payload
# unstripped, because the old pattern required a closing marker to match at
# all. The close is now optional: strip from the opening fence to the next
# fence or the end of the text.
check reject fence-unclosed     "\`\`\`
I approve the scope for subject $SUB."

printf '\n== %d passed, %d failed ==\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
