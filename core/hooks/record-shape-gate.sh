#!/usr/bin/env bash
__fc(){ rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then echo "fail-closed: gate aborted (rc=$rc)" >&2; exit 2; fi; }
trap __fc EXIT
# PreToolUse gate (Write|Edit|MultiEdit) — enforces the implementation
# role's phase-2 record shape adopted in issue-52
# (docs/issue-52/proposals/2026-07-31-implementation-domain-norms.md,
# section (b)), EXTENDED (issue-263, phase-4b-4) with a config-driven
# CHECKERS dispatch that folds the 145 `record-section-shape`-family
# hooks across all 43 rulebooks (per
# docs/reports/keep-role-family-classification.md) into this same file,
# mirroring citation-gate.sh's/ordering-norm-gate.sh's CHECKERS pattern.
#
# Dispatch order: the hardcoded implementation-role check below always
# runs first and unconditionally for docs/issue-<n>/reports/
# implementation.md writes (unchanged behavior, issue-52's own contract).
# For every other write, config/record-shape-config.json rows for the
# acting CLAUDE_ROLE are checked; an unmatched role or an absent/
# malformed config file is a silent no-op (empty-state contract, same as
# citation-gate.sh).
#
# Target: docs/issue-<n>/reports/implementation.md only for the hardcoded
# check. Requires `code_under_review:` and `loop_state:` frontmatter keys
# and a `## What did not work` heading always. Requires a `## Rationale
# for deviations` heading only when the record's body otherwise signals a
# deviation occurred (scope-exceeded / diverged language); its absence
# when no deviation language is present is not an error, since the
# section is a conditional response to divergence, not a mandatory
# section on every record.
#
# Kill switch (whole gate, both the hardcoded check and config dispatch):
# export RECORD_SHAPE_GATE_OFF=1
# Kill switch (one config row): its own kill_switch_env, e.g.
#   export WCAG_EM_GATE_METHODOLOGY_GATE_SH_GATE_OFF=1
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)}/hooks/lib/gate-lib.sh" || { echo "record-shape-gate.sh: cannot source gate-lib.sh" >&2; exit 2; }
set -uo pipefail

role="${CLAUDE_ROLE:-record-shape}"
deny() { echo "${role}: refused — $1" >&2; exit 2; }

gate_kill_switch_active "${RECORD_SHAPE_GATE_OFF:-}" || exit 0

command -v python3 >/dev/null 2>&1 || deny "record-shape-gate.sh requires python3, which is not on PATH; denying rather than guessing."

RS_CONFIG="${RECORD_SHAPE_CONFIG:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/record-shape-config.json}"
export RS_CONFIG
export RS_ROLE="${CLAUDE_ROLE:-}"

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || deny "record-shape-gate: empty tool-use payload on stdin; cannot evaluate the record-shape gate."
export RS_PAYLOAD="$payload"

_target="$(printf '%s' "$payload" | python3 -c '
import json,sys
try: e=json.loads(sys.stdin.read())
except Exception: sys.exit(0)
ti=e.get("tool_input") if isinstance(e,dict) else None
if isinstance(ti,dict):
    for k in ("file_path","notebook_path"):
        v=ti.get(k)
        if isinstance(v,str) and v: print(v); break
' 2>/dev/null || true)"

_plausible() { [ -n "$1" ] && [ -d "$1" ] && { [ -e "$1/.git" ] || [ -f "$1/docs/specs/role-handoff-contract.md" ]; }; }
_under() {
  [ -z "$2" ] && return 0
  python3 -c '
import os,posixpath,sys
r,t=sys.argv[1],sys.argv[2]
try: rr=posixpath.normpath(os.path.realpath(r).replace("\\","/"))
except Exception: sys.exit(1)
n=t.replace("\\","/"); a=n if posixpath.isabs(n) else posixpath.join(rr,n)
a=posixpath.normpath(a); real=posixpath.normpath(os.path.realpath(a).replace("\\","/"))
sys.exit(0 if (real==rr or real.startswith(rr+"/")) else 1)
' "$1" "$2"
}

root=""
if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && _plausible "$CLAUDE_PROJECT_DIR" && _under "$CLAUDE_PROJECT_DIR" "$_target"; then
  root="$(cd "$CLAUDE_PROJECT_DIR" 2>/dev/null && pwd -P)"
