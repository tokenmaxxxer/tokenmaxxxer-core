#!/usr/bin/env bash
# UserPromptSubmit hook: mints a single-use approval token from an assertion in
# the user's OWN turn — never from a file, record, PR comment, or tool result.
# A role's gate consumes it via hooks/lib/consent.py.
#
# This hook NEVER blocks. Malformed input, no root, no subject, or an absent or
# ambiguous approval all mean: write nothing, exit 0. The gate — not this hook
# — is what refuses an unsignaled transition.
#
# Kill switch: export CORE_OFF=1
set -uo pipefail

case "${CORE_OFF:-}" in
  ""|0|false|no|off) ;;
  *) exit 0 ;;
esac

command -v python3 >/dev/null 2>&1 || exit 0

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || exit 0

# The parser is read into a variable at TOP LEVEL and passed to `python3 -c`.
# Written as `$(python3 <<'PY' … PY)` it would not parse under bash 3.2 — a
# quoted-delimiter heredoc nested in a command substitution is not literal
# there, so one apostrophe in a comment ("the gate's own sentinel") breaks the
# whole file. Measured 2026-07-27: that made a UserPromptSubmit hook fail to
# parse, and every prompt for that role came back blocked.
IFS='' read -r -d '' MINT_PY <<'PY' || true
import json, os, posixpath, re, subprocess, sys, tempfile

def bail():
    sys.exit(0)

raw = os.environ.get("CORE_PAYLOAD", "")
try:
    event = json.loads(raw)
except ValueError:
    bail()
if not isinstance(event, dict):
    bail()

prompt = event.get("prompt")
if not isinstance(prompt, str) or not prompt.strip():
    bail()

# An unattended run receives its prompts from the orchestrator, not from a
# human. Reading those as human speech is exactly the self-certification the
# token exists to prevent, so unattended mints nothing at all.
if os.environ.get("TOKENMAXXXER_UNATTENDED", "") not in ("", "0", "false", "no", "off"):
    bail()

# --- the approving sentence, and the subject named inside it -----------
#
# Subject and approval come from ONE sentence. Two independent searches over
# the whole prompt is what leaked on 2026-07-27:
#
#   "subject beta is blocked and stays where it is. Separately, I approve the
#    scope for subject alpha."   -> minted a token for BETA.
#
# Fenced and indented code blocks are quoted material — a pasted transcript,
# or an example of the phrasing someone should use — never the user's own
# assertion. Strip them before any analysis. Measured 2026-07-27: approval
# wording pasted inside a ``` fence minted a token.
speech = re.sub(r"```.*?```", " ", prompt, flags=re.S)
speech = re.sub(r"(?m)^[ \t]{4,}.*$", " ", speech)

# The state name is an identifier, never a speech act. Blank it first, or
# `\bscope\b[^.\n]*\bapproved\b` spans the literal `scope-approved` (the hyphen
# is a word boundary) and "this subject is not yet scope-approved" reads as an
# approval.
speech = re.sub(r"(?i)\bscope[-_ ]?approved\b", " <state> ", speech)
speech = speech.replace("’", "'")

# A sentence disqualifies itself by being a question, a hedge, a negation, or a
# report of someone else's words. Verb suffixes are open (`refus\w*`) — the
# closed form `\brefus\b` shipped once and could not match "refuse" at all.
#
# `would`/`could`/`if i`/etc. disqualify hypothetical and subjunctive framing
# ("If I were QA I would approve..."). This also rejects a genuine "I would
# like to approve the scope" — that is the safe direction and is accepted;
# do not narrow it back to "would not" only.
#
# The Korean markers 않/못/아니 are anchored to negation-conjugation suffixes,
# not left as bare syllables: a bare syllable also matches inside ordinary
# words (피아니스트 "pianist", 못지않게 "no less than") and silently rejects an
# approval that merely contains one, with no signal to the user that it did.
DISQUALIFY = re.compile(
    r"(?i)\?"
    r"|\b(not|never|cannot|shall not|will not|would not|should not|must not"
    r"|can't|won't|wont|shan't|shouldn't|wouldn't|couldn't|didn't|doesn't"
    r"|don't|isn't|aren't|wasn't|weren't|hasn't|haven't"
    r"|refus\w*|declin\w*|without|instead of|unsure|maybe|might"
    r"|would|could|if i|suppose|imagine|hypothetically"
    r"|i think|i wonder|did anyone|has anyone|do you|should we|shall we)\b"
    r"|\bfor example\b|\be\.g\."
    r"|\b(says?|said|according to|comment|quoted?|per the)\b"
    r"|하지\s*마|하지\s*말|말고|말라|없이|금지"
    r"|않(?:다|고|아|은|을|습니다|았)|못\s*(?:한|해|하|합니다)|아니(?:다|고|라|야|에요|ㅂ니다|었)"
    r"|확실치|확실하지|모르겠|인가요|일까요|라고\s*(?:한다|했다|합니다)")

