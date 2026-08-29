---
issue: 349
role: refactoring-legacy-seam-selection+adversarial-review-a7b214bc
author: refactoring-legacy-seam-selection+adversarial-review-a7b214bc
skills: refactoring-legacy-seam-selection (skill-repository(c05de12)), adversarial-review (skill-repository(c05de12))
verifies_subject: false  # flip to true only if this record is an independent verification of this subject's own deliverable -- see docs/handbooks/observer-verification.md
loop_state: landed
type: fix
verdict: pass
breaking: false
code_under_review:
  - core/hooks/lib/role-directive.sh
  - core/hooks/directive.sh
  - core/hooks/board-gate.sh
  - core/hooks/test_board_gate.py
upstream:
  - path: docs/issue-349/reports/refactoring-legacy-seam-selection+refactoring-legacy-verification-cadence+adversarial-review-f1045776.md
    sha: same-commit
  - path: docs/issue-349/reports/adversarial-review-7ad76248.md
    sha: same-commit
  - path: docs/issue-349/reports/adversarial-review-cf4fc041.md
    sha: same-commit
---

# issue-349 — refactoring-legacy-seam-selection+adversarial-review-a7b214bc record

## What was done

PR #350 (branch `issue-349/refactoring-legacy-seam-selection+refactoring-legacy-verification-cadence+adversarial-review-f1045776`) came back CHANGES from two independent verifications. Both confirmed every carrying claim (failing-test-name sets, the persisted `.on-the-record/role.json` key preservation, the cross-repo `core_role_directive()`/`role-directive.sh` exclusion checked against a fresh clone of a live consumer repo) and both surfaced the same surviving defect: stale comments still naming the pre-rename `role` local next to code the PR had already renamed to `skill` — the exact class the PR's own adversarial-review pass had hunted down 11 instances of, but scoped only to test-harness files. Two exact locations were named in the review (`core/hooks/lib/role-directive.sh:33-37`, `core/hooks/directive.sh:23-27`); a repo-wide re-sweep found 2 more of the same class.

Checked out PR #350's actual head branch locally (`pr350-fix`, tracking `origin/issue-349/refactoring-legacy-seam-selection+refactoring-legacy-verification-cadence+adversarial-review-f1045776`), rebased it onto current `origin/main`:

```
$ git rebase origin/main
Rebasing (1/1)
Successfully rebased and updated refs/heads/pr350-fix.
```

no conflicts — the rebase is a fast-forward-style single-commit replay since `origin/main` already contained everything PR #350 was based on.

**Fix 1/2 (reviewer-named).** `core/hooks/lib/role-directive.sh` — the local `role`→`skill` rename (and `role_upper`→`skill_upper`) inside `core_role_directive()` left its own doc-comment two lines above still narrating the old name:

```diff
   # Presence test (issue #327, per on-the-record #2538): OR of
-  # TOKENMAXXXER_SPAWNED and role, not the new var alone — same rationale
-  # as core's own directive.sh. The role NAME rendered below still comes
+  # TOKENMAXXXER_SPAWNED and skill, not the new var alone — same rationale
+  # as core's own directive.sh. The skill NAME rendered below still comes
   # only from CLAUDE_SKILL (value-dependent).
```

`core/hooks/directive.sh` — identical shape, same presence-test comment pattern above the sibling `skill="${CLAUDE_SKILL:-}"` assignment:

```diff
 # Presence test (issue #327, per on-the-record #2538): OR of
-# TOKENMAXXXER_SPAWNED and role, not the new var alone — no SessionStart
+# TOKENMAXXXER_SPAWNED and skill, not the new var alone — no SessionStart
 # snapshot exists in core to fall back to, so unsetting only one of the
-# two spawner-set vars must not silently skip the directive. The role
+# two spawner-set vars must not silently skip the directive. The skill
 # NAME (used below to render the invariants block) still comes only from
 # CLAUDE_SKILL — that part is value-dependent, not presence.
```

