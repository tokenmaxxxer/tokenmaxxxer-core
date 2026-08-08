---
kind: current-state-survey
subject: issue-153
produced_by: implementation
---

# Current-state survey — issue-153

## Scout skip record

Scouting was skipped. Skip condition: pure bugfix. The two defects (F1,
F2) are named findings against a specific, already-landed change to
`core/hooks/record-fields-gate.sh` (`docs/issue-133/reports/execution-observation.md`),
each with an exact file:line locus and a reproducible before/after. The
narrow design choices this proposal still has to make — how to bound the
scan region, how to read the empty-value carve-out, whether to fold in
`code_under_review` — are internal implementation judgment about one
gate script, not a product-facing or prior-art question; the correct shape
for "scope a regex scan to a document's own frontmatter block" is settled
by this repository's own established convention (every record/proposal
already opens with a `---`-delimited frontmatter block — confirmed below),
not by comparison against external tooling.

## The gate today, at HEAD (`f976bcc708a6ab5ffd03898ec565f53b5200dcc7`)

`core/hooks/record-fields-gate.sh` reconstructs the full post-write text
(`new_text`, `gate_lib.gate_reconstruct_write`, :165) for any `Write` /
`Edit` / `MultiEdit` / `NotebookEdit` targeting either this role's own
record (`docs/issue-<n>/reports/<role>.md`) or any
`docs/issue-<n>/proposals/*.md`. Two call sites then run the sha check
(`placeholder_shas`, :174-181) against that entire text:

- `is_proposal` early-exit, :190-194.
- the record path, after the five §20 field checks, :224-231.

```python
def placeholder_shas(text):
    bad = []
    for m in re.finditer(r'^\s*sha:\s*(.*)$', text, re.M):
        v = m.group(1).strip()
        if v == "same-commit" or re.match(r'^[0-9a-f]{40}$', v):
            continue
        bad.append(v)
    return bad
```

`deny_placeholder` (:183-188) then reports `bad[0]` in its message.

Git history since the issue's cited baseline (`778b810`) is two commits,
neither touching this function's body: `8b2bd30` (accumulate every §20
violation into one deny, issue-140) and `2f43491` (normalize `loop_state`
across the digit boundary, unrelated field). This is why the issue's own
line citations (`:174-181`, `:176`, `:183-188`) still match exactly, while
its citation for the `code_under_review` check (`:227-235`) has drifted to
`:233-242` at current HEAD — `8b2bd30` inserted lines above it restructuring
the deny path into an accumulated list. Noted so the proposal's own
citations use current line numbers, not the issue text's.

## F1 — scan scope, confirmed still live

