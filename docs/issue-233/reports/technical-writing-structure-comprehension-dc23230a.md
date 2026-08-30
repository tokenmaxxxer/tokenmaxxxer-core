---
issue: 233
role: technical-writing-structure-comprehension-dc23230a
author: technical-writing-structure-comprehension-dc23230a
skills: technical-writing-structure-comprehension (skill-repository(c05de12))
verifies_subject: false  # flip to true only if this record is an independent verification of this subject's own deliverable -- see docs/handbooks/observer-verification.md
loop_state: landed
upstream:
  - path: core/hooks/board-gate.sh
    sha: same-commit
  - path: warrant/hooks/lib/scope-gate.py
    sha: same-commit
---

# issue-233 — technical-writing-structure-comprehension-dc23230a record

## What was done

Continued on PR #382's branch (`issue-233/technical-writing-structure-comprehension-1973359c`)
per the operator's CHANGES review comment on that PR. The review (PR
#383's verification, plus a fresh coherence check) found the same
jurisdiction limit stated three different ways across live gate text:

```
#367   "outside what this gate claims to bound"
#374   "out of this gate's jurisdiction"
#382   "outside what this gate claims to catch"
```

Unified all three to `#374`'s already-landed "out of this gate's
jurisdiction" — the shortest phrasing, and the word the ruling itself
uses. Edited both the flag-side sentence (`#367`'s) and the head-side
sentence (`#382`'s, this same session's own prior addition) in both
files:

- `core/hooks/board-gate.sh`: the "Jurisdiction limit" header comment
  (both the flag-side and head-side clauses) and the `deny()` message
  string reached by the enforced-write-set path.
- `warrant/hooks/lib/scope-gate.py`: the matching header comment and the
  matching `deny` message reached via `warrant/hooks/scope-gate.sh`.

`#374`'s own `UNANALYZABLE_HEAD_RE` paragraph in `board-gate.sh` already
said "out of this gate's jurisdiction" and was left untouched.

Also fixed PR #382's body: it claimed to reuse "PR #374's 'jurisdiction'
vocabulary" while the landed sentence used "claims to catch" instead —
a description that did not match its own diff (the defect #2813 is filed
for). Edited the PR body (`gh pr edit 382`) to describe the actual
unified wording instead.

Wording-only change: no detection-logic touch, confirmed below.

## Why

Three near-identical sentences that do not quite match teaches a reader
the wording is decorative, not load-bearing — and per every ruling in
this issue's history, the honest jurisdiction statement IS the
deliverable here (stating the limit rather than enumerating a seventh
bypass spelling). `#374`'s phrasing was picked because it is already
landed, is the shortest, and is the word ("jurisdiction") the ruling
itself uses, matching the reviewer's explicit instruction.

## What did not work

None.

## Upstream basis

- `core/hooks/board-gate.sh` (this commit) — three sites unified: the
  header-comment flag clause (was PR #367's "claims to bound"), the
  header-comment head clause and matching `deny()` string (was this
  session's own PR #382 "claims to catch").
- `warrant/hooks/lib/scope-gate.py` (this commit) — the same two sites
  (header comment clause + matching `deny` message string).
- PR #383 (adversarial review, `a9d8673`) — identified the three-way
  wording split and the PR-body/diff mismatch; this record's fix
  addresses both findings.
- PR #374 (`b129611`, issue-361) — source of the target phrasing,
  "out of this gate's jurisdiction", left untouched.

## Verification

- Constants byte-identity: `git diff origin/main -- core/hooks/board-gate.sh warrant/hooks/lib/scope-gate.py | grep -E "^[+-]" | grep -v "^+++\|^---" | grep -E "INTERPRETER_HEADS|INLINE_FLAG|WRITE_UNSAFE_HEADS|FUSED_INTERP_RE|VAR_INTERP_RE|UNANALYZABLE_WRITE_SHAPE|UNANALYZABLE_HEAD_RE|UNANALYZABLE_FLAG_RE|UNANALYZABLE_WRITE_HEAD_RE|IFS_TOKEN_RE\s*="` — no output, all ten named constants byte-identical to `origin/main`.
- Diff scope: `git diff core/hooks/board-gate.sh warrant/hooks/lib/scope-gate.py` is comment text plus one Python `deny(...)` string literal and one bash `gate_deny`-adjacent string literal; no code line changed, confirmed by grepping the diff for lines outside the jurisdiction-phrase text.
- `bash core/hooks/tests/run-board-gate-tests.sh` — 159 passed, 2 failed (`feasibility-spikes`, `ops-postmortems`), identical to PR #382's own baseline.
- `bash core/hooks/tests/run-scope-gate-tests.sh` — 62 passed, 0 failed, identical to PR #382's own baseline.
- `python3 -m pytest -q` — 3 failed, 79 passed; failing-test-name set (`test_proposal_shape_gate_refuses_missing_sections`, `test_survey_order_gate_refuses_proposal_without_survey_or_skip`, `test_A5_trailer_gate_quote_split_commit_is_detected`) identical to PR #382's own baseline, checked as sets of names vs `origin/main`.
- Live subprocess before/after (`board-gate.sh`, real `python3 -c` write-shape against a temp worktree at this branch's parent commit vs the current working tree): both `rc=2`; deny message identical except the target clause, which reads `"is equally outside what this gate claims to catch."` before and `"is equally out of this gate's jurisdiction."` after.
- Live subprocess before/after (`warrant/hooks/scope-gate.sh` → `scope-gate.py`, real `python3 -c` write-shape against a temp git repo with one approved proposal, same parent-commit worktree vs current tree): both `rc=2`; deny message identical except the same target clause swap.
- Retired role axis: `git diff origin/main -- core/hooks/board-gate.sh warrant/hooks/lib/scope-gate.py | grep -E "^[+]" | grep -v "^+++" | grep -iE "\brole"` — no output; no added line mentions "role" in any form.
- Failing-test set vs `origin/main`: the three pytest failures and the two suite failures above are the same named tests PR #382 already reported as pre-existing on `origin/main`; no new failing test name appeared.
- Overhead: 30-call subprocess average of the same `board-gate.sh` payload, parent-commit worktree vs current tree — 51.0ms before vs 50.6ms after (noise-level, no code path added).
- Monitor/watch machinery: `grep -in "monitor\|watch" core/hooks/board-gate.sh warrant/hooks/lib/scope-gate.py` — 0 hits in either file both before and after; nothing present to regress or quiet.

## Open findings

None.

## Next steps

None — `loop_state: landed`.

skill-verdict: work-in-english — applied: invoked; wrote this record, all commit messages, and the PR body edit in English (session default already matched this)
skill-verdict: prose-modes — not-applicable: this edit is a terminology-consistency swap in existing reference-mode comments/messages, not a restructuring or drafting task the mode/reader-axis rules bear on
other mounted skills: technical-writing-structure-comprehension — not triggered (this edit unifies terminology across three existing sentences; it does not restructure sentence/paragraph structure for cognitive load, which is that skill's actual trigger)
