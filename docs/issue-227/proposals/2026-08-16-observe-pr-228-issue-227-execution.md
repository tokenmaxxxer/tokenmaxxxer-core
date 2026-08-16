---
kind: proposal
subject: issue-227
produced_by: execution-observation
phase: 1
loop_state: proposed
observed_pr: 228
observed_role: implementation
upstream:
  - path: docs/issue-227/reports/execution-observation/survey.md
    sha: same-commit
  - path: docs/issue-227/reports/execution-observation/scout-brief.md
    sha: same-commit
---

files: `docs/issue-227/reports/execution-observation.md` (phase-2 record only)

# Proposal — independent observation of PR #228 (issue-227)

## What this proposal covers

Issue #227 asked the `implementation` role to close two residual
write-gate holes (`${IFS}` token-fusion fail-open, board-gate indirect
`tee`). That role delivered a single commit,
`1a2d393fdb3c4fd8ace77cf564026e09c5cead74`, on PR #228, which is
currently **OPEN, unmerged**, and carries an unresolved adversarial-review
PR comment asserting two blocking findings against the commit itself.
This role's job is to independently observe that execution — not to fix
either gate, not to re-run the reviewer's repro commands as an editing
action, and not to touch `core/hooks/board-gate.sh`,
`warrant/hooks/scope-gate.sh`, either test suite, or
`docs/issue-227/reports/implementation.md`.

This document states, before any judgment is formed, which verdict
levels the phase-2 record will address and what evidence settles each.
It renders no verdict, provisional or otherwise; verdict language belongs
to `docs/issue-227/reports/execution-observation.md` and appears there
only after a human `APPROVE issue-227/execution-observation`. The full
first-hand read list and the ten (survey) plus one (scout) open surfaces
are in `docs/issue-227/reports/execution-observation/survey.md` and
`.../scout-brief.md`; this proposal allocates them, it does not restate
them.

## Verdict levels to be checked, and the evidence for each

All **three** levels are addressed in the phase-2 record, even where one
turns out not to apply (written as "not applicable, because X").

### Level 1 — outcome (did PR #228 land what issue #227 asked)

Per the spec's recomputation rule (worst case among the step-level
results this record itself cites, not a standalone summary):

- **Requirement 1 (`${IFS}`/`$IFS` fail-open, both gates)** — the landed
  `IFS_TOKEN_RE` addition to `_is_unanalyzable_write_shape` in
  `core/hooks/board-gate.sh` and the new `UNANALYZABLE_WRITE_SHAPE`
  alternative in `warrant/hooks/scope-gate.sh` (both already read as diff
  this session), checked against the issue's direction line and its
  acceptance `check:` (both `python3${IFS}-c '...'` deny, legitimate
  `python3 -m pytest`/`grep|head`/`git diff` still allow) — **and**
  against survey open surface 4: whether the un-anchored regex
  (`\$\{?IFS\}?`, no `(?![A-Za-z0-9_])` boundary) denies a pure read like
  `cat "$IFSHOME/notes.md"`, per the reviewer's claim. This is checked by
  reading the landed pattern and reasoning about Python `re.search`
  matching (mode: `read`, on the pattern text), not by executing the
  gate — execution of the observed role's code is prohibited to this
  role regardless of outcome.
- **Requirement 2 (board-gate indirect-`tee`)** — the landed
  `tee`-with-no-visible-target branch, checked against the issue's repro
  (`echo docs/issue-3/reports/x.md | xargs tee`) and against the new
  regression-guard test `direct-tee-visible-target` (already read in the
  PR diff), both from the diff, not re-run.
- **Acceptance check line** — the observed record's own cited test
  counts (`119 passed, 0 failed`; `35 passed, 0 failed`; `ALL OK`),
  distinguished as `mode: asserted` (this role did not run those suites
  itself) unless this role independently confirms them by reading the
  suite files' pass/fail assertions structurally.
- **Empty-state line** ("unrestricted sessions ... byte-identical") —
  checked against the two `*-unrestricted-*` tests already visible in the
  diff (`ifs-fusion-unrestricted-session-unaffected`,
  `run_unrestricted allow ifs-fusion-unrestricted-session-unaffected`).
