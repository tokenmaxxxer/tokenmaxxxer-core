#!/usr/bin/env bash
__fc(){ rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then echo "fail-closed: gate aborted (rc=$rc)" >&2; exit 2; fi; }
trap __fc EXIT
# PreToolUse hook (Bash matching `git commit`): enforces contract §13's
# commit-trailer requirement. A commit that stages anything under an issue
# tree (docs/issue-<n>/**) must carry the machine-checkable trailer naming
# that subject:
#
#     Subject: issue-<n>
#
# and one commit belongs to one subject — staging two issues' trees in one
# commit is refused. Commits staging no issue-tree work pass through.
# Fail-closed: a commit whose message cannot be read statically while a unit
# is open is DENIED (use `git commit -m` so the trailer is verifiable).
#
# Promoted to core canon (issue-66): every rulebook vendored a byte-diverged
# copy of this file whose only real difference was the role token baked into
# env-var names and the message prefix (issue-66 survey, 38/40 unique
# hashes). This copy reads role identity from CLAUDE_ROLE at runtime instead
# — same convention core's own board-gate.sh/approval-gate.sh already use —
# so one file is now correct for every role by construction.
#
# Kill switch: export TRAILER_GATE_OFF=1 (role-blind on purpose: CLAUDE_ROLE
# already scopes the session, so the switch needs no per-role namespace).
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)}/hooks/lib/gate-lib.sh"
set -uo pipefail

role="${CLAUDE_ROLE:-}"
deny() { echo "${role:-trailer-gate}: refused — $1" >&2; exit 2; }

gate_kill_switch_active "${TRAILER_GATE_OFF:-}" || exit 0

command -v python3 >/dev/null 2>&1 || deny "trailer-gate: python3 is required to evaluate the gate and is not on PATH."

payload="$(cat 2>/dev/null)"
[ -n "$payload" ] || deny "trailer-gate: empty tool-use payload on stdin; cannot evaluate the trailer gate."

TRAILER_GATE_PAYLOAD="$payload" \
TRAILER_GATE_ROLE="$role" \
TRAILER_GATE_CPD="${CLAUDE_PROJECT_DIR:-}" \
TRAILER_GATE_CWD="$(pwd -P 2>/dev/null || echo)" \
python3 <<'PY'
import json, os, posixpath, re, shlex, subprocess, sys

role = os.environ.get("TRAILER_GATE_ROLE", "").strip() or "trailer-gate"

def deny(msg):
    sys.stderr.write("%s: refused — %s\n" % (role, msg))
    sys.exit(2)

def allow():
    sys.exit(0)

def _fail_closed(_t, _v, _tb):
    try:
        sys.stderr.write("%s: refused — fail-closed: internal error (%s: %s)\n" % (role, _t.__name__, _v))
    except Exception:
        pass
    os._exit(2)
sys.excepthook = _fail_closed

raw = os.environ.get("TRAILER_GATE_PAYLOAD", "")
try:
    event = json.loads(raw)
except ValueError:
    deny("trailer-gate: the tool-use payload is not valid JSON.")
if not isinstance(event, dict):
    deny("trailer-gate: the tool-use payload is not a JSON object.")

tool = event.get("tool_name")
ti = event.get("tool_input")
if not isinstance(tool, str) or not tool:
    deny("trailer-gate: payload has no tool_name.")
if tool != "Bash":
    allow()
if not isinstance(ti, dict):
    deny("trailer-gate: payload has no tool_input object.")

command = ti.get("command")
if not isinstance(command, str) or not command.strip():
    deny("trailer-gate: Bash call has no usable command string.")

if not re.search(r'\bgit\b[^\n;&|]*\bcommit\b(?!-)', command):
    allow()

def git_toplevel(start):
    try:
        d = start if os.path.isdir(start) else os.path.dirname(start)
        if not d:
            return None
        out = subprocess.run(["git", "-C", d, "rev-parse", "--show-toplevel"],
                             capture_output=True, text=True, timeout=10)
        top = out.stdout.strip()
        return top or None
    except Exception:
        return None

def plausible_root(r):
    return bool(r) and os.path.isdir(r) and (
        os.path.exists(os.path.join(r, ".git"))
        or os.path.isfile(os.path.join(r, "docs/specs/role-handoff-contract.md")))

cpd = os.environ.get("TRAILER_GATE_CPD", "")
cwd = os.environ.get("TRAILER_GATE_CWD", "") or "."

root = None
if plausible_root(cpd):
    root = os.path.realpath(cpd)
if root is None:
    root = git_toplevel(cwd)
if not root:
    deny("trailer-gate: no project root could be determined for the commit; refusing rather than allowing an unverified commit.")

try:
    out = subprocess.run(["git", "-C", root, "diff", "--cached", "--name-only"],
                         capture_output=True, text=True, timeout=10)
    staged = [l.strip() for l in out.stdout.splitlines() if l.strip()] if out.returncode == 0 else None
except Exception:
    staged = None
if staged is None:
    deny("trailer-gate: could not read the staged file list to decide whether this commit lands issue-tree work; refusing rather than allowing an unverified commit.")

issues = set()
for f in staged:
    im = re.match(r"^docs/(issue-[0-9]+)/", f)
    if im:
        issues.add(im.group(1))
if not issues:
    allow()  # no issue-tree work staged; the trailer requirement does not gate it
if len(issues) > 1:
    deny("trailer-gate: this commit stages work for multiple issues (%s); one commit belongs to one subject (contract s13). Split the commit." % ", ".join(sorted(issues)))
issue = sorted(issues)[0]

try:
    tokens = shlex.split(command)
except ValueError:
    deny("trailer-gate: the commit command could not be tokenized to verify its trailer; use `git commit -m` with the required `Subject:` trailer.")

messages = []
i = 0
uses_file_or_editor = False
while i < len(tokens):
    tok = tokens[i]
    if tok in ("-m", "--message"):
        if i + 1 < len(tokens):
            messages.append(tokens[i + 1])
            i += 2
            continue
    elif tok.startswith("--message="):
        messages.append(tok[len("--message="):])
    elif tok.startswith("-m") and len(tok) > 2:
        messages.append(tok[2:])
    elif tok in ("-F", "--file") or tok.startswith("--file=") or (tok.startswith("-F") and len(tok) > 2):
        uses_file_or_editor = True
    i += 1

joined = "\n".join(messages)

if not messages:
    if uses_file_or_editor:
        deny("trailer-gate: this commit stages %s work and supplies its message via a file/editor, so the required `Subject: %s` trailer (contract s13) cannot be verified statically. Pass the message with `git commit -m`." % (issue, issue))
    deny("trailer-gate: this commit stages %s work but carries no inline `-m` message, so its `Subject: %s` trailer (contract s13) cannot be verified. Use `git commit -m`." % (issue, issue))

if not re.search(r"(?im)^\s*Subject:\s*" + re.escape(issue) + r"\s*$", joined):
    deny("trailer-gate: this commit stages %s work but its message lacks the required `Subject: %s` trailer (contract s13). The trailer names the subject the staged record belongs to." % (issue, issue))

allow()
PY
rc=$?
if [ "$rc" -ne 0 ] && [ "$rc" -ne 2 ]; then
  echo "${role:-trailer-gate}: refused — fail-closed: internal error (gate judge exited $rc)" >&2
  exit 2
fi
exit "$rc"
