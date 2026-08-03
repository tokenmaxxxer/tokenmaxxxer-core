---
kind: build-proposal
subject: issue-100
produced_by: implementation
loop_state: proposed
upstream:
  - path: docs/issue-100/reports/implementation/survey.md
    sha: <set at commit>
---

files: `docs/issue-100/decisions/2026-08-03-record-citation-format-and-kind-convention.md`, `core/hooks/record-fields-gate.sh`, `core/hooks/tests/run-role-gates-tests.sh`, `docs/handbooks/role-gates-tests.md`, `docs/issue-90/reports/implementation.md`, `docs/issue-94/reports/implementation.md`

## Request

Issue #100: the implementation role's own record
(`docs/issue-<n>/reports/implementation.md`) has, twice in a row, cited a
`code_under_review`/`closed_checks[].code_sha` sha that turns out to be the
docs-only *proposal* commit rather than the code commit the record
describes — confirmed independently as Finding 2 of both
`docs/issue-90/reports/execution-observation.md` and
`docs/issue-94/reports/execution-observation.md` (the second explicitly
"recurrence" of the first). Four things are asked:

1. Settle, as a decision document, that `code_under_review` is
   canonically a **file list**, with the "let the merge fill in the real
   sha afterward" alternative rejected and the rejection reasoned.
2. Give the convention exactly one mechanical check point
   (`record-fields-gate.sh` or a handbook) so an author cannot repeat the
   deviation a third time undetected — this proposal names which.
3. Fix the citation format only in `docs/issue-90/reports/implementation.md`
   and `docs/issue-94/reports/implementation.md`: `code_under_review` to a
   file list, `closed_checks[].code_sha` dropped or replaced by a
   verifiable file:line reference — verdict text unchanged.
4. Settle `kind:` (`implementation-record` vs `coding-record`) by counting
   existing records.

## Constraints

- Docs/convention issue. Even where a gate script is touched, cap it at
  the one check point requirement 2 asks for — no second gate, no
  broader rewrite of `record-fields-gate.sh`.
- `docs/issue-90/reports/execution-observation.md` and
  `docs/issue-94/reports/execution-observation.md` are execution-observation's
  own artifacts and are not touched, read-only evidence only.
- The two target records' verdict content (the `## Why`, `## What was
  done`, `## Hunt`, `closed_checks[].result`, `## Verify` prose) does not
  change — only the citation fields.

## Rationale

**File list over "resolve the sha at merge time."** The defect is
structural, not authorial carelessness: the record is committed in the
same commit as the code it describes, so the sha it would want to cite
does not exist yet when the file is written (survey, "Prior-good and
other-shaped precedent"; both defective records' own execution
observations name this same root cause independently). The rejected
alternative — have a later, merge-time step resolve and backfill the real
sha — was checked against how comparable systems solve exactly this
self-reference problem (scout brief): the working version of that pattern
(e.g. GitHub Actions capturing `git rev-parse HEAD` and threading it into
a *separate, later* job) always requires an out-of-band second write after
the triggering commit. This repo's contract grants no role the ability to
edit another role's already-merged record (§11, never-overwrite
ownership), and there is no bot/CI step in this repo that would perform
that backfill — adopting the alternative would mean inventing that
machinery for one field. It would also leave the sha unresolved for
precisely the window `closed_checks` cite-and-skip (§16) needs it in: a
downstream role reviewing the still-open PR, before any merge exists to
do the resolving. The file-list form needs no second actor, is already
knowable at write time (it is the same write set the proposal already
froze), and is exactly what this repo's own pre-issue-90 records did
(`docs/issue-88/reports/implementation.md:5`,
`docs/issue-20/reports/implementation.md:4`) before the deviation started —
restoring precedent, not inventing a new one. ADR-style conventions
scouted externally corroborate the same shape: a decision record
identifies itself by a stable symbolic key, never by its own containing
commit's sha (scout brief, "Must-bes").

**`closed_checks[].code_sha` → a `ref:` file:line pointer, not a bare
drop.** Requirement 3 offers two sub-alternatives — remove the field, or
replace it with a verifiable file:line reference. Removing loses the "here
is exactly where to look" pointer the field exists to give a reader;
several `closed_checks[].result` entries in both target records already
name a specific test case or line in prose, but not consistently as a
structured, greppable field. Replacing `code_sha:` with `ref: <file>:<line>`
keeps that pointer, keeps it independently verifiable (the reader opens the
line directly, in the same commit the record itself lands in, with no sha
to resolve at all), and is a mechanical rename rather than a content
rewrite — satisfying "인용 형식만" (citation form only). Dropping the field
outright was considered and rejected because it is strictly less
information for the same amount of editing work.

