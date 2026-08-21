#!/usr/bin/env bash
# ordering-norm-gate.sh — live-fire tests (issue #248's lesson: real
# PreToolUse/SessionStart/PostToolUse JSON on stdin, real subprocess,
# never a unit test of an in-process helper). One allow + one refuse case
# per configured mode:gate role (9 gate files), one state-recorded case
# per configured mode:tracker role (6 tracker files), one empty-state case
# (a role with no ordering-norm row passes through silently), and one
# no-config-file case (config file absent -> no-op).
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
. "$HERE/_tmp.sh"
HOOKS="$(cd "$HERE/.." && pwd -P)"
GATE="$HOOKS/ordering-norm-gate.sh"

pass=0
fail=0
report() { # <want> <got> <name>
  if [ "$2" = "$1" ]; then
    pass=$((pass + 1)); printf 'ok     %-70s %s\n' "$3" "$2"
  else
    fail=$((fail + 1)); printf 'FAIL   %-70s want=%s got=%s\n' "$3" "$1" "$2"
  fi
}

run() { # <want> <name> <role> <file_path> <content-file> [extra env NAME=VAL ...]
  want="$1"; name="$2"; role="$3"; fp="$4"; content_file="$5"; shift 5
  content_json="$(python3 -c 'import json,sys; print(json.dumps(open(sys.argv[1]).read()))' "$content_file")"
  payload="$(printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s}}' "$fp" "$content_json")"
  out="$(printf '%s' "$payload" | env CLAUDE_ROLE="$role" CLAUDE_PROJECT_DIR="$td" "$@" \
      /bin/bash "$GATE" 2>&1)"
  rc=$?
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  report "$want" "$got" "$name"
  [ "$got" = "$want" ] || echo "       output: $out"
}

run_event() { # <want> <name> <role> <event> <payload-file> [extra env ...]
  want="$1"; name="$2"; role="$3"; ev="$4"; pf="$5"; shift 5
  out="$(cat "$pf" | env CLAUDE_ROLE="$role" CLAUDE_PROJECT_DIR="$td" CLAUDE_HOOK_EVENT="$ev" "$@" \
      /bin/bash "$GATE" 2>&1)"
  rc=$?
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  report "$want" "$got" "$name"
  [ "$got" = "$want" ] || echo "       output: $out"
}

mktd

# --- issue-retrospective / timeline-order-gate -----------------------------
mkdir -p "$td/docs/issue-9/reports"
cat > "$td/tl-allow.md" <<'EOF'
## Timeline

- 10:00 first symptom observed

## Analysis

contributing factor discussion goes here.
EOF
run allow "issue-retrospective/timeline-order-gate: Timeline before causal -> allow" \
  issue-retrospective "docs/issue-9/reports/issue-retrospective.md" "$td/tl-allow.md"

cat > "$td/tl-refuse.md" <<'EOF'
## Analysis

contributing factor discussion appears before any Timeline section.

## Timeline

- 10:00 first symptom observed
EOF
run deny "issue-retrospective/timeline-order-gate: causal before Timeline -> refuse" \
  issue-retrospective "docs/issue-9/reports/issue-retrospective.md" "$td/tl-refuse.md"

# --- risk-management / erm-order-gate ---------------------------------------
cat > "$td/erm-allow.md" <<'EOF'
## Governance/context

setup

## Assessment

risk-score-inherent: 8
risk-score-residual: 3

## Risk treatment

plan

## Monitoring

cadence
EOF
run allow "risk-management/erm-order-gate: 4 stages in order, distinct scores -> allow" \
  risk-management "docs/issue-9/reports/risk-management.md" "$td/erm-allow.md"

cat > "$td/erm-refuse.md" <<'EOF'
## Assessment

risk-score-inherent: 8
risk-score-residual: 8

## Governance/context

setup

## Risk treatment

plan

## Monitoring

cadence
EOF
run deny "risk-management/erm-order-gate: stages out of order -> refuse" \
  risk-management "docs/issue-9/reports/risk-management.md" "$td/erm-refuse.md"

# --- pr-communications / race-sequence-gate ---------------------------------
cat > "$td/race-allow.md" <<'EOF'
loop_state: landed

## Communications plan

**Research**:
notes

**Action**:
**Objective**: ship the announcement

**Communication**:
**Channel**: #announcements

**Evaluation**:
**Output**: sent
**Outcome**: matches the Action objective above
EOF
run allow "pr-communications/race-sequence-gate: landed + RACE fields -> allow" \
  pr-communications "docs/issue-9/reports/pr-communications.md" "$td/race-allow.md"

cat > "$td/race-refuse.md" <<'EOF'
loop_state: landed

## Communications plan

**Research**:
notes

**Action**:
(no objective stated)

**Communication**:
**Channel**: #announcements

**Evaluation**:
**Output**: sent
**Outcome**: sent
EOF
run deny "pr-communications/race-sequence-gate: landed but missing Objective -> refuse" \
  pr-communications "docs/issue-9/reports/pr-communications.md" "$td/race-refuse.md"

# --- user-discovery / hypothesis-order-gate ---------------------------------
cat > "$td/ud-allow.md" <<'EOF'
## Hypothesis

H1: users want faster checkout

## Evidence

behavioral evidence collected from 5 interviews

## Verdict

pain-confirmed
EOF
run allow "user-discovery/hypothesis-order-gate: evidence before verdict -> allow" \
  user-discovery "docs/issue-9/reports/user-discovery.md" "$td/ud-allow.md"

cat > "$td/ud-refuse.md" <<'EOF'
## Hypothesis

H1: users want faster checkout

## Verdict

pain-confirmed with no evidence section at all
EOF
run deny "user-discovery/hypothesis-order-gate: verdict with no evidence -> refuse" \
  user-discovery "docs/issue-9/reports/user-discovery.md" "$td/ud-refuse.md"