`re.finditer(..., text, re.M)` runs over the **entire** reconstructed
document, not a region bounded to where the `sha:` convention actually
applies. Every record and proposal in this repository opens with a
`---`-delimited YAML frontmatter block carrying `upstream:` (a list of
`path:`/`sha:` pairs) — confirmed against ten sampled files across
`docs/issue-{20,90,100,116,128,133,140,146}/**` — and the convention this
check enforces (contract §1's same-commit citation form) is a property of
that block only. Nothing in the check bounds the match to it.

Consequence, reproduced by direct read of the regex against this survey's
own writing constraint: a document that *quotes* a non-conforming value
inside a fenced code block or an indented example — exactly what a
record or proposal documenting this class of defect needs to do — is
denied the same as a document that actually carries the value live in its
own frontmatter. This is not hypothetical for this subject: this survey
itself avoids ever opening a line with the field name followed by a
non-whitelisted value, for exactly this reason (the precedent is
`docs/issue-133/reports/execution-observation.md`'s own phase-1 proposal,
which had to paraphrase rather than quote at line start).

**Legitimate value with a trailing YAML comment.** Also confirmed by
direct read: a conforming value followed by ` #<comment>` on the same
line — legal YAML, and not a form this repository's corpus currently
uses, but not excluded by the convention either — fails
`v == "same-commit" or re.match(r'^[0-9a-f]{40}$', v)` because the
comment text rides along inside the captured group. Zero live instances
found (`grep -rn "sha:.*#" --include="*.md" docs/` → no hits), so this is
a latent false-positive, not an observed one.

## F2 — empty-value path, confirmed still live

`\s*` (a Python regex metacharacter that matches a newline as well as
space/tab) sits on both sides of the field-name literal in the current
pattern. Traced by hand against the pattern text (not executed, per this
role's own tooling): when a line carries the field name with nothing
following it before end-of-line, the trailing `\s*` does not stop at that
line's end — it continues consuming the newline and any further blank or
indented lines, and `(.*)$` then captures whatever non-whitespace text
starts the next non-blank line. `deny_placeholder` reports that captured
text as `bad[0]`, so the denial names a line the author did not write a
value on.

**Corpus check, this session:** `grep -rEn "^[[:space:]]*sha:[[:space:]]*$"
--include="*.md" docs/` → zero matches across the full tree. Matches the
issue's own claim (0 of 91 total `sha:` lines are value-less) — the defect
is real but has never fired against a landed document; its cost is on
future writes and on how debuggable a wrongly-triggered denial is.

**The carve-out's two possible readings**, both traced against the code as
it stands:

1. **Absent `upstream:` list entirely** (no line carrying the field name
   at all) — already, structurally, outside the regex's reach today; nothing
   to fix here.
2. **A present line carrying the field name with no value following it**
   — today this is *not* skipped; per the newline-swallowing behavior
   above, it is misread as carrying whatever text starts the next line,
   and denied under that misread value.

Issue #133's own requirement 1 wording ("빈 upstream 은 기존 규약대로") and
its restatement in the observed proposal's `## Request` item 1 ("empty
`upstream` stays under the existing convention, untouched") point at
reading 2: a present-but-empty value should be treated the same way the
pre-133 bracket-only regex treated it — outside what the check flags —
not newly denied. Nothing in the delivered diff implements reading 2;
`core/hooks/tests/run-role-gates-tests.sh` carries no case for either
reading (confirmed by grep for the field name with no trailing value in
that file — no hits), so no test exercises this path in either direction.

## F1/F2 shared root: both trace to the same line

Both findings are properties of one pattern,
`r'^\s*sha:\s*(.*)$'` applied to the whole document. F1 is the match
region being too wide; F2 is the value-side `\s*` being too permissive
(crossing a line it should stop at). A fix to the match region (bounding
`re.finditer` to the frontmatter block substring) does not by itself fix
F2 — an empty-value line still exists inside that narrower region and the
same-line `\s*` still needs to stop at the newline. Both changes touch the
same function; neither subsumes the other.

## Requirement 3 — class census

Grep across every `core/hooks/*.sh` (excluding `tests/`) for `re\.(search|match|finditer|sub)` calls, read at each hit:

- `approval-gate.sh`, `gh-guard.sh`, `handbook-trigger-gate.sh`,
  `trailer-gate.sh` — each pattern's match target is already the exact
  region the rule is about (a branch name, a shell command string, a
  staged-file list, the joined commit message) — no whole-document-vs-
  canonical-surface gap of the kind F1 names.
- `record-fields-gate.sh`'s own five §20 field checks (:198-222) scan the
  whole document, matching the prior execution-observation session's
  finding (`docs/issue-133/reports/execution-observation.md`, Finding 1's
  closing paragraph) that this is present but harmless there — a match
  found outside the intended region only makes a presence check *more*
  permissive, never refuses a legitimate write. Re-confirmed by re-reading
  each of the five at current line numbers (:202-222); unchanged in
  shape since that session.
- `code_under_review:` (:234-235, current numbering) is a second instance
  of the same "enumerate one known bad shape" pattern the pre-133 sha
  check used, rather than an allow-list of good shapes — it denies only
  when the value is *exactly* a bare 7-40 character hex token, nothing
  else. Unlike the sha check, this is not observed or plausibly causing
  false-positive denials of legitimate values: a real file list (the
  required shape, per `docs/issue-100/decisions/2026-08-03-record-citation-format-and-kind-convention.md`)
  contains backticks, commas, or path separators, so it can never
  accidentally collapse into a bare hex token. No corpus instance found
  where this check misfires (`grep` across `docs/issue-*/reports/{coding,implementation}.md`
  for the field, all values are file lists or absent).

Judgment on requirement 3 (recorded here, applied in the proposal): F1's
class (whole-document scan vs. canonical-surface region) has exactly one
confirmed-harmful habitat, the sha check itself, now in this issue's write
set. `code_under_review`'s enumerate-bad-shape check is a real second
instance of a *related but distinct* class (deny-one-known-bad-shape vs.
allow-list-good-shapes) with no demonstrated or plausible harm today, and
the issue's own constraint text scopes #153 to "record-fields-gate.sh 의
sha 검사와 빈 값 경로만" — the proposal records this as an accepted
limitation rather than pulling it into this write set.

## Adjacent tracks — file-level overlap check

- **#141** (open PR #144, `issue-141/implementation` → `main`): diff
  touches `core/hooks/handbook-trigger-gate.sh`, `core/hooks/trailer-gate.sh`,
  and their own test files — no line in `core/hooks/record-fields-gate.sh`.
  No overlap.
- **#146** (open PR #148, `issue-146/implementation` → `main`, phase 1):
  diff is `docs/issue-146/proposals/*.md` and
  `docs/issue-146/reports/implementation/survey.md` only — no code change
  yet. Its own proposal's stated fix direction (a mechanical literal↔prose
  coverage check, plus fixing needle-list substring checks) would, if and
  when it reaches phase 2, most plausibly touch the five §20 field checks
  (:198-222) and `core/hooks/directive.sh`'s injected prose — a different
  region of the same file than this issue's write set (:174-194 plus the
  header comment). Flagged, not a present conflict.
