---
issue: 305
role: conformance-review
author: conformance-review
loop_state: reported
upstream:
  - path: docs/issue-305/reports/conformance-review/survey.md
    sha: 35359fbc0734f785b6f494ffca08efd015eb155c
  - path: docs/issue-301/reports/observability.md
    sha: 220c22e7907d591c49a1575fe44d45231783328f
  - path: issue-305/implementation@183e2d3 (PR #313, unmerged, external branch)
    sha: 183e2d379ada4a1792b4ddc4282bd9c368e4fe60
---

# issue-305 — conformance-review record

## What was done

Independently re-executed, against the implementation branch's own tree
(via isolated git worktrees, never the review branch's own checkout), all
24 checkable requirements plus the 2 stated-Unverifiable requirements
extracted in `docs/issue-305/reports/conformance-review/survey.md`:
`core/hooks/tests/run-gate-shape-tests.sh` (18/18, python3 present) and
`core/hooks/tests/run-all.sh` (full sweep, two baselines); the
PATH-without-python3 live-fire repro for each of the 5 python3-missing
sites (`gh-guard.sh`, `approval-gate.sh`, `board-gate.sh`,
`pretooluse-dispatcher.sh`, `facet-keyword-gate.sh`); each of the 19
findings' own stated repro command (F1-F8, F10-F14, F21, F23) plus its
per-file test suite where one exists
(`run-hunt-tier-tests.sh` 15/0, `run-hunt-guard-tests.sh` 9/0,
`run-observe-tests.sh` 9/0, `run-citation-gate-tests.sh` 24/0,
`run-scope-gate-tests.sh` 46/0, `run-role-gates-tests.sh` 83/0,
`run-dispatcher-equivalence-tests.sh` 25/0); a diff inspection of every
touched commit against its pre-fix version to confirm the fail-open/
fail-closed exit-code branch for each mechanism; a diff inspection of PR
#313 against PR #306 (issue-303) and PR #307/#309 (issue-304) for
file/line-range overlap; and a file-scope trace of the full 16-file diff
for the consumer-tree-residue proxy (tree membership + hardcoded-path
grep). One verdict recorded per requirement below with file:line + commit
sha citations, per `conformance-review-verdict-assignment` and
`conformance-review-traceability-and-evidence`.

## Why

Per this role's own phase-1 proposal (`docs/issue-305/proposals/review-python3-consistency-silent-failure-sweep.md`):
this repo's verify-at-landing convention treats a deliverable as code plus
evidence produced by the role that stands behind it, so the implementation
record's own pasted repro output and pass counts are exactly the class of
claim a conformance review exists to independently confirm, not relay.
Every command below was re-run by this review, not copied from
`docs/issue-305/reports/implementation.md`.

## Upstream basis

- `docs/issue-305/reports/conformance-review/survey.md` (sha `35359fb`) —
  the 31 dimension-tagged requirement lines this record checks against.
- `docs/issue-301/reports/observability.md` (sha `220c22e`) — the
  originating Findings table (F1-F14, F16, F18, F21, F22, F23).
- `issue-305/implementation` branch, tip `183e2d3` (PR #313, unmerged) —
  the artifact under review. Individual per-finding commits cited inline
  below by their own sha (`7092f40`, `a824407`, `13f0d62`, `81d93d9`,
  `f2e6ff1`, `66b5a50`, `11a6bea`, `2429060`, `d4fe7b2`, `41904e4`,
  `9e0758a`), all reachable from `183e2d3`.
- `origin/main` tip `cd02e72` and merge-base `509759c` — used as the two
  candidate `run-all.sh` baselines for requirement 27 (see finding below).

## Findings

Per-requirement verdict blocks (`conformance-review-finding-record`).
Verdict set: Present | Surface | Absent | Incorrect | Unverifiable.

---
requirement: "1 — gh-guard.sh missing-python3 fail-closed now names the problem (F16)"
spec_ref: survey.md#1; observability.md F16
verdict: Present
evidence: core/hooks/gh-guard.sh:56 @7092f40; live PATH-without-python3 repro — `gh-guard: refused — python3 not found; cannot evaluate gate`, exit=2
rationale: Named message added on the exact fail-closed exit-code line; exit code unchanged (2).
---
requirement: "2 — approval-gate.sh missing-python3 fail-closed now names the problem (F18a)"
spec_ref: survey.md#2; observability.md F18
verdict: Present
evidence: core/hooks/approval-gate.sh:100 @7092f40; live repro — `approval-gate: refused — python3 not found; cannot evaluate gate`, exit=2
rationale: Same pattern as requirement 1, independently re-executed.
---
requirement: "3 — board-gate.sh missing-python3 fail-closed now names the problem (F18b)"
spec_ref: survey.md#3; observability.md F18
verdict: Present
evidence: core/hooks/board-gate.sh:73 @7092f40; live repro — `board-gate: refused — python3 not found; cannot evaluate gate`, exit=2
rationale: Same pattern as requirement 1, independently re-executed.
---
requirement: "4 — pretooluse-dispatcher.sh missing-python3 fail-closed, inline message, no gate-lib dependency added (F22)"
spec_ref: survey.md#4; observability.md F22
verdict: Present
evidence: core/hooks/pretooluse-dispatcher.sh:13 @7092f40; live repro — `pretooluse-dispatcher.sh: refused — python3 not found; cannot evaluate gate`, exit=2; inspection of the same hunk confirms a plain inline `echo ... >&2; exit 2`, no new `. gate-lib.sh` sourcing.
rationale: Both the functional fix and the dispatcher's own no-new-dependency design constraint hold.
---
requirement: "5 — facet-keyword-gate.sh bash-level python3 check demoted to advisory exit 0 (F9)"
spec_ref: survey.md#5; observability.md F9; issue-282 DEMOTE precedent
verdict: Present
evidence: core/hooks/facet-keyword-gate.sh:26-36 @7092f40; live repro — hookSpecificOutput advisory payload + `systemMessage`, exit=0 (was hard `gate_deny` exit 2 pre-fix)
rationale: The one site where the exit-code value itself changed (2→0) is exactly the intended demotion this requirement asks for, not an unintended decision drift.
---
requirement: "6 — run-gate-shape-tests.sh: 18/18, byte-identical with python3 present"
spec_ref: survey.md#6; issue's own stated acceptance gate
verdict: Present
evidence: `core/hooks/tests/run-gate-shape-tests.sh` independently re-run against `183e2d3` — `== 18 passed, 0 failed ==`, exit 0
rationale: Test-method verification (rule 4, reuse existing suite); matches implementation record's claim and this review's own independent run.
---
requirement: "7 — provenance for requirements 1-5 (executed-live PATH-without-python3 run for each site)"
spec_ref: survey.md#7
verdict: Present
evidence: same evidence as requirements 1-5 (collapsed per conformance-review-traceability-and-evidence rule 4 — identical evidence location and verdict reasoning, no distinct citation)
rationale: Subsumed by requirements 1-5's Demonstration evidence; recorded as a duplicate entry rather than re-cited.
---
requirement: "8 — F1: hunt-tier.sh distinguishes real git-diff failure from empty diff"
spec_ref: survey.md#8; observability.md F1
verdict: Present
evidence: warrant/hooks/hunt-tier.sh:38-48 @a824407; live repro — bad ref gives `reason=git-diff-failed(rc=128)`, genuinely empty diff still gives `reason=empty-diff`; `run-hunt-tier-tests.sh` 15/0
rationale: Two distinct reason codes now exist for two distinct conditions; regression suite clean.
---
requirement: "9 — F2: hunt-guard.sh refuses malformed JSON dispatch at session cap"
spec_ref: survey.md#9; observability.md F2
verdict: Present
evidence: warrant/hooks/hunt-guard.sh:99-115 @a824407; live repro at count=3 — named refusal message, exit=2, count file unchanged at 3
rationale: Exit-code branch changed 0→2 for this specific malformed-payload-at-cap condition; this is the requirement's own named "demonstrated silent-bypass path" exception to the decision-preserving invariant (requirement 25), not a violation of it.
---
requirement: "10 — F2 negative control: unrelated tool type still allows through unchanged"
spec_ref: survey.md#10; observability.md F2 (negative control)
verdict: Present
evidence: same malformed-JSON payload with `tool_name` for an unrelated matcher — exit=0, count file unchanged at 3
rationale: Confirms the fix is scoped to the Agent/Task/Workflow-mentioning case, not a blanket fail-closed on every JSON hiccup.
---
requirement: "11 — F3: corrupted .warrant-hunt.count refuses loudly instead of silently resetting"
spec_ref: survey.md#11; observability.md F3
verdict: Present
evidence: warrant/hooks/hunt-guard.sh:170-207 @a824407; live repro with `garbage-not-a-number` in the count file — named refusal, exit=2, file left unchanged (not reset to 0); `run-hunt-guard-tests.sh` 9/0
rationale: Silent-bypass path (reset to used=0) closed by refusing instead; matches requirement's own stated fix direction.
---
requirement: "12 — F4: scope-gate.sh missing-python3 fail-open now emits a stderr message"
spec_ref: survey.md#12; observability.md F4
verdict: Present
evidence: warrant/hooks/scope-gate.sh:25-34 @13f0d62; live repro — `scope-gate.sh: python3 not found; write-set enforcement is not evaluated for this call (fails open by design).`, exit=0
rationale: Fail-open exit code (0) unchanged, as the requirement demands; only the message is new.
---
requirement: "13 — F5: state.sh surfaces malformed-frontmatter proposals in a new section"
spec_ref: survey.md#13; observability.md F5
verdict: Present
evidence: warrant/hooks/state.sh:46-141 @81d93d9; live repro — a proposal with an unclosed opening fence now appears under a distinct "malformed — never picked up" section, exit=0
rationale: "No opening fence" (not a proposal) still silently skipped, confirmed distinct from the malformed case per the requirement's own carve-out.
---
requirement: "14 — F6: observe.sh appends an anomaly log row for unparseable payloads under FREELUNCH_ENFORCE=1"
spec_ref: survey.md#14; observability.md F6
verdict: Present
evidence: freelunch/hooks/observe.sh:45-64 @f2e6ff1; live repro — anomaly row `{"tool": "unknown", "violations": ["unparseable_payload"], "enforced": false, ...}` appended, never a deny; `run-observe-tests.sh` 9/0
rationale: Audit trail now records the unparseable case instead of leaving it silent, without converting it into a deny (tool_name unrecoverable from broken JSON, as required).
---
requirement: "15 — F7: terse.sh I/O read failure on terse.level embeds a NOTE in the emitted directive"
spec_ref: survey.md#15; observability.md F7
verdict: Present
evidence: terse/hooks/terse.sh:24-36 @66b5a50; live repro — chmod 000 on terse.level now embeds "NOTE: terse.level exists but could not be read..." inside the directive text, still falls back to full, exit=0
rationale: Same channel as the unrecognized-value case, as required; fallback behavior itself unchanged.
---
requirement: "16 — F8: facet-keyword-gate.sh distinguishes malformed FACET_KEYWORD_CONFIG from missing"
spec_ref: survey.md#16; observability.md F8
verdict: Present
evidence: core/hooks/facet-keyword-gate.sh:83-99 @11a6bea; live repro — malformed JSON now goes through `deny()` (visible, advisory exit 0); missing-file case unchanged (OSError path, still silent)
rationale: OSError/ValueError split matches the requirement's stated distinction exactly.
---
requirement: "17 — F10: handbook-trigger-gate.sh projects git add -A/--all/-u/--update into the staged-set pathspec"
spec_ref: survey.md#17; observability.md F10
verdict: Present
evidence: core/hooks/handbook-trigger-gate.sh:139-164 @2429060; live repro — a `git add -A` + operational-surface-file commit now correctly triggers the handbook-required denial, exit=0 (allow-path warning form) per the actual fixture used
rationale: `git add --dry-run` resolves the flags exactly like a real pathspec, closing the previously-silent gap.
---
requirement: "18 — F11: ordering-gate.sh fails closed on non-dict tool_input / non-string file_path"
spec_ref: survey.md#18; observability.md F11
verdict: Present
evidence: core/hooks/ordering-gate.sh:69-87 @d4fe7b2; live repro — malformed Write tool_input now refuses with a named reason, exit=2 (was silent fall-through to exit 0)
rationale: Exit-code branch changed 0→2 for exactly the malformed-schema condition the requirement names; the requirement 25 carve-out applies (closing a demonstrated silent-bypass path), not a violated invariant.
---
requirement: "19 — F12: ordering-gate.sh update_status declines to write back on corrupt .status.json"
spec_ref: survey.md#19; observability.md F12
verdict: Present
evidence: core/hooks/ordering-gate.sh:303-343 @d4fe7b2; live repro — corrupt status file left untouched (not reset to `{}`), named warning emitted, exit=0
rationale: Cross-issue status history for every other tracked issue is preserved instead of nuked.
---
requirement: "20 — F13: status write-back warning also emitted via hookSpecificOutput additionalContext"
spec_ref: survey.md#20; observability.md F13
verdict: Present
evidence: core/hooks/ordering-gate.sh:337-390 @d4fe7b2 (same commit as requirement 19, distinct hunk); live repro — write-back failure now surfaces in `hookSpecificOutput.additionalContext` on the allow path, exit=0
rationale: Visible on the allow path now, not only on stderr, as required.
---
requirement: "21 — F14: citation-gate.sh keeps the fail-closed EXIT trap armed through its own final exit"
spec_ref: survey.md#21; observability.md F14
verdict: Present
evidence: core/hooks/citation-gate.sh:676-685 @41904e4; live repro — a bad-regex config now raises inside Python (exit 1) and the still-armed trap remaps it to exit 2 (was raw exit 1, unblocking, pre-fix)
rationale: Exit-code branch changed 1→2, which is the requirement's own explicit ask (`trap - EXIT` removed); this is the named bypass-closure exception, not a drift.
---
requirement: "22 — F21: pretooluse_dispatcher.py merges every DEMOTE gate's finding into one combined stdout payload"
spec_ref: survey.md#22; observability.md F21
verdict: Present
evidence: core/hooks/pretooluse_dispatcher.py:527-539 @9e0758a; live repro — two simultaneously-tripped DEMOTE gates now both appear in one combined `hookSpecificOutput`/`systemMessage` stdout payload (previously only the first reached stdout)
rationale: Matches the requirement exactly; still exactly one JSON stdout payload per hook call.
---
requirement: "23 — F22 duplicate finding-number reference"
spec_ref: survey.md#23; observability.md F22 (same finding as requirement 4)
verdict: Present
evidence: same evidence as requirement 4 (collapsed per conformance-review-traceability-and-evidence rule 4)
rationale: observability.md lists F22 once; the survey's own item 23 already flags this as the same finding as requirement 4.
---
requirement: "24 — F23: OTR_DISPATCH_ONLY refuses loudly on a typo'd gate name"
spec_ref: survey.md#24; observability.md F23
verdict: Present
evidence: core/hooks/pretooluse_dispatcher.py:544-592 @9e0758a; live repro — typo'd gate name now prints the bad value + full registered-gate list and exits 2 (was a bare `return 0` indistinguishable from a clean gate run); correct gate name still produces its ordinary deny result with a different message
rationale: Exit-code branch changed 0(implicit-clean)→2(named refusal); named bypass-closure exception under requirement 25, matches the requirement's stated fix.
---
requirement: "25 — each of requirements 8-24 keeps its mechanism's pre-existing fail-open/fail-closed decision unchanged, except where a demonstrated silent-bypass path was itself the fix"
spec_ref: survey.md#25
verdict: Present
evidence: diff inspection per commit (a824407, 13f0d62, 81d93d9, f2e6ff1, 66b5a50, 11a6bea, 2429060, d4fe7b2, 41904e4, 9e0758a) against each file's pre-fix version — message-only, decision-preserving: F1, F4, F5, F6, F7, F8, F10, F12, F13, F21; decision changed as the requirement's own explicit fix description calls for (closing a named silent-allow/fall-through bypass): F2 (0→2), F3 (0→2), F9 (2→0, intended demotion, requirement 5), F11 (0→2), F14 (1→2), F23 (0→2)
rationale: Requirement 25's own wording carves out "a demonstrated silent-bypass path" as a legitimate decision change; every decision-changing fix here is exactly the bypass its own requirement (8-24) description names, not an undisclosed drift.
---
requirement: "26 — each of requirements 8-24 has a live-fire before/after repro in its own commit message"
spec_ref: survey.md#26
verdict: Present
evidence: same evidence as requirements 8-24 (collapsed per conformance-review-traceability-and-evidence rule 4)
rationale: Independently re-executed, not trusted from the commit messages alone; subsumed by 8-24's Demonstration verdicts.
---
requirement: "27 — full sweep run-all.sh: no NEW failures relative to baseline"
spec_ref: survey.md#27
verdict: Present
evidence: `run-all.sh` against merge-base `509759c` — `ALL OK`, exit 0, 0 failures; `run-all.sh` against implementation tip `183e2d3` — `ALL OK`, exit 0, 0 failures, identical to baseline
rationale: The proposal's planned baseline (tip-of-main) was corrected during evidence gathering: `origin/main` has advanced 6 unrelated commits since the branch forked, including a board-gate.sh role-key rename from a different issue, which produces 2 spurious failures unrelated to PR #313 when used as the comparison point. The true baseline is the fork point (`509759c`), and against that baseline both runs are clean — a stricter result than the implementation record's own claim of "two pre-existing/unrelated failures" (a latency flake and an approvers.md-dependent failure), neither of which reproduced in this review's re-runs. Recorded as an open finding below, not a defect: the actual requirement (no new failures) holds either way.
---
requirement: "28 — the 15-file diff does not overlap sibling issues #303 (F15/F17) or #304 (F19/F20)"
spec_ref: survey.md#28
verdict: Present
evidence: PR #313 shares 4 filenames with PR #306/#303 (`approval-gate.sh`, `board-gate.sh`, `gh-guard.sh`, `pretooluse_dispatcher.py`) and 0 filenames with PR #307/#309/#304; hunk-header line ranges in all 4 shared files are disjoint (e.g. board-gate.sh: #306's hunk ends at line ~54-70's `esac`, #313's hunk starts at line 73, the `command -v python3` line only)
rationale: No overlapping or reintroduced lines in either sibling issue's mechanism.
---
requirement: "29 — no added per-spawn overhead or steady-state load (operator-frozen constraint)"
spec_ref: survey.md#29
verdict: Unverifiable
evidence: no observable threshold or measurement baseline stated anywhere in the issue or the operator's comment
rationale: Per conformance-review-verdict-assignment rule 3, an unlocatable-evidence/no-stated-threshold case is recorded Unverifiable, never a favorable or unfavorable guess; same conclusion issue-304's review reached for the identical boilerplate constraint.
---
requirement: "30 — no new conflict surfaces, no stall/deadlock modes (operator-frozen constraint)"
spec_ref: survey.md#30
verdict: Unverifiable
evidence: no observable success condition stated
rationale: Same reasoning as requirement 29.
---
requirement: "31 — diff stays confined to this repo's own plugin tree, introducing nothing repo-specific a consumer repo would need to carry itself (consumer-tree-residue proxy)"
spec_ref: survey.md#31
verdict: Present
evidence: `git diff --stat 509759c 183e2d3` — 16 files changed, 543(+)/39(-): 9 under core/hooks/**, 4 under warrant/hooks/**, 1 under freelunch/hooks/**, 1 under terse/hooks/**, 1 under docs/issue-305/**; `git diff ... | grep -niE "/home/|/tmp/issue-305|/tmp/tmp\.|jwjung|self-hosted|hardcod"` on the same range returned no matches
rationale: Analysis-method proxy per the requirement's own framing (the true "any target repo" claim cannot be executed from inside this one repo); every touched file is within the allowed trees and no self-hosted-checkout-specific literal was introduced.
---

## Open findings

- Requirement 27's true `run-all.sh` baseline is the branch's fork point
  (`509759c`), not tip-of-main as this review's own proposal assumed —
  tip-of-main has since drifted with an unrelated board-gate.sh change
  that produces 2 spurious failures if used as the comparison point. Not
  a defect in PR #313; informational only, no resolution path needed.
- The implementation record's self-reported "two pre-existing/unrelated
  failures" (a latency flake, an approvers.md-dependent failure) did not
  reproduce in this review's independent re-runs at either baseline —
  both were completely clean. Not a defect (the actual acceptance
  criterion, no new failures, holds either way); noted for whoever next
  reads the implementation record so the discrepancy isn't mistaken for
  a regression.
- The delegated evidence-gathering pass disclosed one side effect outside
  the repo: its first (uncorrected) live-fire run of the F6/observe.sh
  repro appended one real anomaly row to this session's own
  `~/.claude/freelunch-observe.jsonl` before the destination was
  overridden via `FREELUNCH_OBSERVE_LOG` for subsequent runs. No repo
  file or tracked path was affected; recorded for transparency, no
  resolution path needed.

No other open findings. All 24 checkable requirements verdict Present;
the 2 operator-frozen constraints verdict Unverifiable as stated in the
phase-1 proposal; no Absent or Incorrect verdicts.

## Skill verdicts

skill-verdict: conformance-review-verdict-assignment — applied: invoked;
used to choose Present over Surface/Absent for every requirement above
where evidence showed the fix both exists and fires on the actual
condition (rule 1), to hold requirements 29-30 to Unverifiable rather than
a favorable guess given no stated threshold (rule 3), and to treat
requirement 25's decision-changing fixes (F2/F3/F9/F11/F14/F23) as the
requirement's own named exception rather than Incorrect (rule 2 applied
in reverse — these are not silent contradictions, they are the documented
bypass-closure the requirement itself calls for).
skill-verdict: conformance-review-finding-record — applied: invoked; used
to shape every requirement block above with the full field list
(requirement, spec_ref, verdict, evidence, rationale), one verdict from
the fixed five-value set per block, no bare pass/fail.
skill-verdict: conformance-review-traceability-and-evidence — applied:
invoked; used to cite file:line-range plus commit sha for every Present
verdict (rule 1), to collapse requirements 7, 23, and 26 into their
duplicate/subsuming requirement's evidence rather than re-deriving or
re-citing (rule 4), and to record one link per contributing commit where
a requirement's evidence spanned more than one commit (e.g. requirement
25's per-commit citation list) (rule 2).
other mounted skills: not triggered (conformance-review-severity-classification
— this review's scope was never extended into risk-weighting a finding;
the proposal asked only for verdict assignment, not severity bands, so
the trigger condition does not apply. conformance-review-requirement-extraction,
conformance-review-sampling-derivation, and
conformance-review-verification-method-selection were phase-1 concerns,
already invoked and recorded in `docs/issue-305/reports/conformance-review/survey.md`).

## Next steps

None — `loop_state: reported` is terminal for a `review-record`. This
issue's own acceptance criteria (18/18 `run-gate-shape-tests.sh`,
executed-live python3-missing provenance for the 5 sites) are both
independently confirmed above.
