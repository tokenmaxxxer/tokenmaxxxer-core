"""Live-fire subprocess tests for ordering-gate.sh (issue-248 postmortem of
#247): invoke the hook exactly as the Claude Code harness does -- `bash
core/hooks/ordering-gate.sh` with real PreToolUse JSON on stdin -- for both
the Bash and Write tools. #247's suites called gate internals/functions
directly and never exercised the script as a subprocess end-to-end, which is
why the line-101 `list`/`str` crash (`AttributeError: 'list' object has no
attribute 'splitlines'` on every Bash tool_input) shipped past 34 green
tests. These tests close that gap: a crash on this invocation path fails the
test, not just a silent CI green.
"""
import json
import subprocess
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent


def _init_project(tmp_path):
    (tmp_path / ".git").mkdir()
    return tmp_path


def run_hook(payload, cwd):
    return subprocess.run(
        ["bash", str(REPO / "core/hooks/ordering-gate.sh")],
        input=json.dumps(payload),
        capture_output=True,
        text=True,
        cwd=str(cwd),
        env={"CLAUDE_PROJECT_DIR": str(cwd), "PATH": "/usr/bin:/bin:/usr/local/bin"},
        timeout=15,
    )


def bash_payload(command):
    return {
        "hook_event_name": "PreToolUse",
        "tool_name": "Bash",
        "tool_input": {"command": command},
    }


def write_payload(file_path, content):
    return {
        "hook_event_name": "PreToolUse",
        "tool_name": "Write",
        "tool_input": {"file_path": file_path, "content": content},
    }


def test_livefire_bash_non_matching_command_exits_0_silently(tmp_path):
    root = _init_project(tmp_path)
    proc = run_hook(bash_payload("echo hello"), root)
    assert proc.returncode == 0, (proc.stdout, proc.stderr)
    assert proc.stderr == ""


def test_livefire_bash_matching_out_of_order_write_refuses(tmp_path):
    root = _init_project(tmp_path)
    (root / "docs" / "issue-1" / "proposals").mkdir(parents=True)
    proc = run_hook(
        bash_payload("cat > docs/issue-1/proposals/content-design-thing.md"),
        root,
    )
    assert proc.returncode == 2, (proc.stdout, proc.stderr)
    assert "refused" in proc.stderr


def test_livefire_write_non_matching_file_exits_0_silently(tmp_path):
    root = _init_project(tmp_path)
    proc = run_hook(write_payload("core/hooks/unrelated.sh", "#!/usr/bin/env bash\n"), root)
    assert proc.returncode == 0, (proc.stdout, proc.stderr)
    assert proc.stderr == ""


def test_livefire_write_matching_out_of_order_write_refuses(tmp_path):
    root = _init_project(tmp_path)
    (root / "docs" / "issue-1" / "proposals").mkdir(parents=True)
    proc = run_hook(
        write_payload("docs/issue-1/proposals/architecture-thing.md", "content"),
        root,
    )
    assert proc.returncode == 2, (proc.stdout, proc.stderr)
    assert "refused" in proc.stderr
