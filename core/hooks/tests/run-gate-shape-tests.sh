#!/usr/bin/env bash
# Regression pin (issue-303, F15/F17): every core/hooks/*.sh gate that
# keeps a bash-level raw-text fast path before its python3 JSON judge must
# not let a JSON \uXXXX-escaped payload skip adjudication just because the
# escaped text no longer contains the literal substring the fast path
# scans for. Escaping decodes to a byte-identical parsed command/path, so
# the escaped and unescaped forms of the same payload must get identical
# verdicts.
#
# Scope: gh-guard.sh and approval-gate.sh (the two findings' own files),
# plus board-gate.sh (found vulnerable to the same defect family during
# this issue's verification, via a non-`/` escape the #301 record's
# narrower "docs has no escapable /" check did not try) and ordering-gate.sh
# (has no bash-level substring fast path at all -- pinned here so a future
# change that adds one is caught by this same suite).
#
# want: "allow" (exit 0) | "deny" (exit 2)
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
. "$HERE/_tmp.sh"
PLUGIN_ROOT="$(cd "$HERE/../.." && pwd -P)"
pass=0
fail=0

report() { # <want> <got> <name>
  if [ "$2" = "$1" ]; then
    pass=$((pass + 1)); printf 'ok     %-42s %s\n' "$3" "$2"
  else
    fail=$((fail + 1)); printf 'FAIL   %-42s want=%s got=%s\n' "$3" "$1" "$2"
  fi
}

# stub_python3 <dir> — a python3 that records that it was invoked, so a
# fast-skip can be told apart from "the judge ran and happened to allow".
stub_python3() {
  cat > "$1/python3" <<'SH'
#!/bin/sh
echo "PYTHON3_INVOKED" > "$PYTHON3_INVOKED_MARKER"
exit 1
SH
  chmod +x "$1/python3"
}

# --- gh-guard.sh: F15 -------------------------------------------------------
gh_guard_case() {
  GATE="$HERE/../gh-guard.sh"
  # baseline: unescaped "gh pr merge" denies.
  printf '{"tool_name": "Bash", "tool_input": {"command": "gh pr merge 42 --squash"}}' \
    | env CLAUDE_ROLE=implementation /bin/bash "$GATE" >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  report deny "$got" "gh-guard-unescaped-merge-denies"

  # F15 regression pin: the same command, "gh" JSON-escaped as \u0067h,
  # decodes to a byte-identical command string and must deny identically.
  printf '{"tool_name": "Bash", "tool_input": {"command": "\\u0067h pr merge 42 --squash"}}' \
    | env CLAUDE_ROLE=implementation /bin/bash "$GATE" >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  report deny "$got" "gh-guard-escaped-merge-still-denies-F15"

  # irrelevant payload (no gate-relevant content, no \u escape): still
  # fast-skips without ever invoking python3 (performance intent).
  mktd; stubdir="$td"; stub_python3 "$stubdir"
  marker="$stubdir/marker"
  printf '{"tool_name":"Bash","tool_input":{"command":"echo hello world"}}' \
    | env CLAUDE_ROLE=implementation PATH="$stubdir:/usr/bin:/bin" \
      PYTHON3_INVOKED_MARKER="$marker" /bin/bash "$GATE" >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  report allow "$got" "gh-guard-irrelevant-payload-fast-skips"
  if [ -e "$marker" ]; then got=invoked; else got=not-invoked; fi
  report not-invoked "$got" "gh-guard-irrelevant-payload-never-reaches-python3"
  rm -rf "$stubdir"
}
gh_guard_case

