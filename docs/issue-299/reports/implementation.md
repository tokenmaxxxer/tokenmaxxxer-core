---
issue: 299
role: implementation
loop_state: landed
upstream:
  - path: core/hooks/directive.sh
    sha: 74c8c91b30f20ed23b5d818a0978ca4410fd6a6d
code_under_review:
  - core/hooks/directive.sh
  - core/directive/session-protocol.md
  - core/hooks/tests/run-ups-diet-tests.sh
  - test/test_directive_injection.py
type: fix
breaking: "false"
verdict: pass
---

# issue-299 — implementation record

## What was done

Build-now bypass (`CORE_BUILD_NOW=1`, contract v3 s19a) — delivered directly,
no phase-1 proposal round.

Investigated first: confirmed `core/hooks/directive.sh:103` was the only
`Read <file> NOW, before any work` shape in `core/` (audited every
`core/hooks/*.sh` for the phrase — see the automated regression test below).
Traced the mechanism: `core/directive/session-protocol.md` declared at its
own line 1 that `directive.sh` "renders `${role}` per session", but no such
rendering ever existed anywhere in the repo — the file was only ever pointed
at via the Read-NOW instruction, never rendered or delivered directly.

Fixed both, narrowly:

- `core/hooks/directive.sh`: replaced the trailing `Read ${DFILE} NOW,
  before any work: ...` line with logic that `cat`s `session-protocol.md`'s
  content directly into the hook's own stdout — the same effect #2204 got
  via `--append-system-prompt` on the on-the-record side, achieved here
  through the mechanism core already has (SessionStart hook stdout becomes
  session context with no extra flag). Empty-state handled: when the file
  is missing or unreadable, the hook now emits a clear degrade message
  naming the exact path and stating the INVARIANTS block above it still
  applies, instead of silently emitting nothing beyond that block.
- `core/directive/session-protocol.md`: removed the never-honored "Template
  note" about `${role}` rendering, and replaced every `${role}` occurrence
  with the inert placeholder `<role>` — the same convention the file
  already uses for `<n>` (issue number). This makes the delivered body
  carry zero per-session substitution: it renders byte-identical every
  session regardless of role, satisfying the issue's caching-separation
  constraint without needing any interpolation logic in `directive.sh`. The
  short INVARIANTS block that precedes it (already inlined in `directive.sh`
  itself, unaffected by this change) is the only part that still varies by
  role, via a real `${role}` bash-variable interpolation.
- `core/hooks/tests/run-ups-diet-tests.sh`: the issue-278 SessionStart
  budget (`<=2560` bytes, apostrophe-free) was built on the assumption that
  `session-protocol.md` stayed external and "on demand" — this issue's own
  finding is that it was never actually on-demand, since `NOW, before any
  work` forced an eager read every session anyway, just via a costlier
  route (a tool round-trip instead of inline text). Rescoped: the
  `<=2560`-byte, apostrophe-free assertions now apply only to the short
  per-session INVARIANTS prefix (before the new inline-delivery marker);
  the combined output (prefix + inlined protocol body) gets a generous
  32768-byte sanity ceiling instead, plus new assertions that no `Read ...
  NOW, before any work` pointer remains and that the protocol body is
  genuinely present inline.
