# gh-guard test harness

`core/hooks/tests/run-gh-guard-tests.sh` exercises `core/hooks/gh-guard.sh`
as a real subprocess against synthetic `PreToolUse` JSON payloads (`run`
helper; `want allow|deny` maps to exit 0/2). No git repo or network needed.

Run it directly, no setup required:

    bash core/hooks/tests/run-gh-guard-tests.sh

Covers the seven original `gh`-token rules (PR review/merge/close/reopen,
issue create/close/reopen/edit, the raw-API review/merge spelling, an
APPROVE-shaped comment and its raw-API spelling, `git push` to main), the
role-required precondition (no `CLAUDE_ROLE` passes through untouched),
and, as of issue #20, endpoint+verb matching independent of the client
binary — the survey at `docs/issue-20/reports/implementation/survey.md`
grouped the bypasses it found as Group A-D, and the test names carry the
same labels:

- `gap-a-*` — a non-`gh` HTTP client (`curl`, `wget`) hitting the exact
  REST endpoint the `gh`-spelled rules already cover, including a
  literal-IP host (closed as a side effect of widening Layer 0's
  pre-filter to include `curl`/`wget`/`http://`/`https://`, not just
  `gh`/`git`).
- `gap-b-*` — `gh` itself, via call shapes the seven original rules never
  enumerated: `gh api graphql` PR-merge/review mutations, and raw-API
  `PATCH` state writes on the bare `pulls/N`/`issues/N` endpoints (PR/issue
  close, reopen, edit).
- `gap-c-*` — still open on purpose, asserted `allow` so the gap stays
  visible instead of silently reappearing: a renamed/copied `gh` binary
  (defeats the `\bgh\b` word-boundary match) and file-indirection (`bash
  script.sh`, where the denied text never appears in the command string
  gh-guard sees).
- `gap-d-*` — also still open on purpose: any tool other than `Bash`
  (gh-guard only ever adjudicates `Bash` calls); probed directly rather
  than through the `run` helper, since `run` always sets
  `tool_name:"Bash"`.

None of Group C/D is closable by adding more regexes to a
single-command-string matcher — see `core/hooks/gh-guard.sh`'s RULES
comment and `README.md`'s defense-in-depth bullet for why, and
`docs/issue-20/proposals/2026-07-31-build-gh-guard-endpoint-match.md` for
the full reasoning.
