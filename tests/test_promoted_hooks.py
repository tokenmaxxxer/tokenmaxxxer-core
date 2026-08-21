"""Behavior-equivalence tests for the 3 hook pairs promoted from
implementation-rulebook into core/hooks (issue-234): proposal-shape,
record-shape, survey-order. Each gate gets an allow case, a refuse case,
and an empty-state case (write outside the gate's target surface passes
through silently), invoking the promoted gate script as a subprocess —
mirroring tests/test_side_effect_round.py's existing subprocess pattern.
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


PROPOSAL_OK = """files:
  - core/hooks/x.sh

## Request
do the thing

## Constraints
none

## Rationale
We considered Y but rejected it because Z.

## What will be done
build X

## Out of scope
nothing else

## How you'll know it worked
tests pass
"""

PROPOSAL_MISSING_SECTIONS = """files:
  - core/hooks/x.sh

## Request
do the thing

## What will be done
build X
"""


def test_proposal_shape_gate_allows_well_shaped_proposal(tmp_path):
    root = _init_project(tmp_path)
    (root / "docs" / "issue-1" / "proposals").mkdir(parents=True)
    payload = write_payload(
        "docs/issue-1/proposals/2026-08-21-thing.md", PROPOSAL_OK
    )
    proc = run_gate("proposal-shape-gate.sh", payload, root)
    assert proc.returncode == 0, proc.stderr


def test_proposal_shape_gate_refuses_missing_sections(tmp_path):
    root = _init_project(tmp_path)
    (root / "docs" / "issue-1" / "proposals").mkdir(parents=True)
    payload = write_payload(
        "docs/issue-1/proposals/2026-08-21-thing.md", PROPOSAL_MISSING_SECTIONS
    )
    proc = run_gate("proposal-shape-gate.sh", payload, root)
    assert proc.returncode == 2
    assert "refused" in proc.stderr


def test_proposal_shape_gate_empty_state_passes_through(tmp_path):
    root = _init_project(tmp_path)
    payload = write_payload("core/hooks/unrelated.sh", "#!/usr/bin/env bash\n")
    proc = run_gate("proposal-shape-gate.sh", payload, root)
    assert proc.returncode == 0, proc.stderr


RECORD_OK = """---
code_under_review:
  - core/hooks/x.sh
loop_state: landed
type: feature
breaking: "false"
verdict: pass
---

## What did not work

None.
"""

RECORD_MISSING_FRONTMATTER = """---
loop_state: landed
---

## What did not work

None.
"""


def test_record_shape_gate_allows_well_shaped_record(tmp_path):
    root = _init_project(tmp_path)
    (root / "docs" / "issue-1" / "reports").mkdir(parents=True)
    payload = write_payload("docs/issue-1/reports/implementation.md", RECORD_OK)
    proc = run_gate("record-shape-gate.sh", payload, root)
    assert proc.returncode == 0, proc.stderr


def test_record_shape_gate_refuses_missing_frontmatter_keys(tmp_path):
    root = _init_project(tmp_path)
    (root / "docs" / "issue-1" / "reports").mkdir(parents=True)
    payload = write_payload(
        "docs/issue-1/reports/implementation.md", RECORD_MISSING_FRONTMATTER
    )
    proc = run_gate("record-shape-gate.sh", payload, root)
    assert proc.returncode == 2
    assert "refused" in proc.stderr


def test_record_shape_gate_empty_state_passes_through(tmp_path):
    root = _init_project(tmp_path)
    payload = write_payload("core/hooks/unrelated.sh", "#!/usr/bin/env bash\n")
    proc = run_gate("record-shape-gate.sh", payload, root)
    assert proc.returncode == 0, proc.stderr


def test_survey_order_gate_allows_proposal_when_survey_exists(tmp_path):
    root = _init_project(tmp_path)
    (root / "docs" / "issue-1" / "proposals").mkdir(parents=True)
    survey_dir = root / "docs" / "issue-1" / "reports" / "implementation"
    survey_dir.mkdir(parents=True)
    (survey_dir / "survey.md").write_text("survey content\n")
    payload = write_payload(
        "docs/issue-1/proposals/2026-08-21-thing.md", PROPOSAL_OK
    )
    proc = run_gate("survey-order-gate.sh", payload, root)
    assert proc.returncode == 0, proc.stderr


def test_survey_order_gate_refuses_proposal_without_survey_or_skip(tmp_path):
    root = _init_project(tmp_path)
    (root / "docs" / "issue-1" / "proposals").mkdir(parents=True)
    payload = write_payload(
        "docs/issue-1/proposals/2026-08-21-thing.md", PROPOSAL_OK
    )
    proc = run_gate("survey-order-gate.sh", payload, root)
    assert proc.returncode == 2
    assert "refused" in proc.stderr


def test_survey_order_gate_empty_state_passes_through(tmp_path):
    root = _init_project(tmp_path)
    payload = write_payload("core/hooks/unrelated.sh", "#!/usr/bin/env bash\n")
    proc = run_gate("survey-order-gate.sh", payload, root)
    assert proc.returncode == 0, proc.stderr
