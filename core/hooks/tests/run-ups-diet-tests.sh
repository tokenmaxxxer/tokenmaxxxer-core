#!/usr/bin/env bash
# issue-278: per-turn UserPromptSubmit injection diet.
#
# The seven core-family UPS hooks (core proposal-shape / record-shape /
# survey-order, terse, freelunch, scout, warrant) render a byte-stable index
# (invariants + one Read-<file> trigger each) whose combined per-turn payload
# stays within a 3,072-byte budget; the prose bodies live verbatim in each
# plugin's directive/ files. The SessionStart core directive got the same
# split (index + core/directive/session-protocol.md).
#
# Asserted here:
#   1. combined rendered UPS payload <= 3072 bytes
#   2. byte-stability: every hook rendered twice, cmp byte-identical
#   3. every index names exactly one directive/ file; it exists, non-empty
#   4. no apostrophes in any rendered hook output
#   5. SessionStart: rendered twice byte-identical; the short per-session
#      index prefix stays <= 2560 bytes (issue-278 diet, apostrophe-free);
#      session-protocol.md is delivered inline in the same output (no Read
#      pointer, issue-299) and the combined payload stays <= 32768 bytes
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO="$(cd "$HERE/../../.." && pwd -P)"
CORE_ROOT="$REPO/core"

pass=0
fail=0
report() { # <want> <got> <name>
  if [ "$2" = "$1" ]; then
    pass=$((pass + 1)); printf 'ok     %-60s %s\n' "$3" "$2"
  else
    fail=$((fail + 1)); printf 'FAIL   %-60s want=%s got=%s\n' "$3" "$1" "$2"
  fi
}

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

UPS_HOOKS="core/hooks/proposal-shape-directive.sh
core/hooks/record-shape-directive.sh
core/hooks/survey-order-directive.sh
terse/hooks/terse.sh
freelunch/hooks/freelunch.sh
scout/hooks/directive.sh
warrant/hooks/directive.sh"

render() { # <script-rel-path> <outfile>
  CLAUDE_PLUGIN_ROOT_CORE="$CORE_ROOT" CLAUDE_SKILL=implementation \
    /bin/bash "$REPO/$1" </dev/null >"$2" 2>/dev/null
}

total=0
i=0
while IFS= read -r h; do
  i=$((i + 1))
  render "$h" "$tmp/a$i"
  render "$h" "$tmp/b$i"
  if cmp -s "$tmp/a$i" "$tmp/b$i"; then stable=yes; else stable=no; fi
  report yes "$stable" "byte-stable across two renders: $h"

  bytes=$(wc -c < "$tmp/a$i" | tr -d ' ')
  total=$((total + bytes))

  apos=$(grep -c "'" "$tmp/a$i" || true)
  report 0 "$apos" "no apostrophes in rendered output: $h"

  # exactly one directive/ file reference; the file exists and is non-empty
  refs=$(grep -o '/directive/[a-z-]*\.md' "$tmp/a$i" | sort -u)
  refcount=$(printf '%s' "$refs" | grep -c . || true)
  report 1 "$refcount" "exactly one directive file referenced: $h"
  ref_path=$(grep -o '[^ ]*/directive/[a-z-]*\.md' "$tmp/a$i" | head -1)
  if [ -n "$ref_path" ] && [ -s "$ref_path" ]; then ref_ok=yes; else ref_ok=no; fi
  report yes "$ref_ok" "referenced directive file exists non-empty: $h"
done <<EOF2
$UPS_HOOKS
EOF2

echo "combined UPS bytes/turn: $total"
if [ "$total" -le 3072 ]; then budget=within; else budget=over; fi
report within "$budget" "combined UPS payload <= 3072 bytes"

# --- SessionStart core directive (issue-278 step 3) ---
# Render inside a fake repo with a fake authenticated gh so the precondition
# probe passes deterministically (same technique as run-auth-probe-ttl-tests).
fakerepo="$tmp/repo"
mkdir -p "$fakerepo"
git -C "$fakerepo" init -q 2>/dev/null
git -C "$fakerepo" remote add origin https://example.invalid/o/r.git 2>/dev/null
fakebin="$tmp/bin"
mkdir -p "$fakebin"
printf '#!/bin/sh\nexit 0\n' > "$fakebin/gh"
chmod +x "$fakebin/gh"

render_ss() { # <outfile>
  PATH="$fakebin:$PATH" CLAUDE_PROJECT_DIR="$fakerepo" TMPDIR="$tmp" \
    CLAUDE_PLUGIN_ROOT_CORE="$CORE_ROOT" CLAUDE_SKILL=implementation \
    /bin/bash "$CORE_ROOT/hooks/directive.sh" </dev/null >"$1" 2>/dev/null
}
render_ss "$tmp/ss-a"
render_ss "$tmp/ss-b"
if cmp -s "$tmp/ss-a" "$tmp/ss-b"; then ss_stable=yes; else ss_stable=no; fi
report yes "$ss_stable" "SessionStart index byte-stable across two renders"

# issue-299: the SessionStart hook no longer ends with a "Read <file> NOW"
# pointer to session-protocol.md — that shape was measured (on-the-record
# #2204, confirmed live against this repo's own directive.sh) to cost a
# real tool round-trip every session. It now cats the file's content
# directly into its own stdout instead, so the combined SessionStart
# payload legitimately grew past the old 2560-byte index-only budget; the
# byte-diet intent from issue-278 survives only for the short INVARIANTS
# block that precedes the inline delivery marker below, which stays
# per-session (role-flavored, terse). A generous ceiling still guards
# against unbounded growth of the combined output.
MARKER='[core] Full protocol (session-protocol.md), delivered inline, no Read needed:'
ss_index_bytes=$(awk -v m="$MARKER" 'index($0,m){exit} {print}' "$tmp/ss-a" | wc -c | tr -d ' ')
echo "SessionStart short-index bytes (before inline delivery): $ss_index_bytes"
if [ "$ss_index_bytes" -le 2560 ] && [ "$ss_index_bytes" -gt 0 ]; then ss_index_budget=within; else ss_index_budget=over; fi
report within "$ss_index_budget" "SessionStart short-index <= 2560 bytes and non-empty"

ss_bytes=$(wc -c < "$tmp/ss-a" | tr -d ' ')
echo "SessionStart combined (index + inline protocol) bytes: $ss_bytes"
if [ "$ss_bytes" -le 32768 ] && [ "$ss_bytes" -gt 0 ]; then ss_budget=within; else ss_budget=over; fi
report within "$ss_budget" "SessionStart combined output <= 32768 bytes and non-empty"

ss_index_apos=$(awk -v m="$MARKER" 'index($0,m){exit} {print}' "$tmp/ss-a" | grep -c "'" || true)
report 0 "$ss_index_apos" "no apostrophes in SessionStart short-index (pre-marker)"

if grep -qF "Read " "$tmp/ss-a" && grep -q "NOW, before any work" "$tmp/ss-a"; then ss_read_now=present; else ss_read_now=absent; fi
report absent "$ss_read_now" "SessionStart output carries no 'Read ... NOW, before any work' pointer"

if [ -s "$CORE_ROOT/directive/session-protocol.md" ]; then ss_sec=yes; else ss_sec=no; fi
report yes "$ss_sec" "session-protocol.md section file exists non-empty"

if grep -qF "$MARKER" "$tmp/ss-a"; then ss_inline=yes; else ss_inline=no; fi
report yes "$ss_inline" "session-protocol.md content is delivered inline in SessionStart output"

echo
echo "ups-diet: $pass passed, $fail failed"
[ "$fail" = 0 ]
