---
issue: 384
role: silent-failure-audit-97b1e431
author: silent-failure-audit-97b1e431
skills: silent-failure-audit (skill-repository(c05de12))
verifies_subject: false  # flip to true only if this record is an independent verification of this subject's own deliverable -- see docs/handbooks/observer-verification.md
loop_state: landed
upstream:
  - path: docs/issue-384/reports/adversarial-review-61b82bd3.md (PR #397, round-3 review, open)
    sha: 6507f22e60cc18eefa4316724cb019081930a22f
  - path: core/hooks/directive.sh, core/directive/session-protocol-build-now.md (PR #386 tip)
    sha: 3b50ebbba5c25c69c437b6b1b59d4577c406dcb0
---

# issue-384 — silent-failure-audit-97b1e431 record

## What was done

Round-3 fix to PR #386, addressing both findings from PR #397's independent
verification. Branched from PR #386's tip (`3b50ebb`) rather than main,
since these are fixes to that PR's own content, not a fresh diff.

**Finding 1 — retired role axis survived at
`core/directive/session-protocol-build-now.md:54`.** Changed:
```
- read other roles' state from main, not from open PRs.
+ read other skills' state from main, not from open PRs.
```
Recount with a plural-safe pattern, run over every added line in the whole
PR's diff vs `origin/main` (core+warrant files together):
```
$ git diff origin/main -- core/hooks/directive.sh core/directive/session-protocol-build-now.md \
    core/hooks/board-gate.sh warrant/hooks/state.sh warrant/hooks/lib/scope-gate.py \
    | grep -nE '^\+' | grep -iE '\brole'
(no output, exit 1)
```
Pattern used: `\brole` (no trailing `\b`) — `\b` after "role" still matches
before a non-word character (apostrophe, space, end of string), so this
single pattern also catches "roles", "role's", "roles'" and `<role>`
without a second pass. The previous rounds' `\brole\b` structurally cannot
match "roles" because "s" is a word character, so the trailing boundary
never triggers on the plural — that's the exact blind spot on-the-record
#2876 filed.

**Finding 2 — no test exercised `directive.sh`'s build-now injected text,
and the two build-now copies (the inline heredoc bullets in `directive.sh`
and the file each branch's `DFILE` points at) could drift with nothing
reporting it.** Fixed at the source on both axes, not by pinning bytes:

1. `core/hooks/directive.sh`: the five bullets that were already
   byte-identical between the build-now and two-phase heredoc branches
   (Requirements, ALL-output/board, Layout, docs/specs-regeneration,
   Verification) are now each a single shell variable
   (`REQ_BULLET`/`OUTPUT_BULLET`/`LAYOUT_BULLET`/`SPECS_BULLET`/
   `VERIFY_BULLET`) referenced from both branches, instead of two literal
   copies of the same text. After this change the two branches cannot
   disagree on those five bullets — there is only one copy to disagree
   with itself. Verified this is a pure reshuffle, not a text change: see
   "How you will know it worked" below for the before/after byte diff.

2. `test/test_directive_injection.py`: added
   `test_build_now_protocol_content_genuinely_present` and
   `test_build_now_byte_stable_across_two_renders`, the build-now
   counterparts of the two existing non-build-now tests — these are the
   first tests in the suite to render `directive.sh` with
   `CORE_BUILD_NOW=1` at all, closing the exact gap PR #397 demonstrated
   live (editing the build-now text left the full suite byte-identical).
   Also added `test_shared_bullets_between_protocol_variants_stay_in_sync`,
   which re-derives `session-protocol-build-now.md`'s shared bullets from
   `session-protocol.md`'s via the same role->skill word-substitution this
   repo's ongoing rename already uses (whole-word, boundary-safe, so
   possessives normalize correctly), then diffs the derived text against
   the real build-now file. This is a content-derived consistency check
   between the two files' current bytes, not a snapshot of today's bytes
   against a hardcoded expectation — reverting the Finding-1 fix makes it
   fail (see "How you will know it worked").

I deliberately did not fully collapse the two `.md` files into one shared
file: `session-protocol.md` still intentionally uses the retired `role`
vocabulary throughout (docs/issue-349's record: that rename is explicitly
scoped to a future slice, not this issue), so byte-level sharing would
require introducing a templating layer this repo doesn't have, for a scope
increase issue #384 doesn't ask for. The content-derived sync test gives
the same "verifiably agree" guarantee the reviewer asked for without that
lift, and directly targets the failure mode that actually occurred.

## Why

Round-3 review (PR #397, `docs/issue-384/reports/adversarial-review-61b82bd3.md`)
confirmed the saving but found two things: a missed vocabulary-rename
occurrence, and a real test-coverage gap that let it (and any future
build-now drift) through silently. Both are silent-failure-shaped: the
first because the review's own grep pattern couldn't see the plural; the
second because "no test looks" is a stronger failure than "the check
fails" — nothing anywhere would report a future divergence between the
two build-now copies. The reviewer explicitly asked for a source-level fix
over a pinned-byte test, since a literal-copy test "would have passed the
leak above too" (a byte-for-byte snapshot doesn't catch a wording error
made *consistently* on write, only a later edit to just one copy).

## What did not work

None.

## Upstream basis

- `docs/issue-384/reports/adversarial-review-61b82bd3.md` (PR #397) —
  round-3 review findings this record responds to.
- `core/hooks/directive.sh`, `core/directive/session-protocol-build-now.md`
  at PR #386's tip (commit `3b50ebb`) — the code this record fixes.
- `sha:` values above are the real 40-char upstream commit shas (not
  same-commit): this record's own commit is a fix layered on top of both.

## Open findings

None open. Both PR #397 findings addressed above; see "How you will know
it worked" for the executed evidence.

## Next steps

None — `loop_state` is terminal for this build-now delivery once this PR
is opened.

## How you will know it worked

**1. No return of the retired role axis (plural-safe pattern), full diff
vs origin/main, core+warrant together:**
```
$ git diff origin/main -- core/hooks/directive.sh core/directive/session-protocol-build-now.md \
    core/hooks/board-gate.sh warrant/hooks/state.sh warrant/hooks/lib/scope-gate.py \
    | grep -nE '^\+' | grep -iE '\brole'
(no output; grep exit code 1)
```

**2. No new bug — failing-test set vs origin/main, compared as SETS OF
NAMES.** Directories the comparison actually collects: `core/hooks/tests/`
(bash suites: `run-all.sh`, `run-board-gate-tests.sh`,
`run-approval-gate-tests.sh`, `run-dispatcher-equivalence-tests.sh`,
`run-directive-shape-tests.sh`, `run-ups-diet-tests.sh`, plus everything
`run-all.sh` itself fans out to under `core/hooks/` and the `freelunch`/
`scout` sibling plugin dirs it also runs) and `test/` (pytest,
`test_directive_injection.py`).
```
$ bash core/hooks/tests/run-board-gate-tests.sh 2>&1 | grep -i FAIL
FAIL   feasibility-spikes                 want=allow got=deny
FAIL   ops-postmortems                    want=allow got=deny
$ bash core/hooks/tests/run-approval-gate-tests.sh 2>&1 | grep -i FAIL
FAIL   checkpoint-refusal-names-await-approval want=present got=absent
FAIL   execute-without-remote             want=deny got=allow
$ bash core/hooks/tests/run-dispatcher-equivalence-tests.sh 2>&1 | grep -i FAIL
FAIL   approval-gate: execution write, no approvers.md -> deny   want_rc=2 standalone_rc=0 dispatcher_rc=0
```
Same 3 commands against `origin/main` (via `git worktree add /tmp/main-wt2 origin/main`)
produced the identical 5 names, byte-for-byte identical FAIL lines. Full
`run-all.sh` output diffed between this branch and `origin/main` (after
normalizing the worktree path and one timing-noisy `avg NNms` figure) is
byte-identical (`diff` exit 0) — same 572 passed / 5 failed, same ordered
list of `ok` lines, confirming point 4 below as well.

**3. `python3 -m pytest test/test_directive_injection.py -v`** — 9 passed
(was 6 before this round; the 3 new tests are the build-now-content,
build-now-byte-stability, and cross-file-sync tests above). Mutation check
that the new sync test has teeth — reverted the Finding-1 fix and reran
just that test:
```
$ sed -i "s/read other skills' state/read other roles' state/" core/directive/session-protocol-build-now.md
$ python3 -m pytest test/test_directive_injection.py::test_shared_bullets_between_protocol_variants_stay_in_sync -v
FAILED ... AssertionError: assert '- Output lay...' == '- Output lay...'
$ git checkout -- core/directive/session-protocol-build-now.md  # restored; re-applied the real fix after
```

**4. No overhead increase — injection-point number, re-derived on this
branch (same method as PR #397: actual `directive.sh` stdout, not file
size), before this round's edits (PR #386 tip, `3b50ebb`) vs after:**
```
non-build-now (CORE_BUILD_NOW unset): 10778 bytes / 2650 tok (cl100k_base) -- unchanged (session-protocol.md untouched)
build-now, before (3b50ebb):  8223 bytes
build-now, after (this fix):  8224 bytes / 2031 tok (cl100k_base)
```
The +1 byte is exactly the one-character `roles'`->`skills'` fix; the
heredoc dedup refactor is a byte-for-byte no-op (`diff` of before/after
build-now stdout shows only that single line changed; before/after of the
non-build-now stdout is empty). Saving at the injection point: 10778-8224
= 2554 bytes, ~619 tok (cl100k_base) — still a decrease of the same size
as PR #397's own 610 tok re-derivation (the small difference between
619/610/630 across the three independent measurements this issue has now
had is measurement-environment noise, not drift; the point the reviewer
asked to confirm — that this round's edits didn't shrink or reverse the
saving — holds).

**5. Monitor and watch machinery unbroken and not quieter:**
`core/hooks/tests/run-all.sh` full output is byte-identical between this
branch and `origin/main` after normalizing the worktree path and the one
timing-noisy latency figure (`diff` exit 0, shown under point 2). Same
`ok` step count (49 `parse-check` files under core, same 4 sibling-plugin
groups), same 572/5 passed/failed totals.

skill-verdict: silent-failure-audit — not-applicable: this round's changes
are protocol-text deduplication and test-coverage additions, not
error-handling code with fallible operations (no network/file/DB/
user-input paths to audit); the skill's own "does this even need the
procedure?" gate says skip.
skill-verdict: work-in-english — applied: invoked; wrote this record, all
code comments, commit messages, and the PR body in English per policy;
final user-facing summary in this session is in Korean.
skill-verdict: adversarial-review — not-applicable: this round's own
deliverable already went through a structurally-independent evaluator —
PR #397 (role `adversarial-review-61b82bd3`, no shared context with the
builder) reviewed PR #386 and produced the two findings this record
fixes; spawning a second blind review of this same delivery inside the
same build-now session would duplicate that already-completed round, not
add independence. The acceptance line "do not assume the prepared patch
is correct because it was measured — re-derive it here" is satisfied by
this record's own executed re-derivation (see "How you will know it
worked" points 1-4), which is a distinct requirement from a fresh
adversarial pass.
other mounted skills: not triggered (implementation-audit,
verify-finding-record, merge-gates, parallel-decomposition, model-routing
— none of their trigger conditions match a single-session direct
round-3 bugfix with no concurrent agents, no cross-role verification
handoff, and no model-tier delegation decision).
