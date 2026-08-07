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

As of issue #98, the same three dequoted rules also close the class of
bypass issue-94's own execution-observation (Finding 1) confirmed live:
`bash -c`/`sh -c`/`eval`/`python3 -c`, including through `timeout`/`env`/
`xargs`/`nohup`, DEQUOTE blanks their quoted argument to inert data the
same way it blanks a `grep` pattern, but that argument is not data — it
is EXECUTED. `bash -c "gh pr merge 5"` denied before #94's dequote fix
and silently started allowing after it; this class fix restores the
denial without reopening #94's own negative space. The fix (`gate_lib.
gate_wrapper_head_before`, `docs/handbooks/gate-house-standard.md`) is a
per-quoted-span check: when a dequoted rule's pattern misses `dq` but
matches raw `cmd`, every quoted span whose own raw text also matches the
pattern is checked for a wrapper head immediately before it; a non-empty
wrapper head still denies. `wrapper-bash-c`, `wrapper-bash-lc`,
`wrapper-timeout-bash-c`, `wrapper-env-bash-c`, `wrapper-xargs-bash-c`,
`wrapper-nohup-bash-c`, `wrapper-python3-c`, `wrapper-sh-c`, and
`wrapper-eval` cover the issue's own named variants (one case per
variant, spread across all three dequoted rules — merge, review
--approve, issue create — not all merge), each denying on a real payload
inside the wrapper's quoted argument. The three pre-existing `quote-*`
cases (`quote-gh-pr-merge-in-grep`, etc.) are re-asserted `allow`
unchanged by the same suite run, confirming the new check adds a
detection path gated on a wrapper head rather than undoing #94's
dequoting for non-wrapper heads (a plain `grep` resolves to head `grep`,
not a `WRAPPER_HEADS` member, so `gate_wrapper_head_before` returns
empty). `wrapper-bash-c-plain-grep` (`bash -c "grep -n 'gh pr merge'
x.py"`, a real wrapper invocation nesting a legitimate grep) is a named,
accepted over-block residual: the per-span resolver denies on the
wrapper head firing, whatever the wrapper's own quoted argument actually
contains — recursing into it to tell a real payload from a nested
data-only lookup is a real extension point, not built here (proposal
Rationale, `docs/issue-98/proposals/2026-08-03-wrapper-head-class-fix-
for-dequote-bypass.md`) — kept visible rather than silently accepted,
same convention as `gap-c-*`/`gap-f-*`.

A hunt pass (`docs/issue-98/reports/implementation.md`, `## Hunt`) found
that the first version of `gate_wrapper_head_before` resolved the local
head via `gate_head_of`'s TRANSPARENT hop-by-hop walk, which assumes
every `-`-prefixed token is a self-contained flag — so a TRANSPARENT
wrapper's OWN value-taking flag (`nice -n 10`, `env -u FOO`, `timeout -s
KILL 30`, `xargs -I fmt` with a space instead of `xargs -I{}`) landed the
resolved "head" on the flag's VALUE token instead of the real wrapper,
silently allowing the wrapped verb through — a fail-OPEN outcome, unlike
`board-gate.sh`'s fail-closed-on-unrecognized-head default that absorbs
the same imprecision harmlessly. Fixed by having `gate_wrapper_head_before`
scan the local segment's words DIRECTLY for the rightmost WRAPPER_HEADS
word instead of depending on that walk — `wrapper-timeout-flag-arg`,
`wrapper-nice-flag-arg`, `wrapper-env-flag-arg`, `wrapper-xargs-space-flag`
pin the fix. The same pass also found `perl`'s own code-execution flag is
`-e`, not `-c` (`-c` means "check syntax, don't run" for perl) — the
`-c`-shaped-flag-only check missed perl entirely despite `perl` being a
named `WRAPPER_HEADS` member; fixed with a `perl`-specific `-e`-shaped
flag check, pinned by `wrapper-perl-e`.

Also covers issue-138's fail-closed rc-remap fix: `gh-guard.sh` used to
clear the EXIT trap before propagating the python judge's own exit code,
so an uncaught python error (rc=1) exited non-blocking instead of
denying. `python3-internal-error` stubs a `python3` on `PATH` that
unconditionally exits 1 and asserts the gate still exits 2 (deny), the
same `_fc_rc`-style remap `trailer-gate.sh`/`record-fields-gate.sh`
already carried. `empty-payload` pins that empty stdin, for a role
session, denies rather than silently falling through the fast path to
allow.
