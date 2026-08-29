#!/usr/bin/env bash
# Standard test harness for core/hooks/lib/gate-lib.sh + gate-lib.py
# (issue-72, issue-75). Seven case groups are MANDATORY — a run of this
# file that does not exercise all seven fails the harness itself, not just
# one gate:
#
#   1. Edit with replace_all: true against a multiply-occurring old_string.
#   2. MultiEdit with a mix of replace_all true/false edits in one call.
#   3. Malformed JSON payload (truncated, non-object, non-UTF8).
#   4. Kill-switch set to an unrecognized value -> must stay ACTIVE.
#   5. Absolute file_path matching the same scope a relative-path fixture
#      already matches, plus a ./-prefixed variant.
#   6. A Bash-tool file write to the same target a Write-tool call would
#      hit, asserting equivalent deny/allow via gate_bash_write_targets
#      (sh and py versions, asserted to return the same token set).
#   7. gate-lib.sh sourced with CLAUDE_PLUGIN_ROOT_CORE pointed at a
#      nonexistent path and no valid relative fallback -> the guarded
#      source line must deny (exit 2), not silently allow (issue-75 fix).
#
# Also runs record-fields-gate.sh end-to-end for the replace_all/
# MultiEdit/NotebookEdit fix (issue-72's confirmed core-canon bug), and
# every gate's kill switch against an unrecognized value.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
HOOKS="$(cd "$HERE/.." && pwd -P)"
LIB="$HOOKS/lib/gate-lib.sh"
LIBPY="$HOOKS/lib/gate-lib.py"
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

# sh/py gate_bash_write_targets parity (issue-75 fix)
pywritetargets() { # <command>
  python3 -c "
import importlib.util
spec = importlib.util.spec_from_file_location('gate_lib', '$LIBPY')
gl = importlib.util.module_from_spec(spec); spec.loader.exec_module(gl)
for t in gl.gate_bash_write_targets('$1'):
    print(t)
"
}
parity_cmd='echo x > docs/issue-72/reports/coding.md'
sh_tokens="$(. "$LIB"; gate_bash_write_targets "$parity_cmd" | sort)"
py_tokens="$(pywritetargets "$parity_cmd" | sort)"
got=$([ "$sh_tokens" = "$py_tokens" ] && echo same || echo different)
report same "$got" \
  "gate-lib.py: gate_bash_write_targets returns the same token set as gate-lib.sh"

# --- group: gate_dequote / gate_outside_quotes (issue-94) -----------------
mark dequote
dequote() { # <want:absent|present> <needle> <command-arg> <name>
  out="$(python3 -c "
import importlib.util
spec = importlib.util.spec_from_file_location('gate_lib', '$LIBPY')
gl = importlib.util.module_from_spec(spec); spec.loader.exec_module(gl)
print(gl.gate_dequote('''$3'''))
")"
  case "$out" in
    *"$2"*) got=present ;;
    *)      got=absent ;;
  esac
  report "$1" "$got" "$4"
}
dequote absent  '>' 'grep -n "A > B" x.md' \
  "gate_dequote: quoted > is absent from output"
dequote present 'grep -n' 'grep -n "A > B" x.md' \
  "gate_dequote: unquoted grep -n survives"
dequote present 'x.md' 'grep -n "A > B" x.md' \
  "gate_dequote: unquoted x.md survives"
dequote absent  'gh pr merge' 'grep -n "gh pr merge" spawn.py' \
  "gate_dequote: quoted 'gh pr merge' phrase is absent from output"
dequote present '>' 'echo hi > x.md' \
  "gate_dequote: unquoted > outside any quote survives unchanged"

outquotes() { # <want:True|False> <pattern> <command-arg> <name>
  got="$(python3 -c "
import importlib.util
spec = importlib.util.spec_from_file_location('gate_lib', '$LIBPY')
gl = importlib.util.module_from_spec(spec); spec.loader.exec_module(gl)
print(gl.gate_outside_quotes('''$3''', r'$2'))
")"
  report "$1" "$got" "$4"
}
outquotes True  '>' 'echo hi > x.md' \
  "gate_outside_quotes: real unquoted occurrence -> True"
