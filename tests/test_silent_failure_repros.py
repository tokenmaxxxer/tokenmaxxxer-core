"""Runnable repros for issue-163 defect-verification phase-2 findings.

Each test reproduces exactly one finding recorded in
docs/issue-163/reports/defect-verification.md. A test failing means the
underlying silent-failure bypass it captures has been fixed (good) or the
repro itself has bit-rotted against a changed hook (needs re-derivation).
"""
import json
import os
import re
import subprocess
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent


def run_hook(script, payload, env=None, cwd=None):
    full_env = dict(os.environ)
    # warrant/hooks/*.sh source core/hooks/lib/gate-lib.sh via
    # ${CLAUDE_PLUGIN_ROOT_CORE:-<script-relative fallback>}. The fallback
    # assumes gate-lib.sh sits next to the sourcing script (true for
    # core/hooks/*.sh, false for warrant/hooks/*.sh — its actual home is
    # core/hooks/lib/). The real harness always sets CLAUDE_PLUGIN_ROOT_CORE,
    # so a bare checkout without it fails closed (denies everything) instead
    # of exercising the hook at all. Set it here to match production.
    full_env.setdefault("CLAUDE_PLUGIN_ROOT_CORE", str(REPO / "core"))
    full_env.update(env or {})
    proc = subprocess.run(
        ["bash", str(REPO / script)],
        input=json.dumps(payload),
        capture_output=True,
        text=True,
        cwd=str(cwd or REPO),
        env=full_env,
        timeout=15,
    )
    return proc


def has_deny(proc):
    if proc.returncode == 2:
        return True
    try:
        out = json.loads(proc.stdout)
        return out.get("hookSpecificOutput", {}).get("permissionDecision") == "deny"
    except (ValueError, KeyError):
        return False


def has_allow(proc):
    try:
        out = json.loads(proc.stdout)
        return out.get("hookSpecificOutput", {}).get("permissionDecision") == "allow"
    except (ValueError, KeyError):
        return False


def test_A1_observe_sh_malformed_json_silently_skips_enforcement(tmp_path):
    """freelunch/hooks/observe.sh: a sync-dispatch call that WOULD be denied
    under FREELUNCH_ENFORCE=1 is silently allowed instead, purely because
    the JSON payload is malformed and the python parser exits before the
    enforcement check ever runs."""
    log = tmp_path / "observe.jsonl"
    env = {"FREELUNCH_ENFORCE": "1", "FREELUNCH_OBSERVE_LOG": str(log),
           "CLAUDE_CODE_ENTRYPOINT": "cli"}

    control = run_hook(
        "freelunch/hooks/observe.sh",
        json.loads('{"tool_name":"Agent","tool_input":{"run_in_background":false,"model":"haiku"},"session_id":"x"}'),
        env=env,
    )
    assert has_deny(control), "control: a real sync-dispatch violation must be denied"

    proc = subprocess.run(
        ["bash", str(REPO / "freelunch/hooks/observe.sh")],
        input="{not valid json",
        capture_output=True, text=True, cwd=str(REPO),
        env={**os.environ, **env}, timeout=15,
    )
    assert proc.stdout.strip() == "", "malformed payload must not silently produce an allow with no trace"
    assert not has_deny(proc), "demonstrates the bypass: malformed JSON produces no deny at all"


def test_A2_hunt_guard_matches_actual_namespaced_agent_type(tmp_path):
    """warrant/hooks/hunt-guard.sh must match the real, plugin-namespaced
    dispatch name "warrant:warrant-hunter" (see this session's own agent
    registry) as well as the bare "warrant-hunter", so the single-flight
    lock and the WARRANT_HUNT_MAX cap engage for a real dispatch."""
    repo = tmp_path / "repo"
    repo.mkdir()
    subprocess.run(["git", "init", "-q"], cwd=str(repo), check=True)
    env = {"CLAUDE_PROJECT_DIR": str(repo), "WARRANT_HUNT_MAX": "0"}

    control = run_hook(
        "warrant/hooks/hunt-guard.sh",
        {"tool_name": "Agent", "tool_input": {"subagent_type": "warrant-hunter"}},
        env=env,
    )
    assert control.returncode == 2, "control: unqualified name is correctly capped at 0"

    fixed = run_hook(
        "warrant/hooks/hunt-guard.sh",
        {"tool_name": "Agent", "tool_input": {"subagent_type": "warrant:warrant-hunter"}},
        env=env,
    )
    assert fixed.returncode == 2, "fix: the real qualified name is now capped too"


