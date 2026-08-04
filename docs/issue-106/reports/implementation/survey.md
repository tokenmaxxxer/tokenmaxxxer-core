---
kind: current-state-survey
subject: issue-106
produced_by: implementation
---

# Current-state survey — issue-106

## Write set (projected)

- `core/contract/role-handoff-contract.md` — add one new numbered section
  stating the headless-execution rule (no delegate-then-end-turn-waiting)
  and its priority over any directive that mandates delegation.
- `core/hooks/directive.sh` — mirror that rule's substance in its printed
  `[core] Interaction protocol` text (the file's own docstring already
  states this text and the contract "must describe the same rules",
  `core/hooks/directive.sh:5`).
- `freelunch/hooks/freelunch.sh` — add an explicit subordination note in
  its printed `<freelunch-directive priority="absolute">` text pointing
  back at the new contract section.
- `docs/issue-106/reports/implementation.md` — phase-2 record only
  (not written this phase); will note the implementation-rulebook
  follow-up per requirement 2's fallback clause.

No other file in this repo needs to move for requirement 1 or 2. Requirement
3 (recurrence check) is explicitly assigned to step 2
(execution-observation) by the issue's own execution plan, not to this
write set.

## The incident and its otr counterpart

Issue #106's body (`gh issue view 106`) describes a role session on
`repo-status-board` issue #29 phase 2 that split work across two `Agent`
tool calls, narrated that it would wait for completion notifications, and
then ended its turn. Both dispatched-agent result records came back
`subtype: success, is_error: false` — not a crash — but the parent
process, having nothing left to do in its own main loop, exited, leaving
one worker's edits on disk uncommitted (outcome `failed-no-commit`, per the
issue body).

The sibling issue on the `on-the-record` repo,
`tokenmaxxxer/on-the-record#247` (`gh issue view 247 --repo
tokenmaxxxer/on-the-record`, open), is the fuller incident writeup:
`claude -p` headless sessions terminate once the main loop is idle;
dispatching to `Agent`/`Task` and then narrating "I'll wait for
completion" produces exactly that idle state. Its own "추가 맥락" section
states plainly: "core freelunch 지시문과 정면 충돌한다 ... 지시문을
충실히 따르는 헤드리스 세션일수록 이 실패를 맞는다" — the more faithfully
a session follows freelunch's directive, the more likely it hits this
failure — and explicitly asks whoever picks this up to judge how much of
the fix is otr's (stall-watchdog/respawn) vs. core's (directive text).

