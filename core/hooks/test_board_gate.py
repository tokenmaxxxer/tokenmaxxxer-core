"""board-gate.sh: mention-only text must not be misread as a board write.

issue-198: board-gate.sh split a Bash command's text on every newline,
including lines living inside a heredoc BODY. A heredoc body is data
delivered on stdin, not a command -- but a body line with no recognizable
head word fell through to "unproven write candidate", so a heredoc that
only MENTIONS a docs/issue-<n> path (grep/echo output review, a comment)
was denied as if it wrote there. Real writes -- to a redirect target, or
via a heredoc whose `<<` line itself redirects to a docs/ path -- must
keep being denied on the board's own rules (layout, branch, ownership).

Fixtures use pytest's tmp_path (a fresh directory per test) so no docs/
path literal ever appears in a Bash command this test issues -- the repo's
own board-gate would otherwise flag this test file's fixture setup as a
mention of a board path.
"""
import ast
import json
import os
import re
import subprocess

import pytest

GATE = os.path.join(os.path.dirname(__file__), "board-gate.sh")
PLUGIN_ROOT = os.path.dirname(os.path.dirname(__file__))


@pytest.fixture
def board(tmp_path):
    """A minimal board repo: git init, origin remote, approvers.md."""
    subprocess.run(["git", "init", "-q", str(tmp_path)], check=True)
    subprocess.run(
        ["git", "-C", str(tmp_path), "remote", "add", "origin",
         "git@github.com:tokenmaxxxer/probe.git"],
        check=True,
    )
    subprocess.run(
        ["git", "-C", str(tmp_path), "checkout", "-q", "-b", "issue-198/implementation"],
        check=True,
    )
    specs = tmp_path / "docs" / "specs"
    specs.mkdir(parents=True)
    (specs / "approvers.md").write_text("- jw-human\n")
    return tmp_path


def run_gate(board, command, role="implementation"):
    payload = json.dumps({
        "tool_name": "Bash",
        "tool_input": {"command": command},
        "cwd": str(board),
    })
    env = dict(os.environ)
    env["CLAUDE_PROJECT_DIR"] = str(board)
    env["CLAUDE_PLUGIN_ROOT"] = PLUGIN_ROOT
    if role:
        env["CLAUDE_ROLE"] = role
    else:
        env.pop("CLAUDE_ROLE", None)
    proc = subprocess.run(
        ["/bin/bash", GATE], input=payload, capture_output=True, text=True, env=env,
    )
    return proc.returncode, proc.stderr


def board_path(board, tail):
    return "docs/issue-198/" + tail


# --- green: mention-only text passes -----------------------------------

def test_grep_mentioning_board_path_passes(board):
    target = board_path(board, "reports/implementation.md")
    rc, err = run_gate(board, "grep %r -r src/" % target)
    assert rc == 0, err


def test_echo_mentioning_board_path_passes(board):
    target = board_path(board, "proposals/2026-08-10-x.md")
    rc, err = run_gate(board, "echo 'see %s for context'" % target)
    assert rc == 0, err


def test_heredoc_body_mentioning_board_path_passes(board):
    """The red-fixture case: a heredoc BODY line that only mentions a
    docs/ path used to be misread as its own failing write segment."""
    target = board_path(board, "reports/implementation.md")
    command = "cat <<'EOF'\nsee %s in review notes\nEOF" % target
    rc, err = run_gate(board, command)
    assert rc == 0, err


def test_heredoc_body_mentioning_foreign_issue_passes(board):
    command = "cat <<'EOF'\nrefs docs/issue-651/proposals/x.md too\nEOF"
    rc, err = run_gate(board, command)
    assert rc == 0, err


# --- red: real writes are still denied ----------------------------------

def test_heredoc_redirect_to_foreign_issue_dir_denied(board):
    """The `<<` line's own redirect target is a real write and must still
    be denied -- masking the body must not blind the redirect scan."""
    command = "cat <<'EOF' > docs/issue-999/reports/x.md\nbody mentions docs/issue-198 too\nEOF"
    rc, err = run_gate(board, command)
    assert rc == 2
    assert "issue-999" in err


