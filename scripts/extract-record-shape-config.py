#!/usr/bin/env python3
"""Mechanical extractor for the record-section-shape family fold (issue #263).

Reads the 145 (rulebook, hook file) pairs from
docs/issue-263/reports/implementation/survey.md's table, and for each
source hook:

  - classifies it into one of the four check_types the phase-1 survey
    found (checklist_entry_fields, section_markers_conditional,
    field_literal_token_cooccurrence, methodology_checklist_gated) by
    regexing for that shape's literal patterns;
  - extracts its target_path_regex (the docs/issue-<n>/... path pattern
    the source hook itself matches against) and kill_switch_env (the
    source hook's own *_OFF env var name);
  - assigns a confidence column (high = single clean shape match plus
    both path/kill-switch extracted cleanly; low = ambiguous shape,
    defaulted shape, or a path/kill-switch that could not be extracted
    by regex and needs a hand read).

Prints a summary table to stdout (the acceptance criterion's "extractor
command executed-live") and, with --json, the full config object.

Usage:
    python3 scripts/extract-record-shape-config.py [--rulebooks-root DIR]
    python3 scripts/extract-record-shape-config.py --json > config.json
"""
import argparse
import json
import os
import re
import sys

SURVEY = "docs/issue-263/reports/implementation/survey.md"
DEFAULT_RULEBOOKS_ROOT = os.path.expanduser("~/tokenmaxxxer/rulebooks")

ROW_RE = re.compile(r"^\|\s*([a-z0-9-]+)\s*\|\s*`([^`]+)`\s*\|\s*$")

KILL_SWITCH_RE = re.compile(r"\$\{?([A-Z0-9_]+_OFF)\b")
PATH_RE_RE = re.compile(
    r"docs/issue[^\n\"']{0,60}(?:reports|proposals)/[a-zA-Z0-9._\\+\[\]*-]+\.md"
)


def load_hook_list(survey_path):
    hooks = []
    with open(survey_path, encoding="utf-8") as f:
        for line in f:
            m = ROW_RE.match(line.rstrip("\n"))
            if m:
                hooks.append((m.group(1), m.group(2)))
    return hooks


def classify(src, filename=""):
    has_checklist_marker = bool(re.search(
        r"required_keys|checklist.{0,20}entry|criterion|entry_regex|per.entry", src, re.I))
    has_section_heading_regex = bool(re.search(
        r"#\{1,6\}|required_sections|section.{0,10}marker|heading_regex|next_heading"
        r"|required.{0,15}fields?|LOOP_STATES|required_frontmatter", src, re.I))
    has_frontmatter_gate = bool(re.search(r"loop_state", src))
    has_topic_trigger = bool(re.search(
        r"kimball|inmon|datavault|dimensional model|star schema|stride|nielsen|meddpicc", src, re.I))
    has_token_cooccurrence = bool(re.search(
        r"Sunset.{0,80}Deprecation|N/A.{0,10}net new|co.?occur", src, re.I | re.S))
    is_methodology_filename = filename.endswith("methodology-gate.sh")

    bundled_unrelated = bool(re.search(r"curl |requests\.get|subprocess\.run|urllib", src))

    score = {
        "checklist_entry_fields": 0,
        "section_markers_conditional": 0,
        "field_literal_token_cooccurrence": 0,
        "methodology_checklist_gated": 0,
    }
    if has_checklist_marker:
        score["checklist_entry_fields"] += 2
    if has_section_heading_regex:
        score["section_markers_conditional"] += 2
    if has_frontmatter_gate:
        score["section_markers_conditional"] += 1
    if has_token_cooccurrence:
        score["field_literal_token_cooccurrence"] += 3
    if has_topic_trigger:
        score["methodology_checklist_gated"] += 3
    if is_methodology_filename:
        score["methodology_checklist_gated"] += 1

    best = max(score, key=score.get)
    top = score[best]
    ties = [k for k, v in score.items() if v == top]

    if top == 0:
        return "section_markers_conditional", "low", "no clean single-shape signal; defaulted, needs hand read"
    if len(ties) > 1:
        if is_methodology_filename and "methodology_checklist_gated" in ties:
            return "methodology_checklist_gated", "high", "tie broken by methodology-gate.sh filename convention"
        return best, "low", "ambiguous between %s" % ties
    if bundled_unrelated:
        return best, "low", "bundled unrelated logic (network/subprocess call) detected"
    return best, "high", ""