`on-the-record` PR #256 (`gh pr view 256 --repo
tokenmaxxxer/on-the-record`, open, phase-1-only per its own description)
is otr's answer to the *safety-net* half: it traces `spawn.py`'s existing
`classify()`/`session_end_verdict()`/auto-respawn machinery (issue #132)
and finds the auto-respawn only fires on a `crashed` verdict, which this
incident never produces, so it proposes a second in-process trigger keyed
off the already-computed `uncommitted-work`/`failed-no-commit` verdict.
Its body states, verbatim, that it explicitly scopes the
role-prompt/contract half (issue #247's acceptance criterion 1) **out** of
its own repo: "그 text lives in `tokenmaxxxer-core`/`tokenmaxxxer/
implementation-rulebook`, neither of which is reachable from this
branch." This confirms `tokenmaxxxer-core` (this repo) is one of the two
repos otr itself expects to carry requirement 1 — issue #106 is that
expected landing.

## This repo's contract and directive machinery (what exists today)

- `core/contract/role-handoff-contract.md` is the authority document
  ("Role handoff contract (v3: issue/PR interaction model)", line 5,
  `status: final` frontmatter). It runs 21 sections (`## 1` through
  `## 21`, confirmed by reading the file in full) covering record format,
  ownership, the approval gate, and document placement. **No existing
  section mentions subagent delegation, background/foreground task
  dispatch, or process/session lifetime** — confirmed by reading the full
  document; the nearest neighbors are section 8 (the human's seat) and
  section 19 (the propose-first phase gate), neither of which touches
  how a role session itself should behave mid-turn. This is the gap
  requirement 1 asks to close.
- `core/hooks/directive.sh` (repo root) is the `SessionStart` hook that
  prints the `[core] Interaction protocol for role '<role>'` text quoted
  in this very session's own system reminders. Its header comment states
  it is "the informing half of core — board-gate.sh is the enforcing
  half; the two must describe the same rules (contract v3 s10)"
  (`core/hooks/directive.sh:2-4`). This is the second acceptable landing
  site the issue names ("계약(또는 역할 공통 지시문)") — this file's
  printed text is common to every role, not role-specific.
- `core/hooks/lib/role-directive.sh` is a *shared library* other
  rulebooks' own `directive.sh` source to print their role-specific
  "YOU DECIDE / USE WHEN / PRODUCES / HAND-OFF" text (see its own header
  comment, `core/hooks/lib/role-directive.sh:1-20`). The actual
  role-specific strings (e.g. this session's own "[implementation] Role
  directive: YOU DECIDE: how the approved scope becomes working code...")
  are passed in as arguments *from each role's own rulebook repo* — they
  are not stored in `tokenmaxxxer-core`.
- `gh repo list tokenmaxxxer` confirms `implementation-rulebook` exists as
  a separate repo (along with ~40 other `*-rulebook` repos, one per role/
  specialization), and it is not present in this working tree or reachable
  from this branch — the same fact otr PR #256 already recorded. This
  matches issue #106 requirement 2's own conditional: the per-role
  directive text is owned by `implementation-rulebook` (and siblings),
  not by this repo, so this proposal cannot edit it here.
- `freelunch/hooks/freelunch.sh` **is** owned by this repo — it is one of
  the five plugins `tokenmaxxxer-core` ships, listed in
  `.claude-plugin/marketplace.json`. Its `UserPromptSubmit` hook prints
  `<freelunch-directive priority="absolute">` on every prompt
  (`freelunch/hooks/freelunch.sh:36`), the only directive in this repo
  carrying `priority="absolute"` (`scout`, `warrant`, and `terse`'s own
  directives are all `priority="high"` — confirmed by grepping all four
  `hooks/*.sh` files for `priority=`). Its text unconditionally instructs:
  whenever finishing a turn needs any repo/environment tool call, "YES →
  DELEGATED, always... Dispatch ONE background worker... never
  run_in_background: false" (`freelunch/hooks/freelunch.sh:45-46`). It
  carries no awareness of headless sessions, process lifetime, or the
  possibility that a background worker's completion may never be
  observed. This is the exact directive issue #247's "추가 맥락" section
  names as being in "정면 충돌" with the requested rule, and — unlike the
  per-role rulebook text — it is directly editable in this repo.

## Internal precedent: the practice already exists, ad hoc, uncodified

Four prior `implementation` role sessions in *this* repo already
independently reasoned their way to the same rule this issue asks to
codify, each treating it as a one-off judgment call rather than a
documented requirement:

- `docs/issue-20/reports/implementation.md:192-199`: "this turn's explicit
  constraint is headless and single-shot — work handed to
  `run_in_background: true` ... dies with the parent turn before it can
  report, which is the exact failure mode this session was warned
  against," citing `docs/issue-83/reports/implementation.md` as the
  earlier precedent it followed.
- `docs/issue-83/reports/implementation.md:84-86`: "No warrant-hunter
  dispatch performed this session (single-account headless turn; no
  background hunter tooling available/invoked)."
- `docs/issue-94/reports/implementation/survey.md:168-171`: "a synchronous
  adversarial review pass (general-purpose agent, read-only, foreground —
  this session is a single headless turn with no later turn to receive a
  backgrounded hunter's notification, so the dispatch could not be
  async)."
- `docs/issue-98/reports/implementation.md:172-175`: dispatched "a
  `general-purpose` subagent (`model: sonnet`, run in the foreground —
  this session is a single headless turn with no later turn for a
  background notification to land in)."

None of these four records cite a contract section or a directive line as
the source of this behavior — each session derived it independently,
in-turn, from first principles about its own execution environment. That
is the concrete evidence the rule is already de facto convention but has
never been written down anywhere a session could read it in advance,
which is precisely the gap between "known workaround" and "stated
contract requirement" that issue #106 requirement 1 asks to close.

## External field corroboration (see scout-brief.md for full detail)

Two other agent-CLI issue trackers report the identical failure shape —
a main loop treating itself as idle and exiting while background work is
still outstanding (`oh-my-openagent` issues #3452 and #4721, both cited
with URLs in `scout-brief.md`). Claude Code's own headless documentation
(`https://code.claude.com/docs/en/headless`) states that in current
versions, `claude -p` does wait (capped at 10 minutes) for background
subagents before exiting — but this is a host/version-dependent
guarantee, and the incident this issue reports demonstrably did not
receive it. The rule this proposal drafts is therefore framed as a
caller-side (role-session) obligation that does not depend on assuming
any particular host behavior.

## Other places checked, found not relevant

- `docs/decisions/` does not exist yet in this repo (`ls docs/decisions/`
  → no such directory); a hard-to-reverse choice under contract section 21
  would go there, but this issue's fix is a contract-text/directive-text
  change, not a library/format/schema choice, so this survey does not
  project a write there.
- `core/hooks/tests/canon-manifest.txt` and `canon-forms.txt` register
  structural shapes for `directive.sh` boilerplate reuse; neither
  enumerates contract section numbers or freelunch directive content, so
  adding a new contract section and a freelunch text note carries no
  coupling to these test fixtures (confirmed by reading both files in
  full — 8 and 27 lines respectively).
- `docs/specs/approvers.md` lists `JiwonJung94` and `jjongkwann` as this
  repo's approvers — unchanged, no action needed.

## Unknowns

- Whether `*-rulebook` repos other than `implementation-rulebook` need the
  equivalent per-role directive reflection is not decided by this survey
  or this issue's own text (issue #106 names only
  `implementation-rulebook`, conditionally). The proposal recommends
  filing that as its own separate issue rather than guessing the answer
  here.
- The exact section number the new contract clause will occupy (this
  survey did not reserve one; the proposal states it will be appended as
  the next section after the existing 21) is subject to revision if a
  concurrent PR lands a competing section 22 first — ordinary merge-race
  risk, not specific to this change.
