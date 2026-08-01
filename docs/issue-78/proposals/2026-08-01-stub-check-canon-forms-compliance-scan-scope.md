files:
- core/hooks/tests/stub-check.sh
- core/hooks/tests/canon-forms.txt (new)
- core/hooks/tests/compliance-check.sh
- core/hooks/tests/run-stub-canon-forms-tests.sh (new)
- core/hooks/tests/run-compliance-scan-scope-tests.sh (new)
- core/hooks/tests/run-all.sh
- docs/handbooks/gate-house-standard.md

## Request

Issue #78 (2026-08-01 A+ audit follow-up), two independent structural
defects in core's own canon test scripts:

1. `stub-check.sh`'s `directive.sh` structural check hardcodes exactly one
   permitted shape (single `core_role_directive` call). sales-rulebook's
   already-approved (issue-10) fragment-array `for`-loop combination shape
   fails it, even though the shape itself was approved elsewhere — a canon
   format gap, not a rulebook defect.
2. `compliance-check.sh` scans `*-gate.sh` by filename glob. Confirmed:
   `hunt-guard.sh` and `gh-guard.sh` are both PreToolUse-wired in their
   `hooks.json` but neither matches the glob, so both skip the fail-open
   checks compliance-check exists to catch.

## Constraints

- No public function's existing behavior changes for a shape that already
  passes today (additive only, per the gate-house-standard's own stated
  constraint from issue-75).
- No new external dependency; stay inside bash + `find`/`grep` (compliance-check
  today has no `python3` dependency either — keep it that way).
