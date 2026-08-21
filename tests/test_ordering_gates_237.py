"""Behavior-equivalence tests for the 7 hook scripts promoted from their
rulebooks into core/hooks (issue-237): arch-sequence, content-design
phase1-basis, devrel phase-order, incident-response order, interaction-design
stage-order, issue-retrospective proposal-order, security-threat-model
sequence. Each gate gets an allow case, a refuse case, and an empty-state
case, invoking the promoted gate script as a subprocess — mirroring
tests/test_promoted_hooks.py's existing pattern.
"""
import json
import subprocess
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent


def _init_project(tmp_path):
    (tmp_path / ".git").mkdir()
    return tmp_path


def run_gate(gate_name, payload, cwd):
    proc = subprocess.run(
        ["bash", str(REPO / "core/hooks" / gate_name)],
        input=json.dumps(payload),
        capture_output=True,
        text=True,
        cwd=str(cwd),
        env={"CLAUDE_PROJECT_DIR": str(cwd), "PATH": "/usr/bin:/bin:/usr/local/bin"},
        timeout=15,
    )
    return proc


def write_payload(file_path, content):
    return {
        "tool_name": "Write",
        "tool_input": {"file_path": file_path, "content": content},
    }


# --- arch-sequence-gate.sh ---------------------------------------------

def test_arch_sequence_gate_allows_when_survey_exists(tmp_path):
    root = _init_project(tmp_path)
    (root / "docs" / "issue-1" / "reports" / "architecture").mkdir(parents=True)
    (root / "docs" / "issue-1" / "reports" / "architecture" / "survey.md").write_text("x")
    (root / "docs" / "issue-1" / "proposals").mkdir(parents=True)
    payload = write_payload("docs/issue-1/proposals/architecture-thing.md", "content")
    proc = run_gate("arch-sequence-gate.sh", payload, root)
    assert proc.returncode == 0, proc.stderr


def test_arch_sequence_gate_refuses_missing_survey(tmp_path):
    root = _init_project(tmp_path)
    (root / "docs" / "issue-1" / "proposals").mkdir(parents=True)
    payload = write_payload("docs/issue-1/proposals/architecture-thing.md", "content")
    proc = run_gate("arch-sequence-gate.sh", payload, root)
    assert proc.returncode == 2
    assert "refused" in proc.stderr


def test_arch_sequence_gate_empty_state_passes_through(tmp_path):
    root = _init_project(tmp_path)
    payload = write_payload("core/hooks/unrelated.sh", "#!/usr/bin/env bash\n")
    proc = run_gate("arch-sequence-gate.sh", payload, root)
    assert proc.returncode == 0, proc.stderr


def test_arch_sequence_gate_allows_foreign_role_proposal_without_survey(tmp_path):
    # issue-242 regression: a plain (non-architecture) proposal write must
    # not be gated by architecture's own survey requirement.
    root = _init_project(tmp_path)
    (root / "docs" / "issue-1" / "proposals").mkdir(parents=True)
    payload = write_payload("docs/issue-1/proposals/consolidation.md", "content")
    proc = run_gate("arch-sequence-gate.sh", payload, root)
    assert proc.returncode == 0, proc.stderr


# --- content-design-phase1-basis-gate.sh --------------------------------

def test_content_design_phase1_basis_gate_allows_with_survey_reference(tmp_path):
    root = _init_project(tmp_path)
    (root / "docs" / "issue-1" / "proposals").mkdir(parents=True)
    payload = write_payload(
        "docs/issue-1/proposals/content-design-thing.md",
        "see docs/issue-1/reports/content-design/survey.md for basis",
    )
    proc = run_gate("content-design-phase1-basis-gate.sh", payload, root)
    assert proc.returncode == 0, proc.stderr


def test_content_design_phase1_basis_gate_refuses_missing_basis(tmp_path):
    root = _init_project(tmp_path)
    (root / "docs" / "issue-1" / "proposals").mkdir(parents=True)
    payload = write_payload(
        "docs/issue-1/proposals/content-design-thing.md", "no basis stated here"
    )
    proc = run_gate("content-design-phase1-basis-gate.sh", payload, root)
    assert proc.returncode == 2


