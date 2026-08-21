#!/usr/bin/env bash
# PreToolUse gate — owns exactly one methodology: phase ORDERING for this
# role's contract-v3 loop (survey -> scout-brief-or-justified-skip ->
# proposal -> record). Layered additively on top of core canon's generic
# record-fields-gate (referenced by pointer only, never vendored — see
# core/hooks/record-fields-gate.sh's resulting-content-computation shape,
# which this script follows independently rather than copies).
#
# Sources the shared gate-house library at core/hooks/lib/gate-lib.sh
# (issue-72) for the trap/kill-switch/JSON-parse/path-normalize/
# reconstruct-write machinery, by reference only (never vendored — see
# docs/handbooks/canon-scripts.md). gate-lib.py is loaded via importlib
# inside this script's own Python payload.
#
# Fires on Write|Edit|MultiEdit to two globs for the same issue-<n>:
#   - docs/issue-<n>/proposals/*.md (phase-1 side): requires
#     docs/issue-<n>/reports/architecture/survey.md to already exist.
#   - docs/issue-<n>/reports/architecture.md (phase-2 side): requires
#     both survey.md and scout-brief.md to exist once the resulting
#     content's loop_state leaves drafting/reviewing, UNLESS the
#     proposal for the same issue carries an explicit skip-justification
#     string (issue-1's skip-condition language, carried forward verbatim).
#
# Also applies a narrow, BOUNDED heuristic to Bash tool calls: a `command`
# string containing a literal `>`, `>>`, or `tee` redirect-shaped token
# aimed at one of the two gated globs is treated the same as an
# unresolvable Write and fails closed (this gate cannot reconstruct
# arbitrary shell-produced content, so it refuses the write instead of
# guessing). This heuristic does NOT do shell parsing: command
# substitution (`$(...)`), `eval`, `&&`/`;`-chained multi-command
# sequences beyond the simple redirect/tee token, heredocs, and
# `python3 -c ...` are explicitly NOT covered and are deferred — a
# command using those to write to a gated path will not be caught here.
#
# Existence-only — content shape is arch-adr-content-gate's and
# arch-citation-gate's job, kept separate so this stays single-purpose.
# Fails closed (exit 2) whenever resulting content cannot be determined.
#
# Kill switch: export ARCH_SEQUENCE_GATE_OFF=1 (or true/yes/on). Any other
# value, including unrecognized garbage, keeps the gate ACTIVE (fail-closed
# kill-switch posture — see gate-lib.sh's gate_kill_switch_active).

. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)}/hooks/lib/gate-lib.sh" || { echo "arch-sequence-gate: cannot source gate-lib.sh" >&2; exit 2; }
gate_trap_fail_closed
set -uo pipefail

gate_kill_switch_active "${ARCH_SEQUENCE_GATE_OFF:-}" || { trap - EXIT; exit 0; }

command -v python3 >/dev/null 2>&1 || { echo "arch-sequence-gate: fail-closed: python3 not on PATH" >&2; exit 2; }

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || { echo "arch-sequence-gate: fail-closed: empty tool-use payload" >&2; exit 2; }

SG_ROOT="${CLAUDE_PROJECT_DIR:-$(pwd -P)}" SG_PAYLOAD="$payload" GATE_LIB_PY="$GATE_LIB_PY" python3 <<'PY'
import importlib.util, json, os, re, sys

_spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
gate_lib = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(gate_lib)

def deny(msg):
    sys.stderr.write("arch-sequence-gate: refused — %s\n" % msg)
    sys.exit(2)

def fail_closed(msg):
    sys.stderr.write("arch-sequence-gate: fail-closed: %s\n" % msg)
    sys.exit(2)

raw = os.environ.get("SG_PAYLOAD", "")
ev = gate_lib.gate_parse_json_or_deny(raw, deny)

tool = ev.get("tool_name")
ti = ev.get("tool_input")

root = os.path.normpath(os.environ["SG_ROOT"])

PROPOSAL_RE = re.compile(r'^docs/(issue-[0-9]+)/proposals/.*architecture.*\.md$', re.I)
RECORD_RE = re.compile(r'^docs/(issue-[0-9]+)/reports/architecture\.md$')

# Narrow, bounded Bash-tool-write-bypass heuristic (see header comment for
# scope limits). Not full shell parsing.
BASH_WRITE_RE = re.compile(r'(?:^|[\s;&|])(?:>>?|tee\s+(?:-a\s+)?)\s*(["\']?)([^\s"\';|&<>]+)\1')

