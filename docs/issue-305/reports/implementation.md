---
issue: 305
role: implementation
author: implementation
loop_state: landed
upstream:
  - path: docs/issue-301/reports/observability.md
    sha: 220c22e7907d591c49a1575fe44d45231783328f
code_under_review:
  - core/hooks/gh-guard.sh
  - core/hooks/approval-gate.sh
  - core/hooks/board-gate.sh
  - core/hooks/pretooluse-dispatcher.sh
  - core/hooks/facet-keyword-gate.sh
  - warrant/hooks/hunt-tier.sh
  - warrant/hooks/hunt-guard.sh
  - warrant/hooks/scope-gate.sh
  - warrant/hooks/state.sh
  - freelunch/hooks/observe.sh
  - terse/hooks/terse.sh
  - core/hooks/handbook-trigger-gate.sh
  - core/hooks/ordering-gate.sh
  - core/hooks/citation-gate.sh
  - core/hooks/pretooluse_dispatcher.py
type: fix
breaking: none
verdict: pass
---

# issue-305 — implementation record

## What was done

Worked issue-301's Findings table top-down, fixing every open finding not
already covered by the two sibling issues (#303: F15/F17 uXXXX-escape,
closed; #304: F19/F20 kill-switch fail-open, in review) — 19 findings
across 15 files, each fix keeping the existing fail-closed/fail-open
posture unchanged while adding the missing communication or closing the
silent-bypass path. 11 commits, one per finding or tightly related
finding cluster in the same file:

- **F9/F16/F18/F22** (the issue's named primary ask — python3-missing
  handled inconsistently): `gh-guard.sh`, `approval-gate.sh`,
  `board-gate.sh` now call `gate_deny "<gate>" "python3 not found; cannot
  evaluate gate"` instead of a bare `exit 2`; `pretooluse-dispatcher.sh`
  (deliberately gate-lib-free, "must never grow logic") gets an inline
  echo+exit with the same message shape. `facet-keyword-gate.sh`'s
  bash-level python3 check used `gate_deny` (hard exit 2) despite the
  file's own Python-level `deny()` being advisory-only (issue-282
  DEMOTE) — demoted to match, emitting the same
  stderr+hookSpecificOutput+exit-0 shape.
- **F1**: `hunt-tier.sh` distinguishes a real `git diff` failure (bad
  ref, exit 128) from a genuinely empty diff — both previously reported
  `reason=empty-diff`.
- **F2/F3**: `hunt-guard.sh` — malformed/non-dict JSON that raw-text
  mentions an Agent/Task/Workflow tool_name now refuses instead of
  silently allowing (closes the session-cap bypass); a corrupted (non-
  integer) hunt-count file now refuses loudly instead of silently
  resetting the cap to full budget, mirroring the lock-corruption
  handling a few lines above.
- **F4**: `scope-gate.sh`'s documented fail-open on missing python3 now
  prints a message before exiting 0 (was zero bytes on either stream).
- **F5**: `state.sh` reports a proposal with an opening `---` fence and
  no closing fence under a new "malformed" section instead of silently
  dropping it (byte-identical to "not a proposal file at all").
- **F6**: `observe.sh` appends an anomaly log row on unparseable payload
  instead of leaving the audit trail with no row at all.
- **F7**: `terse.sh`'s I/O failure reading `terse.level` (e.g. permission
  denied) now appends a NOTE inside the emitted directive text itself,
  same channel the unrecognized-value case already uses.
- **F8**: `facet-keyword-gate.sh`'s malformed-JSON config (file exists,
  broken by a bad edit) is now distinguished from missing/unreadable
  (OSError, stays silent by documented design) and goes through the
  file's own advisory `deny()`.
- **F10**: `handbook-trigger-gate.sh` passes `-A`/`--all`/`-u`/`--update`
  through to the `git add --dry-run` projection instead of dropping them
  as ordinary ignored option flags — `git add -A && git commit` now
  contributes to the projected staged set.
- **F11**: `ordering-gate.sh` fails closed on a non-dict `tool_input` or
  non-string `file_path` for Write/Edit/MultiEdit instead of silently
  falling through every mechanism to the unconditional final allow.
- **F12**: `ordering-gate.sh`'s `update_status` declines to write back at
  all on a corrupt/unreadable `.status.json` instead of resetting the
  entire multi-issue document to `{}` and erasing every other tracked
  issue's history.
- **F13**: the same write-back warning is now also emitted via
  `hookSpecificOutput.additionalContext` (visible regardless of exit
  code), not stderr-only on the invisible allow path.