APPROVES = re.compile(
    r"(?i)\b(approve|approved|approving)\b[^.\n]*\bscope\b"
    r"|\bscope\b[^.\n]*\b(approve|approved)\b"
    r"|(?:scope|스코프|범위)[^.\n]*승인")
SUBJECT = re.compile(r"(?i)\bsubject[\s:]+([A-Za-z0-9][A-Za-z0-9_-]{0,127})")

subject = None
approving_sentence = None
# Split on trailing punctuation whether or not whitespace follows it. A
# missing space ("...subject X?Let's circle back...") used to merge two
# sentences into one, moving the "?" off the end and defeating the only
# position-anchored disqualifier above — measured 2026-07-27, and "should I"
# is not itself on the negation word list, so the "?" was the only guard.
for sentence in re.split(r"(?<=[.!?\n])\s*", speech):
    s = sentence.strip()
    if not s or DISQUALIFY.search(s) or not APPROVES.search(s):
        continue
    sub = SUBJECT.search(s)
    if not sub:
        # An approval naming no subject in its own sentence names nothing.
        # Which subject it meant is not this hook's guess to make.
        continue
    subject = sub.group(1)
    approving_sentence = s
    break

if subject is None:
    bail()

KIND = "scope-proposed--scope-approved"

# --- resolve the project root ------------------------------------------
def git_top(p):
    try:
        out = subprocess.run(["git", "-C", p, "rev-parse", "--show-toplevel"],
                             capture_output=True, text=True)
        if out.returncode == 0 and out.stdout.strip():
            return posixpath.normpath(
                os.path.realpath(out.stdout.strip()).replace("\\", "/"))
    except Exception:
        return None
    return None

root = os.environ.get("CLAUDE_PROJECT_DIR", "") or event.get("cwd", "") or ""
root = git_top(root) or (posixpath.normpath(os.path.realpath(root).replace("\\", "/"))
                         if root else "")
if not root or not os.path.isdir(root):
    bail()

records_root = posixpath.join(root, "docs", "reports", "records")
tokens_dir = posixpath.join(records_root, subject, "tokens")
try:
    os.makedirs(tokens_dir, exist_ok=True)
except OSError:
    bail()

tokens_real = posixpath.normpath(os.path.realpath(tokens_dir).replace("\\", "/"))
records_real = posixpath.normpath(os.path.realpath(records_root).replace("\\", "/"))
if not tokens_real.startswith(records_real + "/"):
    bail()

token_file = posixpath.join(tokens_real, KIND + ".token")
if posixpath.dirname(token_file) != tokens_real:
    bail()

phrase = approving_sentence[:300]
# The phrase is the user's own words, kept so a human can audit what minted
# this. Redact anything credential-SHAPED rather than anything merely spelled
# like the word "secret" — the previous scan matched English nouns and let
# ghp_/sk-/AKIA/xoxb- prefixes through untouched.
if re.search(r"(?i)(gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}"
             r"|sk-[A-Za-z0-9-]{20,}|AKIA[A-Z0-9]{16}|ASIA[A-Z0-9]{16}"
             r"|xox[baprs]-[A-Za-z0-9-]{10,}|AIza[A-Za-z0-9_-]{35}"
             r"|eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\."
             r"|-----BEGIN |https?://[^ ]*:[^ ]*@"
             r"|api[_-]?key|secret|password|passwd|bearer |authorization:)",
             phrase):
    phrase = "(approval wording redacted: looked credential-shaped)"
phrase = phrase.replace("\n", " ").replace("\r", " ")

fd, tmp = tempfile.mkstemp(dir=tokens_real, prefix=".mint-")
try:
    with os.fdopen(fd, "w", encoding="utf-8") as fh:
        fh.write("kind: %s\n" % KIND)
        fh.write("subject: %s\n" % subject)
        fh.write("actor: user\n")
        fh.write("phrase: %s\n" % phrase)
    os.replace(tmp, token_file)
except OSError:
    try:
        os.unlink(tmp)
    except OSError:
        pass
    bail()
PY

CORE_PAYLOAD="$payload" python3 -c "$MINT_PY" >/dev/null 2>&1 || true
exit 0
