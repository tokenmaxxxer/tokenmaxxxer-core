#!/usr/bin/env bash
# PreToolUse gate: parameterized fold of the 8 facet-keyword-family hooks
# (issue #254, phase-4b-1) — content-design's tone-axis gate,
# customer-support's escalation-path/five-whys/kcs/playbook-scenario/
# sla-tier gates, finance-unit-economics' sensitivity-scenario gate, and
# sales' playbook gate. Behavior-equivalent per hook under its own row of
# core/hooks/facet-keyword-config.json, keyed by CLAUDE_ROLE (one role may
# carry several facet rows — customer-support carries 5, run
# independently against the same reconstructed write).
#
# Promote-first: none of the 8 source hooks or their rulebooks' hooks.json
# entries are touched by this fold; they keep running unmodified.
#
# Empty-state / no-config-file: an acting role with no config row, or a
# missing/unreadable config file, passes through silently (exit 0) — same
# as a source hook whose target-path regex never matches.
#
# Kill switch (whole gate): export FACET_KEYWORD_GATE_OFF=1
# Kill switch (one facet row): its own kill_switch_env, e.g.
#   export CUSTOMER_SUPPORT_KCS_GATE_OFF=1
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)}/hooks/lib/gate-lib.sh" || { echo "facet-keyword-gate.sh: cannot source gate-lib.sh" >&2; exit 2; }
gate_trap_fail_closed
set -uo pipefail
gate_kill_switch_active "${FACET_KEYWORD_GATE_OFF:-}" || { trap - EXIT; exit 0; }

command -v python3 >/dev/null 2>&1 || gate_deny "facet-keyword-gate" "python3 not found; cannot evaluate gate"

FK_CONFIG="${FACET_KEYWORD_CONFIG:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/facet-keyword-config.json}"
export FK_CONFIG
export FK_ROLE="${CLAUDE_ROLE:-}"
export FK_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# payload travels via env, never re-read from stdin inside the heredoc
# below (issue #245 bash-3.2 guard: no heredoc-in-command-substitution).
FK_PAYLOAD="$(cat 2>/dev/null || true)"
export FK_PAYLOAD

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

GATE_NAME = "facet-keyword-gate"


def deny(msg):
    # issue-282 DEMOTE: advisory only -- detection logic is unchanged but
    # this gate no longer blocks the tool call.
    reason = f"{GATE_NAME}: {msg}"
    print(reason, file=sys.stderr)
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "additionalContext": reason,
        },
        "systemMessage": reason,
    }))
    sys.exit(0)


# --- load config (missing/unreadable/malformed file -> no-op, empty state) -
config_path = os.environ["FK_CONFIG"]
try:
    with open(config_path, "r", encoding="utf-8") as f:
        config = json.load(f)
except (OSError, ValueError):
    sys.exit(0)

role = os.environ.get("FK_ROLE", "")
facets = config.get(role) if isinstance(config, dict) else None
if not facets:
    sys.exit(0)  # no facet configured for this role -- empty state, pass through

root = os.environ.get("FK_PROJECT_DIR") or os.getcwd()
raw = os.environ.get("FK_PAYLOAD", "")
event = gate_lib.gate_parse_json_or_deny(raw, deny)
tool = event.get("tool_name") or ""
ti = event.get("tool_input")
if not isinstance(ti, dict):
    sys.exit(0)

if tool not in ("Write", "Edit", "MultiEdit", "Bash"):
    sys.exit(0)


# --- section/table helpers (ported from the rulebooks' local semantic.py;
# this gate is core-owned and must not import a rulebook file) -------------
def section_slices(text, heading_pattern):
    lines = text.splitlines()
    heading_re = re.compile(r'^(#{1,6})\s+(.*)$')
    headings = []
    for i, line in enumerate(lines):
        m = heading_re.match(line)
        if m:
            headings.append((i, len(m.group(1)), m.group(2)))
    results = []
    for idx, (line_i, level, htext) in enumerate(headings):
        if not re.search(heading_pattern, htext, re.IGNORECASE):
            continue
        end = len(lines)
        for later_i, later_level, _t in headings[idx + 1:]:
            if later_level <= level:
                end = later_i
                break
        results.append((lines[line_i], "\n".join(lines[line_i + 1:end])))
    return results