def extract_fields(check_type, src):
    fields = {}
    if check_type == "checklist_entry_fields":
        keys = sorted(set(re.findall(r'"([a-z_]+)"\s*[:=]', src, re.I)))
        fields["required_keys"] = keys[:12]
    elif check_type == "section_markers_conditional":
        markers = re.findall(r'"(##?\s*[A-Za-z][^"\n]{2,60})"', src)
        fields["required_sections"] = sorted(set(markers))[:12]
        fields["loop_state_gated"] = "loop_state" in src
    elif check_type == "field_literal_token_cooccurrence":
        tokens = re.findall(r'"([A-Z][a-zA-Z ]{2,20})"', src)
        fields["required_tokens"] = sorted(set(tokens))[:8]
    elif check_type == "methodology_checklist_gated":
        topics = re.findall(r"\b(kimball|inmon|datavault|dimensional model|star schema)\b", src, re.I)
        fields["topic_tokens"] = sorted(set(t.lower() for t in topics))
    return fields


def extract_path_and_switch(src, rulebook, hookpath):
    ks_m = KILL_SWITCH_RE.search(src)
    path_m = PATH_RE_RE.search(src)
    ks_ok = bool(ks_m)
    path_ok = bool(path_m)
    kill_switch_env = ks_m.group(1) if ks_m else (
        re.sub(r"[^A-Z0-9]+", "_", (rulebook + "_" + os.path.basename(hookpath)).upper()) + "_GATE_OFF"
    )
    if path_m:
        target_path_regex = path_m.group(0)
    else:
        slug = rulebook.replace("-rulebook", "")
        target_path_regex = r"docs/issue-[0-9]+/reports/%s\.md" % re.escape(slug)
    return kill_switch_env, target_path_regex, ks_ok, path_ok


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--rulebooks-root", default=DEFAULT_RULEBOOKS_ROOT)
    ap.add_argument("--survey", default=SURVEY)
    ap.add_argument("--json", action="store_true", help="also print the config JSON to stderr")
    args = ap.parse_args()

    hooks = load_hook_list(args.survey)
    rows = []
    for rulebook, relpath in hooks:
        full = os.path.join(args.rulebooks_root, rulebook, relpath)
        try:
            with open(full, encoding="utf-8", errors="replace") as f:
                src = f.read()
        except OSError as e:
            rows.append({
                "rulebook": rulebook, "hook": relpath, "check_type": "section_markers_conditional",
                "confidence": "low", "note": "unreadable: %s" % e,
                "kill_switch_env": "UNKNOWN_GATE_OFF", "target_path_regex": "docs/issue-[0-9]+/.*\\.md",
                "fields": {},
            })
            continue
        check_type, confidence, note = classify(src, filename=relpath)
        kill_switch_env, target_path_regex, ks_ok, path_ok = extract_path_and_switch(src, rulebook, relpath)
        if not (ks_ok and path_ok) and confidence == "high":
            confidence = "low"
            note = (note + "; " if note else "") + "path/kill-switch not cleanly regex-extracted"
        fields = extract_fields(check_type, src)
        rows.append({
            "rulebook": rulebook, "hook": relpath,
            "check_type": check_type, "confidence": confidence, "note": note,
            "kill_switch_env": kill_switch_env, "target_path_regex": target_path_regex,
            "fields": fields,
        })

    print("%-30s %-55s %-32s %-20s %s" % ("rulebook", "hook", "check_type", "confidence", "note"))
    for r in rows:
        print("%-30s %-55s %-32s %-20s %s" % (
            r["rulebook"], r["hook"], r["check_type"], r["confidence"], r["note"],
        ))
    high = sum(1 for r in rows if r["confidence"] == "high")
    low = sum(1 for r in rows if r["confidence"] == "low")
    print("\ntotal=%d high=%d low=%d" % (len(rows), high, low))

    if args.json:
        print(json.dumps(rows, indent=2), file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
