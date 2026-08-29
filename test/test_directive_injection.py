"""issue-299: core/hooks/directive.sh (the SessionStart hook) used to end
with "Read <session-protocol.md> NOW, before any work" -- the exact
imperative-Read shape on-the-record #2204 measured costing a real tool
round-trip every session. The fix delivers session-protocol.md's content
directly in the hook's own stdout instead, so the protocol reaches the
session with no Read call needed. These tests exercise the rendered
SessionStart output as a subprocess, the same technique
tests/test_promoted_hooks.py and tests/test_silent_failure_repros.py use
for the other core/hooks/*.sh gates.
"""
import subprocess
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
CORE = REPO / "core"
SESSION_PROTOCOL = CORE / "directive" / "session-protocol.md"

# A phrase that lives only in session-protocol.md's body, never in
# directive.sh's own short INVARIANTS index -- proof of delivery, not just
# absence of the old Read pointer.
BODY_ONLY_PHRASE = "Terminal loop_state is per-kind"


def _fake_repo(tmp_path):
    repo = tmp_path / "repo"
    repo.mkdir()
    subprocess.run(["git", "init", "-q"], cwd=str(repo), check=True)
    subprocess.run(
        ["git", "remote", "add", "origin", "https://example.invalid/o/r.git"],
        cwd=str(repo), check=True,
    )
    return repo


def _fake_gh_bin(tmp_path):
    bindir = tmp_path / "bin"
    bindir.mkdir()
    gh = bindir / "gh"
    gh.write_text("#!/bin/sh\nexit 0\n")
    gh.chmod(0o755)
    return bindir


def render_directive(tmp_path, plugin_root_core):
    """Run core/hooks/directive.sh the same way the SessionStart hook would,
    with a fake authenticated gh so the precondition probe passes
    deterministically (matches core/hooks/tests/run-ups-diet-tests.sh)."""
    repo = _fake_repo(tmp_path)
    bindir = _fake_gh_bin(tmp_path)
    env = {
        "PATH": f"{bindir}:/usr/bin:/bin",
        "CLAUDE_PROJECT_DIR": str(repo),
        "TMPDIR": str(tmp_path),
        "CLAUDE_PLUGIN_ROOT_CORE": str(plugin_root_core),
        "CLAUDE_SKILL": "implementation",
    }
    proc = subprocess.run(
        ["bash", str(CORE / "hooks" / "directive.sh")],
        capture_output=True, text=True, env=env, timeout=15,
    )
    return proc


def test_no_read_now_pointer_to_session_protocol(tmp_path):
    proc = render_directive(tmp_path, CORE)
    assert proc.returncode == 0, proc.stderr
    assert "NOW, before any work" not in proc.stdout
    assert "Read " + str(SESSION_PROTOCOL) not in proc.stdout


def test_protocol_content_genuinely_present(tmp_path):
    """The behavior that depends on the full protocol (e.g. knowing the
    per-kind loop_state vocabulary) must still hold -- the content has to
    actually be there, not merely the Read pointer be gone."""
    proc = render_directive(tmp_path, CORE)
    assert proc.returncode == 0, proc.stderr
    assert BODY_ONLY_PHRASE in proc.stdout
    assert BODY_ONLY_PHRASE not in CORE.joinpath("hooks", "directive.sh").read_text()


def test_byte_stable_across_two_renders(tmp_path):
    (tmp_path / "a").mkdir()
    (tmp_path / "b").mkdir()
    a = render_directive(tmp_path / "a", CORE)
    b = render_directive(tmp_path / "b", CORE)
    assert a.stdout == b.stdout


def test_missing_session_protocol_degrades_to_clear_message(tmp_path):
    """Empty state (issue's acceptance criterion): session-protocol.md
    absent or unreadable must not emit a broken/empty system prompt."""
    fake_core = tmp_path / "fake-core"
    (fake_core / "hooks" / "lib").mkdir(parents=True)
    (fake_core / "directive").mkdir(parents=True)
    (fake_core / "hooks" / "directive.sh").write_text(
        (CORE / "hooks" / "directive.sh").read_text()
    )
    (fake_core / "hooks" / "lib" / "gate-lib.sh").write_text(
        (CORE / "hooks" / "lib" / "gate-lib.sh").read_text()
    )
    # session-protocol.md deliberately not created under fake_core/directive/

    repo = _fake_repo(tmp_path)
    bindir = _fake_gh_bin(tmp_path)
    env = {
        "PATH": f"{bindir}:/usr/bin:/bin",
        "CLAUDE_PROJECT_DIR": str(repo),
        "TMPDIR": str(tmp_path),
        "CLAUDE_PLUGIN_ROOT": str(fake_core),
        "CLAUDE_SKILL": "implementation",
    }
    proc = subprocess.run(
        ["bash", str(fake_core / "hooks" / "directive.sh")],
        capture_output=True, text=True, env=env, timeout=15,
    )
    assert proc.returncode == 0, proc.stderr
    assert "is missing or unreadable" in proc.stdout
    assert "NOW, before any work" not in proc.stdout
    # the short INVARIANTS index must still render even without the file
    assert "Interaction protocol for role implementation" in proc.stdout


def test_session_protocol_md_uses_generic_role_placeholder_not_dollar_role(tmp_path):
    """Caching constraint: session-protocol.md carries no per-session
    substitution (role appears only as the inert placeholder <role>, same
    convention as issue-<n>), so directive.sh's inline delivery renders
    byte-identical regardless of CLAUDE_SKILL."""
    text = SESSION_PROTOCOL.read_text()
    assert "${role}" not in text
    assert "<role>" in text


def test_only_directive_sh_uses_the_now_before_any_work_shape(tmp_path):
    """issue-299 audit: no core/hooks/*.sh script injects (in its actual
    emitted output, i.e. outside its own shell comments) the same
    'Read <file> NOW, before any work' eager-imperative shape. directive.sh
    itself mentions the phrase only inside a `#`-commented history note,
    which this check ignores by design -- comments are never emitted to a
    session, only cat/echo/heredoc bodies are."""
    hits = []
    hooks_dir = CORE / "hooks"
    for path in sorted(hooks_dir.glob("*.sh")):
        code_lines = [
            line for line in path.read_text().splitlines()
            if not line.strip().startswith("#")
        ]
        if "NOW, before any work" in "\n".join(code_lines):
            hits.append(str(path.relative_to(REPO)))
    assert hits == []
