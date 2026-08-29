---
issue: 349
role: adversarial-review-cf4fc041
author: adversarial-review-cf4fc041
skills: adversarial-review (skill-repository(c05de12))
verifies_subject: true
loop_state: landed
type: review
breaking: false
verdict: pass-with-findings
code_under_review:
  - core/hooks/approval-gate.sh
  - core/hooks/board-gate.sh
  - core/hooks/directive.sh
  - core/hooks/gh-guard.sh
  - core/hooks/handbook-trigger-gate.sh
  - core/hooks/lib/role-directive.sh
  - core/hooks/pretooluse_dispatcher.py
  - core/hooks/proposal-shape-gate.sh
  - core/hooks/record-fields-gate.sh
  - core/hooks/record-shape-gate.sh
  - core/hooks/survey-order-gate.sh
  - core/hooks/test_board_gate.py
  - core/hooks/tests/run-approval-gate-tests.sh
  - core/hooks/tests/run-board-gate-tests.sh
  - core/hooks/tests/run-canon-duplication-content-tests.sh
  - core/hooks/tests/run-citation-gate-tests.sh
  - core/hooks/tests/run-facet-keyword-gate-tests.sh
  - core/hooks/tests/run-gate-lib-tests.sh
  - core/hooks/tests/run-role-gates-tests.sh
  - core/hooks/tests/run-survey-order-gate-tests.sh
  - core/hooks/trailer-gate.sh
  - tests/test_ordering_gates_237.py
  - warrant/hooks/tests/run-directive-hunt-path-tests.sh
upstream:
  - path: PR #350 (issue-349, head commit 840b5fe)
    sha: 840b5fe065309faf2729e89e9da16fbcc6d87ae4
---

# issue-349 — adversarial-review-cf4fc041 record

## What was done

Independent adversarial verification of PR #350 (core#349: identifier renames,
core half of on-the-record#2600 slice 4). This session shares no context with
the PR's builder session; every claim below was re-derived from the PR head
(`840b5fe`, fetched as `pr-350-head`) and `origin/main` (`60cbcb5`) with fresh
commands, not read from the PR's own prose.

**Setup.** `git fetch origin pull/350/head:pr-350-head`; two throwaway
worktrees, `/tmp/core-main` (`origin/main`) and `/tmp/core-pr`
(`pr-350-head`), to run every comparison side-by-side without disturbing this
session's own branch.

**1. Failing-test sets, python3 -m pytest, as names not counts.**
checked: `cd /tmp/core-main && python3 -m pytest -q` and
`cd /tmp/core-pr && python3 -m pytest -q` — both: `3 failed, 79 passed`,
identical failing names on both trees:
```
FAILED tests/test_promoted_hooks.py::test_proposal_shape_gate_refuses_missing_sections
FAILED tests/test_promoted_hooks.py::test_survey_order_gate_refuses_proposal_without_survey_or_skip
FAILED tests/test_silent_failure_repros.py::test_A5_trailer_gate_quote_split_commit_is_detected
```
Set-equal. Matches the PR's claim.

