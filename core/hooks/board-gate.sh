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
#   R3  A write under docs/issue-<n>/ requires CLAUDE_SKILL in the
#       environment. Role sessions get it from on-the-record; the orchestrator's
#       own interactive session carries no rulebook gates and has no
#       business writing the board.
#
#   R4  Branch. A role session writes an issue tree only from that issue's
#       own role branch: writing docs/issue-<n>/... requires the current
#       git branch to be exactly issue-<n>/<CLAUDE_SKILL>. Writing the board
#       from main (or any other branch) is refused — every role output
#       reaches main only through a PR the human merges (contract v3 s10).
#
#   R5  Ownership. Within docs/issue-<n>/reports/, a role writes only its
#       own record (<role>.md), its own subtree (<role>/**), and the
#       per-role extra subtree the contract grants (feasibility: spikes/**,
#       ops: postmortems/**). Foreign-record writes are refused (s11).
#
# Jurisdiction limit (issue-233 round 5): this is a write-set discipline
# check, not a security sandbox. It reads the command TEXT before the
# shell runs it and denies only when that text does not tell it which
# file(s) the call will write, so it cannot enforce R1/R4/R5 against it —
# never because the command is inherently dangerous. A command built to
# deliberately hide its own write target from this pre-expansion text
# read (bash's expansion grammar can rewrite a word into anything) is
# out of this gate's jurisdiction; closing that class needs a different
# seam — the shell's own post-expansion argv — not a longer denylist of
# spellings here. The threat model this gate holds is a cooperative
# session drifting out of its lane, not an adversary routing around it.
# The same limit holds on the head side. An interpreter head that
# bash's own expansion grammar assembles -- brace expansion, ANSI-C
# quoting, a hex-escaped word, or variable indirection -- is equally
# out of this gate's jurisdiction.
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
[ -n "$payload" ] || { echo "board-gate.sh: refused — empty tool-use payload on stdin; cannot evaluate the board gate." >&2; exit 2; }

# Fast path, in shell, before python3 is ever started: this gate runs on
# every tool call and python3 startup costs ~50ms. `docs` is the
# discriminator rather than `docs/` because the python below normalizes
# `docs/../docs/issue-3/...` and this must not be narrower than what it
# would then catch. A payload that mentions the word and turns out to be
# unrelated simply falls through and the python allows it — this is an
# optimization, never a verdict.
#
# This matches the RAW, unparsed JSON text -- a payload that JSON-escapes
# one letter of "docs" as \uXXXX (e.g. "docs") decodes to a
# byte-identical path but never contains the literal substring this fast
# path scans for, so it must never be trusted to skip adjudication on its
# own (issue-303, same defect family as F15/F17 -- verified live here
# despite the #301 record's "docs has no escapable /" reasoning, which
# only ruled out escaping the slash, not the letters). Any payload
# carrying a JSON \u escape therefore falls through to the python judge
# unconditionally.
#
# issue-361: a Bash write TARGET can be built entirely at interpreter
# runtime (`python3 -c "...chr()..."`, no literal "docs" in the command
# text at all -- not even escaped). The scan above proves nothing about
# it either way. So this is a second, independent raw-text scan for the
# shape that makes such a write unanalyzable in the first place: an
# interpreter head (INTERPRETER_HEADS below) paired with an inline
# -c/-e flag, a write-unsafe head (WRITE_UNSAFE_HEADS), a heredoc, or
# an $IFS/${IFS fusion.
#
# This scan is a proxy, not a soundness guarantee: it catches the
# shape only when the head and flag are spelled literally in the
# command text. A head assembled through bash's expansion grammar
# defeats it the same way runtime assembly defeats the path scan
# above. A variable holding a printf-octal-decoded interpreter name is
# one confirmed shape (issue-361 PR #377). Nothing in this gate
# catches an expansion-built head. Closing that class is out of this
# gate's jurisdiction, per the limit stated above (issue-233 round 5,
# PR #367).
#
# This is a scan for the literally-spelled subset of THAT closed set
# (the same one the python judge below already treats as unanalyzable,
# issue-225). It is not a widening of the `docs` path-name scan above,
# which stays exactly "docs". A false positive here -- some unrelated
# command that happens to mention both an interpreter name and a bare
# -c/-e word -- only costs one extra python3 call. It never costs a
# missed analysis.
UNANALYZABLE_HEAD_RE='(^|[^a-zA-Z0-9_])(python3|python2|python|bash|sh|zsh|perl|ruby|node|nodejs)([^a-zA-Z0-9_]|$)'
UNANALYZABLE_FLAG_RE='(^|[^a-zA-Z0-9_-])(-c|-e)([^a-zA-Z0-9_-]|$)'
UNANALYZABLE_WRITE_HEAD_RE='(^|[^a-zA-Z0-9_])(dd|awk|gawk|nawk|mawk|ed|ex|tee)([^a-zA-Z0-9_]|$)'

unanalyzable_shape=0
if [[ "$payload" == *'<<'* || "$payload" == *'$IFS'* || "$payload" == *'${IFS'* ]]; then
  unanalyzable_shape=1
elif [[ "$payload" =~ $UNANALYZABLE_WRITE_HEAD_RE ]]; then
  unanalyzable_shape=1
elif [[ "$payload" =~ $UNANALYZABLE_HEAD_RE && "$payload" =~ $UNANALYZABLE_FLAG_RE ]]; then
  unanalyzable_shape=1
fi

case "$payload" in
  *'\u'*) ;;
  *docs*) ;;
  *) [ "$unanalyzable_shape" = 1 ] || { trap - EXIT; exit 0; } ;;
esac

command -v python3 >/dev/null 2>&1 || gate_deny "board-gate" "python3 not found; cannot evaluate gate"

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
# issue-2241 stage 3 (survey finding 2): "feasibility"/"ops" are not, and
# have never been, entries in spawn.py's ROLES tuple -- an orphaned
# mapping. board.py's own equivalent check (board.py's foreign-write
# trace) already uses the correct current role names; this brings
# board-gate.sh's copy in line with it.
EXTRA_SUBTREE = {"technical-feasibility": "spikes", "release-engineering": "postmortems"}

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
# issue-227 re-review B2: awk/gawk also write via their own `system(...)`
# call -- a shell escape run from inside the program text, independent of
# both `-i` and a literal `>` redirect. Without this, `awk 'BEGIN{system
# ("touch pwn.md")}'` had no INPLACE match and no FILE_REDIR match, so
# _segment_is_failing called it read-only and the call never even reached
# _is_unanalyzable_write_shape's unconditional WRITE_UNSAFE_HEADS check --
# that check only fires for segments already flagged failing.
SYSTEM_CALL_RE = re.compile(r"\bsystem\s*\(")
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

