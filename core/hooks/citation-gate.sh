#!/usr/bin/env bash
# PreToolUse gate: parameterized fold of the 11 citation-sourcing-family
# hooks (issue #260, phase-4b-3) — api-design's evidence-citation-gate,
# architecture's arch-citation-gate, capacity-planning's
# capacity-order-enforcement citation-gate, conformance-review's
# review-traceability gate, finance-unit-economics' evidence-chain-gate,
# interaction-design's id-citation-format + id-traceability gates,
# requirements-engineering's traceability-matrix-gate,
# security-threat-model's canon-citation methodology-gate,
# technical-feasibility's evidence-citation gate, and test-authoring's
# traceability-line gate. Behavior-equivalent per hook under its own row
# of core/hooks/citation-config.json — a flat list (issue #331: the role
# axis is retired here; a row applies whenever its OWN target_path_regex
# matches the write, never gated on who/what the acting session is).
#
# Promote-first: none of the 11 source hooks or their rulebooks'
# hooks.json entries are touched by this fold; they keep running
# unmodified.
#
# Empty-state / no-config-file: a missing/unreadable/empty config file
# passes through silently (exit 0) — same as a row whose target-path
# regex never matches.
#
# Kill switch (whole gate): export CITATION_GATE_OFF=1
# Kill switch (one row): its own kill_switch_env, e.g.
#   export ARCH_CITATION_GATE_OFF=1
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)}/hooks/lib/gate-lib.sh" || { echo "citation-gate.sh: cannot source gate-lib.sh" >&2; exit 2; }
gate_trap_fail_closed
set -uo pipefail
gate_kill_switch_active "${CITATION_GATE_OFF:-}" || { trap - EXIT; exit 0; }

command -v python3 >/dev/null 2>&1 || gate_deny "citation-gate" "python3 not found; cannot evaluate gate"

CIT_CONFIG="${CITATION_CONFIG:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/citation-config.json}"
export CIT_CONFIG
export CIT_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
export CIT_BRANCH="$(git -C "${CLAUDE_PROJECT_DIR:-$(pwd)}" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"

# payload travels via env, never re-read from stdin inside the heredoc
# below (issue #245 bash-3.2 guard: no heredoc-in-command-substitution).
CIT_PAYLOAD="$(cat 2>/dev/null || true)"
export CIT_PAYLOAD

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

GATE_NAME = "citation-gate"


def deny(msg):
    # issue-282 DEMOTE: advisory only -- detection logic is unchanged but
    # this gate no longer blocks the tool call. The finding surfaces via
    # additionalContext/systemMessage instead of a permission denial.
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
config_path = os.environ["CIT_CONFIG"]
try:
    with open(config_path, "r", encoding="utf-8") as f:
        config = json.load(f)
except (OSError, ValueError):
    sys.exit(0)

rows = config if isinstance(config, list) else None
if not rows:
    sys.exit(0)  # no rows configured, or config is still the old role-keyed
                 # shape -- empty state

root = os.environ.get("CIT_PROJECT_DIR") or os.getcwd()
branch = os.environ.get("CIT_BRANCH", "")
raw = os.environ.get("CIT_PAYLOAD", "")
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


matched_rows = []  # (row, matched_path)
for row in rows:
    if not row_kill_switch_active(row["kill_switch_env"]):
        continue
    pattern = re.compile(row["target_path_regex"])
    for c in candidate_paths():
        norm = gate_lib.gate_normalize_path(root, c)
        if norm is not None and pattern.match(norm):
            matched_rows.append((row, norm))
            break

if not matched_rows:
    sys.exit(0)

if tool == "Bash":
    bash_rows = [(r, p) for r, p in matched_rows if r.get("bash_write_refuses")]
    if bash_rows:
        names = ", ".join(r["hook"] for r, _p in bash_rows)
        deny(
            f"a Bash-tool command targets a file governed by citation-sourcing row(s) "
            f"[{names}], and the gate cannot reconstruct a Bash-written file's "
            "resulting content to check it; refusing an unverifiable write rather "
            "than passing it through"
        )
    sys.exit(0)

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
        f"this write targets a citation-sourcing-governed file but the gate cannot "
        f"determine the resulting content from the tool input (tool={tool!r})"
    )


