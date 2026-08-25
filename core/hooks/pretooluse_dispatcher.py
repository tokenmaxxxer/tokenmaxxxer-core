#!/usr/bin/env python3
"""issue #282 Part 2 -- single-dispatcher PreToolUse gate execution.

core's PreToolUse gates used to be N separate bash+python3 process pairs
per tool call, registered under one union ".*" matcher in hooks.json. This
dispatcher is registered ONCE for that same matcher and runs every
remaining PreToolUse gate inside one python process, closely mirroring
the pattern already proven in the sibling on-the-record plugin
(hooks/pretooluse_dispatcher.py + pretooluse-dispatcher.sh).

The gate scripts themselves stay on disk as the single source of truth:
each is "bash preamble (kill switch / fast path / root-and-role
resolution, via core/hooks/lib/gate-lib.sh) + one python body in a quoted
heredoc". The dispatcher

  1. reads the stdin payload once,
  2. replicates each gate's bash preamble in a small `setup` function
     below (kill switch, cheap fast-path checks, root/role resolution --
     see GATES), and
  3. extracts the python heredoc body (or bodies -- record-shape-gate.sh
     runs two in sequence) from the .sh file and exec()s it in-process
     with the same env-var contract, capturing SystemExit as the gate's
     exit code and stdout/stderr per gate.

issue #282 Part 1 disposition (evidence audit, issue #282 comment):
  KEEP (unchanged blocking behavior):    approval-gate, board-gate,
    gh-guard, ordering-gate, record-shape-gate
  DEMOTE (blocking -> advisory; the seven scripts below were edited so
    their own `deny()` now prints the finding and exits 0 with a
    hookSpecificOutput.additionalContext/systemMessage payload instead of
    exiting 2 -- this dispatcher does not re-implement that, it just runs
    the already-demoted script bodies): citation-gate, facet-keyword-gate,
    handbook-trigger-gate, proposal-shape-gate, record-fields-gate,
    survey-order-gate, trailer-gate
  RETIRE: ordering-norm-gate (deleted, not listed below)

Verdict merge: any KEEP gate's exit 2 makes the overall dispatcher deny
(exit 2, message on stderr). A DEMOTE gate never denies any more (its own
deny() exits 0), so it only ever contributes stdout JSON / stderr text,
which is forwarded/concatenated. Fail-open: a crashing gate is caught and
never takes down the rest of the chain; the dispatcher itself never blocks
a tool call on its own internal defect.
"""
from __future__ import annotations

import io
import json
import os
import re
import subprocess
import sys
import traceback
from contextlib import redirect_stderr, redirect_stdout

HOOKS_DIR = os.path.dirname(os.path.abspath(__file__))
GATE_LIB_PY = os.path.join(HOOKS_DIR, "lib", "gate-lib.py")

# --------------------------------------------------------------------------
# small helpers mirroring gate-lib.sh / the shared bash preamble idioms
# --------------------------------------------------------------------------

_ON_SPELLINGS = {"1", "true", "yes", "on"}


def _kill_switch_active(value):
    """gate_kill_switch_active: stay active unless value is a recognized
    on-spelling (case-insensitive)."""
    return (value or "").strip().lower() not in _ON_SPELLINGS


def _payload_escaped(payload):
    """True when the raw payload text carries a JSON \\uXXXX escape.

    issue-303 (F15/F17): approval-gate/board-gate/gh-guard's own bash
    preambles fast-path on a literal substring match against the RAW,
    unparsed payload text before their python bodies ever run json.loads.
    This dispatcher's setup functions below replicate those same raw-text
    substring checks (that replication is the whole point of "mirrors the
    bash preamble" -- see module docstring) and so replicate the same
    bug: a payload that JSON-escapes one character of the matched
    substring as \\uXXXX decodes to a byte-identical parsed string but
    never contains the literal substring being scanned for, silently
    skipping the gate. Every setup function's skip condition below must
    stay conditional on this being False -- a payload carrying any \\u
    escape always falls through to the real gate body instead.
    """
    return "\\u" in payload