# git's own global flags that take a separate, space-joined value token
# (per `git`'s synopsis): `-C <path>` and `-c <name>=<value>`. The
# `=`-joined long flags (--git-dir=, --work-tree=, --namespace=,
# --config-env=) need no entry here -- an `=`-joined flag never
# introduces an extra positional token for the loop below to misread.
GIT_GLOBAL_VALUE_FLAGS = ("-C", "-c")

# issue-335: `for`/`select` open a WORD LIST and `case` a dispatch
# variable -- none of the three ever runs a program in its own header
# text (a docs/-shaped item merely being enumerated, or switched on, is
# not the same as that item being written). Before this, any segment
# whose head was not read_only/git/read_unless_inplace fell through to
# _segment_is_failing's own catch-all `return True`, and a *failing*
# segment has every docs/-shaped substring in its raw text harvested as
# an unproven write candidate (own_hits) a few lines below -- so
# `for f in ... docs/issue-100/reports/coding.md ...; do <all-reads>;
# done` was refused as a write to docs/issue-100/ even though the path
# never appears anywhere but this word list and every actual command run
# (find/echo/git log inside the loop body) is independently
# read-only-classified on its own segment, unaffected by this. This is
# not a command-name allow-list (the "must not" this issue names): these
# three are shell reserved words, not programs a write could impersonate,
# and a subshell or file redirect embedded in the same header text is
# still caught by the SUBSHELL/FILE_REDIR check above this one runs
# unconditionally -- a header like `for f in $(rm -rf docs/x); do` or
# `case $x in` followed inline by a `>` still fails as before.
# `do`/`then`/`else`/`elif` are deliberately excluded: bash lets the real
# command follow one of those directly in the same segment with only a
# space (`do rm -rf docs/x`), so treating THOSE heads as safe would blind
# the scan to the command actually running.
NONEXECUTING_LIST_HEADS = ("for", "select", "case")


def _git_subcommand(segment):
    """The git subcommand a segment invokes, or "" if unresolved.

    "" is deliberately not in GIT_READ_SUBCOMMANDS, so a bare `git` falls
    through to the normal write scan -- the safe direction, not a new hole.

    First non-flag word after the resolved head, same skip-leading-flags
    idiom `_cd_target` uses for the analogous `cd`-argument case, plus a
    skip of one extra word whenever that word is one of git's own
    value-taking global flags (GIT_GLOBAL_VALUE_FLAGS) -- e.g. `-C /tmp`
    -- so its value token isn't mistaken for the subcommand. Reads
    gate_lib.gate_trailing_words (issue-107) instead of re-splitting
    `segment` itself, so a wrapper prefix (`timeout 30 git log`) doesn't
    shift which word this scan lands on -- the same resolver
    gate_head_of already used to decide this segment IS a `git` (issue-114,
    closing the sibling gap issue-107 left in gate_lib.gate_trailing_words's
    other caller).
    """
    words = gate_lib.gate_trailing_words(segment)
    i = 0
    while i < len(words):
        w = words[i]
        if w in GIT_GLOBAL_VALUE_FLAGS:
            i += 2
            continue
        if not w.startswith("-"):
            return w
        i += 1
    return ""


# --- issue-280: safe quoted-heredoc body shapes are analyzable ----------
# The single most common denial this gate produced (top-denier tally,
# on-the-record#2138) was `gh pr create --body "$(cat <<'EOF' ... EOF)"`:
# the SUBSHELL/heredoc marks made the segment unprovable and, with no
# visible docs/ hit of its own, _is_unanalyzable_write_shape refused it --
# yet the shape IS statically analyzable. The command word and every flag
# sit outside the heredoc and outside any substitution; the substitution
# is exactly `"$(cat <<'TAG' ... TAG)"` -- a QUOTED heredoc tag, so the
# body undergoes no expansion and is pure inert data -- and it feeds a
# body/message argument of one of four known metadata commands (gh pr
# create / gh pr comment / gh issue comment / git commit) that write no
# repository file through that argument. Everything else stays refused:
# an UNQUOTED tag (the body would expand), eval, a substitution in
# command position, any second substitution/heredoc/redirect left after
# the safe one is excised.
#
# The regex runs on the masked probe (heredoc bodies already blanked by
# _mask_heredocs), so the body lines it crosses are whitespace.
SAFE_BODY_FLAGS_RE = r"(?:--body-file|--body|--message|--file|-b|-F|-m)"
SAFE_HEREDOC_SUBST_RE = re.compile(
    SAFE_BODY_FLAGS_RE
    + r"(?:[ \t]+|=)\"\$\(\s*cat[ \t]+<<-?[ \t]*(['\"])(\w+)\1[ \t]*\n"
    + r"(?:[^\n]*\n)*?[ \t]*\2[ \t]*\n\s*\)\"")
SAFE_BODY_HEADS = {
    "gh": (("pr", "create"), ("pr", "comment"), ("issue", "comment")),
    "git": (("commit",),),
}


def _safe_heredoc_body_segment(stripped):
    """True when this segment is exactly the analyzed-safe shape above.

    Excise the quoted-heredoc body substitution(s), then require that what
    remains is a bare, substitution-free invocation of one of the four
    known commands: no further `$(`/backtick, no heredoc operator, no
    outside-quotes file redirect, no `$IFS` token fusion, and the literal
    command word (with its subcommand words) in command position.
    """
    remainder, n = SAFE_HEREDOC_SUBST_RE.subn(" SAFE_QUOTED_BODY", stripped)
    if not n:
        return False
    if SUBSHELL.search(remainder) or "<<" in remainder:
        return False
    if gate_lib.gate_outside_quotes(remainder, FILE_REDIR.pattern):
        return False
    if IFS_TOKEN_RE.search(remainder):
        return False
    words = remainder.split()
    if not words:
        return False
    forms = SAFE_BODY_HEADS.get(words[0])
    if not forms:
        return False
    tail = tuple(words[1:])
    return any(tail[:len(f)] == f for f in forms)


