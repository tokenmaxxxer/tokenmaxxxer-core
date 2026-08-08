#!/usr/bin/env bash
# trailer-gate.sh, record-fields-gate.sh, handbook-trigger-gate.sh and
# stub-check.sh, exercised as real subprocesses — asserting that two
# different CLAUDE_ROLE values produce correctly-labeled output and
# correctly-namespaced kill switches from the SAME canon file (issue-66).
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
. "$HERE/_tmp.sh"
HOOKS="$(cd "$HERE/.." && pwd -P)"

pass=0
fail=0
report() { # <want> <got> <name>
  if [ "$2" = "$1" ]; then
    pass=$((pass + 1)); printf 'ok     %-40s %s\n' "$3" "$2"
  else
    fail=$((fail + 1)); printf 'FAIL   %-40s want=%s got=%s\n' "$3" "$1" "$2"
  fi
}

# --- trailer-gate.sh: role-labeled refusal, no trailer -> deny -------------
run_trailer() { # <want> <name> <role> <commit-args-json> <extra-env...>
  want="$1"; name="$2"; role="$3"; args="$4"; shift 4
  mktd
  git init -q "$td"
  echo x > "$td/x.txt"
  mkdir -p "$td/docs/issue-3/reports"
  echo x > "$td/docs/issue-3/reports/x.md"
  git -C "$td" add -A
  payload="$(printf '{"tool_name":"Bash","tool_input":{"command":%s}}' "$args")"
  out="$(printf '%s' "$payload" | env CLAUDE_ROLE="$role" CLAUDE_PROJECT_DIR="$td" "$@" \
      /bin/bash "$HOOKS/trailer-gate.sh" 2>&1)"
  rc=$?
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  msg_ok=1
  case "$got" in deny) case "$out" in "${role}: refused"*) ;; *) msg_ok=0 ;; esac ;; esac
  rm -rf "$td"
  report "$want" "$got" "$name"
  [ "$msg_ok" = 1 ] || { fail=$((fail + 1)); echo "FAIL   $name: message not labeled with role '$role': $out"; }
}

run_trailer deny  "coding: commit w/o trailer denied"    coding '"git commit -m x"'
run_trailer allow "coding: commit w/ trailer allowed"    coding '"git commit -m \"x\n\nSubject: issue-3\""'
run_trailer deny  "product: commit w/o trailer denied"   product '"git commit -m x"'
run_trailer allow "TRAILER_GATE_OFF disables the gate"   coding '"git commit -m x"' TRAILER_GATE_OFF=1

# --- trailer-gate.sh: heredoc-supplied multi-line message (issue-151) ------
# The standard multi-line commit idiom is `-m "$(cat <<'EOF' ...body... EOF)"`.
# shlex.split() has no notion of heredocs and mis-parses a body containing an
# unescaped double quote; the gate must extract the heredoc body directly.
heredoc_args_with_trailer='"git commit -m \"$(cat <<'"'"'EOF'"'"'\nRename \\\"foo\\\" to \\\"bar\\\"\n\nSubject: issue-3\nEOF\n)\""'
heredoc_args_without_trailer='"git commit -m \"$(cat <<'"'"'EOF'"'"'\nRename \\\"foo\\\" to \\\"bar\\\"\n\nno trailer here\nEOF\n)\""'
run_trailer allow "coding: heredoc -m with embedded quotes and trailer allowed (issue-151)" \
  coding "$heredoc_args_with_trailer"
run_trailer deny  "coding: heredoc -m with embedded quotes, no trailer, still denied (issue-151)" \
  coding "$heredoc_args_without_trailer"