# --- approval-gate.sh: F17 --------------------------------------------------
approval_gate_case() {
  GATE="$HERE/../approval-gate.sh"
  mktd; repo="$td"
  git init -q "$repo"
  git -C "$repo" remote add origin git@github.com:tokenmaxxxer/probe.git
  git -C "$repo" checkout -q -b issue-7/coding
  mkdir -p "$repo/docs/specs"
  printf -- '- jw-human\n' > "$repo/docs/specs/approvers.md"

  # baseline: unescaped src/ write, no approval anywhere, denies.
  printf '{"tool_name": "Write", "tool_input": {"file_path": "src/bad_file.py", "content":"x"},"cwd":"%s"}' "$repo" \
    | env -u CORE_BUILD_NOW CLAUDE_ROLE=coding CLAUDE_PROJECT_DIR="$repo" /bin/bash "$GATE" >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  report deny "$got" "approval-gate-unescaped-src-write-denies"

  # F17 regression pin: "src/" JSON-escaped as \u0073rc/ decodes to a
  # byte-identical path and must deny identically.
  printf '{"tool_name": "Write", "tool_input": {"file_path": "\\u0073rc/bad_file.py", "content":"x"},"cwd":"%s"}' "$repo" \
    | env -u CORE_BUILD_NOW CLAUDE_ROLE=coding CLAUDE_PROJECT_DIR="$repo" /bin/bash "$GATE" >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  report deny "$got" "approval-gate-escaped-src-write-still-denies-F17"

  # same class via the Bash tool_input.command path (record's "reproduced
  # a second way" note).
  printf '{"tool_name":"Bash","tool_input":{"command":"echo hi > \\u0073rc/bad_file.py"},"cwd":"%s"}' "$repo" \
    | env -u CORE_BUILD_NOW CLAUDE_ROLE=coding CLAUDE_PROJECT_DIR="$repo" /bin/bash "$GATE" >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  report deny "$got" "approval-gate-escaped-src-bash-write-still-denies-F17"

  # irrelevant payload: still fast-skips without ever invoking python3.
  mktd; stubdir="$td"; stub_python3 "$stubdir"
  marker="$stubdir/marker"
  printf '{"tool_name":"Write","tool_input":{"file_path":"README.md","content":"x"},"cwd":"%s"}' "$repo" \
    | env -u CORE_BUILD_NOW CLAUDE_ROLE=coding CLAUDE_PROJECT_DIR="$repo" PATH="$stubdir:/usr/bin:/bin" \
      PYTHON3_INVOKED_MARKER="$marker" /bin/bash "$GATE" >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  report allow "$got" "approval-gate-irrelevant-payload-fast-skips"
  if [ -e "$marker" ]; then got=invoked; else got=not-invoked; fi
  report not-invoked "$got" "approval-gate-irrelevant-payload-never-reaches-python3"
  rm -rf "$stubdir" "$repo"
}
approval_gate_case

# --- board-gate.sh: same defect family, found live during this issue -------
board_gate_case() {
  GATE="$HERE/../board-gate.sh"
  mktd; repo="$td"
  git init -q "$repo"
  git -C "$repo" remote add origin git@github.com:tokenmaxxxer/probe.git
  git -C "$repo" checkout -q -b issue-3/qa
  mkdir -p "$repo/docs/specs"
  printf -- '- jw-human\n' > "$repo/docs/specs/approvers.md"

  # baseline: an unescaped bad-bucket docs/ write denies.
  printf '{"tool_name":"Write","tool_input":{"file_path":"docs/badbucket/x.md","content":"x"},"cwd":"%s"}' "$repo" \
    | env CLAUDE_ROLE=qa CLAUDE_PROJECT_DIR="$repo" /bin/bash "$GATE" >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  report deny "$got" "board-gate-unescaped-badbucket-denies"

  # regression pin: "docs" JSON-escaped on a NON-slash character
  # (\u006f for the "o") decodes to a byte-identical path and must deny
  # identically -- this is the escape the #301 record's "no escapable /"
  # reasoning did not try, and it does bypass the fast path as shipped.
  printf '{"tool_name":"Write","tool_input":{"file_path":"d\\u006fcs/badbucket/x.md","content":"x"},"cwd":"%s"}' "$repo" \
    | env CLAUDE_ROLE=qa CLAUDE_PROJECT_DIR="$repo" /bin/bash "$GATE" >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  report deny "$got" "board-gate-escaped-badbucket-still-denies"

  # irrelevant payload: still fast-skips without ever invoking python3.
  mktd; stubdir="$td"; stub_python3 "$stubdir"
  marker="$stubdir/marker"
  printf '{"tool_name":"Write","tool_input":{"file_path":"README.md","content":"x"},"cwd":"%s"}' "$repo" \
    | env CLAUDE_ROLE=qa CLAUDE_PROJECT_DIR="$repo" PATH="$stubdir:/usr/bin:/bin" \
      PYTHON3_INVOKED_MARKER="$marker" /bin/bash "$GATE" >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  report allow "$got" "board-gate-irrelevant-payload-fast-skips"
  if [ -e "$marker" ]; then got=invoked; else got=not-invoked; fi
  report not-invoked "$got" "board-gate-irrelevant-payload-never-reaches-python3"
  rm -rf "$stubdir" "$repo"
}
board_gate_case

