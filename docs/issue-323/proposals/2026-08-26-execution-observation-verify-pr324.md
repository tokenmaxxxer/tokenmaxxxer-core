---
status: proposed
files:
  - docs/issue-323/reports/execution-observation.md
---

# Proposal: execution-observation record verifying issue-323/implementation (PR #324)

## Request

Fill the pre-written execution-observation record skeleton at
`docs/issue-323/reports/execution-observation.md` (issue #2135 skeleton)
with an independent verification of the work landed on
`issue-323/implementation` and opened as PR #324 ("issue-323: fix
scope-gate.sh heredoc ENOSPC exposure, audit remaining hook scripts",
commit `8fb4857`, `Closes #323`): that PR's claim is that
`warrant/hooks/scope-gate.sh`'s embedded `python3 <<'PY' ... PY` heredoc
payload — which falls back to a `mkstemp()` temp file under `$TMPDIR`
once the body crosses bash's ~64KB pipe-buffer threshold, and fails with
a confusing `cannot create temp file for here-document` /
`fail-closed: gate aborted (rc=1)` message under disk/inode exhaustion —
was extracted into a real sibling file, `warrant/hooks/lib/scope-gate.py`,
loaded via plain `python3 <path>` instead of a heredoc, removing the
temp-file dependency entirely; that the failure was reproduced live
before the fix and shown absent after; that the scope-gate and
role-gates hook test suites pass unchanged; and that the other 21 (25 by
the implementation's own wider grep) heredoc-using hook scripts named in
the issue are each given an explicit shared-exposure disposition,
deferred to a follow-up issue.

## Constraints

- Write only `docs/issue-323/reports/execution-observation.md` this
  phase — no code, no other role's record, no other issue's tree.
- The record must use the pre-written skeleton's frontmatter (`issue`,
  `role`, `loop_state`, `upstream`, `subject`, `test`, `result`,
  `assertedBy`) and its five section headings, in the skeleton's own
  order — this proposal does not introduce a new record shape.
- The `observability-phase-trace` skill mapped onto this session
  (per the spawn context) is a cross-family keyword match, not a fit:
  it checks a phase-2 record's signal set against a methodology
  phase-1 named for an observability *surface* (RED/USE-style panel
  work). Issue #323 is a bash-heredoc/ENOSPC bugfix with no
  observability-methodology phase-1 artifact to trace against — this
  record does not invoke it, and states that explicitly rather than
  silently dropping it.
- PR #324 was delivered on `issue-323/implementation`; this record's
  basis is that PR's actual diff/commit (`8fb4857`) and its own
  `docs/issue-323/reports/implementation.md`, not a phase-1 proposal for
  the implementation role (none is referenced in the commit trailer).
- PR #324 is still open, not yet merged to main; this record observes
  the PR's content as of its current commit (`8fb4857`); if that commit
  changes materially before phase-2 work starts, that basis is stated
  explicitly rather than silently re-read.

## Rationale

Considered writing a full current-state survey
(`docs/issue-323/reports/execution-observation/survey.md`) before this
proposal, per the standard survey-before-proposal ordering. Rejected:
there is no open design decision here to survey toward. The record's
structure is fixed by a pre-written skeleton (issue #2135), and the
subject matter — PR #324's 3-file diff, its own implementation record,
and issue #323's four verbatim acceptance checks — is a closed,
already-written set of artifacts to read and independently re-run, not
a space of implementation alternatives to weigh. Writing a survey file
here would restate the same diff read the record itself performs,
adding a file without adding information. This falls under the
survey-order-directive's own "the spec leaves no design decision open"
skip condition, named here per that directive's requirement that the
skip be stated, not left implicit.

## What will be done

Re-derive, from the actual source on `issue-323/implementation` (not
just PR #324's own narration), whether `warrant/hooks/scope-gate.sh` no
longer embeds a heredoc and now loads `warrant/hooks/lib/scope-gate.py`
as a plain file argument; confirm the extracted Python body is
byte-identical (modulo the stated header-comment addition) to the
pre-fix heredoc content at `f30c9120`; re-run
`core/hooks/tests/run-scope-gate-tests.sh` and
`core/hooks/tests/run-role-gates-tests.sh` directly rather than trusting
the pasted 46/46 and 83/83 counts; independently attempt the
constrained-TMPDIR (0 free inodes/bytes) reproduction against both the
pre-fix heredoc shape and the fixed real-file shape to check the
before/after claim rather than only reading the pasted transcripts;
independently grep the repository for heredoc-using hook scripts
(`<<`, `<<<`) to cross-check the implementation record's 25-script
audit list and byte sizes against the issue's named 21+1 count and note
any discrepancy; check the PR body's test-plan checkboxes and `Closes
#323` trailer against the four acceptance checks verbatim; record a
concrete verdict (pass/fail per claim, evidenced with pasted command
output) in the skeleton's `## What was done`, `## Why`,
`## Upstream basis`, `## Open findings`, and `## Next steps` sections;
set `result:` and `assertedBy:` frontmatter and move `loop_state` to
this record kind's terminal value once verification is complete.

## Out of scope

- Re-opening or re-litigating PR #324's fix approach itself — that call
  belongs to issue #323/PR #324, not to this observation.
- Fixing any of the other 21-25 heredoc-using hook scripts, or filing
  the follow-up issue for them — both are explicitly left to the
  user/maintainers per the role-handoff contract's invariants.
- Any gate or hook code change.
- Invoking `observability-phase-trace` (see Constraints — not a fit for
  this issue's subject matter).
- Anything outside `docs/issue-323/reports/execution-observation.md`.

## How you'll know it worked

`docs/issue-323/reports/execution-observation.md` is filled in per the
skeleton with a stated, evidenced verdict on PR #324's central claims
(heredoc removed and replaced with a real-file load; extracted payload
unchanged; live before/after ENOSPC reproduction holds; scope-gate and
role-gates suites pass with no normal-condition regression; the
21-25-script audit is accurate and each script's disposition is
explicit), citing actual source lines and pasted command output rather
than only restating PR #324's own text, frontmatter
`result:`/`assertedBy:` set, and `loop_state` at this record kind's
terminal value.
