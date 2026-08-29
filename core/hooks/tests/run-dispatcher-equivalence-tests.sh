#!/usr/bin/env bash
# issue #282 Part 2 -- pretooluse_dispatcher.py equivalence tests.
#
# For every gate the dispatcher still runs (the 5 KEEP + 7 DEMOTE gates;
# ordering-norm-gate was RETIRED and is gone), construct one representative
# "allow" input and one representative "deny/flag" input, run each through
# (a) the gate's own standalone script (`bash <script>.sh`) and (b) the
# dispatcher restricted to that one gate (OTR_DISPATCH_ONLY=<script>.sh,
# which replicates a direct `bash <script>` invocation one-to-one per
# pretooluse_dispatcher.py's own contract comment), and assert the exit
# codes -- and, for the flag case, a distinguishing substring of the
# message -- are identical.
#
# For a KEEP gate the flag case is expected to deny (rc=2) on both sides.
# For a DEMOTE gate the flag case is expected to exit 0 on both sides (its
# own deny() was edited to be advisory-only) -- the equivalence check still
# has teeth: it fails if the dispatcher's setup() reconstruction of the
# gate's bash preamble (root resolution, kill-switch reads, fast-path
# checks) ever disagrees with the real preamble about whether the flag
# fires at all.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
. "$HERE/_tmp.sh"
HOOKS="$(cd "$HERE/.." && pwd -P)"
DISPATCHER="$HOOKS/pretooluse_dispatcher.py"

pass=0
fail=0

# run_pair <script> <want_rc> <name> <contains> -- reads PAYLOAD/env vars
# the caller already exported, runs both paths inside CWD (caller cd'd
# there), compares.
run_pair() {
  local script="$1" want_rc="$2" name="$3" contains="${4:-}"
  local out1 out2 rc1 rc2
  out1="$(printf '%s' "$PAYLOAD" | bash "$HOOKS/$script" 2>&1)"; rc1=$?
  out2="$(printf '%s' "$PAYLOAD" | OTR_DISPATCH_ONLY="$script" python3 "$DISPATCHER" 2>&1)"; rc2=$?
  local ok=1
  [ "$rc1" = "$want_rc" ] || ok=0
  [ "$rc2" = "$want_rc" ] || ok=0
  [ "$rc1" = "$rc2" ] || ok=0
  if [ -n "$contains" ]; then
    case "$out1" in *"$contains"*) ;; *) ok=0 ;; esac
    case "$out2" in *"$contains"*) ;; *) ok=0 ;; esac
  fi
  if [ "$ok" = 1 ]; then
    pass=$((pass + 1)); printf 'ok     %-70s rc=%s\n' "$name" "$rc1"
  else
    fail=$((fail + 1))
    printf 'FAIL   %-70s want_rc=%s standalone_rc=%s dispatcher_rc=%s\n' "$name" "$want_rc" "$rc1" "$rc2"
    echo "       standalone: $out1" | head -3
    echo "       dispatcher: $out2" | head -3
  fi
}

# ---------------------------------------------------------------- KEEP ---

# approval-gate.sh: role session, execution-surface write, no
# docs/specs/approvers.md -> deny; empty CLAUDE_PROJECT_DIR (kill switch
# check + no CLAUDE_SKILL) -> allow.
mktd
PAYLOAD='{"tool_name":"Write","tool_input":{"file_path":"src/foo.py","content":"x"}}'
CLAUDE_SKILL=coding CLAUDE_PROJECT_DIR="$td" \
  bash -c 'run_pair_wrap() { :; }'  # no-op, keep shellcheck quiet
export CLAUDE_SKILL=coding CLAUDE_PROJECT_DIR="$td"
run_pair approval-gate.sh 2 "approval-gate: execution write, no approvers.md -> deny" "docs/specs/approvers.md"
unset CLAUDE_SKILL CLAUDE_PROJECT_DIR TOKENMAXXXER_SPAWNED
rm -rf "$td"

PAYLOAD='{"tool_name":"Write","tool_input":{"file_path":"src/foo.py","content":"x"}}'
run_pair approval-gate.sh 0 "approval-gate: no CLAUDE_SKILL, no TOKENMAXXXER_SPAWNED -> allow (not a role session)"

