#!/usr/bin/env bash
# record-shape-gate.sh -- live-fire tests (issue #248's lesson: real
# PreToolUse JSON on stdin, real subprocess, never a unit test of an
# in-process helper).
#
# issue-341 (operator ruling, 2026-08-27): the issue-263 config-driven
# CHECKERS dispatch this file used to cover (43 roles x 4 check_types,
# looked up via `config.get(CLAUDE_SKILL)` against record-shape-config.json)
# was removed as a closed-set identity validation the role-axis removal
# (issue-331) left live by accident. What remains here covers only the
# still-live hardcoded `implementation`-role phase-2 record check
# (issue #52, issue #285/#297's trivial-diff exemption), plus a regression
# guard that the removed dispatch's capability is actually gone: a write
# to a path/role pair the old config used to govern must now allow
# regardless of content, since nothing checks it any more. The
# pre-existing implementation-role hardcoded-check regression tests also
# live in tests/test_promoted_hooks.py and are not duplicated here.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
. "$HERE/_tmp.sh"
HOOKS="$(cd "$HERE/.." && pwd -P)"
GATE="$HOOKS/record-shape-gate.sh"

pass=0
fail=0
report() { # <want> <got> <name>
  if [ "$2" = "$1" ]; then
    pass=$((pass + 1)); printf 'ok     %-70s %s\n' "$3" "$2"
  else
    fail=$((fail + 1)); printf 'FAIL   %-70s want=%s got=%s\n' "$3" "$1" "$2"
  fi
}

mktd

# --- issue-341 regression: the removed config dispatch no longer governs
# a role/path pair it used to (e.g. `accessibility`'s folded WCAG-EM
# methodology-gate.sh row, docs/issue-10/proposals/gate-remediation.md,
# which used to require a `fail` key). The write must now allow even
# though the required key is absent, since record-shape-gate.sh no longer
# looks any of this up. -------------------------------------------------
mkdir -p "$td/docs/issue-10/proposals"
printf 'content with no fail key and no configured checklist markers\n' \
  > "$td/docs/issue-10/proposals/gate-remediation.md"
payload="$(python3 -c 'import json,sys; print(json.dumps({"tool_name":"Write","tool_input":{"file_path":sys.argv[1],"content":open(sys.argv[2]).read()}}))' \
  "docs/issue-10/proposals/gate-remediation.md" "$td/docs/issue-10/proposals/gate-remediation.md")"
out="$(printf '%s' "$payload" | env CLAUDE_SKILL=accessibility CLAUDE_PROJECT_DIR="$td" /bin/bash "$GATE" 2>&1)"
rc=$?
case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
report allow "$got" "issue-341: removed config dispatch no longer governs a formerly-configured role/path"
[ "$got" = allow ] || echo "       output: $out"

# --- hardcoded implementation-role trivial-diff exemption (issue-285,
# widened issue-297) -- a real git repo with a committed HEAD, since the
# triviality check reads `git diff HEAD --numstat`. ------------------------
gtd="$td/git-case"
mkdir -p "$gtd/docs/issue-1/reports"
git -C "$gtd" init -q
git -C "$gtd" -c user.name=t -c user.email=t@example.com commit -q --allow-empty -m init
printf 'line1\nline2\nline3\n' > "$gtd/src.py"
git -C "$gtd" add src.py
git -C "$gtd" -c user.name=t -c user.email=t@example.com commit -q -m "add src.py"
printf 'line1\nline2 changed\nline3\n' > "$gtd/src.py"  # 1-line trivial diff

run_git() { # <want> <name> <content-file>
  want="$1"; name="$2"; content_file="$3"
  content_json="$(python3 -c 'import json,sys; print(json.dumps(open(sys.argv[1]).read()))' "$content_file")"
  payload="$(printf '{"tool_name":"Write","tool_input":{"file_path":"docs/issue-1/reports/implementation.md","content":%s}}' "$content_json")"
  out="$(printf '%s' "$payload" | env CLAUDE_SKILL=implementation CLAUDE_PROJECT_DIR="$gtd" /bin/bash "$GATE" 2>&1)"
  rc=$?
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  report "$want" "$got" "$name"
  [ "$got" = "$want" ] || echo "       output: $out"
}

# issue-297: fixture issue #45's shape -- a minimal, honest trivial-diff
# record missing `code_under_review:` (no longer required below the
# trivial floor) must pass without refusal.
cat > "$gtd/record-no-code-under-review.md" <<'EOF'
---
loop_state: landed
type: docs
verdict: pass
---

Nothing to report for this trivial change.
EOF
run_git allow "issue-297: trivial diff exempts code_under_review:" \
  "$gtd/record-no-code-under-review.md"

# issue-297: the same record shape, mentioning "deviation" only to deny
# one, must not be misread as a deviation signal demanding a
# `## Rationale for deviations` heading.
cat > "$gtd/record-discusses-deviation.md" <<'EOF'
---
code_under_review:
  - src.py
loop_state: landed
type: fix
verdict: pass
---

No deviations from the proposal occurred.

Nothing to report for this trivial change.
EOF
run_git allow "issue-297: bare 'deviation' mention is not a deviation signal" \
  "$gtd/record-discusses-deviation.md"

# regression guard: an actual assertion of divergence still demands the
# heading, and a non-trivial diff still demands code_under_review:.
cat > "$gtd/record-actual-deviation.md" <<'EOF'
---
code_under_review:
  - src.py
loop_state: landed
type: fix
verdict: pass
---

We diverged from the proposal by dropping the CLI flag it specified.

Nothing to report for this trivial change.
EOF
run_git deny "issue-297 regression: an actual divergence still requires the Rationale heading" \
  "$gtd/record-actual-deviation.md"

printf 'line1\n' > "$gtd/src.py"
for i in $(seq 1 20); do printf 'line%s\n' "$i" >> "$gtd/src.py"; done  # >5-line, non-trivial diff
run_git deny "issue-297 regression: non-trivial diff still requires code_under_review:" \
  "$gtd/record-no-code-under-review.md"

echo
echo "record-shape-gate: $pass passed, $fail failed"
[ "$fail" = 0 ]
