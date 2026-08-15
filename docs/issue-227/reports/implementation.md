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

Closed the two residual write-gate holes issue #227 named (found during
core#226's adversarial review of #225, not regressions from it):

- **`${IFS}`/`$IFS` token-fusion fail-open (both gates).** A command like
  `python3${IFS}-c${IFS}'open(1)'` carries no literal whitespace before
  `-c` in the command TEXT the gates parse — `gate_head_of`'s
  whitespace `.split()` reads `python3${IFS}-c${IFS}'open(1)'` as one
  fused word, and scope-gate's `\s-[A-Za-z]*[ce]` alternative needs a
  literal `\s` it never finds. Rather than normalize the fused token
  apart (floated by the issue but flagged there as possibly riskier),
  applied the issue's own "cheap, high-value catch": the bare presence
  of `$IFS`/`${IFS}` in a write-context command is now itself treated as
  an unanalyzable write shape and denied, fail-closed — no legitimate
  gated write needs it.
  - `core/hooks/board-gate.sh`: added `IFS_TOKEN_RE` and a check inside
    `_is_unanalyzable_write_shape` (only reached when the ordinary token
    scan already found no docs/-shaped hit of its own, same call site
    the heredoc/`-c`/`dd` checks already use).
  - `warrant/hooks/scope-gate.sh`: added `\$\{?IFS\}?` as a new
    alternative in `UNANALYZABLE_WRITE_SHAPE`.
- **board-gate indirect-tee miss.** `echo docs/issue-3/reports/x.md |
  xargs tee` resolves (via `gate_head_of`'s existing `TRANSPARENT` walk
  through `xargs`) to head `tee`, but with no trailing argument word of
  its own — its real write target arrives on stdin, invisible in the
  command text — so it fell through both the existing `own_hits` scan
  and the pre-227 `_is_unanalyzable_write_shape` (heredoc/`-c`/`-e`/`dd`
  only) and reached `if not hits: allow()` unseen. Added a `tee`-with-
  no-visible-target branch to `_is_unanalyzable_write_shape`, scoped so
  a `tee` that DOES name a target (`tee docs/x` or `tee /tmp/x`) is
  unaffected — those are already either caught by `own_hits` (docs/-
  shaped) or are genuine non-board writes (not masked), not this gap.
  scope-gate.sh already covered this shape (`\btee\b` matches
  `xargs tee` regardless of indirection) — no change needed there.
- Added red tests reproducing both shapes to both suites before/while
  fixing, then confirmed green:
  `core/hooks/tests/run-board-gate-tests.sh` — `ifs-fused-inline-c-mask-bypass`
  (deny), `ifs-fusion-unrestricted-session-unaffected` (allow),
  `indirect-tee-via-xargs` (deny), `direct-tee-visible-target` (deny,
  unaffected by this fix — regression guard).
  `core/hooks/tests/run-scope-gate-tests.sh` — `ifs-fused-inline-c-write-shape-denied`
  (deny), `ifs-fusion-unrestricted-session-unaffected` (allow).

## Why

Both gaps are instances of the same underlying issue-225 lesson: a
write-capable command whose real target (or even its own interpreter
head) is not visible in the text the gate can see must fail closed, not
fall through a "nothing found, allow" default. `$IFS` fusion defeats the
whitespace-based head/flag detection both gates already rely on;
indirect `tee` defeats board-gate's target-extraction window for `tee`
specifically. Neither shape has a legitimate reason to appear in a
gated write — deny-by-default costs nothing real.

## Upstream / basis

- Issue #227 (this issue), citing core#226's adversarial review of #225
  as the source of both residuals.
- `docs/issue-225/reports/implementation.md` and
  `docs/issue-225/proposals/2026-08-16-close-script-heredoc-write-masking-bypass.md`
  — the prior fix this one extends (same call sites, same
  `_is_unanalyzable_write_shape`/`UNANALYZABLE_WRITE_SHAPE` mechanisms).
- `core/hooks/board-gate.sh`, `warrant/hooks/scope-gate.sh`, and their
  test suites as they stood at `cac1049` (branch base), read in full
  before writing this fix.

## What did not work

The first `tee` fix (unconditional `if head == "tee": return True` in
`_is_unanalyzable_write_shape`) broke a pre-existing passing test,
`bash-tee-comment-not-target` (`echo "see docs/.../review.md" | tee
/tmp/notes.txt`, expected allow): it treated every `tee`, including one
with a visible non-docs target, as unanalyzable. Narrowed to only fire
when `tee` has no visible non-flag trailing word at all (the indirect/
`xargs`-fed case) — expected: catch only the invisible-target shape;
actual (first pass): caught every `tee` regardless of a visible target.

The first `${IFS}`-fusion red test for board-gate's unrestricted-session
case used deeply nested JSON/shell quoting for a Python `open(...)`
call and produced a malformed JSON payload (parsed as an unreadable
PreToolUse payload, denied instead of the expected allow) — expected:
exercise the same shape as the restricted-session test; actual: JSON
quoting broke and the gate denied on "unreadable payload" instead of
standing down for lack of role/board. Rewritten with the issue's own
minimal reproduction shape (`python3${IFS}-c${IFS}'open(1)'`, single
quotes only, no nested double-quote escaping) instead.

## Open findings

None.

## Test evidence

derived: `bash core/hooks/tests/run-board-gate-tests.sh`
```
== 119 passed, 0 failed ==
```
(115 pre-existing + 4 new: ifs-fused-inline-c-mask-bypass,
ifs-fusion-unrestricted-session-unaffected, indirect-tee-via-xargs,
direct-tee-visible-target — all passing, no SKIPPED lines, no
regressions.)

derived: `bash core/hooks/tests/run-scope-gate-tests.sh`
```
== 35 passed, 0 failed ==
```
(33 pre-existing + 2 new: ifs-fused-inline-c-write-shape-denied,
ifs-fusion-unrestricted-session-unaffected — all passing, no SKIPPED
lines, no regressions.)

derived: `bash core/hooks/tests/run-all.sh`
```
ALL OK
```
(board gate, scope gate/warrant, approval gate, gh guard, role-agnostic
gates, and sibling-plugin test suites all pass clean; no SKIPPED lines,
no regressions.)
