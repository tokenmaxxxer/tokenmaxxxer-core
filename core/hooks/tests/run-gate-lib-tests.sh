#!/usr/bin/env bash
# Standard test harness for core/hooks/lib/gate-lib.sh + gate-lib.py
# (issue-72). Six case groups are MANDATORY — a run of this file that does
# not exercise all six fails the harness itself, not just one gate:
#
#   1. Edit with replace_all: true against a multiply-occurring old_string.
#   2. MultiEdit with a mix of replace_all true/false edits in one call.
#   3. Malformed JSON payload (truncated, non-object, non-UTF8).
#   4. Kill-switch set to an unrecognized value -> must stay ACTIVE.
#   5. Absolute file_path matching the same scope a relative-path fixture
#      already matches, plus a ./-prefixed variant.
#   6. A Bash-tool file write to the same target a Write-tool call would
#      hit, asserting equivalent deny/allow via gate_bash_write_targets.
#
# Also runs record-fields-gate.sh end-to-end for the replace_all/
# MultiEdit/NotebookEdit fix (issue-72's confirmed core-canon bug), and
# every gate's kill switch against an unrecognized value.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
HOOKS="$(cd "$HERE/.." && pwd -P)"
LIB="$HOOKS/lib/gate-lib.sh"
LIBPY="$HOOKS/lib/gate-lib.py"

pass=0
fail=0
report() { # <want> <got> <name>
  if [ "$2" = "$1" ]; then
    pass=$((pass + 1)); printf 'ok     %-55s %s\n' "$3" "$2"
  else
    fail=$((fail + 1)); printf 'FAIL   %-55s want=%s got=%s\n' "$3" "$1" "$2"
  fi
}

groups_seen=""
mark() { groups_seen="$groups_seen $1"; }

# --- group 4: kill-switch unrecognized value stays ACTIVE ------------------
mark kill-switch
kswitch() { # <want-active:0|1> <value> <name>
  ( . "$LIB"; gate_kill_switch_active "$2" ); rc=$?
  got=$([ $rc = 0 ] && echo active || echo disabled)
  want=$([ "$1" = 1 ] && echo active || echo disabled)
  report "$want" "$got" "$3"
}
kswitch 1 ""       "unset -> active"
kswitch 1 "0"      "'0' -> active"
kswitch 1 "false"  "'false' -> active"
kswitch 1 "off"    "'off' -> active"
kswitch 0 "1"      "'1' -> disabled"
kswitch 0 "true"   "'true' -> disabled"
kswitch 1 "banana" "unrecognized 'banana' -> ACTIVE (issue-72 fix)"
kswitch 1 " "      "stray-whitespace -> active (not silently disabled)"

# --- group 3: malformed JSON --------------------------------------------
mark malformed-json
mjson() { # <name> <raw>
  out="$(python3 -c "
import sys, importlib.util
spec = importlib.util.spec_from_file_location('gate_lib', '$LIBPY')
gl = importlib.util.module_from_spec(spec); spec.loader.exec_module(gl)
def deny(m):
    sys.stderr.write('deny: ' + m); sys.exit(2)
gl.gate_parse_json_or_deny(sys.argv[1], deny)
print('parsed-ok')
" "$2" 2>&1)"
  rc=$?
  got=$([ $rc = 2 ] && echo deny || echo "exit-$rc")
  report deny "$got" "$1"
}
mjson "truncated JSON denies"       '{"tool_name":"Write"'
mjson "non-object JSON denies"      '"just a string"'
mjson "empty payload denies"        ''

