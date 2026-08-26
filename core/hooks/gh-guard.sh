#!/usr/bin/env bash
# PreToolUse: deny-only guard on GitHub-act commands in ROLE sessions.
#
# Under the two-account model (contract v3 s8/s10) the human decisions —
# review Approve, merge, issue authorship, close — belong to the user's
# account, relayed by the orchestrator's conversational session. A role
# session holds the agent account's token and must never perform them,
# whatever that token's permissions happen to be. Defense in depth: the
# agent account is also excluded from approvers.md, and GitHub itself
# rejects self-approval — this gate just refuses the attempt at the
# session layer, with a message that says where the act belongs.
#
# Denied in role sessions (CLAUDE_ROLE set):
#   gh pr review --approve / --request-changes   (verdicts are human acts)
#   gh pr merge / gh pr close / gh pr reopen     (acceptance/refusal)
#   gh issue create / close / reopen / edit      (user-only backlog)
#   git push targeting main/master               (output returns via PR only)
#   gh api calls to reviews/merge endpoints      (the raw-API spelling)
#
# Sessions without a role identity (the user's own, the orchestrator's)
# pass through untouched. Fail closed on non-0/2. Kill switch: CORE_OFF=1.
#
# Presence test (issue #327, per on-the-record #2538): a role session is
# one where TOKENMAXXXER_SPAWNED or CLAUDE_ROLE is set — OR, not just the
# new var alone, so a session that unsets only one of the two spawner-set
# vars cannot flip this guard into the pass-through branch and dodge the
# deny below. core has no SessionStart snapshot (unlike on-the-record's
# session-role-bind), so this OR is the presence test itself, not a
# fallback to one.
trap 'rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then exit 2; fi' EXIT
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)}/hooks/lib/gate-lib.sh" || { echo "gh-guard.sh: cannot source gate-lib.sh" >&2; exit 2; }
set -uo pipefail

gate_kill_switch_active "${CORE_OFF:-}" || { trap - EXIT; exit 0; }

# Drain stdin before any early exit: exiting without reading makes the
# writer see SIGPIPE.
payload="$(cat 2>/dev/null || true)"

[ -n "${TOKENMAXXXER_SPAWNED:-}${CLAUDE_ROLE:-}" ] || { trap - EXIT; exit 0; }

[ -n "$payload" ] || { echo "gh-guard.sh: refused — empty tool-use payload on stdin; cannot evaluate the gh guard." >&2; exit 2; }

# Fast path: only Bash calls mentioning gh/git (or another HTTP client
# capable of reaching the same REST/GraphQL endpoints) are adjudicated.
# This matches the RAW, unparsed JSON text -- a payload that JSON-escapes
# one character of the matched substring as \uXXXX (e.g. "gh" for
# "gh") decodes to a byte-identical command string but never contains the
# literal substring this fast path scans for, so it must never be trusted
# to skip adjudication on its own (issue-303, F15). Any payload carrying a
# JSON \u escape therefore falls through to the python judge unconditionally,
# whether or not it also happens to match the plain-text patterns below.
case "$payload" in
  *'\u'*) ;;
  *'"Bash"'*) ;;
  *) trap - EXIT; exit 0 ;;
esac
case "$payload" in
  *'\u'*) ;;
  *gh*|*git*|*curl*|*wget*|*http://*|*https://*) ;;
  *) trap - EXIT; exit 0 ;;
esac

command -v python3 >/dev/null 2>&1 || gate_deny "gh-guard" "python3 not found; cannot evaluate gate"

IFS='' read -r -d '' CORE_GH_GUARD <<'PY' || true
import json, os, re, sys

import importlib.util
_spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
gate_lib = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(gate_lib)

def deny(msg):
    sys.stderr.write("gh-guard: %s\n" % msg)
    sys.exit(2)

def allow():
    sys.exit(0)

try:
    event = json.loads(os.environ.get("CORE_PAYLOAD", ""))
except ValueError:
    deny("unreadable PreToolUse payload; refusing rather than guessing")
if not isinstance(event, dict) or (event.get("tool_name") or "") != "Bash":
    allow()
ti = event.get("tool_input") or {}
cmd = ti.get("command") if isinstance(ti, dict) else None
if not isinstance(cmd, str):
    deny("Bash payload carries no command string")

role = os.environ["CLAUDE_ROLE"].strip()

