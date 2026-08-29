# Sourceable Python helper for the gate-house standard (issue-72). Loaded
# via importlib by a gate's own Python payload (never imported by dotted
# module name — the filename carries a hyphen on purpose, matching the
# existing core/hooks/*.sh heredoc-Python convention rather than becoming
# a normal package):
#
#   import importlib.util, os
#   _spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
#   gate_lib = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(gate_lib)
#   gate_lib.gate_parse_json_or_deny(raw, deny)
#
# Reference only, never copy (docs/handbooks/canon-scripts.md).

import json
import os
import posixpath
import re


def gate_parse_json_or_deny(raw, deny):
    """Parse `raw` as a JSON object, or call deny(msg) (expected to exit).

    Codifies the malformed-JSON-deny convention already uniform across
    core's own gates (issue-72 survey section 5): a `json.loads` failure,
    non-object top level, or empty payload all deny rather than proceed on
    a best-effort guess.
    """
    if not raw:
        deny("empty tool-use payload; cannot evaluate the gate on nothing")
    try:
        event = json.loads(raw)
    except ValueError:
        deny("the tool-call payload is not valid JSON; refusing rather than "
             "guessing what was about to be written")
    if not isinstance(event, dict):
        deny("the tool-call payload is not a JSON object; failing closed")
    return event


def gate_normalize_path(root, path):
    """Resolve `path` (absolute, relative, or `./`-prefixed) against `root`
    to a root-relative, forward-slash tail, or None if it resolves outside
    root.

    Generalizes the most defensive of the three normalize techniques
    issue-72's survey (section 3) found scattered across core's gates
    (realpath-then-strip-root, record-fields-gate.sh's `resolve()`): both a
    relative `docs/issue-72/x.md` and an absolute
    `/home/u/repo/docs/issue-72/x.md` normalize to the same tail
    `issue-72/x.md`, and `./`-prefixed inputs collapse the same way via
    posixpath.normpath. This does NOT touch the real filesystem (no
    os.path.realpath / symlink resolution) — callers needing symlink-safe
    resolution against a real project root should still realpath their
    own `root` before calling this; this function's contract is pure
    string/path-algebra so it is usable in a test harness with no
    filesystem fixture at all.
    """
    r = posixpath.normpath(root.replace("\\", "/"))
    n = path.replace("\\", "/")
    a = n if posixpath.isabs(n) else posixpath.join(r, n)
    a = posixpath.normpath(a)
    if a == r:
        return ""
    prefix = r + "/"
    if a.startswith(prefix):
        return a[len(prefix):]
    return None


def _apply_replace(text, old, new, replace_all):
    """One Edit's old_string -> new_string, honoring replace_all.

    The issue-72-confirmed bug (survey section 6): record-fields-gate.sh
    always did `text.replace(old, new, 1)` — first occurrence only,
    `replace_all` never read. The tool's own documented behavior is
    `text.replace(old, new)` (every occurrence) when replace_all is true,
    first-occurrence-only otherwise. Returns (new_text, ok); ok is False
    when old_string does not occur in text (mirrors the failure the
    original code detected via `o in current`/`o not in text`).
    """
    if old not in text:
        return text, False
    if replace_all:
        return text.replace(old, new), True
    return text.replace(old, new, 1), True


def gate_reconstruct_write(tool, tool_input, current_content):
    """Reconstruct the resulting content of a Write/Edit/MultiEdit/
    NotebookEdit tool call.

    Returns (new_text, ok). ok is False when the tool_input's shape makes
    the result undeterminable (e.g. an Edit whose old_string is not present
    in current_content, or an unsupported tool) — callers should deny
    rather than silently pass such a write through, the same fail-closed
    posture record-fields-gate.sh already takes today.

    Covers, per issue-72's four-tool requirement:
      Write        -> tool_input["content"] verbatim.
      Edit         -> one old_string/new_string replace, honoring
                       tool_input.get("replace_all", False).
      MultiEdit    -> tool_input["edits"], applied in order, each edit's
                       own replace_all honored independently.
      NotebookEdit -> not reconstructed as a single text blob (a notebook
                       is a sequence of cells, not one string); returns the
                       edited cell's new source as new_text when
                       edit_mode is "insert" or "replace" (the two modes
                       that carry a resulting cell source), so a caller
                       checking cell-level content (e.g. a field check on
                       a record kept as a single markdown cell) has
                       something to check instead of silently exit-0
                       passthrough (issue-72 survey section 6: no gate in
                       this repo reconstructs NotebookEdit at all today).
    """
    if tool == "Write":
        c = tool_input.get("content")
        if isinstance(c, str):
            return c, True
        return None, False

    if tool == "Edit":
        o, n = tool_input.get("old_string"), tool_input.get("new_string")
        if not isinstance(o, str) or not isinstance(n, str) or current_content is None:
            return None, False
        replace_all = bool(tool_input.get("replace_all", False))
        text, ok = _apply_replace(current_content, o, n, replace_all)
        return (text, True) if ok else (None, False)

    if tool == "MultiEdit":
        edits = tool_input.get("edits")
        if not isinstance(edits, list) or current_content is None:
            return None, False
        text = current_content
        for e in edits:
            if not isinstance(e, dict):
                return None, False
            o, n = e.get("old_string"), e.get("new_string")
            if not isinstance(o, str) or not isinstance(n, str):
                return None, False
            replace_all = bool(e.get("replace_all", False))
            text, ok = _apply_replace(text, o, n, replace_all)
            if not ok:
                return None, False
        return text, True

    if tool == "NotebookEdit":
        new_source = tool_input.get("new_source")
        edit_mode = tool_input.get("edit_mode", "replace")
        if edit_mode in ("insert", "replace") and isinstance(new_source, str):
            return new_source, True
        return None, False

    return None, False


