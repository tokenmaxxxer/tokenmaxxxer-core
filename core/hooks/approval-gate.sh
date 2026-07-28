#!/usr/bin/env bash
# PreToolUse: the phase gate of contract v3 s19. Every role proposes first
# (research, current-state survey, proposal — documents, phase 1) and
# executes only after an allowlisted human's PR review Approve (phase 2).
#
# Deny-only rule: a role session's write under src/ or test/ is refused
# while the role's issue-<n>/<role> PR lacks an Approve review authored by
# an account listed in docs/specs/approvers.md — including while no PR
# exists at all, which is what makes "open the proposal PR first" enforced
# rather than customary. Document writes (phase 1 material) are not this
# gate's business; board-gate.sh governs those.
#
# Who counts as the human is an allowlist, not a heuristic: bot and agent
# accounts are simply not listed, so a CI Approve or a role approving its
# own PR cannot open phase 2 (contract v3 s8).
#
# The verdict needs GitHub (gh pr view --json reviews) — a network call.
# It runs only for src//test/ writes in role sessions, and the result is
# NOT cached: a cache file would be writable by the model's own tools,
# i.e. a forgeable approval. gh unavailable or failing = deny (fail
# closed). Kill switch: CORE_OFF=1. Test seam: CORE_GH overrides the gh
# executable.
trap 'rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then exit 2; fi' EXIT
set -uo pipefail

case "${CORE_OFF:-}" in ""|0|false|no|off) ;; *) trap - EXIT; exit 0 ;; esac

# Not a role session: none of this gate's business. The user's and the
# orchestrator's own sessions write src/ freely.
[ -n "${CLAUDE_ROLE:-}" ] || { trap - EXIT; exit 0; }

payload="$(cat 2>/dev/null || true)"

