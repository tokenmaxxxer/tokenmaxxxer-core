---
kind: current-state-survey
subject: issue-116
produced_by: implementation
---

# Current-state survey — issue-116

Issue #116 bundles three step-2-observation follow-ups (`docs/issue-106/reports/execution-observation.md`
Findings 1-2, `on-the-record` issue-227 execution-observation Finding 1,
read remotely — see "otr cross-reference" below) into one repo-owned
fix set. All three targets are read below at their current on-branch
state (`issue-116/implementation`, which is `git`-identical to `main` as
of this session — `git status` clean, branch up to date with
`origin/main`).

## Write set (projected)

- `freelunch/hooks/observe.sh` — the enforcing half of requirement 1;
  needs a headless-scoped carve-out on the `sync_agent_dispatch` deny.
- `freelunch/hooks/tests/` (new file) — no behavioral test of
  `observe.sh`'s enforcement logic exists today (see "Test surface"
  below); the carve-out needs one so a future edit can't silently
  regress it.
- `core/hooks/tests/run-all.sh` — wires the new test into the one
  existing "every check in one command" entry point.
- `warrant/hooks/directive.sh` — requirement 2's direct target; needs
  the same subordination note `freelunch/hooks/freelunch.sh:39` already
  carries.
- `core/hooks/directive.sh` — requirement 3's mirror target (see
  "Why the mirror is load-bearing" below).
- `core/contract/role-handoff-contract.md` — requirement 3's canonical
  target, section 19.

## Requirement 1 — `freelunch/hooks/observe.sh` vs contract §22

Read in full this session at the current branch tip (unchanged since
`f4b158f`, the merge `docs/issue-106/reports/execution-observation.md`
already pinned its citations to).

- `observe.sh:38` reads `FREELUNCH_ENFORCE` from the environment;
  `:45-46` returns early for any `tool_name` other than
  `Agent`/`Task`/`Workflow`.
- `:63-64`: `if bg is False: row["violations"].append("sync_agent_dispatch")`
  — flags every `run_in_background: false` dispatch, unconditionally,
  regardless of session type.
- `:83`: `row["enforced"] = bool(enforce and row["violations"])`.
- `:101-107`: the `sync_agent_dispatch` reason string asserts
  "Re-issue the SAME Agent call with run_in_background: true; you will
  be notified on completion, which is semantically equivalent to
  waiting."
- `:117-127`: when `enforced`, the hook returns
  `"permissionDecision": "deny"` with that reason — this is a real
  `PreToolUse` block, not advisory logging.
- No occurrence of `headless`, `s22`, `contract`, or `tty` anywhere in
  the file (`grep -c` confirms 0 for all four).

