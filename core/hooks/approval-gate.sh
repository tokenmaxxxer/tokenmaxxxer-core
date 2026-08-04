#!/usr/bin/env bash
# PreToolUse: the phase gate of contract v3 s19. Every role proposes first
# (research, current-state survey, proposal — documents, phase 1) and
# executes only after an allowlisted human's Approve — a PR review, or an
# issue-level `APPROVE issue-<n>/<role>` comment (phase 2).
#
# Deny-only rule: a role session's write to the EXECUTION SURFACE is
# refused while the role's issue-<n>/<role> subject lacks an Approve
# signal authored by an account listed in docs/specs/approvers.md.
# Once the single-account signal is a live issue comment, this
# refusal does not require a PR to be open or to have ever existed —
# the comment path resolves from the issue alone (below); a role's
# frozen proposal scope and the unconditional per-PR merge decision
# bound the work instead (contract v3 s19).
#
# The execution surface is src/**, test/**, and everything under the issue
# tree docs/issue-<n>/ EXCEPT the two phase-1 homes: proposals/** (the
# proposal) and reports/<role>/** (research and current-state material).
# The record file reports/<role>.md is execution output — a doc-producing
# role's deliverable — and waits for the Approve exactly like code does.
#
# Who counts as the human is an allowlist, not a heuristic: bot and agent
# accounts are simply not listed, so a CI Approve or a role approving its
# own PR cannot open phase 2 (contract v3 s8).
#
# The verdict needs GitHub, checked in this order (each a network call).
# First, the issue's own state and comments together (gh issue view
# --json state,comments) — the issue is the one anchor stable across the
# subject's two PRs (phase 1's, then phase 2's), so a closed issue denies
# unconditionally before either approval path is even considered. Then,
# if a PR is currently open on this branch, its reviews (gh pr view
# --json reviews) decide the two-account path; the single-account path
# scans the issue comments already fetched for an exact `APPROVE
# issue-<n>/<role>` string from a listed approver — no PR open is an
# expected gap between the subject's two PRs, not itself a denial.
# Neither result is cached: a cache file would be writable by the model's
# own tools, i.e. a forgeable approval. gh unavailable or failing on
# either call = deny (fail closed). Kill switch: CORE_OFF=1. Test seam:
# CORE_GH overrides the gh executable.
trap 'rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then exit 2; fi' EXIT
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)}/hooks/lib/gate-lib.sh" || { echo "approval-gate.sh: cannot source gate-lib.sh" >&2; exit 2; }
set -uo pipefail

gate_kill_switch_active "${CORE_OFF:-}" || { trap - EXIT; exit 0; }

# Not a role session: none of this gate's business. The user's and the
# orchestrator's own sessions write src/ freely.
[ -n "${CLAUDE_ROLE:-}" ] || { trap - EXIT; exit 0; }

payload="$(cat 2>/dev/null || true)"

