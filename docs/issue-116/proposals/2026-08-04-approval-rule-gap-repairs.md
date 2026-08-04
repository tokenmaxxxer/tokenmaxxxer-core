files: freelunch/hooks/observe.sh, freelunch/hooks/tests/run-observe-tests.sh, core/hooks/tests/run-all.sh, warrant/hooks/directive.sh, core/hooks/directive.sh, core/contract/role-handoff-contract.md

## Request

Issue #116 bundles three step-2-observation follow-ups (`docs/issue-106/reports/execution-observation.md`
Findings 1-2, and `on-the-record` issue-227's execution-observation
Finding 1) into one repo-owned fix set:

1. `freelunch/hooks/observe.sh`'s `sync_agent_dispatch` check denies,
   under `FREELUNCH_ENFORCE=1`, exactly the `run_in_background: false`
   dispatch shape contract §22 requires a headless session to use — the
   deny's own reason text asserts a premise (a completion notification
   "is semantically equivalent to waiting") that §22 was written to
   deny. `freelunch/hooks/freelunch.sh`'s prose already carries a
   subordination note pointing at §22; `observe.sh`, the mechanical
   half of the same plugin, does not.
2. `warrant/hooks/directive.sh` carries the same unconditional
   "dispatch one background agent... and carry on without waiting for
   it" language `freelunch/hooks/freelunch.sh` carried before issue-106
   added its subordination note, with no note of its own and zero
   occurrences of `s22`/`contract v3` in the file. Issue #116 also asks
   for an exhaustive check of whether `scout`/`terse`'s own
   directive-emitting hooks share the gap.
3. `core/contract/role-handoff-contract.md` section 19 states what a
   non-canonical ("near-miss") approval-shaped comment does *not*
   authorize (it never opens phase 2), but not what a role session
   should *do* upon noticing one. The original requirement (carried
   over from issue-227) named the role session as the actor; the
   `on-the-record` landing assigned an analogous warn duty to its own
   orchestrator instead, leaving no counterpart in the one document
   that actually binds a role session here.

## Constraints

- `role-handoff-contract.md` section 22's own text (`:910-953`) is
  unchanged — this issue edits section 19, not section 22.
- `on-the-record`'s two-comment approval recipe (issue-227 landing) is
  unchanged; its repository's files are out of this write set entirely
  (different repo, unreachable from this branch beyond a `WebFetch`
  read — see survey.md).
- `freelunch/hooks/freelunch.sh`'s own subordination note (`:39`) and
  its unconditional dispatch text elsewhere in that file are unchanged
  — requirement 2 targets `warrant` only; `freelunch` already landed
  its fix in issue-106.
- No new environment variable or config flag is introduced for headless
  detection — the fix reads signals the `PreToolUse` subprocess already
  inherits from its session (confirmed in survey.md: `CLAUDECODE`,
  `CLAUDE_CODE_ENTRYPOINT`, and tty state are all already present in a
  hook's own environment).
- The write set does not widen beyond the six paths above.

## Rationale

**Requirement 1 — headless-scoped carve-out, not a blanket disable or a
message-only rewrite.** Considered and rejected: (a) removing the
`sync_agent_dispatch` check's deny entirely, for every session —
rejected because issue #116 explicitly asks that the enforcing hook's
original purpose (catching an orchestrator that dodges `freelunch`'s
fan-out discipline by blocking synchronously) "약해지지 않는 경계를
설계할 것" (design a boundary so it is not weakened); a blanket removal
would drop that protection for interactive sessions too, where §22
does not apply and the original problem is still real. (b) rewriting
only the deny's reason text to acknowledge §22 while still denying —
rejected because it does not resolve the actual contradiction: a
headless session would still be mechanically blocked from making the
one call shape §22 requires, which fails requirement 1's own stated
floor ("최소한 헤드리스 맥락에서 동기 위임을 거부하지 않을 것"). Chosen:
carve the deny out specifically when the hook's own inherited
environment/tty state indicates a headless/non-interactive invocation,
failing toward **not denying** when that signal is absent or
ambiguous — this satisfies requirement 1's floor unconditionally (a
misread signal never re-creates the §22 violation) while leaving the
check fully intact for the interactive case the original purpose was
written for. Scout's field check (scout-brief.md) confirms env/tty-based
non-interactive detection with a safe-fallback default is ordinary
practice, not a novel mechanism.

