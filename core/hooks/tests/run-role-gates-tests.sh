#!/usr/bin/env bash
# trailer-gate.sh, record-fields-gate.sh, handbook-trigger-gate.sh and
# stub-check.sh, exercised as real subprocesses — asserting that two
# different CLAUDE_ROLE values produce correctly-labeled output and
# correctly-namespaced kill switches from the SAME canon file (issue-66).
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
. "$HERE/_tmp.sh"
HOOKS="$(cd "$HERE/.." && pwd -P)"

pass=0
fail=0
report() { # <want> <got> <name>
  if [ "$2" = "$1" ]; then
    pass=$((pass + 1)); printf 'ok     %-40s %s\n' "$3" "$2"
  else
    fail=$((fail + 1)); printf 'FAIL   %-40s want=%s got=%s\n' "$3" "$1" "$2"
  fi
}

# --- trailer-gate.sh: role-labeled refusal, no trailer -> deny -------------
run_trailer() { # <want> <name> <role> <commit-args-json> <extra-env...>
  want="$1"; name="$2"; role="$3"; args="$4"; shift 4
  mktd
  git init -q "$td"
  echo x > "$td/x.txt"
  mkdir -p "$td/docs/issue-3/reports"
  echo x > "$td/docs/issue-3/reports/x.md"
  git -C "$td" add -A
  payload="$(printf '{"tool_name":"Bash","tool_input":{"command":%s}}' "$args")"
  out="$(printf '%s' "$payload" | env CLAUDE_ROLE="$role" CLAUDE_PROJECT_DIR="$td" "$@" \
      /bin/bash "$HOOKS/trailer-gate.sh" 2>&1)"
  rc=$?
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  msg_ok=1
  case "$got" in deny) case "$out" in "${role}: refused"*) ;; *) msg_ok=0 ;; esac ;; esac
  rm -rf "$td"
  report "$want" "$got" "$name"
  [ "$msg_ok" = 1 ] || { fail=$((fail + 1)); echo "FAIL   $name: message not labeled with role '$role': $out"; }
}

run_trailer deny  "coding: commit w/o trailer denied"    coding '"git commit -m x"'
run_trailer allow "coding: commit w/ trailer allowed"    coding '"git commit -m \"x\n\nSubject: issue-3\""'
run_trailer deny  "product: commit w/o trailer denied"   product '"git commit -m x"'
run_trailer allow "TRAILER_GATE_OFF disables the gate"   coding '"git commit -m x"' TRAILER_GATE_OFF=1

# --- record-fields-gate.sh: role-scoped record path, role-labeled refusal --
run_rf() { # <want> <name> <role> <file_path> <content-json> <extra-env...>
  want="$1"; name="$2"; role="$3"; fp="$4"; content="$5"; shift 5
  payload="$(printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s}}' "$fp" "$content")"
  out="$(printf '%s' "$payload" | env CLAUDE_ROLE="$role" CLAUDE_PROJECT_DIR="/tmp" "$@" \
      /bin/bash "$HOOKS/record-fields-gate.sh" 2>&1)"
  rc=$?
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  msg_ok=1
  case "$got" in deny) case "$out" in "${role}: refused"*) ;; *) msg_ok=0 ;; esac ;; esac
  report "$want" "$got" "$name"
  [ "$msg_ok" = 1 ] || { fail=$((fail + 1)); echo "FAIL   $name: message not labeled with role '$role': $out"; }
}

run_rf deny  "coding record missing fields denied" coding \
  "docs/issue-3/reports/coding.md" '"# empty\n"'
run_rf allow "coding record w/ all §20 fields allowed" coding \
  "docs/issue-3/reports/coding.md" \
  '"loop_state: landed\n\n## what was done\nx\n\n## why\ny\n\nupstream: abc1234\n\n## open findings\nnone\n"'
run_rf allow "non-owning role write is not this gate'\''s business" coding \
  "docs/issue-3/reports/product.md" '"# empty\n"'
run_rf deny  "product-role open record missing next-steps denied" product \
  "docs/issue-3/reports/product.md" \
  '"loop_state: scope-proposed\n\n## what was done\nx\n\n## why\ny\n\nupstream: abc1234\n\n## open findings\nnone\n"'
run_rf allow "product-role scope-proposed treated as terminal via override" product \
  "docs/issue-3/reports/product.md" \
  '"loop_state: scope-proposed\n\n## what was done\nx\n\n## why\ny\n\nupstream: abc1234\n\n## open findings\nnone\n"' \
  RECORD_FIELDS_TERMINAL_STATES="landed scope-proposed"
run_rf deny  "implementation record code_under_review bare sha denied (issue-100)" implementation \
  "docs/issue-3/reports/implementation.md" \
  '"loop_state: landed\n\ncode_under_review: 0123456789abcdef0123456789abcdef01234567\n\n## what was done\nx\n\n## why\ny\n\nupstream: abc1234\n\n## open findings\nnone\n"'
run_rf allow "implementation record code_under_review file list allowed (issue-100)" implementation \
  "docs/issue-3/reports/implementation.md" \
  '"loop_state: landed\n\ncode_under_review: `a.sh`, `b.sh`\n\n## what was done\nx\n\n## why\ny\n\nupstream: abc1234\n\n## open findings\nnone\n"'

# --- record-fields-gate.sh: same-commit sha placeholder check (issue-128) --
run_rf deny  "proposal sha bracket placeholder denied (issue-128)" coding \
  "docs/issue-3/proposals/2026-08-04-x.md" \
  '"upstream:\n  - path: docs/issue-3/reports/implementation/survey.md\n    sha: <set at commit>\n"'
