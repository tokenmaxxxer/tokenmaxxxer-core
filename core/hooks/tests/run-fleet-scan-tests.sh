#!/usr/bin/env bash
# Tests for the fleet silent-failure scan driver (issue-168).
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

# (c) synthetic single-repo dry run: fleet-silent-failure-scan.sh round-
# trips a local throwaway repo to a `clean` row (no blocked row, no
# crash) when there's nothing to find.
mktd
clean_repo="$td/clean-rulebook"
mkdir -p "$clean_repo/hooks"
cat > "$clean_repo/hooks/example-gate.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
echo "ok"
EOF
out="$("$HERE/fleet-silent-failure-scan.sh" "$clean_repo" 2>&1)"
rc=$?
report 0 "$rc" "clean synthetic repo exits 0"
report "clean-rulebook | clean" "$out" "clean synthetic repo reports clean"

# synthetic repo carrying a swallowed-error shape must surface a
# FINDING row, never a `blocked` row.
finding_repo="$td/finding-rulebook"
mkdir -p "$finding_repo/hooks"
cat > "$finding_repo/hooks/observe.sh" <<'EOF'
#!/usr/bin/env bash
python3 payload.py 2>/dev/null
exit 0
EOF
out="$("$HERE/fleet-silent-failure-scan.sh" "$finding_repo" 2>&1)"
rc=$?
report 1 "$rc" "finding synthetic repo exits non-zero"
case "$out" in
  "finding-rulebook | FINDING:"*) report "match" "match" "finding synthetic repo reports a FINDING row" ;;
  *) report "match" "no-match" "finding synthetic repo reports a FINDING row" ;;
esac
case "$out" in
  *blocked*) report "no-blocked" "blocked-present" "finding synthetic repo never says blocked" ;;
  *) report "no-blocked" "no-blocked" "finding synthetic repo never says blocked" ;;
esac

# nonexistent path is a hard error (exit 2), not a `blocked` row —
# blocked is never printed for a path that was actually scanned or for
# one that plainly doesn't exist.
out="$("$HERE/fleet-silent-failure-scan.sh" "$td/does-not-exist" 2>&1)"
rc=$?
report 2 "$rc" "nonexistent path exits 2"
case "$out" in
  *blocked*) report "no-blocked" "blocked-present" "nonexistent path never says blocked" ;;
  *) report "no-blocked" "no-blocked" "nonexistent path never says blocked" ;;
esac

# (a)+(b) live fleet run: run-fleet-scan.sh against the real 43-repo
# rulebook fleet — exactly 43 result rows, zero blocked. Network-
# dependent (plain HTTPS clone of public repos); skipped with a clearly
# labeled skip if gh/network isn't available in this environment,
# rather than silently passing.
if command -v gh >/dev/null 2>&1 && gh repo list tokenmaxxxer --limit 1 >/dev/null 2>&1; then
  live_out="$("$HERE/run-fleet-scan.sh" 2>&1)"
  live_rc=$?
  row_count="$(printf '%s\n' "$live_out" | grep -cE '^[A-Za-z0-9._-]+-rulebook \|')"
  report 43 "$row_count" "live fleet run produces 43 repo rows"
  blocked_count="$(printf '%s\n' "$live_out" | grep -i 'blocked' | grep -vc 'blocked=0')"
  report 0 "$blocked_count" "live fleet run has zero blocked rows"
  [ "$live_rc" -eq 0 ] || echo "note: run-fleet-scan.sh exited $live_rc (non-clean rows and/or clone failures present — see rows above)"
else
  echo "SKIP   live 43-repo fleet run (gh/network unavailable in this environment)"
fi

# issue-173: --canon-duplication distinguishes a sanctioned per-repo
# directive.sh stub (docs/handbooks/canon-rollout.md step 3) from a
# genuinely vendored full copy, instead of flagging any file named
# directive.sh on filename alone.
stub_repo="$td/stub-rulebook"
mkdir -p "$stub_repo/hooks"
cat > "$stub_repo/hooks/directive.sh" <<'EOF'
#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/role-directive.sh"
core_role_directive \
  "YOU DECIDE: ..." \
  "USE WHEN: ..." \
  "PRODUCES: ..." \
  "HAND-OFF: ..."
EOF
out="$("$HERE/compliance-check.sh" --canon-duplication "$stub_repo" 2>&1)"
rc=$?
report 0 "$rc" "sanctioned directive.sh stub exits 0 under --canon-duplication"
case "$out" in
  *"vendored copy"*directive.sh*) report "no-vendored-flag" "vendored-flag-present" "sanctioned stub not flagged as vendored copy" ;;
  *) report "no-vendored-flag" "no-vendored-flag" "sanctioned stub not flagged as vendored copy" ;;
esac

vendored_repo="$td/vendored-rulebook"
mkdir -p "$vendored_repo/hooks"
cat > "$vendored_repo/hooks/directive.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
case "${DIRECTIVE_OFF:-}" in
  1|true) exit 0 ;;
esac
echo "full pre-promotion directive body"
EOF
out="$("$HERE/compliance-check.sh" --canon-duplication "$vendored_repo" 2>&1)"
rc=$?
report 1 "$rc" "vendored full directive.sh exits non-zero under --canon-duplication"
case "$out" in
  *"vendored copy"*directive.sh*) report "vendored-flag" "vendored-flag" "vendored full directive.sh flagged as vendored copy" ;;
  *) report "vendored-flag" "no-flag" "vendored full directive.sh flagged as vendored copy" ;;
esac

echo
echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
