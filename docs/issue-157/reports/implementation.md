---
kind: role-record
subject: issue-157
produced_by: implementation
code_under_review: `core/hooks/record-fields-gate.sh`, `core/hooks/tests/run-role-gates-tests.sh`, `docs/handbooks/role-gates-tests.md`
loop_state: landed
upstream:
  - path: docs/issue-157/proposals/2026-08-08-frontmatter-fallback-f2-discriminator-f3-census-f4-handbook.md
    sha: same-commit
closed_checks:
  - name: F1 red->green — fence-less document with a non-conforming sha value denies post-fix, allowed pre-fix
    code_sha: "`core/hooks/record-fields-gate.sh`, `core/hooks/tests/run-role-gates-tests.sh`, `docs/handbooks/role-gates-tests.md`"
    result: >-
      Reproduced directly, not only by prose. `git stash push -- core/hooks/record-fields-gate.sh`
      (keeping the new test fixtures in the working tree) then
      `bash core/hooks/tests/run-role-gates-tests.sh` produced exactly one
      FAIL — `F1 red->green: fence-less document's bad sha value denied
      (issue-157) want=deny got=allow` — with the other 3 new F1/F2 cases
      still green (they pin behavior #154 already landed or the
      leading-blank-line regression this fix's own hunt drove, neither of
      which depends on this session's fallback change). `git stash pop`
      restored the fix; the full suite went to 60 passed, 0 failed.
      Confirmed.
  - name: F2 discriminator — empty-entry + bad-second-entry fixture's denial message names the true offending value, not the swallowed line
    code_sha: "`core/hooks/tests/run-role-gates-tests.sh`"
    result: >-
      `bash core/hooks/tests/run-role-gates-tests.sh` line
      "F2 discriminator: empty entry + bad second entry names HEAD, not
      swallowed text (issue-157)" passes (substring `sha: HEAD is not`
      present in the live denial message). No production-code change
      backs this case — #154 already fixed the underlying
      newline-swallowing behavior; the test was the gap issue-153's
      observation named. Confirmed.
  - name: before-landing hunt (stance 1) finding — F1 fallback re-widens the scan for a fence-less document that legitimately quotes a bad sha spelling in prose
    code_sha: "`core/hooks/record-fields-gate.sh`"
    result: >-
      FINDING, not a fresh defect — a re-derivation of the exact tradeoff
      the approved proposal's own Rationale already named and accepted:
      "at the cost of reintroducing whole-document scanning's own known
      tradeoff (denying a quoted example) but only for the narrow,
      currently-nonexistent-in-corpus shape of a frontmatter-less document
      that also needs to quote a `sha:` value." Re-verified this session,
      not merely re-cited: scanned all 239 `docs/issue-*/{reports,proposals}/**/*.md`
      files, found 96 containing the substring `sha:` anywhere, and of
      those exactly 2 are fence-less (`docs/issue-12/proposals/2026-07-29-review-issue-12.md`,
      `docs/issue-12/reports/review/survey.md`). The second is outside
      this gate's own path scope (`RECORDS_RE`/`PROPOSALS_RE` match a
      role's own `reports/<role>.md` file or a `proposals/*.md` file, not
      a `reports/<subdir>/survey.md`) so it is never evaluated by this
      function at all. The first has no line matching the gate's own
      field regex `^\s*sha:[ \t]*(.*)$` — its one `sha:`-containing line
      is `...code_sha:` (the field name is `code_sha`, not `sha`, and the
      literal string does not begin the line even after stripping
      leading whitespace), so `placeholder_shas` finds nothing to flag in
      it either way. 0 live corpus documents are denied by this fallback
      that were allowed before it. Disposition: accepted as designed, no
      code change; recorded here per the hunt-cadence "HUNT RESULTS ARE
      VERIFY'S INPUT, not your certificate" requirement so this
      re-verification is available to cite-and-skip rather than re-derive.
      Full hunt record (both the after-proposal stance-0 and this
      before-landing stance-1 dispatch):
      `docs/reports/2026-08-08-hunt-issue-157-frontmatter-fallback-f2-discriminator-f3-census-f4-handbook.md`.
---

# Phase-2 implementation record — issue-157

## Why

