#!/usr/bin/env bash
# record-shape-gate.sh's issue-263 extension — live-fire tests (issue
# #248's lesson: real PreToolUse JSON on stdin, real subprocess, never a
# unit test of an in-process helper).
#
# Coverage per the approved proposal (not 145 individual cases): every
# one of the 43 configured roles dispatches without erroring at least
# once, and every distinct check_type shape (checklist_entry_fields,
# section_markers_conditional, field_literal_token_cooccurrence,
# methodology_checklist_gated) gets one allow + one refuse case, plus an
# empty-state case and a no-config-file case. The pre-existing
# implementation-role hardcoded-check regression tests already live in
# tests/test_promoted_hooks.py and are not duplicated here.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
. "$HERE/_tmp.sh"
HOOKS="$(cd "$HERE/.." && pwd -P)"
GATE="$HOOKS/record-shape-gate.sh"
CONFIG="$HOOKS/record-shape-config.json"

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

run_any() { # <name> <role> <file_path> <content-file> -- allow(0) or deny(2), never a crash
  name="$1"; role="$2"; fp="$3"; content_file="$4"
  content_json="$(python3 -c 'import json,sys; print(json.dumps(open(sys.argv[1]).read()))' "$content_file")"
  payload="$(printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s}}' "$fp" "$content_json")"
  out="$(printf '%s' "$payload" | env CLAUDE_ROLE="$role" CLAUDE_PROJECT_DIR="$td" \
      /bin/bash "$GATE" 2>&1)"
  rc=$?
  if [ "$rc" = 0 ] || [ "$rc" = 2 ]; then
    pass=$((pass + 1)); printf 'ok     %-70s exit-%s\n' "$name" "$rc"
  else
    fail=$((fail + 1)); printf 'FAIL   %-70s exit-%s\n' "$name" "$rc"
    echo "       output: $out"
  fi
}

mktd

# --- empty-state: an unconfigured role passes through silently ------------
cat > "$td/generic.md" <<'EOF'
unrelated content
EOF
run allow "empty-state: unconfigured role passes through" \
  no-such-role-configured "docs/issue-9/reports/no-such-role.md" "$td/generic.md"

# --- no-config-file: absent config file is a no-op -------------------------
out="$(printf '%s' '{"tool_name":"Write","tool_input":{"file_path":"docs/issue-9/reports/customer-support.md","content":"x"}}' \
    | env CLAUDE_ROLE=customer-support CLAUDE_PROJECT_DIR="$td" RECORD_SHAPE_CONFIG="$td/absent.json" \
      /bin/bash "$GATE" 2>&1)"
rc=$?
case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
report allow "$got" "no-config-file: absent config file is a no-op"

# --- coverage: every one of the 43 configured roles dispatches cleanly ----
gen="$td/coverage.tsv"
python3 - "$CONFIG" > "$gen" <<'PYEOF'
import json, re, sys
config = json.load(open(sys.argv[1]))
for role in sorted(config):
    row = config[role][0]
    p = row["target_path_regex"].replace("\\.", ".").replace("\\", "")
    p = re.sub(r"\[0-9\]\+", "9", p).lstrip("^").rstrip("$")
    print(role + "\t" + p)
PYEOF

n=0
while IFS=$'\t' read -r role path; do
  [ -n "$role" ] || continue
  n=$((n + 1))
  mkdir -p "$td/$(dirname "$path")"
  printf 'unrelated content with no configured literals\n' > "$td/cov-$n.md"
  run_any "coverage[$role]: dispatches without erroring" "$role" "$path" "$td/cov-$n.md"
done < "$gen"

# --- one allow + one refuse per distinct check_type shape -------------------
sample="$td/sample.json"
python3 - "$CONFIG" > "$sample" <<'PYEOF'
import json, re, sys
config = json.load(open(sys.argv[1]))
want = ("checklist_entry_fields", "section_markers_conditional",
        "field_literal_token_cooccurrence", "methodology_checklist_gated")
out = {}
FIELD_KEY = {
    "checklist_entry_fields": "required_keys",
    "section_markers_conditional": "required_sections",
    "field_literal_token_cooccurrence": "required_tokens",
    "methodology_checklist_gated": None,
}
for role in sorted(config):
    for row in config[role]:
        ct = row["check_type"]
        if ct not in want or ct in out:
            continue
        fk = FIELD_KEY[ct]
        # prefer a row that actually carries extracted fields, so the
        # allow/refuse cases below aren't skipped for lack of data
        if fk is not None and not row.get(fk) and any(
            r.get(fk) for rows2 in config.values() for r in rows2 if r["check_type"] == ct
        ):
            continue
        p = row["target_path_regex"].replace("\\.", ".").replace("\\", "")
        p = re.sub(r"\[0-9\]\+", "9", p).lstrip("^").rstrip("$")
        out[ct] = {"role": role, "path": p, "row": row}
print(json.dumps(out))
PYEOF

get() { python3 -c "import json,sys; d=json.load(open(sys.argv[1])); print(json.dumps(d.get(sys.argv[2])))" "$sample" "$1"; }