run_rf allow "proposal sha: same-commit allowed (issue-128)" coding \
  "docs/issue-3/proposals/2026-08-04-x.md" \
  '"upstream:\n  - path: docs/issue-3/reports/implementation/survey.md\n    sha: same-commit\n"'
run_rf allow "proposal sha real hex allowed (issue-128)" coding \
  "docs/issue-3/proposals/2026-08-04-x.md" \
  '"upstream:\n  - path: docs/issue-3/reports/implementation/survey.md\n    sha: 0123456789abcdef0123456789abcdef01234567\n"'
run_rf deny  "record sha bracket placeholder denied despite complete §20 fields (issue-128)" coding \
  "docs/issue-3/reports/coding.md" \
  '"loop_state: landed\n\n## what was done\nx\n\n## why\ny\n\nupstream:\n  - path: docs/issue-3/reports/implementation/survey.md\n    sha: <set at commit>\n\n## open findings\nnone\n"'
run_rf allow "record sha: same-commit allowed (issue-128)" coding \
  "docs/issue-3/reports/coding.md" \
  '"loop_state: landed\n\n## what was done\nx\n\n## why\ny\n\nupstream:\n  - path: docs/issue-3/reports/implementation/survey.md\n    sha: same-commit\n\n## open findings\nnone\n"'

# --- handbook-trigger-gate.sh: role-labeled refusal ------------------------
run_ht() { # <want> <name> <role> <staged-files...> -- <commit-args-json>
  want="$1"; name="$2"; role="$3"; shift 3
  files=()
  while [ "$1" != "--" ]; do files+=("$1"); shift; done
  shift
  args="$1"
  mktd
  git init -q "$td"
  for f in "${files[@]}"; do
    mkdir -p "$td/$(dirname "$f")"
    echo x > "$td/$f"
  done
  [ "${#files[@]}" -gt 0 ] && git -C "$td" add -A
  payload="$(printf '{"tool_name":"Bash","tool_input":{"command":%s}}' "$args")"
  out="$(printf '%s' "$payload" | env CLAUDE_ROLE="$role" CLAUDE_PROJECT_DIR="$td" \
      /bin/bash "$HOOKS/handbook-trigger-gate.sh" 2>&1)"
  rc=$?
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  msg_ok=1
  case "$got" in deny) case "$out" in "${role}: refused"*) ;; *) msg_ok=0 ;; esac ;; esac
  rm -rf "$td"
  report "$want" "$got" "$name"
  [ "$msg_ok" = 1 ] || { fail=$((fail + 1)); echo "FAIL   $name: message not labeled with role '$role': $out"; }
}

run_ht deny  "coding: package.json w/o handbook denied" coding package.json -- '"git commit -m x"'
run_ht allow "coding: package.json w/ handbook allowed" coding package.json docs/handbooks/x.md -- '"git commit -m x"'
run_ht deny  "product: package.json w/o handbook denied" product package.json -- '"git commit -m x"'

# --- stub-check.sh: absence-based for gates, structural for directive.sh --
mktd
mkdir -p "$td/hooks/tests"
out="$(/bin/bash "$HERE/stub-check.sh" "$td" 2>&1)"; rc=$?
report allow "$([ $rc = 0 ] && echo allow || echo deny)" "stub-check: clean rulebook tree passes"
cp "$HOOKS/trailer-gate.sh" "$td/hooks/trailer-gate.sh"
out="$(/bin/bash "$HERE/stub-check.sh" "$td" 2>&1)"; rc=$?
report deny "$([ $rc = 0 ] && echo allow || echo deny)" "stub-check: vendored trailer-gate.sh caught"
rm -f "$td/hooks/trailer-gate.sh"
cp "$HERE/stub-check.sh" "$td/hooks/tests/stub-check.sh"
out="$(/bin/bash "$HERE/stub-check.sh" "$td" 2>&1)"; rc=$?
report deny "$([ $rc = 0 ] && echo allow || echo deny)" "stub-check: vendored copy of itself caught (issue-69)"
rm -f "$td/hooks/tests/stub-check.sh"
cat > "$td/hooks/directive.sh" <<'EOF'
#!/usr/bin/env bash
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)/hooks/lib/role-directive.sh"
core_role_directive "YOU DECIDE: x" "USE WHEN: y" "PRODUCES: z" "HAND-OFF: w"
EOF
out="$(/bin/bash "$HERE/stub-check.sh" "$td" 2>&1)"; rc=$?
report allow "$([ $rc = 0 ] && echo allow || echo deny)" "stub-check: real stub directive.sh passes"
cat >> "$td/hooks/directive.sh" <<'EOF'
case "${SOME_CYCLE_OFF:-}" in ""|0|false|no|off) ;; *) exit 0 ;; esac
[ "${CLAUDE_ROLE:-}" = "x" ] || exit 0
echo one; echo two; echo three; echo four; echo five; echo six; echo seven
echo eight; echo nine; echo ten; echo eleven; echo twelve; echo thirteen
EOF
out="$(/bin/bash "$HERE/stub-check.sh" "$td" 2>&1)"; rc=$?
report deny "$([ $rc = 0 ] && echo allow || echo deny)" "stub-check: regrown boilerplate caught"
rm -rf "$td"

echo
echo "role-gates: $pass passed, $fail failed"
[ "$fail" = 0 ]
