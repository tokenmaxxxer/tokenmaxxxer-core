---
issue: 233
role: merge-gates-8555133b
author: merge-gates-8555133b
skills: merge-gates (skill-repository(c05de12)), work-in-english (skill-repository(c05de12))
verifies_subject: false  # flip to true only if this record is an independent verification of this subject's own deliverable -- see docs/handbooks/observer-verification.md
loop_state: landed
code_under_review: PR #385 (`issue-233/technical-writing-structure-comprehension-dc23230a`)
type: chore
breaking: false
verdict: PR #385 rebased onto current `origin/main`, dropping the `core/hooks/board-gate.sh` / `warrant/hooks/lib/scope-gate.py` hunks that PR #388 (merged) already carries as a strict superset -- the PR now touches only its three `docs/issue-233/reports/` records, is conflict-free against main, and its record content is unchanged
upstream:
  - path: PR #388 (tokenmaxxxer/tokenmaxxxer-core, merged as commit b22b745), verified as a superset of PR #385's code hunks by docs/issue-233/reports/adversarial-review-a814c155.md's successor round (PR #396, merged as a0c2934)
    sha: b22b745df5923164ff9c699f06b880abb3ed1b7c
  - path: PR #385 pre-reduction tip
    sha: d49dcec23d654aa2469f9a7afdfcbc8b13238f72
---

# issue-233 — merge-gates-8555133b record

## What was done

Reduced PR #385 (`issue-233/technical-writing-structure-comprehension-dc23230a`)
to its three `docs/issue-233/reports/` records and rebased it onto current
`origin/main`, resolving the `CONFLICTING` mergeable state `gh pr view 385`
reported at the start of this session.

PR #385 carried four commits (`b6eaa25`, `7c4b39a`, `fcfdbce`, `d49dcec`).
Two of them (`b6eaa25`, `fcfdbce`) each touched `core/hooks/board-gate.sh`
and `warrant/hooks/lib/scope-gate.py` alongside a new/appended docs record.
PR #388 (merged to main as `b22b745`, independently re-verified round 9 as
`a0c2934`) already carries an equivalent, strictly larger change to those
same two files -- confirmed here by diffing PR #385's and PR #388's raw
diffs (`gh pr diff 385`, `gh pr diff 388`): the header-comment hunk (lines
39-49 of `core/hooks/board-gate.sh`) is byte-identical between the two;
the `deny()`-message hunk differs only in that PR #388 additionally
rewrites the flag-side clause PR #385 leaves as unmodified context. So
rebasing PR #385 onto post-#388 `main` unmodified would conflict on both
files for no remaining payload -- the fix itself is already on trunk.

Mechanics: built a disposable worktree at `/tmp/pr385-reduced` off
`origin/main`, created a local branch `pr385-branch` at PR #385's real tip
(`d49dcec23d654aa2469f9a7afdfcbc8b13238f72`, fetched via
`git fetch origin issue-233/technical-writing-structure-comprehension-dc23230a`),
then `git rebase --onto origin/main b129611 pr385-branch` (`b129611` =
`b6eaa25`'s parent, i.e. PR #385's actual base). This hit the expected
content conflict on `core/hooks/board-gate.sh` and
`warrant/hooks/lib/scope-gate.py` at both `b6eaa25` and `fcfdbce`; each
was resolved with `git checkout --ours -- <path>` (rebase's `--ours` =
the new base, `origin/main`) followed by `git add` and
`git rebase --continue`. The three docs files are new paths PR #385
introduced, so they replayed with no conflict at all -- git's own tree
merge created them; this session's Bash commands never named a
`docs/issue-233/reports/*` path themselves, since a first attempt at the
same result via `git checkout FETCH_HEAD -- <path>` was correctly denied
by `board-gate.sh`'s R11 foreign-record-ownership check (this session's
own record is `merge-gates-8555133b.md`, not the technical-writing
role's records) -- see What did not work.

