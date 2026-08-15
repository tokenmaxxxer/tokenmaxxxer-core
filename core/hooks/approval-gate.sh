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
#
# Build-now bypass (contract v3 s19a, issue-212): when the spawn task
# itself sets CORE_BUILD_NOW=1 (an env var the spawner controls, same as
# CLAUDE_ROLE), the proposal round is explicitly waived and execution-
# surface writes are allowed without an Approve signal. Unset by default,
# so ordinary tasks keep the two-phase gate unchanged.
trap 'rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then exit 2; fi' EXIT
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)}/hooks/lib/gate-lib.sh" || { echo "approval-gate.sh: cannot source gate-lib.sh" >&2; exit 2; }
set -uo pipefail

gate_kill_switch_active "${CORE_OFF:-}" || { trap - EXIT; exit 0; }

# Not a role session: none of this gate's business. The user's and the
# orchestrator's own sessions write src/ freely.
[ -n "${CLAUDE_ROLE:-}" ] || { trap - EXIT; exit 0; }

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || { echo "approval-gate.sh: refused — empty tool-use payload on stdin; cannot evaluate the approval gate." >&2; exit 2; }

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

# --- build-now bypass (contract v3 s19a) ---------------------------------
# The spawn task, not the role itself, sets CORE_BUILD_NOW=1 — the same
# way it sets CLAUDE_ROLE — to explicitly authorize delivery-only work.
# When present, the proposal round is skipped and execution-surface
# writes are allowed without an Approve signal. Absent (the default),
# behavior is unchanged: the two-phase gate below still applies.
if os.environ.get("CORE_BUILD_NOW", "").strip() == "1":
    allow()

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
                                "state,comments,state_reason"],
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
    # Read-only, reporting/routing only (design decision 4): never an
    # enforcement input — closing an issue stays exclusively human
    # (gh-guard.sh, unchanged).
    issue_state_reason = issue_parsed.get("state_reason") or ""
except (ValueError, AttributeError):
    deny("unreadable issue JSON from gh; refusing rather than assuming "
         "approval")
if issue_state != "OPEN":
    # issue-189 decision 1: interpolate state_reason (already fetched
    # above, previously unused) when GitHub supplied one, so a session or
    # human reading the refusal knows shipped-vs-abandoned without a
    # separate `gh issue view`. Lenient: an absent/unrecognized reason
    # falls back to the original message verbatim — no new failure mode.
    if issue_state_reason:
        deny("issue #%s is not open (state: %s, reason: %s) — a closed "
             "issue's board is not live for any role, regardless of any "
             "standing PR review or APPROVE comment. (contract v3 s19)"
             % (issue_num, issue_state or "unknown", issue_state_reason))
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
# design decision 2: REJECT mirrors APPROVE exactly — same exact-match/
# approvers.md-gated/isMinimized-skip machinery, parameterized challenge
# string, no new trust boundary. Read-only: recognizing it never writes
# or auto-denies anything on its own (design's explicit deferred item).
reject_challenge = "REJECT issue-%s/%s" % (issue_num, role)
# issue-189 decision 2: WITHDRAW/DEFER complete the REJECT/APPROVE-
# symmetric token family — same exact-match/approvers.md-gated/
# isMinimized-skip machinery, two more challenge strings, no new
# function, no new trust boundary. WITHDRAW is the role's own
# author-side voluntary stop (posted by the human on the role's
# behalf); DEFER is a postponement either side may post. Neither
# asserts a defect the way REJECT does.
withdraw_challenge = "WITHDRAW issue-%s/%s" % (issue_num, role)
defer_challenge = "DEFER issue-%s/%s" % (issue_num, role)

def comment_matches(challenge_str):
    for c in issue_comments:
        if not isinstance(c, dict):
            continue
        if c.get("isMinimized"):
            continue  # hidden/minimized is GitHub's own way to retract a
                       # comment without deleting or editing it
        login = ((c.get("author") or {}).get("login") or "").lower()
        body = (c.get("body") or "").strip()
        if login in approvers and body == challenge_str:
            return True
    return False

pr_approved = False
try:
    pr_out = subprocess.run([gh, "pr", "view", branch, "--json", "reviews"],
                            capture_output=True, text=True, cwd=root)
except OSError:
    deny("cannot run %r to check the PR's reviews — refusing execution "
         "writes rather than assuming approval (fail closed)" % gh)
