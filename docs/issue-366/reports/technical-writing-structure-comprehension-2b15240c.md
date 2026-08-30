---
issue: 366
role: technical-writing-structure-comprehension-2b15240c
author: technical-writing-structure-comprehension-2b15240c
skills: technical-writing-structure-comprehension (skill-repository(c05de12))
verifies_subject: false  # flip to true only if this record is an independent verification of this subject's own deliverable -- see docs/handbooks/observer-verification.md
loop_state: landed
upstream:
  - path: core/hooks/board-gate.sh
    sha: same-commit
  - path: core/hooks/approval-gate.sh
    sha: same-commit
  - path: core/hooks/gh-guard.sh
    sha: same-commit
  - path: core/hooks/ordering-gate.sh
    sha: same-commit
  - path: core/hooks/record-fields-gate.sh
    sha: same-commit
---

# issue-366 — technical-writing-structure-comprehension-2b15240c record

## What was done

Replaced the retired noun `role` with `skill` in every gate-emitted denial
message that a live session actually reads, across `core/hooks` and
`warrant/hooks`. 13 message sites were rewritten across five files:
`core/hooks/board-gate.sh` (6 sites), `core/hooks/approval-gate.sh` (4
sites — two of them the paired `state_reason`/no-`state_reason` branches
of the same closed-issue denial), `core/hooks/gh-guard.sh` (1 site),
`core/hooks/ordering-gate.sh` (1 site), and
`core/hooks/record-fields-gate.sh` (1 site). Two `role`-containing call
sites were found and deliberately left unchanged (see Rationale below).
`warrant/hooks` returned zero message sites carrying the retired noun.

Population search, defined once and reused for the before/after count and
the final re-check:

```
derived: python3 /tmp/sweep_366.py
# scans core/hooks and warrant/hooks (*.py, *.sh) for any deny(...) /
# sys.stderr.write(...) / sys.stdout.write(...) / print(...) call whose
# full parenthesized argument text contains the whole word "role"
# (case-insensitive); this is the operational definition of "a string a
# session can see" — the four call shapes every PreToolUse/PostToolUse
# hook in this codebase uses to put text in front of a live session.
```

Before (HEAD 8c7cc8d, i.e. `git show HEAD:core/hooks/board-gate.sh`
etc.), the same search returned 14 hits, all in `core/hooks`, none in
`warrant/hooks` (explicit zero):

```
('core/hooks/approval-gate.sh', 213, 'deny')
('core/hooks/approval-gate.sh', 241, 'deny')
('core/hooks/approval-gate.sh', 345, 'deny')
('core/hooks/approval-gate.sh', 350, 'deny')
('core/hooks/board-gate.sh', 845, 'deny')
('core/hooks/board-gate.sh', 922, 'deny')
('core/hooks/board-gate.sh', 954, 'deny')
('core/hooks/board-gate.sh', 973, 'sys.stderr.write')
('core/hooks/board-gate.sh', 989, 'deny')
('core/hooks/board-gate.sh', 1046, 'deny')
('core/hooks/board-gate.sh', 1173, 'deny')
('core/hooks/gh-guard.sh', 148, 'deny')
('core/hooks/ordering-gate.sh', 523, 'deny')
('core/hooks/record-fields-gate.sh', 481, 'deny')
TOTAL: 14
```

After the edits, the same search returns 2 (both deliberately excluded,
not missed — see Rationale):

```
('core/hooks/board-gate.sh', 973, 'sys.stderr.write')
('core/hooks/board-gate.sh', 989, 'deny')
TOTAL: 2
```

14 → 2 is the count-goes-down invariant for the retired role-axis
vocabulary in message strings; the 2 survivors are `role` as a literal
filename fragment (`.on-the-record/role.json`, a real file this issue
does not rename) and one explanatory historical-rename sentence, not the
operative vocabulary.

