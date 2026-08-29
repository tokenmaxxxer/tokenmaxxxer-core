#!/usr/bin/env bash
# compliance-check.sh --canon-duplication's content-hash classification
# (issue-175): every manifest entry other than directive.sh now compares
# content against its in-repo canonical source instead of matching by
# filename alone — a role-specific file that happens to share a manifest
# name (pricing-rulebook's own scope-gate.sh) scans clean, while a
# byte-identical vendored copy of the real canon file still flags.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
. "$HERE/_tmp.sh"

pass=0
fail=0
report() { # <want> <got> <name>
  if [ "$2" = "$1" ]; then
    pass=$((pass + 1)); printf 'ok     %-60s %s\n' "$3" "$2"
  else
    fail=$((fail + 1)); printf 'FAIL   %-60s want=%s got=%s\n' "$3" "$1" "$2"
  fi
}

# canon-manifest.txt's scope-gate.sh entry resolves to warrant/hooks/scope-gate.sh
# in this checkout (compliance-check.sh's repo_root is three levels up from
# core/hooks/tests/).
canon_source="$HERE/../../../warrant/hooks/scope-gate.sh"
[ -f "$canon_source" ] || { echo "FIXTURE ERROR: canon source not found at $canon_source" >&2; exit 2; }

# pricing-rulebook's OWN scope-gate.sh (issue-175's reported gap): same
# manifest filename, genuinely different content — a role-specific gate,
# not a vendored core copy.
mktd
skill_specific_td="$td"
mkdir -p "$skill_specific_td/hooks"
cat > "$skill_specific_td/hooks/scope-gate.sh" <<'SKILL_GATE'
#!/usr/bin/env bash
# pricing-rulebook's own scope gate — not core canon's scope-gate.sh.
set -uo pipefail
case "${PRICING_SCOPE_OFF:-}" in
  1|true) exit 0 ;;
esac
echo "pricing scope check"
exit 0
SKILL_GATE
out="$(bash "$HERE/compliance-check.sh" --canon-duplication "$skill_specific_td" 2>&1)"
rc=$?
case "$out" in
  *"FAIL"*"scope-gate.sh"*) got=flagged ;;
  *) got=clean ;;
esac
report clean "$got" "role-specific scope-gate.sh (different content) scans clean"
report 0 "$rc" "role-specific scope-gate.sh: overall exit stays 0"
rm -rf "$skill_specific_td"

# A byte-identical vendored copy of the real canon scope-gate.sh must
# still flag.
mktd
vendored_td="$td"
mkdir -p "$vendored_td/hooks"
cp "$canon_source" "$vendored_td/hooks/scope-gate.sh"
out="$(bash "$HERE/compliance-check.sh" --canon-duplication "$vendored_td" 2>&1)"
rc=$?
case "$out" in
  *"FAIL"*"scope-gate.sh"*) got=flagged ;;
  *) got=clean ;;
esac
report flagged "$got" "byte-identical vendored scope-gate.sh still flags"
report 1 "$rc" "byte-identical vendored scope-gate.sh: overall exit is 1"
rm -rf "$vendored_td"

echo
echo "pass=$pass fail=$fail"
[ "$fail" = 0 ]