- `test/test_directive_injection.py` (new, the issue's own named gate):
  six cases — no Read-NOW pointer; protocol content genuinely present
  (a phrase that lives only in `session-protocol.md`'s body, never in
  `directive.sh`'s own short index); byte-stability across two renders;
  the missing/unreadable-file empty state degrades to a clear message
  without dropping the INVARIANTS block; `session-protocol.md` carries no
  `${role}` per-session substitution; and the audit — no other
  `core/hooks/*.sh` script emits the same shape.

## Why

`--append-system-prompt` itself is a CLI flag on the on-the-record side's
own invocation of `claude`; `core` is a hook-based plugin with no control
over how it is invoked, so it cannot literally pass that flag. What it does
control is its own SessionStart hook's stdout, which already becomes
session context with no Read call — using that directly reproduces
#2204's effect (content reaches the session without a tool round-trip)
through the channel core actually has, rather than "drop the protocol" or
merely soften the wording (which risks the content never being read at
all, and would not satisfy the issue's "genuinely present" acceptance
bar).

Alternative considered and rejected: keep `Read ${DFILE}` but soften the
imperative from "NOW, before any work" to "when you need it" (a smaller
diff, closer to the existing issue-278 per-turn hooks' "Read X first"
phrasing). Rejected because it does not meet the issue's stated remedy
("deliver session-protocol.md content directly") or its acceptance
criterion ("show the protocol content is genuinely present... not merely
absent") — a softened pointer is still a pointer; a session that never
happens to need a "soft" hint may never read the file at all, and there
would be nothing to grep for in a stream-json log either way. Delivering
the content directly is the only shape that makes both true unconditionally.

Alternative considered and rejected for the caching split: keep
`${role}` interpolated into `session-protocol.md`'s body (render it in
`directive.sh` before catting it), and rely on same-role repeat spawns
sharing a cache-stable prefix. Rejected because the issue names "role
name" explicitly as a per-session variable to separate from the invariant
body, and the `<n>`-style inert-placeholder rewrite achieves full,
role-agnostic byte-identity for zero added interpolation code — a strictly
stronger caching property (stable across every session, not just repeat
spawns of the same role) for less implementation, so there was no
tradeoff actually favoring the rejected option.

Audit scope: `core/hooks/proposal-shape-directive.sh`,
`record-shape-directive.sh`, and `survey-order-directive.sh` also carry a
`Read <file> first` pointer, but that is a materially different, softer
shape (no "NOW", no "before any work") that issue-278 deliberately
designed as part of its per-turn UPS byte-diet (`<=3072` bytes/turn,
verified still passing, unchanged by this fix) — those hooks fire every
turn, not once at session start, so re-delivering their full referenced
`directive/*.md` files inline every turn would blow that budget for a
shape the issue's own problem statement does not name (the issue is
explicit that "NOW, before any work" is "the strongest possible form" and
names it as the specific defect). Left as an open finding below rather
than folded into this fix's scope.

## What did not work

None — the fix landed as scoped; no dead ends.

## Upstream basis

- `core/hooks/directive.sh` at commit
  `74c8c91b30f20ed23b5d818a0978ca4410fd6a6d` (this branch's merge-base with
  `main`, tip = issue-297's merge) — the version investigated, containing
  the `Read ${DFILE} NOW, before any work` line this issue names.
- `core/directive/session-protocol.md` (this same commit) — the file whose
  content is now delivered inline instead of pointed at.
- Issue #299's own text, which in turn cites on-the-record #2204 (PR #2212,
  merged as `443f6136`) as the remedy this issue applies core-side, and PR
  #2220 as the session that confirmed the bug live.

## Open findings

- The three `core/hooks/*-directive.sh` UserPromptSubmit hooks
  (`proposal-shape-directive.sh`, `record-shape-directive.sh`,
  `survey-order-directive.sh`) each still end with a softer `Read <file>
  first` pointer to their own `directive/*.md` file, once per matching
  turn. Not the shape this issue names or fixes (see Why, audit scope,
  above), and changing it would need to weigh against the issue-278
  per-turn byte budget those hooks were designed around — a separate
  design question, not folded into this fix.
  Resolution path: a future issue, if the softer per-turn shape is ever
  independently measured costing meaningful wall-clock the way the
  SessionStart shape was.

## Next steps

None — `loop_state` is terminal (`landed`).

## Acceptance evidence

Executed at landing time, this branch, working tree as committed.

Gate (`test/test_directive_injection.py`, the issue's own named gate):

```
$ python3 -m pytest test/test_directive_injection.py -v
test/test_directive_injection.py::test_no_read_now_pointer_to_session_protocol PASSED
test/test_directive_injection.py::test_protocol_content_genuinely_present PASSED
test/test_directive_injection.py::test_byte_stable_across_two_renders PASSED
test/test_directive_injection.py::test_missing_session_protocol_degrades_to_clear_message PASSED
test/test_directive_injection.py::test_session_protocol_md_uses_generic_role_placeholder_not_dollar_role PASSED
test/test_directive_injection.py::test_only_directive_sh_uses_the_now_before_any_work_shape PASSED

6 passed in 1.19s
```

Empty state (issue's named acceptance criterion — session-protocol.md
absent/unreadable degrades to a clear message, not a broken/empty system
prompt): covered by
`test_missing_session_protocol_degrades_to_clear_message` above, and
reproduced directly:

```
$ PATH=<fakebin>:/usr/bin:/bin CLAUDE_PROJECT_DIR=<fakerepo> \
  CLAUDE_PLUGIN_ROOT=<fake-core-without-session-protocol.md> \
  CLAUDE_ROLE=implementation bash <fake-core>/hooks/directive.sh
...
[core] session-protocol.md is missing or unreadable at: <fake-core>/directive/session-protocol.md
The full protocol (record required fields, loop_state vocabulary per kind,
operational-surface commit rule, headless delegation rule) could not be
delivered this session. The INVARIANTS above still apply; ask a human to
restore the file at that path before relying on anything not listed above.
exit=0
```

Provenance (issue's named requirement — executed-live): spawned a real
role session via `claude --print --output-format stream-json --plugin-dir
<this branch's core/> "Reply with exactly the single word: OK. Do not call
any tools, do not read any files."` with `CLAUDE_ROLE=implementation` in a
scratch git repo with a stub `gh` on `PATH` (same technique
`run-ups-diet-tests.sh` already uses to satisfy directive.sh's precondition
probe). `--plugin-dir` (`claude --help`) loads a plugin from a local
directory for that one session only, so this exercises the actual fixed
`core/hooks/directive.sh` through the harness's real SessionStart
mechanism, not a bare subprocess call:

```
$ python3 -c "
import json
lines=[json.loads(l) for l in open('live-after.jsonl') if l.strip()]
print('total events:', len(lines))
tool_uses=[c for l in lines if l.get('type')=='assistant'
           for c in l.get('message',{}).get('content',[])
           if c.get('type')=='tool_use']
print('tool_use events (any tool):', len(tool_uses))
read_on_session_protocol=[t for t in tool_uses if t.get('name')=='Read'
                           and 'session-protocol.md' in str(t.get('input'))]
print('Read tool_use targeting session-protocol.md:', len(read_on_session_protocol))
out=[l['output'] for l in lines if l.get('type')=='system'
     and l.get('subtype')=='hook_response' and l.get('output')][0]
print('SessionStart hook_response bytes:', len(out))
print('contains NOW, before any work:', 'NOW, before any work' in out)
print('contains body-only phrase (Terminal loop_state is per-kind):',
      'Terminal loop_state is per-kind' in out)
"
total events: 11
tool_use events (any tool): 0
Read tool_use targeting session-protocol.md: 0
SessionStart hook_response bytes: 10725
contains NOW, before any work: False
contains body-only phrase (Terminal loop_state is per-kind): True
```

Zero `Read` tool_use events of any kind fired in the whole session (not
just against `session-protocol.md`), and the SessionStart hook_response
that reached the session already carries the full protocol body —
`Terminal loop_state is per-kind` is a phrase that exists only in
`session-protocol.md`, never in `directive.sh`'s own short INVARIANTS
index, so its presence is direct evidence the content was delivered, not
merely that the old pointer is gone.

Regression suites (unaffected by this change, run to confirm no
collateral breakage):

```
$ bash core/hooks/tests/run-directive-shape-tests.sh
directive-shape: 11 passed, 0 failed

$ bash core/hooks/tests/run-role-directive-staging-tests.sh
role-directive-staging: 4 passed, 0 failed

$ bash core/hooks/tests/run-ups-diet-tests.sh
ups-diet: 36 passed, 0 failed

$ bash core/hooks/tests/parse-check.sh core
parse-check: 48 file(s) under /bin/bash
(0 FAIL lines — bash 5 only available in this environment; no bash 3.2
binary present to exercise PARSE_CHECK_BASH against directly, but this
change adds no heredoc nested inside a `$( … )` command substitution, the
one shape parse-check.sh exists to catch, so it carries the same
bash-3.2 safety as the surrounding unchanged code)

$ python3 -m pytest tests/ test/ -q
3 failed, 57 passed in 116.89s
FAILED tests/test_promoted_hooks.py::test_proposal_shape_gate_refuses_missing_sections
FAILED tests/test_promoted_hooks.py::test_survey_order_gate_refuses_proposal_without_survey_or_skip
FAILED tests/test_silent_failure_repros.py::test_A5_trailer_gate_quote_split_commit_is_detected
```

All 3 failures confirmed pre-existing on clean `HEAD` via `git stash -u`
(identical 3 failures, before this branch's changes were applied) — the
first two match issue-285's and issue-297's own records noting the
identical pair (issue-282's advisory-demotion of
proposal-shape-gate/survey-order-gate); the third
(`test_A5_trailer_gate_quote_split_commit_is_detected`) reproduces
identically with this branch's changes stashed out, so it is an
environment-specific pre-existing failure unrelated to this change, not
regressed by it.

```
$ bash test/hooks/test_trailer_gate.sh; bash test/hooks/test_handbook_trigger_gate.sh
trailer-gate: 5 passed, 5 failed
handbook-trigger-gate: 3 passed, 3 failed
```

Both confirmed pre-existing on clean `HEAD` via `git stash -u` (identical
pass/fail counts, unrelated to `directive.sh`/`session-protocol.md`, which
neither suite touches).

## Skill check

- implementation-blueprint: not applicable — this is a two-file bash/prose
  fix plus one new test file inside an existing hook's existing structure,
  not new multi-module architecture.
- implementation-complexity-coupling-management: not applicable — no
  coupling/cohesion metric, accessor chain, or check-pipeline ordering
  question; `directive.sh` gained a straight `if/else` around a `cat`.
- implementation-design-pattern-selection: not applicable — no GoF-pattern
  question; the fix is inlining a file read, not introducing indirection.
- implementation-performance-data-structure-choice: not applicable — no
  data structure or algorithm choice; the "performance cliff" here (a
  forced tool round-trip) is fixed by removing a Read call, not by
  choosing a different structure.
- other mounted skills: not triggered.