_BASH_WRITE_TARGET_RE = re.compile(r"[A-Za-z0-9_./~$-]+")


def gate_bash_write_targets(command):
    """Extract path-shaped tokens from a Bash tool_input.command string.

    Python mirror of gate-lib.sh's gate_bash_write_targets (issue-75): same
    permissive token-scan technique (not real shell parsing — approval-
    gate.sh/board-gate.sh's approach per gate-lib.sh's own doc comment),
    same character class as the sh version's `grep -oE
    '[[:alnum:]_./~$-]+'`. The sh version prints one token per line to
    stdout; this returns the equivalent list of tokens, the natural
    per-language shape for the same data. Caller applies its own path
    pattern to each token.
    """
    return _BASH_WRITE_TARGET_RE.findall(command)


GATE_QUOTE_SPAN = re.compile(r"(?<!\\)'[^']*'|(?<!\\)\"(?:[^\"\\]|\\.)*\"")


def gate_dequote(text):
    """Blank every quoted span in `text` to a single space.

    Same "substitute with a space" idiom board-gate.sh's own
    DEVNULL_REDIR.sub(" ", cmdline) already uses. A pattern matched
    against the result never fires on an occurrence sitting only inside a
    quoted argument (e.g. a grep search pattern); a real occurrence
    outside any quote is untouched.
    """
    return GATE_QUOTE_SPAN.sub(" ", text)


def gate_outside_quotes(text, pattern):
    """True when `pattern` matches somewhere in `text` outside any quoted span."""
    return re.search(pattern, gate_dequote(text)) is not None


# issue-233 independent verification (PR #358 CHANGES review): a plain
# `segment.split()` splits at every whitespace character, including one a
# backslash-escapes or one sitting inside a quoted span -- both ordinary,
# widely-used shell idioms for a path containing a space (bash's own
# tab-completion inserts the backslash form). `_resolve_transparent` used
# to call `.split()` directly, fragmenting `/opt/My\ Python/python3` into
# `/opt/My\` and `Python/python3`: the resolved "head" was neither the
# real interpreter name nor a token EXPANDED_HEAD_RE could wave through
# consistently -- it happened to still deny (the stray backslash is
# itself an unsafe character) for this exact shape, but happened to ALLOW
# a quoted path (`"/opt/My Python/python3" -c ...` resolves to head
# "My" -- a fully safe-looking fragment with no interpreter-shaped
# content at all), a live, undetected bypass this same review round
# found. Same fix mirrors the backslash-newline splice this issue already
# added to `_split_segments`: make word-formation legible to the
# tokenizer BEFORE any check ever inspects a "head", rather than trying
# to special-case each fragment artifact after the fact.
#
# before-landing warrant-hunt (background, blind to this fix's rationale):
# the first version of this tokenizer had no notion of `$'...'` ANSI-C
# quoting (or its `$"..."` locale-translated sibling) -- both start with a
# literal `$`, which the generic `\S` alternative consumed as an ordinary
# bare character BEFORE the quote-span alternatives ever got a look at the
# following `'`, so `$'-c'` tokenized as the two-character fusion `$` +
# `-c` = `$-c`, never the plain word `-c` real bash evaluates it to. Live
# reproduction: `python3 $'-c' "..."` runs as an ordinary `-c` invocation,
# but `gate_trailing_words()` never contains the literal string `"-c"`,
# so `INLINE_FLAG_WORDS` membership never fires -- a full, confirmed
# bypass (a `qa`-role call denied nothing while writing outside `qa`'s own
# write-set). Matched here BEFORE the bare single-quote alternative (same
# ordering the bare-`$` case needed): the `$` is consumed as PART of the
# quote-opening token, not left for `\S` to claim first.
_WORD_TOKEN_RE = re.compile(
    r"(?<!\\)\$'(?:[^'\\]|\\.)*'"
    r"|(?<!\\)\$\"(?:[^\"\\]|\\.)*\""
    r"|(?<!\\)'[^']*'"
    r"|(?<!\\)\"(?:[^\"\\]|\\.)*\""
    r"|\\+\n"
    r"|\\."
    r"|\S"
)


