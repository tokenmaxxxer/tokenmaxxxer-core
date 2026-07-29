# Report: coding (issue-21)

loop_state: landed

## What was done

Prose sweep renaming stale `muster` mentions to `on-the-record`. Grepped the repo
case-insensitively for `muster` to confirm exact wording before editing. Five live sites were
updated with a literal `muster` -> `on-the-record` substitution:

- `README.md:137` — "muster enables them per role" -> "on-the-record enables them per role"
- `freelunch/README.md:96` — "muster enables it per role" -> "on-the-record enables it per role"
- `scout/README.md:77` — "muster enables it per role" -> "on-the-record enables it per role"
- `core/hooks/directive.sh:6` (comment) — "a session muster did not spawn" -> "a session
  on-the-record did not spawn"
- `core/hooks/board-gate.sh:20` (comment) — "Role sessions get it from muster" -> "Role sessions
  get it from on-the-record"

Also added phase-1 docs in the same PR: `docs/issue-21/reports/coding/survey.md` and
`docs/issue-21/proposals/coding.md`.

## Why

Issue #21 requires cleaning up prose left behind by the earlier on-the-record rename. These five
sites are live documentation/comments describing current mechanics (not historical citations), so
they should reflect the current name.

## Upstream basis

GitHub issue #21 (rename sweep request). Confirmed via `grep -rniE "muster"` across the repo that
these five sites — and only these five, outside of historical citations such as
`core/contract/role-handoff-contract.md:665` and prior issue-14/issue-18/issue-12 report/proposal
docs (which record what actually happened at the time and must not be rewritten) — are the stale,
non-historical `muster` mentions. See `docs/issue-21/reports/coding/survey.md`.

## Open findings

None. This was a small, fully-specified, literal text substitution with no behavioral change.
