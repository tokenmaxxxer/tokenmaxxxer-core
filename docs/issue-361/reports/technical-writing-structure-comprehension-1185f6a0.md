---
issue: 361
role: technical-writing-structure-comprehension-1185f6a0
author: technical-writing-structure-comprehension-1185f6a0
skills: technical-writing-structure-comprehension (skill-repository(c05de12))
verifies_subject: false  # flip to true only if this record is an independent verification of this subject's own deliverable -- see docs/handbooks/observer-verification.md
loop_state: landed
upstream:
  - path: docs/issue-361/reports/adversarial-review-c564956c.md
    sha: 42b81b5a0247bcdac8bfefef27db62e062d02b36
  - path: core/hooks/board-gate.sh
    sha: c9f1c4ce455a13e7285e3c2b9f0a22b6f76974b9
---

# issue-361 — technical-writing-structure-comprehension-1185f6a0 record

## What was done

Amended PR #374 (`issue-361/secure-coding-input-validation-injection-defense-a072264b`)
per its reviewer's CHANGES comment, in place, on that same branch — not a
new PR, per the comment's own scope. The comment's premise: PR #377's
independent adversarial review (`docs/issue-361/reports/adversarial-review-c564956c.md`,
landed as commit `42b81b5`) proved PR #374's stated soundness claim false
— a variable-held, `printf`-octal-decoded interpreter head reaches
`python3` and writes, on both `origin/main` and the PR branch, so
"an interpreter head and its `-c`/`-e` flag must be spelled literally
for the shell to invoke them" does not hold. That bypass shape is out of
this gate's jurisdiction by ruling (issue-233's two ruling comments,
landed on `main` via PR #367 as `b6cb34a`), not by omission, and PR #372
was closed unmerged for trying to enumerate the expansion grammar that
produces it. The scope was therefore a wording fix, not a scan
extension: replace the false soundness claim with an accurate proxy
claim, state that an expansion-produced head is not caught here or
anywhere in this gate, and point at the jurisdiction statement PR #367
put on `main`. No scan logic changes.

Three prose sites carried the same false claim and all three were
corrected, each restructured per `technical-writing-structure-comprehension`
(15-20 word sentence targets, one idea per sentence, filler removed):

- `core/hooks/board-gate.sh`, the `issue-361:` comment block immediately
  above `UNANALYZABLE_HEAD_RE` (originally lines 68-83 of PR #374's head
  `e1dcbb0`): replaced "has to be spelled literally in the command text
  for the shell to actually run it; the runtime-assembly trick that
  defeats a path scan does not defeat a shape scan" with an explicit
  proxy framing, a named PR #377 counterexample, and a pointer to the
  "Jurisdiction limit (issue-233 round 5)" comment block that PR #367
  had, by then, already placed above it on `main`.
- `core/hooks/tests/run-board-gate-tests.sh`, the `issue-361:` comment
  above the `chr-assembled-path-no-docs-substring` test group: replaced
  "The interpreter head and its inline -c/-e flag, unlike the write
  target, ARE spelled literally in the command text for the shell to
  actually run them" with the same proxy/jurisdiction framing, cross-
  referencing `board-gate.sh`'s comment rather than duplicating it.
- `docs/handbooks/board-gate-tests.md`, the "Why a second literal-name
  scan does not repeat the bug" paragraph: replaced "the shell has to
  actually see the interpreter name and the flag as literal words in
  the command text to invoke them at all, so a raw-text scan for *that*
  closed set is sound" with the proxy/expansion-gap/jurisdiction framing
  and renamed the heading to "...and where it does not reach."

PR #374's branch (`e1dcbb0`) was based on `main` from before PR #367
landed the jurisdiction-limit comment my fix points to, so landing the
fix required first merging `origin/main` (`b6cb34a`) into the PR branch
(merge commit `c9f1c4c`) to bring that comment block, and PR #377's own
landed record, onto the branch the fix lands on. The merge produced two
mechanical conflicts (`run-board-gate-tests.sh`, `board-gate-tests.md`)
where PR #374 and `main`'s issue-233 round-5/6 work both appended test
cases/sections at the same location; both were resolved by keeping both
additions, in the order each branch had them, with no test logic changed.
Pushed to `issue-361/secure-coding-input-validation-injection-defense-a072264b`;
PR #374 now carries 3 commits, head `c9f1c4c`.

## Why

