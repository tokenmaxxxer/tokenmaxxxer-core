#!/usr/bin/env bash
# Parameterized fold of the 18 ordering-methodology hook instances (15
# distinct files across 11 rulebooks) — issue #257, phase-4b-2. Each
# source hook's real behavior (order-sequence check and/or its bundled
# non-order sub-checks, or a passive state-tracker's read/derive-state
# logic) is reproduced under its own row of
# core/hooks/ordering-norm-config.json, keyed by CLAUDE_ROLE, dispatched
# by mode (gate|tracker) and event (PreToolUse|SessionStart|PostToolUse).
#
# Promote-first: none of the 15 source hooks or their rulebooks'
# hooks.json entries are touched by this fold; they keep running
# unmodified.
#
# Empty-state / no-config-file: an acting role with no config row, or a
# missing/unreadable config file, passes through silently (exit 0).
#
# Kill switch (whole gate): export ORDERING_NORM_GATE_OFF=1
# Kill switch (one row): its own kill_switch_env, e.g.
#   export ERM_VERDICT_METHODOLOGY_GATE_OFF=1
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)}/hooks/lib/gate-lib.sh" || { echo "ordering-norm-gate.sh: cannot source gate-lib.sh" >&2; exit 2; }
gate_trap_fail_closed
set -uo pipefail
gate_kill_switch_active "${ORDERING_NORM_GATE_OFF:-}" || { trap - EXIT; exit 0; }

command -v python3 >/dev/null 2>&1 || gate_deny "ordering-norm-gate" "python3 not found; cannot evaluate gate"

ONG_CONFIG="${ORDERING_NORM_CONFIG:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/ordering-norm-config.json}"
export ONG_CONFIG
export ONG_ROLE="${CLAUDE_ROLE:-}"
export ONG_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
export ONG_HOOK_EVENT="${CLAUDE_HOOK_EVENT:-}"

# payload travels via env, never re-read from stdin inside the heredoc
# below (issue #245 bash-3.2 guard: no heredoc-in-command-substitution).
ONG_PAYLOAD="$(cat 2>/dev/null || true)"
export ONG_PAYLOAD

python3 <<'PYEOF'
import importlib.util
import json
import os
import re
import sys