outquotes False '>' 'grep -n "a > b" x.md' \
  "gate_outside_quotes: only-quoted occurrence -> False"

# --- group: gate_head_of/TRANSPARENT (relocated from board-gate.sh) and
# gate_wrapper_head_before (issue-98) ---------------------------------------
mark wrapper-head
headof() { # <want-head> <segment> <name>
  got="$(python3 -c "
import importlib.util
spec = importlib.util.spec_from_file_location('gate_lib', '$LIBPY')
gl = importlib.util.module_from_spec(spec); spec.loader.exec_module(gl)
print(gl.gate_head_of('''$2'''))
")"
  report "$1" "$got" "$3"
}
headof bash 'bash -c "gh pr merge 5"' \
  "gate_head_of: bash -c resolves to bash"
headof grep 'xargs grep -l APPROVE' \
  "gate_head_of: xargs resolves through to grep (board-gate parity)"
headof rm   'xargs -I{} rm -rf x' \
  "gate_head_of: xargs -I{} resolves through to rm (board-gate parity)"
headof bash 'timeout 30 bash -c x' \
  "gate_head_of: timeout's own bare DURATION arg is skipped, not mistaken for the head"
headof bash 'nohup bash -c x' \
  "gate_head_of: nohup resolves through to bash"
headof git 'timeout -s KILL 30 git log' \
  "gate_head_of: timeout's own -s value-taking flag no longer swallows the bare DURATION slot"
headof git 'nice -n 10 git log' \
  "gate_head_of: nice's own -n value-taking flag resolves through to git"
headof git 'env -u FOO git log' \
  "gate_head_of: env's own -u value-taking flag resolves through to git"
headof git 'xargs -I fmt git log' \
  "gate_head_of: xargs's own -I value-taking flag (space-separated) resolves through to git"

wrapperhead() { # <want:head-or-empty> <cmdline> <needle> <name>
  got="$(python3 -c "
import importlib.util
spec = importlib.util.spec_from_file_location('gate_lib', '$LIBPY')
gl = importlib.util.module_from_spec(spec); spec.loader.exec_module(gl)
cmd = '''$2'''
for m in gl.GATE_QUOTE_SPAN.finditer(cmd):
    if '$3' in m.group():
        print(repr(gl.gate_wrapper_head_before(cmd, m.start())))
        break
else:
    print('<no-quoted-span-found>')
")"
  report "'$1'" "$got" "$4"
}
wrapperhead bash 'bash -c "gh pr merge 5"' 'gh pr merge' \
  "gate_wrapper_head_before: bash -c \"...\" -> bash"
wrapperhead bash 'bash -lc "gh pr merge 7 --merge"' 'gh pr merge' \
  "gate_wrapper_head_before: bash -lc \"...\" (combined short flag) -> bash"
wrapperhead bash 'timeout 30 bash -c "gh pr merge 7 --merge"' 'gh pr merge' \
  "gate_wrapper_head_before: timeout 30 bash -c \"...\" -> bash (sees through timeout's own bare arg)"
wrapperhead bash 'env bash -c "gh pr merge 7 --merge"' 'gh pr merge' \
  "gate_wrapper_head_before: env bash -c \"...\" -> bash"
wrapperhead bash 'xargs -I{} bash -c "gh pr merge 7 --merge"' 'gh pr merge' \
  "gate_wrapper_head_before: xargs -I{} bash -c \"...\" -> bash"
wrapperhead bash 'nohup bash -c "gh pr merge 7 --merge"' 'gh pr merge' \
  "gate_wrapper_head_before: nohup bash -c \"...\" -> bash"
wrapperhead sh 'sh -c "gh pr merge 5"' 'gh pr merge' \
  "gate_wrapper_head_before: sh -c \"...\" -> sh"
wrapperhead eval 'eval "gh pr merge 5"' 'gh pr merge' \
  "gate_wrapper_head_before: eval \"...\" -> eval (no -c flag needed)"
