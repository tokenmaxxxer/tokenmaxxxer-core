#!/usr/bin/env bash
# PreToolUse hook (Write|Edit|NotebookEdit|Bash): enforces the two mechanical
# halves of the protocol.
#
#   1. While a proposal is approved and in progress, edits land only in paths
#      its frontmatter froze.
#   2. While one is in progress, a commit carries the `Proposal:` trailer.
#
# Both read the TOOL INPUT — a path, a command string — before anything happens.
# Neither reads generated content, and neither judges the work: which bucket, or
# whether the change is any good, is the directive's business.
#
# Inert unless exactly one proposal is `status: approved`. No open unit, none
# approved, or several at once (ambiguous) — the gate stands down rather than
# guessing.
#
# Fails open on a missing python3, unreadable payload, or unexpected schema.
# Kill switch: export WARRANT_OFF=1

. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)}/hooks/lib/gate-lib.sh" || { echo "scope-gate.sh: cannot source gate-lib.sh" >&2; exit 2; }
gate_trap_fail_closed
set -uo pipefail
gate_kill_switch_active "${WARRANT_OFF:-}" || { trap - EXIT; exit 0; }

command -v python3 >/dev/null 2>&1 || { trap - EXIT; exit 0; }

payload="$(cat)"

WARRANT_PAYLOAD="$payload" python3 <<'PY'
import json
import os
import posixpath
import re
import sys

# `approved`, `Approved`, and `approved   # go` are the same intent; a value that
# is none of the three known states is reported rather than read as "not approved".
STATUS = re.compile(r"^status:\s*([A-Za-z]+)\s*(?:#.*)?$", re.M)
KNOWN_STATES = ("proposed", "approved", "landed", "withdrawn", "rejected")
# `git commit`, `git  commit`, `git -C path commit` are one command.
GIT_COMMIT = re.compile(r"\bgit\b(?:\s+-[A-Za-z]\S*(?:\s+\S+)?|\s+--\S+)*\s+commit\b")
FILE_ITEM = re.compile(r"^\s*-\s*(.+?)\s*$")


def allow():
    sys.exit(0)


try:
    event = json.loads(os.environ.get("WARRANT_PAYLOAD", ""))
except ValueError:
    allow()
if not isinstance(event, dict):
    allow()

tool = event.get("tool_name") or ""
tool_input = event.get("tool_input")
if not isinstance(tool_input, dict):
    allow()

root = (os.environ.get("CLAUDE_PROJECT_DIR") or os.getcwd()).replace("\\", "/")
root = posixpath.normpath(root)
# Without CLAUDE_PROJECT_DIR the cwd could be anywhere; anchor on the git root so
# the gate never treats a scratch directory as the project it is guarding.
try:
    import subprocess
    top = subprocess.run(["git", "-C", root, "rev-parse", "--show-toplevel"],
                         capture_output=True, text=True, timeout=5).stdout.strip()
    if top:
        root = posixpath.normpath(top.replace("\\", "/"))
    elif not os.environ.get("CLAUDE_PROJECT_DIR"):
        allow()
except (OSError, subprocess.SubprocessError):
    if not os.environ.get("CLAUDE_PROJECT_DIR"):
        allow()
proposals_dir = posixpath.join(root, "docs", "proposals")


def nested_units():
    """Proposal directories this gate does not read — a monorepo's packages/*/docs/proposals."""
    found = []
    for base, dirs, files in os.walk(root):
        depth = base[len(root):].count("/")
        if depth >= 4:          # packages/<name>/docs/proposals and no deeper
            dirs[:] = []
        dirs[:] = [d for d in dirs if not d.startswith(".") and d != "node_modules"]
        if base == proposals_dir:
            continue
        if base.replace("\\", "/").endswith("/docs/proposals") and any(
            f.endswith(".md") and f != "README.md" for f in files
        ):
            found.append(posixpath.relpath(base, root))
    return found


