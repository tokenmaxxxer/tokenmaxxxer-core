#!/usr/bin/env bash
# PreToolUse: deny-only rules protecting the board under the issue/PR
# interaction model (contract v3). This gate refuses (exit 2) or passes
# through (exit 0); it never emits permissionDecision "allow".
#
#   R1  Layout. A write under docs/ must land at docs/README.md, under one
#       of the six standing buckets (_assets, decisions, handbooks,
#       proposals, reports, specs), or under an issue tree
#       docs/issue-<n>/<bucket>/... using those same six buckets. Nothing
#       else exists under docs/.
#
#   R2  A board write requires the target repo's contract
#       (docs/specs/role-handoff-contract.md) to hash-match the canonical at
#       ${CLAUDE_PLUGIN_ROOT}/contract/role-handoff-contract.md. The
#       contract has no version field; content hash is the only
#       discriminator. A missing contract denies too: a board without its
#       contract is not a board.
#
#   R3  A write under docs/issue-<n>/ requires CLAUDE_ROLE in the
#       environment. Role sessions get it from muster; the orchestrator's
#       own interactive session carries no rulebook gates and has no
#       business writing the board.
#
#   R4  Branch. A role session writes an issue tree only from that issue's
#       own role branch: writing docs/issue-<n>/... requires the current
#       git branch to be exactly issue-<n>/<CLAUDE_ROLE>. Writing the board
#       from main (or any other branch) is refused — every role output
#       reaches main only through a PR the human merges (contract v3 s10).
#
#   R5  Ownership. Within docs/issue-<n>/reports/, a role writes only its
#       own record (<role>.md), its own subtree (<role>/**), and the
#       per-role extra subtree the contract grants (feasibility: spikes/**,
#       ops: postmortems/**). Foreign-record writes are refused (s11).
#
# There is no token machinery: human approval is a PR merge, feedback is a
# PR comment, refusal is an issue/PR close — GitHub acts, not hook state.
#
# Fail closed: the trap remaps any exit but 0/2 to 2, because Claude Code
# treats a non-2 hook exit as NON-BLOCKING (fail-open). An unparseable
# payload refuses. Kill switch: CORE_OFF=1.
trap 'rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then exit 2; fi' EXIT
set -uo pipefail

case "${CORE_OFF:-}" in ""|0|false|no|off) ;; *) trap - EXIT; exit 0 ;; esac

payload="$(cat 2>/dev/null || true)"

# Fast path, in shell, before python3 is ever started: this gate runs on
# every tool call and python3 startup costs ~50ms. `docs` is the
# discriminator rather than `docs/` because the python below normalizes
# `docs/../docs/issue-3/...` and this must not be narrower than what it
# would then catch. A payload that mentions the word and turns out to be
# unrelated simply falls through and the python allows it — this is an
# optimization, never a verdict.
case "$payload" in
  *docs*) ;;
  *) trap - EXIT; exit 0 ;;
esac

command -v python3 >/dev/null 2>&1 || exit 2

# bash 3.2: a quoted heredoc nested inside $( … ) is NOT literal — read the
# program at top level.
IFS='' read -r -d '' CORE_BOARD_GATE <<'PY' || true
import hashlib, json, os, posixpath, re, subprocess, sys

DENY = 2
BUCKETS = ("_assets", "decisions", "handbooks", "proposals", "reports",
           "specs")
ISSUE_RE = re.compile(r"^issue-[0-9]+$")
EXTRA_SUBTREE = {"feasibility": "spikes", "ops": "postmortems"}

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
DOCS = "docs/"
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
    if DOCS in cmdline:
        head = cmdline.strip().split()[0].rsplit("/", 1)[-1] if cmdline.strip() else ""
        if head in READ_ONLY_HEADS and not WRITEISH.search(cmdline):
            allow()          # a plain read of the board is not a write
        # every docs-path-shaped token becomes a candidate target; this is
        # a superset scan, and over-blocking is the safe direction here
        for tok in re.findall(r"[\w./~$-]*%s[\w./-]*" % re.escape(DOCS), cmdline):
            candidates.append(tok)
        if not candidates:
            candidates.append(DOCS)   # mentioned but unextractable: adjudicate
else:
    allow()

def norm(p):
    return posixpath.normpath(p.replace("\\", "/"))

hits = []
for c in candidates:
    n = norm(c)
    idx = n.find(DOCS)
    if idx >= 0:
        tail = n[idx + len(DOCS):]
        if tail:
            hits.append(tail)
if not hits:
    allow()                  # nothing under docs/: not this gate's business

# --- board or bystander? -----------------------------------------------
# Not every repository with a docs/ directory follows this contract. This
# gate is enabled in every session, and a repo keeping ordinary docs has
# nothing to do with the board — refusing its writes would be a false
# positive, not enforcement. No contract and no role means no board: stand
# aside entirely. (A role IS set but the contract is missing → that is a
# real error and R2 denies below.)
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

