#!/usr/bin/env bash
# citation-gate.sh — live-fire tests (issue #248's lesson: real
# PreToolUse JSON on stdin, real subprocess, never a unit test of an
# in-process helper). One allow + one refuse case per configured hook
# (11 hooks across 9 rulebooks), one empty-state case (a role with no
# citation-sourcing row passes through silently), and one no-config-file
# case (config file absent -> no-op).
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
. "$HERE/_tmp.sh"
HOOKS="$(cd "$HERE/.." && pwd -P)"
GATE="$HOOKS/citation-gate.sh"

pass=0
fail=0
report() { # <want> <got> <name>
  if [ "$2" = "$1" ]; then
    pass=$((pass + 1)); printf 'ok     %-65s %s\n' "$3" "$2"
  else
    fail=$((fail + 1)); printf 'FAIL   %-65s want=%s got=%s\n' "$3" "$1" "$2"
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

mktd

# --- api-design / evidence-citation-gate ------------------------------------
cat > "$td/api-allow.md" <<'EOF'
It is standard practice to version APIs via a URL path segment, per RFC 8288.
EOF
run allow "api-design/evidence-citation-gate: RFC marker present -> allow" \
  api-design "docs/issue-9/proposals/api-design.md" "$td/api-allow.md"

cat > "$td/api-refuse.md" <<'EOF'
It is standard practice to version APIs via a URL path segment.
EOF
run deny "api-design/evidence-citation-gate: no source -> refuse" \
  api-design "docs/issue-9/proposals/api-design.md" "$td/api-refuse.md"

# --- architecture / arch-citation-gate --------------------------------------
cat > "$td/arch-allow.md" <<'EOF'
## Choice

This is industry practice. Sources: https://example.com/pattern
EOF
run allow "architecture/arch-citation-gate: URL in same section -> allow" \
  architecture "docs/issue-9/reports/architecture.md" "$td/arch-allow.md"

cat > "$td/arch-refuse.md" <<'EOF'
## Choice

This is industry practice with no citation at all.

## Other

Sources: https://example.com/unrelated
EOF
run deny "architecture/arch-citation-gate: citation in a different section -> refuse" \
  architecture "docs/issue-9/reports/architecture.md" "$td/arch-refuse.md"

# --- capacity-planning / capacity-order-enforcement -------------------------
cat > "$td/cap-allow.md" <<'EOF'
loop_state: terminal

## Rationale

Basis: survey.md and scout-brief.md were both reviewed before this decision.
EOF
run allow "capacity-planning/capacity-order-enforcement: proposal cites both, adjacent -> allow" \
  capacity-planning "docs/issue-9/proposals/capacity-planning.md" "$td/cap-allow.md"

cat > "$td/cap-refuse.md" <<'EOF'
loop_state: terminal

## Rationale

No citation of the upstream documents anywhere near a marker.
EOF
run deny "capacity-planning/capacity-order-enforcement: proposal missing adjacency -> refuse" \
  capacity-planning "docs/issue-9/proposals/capacity-planning.md" "$td/cap-refuse.md"

# --- conformance-review / review-traceability -------------------------------
cat > "$td/cr-allow.md" <<'EOF'
verdict: Present
spec_ref: docs/specs/foo.md
evidence: core/hooks/foo.sh
EOF
run allow "conformance-review/review-traceability: verdict with spec_ref+evidence -> allow" \
  conformance-review "docs/issue-9/reports/conformance-review.md" "$td/cr-allow.md"

cat > "$td/cr-refuse.md" <<'EOF'
verdict: Present
EOF
run deny "conformance-review/review-traceability: verdict missing spec_ref -> refuse" \
  conformance-review "docs/issue-9/reports/conformance-review.md" "$td/cr-refuse.md"

# --- finance-unit-economics / finance-evidence-chain ------------------------
cat > "$td/fin-allow.md" <<'EOF'
CAC is sourced at https://example.com/cac-data.

This is necessary for the mandate to hold (단위경제상 성립).
EOF
run allow "finance-unit-economics/finance-evidence-chain: sourced + mandate chain -> allow" \
  finance-unit-economics "docs/issue-9/proposals/finance-unit-economics.md" "$td/fin-allow.md"

cat > "$td/fin-refuse.md" <<'EOF'
CAC is mentioned here with no source and no mandate chain.
EOF
run deny "finance-unit-economics/finance-evidence-chain: metric with no source -> refuse" \
  finance-unit-economics "docs/issue-9/proposals/finance-unit-economics.md" "$td/fin-refuse.md"

# --- interaction-design / id-citation-format + id-traceability -------------
cat > "$td/id-cf-allow.md" <<'EOF'
- This exemplar pattern is attributed to nn/g research.

## Sources

- https://www.nngroup.com/articles/example
EOF
run allow "interaction-design/id-citation-format: bullet marker + Sources heading -> allow" \
  interaction-design "docs/issue-9/proposals/interaction-design.md" "$td/id-cf-allow.md"

cat > "$td/id-cf-refuse.md" <<'EOF'
- This exemplar pattern is great.
EOF
run deny "interaction-design/id-citation-format: claim bullet with no marker -> refuse" \
  interaction-design "docs/issue-9/proposals/interaction-design.md" "$td/id-cf-refuse.md"

cat > "$td/id-tr-allow.md" <<'EOF'
## Traceability

spec-only boundary maintained.
Scope growth: none
Feedback: confirmation toast shown
EOF
run allow "interaction-design/id-traceability: all 3 fields present -> allow" \
  interaction-design "docs/issue-9/reports/interaction-design.md" "$td/id-tr-allow.md"

cat > "$td/id-tr-refuse.md" <<'EOF'
## Traceability

spec-only boundary maintained.
EOF
run deny "interaction-design/id-traceability: missing scope-growth/feedback -> refuse" \
  interaction-design "docs/issue-9/reports/interaction-design.md" "$td/id-tr-refuse.md"

# --- requirements-engineering / traceability-matrix-gate --------------------
cat > "$td/re-allow.md" <<'EOF'
REQ-1 is discussed here.

## Traceability Matrix

| ID | Description | Source | Downstream Link |
| --- | --- | --- | --- |
| REQ-1 | does a thing | docs/spec.md | not yet linked |
EOF
run allow "requirements-engineering/traceability-matrix-gate: REQ row present -> allow" \
  requirements-engineering "docs/issue-9/reports/requirements-engineering.md" "$td/re-allow.md"

cat > "$td/re-refuse.md" <<'EOF'
REQ-1 and REQ-2 are discussed here.

## Traceability Matrix

| ID | Description | Source | Downstream Link |
| --- | --- | --- | --- |
| REQ-1 | does a thing | docs/spec.md | not yet linked |
EOF
run deny "requirements-engineering/traceability-matrix-gate: REQ-2 missing a row -> refuse" \
  requirements-engineering "docs/issue-9/reports/requirements-engineering.md" "$td/re-refuse.md"

# --- security-threat-model / security-threat-model-canon-citation ----------
cat > "$td/stm-allow.md" <<'EOF'
## canon-references

See core's warrant/ plugin for the hunter stance rotation methodology.
EOF
run allow "security-threat-model/canon-citation: description-only reference -> allow" \
  security-threat-model "docs/issue-9/reports/security-threat-model.md" "$td/stm-allow.md"

cat > "$td/stm-refuse.md" <<'EOF'
## canon-references

#!/usr/bin/env bash
set -uo pipefail
CLAUDE_PLUGIN_ROOT is used here.
EOF
run deny "security-threat-model/canon-citation: pasted script content -> refuse" \
  security-threat-model "docs/issue-9/reports/security-threat-model.md" "$td/stm-refuse.md"

# --- technical-feasibility / evidence-citation ------------------------------
cat > "$td/tf-allow.md" <<'EOF'
## Evidence format

The library supports async I/O. -- source: https://example.com/docs
EOF
run allow "technical-feasibility/evidence-citation: claim with citation -> allow" \
  technical-feasibility "docs/issue-9/proposals/technical-feasibility.md" "$td/tf-allow.md"

cat > "$td/tf-refuse.md" <<'EOF'
## Evidence format

The library supports async I/O.
EOF
run deny "technical-feasibility/evidence-citation: claim with no citation -> refuse" \
  technical-feasibility "docs/issue-9/proposals/technical-feasibility.md" "$td/tf-refuse.md"

# --- test-authoring / traceability-line -------------------------------------
cat > "$td/ta-allow.md" <<'EOF'
This suite traces issue-9 requirement coverage.
EOF
run allow "test-authoring/traceability-line: keyword + matching issue ref -> allow" \
  test-authoring "docs/issue-9/reports/test-authoring.md" "$td/ta-allow.md"

cat > "$td/ta-refuse.md" <<'EOF'
This suite has no traceability statement at all.
EOF
run deny "test-authoring/traceability-line: no traceability line -> refuse" \
  test-authoring "docs/issue-9/reports/test-authoring.md" "$td/ta-refuse.md"

# --- empty state: a role with no citation-sourcing config row passes -------
run allow "empty state: unconfigured role passes through silently" \
  engineering "docs/issue-9/reports/test-authoring.md" "$td/ta-refuse.md"

# --- no-config-file: gate absent config -> no-op ----------------------------
run allow "no-config-file: missing config file -> no-op" \
  test-authoring "docs/issue-9/reports/test-authoring.md" "$td/ta-refuse.md" \
  CITATION_CONFIG="$td/does-not-exist.json"

rm -rf "$td"

echo
echo "citation-gate: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