def _git_toplevel(cwd):
    try:
        out = subprocess.run(["git", "-C", cwd, "rev-parse", "--show-toplevel"],
                              capture_output=True, text=True, timeout=10)
        if out.returncode == 0 and out.stdout.strip():
            return out.stdout.strip()
    except Exception:
        pass
    return None


def _plausible(d):
    if not d or not os.path.isdir(d):
        return False
    return (os.path.exists(os.path.join(d, ".git"))
            or os.path.isfile(os.path.join(d, "docs", "specs",
                                            "role-handoff-contract.md")))


def _target_path(payload_obj):
    ti = payload_obj.get("tool_input") if isinstance(payload_obj, dict) else None
    if isinstance(ti, dict):
        for k in ("file_path", "notebook_path"):
            v = ti.get(k)
            if isinstance(v, str) and v:
                return v
    return ""


def _under(root, target):
    if not target:
        return True
    try:
        rr = os.path.normpath(os.path.realpath(root)).replace("\\", "/")
    except Exception:
        return False
    n = target.replace("\\", "/")
    a = n if n.startswith("/") else os.path.normpath(os.path.join(rr, n))
    a = os.path.normpath(a)
    try:
        real = os.path.normpath(os.path.realpath(a)).replace("\\", "/")
    except Exception:
        return False
    return real == rr or real.startswith(rr + "/")


def _resolve_root_target_pattern(payload_obj, cwd):
    """Mirrors the repeated bash _target/_plausible/_under root-resolution
    idiom used by record-fields-gate.sh, proposal-shape-gate.sh,
    survey-order-gate.sh, record-shape-gate.sh."""
    target = _target_path(payload_obj)
    cpd = os.environ.get("CLAUDE_PROJECT_DIR", "")
    if cpd and _plausible(cpd) and _under(cpd, target):
        return os.path.realpath(cpd)
    d = target or cwd
    if not os.path.isdir(d):
        d = os.path.dirname(d) or cwd
    root = _git_toplevel(d)
    if root:
        return root
    return _git_toplevel(cwd)


def _resolve_root_plausible_only(cwd):
    """Mirrors handbook-trigger-gate.sh's simpler root resolution (no
    target/under check)."""
    cpd = os.environ.get("CLAUDE_PROJECT_DIR", "")
    if cpd and _plausible(cpd):
        return os.path.realpath(cpd)
    return _git_toplevel(cwd)


# --------------------------------------------------------------------------
# heredoc body extraction -- the .sh files stay the single source of truth
# --------------------------------------------------------------------------

_HEREDOC_OPEN_RE = re.compile(r"<<'([A-Za-z0-9_]+)'")
_BODY_CACHE = {}


def _gate_bodies(script):
    """Extract and compile every quoted heredoc python body in `script`, in
    file order. Returns a list of compiled code objects. A script whose
    body cannot be found compiles to an empty list (fail-open: no code to
    run, caller treats that as skip)."""
    if script in _BODY_CACHE:
        return _BODY_CACHE[script]
    path = os.path.join(HOOKS_DIR, script)
    bodies = []
    try:
        with open(path, encoding="utf-8") as fh:
            lines = fh.readlines()
    except OSError:
        _BODY_CACHE[script] = []
        return []
    n = len(lines)
    i = 0
    while i < n:
        m = _HEREDOC_OPEN_RE.search(lines[i].rstrip("\n"))
        if m:
            tag = m.group(1)
            body_lines = []
            j = i + 1
            while j < n and lines[j].rstrip("\n") != tag:
                body_lines.append(lines[j])
                j += 1
            bodies.append(compile("".join(body_lines), f"{path}::{tag}", "exec"))
            i = j + 1
            continue
        i += 1
    _BODY_CACHE[script] = bodies
    return bodies


def _run_body(code, raw_stderr):
    """Run one compiled python body in-process. Returns (rc, stdout_text)."""
    out_buf, err_buf = io.StringIO(), io.StringIO()
    rc = 0
    with redirect_stdout(out_buf), redirect_stderr(err_buf):
        g = {"__name__": "__main__"}
        try:
            exec(code, g)
        except SystemExit as exc:
            code_ = exc.code
            if code_ is None:
                rc = 0
            elif isinstance(code_, int):
                rc = code_
            else:
                err_buf.write(str(code_) + "\n")
                rc = 1
        except BaseException:
            traceback.print_exc(file=err_buf)
            rc = 2  # fail-closed on internal error, matching every gate's
                    # own __fc/gate_trap_fail_closed trap
    raw_stderr.write(err_buf.getvalue())
    return rc, out_buf.getvalue()