def test_content_design_phase1_basis_gate_empty_state_passes_through(tmp_path):
    root = _init_project(tmp_path)
    payload = write_payload("core/hooks/unrelated.sh", "#!/usr/bin/env bash\n")
    proc = run_gate("content-design-phase1-basis-gate.sh", payload, root)
    assert proc.returncode == 0, proc.stderr


# --- devrel-phase-order-gate.sh -----------------------------------------

def test_devrel_phase_order_gate_allows_when_survey_exists(tmp_path):
    root = _init_project(tmp_path)
    (root / "docs" / "issue-1" / "reports" / "devrel").mkdir(parents=True)
    (root / "docs" / "issue-1" / "reports" / "devrel" / "survey.md").write_text("x")
    (root / "docs" / "issue-1" / "proposals").mkdir(parents=True)
    payload = write_payload("docs/issue-1/proposals/devrel-thing.md", "content")
    proc = run_gate("devrel-phase-order-gate.sh", payload, root)
    assert proc.returncode == 0, proc.stderr


def test_devrel_phase_order_gate_refuses_missing_survey(tmp_path):
    root = _init_project(tmp_path)
    (root / "docs" / "issue-1" / "proposals").mkdir(parents=True)
    payload = write_payload("docs/issue-1/proposals/devrel-thing.md", "content")
    proc = run_gate("devrel-phase-order-gate.sh", payload, root)
    assert proc.returncode == 2
    assert "refused" in proc.stderr


def test_devrel_phase_order_gate_empty_state_passes_through(tmp_path):
    root = _init_project(tmp_path)
    payload = write_payload("core/hooks/unrelated.sh", "#!/usr/bin/env bash\n")
    proc = run_gate("devrel-phase-order-gate.sh", payload, root)
    assert proc.returncode == 0, proc.stderr


def test_devrel_phase_order_gate_allows_foreign_role_proposal_without_survey(tmp_path):
    root = _init_project(tmp_path)
    (root / "docs" / "issue-1" / "proposals").mkdir(parents=True)
    payload = write_payload("docs/issue-1/proposals/consolidation.md", "content")
    proc = run_gate("devrel-phase-order-gate.sh", payload, root)
    assert proc.returncode == 0, proc.stderr


# --- incident-response-order-gate.sh ------------------------------------

def test_incident_response_order_gate_allows_when_both_exist(tmp_path):
    root = _init_project(tmp_path)
    rd = root / "docs" / "issue-1" / "reports" / "incident-response"
    rd.mkdir(parents=True)
    (rd / "current-state-survey.md").write_text("x")
    (rd / "scout-brief.md").write_text("x")
    (root / "docs" / "issue-1" / "proposals").mkdir(parents=True)
    payload = write_payload("docs/issue-1/proposals/incident-response-thing.md", "content")
    proc = run_gate("incident-response-order-gate.sh", payload, root)
    assert proc.returncode == 0, proc.stderr


def test_incident_response_order_gate_refuses_missing_artifacts(tmp_path):
    root = _init_project(tmp_path)
    (root / "docs" / "issue-1" / "proposals").mkdir(parents=True)
    payload = write_payload("docs/issue-1/proposals/incident-response-thing.md", "content")
    proc = run_gate("incident-response-order-gate.sh", payload, root)
    assert proc.returncode == 2
    assert "refused" in proc.stderr


def test_incident_response_order_gate_empty_state_passes_through(tmp_path):
    root = _init_project(tmp_path)
    payload = write_payload("core/hooks/unrelated.sh", "#!/usr/bin/env bash\n")
    proc = run_gate("incident-response-order-gate.sh", payload, root)
    assert proc.returncode == 0, proc.stderr


# --- interaction-design-stage-order-gate.sh -------------------------------

def test_interaction_design_stage_order_gate_allows_when_both_exist(tmp_path):
    root = _init_project(tmp_path)
    rd = root / "docs" / "issue-1" / "reports" / "interaction-design"
    rd.mkdir(parents=True)
    (rd / "survey.md").write_text("x")
    (rd / "scout-brief.md").write_text("x")
    (root / "docs" / "issue-1" / "proposals").mkdir(parents=True)
    payload = write_payload("docs/issue-1/proposals/interaction-design-thing.md", "content")
    proc = run_gate("interaction-design-stage-order-gate.sh", payload, root)
    assert proc.returncode == 0, proc.stderr


