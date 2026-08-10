---
status: proposed
files:
  - core/hooks/lib/role-directive.sh
---

Scout skip: scout-directive's second mandatory skip condition applies —
the spec leaves no design decision open. See
`docs/issue-195/reports/implementation/survey.md` for the full reasoning.

## Request

`core_role_directive`'s RECORD line names the record's location and
phase-gating but not its required shape. Downstream sessions have written
commit shas into `code_under_review` and unsourced counts, and been
rejected post-hoc by `record-fields-gate`/`record-claim-guard`/
`accumulation-claim-guard`. Since this heredoc is the single co-injected
authoring point for all 43 roles, fix it there — pre-emptively — instead
of only at the post-hoc gates.

## Constraints

- Text-only change inside the existing heredoc; no new wiring, no new
  functions, no new gate scripts.
- Role-agnostic: the added rules must appear in the directive output
  regardless of `$CLAUDE_ROLE`.
- `core/hooks/tests/parse-check.sh`'s bash-3.2 parse check must keep
  passing — no bash4-only syntax introduced.

## Rationale

Considered adding a new mechanical pre-check (a script sourced by
`role-directive.sh` that validates a role's record shape before commit)
instead of editing the heredoc text. Rejected: the issue is explicitly
about the *authoring* point emitting the wrong information, not about
adding another enforcement layer — enforcement already exists
post-hoc (`record-fields-gate.sh`, `record-claim-guard.sh`,
`accumulation-claim-guard.sh`); the issue's own `## What will be done`
scopes the fix to directive content ("내용만; 새 배선 없음" — content
only, no new wiring). A new gate would also run once per commit rather
than once per session start, missing the "corrective at the point where
the session first reads its own record contract" property the issue is
after.

## What will be done

Extend `core_role_directive`'s heredoc (line 46 of
`core/hooks/lib/role-directive.sh`) with three format rules appended
after the existing `RECORD:` line, applying role-agnostically to the
`${role}` token already in scope:

1. `code_under_review:` must be a file list (`- path` entries per
   reviewed/changed file), never a commit sha.
2. Any count claim must cite an actual code-fenced command output,
   preceded by a `derived: <command or path>` line.
3. When the change is accumulation-cost-shaped, the proposal's
   `## Accumulation` section must be filled with real content.

## Out of scope

- Any change to the post-hoc gate scripts (`record-fields-gate.sh`,
  `record-claim-guard.sh`, `accumulation-claim-guard.sh`) themselves.
- Any change to per-rulebook `directive.sh` callers — they pass through
  unchanged since the new text lives entirely inside the shared heredoc.
- Writing new tests infrastructure beyond the one red/green capture the
  issue's acceptance check names.

## How you'll know it worked

`CLAUDE_ROLE=implementation` sourcing `role-directive.sh` and invoking
`core_role_directive` with placeholder args, capturing stdout, then
grepping for the three rule strings — red before the edit (rules absent),
green after (rules present, role-agnostically since `role` is only used
for the record path token, not gating which rules print).