- **F14**: `citation-gate.sh` no longer disarms `gate_trap_fail_closed`
  before its final `exit "$PY_EXIT"` — a config-authoring crash (e.g. a
  bad regex, Python exit 1) now remaps to exit 2 instead of exiting 1
  (non-blocking per Claude Code's own convention).
- **F21**: `pretooluse_dispatcher.py` merges every DEMOTE gate's
  `additionalContext`/`systemMessage` into one combined stdout JSON
  payload instead of forwarding only the first chunk and shoving every
  other gate's finding (including its raw JSON) into stderr.
- **F23**: the same file's `OTR_DISPATCH_ONLY` test-harness seam now
  refuses (exit 2, naming the bad value and the registered gate list) on
  a name that matches no gate, instead of falling through to the same
  `return 0` a genuine "ran and found nothing" result uses.

## Why

The issue asks to work the record's Findings table top-down; the batch
grouping issue-301 itself proposed (kill-switch → #304, uXXXX-escape →
#303, python3-missing → this issue's named ask, "the remaining 14 [sic,
actually 15] findings... each single-mechanism and independent") is the
resolution path this record follows. Every fix keeps the pre-existing
fail-open/fail-closed *decision* for that mechanism unchanged (e.g.
`scope-gate.sh` and `citation-gate.sh`'s missing-config-file path stay
intentionally silent by their own documented design) — only the
*communication* around that decision, or a demonstrated silent-bypass
path, changed. No mechanism was flipped from advisory to blocking or
vice versa except where the finding itself demonstrated the current
demotion/blocking state was already inconsistent within the same file
(F9).

## What did not work

None — every attempted fix landed. One test-suite assertion
(`run-dispatcher-equivalence-tests.sh`'s dispatcher end-to-end latency
<100ms check) was flaky under this host's load during F21/F23
verification; traced to host contention rather than the code change (see
Open findings) and did not block landing.

## Upstream basis

- `docs/issue-301/reports/observability.md` (commit
  `220c22e7907d591c49a1575fe44d45231783328f`) — the 23-finding inventory
  this issue works, specifically the 19 findings not covered by #303
  (F15/F17) or #304 (F19/F20): F1-F14, F16, F18, F21, F22, F23.
- Issue #305 body (acceptance: `core/hooks/tests/run-gate-shape-tests.sh`
  byte-identical with python3 present; executed-live PATH-without-python3
  evidence per affected gate).

## Open findings

None from this issue's own scope — all 19 target findings are fixed and
verified live. One pre-existing, unrelated item observed during
verification, left open rather than fixed here (out of this issue's
scope):

- `run-dispatcher-equivalence-tests.sh`'s dispatcher-latency assertion
  (<100ms average) is flaky on this host under contention (load average
  observed 100-180 during this session, 90-day-uptime shared machine).
  Confirmed environmental, not a regression from this issue's changes,
  via a stashed/unstashed A/B on unmodified HEAD showing the identical
  escalating-latency pattern (278ms → 482ms → 825ms across 3 consecutive
  runs with zero code changes applied). No action taken; a future issue
  could make the assertion load-aware (e.g. a relative threshold against
  a baseline measured in the same run) if this proves recurring.
- Two pre-existing `approval-gate.sh` test failures
  (`checkpoint-refusal-names-await-approval`, `execute-without-remote`)
  confirmed unrelated to this issue's changes (present identically on
  unmodified HEAD via `git stash`) — environment-dependent (no git
  remote / no `approvers.md` in this sandbox), not addressed here.

## Next steps

None — loop_state: landed.

## Acceptance evidence

`run-gate-shape-tests.sh`, python3 present (empty state — byte-identical
to baseline, all 18 pass):

```
$ bash core/hooks/tests/run-gate-shape-tests.sh
ok     gh-guard-unescaped-merge-denies            deny
ok     gh-guard-escaped-merge-still-denies-F15    deny
ok     gh-guard-irrelevant-payload-fast-skips     allow
ok     gh-guard-irrelevant-payload-never-reaches-python3 not-invoked
ok     approval-gate-unescaped-src-write-denies   deny
ok     approval-gate-escaped-src-write-still-denies-F17 deny
ok     approval-gate-escaped-src-bash-write-still-denies-F17 deny
ok     approval-gate-irrelevant-payload-fast-skips allow
ok     approval-gate-irrelevant-payload-never-reaches-python3 not-invoked
ok     board-gate-unescaped-badbucket-denies      deny
ok     board-gate-escaped-badbucket-still-denies  deny
ok     board-gate-irrelevant-payload-fast-skips   allow
ok     board-gate-irrelevant-payload-never-reaches-python3 not-invoked
ok     ordering-gate-no-bash-fast-path            absent
ok     dispatcher-gh-guard-escaped-merge-denies-F15 deny
ok     dispatcher-approval-gate-escaped-src-denies-F17 deny
ok     dispatcher-board-gate-escaped-badbucket-denies deny
ok     dispatcher-irrelevant-payload-allows-full-chain allow

== 18 passed, 0 failed ==
```