def _segment_is_failing(seg, stripped):
    """True when this segment could not be proven read-only.

    The per-segment classification _write_candidate_segments applies
    (SUBSHELL/FILE_REDIR, git subcommand, READ_ONLY_HEADS,
    READ_UNLESS_INPLACE's own write mechanisms), extracted to its own
    function (issue-99) so the in-order `cd`-tracking walk in the Bash
    candidate builder can reuse the exact same per-segment verdict instead
    of growing a second, independent copy.
    """
    if SUBSHELL.search(seg) or gate_lib.gate_outside_quotes(seg, FILE_REDIR.pattern):
        # issue-280: the one statically-analyzed safe shape -- a quoted
        # heredoc feeding a body flag of a known metadata command -- is
        # provably not a file write; everything else stays failing.
        if _safe_heredoc_body_segment(stripped):
            return False
        return True
    head = gate_lib.gate_head_of(stripped)
    if head in NONEXECUTING_LIST_HEADS:
        return False
    if head == "git":
        return _git_subcommand(stripped) not in GIT_READ_SUBCOMMANDS
    if head in READ_ONLY_HEADS:
        return False
    if head in READ_UNLESS_INPLACE:
        writes = INPLACE.search(stripped) is not None
        # sed/awk read by default; both also have a write mechanism
        # that doesn't involve -i, checked RAW (not gate_outside_quotes)
        # -- the wrapped program argument is not inert data here, same
        # reasoning issue-98/Finding-1 turns on for `bash -c` (issue-98).
        if not writes and head in ("awk", "gawk"):
            writes = (FILE_REDIR.search(stripped) is not None
                       or SYSTEM_CALL_RE.search(stripped) is not None)
        if not writes and head == "sed":
            writes = SED_WRITE_CMD.search(stripped) is not None
        return writes
    return True


HEREDOC_OP = re.compile(r"<<(-)?\s*(['\"]?)(\w+)\2")


def _mask_heredocs(cmdline):
    """Blank out heredoc body lines so their content is never scanned as a
    write-target or split into pseudo-command segments of its own.

    A heredoc body is literal data delivered on stdin between the
    `<<DELIM` operator and a line consisting solely of DELIM (optionally
    indented when the operator is `<<-`) -- it is not a command. Without
    this, `_split_segments`'s newline cut treated each body line as its
    own segment with no recognizable head, so a line that only MENTIONS a
    docs/ path (`cat <<'EOF'\nsee docs/issue-3/x.md\nEOF`) was misread as
    an unproven write candidate and the whole call denied (issue-198),
    even though the resolved write target -- what the shell actually
    opens for writing -- is on the `<<` line itself (a real
    `cat <<EOF > docs/issue-3/x.md` keeps its `> docs/issue-3/x.md`
    target intact; only the interior body is masked).
    """
    spans = []
    for m in HEREDOC_OP.finditer(cmdline):
        dash, _quote, delim = m.groups()
        body_start = cmdline.find("\n", m.end())
        if body_start < 0:
            continue
        body_start += 1
        pattern = (r"^[ \t]*%s[ \t]*$" if dash else r"^%s[ \t]*$") % re.escape(delim)
        tm = re.compile(pattern, re.MULTILINE).search(cmdline, body_start)
        body_end = tm.start() if tm else len(cmdline)
        if body_end > body_start:
            spans.append((body_start, body_end))
    if not spans:
        return cmdline
    chars = list(cmdline)
    for start, end in spans:
        for i in range(start, end):
            if chars[i] != "\n":
                chars[i] = " "
    return "".join(chars)


def _write_candidate_segments(cmdline):
    """Segments of this command line that could not be proven read-only.

    Thin filter over _segment_is_failing (issue-99 refactor; no behavior
    change) — issue-90: a docs-path token sitting inside a different,
    already-provably-read-only segment must not become a write candidate
    just because some other segment on the same line couldn't be
    classified.
    """
    probe = DEVNULL_REDIR.sub(" ", _mask_heredocs(cmdline))
    segments = _split_segments(probe)
    failing = []
    for seg in segments:
        stripped = seg.strip()
        if not stripped:
            continue
        if _segment_is_failing(seg, stripped):
            failing.append(seg)
    return failing


def _reads_only(cmdline):
    """True when no stage of this command line can write a file."""
    return not _write_candidate_segments(cmdline)


def _cd_target(stripped):
    """The argument a `cd` segment would receive, or "" if there isn't one
    (bare `cd`, or only flag-shaped words before the segment ends).

    First non-flag word after `cd` — same skip-leading-flags idiom
    _git_subcommand already uses for the analogous git-subcommand case.
    Reads gate_lib.gate_trailing_words (issue-107) instead of re-splitting
    `stripped` itself, so a wrapper prefix (`timeout 30 cd docs/issue-49`)
    doesn't shift which word this scan lands on -- the same resolver
    gate_head_of already used to decide this segment IS a `cd`.
    """
    for w in gate_lib.gate_trailing_words(stripped):
        if not w.startswith("-"):
            return w
    return ""


def _write_target_windows(seg, stripped):
    """The substrings of a failing segment worth scanning for a docs/
    write target, or None when the whole segment must still be scanned.

    issue-187: `own_hits` used to regex-scan a failing segment's full raw
    text, so a `docs/issue-N`-shaped string sitting in an ECHOED comment
    (`echo "see docs/issue-3/x.md for context" > /tmp/notes.txt`) was
    misread as a write candidate even though the real redirect target is
    `/tmp/notes.txt`. Narrowed to the actual write-target window: the text
    right after a real (outside-quotes) redirection operator, or (for a
    `tee` head) its trailing non-flag arguments. Left at None (whole
    segment) for every other failing reason — git write subcommands,
    subshells, in-place edits, and READ_UNLESS_INPLACE's own raw
    quote-blind redirect scan (awk/sed treat their quoted program as live
    code, not inert text, and `gap-awk-comparison-over-block`'s accepted
    over-block already depends on the full-segment scan there) — where
    the matched argument IS the real target, not commentary.
    """
    head = gate_lib.gate_head_of(stripped)
    if head == "tee":
        return [w for w in gate_lib.gate_trailing_words(stripped) if not w.startswith("-")]
    if head in READ_UNLESS_INPLACE:
        return None
    if not gate_lib.gate_outside_quotes(seg, FILE_REDIR.pattern):
        return None
    # gate_dequote collapses each quoted span to a single space rather than
    # preserving its length, so match offsets in `dequoted` do not line up
    # with `seg` — the tail is sliced from `dequoted` itself, not `seg`.
    windows = []
    dequoted = gate_lib.gate_dequote(seg)
    for m in FILE_REDIR.finditer(dequoted):
        tail = dequoted[m.end():].split(None, 1)
        if tail:
            windows.append(tail[0])
    return windows


