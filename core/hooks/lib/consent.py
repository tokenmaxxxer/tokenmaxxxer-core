"""Find and consume a human approval token.

A role's gate knows WHICH of its transitions need a human. This module knows
WHETHER a human approved. The gate supplies `tokens_dir` because roles keep
their tokens in different places — qa outside the repository, everyone else on
the board — and location is the role's business.

Everything here fails closed. A token that cannot be read, parsed, or removed
is a refusal, never a pass.
"""
import os
import re

__all__ = ["ConsentError", "KIND_RE", "token_path", "find", "consume"]

# A kind is a transition (`<from>--<to>`) or a field (`field-<name>`). It
# becomes a filename, so it may not contain a separator or start with a dash.
KIND_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9_.-]{0,127}$")

_FIELD_RE = re.compile(r"^(kind|subject|actor|phrase):[ \t]*(.*)$")
_REQUIRED = ("kind", "subject", "actor", "phrase")


class ConsentError(Exception):
    """Raised whenever a gate must refuse. Catch this and refuse; do not
    distinguish causes at the call site — every cause has the same verdict."""


def token_path(tokens_dir, kind):
    if not isinstance(kind, str) or not KIND_RE.fullmatch(kind) or kind in (".", ".."):
        raise ValueError("unsafe token kind: %r" % (kind,))
    if not isinstance(tokens_dir, str) or not tokens_dir:
        raise ValueError("tokens_dir is required")
    return os.path.join(tokens_dir, kind + ".token")


def find(tokens_dir, kind):
    """The token's path if one is present and non-empty, else None.

    Note: After consume is called, the token is removed, so find will return
    None. The path returned by find is not the path consume operates on if
    consume has claimed the token — consume uses a .claimed-* suffix during
    processing to ensure single-use semantics.
    """
    p = token_path(tokens_dir, kind)
    try:
        return p if os.path.getsize(p) > 0 else None
    except OSError:
        return None


def _parse(text):
    got = {}
    for line in text.splitlines():
        m = _FIELD_RE.match(line)
        if m and m.group(1) not in got:
            # First occurrence wins. `phrase` is written last and carries the
            # user's own words, so a multi-line phrase cannot inject a second
            # `kind:` that overrides the real one.
            got[m.group(1)] = m.group(2).strip()
    return got


def consume(tokens_dir, kind):
    """Read the token, remove it, return its fields.

    Removal is the point. A token that survives its use is a standing
    approval: measured 2026-07-27, a repository that only checked for the file
    let the same approving write pass four times in a row, so one human
    decision authorized every later re-scoping of that subject.

    This function uses a read-validate-claim-last pattern: read and fully
    validate the token at its original path first, then claim it (rename it).
    This ensures: (1) validation failures never move the file, so evidence
    preservation is automatic; (2) the claim rename is the single-use guard,
    with nothing to restore on failure.
    """
    p = token_path(tokens_dir, kind)

    try:
        with open(p, encoding="utf-8-sig") as fh:
            text = fh.read(1 << 16)
    except (OSError, UnicodeDecodeError) as e:
        raise ConsentError("no approval token for kind %r (%s)" % (kind, e))

    fields = _parse(text)
    missing = [k for k in _REQUIRED if not fields.get(k)]
    if missing:
        raise ConsentError(
            "approval token for kind %r is missing %s; refusing rather than "
            "guessing what it authorized" % (kind, ", ".join(missing)))
    if fields["kind"] != kind:
        raise ConsentError(
            "approval token in %s declares kind %r but was read as %r"
            % (p, fields["kind"], kind))
    if fields["actor"] != "user":
        raise ConsentError(
            "approval token for kind %r has actor %r; only a human may "
            "authorize this" % (kind, fields["actor"]))

    claimed = p + ".claimed-%d" % os.getpid()
    try:
        os.rename(p, claimed)
    except OSError as e:
        raise ConsentError(
            "no approval token for kind %r could not be claimed (%s); "
            "refusing rather than leaving a replayable token in place"
            % (kind, e))

    try:
        os.remove(claimed)
    except OSError as e:
        raise ConsentError(
            "the approval token for kind %r could not be consumed (%s); "
            "refusing rather than leaving a replayable token in place"
            % (kind, e))
    return fields