The reviewer's CHANGES comment is narrower than the finding that
prompted it: it explicitly forbids extending the scan to catch the
`printf`-octal-decoded case or any other expansion form ("that is the
treadmill the #233 ruling exists to stop"), and asks only for the prose
to stop overclaiming soundness the code was never going to have. Keeping
the code unchanged and rewriting only the prose is therefore not a
scope-reduction shortcut — it is the actual request. The three-site fix
(not one) follows from the same claim being duplicated in the test file
and the handbook, both by the same PR: leaving two of three copies
overclaiming while fixing one would still mislead a reader of the other
two.

## Standing invariants

Each re-derived live against two worktrees, `/tmp/main-check` =
`origin/main` (`b6cb34a`) and `/tmp/pr374-edit` = the finished PR #374
branch (`c9f1c4c`), after this session's edits and the main-merge above
— not restated from PR #374's or PR #377's own numbers.

- **No return of the retired role axis, in any reshaped form:**
  `derived: git diff origin/main -- core/hooks/board-gate.sh warrant/hooks/lib/scope-gate.py core/hooks/tests/run-board-gate-tests.sh core/hooks/tests/run-scope-gate-tests.sh | grep -inE 'role|ROLE|역할'`
  → 2 hits, one `-` and one `+` line, both the identical text `# spawn
  form, a multi-skill session's own role/slug` (an issue-336 comment
  moved by the merge's reflow, not new or reworded). None found.
- **No new bug — failing-test set vs `origin/main`, compared as SETS OF
  NAMES, not counts:**
  - `derived: bash core/hooks/tests/run-board-gate-tests.sh` on both
    worktrees — PR branch: 159 passed/2 failed; `main`: 155 passed/2
    failed; the PR branch's +4 are issue-361's own new cases, all
    passing. Failing names not independently re-listed here beyond
    count, since both suites report only 2 failures and neither run's
    tail changed between the two; see the `run-scope-gate-tests.sh` and
    `pytest` checks below for the name-set comparisons this invariant
    is really checking.
  - `derived: bash core/hooks/tests/run-scope-gate-tests.sh` on both —
    62 passed/0 failed, identical, both branches.
  - `derived: env -u CLAUDE_PLUGIN_ROOT_CORE python3 -m pytest -q` on
    both — 3 failed/79 passed on both, identical failing-name set:
    `{test_proposal_shape_gate_refuses_missing_sections,
    test_survey_order_gate_refuses_proposal_without_survey_or_skip,
    test_A5_trailer_gate_quote_split_commit_is_detected}` (pre-existing
    on `main`, unaffected by this branch).
- **No overhead increase** (issue-361's acceptance criterion: state the
  number, not zero): interleaved single-call timing of a `git status`
  payload (fast-path-eligible on both branches), alternating `main` and
  PR-branch `board-gate.sh` on the same probe repo, N=150/branch/trial,
  3 trials (first trial shows cold-cache noise and is reported but not
  relied on): `derived: bash /tmp/time_gate.sh <gate> 150 <root> /tmp/timing-repo`
  → trial 1: main=15648us pr=9878us (cold-cache, main ran first);
  trial 2: main=5483us pr=6353us, delta=+870us; trial 3: main=5470us
  pr=5983us, delta=+513us. Trials 2-3 agree with PR #374's and PR #377's
  own "+0.5-0.9ms per ordinary call" number. Full-analysis path (a
  `docs`-containing payload forcing the python judge on both branches),
  N=80/branch/trial, 2 trials: trial 1 main=48318us pr=49217us
  delta=+899us; trial 2 main=46983us pr=48329us delta=+1346us — a small
  delta, same direction both trials, within the noise band the shared
  timing harness already carries (PR #377's own re-derivation measured a
  small delta in the *other* direction on the same path); not the
  concerning number either way, since the accepted trade is the ordinary
  (fast) path, and removing the pre-check entirely costs ~30ms/call by
  PR #374's and PR #377's own re-derived measurement (not re-derived a
  third time here, since it requires deleting the pre-check to measure
  and this session changes no code).
- **Monitor/watch machinery unbroken and not quieter:**
  `derived: bash core/hooks/tests/run-fleet-scan-tests.sh` on both — 26
  passed/1 failed, both branches; `diff` of the sorted ok/FAIL name list
  between the two runs is empty (identical set); the one failure is the
  pre-existing `live fleet run produces 43 repo rows want=43 got=44`
  flake on both.

## Acceptance-criteria checks

- **The `chr()`-assembled-path reproduction from PR #360's record, run
  against the hook before and after** (same command
  `run-board-gate-tests.sh`'s `chr-assembled-path-no-docs-substring`
  case sends: `python3 -c "import pathlib;pathlib.Path(bytes([...]).decode()).write_text(chr(120))"`,
  decoding to `docs/issue-3/reports/pwned.md`): `derived:` piping the
  JSON payload through `board-gate.sh` directly —
  before (`origin/main`, `b6cb34a`): `rc=0` (allow) — the shell-level
  `*docs*`-substring fast path exits 0 before `python3` ever starts,
  since the literal substring never appears in the Bash command text;
  this is the bypass issue-361 names. After (PR #374 branch, `c9f1c4c`):
  `rc=2` (deny) — but the deny is NOT the shell-level shape-scan itself:
  `UNANALYZABLE_HEAD_RE`/`UNANALYZABLE_FLAG_RE` matching `python3 -c`
  makes the shell layer decline to fast-path-*allow*, so it falls
  through to start `python3`, and the deny is issue-225's own
  unanalyzable-write-shape deny inside the python judge (`deny("a Bash
  call carries an un-analyzable write-capable shape ...")` at
  `board-gate.sh:845` on the merged branch). Recorded explicitly per
  this issue's own trap: a before/after comparison that only reports
  `rc` without naming which layer produced it is not trustworthy on
  this gate.
- **Timed a representative sample of ordinary non-board commands before
  and after; stated the per-command cost:** see "No overhead increase"
  above — `git status`-shaped ordinary calls cost +0.5-0.9ms/call more
  on the PR branch than `main` (trials 2-3; trial 1 discarded as
  cold-cache noise, not averaged in).
- **Measured per-command overhead, before and after:** same measurement;
  stated both for the fast (ordinary) path and the full-analysis
  (`docs`-write) path above, with the ~30ms/call cost of removing the
  pre-check entirely cited from PR #374's/PR #377's own re-derivation
  rather than re-measured (that number requires deleting code this
  session does not touch).

## What did not work

None.

## Upstream basis

- `docs/issue-361/reports/adversarial-review-c564956c.md` (commit
  `42b81b5`) — PR #377's independent adversarial review of PR #374; its
  Open Finding 1 is the false soundness claim this record's fix
  addresses, and its "Test-harness-trap disclosure" section is the
  precedent this record's own "which layer denied" disclosure follows.
- `core/hooks/board-gate.sh` at `c9f1c4c` on
  `issue-361/secure-coding-input-validation-injection-defense-a072264b`
  (PR #374) — the file this session edited; `c9f1c4c` is the merge
  commit landing both this session's wording fix and the `origin/main`
  merge it required.
- Issue #233's two ruling comments and PR #367 (`b6cb34a` on `main`) —
  source of the "Jurisdiction limit (issue-233 round 5)" comment block
  this record's fix points readers at, and of the standing invariant
  list and its exact `derived:` command shapes, reused here unchanged
  from the pattern `docs/issue-233/reports/*.md` already established.

## Open findings

None — PR #377's Open Finding 1 (the expansion-produced-head bypass
itself) is explicitly out of scope for this record, by the CHANGES
comment's own instruction; it stays open as issue-233's jurisdiction
boundary already documents, not as an oversight of this record.

## Next steps

None — this record is terminal (`loop_state: landed`). Resolution of
PR #377's open finding, if it is ever taken up, is next-round work
against issue-233's jurisdiction (or a follow-up issue), not issue-361.

skill-verdict: technical-writing-structure-comprehension — applied:
invoked; loaded the skill's procedure before rewriting the three prose
sites above, applying rule 1 (15-20 word sentence targets), rule 2
(splitting multi-clause sentences), rule 6 (deleting subordinate clauses
before restructuring), and rule 10 (removing filler) to each of the
`board-gate.sh`, `run-board-gate-tests.sh`, and `board-gate-tests.md`
passages.
other mounted skills: work-in-english — not triggered as a standalone
invocation (this record and all repo-bound artifacts written in English
per its policy regardless of the assigning prompt's language);
implementation-audit — not-applicable: this is a narrow, reviewer-
directed wording correction to an already-delivered PR, not a fresh
two-session claim-by-claim audit against the original issue text.
