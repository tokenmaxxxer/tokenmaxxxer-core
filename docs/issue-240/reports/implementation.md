---
code_under_review:
  - core/hooks/ordering-gate.sh
type: refactor
breaking: false
verdict: blocked
loop_state: coding
---

# Implementation record — issue-240: consolidate role-scoped ordering gates

## What was done

Built `core/hooks/ordering-gate.sh`: a single parameterized dispatcher
that ports all 8 role-scoped ordering gates' mechanisms
(`survey-order-gate.sh`, `arch-sequence-gate.sh`,
`content-design-phase1-basis-gate.sh`, `devrel-phase-order-gate.sh`,
`incident-response-order-gate.sh`, `interaction-design-stage-order-gate.sh`,
`issue-retrospective-proposal-order-gate.sh`,
`security-threat-model-sequence-gate.sh`) into one script, per role table
entries dispatched first-match-wins, each mechanism a direct transcription
of the matching original script's Python logic (variable renames only),
each role's own kill-switch env var preserved.

Before wiring it into `hooks.json`, renaming the two test files' `run_gate`
calls, and deleting the 8 originals (steps 2-4 of the proposal's "What
will be done"), I discovered a reproducible conflict between the frozen
test suite's own assertions that makes step 1's stated success condition
("existing tests ... pass against the consolidated gate, assertions
unchanged") impossible to satisfy for 3 of the 30 tests. Per the
scope-exceeded rule (finish what can be verified, stop, report — never
silently narrow the acceptance criterion), I stopped here rather than
land a swap that fails its own acceptance check.

## Blocking finding (reproduced live)

`survey-order-gate.sh`'s surface regex is unscoped — it matches ANY
`docs/issue-<n>/proposals/*.md` write (not filename-scoped like the other
7 promoted gates), and requires
`docs/issue-<n>/reports/implementation/survey.md` to exist regardless of
which role's proposal is being written. This was true before this issue
and is explicitly out of scope to change (proposal Constraints: "no
further scoping change").

3 tests in `tests/test_ordering_gates_237.py` exercise a proposal path
that matches NO scoped role's regex (`docs/issue-1/proposals/consolidation.md`)
and assert `returncode == 0`, testing only that the promoted gate itself
(`arch-sequence-gate.sh` / `devrel-phase-order-gate.sh` /
`interaction-design-stage-order-gate.sh`) doesn't erroneously fire on a
foreign role's proposal — each passes today only because, run in
isolation, that gate's own scoped regex doesn't match, so it exits 0
without ever consulting `survey-order-gate.sh`'s separate, broader rule.

Once every role's mechanism lives in ONE script (as the consolidation
requires), the same input necessarily produces one deterministic output.
For `docs/issue-1/proposals/consolidation.md` with no survey anywhere on
disk, the input is structurally identical (same shape, same missing
state) to `tests/test_promoted_hooks.py`'s own
`test_survey_order_gate_refuses_proposal_without_survey_or_skip`, which
asserts `returncode == 2` on that same shape. No field in the tool-call
payload (path, content, or tool name) distinguishes "a foreign role wrote
this, survey-order shouldn't apply" from "this needs survey-order's
denial" — `run_gate()` passes no role/gate-identity signal, and per the
proposal all calls become `run_gate("ordering-gate.sh", ...)` uniformly.

Reproduced directly against the built `ordering-gate.sh`:

```
$ echo '{"tool_name":"Write","tool_input":{"file_path":"docs/issue-1/proposals/consolidation.md","content":"content"}}' \
    | CLAUDE_PROJECT_DIR=/tmp/gatetest1 PATH=/usr/bin:/bin:/usr/local/bin bash core/hooks/ordering-gate.sh
survey-order: refused — docs/issue-1/proposals/consolidation.md is a phase-1 proposal write for issue-1, ...
RC=2   # test_arch_sequence_gate_allows_foreign_role_proposal_without_survey (and the devrel/
       # interaction-design equivalents) assert RC==0 for this exact payload shape.

$ echo '{"tool_name":"Write","tool_input":{"file_path":"docs/issue-1/proposals/2026-08-21-thing.md","content":"..."}}' \
    | CLAUDE_PROJECT_DIR=/tmp/gatetest2 PATH=/usr/bin:/bin:/usr/local/bin bash core/hooks/ordering-gate.sh
survey-order: refused — ...
RC=2   # test_survey_order_gate_refuses_proposal_without_survey_or_skip asserts RC==2 for the
       # structurally identical payload shape — same script, same verdict, opposite expectation.
```

Affected tests (would flip from pass to fail if the swap landed as
proposed):
- `test_arch_sequence_gate_allows_foreign_role_proposal_without_survey`
- `test_devrel_phase_order_gate_allows_foreign_role_proposal_without_survey`
- `test_interaction_design_stage_order_gate_allows_foreign_role_proposal_without_artifacts`

The other 27 tests across both files (spot-checked: devrel allow/refuse,
content-design allow, empty-state passthrough — see below) are consistent
with the ported mechanisms and are expected to pass once wired.

## What did not work

- Attempted first-match-wins dispatch with survey-order as the final
  (broadest) fallback rule, matching the proposal's Rationale text
  verbatim. Expected: all 30 renamed tests pass. Actual: the 3 tests
  above fail, because survey-order's unscoped rule and its own refuse
  test use structurally identical payload shapes to the 3 "foreign role"
  tests but assert opposite return codes — a contradiction inherent to
  combining an unscoped gate and 7 scoped gates into one deterministic
  function, not a dispatch-ordering bug I could route around.

## Why

Landing the `hooks.json` swap, test-file rename, and 8-file deletion
together (as the proposal's steps 2-4 specify) would commit a change
whose own acceptance check (issue-240 acceptance #1: "existing tests ...
pass ... assertions unchanged") is unmeetable as literally stated. Per
the scope-exceeded rule and the platform's own precedent (issue-241's
survey PR stopped and reported an analogous ordering-gate deadlock rather
than build past it), I stopped at the point the conflict became
concrete and reproducible instead of silently relaxing "assertions
unchanged" by editing the 3 tests, or silently declaring the 3 failures
acceptable without flagging them.

## Upstream basis

docs/issue-240/proposals/consolidate-ordering-gates.md (approved via
`APPROVE issue-240/implementation`, single-account mode, by
JiwonJung94 — listed in docs/specs/approvers.md); docs/issue-240/reports/implementation/survey.md.

## Open findings

- **Blocking**: the 3-test conflict above. Needs a human call on how to
  resolve the contradiction in the frozen acceptance criteria, e.g.:
  (a) accept the 3 tests' outcome changing from 0 to 2 as a correction
      (they were only ever testing gate-isolation, not real pipeline
      behavior — in the live 8-gate `hooks.json` today, a foreign-role
      proposal with no survey anywhere IS already blocked by
      `survey-order-gate.sh` running as its own separate PreToolUse
      entry; the 3 tests' RC==0 expectation never reflected true
      end-to-end pipeline behavior), and update those 3 assertions
      explicitly (a scope change beyond "no payload or assert line
      changes", so it needs sign-off); or
  (b) scope `survey-order-gate.sh`'s regex narrowly as part of this
      issue after all (contradicts the proposal's "no further scoping
      change" constraint — also needs sign-off); or
  (c) keep survey-order-gate.sh as a 9th, separate script (not folded
      into the dispatcher), landing only a 7-gate consolidation — changes
      acceptance criterion 2's file-count math and needs sign-off on a
      narrower scope.

## Next steps

Once a human picks (a), (b), or (c) above (or another resolution), finish
steps 2-4 of the proposal on this same branch: wire `ordering-gate.sh` (or
a 7-gate variant) into `hooks.json`, apply the corresponding test-file
changes, delete the superseded original script(s), and record the
`hooks.json` `json.load` check plus `git diff --stat` file-count evidence
here.

## Resolution path

Re-open this record (loop_state stays `coding` until the human's answer
lands as a PR review comment or issue comment on #240), apply the chosen
resolution, re-run both test files via the fast tier, paste the full pass
output (including any SKIPPED lines) and the `hooks.json` validity check
into an updated version of this section, then flip `loop_state` to
`landed` and open the delivery PR carrying `Closes #240`.

## Rationale for deviations

Diverged from the approved proposal's "What will be done" steps 2-4
(wiring `hooks.json`, renaming test calls, deleting the 8 originals):
stopped after step 1 (writing `ordering-gate.sh`) instead of completing
the swap, because completing it would land a change that fails its own
acceptance criterion 1 for 3 of 30 tests, per the blocking finding above.
This is a scope-exceeded stop, not an alternative swap: the frozen
proposal's design (first-match-wins dispatch, survey-order carried over
verbatim and unscoped) is exactly what was built; the conflict is between
that design and the test suite's own pre-existing assertions, discovered
only once the 8 mechanisms were actually combined into one deterministic
script.
