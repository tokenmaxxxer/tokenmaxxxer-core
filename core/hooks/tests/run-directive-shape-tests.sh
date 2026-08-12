#!/usr/bin/env bash
# core/hooks/directive.sh's shared interaction-protocol heredoc must name
# three gate-enforced shapes every role currently learns only from a gate
# refusal (issue-204, on-the-record #726 rows 3, 4/14, 20): spec-index
# regeneration before docs/specs/* commits, the phase-1/phase-2 PR-trailer
# split, and pytest SKIPPED/pass-count fidelity.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
HOOKS="$(cd "$HERE/.." && pwd -P)"

pass=0
fail=0
report() { # <want> <got> <name>
  if [ "$2" = "$1" ]; then
    pass=$((pass + 1)); printf 'ok     %-60s %s\n' "$3" "$2"
  else
    fail=$((fail + 1)); printf 'FAIL   %-60s want=%s got=%s\n' "$3" "$1" "$2"
  fi
}

out="$(CLAUDE_ROLE=implementation bash "$HOOKS/directive.sh" 2>/dev/null)"

# Row 3: spec-index regeneration.
spec_index=""
spec_index_bullet="$(printf '%s\n' "$out" | awk '/^- A session that stages a change to any docs\/specs/{p=1} p{print; if (/^- [A-Z]/ && !/^- A session that stages a change to any docs\/specs/) exit}')"
case "$spec_index_bullet" in *"docs/specs/reconciled-index.md"*"spec_index.py --update"*) spec_index=present ;; esac
report present "${spec_index:-absent}" "names spec-index regeneration before docs/specs edits"

# Rows 4/14: Closes/Fixes phase split.
phase_split=""
phase_split_bullet="$(printf '%s\n' "$out" | awk '/^- PR trailer phase split:/{p=1} p{print; if (/^- [A-Z]/ && !/^- PR trailer phase split:/) exit}')"
case "$phase_split_bullet" in *"plain #<issue>"*"Closes/Fixes/Resolves"*"is forbidden"*"phase-2 delivery PR"*) phase_split=present ;; esac
report present "${phase_split:-absent}" "names the Closes/Fixes phase split for non-coding roles"

# Row 20: pytest SKIPPED / pass-count fidelity.
test_claim=""
test_claim_bullet="$(printf '%s\n' "$out" | awk '/^- A reply claiming a clean pytest pass/{p=1} p{print; if (/^- [A-Z]/ && !/^- A reply claiming a clean pytest pass/) exit}')"
case "$test_claim_bullet" in *"SKIPPED lines"*"pass count must equal the"*"pasted summary"*"count"*) test_claim=present ;; esac
report present "${test_claim:-absent}" "names the pytest skip/count fidelity rule"

# empty-state fixtures: a directive text missing each shape must be caught,
# not silently pass.
fake_no_spec_index="- A commit that stages docs/specs/* work must use git commit -m
  and carry a Subject trailer naming the issue."
spec_index_in_fake=""
case "$fake_no_spec_index" in *"spec_index.py --update"*) spec_index_in_fake=1 ;; esac
report absent "${spec_index_in_fake:-absent}" "empty-state fixture (no spec-index rule) has no spec_index.py mention"

fake_no_phase_split="- Reference your issue in the PR body."
phase_split_in_fake=""
case "$fake_no_phase_split" in *"plain #<issue>"*) phase_split_in_fake=1 ;; esac
report absent "${phase_split_in_fake:-absent}" "empty-state fixture (no phase-split rule) has no plain #<issue> mention"

fake_no_test_claim="- Report your test results honestly."
test_claim_in_fake=""
case "$fake_no_test_claim" in *"SKIPPED lines"*) test_claim_in_fake=1 ;; esac
report absent "${test_claim_in_fake:-absent}" "empty-state fixture (no test-claim rule) has no SKIPPED mention"

# bypass-fixture (hunt finding): phrases scattered across two disconnected
# bullets must NOT be accepted as stating the phase-split rule.
disconnected="- Coffee is optional but bagels reference their topping as a
  plain #<issue> on the menu.
- Skateboarding indoors is forbidden except during the phase-2 delivery PR
  celebration party."
disc_bullet="$(printf '%s\n' "$disconnected" | awk '/^- PR trailer phase split:/{p=1} p{print; if (/^- [A-Z]/ && !/^- PR trailer phase split:/) exit}')"
disc_match=""
case "$disc_bullet" in *"plain #<issue>"*"Closes/Fixes/Resolves"*"is forbidden"*"phase-2 delivery PR"*) disc_match=1 ;; esac
report absent "${disc_match:-absent}" "bypass fixture (disconnected bullets) is not accepted as the phase-split rule"

# issue-212: build-now bypass bullet.
build_now=""
build_now_bullet="$(printf '%s\n' "$out" | awk '/^- Build-now bypass/{p=1} p{print; if (/^- [A-Z]/ && !/^- Build-now bypass/) exit}')"
case "$build_now_bullet" in *"CORE_BUILD_NOW=1"*"never by you"*"skip the proposal round"*) build_now=present ;; esac
report present "${build_now:-absent}" "names the build-now bypass and its spawner-only env var"

fake_no_build_now="- Do the work when the human says so."
build_now_in_fake=""
case "$fake_no_build_now" in *"CORE_BUILD_NOW"*) build_now_in_fake=1 ;; esac
report absent "${build_now_in_fake:-absent}" "empty-state fixture (no build-now rule) has no CORE_BUILD_NOW mention"

echo
echo "directive-shape: $pass passed, $fail failed"
[ "$fail" = 0 ]
