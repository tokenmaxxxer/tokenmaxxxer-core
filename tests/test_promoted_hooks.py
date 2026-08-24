"""Behavior-equivalence tests for the 3 hook pairs promoted from
implementation-rulebook into core/hooks (issue-234): proposal-shape,
record-shape, survey-order. Each gate gets an allow case, a refuse case,
and an empty-state case (write outside the gate's target surface passes
through silently), invoking the promoted gate script as a subprocess —
mirroring tests/test_side_effect_round.py's existing subprocess pattern.
"""
import json
import re
import subprocess
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent

# bash 3.2 (macOS system bash) fails to parse a heredoc inside a command
# substitution ("unexpected EOF") -- matches `$(cmd <<TAG` / `$(cmd <<'TAG'`
# with the substitution's own body providing the heredoc (issue #245).
HEREDOC_IN_CMD_SUBST_RE = re.compile(r"\$\(\s*[^\n)]*<<")


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


def _init_git_project(tmp_path):
    # issue-285's trivial-diff exemption reads `git diff HEAD --numstat`, so
    # these cases need a real repo with a committed HEAD, not just a bare
    # ".git" directory like _init_project's other callers use.
    root = tmp_path
    env = {"GIT_AUTHOR_NAME": "t", "GIT_AUTHOR_EMAIL": "t@example.com",
           "GIT_COMMITTER_NAME": "t", "GIT_COMMITTER_EMAIL": "t@example.com"}
    subprocess.run(["git", "init", "-q"], cwd=root, check=True)
    (root / "docs" / "issue-1" / "reports").mkdir(parents=True)
    (root / "src.py").write_text("line1\nline2\nline3\n")
    subprocess.run(["git", "add", "."], cwd=root, check=True)
    subprocess.run(["git", "commit", "-q", "-m", "init"], cwd=root, check=True, env=env)
    return root


RECORD_TRIVIAL_NO_BREAKING_NO_HEADING = """---
code_under_review:
  - src.py
loop_state: landed
type: fix
verdict: pass
---

Nothing to report for this trivial change.
"""

RECORD_TRIVIAL_NO_ACKNOWLEDGMENT = """---
code_under_review:
  - src.py
loop_state: landed
type: fix
verdict: pass
---

Did the thing.
"""


def test_record_shape_gate_trivial_diff_exempts_breaking_and_heading(tmp_path):
    root = _init_git_project(tmp_path)
    (root / "src.py").write_text("line1\nline2 changed\nline3\n")  # 1 line changed
    payload = write_payload(
        "docs/issue-1/reports/implementation.md", RECORD_TRIVIAL_NO_BREAKING_NO_HEADING
    )
    proc = run_gate("record-shape-gate.sh", payload, root)
    assert proc.returncode == 0, proc.stderr


def test_record_shape_gate_trivial_diff_still_requires_some_acknowledgment(tmp_path):
    root = _init_git_project(tmp_path)
    (root / "src.py").write_text("line1\nline2 changed\nline3\n")
    payload = write_payload(
        "docs/issue-1/reports/implementation.md", RECORD_TRIVIAL_NO_ACKNOWLEDGMENT
    )
    proc = run_gate("record-shape-gate.sh", payload, root)
    assert proc.returncode == 2
    assert "What did not work" in proc.stderr


def test_record_shape_gate_non_trivial_diff_still_requires_full_record(tmp_path):
    root = _init_git_project(tmp_path)
    (root / "src.py").write_text("\n".join("line%d" % i for i in range(50)) + "\n")
    payload = write_payload(
        "docs/issue-1/reports/implementation.md", RECORD_TRIVIAL_NO_BREAKING_NO_HEADING
    )
    proc = run_gate("record-shape-gate.sh", payload, root)
    assert proc.returncode == 2
    assert "breaking" in proc.stderr


# issue-297: live measurement against fixture issue #45 (a docs-only,
# 2-file change) found the trivial-diff exemption (issue-285) still
# refused an honest trivial-diff record -- on two elements #285 never
# exempted: the `code_under_review:` frontmatter key, and a
# `## Rationale for deviations` heading demanded by a deviation-signal
# false positive (the record never diverged from its proposal; it just
# mentioned the word "deviation").