def test_heredoc_redirect_to_foreign_role_report_denied(board):
    command = "cat <<'EOF' > docs/issue-198/reports/verify.md\nbody\nEOF"
    rc, err = run_gate(board, command)
    assert rc == 2
    assert "belongs to another role" in err


def test_plain_redirect_write_outside_write_set_still_denied(board):
    rc, err = run_gate(board, "echo hi > docs/issue-198/notes.md")
    assert rc == 2
    assert "outside the six buckets" in err


def test_own_record_write_via_heredoc_allowed(board):
    """Positive control: a real write to the role's own record, delivered
    through a heredoc redirect, is exactly the case the fix must not
    collaterally deny."""
    command = "cat <<'EOF' > docs/issue-198/reports/implementation.md\nloop_state: landed\nEOF"
    rc, err = run_gate(board, command)
    assert rc == 0, err


# --- R5 (issue-2241 stage 3): author:-keyed ownership --------------------
#
# Ownership now keys off the record's own `author:` frontmatter field
# (stage 1) instead of matching the writing session's role against the
# record's filename -- a foreign-NAMED record still belongs to whoever
# its `author:` line names, and a foreign-AUTHORED record still accepts
# a provable append (never an edit of the existing lines).


def _write_record(board, tail, author=None, body="body\n"):
    path = board / "docs" / "issue-198" / "reports" / tail
    path.parent.mkdir(parents=True, exist_ok=True)
    if author is None:
        path.write_text(body)
    else:
        path.write_text("---\nauthor: %s\n---\n%s" % (author, body))
    return path


def test_author_bearing_record_accepts_append_from_its_own_author(board):
    """A foreign-NAMED record (verify.md, not implementation.md) whose
    `author:` matches the writing session's own identity is still that
    session's own record now -- the filename no longer decides it."""
    _write_record(board, "verify.md", author="implementation")
    command = "cat <<'EOF' >> docs/issue-198/reports/verify.md\nmore\nEOF"
    rc, err = run_gate(board, command)
    assert rc == 0, err


def test_author_bearing_record_refuses_edit_from_a_different_author(board):
    """A truncating overwrite of a foreign-authored record is not a
    provable append and is refused."""
    _write_record(board, "verify.md", author="architecture")
    rc, err = run_gate(board, "echo hi > docs/issue-198/reports/verify.md")
    assert rc == 2
    assert "authored by 'architecture'" in err


def test_author_bearing_record_allows_append_from_a_different_author(board):
    """Not read-only-foreign: a session may still add new content to a
    record it doesn't own the header of, provided it does not alter the
    existing author's lines -- a provable `>>` append."""
    _write_record(board, "verify.md", author="architecture")
    command = "cat <<'EOF' >> docs/issue-198/reports/verify.md\nmore\nEOF"
    rc, err = run_gate(board, command)
    assert rc == 0, err


def test_author_less_legacy_record_still_enforces_role_filename_rule(board):
    """A record predating stage 1 (on disk, but with no `author:` field
    at all) falls back to the original role-filename rule, unchanged."""
    _write_record(board, "verify.md", author=None, body="no frontmatter here\n")
    rc, err = run_gate(board, "echo hi >> docs/issue-198/reports/verify.md")
    assert rc == 2
    assert "belongs to another role" in err


def test_extra_subtree_keys_match_current_role_names():
    """issue-2241 stage 3 (survey finding 2): EXTRA_SUBTREE's keys must
    be real spawn.py role names, not the stale "feasibility"/"ops"
    orphans -- grep the gate's own source for the dict literal."""
    src = open(GATE, encoding="utf-8").read()
    m = re.search(r"EXTRA_SUBTREE = (\{[^}]*\})", src)
    assert m, "EXTRA_SUBTREE literal not found in board-gate.sh"
    table = ast.literal_eval(m.group(1))
    assert table == {"technical-feasibility": "spikes",
                      "release-engineering": "postmortems"}