# --- record-fields-gate.sh: role-scoped record path, role-labeled refusal --
run_rf() { # <want> <name> <role> <file_path> <content-json> <extra-env...>
  want="$1"; name="$2"; role="$3"; fp="$4"; content="$5"; shift 5
  payload="$(printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s}}' "$fp" "$content")"
  out="$(printf '%s' "$payload" | env CLAUDE_ROLE="$role" CLAUDE_PROJECT_DIR="/tmp" "$@" \
      /bin/bash "$HOOKS/record-fields-gate.sh" 2>&1)"
  rc=$?
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  msg_ok=1
  case "$got" in deny) case "$out" in "${role}: refused"*) ;; *) msg_ok=0 ;; esac ;; esac
  report "$want" "$got" "$name"
  [ "$msg_ok" = 1 ] || { fail=$((fail + 1)); echo "FAIL   $name: message not labeled with role '$role': $out"; }
}

run_rf deny  "coding record missing fields denied" coding \
  "docs/issue-3/reports/coding.md" '"# empty\n"'
run_rf allow "coding record w/ all §20 fields allowed" coding \
  "docs/issue-3/reports/coding.md" \
  '"loop_state: landed\n\n## what was done\nx\n\n## why\ny\n\nupstream: abc1234\n\n## open findings\nnone\n"'
run_rf allow "non-owning role write is not this gate'\''s business" coding \
  "docs/issue-3/reports/product.md" '"# empty\n"'
run_rf deny  "product-role open record missing next-steps denied" product \
  "docs/issue-3/reports/product.md" \
  '"loop_state: scope-proposed\n\n## what was done\nx\n\n## why\ny\n\nupstream: abc1234\n\n## open findings\nnone\n"'
run_rf allow "product-role scope-proposed treated as terminal via override" product \
  "docs/issue-3/reports/product.md" \
  '"loop_state: scope-proposed\n\n## what was done\nx\n\n## why\ny\n\nupstream: abc1234\n\n## open findings\nnone\n"' \
  RECORD_FIELDS_TERMINAL_STATES="landed scope-proposed"
run_rf deny  "implementation record code_under_review bare sha denied (issue-100)" implementation \
  "docs/issue-3/reports/implementation.md" \
  '"loop_state: landed\n\ncode_under_review: 0123456789abcdef0123456789abcdef01234567\n\n## what was done\nx\n\n## why\ny\n\nupstream: abc1234\n\n## open findings\nnone\n"'
run_rf allow "implementation record code_under_review file list allowed (issue-100)" implementation \
  "docs/issue-3/reports/implementation.md" \
  '"loop_state: landed\n\ncode_under_review: `a.sh`, `b.sh`\n\n## what was done\nx\n\n## why\ny\n\nupstream: abc1234\n\n## open findings\nnone\n"'

# --- record-fields-gate.sh: same-commit sha placeholder check (issue-128) --
# issue-153: these fixtures wrap the upstream/sha block in a `---`/`---`
# frontmatter fence, matching every real record/proposal's actual shape
# (confirmed against the corpus) — the sha check now scans only that
# region, so a fixture without the fence would fall through the "no
# frontmatter, nothing to check" path and pass vacuously regardless of
# the value inside it.
run_rf deny  "proposal sha bracket placeholder denied (issue-128)" coding \
  "docs/issue-3/proposals/2026-08-04-x.md" \
  '"---\nupstream:\n  - path: docs/issue-3/reports/implementation/survey.md\n    sha: <set at commit>\n---\n"'
run_rf allow "proposal sha: same-commit allowed (issue-128)" coding \
  "docs/issue-3/proposals/2026-08-04-x.md" \
  '"---\nupstream:\n  - path: docs/issue-3/reports/implementation/survey.md\n    sha: same-commit\n---\n"'
run_rf allow "proposal sha real hex allowed (issue-128)" coding \
  "docs/issue-3/proposals/2026-08-04-x.md" \
  '"---\nupstream:\n  - path: docs/issue-3/reports/implementation/survey.md\n    sha: 0123456789abcdef0123456789abcdef01234567\n---\n"'
run_rf deny  "record sha bracket placeholder denied despite complete §20 fields (issue-128)" coding \
  "docs/issue-3/reports/coding.md" \
  '"---\nloop_state: landed\nupstream:\n  - path: docs/issue-3/reports/implementation/survey.md\n    sha: <set at commit>\n---\n\n## what was done\nx\n\n## why\ny\n\n## open findings\nnone\n"'