def stand_down():
    """Nothing enforceable here — but say why if the reason is reach, not absence."""
    nested = nested_units()
    if nested:
        print(
            "warrant: %s holds proposals, but this gate reads the repository root only "
            "(docs/proposals). Nothing is being enforced for those units."
            % ", ".join(nested), file=sys.stderr)
        sys.exit(1)
    allow()


if not os.path.isdir(proposals_dir):
    stand_down()


def frontmatter(path):
    try:
        with open(path, encoding="utf-8-sig") as handle:
            text = handle.read(65536)
    except (OSError, UnicodeDecodeError):
        # Unreadable bytes are as blinding as a missing closing `---`; both are
        # reported by the caller rather than crashing the gate open.
        return None
    if not text.startswith("---"):
        return None
    end = text.find("\n---", 3)
    return text[3:end] if end != -1 else None


# Needed ahead of the malformed-frontmatter branch below: when no single
# approved unit is enforceable, a read-only tool call still gets vouched for
# (warning on stderr, allow) rather than blocked — a gate that cannot
# enforce a write-set has nothing to protect from a read, and blocking every
# read leaves the session unable to even inspect the file the gate is
# complaining about (issue-216, observed as on-the-record#1581).
READ_TOOLS = {"Read", "Grep", "Glob", "NotebookRead"}
# `|` is deliberately NOT in here: a single pipe of read-only commands
# (`grep ... | head`) is the dominant real-world read shape and is vetted by
# splitting on `|` below instead. Everything else that can chain in an
# unvetted second command, redirect a write, or smuggle a second command via
# a newline stays disqualifying.
SHELL_CHAIN = re.compile(r"[;&`]|\$\(|\|\||[<>]|\n")
SAFE_ARG = r"(?:\s+[^\s;&|`$<>]+)*"
READONLY_ALLOW = [
    re.compile(r"^git\s+(status|diff|log|show|branch|rev-parse|blame)" + SAFE_ARG + r"\s*$"),
    re.compile(r"^(ls|cat|pwd|echo|which|head|tail|wc|find|grep|file)" + SAFE_ARG + r"\s*$"),
    re.compile(r"^python3\s+-m\s+pytest" + SAFE_ARG + r"\s*$"),
    re.compile(r"^bash\s+\S+/(run-gate-lib-tests|run-role-gates-tests)\.sh" + SAFE_ARG + r"\s*$"),
]
# find's exec-capable flags run arbitrary commands or mutate the filesystem;
# a `find` segment carrying any of these is never read-only regardless of
# what else it matches.
FIND_EXEC_FLAGS = re.compile(
    r"(?:^|\s)-(?:exec|execdir|ok|okdir|delete|fprint0?|fprintf|fls)\b")

