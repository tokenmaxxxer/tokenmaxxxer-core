#!/usr/bin/env bash
__fc(){ rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then echo "fail-closed: gate aborted (rc=$rc)" >&2; exit 2; fi; }
trap __fc EXIT
# PreToolUse gate (Write|Edit|MultiEdit) — contract §20.
#
# On a write whose resolved target is the acting role's own record
# docs/issue-<n>/reports/${CLAUDE_ROLE}.md, parse the PROPOSED content and
# require §20's minimum fields: a "what was done" section, a "why" section,
# the upstream basis, the record's own loop_state, and an open-findings
# section. Whenever loop_state is non-terminal, additionally require a
# next-steps section and an open-finding resolution path.
#
# issue-128: a second, independently-scoped check applies to both a role's
# own record above AND docs/issue-<n>/proposals/*.md (a different artifact
# kind — a proposal write does not run the five checks above). It denies
# any `sha:` line whose value is a bracket placeholder (`^<.*>$`, e.g.
# `<set at commit>`). Per contract §1's same-commit convention, an
# upstream path landing in the same commit as the citing document is
# written as the literal `sha: same-commit`, never a placeholder.
#
# Promoted to core canon (issue-66). The issue-66 survey found this file
# NOT to be pure role-token substitution like trailer-gate.sh/
# handbook-trigger-gate.sh: per-rulebook copies had diverged in message
# prefix (some carried a stale/copy-pasted prefix unrelated to their own
# role — e.g. a "coding" rulebook shipped with prefix "doctrine:", a
# "product" rulebook with "product-cycle:") and in which loop_state values
# count as terminal ({"landed"} in one copy, {"decided","scope-proposed"}
# in another). The message-prefix divergence was a copy-paste bug, not
# intentional role behavior, and is fixed here by deriving the prefix from
# CLAUDE_ROLE unconditionally. The terminal-states divergence looks like
# genuine per-role semantics (a proposal-shaped role may treat
# "scope-proposed" as its own terminal state), so it is kept as
# configuration injected via RECORD_FIELDS_TERMINAL_STATES (space-separated
# loop_state values) rather than silently collapsed to one hardcoded set —
# a rulebook whose terminal states differ from the default sets that env
# var in its own hooks.json, the same "role identity via config, not via
# copy" principle the proposal applies everywhere else in this file.
#
# Kill switch: export RECORD_FIELDS_GATE_OFF=1
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)}/hooks/lib/gate-lib.sh" || { echo "record-fields-gate.sh: cannot source gate-lib.sh" >&2; exit 2; }
set -uo pipefail

role="${CLAUDE_ROLE:-}"
deny() { echo "${role:-record-fields-gate}: refused — $1" >&2; exit 2; }

gate_kill_switch_active "${RECORD_FIELDS_GATE_OFF:-}" || exit 0

[ -n "$role" ] || deny "record-fields-gate: no CLAUDE_ROLE in the environment; the gate cannot resolve which record is this role's own."

command -v python3 >/dev/null 2>&1 || deny "record-fields-gate.sh requires python3, which is not on PATH; denying rather than guessing."

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || deny "record-fields-gate: empty tool-use payload on stdin; cannot evaluate the record-fields gate."

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
[ -z "$root" ] && deny "no project root could be determined; failing closed (§20 field check cannot run)."

