#!/usr/bin/env bash
# board-gate.sh, exercised as a real subprocess against real payloads.
#
# Three deny-only rules, each covering a measured 2026-07-27 defect:
#   R1  no tool writes under records/*/tokens/ or to *.token under records/ —
#       coding's path-ownership gate passed exactly that write, so the model
#       could Write a forged approval token.
#   R2  a record write requires the target repo's contract to hash-match the
#       canonical shipped in this plugin — six repos measured 188 lines apart
#       while all claiming status: final.
#   R3  a record write requires CLAUDE_ROLE — the orchestrator's own session
#       carries zero rulebook gates, and its only board protection was prose.
#
# want: "allow" (exit 0) | "deny" (exit 2)
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
GATE="$HERE/../board-gate.sh"
PLUGIN_ROOT="$(cd "$HERE/../.." && pwd -P)"
CANON="$PLUGIN_ROOT/contract/role-handoff-contract.md"
pass=0
fail=0

# run <want> <name> <tool> <input-json-fragment> [env overrides...]
run() {
  want="$1"; name="$2"; tool="$3"; tinput="$4"; shift 4
  td="$(mktemp -d)"
  git init -q "$td"
  mkdir -p "$td/docs/specs" "$td/docs/reports/records/alpha"
  cp "$CANON" "$td/docs/specs/role-handoff-contract.md"
  payload="$(printf '{"tool_name":"%s","tool_input":%s,"cwd":"%s"}' "$tool" "$tinput" "$td")"
  printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$td" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" \
      CLAUDE_ROLE=qa "$@" /bin/bash "$GATE" >/dev/null 2>&1
  rc=$?
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"
  if [ "$got" = "$want" ]; then
    pass=$((pass + 1)); printf 'ok     %-30s %s\n' "$name" "$got"
  else
    fail=$((fail + 1)); printf 'FAIL   %-30s want=%s got=%s\n' "$name" "$want" "$got"
  fi
}

REC=docs/reports/records/alpha

# --- R1: the tokens directory is written by no tool, ever -----------------
run deny  write-token          Write '{"file_path":"'$REC'/tokens/scope-proposed--scope-approved.token","content":"kind: x"}'
run deny  edit-token           Edit  '{"file_path":"'$REC'/tokens/k.token","old_string":"a","new_string":"b"}'
run deny  bash-redirect-token  Bash  '{"command":"echo forged > '$REC'/tokens/k.token"}'
run deny  bash-cp-token        Bash  '{"command":"cp /tmp/x '$REC'/tokens/k.token"}'

# --- R2: record writes require the canonical contract ---------------------
run allow write-own-record     Write '{"file_path":"'$REC'/qa.md","content":"loop_state: probing"}'
run allow bash-append-record   Bash  '{"command":"echo note >> '$REC'/qa.md"}'

drifted() {  # same harness, but the repo contract differs from the canonical
  want="$1"; name="$2"; tool="$3"; tinput="$4"; mode="$5"
  td="$(mktemp -d)"
  git init -q "$td"
  mkdir -p "$td/docs/specs" "$td/docs/reports/records/alpha"
  case "$mode" in
    drift)   { cat "$CANON"; echo "local amendment"; } > "$td/docs/specs/role-handoff-contract.md" ;;
    missing) : ;;
  esac
  payload="$(printf '{"tool_name":"%s","tool_input":%s,"cwd":"%s"}' "$tool" "$tinput" "$td")"
  printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$td" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" \
      CLAUDE_ROLE=qa /bin/bash "$GATE" >/dev/null 2>&1
  rc=$?
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"
  if [ "$got" = "$want" ]; then
    pass=$((pass + 1)); printf 'ok     %-30s %s\n' "$name" "$got"
  else
    fail=$((fail + 1)); printf 'FAIL   %-30s want=%s got=%s\n' "$name" "$want" "$got"
  fi
}

drifted deny  record-contract-drift   Write '{"file_path":"'$REC'/qa.md","content":"x"}' drift
drifted deny  record-contract-missing Write '{"file_path":"'$REC'/qa.md","content":"x"}' missing
drifted allow nonrecord-no-contract   Write '{"file_path":"src/main.py","content":"x"}' missing

# --- R3: no role, no record writes ----------------------------------------
run deny  record-no-role       Write '{"file_path":"'$REC'/qa.md","content":"x"}' CLAUDE_ROLE=
run deny  token-no-role        Bash  '{"command":"tee '$REC'/tokens/k.token < /tmp/x"}' CLAUDE_ROLE=

# --- outside the board: not this gate's business --------------------------
run allow write-elsewhere      Write '{"file_path":"src/app.py","content":"x"}'
run allow bash-elsewhere       Bash  '{"command":"echo hi"}'
run allow bash-read-tokens     Bash  '{"command":"ls '$REC'/tokens"}'
run allow bash-cat-record      Bash  '{"command":"cat '$REC'/qa.md"}'

# --- kill switch and fail-closed ------------------------------------------
run allow kill-switch          Write '{"file_path":"'$REC'/tokens/k.token","content":"x"}' CORE_OFF=1

garbage() {  # unparseable payload must refuse, not pass through
  td="$(mktemp -d)"; git init -q "$td"
  printf 'not json' | env CLAUDE_PROJECT_DIR="$td" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" \
      CLAUDE_ROLE=qa /bin/bash "$GATE" >/dev/null 2>&1
  rc=$?
  rm -rf "$td"
  if [ "$rc" = 2 ]; then
    pass=$((pass + 1)); printf 'ok     %-30s deny\n' "garbage-payload"
  else
    fail=$((fail + 1)); printf 'FAIL   %-30s want=deny got=exit-%s\n' "garbage-payload" "$rc"
  fi
}
garbage

printf '\n== %d passed, %d failed ==\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
