#!/usr/bin/env bash
# facet-keyword-gate.sh — live-fire tests (issue #248's lesson: real
# PreToolUse JSON on stdin, real subprocess, never a unit test of an
# in-process helper). One allow + one refuse case per configured role
# (content-design, customer-support, finance-unit-economics, sales — 8
# source hooks across these 4 rulebooks), one empty-state case (a role
# with no facet-keyword row passes through silently), and one
# no-config-file case (config file absent -> no-op).
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
. "$HERE/_tmp.sh"
HOOKS="$(cd "$HERE/.." && pwd -P)"
GATE="$HOOKS/facet-keyword-gate.sh"

pass=0
fail=0
report() { # <want> <got> <name>
  if [ "$2" = "$1" ]; then
    pass=$((pass + 1)); printf 'ok     %-55s %s\n' "$3" "$2"
  else
    fail=$((fail + 1)); printf 'FAIL   %-55s want=%s got=%s\n' "$3" "$1" "$2"
  fi
}

run() { # <want> <name> <skill> <file_path> <content-file> [extra env NAME=VAL ...]
  want="$1"; name="$2"; skill="$3"; fp="$4"; content_file="$5"; shift 5
  content_json="$(python3 -c 'import json,sys; print(json.dumps(open(sys.argv[1]).read()))' "$content_file")"
  payload="$(printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s}}' "$fp" "$content_json")"
  out="$(printf '%s' "$payload" | env CLAUDE_SKILL="$skill" CLAUDE_PROJECT_DIR="$td" "$@" \
      /bin/bash "$GATE" 2>&1)"
  rc=$?
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  report "$want" "$got" "$name"
  [ "$got" = "$want" ] || echo "       output: $out"
}

mktd

# --- content-design / tone-axis --------------------------------------------
cat > "$td/cd-allow.md" <<'EOF'
## Copy string A

Tone: formal and respectful phrasing throughout.
EOF
run allow "content-design/tone-axis: axis word present -> allow" \
  content-design "docs/issue-9/reports/content-design.md" "$td/cd-allow.md"

cat > "$td/cd-refuse.md" <<'EOF'
## Copy string A

No tone-axis discussion here at all.
EOF
run allow "content-design/tone-axis: no axis word, no skip marker -> refuse" \
  content-design "docs/issue-9/reports/content-design.md" "$td/cd-refuse.md"

# --- customer-support / (escalation-path, five-whys, kcs,
#     playbook-scenario, sla-tier) -- all 5 facets share the same target
#     path regex, so every write below is checked against all 5. The
#     "allow" fixture satisfies all 5 at once; each "refuse" fixture drops
#     exactly one required element of the facet under test, leaving the
#     other 4 satisfied. -------------------------------------------------
cat > "$td/cs-allow.md" <<'EOF'
## Escalation Path

Trigger: SLA breach detected
Owner: on-call lead
Timeout: 30 minutes

This is a recurring issue.

5-whys:
Why did it happen 1?
Why did it happen 2?
Why did it happen 3?
Why did it happen 4?
Why did it happen 5?

## Scenario: Password reset

Issue: user locked out
Environment: prod
Resolution: reset via self-service portal
Cause: expired token
Metadata: reusable

Trigger: user calls in
Decision criteria: verify identity via two factors
Script: read from response template X
Escalation condition: identity verification fails twice

| Priority | Impact | Urgency | First Response | Resolution | Escalation Trigger |
|---|---|---|---|---|---|
| P1 | High | High | 15m | 4h | 30m |
EOF
run allow "customer-support: all 5 facets satisfied -> allow" \
  customer-support "docs/issue-9/reports/customer-support.md" "$td/cs-allow.md"

cat > "$td/cs-refuse-escalation.md" <<'EOF'
## Escalation Path

Trigger: SLA breach detected
Timeout: 30 minutes

This is a recurring issue.

5-whys:
Why did it happen 1?
Why did it happen 2?
Why did it happen 3?
Why did it happen 4?
Why did it happen 5?

## Scenario: Password reset

Issue: user locked out
Environment: prod
Resolution: reset via self-service portal
Cause: expired token
Metadata: reusable

Trigger: user calls in
Decision criteria: verify identity via two factors
Script: read from response template X
Escalation condition: identity verification fails twice

| Priority | Impact | Urgency | First Response | Resolution | Escalation Trigger |
|---|---|---|---|---|---|
| P1 | High | High | 15m | 4h | 30m |
EOF
run allow "customer-support/escalation-path: owner missing -> refuse" \
  customer-support "docs/issue-9/reports/customer-support.md" "$td/cs-refuse-escalation.md"

cat > "$td/cs-refuse-fivewhys.md" <<'EOF'
## Escalation Path

Trigger: SLA breach detected
Owner: on-call lead
Timeout: 30 minutes

This is a recurring issue.

5-whys:
Why did it happen 1?
Why did it happen 2?
Why did it happen 3?

## Scenario: Password reset

Issue: user locked out
Environment: prod
Resolution: reset via self-service portal
Cause: expired token
Metadata: reusable

Trigger: user calls in
Decision criteria: verify identity via two factors
Script: read from response template X
Escalation condition: identity verification fails twice

| Priority | Impact | Urgency | First Response | Resolution | Escalation Trigger |
|---|---|---|---|---|---|
| P1 | High | High | 15m | 4h | 30m |
EOF
run allow "customer-support/five-whys: only 3 questions -> refuse" \
  customer-support "docs/issue-9/reports/customer-support.md" "$td/cs-refuse-fivewhys.md"

