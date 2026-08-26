---
issue: 305
role: execution-observation
author: execution-observation
loop_state: landed
upstream:
  - path: issue-305/implementation (PR #313, commit 183e2d379ada4a1792b4ddc4282bd9c368e4fe60)
    sha: 183e2d379ada4a1792b4ddc4282bd9c368e4fe60
  - path: docs/issue-305/reports/implementation.md
    sha: 183e2d379ada4a1792b4ddc4282bd9c368e4fe60
subject: PR #313 — sweep remainder: python3 fail-closed consistency (F9/F16/F18/F22) + 15 remaining silent-failure findings (F1-F8, F10-F14, F21, F23) from issue-301's inventory
test: core/hooks/tests/run-gate-shape-tests.sh (issue's named acceptance gate); cross-checked run-all.sh, run-scope-gate-tests.sh, warrant/hooks/tests/run-hunt-tier-tests.sh, run-hunt-guard-tests.sh, tests/test_ordering_gates_237.py, tests/test_ordering_gate_livefire.py; independent PATH-without-python3 live-fire for all 5 affected sites; independent live-fire for F11
result: passed
assertedBy: execution-observation (independent re-execution in a git worktree pinned to PR #313's commit 183e2d3, not PR #313's own pasted output)
---

# issue-305 — execution-observation record

## What was done

Independently re-derived and re-executed PR #313's central claims against
a git worktree pinned to its actual commit
(`183e2d379ada4a1792b4ddc4282bd9c368e4fe60` on `issue-305/implementation`,
still open as of this record), rather than trusting the PR's own
narration or pasted output.

**1. Diff scope, read from source.** `git diff` against the PR's true
merge-base (`509759c9`, not `origin/main` directly — a naive
`origin/main..HEAD` diff shows a spurious 116-line deletion in
`board-gate.sh` plus deletions of `docs/issue-304/` and `docs/issue-320/`
records, because `origin/main` has since advanced with unrelated commits
from other issues; the merge-base diff is the true scope) confirms
exactly the 15 hook/gate files + 1 new record PR #313 claims:

```
core/hooks/approval-gate.sh              |   2 +-
core/hooks/board-gate.sh                 |   2 +-
core/hooks/citation-gate.sh              |  10 +-
core/hooks/facet-keyword-gate.sh         |  25 ++-
core/hooks/gh-guard.sh                   |   2 +-
core/hooks/handbook-trigger-gate.sh      |  18 ++-
core/hooks/ordering-gate.sh              |  66 +++++++-
core/hooks/pretooluse-dispatcher.sh      |   2 +-
core/hooks/pretooluse_dispatcher.py      |  57 ++++++-
docs/issue-305/reports/implementation.md | 270 +++++++++++++++++++++++++++++++
freelunch/hooks/observe.sh               |  21 ++-
terse/hooks/terse.sh                     |  12 +-
warrant/hooks/hunt-guard.sh              |  46 +++++-
warrant/hooks/hunt-tier.sh               |  12 +-
warrant/hooks/scope-gate.sh              |  11 +-
warrant/hooks/state.sh                   |  26 ++-
16 files changed, 543 insertions(+), 39 deletions(-)
```

Read every changed hunk directly (not just the commit-message narration)
in `board-gate.sh`, `citation-gate.sh`, `facet-keyword-gate.sh`,
`gh-guard.sh`, `handbook-trigger-gate.sh`, `ordering-gate.sh`,
`pretooluse-dispatcher.sh`, `pretooluse_dispatcher.py`,
`freelunch/hooks/observe.sh`, `terse/hooks/terse.sh`,
`warrant/hooks/{hunt-guard,hunt-tier,scope-gate,state}.sh`. Each matches
its claimed finding: the fail-open/fail-closed *decision* for every
mechanism is unchanged (e.g. `scope-gate.sh` and `citation-gate.sh`'s
missing-config path stays exit 0 by documented design; `facet-keyword`'s
demoted python3-check stays advisory exit 0) — only the missing
communication, or a demonstrated silent-bypass path, is added/closed, with
one exception found by the before-landing warrant hunt below (item 7):
`pretooluse_dispatcher.py`'s F23 fix is a second, undisclosed
allow→deny flip, not just facet-keyword-gate.sh's demotion.

**2. Acceptance gate re-executed live**, in the pinned worktree, with
python3 present (empty state — must be byte-identical to baseline):

```
$ bash core/hooks/tests/run-gate-shape-tests.sh
ok     gh-guard-unescaped-merge-denies            deny
ok     gh-guard-escaped-merge-still-denies-F15    deny
ok     gh-guard-irrelevant-payload-fast-skips     allow
ok     gh-guard-irrelevant-payload-never-reaches-python3 not-invoked
ok     approval-gate-unescaped-src-write-denies   deny
ok     approval-gate-escaped-src-write-still-denies-F17 deny
ok     approval-gate-escaped-src-bash-write-still-denies-F17 deny
ok     approval-gate-irrelevant-payload-fast-skips allow
ok     approval-gate-irrelevant-payload-never-reaches-python3 not-invoked
ok     board-gate-unescaped-badbucket-denies      deny
ok     board-gate-escaped-badbucket-still-denies  deny
ok     board-gate-irrelevant-payload-fast-skips   allow
ok     board-gate-irrelevant-payload-never-reaches-python3 not-invoked
ok     ordering-gate-no-bash-fast-path            absent
ok     dispatcher-gh-guard-escaped-merge-denies-F15 deny
ok     dispatcher-approval-gate-escaped-src-denies-F17 deny
ok     dispatcher-board-gate-escaped-badbucket-denies deny
ok     dispatcher-irrelevant-payload-allows-full-chain allow

== 18 passed, 0 failed ==
```
18/18, byte-identical to the record's pasted claim.

**3. PATH-without-python3 live-fire independently reproduced** for all 5
affected sites (own harness — a scratch `PATH` populated with symlinks to
every `/usr/bin/*` binary except `python3*`, not a copy of PR #313's
script):

```
=== gh-guard.sh (F16) ===
gh-guard: refused — python3 not found; cannot evaluate gate
exit=2
=== approval-gate.sh (F18a) ===
approval-gate: refused — python3 not found; cannot evaluate gate
exit=2
=== board-gate.sh (F18b) ===
board-gate: refused — python3 not found; cannot evaluate gate
exit=2
=== pretooluse-dispatcher.sh (F22) ===
pretooluse-dispatcher.sh: refused — python3 not found; cannot evaluate gate
exit=2
=== facet-keyword-gate.sh (F9) ===
facet-keyword-gate: python3 not found; cannot evaluate gate
{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"facet-keyword-gate: python3 not found; cannot evaluate gate"},"systemMessage":"facet-keyword-gate: python3 not found; cannot evaluate gate"}
exit=0
```
Matches the record's pasted evidence exactly: fail-closed exit 2 + named
message for the 4 hard gates, advisory exit 0 + hookSpecificOutput for
facet-keyword's demoted check.

**4. Full regression sweep re-executed**, `core/hooks/tests/run-all.sh` —
`ALL OK`, 0 failures across every listed suite (including
`run-dispatcher-equivalence-tests.sh`: 25/25 with latency 44ms avg, and
`run-approval-gate-tests.sh`/`run-role-gates-tests.sh` with 0 failures).
This worktree carries a working `origin` remote and no host contention
during the run, so it does not reproduce the record's two documented
pre-existing/unrelated items (the `approvers.md`-dependent approval-gate
failures, and the latency-flake) — consistent with, not contradicting,
the record's own characterization of both as environment-dependent, not
caused by this PR's changes. Also independently re-ran the suites not
folded into `run-all.sh`:

```
warrant/hooks/tests/run-hunt-tier-tests.sh   -> pass=15 fail=0
warrant/hooks/tests/run-hunt-guard-tests.sh  -> 9 passed, 0 failed
core/hooks/tests/run-scope-gate-tests.sh     -> 46 passed, 0 failed
tests/test_ordering_gates_237.py + test_ordering_gate_livefire.py -> 28 passed
```
All byte-identical in count to the record's claims.

**5. One additional live-fire spot-check beyond the record's own pasted
evidence**, for F11 (`ordering-gate.sh`'s malformed-`tool_input` fail-
closed path), run directly against the source rather than trusting the
diff read alone:

```
$ echo '{"tool_name":"Write","tool_input":"not-a-dict"}' | OG_ROOT=<scratch> bash core/hooks/ordering-gate.sh
rc=2
stderr= ordering-gate: refused — Write tool_input is malformed (must be
an object with a string file_path); failing closed rather than silently
treating this as no write
```
Confirms the claimed fail-closed behavior independently (F11 has no
dedicated regression test in the diff — the fix relies on live-fire
evidence plus the unchanged `test_ordering_gates_237.py`/
`test_ordering_gate_livefire.py` suite, consistent with this session's
own no-persistent-test-file-by-default convention).

**6. Operator-frozen constraint** (2026-08-25, systemic scope, no added
overhead/load, no new conflict/stall surfaces, no consumer-tree residue):
independently assessed against the diff, since the implementation record
does not name this constraint explicitly (see Open findings). Every
changed line adds a string constant and one additional
print/write/`hookSpecificOutput` call on an already-executing, low-
frequency failure path (missing python3, malformed JSON, corrupted state
file, a `.*`-matcher hook already invoked every call) — no new
subprocess, lock, or wait is introduced; F2/F3/F11 narrow specific
malformed-input cases from silent-allow to fail-closed, a semantic
change, but through the same existing exit-code convention, not a new
stall surface; no new on-disk file is created in a consumer tree (F6's
extra log row appends to a log `observe.sh` already writes to). The
constraint holds; it just was not written down as its own checked item in
the implementation record.

**7. Before-landing warrant hunt** (one stance, `warrant:warrant-hunter`,
recorded in full at
`docs/issue-305/reports/execution-observation/2026-08-25-hunt-execution-observation-verify-pr313.md`):
assumed the record's positive verdict on PR #313 is wrong and looked for
an undisclosed composition regression. FINDING, independently reproduced
against the pinned worktree: F23's fix to `pretooluse_dispatcher.py`
changes what happens when `OTR_DISPATCH_ONLY` (the exact-match
single-gate test-harness seam, never set outside an inline `env VAR=val`
prefix in the test suite) holds a value that matches no registered gate
— before, `return 0` (silent allow, the bug F23 targets); after, exit 2
naming the bad value. This is a second allow→deny disposition flip beyond
the one the record's item 1 above names (`facet-keyword-gate.sh`'s
demotion) — and unlike that one, it is session-wide: a harmless,
unrelated tool call is denied purely because this env var holds a bad
value, confirmed live:

```
$ echo '{"tool_name":"Read","tool_input":{"file_path":"/etc/hostname"}}' \
  | OTR_DISPATCH_ONLY="record-felds-gate.sh" CLAUDE_ROLE=core python3 core/hooks/pretooluse_dispatcher.py
pretooluse_dispatcher.py: OTR_DISPATCH_ONLY='record-felds-gate.sh' does not match any registered gate (...); refusing rather than silently returning as if it had run and found nothing.
exit=2
```

Assessed, not just reported: `OTR_DISPATCH_ONLY` is read only via inline
`env VAR=val python3 ...`/`env VAR=val bash ...` prefixes scoped to a
single test invocation in `run-gate-shape-tests.sh` and
`run-dispatcher-equivalence-tests.sh` — grepped the full tree; it is set
nowhere in `hooks.json`, any settings file, or any non-test script, so
the real production dispatch path (every actual PreToolUse call in a
live session) never sets it and this fix does not change that path's
behavior. The exposure is narrower than "any session" — it requires the
variable to leak into a shell's exported environment (e.g. a manual
`export OTR_DISPATCH_ONLY=...` left set after an ad hoc test run) before
it can block real tool calls — but F23's own fix, as written, does not
scope or unset the variable, so that exposure is real, not hypothetical,
and the record does not disclose it. This does not overturn the PR's
overall fix (fail-closed on a misconfigured test seam is defensible, and
strictly safer than the silent full-bypass it replaces), but the
record's claim that only one file's disposition changed is not accurate.

## Why

The proposal (`docs/issue-305/proposals/2026-08-25-execution-observation-verify-pr313.md`)
committed to re-deriving each of PR #313's central claims from actual
source and live execution rather than trusting its own narration, per
this role's purpose, and to running an after-proposal and a
before-landing warrant hunt around this role's own transitions. Every
re-derived claim came back matching: the diff scope, the 5-site python3
live-fire, the named acceptance gate, the full regression sweep, and one
additional finding (F11) spot-checked beyond the record's own pasted
evidence. Two gaps surfaced, neither changing the overall verdict that
PR #313's fixes are real and correctly targeted, but both correcting an
overstatement in the implementation record's own self-description:

- The operator-frozen constraint is not named as its own checked item in
  the implementation record, though independently assessing the diff
  against it (item 6 above) found no violation — a process gap, not a
  correctness defect.
- The before-landing warrant hunt (item 7 above) found the implementation
  record's claim "no mechanism was flipped from advisory to blocking or
  vice versa outside... facet-keyword-gate.sh" to be inaccurate: F23's
  fix also flips `pretooluse_dispatcher.py`'s handling of an unmatched
  `OTR_DISPATCH_ONLY` value from silent-allow to a session-wide deny.
  Independently assessed as a real but narrow-exposure regression (the
  variable is never set outside an inline, single-invocation `env`
  prefix in the test suite; it would need to leak into a shell's
  exported environment to affect a real session) and as a defensible
  design choice on its own terms (fail-closed on a misconfigured test
  seam, replacing a silent full bypass) — but a disclosure gap the
  record should have named.

## Upstream basis

- `docs/issue-301/reports/observability.md` (the 23-finding inventory
  this issue works from — 19 findings not covered by sibling issues #303
  or #304), as cited by the implementation record.
- Issue #305 body: acceptance gate `core/hooks/tests/run-gate-shape-tests.sh`
  byte-identical with python3 present; executed-live PATH-without-python3
  evidence per affected gate; the 2026-08-25 operator-frozen constraint.
- `docs/issue-305/reports/implementation.md` (commit `183e2d3`) and PR
  #313 (`gh pr view 313`), cross-checked against direct reads of
  `issue-305/implementation`'s actual source at the same commit.

## Open findings

- **(process, no code change)** The implementation record does not name
  the operator-frozen constraint (systemic scope / no added overhead / no
  new conflict-stall surfaces / no consumer-tree residue) as its own
  explicitly-checked item, even though issue #305's body requires it.
  Independently checked here (see `## What was done`, item 6): the diff
  satisfies the constraint. Flagged so a future record for this issue's
  pattern states the check explicitly rather than leaving it implicit.
- **(disclosure gap, out of this role's write set to fix)** Before-landing
  warrant hunt finding (`## What was done`, item 7; full hunt record at
  `docs/issue-305/reports/execution-observation/2026-08-25-hunt-execution-observation-verify-pr313.md`):
  `pretooluse_dispatcher.py`'s F23 fix turns any unmatched
  `OTR_DISPATCH_ONLY` value into a session-wide deny of every subsequent
  tool call, a second allow→deny disposition flip the implementation
  record does not disclose alongside the one it does name
  (`facet-keyword-gate.sh`'s demotion). Independently confirmed live and
  independently assessed: real but narrow exposure (the variable is only
  ever set via an inline, single-invocation `env` prefix in the test
  suite — never in `hooks.json`, settings, or any non-test script — so it
  would need to leak into a shell's persistent exported environment to
  reach a real session), and a defensible design choice standing alone
  (fail-closed on a misconfigured test-only seam, replacing a silent full
  gate bypass). Not fixed here: out of this role's write set
  (`docs/issue-305/reports/execution-observation.md` only per this
  phase's approved proposal) and out of scope for this role generally
  (re-opening PR #313's fix approach belongs to issue #305/PR #313, not
  to this observation) — reported for a human or a follow-up issue to
  decide whether `OTR_DISPATCH_ONLY` should be explicitly scoped/unset
  rather than left to leak.
- All 19 target findings (F1-F14, F16, F18, F21, F22, F23) are otherwise
  present at their claimed locations, close the described silent failure,
  and are backed by independently-reproduced live-fire evidence or an
  independently-rerun existing test suite showing no regression.

## Next steps

None — loop_state: landed.