A direct grep for bare bash `echo`/`printf` writers (outside the embedded
python judges) confirmed no additional emission mechanism exists in the
top-level gate scripts themselves:

```
derived: for f in core/hooks/*.sh warrant/hooks/*.sh; do grep -nE "\b(echo|printf)\b.*\brole\b" "$f"; done
# 0 lines matched in any file — only core/hooks/tests/*.sh (test-runner
# output, never seen by a live session) mention "role" via echo/printf,
# which is why the population search above only walks deny()/stderr/
# stdout/print call sites, not every echo in the tree.
```

Live before/after trigger, at the real subprocess level, using the
board-gate un-analyzable-write-shape denial the issue itself cites
(the message that used to read `board-gate.sh:747`; it now lives at line
846 after unrelated line drift since the issue was filed — confirmed via
`grep -n "write-set" core/hooks/board-gate.sh`). Reproduced exactly the
way `core/hooks/tests/run-board-gate-tests.sh` itself drives the gate —
"board-gate.sh, exercised as a real subprocess against real payloads" —
by piping a synthetic PreToolUse JSON payload into the script with
`CLAUDE_SKILL=qa CLAUDE_PROJECT_DIR=<board> CLAUDE_PLUGIN_ROOT=<repo>
/bin/bash core/hooks/board-gate.sh`, once against `git show
HEAD:core/hooks/board-gate.sh` (before) and once against the edited
working-tree file (after):

```
acceptance: bash /tmp/gatecheck/run_against.sh /tmp/gatecheck/board-gate-before.sh — result:
board-gate: a Bash call carries an un-analyzable write-capable shape (python3 - <<'EOF') while this gate enforces role 'qa''s write-set. A heredoc body, an interpreter -c/-e inline script, or a dd invocation does not show its real write target in the command text, so this refuses rather than risk a masked out-of-set write (issue-225 — the on-the-record PR #1627 bypass). Use a provably read-only invocation (e.g. python3 -m pytest), or write through Write/Edit or a plain redirect this gate can read the target of. This is a write-set discipline check, not a security boundary (issue-233 round 5): it denies only shapes it cannot read the write target of, and does not claim to catch a shape deliberately built to hide that target from this text-level read.
exit=2

acceptance: bash /tmp/gatecheck/run_against.sh core/hooks/board-gate.sh — result:
board-gate: a Bash call carries an un-analyzable write-capable shape (python3 - <<'EOF') while this gate enforces skill 'qa''s write-set. A heredoc body, an interpreter -c/-e inline script, or a dd invocation does not show its real write target in the command text, so this refuses rather than risk a masked out-of-set write (issue-225 — the on-the-record PR #1627 bypass). Use a provably read-only invocation (e.g. python3 -m pytest), or write through Write/Edit or a plain redirect this gate can read the target of. This is a write-set discipline check, not a security boundary (issue-233 round 5): it denies only shapes it cannot read the write target of, and does not claim to catch a shape deliberately built to hide that target from this text-level read.
exit=2
```

Both runs deny with `exit=2` — the slot still holds the skill value
(`'qa'`), and the sentence now says `skill` instead of `role`, satisfying
"do not rename a message's noun while leaving the value it interpolates
unchanged if that makes the sentence false." This also incidentally
reproduces a live denial against my own session's PreToolUse hook chain,
captured verbatim while investigating (the *installed* plugin copy at
`~/.claude/plugins/...`, unrelated to and untouched by this change, so it
still reads `role`):

```
canonical: PreToolUse:Bash hook error (this session, unedited installed board-gate.sh) — result:
board-gate: a Bash call carries an un-analyzable write-capable shape (python3 - <<'PYEOF') while this gate enforces role 'technical-writing-structure-comprehension-2b15240c''s write-set. [...]
```

Gate test suites, before and after, compared as SETS OF TEST NAMES (not
just pass/fail counts):

