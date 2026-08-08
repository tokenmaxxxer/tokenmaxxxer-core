---
code_under_review:
  - `core/hooks/record-fields-gate.sh`
  - `core/hooks/tests/run-role-gates-tests.sh`
  - `docs/handbooks/role-gates-tests.md`
loop_state: delivered
---

# Implementation record — issue-153

Phase 2, approved proposal:
`docs/issue-153/proposals/2026-08-08-narrow-sha-scan-scope-and-empty-value-carveout.md`.

## Why

Issue #153 is the follow-up to two findings the execution-observation role
left against PR #134 (issue-133's value allow-list): the value check
scanned an entire reconstructed document instead of the frontmatter block
the `upstream:` convention actually lives in, so a record or proposal
quoting a non-conforming value outside frontmatter — exactly what a
document about this defect class needs to do — was denied the same as one
carrying the value live; and the issue-133 requirement-1 empty-value
carve-out was never delivered, with a newline-swallowing capture bug
misnaming the offending line in the denial. The approved proposal bounds
the check to the leading frontmatter block, fixes the value-side capture
so it cannot cross a line break, strips a trailing YAML comment, and
carves out a present-but-empty value.

## What was done

1. `core/hooks/record-fields-gate.sh`, `placeholder_shas`:
   - Added a frontmatter-boundary extraction (anchored `---` fence pair,
     matched from the start of the text; the closing anchor matches
     end-of-line or end-of-string) and ran the existing field scan against
     that substring only; a document with no such block yields an empty
     scan region.
   - Narrowed the post-colon whitespace in the field-value pattern to
     horizontal-only, so the captured value can never cross a line break.
   - Added trailing-YAML-comment stripping before validation, and an
     empty-value carve-out (a present, value-less line is skipped rather
     than flagged).
   - Before-landing hunt (stance 0, see Hunt below) found the new
     frontmatter anchor itself was bypassable: `re.match` requires the
     very first character of the text to start the fence, so a leading
     byte-order-mark on the written content made the anchor fail entirely
     and silently emptied the scan region regardless of what the
     frontmatter actually carried. Fixed by stripping a leading mark from
     the text before anchoring.
2. `core/hooks/tests/run-role-gates-tests.sh`:
   - Added the F1/F2 red→green and regression cases the proposal
     specified: fenced-block quotation outside frontmatter now allowed;
     the identical value inside frontmatter's own entry still denied; a
     frontmatter-only document with no trailing newline after the closing
     fence still denied (the after-proposal hunt's own finding, already
     folded into the approved design before phase 2 began — pinned here as
     a regression case); a conforming value plus a trailing comment now
     allowed; a value-less line followed by another entry now allowed with
     no denial at all; a genuinely bad value in that same shape denies and
     names its own line, not the following line's text.
   - Added a regression case for the before-landing hunt's mark-bypass
     finding.
   - Wrapped the pre-existing issue-128/133 fixtures' `upstream:` blocks in
     the same frontmatter fence every real record and proposal in this
     repository actually uses (see "What did not work" below) — same
     expected verdicts, realistic shape.
3. `docs/handbooks/role-gates-tests.md`: extended the paragraph describing
   the check to state the scan region, the empty-value carve-out, and the
   comment-stripping behavior.

## What did not work

- Expected: the proposal's own text ("existing … cases (issue-128/133)
  keep their current verdicts unchanged") implied the pre-existing
  fixtures would keep passing unmodified once the fix landed. Actual: 5 of
  9 did not — those fixtures wrote the `upstream:`/value block as flat
  content with no frontmatter delimiters (unlike every real corpus
  document, confirmed by the survey), so the frontmatter-bounded scan
  found no region to check and several deny-expecting cases flipped to
  allow. Fixed by wrapping those fixtures in the same fence real documents
  carry; verdicts are unchanged, only the fixture shape is now realistic.

## Rationale for deviations