- Whichever canon-form registration mechanism is chosen must be recorded in
  `docs/handbooks/gate-house-standard.md` (issue's explicit requirement).
- Regression tests required for both fixes.

## Rationale

**Canon combination format — chosen: a second manifest file
(`canon-forms.txt`), not inline shape literals in bash.**

Considered alternative: encode the fragment-loop shape as a second hardcoded
regex block in `stub-check.sh` next to the existing `directive.sh` check
(the smallest literal diff). Rejected: this repeats the exact anti-pattern
`CANON_GATES` was already extracted from `canon-manifest.txt` to avoid — a
third approved shape would mean a third hand-edited bash block instead of a
data addition, and scout angle 1 (ESLint's `no-restricted-syntax`) confirms
config-driven pattern registries are the established shape for "add a
permitted pattern" over hardcoding a new one per case. `canon-forms.txt`
mirrors `canon-manifest.txt`'s existing convention (name → registered shape)
instead of introducing a second registration mechanism.

Considered alternative: define the combination as a separate *file*
regulation instead of a stub-check shape (the issue's own second option —
"조합을 별도 파일로 빼는 규약"). Rejected for now, not dismissed: splitting the
loop into its own sourced file sidesteps stub-check's per-line
classification entirely, but it requires every already-migrated rulebook
(43 repos, issue-66/69/72/75 lineage) to restructure `directive.sh` again on
a new physical-layout rule, which is a second migration wave stacked on the
one just finished. The manifest-registration approach fixes the same
problem by relaxing stub-check's classifier, with zero rulebook-side
restructuring. Recorded here so a future issue can revisit the split-file
option if a combination shape emerges that manifest-registration truly
cannot express.

**Compliance scan scope — chosen: resolve scope from every `hooks.json`'s
`PreToolUse[].hooks[].command` entries, not a wider filename glob.**

Considered alternative: broaden the glob (e.g. `*-gate.sh` OR `*-guard.sh`
OR `*.sh`, whichever loosest pattern happens to cover today's known misses).
Rejected: this is exactly the failure mode the issue reports — a
filename-shaped rule will always be one un-anticipated name away from
missing the next wired script (scout angle 2's finding: scope by
*registration*, not by name, is the pattern practitioner guidance converges
on for hook systems). A glob broad enough to catch `observe.sh` too (no
`-gate`/`-guard` suffix at all) stops being a filename rule in any
meaningful sense — it degenerates to "scan every `.sh` file," which now
also sweeps in non-hook helper scripts compliance-check was never meant to
judge. Reading `hooks.json` directly scopes to exactly what actually fires
on `PreToolUse`, matching the issue's own request verbatim ("hooks.json에
PreToolUse로 배선된 모든 스크립트로 확장").

## What will be done

1. `core/hooks/tests/canon-forms.txt`: new manifest, one entry per
   registered `directive.sh` combination shape (starting with today's
   single-call form and the fragment-array `for`-loop form), in a simple
   `name:pattern-description` line format `stub-check.sh` can classify
   against — same spirit as `canon-manifest.txt`'s plain-line convention.
2. `stub-check.sh`'s directive.sh structural check: instead of a single
   hardcoded "other lines must be empty" rule, classify each non-blank/
   non-comment line against the union of registered shapes from
   `canon-forms.txt` (falling back to today's built-in single-call shape
   if the manifest is missing, matching `CANON_GATES`'s existing
   missing-manifest fallback pattern). A `directive.sh` matching any
   registered shape passes; anything else still fails as regrown
   boilerplate.
3. `compliance-check.sh`: replace the `find ... -name '*-gate.sh'` scan set
   with a two-step resolution — find every `hooks.json` under `$dir`
   (`-maxdepth` unchanged), extract each `PreToolUse[].hooks[].command`
   string's script path (strip the leading `${CLAUDE_PLUGIN_ROOT}/` /
   `bash ` forms already observed across the repo's five `hooks.json`
   files), resolve it relative to the `hooks.json`'s own directory, and
   scan that resolved file set with the existing per-file check logic
   (unchanged).
4. Two new regression test files exercising: (a) stub-check accepting a
   fragment-loop `directive.sh` fixture and still rejecting a genuinely
   malformed one; (b) compliance-check catching a `hunt-guard.sh`-shaped
   fixture (PreToolUse-wired, non-`-gate.sh`-named, with a hand-rolled
   kill switch) that the old glob would have missed. Both wired into
   `run-all.sh`.
5. `docs/handbooks/gate-house-standard.md`: document the `canon-forms.txt`
   registration mechanism and the hooks.json-driven compliance-check scan
   scope, including why the split-file alternative was deferred (for the
   next reader deciding whether to revisit it).

## Out of scope

- Restructuring sales-rulebook's actual `directive.sh` (external repo, not
  in this tree) — this proposal only removes the canon-side block.
- Retrofitting any of the 43 already-migrated rulebooks' own gates
  (explicitly out of scope for this repo per gate-house-standard.md's own
  existing "no retroactive fix... each rulebook's own A+ issue does that"
  clause).
- Adding a JSON parser dependency — `hooks.json`'s `command` field is
  scanned as a literal string line the same way `compliance-check.sh`
  already does grep-based structural checks elsewhere in this file; a full
  JSON-parse rewrite of the script is not needed for this fix.
- Any change to `gate-lib.sh`/`gate-lib.py`'s existing `gate_*` functions.

## How you'll know it worked

- `run-stub-canon-forms-tests.sh` passes: fragment-loop fixture accepted,
  malformed fixture still rejected.
- `run-compliance-scan-scope-tests.sh` passes: a `hunt-guard.sh`-shaped
  fixture (PreToolUse-wired, non-`-gate.sh` name, hand-rolled kill switch)
  is flagged; a script present on disk but *not* wired in any `hooks.json`
  is correctly excluded from the scan.
- `run-all.sh` runs both new suites and stays green end-to-end.
- `compliance-check.sh` run against this repo's own `core/`/`warrant/`
  trees now flags `hunt-guard.sh` and `gh-guard.sh` for review (or clean,
  once phase 2 also fixes them if warranted — flagging alone satisfies this
  issue; remediating those two files' own kill-switch shape is a separate
  concern the flag now makes visible).