# issue-225: an interpreter invocation carrying an inline body -- a heredoc,
# or a '-c'/'-e' string -- or a tee/dd invocation is not provably read-only
# (SHELL_CHAIN's `<` already disqualifies the heredoc form from
# readonly_allowed, and tee/dd/`-c` never matched READONLY_ALLOW), but it
# was previously left to "decline to vouch" (allow() with no
# permissionDecision) the same as any other unproven command -- which
# lets a session running with auto-accept permissions execute it anyway,
# writing wherever the masked body names, unseen by the frozen write set.
# The live bypass (on-the-record PR #1627): board-gate denied a direct
# Edit outside the write set, and the same session rewrote the file via
# `python3 - <<EOF` instead. Denied outright, but ONLY while a write-set
# is actually being enforced (exactly one proposal approved, the branch
# this whole block already runs in) -- an unrestricted session with no
# approved proposal never reaches here (stand_down() above).
UNANALYZABLE_WRITE_SHAPE = re.compile(
    r"<<-?\s*['\"]?\w"
    r"|(?:^|\s)(?:python3?|bash|sh|zsh|perl|ruby|node|nodejs)\b[^\n|;&]*\s-[A-Za-z]*[ce](?:\s|=|$)"
    r"|(?:^|\s)tee\b"
    r"|(?:^|\s)dd\b"
    # issue-227: `ed`/`ex` write via script commands (`w file`) that this
    # gate cannot parse out of the invocation text -- any invocation is
    # treated as unanalyzable, same as `tee`/`dd`.
    r"|(?:^|\s)(?:ed|ex)\b"
    # issue-227: awk/gawk/nawk/mawk can ALSO write a file straight from
    # their program text (`awk 'BEGIN{print "x" > "f"}'`, `system(...)`,
    # or gawk's own `-i inplace`) -- but awk/gawk/nawk/mawk are ordinary
    # read commands by default (`awk '{print $1}' file.txt`), unlike
    # ed/ex. issue-227 re-review finding (d): an earlier, unconditional
    # version of this clause hard-denied every awk-family invocation,
    # including plain reads -- a real over-block regression for the
    # dominant, safe use of these tools. Scoped with a lookahead so only
    # an invocation that ALSO carries a write marker (`system(`, a `>`
    # redirect, or `-i`) trips it; a read with none of those keeps
    # falling through to readonly_allowed()'s ordinary decline-to-vouch.
    r"|(?:^|\s)(?:awk|gawk|nawk|mawk)\b(?=[^\n]*(?:system\s*\(|>|-i\b))"
    # issue-227 review: `python3$(printf " ")-c '...'` / backtick fusion
    # glues the interpreter name straight onto the command-substitution
    # token, so the interpreter head above (which requires literal `\s`
    # before `-c`/`-e`) never fires -- gate_head_of never even sees a bare
    # `python3` word. Fusion via `$(` or a backtick immediately after an
    # interpreter name is itself unanalyzable.
    r"|\b(?:python3?|bash|sh|zsh|perl|ruby|node|nodejs)\b\S*(?:\$\(|`)"
    # issue-227 review: `P=python3; $P -c '...'` indirects the interpreter
    # head through a variable, so no literal interpreter name sits next to
    # `-c`/`-e` at all. Caught only when the same variable is assigned an
    # interpreter name earlier in the same command text. issue-227
    # re-review B1: the brace form (`${P}`) also indirects and was missed
    # by `\$\1\b`, which never matches `${P}`.
    r"|\b(\w+)=(?:python3?|bash|sh|zsh|perl|ruby|node|nodejs)\b[^\n]*"
    r"(?:\$\{\1\}|\$\1\b)[^\n]*-[ce]\b"
    # issue-227: `${IFS}`/`$IFS` used as a space substitute fuses what
    # would otherwise be separate tokens (`python3${IFS}-c${IFS}"..."`),
    # defeating the literal-`\s`-before-`-c`/`-e` requirement in the
    # pattern above. No legitimate gated write needs `$IFS` in its
    # command text, so its bare presence is itself an unanalyzable shape.
    # Anchored so `$IFSHOME`/`${IFS_DIR}` -- distinct variable names that
    # merely start with the four letters IFS -- are plain reads, not hits
    # (issue-227 review finding 1: the unanchored form denied both).
    r"|\$IFS(?![A-Za-z0-9_])|\$\{IFS(?=[:}])"
)


def _segment_readonly(segment):
    if not any(pattern.match(segment) for pattern in READONLY_ALLOW):
        return False
    if re.match(r"^find\b", segment) and FIND_EXEC_FLAGS.search(segment):
        return False
    return True


def readonly_allowed(command):
    if SHELL_CHAIN.search(command):
        # Chaining/redirection/newline-smuggling can hide an unvetted second
        # command or a write; do not try to parse it.
        return False
    stripped = command.strip()
    segments = [seg.strip() for seg in stripped.split("|")]
    if not segments or any(not seg for seg in segments):
        return False
    return all(_segment_readonly(seg) for seg in segments)


def call_is_readonly():
    if tool in READ_TOOLS:
        return True
    if tool == "Bash":
        command = tool_input.get("command")
        return isinstance(command, str) and command.strip() and readonly_allowed(command)
    return False


