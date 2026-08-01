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
# Sessions without CLAUDE_ROLE (the user's own, the orchestrator's) pass
# through untouched. Fail closed on non-0/2. Kill switch: CORE_OFF=1.
trap 'rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then exit 2; fi' EXIT
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)}/hooks/lib/gate-lib.sh"
set -uo pipefail

gate_kill_switch_active "${CORE_OFF:-}" || { trap - EXIT; exit 0; }

# Drain stdin before any early exit: exiting without reading makes the
# writer see SIGPIPE.
payload="$(cat 2>/dev/null || true)"

[ -n "${CLAUDE_ROLE:-}" ] || { trap - EXIT; exit 0; }

# Fast path: only Bash calls mentioning gh/git are adjudicated.
case "$payload" in
  *'"Bash"'*) ;;
  *) trap - EXIT; exit 0 ;;
esac
case "$payload" in
  *gh*|*git*) ;;
  *) trap - EXIT; exit 0 ;;
esac

command -v python3 >/dev/null 2>&1 || exit 2

IFS='' read -r -d '' CORE_GH_GUARD <<'PY' || true
import json, os, re, sys

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
     "with the user's account — never a role session's"),
    (r"\bgh\s+pr\s+(merge|close|reopen)\b",
     "merging or closing a PR is the human's acceptance/refusal — a role "
     "session only opens PRs and pushes to its own issue branch"),
    (r"\bgh\s+issue\s+(create|close|reopen|edit|transfer|delete)\b",
     "issues are the user's requirement backlog, user-authored only "
     "(contract v3 s9) — no role touches them"),
    (r"\bgh\s+api\b.*(pulls?/\d+/(reviews|merge)|/merge\b)",
     "the raw-API spelling of a review/merge is still a review/merge"),
    (r"\bgh\s+pr\s+comment\b.*\bAPPROVE\b",
     "an APPROVE-shaped comment is the single-account approval signal — "
     "posting it from a role session is a forged approval"),
    (r"\bgh\s+api\b.*(issues|pulls?)/\d+/comments.*\bAPPROVE\b",
     "the raw-API spelling of an APPROVE comment is still a forged "
     "approval"),
    (r"\bgit\s+push\b[^\n;|&]*\s(origin\s+)?(main|master)\b",
     "nothing reaches main except a PR the human merges (contract v3 s10) "
     "— push your issue-<n>/<role> branch instead"),
]

for pat, why in RULES:
    if re.search(pat, cmd):
        deny("refused for role session '%s': %s. (two-account model, "
             "contract v3 s8)" % (role, why))

allow()
PY

CORE_PAYLOAD="$payload" python3 -c "$CORE_GH_GUARD"
rc=$?
trap - EXIT
exit "$rc"
