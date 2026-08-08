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

# architecture-rulebook real bytes (issue-177): transcribed verbatim from
# architecture-rulebook@da8565d615d9fb6c18487c9b338fa8b60bdf1120's real
# architecture/hooks/directive.sh lines 14-16 — replaces #175's
# assumption-built unregistered-stub fixture, which matched no real
# Batch-1 repo (docs/issue-177/reports/implementation/survey.md).
gate_lib_real_file="$td/gate-lib-real-directive.sh"
cat > "$gate_lib_real_file" <<'DIRECTIVE'
#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-x}/hooks/lib/role-directive.sh"
ROLE_NAME=architecture
ROLE_SUBJECT_PREFIX=subject
ROLE_HANDBOOK=docs/handbooks/architecture.md
. "${CLAUDE_PLUGIN_ROOT_CORE:-x}/hooks/lib/gate-lib.sh" || { echo "architecture-directive.sh: cannot source gate-lib.sh" >&2; exit 0; }
gate_kill_switch_active "${ARCHITECTURE_CYCLE_OFF:-}" || exit 0
core_role_directive
DIRECTIVE

# genuinely vendored full copy (issue-177 proposal constraint): a
# directive.sh chaining three gate_* calls beyond the mandatory header —
# no real Batch-1 repo has more than one gate-lib-source line or more
# than one gate_* call line, so this must still fail via the new
# gate_is_role_directive_stub one-line-each cap (after-proposal hunt
# finding, docs/reports/2026-08-08-hunt-canon-forms-real-bytes.md).
vendored_chain_file="$td/vendored-chain-directive.sh"
cat > "$vendored_chain_file" <<'DIRECTIVE'
#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-x}/hooks/lib/role-directive.sh"
ROLE_NAME=architecture
ROLE_SUBJECT_PREFIX=subject
ROLE_HANDBOOK=docs/handbooks/architecture.md
. "${CLAUDE_PLUGIN_ROOT_CORE:-x}/hooks/lib/gate-lib.sh" || { echo "cannot source gate-lib.sh" >&2; exit 0; }
gate_kill_switch_active "${ARCHITECTURE_CYCLE_OFF:-}" || exit 0
gate_trap_fail_closed
gate_kill_switch_active "${ANOTHER_OFF:-}" || exit 0
core_role_directive
DIRECTIVE

# non-gate-lib source line (issue-177): a `.`-sourced sibling fragment
# that is NOT gate-lib.sh — proves the structural rule stays narrow and
# does not accept an arbitrary source line as a stand-in for #175's
# falsified layered-directive shape (no real repo bytes support that
# shape passing).
non_gate_lib_source_file="$td/non-gate-lib-source-directive.sh"
cat > "$non_gate_lib_source_file" <<'DIRECTIVE'
#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-x}/hooks/lib/role-directive.sh"
ROLE_NAME=accessibility
ROLE_SUBJECT_PREFIX=subject
ROLE_HANDBOOK=docs/handbooks/accessibility.md
. "$HERE/../accessibility-wcag/hooks/layered-directive.sh" 2>/dev/null
core_role_directive
DIRECTIVE

run_case pass "fragment-loop directive.sh (issue-10 shape) accepted" "$frag_loop_file"
run_case fail "regrown boilerplate directive.sh still rejected"       "$malformed_file"
run_case pass "single-call directive.sh (built-in shape) still accepted" "$single_call_file"
run_case pass "architecture-rulebook real gate-lib-source/gate-call shape accepted (issue-177)" "$gate_lib_real_file"
run_case fail "chained gate_* calls beyond one-line-each cap still rejected (issue-177)" "$vendored_chain_file"
run_case fail "non-gate-lib source line still rejected (issue-177)" "$non_gate_lib_source_file"

rm -rf "$fixtures_td"

echo
echo "pass=$pass fail=$fail"
[ "$fail" = 0 ]
