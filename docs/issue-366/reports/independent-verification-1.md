---
issue: 366
role: independent-verification-1
author: independent-verification-1
verifies_subject: true
loop_state: landed
upstream:
  - path: PR #389 (tokenmaxxxer/tokenmaxxxer-core), "issue-366: replace retired 'role' noun with 'skill' in gate denial messages", branch issue-366/technical-writing-structure-comprehension-2b15240c
    sha: d3adeed7ee818b37dd7e6d5150daa79a8dd7e3ea
  - path: docs/issue-366/reports/technical-writing-structure-comprehension-2b15240c.md
    sha: d3adeed7ee818b37dd7e6d5150daa79a8dd7e3ea
---

# issue-366 — independent-verification-1 record

## What was done

Independent, structurally separate re-verification of PR #389 (commit
`d3adeed` on `issue-366/technical-writing-structure-comprehension-2b15240c`,
parent `8c7cc8d` = current `origin/main`), which replaces the retired
`role` noun with `skill` in gate denial messages across
`core/hooks/{board-gate,approval-gate,gh-guard,ordering-gate,record-fields-gate}.sh`.
Ran all three acceptance checks myself, from scratch, using disposable
git worktrees of `origin/main` (before) and the PR head (after) rather
than trusting the PR's own record — plus an own-authored population
search that only converged with the PR's methodology after I caught and
fixed a flaw in my first attempt (detailed below).

**Check 1 — live trigger of the board-gate denial, before/after.**
Built a real subprocess harness (`/tmp/trigger_366.py`) independent of
the PR's own script, mirroring the shape `run-board-gate-tests.sh` itself
uses (fresh git-init'd probe repo, `docs/specs/approvers.md` planted,
branch `issue-3/qa`, `CLAUDE_SKILL=qa`), piping a synthetic PreToolUse
Bash payload for a heredoc write (`cat > "x" <<'EOF'`) into
`core/hooks/board-gate.sh` as a real subprocess against both worktrees:

```
=== before === exit=2
STDERR: board-gate: a Bash call carries an un-analyzable write-capable shape (cat > "x" <<'EOF') while this gate enforces role 'qa''s write-set. [...]

=== after === exit=2
STDERR: board-gate: a Bash call carries an un-analyzable write-capable shape (cat > "x" <<'EOF') while this gate enforces skill 'qa''s write-set. [...]
```

Both deny with `exit=2`; the interpolated slot still holds the skill
value (`'qa'`), and only the noun changed (`role` → `skill`). Confirms
the issue's exact reproduction case is fixed as claimed. (Note: the
issue's cited line number `board-gate.sh:747` has drifted to line 846 on
both `origin/main` and the PR head — pre-existing drift since the issue
was filed, not something this PR caused; confirmed via
`grep -n write-set core/hooks/board-gate.sh` on both worktrees.)

**Check 2 — the population search, defined and shown independently.**
My first attempt at "a string a session can see" (a 600-char text window
after each `deny(`/`sys.stderr.write(`/`sys.stdout.write(`/`print(` call
open-paren, then a regex for whole-word `role`) was WRONG: it spilled
past the end of the actual call argument into unrelated subsequent code
and comments, inflating the count to 37 before / 24 after — a
population that does not match "a string a session can see" because it
counts text the call never emits. I rewrote it to extract only the
call's own argument text via parenthesis-depth balancing
(`/tmp/sweep_366_verify2.py`, scanning `core/hooks` and `warrant/hooks`,
`*.py`/`*.sh`, matching the four call shapes above, whole-word
case-insensitive `role` inside the balanced argument text only):

