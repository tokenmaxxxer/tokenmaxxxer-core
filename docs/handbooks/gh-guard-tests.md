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

As of issue #94, the three pure verb-invocation rules — PR review-verdict
(`gh pr review ... --approve/--request-changes`), PR merge/close/reopen,
and issue create/close/reopen/edit/transfer/delete — match against
`gate_lib.gate_dequote(cmd)` instead of the raw command string, so a
quoted argument that merely *contains* the denied text (e.g. a `grep`
search pattern like `"gh pr merge"`) no longer trips the gate: this closes
the issue's exact repro, `grep -n "^def \|gh pr merge\|pr merge"
spawn.py`, and is covered by `quote-gh-pr-merge-in-grep`,
`quote-review-approve-in-grep`, and `quote-issue-create-in-grep`. The
`quote-real-merge-after-quote` case is the negative-space sibling: a real,
unquoted `gh pr merge` later on the same line as an earlier quoted
occurrence still denies. The remaining eight rules (the raw-API
endpoint/state rules, the two APPROVE-comment rules, `git push`, and the
GraphQL mutation rule) are UNCHANGED and stay quote-blind on purpose —
they exist specifically to catch content that legitimately lives inside a
quoted `gh`/`curl` argument (an `--body "APPROVE ..."`, a `-f
query='mutation{...}'`), so dequoting them would disable their true-
positive path. This residual false-positive class — a quoted mention of a
raw-API path tripping one of the eight unchanged rules — is tracked by
`gap-f-api-merge-in-quote-still-fires`, kept visible rather than silently
dropped, same convention as `gap-c-*`/`gap-d-*`.