run_rf allow "record sha: same-commit allowed (issue-128)" coding \
  "docs/issue-3/reports/coding.md" \
  '"---\nloop_state: landed\nupstream:\n  - path: docs/issue-3/reports/implementation/survey.md\n    sha: same-commit\n---\n\n## what was done\nx\n\n## why\ny\n\n## open findings\nnone\n"'

# --- record-fields-gate.sh: sha allow-list red->green (issue-133) ----------
run_rf deny  "proposal sha: HEAD denied (issue-133)" coding \
  "docs/issue-3/proposals/2026-08-04-x.md" \
  '"---\nupstream:\n  - path: docs/issue-3/reports/implementation/survey.md\n    sha: HEAD\n---\n"'
run_rf deny  "proposal sha: TBD denied (issue-133)" coding \
  "docs/issue-3/proposals/2026-08-04-x.md" \
  '"---\nupstream:\n  - path: docs/issue-3/reports/implementation/survey.md\n    sha: TBD\n---\n"'
run_rf deny  "proposal sha bracket+trailing-prose denied (issue-133)" coding \
  "docs/issue-3/proposals/2026-08-04-x.md" \
  '"---\nupstream:\n  - path: docs/issue-3/reports/implementation/survey.md\n    sha: <set at commit> -- fix later\n---\n"'

# --- record-fields-gate.sh: sha scan scope + empty-value carve-out (issue-153) --
run_rf deny  "F1 regression: bad value inside frontmatter's own entry still denied" coding \
  "docs/issue-3/proposals/2026-08-04-x.md" \
  '"---\nupstream:\n  - path: docs/issue-3/reports/implementation/survey.md\n    sha: HEAD\n---\n"'
run_rf allow "F1 red->green: fenced-block quotation outside frontmatter allowed" coding \
  "docs/issue-3/proposals/2026-08-04-x.md" \
  '"---\nupstream:\n  - path: docs/issue-3/reports/implementation/survey.md\n    sha: same-commit\n---\n\nbody quoting a bad value as an example:\n\n```\n    sha: HEAD\n```\n"'
run_rf deny  "F1 no-trailing-newline: bad frontmatter value still denied (hunt finding)" coding \
  "docs/issue-3/proposals/2026-08-04-x.md" \
  '"---\nupstream:\n  - path: docs/issue-3/reports/implementation/survey.md\n    sha: HEAD\n---"'
run_rf allow "F1 comment case: conforming value + trailing YAML comment allowed" coding \
  "docs/issue-3/proposals/2026-08-04-x.md" \
  '"---\nupstream:\n  - path: docs/issue-3/reports/implementation/survey.md\n    sha: same-commit  # landed same commit\n---\n"'
run_rf allow "F2 red->green: value-less line followed by another entry allowed (carve-out)" coding \
  "docs/issue-3/proposals/2026-08-04-x.md" \
  '"---\nupstream:\n  - path: docs/issue-3/reports/implementation/survey.md\n    sha:\n  - path: other\n    sha: same-commit\n---\n"'

f2_msg_out="$(printf '%s' '{"tool_name":"Write","tool_input":{"file_path":"docs/issue-3/proposals/2026-08-04-x.md","content":"---\nupstream:\n  - path: docs/issue-3/reports/implementation/survey.md\n    sha: HEAD\n  - path: other\n    sha: same-commit\n---\n"}}' \
    | env CLAUDE_ROLE=coding CLAUDE_PROJECT_DIR="/tmp" /bin/bash "$HOOKS/record-fields-gate.sh" 2>&1)"
case "$f2_msg_out" in
  *"sha: HEAD is not"*) f2_msg_ok=1 ;;
  *) f2_msg_ok=0 ;;
esac
report 1 "$f2_msg_ok" "F2 message-accuracy: denial names the offending line's own value (issue-153)"