# Fast path before python3: only execution-surface writes are adjudicated.
case "$payload" in
  *src/*|*test/*|*issue-*) ;;
  *) trap - EXIT; exit 0 ;;
esac

command -v python3 >/dev/null 2>&1 || exit 2

# bash 3.2: a quoted heredoc nested inside $( … ) is NOT literal — read the
# program at top level.
IFS='' read -r -d '' CORE_APPROVAL_GATE <<'PY' || true
import json, os, posixpath, re, subprocess, sys

import importlib.util
_spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
gate_lib = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(gate_lib)

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
                   "diff", "stat", "file", "git", "cd")
CODE_RE = re.compile(r"(^|/)(src|test)/")
ISSUE_RE = re.compile(r"(^|/)docs/(issue-[0-9]+)/(.*)$")

role = os.environ["CLAUDE_ROLE"].strip()

def norm(p):
    return posixpath.normpath(p.replace("\\", "/"))

def execution_surface(path):
    """True when writing `path` is phase-2 work (contract v3 s19)."""
    n = norm(path)
    im = ISSUE_RE.search(n)
    if im:
        tail = im.group(3)
        # phase-1 homes stay open: the proposal, and the role's own
        # research/current-state subtree (NOT the record file itself)
        if tail.startswith("proposals/") or tail == "proposals":
            return False
        if tail.startswith("reports/%s/" % role):
            return False
        return True
    return bool(CODE_RE.search(n))

candidates = []
if tool in ("Write", "Edit", "MultiEdit", "NotebookEdit"):
    p = ti.get("file_path") or ti.get("notebook_path")
    if isinstance(p, str) and p:
        candidates.append(p)
elif tool == "Bash":
    cmdline = ti.get("command")
    if not isinstance(cmdline, str):
        deny("Bash payload carries no command string")
    head = gate_lib.gate_head_of(cmdline)
    if head in READ_ONLY_HEADS and not gate_lib.gate_outside_quotes(cmdline, r"[>|`]|\$\("):
        allow()              # reading the tree is phase-agnostic
    for tok in re.findall(r"[\w./~$-]+", cmdline):
        if CODE_RE.search(tok) or ISSUE_RE.search(tok):
            candidates.append(tok)
else:
    allow()

hits = [c for c in candidates if execution_surface(c)]
if not hits:
    allow()                  # phase-1 material or unrelated: not this gate's business

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

root = root_of()
if not root:
    deny("cannot resolve the project root for an execution-surface write")

if not os.path.isfile(os.path.join(root, "docs", "specs", "approvers.md")):
    deny("this repository has no docs/specs/approvers.md, but the session "
         "carries CLAUDE_ROLE=%s. A role session works only on a board, and "
         "that file is both the board opt-in and the approver allowlist — "
         "ask the human to add it" % role)

# --- precondition: approvals live on GitHub -----------------------------
try:
    out = subprocess.run(["git", "-C", root, "remote", "get-url", "origin"],
                         capture_output=True, text=True)
    has_remote = out.returncode == 0 and out.stdout.strip()
except Exception:
    has_remote = False
if not has_remote:
    deny("this repository has no git remote 'origin' — there is no PR to "
         "carry a human's Approve, so execution work cannot be authorized "
         "at all. Ask the human to publish the repo first (gh repo create "
         "<owner>/<name> --private --source . --push), then retry. Do not "
         "improvise a local approval. (contract v3 s10)")

# --- the role's issue branch --------------------------------------------
try:
    out = subprocess.run(["git", "-C", root, "symbolic-ref", "--short",
                          "HEAD"], capture_output=True, text=True)
    branch = out.stdout.strip() if out.returncode == 0 else ""
except Exception:
    branch = ""
m = re.match(r"^issue-([0-9]+)/(.+)$", branch)
if not m or m.group(2) != role:
    deny("execution-surface writes happen only on this role's own issue "
         "branch (issue-<n>/%s; current: %s). Check out the branch, submit "
         "phase 1, and get the Approve first. (contract v3 s19)"
         % (role, branch or "<none>"))
issue_num = m.group(1)

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

# --- the issue-state precondition ---------------------------------------
# The issue is the canonical approval anchor (contract v3 s10/s19): it is
# the one location stable across the subject's two PRs (phase 1's, then
# phase 2's, opened after phase 1's has already merged and closed). Its
# open/closed state gates BOTH approval paths below, checked before
# either one, so a closed issue denies unconditionally regardless of any
# standing PR review or issue comment — this is what makes the contract's
# revocation-by-closing guarantee mechanical rather than prose.
gh = os.environ.get("CORE_GH") or "gh"
try:
    issue_out = subprocess.run([gh, "issue", "view", issue_num, "--json",
                                "state,comments"],
                               capture_output=True, text=True, cwd=root)
except OSError:
    deny("cannot run %r to check issue #%s's state — refusing execution "
         "writes rather than assuming approval (fail closed)"
         % (gh, issue_num))
if issue_out.returncode != 0:
    deny("cannot read issue #%s (or gh failed: %s). The issue is the "
         "canonical approval anchor; its own unavailability cannot be "
         "waved through. (contract v3 s19)"
         % (issue_num, (issue_out.stderr or "").strip()[:200]))
try:
    issue_parsed = json.loads(issue_out.stdout)
    issue_state = issue_parsed.get("state") or ""
    issue_comments = issue_parsed.get("comments") or []
except (ValueError, AttributeError):
    deny("unreadable issue JSON from gh; refusing rather than assuming "
         "approval")
if issue_state != "OPEN":
    deny("issue #%s is not open (state: %s) — a closed issue's board is "
         "not live for any role, regardless of any standing PR review or "
         "APPROVE comment. (contract v3 s19)"
         % (issue_num, issue_state or "unknown"))

# --- the Approve signal -------------------------------------------------
# Two spellings, both GitHub acts by an allowlisted human:
#   (a) a PR review with state APPROVED — the two-account path, read from
#       whichever PR is currently open on this branch. No PR open right
#       now is an expected gap in the subject's two-PR practice (phase 1
#       merged, phase 2 not yet opened), not itself a denial;
#   (b) an issue-level comment whose body is EXACTLY
#       "APPROVE issue-<n>/<role>" — the single-account path, because
#       GitHub forbids approving your own PR and with one account the
#       role's PRs are authored by the same login. Exact string equality,
#       never prose interpretation: the measured lesson from the retired
#       mint design. The orchestrator posts it after the human said so in
#       conversation; gh-guard denies role sessions the comment spelling.
challenge = "APPROVE issue-%s/%s" % (issue_num, role)

pr_approved = False
try:
    pr_out = subprocess.run([gh, "pr", "view", branch, "--json", "reviews"],
                            capture_output=True, text=True, cwd=root)
except OSError:
    deny("cannot run %r to check the PR's reviews — refusing execution "
         "writes rather than assuming approval (fail closed)" % gh)
if pr_out.returncode == 0:
    try:
        reviews = (json.loads(pr_out.stdout) or {}).get("reviews") or []
    except (ValueError, AttributeError):
        deny("unreadable reviews JSON from gh; refusing rather than "
             "assuming approval")
    # Last review per author wins: an author who approved and later
    # requested changes has not approved.
    last = {}
    for r in reviews:
        if not isinstance(r, dict):
            continue
        login = ((r.get("author") or {}).get("login") or "").lower()
        state = r.get("state") or ""
        if login and state in ("APPROVED", "CHANGES_REQUESTED", "DISMISSED"):
            last[login] = state
    pr_approved = any(login in approvers and state == "APPROVED"
                      for login, state in last.items())
# pr_out.returncode != 0: no PR open right now — the two-account path is
# simply unavailable, not a denial by itself.

comment_approved = False
for c in issue_comments:
    if not isinstance(c, dict):
        continue
    if c.get("isMinimized"):
        continue  # hidden/minimized is GitHub's own way to retract a
                   # comment without deleting or editing it
    login = ((c.get("author") or {}).get("login") or "").lower()
    body = (c.get("body") or "").strip()
    if login in approvers and body == challenge:
        comment_approved = True
        break

approved = pr_approved or comment_approved

if not approved:
    deny("neither the PR for %s nor issue #%s carries an approval from a "
         "listed human approver (%s): no Approve review on an open PR, "
         "and no issue comment that is exactly '%s'. Free-text comments "
         "are feedback, a bot's or agent's Approve is not a human's, and "
         "phase 2 waits for the human. (contract v3 s19)"
         % (branch, issue_num, ", ".join(approvers), challenge))

allow()
PY

CORE_PAYLOAD="$payload" python3 -c "$CORE_APPROVAL_GATE"
rc=$?
trap - EXIT
exit "$rc"
