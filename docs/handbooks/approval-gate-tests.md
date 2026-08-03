# approval-gate test harness

`core/hooks/tests/run-approval-gate-tests.sh` exercises
`core/hooks/approval-gate.sh` as a real subprocess against synthetic git
repos and JSON tool-call payloads (`run` helper; `want allow|deny` maps to
exit 0/2). `CORE_GH` points the gate at a stubbed `gh` binary instead of
the real network call.

Run it directly, no setup required:

    bash core/hooks/tests/run-approval-gate-tests.sh

`stub_gh <dir> <mode>` generates that stub. It is argument-aware: the
generated `gh` script branches on its own `$1` ("issue" vs "pr"), because
`approval-gate.sh` now makes two independent `gh` calls per check —
`gh issue view <n> --json state,comments` (the issue-state precondition,
checked first, plus the issue's own comments for the single-account
path) and `gh pr view <branch> --json reviews` (the two-account path,
tolerant of "no PR open"). Each `mode` sets `issue_state`,
`issue_comments`, `pr_ok`, and `reviews` independently, so a test case
can combine, e.g., a closed issue with an otherwise-valid PR review.

Covers: PR-review approval (two-account), issue-comment approval
(single-account, including the no-PR-open case that motivated moving the
canonical signal off the PR — see issue #53), bot/agent accounts never
satisfying either path, free-text comments never counting as approval, a
minimized/hidden issue comment not counting (GitHub's non-destructive way
to retract a comment), the issue-closed precondition denying both paths
unconditionally, missing/empty `approvers.md`, branch and role
preconditions, the no-remote precondition, and the docs execution-surface
rules (phase-1 homes stay open; the record file and other doc paths wait
for the Approve).

Also covers two read-classification fixes ported from `board-gate.sh`
(issue-88/PR #89), addressing the identical twin defects `approval-gate.sh`
carried (issue-90): `READ_ONLY_HEADS` had no `"cd"` entry, so a
`cd`-prefixed read (`cd docs/issue-7/reports/coding && ls`) was denied
outright even though the identical read without the `cd` prefix was
allowed (`bash-cd-then-read-own-reports`, plus the negative-space
`bash-cd-then-write-src` proving a `cd`-prefixed real write still denies);
and `WRITEISH` was quote-blind (`re.compile(r"[>|`]|\$\(")` flagged a
`>`/`|` inside a quoted string, e.g. a `grep` pattern, as if it were a
real shell write-ish character). `WRITEISH` now leads with quote-span
alternatives (`(?<!\\)`-guarded, same shape as `board-gate.sh`'s
`SEGMENT`) and a new `_writeish(cmdline)` helper walks
`WRITEISH.finditer` to tell a quoted-span match from a real one, answering
the boolean `WRITEISH.search` used to answer directly.
`bash-quoted-redirect-in-grep` and `bash-single-quoted-pipe-grep` pin the
fix for `"`- and `'`-quoted redirects; the negative-space
`bash-quoted-redirect-then-real-pipe` proves a real, unquoted `|` later
on the same line still denies. `bash-escaped-quote-then-write` ports
`board-gate.sh`'s warrant-hunt regression: a backslash-escaped quote
CHARACTER outside any real shell quote must not open a fake quoted span
that swallows the real `>` between two real tokens.

The quote-aware `WRITEISH`/`_writeish` mechanism described in the two
paragraphs above has since been relocated out of `approval-gate.sh` into
the shared `gate_lib.gate_dequote`/`gate_outside_quotes` primitive
(`core/hooks/lib/gate-lib.py`), the same primitive `board-gate.sh` uses
(issue-94; see
`docs/issue-94/proposals/2026-08-03-quote-aware-board-gate-writeish-and-segment-gh-guard.md`).
The call site now reads
``gate_lib.gate_outside_quotes(cmdline, r"[>|`]|\$\(")`` instead of the
former `_writeish(cmdline)`. Observable behavior is unchanged — same
quote-span-then-match algorithm, just centralized — so no new test cases
were added; the existing `bash-quoted-redirect-in-grep`,
`bash-single-quoted-pipe-grep`, `bash-quoted-redirect-then-real-pipe`,
`bash-escaped-quote-then-write`, `bash-cd-then-read-own-reports`, and
`bash-cd-then-write-src` cases already pin the behavior above and
continue to cover it.

Test-authoring note: this harness's `run()` builds the `Bash` tool's JSON
`tinput` from a `cmd=` option via a plain `printf '%s'` substitution with
no JSON-escaping. A `cmd=` value carrying a literal `"` must pre-escape it
to `\"` (and any literal `\` to `\\`) in the test line itself, or the
resulting JSON is invalid and the gate denies via its unrelated
unreadable-payload path — a deny that can coincidentally match a `want
deny` case without ever exercising `_writeish` at all.
