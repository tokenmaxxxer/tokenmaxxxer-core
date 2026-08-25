#!/usr/bin/env bash
__fc(){ rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then echo "fail-closed: gate aborted (rc=$rc)" >&2; exit 2; fi; }
trap __fc EXIT
# PreToolUse gate (Bash matching `git commit`) — contract §21, handbook half.
#
# When a commit's STAGED file set introduces or changes an operational
# surface (env var example, config key, dependency manifest, migration, or a
# run/setup/deploy script) AND the same commit does not also touch
# docs/handbooks/<component>.md, refuse the commit.
#
# Conservative component derivation: if ANY handbook file under
# docs/handbooks/ is staged, the obligation is treated as met (the gate
# enforces STRUCTURE — that a handbook was touched alongside operational
# change — never which component, a human-owned judgment).
#
# Promoted to core canon (issue-66). The issue-66 survey found the vendored
# copies had drifted in message prefix beyond role substitution — one
# rulebook's copy denied under the literal prefix "warrant:", unrelated to
# that rulebook's own role, a stale copy-paste rather than intentional
# behavior. This canon copy derives the prefix from CLAUDE_ROLE
# unconditionally, closing that bug as a side effect of promotion.
#
# Kill switch: export HANDBOOK_TRIGGER_GATE_OFF=1
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)}/hooks/lib/gate-lib.sh" || { echo "handbook-trigger-gate.sh: cannot source gate-lib.sh" >&2; exit 2; }
set -uo pipefail

self_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/$(basename "${BASH_SOURCE[0]}")"
role="${CLAUDE_ROLE:-}"
deny() { echo "${role:-handbook-trigger-gate}: refused — $* (gate: $self_path)" >&2; exit 0; }  # issue-282 DEMOTE: advisory, not blocking

gate_kill_switch_active "${HANDBOOK_TRIGGER_GATE_OFF:-}" || exit 0

command -v python3 >/dev/null 2>&1 || deny "handbook-trigger-gate.sh requires python3, which is not on PATH; denying rather than guessing."
command -v git >/dev/null 2>&1 || deny "handbook-trigger-gate.sh requires git, which is not on PATH; denying rather than guessing."

payload="$(cat 2>/dev/null || true)"

_plausible() { [ -n "$1" ] && [ -d "$1" ] && { [ -e "$1/.git" ] || [ -f "$1/docs/specs/role-handoff-contract.md" ]; }; }
root=""
if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && _plausible "$CLAUDE_PROJECT_DIR"; then
  root="$(cd "$CLAUDE_PROJECT_DIR" 2>/dev/null && pwd -P)"
fi
[ -z "$root" ] && root="$(git -C "$(pwd -P)" rev-parse --show-toplevel 2>/dev/null || true)"
[ -z "$root" ] && deny "no project root could be determined; failing closed (§21 handbook-trigger cannot be judged)."

