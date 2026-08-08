---
kind: build-proposal
subject: issue-157
produced_by: implementation
loop_state: proposed
upstream:
  - path: docs/issue-157/reports/implementation/survey.md
    sha: same-commit
---

files: `core/hooks/record-fields-gate.sh`, `core/hooks/tests/run-role-gates-tests.sh`, `docs/handbooks/role-gates-tests.md`

## Request

Issue #157 is the follow-up to the four findings the execution-observation
role left against PR #154 (issue-153's frontmatter-scoped sha check),
`docs/issue-153/reports/execution-observation.md`:

1. **F1 — frontmatter-less documents pass unscanned.** `placeholder_shas`'s
   no-match fallback (`region = fm.group(1) if fm else ""`) means a
   written document with no leading `---` fence has zero `sha:` lines
   inspected — the exact spellings issue-128/133 exist to deny (`HEAD`,
   `TBD`, bracket placeholders) go straight through. Decide the intended
   semantics and pin it with a red-green case.
2. **F2 — the message-accuracy case can't tell fixed from unfixed.** The
   landed case uses a non-empty value on the field-name line, which never
   exercises the newline-swallowing input class it's named for. Replace
   or add a case that does.
3. **F3 — the class census covered 7 of 18 non-test shell files.**
   Extend it to the other 11, or record why they're out of class.
4. **F4 — the closing anchor's early-close direction is undocumented.**
   One handbook sentence.

Scouting was skipped (see the survey's "Scout skip record" — pure bugfix
against four named, already-reproduced findings against one already-landed
function; the one open design choice, F1's fallback semantics, is settled
by which of this repository's own existing test fixtures would flip, not
by prior art).

## Constraints

- #154's landed frontmatter-scoping, the newline-swallowing fix, the
  YAML-comment strip, and the empty-value carve-out are unchanged — this
  issue is fallback semantics, pin strength, and record completeness only
  (issue's own `## 제약`).
- No retroactive edit to any already-landed record or proposal (#100
  no-retroactive-fix precedent, restated by issue-153 and carried
  forward here).
- This proposal's own frontmatter and body never quote a non-conforming
  `sha:` value inside a live frontmatter field — every such spelling
  below is either prose or inside a fenced/indented code example outside
  this document's own `---` block, so this document stays writable under
  the gate exactly as it stands today.
- #142 (open PR #145) is confirmed, by reading its diff this session, to
  touch 7 of the 11 files this issue's F3 census newly covers
  (`scout/hooks/directive.sh`, `terse/hooks/terse.sh`,
  `warrant/hooks/directive.sh`, `warrant/hooks/hunt-guard.sh`,
  `warrant/hooks/hunt-state.sh`, `warrant/hooks/scope-gate.sh`,
  `warrant/hooks/state.sh`), but its hunks in the two files this census
  actually reads (`state.sh`, `scope-gate.sh`) are confined to the
  kill-switch/`gate-lib.sh`-sourcing preamble, not the
  `frontmatter()`/`STATUS`/`FILE_ITEM` lines the census cites — no
  present conflict, re-diff before phase 2 if #145 lands first. #141
  (open PR #144) and #146 (open PR #148, phase 1 only) touch neither
  `record-fields-gate.sh` nor `run-role-gates-tests.sh`.

## Rationale

**F1 — chosen: fallback to a whole-document scan only when the
frontmatter anchor fails to match against a leading-whitespace-stripped
copy of the text, still falling back to the full original text.** For a
document that *has* a leading `---` fence, behavior is byte-for-byte
unchanged — the fallback branch is never reached, so #154's
frontmatter-scoped, quote-safe scan stays exactly as landed, honoring
this issue's constraint. For a document that has none, this restores the
pre-#154 whole-document scan for that shape only — closing the gap
Finding 1 names, at the cost of reintroducing whole-document scanning's
own known tradeoff (denying a quoted example) but only for the narrow,
currently-nonexistent-in-corpus shape of a frontmatter-less document that
also needs to quote a `sha:` value. Verified against the full existing
`run_rf` suite (the survey's F1 section): none of the 25 fixtures without
a `---` fence contains a `sha:` field line, so this change flips zero
existing expected verdicts.

**Revised after this proposal's own after-proposal hunt** (stance 0,
`docs/reports/2026-08-08-hunt-issue-157-frontmatter-fallback-f2-discriminator-f3-census-f4-handbook.md`).
The first draft of this fix was the literal one-token change (`region =
fm.group(1) if fm else text`), matching the anchor against the raw text
directly. The hunt found that draft's fence-presence test was stricter
than "has a fence" in any sense a human or this issue's own acceptance
checks would recognize: `re.match` requires the frontmatter anchor at
byte position 0 exactly, so a document with fully-conforming frontmatter
preceded by nothing more than one stray leading blank line — an ordinary
editor or copy-paste artifact — would be reclassified as "has none" and
routed into the whole-document fallback, falsely denying any denied
spelling legitimately quoted in that document's own body (the same idiom
this survey and this proposal use to cite examples). That contradicted
the "byte-for-byte unchanged for fenced documents" claim above. The fix
attempts the anchor match against `text.lstrip()` (leading whitespace of
any kind stripped, after the existing BOM strip) instead of `text`
directly, but still falls back to scanning the *original*, unstripped
`text` when no match is found even against the stripped copy — so a
genuinely frontmatter-less document is still fully covered, while a
document whose frontmatter is merely preceded by incidental leading
whitespace is now correctly recognized as fenced. Re-verified this
session against the hunt's exact repro (now allowed, matching current
behavior) and against all seven existing F1/F2 `run_rf`/inline fixtures
plus the new ones planned below (all unchanged from the values stated
throughout this proposal).

