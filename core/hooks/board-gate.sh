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
#   R2  A board write requires the target repo's docs/specs/approvers.md —
#       the user-authored opt-in that this repository IS a board, and the
#       allowlist the whole approval model rests on. The canonical contract
#       lives only in this plugin (v3): planting per-repo copies carried
#       zero information (the hash check forced them identical) and made
#       every contract revision an atomic N-repo re-sync.
#
#   R3  A write under docs/issue-<n>/ requires CLAUDE_ROLE in the
#       environment. Role sessions get it from on-the-record; the orchestrator's
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
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)}/hooks/lib/gate-lib.sh" || { echo "board-gate.sh: cannot source gate-lib.sh" >&2; exit 2; }
set -uo pipefail

gate_kill_switch_active "${CORE_OFF:-}" || { trap - EXIT; exit 0; }

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
import json, os, posixpath, re, subprocess, sys

import importlib.util
_spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
gate_lib = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(gate_lib)

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
                   "diff", "stat", "file", "sort", "uniq", "cut",
                   "tr", "echo", "printf", "basename", "dirname", "realpath",
                   "column", "nl", "comm", "jq", "true", "test", "[", "cd")
# sed/awk read by default and only write with -i / redirection. Reading a
# FOREIGN record is sanctioned (s4 READ-broad; s15/s16 require reading the
# finder's record) — measured: a role resolving findings could not open
# review.md via `sed -n` and had to work from a prompt summary.
READ_UNLESS_INPLACE = ("sed", "awk", "gawk")
# A file is written by `> f`, `>> f`, `2> f`, `&> f`. It is NOT written by
# `2>&1` or `>&2`, which duplicate a file descriptor and create nothing —
# hence the (?!&). The previous catch-all `[>|`]` counted both those and
# every pipe as a write, so `ls docs/issue-16/… 2>&1` and
# `git log … -- docs/issue-49 | head` were refused as board writes.
# Measured 2026-07-30: five such refusals in one issue-53 session, every
# one of them a read the contract guarantees (s4 READ-broad).
FILE_REDIR = re.compile(r">>?(?!&)")
# `2>/dev/null` is a redirection that creates nothing; the idiom is in most
# read commands a session writes, so it is stripped before the write scan
# rather than counted. A redirect to any OTHER path still counts — the
# measured deny `git log 2>docs/issue-3/log.txt` must stay a deny.
DEVNULL_REDIR = re.compile(r"[0-9&]?>>?\s*/dev/null")
SUBSHELL = re.compile(r"[`]|\$\(")
# Pipeline/list separators. Every stage is checked, because the head of the
# first stage says nothing about what `| tee docs/x` does downstream.
# Quoted-span alternatives come first (regex alternation is ordered) so a
# `|` or `;` inside a quoted string (e.g. a BRE `grep -n "A\|B"` pattern)
# matches as part of the quote, not as a separator; _split_segments below
# tells the two match kinds apart and only cuts on the real separators.
# (?<!\\) on both quote alternatives: outside any real quote, `\"`/`\'` is
# a backslash-escaped literal quote CHARACTER, not the start of a quoted
# region — without the lookbehind a bare quote char there would still open
# a "quote" match here, run to some unrelated later quote char (e.g. one
# inside a trailing `#` comment), and swallow a real `;`/`|` separator in
# between as if it were quoted content, hiding a real write in what the
# shell treats as a second, separate command (found by warrant-hunt,
# issue-88: `ls \" ; rm -rf docs/issue-1/x #"` fell through to allow()
# before this lookbehind). The rare converse (a real quote preceded by an
# already-escaped backslash, e.g. `\\"real quote"`) now instead over-splits
# — the safe direction (comment at board-gate.sh:173).
SEGMENT = re.compile(gate_lib.GATE_QUOTE_SPAN.pattern + r"|\|\||&&|[|;\n]")


def _split_segments(cmdline):
    """Same shape as SEGMENT.split(cmdline), but a quoted span never cuts.

    SEGMENT now also matches whole quoted spans so it can tell them apart
    from real separators; a plain .split() would still cut at those spans.
    This walks the matches instead: a quote match extends the current
    segment, a separator match ends it.
    """
    segments = []
    current = []
    pos = 0
    for m in SEGMENT.finditer(cmdline):
        start, end = m.span()
        current.append(cmdline[pos:start])
        token = m.group()
        if token[:1] in ("'", '"'):
            current.append(token)
        else:
            segments.append("".join(current))
            current = []
        pos = end
    current.append(cmdline[pos:])
    segments.append("".join(current))
    return segments


INPLACE = re.compile(r"(^|\s)-i\b|--in-place")
# sed's own file-write mechanism, independent of -i: the `w`/`W` command
# (as its own command, or as an `s///...w file` trailing flag). Scoped to
# a `w`/`W` word boundary followed by whitespace-then-a-filename-char, so
# an ordinary word beginning with w ("with", "while", ...) never matches
# (issue-98).
SED_WRITE_CMD = re.compile(r"\b[wW]\s+\S")
# `git` needed to split off READ_ONLY_HEADS: unlike the other entries there,
# read vs. write is decided by the SUBCOMMAND, not the command name — `git
# log` cannot write a file but `git rm`/`checkout --`/`restore`/`clean`/
# `apply`/`mv`/`stash` can. Trusting "git" whole-command let those bypass
# the write scan entirely (issue-60).
GIT_READ_SUBCOMMANDS = ("log", "show", "diff", "status", "blame",
                        "ls-files", "ls-tree", "ls-remote", "cat-file",
                        "rev-parse", "symbolic-ref", "describe", "shortlog",
                        "reflog")


