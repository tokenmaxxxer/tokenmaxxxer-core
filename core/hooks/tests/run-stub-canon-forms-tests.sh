#!/usr/bin/env bash
# gate_is_role_directive_stub's structural line classifier (issue-78,
# rewritten as a line classifier by issue-180): a sanctioned directive.sh
# shape passes, and a genuinely malformed directive.sh (regrown
# boilerplate matching no sanctioned line category) still fails.
#
# Exercises gate_is_role_directive_stub directly rather than going
# through stub-check.sh: stub-check.sh's own canon-manifest.txt
# absence-check unconditionally flags any file literally named
# "directive.sh" as a vendored core-canon copy (canon-manifest.txt lists
# "directive.sh" alongside stub-check.sh's other canon-pinned filenames),
# which collides with this suite's fixtures — a pre-existing conflict
# between the manifest's absence-check and directive.sh's own
# structural-check carve-out (both in stub-check.sh), confirmed present
# on main before this change and out of this issue's write set
# (canon-manifest.txt) to fix.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
. "$HERE/_tmp.sh"
. "$HERE/../lib/gate-lib.sh"

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
  out="$(gate_is_role_directive_stub "$body" 2>&1)"
  rc=$?
  case "$rc" in 0) got=pass ;; 1) got=fail ;; *) got="rc-$rc" ;; esac
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

# accessibility-rulebook real bytes (issue-180): transcribed verbatim
# from accessibility-rulebook@ce5cbe5c4c55622001812ed18d8302221c2f5b21's
# real accessibility/hooks/directive.sh — direct nested-quote
# role-directive.sh source, no gate-lib.sh at all (docs/issue-180/
# reports/implementation/survey.md).
accessibility_real_file="$td/accessibility-real-directive.sh"
cat > "$accessibility_real_file" <<'DIRECTIVE'
#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/role-directive.sh"

YOU_DECIDE="..."
USE_WHEN="..."
PRODUCES="..."
HAND_OFF="..."

core_role_directive "$YOU_DECIDE" "$USE_WHEN" "$PRODUCES" "$HAND_OFF"
DIRECTIVE

# localization-rulebook real bytes (issue-180): transcribed verbatim from
# localization-rulebook@da7144369f31800c8e4af3008a1379affc6daf0c's real
# localization/hooks/directive.sh — same direct nested-quote source
# shape as accessibility-rulebook, args as string literals.
localization_real_file="$td/localization-real-directive.sh"
cat > "$localization_real_file" <<'DIRECTIVE'
#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/role-directive.sh"
core_role_directive "..." "..." "..." "..."
DIRECTIVE

# capacity-planning-rulebook real bytes (issue-180): transcribed
# verbatim from capacity-planning-rulebook@00273632123750aa3c5cff608729fa93f042b419's
# real capacity-planning/hooks/directive.sh — direct nested-quote source
# with an `|| { ...; exit 2; }` fallback (a different exit code from
# architecture-rulebook's, not itself a classification signal).
capacity_planning_real_file="$td/capacity-planning-real-directive.sh"
cat > "$capacity_planning_real_file" <<'DIRECTIVE'
#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/role-directive.sh" || { echo "directive.sh: cannot source role-directive.sh" >&2; exit 2; }
core_role_directive "..." $'...' $'...'
DIRECTIVE

# vendored full copy (issue-180 proposal constraint): a directive.sh with
# real prose beyond the sanctioned line categories must still flag.
vendored_full_file="$td/vendored-full-directive.sh"
cat > "$vendored_full_file" <<'DIRECTIVE'
#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-x}/hooks/lib/role-directive.sh"
core_role_directive() {
  echo "reimplemented locally instead of sourcing the shared function"
}
core_role_directive x
DIRECTIVE

# stub-plus-extra-logic (issue-180 proposal constraint): a sanctioned
# stub with one extra non-classifiable logic line appended.
stub_plus_extra_file="$td/stub-plus-extra-directive.sh"
cat > "$stub_plus_extra_file" <<'DIRECTIVE'
#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-x}/hooks/lib/role-directive.sh"
echo "extra custom logic not part of any sanctioned line category"
core_role_directive x
DIRECTIVE

run_case pass "fragment-loop directive.sh (issue-10 shape) accepted" "$frag_loop_file"
run_case fail "regrown boilerplate directive.sh still rejected"       "$malformed_file"
run_case pass "single-call directive.sh (built-in shape) still accepted" "$single_call_file"
run_case pass "architecture-rulebook real gate-lib-source/gate-call shape accepted (issue-177)" "$gate_lib_real_file"
run_case fail "chained gate_* calls beyond one-line-each cap still rejected (issue-177)" "$vendored_chain_file"
run_case fail "non-gate-lib source line still rejected (issue-177)" "$non_gate_lib_source_file"
run_case pass "accessibility-rulebook real direct nested-quote source, no gate-lib.sh, accepted (issue-180)" "$accessibility_real_file"
run_case pass "localization-rulebook real direct nested-quote source accepted (issue-180)" "$localization_real_file"
run_case pass "capacity-planning-rulebook real direct-source-with-fallback accepted (issue-180)" "$capacity_planning_real_file"
run_case fail "vendored full copy (reimplemented core_role_directive) still rejected (issue-180)" "$vendored_full_file"
run_case fail "sanctioned stub plus one extra logic line still rejected (issue-180)" "$stub_plus_extra_file"

rm -rf "$fixtures_td"

CANON_FORMS="$HERE/canon-forms.txt"
if grep -qE '^(single-call|fragment-loop|gate-lib-source|gate-call):' "$CANON_FORMS" 2>/dev/null; then
  fail=$((fail + 1))
  echo "FAIL   canon-forms.txt carries directive.sh shape rows (issue-180 requires none)"
else
  pass=$((pass + 1))
  echo "ok     canon-forms.txt carries no directive.sh shape rows (issue-180)"
fi

echo
echo "pass=$pass fail=$fail"
[ "$fail" = 0 ]