**`record-fields-gate.sh` over a handbook-only note, as the one check
point.** Both are legal per the issue's own wording; the choice is between
a mechanically enforced check and a documented-but-unenforced one. The
handbook-only route already effectively ran once: `docs/issue-90/reports/execution-observation.md:379-386`
recorded the exact same finding, with the exact same two named
alternatives, as a documented action item — and `docs/issue-94/reports/execution-observation.md:347-353`
confirms nothing in the handoff carried it forward four hours later,
naming it a recurrence with "the recurrence rate is one per issue" until
settled. A prose note with no mechanical backstop is the condition that
already produced two failures; a gate check is additive to
`record-fields-gate.sh` (one file, no per-rulebook copies to keep in sync
— confirmed the single canon copy via `docs/handbooks/canon-scripts.md`
and a repo-wide `find`), costs one narrow regex, and is exactly the kind
of check this file already performs (§20 field-shape checks). A handbook
entry is still written alongside it (doc-placement ladder, not a second
check point) so the convention is legible to a reader, not only enforced
against a writer.

**`kind: coding-record` over `kind: implementation-record`.** Counting
every top-level `docs/issue-<n>/reports/implementation.md` that carries a
`kind:` field (survey): issue-88 is the lone `implementation-record`;
issue-90, issue-93, and issue-94 are all `coding-record` — 3 of 4. This
also matches the value the contract's own artifact-kind table already
sanctions for this role's record
(`core/contract/role-handoff-contract.md:63`, under the pre-rename role
name `coding` — a known, separately-tracked naming double, not something
this proposal reconciles). Majority usage and the contract's own table
agree; `implementation-record` is not carried forward.

## What will be done

1. `docs/issue-100/decisions/2026-08-03-record-citation-format-and-kind-convention.md`
   (new): records all four decisions above — file-list `code_under_review`
   with the rejected alternative and why; `ref:` file:line replacing
   `closed_checks[].code_sha`; the gate check as the one enforcement point;
   `kind: coding-record` as canonical, with the count.
2. `core/hooks/record-fields-gate.sh`: one additive check, scoped to
   `role in {"coding", "implementation"}` (the known naming double), that
   denies a write to that role's own record when `code_under_review:`'s
   value, stripped, matches a bare single commit-sha token
   (`^[0-9a-f]{7,40}$`, nothing else on the line) instead of a file list.
   No other check in this file changes.
3. `core/hooks/tests/run-role-gates-tests.sh`: one new case driving
   `record-fields-gate.sh` as a subprocess with `CLAUDE_ROLE=implementation`,
   asserting refusal on a bare-sha `code_under_review:` and pass on a
   file-list one.
4. `docs/handbooks/role-gates-tests.md`: one entry documenting the new
   check, same turn as the gate change.
5. `docs/issue-90/reports/implementation.md`: `code_under_review` becomes
   the file list of files the record's `## What was done` already names
   (`core/hooks/board-gate.sh`, `core/hooks/approval-gate.sh`,
   `core/hooks/tests/run-board-gate-tests.sh`,
   `core/hooks/tests/run-approval-gate-tests.sh`,
   `docs/handbooks/board-gate-tests.md`,
   `docs/handbooks/approval-gate-tests.md`); each `closed_checks[].code_sha`
   line becomes `ref:` pointing at the specific test case or code line that
   entry's unchanged `result:` already describes. Same edit shape for
   `docs/issue-94/reports/implementation.md`. `kind:` in both is left as
   `coding-record` (already canonical, no change needed).

## Out of scope

- `docs/issue-93/reports/implementation.md`, which carries the same-looking
  pattern (survey) but was never independently confirmed by an
  execution-observation pass and is not named in issue #100's requirement
  3 — left untouched; noted as a residual for a future issue, not silently
  fixed here.
- Retroactively changing `docs/issue-88/reports/implementation.md`'s
  `kind: implementation-record` to `coding-record` — issue-88 is not named
  in requirement 3, and the decision doc governs new/edited records, not a
  blanket repo-wide rewrite.
- Rewriting `core/contract/role-handoff-contract.md`'s §16 `closed_checks`
  schema definition itself, or any check beyond the single one named above.
- Building any merge-time or CI mechanism to resolve a real sha
  post-merge — the rejected alternative.
- `docs/issue-90/reports/execution-observation.md` and
  `docs/issue-94/reports/execution-observation.md` — read-only.

## How you'll know it worked

- `bash core/hooks/tests/run-role-gates-tests.sh` passes in full,
  including the new case, and the pre-existing cases are unaffected.
- A synthetic write with `CLAUDE_ROLE=implementation` and
  `code_under_review: <40-hex-char-sha>` is denied by
  `record-fields-gate.sh`; the same write with a file-list value is not.
- `git diff` on `docs/issue-90/reports/implementation.md` and
  `docs/issue-94/reports/implementation.md` touches only the
  `code_under_review:` line and the `closed_checks[].code_sha` →
  `closed_checks[].ref` lines — zero changed words anywhere else in either
  file (verdict prose byte-identical).
- `docs/issue-100/decisions/2026-08-03-record-citation-format-and-kind-convention.md`
  exists and states the rejected alternative with its reason, and the
  `kind:` count.