# --------------------------------------------------------------------------
# per-gate setup functions. Each returns one of:
#   ("skip", None)            -- not this gate's business, silent allow
#   ("deny", message)         -- fail-closed bash-level deny (unchanged
#                                 for both KEEP and DEMOTE gates: an
#                                 infra failure like "no project root" or
#                                 "no CLAUDE_ROLE" is not the substantive
#                                 judgment call the audit evaluated)
#   ("ok", {env updates})     -- proceed; apply these env vars, then run
#                                 the gate's python body/bodies
# --------------------------------------------------------------------------

def _setup_approval_gate(payload, obj, cwd):
    if not _kill_switch_active(os.environ.get("CORE_OFF", "")):
        return "skip", None
    if not os.environ.get("CLAUDE_ROLE", ""):
        return "skip", None
    if not payload:
        return "deny", ("approval-gate.sh: refused -- empty tool-use payload "
                         "on stdin; cannot evaluate the approval gate.")
    if not _payload_escaped(payload) and not any(
            s in payload for s in ("src/", "test/", "issue-")):
        return "skip", None
    return "ok", {"CORE_PAYLOAD": payload}


def _setup_board_gate(payload, obj, cwd):
    if not _kill_switch_active(os.environ.get("CORE_OFF", "")):
        return "skip", None
    if not payload:
        return "deny", ("board-gate.sh: refused -- empty tool-use payload on "
                         "stdin; cannot evaluate the board gate.")
    if not _payload_escaped(payload) and "docs" not in payload:
        return "skip", None
    return "ok", {"CORE_PAYLOAD": payload}


def _setup_gh_guard(payload, obj, cwd):
    if not _kill_switch_active(os.environ.get("CORE_OFF", "")):
        return "skip", None
    if not os.environ.get("CLAUDE_ROLE", ""):
        return "skip", None
    if not payload:
        return "deny", ("gh-guard.sh: refused -- empty tool-use payload on "
                         "stdin; cannot evaluate the gh guard.")
    escaped = _payload_escaped(payload)
    if not escaped and '"Bash"' not in payload:
        return "skip", None
    if not escaped and not any(
            s in payload for s in
            ("gh", "git", "curl", "wget", "http://", "https://")):
        return "skip", None
    return "ok", {"CORE_PAYLOAD": payload}


def _setup_ordering_gate(payload, obj, cwd):
    if not payload:
        return "deny", ("ordering-gate: refused -- empty tool-use payload on "
                         "stdin; cannot evaluate write order.")
    root = os.environ.get("CLAUDE_PROJECT_DIR", "") or _git_toplevel(cwd) or cwd
    return "ok", {"OG_PAYLOAD": payload, "OG_ROOT": root}


def _setup_record_shape_gate(payload, obj, cwd):
    if not _kill_switch_active(os.environ.get("RECORD_SHAPE_GATE_OFF", "")):
        return "skip", None
    if not payload:
        return "deny", ("record-shape-gate: refused -- empty tool-use "
                         "payload on stdin; cannot evaluate the "
                         "record-shape gate.")
    root = _resolve_root_target_pattern(obj, cwd)
    if not root:
        return "deny", ("record-shape-gate.sh: fail-closed: internal "
                         "error: no project root could be determined "
                         "(record-shape check cannot run).")
    config = os.environ.get("RECORD_SHAPE_CONFIG",
                             os.path.join(HOOKS_DIR, "record-shape-config.json"))
    role = os.environ.get("CLAUDE_ROLE", "")
    return "ok", {
        "PG_PAYLOAD": payload, "PG_ROOT": root,
        "PG_CONFIG": config, "PG_ROLE": role,
        "RS_CONFIG": config, "RS_ROLE": role,
        "RS_ROOT": root, "RS_PAYLOAD": payload,
    }


