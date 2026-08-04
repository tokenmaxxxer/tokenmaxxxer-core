---
kind: coding-record
subject: issue-107
produced_by: implementation
code_under_review: `core/hooks/lib/gate-lib.py`, `core/hooks/board-gate.sh`, `core/hooks/tests/run-board-gate-tests.sh`, `docs/handbooks/board-gate-tests.md`
loop_state: landed
upstream:
  - path: docs/issue-107/proposals/2026-08-03-fix-board-gate-wrapper-cd-argument-extraction.md
    sha: 67eb71e9688ae000433e72a69ca78ee01a3efb96
---

# Implementation record — issue-107

## Why

Phase 2, approved via issue-level comment `APPROVE issue-107/implementation`
(exact string, posted by an approvers.md account, jjongkwann:
https://github.com/tokenmaxxxer/tokenmaxxxer-core/issues/107#issuecomment-5173547264).
Delivering exactly the approved proposal's `## What will be done`: Finding 1
of `docs/issue-99/reports/execution-observation.md` — a wrapper-prefixed
`cd` segment (`timeout 30 cd docs/issue-49 && date > x.md`, and the same
shape via `nohup` or the six pre-#98 wrappers) reaches `allow()` with no
rule ever applied, because `board-gate.sh`'s `_cd_target` re-split the raw
segment (`stripped.split()[1:]`) instead of reading the same resolver
`gate_head_of` already used to decide the segment IS a `cd`.

## What was done

1. `core/hooks/lib/gate-lib.py:248-259` — added
   `gate_trailing_words(segment)`, returning
   `_resolve_transparent(segment)[1]`, beside the existing `gate_head_of`
   (`:238-245`, unchanged). `gate_head_of`'s own contract and its two
   existing call sites (`board-gate.sh:214`, `:333`) are untouched.
2. `core/hooks/board-gate.sh:259-272` — `_cd_target` now iterates
   `gate_lib.gate_trailing_words(stripped)` instead of
   `stripped.split()[1:]`; its own first-non-flag-word scan and its own
   call site (`:334`, `_cd_target(stripped)`) are unchanged.
3. `core/hooks/tests/run-board-gate-tests.sh:283-291` — two new `deny`
   cases next to the `bash-cd-relative-*-foreign` block, per the
   proposal's naming convention: `bash-wrapper-timeout-cd-relative-foreign`
   (`timeout 30 cd docs/issue-49 && date > x.md`) and
   `bash-wrapper-command-cd-relative-foreign` (`command cd docs/issue-49 &&
   date > x.md`), covering both the extra-argument wrapper shape
   (`timeout`) and an argument-less pre-#98 wrapper shape (`command`), per
   issue #107 requirement 2.

No change to `TRANSPARENT`, `TRANSPARENT_TAKES_ARG`, `cd_tail`, or the
dead-fallback removal — all named out of scope / another role's property
by the proposal, and confirmed untouched by `git diff --stat` below.

4. `docs/handbooks/board-gate-tests.md` — one entry documenting the
   wrapper-cd argument-extraction root cause and the fix, same turn as
   the code change. See `## Rationale for deviations` below for why this
   file — left open by the proposal's own `## Out of scope`, not
   committed to — was in fact touched.

## Rationale for deviations

The proposal's `## Out of scope` judged a
`docs/handbooks/board-gate-tests.md` update as not clearly required under
the doctrine ladder ("a new accessor alongside an unchanged one, not a
new dependency or config surface"), explicitly leaving the call to
"phase-2 judgment rather than committed to here." At commit time, this
repo's own mechanical `handbook-trigger-gate.sh` (contract §21) refused
the commit: it classifies `core/hooks/tests/run-board-gate-tests.sh` as
an operational surface (a run/setup script) and requires a same-commit
`docs/handbooks/<component>.md` touch whenever it changes, independent of
whether the underlying code change itself introduces a new
dependency/config surface. This is not a new decision this delivery is
making — it is the exact question the proposal itself flagged as open,
now resolved by the mechanical gate rather than by author judgment: a
handbook entry was added, following `docs/handbooks/board-gate-tests.md`'s
own established per-issue-paragraph convention (see the file itself,
issue-90/-94/-98/-99's own entries). No other file outside the proposal's
named write set was touched; the frozen `files:` write set
(`core/hooks/lib/gate-lib.py`, `core/hooks/board-gate.sh`,
`core/hooks/tests/run-board-gate-tests.sh`) is unchanged in shape — this
is an addition the proposal already named as a live possibility, not a
scope-exceeded stop.

## What did not work

One false start, corrected before landing: the first post-fix test run
(`bash run-board-gate-tests.sh`, no env override) reported 8 cases failing
with `exit-1` instead of a clean adjudication — not the expected green.
Root cause: this session's own shell inherits `CLAUDE_PLUGIN_ROOT_CORE`
(pointing at the installed marketplace plugin copy, not this working
tree); `board-gate.sh:42` sources `gate-lib.sh` — and therefore resolves
`GATE_LIB_PY` — through that env var when set, so the test subprocess
loaded the *installed*, unedited `gate-lib.py` (no `gate_trailing_words`)
while running the *repo's* edited `board-gate.sh`, producing
`AttributeError: module 'gate_lib' has no attribute 'gate_trailing_words'`
for every `cd`-classified segment. Expected: a clean pass/fail signal from
the local edit; actual: a cross-copy version mismatch. Fixed by running
with `env -u CLAUDE_PLUGIN_ROOT_CORE` (the same hazard and the same fix
issue-99's own record documents at its `## Verify` section) — not a code
defect, and the initial red-state run (pre-fix, both copies still
identical) was unaffected by this contamination and stands as recorded
below.

## Doc-placement ladder

- No new env var, config key, dependency, or migration — nothing to add
  to a handbook under that ladder rung.
- No changed public signature or wire format beyond what the proposal
  already decided (`gate_trailing_words` is a new accessor alongside an
  unchanged `gate_head_of`) — the library/format choice (one new accessor
  vs. renaming `_resolve_transparent` public) is already fully recorded in
  the phase-1 proposal's `## Rationale`
  (`docs/issue-107/proposals/2026-08-03-fix-board-gate-wrapper-cd-argument-extraction.md`).
  No separate `docs/issue-107/decisions/` entry needed — this delivery
  made no design choice the proposal did not already decide.
- No benchmark or investigation numbers produced — nothing for
  `docs/issue-107/reports/` beyond this record itself.
- `docs/handbooks/board-gate-tests.md`: touched — one entry added, same
  turn as the code change (see `## Rationale for deviations` above for
  why, contrary to the proposal's own tentative "left unedited"
  expectation).

## Hunt

`warrant-hunter` is not among this session's available `Agent`-tool
subagent types (same absence issue-88/90/93/94/98/99's own records note).
Self-directed, rotating to a `contract-literalist` stance (issue-99's own
record used `general-purpose` hostile-bypass; issue-98 used the same
literalist stance before that) — re-reading issue #107's own three
requirements against the actual diff, rather than searching for novel
bypasses:

- Requirement 1 (unify wrapper-prefixed `cd` argument extraction with the
  same command-start model as head detection): `_cd_target` now reads
  `gate_lib.gate_trailing_words`, which is `_resolve_transparent`'s own
  second tuple element — the exact function `gate_head_of` (used one line
  above at `board-gate.sh:333` to decide the segment IS a `cd`) reads its
  first element from. The two questions ("is this a `cd`?" / "what is it
  `cd`-ing to?") are now structurally the same walk, not two independent
  models that can disagree.
- Requirement 2 (regression case + red-green proof, covering `timeout`
  plus at least one pre-#98 wrapper): both `bash-wrapper-timeout-cd-relative-foreign`
  and `bash-wrapper-command-cd-relative-foreign` failed
  (`want=deny got=allow`) against the pre-fix tree and pass after — see
  `closed_checks` below.
- Requirement 3 (no unreachable branch; existing negative space holds):
  both new lines in `_cd_target`'s iteration source are entered by the two
  new cases themselves (no dead code added — the function's control flow
  is unchanged, only its iteration source is); `bash-unresolved-head-then-read`
  and `bash-cd-then-cat` (issue-90/-99's own preserved negative space)
  still pass unchanged in the full suite run below.

No new bypass found; no negative-space regression found.

closed_checks:
- name: both new `deny` cases fail (want=deny got=allow) against the pre-fix board-gate.sh/gate-lib.py, with only the test file changed
  ref: core/hooks/tests/run-board-gate-tests.sh:283-291
  result: added the two new cases to the test file first, before any code
    change, and ran `bash run-board-gate-tests.sh` against the still-unfixed
    `gate-lib.py`/`board-gate.sh` — exactly 2 FAILs, both
    `want=deny got=allow` (`bash-wrapper-timeout-cd-relative-foreign`,
    `bash-wrapper-command-cd-relative-foreign`), all 84 pre-existing cases
    still passing (84 passed, 2 failed). This is the red half of
    requirement 2's proof. Confirmed.
- name: full suite green at baseline + 2 after the code change, no previously-passing case now failing
  ref: core/hooks/lib/gate-lib.py:248-259, core/hooks/board-gate.sh:259-272
  result: after adding `gate_trailing_words` and switching `_cd_target` to
    it, `env -u CLAUDE_PLUGIN_ROOT_CORE bash run-board-gate-tests.sh` → 86
    passed, 0 failed (84 pre-existing + 2 new, all unchanged verdicts
    confirmed, including `bash-unresolved-head-then-read` and
    `bash-cd-then-cat` negative space). This is the green half of
    requirement 2's proof. `-u CLAUDE_PLUGIN_ROOT_CORE` avoids the
    ambient-plugin-copy sandbox hazard recorded in `## What did not work`
    above and in issue-99's own `## Verify`. Confirmed.
- name: no cross-gate regression in gate-lib's own test suite (gate_head_of's contract/call sites unaffected) or in gh-guard.sh (unrelated function, untouched file)
  ref: core/hooks/lib/gate-lib.py (gate_head_of unchanged at :238-245), core/hooks/gh-guard.sh (not in this delivery's write set)
  result: `env -u CLAUDE_PLUGIN_ROOT_CORE bash core/hooks/tests/run-gate-lib-tests.sh`
    → `gate-lib: 53 passed, 1 failed` — confirmed identical (same single
    failure, same pre-existing macOS `mktemp -d` sandbox artifact
    documented in issue-94/98/99's own records) via `git stash`/`stash pop`
    of this delivery's three changed files and re-running the same
    command on the unmodified tree first. `env -u CLAUDE_PLUGIN_ROOT_CORE
    bash core/hooks/tests/run-gh-guard-tests.sh` → 52 passed, 0 failed
    (gh-guard.sh uses `gate_wrapper_head_before`, a different function,
    for an unrelated question — untouched by this delivery, per the
    survey's grep). Confirmed.

## Open findings

None. Issue #107 is scoped to Finding 1 of
`docs/issue-99/reports/execution-observation.md` only; Findings 2 and 3
from that same record remain open for the human to judge separately, per
that record's own "Resolution path" section, and are unchanged by this
delivery (out of scope, per the proposal's own `## Out of scope`).

## Next steps

None from this delivery's own scope — issue #107's three requirements are
met (unified argument extraction, red-green regression proof covering
`timeout` and `command`, no unreachable branch / negative space
preserved). The proposal's own named residuals (a `nohup`-specific case,
left for a future session; a `docs/handbooks/board-gate-tests.md` entry,
judged not clearly applicable under the doctrine ladder) are not blockers
on this issue.

## Resolution path

Any open finding against this record is resolved by amending this file
with a `resolved_findings:` entry referencing the finder's record, per
contract v3 s16, before further build commits proceed.

## Verify

`env -u CLAUDE_PLUGIN_ROOT_CORE bash core/hooks/tests/run-board-gate-tests.sh`
→ `86 passed, 0 failed` (84 pre-existing + 2 new; red-state proof
pre-fix: `84 passed, 2 failed`, both new cases `want=deny got=allow` — see
`closed_checks` above).
`env -u CLAUDE_PLUGIN_ROOT_CORE bash core/hooks/tests/run-gate-lib-tests.sh`
→ `gate-lib: 53 passed, 1 failed` (pre-existing, unrelated macOS sandbox
artifact, confirmed identical on the unmodified tree via stash/pop).
`env -u CLAUDE_PLUGIN_ROOT_CORE bash core/hooks/tests/run-gh-guard-tests.sh`
→ `52 passed, 0 failed` (gh-guard.sh untouched by this delivery).
`env -u CLAUDE_PLUGIN_ROOT_CORE` avoids the ambient
`CLAUDE_PLUGIN_ROOT_CORE`-points-at-the-installed-plugin-copy sandbox
hazard this session hit directly (see `## What did not work`) and that
issue-94/98/99's own records also document.