RF_PAYLOAD="$payload" RF_ROOT="$root" RF_ROLE="$role" \
RF_TERMINAL="${RECORD_FIELDS_TERMINAL_STATES:-landed}" \
python3 <<'PY'
import sys as _fc_sys  # fail-closed-on-internal-error
try:
    import json, os, posixpath, re, sys

    role = os.environ["RF_ROLE"]

    def deny(m):
        sys.stderr.write("%s: refused — %s\n" % (role, m)); sys.exit(2)

    raw = os.environ.get("RF_PAYLOAD", "")
    try:
        ev = json.loads(raw) if raw else {}
    except ValueError:
        deny("the tool-call payload is not valid JSON; the gate cannot judge §20 fields on an unparseable write.")
    if not isinstance(ev, dict):
        deny("the tool-call payload is not a JSON object; failing closed on §20.")

    tool = ev.get("tool_name")
    ti = ev.get("tool_input")
    if not isinstance(ti, dict):
        deny("tool_input is missing or not a JSON object; the gate cannot judge a write it cannot parse (§20).")

    root = posixpath.normpath(os.environ["RF_ROOT"].replace("\\", "/"))
    RECORDS_RE = re.compile(r'^docs/issue-[0-9]+/reports/%s\.md$' % re.escape(role))
    PROPOSALS_RE = re.compile(r'^docs/issue-[0-9]+/proposals/.*\.md$')
    TERMINAL = set(os.environ["RF_TERMINAL"].split())

    def resolve(p):
        n = p.replace("\\", "/")
        a = n if posixpath.isabs(n) else posixpath.join(root, n)
        a = posixpath.normpath(a)
        try:
            return posixpath.normpath(os.path.realpath(a).replace("\\", "/"))
        except OSError:
            return a

    # Only Write/Edit/MultiEdit reach the record in a form whose full
    # resulting content we can read. A Bash write to the record is out of
    # this gate's scope (board-gate/scope-gate handle Bash); passed through.
    path = None
    if tool in ("Write", "Edit", "MultiEdit", "NotebookEdit"):
        p = ti.get("file_path") or ti.get("notebook_path")
        if isinstance(p, str) and p:
            path = p
    if path is None:
        sys.exit(0)

    r = resolve(path)
    if not (r.startswith(root + "/")):
        sys.exit(0)
    rel = r[len(root):].lstrip("/")
    is_record = bool(RECORDS_RE.match(rel))
    is_proposal = bool(PROPOSALS_RE.match(rel))
    if not (is_record or is_proposal):
        sys.exit(0)  # neither this role's own record nor a proposal — not this gate's business

    current = None
    if os.path.isfile(r):
        try:
            with open(r, encoding="utf-8-sig") as fh:
                current = fh.read(1 << 20)
        except OSError:
            deny("%s exists but cannot be read; failing closed on §20." % rel)

    import importlib.util
    _spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
    gate_lib = importlib.util.module_from_spec(_spec)
    _spec.loader.exec_module(gate_lib)
    new_text, _ok = gate_lib.gate_reconstruct_write(tool, ti, current)

    if new_text is None:
        deny(
            "this write targets %s but the gate cannot determine the resulting content "
            "from the tool input (tool=%r). Write the full record with Write, or use an "
            "Edit/MultiEdit whose old_string matches, so §20 fields can be checked." % (rel, tool)
        )

    def placeholder_shas(text):
        return [m.group(1).strip() for m in re.finditer(r'^\s*sha:\s*(<[^\n]*>)\s*$', text, re.M)]

    def deny_placeholder(bad):
        deny(
            "sha: %s is a bracket placeholder, not a resolvable value (issue-128). Per contract "
            "§1's same-commit convention, write `sha: same-commit` when `path` lands in this same "
            "commit; use the real commit sha once it exists." % bad[0]
        )

    if is_proposal and not is_record:
        bad = placeholder_shas(new_text)
        if bad:
            deny_placeholder(bad)
        sys.exit(0)

    low = new_text.lower()

    def has_any(*needles):
        return any(nd in low for nd in needles)

    missing = []
    if not has_any("what was done", "what i did", "## done", "work done", "summary of work"):
        missing.append("what-was-done")
    if not has_any("why", "rationale", "reason:"):
        missing.append("why")
    if not (has_any("upstream", "based on", "basis:")
            or re.search(r'\b[0-9a-f]{7,40}\b', new_text)
            or "docs/issue-" in new_text):
        missing.append("upstream-basis")
    m_ls = re.search(r'^\s*loop_state:\s*([A-Za-z0-9_-]+)\s*$', new_text, re.M)
    if not m_ls:
        missing.append("loop_state")
    if not has_any("open findings", "open_findings", "open finding"):
        missing.append("open-findings")

    if missing:
        deny(
            "record is missing required section(s): %s. Per contract §20 every role record "
            "must state what was done, why, the concrete upstream basis, its own loop_state, "
            "and open findings." % ", ".join(missing)
        )

    bad = placeholder_shas(new_text)
    if bad:
        deny_placeholder(bad)

    if role in ("coding", "implementation"):
        m_cur = re.search(r'^\s*code_under_review:\s*(.+?)\s*$', new_text, re.M)
        if m_cur and re.match(r'^[0-9a-f]{7,40}$', m_cur.group(1).strip()):
            deny(
                "code_under_review: '%s' is a bare commit sha, not a file list. Per "
                "docs/issue-100/decisions/2026-08-03-record-citation-format-and-kind-convention.md, "
                "this role's own record cites code_under_review as the reviewed file list — the "
                "record's own commit sha does not exist yet when the file is written." % m_cur.group(1).strip()
            )

    loop_state = m_ls.group(1).strip().lower()
    if loop_state not in TERMINAL:
        open_missing = []
        if not has_any("next steps", "next-steps", "next_steps"):
            open_missing.append("next-steps")
        if not has_any("resolution path", "resolution-path", "resolution_path"):
            open_missing.append("open-finding-resolution-path")
        if open_missing:
            deny(
                "record shows loop_state '%s' (work left open) but is missing: %s. Per §20, an "
                "open-state record must additionally give next-steps and an open-finding "
                "resolution path." % (loop_state, ", ".join(open_missing))
            )

    sys.exit(0)
except Exception as _fc_e:  # fail-closed-on-internal-error
    _fc_sys.stderr.write("record-fields-gate.sh: fail-closed: internal error: %r\n" % (_fc_e,))
    _fc_sys.exit(2)
PY
_fc_rc=$?  # fail-closed-on-internal-error
if [ "$_fc_rc" -ne 0 ] && [ "$_fc_rc" -ne 2 ]; then
  echo "${role:-record-fields-gate}: refused — fail-closed: internal error (judge exited $_fc_rc)" >&2
  exit 2
fi
exit "$_fc_rc"
