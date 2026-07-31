---
kind: implementation-survey
subject: issue-20
produced_by: implementation
upstream: []
loop_state: proposed
---

# Current-state survey — issue-20

gh-guard's own header states its intent precisely: role sessions must never
perform "the human's acts" (review verdicts, merge/close, issue authorship,
forged-approval comments, their raw-API spellings, pushes to `main`)
"whatever that token's permissions happen to be"
(`core/hooks/gh-guard.sh:6-11`). This survey checks how far that intent
actually reaches, and where it stops.

## Method

All claims below were verified by feeding a fabricated `PreToolUse` JSON
payload (`{"tool_name":"Bash","tool_input":{"command":"<cmd>"}}`) to
`core/hooks/gh-guard.sh` as a real subprocess, under `CLAUDE_ROLE=coding` (or
`qa` where noted), and reading the exit code — the same technique the issue
itself used ("Verified by evaluating the seven patterns directly") and the
same technique `core/hooks/tests/run-gh-guard-tests.sh` already uses in this
repo. No command was ever actually executed against GitHub — none of the
probed strings (`curl`, `wget`, `gh api …`) were run; they were only handed
to gh-guard's stdin as text to classify. exit 0 = ALLOW, exit 2 = DENY.

## 1. Exact scope of the current matcher

`core/hooks/gh-guard.sh` has two layers, both text-pattern matchers over the
single `tool_input.command` string of one `Bash` call:

- **Layer 0 — shell pre-filter** (`gh-guard.sh:34-41`), before python even
  starts: exits 0 unless the raw JSON payload contains the literal substring
  `"Bash"` (line 35) AND contains the literal substring `gh` or `git`
  anywhere in the payload (line 38-41). This is a coarse performance
  short-circuit, not a security boundary by itself — the comment above it
  (line 33) calls it exactly that: "only Bash calls mentioning gh/git are
  adjudicated."
- **Layer 1 — the seven `RULES`** (`gh-guard.sh:68-89`), a python
  `re.search` over the same command string. Every pattern's trigger is the
  literal token `gh` or `git` used as its own word (`\bgh\s+…` /
  `\bgit\s+push\b`), immediately followed by one of a fixed set of
  subcommand or path spellings:
  - `gh pr review … (--approve|-a|--request-changes)` (line 69)
  - `gh pr (merge|close|reopen)` (line 72)
  - `gh issue (create|close|reopen|edit|transfer|delete)` (line 75)
  - `gh api … pulls?/\d+/(reviews|merge)` or `…/merge\b` (line 78)
  - `gh pr comment … APPROVE` (line 80)
  - `gh api … (issues|pulls?)/\d+/comments … APPROVE` (line 83)
  - `git push … (origin )?(main|master)` (line 86)

Both layers are anchored on **which binary's name appears in the command
text**, never on **which network endpoint gets reached** or **which GitHub
account performs the act**. That is the structural property this survey
tests against.

## 2. Bypass paths, verified

### Group A — a different HTTP client, the exact same REST call

The seven rules require the literal token `gh`. Any other client hitting the
identical documented REST endpoint matches none of them:

| probe | result |
|---|---|
| `curl -X PUT -H "Authorization: token TOK" https://api.github.com/repos/o/r/pulls/7/merge` | **ALLOW** |
| `wget --header="Authorization: token TOK" --method=PUT https://api.github.com/repos/o/r/pulls/7/merge` | **ALLOW** |
| `curl -X POST … https://api.github.com/repos/o/r/pulls/7/reviews -d event=APPROVE` | **ALLOW** |

(Sanity check: the `gh`-spelled equivalents of the first two —
`gh pr merge 7 --merge` and `gh api -X PUT repos/o/r/pulls/7/merge` — both
**DENY**, confirming these are true regex misses, not a broken harness.)

The identical logic applies to any other client capable of an authenticated
HTTPS request from inside the same session — `python3 -c
"import urllib.request…"`, `node -e "fetch(…)"`, `ruby -e
"Net::HTTP…"`, `perl`, `osascript … do shell script`, `ssh host curl …`,
`docker run curlimages/curl …` — none contain the token `gh`, so none can
match Layer 1 regardless of what Layer 0 does. This is exactly the pattern
the issue's own "Observed, not hypothetical" section describes: the
issue-73 session's `curl -X PATCH` fallback after `gh pr edit` failed.

Root cause: `api.github.com` must stay reachable (role sessions need it for
`gh`/`git` themselves), and the token is already in the session environment
(`gh auth token` or a manually-set header) — nothing about the network path
or the credential distinguishes `gh` from `curl`.

### Group B — `gh` itself, but a call shape the seven rules never enumerated