approved = []
malformed = []
for name in sorted(os.listdir(proposals_dir)):
    if not name.endswith(".md") or name == "README.md":
        continue
    block = frontmatter(posixpath.join(proposals_dir, name))
    if block is None:
        malformed.append(name)
        continue
    found = STATUS.search(block)
    state = found.group(1).lower() if found else None
    if state == "approved":
        approved.append((name, block))
    elif state not in KNOWN_STATES:
        malformed.append(name)

# No unambiguous unit in flight — nothing to enforce against. A proposal whose
# frontmatter will not parse is reported rather than passed over in silence: an
# unreadable warrant is how the gate would quietly stop existing.
if len(approved) != 1:
    if len(approved) > 1:
        print(
            "warrant: %s are all marked approved. One unit is enforceable at a time, so the write "
            "set and trailer rules are OFF until exactly one is approved — set the finished ones to "
            "`landed`." % ", ".join("docs/proposals/" + n for n, _ in approved),
            file=sys.stderr)
        sys.exit(1)
    if malformed:
        print(
            "warrant: %s cannot be read — the frontmatter has no closing `---`, or its status is "
            "not one of proposed/approved/landed. The gate is standing down until it is valid."
            % ", ".join("docs/proposals/" + n for n in malformed),
            file=sys.stderr,
        )
        if call_is_readonly():
            # Nothing enforceable, and this call cannot write anyway — vouching
            # for it costs nothing and unblocks inspecting the very file the
            # warning names. Writes still hit the sys.exit(1) above (remapped
            # to exit 2 by the fail-closed trap).
            sys.exit(0)
        sys.exit(1)
    stand_down()

name, block = approved[0]
proposal_path = "docs/proposals/" + name

write_set = []
if "files:" in block:
    for line in block.split("files:", 1)[1].splitlines():
        item = FILE_ITEM.match(line)
        if item is None:
            if line.strip():
                break          # the next key ends the list
            continue
        entry = item.group(1).strip().strip("'\"").strip("/")
        # `---` is a delimiter, never a path; a bare key is not a path either.
        if not entry or set(entry) == {"-"} or entry.endswith(":"):
            continue
        write_set.append(entry)

# Approval covers the work, so while a unit is in flight the shell is open by
# default. Two things stay outside that grant: landing the work is the user's
# call, and irreversible damage should never ride in on a build approval.
WITHHELD = [
    (re.compile(r"\bgit\s+push\b"), "pushing is a landing step"),
    (re.compile(r"\bgit\s+merge\b"), "merging is a landing step"),
    (re.compile(r"\bgit\s+rebase\b"), "rebasing rewrites landed history"),
    (re.compile(r"\bgit\s+reset\s+--hard\b"), "hard reset discards work"),
    (re.compile(r"\bgit\s+branch\s+-[dD]\b"), "deleting a branch is cleanup after landing"),
    (re.compile(r"\bgit\s+clean\s+-[a-z]*f"), "clean -f discards untracked work"),
    (re.compile(r"\brm\s+-[a-z]*[rR]"), "recursive delete"),
    (re.compile(r"\bsudo\b"), "privilege escalation"),
    (re.compile(r"\|\s*(sudo\s+)?(ba)?sh\b"), "piping into a shell"),
    (re.compile(r"\bmkfs\b|\bdd\s+if="), "raw disk write"),
    # Writing files THROUGH the shell goes around every path-based gate — this
    # one's write set and doctrine's buckets both. Approval covers running the
    # work, not editing by redirection, so those keep their permission prompt.
    (re.compile(r"(?<![0-9&])>{1,2}(?![&|])"), "writing a file by shell redirection"),
    (re.compile(r"\btee\b"), "writing a file with tee"),
    (re.compile(r"\b(sed|perl|ruby)\b[^|]*\s-i\b"), "in-place file edit"),
    (re.compile(r"\btruncate\b"), "truncating a file"),
]


def withheld(command):
    for pattern, why in WITHHELD:
        if pattern.search(command):
            return why
    return None


