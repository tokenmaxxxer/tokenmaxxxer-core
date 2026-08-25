---
issue: 304
role: conformance-review
kind: review-record
loop_state: reported
upstream:
  - path: docs/issue-304/reports/conformance-review/survey.md
    sha: same-commit
  - path: docs/issue-304/proposals/review-kill-switch-drift-propagation.md
    sha: same-commit
code_under_review: e9b4299b57e41fec5cbe1484a8f754937efd6472
subject: PR #307 (branch issue-304/implementation), commit e9b4299b57e41fec5cbe1484a8f754937efd6472
test: core/hooks/tests/run-directive-shape-tests.sh (issue #304's own named Acceptance gate)
result: passed
assertedBy: issue-304/conformance-review
---

# issue-304 — conformance-review record

## What was done

Independently re-graded PR #307 (`issue-304: propagate fixed
gate_kill_switch_active into 4 directive hooks (F19/F20)`,
`e9b4299b57e41fec5cbe1484a8f754937efd6472`) against the 14 requirements
extracted from issue #304 in phase 1
(`docs/issue-304/reports/conformance-review/survey.md`), reusing that
survey's verification-method selections per rule 4 (already selected,
not re-derived). For each requirement: read the diff against `main`
(`aaab9aeb7826fc79f8e712742b3430366200d488`) for the 4 changed hook
files plus the drift test, checked the `gate_kill_switch_active` helper
itself in `gate-lib.sh`, and independently re-executed the named gate —
`core/hooks/tests/run-directive-shape-tests.sh` — from this review's own
worktree checkout of the implementation branch (`git worktree add
/tmp/issue304-review-checkout issue-304-implementation-ref`), not
trusted from the implementation record's pasted output alone. All 14
requirements verdicted below; 12 Present, 2 Unverifiable (both
previously flagged in phase 1 as having no stated observable threshold —
confirmed still true on inspection, not newly discovered). No Absent or
Incorrect findings.

## Why

The issue's Acceptance section names one gate
(`run-directive-shape-tests.sh`) and one executed-live provenance
requirement; the phase-1 proposal committed this review to independently
re-running that gate rather than relaying the implementer's self-report,
since a conformance review that only reads another role's pasted output
verifies nothing the implementer didn't already claim. Full enumeration
(all 4 files, not a sample) was used because the issue's own Acceptance
text already states "for each of the 4 files" and the population is
only 4 — matching the phase-1 survey's stated derivation.

`skill-verdict: conformance-review-verdict-assignment — applied: invoked; used to choose Present vs Unverifiable for requirements 11-14 and to confirm Present (not Surface) for 1-10, 13 per rule 1 (checked the helper actually fires on the typo condition, not just that matching code exists)`
`skill-verdict: conformance-review-traceability-and-evidence — applied: invoked; every Present/Unverifiable verdict below cites file:line plus the exact commit sha read (e9b4299b57e41fec5cbe1484a8f754937efd6472), not a bare path`
`skill-verdict: conformance-review-finding-record — applied: invoked; the 14 verdict blocks below use this skill's field list (requirement/spec_ref/verdict/evidence/rationale) and only this role's own record file was written`
`skill-verdict: conformance-review-verification-method-selection — not-applicable: methods already selected by the phase-1 survey (Test for 1-9, Inspection+Test for 5, Inspection for 10/14, Unverifiable-stop for 11-12, Analysis for 13) and reused per rule 4, not re-derived this session`
`skill-verdict: conformance-review-requirement-extraction — not-applicable: the 14-item list was already extracted and frozen in phase 1 (survey.md); this session grades against it, it does not re-derive it`
`skill-verdict: conformance-review-sampling-derivation — not-applicable: phase 1 already found the issue's own Acceptance text states full enumeration ("for each of the 4 files") over a population of 4 — no sampling decision exists to make this session`
`skill-verdict: conformance-review-severity-classification — not-applicable: no scope extension into risk-weighting was requested; ordinary Present/Unverifiable fidelity verdicts only`

## Upstream basis

`docs/issue-304/reports/conformance-review/survey.md` (`same-commit`,
requirement extraction + method selection, phase 1) and
`docs/issue-304/proposals/review-kill-switch-drift-propagation.md`
(`same-commit`, phase-1 proposal, approved via the issue-304 issue
comment `APPROVE issue-304/conformance-review`). Reviewed artifact:
PR #307 / branch `issue-304/implementation`, commit
`e9b4299b57e41fec5cbe1484a8f754937efd6472`, diffed against `main`
(`aaab9aeb7826fc79f8e712742b3430366200d488`).

## Requirement verdicts

<!-- one block per conformance-review-finding-record's field list -->

---
requirement: role-directive.sh's inline kill-switch case statement replaced by a call to gate_kill_switch_active
spec_ref: issue #304 body, paragraph 1 ("role-directive.sh and three sibling *-directive.sh hooks still carry the inline pre-fix case statement")
verdict: Present
evidence: core/hooks/lib/role-directive.sh:28 (sources gate-lib.sh), :39 (`gate_kill_switch_active "$off_val" || return 0`), commit e9b4299b57e41fec5cbe1484a8f754937efd6472
rationale: the hand-rolled `case "$off_val" in ""|0|false|no|off) ;; *) return 0 ;; esac` is gone; the function now calls the shared helper and returns based on its result
---

---
requirement: proposal-shape-directive.sh's inline kill-switch case statement replaced by a call to gate_kill_switch_active
spec_ref: issue #304 body, paragraph 1
verdict: Present
evidence: core/hooks/proposal-shape-directive.sh:12-13, commit e9b4299b57e41fec5cbe1484a8f754937efd6472
rationale: sources gate-lib.sh and calls `gate_kill_switch_active "${PROPOSAL_SHAPE_OFF:-}" || exit 0`, replacing the pre-fix inline case
---

---
requirement: record-shape-directive.sh's inline kill-switch case statement replaced by a call to gate_kill_switch_active
spec_ref: issue #304 body, paragraph 1
verdict: Present
evidence: core/hooks/record-shape-directive.sh:15-16, commit e9b4299b57e41fec5cbe1484a8f754937efd6472
rationale: sources gate-lib.sh and calls `gate_kill_switch_active "${RECORD_SHAPE_OFF:-}" || exit 0`, replacing the pre-fix inline case
---

---
requirement: survey-order-directive.sh's inline kill-switch case statement replaced by a call to gate_kill_switch_active
spec_ref: issue #304 body, paragraph 1
verdict: Present
evidence: core/hooks/survey-order-directive.sh:13-14, commit e9b4299b57e41fec5cbe1484a8f754937efd6472
rationale: sources gate-lib.sh and calls `gate_kill_switch_active "${SURVEY_ORDER_OFF:-}" || exit 0`, replacing the pre-fix inline case
---

---
requirement: a drift test exists that fails if the pre-fix hand-rolled off-spelling case branch reappears in any of the 4 files
spec_ref: issue #304 body, paragraph 1 ("add a drift test that fails if a new inline reimplementation appears")
verdict: Present
evidence: core/hooks/tests/run-directive-shape-tests.sh:173-179 (joined-line regex `\*\)[[:space:]]*(exit|return)[[:space:]]+0[[:space:]]*;;` against all 4 files, plus a `gate_kill_switch_active` presence check per file), commit e9b4299b57e41fec5cbe1484a8f754937efd6472; independently re-executed, all 8 assertions (4 files x 2 checks) pass — see the pasted run below
rationale: the guard is joined-line (catches a branch split across physical lines), covers both the `exit 0` shape (3 top-level scripts) and `return 0` shape (role-directive.sh), and was re-run from this review's own checkout, not just inspected as static text
---

---
requirement: acceptance gate core/hooks/tests/run-directive-shape-tests.sh passes overall, independently re-executed by this review
spec_ref: issue #304 Acceptance ("gate: core/hooks/tests/run-directive-shape-tests.sh")
verdict: Present
evidence: independent re-run from /tmp/issue304-review-checkout (worktree of commit e9b4299b57e41fec5cbe1484a8f754937efd6472) — `directive-shape: 31 passed, 0 failed`; full pasted output below
rationale: re-executed from this review's own checkout rather than trusted from docs/issue-304/reports/implementation.md's pasted output; the two match exactly (31/0), independently confirming the implementer's self-report
---

---
requirement: empty state (kill-switch env var unset) leaves each of the 4 hooks active, unchanged, for every file
spec_ref: issue #304 Acceptance ("empty state: kill-switch unset — all four hooks active, unchanged")
verdict: Present
evidence: run-directive-shape-tests.sh:123 (proposal/record/survey-order-directive.sh) and :155 (role-directive.sh) — "kill-switch unset (empty state) — hook active", `present` x4 in the re-run below
rationale: all 4 unset-state assertions report `present` (hook fired) in the independently re-executed run, matching pre-fix baseline active behavior
---

---
requirement: a typo value in the kill-switch env var keeps each of the 4 hooks ACTIVE (previously: silently disabled — the bug being fixed)
spec_ref: issue #304 Acceptance ("provenance: executed-live ... typo value keeps the hook ACTIVE (was: disabled)")
verdict: Present
evidence: run-directive-shape-tests.sh:126 (proposal/record/survey-order-directive.sh) and :158 (role-directive.sh) — "typo value ... keeps hook ACTIVE (was: disabled)", `present` x4 in the re-run below
rationale: all 4 typo-value assertions report `present` (hook still fired on `typo-not-a-real-spelling`), confirming the fix — this is the exact condition the pre-fix inline case got backwards
---

---
requirement: the exact on-spelling '1' in the kill-switch env var disables each of the 4 hooks (regression check)
spec_ref: issue #304 Acceptance ("exact '1' disables")
verdict: Present
evidence: run-directive-shape-tests.sh:129 (proposal/record/survey-order-directive.sh) and :161 (role-directive.sh) — "exact '1' ... disables hook", `absent` x4 (hook did not fire) in the re-run below
rationale: all 4 on-spelling assertions report `absent` (hook correctly suppressed), confirming the real off-switch still works after the fix
---

---
requirement: acceptance provenance must be executed-live — a real command and its real pasted output in the record, not an asserted/typed-up pass count
spec_ref: issue #304 Acceptance ("provenance: executed-live ... paste real output")
verdict: Present
evidence: docs/issue-304/reports/implementation.md, "## Acceptance evidence" section (pastes the full `run-directive-shape-tests.sh` command and its 31/0 output, plus compliance-check.sh before/after and gate-lib.sh regression counts); this review's own independent re-run below reproduces the identical 31/0 count
rationale: the implementation record's pasted output is not merely asserted — this review independently re-ran the same gate from a separate checkout and got the identical count, which is the cross-check this requirement exists to enable
---

---
requirement: no consumer-tree residue — the change is confined to this repo's own plugin tree plus this role's own docs/issue-304/ area, introducing nothing a consumer repo would need to carry itself
spec_ref: issue #304 body, "Operator-frozen constraint" paragraph ("no consumer-tree residue")
verdict: Present
evidence: `gh pr view 307 --json files` file list — core/hooks/lib/role-directive.sh, core/hooks/proposal-shape-directive.sh, core/hooks/record-shape-directive.sh, core/hooks/survey-order-directive.sh, core/hooks/tests/run-directive-shape-tests.sh, docs/issue-304/reports/implementation.md; commit e9b4299b57e41fec5cbe1484a8f754937efd6472
rationale: every touched path is under core/hooks/** (this plugin's own tree) or docs/issue-304/** (a role's own record area); this is a proxy check by Analysis (per phase-1 method selection) since "any target repo" cannot be executed against from inside this one repo — no file outside this repo's own tree is touched, so nothing propagates to a consumer repo by this change alone
---

---
requirement: unavoidable trade-offs are measured and stated in the record
spec_ref: issue #304 body, "Operator-frozen constraint" paragraph ("unavoidable trade-offs measured and stated in the record")
verdict: Present
evidence: docs/issue-304/reports/implementation.md frontmatter `breaking: "no — kill-switch behavior only changes for previously-typo'd/garbage off-var values..."` plus the "## Acceptance evidence" regression-check subsection (gate-lib.sh 63/3 -> 64/2 before/after, with the 2 remaining failures named as pre-existing and out of scope, and the CORE_BUILD_NOW ambient-env artifact named as environment-timing, not a regression)
rationale: the record measures the change's actual effect (regression suite before/after, explicitly naming what changed and what didn't) and states the `breaking: no` determination with its reasoning; since the measurement found no unavoidable trade-off from this specific fix, stating that explicitly (rather than omitting the section) satisfies the requirement — there being no trade-off found is itself a stated, measured conclusion, not a gap
---

---
requirement: no added overhead/load (operator-frozen constraint)
spec_ref: issue #304 body, "Operator-frozen constraint" paragraph ("no added overhead/load")
verdict: Unverifiable
evidence: no observable threshold or measurement method is stated anywhere in the issue for "overhead/load" — not what it is measured against, what baseline, or what counts as "added"
rationale: per conformance-review-verdict-assignment rule 3, an unlocatable-evidence case is Unverifiable, never a favorable or unfavorable guess; inventing a numeric bar the issue itself omits would fabricate confidence this review does not have. Confirmed unchanged from the phase-1 survey's same finding — re-checked, not newly discovered
---

---
requirement: no new conflict/stall surfaces (operator-frozen constraint)
spec_ref: issue #304 body, "Operator-frozen constraint" paragraph ("no new conflict/stall surfaces")
verdict: Unverifiable
evidence: no observable success condition or reproduction target is stated anywhere in the issue for "conflict/stall surfaces"
rationale: same as the overhead/load requirement immediately above — rule 3 applies identically; confirmed unchanged from phase 1
---

## Independently re-executed acceptance gate (executed-live)

```
$ cd /tmp/issue304-review-checkout   # git worktree of commit e9b4299b57e41fec5cbe1484a8f754937efd6472
$ env -u CORE_BUILD_NOW bash core/hooks/tests/run-directive-shape-tests.sh
ok     names spec-index regeneration before docs/specs edits        present
ok     names the Closes/Fixes phase split for non-coding roles      present
ok     names verify-at-landing and pasted-output fidelity           present
ok     cites no phantom enforcement scripts                         absent
ok     states the phase contract conditionally (default + checkpoint) present
ok     empty-state fixture (no spec-index rule) has no spec_index.py mention absent
ok     empty-state fixture (no phase-split rule) has no plain #<issue> mention absent
ok     empty-state fixture (no test-claim rule) has no SKIPPED mention absent
ok     bypass fixture (disconnected bullets) is not accepted as the phase-split rule absent
ok     names the build-now bypass and its spawner-only env var      present
ok     empty-state fixture (no build-now rule) has no CORE_BUILD_NOW mention absent

--- issue-304: kill-switch drift, executed live ---
ok     proposal-shape-directive.sh: kill-switch unset (empty state) — hook active present
ok     proposal-shape-directive.sh: typo value in $PROPOSAL_SHAPE_OFF keeps hook ACTIVE (was: disabled) present
ok     proposal-shape-directive.sh: exact '1' in $PROPOSAL_SHAPE_OFF disables hook absent
ok     record-shape-directive.sh: kill-switch unset (empty state) — hook active present
ok     record-shape-directive.sh: typo value in $RECORD_SHAPE_OFF keeps hook ACTIVE (was: disabled) present
ok     record-shape-directive.sh: exact '1' in $RECORD_SHAPE_OFF disables hook absent
ok     survey-order-directive.sh: kill-switch unset (empty state) — hook active present
ok     survey-order-directive.sh: typo value in $SURVEY_ORDER_OFF keeps hook ACTIVE (was: disabled) present
ok     survey-order-directive.sh: exact '1' in $SURVEY_ORDER_OFF disables hook absent
ok     role-directive.sh: kill-switch unset (empty state) — hook active present
ok     role-directive.sh: typo value in $IMPLEMENTATION_CYCLE_OFF keeps hook ACTIVE (was: disabled) present
ok     role-directive.sh: exact '1' in $IMPLEMENTATION_CYCLE_OFF disables hook absent
ok     proposal-shape-directive.sh: no hand-rolled '*) exit|return 0 ;;' off-spelling branch (drift guard) absent
ok     proposal-shape-directive.sh: calls gate_kill_switch_active   present
ok     record-shape-directive.sh: no hand-rolled '*) exit|return 0 ;;' off-spelling branch (drift guard) absent
ok     record-shape-directive.sh: calls gate_kill_switch_active     present
ok     survey-order-directive.sh: no hand-rolled '*) exit|return 0 ;;' off-spelling branch (drift guard) absent
ok     survey-order-directive.sh: calls gate_kill_switch_active     present
ok     role-directive.sh: no hand-rolled '*) exit|return 0 ;;' off-spelling branch (drift guard) absent
ok     role-directive.sh: calls gate_kill_switch_active             present

directive-shape: 31 passed, 0 failed
```

Identical pass/fail count (31 passed, 0 failed) to the implementation
record's own pasted run — independently reproduced, not relayed.

## Open findings

None. 12 of 14 requirements Present; the remaining 2 (overhead/load,
conflict/stall surfaces) are Unverifiable-as-written per the issue's own
missing threshold, not open — there is no further evidence this review
could locate or produce for them, and no resolution path exists short of
the issue author stating a measurable bar. No Absent or Incorrect
findings, so no fix is being requested back to the implementation role.

## Next steps

None — loop_state: reported (terminal for this record kind).