def load(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


gate_lib = load("gate_lib", os.environ["GATE_LIB_PY"])

GATE_NAME = "ordering-norm-gate"


def deny(msg):
    print(f"{GATE_NAME}: refused — {msg}", file=sys.stderr)
    sys.exit(2)


config_path = os.environ["ONG_CONFIG"]
try:
    with open(config_path, "r", encoding="utf-8") as f:
        config = json.load(f)
except (OSError, ValueError):
    sys.exit(0)  # missing/unreadable/malformed config -> no-op, empty state

role = os.environ.get("ONG_ROLE", "")
rows = config.get(role) if isinstance(config, dict) else None
if not rows:
    sys.exit(0)  # no row configured for this role -- empty state, pass through

root = os.environ.get("ONG_PROJECT_DIR") or os.getcwd()
raw = os.environ.get("ONG_PAYLOAD", "")
event = gate_lib.gate_parse_json_or_deny(raw, deny)
tool = event.get("tool_name") or ""
ti = event.get("tool_input")
hook_event = os.environ.get("ONG_HOOK_EVENT", "") or event.get("hook_event_name") or event.get("hook_event") or ""


def row_kill_switch_active(env_name):
    v = os.environ.get(env_name, "").strip().lower()
    return v not in ("1", "true", "yes", "on")


def candidate_paths():
    if not isinstance(ti, dict):
        return []
    if tool == "Bash":
        return gate_lib.gate_bash_write_targets(ti.get("command", "") or "")
    for k in ("file_path", "notebook_path"):
        v = ti.get(k)
        if isinstance(v, str) and v:
            return [v]
    return []


def resolved_content(target_path):
    """Return (new_text, ok). Reconstructs the write's resulting content
    the same way facet-keyword-gate.sh/record-shape-gate.sh do."""
    abs_path = target_path if os.path.isabs(target_path) else os.path.join(root, target_path)
    current_content = None
    if tool != "Write":
        if os.path.isfile(abs_path):
            try:
                with open(abs_path, "r", encoding="utf-8", errors="replace") as f:
                    current_content = f.read()
            except OSError:
                return None, False
        else:
            return None, False
    return gate_lib.gate_reconstruct_write(tool, ti, current_content)


def on_disk_content(abs_path):
    if not os.path.isfile(abs_path):
        return None
    try:
        with open(abs_path, "r", encoding="utf-8-sig", errors="replace") as f:
            return f.read(1 << 20)
    except OSError:
        return None


def state_load(path):
    try:
        with open(path, "r", encoding="utf-8-sig") as f:
            return json.load(f)
    except (OSError, ValueError):
        return None


def state_save(path, data):
    try:
        os.makedirs(os.path.dirname(path), exist_ok=True)
        tmp = path + ".tmp"
        with open(tmp, "w", encoding="utf-8") as f:
            json.dump(data, f)
            f.write("\n")
        os.replace(tmp, path)
    except OSError:
        pass


# --- step_sequence: ordered marker-position compare (survey category A) --
def check_step_sequence(step_sequence, text):
    positions = []
    for step in step_sequence:
        m = re.search(step["marker_regex"], text)
        if m is None:
            return f"missing required section/step: {step['label']}"
        positions.append((step["label"], m.start()))
    for i in range(1, len(positions)):
        if positions[i][1] < positions[i - 1][1]:
            return f"step order violation: {positions[i][0]!r} appears before {positions[i - 1][0]!r}"
    return None


# --- extra_checks: named, per-hook non-order sub-checks (survey's finding
# that even the 5 "clean" step-sequence files bundle unrelated logic, and
# that 10 of 15 files are not step-sequence checks at all) ---------------
def xc_distinct_pair(xc, text, ctx):
    m1 = re.search(xc["first_regex"], text)
    if not m1:
        return xc["first_missing_message"]
    m2 = re.search(xc["second_regex"], text)
    if not m2:
        return xc["second_missing_message"]
    if m1.group(1).strip() == m2.group(1).strip():
        return xc["equal_message"]
    return None


def xc_adjacency_required(xc, text, ctx):
    window = xc.get("window_chars", 200)
    for m in re.finditer(xc["trigger_regex"], text):
        lo = max(0, m.start() - window)
        hi = min(len(text), m.end() + window)
        if not re.search(xc["required_nearby_regex"], text[lo:hi]):
            return xc["message"]
    return None


def xc_heading_before_forbidden(xc, text, ctx):
    m = re.search(xc["required_heading_regex"], text)
    if not m:
        return xc["missing_message"]
    before = text[: m.start()]
    fm = re.search(xc["forbidden_before_regex"], before)
    if fm:
        return xc["forbidden_message_template"].format(match=fm.group(0))
    return None


def xc_artifact_exists_before(xc, text, ctx):
    n = ctx.get("issue_n")
    if not n:
        return None
    missing = []
    for art in xc["artifacts"]:
        p = os.path.join(root, art["path_template"].format(n=n))
        if not os.path.isfile(p):
            missing.append(art["tag"])
    if missing:
        ctx.setdefault("_missing_tags", []).extend(missing)
    return None  # combined with citation_adjacency below into one message


def xc_citation_adjacency(xc, text, ctx):
    missing = list(ctx.get("_missing_tags", []))
    lines = text.splitlines()
    citation_re = re.compile(xc["citation_regex"], re.IGNORECASE)
    window = xc.get("window_lines", 3)
    for facet in xc["facets"]:
        kw_re = re.compile(facet["keyword_regex"], re.IGNORECASE)
        found_uncited = False
        any_hit = False
        for i, line in enumerate(lines):
            if kw_re.search(line):
                any_hit = True
                lo = max(0, i - window)
                hi = min(len(lines), i + window + 1)
                nearby = "\n".join(lines[lo:hi])
                if not citation_re.search(nearby):
                    found_uncited = True
                else:
                    found_uncited = False
                    break
        if any_hit and found_uncited:
            missing.append(facet["tag"])
    if missing:
        return xc["message_template"].format(missing=",".join(missing))
    return None


def xc_needle_any_missing(xc, text, ctx):
    low = text.lower()
    missing = []
    for g in xc["groups"]:
        topic_hit = any(w in low for w in g["topic_words"])
        needle_hit = any(nd in low for nd in g["needles"])
        if topic_hit and not needle_hit:
            missing.append(g["tag"])
        elif not topic_hit:
            missing.append(g["tag"])
    if missing:
        return xc["message_template"].format(missing="; ".join(missing))
    return None


def xc_conditional_race_sequence(xc, text, ctx):
    if not re.search(xc["condition_regex"], text):
        return None  # not yet loop_state: landed -- not this check's business
    m = re.search(xc["section_heading_regex"], text)
    if not m:
        return xc["missing_section_message"]
    rest = text[m.end():]
    m_next = re.search(r"^## ", rest, re.M)
    section = rest[: m_next.start()] if m_next else rest
    found_labels = re.findall(xc["label_regex"], section, re.M)
    missing_labels = [l for l in xc["labels"] if l not in found_labels]
    if missing_labels or found_labels != [l for l in xc["labels"] if l in found_labels]:
        if missing_labels:
            return xc["missing_labels_message_template"].format(missing=",".join(missing_labels))
    positions = {l: section.find(f"**{l}**") for l in found_labels}
    ordered = sorted((p for p in positions.values() if p >= 0))
    if [positions[l] for l in xc["labels"] if l in positions] != ordered:
        return xc["missing_labels_message_template"].format(missing="out-of-order")
    blocks = {}
    for i, lab in enumerate(xc["labels"]):
        if lab not in positions:
            continue
        start = positions[lab]
        later = [positions[l2] for l2 in xc["labels"][i + 1:] if l2 in positions]
        end = min(later) if later else len(section)
        blocks[lab] = section[start:end]
    for fc in xc["field_checks"]:
        block = blocks.get(fc["section"], "")
        m2 = re.search(fc["field_regex"], block, re.M)
        if not m2 or not m2.group(1).strip():
            return fc["message"]
    return None


def xc_hypothesis_state_or_marker(xc, text, ctx):
    n = ctx.get("issue_n")
    state = {}
    if n:
        sp = os.path.join(root, xc["state_path_template"].format(n=n))
        state = state_load(sp) or {}
    evidence_marker = bool(re.search(xc["evidence_marker_regex"], text))
    verdict_marker = bool(re.search(xc["verdict_marker_regex"], text))
    evidence_logged_effective = bool(state.get(xc["state_key"])) or evidence_marker
    if verdict_marker and not evidence_logged_effective:
        return xc["message"]
    return None


def xc_sources_or_paths_required(xc, text, ctx):
    has_sources = re.search(xc["sources_block_regex"], text) is not None
    has_url = re.search(xc["url_regex"], text) is not None
    if has_sources and has_url:
        return None
    for m in re.finditer(xc["report_path_regex"], text):
        cand = os.path.join(root, m.group(0))
        if os.path.isfile(cand):
            return None
    if has_sources or has_url:
        return None
    return None  # no citation attempted at all -- nothing to check (mirrors source hook's conditional trigger)


XC = {
    "distinct_pair": xc_distinct_pair,
    "adjacency_required": xc_adjacency_required,
    "heading_before_forbidden": xc_heading_before_forbidden,
    "artifact_exists_before": xc_artifact_exists_before,
    "citation_adjacency": xc_citation_adjacency,
    "needle_any_missing": xc_needle_any_missing,
    "conditional_race_sequence": xc_conditional_race_sequence,
    "hypothesis_state_or_marker": xc_hypothesis_state_or_marker,
    "sources_or_paths_required": xc_sources_or_paths_required,
}


def run_gate_row(row):
    if not row_kill_switch_active(row["kill_switch_env"]):
        return
    if tool not in ("Write", "Edit", "MultiEdit", "Bash"):
        return
    pattern = re.compile(row["target_path_regex"])
    matched_path = None
    matched_rel = None
    for c in candidate_paths():
        norm = gate_lib.gate_normalize_path(root, c)
        if norm is not None and pattern.match(norm):
            matched_path, matched_rel = c, norm
            break
    if matched_path is None:
        return

    if tool == "Bash":
        deny(
            f"a Bash-tool command targets {matched_rel}, a file governed by "
            f"ordering-norm row {row['hook']!r}, and the gate cannot reconstruct a "
            "Bash-written file's resulting content to check it; refusing an "
            "unverifiable write rather than passing it through"
        )

    new_text, ok = resolved_content(matched_path)
    if not ok or new_text is None:
        deny(
            f"this write targets {matched_rel} (row {row['hook']!r}) but the gate "
            f"cannot determine the resulting content from the tool input (tool={tool!r})"
        )

    m = pattern.match(matched_rel)
    issue_n = m.group(1) if m.groups() else None
    ctx = {"issue_n": issue_n}

    step_sequence = row.get("step_sequence") or []
    if step_sequence:
        msg = check_step_sequence(step_sequence, new_text)
        if msg is not None:
            deny(f"[{row['hook']}] {msg}")

    for xc in row.get("extra_checks") or []:
        checker = XC.get(xc["type"])
        if checker is None:
            continue
        msg = checker(xc, new_text, ctx)
        if msg is not None:
            deny(f"[{row['hook']}] {msg}")


# --- tracker actions: passive read/derive-state, never deny (survey
# category B's 5 SessionStart/PostToolUse siblings) ----------------------
def ta_context_informer(row):
    return  # informational-only source hooks; no state persisted, no denial


def ta_loop_state_rank_bump(row):
    if hook_event and hook_event != "PostToolUse":
        return
    if not isinstance(ti, dict):
        return
    path = ti.get("file_path") or ti.get("notebook_path")
    if not isinstance(path, str) or not path:
        return
    rel = gate_lib.gate_normalize_path(root, path)
    if rel is None:
        return
    m = re.match(row["record_path_regex"], rel)
    if not m:
        return
    abs_path = os.path.join(root, rel)
    text = on_disk_content(abs_path)
    if text is None:
        return
    matches = re.findall(r"^\s*loop_state\s*:\s*([A-Za-z-]+)\s*$", text, re.M)
    if not matches:
        return
    new_state = matches[-1].lower()
    ranks = row.get("ranks") or {}
    if new_state not in ranks:
        return
    n = m.group(1)
    sp = os.path.join(root, row["state_path_template"].format(n=n))
    cur = state_load(sp) or {}
    cur_state = cur.get("highest_state")
    if cur_state not in ranks or ranks[new_state] > ranks[cur_state]:
        state_save(sp, {"highest_state": new_state})


def ta_marker_file_reset_or_touch(row):
    marker = os.path.join(root, row["marker_path_template"])
    if hook_event == "SessionStart":
        try:
            os.remove(marker)
        except OSError:
            pass
        return
    payload_str = os.environ.get("ONG_PAYLOAD", "")
    if re.search(row["touch_regex"], payload_str):
        try:
            os.makedirs(os.path.dirname(marker), exist_ok=True)
            with open(marker, "w") as f:
                f.write("1\n")
        except OSError:
            pass


def ta_needle_state_record(row):
    if not isinstance(ti, dict):
        return
    path = ti.get("file_path") or ti.get("notebook_path")
    if not isinstance(path, str) or not path:
        return
    rel = gate_lib.gate_normalize_path(root, path)
    if rel is None or not re.match(row["record_path_regex"], rel):
        return
    tr = event.get("tool_response")
    is_success = isinstance(tr, dict) and not tr.get("error") and not tr.get("is_error")
    if not is_success:
        return
    text = on_disk_content(os.path.join(root, rel))
    if text is None:
        return
    m = re.search(r"issue-([0-9]+)", rel)
    if not m:
        return
    n = m.group(1)
    sp = os.path.join(root, row["state_path_template"].format(n=n))
    state_save(sp, {"issue": n, "methodology_named": True, "checked_at_path": rel})


def ta_hypothesis_state_sync(row):
    if not isinstance(ti, dict):
        return
    path = ti.get("file_path") or ti.get("notebook_path")
    if not isinstance(path, str) or not path:
        return
    rel = gate_lib.gate_normalize_path(root, path)
    if rel is None:
        return
    m = re.match(row["record_path_regex"], rel)
    if not m:
        return
    text = on_disk_content(os.path.join(root, rel))
    if text is None:
        return
    n = m.group(1)
    sp = os.path.join(root, row["state_path_template"].format(n=n))
    state = state_load(sp) or {"hypotheses_stated": False, "evidence_logged": False, "verdict_written": False}
    state["hypotheses_stated"] = bool(state.get("hypotheses_stated")) or bool(re.search(row["hyp_marker_regex"], text))
    state["evidence_logged"] = bool(state.get("evidence_logged")) or bool(re.search(row["evidence_marker_regex"], text))
    state["verdict_written"] = bool(state.get("verdict_written")) or bool(re.search(row["verdict_marker_regex"], text))
    state_save(sp, state)


TA = {
    "context_informer": ta_context_informer,
    "loop_state_rank_bump": ta_loop_state_rank_bump,
    "marker_file_reset_or_touch": ta_marker_file_reset_or_touch,
    "needle_state_record": ta_needle_state_record,
    "hypothesis_state_sync": ta_hypothesis_state_sync,
}


def run_tracker_row(row):
    if not row_kill_switch_active(row["kill_switch_env"]):
        return
    action = TA.get(row.get("tracker_action"))
    if action is None:
        return
    try:
        action(row)
    except Exception:
        pass  # a passive tracker must never crash or block the session


for row in rows:
    try:
        if row.get("mode") == "tracker":
            run_tracker_row(row)
        else:
            run_gate_row(row)
    except SystemExit:
        raise

sys.exit(0)
PYEOF
PY_EXIT=$?

trap - EXIT
exit "$PY_EXIT"