# A6 (A4 fix): Bash is never checked against the write set, and the withhold
# list only sees literal substrings (defeated by `F=-rf; rm $F`). Rather than
# chase indirection forms, Bash stops being auto-approved by default: only a
# narrow allowlist of commands provably read-only/inspection gets vouched
# for. Everything else — including anything the gate cannot prove is
# read-only — falls through to the normal permission prompt, same posture as
# a `withheld()` match.
# (SHELL_CHAIN, SAFE_ARG, READONLY_ALLOW, readonly_allowed are defined above,
# ahead of the malformed-frontmatter branch, which needs them too.)
if tool == "Bash":
    command = tool_input.get("command")
    if not isinstance(command, str) or not command.strip():
        allow()

    # issue-225: checked ahead of withheld()/readonly_allowed() -- tee and dd
    # otherwise match WITHHELD's own tee/dd entries first and merely
    # decline to vouch (same as e.g. `git push`), which is the wrong
    # posture for a shape whose write target this gate cannot read at all.
    if UNANALYZABLE_WRITE_SHAPE.search(command):
        print(
            "warrant: refused — this Bash call carries an un-analyzable "
            "write-capable shape (a heredoc body, an interpreter -c/-e "
            "inline script, or tee/dd) while %s's write set is enforced. "
            "Its real write target is not visible in the command text, "
            "so this refuses rather than risk a masked out-of-set write "
            "(issue-225). Use a provably read-only invocation (e.g. "
            "python3 -m pytest), or write through Write/Edit or a plain "
            "redirect the write-set check can read the target of."
            % proposal_path,
            file=sys.stderr,
        )
        sys.exit(2)

    reason = withheld(command)
    if reason is not None:
        # Not refused — warrant simply declines to vouch, and the normal
        # permission prompt decides.
        allow()

    if GIT_COMMIT.search(command) and "Proposal: " + proposal_path not in command:
        print(
            "warrant: refused — this commit carries no warrant.\n"
            "A unit is in progress (%s), so every commit for it ends with:\n"
            "    Proposal: %s\n"
            "Add the trailer as the last line of the commit message."
            % (proposal_path, proposal_path),
            file=sys.stderr,
        )
        sys.exit(2)

    if not readonly_allowed(command):
        # Cannot prove this command is read-only/inspection-only, and it was
        # never checked against the frozen write set — decline to vouch and
        # let the normal permission prompt decide, rather than auto-approving.
        allow()

    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "allow",
        "permissionDecisionReason":
            "warrant: %s is approved and in progress; approval covers the work it described."
            % proposal_path,
    }}))
    sys.exit(0)

path = tool_input.get("file_path") or tool_input.get("notebook_path")
if not isinstance(path, str) or not path:
    allow()

normalized = path.replace("\\", "/")
absolute = posixpath.normpath(
    normalized if posixpath.isabs(normalized) else posixpath.join(root, normalized)
)
# A path inside the write set can still be a symlink pointing elsewhere; judge the
# destination, not the name. realpath resolves the parent chain for files that do
# not exist yet, which is the normal case for a first write.
resolved = posixpath.normpath(os.path.realpath(absolute).replace("\\", "/"))
real_root = posixpath.normpath(os.path.realpath(root).replace("\\", "/"))
if resolved != real_root and not resolved.startswith(real_root + "/"):
    if absolute != resolved:
        print(
            "warrant: refused — `%s` resolves to `%s`, outside the repository. A symlink does not "
            "widen the write set." % (absolute[len(root) + 1:] if absolute.startswith(root + "/")
                                      else absolute, resolved),
            file=sys.stderr)
        sys.exit(2)
    allow()
relative = resolved[len(real_root) + 1:]

# The proposal itself stays writable: status flips and checklist ticks are the
# protocol's own bookkeeping, not the work.
if relative == proposal_path:
    allow()

# So is the record the work produces. doctrine asks for a decision record, a
# report, or a handbook update at the moment the work creates one; a write set
# listing only code would make that impossible, and the two plugins would
# deadlock with the record silently never written. Documents are bookkeeping
# here, not scope — doctrine's own gate still decides where they may land.
if relative.split("/")[0] == "docs" or "/docs/" in "/" + relative:
    allow()