def norm(p):
    return posixpath.normpath(p.replace("\\", "/"))


URL_SCHEME = re.compile(r"^[A-Za-z][A-Za-z0-9+.-]*://")


def _docs_relative_tail(token):
    """The part of `token` after its first `docs/` component, once
    normalized — "" when `token` carries no `docs/` token of its own.

    The same normalize-then-find logic the hit-extraction loop already
    performed inline, exposed here (issue-99) so the `cd`-tracking walk in
    the Bash candidate builder can reuse it to decide whether a `cd`
    target itself lands under `docs/`, not only to extract final hits.

    issue-149: a token naming an external URL (a scheme prefix, or `://`
    appearing before the first `docs/` hit) carries no repository docs-tail
    of its own — its path component is not a repository path, so it is
    treated the same as a token with no `docs/` substring at all.
    """
    idx = token.find(DOCS)
    scheme_idx = token.find("://")
    if URL_SCHEME.match(token) or (scheme_idx >= 0 and (idx < 0 or scheme_idx < idx)):
        return ""
    n = norm(token)
    idx = n.find(DOCS)
    if idx >= 0:
        return n[idx + len(DOCS):]
    return ""

candidates = []
# issue-225: failing (unproven-read-only) Bash segments whose write target
# this gate could not read from the visible command text -- collected
# alongside `candidates`, never in place of them (see the check below).
unanalyzable = []

INTERPRETER_HEADS = ("python3", "python", "python2", "bash", "sh", "zsh",
                      "perl", "ruby", "node", "nodejs")
# issue-233 round 5/6: -c and -e are not interchangeable across this list,
# and treating both as "runs inline code" for every head denied ordinary,
# analyzable invocations for no R1/R4/R5 benefit. Round 5 derived this
# live against the real gate subprocess but trusted `-c`'s documented
# meaning for perl/ruby/node instead of executing it; round 6 re-derived
# every entry by running a script that writes a file if the flag executes
# anything, because round 5's perl entry turned out wrong on execution:
# - `bash -e script.sh`/`sh -e script.sh`: bash/sh/zsh's `-e` is the
#   unrelated errexit option, not an inline-code flag, and `bash
#   script.sh` (no `-e`) was already allowed — confirmed by execution
#   that a script writes identically with and without `-e` (errexit only
#   changes whether an earlier failing command aborts it first).
# - `ruby -c script.rb`/`node -c script.js`: confirmed by execution (a
#   `BEGIN`-block / top-level write staged in the script did NOT run
#   under `-c` for either) that `-c` means "check syntax, do not run".
# - `perl -c script.pl`: round 5 gave this back on the same assumption
#   applied to ruby/node, without executing it. Round 6 did: perl's `-c`
#   still runs `BEGIN`, `UNITCHECK`, and `CHECK` blocks before the syntax
#   check completes, so `BEGIN { open(...) }` writes its file under
#   `perl -c` exactly as it would unflagged. perl is dropped from this
#   table's give-back entirely — `-c` rejoins `-e` as denied.
# - `python3 -e ...`: confirmed by execution — python has no `-e` flag;
#   it exits on "Unknown option: -e" before running anything.
# Each interpreter keeps only the flag spelling IT actually uses to mean
# "execute this string as code": `-c` for python/python2/python3/bash/
# sh/zsh, `-e` for ruby/node/nodejs, and both `-c` and `-e` for perl (the
# one head where neither spelling is a safe give-back). This narrows
# false denials without loosening perl; it adds no new spelling to catch
# (the flag-word matching itself, and the substitution/expansion bypass
# class round 1-4 tracked, are both explicitly out of scope).
INLINE_FLAG_HEADS = {
    "python3": ("-c",), "python": ("-c",), "python2": ("-c",),
    "bash": ("-c",), "sh": ("-c",), "zsh": ("-c",),
    "perl": ("-e", "-c"), "ruby": ("-e",),
    "node": ("-e",), "nodejs": ("-e",),
}
# issue-233: an expansion-produced head (EXPANDED_HEAD_RE below) can never be
# looked up in INLINE_FLAG_HEADS -- the token is literal `$`/backtick text,
# not a real interpreter name -- so which flag actually means "run this
# string as code" is unknown until expansion time. The blanket union of
# every flag any head in the table gives inline-execution meaning to is the
# conservative fallback for that unresolvable case; it must never be
# consulted for a head that IS in INLINE_FLAG_HEADS (that lookup already
# gives the exact, narrower answer per-interpreter and must not regress to
# this wider set, e.g. bash's -e give-back).
INLINE_FLAG_WORDS = frozenset(
    flag for flags in INLINE_FLAG_HEADS.values() for flag in flags)
