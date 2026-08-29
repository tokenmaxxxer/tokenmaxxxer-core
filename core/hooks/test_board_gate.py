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
        env["CLAUDE_SKILL"] = role
    else:
        env.pop("CLAUDE_SKILL", None)
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


# --- issue-336: a `+`-bearing multi-skill slug is not truncated ----------
#
# Since #2572 `--skills` is the sole spawn form: skills.py's
# skill_branch_slug() joins skill names with `+`
# (e.g. "silent-failure-audit+secure-coding-input-validation-injection-
# defense-<hex>"), so every current role/slug can carry one. The
# own_hits regex's trailing character class used to stop at the first
# `+`, truncating the session's own record path to a prefix and making
# the R5 owner check (`tail[0] == role`, unchanged and correct) compare
# a truncated tail against the full role -- denying the session's own
# record as foreign.

MULTISKILL_ROLE = ("silent-failure-audit+secure-coding-input-validation-"
                    "injection-defense-a7be2546")


@pytest.fixture
def multiskill_board(tmp_path):
    """Same shape as `board`, but on a `+`-bearing multi-skill branch."""
    subprocess.run(["git", "init", "-q", str(tmp_path)], check=True)
    subprocess.run(
        ["git", "-C", str(tmp_path), "remote", "add", "origin",
         "git@github.com:tokenmaxxxer/probe.git"],
        check=True,
    )
    subprocess.run(
        ["git", "-C", str(tmp_path), "checkout", "-q", "-b",
         "issue-336/%s" % MULTISKILL_ROLE],
        check=True,
    )
    specs = tmp_path / "docs" / "specs"
    specs.mkdir(parents=True)
    (specs / "approvers.md").write_text("- jw-human\n")
    subprocess.run(["git", "-C", str(tmp_path), "add", "-A"], check=True)
    subprocess.run(["git", "-C", str(tmp_path), "commit", "-q", "-m", "init"],
                    check=True)
    return tmp_path


def test_multiskill_mkdir_own_record_dir_allowed(multiskill_board):
    """The first of the three observed refusals: mkdir -p of the
    session's own record subtree."""
    command = ('mkdir -p "docs/issue-336/reports/%s"' % MULTISKILL_ROLE)
    rc, err = run_gate(multiskill_board, command, role=MULTISKILL_ROLE)
    assert rc == 0, err


def test_multiskill_git_add_own_record_file_allowed(multiskill_board):
    """The second observed refusal: staging a file inside the session's
    own record subtree."""
    record_dir = multiskill_board / "docs" / "issue-336" / "reports" / MULTISKILL_ROLE
    record_dir.mkdir(parents=True)
    (record_dir / "2026-08-27-hunt-x.md").write_text("body\n")
    command = ('git add "docs/issue-336/reports/%s/2026-08-27-hunt-x.md"'
               % MULTISKILL_ROLE)
    rc, err = run_gate(multiskill_board, command, role=MULTISKILL_ROLE)
    assert rc == 0, err


def test_multiskill_git_add_own_record_dir_allowed(multiskill_board):
    """The third observed refusal: staging the whole record subtree."""
    record_dir = multiskill_board / "docs" / "issue-336" / "reports" / MULTISKILL_ROLE
    record_dir.mkdir(parents=True)
    (record_dir / "2026-08-27-hunt-x.md").write_text("body\n")
    command = "git add docs/issue-336/reports/%s/" % MULTISKILL_ROLE
    rc, err = run_gate(multiskill_board, command, role=MULTISKILL_ROLE)
    assert rc == 0, err


def test_multiskill_foreign_record_still_denied(multiskill_board):
    """A genuinely foreign record is still refused with today's message --
    widening the character class must not smuggle a foreign write past
    the unchanged `tail[0] == role` comparison."""
    other_role = "a-different-skill-combo+another-skill-bbbbbbbb"
    record_dir = multiskill_board / "docs" / "issue-336" / "reports" / other_role
    record_dir.mkdir(parents=True)
    (record_dir / "x.md").write_text("body\n")
    command = "git add docs/issue-336/reports/%s/" % other_role
    rc, err = run_gate(multiskill_board, command, role=MULTISKILL_ROLE)
    assert rc == 2
    assert "belongs to another role" in err


def test_multiskill_path_shape_not_in_fixture_set(multiskill_board):
    """issue-336 acceptance bullet 3: the disposition applied to a path
    shape not exercised anywhere else above -- a `+`-bearing slug's
    record .md FILE (not a directory member) written directly via a
    plain redirect."""
    command = ("echo 'loop_state: landed' > docs/issue-336/reports/%s.md"
               % MULTISKILL_ROLE)
    rc, err = run_gate(multiskill_board, command, role=MULTISKILL_ROLE)
    assert rc == 0, err


# --- issue-335: a `for`/`select`/`case` header is not itself a command --
#
# A read-only multi-line script whose only docs/ mentions sit inside a
# `for ... in <word-list>` was refused as a WRITE to that path, misreported
# as a branch-authorization problem: the for-header's own segment had no
# recognized head, fell through to the unproven-write catch-all, and had
# every docs/-shaped item in its word list harvested as a write candidate
# -- even though nothing in that segment executes a program at all, and
# every actual command the loop body runs (find/echo/git log) is
# independently read-only on its own segment.

def test_forloop_wordlist_over_foreign_paths_passes(board):
    """The killed-session repro, recovered verbatim in the issue's
    correcting comment (the issue body's own paraphrase could not
    reproduce it): a multi-line script naming a foreign docs/issue-100/
    path only as an item in a `for` word list, with every actual effect
    -- find, echo, `git log --oneline -- "$f"` -- a read."""
    command = (
        "find docs -maxdepth 1 -type d -name 'issue-*' | wc -l\n"
        "echo ---\n"
        "for f in gates/spawn_on_pr.py docs/specs/record-kind-vocabulary.md "
        "docs/issue-100/reports/coding.md "
        "docs/decisions/2026-08-25-retire-role-axis-staging.md; do\n"
        "  n=$(git log --oneline -- \"$f\" | wc -l)\n"
        "  echo \"$f : $n commits\"\n"
        "done"
    )
    rc, err = run_gate(board, command)
    assert rc == 0, err


def test_forloop_body_literal_write_still_denied(board):
    """Regression guard: exempting the `for`-header segment must not
    exempt the loop BODY. A body statement that writes a literal docs/
    path (not the loop variable) sits in its own segment and is
    classified exactly as before -- still denied."""
    command = ("for x in a b c; do echo bad > docs/issue-198/reports/"
               "verify.md; done")
    rc, err = run_gate(board, command)
    assert rc == 2
    assert "belongs to another role" in err


def test_case_dispatch_mentioning_foreign_issue_passes(board):
    """issue-335 acceptance bullet 3: the same rule applied to a command
    not in READ_ONLY_HEADS and not the `for` case the issue named --
    `case WORD in` where WORD is a literal foreign docs/ path. The switch
    value is data being matched against, not a target being written, the
    same reasoning as a `for` word list."""
    command = "case docs/issue-651/reports/x.md in\n  *) echo matched ;;\nesac"
    rc, err = run_gate(board, command)
    assert rc == 0, err


def test_case_arm_literal_write_still_denied(board):
    """Regression guard for the `case` head: a write inside a case ARM
    (a different segment from the `case ... in` header) is unaffected."""
    command = ("case x in\n  *) echo bad > docs/issue-198/reports/verify.md "
               ";;\nesac")
    rc, err = run_gate(board, command)
    assert rc == 2
    assert "belongs to another role" in err
