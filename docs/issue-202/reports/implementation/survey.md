# Survey — issue-202: warrant hunt-record path vs board-gate role-scope

## Current state

`warrant/hooks/directive.sh` line 76-79 and `warrant/agents/warrant-hunter.md`
lines 80-88 both derive the hunt-record path from whether the *proposal's own
path* carries an issue segment:

- proposal at `docs/issue-<n>/proposals/...` -> record at
  `docs/issue-<n>/reports/hunt-<proposal-slug>.md`
- otherwise -> `docs/reports/<date>-hunt-<proposal-slug>.md` (unchanged)

This is the fix issue-200 landed (`1f2a62c`, `docs/issue-200/proposals/conflict-free-system-writes.md`)
for a *different* failure mode: same-day same-slug hunt reports from two
concurrent issues colliding at `docs/reports/`. It scoped the report into the
issue's tree but stopped at the issue directory — it does not add a
role subdirectory.

`core/hooks/board-gate.sh` R5 (lines 599-614), the gate every role-session
docs write runs through in a board repo (`docs/specs/approvers.md` present +
`CLAUDE_ROLE` set), allows a write under `docs/issue-<n>/reports/` only when
the path's first segment after `reports/` is exactly one of:

- `<role>.md` (a single file)
- `<role>` (a subdirectory, `<role>/**`)
- the role's registered `EXTRA_SUBTREE` entry, if any

`docs/issue-<n>/reports/hunt-<slug>.md` has first segment `hunt-<slug>.md`,
which matches none of those three for any role — R5 denies it with "belongs
to another role" every time, in every role session, regardless of which role
is running. This reproduces the issue's report: every post-PR
implementation session that reaches the after-proposal/before-landing hunt
dispatch and writes into `docs/issue-<n>/reports/` (issue-200 having just
made that the target) strands on `progressed-dirty-tree`.

Confirmed by reading `core/hooks/board-gate.sh` R3/R4/R5 directly (lines
555-614): a role session's git branch is required to be exactly
`issue-<n>/<CLAUDE_ROLE>` (R4, lines 576-591) before any `docs/issue-<n>/`
write is even considered — so both the issue number and the role are already
recoverable from environment the session carries (`CLAUDE_ROLE` +
`git symbolic-ref --short HEAD`), with no separate rule to hardcode: this is
literally the same derivation R4 performs, read once by directive.sh's
instructions rather than duplicated as a second copy of the glob.

Outside a role session (no `CLAUDE_ROLE`, or `CLAUDE_ROLE` set but no board
marker / branch not `issue-<n>/<role>`-shaped), R3 never fires and
`docs/issue-<n>/...` writes are unconstrained (`not role -> allow()` at
board-gate.sh line ~537, or R2/R3 deny board writes and route back to
`docs/reports/...` instead), so the existing `docs/reports/<date>-hunt-...`
fallback still applies unchanged there. Standalone (non-role) warrant use is
therefore untouched by this fix.

## Write set surveyed

- `warrant/hooks/directive.sh` — hunt-dispatch instruction text (line ~76),
  the model-facing source of the illegal path.
- `warrant/agents/warrant-hunter.md` — the hunter's own path-derivation
  instructions (lines 80-88), which must agree with directive.sh's text or
  the dispatcher and the hunter disagree on where the record lives.
- `warrant/hooks/tests/run-directive-hunt-path-tests.sh` (new) — the
  acceptance criterion's "unit test renders the warrant directive for a
  role-session context" requirement; directive.sh emits static instructional
  text (no shell interpolation — the heredoc is quoted `<<'EOF'`), so the
  test that can exist is: render directive.sh's stdout and assert it
  contains the role-subdirectory template `docs/issue-<n>/reports/<role>/`
  and does NOT contain the old flat template
  `docs/issue-<n>/reports/hunt-<proposal-slug>.md`; separately assert the
  standalone-context text `docs/reports/<date>-hunt-<slug>.md` is still
  present unchanged.
- `docs/issue-202/reports/implementation/survey.md` (this file),
  `docs/issue-202/reports/implementation.md` — phase-1/phase-2 records.

## Alternatives considered (feeds the proposal's Rationale)

1. **Derive role/issue in directive.sh's own bash and interpolate a
   concrete path into the heredoc** (change `<<'EOF'` to `<<EOF` and compute
   `$CLAUDE_ROLE`/issue-number via `git symbolic-ref` before printing).
   Plausible: directive.sh already runs as a live hook with env access.
2. **State the derivation rule in prose, unchanged mechanism** (keep the
   heredoc quoted/static; tell the model, in instructional text, to compute
   the role-subdirectory path itself from `CLAUDE_ROLE` + its branch when
   both resolve, else fall back to the old rule). Matches how directive.sh
   already hands other computed facts (diff size, cap tier) to the model as
   instructions rather than precomputed values — the model, not the hook,
   dispatches the hunter and writes the path into its prompt.
3. **Hardcode `docs/issue-<n>/reports/<role>/...` unconditionally**,
   dropping the standalone fallback. Rejected up front: breaks the
   acceptance criterion's explicit empty-state case (no `CLAUDE_ROLE` must
   still name `docs/reports/...`).

Option 2 is what the proposal picks; see proposal Rationale for why over
option 1.