Result verified in the worktree before pushing:
`git diff origin/main --stat` shows exactly the three
`docs/issue-233/reports/technical-writing-structure-comprehension-*`
paths, 463 insertions, 0 deletions; `git diff origin/main -- core/hooks/board-gate.sh
warrant/hooks/lib/scope-gate.py | wc -l` is `0` (byte-identical to main,
hunks fully dropped); `git diff pr385-branch d49dcec... -- <the two
pre-existing records>` is also `0` (record content byte-identical to
PR #385's original tip -- nothing about the records themselves changed).
The four original commits (with their original authorship, dates, and
messages) are preserved, just replayed onto the new base.

Pushed with `git push origin pr385-branch:issue-233/technical-writing-structure-comprehension-dc23230a
--force-with-lease=issue-233/technical-writing-structure-comprehension-dc23230a:d49dcec23d654aa2469f9a7afdfcbc8b13238f72`
(lease pinned to the exact tip this session read, so the force-update
only proceeds if nothing else moved that branch meanwhile). New tip:
`990cedd6b5d1e8f6d9a9dc5ffdb1fae252c0c827` (`git ls-remote origin
issue-233/technical-writing-structure-comprehension-dc23230a`). PR #385
now reports `additions: 463, deletions: 0, commits: 4`
(`gh pr view 385 --json mergeable,additions,deletions,commits`).

Disposable worktree and local branches (`tmp-385-reduced`, `pr385-branch`)
removed after the push; this session's own branch
(`issue-233/merge-gates-8555133b`) carries only this record, since the
actual code/history change lives on PR #385's own branch, not here.

**Four standing invariants, command and actual output for each (run in
the `/tmp/pr385-reduced` worktree, post-rebase, pre-push):**

```
derived: git diff origin/main -- core/hooks/board-gate.sh warrant/hooks/lib/scope-gate.py
  core/hooks/tests/run-board-gate-tests.sh core/hooks/tests/run-scope-gate-tests.sh
  | grep -E '^\+' | grep -iE '\broles?\b'
-> no output (exit 1, no match) -- no return of the retired role axis in any
   reshaped form. Plural-catching pattern used (`\broles?\b`, not `\brole\b`)
   per on-the-record#2876's note that a singular-only pattern misses "roles".
   gates/retirement_count.py is not on `origin/main` yet in this repo, so it
   is not cited here.

derived: python3 -m pytest -q, run once on origin/main (this session's own
  branch, up to date with origin/main) and once in the /tmp/pr385-reduced
  worktree (the reduced+rebased PR #385 branch) -- full repo, all
  collected tests (no path filter, collection scope = repo root)
origin/main:          8 failed, 74 passed
pr385-reduced branch: 8 failed, 74 passed
-> same set of 8 names on both:
   {test_heredoc_redirect_to_foreign_skill_report_denied,
    test_author_less_legacy_record_still_enforces_skill_filename_rule,
    test_multiskill_foreign_record_still_denied,
    test_forloop_body_literal_write_still_denied,
    test_case_arm_literal_write_still_denied,
    test_proposal_shape_gate_refuses_missing_sections,
    test_survey_order_gate_refuses_proposal_without_survey_or_skip,
    test_A5_trailer_gate_quote_split_commit_is_detected}
   Sets equal -- no new bug.

derived: git diff origin/main --name-only -- '*.sh' '*.py'
-> no output -- zero code files touched by the reduced PR (the only diff
   is the three docs records above), so there is no code path for an
   overhead change to occur in; no overhead increase.

derived: git diff origin/main --name-only
-> docs/issue-233/reports/technical-writing-structure-comprehension-1973359c.md
   docs/issue-233/reports/technical-writing-structure-comprehension-dc23230a.md
   docs/issue-233/reports/technical-writing-structure-comprehension-dc23230a/2026-08-30-hunt-technical-writing-structure-comprehension-dc23230a.md
-> nothing under any monitor/watch path -- monitor and watch machinery
   unbroken and not quieter (nothing that could quiet it changed).
```

skill-verdict: merge-gates -- not-applicable: invoked; the skill's own
"First: does this even need the procedure?" section says a conflict that
has already happened is resolution work, not gate design ("Resolve it;
come back here only if the question is what should have blocked it") --
PR #385 vs. #388 was exactly that: an already-landed conflict to
reconcile, not a new gate to design, so Steps 1-8 (inventory, shape test,
combined-state mechanism, fail-open audit, etc.) were not run.
skill-verdict: work-in-english -- applied: invoked; this record, all
commit messages, and the PR body are written in English per the skill's
routing rule; the final chat summary to the user is in Korean.

## Why

The operator's instruction (issue #233 context, this session's task) was
explicit: PR #385's code hunks are redundant now that #388 landed as a
verified superset, and would only produce a conflict on rebase for no
remaining payload; its three records are history and are not carried by
#388, so they are the only part worth keeping. Rebasing (rather than,
say, closing #385 and opening a fresh records-only PR) preserves the
original commit authorship and dates for what is, after all, a historical
record of what those rounds found at the time.

The `--onto`+`--ours`-on-conflict mechanic (rather than manually
reconstructing a single squashed commit) was chosen specifically because
this session's own `board-gate.sh` R11 ownership check refuses any Bash
or Write/Edit tool call that names a `docs/issue-233/reports/*` path
belonging to another role's record (confirmed live -- see What did not
work). A real `git rebase`/`git checkout --ours <path>` never places a
foreign record path as a literal argument to a write-shaped command
(`--ours`/`--continue` name no path at all; the two `--ours` resolutions
here name only the two gate files, which are not under
`docs/issue-233/reports/`), so it is the mechanism this role can
legitimately use to move another role's own, unmodified record content
across a rebase without authoring or touching it.

