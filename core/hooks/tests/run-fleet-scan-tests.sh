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

# issue-185: needle-carrying fixture — a byte copy of
# gate_is_role_directive_stub's own function body with one byte changed
# (a genuinely vendored copy edited by one byte still hash-mismatches, so
# it must still flag via the canon-function-name needle, not read as
# custom-by-convention).
vendored_repo="$td/vendored-rulebook"
mkdir -p "$vendored_repo/hooks"
cat > "$vendored_repo/hooks/directive.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
case "${DIRECTIVE_OFF:-}" in
  1|true) exit 0 ;;
esac
gate_is_role_directive_stub() {
  local f="$1"
  echo "one byte changed here to defeat hash comparison"
  return 0
}
EOF
out="$("$HERE/compliance-check.sh" --canon-duplication "$vendored_repo" 2>&1)"
rc=$?
report 1 "$rc" "vendored full directive.sh exits non-zero under --canon-duplication"
case "$out" in
  *"vendored copy"*directive.sh*) report "vendored-flag" "vendored-flag" "vendored full directive.sh flagged as vendored copy" ;;
  *) report "vendored-flag" "no-flag" "vendored full directive.sh flagged as vendored copy" ;;
esac

# issue-185: a bare gate_* call with no source line at all — canon-
# function-containing, not byte-vendored — must still FAIL, not read as
# custom-by-convention.
gate_call_repo="$td/gate-call-rulebook"
mkdir -p "$gate_call_repo/hooks"
cat > "$gate_call_repo/hooks/directive.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
gate_deny "denied"
EOF
out="$("$HERE/compliance-check.sh" --canon-duplication "$gate_call_repo" 2>&1)"
rc=$?
report 1 "$rc" "bare gate_* call directive.sh exits non-zero under --canon-duplication"
case "$out" in
  *"vendored copy"*directive.sh*) report "vendored-flag" "vendored-flag" "bare gate_* call directive.sh flagged as vendored copy" ;;
  *) report "vendored-flag" "no-flag" "bare gate_* call directive.sh flagged as vendored copy" ;;
esac

# issue-185: three real custom-by-convention directive.sh files, byte-
# exact from the checked-out repos on disk — accessibility-rulebook @
# ce5cbe5c4c55622001812ed18d8302221c2f5b21
# (wcag-em-directive/hooks/directive.sh), localization-rulebook @
# 2c9f76b8b6ebc212845409413de7bb61c2de50c6
# (localization/plugins/mqm-tagging/hooks/directive.sh), and
# capacity-planning-rulebook @ 00273632123750aa3c5cff608729fa93f042b41
# (capacity-forecast-method/hooks/directive.sh). Each must scan clean
# under both stub-check.sh and compliance-check.sh --canon-duplication.

accessibility_repo="$td/accessibility-rulebook"
mkdir -p "$accessibility_repo/hooks"
cat > "$accessibility_repo/hooks/directive.sh" <<'DIRECTIVE_EOF'
#!/usr/bin/env bash
# SessionStart: WCAG-EM per-facet directive, layered ADDITIONALLY on top of
# accessibility/hooks/directive.sh's own core_role_directive call (per
# docs/issue-7/proposals/methodology-enforcement.md section 1: "composes
# alongside via hooks.json ordering" option). This script does NOT call
# core_role_directive and does NOT replace accessibility's SessionStart
# hook -- it is a second, independent SessionStart hook registered by this
# plugin's own hooks/hooks.json.
#
# Kill switch: WCAG_EM_DIRECTIVE_OFF=1 (case handling mirrors
# core/hooks/lib/role-directive.sh's off_val pattern).
case "${WCAG_EM_DIRECTIVE_OFF:-}" in ""|0|false|no|off) ;; *) exit 0 ;; esac

# This plugin's directive text is WCAG-EM/accessibility-specific: no-op
# silently for any other role.
[ "${CLAUDE_SKILL:-}" = "accessibility" ] || exit 0

