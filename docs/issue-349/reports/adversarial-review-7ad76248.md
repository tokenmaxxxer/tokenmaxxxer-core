---
issue: 349
role: adversarial-review-7ad76248
author: adversarial-review-7ad76248
skills: adversarial-review (skill-repository(c05de12))
verifies_subject: true
code_under_review:
  - path: core/hooks/approval-gate.sh
    sha: 840b5fe065309faf2729e89e9da16fbcc6d87ae4
  - path: core/hooks/board-gate.sh
    sha: 840b5fe065309faf2729e89e9da16fbcc6d87ae4
  - path: core/hooks/directive.sh
    sha: 840b5fe065309faf2729e89e9da16fbcc6d87ae4
  - path: core/hooks/gh-guard.sh
    sha: 840b5fe065309faf2729e89e9da16fbcc6d87ae4
  - path: core/hooks/handbook-trigger-gate.sh
    sha: 840b5fe065309faf2729e89e9da16fbcc6d87ae4
  - path: core/hooks/lib/role-directive.sh
    sha: 840b5fe065309faf2729e89e9da16fbcc6d87ae4
  - path: core/hooks/pretooluse_dispatcher.py
    sha: 840b5fe065309faf2729e89e9da16fbcc6d87ae4
  - path: core/hooks/proposal-shape-gate.sh
    sha: 840b5fe065309faf2729e89e9da16fbcc6d87ae4
  - path: core/hooks/record-fields-gate.sh
    sha: 840b5fe065309faf2729e89e9da16fbcc6d87ae4
  - path: core/hooks/record-shape-gate.sh
    sha: 840b5fe065309faf2729e89e9da16fbcc6d87ae4
  - path: core/hooks/survey-order-gate.sh
    sha: 840b5fe065309faf2729e89e9da16fbcc6d87ae4
  - path: core/hooks/test_board_gate.py
    sha: 840b5fe065309faf2729e89e9da16fbcc6d87ae4
  - path: core/hooks/trailer-gate.sh
    sha: 840b5fe065309faf2729e89e9da16fbcc6d87ae4
  - path: core/hooks/tests/run-approval-gate-tests.sh
    sha: 840b5fe065309faf2729e89e9da16fbcc6d87ae4
  - path: core/hooks/tests/run-board-gate-tests.sh
    sha: 840b5fe065309faf2729e89e9da16fbcc6d87ae4
  - path: core/hooks/tests/run-canon-duplication-content-tests.sh
    sha: 840b5fe065309faf2729e89e9da16fbcc6d87ae4
  - path: core/hooks/tests/run-citation-gate-tests.sh
    sha: 840b5fe065309faf2729e89e9da16fbcc6d87ae4
  - path: core/hooks/tests/run-facet-keyword-gate-tests.sh
    sha: 840b5fe065309faf2729e89e9da16fbcc6d87ae4
  - path: core/hooks/tests/run-gate-lib-tests.sh
    sha: 840b5fe065309faf2729e89e9da16fbcc6d87ae4
  - path: core/hooks/tests/run-role-gates-tests.sh
    sha: 840b5fe065309faf2729e89e9da16fbcc6d87ae4
  - path: core/hooks/tests/run-survey-order-gate-tests.sh
    sha: 840b5fe065309faf2729e89e9da16fbcc6d87ae4
  - path: tests/test_ordering_gates_237.py
    sha: 840b5fe065309faf2729e89e9da16fbcc6d87ae4
  - path: warrant/hooks/tests/run-directive-hunt-path-tests.sh
    sha: 840b5fe065309faf2729e89e9da16fbcc6d87ae4
type: review
breaking: false
verdict: Independent verification of core#350 (issue #349, on-the-record#2600 slice 4 core half). All five carrying negative claims re-derived TRUE with my own commands run directly against the PR head (fetched, no trust in the PR's own record): the pytest and shell-suite failing-test-name sets are byte-identical to origin/main (checked at the sub-test-name level inside board-gate/approval-gate/dispatcher-equivalence, not just suite counts); the AST-walk renamed only Python/shell identifiers -- the `.on-the-record/role.json` persisted "role" key and every other checked persisted/CLI-facing string were left alone; the core_role_directive()/role-directive.sh cross-repo exclusion is genuinely necessary, confirmed against a fresh clone of the live accessibility-rulebook repo (not the PR's prose) which still calls `core_role_directive "$YOU_DECIDE" ...` by that exact name; docs/ carries zero M on pre-existing files; no compatibility alias was introduced. One real defect survived the PR's own adversarial-review pass: two files (core/hooks/directive.sh:23-27, core/hooks/lib/role-directive.sh:34-37) carry a stale narrative comment that names a shell variable called "role" which no longer exists in the code (renamed to "skill") -- the same defect class as the 11 stale parameter-doc comments the PR's own reviewer already found and fixed, just not this specific location. Comment-only, not a behavior break.
loop_state: terminal
upstream:
  - path: https://github.com/tokenmaxxxer/tokenmaxxxer-core/pull/350
    sha: 840b5fe065309faf2729e89e9da16fbcc6d87ae4