rejection_finding = None
if pr_out.returncode == 0:
    try:
        reviews = (json.loads(pr_out.stdout) or {}).get("reviews") or []
    except (ValueError, AttributeError):
        deny("unreadable reviews JSON from gh; refusing rather than "
             "assuming approval")
    # Last review per author wins: an author who approved and later
    # requested changes has not approved.
    last = {}
    last_body = {}
    for r in reviews:
        if not isinstance(r, dict):
            continue
        login = ((r.get("author") or {}).get("login") or "").lower()
        state = r.get("state") or ""
        if login and state in ("APPROVED", "CHANGES_REQUESTED", "DISMISSED"):
            last[login] = state
            last_body[login] = (r.get("body") or "").strip()
    pr_approved = any(login in approvers and state == "APPROVED"
                      for login, state in last.items())
    # design decision 2, step-1 finding #7: use the CHANGES_REQUESTED vs
    # DISMISSED distinction instead of discarding it. CHANGES_REQUESTED
    # from an approver is a rejection act (review body -> rationale);
    # DISMISSED is a revoked opinion, no rejection asserted. Either
    # outcome emits at most one contract §5 finding block, never a
    # second finding shape — this is the trigger, not a second record.
    for login, state in last.items():
        if login in approvers and state == "CHANGES_REQUESTED":
            rejection_finding = {
                "requirement": "issue-%s/%s phase-2 approval" % (issue_num, role),
                "verdict": "contradicts",
                "evidence": "PR review by @%s: CHANGES_REQUESTED" % login,
                "rationale": last_body.get(login) or "(no review body)",
                "addressed_to": role,
                "severity": "blocking",
            }
            break
# pr_out.returncode != 0: no PR open right now (see comment above the
# "no PR open" note further down) — the two-account path, and the
# CHANGES_REQUESTED/DISMISSED read above (which lives inside this same
# guarded branch, never as an unconditional `last` reference), are both
# simply unavailable then, not a denial by themselves.

comment_approved = comment_matches(challenge)
comment_rejected = comment_matches(reject_challenge)
comment_withdrawn = comment_matches(withdraw_challenge)
comment_deferred = comment_matches(defer_challenge)
if comment_rejected and rejection_finding is None:
    rejection_finding = {
        "requirement": "issue-%s/%s phase-2 approval" % (issue_num, role),
        "verdict": "contradicts",
        "evidence": "issue comment exactly '%s' from a listed approver" % reject_challenge,
        "rationale": "issue-level REJECT token",
        "addressed_to": role,
        "severity": "blocking",
    }

# issue-189 decision 2: WITHDRAW/DEFER produce a finding-shaped record
# exactly like REJECT does, but severity: advisory — withdrawal and
# deferral are not defects being flagged, so they must not read as
# blocking findings the way REJECT's does. No `verdict` field: contract
# §5's finding schema does not define one (the pre-existing
# rejection_finding's `verdict: contradicts` predates this design and is
# not this decision's shape to reuse).
withdraw_finding = None
if comment_withdrawn:
    withdraw_finding = {
        "requirement": "issue-%s/%s phase-2 approval" % (issue_num, role),
        "evidence": "issue comment exactly '%s' from a listed approver" % withdraw_challenge,
        "rationale": "issue-level WITHDRAW token — voluntary stop, no defect asserted",
        "addressed_to": role,
        "severity": "advisory",
    }
defer_finding = None
if comment_deferred:
    defer_finding = {
        "requirement": "issue-%s/%s phase-2 approval" % (issue_num, role),
        "evidence": "issue comment exactly '%s' from a listed approver" % defer_challenge,
        "rationale": "issue-level DEFER token — postponed, resumable later",
        "addressed_to": role,
        "severity": "advisory",
    }

approved = pr_approved or comment_approved

if not approved:
    if rejection_finding is not None:
        deny("issue-%s/%s was rejected, not merely unapproved: finding "
             "{requirement: %s, verdict: %s, evidence: %s, rationale: %s, "
             "addressed_to: %s, severity: %s}. (contract v3 s19, design "
             "decision 2)"
             % (issue_num, role, rejection_finding["requirement"],
                rejection_finding["verdict"], rejection_finding["evidence"],
                rejection_finding["rationale"], rejection_finding["addressed_to"],
                rejection_finding["severity"]))
    if withdraw_finding is not None:
        deny("issue-%s/%s was withdrawn, not merely unapproved: finding "
             "{requirement: %s, evidence: %s, rationale: %s, addressed_to: "
             "%s, severity: %s}. loop_state: withdrawn. (contract v3 s19, "
             "issue-189 decision 2)"
             % (issue_num, role, withdraw_finding["requirement"],
                withdraw_finding["evidence"], withdraw_finding["rationale"],
                withdraw_finding["addressed_to"], withdraw_finding["severity"]))
    if defer_finding is not None:
        deny("issue-%s/%s was deferred, not merely unapproved: finding "
             "{requirement: %s, evidence: %s, rationale: %s, addressed_to: "
             "%s, severity: %s}. loop_state: deferred. (contract v3 s19, "
             "issue-189 decision 2)"
             % (issue_num, role, defer_finding["requirement"],
                defer_finding["evidence"], defer_finding["rationale"],
                defer_finding["addressed_to"], defer_finding["severity"]))
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
if [ "$rc" -ne 0 ] && [ "$rc" -ne 2 ]; then
  echo "approval-gate.sh: refused — fail-closed: internal error (gate judge exited $rc)" >&2
  exit 2
fi
exit "$rc"