HT_PAYLOAD="$payload" HT_ROOT="$root" HT_ROLE="$role" HT_SELF="$self_path" python3 <<'PY'
import sys as _fc_sys  # fail-closed-on-internal-error
try:
    import json, os, posixpath, re, shlex, subprocess, sys

    role = os.environ.get("HT_ROLE", "").strip() or "handbook-trigger-gate"
    self_path = os.environ.get("HT_SELF", "") or "handbook-trigger-gate.sh"

    def deny(m):
        # issue-282 DEMOTE: advisory only -- detection logic unchanged.
        reason = "%s: %s (gate: %s)" % (role, m, self_path)
        sys.stderr.write(reason + "\n")
        print(json.dumps({
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "additionalContext": reason,
            },
            "systemMessage": reason,
        }))
        sys.exit(0)

    raw = os.environ.get("HT_PAYLOAD", "")
    try:
        ev = json.loads(raw) if raw else {}
    except ValueError:
        deny("the tool-call payload is not valid JSON; failing closed on §21.")
    if not isinstance(ev, dict):
        deny("the tool-call payload is not a JSON object; failing closed on §21.")

    if ev.get("tool_name") != "Bash":
        sys.exit(0)
    ti = ev.get("tool_input")
    if not isinstance(ti, dict):
        deny("tool_input is missing or not a JSON object; the gate cannot judge a commit it cannot parse (§21).")
    cmd = ti.get("command")
    if not isinstance(cmd, str) or not cmd.strip():
        sys.exit(0)
    if not re.search(r'\bgit\b[^\n]*\bcommit\b', cmd):
        sys.exit(0)

    root = posixpath.normpath(os.environ["HT_ROOT"].replace("\\", "/"))

    def git(*args):
        try:
            return subprocess.run(["git", "-C", root, *args],
                                  capture_output=True, text=True, timeout=30)
        except Exception:
            return None

    r = git("diff", "--cached", "--name-only")
    if r is None or r.returncode != 0:
        deny("could not read the staged file set (`git diff --cached`); failing closed on §21.")
    staged = set(ln.strip() for ln in r.stdout.splitlines() if ln.strip())

    # D2 (issue-141): PreToolUse denies the whole Bash call before it runs,
    # so for `git add <paths> && git commit ...` the `git add` never
    # executes and the staged-set read above reflects the PRE-add state.
    # Project forward: for every `git add` segment (split on &&/;/|) that
    # precedes the `git commit` segment, resolve its pathspec with
    # `git add --dry-run --` (no actual staging side effect) and union the
    # result into the judged set. A pathspec that can't be resolved
    # statically (e.g. it depends on shell/variable expansion) gets its
    # own distinctly-worded deny instead of being silently ignored or
    # reusing the genuine-violation message.
    commit_m = re.search(r'\bgit\b[^\n;&|]*\bcommit\b(?!-)', cmd)
    if commit_m:
        segments = re.split(r'&&|;|\|', cmd[:commit_m.start()])
        for seg in segments:
            seg = seg.strip()
            am = re.match(r'^git\s+add\b(.*)$', seg)
            if not am:
                continue
            argstr = am.group(1)
            if re.search(r'\$|`', argstr):
                deny(
                    "this commit is preceded by `git add%s` whose pathspec depends on "
                    "shell/variable expansion, so the staged set it would produce cannot be "
                    "projected statically; the handbook-trigger obligation cannot be judged "
                    "(§21). Stage explicit paths, or run `git add` as a separate step first."
                    % argstr
                )
            try:
                add_toks = shlex.split(argstr)
            except ValueError:
                deny(
                    "this commit is preceded by `git add%s`, whose arguments could not be "
                    "tokenized to project the staged set it would produce; the handbook-trigger "
                    "obligation cannot be judged (§21)." % argstr
                )
            # `--` ends option parsing; every token after it is a pathspec
            # even if it starts with `-` (e.g. a file literally named
            # `-setup.sh`). Dropping such tokens unconditionally would
            # silently exclude them from the projected staged set.
            #
            # F10 (issue-305): -A/--all/-u/--update carry no pathspec of
            # their own but still stage a real (unbounded) set of files --
            # they were previously dropped by the same "starts with -"
            # skip as an ordinary ignored option, silently contributing
            # nothing to the projection. `git add --dry-run` resolves them
            # exactly like any other pathspec (it enumerates the real
            # working-tree diff), so pass them through to the dry-run call
            # instead of discarding them.
            BULK_FLAGS = ("-A", "--all", "-u", "--update")
            pathspecs = []
            bulk_flags = []
            seen_dashdash = False
            for t in add_toks:
                if not seen_dashdash and t == "--":
                    seen_dashdash = True
                    continue
                if not seen_dashdash and t in BULK_FLAGS:
                    bulk_flags.append(t)
                    continue
                if not seen_dashdash and t.startswith("-"):
                    continue
                pathspecs.append(t)
            if not pathspecs and not bulk_flags:
                continue
            dr = git("add", "--dry-run", *bulk_flags, "--", *pathspecs)
            if dr is None:
                deny(
                    "could not run `git add --dry-run` to project the staged set that "
                    "`git add%s` would produce; failing closed on §21." % argstr
                )
            for ln in dr.stdout.splitlines():
                ln = ln.strip()
                m = re.match(r"^add '(.+)'$", ln)
                if m:
                    staged.add(m.group(1))

    if not staged:
        sys.exit(0)

    # issue-147 C3: keyed on the human-readable trigger token (the literal
    # #146's gate-prose-coverage-check.py dict-key extractor picks up as a
    # needle directive.sh must state), not the raw regex source -- a tuple
    # list has no shape any of the checker's three extractors recognize, so
    # this trigger set could drift from the injected prose with nothing
    # catching it (the same silent-drift shape #140 left behind for C2).
    OP_PATTERNS = {
        "package.json": re.compile(r'(^|/)package\.json$'),
        "package-lock.json": re.compile(r'(^|/)package-lock\.json$'),
        "pyproject.toml": re.compile(r'(^|/)pyproject\.toml$'),
        "requirements.txt": re.compile(r'(^|/)requirements[^/]*\.txt$'),
        "go.mod": re.compile(r'(^|/)go\.mod$'),
        "Cargo.toml": re.compile(r'(^|/)Cargo\.toml$'),
        "Gemfile": re.compile(r'(^|/)Gemfile$'),
        "Dockerfile": re.compile(r'(^|/)Dockerfile$'),
        "docker-compose.yml": re.compile(r'(^|/)docker-compose\.ya?ml$'),
        ".env": re.compile(r'\.env(\.[A-Za-z0-9_.-]+)?$'),
        "migrations/": re.compile(r'(^|/)migrations?/'),
        ".github/workflows/": re.compile(r'(^|/)\.github/workflows/'),
        "deploy/setup/run/install script": re.compile(r'(^|/)(deploy|setup|run|install)[^/]*\.sh$'),
    }

    op_hits = []
    for f in staged:
        for kind, rx in OP_PATTERNS.items():
            if rx.search(f):
                op_hits.append((f, kind))
                break

    if not op_hits:
        sys.exit(0)  # no operational surface changed — not this gate's business

    handbook_touched = any(re.match(r'^docs/handbooks/.+', f) for f in staged)
    if handbook_touched:
        sys.exit(0)

    path, kind = op_hits[0]
    deny(
        "this commit changes %s (operational surface: %s) but does not touch any "
        "docs/handbooks/<component>.md. Per contract §21, update the handbook in the same "
        "unit of work." % (path, kind)
    )
except Exception as _fc_e:  # fail-closed-on-internal-error
    _fc_sys.stderr.write("handbook-trigger-gate.sh: fail-closed: internal error: %r (gate: %s)\n" % (_fc_e, os.environ.get("HT_SELF", "handbook-trigger-gate.sh")))
    _fc_sys.exit(2)
PY
_fc_rc=$?  # fail-closed-on-internal-error
if [ "$_fc_rc" -ne 0 ] && [ "$_fc_rc" -ne 2 ]; then
  echo "${role:-handbook-trigger-gate}: refused — fail-closed: internal error (judge exited $_fc_rc) (gate: $self_path)" >&2
  exit 2
fi
exit "$_fc_rc"