wrapperhead '' 'grep "gh pr merge" file.txt' 'gh pr merge' \
  "gate_wrapper_head_before: quoted grep pattern (no wrapper head) -> empty"
wrapperhead '' 'bash "script.sh with gh pr merge inside"' 'gh pr merge' \
  "gate_wrapper_head_before: bash \"path\" with no -c reads a file, not code -> empty"
# hunt-confirmed (docs/issue-98/reports/implementation.md, Hunt): a
# TRANSPARENT wrapper's own value-taking flag (nice -n N, timeout -s SIG)
# used to defeat resolution by landing on the flag's value token instead
# of the real wrapper head.
wrapperhead bash 'timeout -s KILL 30 bash -c "gh pr merge 5"' 'gh pr merge' \
  "gate_wrapper_head_before: timeout -s KILL 30 (value-taking flag before the bare DURATION) -> bash"
wrapperhead bash 'nice -n 10 bash -c "gh pr merge 5"' 'gh pr merge' \
  "gate_wrapper_head_before: nice -n 10 (value-taking flag) -> bash"

# --- group: gate_budget_exceeded (issue-63) -------------------------------
mark budget-exceeded
budgexc() { # <want:exceeded|not-exceeded> <started> <cap> <now> <name>
  ( . "$LIB"; gate_budget_exceeded "$2" "$3" "$4" ); rc=$?
  got=$([ $rc = 0 ] && echo exceeded || echo not-exceeded)
  report "$1" "$got" "$5"
}
budgexc exceeded     1000 60  1200 "gate_budget_exceeded: 200s elapsed > 60s cap -> exceeded"
budgexc not-exceeded 1000 120 1050 "gate_budget_exceeded: 50s elapsed < 120s cap -> not exceeded"
budgexc not-exceeded ""   60  1200 "gate_budget_exceeded: malformed started -> fail-open not-exceeded"
budgexc not-exceeded 1000 bad 1200 "gate_budget_exceeded: malformed cap -> fail-open not-exceeded"

# --- record-fields-gate.sh end-to-end: the confirmed core bug, fixed ----
mark record-fields-gate-e2e
rf() { # <want> <name> <role> <file_path> <content-json>
  payload="$(printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s}}' "$4" "$5")"
  out="$(printf '%s' "$payload" | env CLAUDE_SKILL="$3" CLAUDE_PROJECT_DIR="/tmp" \
      /bin/bash "$HOOKS/record-fields-gate.sh" 2>&1)"
  rc=$?
  got=$([ $rc = 0 ] && echo allow || { [ $rc = 2 ] && echo deny || echo "exit-$rc"; })
  report "$1" "$got" "$2"
}
rf deny "record-fields-gate.sh: missing §20 fields still denied post-migration" \
  coding "docs/issue-3/reports/coding.md" '"# empty\n"'
payload="$(printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s}}' "docs/issue-3/reports/coding.md" '"# empty\n"')"
out="$(printf '%s' "$payload" | env CLAUDE_SKILL=coding CLAUDE_PROJECT_DIR="/tmp" RECORD_FIELDS_GATE_OFF=banana \
    /bin/bash "$HOOKS/record-fields-gate.sh" 2>&1)"; rc=$?
got=$([ $rc = 0 ] && echo allow || { [ $rc = 2 ] && echo deny || echo "exit-$rc"; })
report deny "$got" "record-fields-gate.sh: RECORD_FIELDS_GATE_OFF=banana stays active (issue-72 fix)"