# --- per-check_type evaluators; each returns None (ok) or a deny message --

def para_of(text, offset):
    start = text.rfind("\n\n", 0, offset)
    start = 0 if start == -1 else start + 2
    end = text.find("\n\n", offset)
    end = len(text) if end == -1 else end
    return text[start:end]


def check_claim_adjacent_marker(row, text):
    scope = row.get("scope", "paragraph")
    claim_re = re.compile(row["claim_regex"], re.I)
    marker_res = [re.compile(p, re.I) for p in row["marker_regexes"]]

    if scope == "paragraph":
        missing = []
        for para in re.split(r"\n\s*\n", text):
            if claim_re.search(para):
                if not any(mr.search(para) for mr in marker_res):
                    snippet = para.strip().splitlines()[0][:80] if para.strip() else "(empty)"
                    missing.append(f"a claim with no named source (paragraph starting: {snippet})")
        if missing:
            return row["deny_message_template"].format(missing="; ".join(missing))
        return None

    # scope == "section_or_window" (architecture): section-scoped, or a
    # bounded line window when the file carries no headings.
    trigger_matches = list(claim_re.finditer(text))
    if not trigger_matches:
        return None
    heading_re = re.compile(r"^#{1,6}\s.*$", re.M)
    window = row.get("window_lines", 15)

    def has_marker(span):
        return any(mr.search(span) for mr in marker_res)

    headings = list(heading_re.finditer(text))
    uncited = None
    if headings:
        blocks = []
        if headings[0].start() > 0:
            blocks.append((0, headings[0].start()))
        for i, h in enumerate(headings):
            start = h.start()
            end = headings[i + 1].start() if i + 1 < len(headings) else len(text)
            blocks.append((start, end))

        def find_block(offset):
            for start, end in blocks:
                if start <= offset < end:
                    return start, end
            return 0, len(text)

        for m in trigger_matches:
            start, end = find_block(m.start())
            if not has_marker(text[start:end]):
                uncited = m
                break
    else:
        line_starts = [0]
        for idx, ch in enumerate(text):
            if ch == "\n":
                line_starts.append(idx + 1)
        total_lines = len(line_starts)
        line_starts.append(len(text) + 1)
        for m in trigger_matches:
            ln = text.count("\n", 0, m.start())
            lo_line = max(0, ln - window)
            hi_line = min(total_lines - 1, ln + window)
            win_start = line_starts[lo_line]
            win_end = line_starts[hi_line + 1] if hi_line + 1 < len(line_starts) else len(text)
            if not has_marker(text[win_start:win_end]):
                uncited = m
                break

    if uncited is not None:
        return row["deny_message_template"].format(trigger=uncited.group(0))
    return None


def check_whole_doc_metric_source_and_paragraph_pair(row, text):
    low = text.lower()
    if not any(n in low for n in row["trigger_needles"]):
        return None
    missing = []
    if not any(n in low for n in row["source_needles"]):
        missing.append("source-or-assumption-label")
    mandate_words = row["mandate_words"]
    causal_words = row["causal_words"]
    chain_ok = False
    for para in re.split(r"\n\s*\n", low):
        if any(w in para for w in mandate_words) and any(w in para for w in causal_words):
            chain_ok = True
            break
    if not chain_ok:
        missing.append("evidence-to-mandate-chain")
    if missing:
        return row["deny_message_template"].format(missing=", ".join(missing))
    return None


