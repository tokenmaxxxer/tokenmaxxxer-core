# Proposal: independent execution observation of issue-90's implementation pass (PR #91)

## Verdict levels this observation will check, and against what evidence

Declared up front, before anything else in this document, per the
role's phase-2 contract. All three levels will be addressed; a level
that turns out not to apply will be written as "not applicable, because
X" rather than dropped.

- **Outcome** — did PR #91 land what issue #90 asked for. Evidence:
  issue #90's body (defect 1, defect 2, and the three `## 제약`
  constraints) read against the `c66aecc` diffs of
  `core/hooks/board-gate.sh`, `core/hooks/approval-gate.sh`, and both
  harnesses, plus the `c66aecc^` blobs as the pre-change comparator.
- **Trajectory** — was the phase-1 → phase-2 path sound. Evidence:
  `d52d1e6` (docs-only propose commit) and its two files, issue #90
  comment 1 (`APPROVE issue-90/implementation`, author checked against
  `docs/specs/approvers.md`), PR #91's empty `reviews`/`comments`
  arrays, PR #91's body text, `c66aecc`'s `Closes #90` trailer, and
  issue #90 comment 2.
- **Step** — which specific artifact, if any, is deficient. Evidence:
  per-artifact, at file:line in `c66aecc` or `c66aecc^`, or at a line of
  `docs/issue-90/reports/implementation.md`.

No verdict is rendered in this proposal. Each level's answer is produced
only in phase 2, in
`docs/issue-90/reports/execution-observation.md`, and only after the
independence statement required by this role's record ordering.

## Request (paraphrased intent)

Judge independently whether merged PR #91 (commit `c66aecc`) actually
fixed the two defects issue #90 named, and whether the mitigation stayed
inside the gates' protection scope. The observed surfaces are
`_write_candidate_segments()`-based candidate scoping in
`core/hooks/board-gate.sh` and the `cd` listing, quote-aware `WRITEISH`,
and `_writeish()` in `core/hooks/approval-gate.sh`. The builder's own
record (`docs/issue-90/reports/implementation.md`) claims board-gate
67/0, approval-gate 42/0, and that it caught three cases spinning on
invalid JSON; those claims are to be confirmed independently rather than
taken on trust — in particular whether the deny cases deny for their
named reason and not through an incidental path such as a parse failure.
Observe only; do not fix.

## Constraints

- **Never re-run the observed role's work.** Neither gate nor either
  harness is executed in this observation. Admissible evidence is the
  PR, its commits, and the observed role's own record. This is a role
  prohibition, and it is also what the scouted field calls the
  artifact-only evidence standard
  (`docs/issue-90/reports/execution-observation/scout-brief.md`, source 6).
- **Never edit the observed artifact.** No file under `core/`,
  `test/`, `docs/handbooks/`, or `docs/issue-90/reports/implementation*`
  is touched. Findings return only through this role's own record and
  PR.
- **Never file an issue.** Under contract v3 issues are user-authored;
  a confirmed deficiency lands as a finding in the record, for the human
  to judge.
- **Citation discipline.** Every verdict-bearing sentence carries its
  source adjacent to it — commit sha, `file:line`, or comment URL.
- **Phase gate.** Phase 2 opens only on an issue-level comment whose
  whole body is exactly `APPROVE issue-90/execution-observation`, posted
  by an account in `docs/specs/approvers.md`. No such comment exists as
  of this writing, so this PR carries phase-1 artifacts only.

## What will be done (phase 2)

1. **Write the record first.** Create
   `docs/issue-90/reports/execution-observation.md` as the first act of
   phase 2, with the independence statement above any verdict language,
   and update its `loop_state` at each transition.
2. **Discrimination trace, per new test case (survey G2, G3).** For each
   of the 8 cases `c66aecc` added — board-gate `:269`, `:273`;
   approval-gate `:166`, `:169`, `:176`, `:177`, `:180`, `:186` — trace
   the case's literal command through the `c66aecc` code path and again
   through the `c66aecc^` code path, and record whether the two paths
   yield different verdicts. A case that yields the same verdict on both
   is recorded as non-discriminating, with the reason. This is the
   scout brief's adopted mutant-kill criterion applied statically.