# before-landing hunt (issue-153, stance 0): a leading BOM made the
# frontmatter anchor fail to match at all, silently emptying the scan
# region and letting any sha value through — fixed by stripping a leading
# BOM before anchoring; regression-pin it here.
run_rf deny "before-landing hunt: leading BOM does not bypass the sha check (issue-153)" coding \
  "docs/issue-3/proposals/2026-08-04-x.md" \
  '"﻿---\nupstream:\n  - path: docs/issue-3/reports/implementation/survey.md\n    sha: HEAD\n---\n"'

# --- record-fields-gate.sh: frontmatter-less fallback (issue-157 F1) -------
# F1 red->green: a document with NO leading `---` fence at all used to fall
# back to an empty scan region (region = "" when fm is None) -- every sha:
# line went uninspected, so a bare unresolved spelling went straight
# through. Pre-fix this fixture is `allow` (reproduced by direct regex
# trace, docs/issue-157/reports/implementation/survey.md's F1 section:
# region="" -> bad=[]); post-fix the whole-document fallback scans it and
# denies. Green as of this commit.
run_rf deny "F1 red->green: fence-less document's bad sha value denied (issue-157)" coding \
  "docs/issue-3/proposals/2026-08-04-x.md" \
  '"sha: HEAD\n"'
# Regression guard: a fence-less document with a CONFORMING value must stay
# allowed both before and after the fix -- the fallback closes the gap for
# bad values, it must not become an always-deny trap for fence-less writes.
run_rf allow "F1 regression: fence-less document's conforming sha value stays allowed (issue-157)" coding \
  "docs/issue-3/proposals/2026-08-04-x.md" \
  '"sha: same-commit\n"'
# Hunt finding regression (issue-157 after-proposal hunt, stance 0): a
# document with a fully-conforming leading fence, preceded only by one
# stray leading blank line (an ordinary editor/copy-paste artifact), must
# still be recognized as fenced -- not misclassified as fence-less and
# routed into the whole-document fallback, which would falsely deny the
# denied spelling this fixture legitimately quotes inside a fenced example
# in its body.
run_rf allow "F1 hunt regression: leading blank line before a real fence still allowed to quote an example (issue-157)" coding \
  "docs/issue-3/proposals/2026-08-04-x.md" \
  '"\n---\nupstream:\n  - path: docs/issue-3/reports/implementation/survey.md\n    sha: same-commit\n---\n\nbody quoting a bad value as an example:\n\n```\n    sha: HEAD\n```\n"'

# --- record-fields-gate.sh: F2 message-accuracy discriminator (issue-157) --
# The pre-existing message-accuracy probe (:145-151) uses a non-empty value
# directly on the field-name line, which never exercises the
# newline-swallowing bug the case is named for -- old and current regex
# produce the identical result against it (survey's F2 section). This
# fixture reuses the landed carve-out fixture's shape (:141-143: one entry
# with an empty sha:, a second entry with a value) but with the SECOND
# entry's value made non-conforming: under the pre-#154 whole-document
# pattern, the first (empty) entry's trailing `\s*` swallows the next
# line's literal `- path: other` text as bad[0], so the denial message
# would never contain the substring `sha: HEAD is not`; under the current,
# carve-out-aware pattern it does. No production-code change pins this --
# #154 already fixed the underlying behavior; only the test was
# non-discriminating.
f2b_msg_out="$(printf '%s' '{"tool_name":"Write","tool_input":{"file_path":"docs/issue-3/proposals/2026-08-04-x.md","content":"---\nupstream:\n  - path: a\n    sha:\n  - path: other\n    sha: HEAD\n---\n"}}' \
    | env CLAUDE_ROLE=coding CLAUDE_PROJECT_DIR="/tmp" /bin/bash "$HOOKS/record-fields-gate.sh" 2>&1)"
case "$f2b_msg_out" in
  *"sha: HEAD is not"*) f2b_msg_ok=1 ;;
  *) f2b_msg_ok=0 ;;
esac
report 1 "$f2b_msg_ok" "F2 discriminator: empty entry + bad second entry names HEAD, not swallowed text (issue-157)"