def test_interaction_design_stage_order_gate_refuses_missing_artifacts(tmp_path):
    root = _init_project(tmp_path)
    (root / "docs" / "issue-1" / "proposals").mkdir(parents=True)
    payload = write_payload("docs/issue-1/proposals/interaction-design-thing.md", "content")
    proc = run_gate("interaction-design-stage-order-gate.sh", payload, root)
    assert proc.returncode == 2
    assert "refused" in proc.stderr


def test_interaction_design_stage_order_gate_empty_state_passes_through(tmp_path):
    root = _init_project(tmp_path)
    payload = write_payload("core/hooks/unrelated.sh", "#!/usr/bin/env bash\n")
    proc = run_gate("interaction-design-stage-order-gate.sh", payload, root)
    assert proc.returncode == 0, proc.stderr


def test_interaction_design_stage_order_gate_allows_foreign_role_proposal_without_artifacts(tmp_path):
    root = _init_project(tmp_path)
    (root / "docs" / "issue-1" / "proposals").mkdir(parents=True)
    payload = write_payload("docs/issue-1/proposals/consolidation.md", "content")
    proc = run_gate("interaction-design-stage-order-gate.sh", payload, root)
    assert proc.returncode == 0, proc.stderr


# --- issue-retrospective-proposal-order-gate.sh ---------------------------

def test_issue_retrospective_proposal_order_gate_allows_with_full_proposal(tmp_path):
    root = _init_project(tmp_path)
    (root / "docs" / "issue-1" / "proposals").mkdir(parents=True)
    (root / "docs" / "issue-1" / "proposals" / "issue-retrospective-thing.md").write_text(
        "see docs/issue-1/reports/issue-retrospective/survey.md and scout-brief.md"
    )
    (root / "docs" / "issue-1" / "reports").mkdir(parents=True)
    payload = write_payload("docs/issue-1/reports/issue-retrospective.md", "record content")
    proc = run_gate("issue-retrospective-proposal-order-gate.sh", payload, root)
    assert proc.returncode == 0, proc.stderr


def test_issue_retrospective_proposal_order_gate_refuses_missing_proposal(tmp_path):
    root = _init_project(tmp_path)
    (root / "docs" / "issue-1" / "reports").mkdir(parents=True)
    payload = write_payload("docs/issue-1/reports/issue-retrospective.md", "record content")
    proc = run_gate("issue-retrospective-proposal-order-gate.sh", payload, root)
    assert proc.returncode == 2
    assert "refused" in proc.stderr


def test_issue_retrospective_proposal_order_gate_empty_state_passes_through(tmp_path):
    root = _init_project(tmp_path)
    payload = write_payload("core/hooks/unrelated.sh", "#!/usr/bin/env bash\n")
    proc = run_gate("issue-retrospective-proposal-order-gate.sh", payload, root)
    assert proc.returncode == 0, proc.stderr


# --- security-threat-model-sequence-gate.sh -------------------------------

def test_security_threat_model_sequence_gate_allows_when_survey_exists(tmp_path):
    root = _init_project(tmp_path)
    rd = root / "docs" / "issue-1" / "reports" / "security-threat-model"
    rd.mkdir(parents=True)
    (rd / "survey.md").write_text("x")
    (root / "docs" / "issue-1" / "proposals").mkdir(parents=True)
    payload = write_payload("docs/issue-1/proposals/security-threat-model-thing.md", "content")
    proc = run_gate("security-threat-model-sequence-gate.sh", payload, root)
    assert proc.returncode == 0, proc.stderr


def test_security_threat_model_sequence_gate_refuses_missing_survey(tmp_path):
    root = _init_project(tmp_path)
    (root / "docs" / "issue-1" / "proposals").mkdir(parents=True)
    payload = write_payload("docs/issue-1/proposals/security-threat-model-thing.md", "content")
    proc = run_gate("security-threat-model-sequence-gate.sh", payload, root)
    assert proc.returncode == 2
    assert "refused" in proc.stderr


def test_security_threat_model_sequence_gate_empty_state_passes_through(tmp_path):
    root = _init_project(tmp_path)
    payload = write_payload("core/hooks/unrelated.sh", "#!/usr/bin/env bash\n")
    proc = run_gate("security-threat-model-sequence-gate.sh", payload, root)
    assert proc.returncode == 0, proc.stderr