Phase 2 opened on the issue-level comment `APPROVE issue-157/implementation`
(single-account mode: `jjongkwann` is both PR #158's author and a listed
account in `docs/specs/approvers.md`, so the issue-level exact-string path
applies rather than a separate-account PR-review Approve). Delivering
exactly the approved proposal's `## What will be done`
(`docs/issue-157/proposals/2026-08-08-frontmatter-fallback-f2-discriminator-f3-census-f4-handbook.md`):
the F1 frontmatter-less fallback (post-hunt lstrip-anchor design, not the
proposal's own superseded first draft), the F2 message-accuracy
discriminator, the F3 census result (restated below), and the F4 handbook
boundary sentence.

## What was done

1. `core/hooks/record-fields-gate.sh`, `placeholder_shas`: the frontmatter
   anchor is now attempted against `text.lstrip()` (after the existing BOM
   strip) instead of the raw `text`, and — only when that also fails to
   match — falls back to scanning the full, unstripped `text` instead of
   an empty region (`region = fm.group(1) if fm else text`, `fm` matched
   against the lstripped copy). A document with a real leading `---` fence
   is completely unaffected (first match attempt succeeds; `region` is the
   frontmatter block exactly as #154 landed it). A genuinely
   frontmatter-less document now has its `sha:` lines inspected instead of
   silently skipped. Comment block updated in place to state this
   fallback and its provenance (post-hunt design, not the proposal's
   original one-token draft).
2. `core/hooks/tests/run-role-gates-tests.sh`: four new cases, inserted
   after the existing BOM-hunt regression case and before the
   issue-140 "single deny lists every violation" section —
   - `F1 red->green: fence-less document's bad sha value denied (issue-157)`
     — content `"sha: HEAD\n"`, no fence, role `coding`, path
     `docs/issue-3/proposals/2026-08-04-x.md`. Deny post-fix; verified
     `allow` pre-fix by direct `git stash` (see `closed_checks` above).
   - `F1 regression: fence-less document's conforming sha value stays allowed (issue-157)`
     — same shape, `"sha: same-commit\n"` — allow both before and after,
     so the fallback does not become an always-deny trap for fence-less
     writes.
   - `F1 hunt regression: leading blank line before a real fence still allowed to quote an example (issue-157)`
     — a leading blank line, then a fully-conforming frontmatter block,
     then a body quoting `sha: HEAD` inside a fence — allow, pinning the
     after-proposal hunt's (stance 0) finding fix (the lstrip-anchor
     design, not the proposal's original one-token draft).
   - `F2 discriminator: empty entry + bad second entry names HEAD, not swallowed text (issue-157)`
     — a second inline message-content probe (alongside the existing one
     at what is now line ~151) asserting the denial message for a
     two-entry (`sha:` empty, second `sha: HEAD`) fixture contains the
     substring `sha: HEAD is not`, discriminating fixed code from
     pre-#154 code (which would report the swallowed `- path: other` text
     instead).
   - Full suite: `bash core/hooks/tests/run-role-gates-tests.sh` →
     `role-gates: 60 passed, 0 failed` (56 pre-existing + 4 new; all 56
     pre-existing verdicts unaffected — verified by the same full run,
     not merely asserted).
3. `docs/handbooks/role-gates-tests.md:61-71`'s sha-check paragraph gained
   two sentences: the F1 fallback (a fence-less document has its entire
   text scanned instead of skipped) and the F4 boundary (the scanned
   region ends at the first column-0 `---` line after the opening fence,
   not the last).
4. This record restates the F3 census result per the proposal's own
   item 4: the survey (`docs/issue-157/reports/implementation/survey.md`,
   F3 section) extended issue-153's `core/hooks/*.sh`-glob census (7
   files) to all 18 tracked non-test shell files repo-wide, examining the
   11 files outside the original glob. **Result: 11/11 examined, 0
   additional instances of F1's whole-document-scan-with-silent-empty-fallback
   class.** Two of the 11 — `warrant/hooks/state.sh` and
   `warrant/hooks/scope-gate.sh` — independently implement a bounded
   `frontmatter(path)` helper that already fails *closed* (deny/skip) on
   a missing or malformed fence, the opposite direction from F1's bug and
   not requiring a fix. The remaining 9 either parse a Bash command
   string (a different concern from F1's document-scan class:
   `scope-gate.sh`'s `WITHHELD`/`GIT_COMMIT`, `gate-lib.sh`'s
   `gate_bash_write_targets`) or contain no regex/pattern-based
   document-content parsing at all (`core/hooks/lib/role-directive.sh`,
   `freelunch/hooks/freelunch.sh`, `freelunch/hooks/observe.sh`,
   `scout/hooks/directive.sh`, `terse/hooks/terse.sh`,
   `warrant/hooks/directive.sh`, `warrant/hooks/hunt-guard.sh`,
   `warrant/hooks/hunt-state.sh`). Requirement 3's acceptance check
   ("census 확장 결과 또는 경계 사유가 record 에 명시") is satisfied by this
   full-count result.

## Doc placement (ladder outcomes)

- [x] Handbook sentence for a scan-scope/boundary behavior change (F1
      fallback, F4 anchor boundary) → same-turn edit to
      `docs/handbooks/role-gates-tests.md:61-71` (item 3 above). No new
      env var, dependency, or migration in this issue's write set.
- [x] F3 census result (an investigation outcome the issue's own
      acceptance check requires "in the record") → this record, `## What
      was done` item 4, restating the survey's already-complete finding.
- [ ] No library-or-format decision or public-signature/wire-format
      change occurred — `docs/issue-157/decisions/` not applicable.
- [ ] No benchmark/investigation-numbers report beyond the census above —
      `docs/issue-157/reports/` (a separate report file) not applicable;
      the census lives in this record per the proposal's own placement
      choice.

## What did not work

None. The approved proposal's design (already revised once, in phase 1,
by its own after-proposal hunt) implemented cleanly against the live
regex; no attempted approach here was written then undone.

## Hunt cadence

- After-proposal (phase 1, stance 0): FINDING, resolved before the
  proposal was approved — see the proposal's Rationale ("Revised after
  this proposal's own after-proposal hunt") and
  `docs/reports/2026-08-08-hunt-issue-157-frontmatter-fallback-f2-discriminator-f3-census-f4-handbook.md`'s
  "after-proposal — stance 0" section.
- Before-landing (phase 2, this session, stance 1): FINDING — see
  `closed_checks` above for the finding and its accepted-tradeoff
  disposition, and the hunt record's "before-landing — stance 1" section
  for the hunter's own reproduction. Not a blocking finding: it is a
  re-derivation of a tradeoff the approved proposal's Rationale already
  named and accepted, re-verified this session against the live corpus
  (0 documents affected) rather than re-cited without checking.

## Open finding resolution path

N/A — `loop_state` is terminal (`landed`); no non-terminal open finding
requires one.

## Open findings

none