def _git_subcommand(segment):
    """The git subcommand a segment invokes, or "" if unresolved.

    "" is deliberately not in GIT_READ_SUBCOMMANDS, so a bare `git`, or one
    preceded only by argument-taking global flags (e.g. `-C <dir>`) this
    function does not special-case, falls through to the normal write scan
    — the safe direction, not a new hole.
    """
    words = segment.split()[1:]
    for w in words:
        if not w.startswith("-"):
            return w
    return ""


def _write_candidate_segments(cmdline):
    """Segments of this command line that could not be proven read-only.

    Same classification rules _reads_only used to apply inline (SUBSHELL/
    FILE_REDIR, git subcommand, READ_ONLY_HEADS, READ_UNLESS_INPLACE), but
    checked per-segment and returning WHICH segments failed instead of
    collapsing to one bool — issue-90: a docs-path token sitting inside a
    different, already-provably-read-only segment must not become a write
    candidate just because some other segment on the same line couldn't be
    classified.
    """
    probe = DEVNULL_REDIR.sub(" ", cmdline)
    segments = _split_segments(probe)
    failing = []
    for seg in segments:
        stripped = seg.strip()
        if not stripped:
            continue
        if SUBSHELL.search(seg) or gate_lib.gate_outside_quotes(seg, FILE_REDIR.pattern):
            failing.append(seg)
            continue
        head = gate_lib.gate_head_of(stripped)
        if head == "git":
            if _git_subcommand(stripped) in GIT_READ_SUBCOMMANDS:
                continue
            failing.append(seg)
            continue
        if head in READ_ONLY_HEADS:
            continue
        if head in READ_UNLESS_INPLACE:
            writes = INPLACE.search(stripped) is not None
            # sed/awk read by default; both also have a write mechanism
            # that doesn't involve -i, checked RAW (not gate_outside_quotes)
            # -- the wrapped program argument is not inert data here, same
            # reasoning issue-98/Finding-1 turns on for `bash -c` (issue-98).
            if not writes and head in ("awk", "gawk"):
                writes = FILE_REDIR.search(stripped) is not None
            if not writes and head == "sed":
                writes = SED_WRITE_CMD.search(stripped) is not None
            if not writes:
                continue
        failing.append(seg)
    return failing


def _reads_only(cmdline):
    """True when no stage of this command line can write a file."""
    return not _write_candidate_segments(cmdline)

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
        failing_segments = _write_candidate_segments(cmdline)
        if not failing_segments:
            allow()          # a plain read of the board is not a write (s4)
        # every docs-path-shaped token in a segment that could not be
        # proven read-only becomes a candidate target (issue-90: scoped to
        # those segments, not the whole cmdline); this is a superset scan
        # within scope, and over-blocking is the safe direction here
        scan_text = "\n".join(failing_segments)
        for tok in re.findall(r"[\w./~$-]*%s[\w./-]*" % re.escape(DOCS), scan_text):
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

role = os.environ.get("CLAUDE_ROLE", "").strip()
root = root_of()
if not root:
    deny("cannot resolve the project root for a docs/ write")

marker = os.path.join(root, "docs", "specs", "approvers.md")
is_board = os.path.isfile(marker)
if not is_board and not role:
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

# --- R2: the board requires the user's approvers.md ----------------------
if not is_board:
    deny("this repository has no docs/specs/approvers.md. That file is the "
         "user's opt-in that this repo is a board AND the human-approver "
         "allowlist; without it no approval can ever be verified. Ask the "
         "human to add it (one line per GitHub login) before board work")

if not issue_hits:
    allow()                      # standing-doc write by a role: layout + contract suffice

# --- R3: no role, no board writes ---------------------------------------
if not role:
    deny("a write under docs/issue-<n>/ from a session with no CLAUDE_ROLE. "
         "The board belongs to role sessions; this one carries no rulebook "
         "gates. (contract v3 s8/s10)")

# --- precondition: a board lives on GitHub ------------------------------
# Issues, PRs, and reviews are GitHub objects; a local-only repository has
# no issue to anchor this tree to and no PR to return it through
# (contract v3 s10).
try:
    out = subprocess.run(["git", "-C", root, "remote", "get-url", "origin"],
                         capture_output=True, text=True)
    has_remote = out.returncode == 0 and out.stdout.strip()
except Exception:
    has_remote = False
if not has_remote:
    deny("this repository has no git remote 'origin', so issue-<n> can "
         "reference no real issue and no PR can return this work. Ask the "
         "human to publish the repo first (gh repo create <owner>/<name> "
         "--private --source . --push), then retry. Do not improvise a "
         "local substitute. (contract v3 s10)")

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
    if tail[0] == role:
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