def table_header_slice(text):
    lines = text.splitlines()
    for i, line in enumerate(lines):
        if '|' in line:
            header = line
            sep = lines[i + 1] if i + 1 < len(lines) else ""
            if re.search(r'^\s*\|?[\s:|-]+\|?\s*$', sep):
                return header + "\n" + sep
            return header
    return ""


def split_headed_sections(text, header_split_regex):
    matches = list(re.finditer(header_split_regex, text, re.IGNORECASE | re.MULTILINE))
    out = []
    for i, m in enumerate(matches):
        header = m.group(0).strip()
        start = m.end()
        end = matches[i + 1].start() if i + 1 < len(matches) else len(text)
        out.append((header, text[start:end]))
    return out


def markdown_headings(text):
    lines = text.splitlines()
    heading_re = re.compile(r'^(#{1,6})\s+(.*?)\s*$')
    out = []
    for i, ln in enumerate(lines):
        m = heading_re.match(ln)
        if m:
            out.append((len(m.group(1)), m.group(2).strip().lower(), i))
    return out, lines


# --- per-check_type evaluators; each returns None (ok) or a deny message --
def check_header_present_or_skip(facet, text):
    sections = split_headed_sections(text, facet["header_split_regex"])
    if not sections:
        return facet["no_sections_message"]
    present_re = re.compile(facet["present_regex"], re.IGNORECASE)
    skip_re = re.compile(facet["skip_regex"], re.IGNORECASE)
    sec_re = re.compile(facet["skip_secondary_regex"], re.IGNORECASE)
    ctx_re = re.compile(facet["skip_secondary_context_regex"], re.IGNORECASE)
    window = facet.get("skip_secondary_window", 60)
    for header, body in sections:
        if present_re.search(body):
            continue
        if skip_re.search(body):
            continue
        ok = False
        for m in sec_re.finditer(body):
            lo = max(0, m.start() - window)
            hi = min(len(body), m.end() + window)
            if ctx_re.search(body[lo:hi]):
                ok = True
                break
        if ok:
            continue
        return facet["missing_message_template"].format(header=header)
    return None


def check_trigger_required_elements(facet, text):
    if not re.search(facet["trigger_regex"], text, re.IGNORECASE):
        return None
    slices = section_slices(text, facet["section_scope_regex"])
    if slices:
        scoped = "\n".join(s for _h, s in slices)
    else:
        m = re.search(facet["trigger_regex"], text, re.IGNORECASE)
        scoped = text[m.end():]
    missing = [e["tag"] for e in facet["required_elements"]
               if not re.search(e["regex"], scoped, re.IGNORECASE)]
    if missing:
        return facet["deny_message_template"].format(
            missing=",".join(missing), doc_ref=facet.get("doc_ref", ""))
    return None


def check_trigger_count(facet, text):
    if not re.search(facet["trigger_regex"], text, re.IGNORECASE):
        return None
    has_label = bool(re.search(facet["label_regex"], text, re.IGNORECASE))
    count = len(re.findall(facet["count_regex"], text, re.MULTILINE))
    if not has_label or count < facet["min_count"]:
        return facet["deny_message_template"].format(doc_ref=facet.get("doc_ref", ""))
    return None


def check_marker_required_elements(facet, text):
    marker = bool(
        re.search(facet["marker_primary_regex"], text, re.IGNORECASE | re.MULTILINE)
        or re.search(facet["marker_secondary_regex"], text, re.IGNORECASE)
    )
    if not marker:
        return None
    missing = [e["tag"] for e in facet["required_elements"]
               if not re.search(e["regex"], text, re.IGNORECASE | re.MULTILINE)]
    if missing:
        return facet["deny_message_template"].format(
            missing=",".join(missing), doc_ref=facet.get("doc_ref", ""))
    return None


def check_table_header_columns(facet, text):
    header = table_header_slice(text)
    missing = [c["tag"] for c in facet["columns"]
               if not re.search(c["regex"], header, re.IGNORECASE)]
    if missing:
        return facet["deny_message_template"].format(
            missing=",".join(missing), doc_ref=facet.get("doc_ref", ""))
    return None


