#!/usr/bin/env bash
# board-gate.sh, exercised as a real subprocess against real payloads.
#
# Five deny-only rules of the issue/PR interaction model (contract v3):
#   R1  docs/ layout: README.md, the six buckets, or issue-<n>/<bucket>
#   R2  a board write requires the repo contract to hash-match the canonical
#   R3  a write under docs/issue-<n>/ requires CLAUDE_ROLE
#   R4  a board write happens only on branch issue-<n>/<role>
#   R5  within issue-<n>/reports/, a role writes only its own record area
#
# want: "allow" (exit 0) | "deny" (exit 2)
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
GATE="$HERE/../board-gate.sh"
PLUGIN_ROOT="$(cd "$HERE/../.." && pwd -P)"

pass=0
fail=0

report() { # <want> <got> <name>
  if [ "$2" = "$1" ]; then
    pass=$((pass + 1)); printf 'ok     %-34s %s\n' "$3" "$2"
  else
    fail=$((fail + 1)); printf 'FAIL   %-34s want=%s got=%s\n' "$3" "$1" "$2"
  fi
}

# run <want> <name> <tool> <input-json-fragment> [env overrides...]
# Board repo: canonical contract planted, role qa, branch issue-3/qa.
run() {
  want="$1"; name="$2"; tool="$3"; tinput="$4"; shift 4
  td="$(cd "$(mktemp -d)" && pwd -P)"
  git init -q "$td"
  git -C "$td" remote add origin git@github.com:tokenmaxxxer/probe.git
  git -C "$td" checkout -q -b issue-3/qa
  mkdir -p "$td/docs/specs" "$td/docs/issue-3/reports"
  printf -- '- jw-human\n' > "$td/docs/specs/approvers.md"
  payload="$(printf '{"tool_name":"%s","tool_input":%s,"cwd":"%s"}' "$tool" "$tinput" "$td")"
  printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$td" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" \
      CLAUDE_ROLE=qa "$@" /bin/bash "$GATE" >/dev/null 2>&1
  rc=$?
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"
  report "$want" "$got" "$name"
}

# runb <want> <name> <branch> <role> <file_path> — branch/role matrix
runb() {
  want="$1"; name="$2"; branch="$3"; brole="$4"; fp="$5"
  td="$(cd "$(mktemp -d)" && pwd -P)"
  git init -q "$td"
  git -C "$td" remote add origin git@github.com:tokenmaxxxer/probe.git
  git -C "$td" checkout -q -b "$branch"
  mkdir -p "$td/docs/specs"
  printf -- '- jw-human\n' > "$td/docs/specs/approvers.md"
  printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"x"},"cwd":"%s"}' "$fp" "$td" \
    | env CLAUDE_PROJECT_DIR="$td" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" \
      CLAUDE_ROLE="$brole" /bin/bash "$GATE" >/dev/null 2>&1
  rc=$?
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"
  report "$want" "$got" "$name"
}

BOARD=docs/issue-3

# --- R1: docs/ layout -----------------------------------------------------
run deny  loose-docs-file        Write '{"file_path":"docs/notes.md","content":"x"}'
run deny  loose-issue-file       Write '{"file_path":"'$BOARD'/notes.md","content":"x"}'
run deny  nonbucket-issue-dir    Write '{"file_path":"'$BOARD'/tokens/k.token","content":"x"}'
run deny  nonbucket-standing-dir Write '{"file_path":"docs/product/one-pager.md","content":"x"}'
run allow docs-readme            Write '{"file_path":"docs/README.md","content":"x"}'
run allow standing-bucket        Write '{"file_path":"docs/specs/one-pager.md","content":"x"}'
run allow issue-proposal         Write '{"file_path":"'$BOARD'/proposals/2026-07-28-x.md","content":"x"}'

# --- R2: board writes require the canonical contract ----------------------
run allow write-own-record       Write '{"file_path":"'$BOARD'/reports/qa.md","content":"loop_state: observed"}'
run allow bash-append-record     Bash  '{"command":"echo note >> '$BOARD'/reports/qa.md"}'

drifted() {  # same harness, but approvers.md present/absent varies
  want="$1"; name="$2"; fp="$3"; mode="$4"; roleenv="$5"
  td="$(cd "$(mktemp -d)" && pwd -P)"
  git init -q "$td"
  git -C "$td" remote add origin git@github.com:tokenmaxxxer/probe.git
  git -C "$td" checkout -q -b issue-3/qa
  mkdir -p "$td/docs/specs"
  case "$mode" in
    drift)   printf -- '- jw-human\n' > "$td/docs/specs/approvers.md" ;;
    missing) : ;;
  esac
  if [ -n "$roleenv" ]; then
    printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"x"},"cwd":"%s"}' "$fp" "$td" \
      | env CLAUDE_PROJECT_DIR="$td" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" CLAUDE_ROLE="$roleenv" \
        /bin/bash "$GATE" >/dev/null 2>&1
  else
    printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"x"},"cwd":"%s"}' "$fp" "$td" \
      | env -u CLAUDE_ROLE CLAUDE_PROJECT_DIR="$td" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" \
        /bin/bash "$GATE" >/dev/null 2>&1
  fi
  rc=$?
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"
  report "$want" "$got" "$name"
}