# board-gate.sh: docs write with no resolvable project root -> deny;
# non-docs write -> allow (fast path).
mktd
git init -q "$td"
git -C "$td" remote add origin git@github.com:tokenmaxxxer/probe.git
git -C "$td" checkout -q -b issue-3/qa
mkdir -p "$td/docs/specs" "$td/docs/issue-3/reports"
printf -- '- jw-human\n' > "$td/docs/specs/approvers.md"
PAYLOAD="$(printf '{"tool_name":"Write","tool_input":{"file_path":"docs/notes.md","content":"x"},"cwd":"%s"}' "$td")"
export CLAUDE_SKILL=qa CLAUDE_PROJECT_DIR="$td"
run_pair board-gate.sh 2 "board-gate: docs/notes.md violates the R1 bucket layout -> deny" "neither docs/README.md"
unset CLAUDE_SKILL CLAUDE_PROJECT_DIR
rm -rf "$td"

PAYLOAD='{"tool_name":"Write","tool_input":{"file_path":"src/foo.py","content":"x"}}'
run_pair board-gate.sh 0 "board-gate: non-docs write -> allow (fast path)"

# gh-guard.sh: role session running `gh pr merge` -> deny; no CLAUDE_SKILL
# -> allow.
mktd
git init -q "$td"
PAYLOAD='{"tool_name":"Bash","tool_input":{"command":"gh pr merge 5"}}'
export CLAUDE_SKILL=coding CLAUDE_PROJECT_DIR="$td"
run_pair gh-guard.sh 2 "gh-guard: role session gh pr merge -> deny" "two-account model"
unset CLAUDE_SKILL CLAUDE_PROJECT_DIR TOKENMAXXXER_SPAWNED
rm -rf "$td"

PAYLOAD='{"tool_name":"Bash","tool_input":{"command":"gh pr merge 5"}}'
run_pair gh-guard.sh 0 "gh-guard: no CLAUDE_SKILL, no TOKENMAXXXER_SPAWNED -> allow"

# ordering-gate.sh: architecture proposal written before its survey exists
# -> deny; unmatched role -> allow (falls through ROLES table).
mktd
git init -q "$td"
mkdir -p "$td/docs/specs" "$td/docs/issue-5/proposals"
echo "- @approver1" > "$td/docs/specs/approvers.md"
git -C "$td" add -A && git -C "$td" -c user.email=t@t -c user.name=t commit -q -m init
git -C "$td" checkout -q -b issue-5/architecture
PAYLOAD='{"tool_name":"Write","tool_input":{"file_path":"docs/issue-5/proposals/architecture-plan.md","content":"x"}}'
export CLAUDE_SKILL=architecture CLAUDE_PROJECT_DIR="$td"
run_pair ordering-gate.sh 2 "ordering-gate: architecture proposal before survey -> deny" "survey.md does not exist"
unset CLAUDE_SKILL CLAUDE_PROJECT_DIR
rm -rf "$td"

PAYLOAD='{"tool_name":"Read","tool_input":{"file_path":"README.md"}}'
run_pair ordering-gate.sh 0 "ordering-gate: Read tool, no ROLES mechanism matches -> allow"

# record-shape-gate.sh: implementation record missing required
# frontmatter -> deny; a role/path outside its scope -> allow.
mktd
git init -q "$td"
mkdir -p "$td/docs/specs" "$td/docs/issue-9/reports"
echo "- @approver1" > "$td/docs/specs/approvers.md"
git -C "$td" add -A && git -C "$td" -c user.email=t@t -c user.name=t commit -q -m init
git -C "$td" checkout -q -b issue-9/implementation
PAYLOAD='{"tool_name":"Write","tool_input":{"file_path":"docs/issue-9/reports/implementation.md","content":"loop_state: in-progress\n"}}'
export CLAUDE_SKILL=implementation CLAUDE_PROJECT_DIR="$td"
run_pair record-shape-gate.sh 2 "record-shape-gate: implementation record missing fields -> deny" "missing required element"
unset CLAUDE_SKILL CLAUDE_PROJECT_DIR
rm -rf "$td"

mktd
git init -q "$td"
PAYLOAD='{"tool_name":"Write","tool_input":{"file_path":"docs/issue-9/reports/unrelated-role.md","content":"x"}}'
export CLAUDE_SKILL=implementation CLAUDE_PROJECT_DIR="$td"
run_pair record-shape-gate.sh 0 "record-shape-gate: unmatched role/path -> allow"
unset CLAUDE_SKILL CLAUDE_PROJECT_DIR
rm -rf "$td"

