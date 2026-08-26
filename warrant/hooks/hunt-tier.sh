#!/usr/bin/env bash
# Computes the warrant-hunt budget tier for a diff, mechanically, per the
# tier mapping stated in directive.sh (issue-63) plus the gates/hooks
# regression guard (issue-214): a gates/hooks path touched forces the full
# tier regardless of size, so the composition-bypass class this repo has
# already caught twice cannot slip into a cheap tier just because the diff
# that carries it happens to be small.
#
# Usage: hunt-tier.sh <base-ref> [<head-ref>]   (head defaults to HEAD)
# Output (stdout, one line):
#   tier=<none|skip|docs-only|small|full> cap_seconds=<N> max_stances=<0|1|2> reason=<...>
# `max_stances` is a ceiling the tier permits, not a dispatch count this
# script drives — escalating a session's second stance stays gated on the
# first hunt's FIND, a judgment call the session makes, not this script.
#
# issue-284: a diff <=5 lines with every touched path under docs/ (the
# issue's own record files included) maps to tier=skip, cap_seconds=0 — the
# dispatch itself is skipped, not merely shrunk to the cheapest paid tier.
# A proposals/ path is excluded from that skip (falls through to the
# unchanged docs-only tier instead): scope-gate.sh reads a proposal's
# `status:` frontmatter to arm/disarm write-set enforcement, so even a
# 1-line status flip there is a gating-relevant edit, not the kind of
# trivial prose/record change the skip floor is meant for.
# Exit: 0 always — this reports a classification, it does not gate a tool call.
#
# Kill switch: export WARRANT_OFF=1 (reports tier=none, same as no diff)

set -uo pipefail

if [ "${WARRANT_OFF:-}" = "1" ]; then
  echo "tier=none cap_seconds=0 max_stances=0 reason=warrant-off"
  exit 0
fi

base="${1:?usage: hunt-tier.sh <base-ref> [<head-ref>]}"
head="${2:-HEAD}"

diff_stat="$(git diff --numstat "$base" "$head" -- 2>&1)"
diff_rc=$?

if [ "$diff_rc" -ne 0 ]; then
  # F1 (issue-305): a bad/typo'd ref (git exit 128) produced no stdout,
  # same as a genuinely empty diff — distinguish them so a broken base ref
  # surfaces instead of silently cancelling the hunter dispatch.
  echo "$diff_stat" >&2
  echo "tier=none cap_seconds=0 max_stances=0 reason=git-diff-failed(rc=$diff_rc)"
  exit 0
fi

if [ -z "$diff_stat" ]; then
  echo "tier=none cap_seconds=0 max_stances=0 reason=empty-diff"
  exit 0
fi

file_count=0
line_count=0
gates_hooks_hit=0
docs_only=1
proposals_hit=0

while IFS="$(printf '\t')" read -r added deleted path; do
  [ -z "${path:-}" ] && continue
  file_count=$((file_count + 1))
  case "$added" in *[!0-9]*) added=0 ;; esac
  case "$deleted" in *[!0-9]*) deleted=0 ;; esac
  line_count=$((line_count + added + deleted))
  case "$path" in
    docs/*) : ;;
    *) docs_only=0 ;;
  esac
  # Match a path SEGMENT, never a substring — "hookspec/x.sh" or
  # "warrant-hooks/x" must not trip the override; only an actual
  # hooks/ or gates/ directory in the path does. A path under docs/ is
  # never gates/hooks code even if it happens to be a report ABOUT hooks
  # (e.g. docs/issue-1/reports/hooks/notes.md) — the docs-only fast path
  # must still apply there, so the override is scoped to non-docs paths.
  case "$path" in
    docs/*) : ;;
    *) case "/$path" in
         */hooks/*|*/gates/*) gates_hooks_hit=1 ;;
       esac ;;
  esac
  # A proposals/ path is gating-relevant (scope-gate.sh reads its `status:`
  # frontmatter) even when it is small and wholly under docs/ — it must
  # never earn the skip tier just by matching docs_only + line-count.
  case "/$path" in
    */proposals/*) proposals_hit=1 ;;
  esac
done <<EOF2
$diff_stat
EOF2

if [ "$gates_hooks_hit" -eq 1 ]; then
  echo "tier=full cap_seconds=180 max_stances=2 reason=gates-or-hooks-path-touched"
  exit 0
fi

if [ "$docs_only" -eq 1 ] && [ "$line_count" -le 5 ] && [ "$proposals_hit" -eq 0 ]; then
  echo "tier=skip cap_seconds=0 max_stances=0 reason=docs-only-trivial-diff"
  exit 0
fi

if [ "$docs_only" -eq 1 ] || [ "$line_count" -le 20 ]; then
  echo "tier=docs-only cap_seconds=60 max_stances=1 reason=docs-only-or-tiny-diff"
  exit 0
fi

if [ "$line_count" -le 200 ] && [ "$file_count" -le 5 ]; then
  echo "tier=small cap_seconds=120 max_stances=1 reason=small-diff"
  exit 0
fi

echo "tier=full cap_seconds=180 max_stances=2 reason=large-diff"
