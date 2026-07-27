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

    Note: find() checks for <kind>.token only, not .claimed-* files. If
    consume() failed due to malformed content or read errors, the token
    remains at .claimed-<pid>-<random> and will not be reported by find().
    This is correct behavior — a malformed token should not appear as
    available approval to a subsequent caller.
    """
    p = token_path(tokens_dir, kind)
    try:
        # isfile first: getsize() is truthy for a DIRECTORY, so a directory
        # planted at <kind>.token used to read as an available approval.
        return p if os.path.isfile(p) and os.path.getsize(p) > 0 else None
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


def consume(tokens_dir, kind, allowed_actors=("user",), subject=None):
    """Read the token, remove it, return its fields.

    `allowed_actors` defaults to the human alone. A gate opts into
    ("user", "judge") only when the unattended flag is set for its session —
    so a stale judge token can never satisfy an attended gate (cross-mode
    replay stays closed). The four contract §8/§19 human-reserved kinds
    (scope approval, defect adjudication, metric freeze, round-end) never
    include "judge"; that rule lives in the contract, and a gate for one of
    those kinds must not pass "judge" here. An empty allow-list is caller
    misuse: ValueError before the token is touched, keeping the evidence.

    `subject`, when supplied, must equal the token's own subject field. A
    gate that knows which subject it is acting on should always pass it: on
    a case-insensitive filesystem two subjects differing only in case share
    one tokens directory, so an approval for one satisfied a gate for the
    other.

    Removal is the point. A token that survives its use is a standing
    approval: measured 2026-07-27, a repository that only checked for the file
    let the same approving write pass four times in a row, so one human
    decision authorized every later re-scoping of that subject.

    Claim first and keep the claim: the token is renamed to
    .claimed-<pid>-<random> before being read. This ensures (1) TOCTOU
    safety — the rename captures the bytes, so nothing can be swapped under
    us while validating, and (2) no restores — validation failures leave the
    token claimed but unconsumed, which is fail-closed.

    The claimed name includes a random component, not just the pid: the pid
    alone is unique per process, not per attempt, and os.rename silently
    replaces an existing destination on POSIX. Two failed consumes in the
    same process — or two short-lived hook processes that happen to reuse a
    pid — would otherwise collide on the same claimed path, and the second
    failure would destroy the first failure's stranded evidence.

    Known limitation: if os.remove fails after validation succeeds, the token
    is stranded under .claimed-<pid>-<random> and the human must re-approve.
    This is the fail-closed call — we refuse rather than proceeding with a
    partially consumed token.
    """
    if (not isinstance(allowed_actors, (tuple, list)) or not allowed_actors
            or not all(isinstance(a, str) and a for a in allowed_actors)):
        raise ValueError("allowed_actors must name at least one actor: %r"
                         % (allowed_actors,))

    p = token_path(tokens_dir, kind)
    claimed = p + ".claimed-%d-%s" % (os.getpid(), os.urandom(8).hex())

    try:
        os.rename(p, claimed)
    except OSError as e:
        raise ConsentError("no approval token for kind %r (%s)" % (kind, e))

    try:
        with open(claimed, encoding="utf-8-sig") as fh:
            text = fh.read(1 << 16)
    except (OSError, UnicodeDecodeError) as e:
        raise ConsentError(
            "approval token for kind %r at %s is unreadable (%s)"
            % (kind, claimed, e))

    fields = _parse(text)
    missing = [k for k in _REQUIRED if not fields.get(k)]
    if missing:
        raise ConsentError(
            "approval token for kind %r at %s is missing %s; refusing rather than "
            "guessing what it authorized" % (kind, claimed, ", ".join(missing)))
    if fields["kind"] != kind:
        raise ConsentError(
            "approval token at %s declares kind %r but was read as %r"
            % (claimed, fields["kind"], kind))
    if subject is not None and fields["subject"] != subject:
        # Case matters even where the filesystem disagrees. On a
        # case-insensitive filesystem `records/Alpha/tokens/` and
        # `records/alpha/tokens/` are one directory, so a token minted for
        # subject `Alpha` was consumable by a gate acting on `alpha` —
        # authority for one subject satisfying a gate for another. A gate
        # that knows its subject must pass it.
        raise ConsentError(
            "approval token for kind %r at %s names subject %r but this gate "
            "acts on %r" % (kind, claimed, fields["subject"], subject))
    if fields["actor"] not in allowed_actors:
        raise ConsentError(
            "approval token for kind %r at %s has actor %r; this gate accepts "
            "only %s" % (kind, claimed, fields["actor"],
                         ", ".join(allowed_actors)))

    try:
        os.remove(claimed)
    except OSError as e:
        raise ConsentError(
            "the approval token for kind %r could not be consumed (%s); "
            "refusing rather than leaving a replayable token in place"
            % (kind, e))
    return fields