for entry in write_set:
    if relative == entry or relative.startswith(entry.rstrip("/") + "/"):
        allow()

# issue-187: a hook-script edit outside the frozen write set is a class of
# its own. Blanket-denying it regardless of content only rewards the
# scratchpad-write + `mv` workaround (#476's exact lesson) — a legitimately
# scoped edit still needs a way to prove its content is safe. Content-
# inspect this one narrow class instead of denying on path alone; every
# other path keeps today's content-blind write-set behavior.
HOOK_SCRIPT_RE = re.compile(r"(^|/)hooks/[^/]+\.sh$")
UNSAFE_HOOK_CONTENT = [
    (re.compile(r"\|\s*(sudo\s+)?(ba)?sh\b"), "piping into a shell"),
    (re.compile(r"\b(curl|wget)\b[^\n]*\|\s*(sudo\s+)?(ba)?sh\b"),
     "piping a download into a shell"),
    (re.compile(r"\brm\s+-[A-Za-z]*[rR][A-Za-z]*(\s|$)"), "recursive delete"),
    (re.compile(r"\bsudo\b"), "privilege escalation"),
    # `trap - EXIT` (restore the default action) is the project-wide
    # sanctioned early-exit idiom every gate script uses on its own kill
    # switch/success path (`{ trap - EXIT; exit 0; }`) — flagging it would
    # deny ordinary hook maintenance, not catch anything unsafe. The
    # actually dangerous shape is disarming a trap by IGNORING the signal
    # (`trap '' EXIT` / `trap -- '' EXIT`) rather than restoring it —
    # that permanently silences whatever cleanup/fail-closed behavior the
    # trap existed to run, with no exit to follow it.
    (re.compile(r"\btrap\s+(--\s+)?''\s+EXIT\b"), "disabling a trap by ignoring EXIT"),
    (re.compile(r"gate_kill_switch_active[^\n]*\|\|\s*(:|true)\b"),
     "short-circuiting a gate's kill-switch check"),
]


def hook_edit_content():
    if tool == "Write":
        content = tool_input.get("content")
        return content if isinstance(content, str) else None
    if tool == "Edit":
        content = tool_input.get("new_string")
        return content if isinstance(content, str) else None
    if tool == "MultiEdit":
        edits = tool_input.get("edits")
        if not isinstance(edits, list):
            return None
        parts = []
        for e in edits:
            if not isinstance(e, dict):
                return None
            new_string = e.get("new_string")
            if not isinstance(new_string, str):
                return None
            parts.append(new_string)
        return "\n".join(parts)
    return None


if HOOK_SCRIPT_RE.search(relative):
    content = hook_edit_content()
    if content is not None:
        unsafe_reason = None
        for pattern, why in UNSAFE_HOOK_CONTENT:
            if pattern.search(content):
                unsafe_reason = why
                break
        if unsafe_reason is None:
            print(json.dumps({"hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "allow",
                "permissionDecisionReason":
                    "warrant: `%s` is outside the write set frozen by %s, but content-inspected as a "
                    "hook-script edit — no denylist pattern matched, so it is allowed directly instead "
                    "of forcing a scratchpad + mv workaround." % (relative, proposal_path),
            }}))
            sys.exit(0)
        print(
            "warrant: refused — `%s` is a hook-script edit outside the write set frozen by %s, and its "
            "proposed content matched a denylist pattern (%s). Hook edits are content-inspected, not "
            "blanket-denied, but unsafe content still refuses." % (relative, proposal_path, unsafe_reason),
            file=sys.stderr)
        sys.exit(2)

print(
    "warrant: refused — `%s` is outside the write set frozen by %s.\n"
    "Approved paths: %s\n"
    "Finish what the proposal covers and report the rest; the discovered work becomes the next "
    "proposal. Widening the set mid-build is what the gate exists to prevent."
    % (relative, proposal_path, ", ".join(write_set) or "(none listed)"),
    file=sys.stderr,
)
sys.exit(2)
PY

exit $?
