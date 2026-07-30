#!/usr/bin/env bash
# Shared temp-directory helper for this repository's test scripts.
#
# The idiom it replaces looked safe and was not:
#
#     td="$(cd "$(mktemp -d)" && pwd -P)"
#     ...
#     rm -rf "$td"
#
# When `mktemp -d` fails it writes nothing to stdout, so `$(mktemp -d)` is the
# empty string and the command becomes `cd "" && pwd -P`. **`cd ""` returns 0
# and does not move**, so `pwd -P` yields the CURRENT directory and `td` becomes
# the repository root — which the caller then `rm -rf`s, `.git` included.
# `set -uo pipefail` does not help: there is no `-e`, and `-u` sees `td` as set,
# because it is set to the wrong value rather than left unset.
#
# The failure needs an unwritable or missing $TMPDIR, which never happens on a
# developer's machine and can inside the Seatbelt sandbox a role session runs
# in. So it is invisible by hand and fires only in role sessions. It destroyed
# the core issue-16 workspace (see issue #57).
#
# `pwd -P` is kept deliberately: on macOS `mktemp -d` hands back /var/... which
# realpath resolves to /private/var/..., and a gate that normalizes its root
# without realpath but resolves the target with it then compares two different
# strings and allows everything. See deny-only-check.sh's own note.

# mktd — set $td to a fresh temp directory, or abort the script.
#
# Three checks, three different failures: empty output (the `cd ""` path above),
# a path that is not a directory, and a relative path (which would make a later
# `rm -rf "$td"` resolve against the caller's cwd).
#
# Call it plainly — `mktd`, never `$(mktd)`. Inside a command substitution the
# `exit 1` would only leave the subshell and the caller would carry on with a
# stale $td, which is the very shape of bug this file exists to end.
# `-p "${TMPDIR:-/tmp}"` is the first half of the fix, and it is not optional
# on macOS: /usr/bin/mktemp IGNORES $TMPDIR and resolves the base through
# confstr(_CS_DARWIN_USER_TEMP_DIR) to /var/folders/.../T — a path the role
# session's sandbox denies writing to. That is why the failure happens at all
# (measured in the issue-53 session, which lost its working tree to it). `-p`
# sends mktemp somewhere writable; the checks below catch the case where it
# still fails, because a lower probability is not a guarantee.
mktd() {
  td="$(mktemp -d -p "${TMPDIR:-/tmp}")" \
    && [ -n "$td" ] && [ -d "$td" ] && [ "${td#/}" != "$td" ] \
    || { echo "mktemp -d failed: [${td:-}]" >&2; exit 1; }
  td="$(cd "$td" && pwd -P)"
}
