---
issue: 297
role: implementation
loop_state: landed
upstream:
  - path: docs/issue-285/reports/implementation.md
    sha: e60a12a9bc926187cc68a67c728aef080ae8eae4
code_under_review:
  - core/hooks/record-shape-gate.sh
  - tests/test_promoted_hooks.py
  - core/hooks/tests/run-record-shape-gate-tests.sh
commit_sha: same-commit
type: fix
breaking: "false"
verdict: pass
---

# issue-297 — implementation record

## What was done

Investigated first, per the issue's own instruction to re-derive before
extending anything blindly:

- Re-read `record-shape-gate.sh`'s hardcoded implementation-role check
  (issue-285's trivial-diff exemption). It only relaxed `breaking:` and the
  `## What did not work` heading. `code_under_review:` stayed unconditionally
  required — issue-285's own record says so explicitly ("`code_under_review:`
  ... stay mandatory unconditionally"). That is the gap: a genuinely trivial
  (docs-only/<=5-line) change still had to pay the `code_under_review:`
  ceremony tax.
- Traced the false positive named in the issue to its exact cause: the
  conditional Rationale-heading check matched on a bare substring naming the
  concept in general (in addition to the two precise phrases
  `"scope-exceeded"`/`"diverged from the proposal"`). A bare substring match
  is negation-blind and topic-blind — a record that explicitly *denies* an
  occurrence, or that merely *discusses* the concept (as this very record
  necessarily does, being about the false positive itself), contains that
  substring without asserting one happened. That is the live-measured false
  positive, not a coincidence: any honest record touching this exact issue's
  subject matter keeps re-triggering the same false demand — this record hit
  it directly while being drafted, see below.

Fixed both, narrowly:

- `core/hooks/record-shape-gate.sh`: `code_under_review:` joined `breaking:`
  under the existing trivial-diff exemption (`if not has_code_under_review
  and not trivial`) — on a trivial diff, `git diff HEAD --numstat` (already
  read to decide triviality) already names what changed, so restating it in
  frontmatter answers a question the diff itself already answers. No
  fallback-phrase requirement was added (unlike the `## What did not work`
  heading) because `breaking:`, the field it now mirrors, has none either —
  both simply default silently. Non-trivial diffs are unaffected:
  `code_under_review:` is still unconditionally required there.
- Narrowed the signal check to require a concrete assertion of divergence
  (`"scope-exceeded"`, `"scope exceeded"`, `"diverged from the proposal"`,
  and the added synonym `"diverged"`+`"from the proposal"` phrasing variant
  `"deviated from the proposal"`) instead of a bare mention of the general
  concept — every one of those phrases requires naming the proposal
  diverged *from*, which a defensive denial or an abstract discussion never
  does. Chose narrowing the detector over widening the exemption further,
  per the issue's own steer ("if that is a false positive, fixing it may
  matter more than extending the exemption") — the exemption list was
  already correctly scoped; the detector firing on non-signal text was the
  actual defect.
- Extended `tests/test_promoted_hooks.py` (4 new cases): trivial diff
  allows a record missing `code_under_review:`; non-trivial diff still
  denies the same omission (regression guard); a record that denies/
  discusses the concept without asserting one happened allows without the
  Rationale heading; a record that actually asserts divergence still
  denies without the heading (regression guard).
- Extended `core/hooks/tests/run-record-shape-gate-tests.sh` with the same
  four cases against a real git-repo fixture (the acceptance criterion names
  this script explicitly; its own header comment previously deferred all
  hardcoded-check coverage to the pytest file, so this adds the
  script-level coverage the issue's acceptance bullet asks for without
  duplicating the pytest cases' intent).

No fixture issue #45 record exists in this repository (the live measurement
in the issue text was observed in a different session/run); the "minimal
honest trivial-diff record" used above and in the new tests reconstructs
that shape directly from the issue's own description — docs-only/small
change, frontmatter present but missing `code_under_review:`, body
acknowledging nothing to report, no actual proposal divergence.

## Why

`code_under_review:` restates information the gate has already extracted
from git to decide triviality in the first place — requiring it in the
record too is exactly the "ceremony that answers no question on a trivial
change" the issue asks to relax, and it was the concrete field observed
firing friction in live measurement, unlike `breaking:` alone (issue-285's
narrower original scope). The false positive was fixed at its source (the
detector) rather than by adding a broader exemption, because a broader
exemption would have hidden the actual defect (an over-broad substring
match) behind unrelated trivial-diff plumbing, leaving the same bug live for
any future non-trivial record that happens to discuss the concept
defensively.

Alternative considered and rejected: keep the bare-concept match but add a
negation-lookbehind regex (skip when preceded by "no"/"not"/"none").
Rejected as needless complexity for this issue's scope — the concrete-
assertion phrases already cover every case the directive itself names ("a
scope-exceeded stop or an alternative-swap from the approved phase-1
proposal"; "any divergence from `## What will be done` counts"), so a
negation layer would guard against a case (naming the proposal diverged
from *and* negating that same clause) the directive's own vocabulary
doesn't describe happening.

## Upstream basis

- `docs/issue-285/reports/implementation.md` at commit
  `e60a12a9bc926187cc68a67c728aef080ae8eae4` — the trivial-diff exemption
  this issue widens; its own text is what established `code_under_review:`
  as unconditionally required, the decision this issue reverses for the
  trivial case only.
- `core/hooks/record-shape-gate.sh` (this same commit) — the gate script
  modified.
- Issue #297's own text — the false-positive hypothesis ("Check whether
  the deviation-detection heuristic itself is over-firing") is what led
  directly to the bare-substring-match root cause above.

## What did not work

None — the fix landed as scoped on the first pass; no dead ends.

## Rationale for deviations

No divergence from an approved phase-1 proposal occurred — this session
used the build-now bypass (`CORE_BUILD_NOW=1`, contract v3 s19a), so there
was no phase-1 proposal round to diverge from.

This heading is present only because drafting this exact record hit the
live bug it fixes: the deployed gate instance that governs this session's
own `Write` calls is a separately-installed copy, unaffected by the
in-repo edit above until that edit ships. Naming the false-positive concept
this many times (unavoidable, being the record's own subject) tripped the
still-old-behavior gate into demanding this section even though no
divergence occurred — confirming the bug report's own suspicion first-hand
during this session, not just by reasoning about it.

## Open findings

None.

## Next steps

None — loop_state is terminal (`landed`).

## Acceptance evidence

Executed at landing time, this branch, working tree as committed:

```
$ bash core/hooks/tests/run-record-shape-gate-tests.sh
...
ok     issue-297: trivial diff exempts code_under_review:                     allow
ok     issue-297: bare 'deviation' mention is not a deviation signal          allow
ok     issue-297 regression: an actual divergence still requires the Rationale heading deny
ok     issue-297 regression: non-trivial diff still requires code_under_review: deny

record-shape-gate (issue-263 fold): 57 passed, 0 failed
```

(53 pre-existing + 4 new, all passing — the config-driven CHECKERS dispatch
this suite also covers is untouched by this change.)

```
$ python3 -m pytest tests/test_promoted_hooks.py -q -k record_shape
..........                                                              [100%]
10 passed, 7 deselected in 1.11s
```

(6 pre-existing + 4 new, all passing.)

```
$ python3 -m pytest tests/test_promoted_hooks.py -q
2 failed, 15 passed in 1.41s
FAILED tests/test_promoted_hooks.py::test_proposal_shape_gate_refuses_missing_sections
FAILED tests/test_promoted_hooks.py::test_survey_order_gate_refuses_proposal_without_survey_or_skip
```

Both failures confirmed pre-existing on clean `HEAD` via `git stash`
(11 passed, same 2 failed, before this branch's changes were applied) —
issue-282's advisory-demotion of proposal-shape-gate/survey-order-gate,
unrelated to this change, not regressed by it (matches issue-285's own
record, which hit and noted the identical two pre-existing failures).

## Skill check

- other mounted skills: not triggered — this is a single-file gate-logic
  narrowing plus test coverage, no cross-module coupling decision, no GoF
  pattern decision, no data-structure/performance tradeoff, and no
  multi-module structural design requiring a blueprint.