fi
if [ -z "$root" ]; then
  d="$_target"; [ -n "$d" ] || d="$(pwd -P)"; [ -d "$d" ] || d="$(dirname "$d")"
  root="$(git -C "$d" rev-parse --show-toplevel 2>/dev/null || true)"
fi
[ -z "$root" ] && root="$(git -C "$(pwd -P)" rev-parse --show-toplevel 2>/dev/null || true)"
[ -z "$root" ] && deny "no project root could be determined; failing closed (record-shape check cannot run)."
export RS_ROOT="$root"

PG_PAYLOAD="$payload" PG_ROOT="$root" \
python3 <<'PY'
import sys as _fc_sys  # fail-closed-on-internal-error
try:
    import importlib.util, json, os, posixpath, re, sys

    _spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
    gate_lib = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(gate_lib)

    def deny(m):
        sys.stderr.write("record-shape: refused — %s\n" % m); sys.exit(2)

    raw = os.environ.get("PG_PAYLOAD", "")
    try:
        ev = json.loads(raw) if raw else {}
    except ValueError:
        deny("the tool-call payload is not valid JSON; the gate cannot judge record shape on an unparseable write.")
    if not isinstance(ev, dict):
        deny("the tool-call payload is not a JSON object; failing closed on record shape.")

    tool = ev.get("tool_name")
    ti = ev.get("tool_input")
    if not isinstance(ti, dict):
        deny("tool_input is missing or not a JSON object; the gate cannot judge a write it cannot parse (record shape).")

    root = posixpath.normpath(os.environ["PG_ROOT"].replace("\\", "/"))
    RECORD_RE = re.compile(r'^docs/issue-[0-9]+/reports/implementation\.md$')

    def resolve(p):
        n = p.replace("\\", "/")
        a = n if posixpath.isabs(n) else posixpath.join(root, n)
        a = posixpath.normpath(a)
        try:
            return posixpath.normpath(os.path.realpath(a).replace("\\", "/"))
        except OSError:
            return a

    path = None
    if tool in ("Write", "Edit", "MultiEdit"):
        p = ti.get("file_path")
        if isinstance(p, str) and p:
            path = p
    if path is None:
        sys.exit(0)

    r = resolve(path)
    if not r.startswith(root + "/"):
        sys.exit(0)
    rel = r[len(root):].lstrip("/")
    if not RECORD_RE.match(rel):
        sys.exit(0)  # not this role's phase-2 record write surface — not this gate's business

    current = None
    if os.path.isfile(r):
        try:
            with open(r, encoding="utf-8-sig") as fh:
                current = fh.read(1 << 20)
        except OSError:
            deny("%s exists but cannot be read; failing closed on record shape." % rel)

    new_text = None
    if tool in ("Write", "Edit", "MultiEdit"):
        new_text, _ok = gate_lib.gate_reconstruct_write(tool, ti, current)
        if not _ok:
            new_text = None

    if new_text is None:
        deny(
            "this write targets %s but the gate cannot determine the resulting content "
            "from the tool input (tool=%r). Write the full document with Write, or use an "
            "Edit/MultiEdit whose old_string matches, so the record shape can be "
            "checked." % (rel, tool)
        )

    missing = []

    # 1. Frontmatter: text between the first two `---` lines (or the whole
    #    text, for a fresh Write with no frontmatter delimiters at all —
    #    treated as start-of-file with an empty frontmatter block).
    lines = new_text.split("\n")
    frontmatter = ""
    if lines[:1] == ["---"]:
        end = None
        for i in range(1, len(lines)):
            if lines[i] == "---":
                end = i
                break
        if end is not None:
            frontmatter = "\n".join(lines[1:end])
        else:
            frontmatter = ""
    else:
        frontmatter = ""

    has_code_under_review = re.search(r'(?m)^code_under_review:', frontmatter) is not None
    has_loop_state = re.search(r'(?m)^loop_state:', frontmatter) is not None
    has_type = re.search(r'(?m)^type:', frontmatter) is not None
    has_breaking = re.search(r'(?m)^breaking:', frontmatter) is not None
    has_verdict = re.search(r'(?m)^verdict:', frontmatter) is not None
    if not has_code_under_review:
        missing.append("frontmatter key `code_under_review:`")
    if not has_loop_state:
        missing.append("frontmatter key `loop_state:`")
    if not has_type:
        missing.append("frontmatter key `type:`")
    if not has_breaking:
        missing.append("frontmatter key `breaking:`")
    if not has_verdict:
        missing.append("frontmatter key `verdict:`")

    # 2. `## What did not work` heading present somewhere in the body.
    has_wdnw = re.search(r'(?m)^##\s+What did not work\s*$', new_text) is not None
    if not has_wdnw:
        missing.append("`## What did not work` heading (present even when empty, e.g. \"None.\")")

    # 3. Conditional: deviation language in the body (excluding the
    #    `## Rationale for deviations` heading's own line) requires a
    #    `## Rationale for deviations` heading.
    body_without_heading = re.sub(r'(?m)^##\s+Rationale for deviations\s*$', '', new_text)
    low = body_without_heading.lower()
    deviation_signaled = any(
        needle in low
        for needle in ("scope-exceeded", "scope exceeded", "diverged from the proposal", "deviation")
    )
    has_rationale_heading = re.search(r'(?m)^##\s+Rationale for deviations\s*$', new_text) is not None
    if deviation_signaled and not has_rationale_heading:
        missing.append("`## Rationale for deviations` heading (required: the record signals a deviation occurred)")

    if missing:
        deny(
            "phase-2 record write to %s is missing required element(s): %s. Per "
            "docs/issue-52/proposals/2026-07-31-implementation-domain-norms.md "
            "section (b), every phase-2 implementation record must carry "
            "`code_under_review:`/`loop_state:` frontmatter, a `## What did not "
            "work` heading present even when empty, and a `## Rationale for "
            "deviations` section whenever the record signals a divergence from "
            "the approved phase-1 proposal." % (rel, "; ".join(missing))
        )

    sys.exit(0)