# --- record-fields-gate.sh: single deny lists every violation (issue-140) --
run_rf_count() { # <want-count> <name> <role> <file_path> <content-json>
  want="$1"; name="$2"; role="$3"; fp="$4"; content="$5"
  payload="$(printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s}}' "$fp" "$content")"
  out="$(printf '%s' "$payload" | env CLAUDE_ROLE="$role" CLAUDE_PROJECT_DIR="/tmp" \
      /bin/bash "$HOOKS/record-fields-gate.sh" 2>&1)"
  rc=$?
  got=0
  [ "$rc" = 2 ] && got="$(printf '%s' "$out" | grep -o ';' | wc -l | tr -d ' ')" && got=$((got + 1))
  report "$want" "$got" "$name"
}
run_rf_count 4 "one deny lists all 4 missing sections (issue-140)" coding \
  "docs/issue-3/reports/coding.md" \
  '"loop_state: landed\n"'

run_rf deny "phase-2-complete with -/_ variants still requires §20 fields" coding \
  "docs/issue-3/reports/coding.md" \
  '"loop_state: phase_2_complete\n"'
run_rf allow "phase-2-complete (normalized) treated as terminal (issue-140)" coding \
  "docs/issue-3/reports/coding.md" \
  '"loop_state: phase_2_complete\n\n## what was done\nx\n\n## why\ny\n\nupstream: abc1234\n\n## open findings\nnone\n"'
run_rf allow "closed loop_state treated as terminal (issue-140)" coding \
  "docs/issue-3/reports/coding.md" \
  '"loop_state: closed\n\n## what was done\nx\n\n## why\ny\n\nupstream: abc1234\n\n## open findings\nnone\n"'
run_rf allow "done loop_state treated as terminal (issue-140)" coding \
  "docs/issue-3/reports/coding.md" \
  '"loop_state: done\n\n## what was done\nx\n\n## why\ny\n\nupstream: abc1234\n\n## open findings\nnone\n"'
run_rf allow "complete loop_state treated as terminal (issue-140)" coding \
  "docs/issue-3/reports/coding.md" \
  '"loop_state: complete\n\n## what was done\nx\n\n## why\ny\n\nupstream: abc1234\n\n## open findings\nnone\n"'

# --- record-fields-gate.sh: full terminal-state spelling table (PR #143) ---
# Pins every spelling from the PR #143 feedback comment's table, both
# directions: accepted spellings stay accepted (allow), non-terminal
# spellings stay non-terminal (deny).
for spelling in landed complete closed done delivered \
    phase-2-complete phase-2_complete Complete COMPLETE \
    phase2-complete phase2_complete; do
  run_rf allow "loop_state '$spelling' accepted as terminal (PR #143)" coding \
    "docs/issue-3/reports/coding.md" \
    "\"loop_state: $spelling\n\n## what was done\nx\n\n## why\ny\n\nupstream: abc1234\n\n## open findings\nnone\n\""
done
run_rf deny "loop_state 'in_progress' stays non-terminal (PR #143)" coding \
  "docs/issue-3/reports/coding.md" \
  '"loop_state: in_progress\n"'
run_rf allow "loop_state 'in_progress' allowed once next-steps present (PR #143)" coding \
  "docs/issue-3/reports/coding.md" \
  '"loop_state: in_progress\n\n## what was done\nx\n\n## why\ny\n\nupstream: abc1234\n\n## open findings\nnone\n\n## next steps\nz\n\n## open finding resolution path\nnone\n"'

out="$(printf '%s' '{"tool_name":"Write","tool_input":{"file_path":"docs/issue-3/reports/coding.md","content":"loop_state: landed\n"}}' \
    | env CLAUDE_ROLE=coding CLAUDE_PROJECT_DIR="/tmp" /bin/bash "$HOOKS/record-fields-gate.sh" 2>&1)"
case "$out" in
  *'"what was done"'*'"why"'*) msg_ok=1 ;;
  *) msg_ok=0 ;;
esac
report 1 "$msg_ok" "deny message names the accepted literal strings (issue-140)"