# --- group 5: absolute / relative / ./-prefixed path normalize ----------
mark absolute-path
npath() { # <want> <root> <path> <name>
  got="$(python3 -c "
import importlib.util
spec = importlib.util.spec_from_file_location('gate_lib', '$LIBPY')
gl = importlib.util.module_from_spec(spec); spec.loader.exec_module(gl)
r = gl.gate_normalize_path('$2', '$3')
print(r if r is not None else '<outside>')
")"
  report "$1" "$got" "$4"
}
npath "docs/issue-72/x.md" "/repo" "docs/issue-72/x.md"          "relative path normalizes"
npath "docs/issue-72/x.md" "/repo" "/repo/docs/issue-72/x.md"    "absolute path normalizes to same tail"
npath "docs/issue-72/x.md" "/repo" "./docs/issue-72/x.md"        "./-prefixed path normalizes to same tail"
npath "<outside>"          "/repo" "/elsewhere/x.md"              "outside-root path rejected"

# --- groups 1+2: replace_all (Edit) and MultiEdit mixed replace_all -----
mark replace_all-edit
mark multiedit-replace_all
recon() { # <want-new-text> <name> <python-args-json...>
  got="$(python3 -c "
import json, importlib.util
spec = importlib.util.spec_from_file_location('gate_lib', '$LIBPY')
gl = importlib.util.module_from_spec(spec); spec.loader.exec_module(gl)
tool, ti, cur = json.loads('''$3''')
new_text, ok = gl.gate_reconstruct_write(tool, ti, cur)
print(new_text if ok else '<fail>')
")"
  report "$1" "$got" "$2"
}
recon "a-a-a" "Edit replace_all:true replaces every occurrence" \
  '["Edit", {"old_string":"x","new_string":"a","replace_all":true}, "x-x-x"]'
recon "a-x-x" "Edit replace_all:false (default) replaces first only" \
  '["Edit", {"old_string":"x","new_string":"a"}, "x-x-x"]'
recon "b-b-Y" "MultiEdit mixes replace_all true/false across edits" \
  '["MultiEdit", {"edits":[{"old_string":"x","new_string":"b","replace_all":true},{"old_string":"y","new_string":"Y","replace_all":false}]}, "x-x-y"]'
recon "<fail>" "MultiEdit fails closed when an edit's old_string is absent" \
  '["MultiEdit", {"edits":[{"old_string":"nope","new_string":"b"}]}, "x-x-y"]'
recon "cell body" "NotebookEdit reconstructs the edited cell source" \
  '["NotebookEdit", {"new_source":"cell body","edit_mode":"replace"}, null]'

# --- group 6: Bash-tool write reaches the same target a Write call would ---
mark bash-write-coverage
bashscan() { # <want:0|1 found> <command> <pattern> <name>
  ( . "$LIB"
    hits="$(gate_bash_write_targets "$2")"
    echo "$hits" | grep -Eq "$3" )
  rc=$?
  got=$([ $rc = 0 ] && echo found || echo not-found)
  want=$([ "$1" = 1 ] && echo found || echo not-found)
  report "$want" "$got" "$4"
}
bashscan 1 'echo x > docs/issue-72/reports/coding.md' 'docs/issue-72/reports/coding\.md' \
  "Bash redirect write to record path is scanned like a Write call"
bashscan 0 'git status' 'docs/' \
  "Bash read-only command yields no docs/ candidate"

# --- record-fields-gate.sh end-to-end: the confirmed core bug, fixed ----
mark record-fields-gate-e2e
rf() { # <want> <name> <role> <file_path> <content-json>
  payload="$(printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s}}' "$4" "$5")"
  out="$(printf '%s' "$payload" | env CLAUDE_ROLE="$3" CLAUDE_PROJECT_DIR="/tmp" \
      /bin/bash "$HOOKS/record-fields-gate.sh" 2>&1)"
  rc=$?
  got=$([ $rc = 0 ] && echo allow || { [ $rc = 2 ] && echo deny || echo "exit-$rc"; })
  report "$1" "$got" "$2"
}
rf deny "record-fields-gate.sh: missing §20 fields still denied post-migration" \
  coding "docs/issue-3/reports/coding.md" '"# empty\n"'