rfedit() { # <want> <name> <skill> <file_path-on-disk-relative-content> <tool_name> <tool_input-json>
  want="$1"; name="$2"; skill="$3"; content="$4"; tool="$5"; ti="$6"
  mktd
  fp="$td/docs/issue-3/reports/$skill.md"
  mkdir -p "$(dirname "$fp")"
  printf '%s' "$content" > "$fp"
  payload="$(printf '{"tool_name":"%s","tool_input":%s}' "$tool" "$(printf '%s' "$ti" | sed "s#__FP__#$fp#")")"
  out="$(printf '%s' "$payload" | env CLAUDE_SKILL="$skill" CLAUDE_PROJECT_DIR="$td" \
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
mktd
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
mktd
mkdir -p "$td/hooks/lib"
cp "$HOOKS/lib/gate-lib.sh" "$td/hooks/lib/gate-lib.sh"
out="$(bash "$HERE/stub-check.sh" "$td" 2>&1)"; rc=$?
report deny "$([ $rc = 0 ] && echo allow || echo deny)" \
  "stub-check: vendored gate-lib.sh caught (issue-72 canon-manifest entry)"
rm -rf "$td"

# --- group 7: missing-core -> guarded source must deny, not allow --------
mark missing-core
mktd
out="$(printf '{"tool_name":"Write","tool_input":{"file_path":"docs/issue-3/reports/coding.md","content":"x"}}' \
    | env CLAUDE_SKILL=coding CLAUDE_PROJECT_DIR="$td" \
      CLAUDE_PLUGIN_ROOT_CORE="$td/no-such-core" \
      /bin/bash "$HOOKS/record-fields-gate.sh" 2>&1)"
rc=$?
got=$([ $rc = 0 ] && echo allow || { [ $rc = 2 ] && echo deny || echo "exit-$rc"; })
report deny "$got" \
  "record-fields-gate.sh: CLAUDE_PLUGIN_ROOT_CORE pointed nowhere denies (issue-75 fix, not silent-allow)"
rm -rf "$td"

# --- issue-185: gate_directive_custom_by_convention unit coverage --------
. "$LIB"
mktd

stub_f="$td/stub-directive.sh"
cat > "$stub_f" <<'EOF'
#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/role-directive.sh"
core_role_directive \
  "YOU DECIDE: ..." \
  "USE WHEN: ..." \
  "PRODUCES: ..." \
  "HAND-OFF: ..."
EOF
if gate_directive_custom_by_convention "$stub_f"; then got=custom; else got=not-custom; fi
report not-custom "$got" "gate_directive_custom_by_convention: sanctioned stub reads as not-custom (sources role-directive.sh)"

custom_f="$td/custom-directive.sh"
cat > "$custom_f" <<'EOF'
#!/usr/bin/env bash
# mentions core_role_directive only in a comment/heredoc, never calls it
case "${DIRECTIVE_OFF:-}" in 1|true) exit 0 ;; esac
cat <<'INNER'
core_role_directive is mentioned here in prose only.
INNER
EOF
if gate_directive_custom_by_convention "$custom_f"; then got=custom; else got=not-custom; fi
report custom "$got" "gate_directive_custom_by_convention: comment/heredoc-only mention reads as custom (needle must not trip on prose)"

needle_call_f="$td/needle-call-directive.sh"
cat > "$needle_call_f" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
gate_deny "denied"
EOF
if gate_directive_custom_by_convention "$needle_call_f"; then got=custom; else got=not-custom; fi
report not-custom "$got" "gate_directive_custom_by_convention: bare gate_* call reads as not-custom (needle bypass attempt caught)"

hash_vendored_f="$td/hash-vendored-directive.sh"
cp "$HOOKS/lib/role-directive.sh" "$hash_vendored_f"
if gate_directive_custom_by_convention "$hash_vendored_f"; then got=custom; else got=not-custom; fi
report not-custom "$got" "gate_directive_custom_by_convention: byte-identical copy of role-directive.sh reads as not-custom (hash match)"

rm -rf "$td"

echo
echo "gate-lib: $pass passed, $fail failed"
echo "mandatory groups exercised:$groups_seen"
for g in replace_all-edit multiedit-replace_all malformed-json kill-switch absolute-path bash-write-coverage missing-core; do
  case " $groups_seen " in
    *" $g "*) ;;
    *) echo "gate-lib: MANDATORY GROUP MISSING: $g" >&2; fail=$((fail + 1)) ;;
  esac
done
[ "$fail" = 0 ]