def test_A4_scope_gate_no_longer_auto_approves_arbitrary_bash(tmp_path):
    """warrant/hooks/scope-gate.sh must not auto-approve (permissionDecision:
    allow) a Bash command just because it misses the withhold regex list.
    Variable-indirected commands and commands unrelated to the frozen write
    set must both decline to vouch and defer to the normal permission
    prompt, not be silently auto-approved."""
    repo = tmp_path / "repo"
    (repo / "docs" / "proposals").mkdir(parents=True)
    subprocess.run(["git", "init", "-q"], cwd=str(repo), check=True)
    (repo / "docs" / "proposals" / "2026-08-08-x.md").write_text(
        "---\nstatus: approved\nfiles:\n  - src/only.py\n---\nbody\n"
    )
    env = {"CLAUDE_PROJECT_DIR": str(repo)}

    plain_rm = run_hook("warrant/hooks/scope-gate.sh",
                         {"tool_name": "Bash", "tool_input": {"command": "rm -rf /tmp/x"}}, env=env)
    assert not has_allow(plain_rm), "control: a literal rm -rf declines to vouch (no auto-allow)"

    indirected_rm = run_hook(
        "warrant/hooks/scope-gate.sh",
        {"tool_name": "Bash", "tool_input": {"command": "F=-rf; rm $F /tmp/x"}},
        env=env,
    )
    assert not has_allow(indirected_rm), "fix: variable-indirected rm -rf is no longer auto-approved"

    unrelated = run_hook(
        "warrant/hooks/scope-gate.sh",
        {"tool_name": "Bash", "tool_input": {"command": "curl -s http://example.com/x -o /tmp/leak.txt"}},
        env=env,
    )
    assert not has_allow(unrelated), "fix: a command unrelated to the write set is no longer auto-approved"

    readonly = run_hook(
        "warrant/hooks/scope-gate.sh",
        {"tool_name": "Bash", "tool_input": {"command": "git status"}},
        env=env,
    )
    assert has_allow(readonly), "control: a provably read-only command is still vouched for"


def test_A5_trailer_gate_quote_split_commit_is_detected(tmp_path):
    """core/hooks/trailer-gate.sh must detect `git commit` even when the
    literal word "commit" is split by an empty-string quote pair
    (`commi""t`), since that produces the exact same shell command as
    `git commit`. The §13 trailer requirement must apply to it the same as
    an unsplit commit for staged docs/issue-<n>/** work."""
    scratch = REPO / "docs/issue-163/reports/defect-verification/._a5_repro_scratch.md"
    scratch.write_text("scratch\n")
    subprocess.run(["git", "add", str(scratch)], cwd=str(REPO), check=True)
    try:
        env = {"CLAUDE_ROLE": "defect-verification", "CLAUDE_PROJECT_DIR": str(REPO)}

        control = run_hook("core/hooks/trailer-gate.sh",
                            {"tool_name": "Bash", "tool_input": {"command": "git commit -m x"}}, env=env)
        assert control.returncode == 2, "control: an untrailered commit of staged issue-163 work is denied"

        fixed = run_hook(
            "core/hooks/trailer-gate.sh",
            {"tool_name": "Bash", "tool_input": {"command": 'git commi""t -m x'}},
            env=env,
        )
        assert fixed.returncode == 2, "fix: quote-split commit is now detected and denied without a trailer"

        single_char_split = run_hook(
            "core/hooks/trailer-gate.sh",
            {"tool_name": "Bash", "tool_input": {"command": "git c'o'm'm'i't -m x"}},
            env=env,
        )
        assert single_char_split.returncode == 2, (
            "fix: single-char quote-split commit (not just an empty pair) is also detected"
        )
    finally:
        subprocess.run(["git", "reset", "HEAD", str(scratch)], cwd=str(REPO), check=True)
        scratch.unlink()


def test_A7_gh_guard_renamed_binary_bypass_still_holds():
    """core/hooks/gh-guard.sh's own test suite documents (gap-c-renamed-bin,
    gap-c-file-indirect) that a renamed `gh` binary or an indirect wrapper
    script bypasses the guard by design of its string-matching approach.
    This is a self-admitted, tracked gap (not a newly silent one) — this
    test only confirms it has not drifted since it was last documented."""
    proc = subprocess.run(
        ["bash", str(REPO / "core/hooks/tests/run-gh-guard-tests.sh")],
        capture_output=True, text=True, cwd=str(REPO), timeout=60,
    )
    assert proc.returncode == 0, "gh-guard test suite should pass (including its accepted gap-c-* cases)"
    assert "gap-c-renamed-bin" in proc.stdout and re.search(r"gap-c-renamed-bin\s+allow", proc.stdout)
    assert "gap-c-file-indirect" in proc.stdout and re.search(r"gap-c-file-indirect\s+allow", proc.stdout)


FLEET_REPO_COUNT = 43


def test_fleet_table_lists_all_43_repos():
    record = (REPO / "docs/issue-163/reports/defect-verification.md").read_text()
    rows = re.findall(r"^\|\s*\d+\s*\|", record, re.M)
    assert len(rows) == FLEET_REPO_COUNT, (
        f"expected {FLEET_REPO_COUNT} fleet rows (zero findings is a row, not an omission), "
        f"found {len(rows)}"
    )
