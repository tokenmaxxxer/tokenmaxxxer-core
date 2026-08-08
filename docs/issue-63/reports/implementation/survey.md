---
subject: issue-63
role: implementation
---

# Current-state survey — issue-63 remaining Acceptance gaps

(Supersedes the pre-canon-promotion survey that lived at this path: PR
#65 already delivered the canon promotion and cadence-directive text
this file originally scoped. What follows surveys what is left.)

Scout skip note: this is internal gate-hook infrastructure with no
external product category to benchmark against. The comparable-system
pass scout-directive asks for is this repo's own existing gate designs
(scope-gate.sh, hunt-guard.sh, gate-lib.sh), surveyed below in place of
a web sweep.

## What issue-63's Acceptance still requires

PR #65 (merged 2026-07-31) added `warrant/` as a canon plugin dir and
wrote the proportional-cadence rules as **directive text** in
`warrant/hooks/directive.sh`. Two Acceptance checks are mechanical and
neither currently passes:

1. **Canon-duplication scan must cover the warrant-hunt files.**
   `core/hooks/tests/compliance-check.sh --canon-duplication <path>`
   (built by #66, merged since PR #65) reads its file list from
   `core/hooks/tests/canon-manifest.txt`. That manifest today lists only
   the eight original core-canon files (trailer-gate.sh ...
   compliance-check.sh) — none of `warrant/hooks/{directive.sh,
   hunt-guard.sh,hunt-state.sh,scope-gate.sh,state.sh}` or
   `warrant/agents/warrant-hunter.md`. A vendored copy of any warrant
   file in a rulebook would not be caught by the scan today. Confirmed
   by grep: zero "warrant" hits in canon-manifest.txt.
2. **No mechanical budget-bound test exists.** `core/hooks/tests/
   run-gate-lib-tests.sh` (368 lines) has no case for the wall-clock cap.
   `gate-lib.sh` (95 lines) exposes `gate_trap_fail_closed`,
   `gate_kill_switch_active`, `gate_deny`, `gate_allow`,
   `gate_bash_write_targets` — no time/deadline helper. The 60/120/180s
   tiers exist only as directive prose; nothing refuses or truncates a
   hunter that overruns its cap.

## Current mechanical enforcement in warrant/ (precedent to extend)

- `hunt-guard.sh` (PreToolUse on Agent/Task/Workflow): single-flight
  lock file `.warrant-hunt.lock` (format `"<started_epoch>
  <prompt-head>"`), session dispatch cap `.warrant-hunt.count`,
  no-nesting refusal via `WARRANT_IN_HUNT=1`. A stale lock (>300s,
  `STALE_SECONDS`) is reported, not killed — the file states outright
  that a hook cannot terminate a running agent.
- `scope-gate.sh` (PreToolUse on Write/Edit/NotebookEdit/Bash): reads a
  proposal's frontmatter `files:` list, refuses writes outside it,
  fails open on ambiguity (0 or >1 approved proposals, missing python3,
  unreadable payload).
- Both source `gate-lib.sh` via `CLAUDE_PLUGIN_ROOT_CORE`, call
  `gate_trap_fail_closed`, honor `WARRANT_OFF=1`. A new budget check
  should follow the same shape: a `gate_*` helper added to
  `gate-lib.sh`, invoked from `hunt-guard.sh`, fail-open on ambiguous
  input, same kill switch — consistent with both existing gates.

## The write set this implies

- `core/hooks/tests/canon-manifest.txt` — append the six warrant
  filenames.
- `core/hooks/lib/gate-lib.sh` — add one small elapsed-vs-cap helper.
  A hunter's own tool calls are the only thing a hook can gate — per
  `hunt-guard.sh`'s own comment, nothing here can kill a running agent.
- `warrant/hooks/hunt-guard.sh` — store the cap alongside the existing
  lock timestamp at dispatch, and refuse (loudly, exit 2) a hunter's
  own further tool calls once elapsed exceeds that cap.
- `core/hooks/tests/run-gate-lib-tests.sh` — one red case (elapsed >
  cap -> refuse) and one green case (elapsed <= cap -> proceed), the
  literal wording of the issue's Acceptance check.

## Alternatives considered

- **Enforce the budget only in `warrant-hunter.md`'s prompt text**
  (self-reported elapsed time, no hook). Rejected: issue-63 items 1/3
  exist specifically to move hunt cadence off prompt-only discipline
  onto scout's mechanical footing; a prompt-only cap is what already
  exists today, unenforced, and is what the owner's complaint names.
- **Kill the hunter process on overrun** (e.g. a monitoring loop calling
  TaskStop). Rejected: no hook in this system can terminate a running
  subagent — `hunt-guard.sh`'s own stale-lock handling admits this. The
  only enforceable point is the hunter's *next* tool call, so
  "refuses/loudly truncates" is read as gating that next call — the
  issue's own wording treats the two as one mechanism, not two.