def _shell_split(segment):
    """Split `segment` into words the way a shell forms them.

    Same permissive, non-shell-parser posture as the rest of this module
    (not full quote/escape semantics for every edge case -- see
    GATE_QUOTE_SPAN's own docstring) but aware of the mechanisms that let
    one argument contain whitespace without becoming a separate word: a
    backslash immediately before any character escapes it (the backslash
    is dropped, the character -- including a literal space -- is kept), a
    single/double-quoted span -- including its `$'...'`/`$"..."` ANSI-C
    and locale-translated variants, whose leading `$` is part of the
    quote-opening syntax, not a separate literal character -- is one word
    regardless of the whitespace inside it (the quote-opening syntax is
    dropped, the content is kept), and a backslash-newline line
    continuation splices with ZERO residual
    (unlike an ordinary escape, neither character survives -- same N//2
    odd/even backslash-run counting `_split_segments`/scope-gate.py's
    `_splice_line_continuations` already use, since `_split_segments` may
    hand this function a segment where the continuation was kept intact
    rather than pre-spliced). `(?<!\\)` on both quote alternatives mirrors
    GATE_QUOTE_SPAN: a backslash-escaped literal quote CHARACTER does not
    open a quoted span (issue-88's warrant-hunt finding, the same gap
    class this module's SEGMENT regex already guards against).

    A plain `.split()` cannot express any of this, so an escaped-space
    path, its quoted equivalent, and a backslash-newline-spliced head all
    used to fragment into something that was never the actual first word
    the shell would run.
    """
    words = []
    current = []
    last_end = 0
    for m in _WORD_TOKEN_RE.finditer(segment):
        start, end = m.span()
        if start > last_end and current:
            words.append("".join(current))
            current = []
        token = m.group()
        if token[:1] == "$" and token[1:2] in ("'", '"'):
            current.append(token[2:-1])
        elif token[:1] in ("'", '"'):
            current.append(token[1:-1])
        elif token[-1:] == "\n":
            backslashes = token[:-1]
            current.append("\\" * (len(backslashes) // 2))
            if len(backslashes) % 2 == 0:
                # a genuine, unescaped newline: ends the current word.
                if current:
                    words.append("".join(current))
                    current = []
        elif token[:1] == "\\":
            current.append(token[1:])
        else:
            current.append(token)
        last_end = end
    if current:
        words.append("".join(current))
    return words


TRANSPARENT = ("xargs", "env", "time", "nice", "command", "builtin",
               "timeout", "nohup")
# `timeout` (unlike the rest of TRANSPARENT) always takes one bare
# positional DURATION argument of its own before the wrapped command --
# `timeout 30 cmd`, no flag -- so resolving through it needs one extra
# word skipped beyond its own flags to reach the command it actually runs.
TRANSPARENT_TAKES_ARG = ("timeout",)

# The subset of TRANSPARENT members with a documented own value-taking
# flag in common shell usage (gate_wrapper_head_before's own docstring
# below names these four shapes). A wrapper's own flag value must be
# consumed before the generic bare-flag/skip_extra walk below gets a
# chance at it, or the value token is misread as the wrapped command's
# own bare positional (or worse, as the head itself).
TRANSPARENT_FLAG_TAKES_ARG = {
    "nice": ("-n", "--adjustment"),
    "env": ("-u", "--unset"),
    "timeout": ("-s", "--signal"),
    "xargs": ("-I",),
}


def _resolve_transparent(segment):
    """Walk `segment`'s words through TRANSPARENT.

    Returns (head, trailing_words): the first word that is not itself a
    pass-through wrapper, and the words (unfiltered, in original order)
    that follow it in `segment` -- e.g. for "env bash -c ", head is
    "bash" and trailing_words is ["-c"]. Flags/VAR=value words belonging
    to a TRANSPARENT wrapper are skipped one hop at a time (stopping at
    the first surviving word) rather than filtered from the whole
    remainder in one pass, so a flag that belongs to the REAL command
    (e.g. bash's own `-c` in `timeout 30 bash -c "..."`) is preserved in
    trailing_words instead of being swept away as if it were the
    wrapper's own flag.
    """
    words = _shell_split(segment)
    while words:
        w = words[0].rsplit("/", 1)[-1]
        if w not in TRANSPARENT:
            return w, words[1:]
        skip_extra = w in TRANSPARENT_TAKES_ARG
        i = 1
        while i < len(words):
            tok = words[i]
            if tok in TRANSPARENT_FLAG_TAKES_ARG.get(w, ()):
                i += 2
                continue
            if tok.startswith("-") or "=" in tok.split("/")[0]:
                i += 1
                continue
            if skip_extra:
                skip_extra = False
                i += 1
                continue
            break
        words = words[i:]
    return "", []


def gate_head_of(segment):
    """The command a pipeline stage will actually run, or "" if unknowable.

    Relocated from board-gate.sh's own `_head_of` (issue-98), so both
    board-gate.sh and gh-guard.sh resolve pass-through wrappers through
    the same primitive instead of growing a second, independent copy.
    """
    return _resolve_transparent(segment)[0]


def gate_trailing_words(segment):
    """The words in `segment` after its resolved head, in original order.

    issue-107: board-gate.sh's `_cd_target` needs a `cd` segment's own
    argument, which a wrapper prefix (`timeout 30 cd docs/issue-49`)
    shifts to a different word index than a bare `cd`. Exposing
    `_resolve_transparent`'s own trailing_words here lets `_cd_target`
    extract the argument through the same command-start model
    `gate_head_of` already uses to decide the segment IS a `cd`, instead
    of re-splitting the raw segment and guessing the argument sits at a
    fixed offset.
    """
    return _resolve_transparent(segment)[1]


WRAPPER_HEADS = ("bash", "sh", "dash", "ksh", "zsh", "eval",
                 "python", "python3", "python2", "perl")

_SEPARATOR_RE = re.compile(r"\|\||&&|[|;\n]")
_WRAPPER_C_FLAG_RE = re.compile(r"^-[A-Za-z]*c[A-Za-z]*$")
# perl's own code-argument flag is `-e`, not `-c` (`-c` means "check syntax,
# don't run" for perl) -- every other WRAPPER_HEADS member uses `-c`.
_PERL_E_FLAG_RE = re.compile(r"^-[A-Za-z]*e[A-Za-z]*$")


def gate_wrapper_head_before(cmdline, span_start):
    """Is the quoted span starting at `span_start` a shell/interpreter
    wrapper's code argument -- about to be EXECUTED, not inert data?

    Walks backward from `span_start` to the previous top-level separator
    (`;`, `|`, `&&`, `||`, newline, or start-of-string -- all outside any
    quoted span; found by blanking quoted spans in the text before
    `span_start` to a same-length run of spaces first, so positions stay
    aligned with `cmdline`), then scans the words of that local text
    DIRECTLY for the rightmost (closest-to-the-quote) WRAPPER_HEADS word
    -- deliberately not via gate_head_of's TRANSPARENT hop-by-hop walk,
    which assumes every `-`-prefixed token is a self-contained flag: a
    wrapper reached through a TRANSPARENT prefix whose OWN flag takes a
    separate value token (`nice -n 10 bash -c "..."`, `env -u FOO bash -c
    "..."`, `timeout -s KILL 30 bash -c "..."`, `xargs -I fmt bash -c
    "..."`) would otherwise misresolve the head to that value token
    instead of the real wrapper -- a fail-OPEN outcome here (unlike
    board-gate.sh's fail-closed-on-unrecognized-head default), so this
    scan intentionally does not depend on correctly walking past every
    wrapper's own flag grammar. Returns that head only when its quoted
    argument is unambiguously code: `eval` always executes with no flag
    needed; `perl` needs `-e`-shaped (its actual code flag; `-c` means
    "check syntax, don't run" for perl); every other wrapper head needs a
    `-c`-shaped flag (exactly `-c`, or a combined short-flag token
    containing `c`, e.g. `-lc`/`-ic`) between the head and the quote.
    Returns "" otherwise -- including a bare `bash "script.sh"` with no
    `-c`, which reads a script FILE rather than executing the quoted text
    as code, and a WRAPPER_HEADS word appearing only as a `find -exec`-
    style unrelated argument with no code-flag following it.
    """
    masked = GATE_QUOTE_SPAN.sub(lambda m: " " * len(m.group()),
                                  cmdline[:span_start])
    sep_end = 0
    for m in _SEPARATOR_RE.finditer(masked):
        sep_end = m.end()
    words = cmdline[sep_end:span_start].split()
    head, head_idx = "", -1
    for i, w in enumerate(words):
        base = w.rsplit("/", 1)[-1]
        if base in WRAPPER_HEADS:
            head, head_idx = base, i
    if not head:
        return ""
    if head == "eval":
        return head
    tail = words[head_idx + 1:]
    flag_re = _PERL_E_FLAG_RE if head == "perl" else _WRAPPER_C_FLAG_RE
    if any(flag_re.match(t) for t in tail):
        return head
    return ""
