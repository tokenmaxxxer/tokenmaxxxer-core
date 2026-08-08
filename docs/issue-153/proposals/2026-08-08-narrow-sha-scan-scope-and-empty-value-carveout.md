---
kind: build-proposal
subject: issue-153
produced_by: implementation
loop_state: proposed
upstream:
  - path: docs/issue-153/reports/implementation/survey.md
    sha: same-commit
---

files: `core/hooks/record-fields-gate.sh`, `core/hooks/tests/run-role-gates-tests.sh`, `docs/handbooks/role-gates-tests.md`

## Request

Issue #153 is the follow-up to two findings the execution-observation role
left against PR #134 (issue-133's sha whitelist conversion),
`docs/issue-133/reports/execution-observation.md` Findings 1 and 2:

1. **F1 — scan scope.** The sha-value check runs its regex over an entire
   reconstructed document, not the frontmatter block the `upstream:`
   convention actually lives in. A record or proposal that *quotes* a
   non-conforming value — the exact thing a document about this defect
   class needs to do — is denied the same as one that carries the value
   live. A legitimate value trailed by a YAML comment is denied too.
2. **F2 — empty-value path.** Issue #133's requirement 1 carved out an
   empty value ("existing convention, untouched") but the delivered
   allow-list never implemented the carve-out, and the value-side pattern
   crosses a line break — a value-less line is misread as carrying the
   next non-blank line's text, and the denial names that wrong line.
3. **Class census (§20 clause 6).** Sweep `core/hooks/*.sh` for other
   habitats of (a) a canonical-surface rule scanned over a wider region,
   and (b) an enumerate-one-bad-shape check standing in for an allow-list
   — judge whether the known candidate, the `code_under_review` bare-sha
   check, belongs in this write set.

Scouting was skipped (see the survey's "Scout skip record" — pure
bugfix against two named, already-reproduced findings; the remaining
choices are internal implementation judgment, not a prior-art question).

## Constraints

- Issue #133's landed whitelist semantics (`same-commit` or exactly
  40-lowercase-hex) are unchanged — this issue is scope, carve-out, and
  diagnosability only, not what counts as a valid value.
- No retroactive edit to any already-landed record or proposal (issue's
  own instruction, consistent with the #100 no-retroactive-fix
  precedent this repository already follows).
- #141 (open PR #144) and #146 (open PR #148) are confirmed, by diff, not
  to touch any line in `core/hooks/record-fields-gate.sh` — no
  coordination action needed against either right now. #147 has not
  started (no branch, no PR); it names the same file for a different
  region (the five §20 field checks and the `RF_TERMINAL` default, not
  the sha check). Sequencing risk, not a present conflict: if #147 lands
  first, this issue's phase-2 build re-diffs against `main` before
  editing rather than assuming the survey's line numbers still hold.

## Rationale

**Chosen: bound `placeholder_shas`'s scan to the leading
`---`-delimited frontmatter block, in place, keeping the existing two
call sites.** Every record and proposal in this repository already opens
with exactly this block (confirmed against a ten-file sample in the
survey), and it is precisely "the region the rule is about" — the
observation's own root-cause language for F1. A single anchored regex
(`^---[ \t]*\r?\n(.*?\n)^---[ \t]*\r?$`, `re.DOTALL | re.MULTILINE`)
extracts that substring; the existing line-scan then runs against the
substring instead of the whole document. Same file, same function, same
call sites, same style as every other check in this gate — no new
dependency, no new failure mode. (This exact pattern replaced an earlier
draft that required a newline *after* the closing fence too — the
after-proposal hunt, stance 0, caught that a document ending exactly at
the closing `---` with no trailing newline would then match nothing,
silently emptying the scan region instead of narrowing it. Anchoring the
closing fence with multiline `$` — which matches at end-of-line *or*
end-of-string — closes that gap; see
`docs/reports/2026-08-08-hunt-issue-153-narrow-sha-scan-scope-and-empty-value-carveout.md`.)

**Rejected alternative: skip fenced-code and indented-quotation regions
instead of positively bounding to frontmatter** (the observation's other
stated option). Rejected because it inverts the wrong side of the
problem: it would need to keep detecting every quoting convention
(fenced blocks, indented quotes, and whatever future documentation style
appears) rather than anchoring to the one region that is actually
canonical, and it does nothing for F2 — the newline-swallowing defect
exists independent of where the scan starts and stops. Bounding to
frontmatter fixes F1 outright and narrows F2's blast radius to exactly
the region where an empty value can legitimately occur.