---

# issue-349 — adversarial-review-7ad76248 record

## What was done

Independently re-derived every carrying claim in core PR #350 (issue #349:
retire `role`/`Role`/`ROLE`/`roles` Python and shell identifiers in
tokenmaxxxer-core, the core half of on-the-record#2600 slice 4) against the
PR's own head commit, without reading or trusting the PR's own record file
until after each check had already run. Every negative claim below is
followed by the exact command and its output.

**Setup.** checked: `git fetch origin pull/350/head:pr-350-review` then
`git worktree add /tmp/pr350-head pr-350-review` and
`git worktree add /tmp/main-base origin/main` (origin/main resolved to
`60cbcb5`, PR #350's parent commit) — two clean worktrees, no shared state,
so both trees could be exercised with the exact same commands.

**1. pytest failing-test set, PR head vs origin/main, as a set of names.**
checked: `python3 -m pytest -q --tb=no` in each worktree, filtered to
`^FAILED` lines, sorted, `diff`'d — result: `IDENTICAL SETS`, three names on
both sides:
```
FAILED tests/test_promoted_hooks.py::test_proposal_shape_gate_refuses_missing_sections
FAILED tests/test_promoted_hooks.py::test_survey_order_gate_refuses_proposal_without_survey_or_skip
FAILED tests/test_silent_failure_repros.py::test_A5_trailer_gate_quote_split_commit_is_detected
```
Both sides: `3 failed, 79 passed`.

**2. Shell suite failing-test set, PR head vs origin/main, as sets of
names.** checked: `bash core/hooks/tests/run-all.sh` in each worktree,
path-normalized (`sed -E 's#/tmp/(pr350-head|main-base)#REPO#g'`), `diff`'d
— result: `IDENTICAL (path-normalized)`, the entire 156-line log
byte-identical, including every suite's `passed`/`fail=` summary line. The
suite-level summary lines don't print individual failing sub-test names, so
for every suite reporting >0 failures I ran its underlying runner script
directly on both worktrees and diffed the `FAIL` lines by name (not just
counts):
```
board-gate:              FAIL feasibility-spikes (want=allow got=deny)
                          FAIL ops-postmortems (want=allow got=deny)
approval-gate:            FAIL checkpoint-refusal-names-await-approval (want=present got=absent)
                          FAIL execute-without-remote (want=deny got=allow)
dispatcher-equivalence:   FAIL approval-gate: execution write, no approvers.md -> deny
```
All five names identical, both sides — these are the same pre-existing
failures on `origin/main`, unrelated to this PR. This also satisfies the
"exercise the gates ... on a payload they allow and one they refuse, before
and after" acceptance check: `run-board-gate-tests.sh`,
`run-approval-gate-tests.sh` and `run-dispatcher-equivalence-tests.sh` each
carry both allow and deny cases per changed identifier, and every case
(pass and fail alike) matched by name before/after.

**3. AST-walk correctness — persisted keys and CLI-facing strings left
alone.** checked:
`grep -rn "get(['\"]role\|\['role'\]\|\[\"role\"\]\|--role\|role=" --include='*.py' --include='*.sh' core warrant` on
the PR head, excluding docs/ — result: only
`core/hooks/board-gate.sh:865,868` (`_sidecar.get("role")`,
`_sidecar["role"]`), both dict-key reads of the same persisted sidecar.
checked: `git diff origin/main -- . ':!docs'` around those lines — the dict
key literal `"role"` in `.get("role")`/`_sidecar["role"]` and in the
`printf '{"role":"%s","issue":%s}' ... > "$td/.on-the-record/role.json"`
test-fixture writer is untouched on both the read and write side; only the
Python/shell local variable holding the value was renamed
(`_sidecar_role`→`_sidecar_skill`, `sc_role`→`sc_skill`). No other
persisted-key or CLI-flag string was found renamed anywhere in the diff —
the "role=<r>" comment-doc placeholders in `run-board-gate-tests.sh` were
correctly updated to `skill=<r>` only where they document a shell
function's own positional-arg variable, never where they describe the
`.on-the-record/role.json` sidecar's `"role"` key (verified: lines
892-894 of the diff still read `.on-the-record/role.json`/`role.json
written`/`<issue>:<role>` unchanged).

