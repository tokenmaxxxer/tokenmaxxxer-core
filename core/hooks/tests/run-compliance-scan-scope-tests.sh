#!/usr/bin/env bash
# compliance-check.sh's hooks.json-driven scan scope (issue-78): a
# PreToolUse-wired script that does not match the old '*-gate.sh' glob
# (a hunt-guard.sh-shaped fixture: hand-rolled kill-switch case statement,
# no gate-lib.sh call) is still flagged, and a script present on disk but
# not wired into any hooks.json is excluded from the scan.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
. "$HERE/_tmp.sh"

pass=0
fail=0
report() { # <want> <got> <name>
  if [ "$2" = "$1" ]; then
    pass=$((pass + 1)); printf 'ok     %-55s %s\n' "$3" "$2"
  else
    fail=$((fail + 1)); printf 'FAIL   %-55s want=%s got=%s\n' "$3" "$1" "$2"
  fi
}

mktd
mkdir -p "$td/plugin/hooks"

# hunt-guard.sh-shaped: PreToolUse-wired, non-'-gate.sh' name, hand-rolled
# *_OFF case-statement kill switch (the confirmed fail-open shape) instead
# of gate_kill_switch_active.
cat > "$td/plugin/hooks/hunt-guard.sh" <<'GUARD'
#!/usr/bin/env bash
case "${WARRANT_OFF:-}" in
  ""|0|false|no|off) ;;
  *) exit 0 ;;
esac
exit 0
GUARD

# Wired but clean, to prove the scan doesn't just fail everything it finds.
cat > "$td/plugin/hooks/board-gate.sh" <<'GATE'
#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-x}/hooks/lib/gate-lib.sh" || exit 2
gate_kill_switch_active "${CORE_OFF:-}" || exit 0
exit 0
GATE

# Present on disk but NOT wired in hooks.json — must be excluded from the
# scan even though its name matches the historical '*-gate.sh' glob and it
# has the same fail-open shape as hunt-guard.sh above.
cat > "$td/plugin/hooks/unwired-gate.sh" <<'UNWIRED'
#!/usr/bin/env bash
case "${SOME_OFF:-}" in
  ""|0|false|no|off) ;;
  *) exit 0 ;;
esac
exit 0
UNWIRED

cat > "$td/plugin/hooks/hooks.json" <<'JSON'
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/board-gate.sh"
          },
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/hunt-guard.sh"
          }
        ]
      }
    ]
  }
}
JSON

out="$(bash "$HERE/compliance-check.sh" "$td" 2>&1)"
rc=$?

case "$out" in
  *"FAIL"*"hunt-guard.sh"*) got_hunt_guard=flagged ;;
  *) got_hunt_guard=missed ;;
esac
report flagged "$got_hunt_guard" "hunt-guard.sh (PreToolUse-wired, non-gate-named) flagged"

case "$out" in
  *"unwired-gate.sh"*) got_unwired=scanned ;;
  *) got_unwired=excluded ;;
esac
report excluded "$got_unwired" "unwired-gate.sh (on disk, not in hooks.json) excluded"

case "$out" in
  *"ok — "*"board-gate.sh"*) got_clean=ok ;;
  *) got_clean=not-ok ;;
esac
report ok "$got_clean" "board-gate.sh (wired, gate-lib.sh-compliant) passes clean"

case "$rc" in 1) got_rc=fail ;; 0) got_rc=pass ;; *) got_rc="rc-$rc" ;; esac
report fail "$got_rc" "overall exit reflects the flagged fixture"

rm -rf "$td"

echo
echo "--- compliance-check output ---"
printf '%s\n' "$out"
echo "--- end output ---"
echo
echo "pass=$pass fail=$fail"
[ "$fail" = 0 ]