**Rejected alternative: parse the frontmatter with a YAML library
instead of a bounded line-regex.** Same rejection issue-133's own
proposal already recorded for this file: Python's standard library ships
no YAML parser, this gate has no such dependency today, and a parse
failure on subtly malformed YAML would need its own new fail-open-or-
closed decision this gate does not currently have to make. The frontmatter
*boundary* is a fixed two-line anchor (`---` at the start, `---` at the
first line matching it again) — regex is sufficient for finding that
boundary; nothing about this fix needs a structured parse of the content
inside it.

**Empty-value carve-out: read it as "a present line, no value" (not
"the whole `upstream:` list absent"), matching pre-issue-133 behavior.**
Issue #133's own wording ("빈 upstream 은 기존 규약대로") and its
proposal's restated Request item 1 both point at a value-less line
staying outside what gets flagged — not merely an absent list, which was
already, structurally, never reached by this regex. The rejected reading
(carve-out means only "no `upstream:` field at all") does nothing new,
since that case never entered `placeholder_shas`'s match set in any
version of this check; it would leave issue #133's requirement 1
undelivered a second time.

**Trailing-YAML-comment handling: strip and validate the remainder,
rather than record it as an accepted limitation.** The issue explicitly
leaves this judgment to the proposal. Chosen because it is low-risk (a
comment strip that only fires when at least one space/tab precedes a
`#`, so a value that merely starts with `#` is untouched and still
denied) and stays in theme with F1 — both are cases of a legitimate value
being refused for carrying something outside the semantic content the
whitelist actually needs to check. Rejected: leaving it denied, on the
grounds that the corpus has zero live instances — rejected because the
fix is a two-line addition to a function already being rewritten for F1,
and the issue frames exactly this case as something to decide rather than
skip.

**`code_under_review`'s enumerate-bad-shape check: record as an accepted
limitation, do not extend this write set to it.** It is a real second
instance of a related class (deny-one-known-bad-shape vs. allow-list-
good-shapes), matching the issue's own named candidate. Rejected pulling
it into scope: unlike the sha check, no corpus scan or code trace found
it capable of denying a legitimate value — the required shape (a file
list, per `docs/issue-100/decisions/2026-08-03-record-citation-format-and-kind-convention.md`)
cannot collapse into the one bare-hex-token shape the check denies — and
the issue's own constraint text scopes #153 to "record-fields-gate.sh 의
sha 검사와 빈 값 경로만." Converting it anyway would be the kind of
scope-widening the constraint explicitly rules out for a problem with no
demonstrated harm.

## What will be done

1. `core/hooks/record-fields-gate.sh`, inside `placeholder_shas`:
   - Add a frontmatter-boundary extraction
     (`^---[ \t]*\r?\n(.*?\n)^---[ \t]*\r?$`, `re.DOTALL | re.MULTILINE`,
     matched from the start of the reconstructed text — the closing `$`
     matches end-of-line or end-of-string, so a document ending exactly
     at the closing fence with no trailing newline still yields the full
     frontmatter as the scan region) and run the existing per-line scan
     against that substring; a document with no such block yields an
     empty region (nothing to check — other gates already require a
     well-formed proposal/record shape).
   - Change the field-value pattern from `sha:\s*(.*)$` to
     `sha:[ \t]*(.*)$` (horizontal whitespace only after the field name,
     matching the leading-indent side the same way) so the value capture
     can never cross a line break.
   - Before comparing, strip a trailing comment matched by
     `[ \t]+#.*$` from the captured value, then strip whitespace.
   - After that, an empty captured value is skipped (the carve-out) —
     not appended to `bad`; the two existing accept branches
     (`same-commit`, exactly 40 lowercase hex) are otherwise unchanged.
   - `deny_placeholder`'s message text is unchanged in substance (it
     already names the exact denied value); no wording change is needed
     since the value it now receives is always the correct line's value.
   - `code_under_review`'s check (current :234-235) and the five §20
     field checks (:198-222) are not touched.