def _setup_citation_gate(payload, obj, cwd):
    if not _kill_switch_active(os.environ.get("CITATION_GATE_OFF", "")):
        return "skip", None
    cpd = os.environ.get("CLAUDE_PROJECT_DIR", "") or cwd
    branch = ""
    try:
        out = subprocess.run(["git", "-C", cpd, "rev-parse", "--abbrev-ref",
                               "HEAD"], capture_output=True, text=True, timeout=10)
        if out.returncode == 0:
            branch = out.stdout.strip()
    except Exception:
        pass
    config = os.environ.get("CITATION_CONFIG",
                             os.path.join(HOOKS_DIR, "citation-config.json"))
    return "ok", {
        "CIT_PAYLOAD": payload, "CIT_CONFIG": config,
        "CIT_ROLE": os.environ.get("CLAUDE_ROLE", ""),
        "CIT_PROJECT_DIR": cpd, "CIT_BRANCH": branch,
    }


def _setup_facet_keyword_gate(payload, obj, cwd):
    if not _kill_switch_active(os.environ.get("FACET_KEYWORD_GATE_OFF", "")):
        return "skip", None
    cpd = os.environ.get("CLAUDE_PROJECT_DIR", "") or cwd
    config = os.environ.get("FACET_KEYWORD_CONFIG",
                             os.path.join(HOOKS_DIR, "facet-keyword-config.json"))
    return "ok", {
        "FK_PAYLOAD": payload, "FK_CONFIG": config,
        "FK_ROLE": os.environ.get("CLAUDE_ROLE", ""), "FK_PROJECT_DIR": cpd,
    }


def _setup_handbook_trigger_gate(payload, obj, cwd):
    if not _kill_switch_active(os.environ.get("HANDBOOK_TRIGGER_GATE_OFF", "")):
        return "skip", None
    root = _resolve_root_plausible_only(cwd)
    if not root:
        return "deny", ("handbook-trigger-gate.sh: refused -- no project "
                         "root could be determined; failing closed (§21 "
                         "handbook-trigger cannot be judged).")
    self_path = os.path.join(HOOKS_DIR, "handbook-trigger-gate.sh")
    return "ok", {
        "HT_PAYLOAD": payload, "HT_ROOT": root,
        "HT_ROLE": os.environ.get("CLAUDE_ROLE", ""), "HT_SELF": self_path,
    }


def _setup_proposal_shape_gate(payload, obj, cwd):
    if not _kill_switch_active(os.environ.get("PROPOSAL_SHAPE_GATE_OFF", "")):
        return "skip", None
    if not payload:
        return "deny", ("proposal-shape-gate: refused -- empty tool-use "
                         "payload on stdin; cannot evaluate the proposal "
                         "shape gate.")
    root = _resolve_root_target_pattern(obj, cwd)
    if not root:
        return "deny", ("proposal-shape-gate: refused -- no project root "
                         "could be determined; failing closed (proposal "
                         "shape check cannot run).")
    return "ok", {"PG_PAYLOAD": payload, "PG_ROOT": root}


def _setup_record_fields_gate(payload, obj, cwd):
    if not _kill_switch_active(os.environ.get("RECORD_FIELDS_GATE_OFF", "")):
        return "skip", None
    role = os.environ.get("CLAUDE_ROLE", "")
    if not role:
        return "deny", ("record-fields-gate: refused -- no CLAUDE_ROLE in "
                         "the environment; the gate cannot resolve which "
                         "record is this role's own.")
    if not payload:
        return "deny", ("record-fields-gate: refused -- empty tool-use "
                         "payload on stdin; cannot evaluate the "
                         "record-fields gate.")
    root = _resolve_root_target_pattern(obj, cwd)
    if not root:
        return "deny", ("record-fields-gate: refused -- no project root "
                         "could be determined; failing closed (§20 field "
                         "check cannot run).")
    terminal = os.environ.get(
        "RECORD_FIELDS_TERMINAL_STATES",
        "landed complete closed done delivered phase-2-complete")
    return "ok", {"RF_PAYLOAD": payload, "RF_ROOT": root, "RF_ROLE": role,
                  "RF_TERMINAL": terminal}