# checklist_entry_fields
row_json="$(get checklist_entry_fields)"
if [ "$row_json" != "null" ]; then
  role="$(printf '%s' "$row_json" | python3 -c 'import json,sys;print(json.load(sys.stdin)["role"])')"
  path="$(printf '%s' "$row_json" | python3 -c 'import json,sys;print(json.load(sys.stdin)["path"])')"
  keys="$(printf '%s' "$row_json" | python3 -c 'import json,sys;print("\n".join(json.load(sys.stdin)["row"].get("required_keys") or []))')"
  mkdir -p "$td/$(dirname "$path")"
  if [ -n "$keys" ]; then
    printf '%s\n' "$keys" | awk '{print $0": present"}' > "$td/ck-ok.md"
    run allow "checklist_entry_fields[$role]: required keys present -> allow" "$role" "$path" "$td/ck-ok.md"
    printf 'none of the required keys appear here\n' > "$td/ck-bad.md"
    run deny "checklist_entry_fields[$role]: required keys absent -> refuse" "$role" "$path" "$td/ck-bad.md"
  else
    echo "skip   checklist_entry_fields: sampled row carries no extracted required_keys"
  fi
fi

# section_markers_conditional
row_json="$(get section_markers_conditional)"
if [ "$row_json" != "null" ]; then
  role="$(printf '%s' "$row_json" | python3 -c 'import json,sys;print(json.load(sys.stdin)["role"])')"
  path="$(printf '%s' "$row_json" | python3 -c 'import json,sys;print(json.load(sys.stdin)["path"])')"
  secs="$(printf '%s' "$row_json" | python3 -c 'import json,sys;print("\n".join(json.load(sys.stdin)["row"].get("required_sections") or []))')"
  mkdir -p "$td/$(dirname "$path")"
  if [ -n "$secs" ]; then
    { echo "loop_state: terminal"; echo; printf '%s\n' "$secs"; } > "$td/sm-ok.md"
    run allow "section_markers_conditional[$role]: required sections present -> allow" "$role" "$path" "$td/sm-ok.md"
    { echo "loop_state: terminal"; echo; echo "no matching section markers here"; } > "$td/sm-bad.md"
    run deny "section_markers_conditional[$role]: required sections absent -> refuse" "$role" "$path" "$td/sm-bad.md"
  else
    echo "skip   section_markers_conditional: sampled row carries no extracted required_sections"
  fi
fi

# field_literal_token_cooccurrence
row_json="$(get field_literal_token_cooccurrence)"
if [ "$row_json" != "null" ]; then
  role="$(printf '%s' "$row_json" | python3 -c 'import json,sys;print(json.load(sys.stdin)["role"])')"
  path="$(printf '%s' "$row_json" | python3 -c 'import json,sys;print(json.load(sys.stdin)["path"])')"
  toks="$(printf '%s' "$row_json" | python3 -c 'import json,sys;print(" ".join(json.load(sys.stdin)["row"].get("required_tokens") or []))')"
  mkdir -p "$td/$(dirname "$path")"
  if [ -n "$toks" ]; then
    printf '%s\n' "$toks" > "$td/fl-ok.md"
    run allow "field_literal_token_cooccurrence[$role]: token present -> allow" "$role" "$path" "$td/fl-ok.md"
    printf 'none of the configured tokens appear in this write\n' > "$td/fl-bad.md"
    run deny "field_literal_token_cooccurrence[$role]: no tokens -> refuse" "$role" "$path" "$td/fl-bad.md"
  else
    echo "skip   field_literal_token_cooccurrence: sampled row carries no extracted required_tokens"
  fi
fi

# methodology_checklist_gated (topic-gated -- untriggered write always allows)
row_json="$(get methodology_checklist_gated)"
if [ "$row_json" != "null" ]; then
  role="$(printf '%s' "$row_json" | python3 -c 'import json,sys;print(json.load(sys.stdin)["role"])')"
  path="$(printf '%s' "$row_json" | python3 -c 'import json,sys;print(json.load(sys.stdin)["path"])')"
  mkdir -p "$td/$(dirname "$path")"
  printf 'content with no topic trigger\n' > "$td/mg-ok.md"
  run allow "methodology_checklist_gated[$role]: topic not triggered -> allow" "$role" "$path" "$td/mg-ok.md"
fi

# --- Bash-tool write to a matched row fails closed (unreconstructible content) ---
row_json="$(get checklist_entry_fields)"
if [ "$row_json" != "null" ]; then
  role="$(printf '%s' "$row_json" | python3 -c 'import json,sys;print(json.load(sys.stdin)["role"])')"
  path="$(printf '%s' "$row_json" | python3 -c 'import json,sys;print(json.load(sys.stdin)["path"])')"
  bash_cmd="echo bad > $path"
  bash_payload="$(python3 -c 'import json,sys; print(json.dumps({"tool_name":"Bash","tool_input":{"command":sys.argv[1]}}))' "$bash_cmd")"
  out="$(printf '%s' "$bash_payload" | env CLAUDE_ROLE="$role" CLAUDE_PROJECT_DIR="$td" /bin/bash "$GATE" 2>&1)"
  rc=$?
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  report deny "$got" "Bash-tool write to a matched row[$role]: unreconstructible content -> refuse"
  [ "$got" = deny ] || echo "       output: $out"
fi

echo
echo "record-shape-gate (issue-263 fold): $pass passed, $fail failed"
[ "$fail" = 0 ]