**Requirement 2 — a per-plugin subordination note, not a core-central
one.** Considered and rejected: have `core/hooks/directive.sh` carry
the subordination note once, centrally, instead of duplicating it into
each plugin's own `directive.sh`/`freelunch.sh` heredoc — rejected
because each plugin's directive text is an independently printed
`UserPromptSubmit` heredoc, not composed through `core`; a central-only
note would never appear inside `warrant`'s own printed directive block,
reproducing the exact "prose that isn't inside the block a session
actually reads doesn't reach the session" gap `docs/issue-106/reports/execution-observation.md:358-379`
(check point 4) already established for `role-handoff-contract.md`
itself. Chosen: copy `freelunch.sh:39`'s note verbatim in shape into
`warrant/hooks/directive.sh`, placed above its first unconditional
dispatch line (`:60`) exactly as the precedent does. `scout`/`terse`
are audited in survey.md and confirmed to carry no equivalent
unconditional "don't wait" language — no edit needed there, stated
here per the issue's own requirement to record the audit result.

**Requirement 3 — a role-session-side duty on this repo's contract,
not reliance on otr's orchestrator-side duty alone.** Considered and
rejected: do nothing on this repo's side, on the reasoning that
`on-the-record`'s orchestrator already carries a warn duty covering the
same event — rejected because a role session that reads the same
GitHub comments directly through its own `gh` calls (section 19's own
mechanism) can encounter and silently pass a near-miss comment without
`on-the-record` ever independently observing that specific read; the
two are not the same observation event, and relying solely on the
orchestrator reproduces the exact root cause the issue's `## 배경`
names (the duty landed on the actor that was *not* named). Chosen: add
the role-session-side duty to `role-handoff-contract.md` section 19,
mirrored into `core/hooks/directive.sh` per the same reachability
lesson used for requirement 2 — since no hook prints
`role-handoff-contract.md` itself, an obligation stated only there
would be as mechanically unreachable as `observe.sh`'s Finding 1 gap
was. This is complementary to, not a duplicate of, otr's own
orchestrator-side duty (different actor, different observation point);
no otr text needs to change.

## What will be done

1. **`freelunch/hooks/observe.sh`.** Read a headless/non-interactive
   signal from the hook's own process state (its inherited environment
   and/or tty presence) before evaluating the `sync_agent_dispatch`
   violation. When that signal indicates headless/non-interactive, or
   is absent/ambiguous, the violation is still logged (row still
   written, `"violations"` still lists `sync_agent_dispatch`, full
   audit trail preserved) but never contributes to `row["enforced"]`
   — i.e. `PreToolUse` never denies solely for this violation in that
   case. When the signal clearly indicates an interactive session, the
   existing deny behavior is unchanged. The `non_sonnet_worker` check
   and its deny are untouched by this change — they hold in every
   session type, headless or not. Update the deny reason text
   (`:101-107`) so it no longer asserts "which is semantically
   equivalent to waiting" as a universal claim.