def _setup_survey_order_gate(payload, obj, cwd):
    if not _kill_switch_active(os.environ.get("SURVEY_ORDER_GATE_OFF", "")):
        return "skip", None
    if not payload:
        return "deny", ("survey-order: refused -- empty tool-use payload on "
                         "stdin; cannot evaluate write order.")
    root = _resolve_root_target_pattern(obj, cwd)
    if not root:
        return "deny", ("survey-order: refused -- no project root could be "
                         "determined; failing closed (write order cannot "
                         "be judged).")
    return "ok", {"PG_PAYLOAD": payload, "PG_ROOT": root,
                  "PG_ROLE": os.environ.get("CLAUDE_ROLE", "")}


def _setup_trailer_gate(payload, obj, cwd):
    if not _kill_switch_active(os.environ.get("TRAILER_GATE_OFF", "")):
        return "skip", None
    if not payload:
        return "deny", ("trailer-gate: refused -- empty tool-use payload on "
                         "stdin; cannot evaluate the trailer gate.")
    self_path = os.path.join(HOOKS_DIR, "trailer-gate.sh")
    return "ok", {
        "TRAILER_GATE_PAYLOAD": payload,
        "TRAILER_GATE_ROLE": os.environ.get("CLAUDE_ROLE", ""),
        "TRAILER_GATE_CPD": os.environ.get("CLAUDE_PROJECT_DIR", ""),
        "TRAILER_GATE_CWD": cwd, "TRAILER_GATE_SELF": self_path,
    }


# script -> (setup fn, disposition). disposition is informational only --
# every gate's own script already encodes whether it can deny (KEEP) or
# only advises (DEMOTE, per its own already-edited deny()).
GATES = [
    ("approval-gate.sh", _setup_approval_gate, "keep"),
    ("board-gate.sh", _setup_board_gate, "keep"),
    ("gh-guard.sh", _setup_gh_guard, "keep"),
    ("ordering-gate.sh", _setup_ordering_gate, "keep"),
    ("record-shape-gate.sh", _setup_record_shape_gate, "keep"),
    ("citation-gate.sh", _setup_citation_gate, "demote"),
    ("facet-keyword-gate.sh", _setup_facet_keyword_gate, "demote"),
    ("handbook-trigger-gate.sh", _setup_handbook_trigger_gate, "demote"),
    ("proposal-shape-gate.sh", _setup_proposal_shape_gate, "demote"),
    ("record-fields-gate.sh", _setup_record_fields_gate, "demote"),
    ("survey-order-gate.sh", _setup_survey_order_gate, "demote"),
    ("trailer-gate.sh", _setup_trailer_gate, "demote"),
]

DISPATCHED_SCRIPTS = tuple(g[0] for g in GATES)


def _run_gate(script, setup_fn, disposition, payload, obj, cwd, raw_stderr):
    """Run one gate end to end. Returns (rc, stdout_text)."""
    try:
        verdict, data = setup_fn(payload, obj, cwd)
    except Exception:
        traceback.print_exc(file=raw_stderr)
        # A crashing setup on a KEEP gate fails closed (same posture as
        # the bash preamble's own __fc trap); on a DEMOTE gate the whole
        # point of the disposition is that this script never blocks the
        # call any more, so a setup crash there is advisory-only too.
        return (2 if disposition == "keep" else 0), ""
    if verdict == "skip":
        return 0, ""
    if verdict == "deny":
        raw_stderr.write((data or "") + "\n")
        if disposition == "keep":
            return 2, ""
        # DEMOTE (issue #282 Part 2): this bash-preamble-level deny path
        # (e.g. "no project root", "no CLAUDE_ROLE") is the same
        # gate's own blocking judgment as its python-body deny() calls,
        # which were already edited to be non-blocking -- treat it the
        # same way here rather than leaving a back door that still
        # blocks the call.
        return 0, ""
    env_updates = data or {}
    saved = {k: os.environ.get(k) for k in env_updates}
    saved["GATE_LIB_PY"] = os.environ.get("GATE_LIB_PY")
    os.environ["GATE_LIB_PY"] = GATE_LIB_PY
    os.environ.update({k: v for k, v in env_updates.items() if v is not None})
    try:
        stdout_out = ""
        rc = 0
        for body in _gate_bodies(script):
            rc, out = _run_body(body, raw_stderr)
            if out:
                stdout_out = stdout_out + out if stdout_out else out
            if rc != 0:
                break
        return rc, stdout_out
    finally:
        for k, v in saved.items():
            if v is None:
                os.environ.pop(k, None)
            else:
                os.environ[k] = v