# issue-227: `${IFS}`/`$IFS` used in place of a literal space fuses what
# would otherwise be separate tokens (`python3${IFS}-c${IFS}"..."` reads,
# to whitespace-splitting code, as ONE word) -- gate_head_of's
# `.split()` and gate_trailing_words see no interpreter head and no `-c`
# flag at all, so the INTERPRETER_HEADS branch above never fires. No
# legitimate gated write needs `$IFS` in its command text, so its mere
# presence is itself treated as an unanalyzable write shape rather than
# attempting to normalize the fused token apart (issue #227 direction).
# Anchored so `$IFSHOME`/`${IFS_DIR}` -- distinct variable names that merely
# start with the four letters IFS -- are plain reads, not hits (issue-227
# review finding 1: the unanchored `\$\{?IFS\}?` denied both).
IFS_TOKEN_RE = re.compile(r"\$IFS(?![A-Za-z0-9_])|\$\{IFS(?=[:}])")
# issue-227 review finding 2: `awk`/`gawk`/`nawk`/`mawk` write a file
# straight from program text (`BEGIN{print "x" > "f"}`, `system(...)`) and
# `ed`/`ex` write via script commands (`w file`) -- neither takes a `-c`/`-e`
# flag the interpreter branch below would catch, so they were absent from
# the write-capable set entirely.
# issue-233: `eval STRING` runs STRING as freshly-typed shell text this
# gate never parses -- no `-c`/`-e` flag involved at all (that's `eval`'s
# whole job, unconditionally, the same reason gate_lib.gate_wrapper_head_before
# already treats `eval` as always-code with no flag check, unlike every
# other WRAPPER_HEADS member). Unconditional, same bucket as ed/ex (a
# script/command text this gate cannot parse out of the invocation at
# all) rather than awk/gawk's conditional lookahead (which exists only
# because awk/gawk have a dominant, legitimate plain-read use this gate
# must not break -- eval has no equivalent legitimate gated-write use).
WRITE_UNSAFE_HEADS = ("dd", "awk", "gawk", "nawk", "mawk", "ed", "ex", "eval")
# issue-227 review finding 2: fusion glues an interpreter name straight onto
# a command-substitution/backtick token (`python3$(printf " ")-c '...'`), so
# gate_head_of never resolves a bare interpreter word and the flag check
# below never fires.
FUSED_INTERP_RE = re.compile(
    r"\b(?:python3?|bash|sh|zsh|perl|ruby|node|nodejs)\b\S*(?:\$\(|`)")
# issue-227 review finding 2: `P=python3; $P -c '...'` indirects the
# interpreter head through a variable -- caught only when the same variable
# is assigned an interpreter name earlier in the same command text. issue-227
# re-review B1: the brace form (`${P}`) also indirects and was missed --
# `\$\1\b` never matches `${P}` (the `{` breaks the literal-`$`-then-name
# match), so `${P} -c '...'` sailed through denied only by luck of no other
# clause catching it.
VAR_INTERP_RE = re.compile(
    r"\b(\w+)=(?:python3?|bash|sh|zsh)\b[^\n]*"
    r"(?:\$\{\1\}|\$\1\b)[^\n]*-c\b"
    r"|\b(\w+)=(?:perl|ruby|node|nodejs)\b[^\n]*"
    r"(?:\$\{\2\}|\$\2\b)[^\n]*-e\b")
# issue-233: a third adversarial review round found the interpreter-head
# masking class still leaking through spellings FUSED_INTERP_RE/
# VAR_INTERP_RE do not name -- parameter-default expansion
# (`${x:-python3}`, `${x:=bash}`) and a command substitution that
# PRODUCES the head outright (`$(echo python3)`). Naming those two
# spellings the same way (a fifth, sixth regex alternative enumerating
# more ways to spell "produce an interpreter name") is the closed-set
# trap this program has already spent a month escaping elsewhere
# (issue-2600/issue-2670/issue-349 retired the same shape for a
# different axis) -- every new review round finds one more spelling an
# enumeration didn't name. This keys off STRUCTURE instead: a segment
# whose head token itself begins with `$` or a backtick is never a
# literal program name this gate can read -- what actually runs is
# decided at expansion time, regardless of which interpreter (or
# non-interpreter) the expansion happens to produce. No enumeration
# needed: it does not matter whether the hidden head is python3, bash,
# or some name this gate has never heard of.
#
# `search`, not `match`, and no `^` anchor: a fresh adversarial hunt round
# found a QUOTED expansion head (`"$SHELL" -c ...`, `` "`cmd`" -c ... ``)
# slips past an anchored start-of-token check -- the literal quote
# character sits before the `$`/backtick, so `^[`$]` never fires even
# though the shell still resolves this to an expansion-produced program.
# Searching for `$`/backtick ANYWHERE in the resolved head token is safe
# here specifically because `head` is never argument text (unlike a
# whole-command regex scan) -- it is exactly the one token
# gate_head_of/_resolve_transparent decided is this segment's head, so a
# `$`/backtick anywhere inside it is always suspect, never a false hit
# borrowed from some later, unrelated argument.
EXPANDED_HEAD_RE = re.compile(r"[`$]")
# The same hunt round found a SECOND spelling: an expansion FUSED into an
# otherwise-literal name (`python3${X}-c` where `X` holds a space --
# generalizing issue-227's `$IFS` fix to ANY variable holding whitespace,
# not one enumerated name) puts the `-c`/`-e` flag INSIDE the same fused
# head token, not as a separate word `gate_trailing_words` would ever
# see -- so EXPANDED_HEAD_RE.search(head) correctly flags the head as
# expansion-tainted, but the INLINE_FLAG_WORDS check right below it never
# fires because there is no separate "-c" word to find. Checked directly
# against the raw, unsplit segment text instead: a run of non-space
# characters starting the segment, containing `$`/a backtick, ending in a
# fused `-c`/`-e`-shaped flag -- anchored to the START of the segment (not
# `re.search` over the whole thing), so this can only ever match the head
# token itself, never a later argument.
EXPANDED_HEAD_FUSED_FLAG_RE = re.compile(r"^\S*[`$]\S*-[A-Za-z]*[ce]\b")