Contract §22 (`core/contract/role-handoff-contract.md:910-953`) states
the opposite premise at `:917-924`: in a headless/single-shot session
there is no later turn for a completion notification to land in, so
"you will be notified on completion" is not "semantically equivalent to
waiting" — it is data loss. `:926-931` states the rule's fallback
explicitly: if a same-turn wait is not possible, do not delegate the
unit at all; work it in the foreground. `run_in_background: false` is
the only mechanism that makes a same-turn wait possible for an `Agent`
dispatch (confirmed against the `Agent` tool's own description in this
session's tool list: `run_in_background: false` is documented as "run
in the foreground when you need its results before you can proceed").
So under `FREELUNCH_ENFORCE=1`, a headless session obeying §22 is
mechanically denied the one call shape §22 requires it to make.

**Operating evidence this is latent, not yet triggered in practice:**
`docs/issue-106/reports/execution-observation.md:289-296` reports all
134 rows in `~/.claude/freelunch-observe.jsonl` (as read in that
session) carry `"enforced": false` — no deny has fired to date because
`FREELUNCH_ENFORCE` has apparently never been set to `1` in an observed
run. That does not make the contradiction inert: the deny logic itself
is unconditional on session type, so any future run with the flag set
would hit it on the first §22-compliant dispatch.

**Headless-detection signal, and its limit.** `PreToolUse` hooks run as
subprocesses of the invoking session and inherit its environment —
confirmed empirically this session: `env` inside this session's own
`Bash` tool shows `CLAUDECODE=1`, `CLAUDE_CODE_ENTRYPOINT=sdk-cli`, and
`tty` reports "not a tty", consistent with this session's own known
headless/single-shot status (stated in this session's invocation
prompt). This means `observe.sh` *can* read the same signals. **Unknown
(not resolved this session):** whether `CLAUDE_CODE_ENTRYPOINT=sdk-cli`
or "no controlling tty" reliably distinguishes headless from
interactive sessions in general, since no interactive-session sample
was available in this sandbox to diff against — only this one
known-headless sample was inspected. A brief external check (see
scout-brief.md) confirms env/tty-based non-interactive-mode detection
is the standard pattern industry-wide, which supports the *mechanism*,
but the exact predicate still needs phase-2 verification (e.g. against
Claude Code's own headless-mode documentation) before being relied on
as the sole gate.

## Requirement 2 — `warrant/hooks/directive.sh` and sibling directive-emitting plugins

This repo has exactly five plugin directories:
`core`, `freelunch`, `scout`, `terse`, `warrant` (confirmed:
`find . -maxdepth 2 -iname hooks` plus a directory listing turned up no
sixth). Of these, four print an injected directive via a
`UserPromptSubmit` hook; `core`'s is the contract mirror (see
requirement 3 below), not an independent directive-emitting plugin.

- **`warrant/hooks/directive.sh`** (full file read this session) —
  `:60`: "dispatch ONE background agent — `subagent_type:
  warrant-hunter`, `model: sonnet`, `run_in_background: true` — and
  carry on without waiting for it." `:79`: "Never wait on it, never
  interrupt work for it, never dispatch a second while one is
  running." Zero occurrences of `s22` or `contract v3` in the file
  (`grep -c` = 0 for both). This is the same unconditional shape
  `freelunch/hooks/freelunch.sh` carried before `ce4e81c` added its
  subordination note — confirmed already by
  `docs/issue-106/reports/execution-observation.md:298-303` and
  self-reported by the observed role at
  `docs/issue-106/reports/implementation.md:111-165` (not re-litigated
  here, only independently re-confirmed at the current SHA).
- **`freelunch/hooks/freelunch.sh:39`** — the precedent pattern to
  reuse verbatim in shape: one paragraph, placed inside the same
  `cat <<'EOF'` heredoc, *above* the first unconditional
  delegation-mandating line (`:48`), naming contract §22 and stating it
  takes priority.
- **`scout/hooks/directive.sh`** (full file read this session) — its
  only `Agent`-dispatch language is at `:44`, "Run several such angles
  concurrently in one turn... as parallel subagents (Agent tool, one
  message with multiple calls)." This does not mandate
  `run_in_background: true`, does not say "don't wait," and the
  results of that dispatch are consumed synchronously later in the same
  stage (fed into "JUDGE POINT 1"). No occurrence of "wait" as a
  don't-wait instruction anywhere in the file. **No gap: this file does
  not conflict with §22 and needs no subordination note.**
- **`terse/hooks/terse.sh`** (full file read this session) — governs
  conversational output compression only; contains no `Agent`/`Task`
  dispatch language of any kind. **No gap, not applicable.**

This matches the root-cause note already on record at
`docs/issue-106/reports/execution-observation.md:424-430`: the prior
session's own before-landing hunt already swept exactly these three
sibling files under the stance "assume this change and another
plugin's rule cancel each other" and it is independently re-confirmed
here that only `warrant/hooks/directive.sh` actually cancels.

## Requirement 3 — role-session obligation on non-canonical approval comments

**This repo's existing text (what already covers "not approval").**
`core/contract/role-handoff-contract.md:757-759` (section 19): "Any
other comment is feedback on the proposal — revise and push to the
same PR. A close is refusal. Nothing else — no free-text comment, no
reaction, no bot Approve — opens phase 2." Mirrored into every live
session via `core/hooks/directive.sh:90-92`: "any other comment,
including a near-match or an affirmative-sounding one, is feedback,
not approval (revise on the same branch, push to the same PR)." Both
say what a near-miss comment does *not* do (it does not open phase 2).
**Neither says what the role session must actively do when it
encounters one** — no instruction to surface it, flag it, or record it
for the human; a session that silently treats it as "just feedback" and
continues waiting is textually compliant with the current wording.

**Why the mirror is load-bearing (lesson already on record).**
`docs/issue-106/reports/execution-observation.md:358-379` (check point
4) established, for the §22 addition, that contract prose alone never
reaches a running role session — no hook prints
`role-handoff-contract.md`; only `core/hooks/directive.sh`'s
`SessionStart` heredoc does, and it verified that empirically across
nine post-merge session logs. Any new role-session obligation added to
the contract this issue lands needs the same mirror treatment in
`core/hooks/directive.sh` or it inherits the exact "mechanically
unreachable" gap Finding 1 identified for `observe.sh` — a documented
rule nothing ever delivers to a session. This is why
`core/hooks/directive.sh` is in the projected write set for requirement
3, not just `role-handoff-contract.md`.

**otr cross-reference (out of scope to edit, in scope to read for
consistency — issue's own constraint).** No local checkout of
`on-the-record` exists in this environment
(`find /Users/jk -iname "*otr*"` → empty), and this repo's
`board-gate.sh` `PreToolUse` hook denies any Bash command whose text
contains a `docs/issue-<n>/` substring matching the *current* branch's
issue number pattern — confirmed this session: `gh api
repos/tokenmaxxxer/on-the-record/contents/docs/issue-227/...` was
denied by `board-gate.sh` even though it targets a different repository
and is a read, because the hook's string match does not distinguish
repo or read/write (a separate, unrelated defect in `board-gate.sh`,
out of this issue's scope, not investigated further). Read instead via
`WebFetch` against `on-the-record`'s raw GitHub content (a different
tool than `Bash`, not subject to that hook), which returns a
summarized/paraphrased read rather than a verbatim byte read of the
source file — **flagged here as lower-confidence than the contract and
hook reads above, all of which are verbatim.** That summary states:
`on-the-record`'s `run.md:209-215` places the warn duty inside its
step 6 ("사용자의 결정을 중계한다" — relay the user's decision), which is
its own orchestrator's obligation, not a role session's; and that
`on-the-record`'s own `protocol.md` §5 (the document role sessions
there receive at start) currently contains no near-miss handling text
either. This is consistent with the issue body's own framing: the
original requirement named "역할 세션" (role session) as the actor, the
otr-side landing assigned the duty to the orchestrator instead, and
this repo's `role-handoff-contract.md` is the one document that
actually binds a role session (this repo has no separate
"orchestrator" layer of its own — `on-the-record` fills that role
externally, spawning sessions like this one into target repos such as
this one). Adding the role-session-side duty here does not need to
change otr's `run.md` wording (unreachable and out of scope per the
issue's own constraint) — it is a complementary, not competing,
obligation: otr's orchestrator watches from outside; this addition
makes the role session itself, which sees the same GitHub comments
directly through its own `gh` calls under section 19, no longer silent
about a near-miss it personally observes.

## Test surface (current state)

- `freelunch/hooks/tests/` contains only `parse-check.sh` (bash 3.2
  syntax check, no behavioral assertions). No test exercises
  `observe.sh`'s `sync_agent_dispatch`/`non_sonnet_worker` logic today.
- `warrant/hooks/tests/` does not exist as a directory at all.
- `core/hooks/tests/run-all.sh` runs `freelunch/hooks/tests/parse-check.sh`
  as a "sibling plugin" step (`:34-35`) but has no equivalent line for
  any freelunch behavioral test, since none exists yet.
- `core/hooks/tests/compliance-check.sh` and `canon-forms.txt`/
  `canon-manifest.txt` govern the *shape* of a rulebook's own
  `directive.sh` (its call into `core_role_directive`), not the prose
  content of `warrant`/`scout`/`terse`'s independent heredoc-based
  directive files — confirmed by reading `compliance-check.sh` in full
  and `canon-forms.txt`'s header comment. Editing
  `warrant/hooks/directive.sh`'s prose does not touch anything these
  scripts check.
- Precedent: `core/contract/role-handoff-contract.md` §22 and its
  `core/hooks/directive.sh` mirror landed with no dedicated content
  test (`docs/issue-106/reports/execution-observation.md:381-390`,
  explicitly noted as a stated property, not a defect, since no
  requirement asked for one). The same reasoning applies to
  requirement 2's and requirement 3's prose-only edits in this issue.

## Unknowns

- Whether `CLAUDE_CODE_ENTRYPOINT=sdk-cli` (or tty absence) reliably
  distinguishes headless from interactive Claude Code sessions in
  general — only one known-headless sample was inspected this session;
  no interactive-session sample was available to diff against. The
  proposal's design compensates by choosing a fail-toward-not-denying
  default when the signal is absent or ambiguous, rather than resolving
  the predicate to certainty in phase 1.
- `on-the-record`'s exact `run.md:209-215` and `protocol.md` §5 text —
  read only as a `WebFetch` summary, not verbatim (see "otr
  cross-reference" above). Sufficient for this issue's own
  constraint ("otr 레포 파일은 범위 밖... 후속 기록으로"), which asks only
  that a cross-reference not contradict, not that it be pixel-verified.