# --- ux-engineering / phase1-structure-gate ---------------------------------
cat > "$td/ux-allow.md" <<'EOF'
# Request
r

# Survey summary
s

# Scout summary
sc

# Adopted norms
a

# Rationale
ra

# Plugin reflection plan
p

# Constraints
c
EOF
run allow "ux-engineering/phase1-structure-gate: 7 sections in order -> allow" \
  ux-engineering "docs/issue-9/proposals/ux-engineering.md" "$td/ux-allow.md"

cat > "$td/ux-refuse.md" <<'EOF'
# Survey summary
s

# Request
r

# Scout summary
sc

# Adopted norms
a

# Rationale
ra

# Plugin reflection plan
p

# Constraints
c
EOF
run deny "ux-engineering/phase1-structure-gate: sections out of order -> refuse" \
  ux-engineering "docs/issue-9/proposals/ux-engineering.md" "$td/ux-refuse.md"

# --- performance-engineering / order-check ----------------------------------
cat > "$td/pe-allow.md" <<'EOF'
## Workload characterization

traffic profile details

## Evidence

benchmark numbers
EOF
run allow "performance-engineering/order-check: workload before evidence -> allow" \
  performance-engineering "docs/issue-9/reports/performance-engineering.md" "$td/pe-allow.md"

cat > "$td/pe-refuse.md" <<'EOF'
## Evidence

benchmark numbers

## Workload characterization

traffic profile details
EOF
run deny "performance-engineering/order-check: evidence before workload -> refuse" \
  performance-engineering "docs/issue-9/reports/performance-engineering.md" "$td/pe-refuse.md"

# --- observability / methodology-selector-gate ------------------------------
cat > "$td/obs-allow.md" <<'EOF'
## Methodology

Signal methodology: RED method (rate/errors/duration)

## Surface classification

This is a request-driven surface.
EOF
run allow "observability/methodology-selector-gate: methodology + surface named -> allow" \
  observability "docs/issue-9/proposals/observability.md" "$td/obs-allow.md"

cat > "$td/obs-refuse.md" <<'EOF'
## Notes

Nothing about signal methodology or surface classification here.
EOF
run deny "observability/methodology-selector-gate: neither named -> refuse" \
  observability "docs/issue-9/proposals/observability.md" "$td/obs-refuse.md"

# --- observability / phase-trace-gate ---------------------------------------
cat > "$td/pt-allow.md" <<'EOF'
We made a deviation because the original plan proved unworkable.
EOF
run allow "observability/phase-trace-gate: deviation with nearby reason -> allow" \
  observability "docs/issue-9/reports/observability.md" "$td/pt-allow.md"

cat > "$td/pt-refuse.md" <<'EOF'
We made a deviation from the plan.

(several paragraphs later, unrelated content, nothing further stated at all about the deviation above, padding padding padding padding padding padding padding padding padding padding padding padding padding padding padding padding padding padding padding padding padding padding padding)
EOF
run deny "observability/phase-trace-gate: deviation with no nearby reason -> refuse" \
  observability "docs/issue-9/reports/observability.md" "$td/pt-refuse.md"

# --- customer-support / phase1-order-gate -----------------------------------
mkdir -p "$td/docs/issue-9/reports/customer-support"
touch "$td/docs/issue-9/reports/customer-support/survey.md"
touch "$td/docs/issue-9/reports/customer-support/scout-brief.md"
cat > "$td/cs-allow.md" <<'EOF'
## SLA

sla target: 4h. see scout-brief.md for detail.

## Escalation

escalation path documented, see scout-brief.md

## Playbook

playbook reference, see scout-brief.md

## Evidence

evidence metric tracked, see scout-brief.md

## Root cause

5-whys applied, see scout-brief.md
EOF
run allow "customer-support/phase1-order-gate: artifacts exist + all claims cited -> allow" \
  customer-support "docs/issue-9/proposals/customer-support.md" "$td/cs-allow.md"

cat > "$td/cs-refuse.md" <<'EOF'
## SLA

sla target: 4h, no citation nearby at all, just padding text with no link or reference of any kind whatsoever in this whole paragraph block.
EOF
run deny "customer-support/phase1-order-gate: uncited sla claim -> refuse" \
  customer-support "docs/issue-9/proposals/customer-support.md" "$td/cs-refuse.md"

# --- empty-state: a role with no ordering-norm row passes through silently -
run allow "empty-state: unconfigured role passes through silently" \
  no-such-role "docs/issue-9/reports/whatever.md" "$td/ux-allow.md"

# --- no-config-file: config file absent -> no-op ----------------------------
run allow "no-config-file: ORDERING_NORM_CONFIG points at nothing -> no-op" \
  risk-management "docs/issue-9/reports/risk-management.md" "$td/erm-refuse.md" \
  ORDERING_NORM_CONFIG="$td/does-not-exist.json"

# --- tracker rows: never deny regardless of content, mode:tracker rows -----
for pair in \
  "conformance-review:SessionStart" \
  "performance-engineering:SessionStart" \
  "execution-observation:SessionStart" \
  "execution-observation:PostToolUse" \
  "observability:PostToolUse" \
  "defect-verification:PostToolUse" \
  "user-discovery:PostToolUse" \
  ; do
  role="${pair%%:*}"; ev="${pair#*:}"
  pf="$td/tracker-$role-$ev.json"
  printf '{"hook_event_name":"%s","tool_name":"Write","tool_input":{"file_path":"docs/issue-9/reports/whatever.md"},"tool_response":{}}' "$ev" > "$pf"
  run_event allow "tracker/$role ($ev): passive state action never denies" "$role" "$ev" "$pf"
done

echo
echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
