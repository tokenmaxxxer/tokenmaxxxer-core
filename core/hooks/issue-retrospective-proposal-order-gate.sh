#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)}/hooks/lib/gate-lib.sh" || { echo "proposal-order-gate.sh: cannot source gate-lib.sh" >&2; exit 2; }
gate_trap_fail_closed
# PreToolUse gate (Write|Edit|MultiEdit) -- one plugin, one methodology
# (issue #18 plugin-set design; order-constraint pattern adopted from
# implementation-rulebook/coding/hooks/coding-progress-gate.sh: state via
# direct file-read of the subject's own phase-1 proposal, no new
# persistent state file).
#
# Owns: phase ordering (phase-1-before-phase-2, contract v3 s19). Guards
# the phase-2 record write by reading the subject's own phase-1 proposal
# directly off disk and requiring it to name a survey path, plus either a
# scout-brief path or an explicit scout-skip statement.
#
# Write surface: docs/issue-<n>/reports/issue-retrospective.md (the
# 산출물/record surface -- this plugin guards the NEXT surface, the
# 기획서/proposal it reads, not the proposal write itself). Additive to
# (never replacing) core's generic record-fields-gate.sh.
#
# Kill switch: export ISSUE_RETROSPECTIVE_PROPOSAL_ORDER_GATE_OFF=1
set -uo pipefail

role="${CLAUDE_ROLE:-issue-retrospective}"
deny() { gate_deny "$role" "$1"; }

gate_kill_switch_active "${ISSUE_RETROSPECTIVE_PROPOSAL_ORDER_GATE_OFF:-}" || { trap - EXIT; exit 0; }

command -v python3 >/dev/null 2>&1 || deny "proposal-order-gate.sh requires python3, which is not on PATH; denying rather than guessing."

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || deny "proposal-order-gate: empty tool-use payload on stdin; cannot evaluate the gate."

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
[ -z "$root" ] && deny "no project root could be determined; failing closed (proposal-order check cannot run)."

PG_PAYLOAD="$payload" PG_ROOT="$root" \
python3 <<'PY'
import sys as _fc_sys  # fail-closed-on-internal-error
try:
    import json, os, posixpath, re, sys, importlib.util

    _spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
    gate_lib = importlib.util.module_from_spec(_spec)
    _spec.loader.exec_module(gate_lib)

    def deny(m):
        sys.stderr.write("issue-retrospective: refused — %s\n" % m); sys.exit(2)

    raw = os.environ.get("PG_PAYLOAD", "")
    ev = gate_lib.gate_parse_json_or_deny(raw, deny)

    tool = ev.get("tool_name")
    ti = ev.get("tool_input")
    if not isinstance(ti, dict):
        deny("tool_input is missing or not a JSON object; the gate cannot judge a write it cannot parse (phase ordering).")

    root = os.environ["PG_ROOT"]
    RECORD_RE = re.compile(r'^docs/issue-([0-9]+)/reports/issue-retrospective\.md$')

    path = None
    if tool in ("Write", "Edit", "MultiEdit"):
        p = ti.get("file_path")
        if isinstance(p, str) and p:
            path = p
    if path is None:
        sys.exit(0)

    rel = gate_lib.gate_normalize_path(root, path)
    if rel is None:
        sys.exit(0)
    m = RECORD_RE.match(rel)
    if not m:
        sys.exit(0)  # not the record write surface — not this plugin's business

    subject_n = m.group(1)
    prop_dir = posixpath.join(root, "docs", "issue-%s" % subject_n, "proposals")
    prop_path = None
    if os.path.isdir(prop_dir):
        for name in sorted(os.listdir(prop_dir)):
            if "issue-retrospective" in name.lower() and name.lower().endswith(".md"):
                prop_path = posixpath.join(prop_dir, name)
                break

    if prop_path is None or not os.path.isfile(prop_path):
        deny(
            "issue-retrospective record write for subject issue-%s targets %s but no phase-1 "
            "proposal (docs/issue-%s/proposals/*issue-retrospective*.md) exists on "
            "disk. Per contract v3 s19, phase 1 (proposal) must precede phase 2 "
            "(record)." % (subject_n, rel, subject_n)
        )

    try:
        with open(prop_path, encoding="utf-8-sig") as fh:
            prop_text = fh.read(1 << 20)
    except OSError:
        deny(
            "issue-retrospective record write for subject issue-%s targets %s but its phase-1 "
            "proposal at %s exists and cannot be read; failing closed on phase "
            "ordering." % (subject_n, rel, prop_path[len(root):].lstrip("/"))
        )

    low = prop_text.lower()
    names_survey = bool(re.search(r'reports/issue-retrospective/survey\.md|current-state survey', low))
    names_scout = bool(re.search(r'scout-brief\.md', low))
    explicit_skip = bool(re.search(r'scout(ing)? (was )?skipped|no design decision', low))

    if not names_survey:
        deny(
            "phase-1 proposal for subject issue-%s (%s) does not name a survey path "
            "(docs/issue-%s/reports/issue-retrospective/survey.md). Per contract v3 "
            "s19, a phase-2 record write requires its own phase-1 proposal to name "
            "the survey it read." % (subject_n, prop_path[len(root):].lstrip("/"), subject_n)
        )
    if not (names_scout or explicit_skip):
        deny(
            "phase-1 proposal for subject issue-%s (%s) names no scout-brief path and "
            "no explicit scout-skip statement. Per the platform scout directive, a "
            "phase-1 proposal must either link its scout brief or record why scouting "
            "was skipped." % (subject_n, prop_path[len(root):].lstrip("/"))
        )

    sys.exit(0)
except Exception as _fc_e:  # fail-closed-on-internal-error
    _fc_sys.stderr.write("proposal-order-gate.sh: fail-closed: internal error: %r\n" % (_fc_e,))
    _fc_sys.exit(2)
PY
_fc_rc=$?  # fail-closed-on-internal-error
if [ "$_fc_rc" -ne 0 ] && [ "$_fc_rc" -ne 2 ]; then
  echo "proposal-order-gate.sh: fail-closed: internal error (judge exited $_fc_rc)" >&2
  exit 2
fi
exit "$_fc_rc"