RECORD_TRIVIAL_NO_CODE_UNDER_REVIEW = """---
loop_state: landed
type: docs
verdict: pass
---

Nothing to report for this trivial change.
"""

RECORD_TRIVIAL_DISCUSSES_DEVIATION_WITHOUT_ONE = """---
code_under_review:
  - src.py
loop_state: landed
type: fix
verdict: pass
---

No deviations from the proposal occurred; this record's own subject is
the record-shape-gate's deviation-signal heuristic, which is why the word
"deviation" appears here at all.

Nothing to report for this trivial change.
"""

RECORD_ACTUAL_DEVIATION = """---
code_under_review:
  - src.py
loop_state: landed
type: fix
verdict: pass
---

We diverged from the proposal by dropping the CLI flag it specified.

Nothing to report for this trivial change.
"""


def test_record_shape_gate_trivial_diff_exempts_code_under_review(tmp_path):
    root = _init_git_project(tmp_path)
    (root / "src.py").write_text("line1\nline2 changed\nline3\n")  # 1 line changed
    payload = write_payload(
        "docs/issue-1/reports/implementation.md", RECORD_TRIVIAL_NO_CODE_UNDER_REVIEW
    )
    proc = run_gate("record-shape-gate.sh", payload, root)
    assert proc.returncode == 0, proc.stderr


def test_record_shape_gate_non_trivial_diff_still_requires_code_under_review(tmp_path):
    root = _init_git_project(tmp_path)
    (root / "src.py").write_text("\n".join("line%d" % i for i in range(50)) + "\n")
    payload = write_payload(
        "docs/issue-1/reports/implementation.md", RECORD_TRIVIAL_NO_CODE_UNDER_REVIEW
    )
    proc = run_gate("record-shape-gate.sh", payload, root)
    assert proc.returncode == 2
    assert "code_under_review" in proc.stderr


def test_record_shape_gate_deviation_word_alone_is_not_a_signal(tmp_path):
    root = _init_git_project(tmp_path)
    (root / "src.py").write_text("line1\nline2 changed\nline3\n")
    payload = write_payload(
        "docs/issue-1/reports/implementation.md",
        RECORD_TRIVIAL_DISCUSSES_DEVIATION_WITHOUT_ONE,
    )
    proc = run_gate("record-shape-gate.sh", payload, root)
    assert proc.returncode == 0, proc.stderr


def test_record_shape_gate_actual_deviation_still_requires_rationale_heading(tmp_path):
    root = _init_git_project(tmp_path)
    (root / "src.py").write_text("line1\nline2 changed\nline3\n")
    payload = write_payload(
        "docs/issue-1/reports/implementation.md", RECORD_ACTUAL_DEVIATION
    )
    proc = run_gate("record-shape-gate.sh", payload, root)
    assert proc.returncode == 2
    assert "Rationale for deviations" in proc.stderr


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


def test_no_hook_script_has_heredoc_inside_command_substitution():
    """issue #245: `$(cmd <<TAG ... TAG)` parses fine under bash 5 but
    fails to parse under bash 3.2 (macOS system bash) with "unexpected
    EOF" -- and since every gate is fail-closed, that parse failure
    blocks every tool call in the role session it runs under. Guard the
    live hook/gate scripts (core/hooks/*.sh and core/hooks/lib/*.sh) so
    the pattern cannot recur; core/hooks/tests/ is excluded because it
    holds test-fixture strings that illustrate the idiom in comments and
    quoted literals, not live command substitutions.
    """
    hooks_dir = REPO / "core" / "hooks"
    offenders = []
    for f in sorted(hooks_dir.glob("*.sh")) + sorted((hooks_dir / "lib").glob("*.sh")):
        for lineno, line in enumerate(f.read_text().splitlines(), start=1):
            if line.lstrip().startswith("#"):
                continue
            if HEREDOC_IN_CMD_SUBST_RE.search(line):
                offenders.append(f"{f.relative_to(REPO)}:{lineno}: {line.strip()}")
    assert not offenders, "heredoc inside command substitution (bash 3.2 parse failure):\n" + "\n".join(offenders)
