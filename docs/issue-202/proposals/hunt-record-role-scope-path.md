---
status: proposed
files:
  - warrant/hooks/directive.sh
  - warrant/agents/warrant-hunter.md
  - warrant/hooks/tests/run-directive-hunt-path-tests.sh
  - docs/issue-202/reports/implementation/survey.md
  - docs/issue-202/reports/implementation.md
---

## Request

`warrant/hooks/directive.sh` (~line 76) and `warrant/agents/warrant-hunter.md`
(~lines 80-88) tell the warrant-hunter to write its hunt record to
`docs/issue-<n>/reports/hunt-<slug>.md` whenever the proposal path carries an
issue segment. Inside a role session governed by `on-the-record`'s
`board-gate.sh`, that path's first segment after `reports/` is
`hunt-<slug>.md`, which matches none of R5's allowed shapes
(`<role>.md`, `<role>/**`, or the role's extra subtree) — the gate denies it
as belonging to another role, on every role, every time. Every implementation
session that reaches its post-PR hunt dispatch strands. Fix: when the
dispatching session is issue-scoped and role-scoped (`CLAUDE_ROLE` set, an
issue number resolvable from the session's own branch), name the hunt-record
path inside the role's own subtree; otherwise keep the existing behavior
unchanged.

## Constraints

- Do not hardcode a second copy of `board-gate.sh`'s role-scope glob that can
  drift from the gate's actual rule — derive the path from the same signals
  R4/R5 already key on (`CLAUDE_ROLE`, the session's own branch), not a
  re-encoded literal list of allowed shapes.
- The non-role-session (standalone warrant) path,
  `docs/reports/<date>-hunt-<slug>.md`, must be unchanged — the acceptance
  criterion's empty-state case requires it.
- `directive.sh`'s hunt-dispatch text and `warrant-hunter.md`'s own
  path-derivation text must state the same rule; they currently already
  need to agree (issue-200 kept them in lockstep) and this change must not
  break that.
- No behavior change to hunt cadence, stance rotation, cap/tier logic, or
  hunt-record *content* — path only, same as issue-200's prior fix.

## Rationale

**Chosen — restate the rule in the instructional text handed to the
dispatching model, unconditioned on shell interpolation.** `directive.sh`
already hands the model several facts it must compute itself at dispatch
time (diff size -> cap tier, dispatch count mod 5 -> stance, docs-only ->
skip before-landing) as prose instructions rather than precomputed values,
because the hook fires once per turn and the model does the actual dispatch
several steps later in the same session. The hunt-record path fits the same
shape: tell the model to check whether `CLAUDE_ROLE` is set and its own
branch resolves as `issue-<n>/<CLAUDE_ROLE>` (the same check R4 performs) —
if so, name the record `docs/issue-<n>/reports/<role>/<date>-hunt-<slug>.md`
(role subdirectory, matching R5's `<role>/**` allowance); otherwise keep the
existing proposal-path-segment rule for the non-role-session case.

**Rejected alternative — interpolate a concrete path into the heredoc by
switching `directive.sh`'s `cat <<'EOF'` to unquoted `<<EOF` and computing
`$CLAUDE_ROLE`/branch in bash before printing.** Plausible given
`directive.sh` already runs as a live hook with full env access at
UserPromptSubmit time. Rejected because the heredoc is emitted once at the
*start* of a turn, and the hunt dispatch it is describing happens
*mid-session*, potentially turns later, on whatever branch/role state holds
at dispatch time, not at hook-fire time — precomputing a single literal path
into static instructional text would go stale the moment the session's
branch changes (e.g. between phase-1 and phase-2, or in a session that opens
before `CLAUDE_ROLE`/branch are both settled) and, more immediately, would
require unquoting a currently-quoted heredoc that also contains literal `$`
and backtick-shaped example text elsewhere in the same block, risking
unintended shell interpolation in unrelated lines. Keeping the heredoc
quoted and pushing the derivation into instructional prose (option 2 in the
survey) matches how every other computed-at-dispatch-time fact in this same
file is already handled and touches nothing else in the block.

**Rejected alternative — hardcode
`docs/issue-<n>/reports/<role>/...` unconditionally, dropping the
standalone fallback.** Rejected because the acceptance criterion's stated
empty-state case (no `CLAUDE_ROLE` -> `docs/reports/<date>-hunt-<slug>.md`)
requires the fallback to survive.

## What will be done

1. **`warrant/hooks/directive.sh`** (~line 76, the "Tell it five things"
   paragraph): replace the proposal-path-segment derivation rule with:
   when `CLAUDE_ROLE` is set for this session and the session's own branch
   resolves as `issue-<n>/<CLAUDE_ROLE>` (the same check the board-gate's
   own R4 performs), the record goes to
   `docs/issue-<n>/reports/<role>/<date>-hunt-<proposal-slug>.md`; otherwise
   the existing rule stands (proposal path carries an issue segment ->
   `docs/issue-<n>/reports/hunt-<proposal-slug>.md`; no issue segment ->
   `docs/reports/<date>-hunt-<proposal-slug>.md`).
2. **`warrant/agents/warrant-hunter.md`** (Output section, lines ~80-88):
   restate the same three-way rule so the hunter agent's own path-derivation
   text agrees with what the dispatcher's prompt will tell it, and so a
   hunter invoked standalone (no dispatcher prompt override) derives the
   same path from the same signals.
3. **`warrant/hooks/tests/run-directive-hunt-path-tests.sh`** (new): renders
   `directive.sh`'s stdout (it is a static heredoc — no env needed to render
   it) and asserts the role-subdirectory template
   `docs/issue-<n>/reports/<role>/` string is present, the old
   unconditional flat template `docs/issue-<n>/reports/hunt-<proposal-slug>.md`
   is stated only as the non-role-session fallback (still present, but
   qualified), and the standalone `docs/reports/<date>-hunt-<slug>.md` text
   is unchanged and present. This is the acceptance criterion's "unit test
   renders the warrant directive for a role-session context ... asserts the
   hunt-record path" — `directive.sh` has no runtime CLAUDE_ROLE branching
   to unit-test (the rule lives in prose the model reads and applies later,
   per the Rationale above), so the test verifies the rendered instruction
   text contains and correctly conditions the role-scope template rather
   than executing a role-session end-to-end.

## Out of scope

- Any change to `on-the-record`'s `board-gate.sh` itself — this repo does
  not own that file; issue text confirms the on-the-record-side proposal is
  already merged there.
- `warrant/hooks/hunt-guard.sh` / `hunt-state.sh` (the `.git/`-relative
  count/lock relocation) — already fixed by issue-200, untouched here.
- Any change to hunt cadence, stance rotation, or cap/tier computation.
- Retroactively renaming/moving any hunt record already written under the
  old flat path (e.g. from issue-200's own session) — those are historical
  records, not live state.

## How you'll know it worked

- `warrant/hooks/tests/run-directive-hunt-path-tests.sh` passes: the
  rendered directive text contains the role-subdirectory template and the
  unchanged standalone fallback template, and does not state the flat
  `docs/issue-<n>/reports/hunt-<slug>.md` template as the unconditional rule
  for a role session.
- Manual check: a role session's hunt dispatch prompt (constructed by
  following the updated instructions by hand for `CLAUDE_ROLE=implementation`,
  branch `issue-202/implementation`) names
  `docs/issue-202/reports/implementation/<date>-hunt-<slug>.md`, which
  satisfies `board-gate.sh` R5's `tail[0] == role` branch (`implementation`
  is exactly the first path segment after `reports/`) — traced by re-reading
  `core/hooks/board-gate.sh` lines 599-614 against the constructed path,
  not by running the gate against a synthetic role session (no board-gate
  test harness is in this write set).