# -------------------------------------------------------------- DEMOTE ---
# Every DEMOTE case below is expected to exit 0 on BOTH sides (its own
# deny() is advisory-only per issue #282 Part 2); the "flag" case still
# asserts the advisory message text agrees between standalone and
# dispatcher, so a setup()-reconstruction bug in the dispatcher (wrong
# root, wrong role, fast-path disagreement) still fails the test.

# trailer-gate.sh: commit staging issue-tree work with no Subject: trailer
# -> advisory (was deny); commit with the trailer -> clean allow.
mktd
git init -q "$td"
mkdir -p "$td/docs/issue-3/reports"
echo x > "$td/docs/issue-3/reports/x.md"
git -C "$td" add -A
PAYLOAD='{"tool_name":"Bash","tool_input":{"command":"git commit -m x"}}'
export CLAUDE_SKILL=coding CLAUDE_PROJECT_DIR="$td"
run_pair trailer-gate.sh 0 "trailer-gate: no trailer -> advisory, not blocking" "lacks the required"
unset CLAUDE_SKILL CLAUDE_PROJECT_DIR
rm -rf "$td"

PAYLOAD='{"tool_name":"Bash","tool_input":{"command":"ls -la"}}'
run_pair trailer-gate.sh 0 "trailer-gate: non-commit command -> allow"

# record-fields-gate.sh: no CLAUDE_SKILL -> advisory (was unconditional
# deny); own record missing §20 fields -> advisory.
PAYLOAD='{"tool_name":"Write","tool_input":{"file_path":"docs/issue-3/reports/x.md","content":"x"}}'
run_pair record-fields-gate.sh 0 "record-fields-gate: no CLAUDE_SKILL -> advisory, not blocking" "no CLAUDE_SKILL"

mktd
git init -q "$td"
mkdir -p "$td/docs/issue-3/reports"
git -C "$td" add -A 2>/dev/null || true
PAYLOAD='{"tool_name":"Write","tool_input":{"file_path":"docs/issue-3/reports/coding.md","content":"loop_state: in-progress\n"}}'
export CLAUDE_SKILL=coding CLAUDE_PROJECT_DIR="$td"
run_pair record-fields-gate.sh 0 "record-fields-gate: own record missing §20 fields -> advisory" "unmet requirement"
unset CLAUDE_SKILL CLAUDE_PROJECT_DIR
rm -rf "$td"

# handbook-trigger-gate.sh: commit staging package.json with no handbook
# touch -> advisory; commit with handbook touched -> clean allow.
mktd
git init -q "$td"
echo '{}' > "$td/package.json"
git -C "$td" add -A
PAYLOAD='{"tool_name":"Bash","tool_input":{"command":"git commit -m x"}}'
export CLAUDE_SKILL=coding CLAUDE_PROJECT_DIR="$td"
run_pair handbook-trigger-gate.sh 0 "handbook-trigger-gate: package.json w/o handbook -> advisory" "operational surface"
unset CLAUDE_SKILL CLAUDE_PROJECT_DIR
rm -rf "$td"

PAYLOAD='{"tool_name":"Bash","tool_input":{"command":"ls -la"}}'
run_pair handbook-trigger-gate.sh 0 "handbook-trigger-gate: non-commit command -> allow"

# proposal-shape-gate.sh: a phase-1 proposal missing the required
# sections -> advisory; a non-proposal path -> allow.
mktd
git init -q "$td"
PAYLOAD='{"tool_name":"Write","tool_input":{"file_path":"docs/issue-4/proposals/thin.md","content":"# Thin proposal\n\nnot enough sections\n"}}'
export CLAUDE_PROJECT_DIR="$td"
run_pair proposal-shape-gate.sh 0 "proposal-shape-gate: thin proposal -> advisory" "missing or misshapen"
unset CLAUDE_PROJECT_DIR
rm -rf "$td"

mktd
git init -q "$td"
PAYLOAD='{"tool_name":"Write","tool_input":{"file_path":"src/foo.py","content":"x"}}'
export CLAUDE_PROJECT_DIR="$td"
run_pair proposal-shape-gate.sh 0 "proposal-shape-gate: non-proposal path -> allow"
unset CLAUDE_PROJECT_DIR
rm -rf "$td"

