#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)}/hooks/lib/gate-lib.sh" 2>/dev/null || {
  echo "$(basename "${BASH_SOURCE[0]}"): refused — core gate-lib.sh could not be sourced (CLAUDE_PLUGIN_ROOT_CORE unset/wrong and no sibling core/ found); failing closed rather than running without the shared fail-closed/kill-switch machinery." >&2
  exit 2
}
gate_trap_fail_closed
# PreToolUse gate (Write|Edit|MultiEdit) — id-stage-order plugin's own
# gate. Owns exactly one cross-cutting constraint: the interaction-design
# methodology's stage ordering (survey -> scout -> proposal ->
# [human approval, enforced by core's own approval-gate.sh, NOT this
# plugin] -> phase-2 record), per docs/issue-21/proposals/
# issue-21-interaction-design-gate-machine.md §4 and §6.
#
# Two checks, both purely file-EXISTENCE based (never content, never
# network/gh):
#
#   1. A NEW docs/issue-<n>/proposals/*.md write (the file does not yet
#      exist on disk at write time — an edit to an already-existing
#      proposal is always allowed, ordering only gates first creation)
#      requires both survey.md and scout-brief.md under
#      docs/issue-<n>/reports/interaction-design/ to already exist,
#      UNLESS survey.md itself records an explicit scout-skip (a line
#      matching /skip(ped)?/i near /scout/i).
#
#   2. Any write to docs/issue-<n>/reports/interaction-design.md (the
#      phase-2 record) requires at least one
#      docs/issue-<n>/proposals/*.md file to already exist on disk.
#      This plugin does NOT check GitHub/human approval — core's
#      hooks/approval-gate.sh already fail-closed-blocks this same
#      write until an allowlisted human's Approve exists; this check is
#      a narrower, purely-local precondition layered on top of that.
#
# On every passing check (not a skip-exit for an out-of-scope path),
# read-merge-writes docs/issue-<n>/reports/interaction-design/.status.json,
# recomputed from actual file presence — the shared on-disk contract the
# other ten interaction-design plugins each add their own key to.
#
# Kill switch: export ID_STAGE_ORDER_GATE_OFF=1
set -uo pipefail

deny() { echo "id-stage-order: refused — $1" >&2; exit 2; }

gate_kill_switch_active "${ID_STAGE_ORDER_GATE_OFF:-}" || exit 0

command -v python3 >/dev/null 2>&1 || deny "stage-order-gate.sh requires python3, which is not on PATH; denying rather than guessing."

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || deny "empty tool-use payload on stdin; cannot evaluate the stage-order gate."

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
[ -z "$root" ] && deny "no project root could be determined; failing closed (stage-order check cannot run)."