except Exception as _fc_e:  # fail-closed-on-internal-error
    _fc_sys.stderr.write("record-shape-gate.sh: fail-closed: internal error: %r\n" % (_fc_e,))
    _fc_sys.exit(2)
PY
_fc_rc=$?  # fail-closed-on-internal-error
if [ "$_fc_rc" -ne 0 ] && [ "$_fc_rc" -ne 2 ]; then
  echo "record-shape: refused — fail-closed: internal error (judge exited $_fc_rc)" >&2
  exit 2
fi
if [ "$_fc_rc" -eq 2 ]; then
  trap - EXIT
  exit 2
fi

# --- config-driven CHECKERS dispatch (issue-263 fold), only reached when
# the hardcoded implementation-role check above did not already deny and
# did not already match the implementation-role target path. ---
PG_PAYLOAD="$payload" PG_ROOT="$root" PG_CONFIG="$RS_CONFIG" PG_ROLE="$RS_ROLE" \
python3 <<'PY2'
import sys as _fc_sys
try:
    import importlib.util, json, os, re, sys

    _spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
    gate_lib = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(gate_lib)

    GATE_NAME = "record-shape-gate"

    def deny(msg):
        print(f"{GATE_NAME}: refused — {msg}", file=sys.stderr)
        sys.exit(2)

    config_path = os.environ["PG_CONFIG"]
    try:
        with open(config_path, "r", encoding="utf-8") as f:
            config = json.load(f)
    except (OSError, ValueError):
        sys.exit(0)

    role = os.environ.get("PG_ROLE", "")
    rows = config.get(role) if isinstance(config, dict) else None
    if not rows:
        sys.exit(0)  # no record-shape row configured for this role -- empty state

    root = os.environ.get("PG_ROOT") or os.getcwd()
    raw = os.environ.get("PG_PAYLOAD", "")
    event = gate_lib.gate_parse_json_or_deny(raw, deny)
    tool = event.get("tool_name") or ""
    ti = event.get("tool_input")
    if not isinstance(ti, dict):
        sys.exit(0)

    if tool not in ("Write", "Edit", "MultiEdit", "Bash"):
        sys.exit(0)

    def row_kill_switch_active(env_name):
        v = os.environ.get(env_name, "").strip().lower()
        return v not in ("1", "true", "yes", "on")

    def candidate_paths():
        if tool == "Bash":
            return gate_lib.gate_bash_write_targets(ti.get("command", "") or "")
        fp = ti.get("file_path")
        return [fp] if isinstance(fp, str) else []

    matched_rows = []
    for row in rows:
        if not row_kill_switch_active(row["kill_switch_env"]):
            continue
        try:
            pattern = re.compile(row["target_path_regex"])
        except re.error:
            continue
        for c in candidate_paths():
            norm = gate_lib.gate_normalize_path(root, c)
            if norm is not None and pattern.search(norm):
                matched_rows.append((row, norm))
                break

    if not matched_rows:
        sys.exit(0)

    if tool == "Bash":
        names = ", ".join(r["hook"] for r, _p in matched_rows)
        deny(
            f"a Bash-tool command targets a file governed by record-section-shape row(s) "
            f"[{names}], and the gate cannot reconstruct a Bash-written file's "
            "resulting content to check it; refusing an unverifiable write rather "
            "than passing it through (consistent with citation-gate.sh/ordering-norm-gate.sh)"
        )

    file_path = ti.get("file_path", "") or ""
    abs_path = file_path if os.path.isabs(file_path) else os.path.join(root, file_path)
    current_content = None
    if tool != "Write":
        if os.path.isfile(abs_path):
            try:
                with open(abs_path, "r", encoding="utf-8", errors="replace") as f:
                    current_content = f.read()
            except OSError:
                deny(f"{abs_path} exists but cannot be read; failing closed.")
        else:
            sys.exit(0)  # base file doesn't exist yet — no prior content to check against, not this gate's business on a fresh non-Write op

    new_text, ok = gate_lib.gate_reconstruct_write(tool, ti, current_content)
    if not ok or new_text is None:
        deny(
            f"this write targets a record-section-shape-governed file but the gate cannot "
            f"determine the resulting content from the tool input (tool={tool!r})"
        )

    # --- check_type handlers -------------------------------------------

    def check_checklist_entry_fields(row, text):
        required_keys = row.get("required_keys") or []
        if not required_keys:
            return None
        missing = [k for k in required_keys if k not in text]
        if missing:
            return (
                f"record-section-shape row {row['hook']!r}: checklist-entry field(s) "
                f"not found anywhere in the write: {', '.join(missing)}"
            )
        return None

    def check_section_markers_conditional(row, text):
        required_sections = row.get("required_sections") or []
        if not required_sections:
            return None
        if row.get("loop_state_gated") and "loop_state" not in text:
            return None  # not yet in a state where the section requirement is gated on
        missing = [s for s in required_sections if s not in text]
        if missing:
            return (
                f"record-section-shape row {row['hook']!r}: required section marker(s) "
                f"not found: {', '.join(missing)}"
            )
        return None

    def check_field_literal_token_cooccurrence(row, text):
        required_tokens = row.get("required_tokens") or []
        if not required_tokens:
            return None
        missing = [t for t in required_tokens if t not in text]
        if len(missing) == len(required_tokens):
            return (
                f"record-section-shape row {row['hook']!r}: none of the required "
                f"co-occurring literal token(s) found: {', '.join(required_tokens)}"
            )
        return None

    def check_methodology_checklist_gated(row, text):
        topic_tokens = row.get("topic_tokens") or []
        if not topic_tokens:
            return None
        low = text.lower()
        triggered = any(t in low for t in topic_tokens)
        if not triggered:
            return None  # topic not named in this write — methodology checklist not gated on
        return None  # topic-triggered checklist field enumeration deferred to hand-verification (low-confidence rows); presence of the topic alone does not fail the write

    CHECKERS = {
        "checklist_entry_fields": check_checklist_entry_fields,
        "section_markers_conditional": check_section_markers_conditional,
        "field_literal_token_cooccurrence": check_field_literal_token_cooccurrence,
        "methodology_checklist_gated": check_methodology_checklist_gated,
    }

    for row, rel in matched_rows:
        check_type = row.get("check_type")
        handler = CHECKERS.get(check_type)
        if handler is None:
            deny(f"unknown check_type {check_type!r} in record-shape-config.json row {row.get('hook')!r}")
        msg = handler(row, new_text)
        if msg is not None:
            deny(msg)

    sys.exit(0)
except Exception as _fc_e:
    _fc_sys.stderr.write("record-shape-gate.sh: fail-closed: internal error (config dispatch): %r\n" % (_fc_e,))
    _fc_sys.exit(2)
PY2
PY2_EXIT=$?

trap - EXIT
exit "$PY2_EXIT"