```
=== BEFORE (origin/main) ===
warrant/hooks: 0 hits (explicit zero)
('core/hooks/approval-gate.sh', 213, 'deny')
('core/hooks/approval-gate.sh', 241, 'deny')
('core/hooks/approval-gate.sh', 345, 'deny')
('core/hooks/approval-gate.sh', 350, 'deny')
('core/hooks/board-gate.sh', 845, 'deny')
('core/hooks/board-gate.sh', 922, 'deny')
('core/hooks/board-gate.sh', 954, 'deny')
('core/hooks/board-gate.sh', 973, 'sys.stderr.write')
('core/hooks/board-gate.sh', 989, 'deny')
('core/hooks/board-gate.sh', 1046, 'deny')
('core/hooks/board-gate.sh', 1173, 'deny')
('core/hooks/gh-guard.sh', 148, 'deny')
('core/hooks/ordering-gate.sh', 523, 'deny')
('core/hooks/record-fields-gate.sh', 481, 'deny')
TOTAL: 14

=== AFTER (PR branch) ===
warrant/hooks: 0 hits (explicit zero)
('core/hooks/board-gate.sh', 973, 'sys.stderr.write')
('core/hooks/board-gate.sh', 989, 'deny')
TOTAL: 2
```

This is 14 → 2 with the identical file:line set the PR's own record
reports, arrived at independently (my search implementation and script
path are distinct from theirs). `warrant/hooks` is an explicit,
code-checked zero on both sides, not an assumption.

**Check 3 — gate test suites, before/after, as SETS OF TEST NAMES.**
Ran `run-board-gate-tests.sh`, `run-approval-gate-tests.sh`,
`run-dispatcher-equivalence-tests.sh`, `run-ups-diet-tests.sh` against
both worktrees and extracted full test names (not truncated to the
first whitespace-separated token — the PR record's own
`awk '{print $2}'` extraction silently truncates multi-word names,
undercounting `run-dispatcher-equivalence-tests` as "13" and
`run-ups-diet-tests` as "7" when the real distinct-name counts are 25
and 36 respectively; this does not change whether the sets are
identical, but the PR record's reported name-set *sizes* for those two
suites are wrong). Extracted names via fixed-width column slicing
matching each suite's own `printf` format (`%-34s`, `%-70s`, `%-60s`):

```
run-board-gate-tests:              before=161 names, after=161 names — diff: IDENTICAL
run-approval-gate-tests:           before=67 names,  after=67 names  — diff: IDENTICAL
run-ups-diet-tests:                before=36 names,  after=36 names  — diff: IDENTICAL
run-dispatcher-equivalence-tests:  before=25 names,  after=25 names  — diff: 1 line differs only in an
  embedded live latency number in the test's own name string
  ("dispatcher end-to-end latency < 100ms (avg 44ms)" vs "(avg 42ms)"),
  not a name added/removed/reworded — timing jitter inherent to that
  suite on both sides of this diff, unrelated to the role->skill edit.
```

Pass/fail counts, independently re-run, identical before/after in my
environment: board 159/2, approval 65/2, dispatcher 24/1, ups-diet
36/0. `core/hooks/tests/run-all.sh` full output is identical between
worktrees except for the worktree's own absolute path appearing in one
line (`deny-only-check: ok — no permissionDecision allow under
<worktree-path>/core/hooks`) — an artifact of using two different
directories for before/after, not a behavioral difference; every
per-suite `== N passed, M failed ==` / `role-gates: 83 passed, 0
failed` / `ups-diet: 36 passed, 0 failed` line is byte-identical.

**Discrepancy found (informational, not a blocker):** the PR record
claims 6 named pre-existing failures, including
`"combined UPS payload <= 3072 bytes"` under `run-ups-diet-tests.sh`. In
my independent re-run, that suite is 36 passed / 0 failed on BOTH
`origin/main` and the PR head — the UPS-payload-budget test passes in my
environment on both sides. This is very likely session/environment
dependent (the byte budget the test checks against depends on which
directives/skills are mounted in the running session, not on this PR's
diff), and it does not affect the acceptance check itself: within my own
environment, the before and after failure sets are identical (which is
what "no gate changes what it allows or denies" requires). Flagged so a
future reader does not treat the PR record's specific 6-failure
enumeration as environment-independent ground truth.