```
derived: for suite in run-board-gate-tests run-approval-gate-tests run-dispatcher-equivalence-tests run-ups-diet-tests; do bash core/hooks/tests/$suite.sh; done — captured to before_*.txt / after_*.txt (before = `git stash`, after = working tree), test names extracted via `awk '/^(ok|FAIL)/{print $2}'`, then `diff before_*_names.txt after_*_names.txt`
board:      before=161 names, after=161 names — diff: IDENTICAL SETS
approval:   before=67 names,  after=67 names  — diff: IDENTICAL SETS
dispatcher: before=13 names,  after=13 names  — diff: IDENTICAL SETS
ups-diet:   before=7 names,   after=7 names   — diff: IDENTICAL SETS
```

The 4 pre-existing failures inside those sets
(`feasibility-spikes`, `ops-postmortems`,
`checkpoint-refusal-names-await-approval`, `execute-without-remote`,
`approval-gate: execution write, no approvers.md -> deny`, `combined UPS
payload <= 3072 bytes` — 6 named failures across 4 suites, since
board-gate and ups/dispatcher each contribute) are present identically
in the `git stash`-restored pre-fix tree and the current tree — confirmed
by re-running each suite against both trees and diffing the FAIL lines,
not merely assumed pre-existing.

Full-repository confirmation, one command, one artifact per side:

```
acceptance: bash core/hooks/tests/run-all.sh (before, via `git stash`) captured to before_full.txt; same command (after) captured to after_full.txt; `diff before_full.txt after_full.txt` — result: exit 0, zero-byte diff
```

`bash core/hooks/tests/run-all.sh` output is byte-identical before and
after across all 49 parsed hook files, every gate suite's pass/fail
counts (board-gate 159/2, approval-gate 65/2, gh-guard 54/0, role-gates
83/0, dispatcher-equivalence 24/1, facet-keyword-gate 14/0,
citation-gate 24/0, record-shape-gate 5/0, survey-order-gate 7/0,
ups-diet 35/1, and every other suite in the file), and the dispatcher
latency line (`ok dispatcher end-to-end latency < 100ms`). No overhead
increase: the diff is empty, so the same latency assertion held on both
sides, and the edits themselves are pure same-length-order string-literal
substitutions with zero added branches, calls, or subprocess spawns.
Monitor/watch machinery unbroken and not quieter: `run-all.sh`'s
`freelunch observe.sh enforcement (sibling plugin)` block (`== 9 passed,
0 failed ==`) and `deny-only-check` block (6/6 board-write forgery
checks) are part of that same byte-identical output.

PR #386 (`issue-384/diagnose-first+technical-writing-minimalism-scoping-bceafc9c`,
state OPEN, not merged) touches `core/directive/session-protocol-build-now.md`,
`core/hooks/directive.sh`, two files under `docs/issue-384/reports/`, and
`warrant/hooks/state.sh` — none of the five files this issue edited, and
none merged to `main` as of this work, so nothing in that PR's diff was
present on this branch to conflict with or exclude from the sweep:

```
canonical: `gh pr view 386 --repo tokenmaxxxer/tokenmaxxxer-core --json state,files,headRefName` — result: state OPEN, files: core/directive/session-protocol-build-now.md, core/hooks/directive.sh, docs/issue-384/reports/diagnose-first+technical-writing-minimalism-scoping-bceafc9c.md, docs/issue-384/reports/technical-writing-structure-comprehension-e0bd9d2c.md, warrant/hooks/state.sh
```

## Why

`#2600` sliced the earlier role→skill cleanup by occurrence *kind* (env
vars, comments/docstrings, prompt text, identifiers, persisted keys) —
gate denial messages fit none of those slices cleanly, so no slice
claimed them, and they kept teaching the retired noun at the exact moment
(a live denial) a session is most attentive. The fix scope is narrow by
design: only the noun that names *what the gate enforces*, only where a
live session actually reads it (deny/stderr/stdout/print call sites, not
comments, not test-runner echo, not identifiers, not filenames).

