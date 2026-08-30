---
issue: 384
role: technical-writing-structure-comprehension-e0bd9d2c
author: technical-writing-structure-comprehension-e0bd9d2c
skills: technical-writing-structure-comprehension (skill-repository(c05de12))
verifies_subject: false  # flip to true only if this record is an independent verification of this subject's own deliverable -- see docs/handbooks/observer-verification.md
code_under_review: `core/directive/session-protocol-build-now.md`, `core/hooks/directive.sh`, `warrant/hooks/state.sh`
loop_state: landed
type: fix
breaking: false
verdict: fixed
upstream:
  - path: core/directive/session-protocol-build-now.md
    sha: same-commit
  - path: core/hooks/directive.sh
    sha: same-commit
  - path: warrant/hooks/state.sh
    sha: same-commit
---

# issue-384 — technical-writing-structure-comprehension-e0bd9d2c record

## What was done

Responded to the CHANGES comment JiwonJung94 posted on PR #386 at
2026-08-30T06:57:48Z — checked: `gh pr view 386 --json comments` —
result: one comment, id `IC_kwDOTk3ZJs8AAAABRd_bbg`, one blocking
finding, scope "one thing."

The finding: `core/directive/session-protocol-build-now.md` — a new
file added by PR #386 — reintroduced the retired role axis. It did so
in the exact `tokenmaxxxer-core#366` shape: the variable is `skill`,
the label is `role` (`for role ${skill}`). Fix, per the comment: write the
build-now variant in the vocabulary the code uses — `skill` where the
value is a skill, `issue-<n>/<skill>` for the branch,
`docs/issue-<n>/reports/<skill>.md` for the record — and do not touch
`session-protocol.md` itself.

Checked out PR #386's actual branch first — checked: `gh pr view 386
--json headRefName` — result:
`issue-384/diagnose-first+technical-writing-minimalism-scoping-bceafc9c`,
not this session's own spawn branch — and fetched/checked it out
before editing.

Renamed every occurrence the standing-invariant check catches, across
all three non-docs files the diff touches, not only the one the
comment quoted:

- `core/directive/session-protocol-build-now.md`: `for role '<role>'`
  → `for skill '<skill>'`; `role-handoff contract v3` → `skill-handoff
  contract v3`; `issue-<n>/<role>` → `issue-<n>/<skill>` (branch,
  three call sites); `docs/issue-<n>/reports/<role>.md` → `.../
  <skill>.md`; `never share a branch with another role` → `...another
  skill`; `never another role's` → `never another skill's`.
- `core/hooks/directive.sh`: the build-now heredoc's own preview line
  — `Interaction protocol for role ${skill} (role-handoff contract
  v3)...` → `for skill ${skill} (skill-handoff contract v3)...`. (Its
  branch/record-path lines already read `issue-<n>/${skill}` and
  `docs/issue-<n>/reports/${skill}.md` — variable-substituted, no
  `role` label — so only this one line needed the change.)
- `warrant/hooks/state.sh`: a code comment introduced by the same PR,
  `# a role session only ever writes its own proposals under` → `# a
  skill session...`. Not quoted in the CHANGES comment's illustrative
  block, but it is one of the 8 lines the comment's own grep command
  counts (see Acceptance evidence #1), so leaving it unrenamed would
  have left the re-run count non-zero.

Did not touch `core/directive/session-protocol.md` — unedited, per the
comment's explicit instruction, so the vocabulary difference between
the two files reads as intended.

## Why

The comment names the reason directly. This is a new file. The
retirement's standing invariant is that the count of `role`-axis
occurrences does not increase. This file is injected into every
spawned session — the most-read text in the system — so an 8-line
reintroduction here is the largest single one of the night.

`for role ${skill}` is not a stylistic quibble. It is the literal
shape of `tokenmaxxxer-core#366`'s defect: a variable named for the
current vocabulary (`skill`), labeled with the word the system retired
(`role`). The session-protocol.md source carries that vocabulary
because it predates the retirement. A file created today does not
need to inherit it.

Renaming all 8 occurrences — not just the 5 the comment's illustrative
code block quoted — rather than only the ones explicitly shown: the
comment's own re-verification instruction is the exact grep count, not
"fix the quoted lines." A partial fix that left the `state.sh` comment
or the `directive.sh` preview line untouched would still fail the
re-run the comment asks for.

## What did not work

Nothing — this was a same-day, single-pass mechanical rename inside
already-reviewed prose; no dead end to report.

## Upstream basis

- PR #386 (https://github.com/tokenmaxxxer/tokenmaxxxer-core/pull/386),
  branch `issue-384/diagnose-first+technical-writing-minimalism-scoping-bceafc9c`,
  commit `77d6ca5` (the round this CHANGES comment was posted against).
- The CHANGES comment quoted throughout this record. checked: `gh pr
  view 386 --json comments` — result: comment id
  `IC_kwDOTk3ZJs8AAAABRd_bbg`, author JiwonJung94, `2026-08-30T06:57:48Z`.

## Open findings

None.

## Next steps

`loop_state: landed` — this round's fix is complete: committed on PR
#386's branch, all four standing invariants re-derived below, nothing
else outstanding. No further action implied for this role's session.

