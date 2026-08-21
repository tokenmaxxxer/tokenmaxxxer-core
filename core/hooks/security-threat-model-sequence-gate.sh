#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)}/hooks/lib/gate-lib.sh" || { echo "sequence-gate.sh: cannot source gate-lib.sh" >&2; exit 2; }
gate_trap_fail_closed
# ^ fail-closed: the `||` guard on the source line above is what makes a
#   failed source itself deny (exit 2) instead of silently no-op'ing past a
#   missing gate-lib.sh; gate_trap_fail_closed then covers everything after
#   a successful source (core issue-72, adopted here by issue-10; guard
#   mandated by core #75). Any abnormal termination (set -u abort, unbound
#   var) before the verdict logic runs is forced to exit 2 (DENY), since a
#   PreToolUse hook treats any non-2 exit as NON-BLOCKING (fail-OPEN).
#   Installed as the FIRST executable statement, above `set -uo pipefail`.
#   gate-lib.sh is referenced by path, never vendored; sourcing it also
#   exports GATE_LIB_PY for the Python judge below.
#
# PreToolUse gate (Write|Edit|MultiEdit) — base security-threat-model plugin's
# sequence-precondition gate: a phase-1 proposal write must not happen before
# this issue's phase-1 survey exists. Mirrors
# implementation-rulebook/coding/hooks/coding-progress-gate.sh's precondition
# pattern (referenced, not copied) and pricing-rulebook's
# pricing/hooks/methodology-gate.sh's script skeleton.
#
# Targets: docs/issue-<n>/proposals/*security-threat-model*.md only. For any
# other path, this is not this gate's business.
#
# Requires docs/issue-<n>/reports/security-threat-model/survey.md to already
# exist as a file under the project root; denies naming the missing path and
# citing contract v3 s19 rigor floor / scout-directive survey-first-order
# when it does not.
#
# Kill switch: export SECURITY_THREAT_MODEL_SEQUENCE_GATE_OFF=1 (any other
# value — including a typo — leaves the gate ACTIVE, per
# gate_kill_switch_active's fixed on-spelling set 1/true/yes/on).
set -uo pipefail

role="${CLAUDE_ROLE:-security-threat-model}"
deny() { echo "${role}: refused — $1" >&2; exit 2; }

gate_kill_switch_active "${SECURITY_THREAT_MODEL_SEQUENCE_GATE_OFF:-}" || { trap - EXIT; exit 0; }

command -v python3 >/dev/null 2>&1 || deny "sequence-gate.sh requires python3, which is not on PATH; denying rather than guessing."

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || deny "sequence-gate: empty tool-use payload on stdin; cannot evaluate the sequence gate."

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

# `_plausible`/root-detection stays bash-side (issue-10 proposal s3): the
# in-root/out-of-root decision is now made once, by gate_lib.gate_normalize_path
# in the Python judge below, so the old bash-side `_under()` pre-check is gone.
_plausible() { [ -n "$1" ] && [ -d "$1" ] && { [ -e "$1/.git" ] || [ -f "$1/docs/specs/role-handoff-contract.md" ]; }; }

root=""
if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && _plausible "$CLAUDE_PROJECT_DIR"; then
  root="$(cd "$CLAUDE_PROJECT_DIR" 2>/dev/null && pwd -P)"
fi
if [ -z "$root" ]; then
  d="$_target"; [ -n "$d" ] || d="$(pwd -P)"; [ -d "$d" ] || d="$(dirname "$d")"
  root="$(git -C "$d" rev-parse --show-toplevel 2>/dev/null || true)"
fi
[ -z "$root" ] && root="$(git -C "$(pwd -P)" rev-parse --show-toplevel 2>/dev/null || true)"
[ -z "$root" ] && deny "no project root could be determined; failing closed (sequence check cannot run)."

SG_PAYLOAD="$payload" SG_ROOT="$root" GATE_LIB_PY="$GATE_LIB_PY" \
python3 <<'PY'
import sys as _fc_sys  # fail-closed-on-internal-error
try:
    import importlib.util, json, os, posixpath, re, sys

    def deny(m):
        sys.stderr.write("security-threat-model: refused — %s\n" % m); sys.exit(2)

    # core canon gate-lib.py, loaded by path (never vendored) — supplies
    # gate_parse_json_or_deny and gate_normalize_path.
    _spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
    gate_lib = importlib.util.module_from_spec(_spec)
    _spec.loader.exec_module(gate_lib)

    raw = os.environ.get("SG_PAYLOAD", "")
    ev = gate_lib.gate_parse_json_or_deny(raw, deny)

    tool = ev.get("tool_name")
    ti = ev.get("tool_input")
    if not isinstance(ti, dict):
        deny("tool_input is missing or not a JSON object; the gate cannot judge a write it cannot parse (sequence).")

    root = posixpath.normpath(os.path.realpath(os.environ["SG_ROOT"]).replace("\\", "/"))
    PROPOSAL_RE = re.compile(r'^docs/issue-([0-9]+)/proposals/.*security-threat-model.*\.md$', re.I)

    path = None
    if tool in ("Write", "Edit", "MultiEdit"):
        p = ti.get("file_path")
        if isinstance(p, str) and p:
            path = p
    if path is None:
        sys.exit(0)

    # Absolute, relative, and `./`-prefixed file_path all normalize the same
    # way here (core canon gate_normalize_path); None = resolves outside the
    # project root, which is not this gate's business.
    rel = gate_lib.gate_normalize_path(root, path)
    if rel is None:
        sys.exit(0)
    m = PROPOSAL_RE.match(rel)
    if not m:
        sys.exit(0)  # not a phase-1 proposal write surface — not this gate's business

    issue_no = m.group(1)
    survey_rel = "docs/issue-%s/reports/security-threat-model/survey.md" % issue_no
    survey_abs = posixpath.join(root, survey_rel)

    if not os.path.isfile(survey_abs):
        deny(
            "%s is a phase-1 proposal write for issue-%s, but %s does not exist. "
            "Per contract v3 s19 rigor floor / scout-directive survey-first-order, "
            "phase-1 proposals require the survey to exist first." % (rel, issue_no, survey_rel)
        )

    sys.exit(0)
except Exception as _fc_e:  # fail-closed-on-internal-error
    _fc_sys.stderr.write("sequence-gate.sh: fail-closed: internal error: %r\n" % (_fc_e,))
    _fc_sys.exit(2)
PY
_fc_rc=$?  # fail-closed-on-internal-error
if [ "$_fc_rc" -ne 0 ] && [ "$_fc_rc" -ne 2 ]; then
  echo "security-threat-model: refused — fail-closed: internal error (judge exited $_fc_rc)" >&2
  exit 2
fi
exit "$_fc_rc"