def _is_unanalyzable_write_shape(stripped, head, full_cmd=None):
    """True when `stripped` is a write-capable command whose actual write
    target(s) cannot be read from the command text itself: an inline
    heredoc body, a shell/interpreter '-c'/'-e' string, a `dd`
    invocation, a `tee` invocation with no visible target of its own
    (piped in indirectly, e.g. via `xargs`), or a command carrying an
    `$IFS`/`${IFS}` token-fusion space substitute. Called only when the
    ordinary token scan already found no docs/-shaped hit of its own
    (own_hits empty) -- a heredoc/-c/dd/tee whose visible text DOES name a
    docs/ path is still caught by that scan and never reaches here.

    This is the gap on-the-record PR #1627 hit live: `python3 - <<EOF`
    masked its body via `_mask_heredocs` before the segment scan ever ran,
    so the write it performed inside contributed zero candidates and the
    whole call fell through `if not hits: allow()` as if it were a plain
    read.
    """
    if "<<" in stripped:
        return True
    if head in INLINE_FLAG_HEADS:
        if any(w in INLINE_FLAG_HEADS[head] for w in gate_lib.gate_trailing_words(stripped)):
            return True
    elif EXPANDED_HEAD_RE.search(head):
        if any(w in INLINE_FLAG_WORDS for w in gate_lib.gate_trailing_words(stripped)):
            return True
    if EXPANDED_HEAD_FUSED_FLAG_RE.match(stripped):
        return True
    if head in WRITE_UNSAFE_HEADS:
        return True
    if FUSED_INTERP_RE.search(stripped):
        return True
    # `P=python3; $P -c ...` splits into separate `;`-delimited segments
    # (the assignment and the indirected call are never in the same
    # `stripped` segment), so this one checks the whole raw command text
    # instead of the current segment.
    if full_cmd is not None and VAR_INTERP_RE.search(full_cmd):
        return True
    # issue-227: `echo docs/issue-3/reports/x.md | xargs tee` resolves
    # (via gate_head_of's TRANSPARENT walk through xargs) to head=="tee"
    # with no trailing word of its own -- its real write target arrives
    # on stdin, invisible in the command text. A `tee` with a visible
    # non-flag trailing word (docs/-shaped or not, e.g. `tee /tmp/x`) is
    # analyzable -- own_hits already caught a docs/-shaped one via
    # `_write_target_windows`'s head=="tee" branch, and a non-docs/ one is
    # a genuine non-board write, not a masked target -- so this only
    # fires when tee names NO target of its own to inspect.
    if head == "tee" and not [w for w in gate_lib.gate_trailing_words(stripped)
                               if not w.startswith("-")]:
        return True
    if IFS_TOKEN_RE.search(stripped):
        return True
    return False


if tool in ("Write", "Edit", "MultiEdit", "NotebookEdit"):
    p = ti.get("file_path") or ti.get("notebook_path")
    if isinstance(p, str) and p:
        candidates.append(p)
elif tool == "Bash":
    cmdline = ti.get("command")
    if not isinstance(cmdline, str):
        deny("Bash payload carries no command string")
    # issue-361: this used to be gated on `if DOCS in cmdline:`, mirroring
    # the shell fast path's own literal-substring bet -- and losing the
    # same bet for the same reason. A write target built at interpreter
    # runtime (`python3 -c "...chr()..."`, no literal "docs" anywhere in
    # cmdline) made this whole block a no-op: `candidates`/`unanalyzable`
    # stayed empty, so `if not hits: allow()` far below waved the call
    # through with issue-225's own unanalyzable-write-shape deny never
    # even consulted. Always classifying the command here costs pure-Python
    # string/regex work, not a subprocess -- the python3 startup cost this
    # gate is trying to avoid was already paid to reach this line.
    probe = DEVNULL_REDIR.sub(" ", _mask_heredocs(cmdline))
    classified = []
    for seg in _split_segments(probe):
        stripped = seg.strip()
        if not stripped:
            continue
        classified.append((seg, stripped, _segment_is_failing(seg, stripped)))
    if not any(failing for _, _, failing in classified):
        allow()          # a plain read of the board is not a write (s4)
    # In-order walk (issue-99), replacing the old whole-block rescan:
    # a preceding read-only `cd` into a docs/ path is tracked as
    # cd_tail — sticky, never cleared by a later non-docs/ `cd` (a
    # deliberate, named over-blocking trade-off; a full relative-path
    # resolver that un-tracks on leaving docs/ was scouted and
    # rejected — see the proposal's Rationale). Every docs-path-shaped
    # token a segment that could not be proven read-only carries of
    # its own becomes a candidate, same as before (issue-90, scoped to
    # failing segments only); a failing segment with NO token of its
    # own now reconstructs DOCS + cd_tail instead of the dead
    # candidates.append(DOCS) fallback, but only when cd_tail is
    # actually set — a failing segment with no docs/ token of its own
    # and no preceding docs/-landing cd contributes nothing, which is
    # exactly issue-90's own preserved negative space (a docs/ mention
    # living only in an already-read-only segment elsewhere on the
    # line must not manufacture a candidate here).
    cd_tail = ""
    for seg, stripped, failing in classified:
        if not failing:
            if gate_lib.gate_head_of(stripped) == "cd":
                target = _cd_target(stripped)
                if target:
                    tail = _docs_relative_tail(target)
                    if tail:
                        cd_tail = tail
            continue
        windows = _write_target_windows(seg, stripped)
        scan_targets = [seg] if windows is None else windows
        own_hits = []
        for target in scan_targets:
            # issue-336: the trailing class used to be [\w./-]*, which
            # excludes `+` -- and since #2572 made `--skills` the sole
            # spawn form, a multi-skill session's own role/slug
            # (skill_branch_slug() in the on-the-record plugin joins
            # skill names with `+`) always contains one. A path tail
            # that stops at the first `+` truncates the session's own
            # record path to a PREFIX, which then fails the exact
            # `tail[0] == skill` owner comparison below even though the
            # write is the session's own. `+` is added here, not
            # special-cased around: it is simply one more character a
            # `--skills`-composed slug can legitimately produce
            # alongside the word chars, dots, slashes and hyphens
            # already accepted -- the class still only ever matches a
            # SUPERSET of what it matched before (every previously
            # accepted tail stays accepted; `+`-bearing tails are no
            # longer cut short).
            own_hits.extend(re.findall(r"[\w./~$:-]*%s[\w.+/-]*" % re.escape(DOCS), target))
        if own_hits:
            candidates.extend(own_hits)
        elif cd_tail:
            candidates.append(DOCS + cd_tail)
        if not own_hits:
            head = gate_lib.gate_head_of(stripped)
            if _is_unanalyzable_write_shape(stripped, head, cmdline):
                unanalyzable.append(stripped)
else:
    allow()

# Not every repository with a docs/ directory follows this contract, and a
# candidate is not necessarily a real repository path at all -- a Bash
# segment can carry an absolute path that merely CONTAINS a docs/-shaped
# component while pointing entirely outside this repo (e.g. a /tmp/...
# fixture path). root_of() is resolved here, before hits are built, so an
# absolute candidate can be checked against it below rather than judged on
# substring text alone (issue-651).
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

