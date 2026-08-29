#!/usr/bin/env bash
__fc(){ rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then echo "fail-closed: gate aborted (rc=$rc)" >&2; exit 2; fi; }
trap __fc EXIT
# PreToolUse gate (Write|Edit|MultiEdit) — enforces the implementation
# role's phase-2 record shape adopted in issue-52
# (docs/issue-52/proposals/2026-07-31-implementation-domain-norms.md,
# section (b)).
#
# issue-341 (operator ruling, 2026-08-27): this file used to also carry a
# config-driven CHECKERS dispatch (issue-263, phase-4b-4) that folded 145
# `record-section-shape`-family hooks across 43 rulebooks into one
# per-rulebook-JSON-config lookup keyed by CLAUDE_SKILL -- a config object
# indexed by the acting role's name, against a ~40-entry role-keyed dict,
# a closed-set identity validation the role-axis removal (issue-331) left
# live by accident (documented then as a deliberate deferral,
# docs/issue-331/reports/implementation.md:471,494). That dispatch, its
# env-var plumbing, and its JSON config file are removed here (see
# docs/issue-341/reports/architecture-interface-contract-shape+
# silent-failure-audit-e0c3b8a8.md for the exact identifiers removed). The
# decision those 145 rows made -- "does this
# specific role's specific proposal/report path carry these specific
# checklist fields/section markers/tokens" -- is inherently a lookup by role
# identity against a fixed role roster; per the operator ruling, that
# capability is dropped rather than re-expressed under another name.
# Capability lost: none of the 43 rulebooks' folded per-role record-shape
# checks run any more (e.g. accessibility's WCAG-EM methodology-gate.sh
# check, folded in as the `accessibility` config row, no longer requires a
# `fail` key in docs/issue-10/proposals/gate-remediation.md -- and likewise
# for the other 144 rows). The hardcoded implementation-role check below,
# which was never role-keyed-dict-driven (it matches one fixed path,
# docs/issue-<n>/reports/implementation.md), is unaffected and still runs
# unconditionally, unchanged from issue-52's own contract.
#
# Target: docs/issue-<n>/reports/implementation.md only. Requires
# `loop_state:`, `type:`, `verdict:` frontmatter keys
# always, plus `code_under_review:`, `breaking:` and a `## What did not
# work` heading UNLESS the current workspace diff (git diff HEAD
# --numstat) is trivial -- docs-only or <=5 changed lines total
# (issue-285, widened issue-297). On a trivial diff, `code_under_review:`
# and `breaking:` may both be omitted (the diff itself, already read to
# decide triviality, names what changed; breaking defaults false) and the
# `## What did not work` heading may be omitted too, provided the record
# says elsewhere that there was nothing to report; a diff whose size
# can't be determined (no HEAD yet, git unavailable, non-repo root) is
# treated as NOT trivial, so the full-record floor is never silently
# skipped. issue-297: `code_under_review:` joined the trivial exemption
# because it was, in live measurement, one of the two fields that
# actually fired friction on an honest trivial-diff record -- `breaking:`
# alone (issue-285's original scope) did not match the observed surface.
# Requires a `## Rationale for deviations` heading only when the record's
# body otherwise signals a deviation occurred (scope-exceeded / diverged-
# or deviated-from-the-proposal language); its absence when no deviation
# language is present is not an error, since the section is a conditional
# response to divergence, not a mandatory section on every record.
# issue-297: the heuristic no longer treats a bare mention of the word
# "deviation" as a signal -- that over-fired on records that discuss
# deviations in the abstract (e.g. this very gate's own documentation) or
# that explicitly deny one ("no deviations occurred" contains the
# substring "deviation"); only a concrete assertion that one happened
# (scope-exceeded, or diverged/deviated from the proposal) counts.
#
# Kill switch: export RECORD_SHAPE_GATE_OFF=1
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)}/hooks/lib/gate-lib.sh" || { echo "record-shape-gate.sh: cannot source gate-lib.sh" >&2; exit 2; }
set -uo pipefail

skill="${CLAUDE_SKILL:-record-shape}"
deny() { echo "${skill}: refused — $1" >&2; exit 2; }

gate_kill_switch_active "${RECORD_SHAPE_GATE_OFF:-}" || exit 0

