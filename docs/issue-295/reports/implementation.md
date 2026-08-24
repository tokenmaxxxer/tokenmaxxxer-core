---
issue: 295
role: implementation
loop_state: landed
upstream:
  - path: docs/issue-295 (issue #295 itself — no phase-1 proposal exists; contract v3 s19a build-now bypass, CORE_BUILD_NOW=1)
    sha: same-commit
  - path: on-the-record/hooks/approval-gate.sh (sibling repo, diffed against core's copy to confirm the two never shared this closed-issue precondition)
    sha: 4874de73fb6419735c2b28b8dd5846d5deb20f27
commit_sha: same-commit
code_under_review: same-commit
type: fix
breaking: false
verdict: pass
---

# issue-295 — implementation record

## What was done

`core/hooks/approval-gate.sh`'s closed-issue precondition (contract v3
s19/s10's "revocation-by-closing guarantee") denied phase-2 writes
unconditionally on any non-OPEN issue, for every role — including
`execution-observation` and `conformance-review`, whose whole purpose is
to keep verifying an implementation role's already-landed work AFTER
that role's own PR merges and auto-closes the shared issue via a
`Closes #<n>` trailer. Added a narrow, causally-grounded exemption:
before the closed-issue deny fires, if `role` is exactly
`execution-observation` or `conformance-review`, the gate now asks GitHub
directly whether any pull request in the issue's own
`closedByPullRequestsReferences` is a **MERGED** PR on that issue's own
`issue-<n>/implementation` branch (one extra `gh pr view <number> --json
headRefName,state` call per candidate). Only then does it skip the
closed-issue deny and fall through to the normal Approve-signal check
(PR review APPROVED, or an exact `APPROVE issue-<n>/<role>` issue
comment from a `docs/specs/approvers.md`-listed account) — the exemption
never grants approval by itself, it only un-blocks the precondition.
Every other case is unchanged: non-observer roles still deny
unconditionally on any closed issue, and observer roles still deny when
the closer check finds no matching merged implementation PR (a human's
manual close-to-revoke, or a `NOT_PLANNED` reject).

Also extended `core/hooks/tests/run-approval-gate-tests.sh`'s `stub_gh`
to model `closedByPullRequestsReferences` and the new `gh pr view
<number> --json headRefName,state` call shape (told apart from the
existing branch-review lookup by whether `headRefName` appears in the
stub's own argv), and added 6 regression cases (see `## How you will
know it worked`).

Files touched: `core/hooks/approval-gate.sh`,
`core/hooks/tests/run-approval-gate-tests.sh`,
`docs/issue-295/reports/implementation.md` (this record),
`docs/issue-295/reports/implementation/2026-08-24-hunt-issue-295-approval-gate-observer-exemption.md`
(warrant-hunt record).

## Why

Investigated per the issue's own instructions: diffed core's
`approval-gate.sh` against the local clone of the sibling `on-the-record`
repo (`/home/jwjung/tokenmaxxxer/on-the-record`, commit `4874de7`). The
two files have completely diverged (different generations of the same
hook, not a copy-paste-able shared file) — on-the-record's
`approval-gate.sh` has **no** issue-open/closed precondition at all; it
checks only for a matching `APPROVE issue-<n>/<role>` comment (or a live
delegation citation) from a `docs/specs/approvers.md`-listed account,
regardless of the issue's state. That is *why* on-the-record's observer
roles land phase-2 without friction: its gate never blocks on closed
state to begin with. Core's stricter behavior is real, intentional
design (contract v3 s19, `issue-189` decision 1's revocation-by-closing
guarantee) — not drift from a shared original — so the fix is not "port
on-the-record's gate" (that would remove the guarantee entirely, for
every role) but "teach core's gate to recognize the one case the
guarantee was never meant to cover": an issue auto-closing as the
*expected side effect* of the very role whose work an observer is meant
to verify.

`stateReason == "COMPLETED"` was the first, simpler design (matches the
issue's own observed evidence: issues #288/#290/#292-before-reopen all
show `COMPLETED` on their merge-close). A before-landing warrant-hunter
dispatch (stance 0, "assume the gate just touched is bypassable — find
the bypass") reproduced a real gap in that design against the *real*
hook: GitHub sets the identical `stateReason: COMPLETED` when a human
manually clicks "Close as completed" on the issue page as a deliberate
revocation act — indistinguishable from the merge-close shape via
`stateReason` alone — so a human's own revocation-by-closing act would
silently fail to block an observer role whenever a standing PR review or
APPROVE comment already existed, defeating the gate's own stated
"regardless of any standing PR review or APPROVE comment" guarantee for
exactly those two roles. Switched the discriminator to the causal
signal GitHub actually maintains for "which PR closed this issue" —
`closedByPullRequestsReferences` plus a `MERGED`+branch-name check on
each candidate — verified empirically against this repo's own real
issues (see the hunt record's "Resolved" section) rather than assumed
from documentation alone.

## Upstream basis

- Issue #295 itself (github.com/tokenmaxxxer/tokenmaxxxer-core#295) —
  the requirement, including its own live finding (issue #292/PR #293/PR
  #294) used as the real-world reproduction case throughout.
- `/home/jwjung/tokenmaxxxer/on-the-record/on-the-record/hooks/approval-gate.sh`
  at commit `4874de73fb6419735c2b28b8dd5846d5deb20f27` — the sibling
  repo's copy, diffed to confirm the two never shared this precondition
  (design divergence, not drift).
- `core/hooks/approval-gate.sh` and `core/hooks/tests/run-approval-gate-tests.sh`
  as they stood at `e3ff185` (this branch's parent commit) before this
  change.
- `docs/issue-295/reports/implementation/2026-08-24-hunt-issue-295-approval-gate-observer-exemption.md`
  — the warrant-hunt record (finding + resolution) produced and
  consumed within this same session.

## Open findings

None. The one finding raised during this session (warrant-hunt,
`stateReason`-only discriminator bypassable by a human's manual
"close as completed") was fixed in this same commit — see
`## What did not work` and the hunt record's `### Resolved` section.

## Next steps

None — `loop_state: landed` (terminal for `coding-record`, contract v3
§2). If a future session finds `closedByPullRequestsReferences`'s
reopen/re-close semantics behave differently from what this session
empirically observed in this repo (issues #288, #290, #292), that would
warrant a fresh look, but nothing here is currently open.

## What did not work

- First attempt keyed the exemption purely on `issue_state_reason ==
  "COMPLETED"` (role in `{execution-observation, conformance-review}`
  plus that one field). A before-landing warrant-hunter dispatch (stance
  0) reproduced a real bypass against the actual hook: GitHub sets the
  same `stateReason: COMPLETED` for a human's deliberate "Close as
  completed" as for an auto-close-via-merged-PR, so a human's own
  revocation-by-closing act would silently fail to block an observer
  role whenever a standing PR review or APPROVE comment already existed.
  Replaced the discriminator with a `closedByPullRequestsReferences` +
  "is there a MERGED PR on this issue's own `issue-<n>/implementation`
  branch" check, which is causally precise instead of merely correlated,
  and added a regression test (`observer-completed-close-no-merge-closer`)
  reproducing the hunter's exact scenario as a permanent deny case.
- The `gh-json-field-schema` self-check (validates every requested
  `--json` field name against `gh`'s real schema) initially failed after
  adding `closedByPullRequestsReferences`: the field list was split
  across two adjacent Python string literals
  (`"state,comments,stateReason,"` + `"closedByPullRequestsReferences"`),
  which the test's own field-extraction regex (correctly) does not
  follow across a string-literal boundary, producing a spurious empty
  field name. Not a real behavior bug — `subprocess.run` concatenates
  adjacent literals identically either way — but merged the two literals
  onto one line so the test's regex reads the whole field list.

## Doc placement

- `docs/specs/` — not touched; no system-design change, so no
  regeneration of `docs/specs/reconciled-index.md` was needed.
- `docs/decisions/` — not touched; the design reasoning (why
  `closedByPullRequestsReferences` over `stateReason`) lives in this
  record's `## Why` and the hunt record instead, since it is scoped
  entirely to this one hook, not a repo-wide decision.
- `docs/reports/` (standing) — not touched; this issue's own
  `docs/issue-295/reports/` tree is where the record and hunt record
  landed.
- `docs/issue-295/reports/implementation.md` — this record (filled the
  pre-written skeleton per issue #2135; frontmatter widened beyond the
  skeleton's own `commit_sha`/no-`breaking` shape to match what
  `record-shape-gate.sh` actually enforces: `code_under_review:`,
  `breaking:` added).
- `docs/issue-295/reports/implementation/2026-08-24-hunt-issue-295-approval-gate-observer-exemption.md`
  — the one before-landing warrant-hunter record (no after-proposal
  dispatch: build-now bypass skips the phase-1 proposal round entirely,
  so there was no proposal transition to hunt at).

## Executed acceptance evidence

Full approval-gate suite, `CORE_BUILD_NOW` explicitly unset so this
session's own build-now env doesn't short-circuit the tests under test
(this repo's `core/hooks/tests/run-all.sh` does the same):

```
$ env -u CORE_BUILD_NOW bash core/hooks/tests/run-approval-gate-tests.sh
...
ok     observer-completed-close-with-comment allow
ok     observer-completed-close-conformance-review allow
ok     observer-completed-close-no-approval deny
ok     observer-not-planned-close-with-comment deny
ok     non-observer-completed-close-with-comment deny
ok     observer-completed-close-no-merge-closer deny
...
ok     gh-json-field-schema               ok

== 66 passed, 0 failed ==
```

Full repo gate suite (`run-all.sh`, all sibling gates + plugins),
confirming no cross-gate regression:

```
$ env -u CORE_BUILD_NOW bash core/hooks/tests/run-all.sh
...
ok    approval-gate.sh
ok    tests/run-approval-gate-tests.sh
...
ALL OK
```

(A standalone `bash core/hooks/tests/run-approval-gate-tests.sh` run
*without* `env -u CORE_BUILD_NOW` — i.e. inheriting this session's own
`CORE_BUILD_NOW=1` — shows 2 unrelated pre-existing failures,
`execute-without-remote` and `checkpoint-refusal-names-await-approval`.
Confirmed via `git stash` against the pre-change tree that both fail
identically before this change too: two of the test harness's own helper
functions (`noremote()`, `checkpoint_wording()`) don't explicitly reset
`CORE_BUILD_NOW` the way `run()` does, so they leak whatever
`CORE_BUILD_NOW` the *invoking* shell happens to carry. Not introduced by
this change and out of this issue's scope; `run-all.sh` itself already
runs with a clean environment and shows 0 failures.)

## Acceptance criteria (from the issue)

- "An observer role's phase-2 record write succeeds on an issue that
  auto-closed via the implementation PR's Closes trailer, without manual
  reopening" — `observer-completed-close-with-comment` /
  `-conformance-review` (allow).
- "Existing approval-gate closed-issue-blocks-non-observer-roles behavior
  unchanged (regression guard)" — `closed-issue-with-comment`,
  `closed-issue-with-pr-review` (pre-existing, still deny),
  `non-observer-completed-close-with-comment` (new, still deny for
  `coding` on the identical merge-closed shape).
- "Executed acceptance evidence in the record" — see
  `## Executed acceptance evidence` above.

skill-verdict: other mounted skills: not triggered — single-file hook
logic change plus its matching regression tests; no coupling/cohesion
threshold, no GoF pattern decision, no data-structure/algorithm choice,
and not a multi-module structural build the blueprint skill's own
classify step would accept (checked against each skill's trigger
description before deciding, per the invoke-before-apply obligation —
none matched closely enough to warrant loading a skill body for a
15-line conditional-logic fix to one existing hook).