Two `role`-bearing sites were found and deliberately left unedited,
each with a stated reason rather than silently skipped:

- `board-gate.sh:973` — a `sys.stderr.write` that explains a *past*
  rename: `"issue #2741: this key was renamed role -> skill,
  forward-only; a sidecar written before that rename no longer resolves
  here"`. This sentence's job is to describe the historical rename
  itself; rewriting `role -> skill` out of it would make the sentence
  describe nothing. Leaving it matches the issue's own must-not:
  "do not rename a message's noun while leaving the value it interpolates
  unchanged if that makes the sentence false" — the inverse case, where
  renaming would be what makes it false.
- `board-gate.sh:989` (post-fix) — the same deny call's `skill/issue`
  phrasing was rewritten, but the call also references the literal
  filename `.on-the-record/role.json` inside "Make .on-the-record/role.json
  and the current branch name agree". That file is genuinely named
  `role.json` on disk; renaming the file itself is a schema change well
  outside this issue's scope (message vocabulary, not persisted-key
  naming — `#2600`'s "persisted keys" slice, already landed, is what
  covers that class, and did not touch this filename).

No compatibility alias and no dual-vocabulary period were introduced —
every edit is a direct word substitution in place, matching the
precedent (`#2572`, `#2592`) the issue names as a hard error naming the
replacement, never a bridge.

Two directive-level judgment calls, both driven by this being a
headless, single-shot, build-now-bypass session (`CORE_BUILD_NOW=1`,
confirmed via `printf` of the env var at the start of this session) with
an explicit operator warning that backgrounded work does not survive the
end of this turn:

- freelunch's "any repo tool call → delegate to a background worker"
  rule was not followed for the implementation. Contract v3 s22, which
  both the warrant and freelunch directives name as taking priority in
  headless/single-shot sessions, permits "do not dispatch that unit at
  all" when the delegated result cannot safely be waited on and consumed
  within the same turn — chosen here because this task's acceptance
  criteria (an exact live-trigger transcript, an exact test-name-set
  diff) need iterative, self-correcting verification that a single raw,
  unverified worker delivery is a poor fit for.
- the warrant directive's before-landing hunter dispatch was skipped for
  the same reason: a background dispatch whose finding is never consumed
  before the turn ends is exactly the failure mode the operator's
  completion-and-landing guidance warns against, and s22 names skipping
  the dispatch as the sanctioned alternative to dispatching-and-not-waiting.
  This diff also touches `core/hooks/` (a `hooks/` directory), which the
  warrant directive's size table keeps at the full 180s/two-stance tier
  regardless of line count — the tier a background dispatch would have
  needed here was the most expensive one, not the cheapest, which raised
  rather than lowered the risk of an orphaned dispatch.

## What did not work

None — every edit landed as intended on the first pass, and the search
contract used for the before-count and the after-recheck was defined
once and reused unchanged for both, so there was no rework to log.

## Upstream basis

No prior `docs/issue-366/` work exists; this record's upstream is the
issue text itself (`gh issue view 366`) and the five code paths edited in
this same commit (frontmatter `upstream:`, `sha: same-commit` for each).

## Open findings

None. The two remaining `role` occurrences in the population search
(`board-gate.sh:973`, `:989`) are resolved findings, not open ones — each
carries its own justification in Why above, and re-running the same
search after the edits is how that justification was checked, not
asserted.

## Next steps

None — `loop_state: landed`. Work under `#2626` (the completion
judgement this issue's Non-goals section names as downstream) is out of
this record's scope.

skill-verdict: technical-writing-structure-comprehension — not-applicable: this task is a single-noun vocabulary substitution (role -> skill) that must preserve every message's existing sentence structure and length exactly (per the issue's own must-not clause); it is not a sentence/paragraph/section restructuring-for-comprehension task, so the skill's structure-comprehension techniques (15-20 word targets, chunk breaks, phase-grouped procedures) do not apply here.