hits = []
for c in candidates:
    tail = _docs_relative_tail(c)
    if not tail:
        continue
    if c.startswith("/"):
        # An absolute candidate can be resolved and root-checked exactly,
        # unlike a relative Bash token (no reliable cwd model -- see the
        # proposal's Rationale). If root itself can't be resolved, refuse
        # rather than silently allow what might be a real board write.
        if root is None:
            deny("cannot resolve the project root to check an absolute "
                 "write-target path against it; refusing rather than "
                 "guessing whether %s is inside this board" % c)
        normalized = os.path.realpath(norm(c))
        if normalized != root and not normalized.startswith(root + os.sep):
            continue      # resolves outside the repo: not a board write
    hits.append(tail)

skill = os.environ.get("CLAUDE_SKILL", "").strip()
is_board = bool(root) and os.path.isfile(
    os.path.join(root, "docs", "specs", "approvers.md"))

# issue-225: an unanalyzable write-capable segment must not silently
# contribute zero candidates and let `if not hits: allow()` below wave the
# whole call through as if it were a plain read -- deny it here instead,
# fail-closed, but ONLY where a write-set is actually being enforced (a
# role session against a board repo). No role, or no board marker, and
# this command is unaffected -- same posture R3 already takes.
if unanalyzable and skill and is_board:
    deny("a Bash call carries an un-analyzable write-capable shape (%s) "
         "while this gate enforces skill %r's write-set. A heredoc body, "
         "an interpreter -c/-e inline script, or a dd invocation does not "
         "show its real write target in the command text, so this "
         "refuses rather than risk a masked out-of-set write (issue-225 — "
         "the on-the-record PR #1627 bypass). Use a provably read-only "
         "invocation (e.g. python3 -m pytest), or write through "
         "Write/Edit or a plain redirect this gate can read the target of. "
         "This is a write-set discipline check, not a security boundary "
         "(issue-233 round 5): it denies only shapes it cannot read the "
         "write target of. A shape deliberately built to hide that "
         "target from this text-level read is out of this gate's "
         "jurisdiction. The same limit holds on the head side. An "
         "interpreter head that bash's own expansion grammar assembles "
         "-- brace expansion, ANSI-C quoting, a hex-escaped word, or "
         "variable indirection -- is equally out of this gate's "
         "jurisdiction."
         % ("; ".join(unanalyzable), skill))

if not hits:
    allow()                  # nothing under docs/: not this gate's business

# --- board or bystander? -----------------------------------------------
# No contract and no role means no board: stand aside entirely. (A role IS
# set but the contract is missing -> that is a real error and R2 denies
# below.)
if not root:
    deny("cannot resolve the project root for a docs/ write")