if tool == "Bash":
    if not isinstance(ti, dict):
        sys.exit(0)
    command = ti.get("command")
    if not isinstance(command, str):
        sys.exit(0)
    for mo in BASH_WRITE_RE.finditer(command):
        token = mo.group(2)
        rel_candidate = gate_lib.gate_normalize_path(root, token)
        if rel_candidate is None:
            continue
        m_bash = PROPOSAL_RE.match(rel_candidate) or RECORD_RE.match(rel_candidate)
        if m_bash:
            fail_closed(
                "a Bash command appears to target %s (matched %s), which is a "
                "phase-ordering-gated path (docs/%s/proposals/*.md or the phase-2 "
                "record). arch-sequence-gate cannot reconstruct arbitrary shell "
                "output, so resulting-content computation is out of scope and this "
                "write is refused. Use Write/Edit/MultiEdit on this path instead." %
                (rel_candidate, token, m_bash.group(1))
            )
    sys.exit(0)

if tool not in ("Write", "Edit", "MultiEdit"):
    sys.exit(0)
if not isinstance(ti, dict):
    fail_closed("tool_input missing or not an object")

path = ti.get("file_path")
if not isinstance(path, str) or not path:
    sys.exit(0)

rel = gate_lib.gate_normalize_path(root, path)
if rel is None:
    sys.exit(0)

abs_path = os.path.join(root, rel) if rel else root

m = PROPOSAL_RE.match(rel) or RECORD_RE.match(rel)
if not m:
    sys.exit(0)
issue = m.group(1)
is_record = bool(RECORD_RE.match(rel))

def resulting_content():
    current = None
    if os.path.isfile(abs_path):
        try:
            with open(abs_path, encoding="utf-8-sig") as fh:
                current = fh.read(1 << 20)
        except OSError:
            fail_closed("%s exists but cannot be read" % rel)
    new_text, ok = gate_lib.gate_reconstruct_write(tool, ti, current)
    return new_text if ok else None

content = resulting_content()
if content is None:
    fail_closed(
        "this write targets %s but the resulting content cannot be determined from "
        "tool=%r input. Use Write, or an Edit/MultiEdit whose old_string matches, so "
        "phase ordering can be checked." % (rel, tool)
    )

survey = os.path.join(root, "docs", issue, "reports", "architecture", "survey.md")
scout_brief = os.path.join(root, "docs", issue, "reports", "architecture", "scout-brief.md")

if not is_record:
    # phase-1 side: a proposal write requires the survey to already exist.
    if not os.path.isfile(survey):
        deny(
            "docs/%s/proposals/*.md is being written but docs/%s/reports/architecture/"
            "survey.md does not exist yet. Per contract v3 s19's rigor floor, the survey "
            "runs before the proposal." % (issue, issue)
        )
    sys.exit(0)

# phase-2 side: only decision-bearing writes (loop_state past proposal-only
# states) are gated. drafting/reviewing are the in-progress states;
# decision-not-ripe/options-unreachable are refusal/error states that also
# do not assert a decision, so phase-ordering does not apply to them either.
m_ls = re.search(r'^\s*loop_state:\s*([A-Za-z0-9_-]+)\s*$', content, re.M)
loop_state = m_ls.group(1).strip().lower() if m_ls else ""
if loop_state in ("", "drafting", "reviewing", "decision-not-ripe", "options-unreachable"):
    sys.exit(0)

missing = []
if not os.path.isfile(survey):
    missing.append("survey.md")

skip_justified = False
if not os.path.isfile(scout_brief):
    # look for an explicit skip-justification in this issue's proposal(s)
    proposals_dir = os.path.join(root, "docs", issue, "proposals")
    SKIP_PHRASES = ("scout skipped", "scouting skipped", "skip condition",
                     "no design decision open", "스카우트 생략", "스카우트를 생략")
    if os.path.isdir(proposals_dir):
        for fn in os.listdir(proposals_dir):
            if not fn.endswith(".md"):
                continue
            try:
                with open(os.path.join(proposals_dir, fn), encoding="utf-8-sig") as fh:
                    text = fh.read().lower()
            except OSError:
                continue
            if any(p in text for p in SKIP_PHRASES):
                skip_justified = True
                break
    if not skip_justified:
        missing.append("scout-brief.md")

if missing:
    deny(
        "docs/%s/reports/architecture.md sets loop_state '%s' (decision-bearing) but "
        "required phase-1 artifact(s) are missing: %s. Per this role's phase-1/phase-2 "
        "ordering norm, all phase-1 artifacts for %s must exist first (or scout-brief.md "
        "may be justified-skipped in the proposal text)." % (issue, loop_state, ", ".join(missing), issue)
    )

sys.exit(0)
PY
