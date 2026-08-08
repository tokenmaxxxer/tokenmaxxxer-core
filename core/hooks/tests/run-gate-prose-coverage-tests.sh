#!/usr/bin/env bash
# Synthetic-fixture tests for gate-prose-coverage-check.py (issue-146).
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
HOOKS="$(cd "$HERE/.." && pwd -P)"
CHECK="$HERE/gate-prose-coverage-check.py"
. "$HERE/_tmp.sh"
mktd
trap 'rm -rf "$td"' EXIT

pass=0
fail=0
report() { # <want-substring-present:0|1> <got-output> <name>
  local want="$1" got="$2" name="$3"
  if [ "$want" = "1" ]; then
    if printf '%s' "$got" | grep -q "VIOLATION"; then
      pass=$((pass + 1)); printf 'ok     %-45s (violation reported)\n' "$name"
    else
      fail=$((fail + 1)); printf 'FAIL   %-45s want violation, got none\n' "$name"
    fi
  else
    if printf '%s' "$got" | grep -q "VIOLATION"; then
      fail=$((fail + 1)); printf 'FAIL   %-45s want no violation, got one\n' "$name"
    else
      pass=$((pass + 1)); printf 'ok     %-45s (no violation)\n' "$name"
    fi
  fi
}

mkfixture() { # writes a gate + a unit dir under $td/<n>
  local n="$1"
  mkdir -p "$td/$n/hooks"
}

# --- case 1: needle present in directive.sh -> pass ---
mkfixture case1
cat > "$td/case1/hooks/directive.sh" <<'EOF'
#!/usr/bin/env bash
# tell the role: state "what was done" in the record.
EOF
cat > "$td/case1/hooks/my-gate.sh" <<'EOF'
#!/usr/bin/env python3
def has_any(*needles):
    pass
has_any("what was done")
EOF
out="$(python3 "$CHECK" "$td/case1" 2>&1)"
report 0 "$out" "case1: needle in directive.sh"

# --- case 2: needle absent everywhere -> violation ---
mkfixture case2
cat > "$td/case2/hooks/directive.sh" <<'EOF'
#!/usr/bin/env bash
# no mention of the needle below anywhere in this file.
EOF
cat > "$td/case2/hooks/my-gate.sh" <<'EOF'
#!/usr/bin/env python3
def has_any(*needles):
    pass
has_any("totally-undiscoverable-literal")
EOF
out="$(python3 "$CHECK" "$td/case2" 2>&1)"
report 1 "$out" "case2: needle absent -> violation"

# --- case 3: needle only in a non-referenced handbook -> still a violation ---
mkfixture case3
mkdir -p "$td/case3/docs/handbooks"
cat > "$td/case3/hooks/directive.sh" <<'EOF'
#!/usr/bin/env bash
# this directive never names any handbook file.
EOF
cat > "$td/case3/docs/handbooks/record-template.md" <<'EOF'
The record must state the resolution-path.
EOF
cat > "$td/case3/hooks/my-gate.sh" <<'EOF'
#!/usr/bin/env python3
def has_any(*needles):
    pass
has_any("resolution-path")
EOF
out="$(python3 "$CHECK" "$td/case3" 2>&1)"
report 1 "$out" "case3: needle only in unreferenced handbook -> violation"

# --- case 4: needle covered via SKILL.md under the unit -> pass ---
mkfixture case4
mkdir -p "$td/case4/some-skill"
cat > "$td/case4/hooks/directive.sh" <<'EOF'
#!/usr/bin/env bash
# see the skill for details.
EOF
cat > "$td/case4/some-skill/SKILL.md" <<'EOF'
When writing the record, include an alternatives-considered section.
EOF
cat > "$td/case4/hooks/my-gate.sh" <<'EOF'
#!/usr/bin/env python3
def has_any(*needles):
    pass
has_any("alternatives-considered")
EOF
out="$(python3 "$CHECK" "$td/case4" 2>&1)"
report 0 "$out" "case4: needle covered via SKILL.md"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