def main():
    if not _kill_switch_active(os.environ.get("ORCHESTRATE_OFF", "")):
        return 0
    try:
        payload = sys.stdin.read()
    except Exception:
        payload = ""

    obj = {}
    try:
        parsed = json.loads(payload) if payload else {}
        if isinstance(parsed, dict):
            obj = parsed
    except ValueError:
        obj = {}

    cwd = obj.get("cwd") or os.getcwd()

    only = os.environ.get("OTR_DISPATCH_ONLY", "")
    if only:
        for script, setup_fn, _disp in GATES:
            if script == only:
                rc, out = _run_gate(script, setup_fn, _disp, payload, obj, cwd,
                                     sys.stderr)
                if out:
                    sys.stdout.write(out)
                return rc
        # F23 (issue-305): a typo'd OTR_DISPATCH_ONLY value previously
        # fell through to this same `return 0` a genuine "gate ran and
        # found nothing wrong" result uses -- "gate not found" and "gate
        # ran clean" were byte-identical, silently turning a test that
        # relies on this seam vacuous instead of failing loudly.
        print(
            "pretooluse_dispatcher.py: OTR_DISPATCH_ONLY=%r does not match any registered gate "
            "(%s); refusing rather than silently returning as if it had run and found nothing." %
            (only, ", ".join(DISPATCHED_SCRIPTS)),
            file=sys.stderr,
        )
        return 2

    denied = False
    stdout_chunks = []
    for script, setup_fn, _disp in GATES:
        try:
            rc, out = _run_gate(script, setup_fn, _disp, payload, obj, cwd,
                                 sys.stderr)
        except Exception:
            traceback.print_exc(file=sys.stderr)
            continue  # dispatcher-level defect around one gate: fail open
                      # for that gate only, never take down the chain
        if rc == 2:
            denied = True
        if out:
            stdout_chunks.append(out)
    if stdout_chunks:
        # F21 (issue-305): forwarding only the first chunk verbatim and
        # shoving every other DEMOTE gate's finding -- including its raw
        # JSON blob -- to stderr meant a consumer reading only the
        # documented stdout channel saw just the first gate's finding and
        # discovered the rest only on a later turn. Merge every chunk's
        # additionalContext/systemMessage into ONE combined
        # hookSpecificOutput JSON payload instead: platform contract
        # (one JSON stdout payload per hook call) still holds, but it now
        # carries every gate's finding, not just the first. DEMOTE gates
        # are the only ones that ever populate stdout_chunks (KEEP-gate
        # denials are stderr + exit 2 only, no stdout JSON), so this is
        # always merging same-shaped additionalContext/systemMessage
        # payloads, never a permissionDecision one.
        contexts = []
        messages = []
        for chunk in stdout_chunks:
            try:
                parsed = json.loads(chunk)
            except ValueError:
                # Not the well-formed JSON every DEMOTE gate emits --
                # forward as-is rather than corrupt the merged payload.
                sys.stderr.write(chunk)
                continue
            hso = parsed.get("hookSpecificOutput") if isinstance(parsed, dict) else None
            ctx = hso.get("additionalContext") if isinstance(hso, dict) else None
            if ctx:
                contexts.append(ctx)
            sm = parsed.get("systemMessage") if isinstance(parsed, dict) else None
            if sm:
                messages.append(sm)
        if contexts or messages:
            merged = {"hookSpecificOutput": {"hookEventName": "PreToolUse"}}
            if contexts:
                merged["hookSpecificOutput"]["additionalContext"] = "\n".join(contexts)
            if messages:
                merged["systemMessage"] = "\n".join(messages)
            sys.stdout.write(json.dumps(merged))
    return 2 if denied else 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except SystemExit:
        raise
    except BaseException:
        traceback.print_exc(file=sys.stderr)
        sys.exit(0)  # dispatcher crash must never block the tool call