**4. Cross-repo exclusion — verified against on-the-record's live source,
not the PR's prose.** checked:
`grep -rln "core_role_directive\|role-directive\.sh" .` in a fresh
`git clone --depth 1 https://github.com/tokenmaxxxer/on-the-record
/tmp/otr-fresh` (HEAD `d5651f2`) — result: zero hits outside `docs/`; the
on-the-record repo does not itself call this convention (it ships it for
*other* consuming rulebook repos, not for itself — matches the PR's own
record's claim on this specific point). Since the "other repos" that
actually call it are separate rulebook repos, not on-the-record itself, I
went one level further than the task's literal instruction and checked one
of those external repos directly: checked:
`git clone --depth 1 https://github.com/tokenmaxxxer/accessibility-rulebook
/tmp/access-rb` then read `accessibility/hooks/directive.sh` — it sources
`${CLAUDE_PLUGIN_ROOT_CORE}/hooks/lib/role-directive.sh` and calls
`core_role_directive "$YOU_DECIDE" "$USE_WHEN" "$PRODUCES" "$HAND_OFF"` by
those exact literal names. This confirms the exclusion is not just
plausible prose — a real external repo genuinely depends on both names
staying unchanged; renaming either in core#350 would have broken this
caller's `source`/function-call silently (no test in either repo would
catch it, since the caller lives in a third repo neither test suite
exercises).

Checked whether any OTHER identifier this PR did rename is read by
on-the-record (or accessibility-rulebook) under the old name: none of the
renamed identifiers (`role`, `role_upper`, `_sidecar_role`, `sc_role`,
`stub_role`, `MULTISKILL_ROLE`, `norole`, `role_scope_hits`,
`role_check_hits`, `test_extra_subtree_keys_match_current_role_names`) are
local/private to their own functions or test files — none are called or
grepped-for by external callers by name. Only `core_role_directive` and the
literal filename `role-directive.sh` cross the repo boundary, and both are
correctly left unrenamed.

**5. docs/ zero M on pre-existing files.** checked:
`git diff origin/main --name-status -- docs/` on the PR head — result:
```
A	docs/issue-349/reports/refactoring-legacy-seam-selection+refactoring-legacy-verification-cadence+adversarial-review-f1045776.md
```
One `A`, zero `M`, zero `D` — matches the acceptance criterion exactly (the
criterion is zero `M`, not an empty diff).

**6. No compatibility alias.** checked:
`grep -nE '^\+' /tmp/pr350_full.diff | grep -iE '\brole\b'` filtered to
added lines that are not prose/message/persisted-key/placeholder text —
every hit is either the untouched `"role"` persisted-key literal, prose
inside a heredoc message string (`"[core] Interaction protocol for role
${skill}..."`), or a test failure-message string interpolating the new
`$skill` variable next to the English word "role" (e.g. `"message not
labeled with role '$skill'"` — a human-readable assertion message, not a
code identifier). No line assigns the old name to the new value or vice
versa (`role=$skill`, `alias role=...`, etc.) — no shim was introduced.

