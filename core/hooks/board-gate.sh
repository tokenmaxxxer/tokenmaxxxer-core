#!/usr/bin/env bash
# PreToolUse: three deny-only rules protecting the shared board. This gate
# refuses (exit 2) or passes through (exit 0); it never emits
# permissionDecision "allow".
#
#   R1  No tool writes under docs/reports/records/*/tokens/ or to any *.token
#       under records/. Tokens are minted by mint.sh or lib/judge.py (hook
#       processes) and consumed by gates through lib/consent.py — never by
#       the model's tools. Measured 2026-07-27: coding's path-ownership gate
#       denied a foreign-record write only when the tail had no slash or
#       ended in .md, so records/<subject>/tokens/<kind>.token passed both
#       tests and the model could Write a forged approval.
#
#   R2  A record write requires the target repo's contract
#       (docs/specs/role-handoff-contract.md) to hash-match the canonical at
#       ${CLAUDE_PLUGIN_ROOT}/contract/role-handoff-contract.md. The contract
#       has no version field; content hash is the only discriminator, and six
#       repos were measured 188 lines apart while all claiming status: final.
#       A missing contract denies too: a board without its contract is not a
#       board.
#
#   R3  A record write requires CLAUDE_ROLE in the environment. Role sessions
#       get it from muster; the orchestrator's own interactive session — which
#       carries zero rulebook gates — does not, and its only board protection
#       used to be prose.
#
# Fail closed: the trap remaps any exit but 0/2 to 2, because Claude Code
# treats a non-2 hook exit as NON-BLOCKING (fail-open). An unparseable
# payload refuses. Kill switch: CORE_OFF=1.
trap 'rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then exit 2; fi' EXIT
set -uo pipefail

case "${CORE_OFF:-}" in ""|0|false|no|off) ;; *) trap - EXIT; exit 0 ;; esac

command -v python3 >/dev/null 2>&1 || exit 2

payload="$(cat 2>/dev/null || true)"

# bash 3.2: a quoted heredoc nested inside $( … ) is NOT literal — read the
# program at top level (see mint.sh for the measured failure).
IFS='' read -r -d '' CORE_BOARD_GATE <<'PY' || true
import hashlib, json, os, posixpath, re, subprocess, sys

DENY = 2

def deny(msg):
    sys.stderr.write("board-gate: %s\n" % msg)
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

# --- what is this call about to touch? ---------------------------------
RECORDS = "docs/reports/records/"
READ_ONLY_HEADS = ("ls", "cat", "head", "tail", "grep", "rg", "find", "wc",
                   "diff", "stat", "file", "git")
WRITEISH = re.compile(r"[>|`]|\$\(")

candidates = []
if tool in ("Write", "Edit", "MultiEdit", "NotebookEdit"):
    p = ti.get("file_path") or ti.get("notebook_path")
    if isinstance(p, str) and p:
        candidates.append(p)
elif tool == "Bash":
    cmdline = ti.get("command")
    if not isinstance(cmdline, str):
        deny("Bash payload carries no command string")
    if RECORDS in cmdline:
        head = cmdline.strip().split()[0].rsplit("/", 1)[-1] if cmdline.strip() else ""
        if head in READ_ONLY_HEADS and not WRITEISH.search(cmdline):
            allow()          # a plain read of the board is not a write
        # every records-path-shaped token becomes a candidate target; this is
        # a superset scan, and over-blocking is the safe direction here
        for tok in re.findall(r"[\w./~$-]*%s[\w./-]*" % re.escape(RECORDS), cmdline):
            candidates.append(tok)
        if not candidates:
            candidates.append(RECORDS)   # mentioned but unextractable: adjudicate
else:
    allow()

def norm(p):
    return posixpath.normpath(p.replace("\\", "/"))

hits = []
for c in candidates:
    n = norm(c)
    idx = n.find(RECORDS)
    if idx >= 0:
        hits.append(n[idx + len(RECORDS):])
if not hits:
    allow()                  # nothing under the board: not this gate's business

# --- R3: no role, no record writes -------------------------------------
if not os.environ.get("CLAUDE_ROLE", "").strip():
    deny("a write under docs/reports/records/ from a session with no "
         "CLAUDE_ROLE. The board belongs to role sessions; this one carries "
         "no rulebook gates. (contract sections 8/19)")

# --- R1: the tokens directory is written by no tool --------------------
for tail in hits:
    parts = tail.split("/")
    if "tokens" in parts[1:] or tail.endswith(".token"):
        deny("writes under records/<subject>/tokens/ are forbidden for every "
             "role. Approval tokens are minted from a human turn or by the "
             "unattended judge, and consumed by gates — a token written by a "
             "tool is a forged approval. (measured defect, 2026-07-27)")

# --- R2: the board requires the canonical contract ---------------------
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

def sha(p):
    try:
        with open(p, "rb") as fh:
            return hashlib.sha256(fh.read()).hexdigest()
    except OSError:
        return None

root = root_of()
if not root:
    deny("cannot resolve the project root for a record write")

plugin_root = os.environ.get("CLAUDE_PLUGIN_ROOT") or ""
canon = os.path.join(plugin_root, "contract", "role-handoff-contract.md")
repo = os.path.join(root, "docs", "specs", "role-handoff-contract.md")
canon_sha, repo_sha = sha(canon), sha(repo)
if canon_sha is None:
    deny("the plugin's canonical contract is unreadable at %s — refusing "
         "record writes rather than enforcing an unknown contract" % canon)
if repo_sha is None:
    deny("this repository has no docs/specs/role-handoff-contract.md. A "
         "board without its contract is not a board; plant it with "
         "`spawn.py init` first")
if repo_sha != canon_sha:
    deny("this repository's role-handoff-contract.md differs from the "
         "canonical shipped in core (repo %s… vs canonical %s…). The "
         "contract has no version field — the hash is the only "
         "discriminator, and six repos were measured 188 lines apart while "
         "all claiming status: final. Reconcile before writing the board."
         % (repo_sha[:12], canon_sha[:12]))

allow()
PY

CORE_PAYLOAD="$payload" python3 -c "$CORE_BOARD_GATE"
rc=$?
trap - EXIT
exit "$rc"