cat <<'EOF'
[wcag-em-directive] WCAG-EM methodology directive (layered on accessibility's own SessionStart directive):

PHASE 1 FACET (pre-record scoping):

Applies whenever this role is asked to scope or plan an evaluation before
writing the record itself (e.g., deciding what a token-set change's
evaluation should cover).

1. Step: state the scope constraint verbatim from the triggering change
   (which screens/components/token sets, per USE_WHEN: "신규 인터랙션
   패턴·색상 토큰 도입 시") before doing anything else.
   - Judgment criterion: if the triggering change's boundary is ambiguous
     (e.g., a token change with unclear downstream component reach), the
     scope statement must say so explicitly rather than guessing a
     boundary.
   - Prohibition: do not begin per-criterion evaluation before scope is
     written down. Evaluating first and writing scope after inverts
     WCAG-EM's own order and hides what was silently excluded.

2. Step: identify the interaction pattern(s)/token(s) actually under
   evaluation (WCAG-EM's "explore target" step) and name which WCAG
   success criteria are even reachable for this kind of change (e.g., a
   pure color-token change reaches contrast/visual-indicator SCs, not
   keyboard-operability SCs).
   - Judgment criterion: a criterion is "in scope" if the change could
     plausibly affect it, not only if it obviously does -- err toward
     including a criterion and marking it not-applicable with a scope
     note over silently omitting it.
   - Prohibition: do not narrow the criterion set to "the ones I already
     know how to test" -- that optimizes for evaluator convenience over
     WCAG-EM's own reachability standard.

3. Step: if scope spans more than one screen/state, name the
   representative sample and the reason it's representative; if scope is
   already a single screen/token set, write one line stating that and
   skip sampling -- do not pad a single-item scope with a sampling
   justification it doesn't need.
   - Prohibition: do not sample without stating representativeness -- an
     unstated sample is indistinguishable from an arbitrary one.

PHASE 2 FACET (the evaluation record):

1. Step: evaluate each in-scope criterion using more than one technique
   where applicable -- automated + manual inspection at minimum; add
   assistive-technology or functional testing when the pattern is
   interaction-heavy (custom widgets, focus management, dynamic content).
   - Judgment criterion: "interaction-heavy" means the pattern accepts
     keyboard/pointer/AT input beyond passive display -- a static color
     token change is not interaction-heavy; a custom combobox is.
   - Prohibition: do not mark a criterion pass on automated-scan evidence
     alone when the criterion is one automated tooling cannot fully verify
     (e.g., 1.3.1 Info and Relationships on custom widgets, 2.1.1
     Keyboard on interactive components) -- the evidence field must name
     a technique actually capable of verifying that criterion.

2. Step: for each entry, populate all six fields -- criterion (SC id +
   name), level (A/AA/AAA), verdict (pass/fail/not-applicable), evidence
   (technique used), remediation (required if verdict: fail), scope note
   (required if verdict: not-applicable).
   - Prohibition: a fail verdict with an empty remediation, or a
     not-applicable verdict with an empty scope note, is an incomplete
     entry -- do not submit the record in this state. (This prohibition
     is what wcag-em-gate turns into a mechanical check, closing the open
     question issue-1 phase 2 left unresolved.)

3. Step: write the record-level scope and sample fields (carried forward
   from the phase-1 facet's outputs 1 and 3) at the top of the record,
   before the per-criterion entries.
   - Prohibition: do not leave scope/sample implicit in the per-criterion
     entries -- a reader must be able to answer "what was NOT tested"
     from the record-level fields alone, without inferring it from the
     checklist's absences.

4. Step: apply the boundary-case discipline already in HAND_OFF -- if the
   work drifts into copy/content understandability, stop and hand off to
   content-design per the arrow; record the hand-off point in this record
   before opening the next role's session.
EOF
DIRECTIVE_EOF
out_stub="$("$HERE/stub-check.sh" "$accessibility_repo" 2>&1)"
rc_stub=$?
report 0 "$rc_stub" "real accessibility custom directive.sh exits 0 under stub-check.sh"
case "$out_stub" in
  *"FAIL"*) report "no-fail" "fail-present" "real accessibility custom directive.sh not flagged by stub-check.sh" ;;
  *) report "no-fail" "no-fail" "real accessibility custom directive.sh not flagged by stub-check.sh" ;;
esac
out_cc="$("$HERE/compliance-check.sh" --canon-duplication "$accessibility_repo" 2>&1)"
rc_cc=$?
report 0 "$rc_cc" "real accessibility custom directive.sh exits 0 under --canon-duplication"
case "$out_cc" in
  *"vendored copy"*directive.sh*) report "no-vendored-flag" "vendored-flag-present" "real accessibility custom directive.sh not flagged as vendored copy" ;;
  *) report "no-vendored-flag" "no-vendored-flag" "real accessibility custom directive.sh not flagged as vendored copy" ;;
esac

localization_repo="$td/localization-rulebook"
mkdir -p "$localization_repo/hooks"
cat > "$localization_repo/hooks/directive.sh" <<'DIRECTIVE_EOF'
#!/usr/bin/env bash
# SessionStart directive for localization-mqm-tagging.
# Kill switch: export LOCALIZATION_MQM_TAGGING_DIRECTIVE_OFF=1
set -uo pipefail

case "${LOCALIZATION_MQM_TAGGING_DIRECTIVE_OFF:-}" in
  ""|0|false|no|off) ;;
  *) exit 0 ;;
esac

[ "${CLAUDE_SKILL:-}" = "localization" ] || exit 0