RULES = [
    (r"\bgh\s+pr\s+review\b.*(--approve|-a\b|--request-changes)",
     "a PR review verdict is the human's act, relayed by the orchestrator "
     "with the user's account — never a role session's",
     True),
    (r"\bgh\s+pr\s+(merge|close|reopen)\b",
     "merging or closing a PR is the human's acceptance/refusal — a role "
     "session only opens PRs and pushes to its own issue branch",
     True),
    (r"\bgh\s+issue\s+(create|close|reopen|edit|transfer|delete)\b",
     "issues are the user's requirement backlog, user-authored only "
     "(contract v3 s9) — no role touches them",
     True),
    (r"\bgh\s+api\b.*(pulls?/\d+/(reviews|merge)|/merge\b)",
     "the raw-API spelling of a review/merge is still a review/merge",
     False),
    (r"\bgh\s+pr\s+comment\b.*\bAPPROVE\b",
     "an APPROVE-shaped comment is the single-account approval signal — "
     "posting it from a role session is a forged approval",
     False),
    (r"\bgh\s+api\b.*(issues|pulls?)/\d+/comments.*\bAPPROVE\b",
     "the raw-API spelling of an APPROVE comment is still a forged "
     "approval",
     False),
    (r"\bgit\s+push\b[^\n;|&]*\s(origin\s+)?(main|master)\b",
     "nothing reaches main except a PR the human merges (contract v3 s10) "
     "— push your issue-<n>/<role> branch instead",
     False),
    # Endpoint+verb rules below match the REST/GraphQL surface itself, not
    # the `gh` token — the same act is still the act whether it is spelled
    # `gh api ...`, `curl -X ... ...`, or `wget --method=... ...` (issue #20).
    (r"(?=.*\bpulls?/\d+/(reviews|merge)\b)"
     r"(?=.*(-X\s*(POST|PUT|PATCH|DELETE)\b|--method[= ]|-f\s))",
     "the raw-API spelling of a review/merge is still a review/merge, "
     "whatever HTTP client reaches the endpoint",
     False),
    (r"(?=.*\bpulls?/\d+(?!/))"
     r"(?=.*(state\s*=\s*(closed|open)|-f\s+state=))",
     "the raw-API spelling of a PR close/reopen (a state= write on the "
     "bare pulls/N endpoint) is still a close/reopen",
     False),
    (r"(?=.*\bissues?/\d+(?!/))"
     r"(?=.*(-X\s*(POST|PUT|PATCH|DELETE)\b|--method[= ]|-f\s+(state|title|body)=))",
     "the raw-API spelling of an issue edit/close/reopen is still "
     "user-only backlog work — no role touches issues, whatever the client",
     False),
    (r"(?=.*\bgraphql\b)"
     r"(?=.*\b(mergePullRequest|addPullRequestReview|closePullRequest|"
     r"reopenPullRequest|closeIssue|reopenIssue|updateIssue|deleteIssue)\b)",
     "the GraphQL spelling of a PR/issue human-act mutation is still that "
     "human act, whatever the transport",
     False),
]

def _deny_for(why):
    deny("refused for role session '%s': %s. (two-account model, "
         "contract v3 s8)" % (role, why))

dq = gate_lib.gate_dequote(cmd)
for pat, why, dequote in RULES:
    if re.search(pat, dq if dequote else cmd):
        _deny_for(why)
    # issue-98: `bash -c`/`sh -c`/`eval`/`python3 -c`-style wrappers put
    # the denied text inside a quoted argument that is EXECUTED, not
    # inert data -- gate_dequote blanks it same as a real grep pattern
    # would be blanked, so the check above alone lets the wrapped verb
    # through. Only reached for the three dequote=True rules, and only
    # when the raw (unquoted-aware) command also carries the pattern, so
    # a quoted-only mention with no wrapper head (e.g. a plain grep) is
    # still unaffected.
    if dequote and re.search(pat, cmd):
        for span in gate_lib.GATE_QUOTE_SPAN.finditer(cmd):
            if re.search(pat, span.group()) and \
               gate_lib.gate_wrapper_head_before(cmd, span.start()):
                _deny_for(why)

allow()
PY

CORE_PAYLOAD="$payload" python3 -c "$CORE_GH_GUARD"
rc=$?
trap - EXIT
if [ "$rc" -ne 0 ] && [ "$rc" -ne 2 ]; then
  echo "gh-guard.sh: refused — fail-closed: internal error (gate judge exited $rc)" >&2
  exit 2
fi
exit "$rc"