- **#147** (no branch, no PR — not yet started): its three findings (C1
  §20 fields unannounced in prose, C2 terminal-state override channel
  inert, C3 handbook-trigger-gate §21) target
  `core/hooks/record-fields-gate.sh:95` (`RF_TERMINAL` default) and
  `:202-222` (the five §20 checks) plus `core/hooks/directive.sh` — again a
  different region of the same file, no line overlap with this issue's
  sha-check write set. Since it has not started, there is no open PR to
  coordinate against yet; the proposal notes that a phase-2 build should
  re-diff against `main` before editing, in case #147 lands first.

No currently-open PR edits a line this issue's write set touches.

## Test harness

`core/hooks/tests/run-role-gates-tests.sh` (:60-71) defines `run_rf`,
already used by every existing sha-check case (issue-128, issue-133,
:94-121). This is the harness a red→green pair for F1 and F2 extends —
same helper, same style, no new infrastructure needed. A frontmatter-only
scan needs one more thing the current `run_rf` payload shape already
supports: a `content` string whose fenced-code-block portion carries a
non-conforming value outside the frontmatter delimiters, to prove the scan
no longer reaches it.

## Handbook

`docs/handbooks/role-gates-tests.md:47-59` documents the current
whole-document allow-list check in prose. It says nothing today about scan
region or the empty-value case, so both need a same-turn addition once the
gate's behavior changes (doctrine ladder: a changed check's description
lives in the component's handbook).

## Write set this survey projects

- `core/hooks/record-fields-gate.sh` — bound `placeholder_shas`'s scan to
  the frontmatter block substring (both call sites keep calling the same
  function); fix the value-side pattern so a same-line empty value cannot
  cross into a following line; decide and implement the empty-value
  carve-out reading; leave `code_under_review` and the five §20 checks
  untouched.
- `core/hooks/tests/run-role-gates-tests.sh` — red→green cases for F1
  (fenced-block quotation now allowed, frontmatter-region violation still
  denied) and F2 (empty value allowed, denial message — when a real
  violation exists on the same line — never names a different line).
- `docs/handbooks/role-gates-tests.md` — update the one section describing
  the sha check to state its scan region and the empty-value carve-out.
- No existing `docs/issue-<n>/proposals/*.md` or `reports/*.md` file is
  edited (no retroactive fix, consistent with #100/#133 precedent); this
  issue's own constraint text does not raise the question but the
  precedent applies by default.

## Unknowns

- Exact phase-2 regex text for the frontmatter-bound scan and the
  comment-stripping behavior — left to the proposal's `## What will be
  done`, not resolved here.
- Whether any other role's own record (outside `coding`/`implementation`)
  has a live value-less `sha:` line — the corpus grep above is repo-wide,
  not role-scoped, and found zero, so this is answered: none exist today.