command -v python3 >/dev/null 2>&1 || deny "record-shape-gate.sh requires python3, which is not on PATH; denying rather than guessing."

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || deny "record-shape-gate: empty tool-use payload on stdin; cannot evaluate the record-shape gate."

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

PG_PAYLOAD="$payload" PG_ROOT="$root" \
python3 <<'PY'
import sys as _fc_sys  # fail-closed-on-internal-error
try:
    import importlib.util, json, os, posixpath, re, subprocess, sys

    _spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
    gate_lib = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(gate_lib)

    def deny(m):
        sys.stderr.write("record-shape: refused — %s\n" % m); sys.exit(2)

    # issue-285: a trivial diff (docs-only, or <=5 changed lines total in the
    # current workspace diff against HEAD) is exempt from the `breaking:`
    # frontmatter key and the `## What did not work` heading below. Best-
    # effort only: any git failure (no HEAD yet, git missing, non-repo root)
    # makes the diff size unknowable, and an unknowable diff is treated as
    # NOT trivial -- the full-record floor never gets silently skipped just
    # because the check couldn't run.
    def _workspace_diff_is_trivial(root):
        try:
            out = subprocess.run(
                ["git", "-C", root, "diff", "HEAD", "--numstat"],
                capture_output=True, text=True, timeout=5)
        except Exception:
            return False
        if out.returncode != 0:
            return False
        total = 0
        docs_only = True
        saw_line = False
        for line in out.stdout.splitlines():
            parts = line.strip("\n").split("\t")
            if len(parts) != 3:
                continue
            saw_line = True
            added, deleted, path = parts
            if not path.startswith("docs/"):
                docs_only = False
            for n in (added, deleted):
                if n.isdigit():
                    total += int(n)
        if not saw_line:
            return True  # nothing else changed -- trivially small
        return docs_only or total <= 5

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

    trivial = _workspace_diff_is_trivial(root)

    has_code_under_review = re.search(r'(?m)^code_under_review:', frontmatter) is not None
    has_loop_state = re.search(r'(?m)^loop_state:', frontmatter) is not None
    has_type = re.search(r'(?m)^type:', frontmatter) is not None
    has_breaking = re.search(r'(?m)^breaking:', frontmatter) is not None
    has_verdict = re.search(r'(?m)^verdict:', frontmatter) is not None
    if not has_code_under_review and not trivial:
        missing.append("frontmatter key `code_under_review:`")
    if not has_loop_state:
        missing.append("frontmatter key `loop_state:`")
    if not has_type:
        missing.append("frontmatter key `type:`")
    if not has_breaking and not trivial:
        missing.append("frontmatter key `breaking:`")
    if not has_verdict:
        missing.append("frontmatter key `verdict:`")

    # 2. `## What did not work` heading present somewhere in the body.
    # issue-285: for a trivial diff (docs-only or <=5 changed lines), the
    # literal heading is optional as long as the record says elsewhere that
    # there was nothing to report -- the audit spine (some acknowledgment)
    # stays required, only the fixed heading name is relaxed.
    has_wdnw = re.search(r'(?m)^##\s+What did not work\s*$', new_text) is not None
    if not has_wdnw:
        nothing_to_report = trivial and re.search(
            r'nothing to report|nothing went wrong|no issues|^none\.?$',
            new_text, re.I | re.M) is not None
        if not nothing_to_report:
            if trivial:
                missing.append(
                    "`## What did not work` heading, or (trivial-diff exemption, "
                    "issue-285) some statement that there was nothing to report"
                )
            else:
                missing.append("`## What did not work` heading (present even when empty, e.g. \"None.\")")

    # 3. Conditional: deviation language in the body (excluding the
    #    `## Rationale for deviations` heading's own line) requires a
    #    `## Rationale for deviations` heading.
    body_without_heading = re.sub(r'(?m)^##\s+Rationale for deviations\s*$', '', new_text)
    low = body_without_heading.lower()
    # issue-297: a bare "deviation" substring over-fires -- it matches a
    # record that explicitly denies one ("no deviations occurred") or that
    # discusses the concept in the abstract (e.g. this gate's own
    # documentation). Only a concrete assertion that a divergence actually
    # happened counts as the signal.
    deviation_signaled = any(
        needle in low
        for needle in (
            "scope-exceeded",
            "scope exceeded",
            "diverged from the proposal",
            "deviated from the proposal",
        )
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
trap - EXIT
exit "$_fc_rc"
