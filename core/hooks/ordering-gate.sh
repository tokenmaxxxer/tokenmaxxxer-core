#!/usr/bin/env bash
# PreToolUse gate (Write|Edit|MultiEdit|Bash) — consolidates the 8
# role-scoped ordering gates promoted by core#234/#237 into one
# parameterized dispatcher (issue-240). Each role's surface regex(es),
# required file(s), and verification mechanism are carried over verbatim
# from the original per-role script (the #237 equivalence table is the
# frozen spec) into the ROLES table inside this script's Python payload.
# Dispatch is first-match-wins over ROLES in the order below: every
# filename-scoped role is tried before survey-order (the one unscoped,
# any-proposal rule), so a proposal write that matches a scoped role's
# surface is judged only by that role — never additionally re-judged by
# survey-order's generic rule, mirroring how the two would have run as
# fully independent PreToolUse entries whenever a scoped role's own gate
# already claims the write as its business.
#
# Kill switch per role: each role's env var name is preserved verbatim
# (e.g. SURVEY_ORDER_GATE_OFF, ARCH_SEQUENCE_GATE_OFF, ...) so existing
# operator overrides keep working unchanged. Checked once the role's
# surface has matched; a role whose kill switch is on is treated as
# "not this role's business" and dispatch continues to the next role in
# table order (never a global short-circuit).
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)}/hooks/lib/gate-lib.sh" || { echo "ordering-gate.sh: cannot source gate-lib.sh" >&2; exit 2; }
gate_trap_fail_closed
set -uo pipefail

command -v python3 >/dev/null 2>&1 || { echo "ordering-gate: refused — python3 not on PATH; denying rather than guessing." >&2; exit 2; }

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || { echo "ordering-gate: refused — empty tool-use payload on stdin; cannot evaluate write order." >&2; exit 2; }

root="${CLAUDE_PROJECT_DIR:-}"
if [ -z "$root" ]; then
  root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
fi
[ -z "$root" ] && root="$(pwd -P)"

