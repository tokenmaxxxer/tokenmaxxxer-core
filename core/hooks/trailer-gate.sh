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
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)}/hooks/lib/gate-lib.sh" || { echo "trailer-gate.sh: cannot source gate-lib.sh" >&2; exit 2; }
set -uo pipefail

self_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/$(basename "${BASH_SOURCE[0]}")"
role="${CLAUDE_ROLE:-}"
deny() { echo "${role:-trailer-gate}: refused — $1 (gate: $self_path)" >&2; exit 0; }  # issue-282 DEMOTE: advisory, not blocking

gate_kill_switch_active "${TRAILER_GATE_OFF:-}" || exit 0

command -v python3 >/dev/null 2>&1 || deny "trailer-gate: python3 is required to evaluate the gate and is not on PATH."

payload="$(cat 2>/dev/null)"
[ -n "$payload" ] || deny "trailer-gate: empty tool-use payload on stdin; cannot evaluate the trailer gate."

TRAILER_GATE_PAYLOAD="$payload" \
TRAILER_GATE_SKILL="$role" \
TRAILER_GATE_CPD="${CLAUDE_PROJECT_DIR:-}" \
TRAILER_GATE_CWD="$(pwd -P 2>/dev/null || echo)" \
TRAILER_GATE_SELF="$self_path" \
python3 <<'PY'
import json, os, posixpath, re, shlex, subprocess, sys

role = os.environ.get("TRAILER_GATE_SKILL", "").strip() or "trailer-gate"
self_path = os.environ.get("TRAILER_GATE_SELF", "") or "trailer-gate.sh"

def deny(msg):
    # issue-282 DEMOTE: advisory only -- detection logic unchanged.
    reason = "%s: %s (gate: %s)" % (role, msg, self_path)
    sys.stderr.write(reason + "\n")
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "additionalContext": reason,
        },
        "systemMessage": reason,
    }))
    sys.exit(0)

def allow():
    sys.exit(0)

def _fail_closed(_t, _v, _tb):
    try:
        sys.stderr.write("%s: refused — fail-closed: internal error (%s: %s) (gate: %s)\n" % (role, _t.__name__, _v, self_path))
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

# Any quote character dropped at shell-execution time joins its neighbors:
# `git commi""t` and `git c'o'm'm'i't` both run `git commit`, even though
# the raw source text has no contiguous `commit` substring — one strips an
# empty pair, the other strips single-char fragments, but both are just
# quote removal. Detect against a copy with every quote character removed
# (mapped back to original offsets), same resolve-before-match discipline
# as `_extract_resolvable_expr` below — the original `command` (quotes
# intact) still drives everything downstream of the match.
def _strip_quotes_with_map(s):
    chars = []
    offsets = []
    for i, ch in enumerate(s):
        if ch in ("'", '"'):
            continue
        chars.append(ch)
        offsets.append(i)
    return "".join(chars), offsets


_dequoted, _offsets = _strip_quotes_with_map(command)
commit_m = re.search(r'\bgit\b[^\n;&|]*\bcommit\b(?!-)', _dequoted)
if not commit_m:
    allow()
# Map the match end back into `command`'s coordinate space so downstream
# parsing (the `-m` payload resolver etc.) still runs against the real text.
commit_end = _offsets[commit_m.end() - 1] + 1 if commit_m.end() > 0 else 0

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

# --- D1: resolve $(...)/`...`/heredoc `-m` message constructs by effect,
# not by shlex-tokenizing the raw source text (issue-141). shlex has no
# notion of command substitution or heredocs; asking it to tokenize a
# `-m "$(cat <<'EOF' ... EOF)"` construct either (a) false-denies a commit
# whose resolved message DOES carry the trailer, because shlex's naive
# token happens not to contain it, or (b) false-ALLOWS a commit whose
# resolved message does NOT carry the trailer, because unrelated raw
# source text around the heredoc happens to contain the trailer string.
# Both are closed by resolving the expression under a narrow allowlist
# (cat with zero operands, or shape-checked printf/echo — nothing else)
# and judging the RESOLVED string, never the source text.

def _scan_dollar_paren_or_backtick(s, start):
    """s[start] is the '$' of '$(' or a backtick. Returns the index just
    past the matching close, skipping over heredoc bodies (which may
    contain unbalanced parens/quotes that are not shell structure), or
    None if unterminated."""
    if s[start:start + 2] == "$(":
        i = start + 2
        depth = 1
    elif s[start] == "`":
        i = start + 1
        j = i
        while j < len(s):
            if s[j] == "\\" and j + 1 < len(s):
                j += 2
                continue
            if s[j] == "`":
                return j + 1
            j += 1
        return None
    else:
        return None

    while i < len(s):
        heredoc_m = re.match(r"<<-?\s*(['\"]?)(\w+)\1", s[i:])
        if heredoc_m:
            delim = heredoc_m.group(2)
            i += heredoc_m.end()
            nl = s.find("\n", i)
            if nl == -1:
                return None
            i = nl + 1
            while True:
                nl2 = s.find("\n", i)
                line = s[i:nl2] if nl2 != -1 else s[i:]
                if line.strip() == delim:
                    i = (nl2 + 1) if nl2 != -1 else len(s)
                    break
                if nl2 == -1:
                    return None
                i = nl2 + 1
            continue
        ch = s[i]
        if ch == "(":
            depth += 1
            i += 1
        elif ch == ")":
            depth -= 1
            i += 1
            if depth == 0:
                return i
        else:
            i += 1
    return None