## Acceptance evidence

1. **No return of the retired role axis (the subject of this round).**
   checked: `git diff origin/main -- . ':!docs' | grep '^+' | grep -v
   '^+++' | grep -icE '\brole\b|역할'` (the comment's own re-run
   instruction, working tree included via the merge-base form since
   this round's fix was still uncommitted when first measured) —
   result: `8` before this round's edits, `0` after. checked (same
   command, `origin/main...HEAD` form, after committing this round's
   fix): `0`.
2. **No new bug — failing-test-name sets vs `origin/main`, as sets of
   names, not counts.** Compared via a fresh detached `git worktree`
   at PR #386's pre-fix commit `77d6ca5` and the same worktree with
   this round's diff applied (`git apply`), to isolate this session's
   own working-directory environment noise from the actual repo
   content:
   - `bash core/hooks/tests/run-board-gate-tests.sh` — derived: run on
     both. Both: `159 passed, 2 failed` — `feasibility-spikes`,
     `ops-postmortems`. Identical set, pre-existing on `origin/main`
     too (unrelated to `core/hooks/directive.sh` or `session-protocol-
     build-now.md`, neither of which that suite exercises).
   - `bash core/hooks/tests/run-approval-gate-tests.sh` — derived: run
     on both. Both: `65 passed, 2 failed` —
     `checkpoint-refusal-names-await-approval`, `execute-without-remote`.
     Identical set.
   - `bash core/hooks/tests/run-dispatcher-equivalence-tests.sh` —
     derived: run on both. Both: `24 passed, 1 failed` — `approval-
     gate: execution write, no approvers.md -> deny`. Identical set.
   - `bash core/hooks/tests/run-ups-diet-tests.sh` — derived: run on
     both inside a clean detached worktree (isolates this session's
     own working directory, which reads a `CLAUDE_PLUGIN_ROOT_CORE`-
     adjacent path this repo does not control and adds ~600 bytes of
     unrelated content to 3 of the 7 measured sibling-plugin hooks
     regardless of this round's diff — confirmed by running the
     pre-fix commit `77d6ca5` unmodified in that same working
     directory and getting the identical `FAIL combined UPS payload`
     line). Both (clean worktree): `36 passed, 0 failed`.
   - `bash core/hooks/tests/run-directive-shape-tests.sh` — derived:
     `31 passed, 0 failed`, unchanged from PR #386's own stated result.
   - `python3 -m pytest -q test/test_directive_injection.py` —
     derived: `6 passed`, unchanged from PR #386's own stated result.
   No new failing test name on either side; the two failing-set
   differences that exist (`run-board-gate-tests.sh`,
   `run-approval-gate-tests.sh`, `run-dispatcher-equivalence-tests.sh`)
   are byte-identical before and after this round's rename, and
   pre-existing per PR #386's own record.
3. **No overhead increase.** derived: `CLAUDE_SKILL=implementation
   CORE_BUILD_NOW=1 TOKENMAXXXER_SPAWNED=1 bash core/hooks/directive.sh
   </dev/null 2>/dev/null | wc -c`, run in a clean detached worktree at
   commit `77d6ca5` before and after applying this round's diff —
   result: `8212` bytes before, `8223` bytes after — `+11` bytes.
   `skill` (5 chars) and `skill-handoff` (13 chars) are each one
   character longer than `role` (4) / `role-handoff` (12). The
   increase is exactly that literal substitution, repeated across the
   renamed occurrences — not new content. This is a real, small
   increase, reported as such rather than rounded to "no change." It
   does not affect PR #386's own 630-token build-now-vs-two-phase
   savings measurement, which compares the build-now path against the
   two-phase path, not against its own pre-rename byte count.
4. **Monitor/watch machinery (`run-fleet-scan-tests.sh` /
   `run-fleet-scan.sh`) unbroken, not quieter.** checked:
   `run-fleet-scan-tests.sh` — result: `pass=26 fail=1`, unchanged
   (this suite does not exercise `core/hooks/directive.sh` or
   `core/directive/session-protocol-build-now.md`). checked:
   `run-fleet-scan.sh` — result: `total=44 clean=8 with-findings=36
   clone-failed=0 blocked=0`, unchanged — same pre-existing
   cross-rulebook findings, none newly silent.

skill-verdict: technical-writing-structure-comprehension — applied:
invoked; used to keep this record's `What was done`/`Why` paragraphs
to one claim per sentence when listing the 8 renamed occurrences and
the reason each mattered, rather than one long sentence enumerating
all three files and both defect shapes (label-word vs. templated
placeholder) at once.
other mounted/configured skills: not triggered — work-in-english (this
record, the commit, and all repo-bound text are already English
throughout), verify-finding-record / conformance-review-finding-record
/ technical-feasibility-verdict-and-timebox-selection (no reproduction
attempt, conformance verdict, or feasibility spike was in scope — this
was a direct, reviewer-specified wording fix), model-routing (a single
mechanical rename plus its own re-derivation did not warrant
delegating any piece to a different model tier), and adversarial-review
(the reviewing session in this loop is JiwonJung94's own CHANGES
comment, not a fresh independent-evaluator pass) were reviewed and
judged not-applicable to this task.