def check_section_required_fields(row, text):
    heading_re = re.compile(row["heading_regex"], re.I | re.M)
    m = heading_re.search(text)
    if not m:
        return row["no_heading_message"]
    body_start = m.end()
    next_heading = re.search(r"^#+\s", text[body_start:], re.M)
    body = text[body_start: body_start + next_heading.start()] if next_heading else text[body_start:]
    if not body.strip():
        return row["blank_body_message"]
    missing = []
    for field in row["required_fields"]:
        if not re.search(field["regex"], body, re.I):
            missing.append(field["detail"])
    if missing:
        return row["deny_message_template"].format(missing="; ".join(missing))
    return None


def check_whole_doc_keyword_and_ref_plus_branch(row, text):
    low = text.lower()
    keyword_present = any(n in low for n in row["keyword_needles"])
    ref_re = re.compile(row["issue_ref_regex"])
    refs = ref_re.findall(text)
    ref_numbers = [a or b for (a, b) in refs]
    if not (keyword_present and ref_numbers):
        return row["missing_message"]
    branch_m = re.match(row["branch_regex"], branch)
    if branch_m:
        branch_issue = branch_m.group(1)
        if branch_issue not in ref_numbers:
            return row["branch_mismatch_message_template"].format(
                refs=", ".join(sorted(set(ref_numbers))), branch=branch, branch_issue=branch_issue
            )
    return None


def check_table_req_membership(row, text):
    low = text.lower()
    needle = row["section_needle"]
    if needle not in low:
        return row["no_section_message"]

    heading_re = re.compile(r"^(#{1,6})[ \t]+.*$", re.M)
    headings = list(heading_re.finditer(text))
    start_idx = low.index(needle)
    matrix_heading = None
    for hm in headings:
        if hm.start() <= start_idx <= hm.end():
            matrix_heading = hm
            break
    if matrix_heading is None:
        preceding = [hm for hm in headings if hm.end() <= start_idx]
        matrix_heading = preceding[-1] if preceding else None

    if matrix_heading is not None:
        level = len(matrix_heading.group(1))
        section_start = matrix_heading.start()
        section_end = len(text)
        for hm in headings:
            if hm.start() > matrix_heading.start() and len(hm.group(1)) <= level:
                section_end = hm.start()
                break
        section_text = text[section_start:section_end]
    else:
        section_text = text

    header_line_re = re.compile(r"^[ \t]*\|.*\|[ \t]*$")
    sep_line_re = re.compile(r"^[ \t]*\|(?:[\s:-]+\|)+[ \t]*$")
    sec_lines = section_text.splitlines()
    header_idx = None
    for idx in range(len(sec_lines) - 1):
        if header_line_re.match(sec_lines[idx]) and sep_line_re.match(sec_lines[idx + 1]):
            header_idx = idx
            break
    if header_idx is None:
        return row["no_table_message"]

    header_cells = [c.strip().lower() for c in sec_lines[header_idx].strip().strip("|").split("|")]

    def col_present(aliases):
        return any(cell in aliases for cell in header_cells)

    missing_cols = [c["label"] for c in row["columns"] if not col_present(c["aliases"])]
    if missing_cols:
        return row["missing_columns_message_template"].format(missing=", ".join(missing_cols))

    req_re = re.compile(row["req_id_regex"])
    all_req_ids = set(req_re.findall(text))
    matrix_ids = set(req_re.findall(section_text))
    missing_rows = all_req_ids - matrix_ids
    if missing_rows:
        return row["missing_row_message_template"].format(missing=", ".join(sorted(missing_rows)))

    if not row.get("reference_shape_check"):
        return None

    def col_index(aliases):
        for i, cell in enumerate(header_cells):
            if cell in aliases:
                return i
        return None

    source_idx = col_index(("source",))
    link_idx = col_index(("downstream link", "downstream", "link"))
    status_idx = col_index(tuple(row.get("status_column_aliases", ["status"])))

    def split_row(line):
        return [c.strip() for c in line.strip().strip("|").split("|")]

    data_rows = []
    for i in range(header_idx + 2, len(sec_lines)):
        line = sec_lines[i]
        if not header_line_re.match(line):
            break
        data_rows.append(split_row(line))

    not_yet_linked_re = re.compile(r"^\s*not yet linked\s*$", re.I)
    url_re = re.compile(r"^[a-z][a-z0-9+.\-]*://", re.I)
    sha_re = re.compile(r"^[0-9a-f]{7,40}$", re.I)
    citation_re = re.compile(r"\[.+\]\(.+\)")
    bracket_re = re.compile(r"^\[.+\]$")

    def looks_reference_shaped(value):
        v = value.strip()
        if not v:
            return True
        if not_yet_linked_re.match(v):
            return True
        if url_re.match(v):
            return False
        if citation_re.search(v) or bracket_re.match(v):
            return True
        if sha_re.match(v):
            return True
        if (("/" in v) or ("." in v)) and (" " not in v):
            return True
        return False

    def cell_at(row_cells, idx):
        return row_cells[idx] if idx is not None and idx < len(row_cells) else ""

    for row_cells in data_rows:
        req_id = cell_at(row_cells, header_cells.index("id")) if "id" in header_cells else "?"
        for label, idx in (("Source", source_idx), ("Downstream Link", link_idx)):
            value = cell_at(row_cells, idx)
            if not value.strip():
                continue
            if not looks_reference_shaped(value):
                return row["shape_deny_message_template"].format(req_id=req_id, label=label, value=value)
        if status_idx is not None:
            status_value = cell_at(row_cells, status_idx)
            if not status_value.strip():
                return row["empty_status_message_template"].format(req_id=req_id)
    return None