role = os.environ.get("CLAUDE_ROLE", "").strip()
root = root_of()
if not root:
    deny("cannot resolve the project root for a docs/ write")

repo_contract = os.path.join(root, "docs", "specs",
                             "role-handoff-contract.md")
repo_sha = sha(repo_contract)
if repo_sha is None and not role:
    allow()

# --- R1: docs/ layout ---------------------------------------------------
def bucketed(tail):
    """tail is relative to docs/. Returns an error string or None."""
    parts = tail.split("/")
    if parts == ["README.md"]:
        return None
    top = parts[0]
    if ISSUE_RE.match(top):
        if len(parts) == 1:
            return None          # the issue directory itself (mkdir)
        sub = parts[1]
        if sub == "README.md" and len(parts) == 2:
            return None
        if sub not in BUCKETS:
            return ("docs/%s/%s is outside the six buckets. An issue tree "
                    "contains only %s" % (top, sub, ", ".join(BUCKETS)))
        return None
    if top not in BUCKETS:
        return ("docs/%s is neither docs/README.md, one of the six standing "
                "buckets (%s), nor an issue tree (docs/issue-<n>/). "
                "(contract v3 s10)" % (tail, ", ".join(BUCKETS)))
    return None

issue_hits = []      # (issue_dir, parts-after-docs/) for docs/issue-<n>/ writes
for tail in hits:
    err = bucketed(tail)
    if err:
        deny(err)
    parts = tail.split("/")
    if ISSUE_RE.match(parts[0]):
        issue_hits.append(parts)

if not issue_hits:
    # standing-doc bucket write: layout holds, board preconditions don't
    # apply. R2 still guards it when a role session writes a board repo.
    if not role:
        allow()

# --- R2: the board requires the canonical contract ----------------------
plugin_root = os.environ.get("CLAUDE_PLUGIN_ROOT") or ""
canon = os.path.join(plugin_root, "contract", "role-handoff-contract.md")
canon_sha = sha(canon)
if canon_sha is None:
    deny("the plugin's canonical contract is unreadable at %s — refusing "
         "docs writes rather than enforcing an unknown contract" % canon)
if repo_sha is None:
    deny("this repository has no docs/specs/role-handoff-contract.md. A "
         "board without its contract is not a board; plant it first")
if repo_sha != canon_sha:
    deny("this repository's role-handoff-contract.md differs from the "
         "canonical shipped in core (repo %s… vs canonical %s…). The "
         "contract has no version field — the hash is the only "
         "discriminator. Reconcile before writing the board."
         % (repo_sha[:12], canon_sha[:12]))

if not issue_hits:
    allow()                      # standing-doc write by a role: layout + contract suffice

# --- R3: no role, no board writes ---------------------------------------
if not role:
    deny("a write under docs/issue-<n>/ from a session with no CLAUDE_ROLE. "
         "The board belongs to role sessions; this one carries no rulebook "
         "gates. (contract v3 s8/s10)")

# --- R4: the role's own issue branch ------------------------------------
# symbolic-ref rather than rev-parse --abbrev-ref: it answers on a branch
# with no commits yet, and fails on detached HEAD — which is exactly the
# deny we want (a role writes its board only from its own named branch).
try:
    out = subprocess.run(["git", "-C", root, "symbolic-ref", "--short",
                          "HEAD"], capture_output=True, text=True)
    branch = out.stdout.strip() if out.returncode == 0 else ""
except Exception:
    branch = ""
if not branch:
    deny("cannot resolve the current git branch for a board write; a role "
         "writes its issue tree only from issue-<n>/<role>")

for parts in issue_hits:
    issue_dir = parts[0]
    expected = "%s/%s" % (issue_dir, role)
    if branch != expected:
        deny("writing docs/%s/ requires branch %s (current: %s). Every "
             "role output reaches main only through a PR the human merges "
             "— never a direct write from another branch. (contract v3 s10)"
             % (issue_dir, expected, branch))

# --- R5: reports/ ownership ---------------------------------------------
for parts in issue_hits:
    if len(parts) < 3 or parts[1] != "reports":
        continue
    tail = parts[2:]
    owner_file = role + ".md"
    extra = EXTRA_SUBTREE.get(role)
    if tail[0] == owner_file and len(tail) == 1:
        continue
    if tail[0] == role and len(tail) > 1:
        continue
    if extra and tail[0] == extra:
        continue
    deny("docs/%s/reports/%s belongs to another role. %s writes only "
         "%s, %s/** %s— never a foreign record. (contract v3 s11)"
         % (parts[0], "/".join(tail), role, owner_file, role,
            ("and %s/** " % extra) if extra else ""))

allow()
PY

CORE_PAYLOAD="$payload" python3 -c "$CORE_BOARD_GATE"
rc=$?
trap - EXIT
exit "$rc"