SG_PAYLOAD="$payload" SG_ROOT="$root" \
python3 <<'PY'
import sys as _fc_sys  # fail-closed-on-internal-error
try:
    import json, os, posixpath, re, sys
    import importlib.util
    _spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
    gate_lib = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(gate_lib)

    def deny(m):
        sys.stderr.write("id-stage-order: refused — %s\n" % m); sys.exit(2)

    raw = os.environ.get("SG_PAYLOAD", "")
    ev = gate_lib.gate_parse_json_or_deny(raw, deny)
    tool = ev.get("tool_name")
    ti = ev.get("tool_input")
    if not isinstance(ti, dict):
        deny("tool_input is missing or not a JSON object; the gate cannot judge a write it cannot parse (stage-order).")

    root = posixpath.normpath(os.environ["SG_ROOT"].replace("\\", "/"))
    PROPOSAL_RE = re.compile(r'^docs/issue-([0-9]+)/proposals/.*interaction-design.*\.md$', re.I)
    RECORD_RE = re.compile(r'^docs/issue-([0-9]+)/reports/interaction-design\.md$')

    path = None
    if tool in ("Write", "Edit", "MultiEdit"):
        p = ti.get("file_path")
        if isinstance(p, str) and p:
            path = p
    elif tool == "Bash":
        cmdline = ti.get("command")
        if isinstance(cmdline, str):
            for tok in re.findall(r'[A-Za-z0-9_./~$-]+', cmdline):
                rel_try = gate_lib.gate_normalize_path(root, tok)
                if (PROPOSAL_RE.match(rel_try) if rel_try else False) or (RECORD_RE.match(rel_try) if rel_try else False):
                    path = tok
                    break
    if path is None:
        sys.exit(0)

    rel = gate_lib.gate_normalize_path(root, path)
    if rel is None:
        sys.exit(0)
    r = posixpath.join(root, rel) if rel else root

    def update_status(issue_n, stage):
        try:
            status_dir = os.path.join(root, "docs", "issue-%s" % issue_n, "reports", "interaction-design")
            status_path = os.path.join(status_dir, ".status.json")
            subject = "issue-%s" % issue_n
            data = {}
            if os.path.isfile(status_path):
                try:
                    with open(status_path, encoding="utf-8") as fh:
                        data = json.load(fh)
                    if not isinstance(data, dict):
                        data = {}
                except Exception:
                    data = {}
            if subject not in data or not isinstance(data.get(subject), dict):
                data[subject] = {}
            # Recompute all four fields from actual on-disk presence — never
            # trust a prior value, self-updating per proposal §4.
            survey_p = os.path.join(status_dir, "survey.md")
            scout_p = os.path.join(status_dir, "scout-brief.md")
            proposals_dir = os.path.join(root, "docs", "issue-%s" % issue_n, "proposals")
            record_p = os.path.join(root, "docs", "issue-%s" % issue_n, "reports", "interaction-design.md")

            def scout_skipped():
                if not os.path.isfile(survey_p):
                    return False
                try:
                    with open(survey_p, encoding="utf-8-sig") as fh:
                        text = fh.read()
                except OSError:
                    return False
                for line in text.splitlines():
                    if re.search(r'scout', line, re.I) and re.search(r'skip(ped)?', line, re.I):
                        return True
                return False

            has_proposal = os.path.isdir(proposals_dir) and any(
                f.endswith(".md") for f in os.listdir(proposals_dir)
            ) if os.path.isdir(proposals_dir) else False

            data[subject]["survey"] = "done" if os.path.isfile(survey_p) else data[subject].get("survey", "pending")
            data[subject]["scout"] = "done" if (os.path.isfile(scout_p) or scout_skipped()) else data[subject].get("scout", "pending")
            data[subject]["proposal"] = "done" if has_proposal else data[subject].get("proposal", "pending")
            data[subject]["record"] = "done" if os.path.isfile(record_p) else data[subject].get("record", "pending")
            # The stage that just passed is authoritatively "done" even if
            # the write hasn't landed on disk yet (Write hasn't executed at
            # PreToolUse time) — this write is the artifact for that stage.
            data[subject][stage] = "done"

            os.makedirs(status_dir, exist_ok=True)
            with open(status_path, "w", encoding="utf-8") as fh:
                json.dump(data, fh, indent=2)
        except Exception as _state_e:
            sys.stderr.write("id-stage-order: warning: could not update status file: %r\n" % (_state_e,))

    # --- check 1: new proposal write -------------------------------------
    m = PROPOSAL_RE.match(rel)
    if m:
        issue_n = m.group(1)
        if os.path.isfile(r):
            # Edit to an already-existing proposal file: always allowed,
            # ordering only gates first creation.
            sys.exit(0)

        rd = os.path.join(root, "docs", "issue-%s" % issue_n, "reports", "interaction-design")
        survey_p = os.path.join(rd, "survey.md")
        scout_p = os.path.join(rd, "scout-brief.md")

        survey_ok = os.path.isfile(survey_p)

        def scout_skipped():
            if not survey_ok:
                return False
            try:
                with open(survey_p, encoding="utf-8-sig") as fh:
                    text = fh.read()
            except OSError:
                return False
            for line in text.splitlines():
                if re.search(r'scout', line, re.I) and re.search(r'skip(ped)?', line, re.I):
                    return True
            return False

        scout_ok = os.path.isfile(scout_p) or scout_skipped()

        missing = []
        if not survey_ok:
            missing.append("survey.md")
        if not scout_ok:
            missing.append("scout-brief.md")
        if missing:
            deny(
                "new proposal at %s requires the prerequisite stage artifact(s) "
                "under docs/issue-%s/reports/interaction-design/ to already exist "
                "first: missing %s (scout-brief.md is excused only if survey.md "
                "itself records an explicit scout-skip). Per "
                "docs/issue-21/proposals/issue-21-interaction-design-gate-machine.md "
                "§4/§6, stage ordering is survey -> scout -> proposal."
                % (rel, issue_n, ", ".join(missing))
            )

        update_status(issue_n, "proposal")
        sys.exit(0)

    # --- check 2: phase-2 record write ------------------------------------
    m = RECORD_RE.match(rel)
    if m:
        issue_n = m.group(1)
        proposals_dir = os.path.join(root, "docs", "issue-%s" % issue_n, "proposals")
        has_proposal = os.path.isdir(proposals_dir) and any(
            f.endswith(".md") for f in os.listdir(proposals_dir)
        )
        if not has_proposal:
            deny(
                "phase-2 record write at %s requires at least one "
                "docs/issue-%s/proposals/*.md file to already exist on disk — "
                "none found. This plugin checks only that a proposal document "
                "exists (a purely local/offline precondition); it does NOT check "
                "GitHub or human approval itself — core's hooks/approval-gate.sh "
                "already fail-closed-blocks this same write until an allowlisted "
                "human's Approve exists on GitHub (contract v3 s19). Write the "
                "proposal and get it approved first."
                % (rel, issue_n)
            )

        update_status(issue_n, "record")
        sys.exit(0)

    # Not a write this plugin cares about.
    sys.exit(0)
except Exception as _fc_e:  # fail-closed-on-internal-error
    _fc_sys.stderr.write("stage-order-gate.sh: fail-closed: internal error: %r\n" % (_fc_e,))
    _fc_sys.exit(2)
PY
_fc_rc=$?  # fail-closed-on-internal-error
if [ "$_fc_rc" -ne 0 ] && [ "$_fc_rc" -ne 2 ]; then
  echo "id-stage-order: refused — fail-closed: internal error (judge exited $_fc_rc)" >&2
  exit 2
fi
exit "$_fc_rc"