cat <<'EOF'
[localization-mqm-tagging] issue-1 (b)-2 MQM 8-dimension 축소 채용 분류:

REQUIRES: docs/issue-<n>/reports/localization.md의 terminal 쓰기에서
string-external 문제로 지목한 각 항목은 아래 8대 카테고리 중 하나로
태깅되어야 한다(태그는 해당 불릿/항목에 인접 — 문서 전체 아무 곳이
아니다):
  Accuracy / Fluency / Terminology / Locale convention / Style /
  Verity / Design / Internationalization

SCOPE 한정: MQM의 100+ 세부 issue type 체계는 채택하지 않는다 — 위 8개
top-level 카테고리까지만 채택 범위다. 세부 하위분류를 요구하지 않는다.
EOF
DIRECTIVE_EOF
out_stub="$("$HERE/stub-check.sh" "$localization_repo" 2>&1)"
rc_stub=$?
report 0 "$rc_stub" "real localization custom directive.sh exits 0 under stub-check.sh"
case "$out_stub" in
  *"FAIL"*) report "no-fail" "fail-present" "real localization custom directive.sh not flagged by stub-check.sh" ;;
  *) report "no-fail" "no-fail" "real localization custom directive.sh not flagged by stub-check.sh" ;;
esac
out_cc="$("$HERE/compliance-check.sh" --canon-duplication "$localization_repo" 2>&1)"
rc_cc=$?
report 0 "$rc_cc" "real localization custom directive.sh exits 0 under --canon-duplication"
case "$out_cc" in
  *"vendored copy"*directive.sh*) report "no-vendored-flag" "vendored-flag-present" "real localization custom directive.sh not flagged as vendored copy" ;;
  *) report "no-vendored-flag" "no-vendored-flag" "real localization custom directive.sh not flagged as vendored copy" ;;
esac

capacity_repo="$td/capacity-planning-rulebook"
mkdir -p "$capacity_repo/hooks"
cat > "$capacity_repo/hooks/directive.sh" <<'DIRECTIVE_EOF'
#!/usr/bin/env bash
__fc(){ rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then echo "directive.sh: fail-closed: aborted (rc=$rc)" >&2; exit 0; fi; }
trap __fc EXIT
# SessionStart addition — forecast-method methodology framing. Not a
# second core_role_directive stub (that positional call stays solely in
# the base capacity-planning plugin); this only prints phase-1 framing
# text so it shows up in session context. Non-blocking: a print, not a
# gate, so it always exits 0 on a normal run.
set -uo pipefail

cat <<'EOF'
[capacity-forecast-method] Forecast-method selection framing (phase-1 proposal only):

- Classify the workload's demand shape first: steady/organic growth, a
  specific scenario/inorganic event, or seasonality/campaign-driven —
  with the evidence (time series, event calendar, campaign schedule)
  behind the classification. Per SRE book "Capacity Planning" chapter.
- Pick the method the shape calls for: linear/exponential regression
  trend fit (steady organic growth); Holt-Winters exponential smoothing
  or ARIMA (seasonality/campaign-driven demand); scenario/queueing
  modeling (a specific inorganic event) — or an explicitly justified
  alternative under a literal `대안:`/`alternative:` marker.
- State the pick with substantive justification tied to the shape
  classification, not a bare keyword.
- If a prior forecast exists for the same subject, compare
  forecast-vs-actual: a divergence is a model-instability signal to
  flag, never silently overwrite.
- A mechanical backstop (hooks/forecast-method-gate.sh) checks the
  keyword/justification/shape-link on write, but it is a heuristic, not
  a substitute for judgment.
EOF
DIRECTIVE_EOF
out_stub="$("$HERE/stub-check.sh" "$capacity_repo" 2>&1)"
rc_stub=$?
report 0 "$rc_stub" "real capacity-planning custom directive.sh exits 0 under stub-check.sh"
case "$out_stub" in
  *"FAIL"*) report "no-fail" "fail-present" "real capacity-planning custom directive.sh not flagged by stub-check.sh" ;;
  *) report "no-fail" "no-fail" "real capacity-planning custom directive.sh not flagged by stub-check.sh" ;;
esac
out_cc="$("$HERE/compliance-check.sh" --canon-duplication "$capacity_repo" 2>&1)"
rc_cc=$?
report 0 "$rc_cc" "real capacity-planning custom directive.sh exits 0 under --canon-duplication"
case "$out_cc" in
  *"vendored copy"*directive.sh*) report "no-vendored-flag" "vendored-flag-present" "real capacity-planning custom directive.sh not flagged as vendored copy" ;;
  *) report "no-vendored-flag" "no-vendored-flag" "real capacity-planning custom directive.sh not flagged as vendored copy" ;;
esac

echo
echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