**2. Failing-test sets, bash core/hooks/tests/run-all.sh, as names not counts.**
`run-all.sh` pipes every sub-suite through `tail -2`
(`core/hooks/tests/run-all.sh:14,17,20,...`), so its own output — and the
PR's own verification section, which only diffs those summary lines — never
carries test **names**, only counts. The acceptance requires names. Ran the
three sub-suites that show nonzero failures directly (bypassing `run-all.sh`)
on both trees:
```
board-gate:   FAIL   feasibility-spikes                 want=allow got=deny
              FAIL   ops-postmortems                    want=allow got=deny
approval-gate:FAIL   checkpoint-refusal-names-await-approval want=present got=absent
              FAIL   execute-without-remote             want=deny got=allow
dispatcher-equivalence: FAIL approval-gate: execution write, no approvers.md -> deny
```
Identical names, identical want/got, on both `/tmp/core-main` and
`/tmp/core-pr` (5 pre-existing failures total, matching the PR's "5
pre-existing shell-suite failures" count). Also diffed the two full
`run-all.sh` logs directly: `diff /tmp/main-run-all.log /tmp/pr-run-all.log`
— only difference is the embedded checkout path string and one latency
sample (43ms vs 40ms, both under the suite's 100ms threshold). Set-equal by
name; PR's claim holds, though its own record only established this by count.

**3. AST-walk-only claim — re-derived, not re-read.** Independently
re-implemented the AST walk (own script, not copy-pasted from the PR's
record) against `/tmp/core-pr`:
- Standalone `.py` files: 1 identifier-kind occurrence remains —
  `test/test_directive_injection.py:123`,
  `test_session_protocol_md_uses_generic_role_placeholder_not_dollar_role` —
  matching the PR's stated, deliberately-left Open finding (its own
  assertions pin `session-protocol.md`'s literal `<role>` placeholder text,
  a prompt/directive-text slice, not this PR's to rename).
- Embedded Python heredocs (`board-gate.sh`'s and `approval-gate.sh`'s
  `<<'PY'` blocks): extracted both with `awk`, parsed each with `ast.parse`
  (both parse clean) — 0 identifier-kind occurrences in either.
- Shell files: wrote an independent regex scan (assignment position and
  `${var}`/`$var` position, comments excluded, `core_role_directive`
  excluded by name) over every non-`docs/` `.sh` file — 0 hits.
Independently confirms the PR's "zero identifier-kind occurrences outside
the one deliberately-left exception" claim.

**4. Persisted-key claim — `.on-the-record/role.json`.** checked:
`git diff origin/main..pr-350-head -- core/hooks/board-gate.sh
core/hooks/tests/run-board-gate-tests.sh` — the only touches are
`_sidecar_role`→`_sidecar_skill` (a local Python binding) and
`sc_role`→`sc_skill` (a local shell binding); the JSON key itself,
`printf '{"role":"%s",...}'` and `_sidecar["role"]`, is untouched in both
files. Also grepped the whole `/tmp/core-pr` tree for any other
`"skill":`-shaped literal introduced by the diff (`git diff ... | grep
'"skill"\s*:'`) — none. No persisted key was renamed.

**5. Cross-repo exclusion — `core_role_directive()` / `role-directive.sh`.**
checked, against on-the-record's live checkout at `$ON_THE_RECORD`
(`git remote -v` confirms `origin/on-the-record.git`), not the PR's prose:
- `grep -rn "role-directive\.sh\|core_role_directive" --exclude-dir=.git
  --exclude-dir=docs .` inside `$ON_THE_RECORD` — 0 hits outside
  `runs/rulebooks/tokenmaxxxer-core/` (a mirrored copy of *this* repo's own
  rulebook, not on-the-record's own source calling the convention) and
  `docs/` (historical audit records, not live source). on-the-record's own
  Python orchestration code (`pipeline.py`, `directive_assembly.py`,
  `spawn.py`, `events.py`, `lifecycle.py`, `roster.py`) does **not** itself
  source or call this convention by name — it is a convention core ships
  for *other* consuming rulebook repos (accessibility-rulebook,
  finance-unit-economics-rulebook, coding, incident-response, etc., per
  `docs/reports/rulebook-hook-audit.md`'s historical catalogue), none of
  which are checked out in this environment. **This specific sub-claim —
  that those other repos' live `directive.sh` stubs still source
  `role-directive.sh` by that exact name today — is unverifiable from this
  machine** and is flagged as such rather than assumed true.
- What IS independently verifiable and checked: `core/hooks/lib/gate-lib.sh`
  (unchanged by this PR — not in its file list) contains
  `gate_is_role_directive_stub()`, which greps a target `directive.sh` for
  the literal strings `role-directive\.sh` and `core_role_directive`
  (`core/hooks/lib/gate-lib.sh:168-177`) to decide pass/fail compliance.
  This is a live, mechanical dependency on those exact spellings that this
  PR did not touch — independent confirmation that renaming either string
  would break `gate_is_role_directive_stub`'s own grep, regardless of what
  any external repo does. The PR's rationale is internally sound on this
  evidence even where the "every other repo" empirical premise could not be
  checked directly.
- checked: `sed -n '905,932p' pipeline.py` inside `$ON_THE_RECORD` —
  `_write_skill_sidecar()` (parameter already named `skill`) still writes
  `.on-the-record/role.json` with a literal `{"role": skill, ...}` JSON key
  today. checked: `grep -n '"role"' events.py lifecycle.py roster.py` —
  all three still use `"role"` as a live dict/board key. Confirms the PR's
  claim that on-the-record's persisted-key slice (slice 5) has not landed,
  so leaving `.on-the-record/role.json`'s key alone in core matches the
  live cross-repo contract, not a guess.
- No other identifier this PR renamed is read by on-the-record under its
  old name: the only renamed names on-the-record's own source touches at
  all are the `"role"` JSON/dict key (a persisted key, never touched by
  this PR) and the general English word "role" in prose — no renamed
  Python/shell identifier from this PR's file list appears anywhere in
  `$ON_THE_RECORD`'s non-docs source.

**6. docs/ diff.** checked: `git diff --name-status origin/main..pr-350-head
-- docs/` — exactly one line, `A
docs/issue-349/reports/refactoring-legacy-seam-selection+...-f1045776.md`.
Zero `M`.

**7. Compatibility alias.** checked: `grep -nE
'\bALIAS\b|_role_compat|role_alias|:-\$\{?role|# deprecated|# backward.compat'`
over the full PR diff — no hits. No dual-read/fallback shim introduced.

**8. Comment-staleness sweep (beyond the PR's own claimed 11 fixes).**
Found one surviving instance of the same defect class the PR's own
adversarial-review subagent was credited with hunting down — see Open
findings below.

Verdict: **pass, with one confirmed comment-staleness finding** the PR's own
review pass should have caught but didn't, and one claim (external-repo
`directive.sh` stubs) that is honestly unverifiable from this machine rather
than false — it is called out as unverified, not treated as failing.

## Why

Adversarial-review's core mechanism is structural session separation: this
session has no access to the builder's reasoning, so every negative claim
("failing-test set unchanged," "only identifiers touched," "no cross-repo
breakage") was re-executed from scratch rather than accepted from the PR's
prose. Where the PR's own verification took a shortcut (comparing shell-suite
*counts* instead of *names*, as literally required by the acceptance
criterion), that gap was closed independently rather than silently
inherited. Where a claim reached outside this machine's visibility (other
rulebook repos' live source), that boundary is stated explicitly rather than
converted into an unearned pass.

implementation-audit was reviewed and judged not applicable: this task
already supplies a concrete, closed list of falsifiable claims to verify
(the issue's own Acceptance section plus the task brief's five callouts) —
there is no separate claim-extraction step to run, and the required output
shape (executed command + output per negative claim) is what this record
already produces. work-in-english applies as normal project convention:
this record, all commands, and all reasoning are in English; only this
final chat summary is in Korean.

skill-verdict: adversarial-review — applied: invoked; every negative claim
in the task brief was re-derived with fresh commands in a fresh worktree
pair against the PR head and `origin/main`, per the skill's core mechanism
of structural session separation
skill-verdict: implementation-audit — not-applicable: the claims to verify
were already given as a closed, falsifiable list (issue Acceptance +
task brief); no separate claim-extraction pass was needed
skill-verdict: work-in-english — applied: invoked; record, commands, and
internal reasoning in English, final user-facing summary in Korean

## What did not work

None.

## Upstream basis

- PR #350, head commit `840b5fe` (fetched as `origin pull/350/head`) —
  the deliverable under review.
- `docs/issue-349/reports/refactoring-legacy-seam-selection+refactoring-legacy-verification-cadence+adversarial-review-f1045776.md`
  (same-commit as PR #350) — the builder's own record; read only to locate
  claims to independently re-check, never trusted as evidence on its own.
- `$ON_THE_RECORD` live checkout (`pipeline.py`, `events.py`, `lifecycle.py`,
  `roster.py`, `core/hooks/lib/gate-lib.sh`'s mirrored copy) — cross-repo
  verification surface for the persisted-key and cross-repo-exclusion
  claims.

## Open findings

1. **Confirmed — stale parameter-doc comment survives in
   `core/hooks/lib/role-directive.sh`.** Line 33 (PR head) reads:
   ```
   local skill="${CLAUDE_SKILL:-}"
     # Presence test (issue #327, per on-the-record #2538): OR of
     # TOKENMAXXXER_SPAWNED and role, not the new var alone — same rationale
     # as core's own directive.sh. The role NAME rendered below still comes
     # only from CLAUDE_SKILL (value-dependent).
     [ -n "${TOKENMAXXXER_SPAWNED:-}${skill}" ] || return 0
   ```
   checked: `git diff origin/main..pr-350-head -- core/hooks/lib/role-directive.sh`
   — the local variable was correctly renamed `role`→`skill` (and
   `role_upper`→`skill_upper` two lines further down), but the comment
   directly above it — "OR of TOKENMAXXXER_SPAWNED and role, not the new
   var alone" — still names the pre-rename identifier. This is exactly the
   defect class the PR's own record credits its adversarial-review subagent
   with hunting down and fixing (11 instances, all in test-harness files);
   this one instance, in the very file the PR discusses most carefully (the
   cross-repo-exclusion file), was not caught. It is misleading rather than
   behavior-breaking (the file's own header docstring above it still
   correctly describes the current contract), so it does not change the
   pass verdict, but it is a real, currently-live instance of the same
   class the PR claims a clean sweep on. Resolution path: a one-line
   comment fix (`role` → `skill` in that one comment), whenever this file
   is next touched — not urgent enough to justify reopening this PR solo.
2. **Noted, lower confidence — pre-existing (not introduced by this PR)
   twin-helper doc-comment drift in `core/hooks/tests/run-gate-lib-tests.sh`.**
   Line 285's `rf()` helper carries `# <want> <name> <role> <file_path>
   <content-json>`, while the adjacent, structurally identical `rfedit()`
   helper (same file, renamed by this PR at
   `core/hooks/tests/run-gate-lib-tests.sh:9-20` in the diff) now correctly
   reads `<skill>`. Unlike finding 1, `rf()`'s body never bound `$3` to a
   local variable (it uses the positional parameter directly), so there was
   no identifier for this PR's AST/grep-based rename to touch — checked:
   `git diff origin/main..pr-350-head -- core/hooks/tests/run-gate-lib-tests.sh`
   shows no hunk touching `rf()`'s definition at all. This predates the PR
   and is arguably out of this identifier-only slice's scope (the
   inconsistency is between two *comments*, not a renamed identifier and a
   stale comment about it) — flagged for completeness per the task's
   staleness-sweep request, not counted against the PR's own verdict.
3. **Unverifiable from this machine — the "every other repo's `directive.sh`
   stub" premise.** The PR's rationale for leaving `core_role_directive()`
   and `role-directive.sh` unrenamed rests partly on external rulebook
   repos (accessibility-rulebook, coding, incident-response, etc.) still
   sourcing/calling them by those exact names today; none of those repos
   are checked out in this environment, so that specific empirical claim
   could not be directly re-derived. The internal, checkable half of the
   same rationale — `core/hooks/lib/gate-lib.sh`'s
   `gate_is_role_directive_stub()` mechanically depending on those exact
   literal strings — was verified and holds regardless. Resolution path:
   whoever has access to one of those other repos' checkouts can close
   this with one `grep`; not blocking for this PR since the internal
   dependency alone already justifies the exclusion.

## Next steps

None outstanding for this verification. `loop_state` is `landed`; this
record is committed on its own in this branch/PR, independent of PR #350's
own branch.
