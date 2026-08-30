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
import re
import subprocess
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
CORE = REPO / "core"
SESSION_PROTOCOL = CORE / "directive" / "session-protocol.md"
BUILD_NOW_SESSION_PROTOCOL = CORE / "directive" / "session-protocol-build-now.md"

# A phrase that lives only in session-protocol.md's body, never in
# directive.sh's own short INVARIANTS index -- proof of delivery, not just
# absence of the old Read pointer.
BODY_ONLY_PHRASE = "Terminal loop_state is per-kind"

# issue-384 round 3: a phrase that lives only in the build-now variant's
# body, never in the two-phase file or either INVARIANTS index -- proof
# CORE_BUILD_NOW=1 actually swaps in the build-now section file, not just
# the short heredoc.
BUILD_NOW_BODY_ONLY_PHRASE = "This session is running build-now"


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


def render_directive(tmp_path, plugin_root_core, build_now=False):
    """Run core/hooks/directive.sh the same way the SessionStart hook would,
    with a fake authenticated gh so the precondition probe passes
    deterministically (matches core/hooks/tests/run-ups-diet-tests.sh).
    build_now=True renders the CORE_BUILD_NOW=1 path (issue-384)."""
    repo = _fake_repo(tmp_path)
    bindir = _fake_gh_bin(tmp_path)
    env = {
        "PATH": f"{bindir}:/usr/bin:/bin",
        "CLAUDE_PROJECT_DIR": str(repo),
        "TMPDIR": str(tmp_path),
        "CLAUDE_PLUGIN_ROOT_CORE": str(plugin_root_core),
        "CLAUDE_SKILL": "implementation",
    }
    if build_now:
        env["CORE_BUILD_NOW"] = "1"
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


def test_build_now_protocol_content_genuinely_present(tmp_path):
    """issue-384 round 3: independent verification (#397) demonstrated live
    that no test in the suite exercised directive.sh's CORE_BUILD_NOW=1
    path -- editing the build-now injected text left the full test suite
    output byte-identical. This is the build-now counterpart of
    test_protocol_content_genuinely_present above: the build-now section
    file's actual body must reach stdout, not just its own short
    INVARIANTS index."""
    proc = render_directive(tmp_path, CORE, build_now=True)
    assert proc.returncode == 0, proc.stderr
    assert BUILD_NOW_BODY_ONLY_PHRASE in proc.stdout
    assert BUILD_NOW_BODY_ONLY_PHRASE not in CORE.joinpath("hooks", "directive.sh").read_text()
    # a bullet shared verbatim between both variants' bodies (issue-384's
    # heredoc dedup) must also be present -- proves the shared-bullet
    # variables render, not just the branch-specific text.
    assert BODY_ONLY_PHRASE in proc.stdout
    assert "Interaction protocol for skill implementation" in proc.stdout
    assert "build-now (single-phase)" in proc.stdout


def test_build_now_byte_stable_across_two_renders(tmp_path):
    """Same caching-stability guarantee as test_byte_stable_across_two_renders,
    for the CORE_BUILD_NOW=1 path."""
    (tmp_path / "a").mkdir()
    (tmp_path / "b").mkdir()
    a = render_directive(tmp_path / "a", CORE, build_now=True)
    b = render_directive(tmp_path / "b", CORE, build_now=True)
    assert a.stdout == b.stdout


def test_shared_bullets_between_protocol_variants_stay_in_sync():
    """issue-384 round 3: the two-phase and build-now section files share a
    block of bullets (layout, commit staging, headless/single-shot, board
    state, record fields, terminal loop_state, operational-surface,
    docs/specs regeneration) that are meant to be identical apart from the
    role->skill vocabulary rename in progress elsewhere in this repo
    (see docs/issue-349's record on why that rename is deliberately not
    yet applied to session-protocol.md itself). This round's own leak --
    session-protocol-build-now.md:54 still saying "roles'" -- survived
    both prior review rounds because their grep used \\brole\\b, which
    cannot match the plural. Re-deriving the build-now text from the
    two-phase text via the same substitution this repo's rename already
    uses (whole-word role/roles -> skill/skills, boundary-safe including
    possessives) and diffing against the real file catches that whole
    class of drift structurally, not by pinning today's bytes."""

    def role_to_skill(text):
        text = text.replace("<role>", "<skill>")
        text = re.sub(r"\broles\b", "skills", text)
        text = re.sub(r"\brole\b", "skill", text)
        text = re.sub(r"\bRoles\b", "Skills", text)
        text = re.sub(r"\bRole\b", "Skill", text)
        return text

    def between(text, start, end):
        i = text.index(start)
        j = text.index(end, i)
        return text[i:j]

    two_phase = SESSION_PROTOCOL.read_text()
    build_now = BUILD_NOW_SESSION_PROTOCOL.read_text()

    # Chunk 1: "Requirements enter..." / "YOUR issue is assigned..." bullets
    # -- zero role/skill vocabulary in either file, must be byte-identical.
    req_two_phase = between(
        two_phase, "- Requirements enter as GitHub ISSUES", "- ALL of your output"
    )
    req_build_now = between(
        build_now, "- Requirements enter as GitHub ISSUES", "- ALL of your output"
    )
    assert role_to_skill(req_two_phase) == req_build_now

    # Chunk 2: the long shared middle -- layout through docs/specs
    # regeneration -- between the phase-mechanics bullets and each file's
    # own PR-trailer bullet.
    middle_two_phase = between(
        two_phase, "- Output layout, enforced:", "- PR trailer phase split:"
    )
    middle_build_now = between(
        build_now, "- Output layout, enforced:", "- This build-now PR is the delivery PR:"
    )
    assert role_to_skill(middle_two_phase) == middle_build_now

    # Chunk 3: the trailing Verification bullet -- identical in both today.
    verify_two_phase = two_phase[two_phase.index("- Verification is verify-at-landing"):]
    verify_build_now = build_now[build_now.index("- Verification is verify-at-landing"):]
    assert role_to_skill(verify_two_phase) == verify_build_now


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
