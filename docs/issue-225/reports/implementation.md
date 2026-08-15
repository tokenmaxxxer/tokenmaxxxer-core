---
code_under_review:
  - core/hooks/board-gate.sh
  - warrant/hooks/scope-gate.sh
  - core/hooks/tests/run-board-gate-tests.sh
  - core/hooks/tests/run-scope-gate-tests.sh
type: fix
breaking: false
verdict: pass
loop_state: landed
---

## What was done

Closed the script-heredoc write-masking bypass in both path-keyed write
gates named by the issue:

- `core/hooks/board-gate.sh`: a Bash segment already classified as
  write-capable-but-unproven-read-only is now also checked for whether it
  is "unanalyzable" — a heredoc operator (`<<`), an interpreter `-c`/`-e`
  flag (python3/python/bash/sh/zsh/perl/ruby/node), or `dd` — AND
  contributed no docs/-shaped candidate of its own (its real write target
  is masked or otherwise invisible in the command text). When such a
  segment exists, a role is set, and the repo is a board
  (`docs/specs/approvers.md` present), the call is denied before the old
  `if not hits: allow()` fallthrough that previously let it through
  unseen — this is the exact defect on-the-record PR #1627 hit live
  (`python3 - <<EOF` after board-gate had already denied a direct
  cross-issue `Edit`).
- `warrant/hooks/scope-gate.sh`: added the same shape check
  (`UNANALYZABLE_WRITE_SHAPE`, matching heredocs / `-c`/`-e` / `tee` /
  `dd`), checked ahead of `withheld()`/`readonly_allowed()` in the Bash
  branch that only runs while exactly one proposal is `approved` (a
  write-set is actively enforced). `tee`/`dd` previously matched
  `withheld()`'s own entries and only "declined to vouch" — the same
  fallthrough posture as any unrecognized command, not a deny; they now
  deny explicitly, same as heredocs/`-c`/`-e`.
- Added test coverage to both `core/hooks/tests/run-board-gate-tests.sh`
  and `core/hooks/tests/run-scope-gate-tests.sh`: the live bypass shape,
  a `bash <<EOF` heredoc, a `-c` inline string, `tee`/`dd` (scope-gate),
  an unrestricted-session negative case, and a `python3 -m pytest`
  still-allowed case.

## Why

board-gate R4 and scope-gate's write-set check both key writes off the
command text they can see. An interpreter call with an inline body never
shows its real write target in that text — `_mask_heredocs` blanks
heredoc bodies before the segment scan runs (so pseudo-command lines
inside a heredoc body are never split apart and misread as writes,
issue-198), which also means a REAL write hidden in that body vanishes
from the scan entirely. The command then reads as carrying no docs/
candidate at all, and the gate's fallback ("nothing found, not this
gate's business") lets it straight through. Deny-by-default for
un-analyzable write shapes closes this the same way the warrant
read-only allowlist already treats unprovable reads: fail closed rather
than guess.

## Upstream / basis

- Issue #225 (this issue), citing on-the-record#1627's PR record as the
  live bypass.
- `core/hooks/board-gate.sh` and `warrant/hooks/scope-gate.sh` as they
  stood at `e05b91f` (branch base), read in full before writing this fix.

## What did not work

None — the fix landed on the first pass; both gates' test suites and
`core/hooks/tests/run-all.sh` passed clean after implementation with no
prior failed attempt to record.

## Open findings

None.

## Test evidence

derived: `bash core/hooks/tests/run-board-gate-tests.sh`
```
== 115 passed, 0 failed ==
```
(110 pre-existing + 5 new: heredoc-python-mask-bypass,
heredoc-bash-mask-bypass, inline-c-flag-mask-bypass,
heredoc-unrestricted-session-unaffected, python-pytest-still-allowed —
all passing, no SKIPPED lines, no regressions.)

derived: `bash core/hooks/tests/run-scope-gate-tests.sh`
```
== 33 passed, 0 failed ==
```
(26 pre-existing + 7 new: heredoc-write-shape-denied,
bash-heredoc-write-shape-denied, inline-c-flag-write-shape-denied,
tee-write-shape-denied, dd-write-shape-denied, python-pytest-still-allowed,
heredoc-unrestricted-session-unaffected — all passing, no SKIPPED lines,
no regressions.)

derived: `bash core/hooks/tests/run-all.sh`
```
=== board gate ===
== 115 passed, 0 failed ==
=== scope gate (warrant) ===
== 33 passed, 0 failed ==
=== approval gate ===
== 50 passed, 0 failed ==
=== gh guard ===
== 54 passed, 0 failed ==
=== role-agnostic gates (trailer/record-fields/handbook-trigger) ===
role-gates: 81 passed, 0 failed
...
ALL OK
```