**Rejected alternative: fail-closed — deny any record/proposal write with
no leading `---` fence, as a new check ahead of the sha scan.** This is
the issue's own other named candidate. Rejected because the survey traced
it against the live fixture set and found it breaks 5 *currently-passing*
fixtures at `run-role-gates-tests.sh:75-92` that have nothing to do with
the sha check — legitimate §20-complete records written as flat text with
no frontmatter block, which `record-fields-gate.sh`'s own five §20 field
checks (`has_any(...)`, substring matches over the whole document) have
never required a fence for. Fail-closed would be a behavior change to
document-shape requirements generally, which is broader than issue #157's
own scope ("fallback 의미론·핀 강도·기록 완결성," not "require frontmatter
on every record") and than #153's constraint this issue inherits.

**The `:90-92` allow fixture the observation cited needs no edit.** Its
content carries no `sha:` line at all — it was never a test of the sha
check, only of the `code_under_review` and §20 field checks — so neither
candidate above changes its expected verdict. What pins F1 is a *new*
fixture (a fence-less document that *does* carry a bad `sha:` value), not
a change to this one; recorded here since the issue asked the two
questions (fallback semantics, this fixture's disposition) to be answered
together.

**F2 — chosen: add a second inline message-content probe, reusing the
already-landed carve-out fixture's shape with the second entry's value
changed to non-conforming, keep the existing case too.** The survey
traced two candidate discriminating fixtures by hand against both the
old (pre-#154) and current regex and found only one that actually
discriminates: two `path:`/`sha:` entries, the first with an empty value,
the second with `sha: HEAD`. Old code's newline-swallowing bug makes the
first (empty) entry's match swallow the second entry's *`- path: other`*
line as `bad[0]` — not `HEAD` — so the pre-fix denial message never
contains the substring `sha: HEAD is not`; current code correctly carves
out the empty entry and denies the second on its own line, producing
exactly that substring. This requires no production-code change — #154
already fixed the underlying behavior; the test was the gap.

**Rejected alternative: the issue's own literal phrasing, "value-less
line immediately followed by a line also starting with `sha:`."** Traced
and rejected: under the old pattern, the swallow captures the *entire*
next line including its own `sha:` prefix (`bad[0] = "sha: HEAD"`), and
the resulting old-code message (`sha: sha: HEAD is not ...`) still
*contains* the substring `sha: HEAD is not` as its tail — a false
negative, indistinguishable from the fixed message under a substring
check, which is exactly how the existing inline probe (and this proposal's
new one) has to check message content. The two-`path:`-entry shape avoids
this because the swallowed text (`- path: other`) never contains the
literal string `HEAD`.

**F3 — chosen: extend the census to the 11 previously-uncovered files,
record the result (rather than a boundary-exclusion rationale), because
the extension is already done.** The survey ran it: 11/11 examined, 0
additional instances of F1's whole-document-scan-with-silent-empty-fallback
class. Two of the 11 (`warrant/hooks/state.sh`, `warrant/hooks/scope-gate.sh`)
independently implement a bounded `frontmatter()` extraction and — unlike
record-fields-gate.sh's F1 — fail closed (deny/skip) rather than open when
the fence is missing or malformed. The rest either operate on a Bash
command string (a different concern from F1's document-scan class) or
contain no document-parsing regex at all. Recording a boundary-exclusion
rationale instead was the other option the issue allowed; not chosen
because the actual grep-and-read took the same effort as writing a
justification for skipping it would have, and the result is stronger
evidence than a scope argument.

**F4 — chosen: one handbook sentence, no code or test change.** The
issue's own severity framing (0 live corpus instances, cheap close) and
the survey's confirmation (every existing document's `sha:` lines fall
before its first closing fence, corrected and re-verified after an
initial one-line corpus check was found to be checking the wrong thing)
both point at documentation being the correct-sized fix. A code change
here (e.g., a greedy-with-backtracking anchor, or denying on multiple
column-0 `---` lines) is rejected as unwarranted scope: it would touch
the same function as F1 for a defect class with zero live instances and
no test gap the issue asks to close beyond documenting it.

## What will be done

1. `core/hooks/record-fields-gate.sh`, inside `placeholder_shas`:
   - Attempt the frontmatter-anchor match against `text.lstrip()` (after
     the existing BOM strip) instead of `text` directly, and fall back to
     scanning the full, unstripped `text` — not an empty region — when
     even that fails to match: `region = fm.group(1) if fm else text`,
     with `fm` now matched against the lstripped copy. This is the
     post-hunt design (see Rationale's "Revised after this proposal's own
     after-proposal hunt"), not the original one-token draft.
   - Update the function's existing comment block to state the fallback:
     a document with no real leading `---` fence — after tolerating
     incidental leading whitespace, the same way the existing BOM strip
     already tolerates a leading byte-order mark — has its whole text
     scanned (pre-#154 behavior, for that shape only), instead of the
     current comment's "other gates already require a well-formed
     proposal/record shape" claim, which the observation found uncited
     and which this change makes moot.
2. `core/hooks/tests/run-role-gates-tests.sh`:
   - New `run_rf` case: content `"sha: HEAD\n"` (no fence), role
     `coding`, a `docs/issue-3/proposals/...` path. Documented as a
     red→green pin: pre-fix `allow` (reproduced in the survey by direct
     regex trace), post-fix `deny`.
   - New `run_rf` case, same shape with a conforming value (`"sha:
     same-commit\n"`, no fence): stays `allow` before and after — a
     regression guard so the fallback doesn't turn into an
     always-deny-fence-less-writes trap.
   - New `run_rf` case (hunt finding, stance 0): content opening with one
     blank line, then a fully-conforming frontmatter block, then a body
     quoting a denied spelling inside a fence — stays `allow` both before
     and after this fix, regression-pinning the leading-whitespace
     tolerance the post-hunt design adds.
   - New inline message-content probe next to the existing F2 one
     (`:145-151`): the two-entry fixture from the survey/Rationale above
     (`sha:` empty, second entry `sha: HEAD`), asserting the denial
     message contains `sha: HEAD is not`. Comment states this is the
     newline-swallowing discriminator the existing non-empty-value case
     is not.
   - Regression: all 56 currently-passing cases keep their verdicts
     (verified in the survey — none of the fence-less fixtures contains a
     `sha:` line, so the F1 fallback change touches none of them).
3. `docs/handbooks/role-gates-tests.md:61-71` (the paragraph documenting
   #154's scan-scoping):
   - F1: state that a document with no leading frontmatter fence has its
     entire text scanned instead (not skipped) — the fallback exists so a
     malformed or absent fence cannot silently disable the check.
   - F4: state that the scanned region ends at the *first* column-0
     `---` line after the opening fence, so a `---` line appearing inside
     intended frontmatter content truncates the region there.
4. `docs/issue-157/reports/implementation.md` (phase 2, this role's own
   record): restates F3's census result (11/11 examined, 0 additional
   instances, with the two frontmatter()-implementing files named) as the
   record of requirement 3, per the issue's "record 에 명시" acceptance
   check — the survey already contains the work; the record is where the
   issue's acceptance check expects to find it stated.

## Out of scope

- Any change to what counts as a valid `sha:` value, the empty-value
  carve-out's meaning, the YAML-comment strip, or the closing-anchor
  pattern itself — all #154-landed and constrained unchanged by this
  issue.
- Fixing F4 in code (backtracking/greedy anchor, multi-`---` detection) —
  zero live instances, issue's own framing calls for a handbook sentence.
- `warrant/hooks/state.sh` / `warrant/hooks/scope-gate.sh`'s own
  `frontmatter()` helpers — the census found them already correctly
  bounded and, if anything, stricter than record-fields-gate.sh's
  pre-fix behavior; nothing to change there.
- `code_under_review`'s enumerate-bad-shape check — out of scope per
  issue-153's own accepted-limitation judgment, unchanged by #157.
- Coordinating a merge order with PR #145 (issue-142) — confirmed no line
  overlap; noted as a re-diff-before-phase-2 precaution only.

## How you'll know it worked

- `bash core/hooks/tests/run-role-gates-tests.sh` passes in full,
  including the new F1 red→green pair, the new F1 fence-less-but-legitimate
  regression case, the new F1 leading-blank-line hunt-finding regression
  case, and the new F2 message-accuracy discriminator, with all 56
  pre-existing cases unaffected.
- A synthetic fence-less write carrying a non-conforming `sha:` value is
  denied by `record-fields-gate.sh`; the identical fence-less write with a
  conforming value is still allowed; a write with fully-conforming
  frontmatter preceded by a stray leading blank line, quoting a denied
  spelling in its body, is still allowed (not falsely denied) — all three
  demonstrable directly against the script as a subprocess, the same way
  existing `run_rf` cases do.
- The new inline probe demonstrates, by direct string comparison, that
  the denial message for the two-entry (empty + bad) fixture names
  `HEAD`, not the swallowed `- path: other` text a reversion to the old
  pattern would produce.
- `docs/issue-157/reports/implementation.md` states the F3 census result
  (11/11, 0 additional instances) as the record of requirement 3.
- `docs/handbooks/role-gates-tests.md` describes both the fallback
  behavior and the closing-anchor boundary accurately, readable without
  cross-referencing this proposal or the issue-153 observation record.
- This proposal document itself was writable under the gate as it stands
  today (unfixed) — confirmed by construction: every non-conforming
  spelling above is either prose or inside this document's body outside
  its own `---` frontmatter block, never a live field inside it.