drifted allow board-approvers-valid     "$BOARD/reports/qa.md" drift   qa
drifted deny  board-no-approvers       "$BOARD/reports/qa.md" missing qa
drifted allow standing-write-w-role    "docs/specs/x.md"      drift   qa

# --- not every repo with a docs/ directory is a board ---------------------
# No contract and no role means no board: an ordinary repo's docs are none
# of this gate's business, whatever their layout.
drifted allow bystander-loose-docs    "docs/architecture.md" missing ""
drifted allow bystander-issue-path    "$BOARD/notes.md"      missing ""

# --- R3: no role, no board writes -----------------------------------------
drifted() { :; } # not reused below
noRole() {
  td="$(cd "$(mktemp -d)" && pwd -P)"
  git init -q "$td"; git -C "$td" checkout -q -b issue-3/qa
  mkdir -p "$td/docs/specs"
  printf -- '- jw-human\n' > "$td/docs/specs/approvers.md"
  printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"x"},"cwd":"%s"}' "$1" "$td" \
    | env -u CLAUDE_ROLE CLAUDE_PROJECT_DIR="$td" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" \
      /bin/bash "$GATE" >/dev/null 2>&1
  rc=$?
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"
  report deny "$got" "board-write-no-role"
}
noRole "$BOARD/reports/qa.md"

# --- R4: the role's own issue branch --------------------------------------
runb deny  board-from-main       main       qa "$BOARD/reports/qa.md"
runb deny  board-wrong-issue     issue-4/qa qa "$BOARD/reports/qa.md"
runb deny  board-wrong-role      issue-3/coding qa "$BOARD/reports/qa.md"
runb allow board-right-branch    issue-3/qa qa "$BOARD/reports/qa.md"

# --- precondition: no remote, no board ------------------------------------
noremote() {
  td="$(cd "$(mktemp -d)" && pwd -P)"
  git init -q "$td"
  git -C "$td" checkout -q -b issue-3/qa
  mkdir -p "$td/docs/specs"
  printf -- '- jw-human\n' > "$td/docs/specs/approvers.md"
  printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"x"},"cwd":"%s"}' "$BOARD/reports/qa.md" "$td" \
    | env CLAUDE_PROJECT_DIR="$td" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" \
      CLAUDE_ROLE=qa /bin/bash "$GATE" >/dev/null 2>&1
  rc=$?
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"
  report deny "$got" "board-without-remote"
}
noremote

# --- R5: reports/ ownership -----------------------------------------------
runb deny  foreign-record        issue-3/qa qa "$BOARD/reports/review.md"
runb deny  foreign-subtree       issue-3/qa qa "$BOARD/reports/coding/x.md"
runb allow own-subtree           issue-3/qa qa "$BOARD/reports/qa/run-1.md"
runb allow feasibility-spikes    issue-3/feasibility feasibility "$BOARD/reports/spikes/probe.md"
runb allow ops-postmortems       issue-3/ops ops "$BOARD/reports/postmortems/outage.md"
runb deny  qa-not-spikes         issue-3/qa qa "$BOARD/reports/spikes/probe.md"

# --- the shell fast path must not change any verdict ----------------------
fastpath() {
  td="$(cd "$(mktemp -d)" && pwd -P)"
  git init -q "$td"
  printf '{"tool_name":"Read","tool_input":{"file_path":"src/app.py"},"cwd":"%s"}' "$td" \
    | env CLAUDE_ROLE=qa CLAUDE_PROJECT_DIR="$td" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" \
      /bin/bash "$GATE" >/dev/null 2>&1
  rc=$?
  rm -rf "$td"
  if [ "$rc" = 0 ]; then
    pass=$((pass + 1)); printf 'ok     %-34s allow (python3 never started)\n' "unrelated-tool-call"
  else
    fail=$((fail + 1)); printf 'FAIL   %-34s want=allow got=exit-%s\n' "unrelated-tool-call" "$rc"
  fi
}
fastpath

# --- outside docs/: not this gate's business ------------------------------
run allow write-src              Write '{"file_path":"src/app.py","content":"x"}'
run allow write-test             Write '{"file_path":"test/test_app.py","content":"x"}'
run allow bash-elsewhere         Bash  '{"command":"echo hi"}'
run allow bash-read-board        Bash  '{"command":"cat '$BOARD'/reports/qa.md"}'

# --- kill switch and fail-closed ------------------------------------------
run allow kill-switch            Write '{"file_path":"docs/loose.md","content":"x"}' CORE_OFF=1

# An unparseable payload that MENTIONS docs must refuse — the gate cannot
# tell what was about to be written. One that never mentions it cannot be a
# docs write at all.
garbage() {
  want="$1"; name="$2"; raw="$3"
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
  printf '%s' "$raw" | env CLAUDE_PROJECT_DIR="$td" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" \
      CLAUDE_ROLE=qa /bin/bash "$GATE" >/dev/null 2>&1
  rc=$?
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"
  report "$want" "$got" "$name"
}
garbage deny  garbage-mentioning-docs 'not json docs/issue-3/reports/qa.md'
garbage allow garbage-unrelated       'not json at all'

printf '\n== %d passed, %d failed ==\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