These stay on the `gh` binary — Layer 0's fast-path is irrelevant here,
they'd pass it regardless of its exact substring list — and still bypass,
because the RULES' *shapes* don't cover them:

| probe | result | why no rule fires |
|---|---|---|
| `gh api graphql -f query=…mergePullRequest…` | **ALLOW** | rule 4 matches REST path text (`pulls?/\d+/(reviews\|merge)`); a GraphQL mutation body has no such path segment |
| `gh api graphql -f query=…addPullRequestReview(…event:APPROVE)…` | **ALLOW** | same — no rule matches GraphQL mutation names at all |
| `gh api -X PATCH repos/o/r/pulls/7 -f state=closed` | **ALLOW** | rule 4 requires `pulls?/\d+/(reviews\|merge)`; a bare `pulls/7` PATCH (the REST spelling of *close*, distinct from *merge*) matches nothing |
| `gh api -X PATCH repos/o/r/pulls/7 -f state=open` | **ALLOW** | same gap, for *reopen* |
| `gh api -X PATCH repos/o/r/issues/7 -f state=closed` | **ALLOW** | rule 3 only matches the `gh issue close` subcommand spelling; rule 6 only matches comment bodies containing `APPROVE` — nothing matches a raw issue-state PATCH |
| `gh api -X PATCH repos/o/r/issues/7 -f title=pwned` | **ALLOW** | same — no rule covers raw-API issue edit at all |

These are gaps in gh-guard's own stated coverage ("the raw-API spelling of a
review/merge is still a review/merge", `gh-guard.sh:79`) — the intent named
in the code comments is broader than what the seven patterns actually
match, independent of the curl/wget question the issue raises.

### Group C — defeating the literal-token match itself

| probe | result | mechanism |
|---|---|---|
| `/tmp/…/ghcopy pr merge 7 --merge` (binary copied/renamed) | **ALLOW** | Layer 0's substring check still fires (`ghcopy` contains `gh`), but Layer 1's `\bgh\s+pr\s+(merge…)` requires "gh" to be its own token immediately before whitespace; `ghcopy` isn't |
| write the real command to a file, then `bash /path/to/file.sh` | **ALLOW** | the Bash `command` string is just `bash /path/to/file.sh` — neither `gh` nor `git` nor any endpoint text appears in it; gh-guard never reads file contents, so what the file does is invisible regardless of what it contains |
| `curl -X PUT … https://140.82.112.6/repos/o/r/pulls/7/merge` (literal IP instead of hostname) | **ALLOW** | Layer 0 itself never fires — the whole payload contains neither `gh` nor `git` as a substring, so python is never invoked. (`api.github.com` only happens to satisfy today's `*git*` check because "github" starts with the letters "git" — an accidental side effect of Layer 0 being a raw substring match, not a designed host check.) |

### Group D — gh-guard only ever looks at `Bash` calls

`gh-guard.sh:35` exits 0 immediately unless the JSON payload contains the
literal substring `"Bash"`. Confirmed by feeding a `tool_name: "Write"`
payload whose `content` field carries the exact denied
`curl … pulls/7/merge` text: **ALLOW**, unconditionally, before any content
is inspected. Any tool other than `Bash` that can get an HTTPS request out —
today, chiefly the Write tool writing an executable script (which is also
Group C's file-indirection path) — is structurally outside gh-guard's
field of view, by construction, regardless of how Layer 1's rules are
extended.

## Synthesis

Every bypass above traces to the same structural fact: gh-guard classifies
**command text**, not **which account performs the act**. Groups A and B are
closable by widening what Layer 1's patterns match (endpoint shape and
verb, not client-binary name) — a real, boundable improvement. Group C's
file-indirection and host-obfuscation cases and Group D's tool-blindness
are not closable by adding more regexes to a single-command-string matcher;
closing them needs either inspecting file contents *and* tracking them
across tool calls (a materially different, stateful hook design) or,
per the issue's own "Direction" section, removing the incentive at the
account layer instead of the command-text layer. This survey does not
attempt to resolve which of those the project wants; it hands the accepted
scope and the two closable/non-closable groups to the proposal.

## Unknowns

- Whether any MCP tool currently wired into role sessions in this
  deployment can issue an outbound authenticated HTTPS request the way the
  `Write`-tool probe simulates for an executable file. No such tool is
  present in this repository's own plugin set (`core/`, `terse/`,
  `freelunch/`, `scout/` — none register network-capable MCP tools), so this
  is flagged as unknown rather than tested, not asserted safe.
- Whether `git push` to `main` has an analogous curl-based bypass (pushing
  over git's smart-HTTP protocol without the `git` binary). Not probed: it
  needs a packfile negotiation, not a single HTTP call, so it is a
  materially higher-effort path than the API bypasses above and is treated
  as out of this survey's scope rather than confirmed either way.