2. **`freelunch/hooks/tests/run-observe-tests.sh`** (new). A behavioral
   test harness (matching this repo's `run-*-tests.sh` convention) that
   feeds `observe.sh` synthetic `PreToolUse` payloads and asserts: (a)
   `sync_agent_dispatch` + `FREELUNCH_ENFORCE=1` + a headless signal →
   allow; (b) `sync_agent_dispatch` + `FREELUNCH_ENFORCE=1` + no
   headless signal → deny (regression guard for the original,
   still-valid interactive-session behavior); (c) `non_sonnet_worker` +
   `FREELUNCH_ENFORCE=1`, either session type → deny, unchanged.
3. **`core/hooks/tests/run-all.sh`.** Add one line invoking the new
   test, in the existing "sibling plugin" section alongside the
   `freelunch` `parse-check.sh` line (`:34-35`).
4. **`warrant/hooks/directive.sh`.** Insert, immediately after the
   opening `<warrant-directive priority="high">` line and before the
   first unconditional dispatch instruction (`:60`), a subordination
   paragraph matching `freelunch/hooks/freelunch.sh:39`'s shape: names
   contract §22, states §22 takes priority over this directive's
   "dispatch and carry on without waiting" instructions whenever the
   role session is headless/single-shot.
5. **`core/hooks/directive.sh`.** Extend the existing "any other
   comment... is feedback" bullet (`:90-92`) with the role-session
   near-miss-reporting duty from item 6 below, mirrored verbatim in
   substance.
6. **`core/contract/role-handoff-contract.md`, section 19.** Extend the
   "Any other comment is feedback on the proposal" bullet (`:757-759`)
   with an explicit duty: when a role session's own approval check
   (this section's mechanism) surfaces a comment that is
   approval-shaped but fails the exact-string/account test — a
   near-match or an affirmative-sounding comment from a listed or
   unlisted account — the role session must, in addition to not
   treating it as approval, state that fact plainly once (not
   repeatedly) in its reply or its record, so the human learns of the
   near-miss from the session that actually observed it rather than
   depending solely on an external orchestrator noticing it
   separately. States explicitly that this is complementary to (not a
   replacement for) any warn duty a spawning orchestrator carries
   under its own rulebook.

## Out of scope

- `board-gate.sh`'s cross-repo path-substring matching (it denied a
  read-only `gh api` call against a *different* repository because the
  command text happened to contain a `docs/issue-<n>/` substring — see
  survey.md's "otr cross-reference" section) — a real defect surfaced
  during this research, unrelated to issue #116's three named items;
  left for the human to judge whether it warrants its own issue, not
  fixed here.
- `on-the-record`'s `run.md`/`protocol.md` — a different repository,
  out of scope per the issue's own constraint.
- The exact bash predicate/env-var name(s) used for the headless/tty
  signal in `observe.sh` — frozen here as behavior ("fail toward not
  denying when the signal is absent or ambiguous, keyed on the hook's
  own inherited environment/tty state"), not as literal syntax; the
  literal check is ordinary implementation detail settled during
  phase-2 build against that frozen behavior, and against Claude Code's
  own headless-mode documentation if reachable at build time.
- Restructuring or renumbering section 19's existing bullets beyond the
  one extension in item 6 above.
- `scout/hooks/directive.sh` and `terse/hooks/terse.sh` — audited in
  survey.md, confirmed to need no edit.

## How you'll know it worked

- `freelunch/hooks/tests/run-observe-tests.sh` passes its three cases
  (headless sync-dispatch allowed, interactive sync-dispatch still
  denied, non-sonnet-worker still denied regardless of session type).
- `bash core/hooks/tests/run-all.sh` passes end to end, including the
  newly wired test and the existing bash-3.2 `parse-check.sh` pass over
  the edited shell files (`observe.sh`, `warrant/hooks/directive.sh`).
- `rg -n "s22|contract v3" warrant/hooks/directive.sh` returns at least
  one match (currently zero).
- `rg -n "s22|contract v3" scout/hooks/directive.sh terse/hooks/terse.sh`
  continues to return zero matches, with the proposal's own text
  stating why (no gap found), so a future reader does not mistake the
  absence for an oversight.
- `core/contract/role-handoff-contract.md` section 19 and
  `core/hooks/directive.sh`'s printed heredoc both contain the new
  role-session near-miss-reporting text (grepped, both present — the
  mirror, not just the canonical copy).

## Warrant hunt (phase 1)

`subagent_type: warrant-hunter` is not among the agent types available
to this session (confirmed against this session's own agent-type
list). As in `docs/issue-106/reports/implementation.md:85-88`, this is
a disclosed substitution: the stance was adopted and applied by direct
inspection instead of a dispatched hunter. `.warrant-hunt.count` does
not exist in this working tree, so stance index `0 mod 5` applies:
"assume the gate just touched is bypassable — find the bypass." No
gate is touched yet (phase 1 is docs-only), so the stance is applied
forward, against this proposal's own design for requirement 1's
`observe.sh` carve-out, as a pre-mortem.

**Finding.** The fail-open-by-default design ("when the headless signal
is absent or ambiguous, do not deny") is itself a bypass vector for the
enforcement's *original* purpose if the signal it reads turns out to be
one an interactive orchestrator can cheaply spoof — e.g. a self-declared
environment variable the orchestrator's own conversation could
instruct itself to set would let any interactive session dodge
`sync_agent_dispatch` denial at will, defeating exactly the protection
requirement 1 says must not weaken.

**Disposition.** Already constrained by this proposal's own text, not
a new item: "What will be done" item 1 and the Constraints section both
already commit to reading only signals the `PreToolUse` subprocess
inherits from the *harness* (`CLAUDE_CODE_ENTRYPOINT`, tty state) —
set before the session's own conversation begins — never a new
self-declared flag. Recorded here as an explicit build-time constraint
for phase 2, not merely an implementation preference: whichever exact
signal phase 2 lands on must be harness-set, not conversation-writable,
or this finding re-opens.
