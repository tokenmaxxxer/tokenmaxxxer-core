#!/usr/bin/env bash
# survey-order-gate.sh's issue-271 role-aware survey path — live-fire tests
# (real PreToolUse JSON on stdin, real subprocess).
#
# Coverage per the approved proposal (docs/issue-271/proposals/):
#   (a) existing implementation-role behavior unchanged, with and without
#       CLAUDE_SKILL set;
#   (b) a non-implementation role's phase-1 proposal write is allowed once
#       its own reports/<role>/survey.md exists, and denied when only
#       reports/implementation/survey.md exists (no accept-any-glob);
#   (c) scout-skip-marker text still permits the write when no survey is
#       on disk.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
. "$HERE/_tmp.sh"
HOOKS="$(cd "$HERE/.." && pwd -P)"
GATE="$HOOKS/survey-order-gate.sh"

pass=0
fail=0
report() { # <want> <got> <name>
  if [ "$2" = "$1" ]; then
    pass=$((pass + 1)); printf 'ok     %-70s %s\n' "$3" "$2"
  else
    fail=$((fail + 1)); printf 'FAIL   %-70s want=%s got=%s\n' "$3" "$1" "$2"
  fi
}

run() { # <want> <name> <role> <file_path> <content> [extra env NAME=VAL ...]
  want="$1"; name="$2"; role="$3"; fp="$4"; content="$5"; shift 5
  content_json="$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$content")"
  payload="$(printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s}}' "$fp" "$content_json")"
  out="$(printf '%s' "$payload" | env CLAUDE_SKILL="$role" CLAUDE_PROJECT_DIR="$td" "$@" \
      /bin/bash "$GATE" 2>&1)"
  rc=$?
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  report "$want" "$got" "$name"
  [ "$got" = "$want" ] || echo "       output: $out"
}

mktd
mkdir -p "$td/.git"
mkdir -p "$td/docs/issue-9/proposals"
mkdir -p "$td/docs/issue-9/reports/implementation"
mkdir -p "$td/docs/issue-9/reports/product-discovery"

ordinary_body="---
status: proposed
files:
  - foo.py
---
## Request
do the thing
## Constraints
none
## Rationale
chose X over Y because Y was rejected
## What will be done
1. do it
## Out of scope
nothing
## How you'll know it worked
tests pass
"

skip_body="---
status: proposed
files:
  - foo.py
---
## Request
this is a pure bugfix, no design decision open (skip condition per scout directive)
## Constraints
none
## Rationale
chose X over Y because Y was rejected
## What will be done
1. do it
## Out of scope
nothing
## How you'll know it worked
tests pass
"

# --- (a) implementation-role unchanged, survey present --------------------
: > "$td/docs/issue-9/reports/implementation/survey.md"
run allow "implementation role, CLAUDE_SKILL unset, survey present" \
  "" "docs/issue-9/proposals/x.md" "$ordinary_body"
run allow "implementation role, CLAUDE_SKILL=implementation, survey present" \
  implementation "docs/issue-9/proposals/x.md" "$ordinary_body"

rm -f "$td/docs/issue-9/reports/implementation/survey.md"
run allow "implementation role, CLAUDE_SKILL unset, survey absent" \
  "" "docs/issue-9/proposals/x.md" "$ordinary_body"
run allow "implementation role, CLAUDE_SKILL=implementation, survey absent" \
  implementation "docs/issue-9/proposals/x.md" "$ordinary_body"

# --- (b) non-implementation role: own survey required, no accept-any-glob -
: > "$td/docs/issue-9/reports/implementation/survey.md"
run allow "product-discovery role: only implementation survey exists" \
  product-discovery "docs/issue-9/proposals/x.md" "$ordinary_body"
rm -f "$td/docs/issue-9/reports/implementation/survey.md"

: > "$td/docs/issue-9/reports/product-discovery/survey.md"
run allow "product-discovery role: own survey exists" \
  product-discovery "docs/issue-9/proposals/x.md" "$ordinary_body"
rm -f "$td/docs/issue-9/reports/product-discovery/survey.md"

# --- (c) scout-skip marker permits write with no survey on disk ----------
run allow "product-discovery role: no survey, but skip-condition text present" \
  product-discovery "docs/issue-9/proposals/x.md" "$skip_body"

echo
echo "survey-order-gate: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