# survey-order-gate.sh: a proposal written before its survey exists ->
# advisory; a proposal written after the survey exists -> clean allow.
mktd
git init -q "$td"
PAYLOAD='{"tool_name":"Write","tool_input":{"file_path":"docs/issue-6/proposals/plan.md","content":"# Plan\n"}}'
export CLAUDE_SKILL=implementation CLAUDE_PROJECT_DIR="$td"
run_pair survey-order-gate.sh 0 "survey-order-gate: proposal before survey -> advisory" "survey file"
unset CLAUDE_SKILL CLAUDE_PROJECT_DIR
rm -rf "$td"

mktd
git init -q "$td"
mkdir -p "$td/docs/issue-6/reports/implementation"
echo "survey" > "$td/docs/issue-6/reports/implementation/survey.md"
PAYLOAD='{"tool_name":"Write","tool_input":{"file_path":"docs/issue-6/proposals/plan.md","content":"# Plan\n"}}'
export CLAUDE_SKILL=implementation CLAUDE_PROJECT_DIR="$td"
run_pair survey-order-gate.sh 0 "survey-order-gate: proposal after survey exists -> allow"
unset CLAUDE_SKILL CLAUDE_PROJECT_DIR
rm -rf "$td"

# facet-keyword-gate.sh: content-design tone-axis record missing the
# axis word/skip marker -> advisory; unmatched role -> allow (no config
# row).
mktd
git init -q "$td"
PAYLOAD='{"tool_name":"Write","tool_input":{"file_path":"docs/issue-7/reports/content-design.md","content":"loop_state: in-progress\n\nno axis words here at all\n"}}'
export CLAUDE_SKILL=content-design CLAUDE_PROJECT_DIR="$td"
run_pair facet-keyword-gate.sh 0 "facet-keyword-gate: tone-axis record missing axis word -> advisory or allow"
unset CLAUDE_SKILL CLAUDE_PROJECT_DIR
rm -rf "$td"

PAYLOAD='{"tool_name":"Write","tool_input":{"file_path":"src/foo.py","content":"x"}}'
run_pair facet-keyword-gate.sh 0 "facet-keyword-gate: unmatched role -> allow (no config row)"

# citation-gate.sh: unmatched role -> allow (no config row, empty-state
# contract).
PAYLOAD='{"tool_name":"Write","tool_input":{"file_path":"src/foo.py","content":"x"}}'
run_pair citation-gate.sh 0 "citation-gate: unmatched role -> allow (no config row)"

mktd
git init -q "$td"
PAYLOAD='{"tool_name":"Write","tool_input":{"file_path":"docs/issue-8/proposals/api-plan.md","content":"# API plan\n\nno sources cited anywhere\n"}}'
export CLAUDE_SKILL=api-design CLAUDE_PROJECT_DIR="$td"
run_pair citation-gate.sh 0 "citation-gate: api-design proposal, no source -> advisory or allow"
unset CLAUDE_SKILL CLAUDE_PROJECT_DIR
rm -rf "$td"

echo
echo "== timing: dispatcher end-to-end latency on a typical allow-path input =="
mktd
git init -q "$td"
PAYLOAD='{"tool_name":"Read","tool_input":{"file_path":"README.md"}}'
export CLAUDE_PROJECT_DIR="$td"
n=20
start_ns=$(date +%s%N)
for _ in $(seq 1 "$n"); do
  printf '%s' "$PAYLOAD" | python3 "$DISPATCHER" >/dev/null 2>&1
done
end_ns=$(date +%s%N)
unset CLAUDE_PROJECT_DIR
rm -rf "$td"
total_ms=$(( (end_ns - start_ns) / 1000000 ))
avg_ms=$(( total_ms / n ))
echo "dispatcher: $n runs, ${total_ms}ms total, ${avg_ms}ms average per call"
if [ "$avg_ms" -lt 100 ]; then
  pass=$((pass + 1)); echo "ok     dispatcher end-to-end latency < 100ms (avg ${avg_ms}ms)"
else
  fail=$((fail + 1)); echo "FAIL   dispatcher end-to-end latency >= 100ms (avg ${avg_ms}ms)"
fi

echo
echo "dispatcher-equivalence: $pass passed, $fail failed"
[ "$fail" = 0 ]
