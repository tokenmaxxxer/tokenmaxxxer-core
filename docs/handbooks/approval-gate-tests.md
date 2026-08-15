# approval-gate test harness

`core/hooks/tests/run-approval-gate-tests.sh` exercises
`core/hooks/approval-gate.sh` as a real subprocess against synthetic git
repos and JSON tool-call payloads (`run` helper; `want allow|deny` maps to
exit 0/2). `CORE_GH` points the gate at a stubbed `gh` binary instead of
the real network call.

Run it directly, no setup required:

    bash core/hooks/tests/run-approval-gate-tests.sh

issue-189: `approval-gate.sh` now also reads `state_reason` from
`gh issue view --json state,comments,state_reason` (read-only, unused for
enforcement — reporting/routing only) and computes a `reject_challenge`
("REJECT issue-<n>/<role>") matched via the same
`comment_matches(challenge_str)` machinery now shared with `APPROVE`'s
`challenge`. It also reads the existing `last[login]` state map (already
computed only inside the `if pr_out.returncode == 0:` guarded block) to
tell `CHANGES_REQUESTED` (a rejection act, review body as rationale) apart
from `DISMISSED` (a revoked opinion, no rejection): either recognized
path — or an exact `REJECT` comment — computes one contract §5 `finding`
block (`verdict: contradicts`, `addressed_to: <role>`, `severity:
blocking`) folded into the existing deny message when the write is
refused. This read never itself denies anything beyond what was already
being refused (no auto-enforcement off `CHANGES_REQUESTED` — deferred,
see `docs/issue-189/proposals/2026-08-10-rejection-withdrawal-lifecycle-design.md`'s
alternatives-considered). `run-approval-gate-tests.sh` itself is
unchanged and stays the read-only reference suite (46/46 green against
this build); `REJECT`/`CHANGES_REQUESTED` coverage instead lives in
`core/hooks/tests/deny-only-check.sh`'s `reject_forgery_probe` (see
`docs/handbooks/board-gate-tests.md`).

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

Also covers issue-124's R1 fix (`docs/issue-114/reports/execution-observation.md`
`## Verdict 4`, R1): the read-only early-allow head check used to compute
`head` via raw `cmdline.strip().split()[0].rsplit("/", 1)[-1]`, with no
`TRANSPARENT`-wrapper resolution, so a wrapped read (`timeout 30 grep -rn
foo src/app.py`) resolved `head` to `"timeout"` — not in `READ_ONLY_HEADS`
— and missed the shortcut, falling through to the slower candidate scan
with no PR to authorize it (an over-block, not a hole: the same fail-closed
direction issue-114 fixed in `board-gate.sh`, in a different gate). Fixed
by switching the call site to `gate_lib.gate_head_of(cmdline)`, the same
resolver `board-gate.sh` and `gh-guard.sh` already use, instead of growing
a second, independent head-resolution path in `approval-gate.sh` itself.
`bash-wrapper-timeout-grep-read` pins the fix (`allow`); its negative-space
sibling `bash-wrapper-timeout-write` pins that a same-wrapper write stays
denied, unchanged before and after the fix.

Also covers the narrow negative-lifecycle remainder (2026-08-16,
`docs/issue-189/proposals/2026-08-16-narrow-negative-lifecycle-remainder.md`):
the closed-issue denial message now interpolates `issue_state_reason`
when GitHub supplied one (`"issue #%s is not open (state: %s, reason:
%s)"`), falling back to the original wording verbatim when absent —
lenient, no new failure mode. `approval-gate.sh` also gained
`withdraw_challenge`/`defer_challenge` ("WITHDRAW"/"DEFER
issue-<n>/<role>"), matched via the same `comment_matches()` used for
`APPROVE`/`REJECT`. When the write is refused for lack of approval, a
matching `WITHDRAW`/`DEFER` comment now folds its own `severity:
advisory` finding into the deny message (no `verdict` field, unlike the
pre-existing `REJECT`/`CHANGES_REQUESTED` finding's `verdict:
contradicts` — contract §5 defines no `verdict` field on a `finding`
block). Precedence is unchanged and pre-existing: `approved = pr_approved
or comment_approved` short-circuits before any of `REJECT`/`WITHDRAW`/
`DEFER` are consulted, so an approval present alongside one of these
tokens on the same issue silently wins — a before-landing hunt confirmed
this is inherited, not introduced, by the new tokens, and is the
proposal's own named out-of-scope item (no precedence rule decided
here). Coverage for the new tokens' forgery resistance lives in
`core/hooks/tests/deny-only-check.sh`'s `withdraw_forgery_probe` (see
`docs/handbooks/board-gate-tests.md`), not in this reference suite,
which stays unchanged and green (50/50) against this build.

Also covers issue-138's fail-closed rc-remap fix: `approval-gate.sh`
used to clear the EXIT trap (`trap - EXIT`) before propagating the
python judge's own exit code, so an uncaught python error (rc=1) exited
non-blocking instead of denying. `python3-internal-error` stubs a
`python3` on `PATH` that unconditionally exits 1 and asserts the gate
still exits 2 (deny), pinning the `_fc_rc`-style remap ported from
`trailer-gate.sh`/`record-fields-gate.sh`. `empty-payload` pins that
empty stdin (a delivery failure) denies rather than silently falling
through the fast path to allow.

Also covers issue-142's C4 sweep: the `internal_error` case's scratch
`python3` stub directory used to come from a raw `mktemp -d` call — the
canon abolished after it destroyed a workspace (issue #57: a failed
`mktemp -d` lets `cd ""` succeed in place, so `td` silently becomes the
repo root and the later `rm -rf "$td"` deletes the checkout). Replaced
with the `mktd` helper from `_tmp.sh` (now sourced at the top of this
file), assigned to a separate `stubdir` so it does not collide with the
case's own `td`. Mechanical, no behavior change; no new test cases.

Test-authoring note: this harness's `run()` builds the `Bash` tool's JSON
`tinput` from a `cmd=` option via a plain `printf '%s'` substitution with
no JSON-escaping. A `cmd=` value carrying a literal `"` must pre-escape it
to `\"` (and any literal `\` to `\\`) in the test line itself, or the
resulting JSON is invalid and the gate denies via its unrelated
unreadable-payload path — a deny that can coincidentally match a `want
deny` case without ever exercising `_writeish` at all.

Also covers issue-212's build-now bypass (contract v3 s19a,
on-the-record#785 cross-repo-blocked basis): when the spawn task sets
`CORE_BUILD_NOW=1` in the session's environment, `approval-gate.sh` now
allows execution-surface writes without any Approve signal, checked
before the gh-backed checks. `run()` gained a `buildnow` option that sets
`CORE_BUILD_NOW=1` for the invocation (default empty, so every other test
case is unaffected). `build-now-bypass-no-pr`,
`build-now-bypass-no-approvers`, and `build-now-bypass-bash-write` pin
the bypass allowing even with no PR, no approvers file, or a raw Bash
redirect; `build-now-unset-still-gated` is the empty-state sibling — the
same `nopr` fixture with `CORE_BUILD_NOW` left unset still denies,
proving the default two-phase gate is unchanged.