def check_sequencing_filename_anchor(row, text, rel):
    if re.match(row["survey_exempt_regex"], rel):
        return None
    anchor = row["anchor_regex"]
    window = row.get("anchor_window", 200)

    def adjacent(name):
        return bool(re.search(anchor + r".{0," + str(window) + r"}?" + name, text, re.I | re.M | re.S)) or \
            bool(re.search(name + r".{0," + str(window) + r"}?" + anchor, text, re.I | re.M | re.S))

    if re.match(row["scout_brief_regex"], rel):
        if not re.search(row["terminal_trigger_regex"] + "|" + row["scout_brief_extra_trigger_regex"], text, re.I | re.M):
            return None
        missing = [n for n in row["scout_brief_required_names"] if not adjacent(n)]
        if missing:
            return row["deny_message_template"].format(missing="scout-brief.md must cite survey.md adjacent to an anchor marker")
        return None

    if re.match(row["proposal_regex"], rel):
        if not re.search(row["terminal_trigger_regex"] + "|" + row["proposal_extra_trigger_regex"], text, re.I | re.M):
            return None
        missing = []
        for n in row["proposal_required_names"]:
            if not adjacent(n):
                missing.append(f"proposal does not cite {n.replace(chr(92), '')} adjacent to an anchor marker")
        if missing:
            return row["deny_message_template"].format(missing="; ".join(missing))
    return None


def check_verdict_field_required_plus_list_shape(row, text, rel):
    if re.match(row["phase1_regex"], rel):
        bullet_hits = len(re.findall(row["phase1_bullet_regex"], text, re.M))
        numbered_hits = len(re.findall(row["phase1_numbered_regex"], text, re.M))
        has_list = (bullet_hits + numbered_hits) >= row["phase1_min_list_items"]
        has_sampling = bool(re.search(row["phase1_sampling_regex"], text, re.I))
        if not (has_list or has_sampling):
            return row["phase1_deny_message"]
        return None

    verdict_re = re.compile(row["verdict_line_regex"])
    matches = list(verdict_re.finditer(text))
    if not matches:
        return None
    blocks = re.split(row["block_split_regex"], text, flags=re.M)
    offsets = []
    cursor = 0
    for b in blocks:
        idx = text.find(b, cursor)
        if idx == -1:
            idx = cursor
        offsets.append((idx, idx + len(b), b))
        cursor = idx + len(b)

    def block_for(pos):
        for start, end, b in offsets:
            if start <= pos < end:
                return b
        return text

    for m in matches:
        verdict = m.group(1)
        block = block_for(m.start())
        if not re.search(row["spec_ref_regex"], block):
            return row["missing_spec_ref_message"].format(verdict=verdict)
        if verdict.lower() != row["unverifiable_value"]:
            if not re.search(row["evidence_regex"], block):
                return row["missing_evidence_message"].format(verdict=verdict)
    return None