payload="$(printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s}}' "docs/issue-3/reports/coding.md" '"# empty\n"')"
out="$(printf '%s' "$payload" | env CLAUDE_ROLE=coding CLAUDE_PROJECT_DIR="/tmp" RECORD_FIELDS_GATE_OFF=banana \
    /bin/bash "$HOOKS/record-fields-gate.sh" 2>&1)"; rc=$?
got=$([ $rc = 0 ] && echo allow || { [ $rc = 2 ] && echo deny || echo "exit-$rc"; })
report deny "$got" "record-fields-gate.sh: RECORD_FIELDS_GATE_OFF=banana stays active (issue-72 fix)"

rfedit() { # <want> <name> <role> <file_path-on-disk-relative-content> <tool_name> <tool_input-json>
  want="$1"; name="$2"; role="$3"; content="$4"; tool="$5"; ti="$6"
  td="$(mktemp -d)"
  fp="$td/docs/issue-3/reports/$role.md"
  mkdir -p "$(dirname "$fp")"
  printf '%s' "$content" > "$fp"
  payload="$(printf '{"tool_name":"%s","tool_input":%s}' "$tool" "$(printf '%s' "$ti" | sed "s#__FP__#$fp#")")"
  out="$(printf '%s' "$payload" | env CLAUDE_ROLE="$role" CLAUDE_PROJECT_DIR="$td" \
      /bin/bash "$HOOKS/record-fields-gate.sh" 2>&1)"
  rc=$?
  got=$([ $rc = 0 ] && echo allow || { [ $rc = 2 ] && echo deny || echo "exit-$rc"; })
  rm -rf "$td"
  report "$want" "$got" "$name"
}
GOOD_RECORD='loop_state: landed

## what was done
x

## why
y

upstream: abc1234

## open findings
none
'
rfedit allow "record-fields-gate.sh: replace_all edit reconstructs to a passing record" \
  coding "$GOOD_RECORD" "Edit" \
  '{"file_path":"__FP__","old_string":"x","new_string":"x","replace_all":true}'

# --- compliance-check.sh: catches a synthetic hand-rolled violation ------
mark compliance-check
td="$(mktemp -d)"
cat > "$td/fixture-gate.sh" <<'EOF'
#!/usr/bin/env bash
case "${FIXTURE_OFF:-}" in ""|0|false|no|off) ;; *) exit 0 ;; esac
python3 -c 'new_text = current.replace(old, new, 1)'
EOF
out="$(bash "$HOOKS/tests/compliance-check.sh" "$td" 2>&1)"; rc=$?
report deny "$([ $rc = 0 ] && echo allow || echo deny)" \
  "compliance-check.sh: flags a hand-rolled kill-switch + replace shape"
rm -rf "$td"
out="$(bash "$HOOKS/tests/compliance-check.sh" "$HOOKS" 2>&1)"; rc=$?
report allow "$([ $rc = 0 ] && echo allow || echo deny)" \
  "compliance-check.sh: core's own migrated gates pass clean"

# --- stub-check.sh: gate-lib.sh/compliance-check.sh added to the manifest -
mark stub-check-manifest
td="$(mktemp -d)"
mkdir -p "$td/hooks/lib"
cp "$HOOKS/lib/gate-lib.sh" "$td/hooks/lib/gate-lib.sh"
out="$(bash "$HERE/stub-check.sh" "$td" 2>&1)"; rc=$?
report deny "$([ $rc = 0 ] && echo allow || echo deny)" \
  "stub-check: vendored gate-lib.sh caught (issue-72 canon-manifest entry)"
rm -rf "$td"

echo
echo "gate-lib: $pass passed, $fail failed"
echo "mandatory groups exercised:$groups_seen"
for g in replace_all-edit multiedit-replace_all malformed-json kill-switch absolute-path bash-write-coverage; do
  case " $groups_seen " in
    *" $g "*) ;;
    *) echo "gate-lib: MANDATORY GROUP MISSING: $g" >&2; fail=$((fail + 1)) ;;
  esac
done
[ "$fail" = 0 ]