# --- handbook-trigger-gate.sh: role-labeled refusal ------------------------
run_ht() { # <want> <name> <role> <staged-files...> -- <commit-args-json>
  want="$1"; name="$2"; role="$3"; shift 3
  files=()
  while [ "$1" != "--" ]; do files+=("$1"); shift; done
  shift
  args="$1"
  mktd
  git init -q "$td"
  for f in "${files[@]}"; do
    mkdir -p "$td/$(dirname "$f")"
    echo x > "$td/$f"
  done
  [ "${#files[@]}" -gt 0 ] && git -C "$td" add -A
  payload="$(printf '{"tool_name":"Bash","tool_input":{"command":%s}}' "$args")"
  out="$(printf '%s' "$payload" | env CLAUDE_ROLE="$role" CLAUDE_PROJECT_DIR="$td" \
      /bin/bash "$HOOKS/handbook-trigger-gate.sh" 2>&1)"
  rc=$?
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  msg_ok=1
  case "$got" in deny) case "$out" in "${role}: refused"*) ;; *) msg_ok=0 ;; esac ;; esac
  rm -rf "$td"
  report "$want" "$got" "$name"
  [ "$msg_ok" = 1 ] || { fail=$((fail + 1)); echo "FAIL   $name: message not labeled with role '$role': $out"; }
}

run_ht deny  "coding: package.json w/o handbook denied" coding package.json -- '"git commit -m x"'
run_ht allow "coding: package.json w/ handbook allowed" coding package.json docs/handbooks/x.md -- '"git commit -m x"'
run_ht deny  "product: package.json w/o handbook denied" product package.json -- '"git commit -m x"'

# --- stub-check.sh: absence-based for gates, structural for directive.sh --
mktd
mkdir -p "$td/hooks/tests"
out="$(/bin/bash "$HERE/stub-check.sh" "$td" 2>&1)"; rc=$?
report allow "$([ $rc = 0 ] && echo allow || echo deny)" "stub-check: clean rulebook tree passes"
cp "$HOOKS/trailer-gate.sh" "$td/hooks/trailer-gate.sh"
out="$(/bin/bash "$HERE/stub-check.sh" "$td" 2>&1)"; rc=$?
report deny "$([ $rc = 0 ] && echo allow || echo deny)" "stub-check: vendored trailer-gate.sh caught"
rm -f "$td/hooks/trailer-gate.sh"
cp "$HERE/stub-check.sh" "$td/hooks/tests/stub-check.sh"
out="$(/bin/bash "$HERE/stub-check.sh" "$td" 2>&1)"; rc=$?
report deny "$([ $rc = 0 ] && echo allow || echo deny)" "stub-check: vendored copy of itself caught (issue-69)"
rm -f "$td/hooks/tests/stub-check.sh"
cat > "$td/hooks/directive.sh" <<'EOF'
#!/usr/bin/env bash
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)/hooks/lib/role-directive.sh"
core_role_directive "YOU DECIDE: x" "USE WHEN: y" "PRODUCES: z" "HAND-OFF: w"
EOF
out="$(/bin/bash "$HERE/stub-check.sh" "$td" 2>&1)"; rc=$?
report allow "$([ $rc = 0 ] && echo allow || echo deny)" "stub-check: real stub directive.sh passes"
cat >> "$td/hooks/directive.sh" <<'EOF'
case "${SOME_CYCLE_OFF:-}" in ""|0|false|no|off) ;; *) exit 0 ;; esac
[ "${CLAUDE_ROLE:-}" = "x" ] || exit 0
echo one; echo two; echo three; echo four; echo five; echo six; echo seven
echo eight; echo nine; echo ten; echo eleven; echo twelve; echo thirteen
EOF
out="$(/bin/bash "$HERE/stub-check.sh" "$td" 2>&1)"; rc=$?
report deny "$([ $rc = 0 ] && echo allow || echo deny)" "stub-check: regrown boilerplate caught"
rm -rf "$td"

echo
echo "role-gates: $pass passed, $fail failed"
[ "$fail" = 0 ]