Also spot-checked the two deliberately-unedited `role` survivors
(`board-gate.sh:973`, `:989`) by reading the surrounding code directly:
line 973's `sys.stderr.write` genuinely describes a past rename
("issue #2741: this key was renamed role -> skill") and would become
false if rewritten; line 989's `deny()` was rewritten to say
`skill 'issue'` throughout except the literal, still-real filename
`.on-the-record/role.json`, which the PR correctly did not rename (a
persisted-key/filename change is `#2600`'s already-landed "persisted
keys" slice, out of this issue's scope). Both survivors match the
issue's own must-not clause as intended, not missed.

No `docs/` file was modified by PR #389 other than its own new record
at `docs/issue-366/reports/technical-writing-structure-comprehension-2b15240c.md`
— confirmed via the PR diff (`gh pr diff 389`), satisfying "do not
modify anything under docs/". No compatibility alias or dual-vocabulary
period was introduced — every changed line in the diff is a direct
in-place word substitution (`role` → `skill`, `role's` → `skill's`,
`role/issue` → `skill/issue`, `per-role` → `per-skill`), confirmed by
reading the full diff.

## Why

Independent verification exists to catch what a single self-reporting
session might rationalize past — I re-derived the population search
from the acceptance text ("state the search that defines 'a string a
session can see'") rather than adopting the PR's script unread, which is
what surfaced my own first-draft search being wrong (over-broad window)
before it converged on the same 14→2 result via a structurally sound
method (balanced-paren argument extraction). I used disposable git
worktrees of `origin/main` and the PR head rather than `git stash` in a
single directory so before/after runs cannot cross-contaminate through
leftover state, and re-ran every check as a real subprocess rather than
reading the PR record's pasted transcripts as ground truth.

## What did not work

My first population-search implementation (fixed 600-char text window
after each call's open-paren) overcounted (37/24 instead of 14/2)
because the window spilled into unrelated subsequent code. Rewritten to
balance parentheses and extract only the call's actual argument text,
which converged on the PR's own reported 14/2 figures independently.
Logged here as the "what did not work" for this record, not folded
silently into the final numbers above.

## Upstream basis

PR #389 (`tokenmaxxxer/tokenmaxxxer-core`), commit `d3adeed` on
`issue-366/technical-writing-structure-comprehension-2b15240c`, parent
`8c7cc8d` (= current `origin/main`); and that PR's own record at
`docs/issue-366/reports/technical-writing-structure-comprehension-2b15240c.md`,
both same-commit-cited above as the concrete upstream basis for this
verification.

## Open findings

- The PR record's claim of "6 named pre-existing failures" (via its PR
  description's "same 6 pre-existing failures present on both sides")
  includes one (`combined UPS payload <= 3072 bytes`) that does not
  reproduce as a failure in my independent re-run (36 passed / 0 failed
  on both sides here) — almost certainly session/mounted-directive-size
  dependent, not a defect in PR #389's edit. Resolution path: none
  needed for this issue; note for whoever next touches
  `run-ups-diet-tests.sh` or the UPS byte budget that its pass/fail
  status is environment-sensitive.
- The PR record's reported test-name-*set sizes* for
  `run-dispatcher-equivalence-tests` (13) and `run-ups-diet-tests` (7)
  are undercounts caused by their `awk '{print $2}'` extraction
  truncating multi-word test names at the first space; the real counts
  are 25 and 36. This does not change the acceptance verdict (the sets
  are still identical before/after under a name extraction that doesn't
  truncate), but the PR record's numbers should not be read as the true
  distinct-test-name counts for those two suites.

Neither finding changes the verdict: all three acceptance checks pass
under independent re-verification.

## Next steps

None — `loop_state: landed`. This record's `verifies_subject: true`
marks it as one of the two required independent verifications of PR
#389's deliverable for issue #366.

skill-verdict: work-in-english — applied: invoked; this record, and all
scratch scripts/comments produced during verification, are written in
English.
other mounted skills: not triggered — this task is read-only
verification (audit an existing PR's claims against fresh subprocess
runs), not a coding/design/dataviz/deploy task any other mounted skill's
trigger describes.
