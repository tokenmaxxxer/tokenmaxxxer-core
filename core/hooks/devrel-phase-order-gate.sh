#!/usr/bin/env bash
# PreToolUse(Write|Edit|MultiEdit|Bash) gate: docs/issue-<n>/proposals/*.md
# may not be written before docs/issue-<n>/reports/devrel/survey.md exists
# (phase-1 order: survey -> scout -> proposal).
#
# gate-lib adoption (issue-13 A+ remediation, core issue-72 gate-house
# standard): sources core's gate-lib.sh for trap/kill-switch/path-normalize
# instead of hand-rolling them. The judgment here never depended on the
# write's resulting content (only sibling-file existence), so the old
# compute_content() reconstruction — whose result was discarded into `_` and
# never consulted — is removed rather than repaired; see the issue-13
# proposal's Alternatives.

. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)}/hooks/lib/gate-lib.sh" || { echo "phase-order-gate.sh: cannot source gate-lib.sh" >&2; exit 2; }
gate_trap_fail_closed
set -uo pipefail

gate_kill_switch_active "${PHASE_ORDER_GATE_OFF:-}" || { trap - EXIT; exit 0; }

command -v python3 >/dev/null 2>&1 || gate_deny "phase-order-gate" "python3 is required and not on PATH; failing closed."

payload="$(cat 2>/dev/null || true)"

root="$(git rev-parse --show-toplevel 2>/dev/null || pwd -P)"

command_str="$(printf '%s' "$payload" | python3 -c '
import json, sys
try:
    d = json.loads(sys.stdin.read())
except Exception:
    d = {}
ti = d.get("tool_input") if isinstance(d, dict) else None
print(ti.get("command", "") if isinstance(ti, dict) and d.get("tool_name") == "Bash" else "")
' 2>/dev/null || true)"

bash_targets=""
if [ -n "$command_str" ]; then
  bash_targets="$(gate_bash_write_targets "$command_str")"
fi

GL_PAYLOAD="$payload" GL_ROOT="$root" GL_BASH_TARGETS="$bash_targets" GATE_LIB_PY="$GATE_LIB_PY" \
python3 <<'PY'
import sys
try:
    import json, os, posixpath, re, importlib.util

    def deny(m):
        sys.stderr.write("phase-order-gate: refused — %s\n" % m)
        sys.exit(2)

    _spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
    gate_lib = importlib.util.module_from_spec(_spec)
    _spec.loader.exec_module(gate_lib)

    raw = os.environ.get("GL_PAYLOAD", "")
    ev = gate_lib.gate_parse_json_or_deny(raw, deny)

    tool = ev.get("tool_name")
    ti = ev.get("tool_input")
    if not isinstance(ti, dict):
        sys.exit(0)

    root = os.environ["GL_ROOT"]
    TARGET_RE = re.compile(r'^(docs/issue-[^/]+)/proposals/.*devrel.*\.md$', re.I)

    candidates = []
    if tool in ("Write", "Edit", "MultiEdit"):
        p = ti.get("file_path")
        if isinstance(p, str) and p:
            candidates.append(p)
    elif tool == "Bash":
        candidates.extend(
            t.strip() for t in os.environ.get("GL_BASH_TARGETS", "").splitlines() if t.strip()
        )

    issue_root = None
    for c in candidates:
        rel = gate_lib.gate_normalize_path(root, c)
        if rel is None:
            continue
        m = TARGET_RE.match(rel)
        if m:
            issue_root = m.group(1)
            break

    if issue_root is None:
        sys.exit(0)

    survey_path = posixpath.join(root, issue_root, "reports", "devrel", "survey.md")
    if os.path.isfile(survey_path):
        sys.exit(0)

    deny(
        "docs/issue-<n>/proposals/*.md written before %s/reports/devrel/survey.md "
        "exists — write survey.md first (phase-1 order: survey -> scout -> proposal)."
        % issue_root
    )
except SystemExit:
    raise
except Exception as e:
    sys.stderr.write("phase-order-gate: fail-closed: internal error: %r\n" % (e,))
    sys.exit(2)
PY
rc=$?
if [ "$rc" -ne 0 ] && [ "$rc" -ne 2 ]; then
  echo "phase-order-gate: refused — fail-closed: internal error (judge exited $rc)" >&2
  exit 2
fi
exit "$rc"
