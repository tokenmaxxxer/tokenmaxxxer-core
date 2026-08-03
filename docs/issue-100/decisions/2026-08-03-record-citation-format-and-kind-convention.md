---
kind: decision
subject: issue-100
produced_by: implementation
loop_state: decided
upstream:
  - path: docs/issue-100/proposals/2026-08-03-canonicalize-record-citation-format.md
    sha: 8637a9ff24268468ca7e900a9661c1ab8ad229ea
---

# Decision: record citation format and `kind:` convention (issue-100)

## Context

The implementation role's own record (`docs/issue-<n>/reports/implementation.md`)
cited a `code_under_review`/`closed_checks[].code_sha` that pointed at the
docs-only *proposal* commit rather than the code commit the record
describes, twice in a row — confirmed independently as Finding 2 of both
`docs/issue-90/reports/execution-observation.md` and
`docs/issue-94/reports/execution-observation.md` (the second explicitly
"recurrence" of the first). This document settles the convention so a
third recurrence is structurally prevented, not re-corrected session by
session.

## Decision 1 — `code_under_review` is a file list, not a commit sha

`code_under_review` in `docs/issue-<n>/reports/implementation.md` cites the
reviewed **write set as a file list** (e.g. `` `core/hooks/foo.sh`,
`docs/handbooks/foo.md` ``), never a bare commit sha.

**Rejected alternative: resolve the real sha at merge time.** A later,
merge-time (or CI) step would backfill the record's `code_under_review`
with the real landing sha once it exists. Rejected because the defect is
structural, not authorial carelessness: the record is committed in the
same commit as the code it describes, so the sha it would want to cite
does not exist yet when the file is written. The working version of this
pattern in comparable systems (e.g. GitHub Actions capturing `git
rev-parse HEAD` into a separate, later job) always needs an out-of-band
second write after the triggering commit; this repo's contract grants no
role the ability to edit another role's already-merged record (§11,
never-overwrite ownership), and there is no bot/CI step here that would
perform that backfill — adopting the alternative means inventing that
machinery for one field. It would also leave the sha unresolved for
exactly the window `closed_checks` cite-and-skip (§16) needs it in: a
downstream role reviewing the still-open PR, before any merge exists to do
the resolving. The file-list form needs no second actor, is already
knowable at write time, and restores this repo's own pre-issue-90
precedent (`docs/issue-88/reports/implementation.md:5`,
`docs/issue-20/reports/implementation.md:4`).

## Decision 2 — `closed_checks[].code_sha` becomes `ref: <file>:<line>`

A `closed_checks[]` entry in the implementation role's own record cites its
evidence as `ref: <file>:<line>` — a verifiable pointer into the same
commit the record itself lands in — instead of `code_sha: <sha>`.

**Rejected alternative: drop the field entirely.** Considered and
rejected: it is strictly less information for the same amount of editing
work. `ref:` keeps the "here is exactly where to look" pointer the field
exists to give a reader, keeps it independently verifiable with no sha to
resolve, and is a mechanical rename rather than a content rewrite.

This decision governs the implementation role's own record only; it does
not amend `core/contract/role-handoff-contract.md` §16's generic
`closed_checks` schema (still `code_sha`-keyed for `review-record` /
`verify-record`), which is out of scope here.

## Decision 3 — one mechanical check point: `record-fields-gate.sh`

The convention is enforced at exactly one point: an additive check in
`core/hooks/record-fields-gate.sh`, scoped to `role in {"coding",
"implementation"}` (the repo's known coding/implementation naming double),
denying a write to that role's own record when `code_under_review:`'s
value, stripped, matches a bare single commit-sha token
(`^[0-9a-f]{7,40}$`, nothing else on the line).

**Rejected alternative: handbook-only note, no mechanical check.** Both a
gate check and a handbook-only note are legal under the issue's own
wording; the difference is enforced vs. documented-but-unenforced. The
handbook-only route already effectively ran once:
`docs/issue-90/reports/execution-observation.md:379-386` recorded this
exact finding, with these exact two alternatives, as a documented action
item — and `docs/issue-94/reports/execution-observation.md:347-353`
confirms nothing in the handoff carried it forward, naming it a
recurrence. A prose note with no mechanical backstop is the condition that
already produced two failures. A handbook entry
(`docs/handbooks/role-gates-tests.md`) is still written alongside the gate
check so the convention stays legible to a reader, not only enforced
against a writer — but it documents the one check point, it is not a
second check point.

## Decision 4 — `kind: coding-record` is canonical

Counting every top-level `docs/issue-<n>/reports/implementation.md` that
carries a `kind:` field: issue-88 is the lone `implementation-record`;
issue-90, issue-93, and issue-94 are all `coding-record` — 3 of 4. This
also matches the value `core/contract/role-handoff-contract.md`'s
artifact-kind table already sanctions for this role's record (under the
pre-rename role name `coding` — a known, separately-tracked naming
double). Majority usage and the contract's own table agree;
`implementation-record` is not carried forward. This decision governs
new/edited records only — it does not retroactively rewrite issue-88's own
`kind:` field.

## Effect

- `core/hooks/record-fields-gate.sh` gains the one additive check
  described in Decision 3, tested in
  `core/hooks/tests/run-role-gates-tests.sh` and documented in
  `docs/handbooks/role-gates-tests.md`.
- `docs/issue-90/reports/implementation.md` and
  `docs/issue-94/reports/implementation.md` are edited to the canonical
  citation format (Decisions 1–2); their verdict content (`## Why`,
  `## What was done`, `## Hunt`, `closed_checks[].result`, `## Verify`) is
  unchanged.