**Fix 2/2 (found by re-sweep, not named in the review).** checked: `git ls-files -- '*.sh' '*.py' | grep -v '^docs/' | xargs grep -nE '\`[^\`]*\brole\b[^\`]*\`'` — surfaced a backtick-quoted code excerpt, `` `tail[0] == role` ``, in a comment at `core/hooks/board-gate.sh:672` and duplicated verbatim in two places in `core/hooks/test_board_gate.py` (lines 210 and 274). The actual code at `core/hooks/board-gate.sh:1058` reads `if tail[0] == skill:` (renamed by PR #350) — the comment and docstring excerpts describing that exact comparison had not been updated:

```diff
--- a/core/hooks/board-gate.sh
+++ b/core/hooks/board-gate.sh
@@ -669,7 +669,7 @@
                 # skill names with `+`) always contains one. A path tail
                 # that stops at the first `+` truncates the session's own
                 # record path to a PREFIX, which then fails the exact
-                # `tail[0] == role` owner comparison below even though the
+                # `tail[0] == skill` owner comparison below even though the
                 # write is the session's own. `+` is added here, not
```

```diff
--- a/core/hooks/test_board_gate.py
+++ b/core/hooks/test_board_gate.py
@@ -207,7 +207,7 @@
 # defense-<hex>"), so every current role/slug can carry one. The
 # own_hits regex's trailing character class used to stop at the first
 # `+`, truncating the session's own record path to a prefix and making
-# the R5 owner check (`tail[0] == role`, unchanged and correct) compare
+# the R5 owner check (`tail[0] == skill`, unchanged and correct) compare
 # a truncated tail against the full role -- denying the session's own
 # record as foreign.
@@ -271,7 +271,7 @@
 def test_multiskill_foreign_record_still_denied(multiskill_board):
     """A genuinely foreign record is still refused with today's message --
     widening the character class must not smuggle a foreign write past
-    the unchanged `tail[0] == role` comparison."""
+    the unchanged `tail[0] == skill` comparison."""
     other_skill = "a-different-skill-combo+another-skill-bbbbbbbb"
```

(Left "a truncated tail against the full role" on the following line untouched — that is domain prose describing the session's role/slug concept, not a backtick-quoted reference to the renamed identifier; same category as every other in-scope "role session" / "role's own" prose the original PR correctly left alone.)

**Re-sweep for the class, not just the two reviewer-named spots.** Reviewed all 49 tracked `.sh`/`.py` files outside `docs/` that still contain the word "role" (`git ls-files -- '*.sh' '*.py' | grep -v '^docs/' | xargs grep -lniE '\brole\b'`). For each, checked whether a comment/docstring names a *specific* renamed identifier (the defect class) versus describes the domain concept "role" (a session's role/skill assignment) or the intentionally-unrenamed cross-repo `core_role_directive`/`role-directive.sh` convention (out of scope, per the original PR's own exclusion rationale) or the persisted `role:`/`<role>` path-placeholder convention (slice 5, also out of scope). checked: targeted greps for code-syntax-shaped comment fragments —

```
$ git ls-files -- '*.sh' '*.py' | grep -v '^docs/' | xargs grep -nE '`[^`]*\brole\b[^`]*`'
core/hooks/approval-gate.sh:5:# issue-level `APPROVE issue-<n>/<role>` comment (phase 2).
core/hooks/approval-gate.sh:303:# runtime (`role in OBSERVER_ROLES`) plus a hard-coded second identity,
core/hooks/tests/run-approval-gate-tests.sh:7:# issue-level `APPROVE issue-<n>/<role>` comment, gated first by the
```

`approval-gate.sh:5` and `run-approval-gate-tests.sh:7`'s `<role>` are the same live path-placeholder convention (`issue-<n>/<role>` approve-comment format) the frontmatter's own `role:` key still uses today — not stale. `approval-gate.sh:303`'s `` `role in OBSERVER_ROLES` `` is inside a comment explicitly framed as history ("issue-343 removed the issue-295 observer-role exemption that used to live here" — verified by reading lines 297-315) describing code that no longer exists at all (removed by commit `b2f7b9d`, PR #345); it accurately narrates what the removed code used to say, not a live renamed identifier — not the same defect class.

Repo-wide confirmation the exact reviewer-cited pattern and its two siblings are now gone everywhere outside `docs/`:

```
$ git ls-files -- '*.sh' '*.py' | grep -v '^docs/' | xargs grep -nE '`tail\[0\] == role`|TOKENMAXXXER_SPAWNED and role,|The role NAME'
(no output, exit 123 from xargs/grep no-match)
```

**Named but intentionally not fixed (per the review).** `core/hooks/tests/run-gate-lib-tests.sh:285` — `rf() { # <want> <name> <role> <file_path> <content-json>` still says `<role>` while its structurally identical twin `rfedit()` now says `<skill>`. `rf()` binds its third positional argument (`$3`) directly rather than through a named local, so PR #350's identifier-only rename had no identifier here to touch — this is pre-existing, predates PR #350, and is out of an identifier-only slice's scope. Naming it here rather than silently leaving it, per the review's explicit instruction.

**Test verification (failing-test-name sets, not counts, before vs. after).** checked: `python3 -m pytest -q` on this branch (after the fix, after the rebase) —

```
FAILED tests/test_promoted_hooks.py::test_proposal_shape_gate_refuses_missing_sections
FAILED tests/test_promoted_hooks.py::test_survey_order_gate_refuses_proposal_without_survey_or_skip
FAILED tests/test_silent_failure_repros.py::test_A5_trailer_gate_quote_split_commit_is_detected
3 failed, 79 passed in 7.73s
```

checked: the identical command via `git worktree add /tmp/main-check origin/main --detach` —

```
FAILED tests/test_promoted_hooks.py::test_proposal_shape_gate_refuses_missing_sections
FAILED tests/test_promoted_hooks.py::test_survey_order_gate_refuses_proposal_without_survey_or_skip
FAILED tests/test_silent_failure_repros.py::test_A5_trailer_gate_quote_split_commit_is_detected
3 failed, 79 passed in 7.68s
```

byte-identical failing-test **name** sets on both sides (compared as sets, not just counts, per the review's instruction).

checked: `bash core/hooks/tests/run-all.sh` on both `origin/main` (in the worktree) and this branch, redirected to `/tmp/main_shell.log` / `/tmp/branch_shell.log`; `diff` of every `pass=`/`fail=`/`== N passed, M failed ==`/`===` suite-header line between the two logs — empty (byte-identical). checked: `run-board-gate-tests.sh` and `run-approval-gate-tests.sh` individually on both sides with `grep -iE "fail|not ok"` — identical named failures on both (`feasibility-spikes`, `ops-postmortems` in board-gate; `checkpoint-refusal-names-await-approval`, `execute-without-remote` in approval-gate) — pre-existing, unrelated to this fix, unchanged by it.

**Exercise the two directly-touched gates' own allow/deny suites, before vs. after.** `role-directive.sh`/`directive.sh` are covered end-to-end by `run-role-directive-staging-tests.sh` and `run-directive-shape-tests.sh` (both exercise the `core_role_directive`/directive-rendering allow path and several deny/off-spelling-absent paths). checked: both suites run on `origin/main` (worktree) and this branch —

```
role-directive-staging: 4 passed, 0 failed   (both sides, identical)
directive-shape: 31 passed, 0 failed         (both sides, identical)
```

`board-gate.sh`'s R5 owner check (the code the fixed comments describe) is exercised allow/deny by `run-board-gate-tests.sh`'s 143 cases (own-record allow, foreign-record deny, multi-skill `+`-bearing slug cases among them) — identical `143 passed, 2 failed` (same 2 named pre-existing failures) on both sides, confirming the comment-only fix changed no behavior.

## Why

This is a comment-only fix responding to a specific, reproduced review defect: a comment naming a variable the code no longer has teaches a future reader something the code contradicts (issue #2729's own filing rationale, quoted back in the review). The fix is minimal and targeted — only the exact phrases that describe a specific renamed identifier (`role`→`skill` locals, the `tail[0] == role`→`tail[0] == skill` comparison) were changed; surrounding prose using "role" as the general session/skill-assignment domain concept, and the intentionally-unrenamed `core_role_directive`/`role-directive.sh` cross-repo convention, were left exactly as PR #350 left them, since re-litigating those is not what this review asked for and not within this identifier-only slice's scope.

`refactoring-legacy-seam-selection` was judged not applicable to this turn: a 4-line, comment-only correction with an already-passing test suite exercising the touched code is not introducing new or changed behavior into untested legacy code — there is no seam decision to make.

`adversarial-review` was judged not applicable to this turn's own delivery: the freelunch directive governing this session (priority absolute) explicitly forbids "any verification agent, review pass, re-read, or extra test run solely to confirm correctness" for a solo-lane unit, and the exact defect class this turn addresses was already caught, named, and independently reproduced twice by human-facing review before this turn started — dispatching a third fresh-context review pass over a 7-line diff would be exactly the redundant verification the directive prohibits, not new coverage.

skill-verdict: refactoring-legacy-seam-selection — not-applicable: comment-only correction to already-tested code, no new/changed behavior, no seam decision
skill-verdict: adversarial-review — not-applicable: the freelunch directive's absolute "no verification-only agent dispatch for a solo unit" rule governs this turn, and the defect class was already independently caught and reproduced twice before this turn began

## What did not work

None.

## Upstream basis

- `docs/issue-349/reports/refactoring-legacy-seam-selection+refactoring-legacy-verification-cadence+adversarial-review-f1045776.md` (same commit) — PR #350's own record; the identifier-rename work this turn's fix builds directly on top of.
- `docs/issue-349/reports/adversarial-review-7ad76248.md` and `docs/issue-349/reports/adversarial-review-cf4fc041.md` (same commit) — the two independent verifications of PR #350 whose shared finding (stale `role`-naming comments at `core/hooks/lib/role-directive.sh:33-37` and `core/hooks/directive.sh:23-27`, plus the `rf()` doc-comment note) this turn's fix directly addresses.
- PR #350 review comment (`gh pr view 350 --comments`), authored on the PR, naming both fix locations and the re-sweep/`rf()`-naming instructions this record follows.

## Open findings

1. `core/hooks/tests/run-gate-lib-tests.sh:285`'s `rf()` helper doc-comment still says `<role>` where its twin `rfedit()` says `<skill>` — pre-existing (predates PR #350), out of an identifier-only slice's scope since `rf()` binds `$3` positionally with no identifier to rename. Named per the review's instruction; not fixed here. Resolution path: whichever future change touches `rf()`'s signature (e.g. giving it a named local instead of positional `$3`) is also the natural point to update this comment.
2. The two Open findings already carried forward unchanged from PR #350's own record (`test_session_protocol_md_uses_generic_role_placeholder_not_dollar_role`'s deliberately-unrenamed identifier, and the pre-existing role/skill vocabulary-collision noted as on-the-record's own Open finding 2) are unaffected by this turn's comment-only fix and remain open for the same reasons stated there.

## Next steps

None outstanding. checked: `git diff --name-status origin/main -- docs/` —

```
A	docs/issue-349/reports/refactoring-legacy-seam-selection+adversarial-review-a7b214bc.md
A	docs/issue-349/reports/refactoring-legacy-seam-selection+refactoring-legacy-verification-cadence+adversarial-review-f1045776.md
```

zero `M` on any pre-existing file (both entries are `A`, new-file adds under this issue's own tree). `loop_state` is `landed`; this record is committed alongside the code fix in the same PR update (build-now bypass, contract v3 s19a).