if not is_board and not skill:
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
    if not skill:
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
if not skill:
    deny("a write under docs/issue-<n>/ from a session with no CLAUDE_SKILL. "
         "The board belongs to skill sessions; this one carries no rulebook "
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
    deny("cannot resolve the current git branch for a board write; a skill "
         "writes its issue tree only from issue-<n>/<skill>")

# R4 sidecar-preferred identity (issue-1827): prefer the workspace role
# sidecar .on-the-record/role.json (issue-1814) over the branch string
# itself when present. A present-but-disagreeing sidecar is a hard
# fail-closed refuse naming both values; an absent/unreadable/malformed
# sidecar falls through to today's exact-branch-string check, unchanged.
_sidecar_issue = None
_sidecar_skill = None
try:
    with open(os.path.join(root, ".on-the-record", "role.json"),
              encoding="utf-8") as _f:
        _sidecar = json.load(_f)
    if (isinstance(_sidecar, dict) and isinstance(_sidecar.get("skill"), str)
            and isinstance(_sidecar.get("issue"), int)):
        _sidecar_issue = _sidecar["issue"]
        _sidecar_skill = _sidecar["skill"]
    else:
        sys.stderr.write(
            "board-gate: .on-the-record/role.json present but not in "
            "the expected shape (skill: str, issue: int) -- falling back "
            "to branch-name parsing (issue #2741: this key was renamed "
            "role -> skill, forward-only; a sidecar written before that "
            "rename no longer resolves here).\n"
        )
except (OSError, ValueError):
    pass

if _sidecar_issue is not None:
    _cross_bm = re.match(r"^issue-([0-9]+)/([\w-]+)$", branch)
    if _cross_bm:
        _cross_issue = int(_cross_bm.group(1))
        _cross_skill = _cross_bm.group(2)
        if _cross_issue != _sidecar_issue or _cross_skill != _sidecar_skill:
            deny("sidecar skill/issue (issue-%d/%s) disagrees with the "
                 "branch-parsed skill/issue (issue-%d/%s) — workspace "
                 "state is inconsistent. Make .on-the-record/role.json "
                 "and the current branch name agree, or remove the stale "
                 "sidecar. (contract v3 s10)"
                 % (_sidecar_issue, _sidecar_skill, _cross_issue, _cross_skill))

# R4 maintenance-targets exception (issue-222): a role's own issue may
# declare, in its GitHub issue BODY (not writable by the role's own
# tools — gh-guard.sh already denies role sessions `gh issue edit`), a
# literal `maintenance-targets: <tree list>` line naming OTHER
# docs/issue-<n>/ trees it may also write. Read live via `gh issue view`
# on mismatch only, never cached to a repo file (a repo file would be
# exactly the self-expandable surface the exception must not open).
_bm = re.match(r"^issue-([0-9]+)/(.+)$", branch)
_own_issue = _bm.group(1) if _bm and _bm.group(2) == skill else None
_maint_targets = None  # lazily resolved set of "issue-<n>" strings; None = not fetched yet

def _resolve_maintenance_targets():
    if _own_issue is None:
        return set()
    gh = os.environ.get("CORE_GH") or "gh"
    try:
        out = subprocess.run([gh, "issue", "view", _own_issue, "--json", "body"],
                             capture_output=True, text=True, cwd=root)
    except OSError:
        return set()
    if out.returncode != 0:
        return set()
    try:
        body = json.loads(out.stdout).get("body") or ""
    except (ValueError, AttributeError):
        return set()
    m = re.search(r"^maintenance-targets:\s*(.+)$", body, re.MULTILINE)
    if not m:
        return set()
    targets = set()
    for tok in re.split(r"[,\s]+", m.group(1).strip()):
        tm = re.match(r"^(?:docs/)?(issue-[0-9]+)/?$", tok)
        if tm:
            targets.add(tm.group(1))
    return targets

for parts in issue_hits:
    issue_dir = parts[0]
    expected = "%s/%s" % (issue_dir, skill)
    if _sidecar_issue is not None:
        _hit_issue_num = int(issue_dir.split("-", 1)[1])
        if _hit_issue_num == _sidecar_issue and _sidecar_skill == skill:
            continue
    else:
        if branch == expected:
            continue
    if _maint_targets is None:
        _maint_targets = _resolve_maintenance_targets()
    if issue_dir in _maint_targets:
        continue
    deny("writing docs/%s/ requires branch %s (current: %s), and issue "
         "#%s's body declares no matching `maintenance-targets:` entry "
         "for %s. Every skill output reaches main only through a PR the "
         "human merges — never a direct write from another branch. "
         "(contract v3 s10)"
         % (issue_dir, expected, branch, _own_issue or "?", issue_dir))

# --- R5: reports/ ownership ---------------------------------------------
# issue-2241 stage 3: ownership keys off the record's own `author:`
# frontmatter field (stage 1) instead of matching the writing session's
# role against the record's filename -- a lease (who currently holds the
# right to work an issue right now) and authorship (who actually wrote
# the content already sitting in a file) are different questions that
# can legitimately disagree mid-flight: one session's lease expires,
# another acquires it, and the record a foreign-write check must respect
# is still keyed to whoever wrote what is already there. A record with
# no `author:` field (written before stage 1 landed, or not yet created)
# falls back to the original role-filename rule below unchanged -- no
# legacy record becomes suddenly unwritable, and a brand-new record's
# ownership is still decided by whose name it is filed under.
AUTHOR_FIELD_RE = re.compile(r"(?m)^author:[ \t]*(\S+)[ \t]*$")


def _record_text(path):
    """The on-disk text of a record file, or None if it does not exist
    (a brand-new record) or cannot be read as UTF-8 text."""
    try:
        with open(path, encoding="utf-8") as f:
            return f.read()
    except OSError:
        return None
    except UnicodeDecodeError:
        return None


def _record_author(text):
    """The `author:` frontmatter value of a record's on-disk text, or
    None when there is no on-disk text yet or no such field -- both
    read identically by the fallback below (issue-2241 stage 3)."""
    if text is None or not text.startswith("---\n"):
        return None
    end = text.find("\n---", 4)
    frontmatter = text[4:end if end >= 0 else len(text)]
    m = AUTHOR_FIELD_RE.search(frontmatter)
    return m.group(1) if m else None


APPEND_ONLY_UNPROVABLE_HEADS = READ_UNLESS_INPLACE + WRITE_UNSAFE_HEADS


def _bash_append_only(cmdline, tail):
    """True only when every failing segment of `cmdline` that names this
    docs/`tail` write target reaches it through a provable append: a
    `>>` redirect (never a truncating bare `>`), or `tee -a`/`--append`.
    A heredoc `<<TAG` feeding that same segment's own `>>` redirect (the
    shape `cat <<'EOF' >> target`, already trusted elsewhere in this file
    for target extraction) is not itself disqualifying -- the body is
    masked before this scan runs, so only the visible redirect operator
    on the `<<` line decides. Anything else this gate cannot prove
    append-only from the command text alone -- an in-place edit (sed/awk
    -i), awk's own `system()`/`w` write paths, `dd`, or a `tee` with no
    `-a` -- denies, matching this gate's existing fail-closed posture for
    unanalyzable write shapes (issue-225).
    """
    needle = DOCS + tail
    probe = DEVNULL_REDIR.sub(" ", _mask_heredocs(cmdline))
    found = False
    for seg in _split_segments(probe):
        stripped = seg.strip()
        if not stripped:
            continue
        deq = gate_lib.gate_dequote(seg)
        if needle not in deq:
            continue
        found = True
        head = gate_lib.gate_head_of(stripped)
        if head in APPEND_ONLY_UNPROVABLE_HEADS:
            return False
        if head == "tee":
            words = gate_lib.gate_trailing_words(stripped)
            if not any(w in ("-a", "--append") for w in words):
                return False
            continue
        redirs = list(FILE_REDIR.finditer(deq))
        if not redirs or any(m.group() != ">>" for m in redirs):
            return False
    return found


def _write_is_append_only(existing_text, tail):
    """True when this tool call cannot alter any line `existing_text`
    already carries -- the allowance a foreign-authored record keeps
    (contract v3 s11, issue-2241 stage 3): a session may add new content
    to a record it does not own the header of, provided it does not
    touch another author's existing lines. False whenever that can't be
    proven from the tool call alone (fail closed)."""
    if tool == "Bash":
        return _bash_append_only(cmdline, tail)
    new_text, ok = gate_lib.gate_reconstruct_write(tool, ti, existing_text)
    return ok and new_text.startswith(existing_text)


for parts in issue_hits:
    if len(parts) < 3 or parts[1] != "reports":
        continue
    tail = parts[2:]
    owner_file = skill + ".md"
    extra = EXTRA_SUBTREE.get(skill)
    record_path = os.path.join(root, "docs", parts[0], "reports", *tail)
    existing_text = _record_text(record_path)
    author = _record_author(existing_text)
    if author is not None:
        if author == skill:
            continue
        if _write_is_append_only(existing_text, "/".join(parts)):
            continue
        deny("docs/%s/reports/%s is authored by %r, not %r. A session may "
             "append new content to a foreign-authored record but never "
             "alter another author's existing lines. (contract v3 s11, "
             "issue-2241 stage 3)"
             % (parts[0], "/".join(tail), author, skill))
    if tail[0] == owner_file and len(tail) == 1:
        continue
    if tail[0] == skill:
        continue
    if extra and tail[0] == extra:
        continue
    deny("docs/%s/reports/%s belongs to another skill. %s writes only "
         "%s, %s/** %s— never a foreign record. (contract v3 s11)"
         % (parts[0], "/".join(tail), skill, owner_file, skill,
            ("and %s/** " % extra) if extra else ""))

allow()
PY

CORE_PAYLOAD="$payload" python3 -c "$CORE_BOARD_GATE"
rc=$?
trap - EXIT
if [ "$rc" -ne 0 ] && [ "$rc" -ne 2 ]; then
  echo "board-gate.sh: refused — fail-closed: internal error (gate judge exited $rc)" >&2
  exit 2
fi
exit "$rc"