- **Blocking finding 1 (false positive)** and **blocking finding 2
  (surviving fusion spellings)** from the unresolved PR comment
  (<https://github.com/tokenmaxxxer/tokenmaxxxer-core/pull/228#issuecomment-5304788003>) —
  weighed as step-level facts about the artifact (see Level 3) that feed
  into the outcome recomputation: an outstanding, unaddressed blocking
  finding on an unmerged PR is not silently dropped from the outcome
  call merely because the observed role's own record predates it.
- **PR merge state** — `gh pr view 228 --json state,mergedAt` (already
  read: `OPEN`, `mergedAt: null`) is itself an outcome-relevant fact, not
  assumed away.

### Level 2 — trajectory (was the phase-1→phase-2 path sound, for the observed `implementation` role)

Three named checks, each pass/fail/not-applicable on its own line, per
this role's own governing directive:

- **scouted-when-required** — whether the observed role's own phase-1
  research is visible anywhere reachable this session (its survey/scout,
  if any, under `docs/issue-227/reports/implementation/` or folded into
  its record's "Upstream / basis" section, already partially read there:
  it cites `docs/issue-225/reports/implementation.md` and the #225
  proposal as basis).
- **surveyed-before-proposing** — whether a current-state survey or
  proposal document exists for the `implementation` role's own step, or
  whether the issue's `validity-consult-skip: trivial` /
  build-now-shaped single commit means no separate phase-1 artifact was
  produced — checked against what is actually reachable in the merged
  tree and the PR's file list, not assumed from the issue label alone
  (survey open surface 8).
- **approved-by-human** — the issue-level comment
  `APPROVE issue-227/implementation` (`JiwonJung94`, `2026-08-15T23:30:02Z`,
  already fetched verbatim), checked against contract v3 §19's
  single-account path (PR author `JiwonJung94` == approver
  `JiwonJung94`, both listed in `docs/specs/approvers.md`), against the
  ordering (approval `23:30:02Z` precedes PR creation `23:37:13Z`
  precedes the commit `23:37:01Z`... — the exact second-level ordering
  between commit-authoring and PR-creation timestamps is checked
  literally, not assumed monotonic), and stated as covering the
  *implementation* role specifically, not this role's own approval
  (which does not yet exist — see below).

This role's **own** trajectory (this phase-1 proposal preceding any
verdict language, produced before any `APPROVE
issue-227/execution-observation`) is a process fact about this session,
not a subject of the phase-2 verdict on the observed role — noted here
for completeness, not scored.

### Level 3 — step (which specific artifact, if any, is deficient)

Per-artifact, in this order:

1. **`core/hooks/board-gate.sh`'s `IFS_TOKEN_RE`** and
   **`warrant/hooks/scope-gate.sh`'s `\$\{?IFS\}?` alternative** — on
   blocking finding 1 (missing boundary, over-broad match on
   `IFS`-prefixed variable names). `assertedBy`: this role, `mode: read`
   on the pattern text itself; the reviewer's specific repro commands
   (`cat "$IFSHOME/notes.md"`) are `mode: asserted` unless traced by hand
   against the regex without executing the gate.
2. **The absence of command-substitution-fusion, variable-indirection,
   and `awk`/`gawk`/`ed`/`ex` coverage** — on blocking finding 2, checked
   against issue #227's own direction text (which names only the
   `$IFS` spelling) to settle whether this is an in-scope acceptance gap
   or an out-of-scope residual the record should have flagged for a
   follow-up issue rather than declaring `Open findings: None`.
3. **`docs/issue-227/reports/implementation.md`'s `Open findings: None`
   line** — against findings 1 and 2 above, and against the fact that the
   record was committed before the reviewing comment existed
   (`23:37:01Z` vs. `23:45:35Z`) — whether `None` was accurate *at
   commit time* (a timing fact, not a defect) versus whether it remains
   accurate *now*, with the PR still open and no follow-up commit.
4. **Test-evidence citations in the record** (`119 passed`, `35 passed`,
   `ALL OK`) — cross-checked against the actual new-test names visible in
   the diff (four board-gate tests, two scope-gate tests) for
   consistency, not re-run.

## Constraints this role binds itself to

- No re-execution of `board-gate.sh`, `scope-gate.sh`, or either test
  suite this session — all Level-1/2/3 evidence above is read from
  already-landed diff/commit/comment text.
- No edit to `core/hooks/board-gate.sh`, `warrant/hooks/scope-gate.sh`,
  either test file, `docs/handbooks/board-gate-tests.md`, or
  `docs/issue-227/reports/implementation.md` — findings return only in
  this role's own record.
- No issue filed by this role. A confirmed deficiency (if any) is written
  into the phase-2 record for the human to act on.
- Every verdict-bearing sentence in the phase-2 record names its source
  (commit SHA, file:line, or PR comment URL) directly adjacent, with an
  explicit `mode:` (`read`/`command`/`asserted`) per claim.
