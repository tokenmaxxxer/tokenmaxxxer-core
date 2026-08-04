files: core/contract/role-handoff-contract.md, core/hooks/directive.sh, freelunch/hooks/freelunch.sh

## Request

Issue #106 asks this repo to formalize, in the contract or the
role-common directive it owns, a rule that a headless role session must
never end a turn having delegated work to a subagent while still waiting
for that delegation's completion notification — delegation is fine only
if the same turn waits for and consumes the result (through commit, if
applicable) before ending; otherwise the role must not delegate that unit
of work at all. It also asks this rule's priority to be stated explicitly
against existing directives that recommend/mandate delegation (naming the
`freelunch` family), and, where the fix instead requires editing per-role
rulebook directive text this repo does not own, to record that as
follow-up work for a separate issue rather than attempt it here. This is
the prevention half of a two-repo split; `on-the-record`'s PR #256 is the
sibling after-the-fact safety net (auto-respawn on `failed-no-commit`),
explicitly out of this proposal's scope.

## Constraints

- Do not modify `on-the-record`'s auto-respawn/stall-watchdog design
  (PR #256) — different repo, different ownership, and issue #106's own
  constraints name this explicitly.
- Do not prohibit delegation/subagent use outright — only the
  "delegate, then end the turn still waiting" pattern.
- Stay inside what this repo actually owns: `role-handoff-contract.md`,
  `core`'s own `directive.sh`, and this repo's own plugin directives
  (`freelunch`, `scout`, `warrant`, `terse`). Per-role rulebook directive
  text (e.g. `implementation-rulebook`'s own "[implementation] Role
  directive" content) lives in separate repos not reachable from this
  branch (confirmed in the survey) — editing those is out of scope here
  and gets recorded as follow-up instead.

## Rationale

**Chosen: land the rule as a new numbered section in
`role-handoff-contract.md` (the one document every role rulebook is
already required to sync against), mirror its substance in
`core/hooks/directive.sh`'s printed common directive, and add a pointer
back to it directly inside `freelunch/hooks/freelunch.sh`'s own printed
text.** All three edits are needed together: the contract section is the
authoritative statement, `directive.sh` is what every role session
actually reads at `SessionStart` (per contract v3 s10, `directive.sh` and
the contract "must describe the same rules" — its own docstring says so),
and `freelunch.sh` is the specific directive issue #247 names as being in
head-on conflict with this rule, so the carve-out has to be visible at
the exact point a session reads "priority=absolute, always delegate."

**Alternative considered and rejected: add the carve-out only inside
`freelunch/hooks/freelunch.sh`, and leave `role-handoff-contract.md`
untouched.** This would fix the one named conflict fastest, but the
contract is the structurally-required sync target for every current and
future directive-emitting plugin or role rulebook — anchoring the rule
in one consumer (`freelunch.sh`) means a *different* future directive
that independently recommends aggressive delegation (a new plugin, or a
per-role rulebook's own instructions) would not inherit the constraint
at all, reproducing the same incident under a different directive's
name. The contract is where a rule has to live for every reader to be
bound by it; a single plugin file is not.

**Alternative considered and rejected: rely on `on-the-record` PR #256's
auto-respawn safety net as the complete fix, and treat this repo's
contribution as unnecessary.** PR #256 is explicitly framed, by its own
issue (#247), as a "사후 안전망" (after-the-fact safety net) — a session
still produces the `failed-no-commit` outcome and still burns a turn
narrating a wait that goes nowhere; the safety net recovers the artifact,
it does not stop the pattern from recurring, and issue #247's own "추가
맥락" section states plainly that the more faithfully a session follows
`freelunch`'s current text, the more likely it hits this failure. A
safety net and a prevention rule answer different questions; issue #106
asks specifically for the prevention half, which only this repo (or
`implementation-rulebook`) can supply.

**Failure signal.** If, after this clause lands, a future headless role
session still narrates something like "I'll continue once the background
worker reports" and then ends its turn — the same `failed-no-commit`
shape as `repo-status-board` issue #29 phase 2 — that is the check that
would fail. Detecting that recurrence is issue #106's own requirement 3,
assigned to step 2 (execution-observation) by the issue's execution plan,
not to this proposal.

## What will be done

1. Add a new section to `core/contract/role-handoff-contract.md`
   (appended after the existing section 21, i.e. section 22, subject to
   renumbering if a concurrent change lands a competing section 22
   first) stating: a role session must not end a turn having delegated
   work (any `Agent`/`Task`-style subagent dispatch, backgrounded or not)
   whose result it has not yet consumed within that same turn; if
   delegating, the turn must wait for the result and act on it (through
   commit, where applicable) before ending; if a same-turn wait is not
   possible, the role must not delegate that unit of work. The section
   states explicitly that this rule takes priority over any directive
   that recommends or mandates delegation (naming `freelunch`'s
   `priority="absolute"` directive by name) whenever the session is a
   headless/single-shot run with no later turn to receive an async
   completion notification.
2. Mirror that rule's substance in `core/hooks/directive.sh`'s printed
   `[core] Interaction protocol` text, consistent with the file's own
   stated obligation to describe the same rules as the contract.
3. Add a short subordination note directly inside
   `freelunch/hooks/freelunch.sh`'s printed
   `<freelunch-directive priority="absolute">` text, pointing back at the
   new contract section, so a session reading freelunch's own text sees
   the carve-out in the same place it currently sees the unconditional
   delegate instruction.
4. In the phase-2 implementation record
   (`docs/issue-106/reports/implementation.md`), explicitly note that
   per-role rulebook directive text (e.g. `implementation-rulebook`'s own
   role-specific directive content) is not reachable or editable from
   this repo/branch, and recommend the human file a separate issue
   against `implementation-rulebook` (and flag whether other
   `*-rulebook` repos share the same gap, without deciding that for
   them) to carry the equivalent reflection there — satisfying issue
   #106 requirement 2's own stated fallback.

## Out of scope

- Any change to `on-the-record`'s `spawn.py`, stall-watchdog, or
  auto-respawn machinery (PR #256's territory).
- Editing `implementation-rulebook` or any other `*-rulebook` repo
  directly — unreachable from this branch; recorded as a follow-up issue
  recommendation instead.
- Building or wiring any mechanical detection/enforcement (a hook or gate
  that detects "delegated, then ended the turn still waiting") — issue
  #106's own requirement 3 assigns recurrence-detection to step 2
  (execution-observation), not to this implementation step.
- Widening the rule to interactive (non-headless) sessions' delegation
  behavior — the incident and the requested rule are scoped to headless
  execution specifically; an interactive session has a human present who
  can notice an idle wait, and does not exit the process merely because
  its main loop is idle.

## How you'll know it worked

- `core/contract/role-handoff-contract.md` contains a new numbered
  section, findable by section number, stating the same-turn-completion
  rule and its explicit priority over `freelunch`'s delegation directive.
- `core/hooks/directive.sh`'s printed text and
  `freelunch/hooks/freelunch.sh`'s printed text both reference the new
  section (grep for a cross-reference to it in both files' heredocs).
- The phase-2 record names the specific follow-up issue recommendation
  needed for `implementation-rulebook`'s own directive text.
- Step 2 (execution-observation, per issue #106's own execution plan) can
  observe, across role sessions opened after this lands, whether the
  "delegate then end-turn-waiting" pattern recurs; this proposal makes
  that observation possible without itself claiming the measurement.