# --- ordering-gate.sh: no bash-level fast path exists at all ---------------
# Pinned so a future change that adds one is caught by this same suite: a
# \u-escaped payload must adjudicate identically to its unescaped twin
# regardless, since there is no raw-text shortcut to bypass in the first
# place (confirmed by reading the full preamble -- payload goes straight
# from stdin into OG_PAYLOAD and json.loads, never a shell case match).
ordering_gate_case() {
  GATE="$HERE/../ordering-gate.sh"
  grep -q 'case "\$payload"' "$GATE"
  if [ $? -eq 0 ]; then
    report absent present "ordering-gate-no-bash-fast-path"
  else
    report absent absent "ordering-gate-no-bash-fast-path"
  fi
}
ordering_gate_case

# --- pretooluse_dispatcher.py: the actual registered production hook ------
# core/hooks/hooks.json registers ONLY pretooluse-dispatcher.sh -> this
# script for PreToolUse; the .sh gates above are the on-disk source of
# truth for policy, but this dispatcher's per-gate `_setup_*` functions
# independently re-derive each gate's raw-text fast-path check (module
# docstring: "replicates each gate's bash preamble ... cheap fast-path
# checks"), which means it re-derived the same F15/F17 bug rather than
# inheriting the .sh fix. A gate fix landed only in the .sh files would
# leave the real, enforced hook still bypassable. OTR_DISPATCH_ONLY routes
# a single named gate through the dispatcher without running the rest of
# the chain, mirroring the direct-.sh calls above one for one.
dispatcher_case() {
  DISPATCHER="$HERE/../pretooluse_dispatcher.py"

  # gh-guard.sh via the dispatcher: F15 pin.
  printf '{"tool_name": "Bash", "tool_input": {"command": "\\u0067h pr merge 42 --squash"}}' \
    | env -u CORE_BUILD_NOW CLAUDE_ROLE=implementation OTR_DISPATCH_ONLY=gh-guard.sh \
      python3 "$DISPATCHER" >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  report deny "$got" "dispatcher-gh-guard-escaped-merge-denies-F15"

  # approval-gate.sh via the dispatcher: F17 pin. A throwaway repo with a
  # role branch and approvers.md, matching approval_gate_case's baseline
  # above, so the python body's branch/approvers preconditions resolve the
  # same way and the only variable is the \u escape.
  mktd; repo="$td"
  git init -q "$repo"
  git -C "$repo" remote add origin git@github.com:tokenmaxxxer/probe.git
  git -C "$repo" checkout -q -b issue-7/coding
  mkdir -p "$repo/docs/specs"
  printf -- '- jw-human\n' > "$repo/docs/specs/approvers.md"
  printf '{"tool_name": "Write", "tool_input": {"file_path": "\\u0073rc/bad.py", "content":"x"},"cwd":"%s"}' "$repo" \
    | env -u CORE_BUILD_NOW CLAUDE_ROLE=coding CLAUDE_PROJECT_DIR="$repo" \
      OTR_DISPATCH_ONLY=approval-gate.sh python3 "$DISPATCHER" >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  report deny "$got" "dispatcher-approval-gate-escaped-src-denies-F17"
  rm -rf "$repo"

  # board-gate.sh via the dispatcher: same defect family pin.
  mktd; repo="$td"
  git init -q "$repo"
  git -C "$repo" remote add origin git@github.com:tokenmaxxxer/probe.git
  git -C "$repo" checkout -q -b issue-3/qa
  mkdir -p "$repo/docs/specs"
  printf -- '- jw-human\n' > "$repo/docs/specs/approvers.md"
  printf '{"tool_name":"Write","tool_input":{"file_path":"d\\u006fcs/badbucket/x.md","content":"x"},"cwd":"%s"}' "$repo" \
    | env -u CORE_BUILD_NOW CLAUDE_ROLE=qa CLAUDE_PROJECT_DIR="$repo" \
      OTR_DISPATCH_ONLY=board-gate.sh python3 "$DISPATCHER" >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  report deny "$got" "dispatcher-board-gate-escaped-badbucket-denies"
  rm -rf "$repo"

  # irrelevant payload through the full chain (all gates dispatched, not
  # OTR_DISPATCH_ONLY-scoped): still allows, empty-state performance
  # intent preserved end to end.
  printf '{"tool_name":"Bash","tool_input":{"command":"echo hello world"}}' \
    | env -u CORE_BUILD_NOW CLAUDE_ROLE=implementation python3 "$DISPATCHER" >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  report allow "$got" "dispatcher-irrelevant-payload-allows-full-chain"
}
dispatcher_case

printf '\n== %d passed, %d failed ==\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