def check_heading_scenario_min_labels(facet, text):
    low = text.lower()
    if facet["trigger_word"] not in low:
        return None
    headings, lines = markdown_headings(text)
    secs = []
    for idx, (level, title, i) in enumerate(headings):
        start = i + 1
        end = len(lines)
        for lvl2, _t2, i2 in headings[idx + 1:]:
            if lvl2 <= level:
                end = i2
                break
        secs.append((title, "\n".join(lines[start:end])))
    sens_body = "\n".join(
        body for title, body in secs if re.search(facet["heading_scope_regex"], title, re.IGNORECASE)
    ).lower()
    labels = re.findall(facet["label_regex"], sens_body)
    if len(set(labels)) < facet["min_distinct"]:
        return facet["deny_message_template"]
    return None


def check_heading_sections_required(facet, text):
    headings, lines = markdown_headings(text)
    if not headings:
        return None
    mentions = bool(re.search(facet["mentions_regex"], lines[0], re.IGNORECASE)) if lines else False
    mentions = mentions or any(re.search(facet["mentions_regex"], t, re.IGNORECASE) for _l, t, _i in headings)
    if not mentions:
        return None

    def section_body(idx):
        level = headings[idx][0]
        start = headings[idx][2] + 1
        end = len(lines)
        for j in range(idx + 1, len(headings)):
            if headings[j][0] <= level:
                end = headings[j][2]
                break
        return lines[start:end]

    missing = []
    section_indices = {}
    for key, aliases in facet["section_aliases"].items():
        found = None
        for hi, (_lvl, title, _i) in enumerate(headings):
            if title in aliases:
                found = hi
                break
        if found is None:
            missing.append(key)
        else:
            section_indices[key] = found

    scoped_parts = []
    for key in facet["messaging_scope_keys"]:
        if key in section_indices:
            scoped_parts.append("\n".join(section_body(section_indices[key])))
    if headings:
        trailing_start = headings[-1][2] + 1
        scoped_parts.append("\n".join(lines[trailing_start:]))
    scoped_low = "\n".join(scoped_parts).lower()

    if any(nd in scoped_low for nd in facet["messaging_needles"]):
        missing.append("inline-messaging-copy-detected (must reference marketing's asset, not duplicate it)")

    if missing:
        return facet["deny_message_template"].format(missing=", ".join(missing))
    return None


CHECKERS = {
    "header_present_or_skip": check_header_present_or_skip,
    "trigger_required_elements": check_trigger_required_elements,
    "trigger_count": check_trigger_count,
    "marker_required_elements": check_marker_required_elements,
    "table_header_columns": check_table_header_columns,
    "heading_scenario_min_labels": check_heading_scenario_min_labels,
    "heading_sections_required": check_heading_sections_required,
}


def candidate_paths():
    if tool == "Bash":
        return gate_lib.gate_bash_write_targets(ti.get("command", "") or "")
    fp = ti.get("file_path")
    return [fp] if isinstance(fp, str) else []


def facet_kill_switch_active(env_name):
    # mirrors gate-lib.sh's gate_kill_switch_active: only a recognized
    # on-spelling disables; empty/unset/off/unrecognized stays active.
    v = os.environ.get(env_name, "").strip().lower()
    return v not in ("1", "true", "yes", "on")


matched_facets = []  # (facet, matched_token)
for facet in facets:
    if not facet_kill_switch_active(facet["kill_switch_env"]):
        continue  # this facet row's own kill switch is on -- skip only this row
    pattern = re.compile(facet["target_path_regex"])
    for c in candidate_paths():
        norm = gate_lib.gate_normalize_path(root, c)
        if norm is not None and pattern.match(norm):
            matched_facets.append((facet, c))
            break

if not matched_facets:
    sys.exit(0)

if tool == "Bash":
    names = ", ".join(f["hook"] for f, _c in matched_facets)
    deny(
        f"a Bash-tool command targets a file governed by facet-keyword row(s) [{names}], "
        "and the gate cannot reconstruct a Bash-written file's resulting content to check "
        "it; refusing an unverifiable write rather than passing it through"
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
        deny("cannot determine resulting content (base file unreadable)")

new_text, ok = gate_lib.gate_reconstruct_write(tool, ti, current_content)
if not ok or new_text is None:
    deny(
        f"this write targets a facet-keyword-governed file but the gate cannot determine "
        f"the resulting content from the tool input (tool={tool!r})"
    )

for facet, _c in matched_facets:
    checker = CHECKERS[facet["check_type"]]
    msg = checker(facet, new_text)
    if msg is not None:
        deny(msg)

sys.exit(0)
PYEOF
PY_EXIT=$?

trap - EXIT
exit "$PY_EXIT"