OG_PAYLOAD="$payload" OG_ROOT="$root" GATE_LIB_PY="$GATE_LIB_PY" \
SURVEY_ORDER_GATE_OFF="${SURVEY_ORDER_GATE_OFF:-}" \
ARCH_SEQUENCE_GATE_OFF="${ARCH_SEQUENCE_GATE_OFF:-}" \
CONTENT_DESIGN_PHASE1_BASIS_GATE_OFF="${CONTENT_DESIGN_PHASE1_BASIS_GATE_OFF:-}" \
PHASE_ORDER_GATE_OFF="${PHASE_ORDER_GATE_OFF:-}" \
INCIDENT_RESPONSE_PROPOSAL_ORDER_GATE_OFF="${INCIDENT_RESPONSE_PROPOSAL_ORDER_GATE_OFF:-}" \
ID_STAGE_ORDER_GATE_OFF="${ID_STAGE_ORDER_GATE_OFF:-}" \
ISSUE_RETROSPECTIVE_PROPOSAL_ORDER_GATE_OFF="${ISSUE_RETROSPECTIVE_PROPOSAL_ORDER_GATE_OFF:-}" \
SECURITY_THREAT_MODEL_SEQUENCE_GATE_OFF="${SECURITY_THREAT_MODEL_SEQUENCE_GATE_OFF:-}" \
python3 <<'PY'
import sys as _fc_sys  # fail-closed-on-internal-error
try:
    import importlib.util, json, os, posixpath, re, sys

    _spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
    gate_lib = importlib.util.module_from_spec(_spec)
    _spec.loader.exec_module(gate_lib)

    def on(v):
        return (v or "").strip().lower() in ("1", "true", "yes", "on")

    raw = os.environ.get("OG_PAYLOAD", "")
    if not raw:
        sys.stderr.write("ordering-gate: refused — empty tool-use payload; cannot evaluate the gate on nothing\n")
        sys.exit(2)
    try:
        ev = json.loads(raw)
    except ValueError:
        sys.stderr.write("ordering-gate: refused — the tool-call payload is not valid JSON; refusing rather than guessing what was about to be written\n")
        sys.exit(2)
    if not isinstance(ev, dict):
        sys.stderr.write("ordering-gate: refused — the tool-call payload is not a JSON object; failing closed\n")
        sys.exit(2)

    tool = ev.get("tool_name")
    ti = ev.get("tool_input")
    if not isinstance(ti, dict):
        ti = {}

    root = posixpath.normpath(os.environ["OG_ROOT"].replace("\\", "/"))

    def deny(role, msg):
        sys.stderr.write("%s: refused — %s\n" % (role, msg))
        sys.exit(2)

    def norm(path):
        return gate_lib.gate_normalize_path(root, path)

    def resulting_content(abs_path):
        current = None
        if os.path.isfile(abs_path):
            try:
                with open(abs_path, encoding="utf-8-sig") as fh:
                    current = fh.read(1 << 20)
            except OSError:
                return None, False
        new_text, ok = gate_lib.gate_reconstruct_write(tool, ti, current)
        return (new_text if ok else None), True

    file_path = None
    if tool in ("Write", "Edit", "MultiEdit"):
        p = ti.get("file_path")
        if isinstance(p, str) and p:
            file_path = p
    bash_command = ti.get("command") if tool == "Bash" else None
    bash_targets = []
    if isinstance(bash_command, str) and bash_command:
        bash_targets = [t for t in gate_lib.gate_bash_write_targets(bash_command).splitlines() if t.strip()]

    # ---- mechanism: content-design-phase1-basis (content-citation) --------
    def mech_content_design():
        SCOPE_RE = re.compile(r'^docs/issue-[0-9]+/proposals/.*content-design.*\.md$')
        role = "content-design-phase1-basis"

        def in_scope(tail):
            return tail is not None and SCOPE_RE.fullmatch(tail) is not None

        if tool == "Bash":
            for tok in bash_targets:
                if in_scope(norm(tok)):
                    deny(role, "Bash-tool command appears to write to gated file '%s'; this gate cannot verify semantic content from a Bash write -- use Write/Edit/MultiEdit instead" % tok)
            return None
        if tool not in ("Write", "Edit", "MultiEdit"):
            return None
        rel = norm(file_path) if file_path else None
        if not in_scope(rel):
            return None
        abs_path = posixpath.join(root, rel)
        current = None if tool == "Write" else (open(abs_path, encoding="utf-8-sig").read() if os.path.isfile(abs_path) else None)
        if tool != "Write" and current is None:
            deny(role, "cannot determine resulting content (base file unreadable)")
        text, ok = gate_lib.gate_reconstruct_write(tool, ti, current)
        if not ok:
            deny(role, "cannot determine resulting content (edit target not found or unsupported shape)")
        survey_re = r'docs/issue-[0-9]+/reports/[\w-]+/survey\.md'
        if re.search(survey_re, text):
            return True
        if re.search(r'scout-brief', text, re.IGNORECASE):
            return True
        if re.search(r'skip(ped)?.{0,40}scout', text, re.IGNORECASE) or re.search(r'scout.{0,40}skip', text, re.IGNORECASE):
            return True
        deny(role, "missing stated survey+scout basis (or documented skip)")

    # ---- mechanism: devrel-phase-order (file-existence) --------------------
    def mech_devrel():
        role = "phase-order-gate"
        TARGET_RE = re.compile(r'^(docs/issue-[^/]+)/proposals/.*devrel.*\.md$', re.I)
        candidates = [file_path] if file_path else []
        if tool == "Bash":
            candidates = list(bash_targets)
        issue_root = None
        for c in candidates:
            rel = norm(c)
            if rel is None:
                continue
            m = TARGET_RE.match(rel)
            if m:
                issue_root = m.group(1)
                break
        if issue_root is None:
            return None
        survey_path = posixpath.join(root, issue_root, "reports", "devrel", "survey.md")
        if os.path.isfile(survey_path):
            return True
        deny(role, "docs/issue-<n>/proposals/*.md written before %s/reports/devrel/survey.md exists — write survey.md first (phase-1 order: survey -> scout -> proposal)." % issue_root)

    # ---- mechanism: security-threat-model-sequence (file-existence) -------
    def mech_security_threat_model():
        role = "security-threat-model"
        PROPOSAL_RE = re.compile(r'^docs/issue-([0-9]+)/proposals/.*security-threat-model.*\.md$', re.I)
        if tool not in ("Write", "Edit", "MultiEdit") or not file_path:
            return None
        rel = norm(file_path)
        if rel is None:
            return None
        m = PROPOSAL_RE.match(rel)
        if not m:
            return None
        issue_no = m.group(1)
        survey_rel = "docs/issue-%s/reports/security-threat-model/survey.md" % issue_no
        survey_abs = posixpath.join(root, survey_rel)
        if os.path.isfile(survey_abs):
            return True
        deny(role, "%s is a phase-1 proposal write for issue-%s, but %s does not exist. Per contract v3 s19 rigor floor / scout-directive survey-first-order, phase-1 proposals require the survey to exist first." % (rel, issue_no, survey_rel))

    # ---- mechanism: incident-response-order (two-file, window-skip) -------
    def mech_incident_response():
        role = "incident-response"
        SURFACE_RE = re.compile(r'^docs/issue-([0-9]+)/proposals/incident-response.*\.md$')

        def judge(path):
            rel = norm(path)
            if rel is None:
                return None
            m = SURFACE_RE.match(rel)
            if not m:
                return None
            n = m.group(1)
            survey_rel = "docs/issue-%s/reports/incident-response/current-state-survey.md" % n
            scout_rel = "docs/issue-%s/reports/incident-response/scout-brief.md" % n
            survey_abs = posixpath.join(root, survey_rel)
            scout_abs = posixpath.join(root, scout_rel)
            survey_exists = os.path.isfile(survey_abs)
            scout_exists = os.path.isfile(scout_abs)
            if survey_exists and scout_exists:
                return True
            skip_recorded = False
            if survey_exists:
                try:
                    with open(survey_abs, encoding="utf-8-sig") as fh:
                        content = fh.read(1 << 20)
                except OSError:
                    content = ""
                if content:
                    NEGATION_TOKENS = {"not", "never"}
                    lines = content.splitlines()
                    heading_re = re.compile(r'^(#{1,6})\s*.*scout\b', re.I)
                    section_lines = []
                    in_section = False
                    section_level = None
                    for ln in lines:
                        hm = re.match(r'^(#{1,6})\s+(.*)$', ln)
                        if hm:
                            level = len(hm.group(1))
                            if heading_re.match(ln):
                                in_section = True
                                section_level = level
                                continue
                            if in_section and level <= (section_level or 1):
                                in_section = False
                                continue
                        if in_section:
                            section_lines.append(ln)
                        elif re.match(r'^\s*scout(\s*brief)?\s*:?\s*$', ln, re.I):
                            in_section = True
                            section_level = 99
                    skip_marker_re = re.compile(r'\bskip(?:ped|ping)?\b', re.I)
                    if any(skip_marker_re.search(ln) for ln in section_lines):
                        skip_recorded = True
                    if not skip_recorded:
                        tokens = re.findall(r"[A-Za-z']+", content.lower())
                        skip_idxs = [i for i, t in enumerate(tokens) if t in ("skip", "skipped", "skipping")]
                        scout_idxs = [i for i, t in enumerate(tokens) if t == "scout"]
                        for si in skip_idxs:
                            if skip_recorded:
                                break
                            for ci in scout_idxs:
                                if abs(si - ci) > 15:
                                    continue
                                lo, hi = min(si, ci), max(si, ci)
                                window = tokens[max(0, lo - 15):hi + 1]
                                if not any(t in NEGATION_TOKENS or t.endswith("n't") for t in window):
                                    skip_recorded = True
                                    break
            if skip_recorded:
                return True
            missing = []
            if not survey_exists:
                missing.append(survey_rel)
            if not scout_exists:
                missing.append(scout_rel)
            deny(role, "write to %s requires phase-1 order (survey then scout-brief) to be on disk first, per docs/issue-7/proposals/incident-response.md §2 (issue-1 (a)(1)). Missing: %s. Create the missing file(s), or record an explicit, non-negated scout-skip (\"skip\"/\"scout\" near each other, or under a scout-heading section) in %s, before writing the proposal." % (rel, ", ".join(missing), survey_rel))

        if tool == "Bash":
            matched = False
            for tok in bash_targets:
                r = judge(tok)
                if r is not None:
                    matched = True
                    if r is True:
                        return True
            return True if matched else None
        if tool in ("Write", "Edit", "MultiEdit") and file_path:
            return judge(file_path)
        return None

    # ---- mechanism: interaction-design-stage-order (two-file + record) ----
    def mech_interaction_design():
        role = "id-stage-order"
        PROPOSAL_RE = re.compile(r'^docs/issue-([0-9]+)/proposals/.*interaction-design.*\.md$', re.I)
        RECORD_RE = re.compile(r'^docs/issue-([0-9]+)/reports/interaction-design\.md$')

        path = None
        if tool in ("Write", "Edit", "MultiEdit"):
            path = file_path
        elif tool == "Bash" and isinstance(bash_command, str):
            for tok in re.findall(r'[A-Za-z0-9_./~$-]+', bash_command):
                rel_try = norm(tok)
                if (rel_try and (PROPOSAL_RE.match(rel_try) or RECORD_RE.match(rel_try))):
                    path = tok
                    break
        if path is None:
            return None
        rel = norm(path)
        if rel is None:
            return None
        r = posixpath.join(root, rel) if rel else root

        def update_status(issue_n, stage):
            try:
                status_dir = posixpath.join(root, "docs", "issue-%s" % issue_n, "reports", "interaction-design")
                status_path = posixpath.join(status_dir, ".status.json")
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
                survey_p = posixpath.join(status_dir, "survey.md")
                scout_p = posixpath.join(status_dir, "scout-brief.md")
                proposals_dir = posixpath.join(root, "docs", "issue-%s" % issue_n, "proposals")
                record_p = posixpath.join(root, "docs", "issue-%s" % issue_n, "reports", "interaction-design.md")

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

                has_proposal = os.path.isdir(proposals_dir) and any(f.endswith(".md") for f in os.listdir(proposals_dir))
                data[subject]["survey"] = "done" if os.path.isfile(survey_p) else data[subject].get("survey", "pending")
                data[subject]["scout"] = "done" if (os.path.isfile(scout_p) or scout_skipped()) else data[subject].get("scout", "pending")
                data[subject]["proposal"] = "done" if has_proposal else data[subject].get("proposal", "pending")
                data[subject]["record"] = "done" if os.path.isfile(record_p) else data[subject].get("record", "pending")
                data[subject][stage] = "done"

                os.makedirs(status_dir, exist_ok=True)
                with open(status_path, "w", encoding="utf-8") as fh:
                    json.dump(data, fh, indent=2)
            except Exception as _state_e:
                sys.stderr.write("id-stage-order: warning: could not update status file: %r\n" % (_state_e,))

        m = PROPOSAL_RE.match(rel)
        if m:
            issue_n = m.group(1)
            if os.path.isfile(r):
                return True
            rd = posixpath.join(root, "docs", "issue-%s" % issue_n, "reports", "interaction-design")
            survey_p = posixpath.join(rd, "survey.md")
            scout_p = posixpath.join(rd, "scout-brief.md")
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
                deny(role, "new proposal at %s requires the prerequisite stage artifact(s) under docs/issue-%s/reports/interaction-design/ to already exist first: missing %s (scout-brief.md is excused only if survey.md itself records an explicit scout-skip). Per docs/issue-21/proposals/issue-21-interaction-design-gate-machine.md §4/§6, stage ordering is survey -> scout -> proposal." % (rel, issue_n, ", ".join(missing)))
            update_status(issue_n, "proposal")
            return True

        m = RECORD_RE.match(rel)
        if m:
            issue_n = m.group(1)
            proposals_dir = posixpath.join(root, "docs", "issue-%s" % issue_n, "proposals")
            has_proposal = os.path.isdir(proposals_dir) and any(f.endswith(".md") for f in os.listdir(proposals_dir))
            if not has_proposal:
                deny(role, "phase-2 record write at %s requires at least one docs/issue-%s/proposals/*.md file to already exist on disk — none found. This plugin checks only that a proposal document exists (a purely local/offline precondition); it does NOT check GitHub or human approval itself — core's hooks/approval-gate.sh already fail-closed-blocks this same write until an allowlisted human's Approve exists on GitHub (contract v3 s19). Write the proposal and get it approved first." % (rel, issue_n))
            update_status(issue_n, "record")
            return True

        return None

    # ---- mechanism: arch-sequence (two globs, two directions, Bash heur) --
    def mech_arch_sequence():
        role = "arch-sequence-gate"
        PROPOSAL_RE = re.compile(r'^docs/(issue-[0-9]+)/proposals/.*architecture.*\.md$', re.I)
        RECORD_RE = re.compile(r'^docs/(issue-[0-9]+)/reports/architecture\.md$')
        BASH_WRITE_RE = re.compile(r'(?:^|[\s;&|])(?:>>?|tee\s+(?:-a\s+)?)\s*(["\']?)([^\s"\';|&<>]+)\1')

        if tool == "Bash":
            if not isinstance(bash_command, str):
                return None
            matched = False
            for mo in BASH_WRITE_RE.finditer(bash_command):
                token = mo.group(2)
                rel_candidate = norm(token)
                if rel_candidate is None:
                    continue
                m_bash = PROPOSAL_RE.match(rel_candidate) or RECORD_RE.match(rel_candidate)
                if m_bash:
                    matched = True
                    deny(role, "a Bash command appears to target %s (matched %s), which is a phase-ordering-gated path (docs/%s/proposals/*.md or the phase-2 record). arch-sequence-gate cannot reconstruct arbitrary shell output, so resulting-content computation is out of scope and this write is refused. Use Write/Edit/MultiEdit on this path instead." % (rel_candidate, token, m_bash.group(1)))
            return True if matched else None

        if tool not in ("Write", "Edit", "MultiEdit") or not file_path:
            return None
        rel = norm(file_path)
        if rel is None:
            return None
        abs_path = posixpath.join(root, rel) if rel else root
        m = PROPOSAL_RE.match(rel) or RECORD_RE.match(rel)
        if not m:
            return None
        issue = m.group(1)
        is_record = bool(RECORD_RE.match(rel))

        current = None
        if os.path.isfile(abs_path):
            try:
                with open(abs_path, encoding="utf-8-sig") as fh:
                    current = fh.read(1 << 20)
            except OSError:
                deny(role, "%s exists but cannot be read" % rel)
        new_text, ok = gate_lib.gate_reconstruct_write(tool, ti, current)
        content = new_text if ok else None
        if content is None:
            deny(role, "this write targets %s but the resulting content cannot be determined from tool=%r input. Use Write, or an Edit/MultiEdit whose old_string matches, so phase ordering can be checked." % (rel, tool))

        survey = posixpath.join(root, "docs", issue, "reports", "architecture", "survey.md")
        scout_brief = posixpath.join(root, "docs", issue, "reports", "architecture", "scout-brief.md")

        if not is_record:
            if not os.path.isfile(survey):
                deny(role, "docs/%s/proposals/*.md is being written but docs/%s/reports/architecture/survey.md does not exist yet. Per contract v3 s19's rigor floor, the survey runs before the proposal." % (issue, issue))
            return True

        m_ls = re.search(r'^\s*loop_state:\s*([A-Za-z0-9_-]+)\s*$', content, re.M)
        loop_state = m_ls.group(1).strip().lower() if m_ls else ""
        if loop_state in ("", "drafting", "reviewing", "decision-not-ripe", "options-unreachable"):
            return True

        missing = []
        if not os.path.isfile(survey):
            missing.append("survey.md")
        skip_justified = False
        if not os.path.isfile(scout_brief):
            proposals_dir = posixpath.join(root, "docs", issue, "proposals")
            SKIP_PHRASES = ("scout skipped", "scouting skipped", "skip condition",
                             "no design decision open", "스카우트 생략", "스카우트를 생략")
            if os.path.isdir(proposals_dir):
                for fn in os.listdir(proposals_dir):
                    if not fn.endswith(".md"):
                        continue
                    try:
                        with open(posixpath.join(proposals_dir, fn), encoding="utf-8-sig") as fh:
                            text = fh.read().lower()
                    except OSError:
                        continue
                    if any(p in text for p in SKIP_PHRASES):
                        skip_justified = True
                        break
            if not skip_justified:
                missing.append("scout-brief.md")
        if missing:
            deny(role, "docs/%s/reports/architecture.md sets loop_state '%s' (decision-bearing) but required phase-1 artifact(s) are missing: %s. Per this role's phase-1/phase-2 ordering norm, all phase-1 artifacts for %s must exist first (or scout-brief.md may be justified-skipped in the proposal text)." % (issue, loop_state, ", ".join(missing), issue))
        return True

    # ---- mechanism: issue-retrospective-proposal-order (cross-file) -------
    def mech_issue_retrospective():
        role = "issue-retrospective"
        RECORD_RE = re.compile(r'^docs/issue-([0-9]+)/reports/issue-retrospective\.md$')
        if tool not in ("Write", "Edit", "MultiEdit") or not file_path:
            return None
        rel = norm(file_path)
        if rel is None:
            return None
        m = RECORD_RE.match(rel)
        if not m:
            return None
        subject_n = m.group(1)
        prop_dir = posixpath.join(root, "docs", "issue-%s" % subject_n, "proposals")
        prop_path = None
        if os.path.isdir(prop_dir):
            for name in sorted(os.listdir(prop_dir)):
                if "issue-retrospective" in name.lower() and name.lower().endswith(".md"):
                    prop_path = posixpath.join(prop_dir, name)
                    break
        if prop_path is None or not os.path.isfile(prop_path):
            deny(role, "issue-retrospective record write for subject issue-%s targets %s but no phase-1 proposal (docs/issue-%s/proposals/*issue-retrospective*.md) exists on disk. Per contract v3 s19, phase 1 (proposal) must precede phase 2 (record)." % (subject_n, rel, subject_n))
        try:
            with open(prop_path, encoding="utf-8-sig") as fh:
                prop_text = fh.read(1 << 20)
        except OSError:
            deny(role, "issue-retrospective record write for subject issue-%s targets %s but its phase-1 proposal at %s exists and cannot be read; failing closed on phase ordering." % (subject_n, rel, prop_path[len(root):].lstrip("/")))
        low = prop_text.lower()
        names_survey = bool(re.search(r'reports/issue-retrospective/survey\.md|current-state survey', low))
        names_scout = bool(re.search(r'scout-brief\.md', low))
        explicit_skip = bool(re.search(r'scout(ing)? (was )?skipped|no design decision', low))
        if not names_survey:
            deny(role, "phase-1 proposal for subject issue-%s (%s) does not name a survey path (docs/issue-%s/reports/issue-retrospective/survey.md). Per contract v3 s19, a phase-2 record write requires its own phase-1 proposal to name the survey it read." % (subject_n, prop_path[len(root):].lstrip("/"), subject_n))
        if not (names_scout or explicit_skip):
            deny(role, "phase-1 proposal for subject issue-%s (%s) names no scout-brief path and no explicit scout-skip statement. Per the platform scout directive, a phase-1 proposal must either link its scout brief or record why scouting was skipped." % (subject_n, prop_path[len(root):].lstrip("/")))
        return True

    # ---- mechanism: survey-order (file-existence, unscoped fallback) ------
    def mech_survey_order():
        role = "survey-order"
        PROPOSAL_RE = re.compile(r'^docs/issue-([0-9]+)/proposals/.*\.md$')
        if tool not in ("Write", "Edit", "MultiEdit") or not file_path:
            return None
        rel = norm(file_path)
        if rel is None:
            return None
        m = PROPOSAL_RE.match(rel)
        if not m:
            return None
        issue_n = m.group(1)
        survey_rel = "docs/issue-%s/reports/implementation/survey.md" % issue_n
        survey_abs = posixpath.join(root, survey_rel)
        if os.path.isfile(survey_abs):
            return True
        abs_path = posixpath.join(root, rel)
        current = None
        if os.path.isfile(abs_path):
            try:
                with open(abs_path, encoding="utf-8-sig") as fh:
                    current = fh.read(1 << 20)
            except OSError:
                deny(role, "%s exists but cannot be read; failing closed on write order." % rel)
        new_text, ok = gate_lib.gate_reconstruct_write(tool, ti, current)
        new_text = new_text if ok else None
        if new_text is None:
            deny(role, "%s targets a phase-1 proposal but the survey file %s is absent, and the gate cannot determine the resulting content from the tool input (tool=%r) to check for scout-skip language. Write the full document with Write, or use an Edit/MultiEdit whose old_string matches, so write order can be checked." % (rel, survey_rel, tool))
        low = new_text.lower()
        SKIP_MARKERS = ("skip condition", "scouting was skipped", "pure bugfix", "no design decision", "skip record")
        if any(mk in low for mk in SKIP_MARKERS):
            return True
        deny(role, "%s is a phase-1 proposal write for issue-%s, but its survey file %s does not exist on disk, and the proposal's own text states no scout-skip condition. Write the current-state survey first, or — only for a pure bugfix or a spec that leaves no design decision open — state which skip condition applies and why, in the proposal body itself." % (rel, issue_n, survey_rel))

    # role table: (kill-switch env var name, mechanism function).
    # Filename-scoped roles are tried before survey-order (the sole
    # unscoped, any-proposal rule) so a scoped role's own surface is never
    # additionally re-judged by survey-order's generic rule.
    ROLES = [
        ("CONTENT_DESIGN_PHASE1_BASIS_GATE_OFF", mech_content_design),
        ("PHASE_ORDER_GATE_OFF", mech_devrel),
        ("SECURITY_THREAT_MODEL_SEQUENCE_GATE_OFF", mech_security_threat_model),
        ("INCIDENT_RESPONSE_PROPOSAL_ORDER_GATE_OFF", mech_incident_response),
        ("ID_STAGE_ORDER_GATE_OFF", mech_interaction_design),
        ("ARCH_SEQUENCE_GATE_OFF", mech_arch_sequence),
        ("ISSUE_RETROSPECTIVE_PROPOSAL_ORDER_GATE_OFF", mech_issue_retrospective),
        ("SURVEY_ORDER_GATE_OFF", mech_survey_order),
    ]

    for env_name, mech in ROLES:
        if on(os.environ.get(env_name, "")):
            continue
        result = mech()
        if result is True:
            sys.exit(0)
        # result is None: not this role's business, try the next role.

    sys.exit(0)
except SystemExit:
    raise
except Exception as _fc_e:  # fail-closed-on-internal-error
    _fc_sys.stderr.write("ordering-gate.sh: fail-closed: internal error: %r\n" % (_fc_e,))
    _fc_sys.exit(2)
PY
_fc_rc=$?
if [ "$_fc_rc" -ne 0 ] && [ "$_fc_rc" -ne 2 ]; then
  echo "ordering-gate: refused — fail-closed: internal error (judge exited $_fc_rc)" >&2
  exit 2
fi
exit "$_fc_rc"