def check_bullet_adjacent_plus_doc_sources(row, text):
    trigger_re = re.compile(row["trigger_regex"], re.I)
    cite_re = re.compile(row["cite_regex"], re.I)
    sources_heading_re = re.compile(row["sources_heading_regex"], re.I)
    heading_re = re.compile(row["heading_regex"])
    no_access_re = re.compile(row["no_access_regex"], re.I)
    url_or_path_re = re.compile(row["url_or_path_regex"])

    lines = text.splitlines()
    for i, line in enumerate(lines):
        stripped = line.strip()
        if not (stripped.startswith("-") or stripped.startswith("*")):
            continue
        if not trigger_re.search(stripped):
            continue
        if not cite_re.search(stripped):
            return row["bullet_deny_message_template"].format(line=i + 1, text=stripped)

    prose = "\n".join(line for line in lines if not (line.strip().startswith("-") or line.strip().startswith("*")))

    heading_idx = None
    heading_level = None
    for i, line in enumerate(lines):
        hm = heading_re.match(line)
        if hm and sources_heading_re.match(line):
            heading_idx = i
            heading_level = len(hm.group(1))
            break

    sources_body = None
    if heading_idx is not None:
        body_lines = []
        for line in lines[heading_idx + 1:]:
            hm = heading_re.match(line)
            if hm and len(hm.group(1)) <= heading_level:
                break
            body_lines.append(line)
        sources_body = "\n".join(body_lines)

    no_access_scoped = bool(no_access_re.search(prose)) or (
        sources_body is not None and bool(no_access_re.search(sources_body))
    )

    if not no_access_scoped:
        if heading_idx is None:
            return row["no_sources_heading_message"]
        if not url_or_path_re.search(sources_body):
            return row["empty_sources_heading_message"]
    return None


def check_anti_pattern_section(row, text):
    marker_re = re.compile(row["marker_regex"], re.I | re.M)
    m = marker_re.search(text)
    if not m:
        return None
    heading_line = text[m.start():m.end()]
    heading_level_match = re.match(r"^\s{0,3}(#{1,6})", heading_line)
    section_start = m.end()
    if heading_level_match:
        level = len(heading_level_match.group(1))
        next_heading_re = re.compile(r"^\s{0,3}#{1,%d}\s+\S" % level, re.M)
    else:
        next_heading_re = re.compile(r"^\s{0,3}#{1,6}\s+\S", re.M)
    rest = text[section_start:]
    nm = next_heading_re.search(rest)
    section_text = rest[:nm.start()] if nm else rest

    problems = []
    if re.search(row["forbidden_shebang_regex"], section_text):
        problems.append("a shebang line (`#!/`)")
    hit_tokens = [t for t in row["forbidden_tokens"] if t in section_text]
    if hit_tokens:
        problems.append("text that looks like a pasted hook script (contains: %s)" % ", ".join(hit_tokens))
    if problems:
        return row["deny_message_template"].format(problems=" and ".join(problems))
    return None