2. `core/hooks/tests/run-role-gates-tests.sh` — add `run_rf` cases
   (red→green pairs, each currently `allow`-or-wrongly-`deny`, asserted
   correctly after the fix):
   - F1 red→green: a proposal whose frontmatter is well-formed but whose
     body (outside the `---` fences) contains a fenced block quoting a
     non-conforming value — denied today, allowed after.
   - F1 regression: the identical non-conforming value placed inside the
     frontmatter's own `upstream:`/field-name entry — denied before and
     after (scope narrowing must not loosen the frontmatter itself).
   - F1 no-trailing-newline case (after-proposal hunt finding — see
     `docs/reports/2026-08-08-hunt-issue-153-narrow-sha-scan-scope-and-empty-value-carveout.md`):
     a document whose content ends exactly at the closing fence with no
     trailing newline, and whose frontmatter carries a non-conforming
     value — must stay denied after the fix, not silently pass through an
     empty scan region.
   - F1 comment case: a conforming value followed by a space and a `#`
     comment inside the frontmatter — denied today, allowed after.
   - F2 red→green: a frontmatter entry carrying the field name with no
     value, immediately followed by another non-blank line (e.g. the next
     field) — denied today (naming the wrong line's text), allowed after
     (carve-out, no denial at all).
   - F2 message-accuracy case: a frontmatter entry carrying the field
     name with a genuinely non-conforming value on the same line,
     immediately followed by another non-blank line — after the fix,
     confirm the denial names that line's own value, not the following
     line's text.
   - Regression: existing `same-commit`, real-40-hex, bracket-placeholder,
     `HEAD`, `TBD`, and bracket+trailing-prose cases (issue-128/133,
     `:94-121` today) keep their current verdicts unchanged.
3. `docs/handbooks/role-gates-tests.md:47-59` — extend the paragraph
   describing the sha check to state that it scans only the leading
   frontmatter block (not the full document), that a value-less line is
   allowed (existing convention), and that a trailing YAML comment on an
   otherwise-conforming value is stripped before validation.

## Out of scope

- Any change to what counts as a valid `sha:` value (`same-commit` or
  40-lowercase-hex) — issue-133's landed semantics, explicitly unchanged
  by this issue's constraint.
- `code_under_review`'s enumerate-bad-shape check — recorded above as an
  accepted limitation of the same defect class, left for a separate
  human-filed issue if the class census result is judged worth acting on.
- A comment-only line (the field name followed only by a `#`-led
  comment, no value before it) — not named by issue #133's carve-out
  wording or by this issue's F2 text; left denied, the same direction the
  current (pre-fix) code already leans for any non-empty, non-whitelisted
  captured text.
- Any edit to `core/hooks/handbook-trigger-gate.sh`, `trailer-gate.sh`,
  `core/hooks/directive.sh`, or the `RF_TERMINAL`/`RECORD_FIELDS_TERMINAL_STATES`
  channel — #141's and #147's respective territory, confirmed by this
  survey to be a different region of the codebase (and, for #141, a
  different file already touched by its own open PR).
- Retroactively editing any already-landed record or proposal that
  currently carries a non-conforming or value-less `sha:` line — #100/#133
  no-retroactive-fix precedent.

## How you'll know it worked

- `bash core/hooks/tests/run-role-gates-tests.sh` passes in full,
  including the new F1/F2 red→green and regression cases, with every
  pre-existing case (§20 fields, `code_under_review`, trailer-gate,
  handbook-trigger-gate, stub-check) unaffected.
- A synthetic proposal write whose body quotes a non-conforming value
  outside its frontmatter is allowed by `record-fields-gate.sh`; the
  identical value placed inside the frontmatter's own field is still
  denied — demonstrable directly against the script as a subprocess, the
  same way existing `run_rf` cases already do.
- A synthetic write with the field name and no value on its own line,
  followed by other content, is allowed with no denial at all; a write
  with a genuinely bad value on that same line, followed by other
  content, is denied and the message names that line's own value.
- `docs/handbooks/role-gates-tests.md` describes the scan region and the
  empty-value carve-out accurately, readable without cross-referencing
  this proposal or the issue-133 observation record.
- This proposal document itself was writable under the gate as it stands
  today (unfixed) — confirmed by construction, since every non-conforming
  example value above is stated in prose rather than quoted at the start
  of a line.