Executed-live, PATH stripped of python3, one command per affected gate
(named message + fail-closed exit 2 preserved for the 4 hard gates;
facet-keyword-gate's advisory demote correctly stays exit 0 +
hookSpecificOutput, matching the file's own design):

```
$ NOPY=/tmp/nopy-bin; # NOPY/bin holds symlinks to every /usr/bin executable except python3*
$ env PATH="$NEWPATH" bash -c 'command -v python3; echo rc=$?'
rc=1

=== gh-guard.sh (F16) ===
gh-guard: refused — python3 not found; cannot evaluate gate
exit=2
=== approval-gate.sh (F18a) ===
approval-gate: refused — python3 not found; cannot evaluate gate
exit=2
=== board-gate.sh (F18b) ===
board-gate: refused — python3 not found; cannot evaluate gate
exit=2
=== pretooluse-dispatcher.sh (F22) ===
pretooluse-dispatcher.sh: refused — python3 not found; cannot evaluate gate
exit=2
=== facet-keyword-gate.sh (F9) ===
facet-keyword-gate: python3 not found; cannot evaluate gate
{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"facet-keyword-gate: python3 not found; cannot evaluate gate"},"systemMessage":"facet-keyword-gate: python3 not found; cannot evaluate gate"}
exit=0
```

Per-finding live-fire evidence for F1-F8, F10-F14, F21, F23 is recorded
in each finding's own commit message (`git log --oneline` on this
branch); every commit reproduces the pre-fix silent/inconsistent
behavior, the post-fix behavior, and the relevant existing test suite
re-run showing no regression:

```
$ git log --oneline origin/main..HEAD
9e0758a issue-305: merge every DEMOTE gate's finding into one stdout payload instead of dropping all but the first; fail loudly on a typo'd OTR_DISPATCH_ONLY (F21/F23)
41904e4 issue-305: keep the fail-closed EXIT trap armed through the final exit so a Python crash remaps to deny (F14)
d4fe7b2 issue-305: fail closed on malformed Write/Edit/MultiEdit schema; stop nuking cross-issue status history on corruption; surface the warning on the allow path (F11/F12/F13)
2429060 issue-305: project git add -A/--all/-u/--update into the staged-set projection instead of dropping them (F10)
11a6bea issue-305: name malformed facet-keyword-config JSON instead of silently disabling the gate (F8)
66b5a50 issue-305: surface terse.level I/O read failures in the directive text itself (F7)
f2e6ff1 issue-305: log an anomaly row for unparseable observe.sh payloads instead of leaving the audit trail silent (F6)
81d93d9 issue-305: surface malformed-frontmatter proposals instead of silently dropping them (F5)
13f0d62 issue-305: name the missing-python3 fail-open in scope-gate.sh (F4)
a824407 issue-305: distinguish real git-diff failure from empty diff (F1); close malformed-JSON session-cap bypass and corrupted-count-file silent reset (F2/F3)
7092f40 issue-305: name the python3-missing failure in 4 core gates + demote facet-keyword's bash-level check to parity (F9/F16/F18/F22)
```

Full regression sweep (`core/hooks/tests/run-all.sh`) after all 11
commits: every suite unchanged except the two pre-existing/unrelated
items in Open findings above.

## Skill verdicts

skill-verdict: implementation-performance-data-structure-choice —
applied: invoked; evaluated the F21 fix (a loop over
`stdout_chunks`, bounded by `len(GATES) == 12`, calling `json.loads` on
each small JSON blob before one final merge). No rule fired: not a
membership-test-in-a-loop (rule 1), memory-constrained lookup (rule 2),
asymptotic-class comparison (rule 3), per-message-connection scheme
(rule 4), or cache/index removal decision (rule 5/6) — bounded-constant
work on already-small payloads in a repo that already regression-tests
this dispatcher's latency, matching the skill's own rule-1
counter-example (fixed small n, no conversion needed).
skill-verdict: work-in-english — applied: invoked; confirmed the
policy (commits/code/PR/record in English, final chat summary in
Korean) matches what this session was already doing throughout —
no change to output language as a result.
skill-verdict: implementation-complexity-coupling-management —
not-applicable: no coupling/cohesion metric, accessor chain, or
cross-module import direction decision in this task (each fix is a
narrow, existing-pattern-following bugfix inside one file)
skill-verdict: implementation-design-pattern-selection — not-applicable:
no GoF-style pattern introduced or removed
skill-verdict: implementation-blueprint — not-applicable: no new
multi-module structure decided and no fan-out to parallel workers (this
session's own freelunch tally selected solo execution — 19 small,
independent, existing-pattern fixes, none reaching the ~100-line-per-unit
fan-out floor)