def check_claim_adjacent_marker_phase_scoped(row, text, rel, root):
    claim_re = re.compile(row["claim_line_regex"])
    citation_re = re.compile(row["citation_regex"], re.I)
    adj = row.get("adjacency_lines", 1)

    def is_claim_line(line):
        return bool(claim_re.match(line))

    def line_has_citation(line):
        return bool(citation_re.search(line))

    if re.match(row["phase1_regex"], rel):
        m = re.search(row["phase1_section_heading_regex"], text, re.M | re.I)
        if not m:
            return None
        sec_start = m.end()
        nxt = re.search(r"^##\s+\S", text[sec_start:], re.M)
        sec_end = sec_start + nxt.start() if nxt else len(text)
        section = text[sec_start:sec_end].strip()
        if not section:
            return None
        lines = section.splitlines()
        uncited = []
        for i, line in enumerate(lines):
            if not is_claim_line(line):
                continue
            nearby = lines[max(0, i - adj):i + adj + 1]
            if not any(line_has_citation(l) for l in nearby):
                uncited.append(line.strip())
        if uncited:
            return row["phase1_deny_message_template"].format(missing="; ".join(uncited[:3]))
        return None

    # phase 2
    lines = text.splitlines()
    uncited = []
    for i, line in enumerate(lines):
        if not is_claim_line(line):
            continue
        nearby = lines[max(0, i - adj):i + adj + 1]
        if any(line_has_citation(l) for l in nearby):
            continue
        uncited.append(line.strip())
    if not uncited:
        return None

    m = re.match(row["phase2_regex"], rel)
    issue_n = None
    mm = re.match(r"^docs/issue-([0-9]+)/reports/technical-feasibility\.md$", rel)
    if mm:
        issue_n = mm.group(1)
    proposal_lower = ""
    if issue_n:
        import glob
        pattern = row["phase2_proposal_glob"].format(n=issue_n)
        matches = sorted(glob.glob(os.path.join(root, pattern)))
        if matches:
            try:
                with open(matches[0], "r", encoding="utf-8", errors="replace") as f:
                    proposal_lower = f.read().lower()
            except OSError:
                proposal_lower = ""

    still_uncited = [line for line in uncited if not (proposal_lower and line.lower() in proposal_lower)]
    if still_uncited:
        return row["phase2_deny_message_template"].format(missing="; ".join(still_uncited[:3]))
    return None


CHECKERS = {
    "claim_adjacent_marker": check_claim_adjacent_marker,
    "whole_doc_metric_source_and_paragraph_pair": check_whole_doc_metric_source_and_paragraph_pair,
    "section_required_fields": check_section_required_fields,
    "whole_doc_keyword_and_ref_plus_branch": check_whole_doc_keyword_and_ref_plus_branch,
    "table_req_membership": check_table_req_membership,
}


for row, rel in matched_rows:
    check_type = row["check_type"]
    if check_type in CHECKERS:
        msg = CHECKERS[check_type](row, new_text)
    elif check_type == "sequencing_filename_anchor":
        msg = check_sequencing_filename_anchor(row, new_text, rel)
    elif check_type == "verdict_field_required_plus_list_shape":
        msg = check_verdict_field_required_plus_list_shape(row, new_text, rel)
    elif check_type == "bullet_adjacent_plus_doc_sources":
        msg = check_bullet_adjacent_plus_doc_sources(row, new_text)
    elif check_type == "anti_pattern_section":
        msg = check_anti_pattern_section(row, new_text)
    elif check_type == "claim_adjacent_marker_phase_scoped":
        msg = check_claim_adjacent_marker_phase_scoped(row, new_text, rel, root)
    else:
        deny(f"unknown check_type {check_type!r} in citation-config.json row {row.get('hook')!r}")
    if msg is not None:
        deny(msg)

sys.exit(0)
PYEOF
PY_EXIT=$?

# F14 (issue-305): the fail-closed EXIT trap (gate_trap_fail_closed)
# exists to remap any non-0/2 exit to 2, but disarming it here before
# re-exiting with the raw Python exit code let a config-authoring bug
# (e.g. a bad regex in citation-config.json raising re.error, exit 1)
# bypass the remap entirely -- exit 1 is non-blocking per Claude Code's
# own convention (gate-lib.sh's doc comment), so the whole gate silently
# disabled for that row with only a buried stderr traceback. Leaving the
# trap armed is safe: it only acts when rc is neither 0 nor 2, so a
# legitimate PY_EXIT of 0 or 2 passes through unchanged.
exit "$PY_EXIT"