# Fast path before python3: only src//test/ writes are adjudicated.
case "$payload" in
  *src/*|*test/*) ;;
  *) trap - EXIT; exit 0 ;;
esac

command -v python3 >/dev/null 2>&1 || exit 2

# bash 3.2: a quoted heredoc nested inside $( … ) is NOT literal — read the
# program at top level.
IFS='' read -r -d '' CORE_APPROVAL_GATE <<'PY' || true
import json, os, posixpath, re, subprocess, sys

DENY = 2

def deny(msg):
    sys.stderr.write("approval-gate: %s\n" % msg)
    sys.exit(DENY)

def allow():
    sys.exit(0)

try:
    event = json.loads(os.environ.get("CORE_PAYLOAD", ""))
except ValueError:
    deny("unreadable PreToolUse payload; refusing rather than guessing "
         "what was about to be written")
if not isinstance(event, dict):
    deny("payload is not an object")

tool = event.get("tool_name") or ""
ti = event.get("tool_input") or {}
if not isinstance(ti, dict):
    deny("tool_input is not an object")

READ_ONLY_HEADS = ("ls", "cat", "head", "tail", "grep", "rg", "find", "wc",
                   "diff", "stat", "file", "git")
WRITEISH = re.compile(r"[>|`]|\$\(")
EXEC_RE = re.compile(r"(^|/)(src|test)/")

candidates = []
if tool in ("Write", "Edit", "MultiEdit", "NotebookEdit"):
    p = ti.get("file_path") or ti.get("notebook_path")
    if isinstance(p, str) and p:
        candidates.append(p)
elif tool == "Bash":
    cmdline = ti.get("command")
    if not isinstance(cmdline, str):
        deny("Bash payload carries no command string")
    head = cmdline.strip().split()[0].rsplit("/", 1)[-1] if cmdline.strip() else ""
    if head in READ_ONLY_HEADS and not WRITEISH.search(cmdline):
        allow()              # reading the tree is phase-agnostic
    for tok in re.findall(r"[\w./~$-]+", cmdline):
        if EXEC_RE.search(tok):
            candidates.append(tok)
else:
    allow()

def norm(p):
    return posixpath.normpath(p.replace("\\", "/"))

hits = [c for c in candidates if EXEC_RE.search(norm(c))]
if not hits:
    allow()                  # no execution-surface write: not this gate's business

# --- where are we, and is it a board? -----------------------------------
def root_of():
    cpd = os.environ.get("CLAUDE_PROJECT_DIR")
    if cpd and os.path.isdir(cpd):
        return os.path.realpath(cpd)
    cwd = event.get("cwd") or os.getcwd()
    try:
        out = subprocess.run(["git", "-C", cwd, "rev-parse", "--show-toplevel"],
                             capture_output=True, text=True)
        if out.returncode == 0 and out.stdout.strip():
            return os.path.realpath(out.stdout.strip())
    except Exception:
        pass
    return None

role = os.environ["CLAUDE_ROLE"].strip()
root = root_of()
if not root:
    deny("cannot resolve the project root for an execution-surface write")

if not os.path.isfile(os.path.join(root, "docs", "specs",
                                   "role-handoff-contract.md")):
    deny("this repository carries no role-handoff contract, but the session "
         "carries CLAUDE_ROLE=%s. A role session works only on a board; "
         "plant the contract first" % role)

# --- the role's issue branch --------------------------------------------
try:
    out = subprocess.run(["git", "-C", root, "symbolic-ref", "--short",
                          "HEAD"], capture_output=True, text=True)
    branch = out.stdout.strip() if out.returncode == 0 else ""
except Exception:
    branch = ""
m = re.match(r"^issue-[0-9]+/(.+)$", branch)
if not m or m.group(1) != role:
    deny("execution-surface writes happen only on this role's own issue "
         "branch (issue-<n>/%s; current: %s). Check out the branch, submit "
         "phase 1, and get the Approve first. (contract v3 s19)"
         % (role, branch or "<none>"))

# --- the human allowlist ------------------------------------------------
approvers = []
try:
    with open(os.path.join(root, "docs", "specs", "approvers.md")) as fh:
        for line in fh:
            lm = re.match(r"^[-*]\s+@?([A-Za-z0-9][A-Za-z0-9-]*)\s*$",
                          line.strip())
            if lm:
                approvers.append(lm.group(1).lower())
except OSError:
    deny("docs/specs/approvers.md is missing or unreadable — without the "
         "human-approver allowlist no review can be told apart from a bot's "
         "or an agent's. Add it before execution work. (contract v3 s8)")
if not approvers:
    deny("docs/specs/approvers.md lists no approvers (expected '- <github "
         "login>' lines). An empty allowlist can approve nothing")

# --- the Approve review -------------------------------------------------
gh = os.environ.get("CORE_GH") or "gh"
try:
    out = subprocess.run([gh, "pr", "view", branch, "--json", "reviews"],
                         capture_output=True, text=True, cwd=root)
except OSError:
    deny("cannot run %r to check the PR's reviews — refusing execution "
         "writes rather than assuming approval (fail closed)" % gh)
if out.returncode != 0:
    deny("no open PR found for branch %s (or gh failed: %s). Phase 1 comes "
         "first: commit research, current-state and proposal, open the PR, "
         "and wait for an Approve review. (contract v3 s19)"
         % (branch, (out.stderr or "").strip()[:200]))
try:
    reviews = json.loads(out.stdout).get("reviews") or []
except (ValueError, AttributeError):
    deny("unreadable reviews JSON from gh; refusing rather than assuming "
         "approval")

# Last review per author wins: an author who approved and later requested
# changes has not approved.
last = {}
for r in reviews:
    if not isinstance(r, dict):
        continue
    login = ((r.get("author") or {}).get("login") or "").lower()
    state = r.get("state") or ""
    if login and state in ("APPROVED", "CHANGES_REQUESTED", "DISMISSED"):
        last[login] = state

if not any(login in approvers and state == "APPROVED"
           for login, state in last.items()):
    deny("the PR for %s carries no Approve review from a listed human "
         "approver (%s). A comment is feedback, a bot's Approve is not a "
         "human's, and phase 2 waits for the human. (contract v3 s19)"
         % (branch, ", ".join(approvers)))

allow()
PY

CORE_PAYLOAD="$payload" python3 -c "$CORE_APPROVAL_GATE"
rc=$?
trap - EXIT
exit "$rc"