3. **Deny-reason reachability trace (survey G4).** Both harnesses assert
   exit code only — `run-board-gate-tests.sh:22-28` with the gate's
   output discarded at `:42`, and `run-approval-gate-tests.sh:21-27`
   with output discarded at `:103`. For each deny case among the 8, name
   which `deny()` call site the traced path reaches, and state whether
   that is the deny the case name claims or an incidental one
   (unreadable payload, no-remote, wrong branch, foreign-path token
   scan).
4. **Protection-scope delta (survey G1).** Read `_split_segments` and
   the `SEGMENT`/`SUBSHELL`/`FILE_REDIR` definitions at `c66aecc` and
   determine whether moving the `SUBSHELL`/`FILE_REDIR` test from
   whole-probe (`c66aecc^:211-212`) to per-segment (`c66aecc:226`)
   changes which command lines reach the R4 candidate scan. Same for
   approval-gate: whether adding `cd` to `READ_ONLY_HEADS`
   (`c66aecc:85`) widens the early `allow()` at `:139` given that the
   file has no segment splitting and `head` is the whole line's first
   word (`:138`).
5. **Record-claim corroboration (survey G5, G6).** Recount both harness
   registration sets against the record's 67 and 42
   (`implementation.md:56-59`); state explicitly what a registration
   count does and does not corroborate about a pass count. Check whether
   the naive JSON builder left unchanged at
   `run-approval-gate-tests.sh:96-100` still produces invalid JSON for
   any *pre-existing* case. Check `code_under_review: d52d1e6`
   (`implementation.md:5`) and the five `closed_checks` `code_sha`
   values against the repo's record convention.
6. **Trajectory check (survey G7).** Establish the order of
   propose commit → approval comment → deliver commit from artifact
   timestamps; check the approver against `docs/specs/approvers.md`;
   record the standing of PR #91's phase-1-only body text against the
   code that landed under it, and of `Closes #90` against the
   unexhausted plan.
7. **Render the three-level verdict** with per-sentence citations, and
   for any deficiency, the four-part blameless shape — impact,
   timeline, root cause, action item — scaled to that one finding.

## Out of scope

- Executing either gate or either harness, in any form, including in a
  scratch copy.
- Any edit to the observed role's code, tests, handbooks, or record;
  any proposed patch text for them.
- Re-litigating issue #88 / PR #89, except where `c66aecc` cites them as
  the pattern it ports.
- Filing an issue for anything found.

## How you'll know it worked

- Every one of the 8 added cases has a recorded discrimination result
  and, where it is a deny case, a named deny path.
- All three verdict levels appear, each with adjacent citations, and the
  independence statement precedes all of them.
- The record's 67/0 and 42/0 claims are answered by what artifacts can
  and cannot show, without the suite having been re-run.
- `docs/issue-90/reports/execution-observation.md` is committed on
  `issue-90/execution-observation` and carried by this PR.

## Alternatives considered

- **Re-run both harnesses and compare to 67/0 and 42/0.** Rejected: this
  role's prohibition on re-executing the observed task, and re-execution
  would answer a weaker question than the discrimination trace anyway —
  a green re-run reproduces the same exit-code-only assertion that made
  the record's own vacuous-case episode possible
  (`implementation.md:61-81`).
- **Check out `c66aecc^` and run the new cases against it** to
  demonstrate mutant-kill empirically. Rejected for the same reason; the
  static trace over both blobs yields the same answer within the
  admissible evidence set.
- **Verdict on outcome only.** Rejected: the role's phase-2 contract
  requires all three levels.

## Failure signal

If the static trace cannot settle whether a given case discriminates —
for example because `_split_segments`' behaviour on a literal is
genuinely ambiguous from reading alone — that case is recorded as
**undetermined with the reason**, never as confirmed in either
direction. An observation that quietly converts "could not determine"
into "fine" is the failure mode this proposal is written to avoid.