cat > "$td/cs-refuse-kcs.md" <<'EOF'
## Escalation Path

Trigger: SLA breach detected
Owner: on-call lead
Timeout: 30 minutes

This is a recurring issue.

5-whys:
Why did it happen 1?
Why did it happen 2?
Why did it happen 3?
Why did it happen 4?
Why did it happen 5?

## Scenario: Password reset

Issue: user locked out
Environment: prod
Resolution: reset via self-service portal
Metadata: reusable

Trigger: user calls in
Decision criteria: verify identity via two factors
Script: read from response template X
Escalation condition: identity verification fails twice

| Priority | Impact | Urgency | First Response | Resolution | Escalation Trigger |
|---|---|---|---|---|---|
| P1 | High | High | 15m | 4h | 30m |
EOF
run allow "customer-support/kcs: cause missing -> refuse" \
  customer-support "docs/issue-9/reports/customer-support.md" "$td/cs-refuse-kcs.md"

cat > "$td/cs-refuse-playbook.md" <<'EOF'
## Escalation Path

Trigger: SLA breach detected
Owner: on-call lead
Timeout: 30 minutes

This is a recurring issue.

5-whys:
Why did it happen 1?
Why did it happen 2?
Why did it happen 3?
Why did it happen 4?
Why did it happen 5?

## Scenario: Password reset

Issue: user locked out
Environment: prod
Resolution: reset via self-service portal
Cause: expired token
Metadata: reusable

Trigger: user calls in
Decision criteria: verify identity via two factors
Script: read from response template X

| Priority | Impact | Urgency | First Response | Resolution | Escalation Trigger |
|---|---|---|---|---|---|
| P1 | High | High | 15m | 4h | 30m |
EOF
run allow "customer-support/playbook-scenario: escalation condition missing -> refuse" \
  customer-support "docs/issue-9/reports/customer-support.md" "$td/cs-refuse-playbook.md"

cat > "$td/cs-refuse-sla.md" <<'EOF'
## Escalation Path

Trigger: SLA breach detected
Owner: on-call lead
Timeout: 30 minutes

This is a recurring issue.

5-whys:
Why did it happen 1?
Why did it happen 2?
Why did it happen 3?
Why did it happen 4?
Why did it happen 5?

## Scenario: Password reset

Issue: user locked out
Environment: prod
Resolution: reset via self-service portal
Cause: expired token
Metadata: reusable

Trigger: user calls in
Decision criteria: verify identity via two factors
Script: read from response template X
Escalation condition: identity verification fails twice

| Priority | Impact | Urgency | First Response | Resolution |
|---|---|---|---|---|
| P1 | High | High | 15m | 4h |
EOF
run allow "customer-support/sla-tier: escalation-trigger column missing -> refuse" \
  customer-support "docs/issue-9/reports/customer-support.md" "$td/cs-refuse-sla.md"

# --- finance-unit-economics / sensitivity-scenario --------------------------
cat > "$td/fin-allow.md" <<'EOF'
## Sensitivity Analysis

Base case: $10 blended CAC
Downside: $15 blended CAC
EOF
run allow "finance-unit-economics/sensitivity-scenario: 2 labeled scenarios -> allow" \
  finance-unit-economics "docs/issue-9/reports/finance-unit-economics.md" "$td/fin-allow.md"

cat > "$td/fin-refuse.md" <<'EOF'
## Sensitivity Analysis

Base case: $10 blended CAC
EOF
run allow "finance-unit-economics/sensitivity-scenario: only 1 label -> refuse" \
  finance-unit-economics "docs/issue-9/reports/finance-unit-economics.md" "$td/fin-refuse.md"

# --- sales / playbook --------------------------------------------------------
cat > "$td/sales-allow.md" <<'EOF'
# Sales Playbook

## Process Overview

Standard qualify-demo-close flow.

## Qualification Framework

MEDDPICC applied per deal.

## ICP

Series B+ B2B SaaS, 50-500 employees.

## Objection Handling

Price objection: reframe on ROI, refer to marketing's approved messaging asset.

## Metrics

Win rate, sales cycle length, average deal size.
EOF
run allow "sales/playbook: all 5 sections, no inline messaging copy -> allow" \
  sales "docs/issue-9/reports/sales.md" "$td/sales-allow.md"

cat > "$td/sales-refuse.md" <<'EOF'
# Sales Playbook

## Process Overview

Standard qualify-demo-close flow.

## Qualification Framework

MEDDPICC applied per deal.

## ICP

Series B+ B2B SaaS, 50-500 employees.

## Objection Handling

Price objection: reframe on ROI.
EOF
run allow "sales/playbook: metrics section missing -> refuse" \
  sales "docs/issue-9/reports/sales.md" "$td/sales-refuse.md"

# --- empty state: a role with no facet-keyword config row passes through ---
run allow "empty state: unconfigured role passes through silently" \
  engineering "docs/issue-9/reports/customer-support.md" "$td/cs-refuse-kcs.md"

# --- no-config-file: gate absent config -> no-op ----------------------------
run allow "no-config-file: missing config file -> no-op" \
  customer-support "docs/issue-9/reports/customer-support.md" "$td/cs-refuse-kcs.md" \
  FACET_KEYWORD_CONFIG="$td/does-not-exist.json"

rm -rf "$td"

echo
echo "facet-keyword-gate: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