The before-landing hunt (stance 0, mandated by the role's hunt cadence)
found a bypass the approved proposal's `## What will be done` did not
anticipate or list: a leading byte-order-mark on the written content
defeats the new frontmatter anchor entirely, silently emptying the scan
region and letting any value through regardless of what the frontmatter
carries. This is not a scope-exceeded stop — the fix stays inside
`placeholder_shas`, the same function in the same already-frozen file —
and not an alternative swap; it is an addition the proposal's text did not
cover. Left unfixed it would have shipped a second, narrower bypass of the
exact property F1 exists to preserve (a bad value sitting live inside real
frontmatter must still be denied), so it was fixed in this same commit
rather than deferred. The finding and its resolution are both recorded in
`docs/reports/2026-08-08-hunt-issue-153-narrow-sha-scan-scope-and-empty-value-carveout.md`.

## Class census (issue #153 requirement 3)

No new judgment beyond the phase-1 survey/proposal: `code_under_review`'s
enumerate-bad-shape check remains a recorded, accepted limitation (a real
second instance of a related-but-distinct class, no demonstrated or
plausible harm, out of this issue's stated scope) — see the proposal's
Rationale, unchanged by phase-2 execution.

## Test results (as run)

- `bash core/hooks/tests/run-role-gates-tests.sh` → `56 passed, 0 failed`
  (49 pre-existing, 5 of which had their fixtures reshaped per "What did
  not work" above, plus 7 new issue-153 cases including the before-landing
  hunt's regression pin).
- Red→green, directly observed: with only the frontmatter-boundary/value
  pattern/comment-strip/carve-out change reverted (`git stash` on just
  `record-fields-gate.sh`, new test cases left in place) and the suite
  re-run, exactly 3 of the new F1/F2 cases failed as expected — the
  fenced-block-quotation case, the trailing-YAML-comment case, and the
  empty-value carve-out case — with every other case (old and new)
  unaffected; restoring the change turned all 3 green with no other change
  in outcome.
- The before-landing hunt's own reproduction (in the hunt record) shows
  the mark-bypass red state directly against the real hook subprocess
  (exit 0, no denial) before this record's fix; after the fix, the
  regression case added to the suite denies it (exit 2) — confirmed by
  this session's own run of the full suite above, not re-derived from the
  hunter's report alone.
- `bash core/hooks/tests/run-all.sh` → `ALL OK` across every sibling-plugin
  and core-hooks suite.

## Doc placement

- [x] `docs/handbooks/role-gates-tests.md` — scan region, empty-value
  carve-out, and comment-stripping documented (this issue's check
  behavior changed; same-turn handbook update per the doctrine ladder).
- No `docs/issue-153/decisions/` entry: no new dependency, env var, config
  key, migration, or public signature/wire-format change; the
  format/parsing-approach choices (bounded regex vs. skip-fenced-regions
  vs. a YAML library) were already decided and recorded in the phase-1
  proposal's Rationale, unchanged by execution. The before-landing hunt's
  mark-strip addition is a bug fix inside the already-decided approach,
  not a new named-alternative choice — recorded above instead.
- No `docs/issue-153/reports/` benchmark/investigation doc beyond this
  record and the hunt file: no performance measurement was taken.

## Hunt

- After-proposal (phase 1, stance 0): FINDING — a frontmatter-only
  document with no trailing newline after the closing fence emptied the
  scan region under an earlier draft pattern; folded into the approved
  proposal's design (the closing anchor matches end-of-line or
  end-of-string) before phase 2 began. Pinned as a dedicated regression
  case in this delivery.
- Before-landing (phase 2, stance 0): FINDING — the byte-order-mark bypass
  described above; resolved in this same commit, regression-pinned.
- Both recorded in full at
  `docs/reports/2026-08-08-hunt-issue-153-narrow-sha-scan-scope-and-empty-value-carveout.md`.
- closed_checks: F1 red→green (fenced-block quotation outside
  frontmatter), F1 frontmatter regression, F1 no-trailing-newline
  regression, F1 trailing-comment allow, F2 red→green (empty-value
  carve-out), F2 message-accuracy, before-landing-hunt mark-bypass
  regression — all seven run as real subprocess cases in
  `run-role-gates-tests.sh`, code_under_review as listed in this record's
  frontmatter.
- resolved_findings: before-landing hunt stance-0 mark-bypass — fixed and
  regression-pinned in this commit; no further action needed.

## Open findings

None open.
