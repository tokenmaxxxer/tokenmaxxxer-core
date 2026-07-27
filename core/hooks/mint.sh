#!/usr/bin/env bash
# UserPromptSubmit: mints a consent token when the user's whole turn is exactly
#
#     APPROVE <kind> <subject>
#
# and never otherwise. Not a sentence containing that line, not a paraphrase,
# not an approval written in prose.
#
# Three earlier designs read approval out of natural language and all three
# leaked (see tests/run-mint-tests.sh for the measured cases). Deciding what a
# sentence means is a language problem and a regex is the wrong tool for it;
# deciding whether two strings are equal is not a language problem. The model
# asks the human clearly and prints the exact line to send — that half IS a
# language problem, and the model is good at it. This hook only checks equality.
#
# Why a hook and not the model's own judgment: the model is the thing being
# gated, and the input is adversarial text. An entity cannot authorize itself,
# and an LLM reading adversarial text to decide authorization is injectable.
# String equality is neither.
#
# Never blocks: exit 0 on every path. The GATE refuses; this hook only records.
# Kill switch: CORE_OFF=1
# Unattended: mints nothing. There is no human turn to read, and an approval in
# an unattended run comes from the judge (see lib/judge.py), not from here.
set -euo pipefail

case "${CORE_OFF:-}" in ""|0|false|no|off) ;; *) exit 0 ;; esac
case "${TOKENMAXXXER_UNATTENDED:-}" in ""|0|false|no|off) ;; *) exit 0 ;; esac

command -v python3 >/dev/null 2>&1 || exit 0

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || exit 0

# Read the program at top level. bash 3.2 tracks quotes and parens inside a
# heredoc body while scanning for a closing `)`, so a quoted heredoc nested in
# $( … ) is NOT literal and one apostrophe in a comment breaks the file.
IFS='' read -r -d '' CORE_MINT <<'PY' || true
import json, os, posixpath, re, subprocess, sys, tempfile

def bail():
    sys.exit(0)

try:
    event = json.loads(os.environ.get("CORE_PAYLOAD", ""))
except ValueError:
    bail()
if not isinstance(event, dict):
    bail()

prompt = event.get("prompt")
if not isinstance(prompt, str):
    bail()

# The WHOLE turn, or nothing. `re.match` alone would accept a trailing
# remainder, and `contains` would accept every quoted, fenced and negated case
# in the test suite. `\Z` with no `re.M` is what makes this equality.
ID = r"[A-Za-z0-9][A-Za-z0-9_.-]{0,127}"
m = re.match(r"\AAPPROVE (%s) (%s)\Z" % (ID, ID), prompt.strip())
if not m:
    bail()
kind, subject = m.group(1), m.group(2)

# --- resolve project root (no root -> nothing to do) -------------------
def git_top(p):
    try:
        out = subprocess.run(["git", "-C", p, "rev-parse", "--show-toplevel"],
                             capture_output=True, text=True)
        if out.returncode == 0 and out.stdout.strip():
            return posixpath.normpath(os.path.realpath(out.stdout.strip()).replace("\\", "/"))
    except Exception:
        return None
    return None

def plausible(r):
    return bool(r) and os.path.isdir(r) and os.path.exists(os.path.join(r, ".git"))

cpd = os.environ.get("CLAUDE_PROJECT_DIR")
root = None
if cpd and plausible(cpd):
    root = posixpath.normpath(os.path.realpath(cpd).replace("\\", "/"))
if root is None:
    root = git_top(os.getcwd())
if not root:
    bail()

# Token dir under the subject's record area. Resolve, then containment-check —
# KIND_RE already excludes `/` and `..`, and this is the second lock.
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

token_file = posixpath.join(tokens_real, kind + ".token")
if posixpath.dirname(token_file) != tokens_real:
    bail()

# `phrase` is the challenge line itself. It cannot carry a secret, so the
# credential-redaction pass the prose version needed is gone with the prose.
try:
    fd, tmp = tempfile.mkstemp(dir=tokens_real, prefix=".token.")
    with os.fdopen(fd, "w", encoding="utf-8") as fh:
        fh.write("kind: %s\n" % kind)
        fh.write("subject: %s\n" % subject)
        fh.write("actor: user\n")
        fh.write("phrase: APPROVE %s %s\n" % (kind, subject))
    os.replace(tmp, token_file)
except OSError:
    bail()

sys.exit(0)
PY

CORE_PAYLOAD="$payload" python3 -c "$CORE_MINT" || true
exit 0