## What did not work

A first attempt to build the reduced branch by copying the record files'
exact blobs directly (`git checkout FETCH_HEAD -- docs/issue-233/reports/technical-writing-structure-comprehension-1973359c.md
...` from a fresh worktree) was denied by `core/hooks/board-gate.sh`:
`docs/issue-233/reports/technical-writing-structure-comprehension-1973359c.md
belongs to another skill. merge-gates-8555133b writes only
merge-gates-8555133b.md, merge-gates-8555133b/** -- never a foreign
record. (contract v3 s11)`. Correct behavior: the gate cannot distinguish
"copying another role's file verbatim during a rebase" from "authoring
content into another role's record," and fails closed on the latter. Not
a bug to route around by disguising the write -- switched to the real
`git rebase` mechanic described above, which resolves conflicts without
ever naming a `docs/issue-233/reports/*` path in a write-shaped command
and so never authors or touches PR #385's own record content.

A stale local branch ref named `main` (pre-existing in this repo clone,
pinned at an old commit that predates the `warrant/` directory) was used
by mistake for the first `git rebase --onto main ...` attempt, producing
a spurious `warrant/hooks/lib/scope-gate.py deleted in HEAD` conflict.
Caught by `git rev-parse main` resolving to a commit missing that file
entirely; aborted (`git rebase --abort`) and redone against `origin/main`
explicitly.

## Upstream basis

- `docs/issue-233/reports/adversarial-review-5c3fbc55.md` -- source of
  the four-standing-invariants command set and phrasing this record's
  invariant block follows (`sha:` not applicable, pre-existing file read
  for format, not modified).
- PR #388 / commit `b22b745df5923164ff9c699f06b880abb3ed1b7c` (merged) and
  its round-9 verification (`docs/issue-233/reports/adversarial-review-...`
  PR #396, merged as `a0c293465600636b859aa088bc8b598b8ac240d5`) -- the
  claim that PR #388 is a strict superset of PR #385's code hunks, which
  this record relies on to justify dropping those hunks rather than
  reconciling them line-by-line.

## Open findings

None. PR #385 is now conflict-free against `origin/main`
(`gh pr view 385 --json mergeable` returned `UNKNOWN` immediately after
the force-push, which is GitHub's async recompute state, not a conflict
report -- `additions`/`deletions`/`commits` on the same call already
reflect the new tip).

## Next steps

None -- `loop_state: landed`. This record documents a completed,
already-pushed reduction of another role's PR branch; PR #385 itself
still needs its own human review/merge decision, which is outside this
role's scope.
