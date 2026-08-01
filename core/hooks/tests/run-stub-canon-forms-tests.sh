#!/usr/bin/env bash
# stub-check.sh's canon-forms.txt combination-shape classifier (issue-78):
# a registered directive.sh combination shape (sales-rulebook's approved
# fragment-array for-loop, issue-10) passes, and a genuinely malformed
# directive.sh (regrown boilerplate matching no registered shape) still
# fails.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
. "$HERE/_tmp.sh"

pass=0
fail=0
report() { # <want> <got> <name>
  if [ "$2" = "$1" ]; then
    pass=$((pass + 1)); printf 'ok     %-45s %s\n' "$3" "$2"
  else
    fail=$((fail + 1)); printf 'FAIL   %-45s want=%s got=%s\n' "$3" "$1" "$2"
  fi
}

run_case() { # <want-rc> <name> <directive-body-file>
  want="$1"; name="$2"; body="$3"
  mktd
  mkdir -p "$td/hooks"
  cp "$body" "$td/hooks/directive.sh"
  out="$(bash "$HERE/stub-check.sh" "$td" 2>&1)"
  rc=$?
  case "$rc" in 0) got=pass ;; 1) got=fail ;; *) got="rc-$rc" ;; esac
  rm -rf "$td"
  report "$want" "$got" "$name"
  [ "$got" = "$want" ] || echo "  output: $out"
}

mktd
fixtures_td="$td"
frag_loop_file="$td/frag-loop-directive.sh"
cat > "$frag_loop_file" <<'DIRECTIVE'
#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-x}/hooks/lib/role-directive.sh"
ROLE_NAME=sales
ROLE_SUBJECT_PREFIX=subject
ROLE_HANDBOOK=docs/handbooks/sales.md
for frag in \
  "$HERE/../../sales-proposal-norm/hooks/directive.sh" \
  "$HERE/../../sales-qualification-meddpicc/hooks/directive.sh" \
  "$HERE/../../sales-stage-definitions/hooks/directive.sh" \
  "$HERE/../../sales-playbook/hooks/directive.sh"
do
  [ -f "$frag" ] && . "$frag" 2>/dev/null
done
core_role_directive "$frag"
DIRECTIVE

malformed_file="$td/malformed-directive.sh"
cat > "$malformed_file" <<'DIRECTIVE'
#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-x}/hooks/lib/role-directive.sh"
echo "hand rolled boilerplate"
core_role_directive x
DIRECTIVE

single_call_file="$td/single-call-directive.sh"
cat > "$single_call_file" <<'DIRECTIVE'
#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-x}/hooks/lib/role-directive.sh"
ROLE_NAME=coding
ROLE_SUBJECT_PREFIX=subject
ROLE_HANDBOOK=docs/handbooks/coding.md
core_role_directive
DIRECTIVE

run_case pass "fragment-loop directive.sh (issue-10 shape) accepted" "$frag_loop_file"
run_case fail "regrown boilerplate directive.sh still rejected"       "$malformed_file"
run_case pass "single-call directive.sh (built-in shape) still accepted" "$single_call_file"

rm -rf "$fixtures_td"

echo
echo "pass=$pass fail=$fail"
[ "$fail" = 0 ]