def _extract_resolvable_expr(cmd, after_commit_idx):
    """Find the -m/--message flag after the `git commit` match and, if its
    value is a double-quoted string whose entire content is a single
    $(...) or `...` expression, return that expression's source text
    (including the wrapper). Returns None if the value is not shaped this
    way (plain literal, single-quoted, unquoted, malformed) — callers fall
    back to the existing shlex path or an explicit cannot-verify deny."""
    rest = cmd[after_commit_idx:]
    fm = re.search(r"(?:^|\s)(-m|--message)(=)?", rest)
    if not fm:
        return None
    after = rest[fm.end():]
    if fm.group(2) != "=":
        idx = 0
        while idx < len(after) and after[idx] in " \t":
            idx += 1
        after = after[idx:]
    if not after or after[0] != '"':
        return None
    inner_start = 1
    if inner_start >= len(after) or after[inner_start] not in ("$", "`"):
        return None
    if after[inner_start] == "$" and after[inner_start:inner_start + 2] != "$(":
        return None
    end = _scan_dollar_paren_or_backtick(after, inner_start)
    if end is None:
        return None
    if end >= len(after) or after[end] != '"':
        return None
    return after[inner_start:end]

def _check_allowlist(expr):
    """expr is exactly one $(...) or `...` expression. Returns the inner
    command text if it is a bare `cat` with zero operands (heredoc/stdin
    only — never a file operand, closing the arbitrary-file-read hole) or
    a shape-checked `printf`/`echo` call (no `-`-flag args, no `/` in any
    arg, no nested substitution or `;`/`&`/`|`). Returns None otherwise —
    callers must treat that as statically unverifiable, never as empty."""
    if expr.startswith("$(") and expr.endswith(")"):
        inner = expr[2:-1]
    elif expr.startswith("`") and expr.endswith("`"):
        inner = expr[1:-1]
    else:
        return None
    if re.match(r"^\s*cat\s*(<<-?\s*(['\"]?)(\w+)\2\s*\n.*\n\s*\3\s*)$", inner, re.S):
        return inner
    m2 = re.match(r"^\s*(printf|echo)\s+(.*)$", inner, re.S)
    if m2:
        args_text = m2.group(2)
        if re.search(r"[;&|`]|\$\(", args_text):
            return None
        try:
            toks = shlex.split(args_text, posix=True)
        except ValueError:
            return None
        for t in toks:
            if t.startswith("-") or "/" in t:
                return None
        return inner
    return None

def _resolve_abs(names, dirs):
    for d in dirs:
        for n in names:
            p = os.path.join(d, n)
            if os.path.isfile(p) and os.access(p, os.X_OK):
                return p
    return None

_TRUSTED_BIN_DIRS = ("/bin", "/usr/bin")

def _evaluate_allowlisted(inner):
    """Run the allowlisted `cat`/`printf`/`echo` invocation with PATH
    cleared and `cat` resolved to its absolute, non-session-writable
    system path (never looked up by bare name on the session's PATH — a
    session-writable PATH entry could otherwise shadow `cat` with an
    attacker-controlled binary). `printf`/`echo` are bash builtins and
    need no PATH lookup at all. Returns the resolved message text
    (trailing newlines stripped, matching `$()` semantics) or None on any
    resolution failure or timeout — callers must deny, never treat None
    as an empty-but-verified message."""
    bash_abs = _resolve_abs(("bash",), _TRUSTED_BIN_DIRS)
    cat_abs = _resolve_abs(("cat",), _TRUSTED_BIN_DIRS)
    if not bash_abs or not cat_abs:
        return None
    script = re.sub(r"(?<![\w/])cat\b", cat_abs, inner, count=1)
    try:
        r = subprocess.run([bash_abs, "-s"], input=script, capture_output=True,
                            text=True, timeout=2, env={"PATH": ""})
    except Exception:
        return None
    if r.returncode != 0:
        return None
    out = r.stdout
    while out.endswith("\n"):
        out = out[:-1]
    return out

_marker_re = re.compile(r"\$\(|`|<<")
resolved_joined = None
skip_shlex_path = False

_rest_after_commit = command[commit_end:]
_fm_probe = re.search(r"(?:^|\s)(-m|--message)(=)?", _rest_after_commit)
if _fm_probe:
    _after_probe = _rest_after_commit[_fm_probe.end():]
    if _fm_probe.group(2) != "=":
        _idx = 0
        while _idx < len(_after_probe) and _after_probe[_idx] in " \t":
            _idx += 1
        _after_probe = _after_probe[_idx:]
    if _after_probe[:1] == '"':
        expr = _extract_resolvable_expr(command, commit_end)
        if expr is not None:
            skip_shlex_path = True
            inner = _check_allowlist(expr)
            if inner is None:
                deny("this commit stages %s work and its `-m` message is a `$(...)`/backtick construct that is not a plain cat(heredoc)/printf/echo invocation matching the allowlist, so its `Subject: %s` trailer (contract s13) cannot be verified statically." % (issue, issue))
            resolved_joined = _evaluate_allowlisted(inner)
            if resolved_joined is None:
                deny("this commit stages %s work and resolving its `-m` message's `$(...)`/backtick construct timed out or failed, so its `Subject: %s` trailer (contract s13) cannot be verified statically." % (issue, issue))
        elif _marker_re.search(_after_probe[:2000]):
            skip_shlex_path = True
            deny("this commit stages %s work and its `-m` message contains a `$(...)`/backtick/heredoc construct that could not be parsed into a single resolvable expression, so its `Subject: %s` trailer (contract s13) cannot be verified statically." % (issue, issue))

if skip_shlex_path:
    joined = resolved_joined
else:
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