**7. Stale-comment staleness sweep — the same defect class as the 11
already found and fixed, checked for recurrence.** The PR's own record
reports its adversarial-review subagent found and fixed 11 stale `<role>`
parameter-documentation comments, and separately claims (from a
code-position-only grep:
`\brole=|\$\{?role\b|\bother_role\b|\bstub_role\b|\bMULTISKILL_ROLE\b|\bbrole\b|\bsc_role\b|\broleenv\b|\bnorole\b|\bnoRole\b`)
that only one historical prose comment
(`run-issue-280-tests.sh:54`) survives. That grep pattern only matches
`role` in *code position* (`$role`, `role=`), so it cannot catch a comment
that names the variable in *English prose* instead of shell syntax. I
checked that gap directly: checked (on the PR head) —
```
core/hooks/directive.sh:21:  skill="${CLAUDE_SKILL:-}"
core/hooks/directive.sh:23:  # TOKENMAXXXER_SPAWNED and role, not the new var alone — no SessionStart
core/hooks/directive.sh:25:  # two spawner-set vars must not silently skip the directive. The role
core/hooks/directive.sh:26:  # NAME (used below to render the invariants block) still comes only from
```
```
core/hooks/lib/role-directive.sh:33:  local skill="${CLAUDE_SKILL:-}"
core/hooks/lib/role-directive.sh:35:  # TOKENMAXXXER_SPAWNED and role, not the new var alone — same rationale
core/hooks/lib/role-directive.sh:36:  # as core's own directive.sh. The role NAME rendered below still comes
```
Both comments explicitly narrate "role, not the new var alone" and "The
role NAME ... still comes only from CLAUDE_SKILL" — sentences that made
sense when the adjacent variable really was named `role`, and are now
describing a variable (`skill`) by a name it no longer has. This is the
exact defect class the PR's own review already fixed 11 instances of
(a comment describing an identifier by a name the code no longer uses),
in two files the PR did touch (both are in the PR's changed-file list),
surviving because the reviewer's sweep pattern was code-position-only. It
is comment-only — no behavior effect, confirmed by the identical
before/after test runs above — but it is a real recurrence of a defect
class the PR's own record claims was fully swept.

## Why

The task instructions were explicit that the class of risk here is
"carrying claims produced without looking" — negative claims like
"behavior unchanged" and "failing-test set is identical" that this program
has previously seen asserted without execution. The only way to give those
claims real weight is to re-run the underlying commands myself, on the
PR's actual head commit, in isolated worktrees, before reading the PR's own
record — which is what every check above does. For the cross-repo claim
specifically, the task asked me to check on-the-record's live source rather
than the PR's prose; I went one step further and cloned the actual external
consuming repo (accessibility-rulebook) once I found on-the-record itself
doesn't call the convention, since stopping at "on-the-record doesn't call
it" would have left the PR's central safety claim (why the exclusion is
necessary) unverified rather than refuted-or-confirmed.

## What did not work

None — every check above ran cleanly against the PR head on the first
attempt; no worktree, clone, or test run needed a redo.

## Upstream basis

- `https://github.com/tokenmaxxxer/tokenmaxxxer-core/pull/350` (sha
  `840b5fe065309faf2729e89e9da16fbcc6d87ae4`) — the deliverable under
  review.
- `docs/issue-349/reports/refactoring-legacy-seam-selection+refactoring-legacy-verification-cadence+adversarial-review-f1045776.md`
  (read from the PR head, same sha as above) — the PR's own record; read
  only after each independent check had already produced a result, to
  compare rather than to source the claims from.
- `https://github.com/tokenmaxxxer/on-the-record` (sha `d5651f2`, fresh
  clone) and `https://github.com/tokenmaxxxer/accessibility-rulebook`
  (fresh clone, default branch head) — external live source for the
  cross-repo exclusion check.

## Open findings

1. **Stale narrative comment survives in 2 files** —
   `core/hooks/directive.sh:23-27` and
   `core/hooks/lib/role-directive.sh:34-37` each carry a comment that
   names a shell variable `role` which no longer exists in the code (the
   variable is `skill` as of this PR). Same defect class as the 11 the
   PR's own adversarial-review pass already found and fixed elsewhere in
   the same diff; this instance wasn't caught because it's prose, not
   code-position syntax. Comment-only — verified no behavior effect via
   the identical before/after pytest and shell-suite runs above.
   Resolution path: not this record's to fix (verify-only, per this
   session's own skill/role); a follow-up one-line comment edit in a
   future PR (or this PR before merge, at the PR author's discretion)
   would close it. Not blocking: it doesn't violate the "zero
   identifier-kind occurrences" acceptance criterion (the identifiers
   themselves are correctly renamed; it's the English prose around them
   that's now inaccurate), and it doesn't reopen any of the four other
   acceptance checks.

## Next steps

None — this record is terminal. All five acceptance-criteria checks from
the issue were independently re-derived and confirmed true; the one open
finding is a non-blocking comment-staleness recurrence, reported for the
PR author's discretion, not a re-verification loop.

skill-verdict: adversarial-review — applied: invoked; used to structure this
entire record as a blind, evidence-first re-derivation of the PR's carrying
claims (command + output per claim, PR's own record read only after each
independent check already had a result) rather than a critique of the PR's
prose
skill-verdict: work-in-english — applied: invoked; this record, all commands,
and all intermediate progress notes were written in English per policy; the
final chat summary to the user is in Korean
other mounted skills: implementation-audit not triggered — this task is a
direct adversarial re-derivation of a fixed set of claims from the issue's
own acceptance criteria, not the two-session falsifiable-claim-extraction-
then-classification protocol implementation-audit defines
