---
kind: coding-record
subject: issue-114
produced_by: implementation
code_under_review: `core/hooks/board-gate.sh`, `core/hooks/tests/run-board-gate-tests.sh`
loop_state: landed
upstream:
  - path: docs/issue-114/proposals/2026-08-04-fix-board-gate-wrapper-git-subcommand-extraction.md
    sha: 71f11040f221277293be46ec7474c51fd3a1598b
---

# Implementation record — issue-114

## Why

Phase 2, approved via issue-level comment `APPROVE issue-114/implementation`
(exact string, single-account mode — PR #115's author and the approving
account are both `jjongkwann`, an approvers.md account — posted on issue
#114). Delivering exactly the approved proposal's `## What will be done`:
Finding 1 of `docs/issue-107/reports/execution-observation.md` (the
remaining sibling to Finding 1 of
`docs/issue-99/reports/execution-observation.md`, which issue #107/PR #108
already closed for `cd`) — `board-gate.sh`'s `_git_subcommand` still
re-split the raw segment for a `git` segment's own subcommand
(`segment.split()[1:]`) instead of reading `gate_lib.gate_trailing_words`,
so a wrapper-prefixed read-only git segment (e.g. `timeout 30 git log`)
was misclassified as a write candidate — a fail-closed over-block, not a
security hole (confirmed by the phase-1 survey's hand-trace, and
re-confirmed live below).

## What was done

1. `core/hooks/board-gate.sh:187-205` — `_git_subcommand` now iterates
   `gate_lib.gate_trailing_words(segment)` instead of
   `segment.split()[1:]`; its own first-non-flag-word loop and its sole
   call site (`:224`, `_git_subcommand(stripped)`) are unchanged. Docstring
   extended to describe wrapper-prefix resolution, mirroring `_cd_target`'s
   own docstring (`:267-277`).
2. `core/hooks/tests/run-board-gate-tests.sh` — three new cases added next
   to the existing "git subcommand awareness" block (issue-60), per the
   proposal's naming convention:
   `bash-wrapper-timeout-git-log-foreign-issue` (`timeout 30 git log
   --oneline -1 -- docs/issue-49`, want `allow`),
   `bash-wrapper-command-git-log-foreign-issue` (`command git log
   --oneline -1 -- docs/issue-49`, want `allow`, the pre-#98
   argument-less wrapper shape), and
   `bash-wrapper-timeout-git-rm-foreign-issue` (`timeout 30 git rm -r
   docs/issue-49/reports`, want `deny`, pinning the reverse direction).
3. `docs/handbooks/board-gate-tests.md` — one entry added, same commit as
   the code change, describing the root cause and the fix (see
   `## Rationale for deviations` for why, given the proposal's own `## Out
   of scope` left this open).

No change to `gate_lib.gate_trailing_words`, `gate_lib.gate_head_of`,
`_cd_target`, or the `TRANSPARENT` tuple — confirmed by `git diff --stat`
below (only `core/hooks/board-gate.sh`, `core/hooks/tests/run-board-gate-tests.sh`,
and `docs/handbooks/board-gate-tests.md` changed).

## Rationale for deviations

The proposal's `## Out of scope` explicitly left a
`docs/handbooks/board-gate-tests.md` update "to phase-2 judgment (or the
repo's own mechanical `handbook-trigger-gate.sh`, which forced #107's hand
on this exact question) rather than committed to here." At commit time,
`handbook-trigger-gate.sh` classifies `core/hooks/tests/run-board-gate-tests.sh`
as an operational surface (its filename matches the `run[^/]*\.sh$`
run/setup-script pattern) and refuses a commit that changes it without
also touching a `docs/handbooks/*.md` file in the same commit — the same
gate, same reasoning, #107's own record already documented. A handbook
entry was added following `docs/handbooks/board-gate-tests.md`'s own
established per-issue-paragraph convention (directly after the issue-107
entry it extends). No file outside the proposal's named write set
(`core/hooks/board-gate.sh`, `core/hooks/tests/run-board-gate-tests.sh`)
was touched by the code/test change itself; the handbook touch is the one
addition, and the proposal's own `## Out of scope` already named it as a
live possibility, not a scope-exceeded stop.

## What did not work

None — the fix landed on the first attempt; no false starts.

## Doc-placement ladder

- No new env var, config key, dependency, or migration.
- No changed public signature or wire format: `_git_subcommand` keeps its
  existing signature (`segment` in, subcommand-or-`""` out) and its sole
  call site is unchanged. The library-choice question (reuse
  `gate_lib.gate_trailing_words`, reject moving the resolve to the call
  site) is already fully recorded in the phase-1 proposal's own
  `## Rationale` — no separate `docs/issue-114/decisions/` entry needed.
- No benchmark or investigation numbers produced beyond this record.
- `docs/handbooks/board-gate-tests.md`: touched, same commit as the code
  change — see `## Rationale for deviations` above.

## Hunt

`warrant-hunter` is not among this session's available `Agent`-tool
subagent types (same absence issue-88/90/93/94/98/99/100/107's own
records note). Self-directed, stance **boundary-prober** — assume the fix
either under-fixes (some other `TRANSPARENT`-wrapper shape still
misreads) or over-fixes (breaks a case the proposal's own survey marked
"unchanged") — rotating from issue-106's most recent self-directed stance
("assume the rule as drafted cannot hold — find the state nothing
maintains") and issue-107's `contract-literalist` before that. Chosen for
fit: this fix's own risk shape is a parser-differential generalization
question (does the resolver-based rewrite cover every `TRANSPARENT`
member and every nesting, and does it disturb the two cases the survey
called "unchanged by design"), which a boundary-prober lens targets
directly.

Ran 14 live probes (real `board-gate.sh` subprocess invocations, same
harness shape as `run-board-gate-tests.sh`'s own `run()`, via a scratch
script not committed) beyond the three cases the proposal's own test
additions cover:

- **Under-fix check**: every other `TRANSPARENT` wrapper the proposal's
  `## Out of scope` named as "not a new code path" —
  `nohup`/`env`/`xargs`/`time`/`nice`/`builtin` prefixing `git log`, plus
  a nested double-wrap (`timeout 30 nohup git log`) and a wrapper-own
  flag-with-separate-value shape (`timeout -s KILL 30 git log`) — all
  `allow` after the fix (over-block resolved for the whole `TRANSPARENT`
  class, not just `timeout`/`command`); the write-direction siblings
  (`nohup git rm`, `env git checkout`) stayed `deny`.
- **Over-fix check**: the two rows the survey's own trace table marked
  "unchanged" — `git -C /tmp log` and bare `git` — both resolve to
  `allow` identically before and after the fix (confirmed by `git stash`/
  `stash pop` of the three changed files and re-running the same probe
  script against the unmodified tree first, per the same method issue-107's
  own record used for its cross-gate regression check). This corrects my
  own first-pass misreading of the survey table (I initially expected
  these two to `deny`; the survey's "classified read? False" column means
  "not proven read-only", i.e. a write-candidate segment, not an outright
  `deny` — since neither segment carries a `docs/`-path token, the later
  R1-R5 stage has nothing to act on and both allow, matching the survey's
  own "unchanged" claim once read correctly). Re-verified against the
  pre-fix tree: identical `allow` both times — no regression, no
  survey error.

No new bypass found; no negative-space regression found; no under-fixed
`TRANSPARENT`-wrapper shape found.

closed_checks:
- name: two new `allow`-want cases fail (want=allow got=deny) against the pre-fix board-gate.sh, with only the test file changed; the `deny`-want reverse-direction case already passes unchanged
  ref: core/hooks/tests/run-board-gate-tests.sh (bash-wrapper-timeout-git-log-foreign-issue, bash-wrapper-command-git-log-foreign-issue, bash-wrapper-timeout-git-rm-foreign-issue)
  result: added the three new cases to the test file first, before any
    code change, and ran `env -u CLAUDE_PLUGIN_ROOT_CORE bash core/hooks/tests/run-board-gate-tests.sh`
    against the still-unfixed `board-gate.sh` — exactly 2 FAILs, both
    `want=allow got=deny` (the two read cases), the write case already
    passing `deny`, all 86 pre-existing cases still passing (87 passed, 2
    failed). This is the red half of requirement 2's proof. Confirmed.
- name: full suite green at baseline + 3 after the code change, no previously-passing case now failing
  ref: core/hooks/board-gate.sh:187-205 (`_git_subcommand`)
  result: after switching `_git_subcommand` to
    `gate_lib.gate_trailing_words`, `env -u CLAUDE_PLUGIN_ROOT_CORE bash core/hooks/tests/run-board-gate-tests.sh`
    → 89 passed, 0 failed (86 pre-existing + 3 new, all unchanged verdicts
    confirmed). This is the green half of requirement 2's proof. Confirmed.
- name: no unreachable branch; the changed iteration source is entered by every git-headed case in the suite
  ref: core/hooks/board-gate.sh:216-218 (`_segment_is_failing`'s `head == "git"` branch)
  result: every existing and new `git`-headed case in the 89-case suite
    (unwrapped "git subcommand awareness" block, the unwrapped read-broad
    cases `bash-gitlog-pathspec`/`bash-gitlog-glob`/`bash-wc-pipe`, and the
    three new wrapped cases) passes through the changed line; no dead code
    added, only the iteration source of an existing loop changed. Confirmed.
- name: no regression in gate-lib's own test suite or gh-guard.sh (both untouched by this delivery's write set)
  ref: core/hooks/lib/gate-lib.py (gate_trailing_words/gate_head_of unchanged), core/hooks/gh-guard.sh (not in this delivery's write set)
  result: `env -u CLAUDE_PLUGIN_ROOT_CORE bash core/hooks/tests/run-gate-lib-tests.sh`
    → `gate-lib: 53 passed, 1 failed` (the same single pre-existing macOS
    `mktemp -d` sandbox artifact issue-94/98/99/107's own records document
    — `gate-lib.py` is not in this delivery's write set, so this is
    environmental, not a regression). `env -u CLAUDE_PLUGIN_ROOT_CORE bash core/hooks/tests/run-gh-guard-tests.sh`
    → 52 passed, 0 failed (`gh-guard.sh` uses `gate_wrapper_head_before`, a
    different function, untouched by this delivery). Confirmed.
- name: boundary-prober hunt — every other TRANSPARENT wrapper shape (under-fix) and both survey-marked-unchanged rows (over-fix)
  ref: core/hooks/board-gate.sh:187-205, core/hooks/lib/gate-lib.py `TRANSPARENT` (unchanged)
  result: 14 live probes via a scratch harness (not committed) — 6
    argument-less wrappers, 1 nested double-wrap, 1 wrapper-own
    flag-with-value shape, all resolve to the fixed `allow` post-fix and
    `deny` pre-fix (confirmed via `git stash`/`stash pop`); the two
    survey "unchanged" rows (`git -C /tmp log`, bare `git`) resolve to the
    identical `allow` before and after (also confirmed via stash/pop). See
    `## Hunt` above for the detail. Confirmed.

## Open findings

None.

## Next steps

None from this delivery's own scope — issue #114's requirements are met
(unified iteration source, red-green regression proof, no regression in
existing negative space or in the broader `TRANSPARENT`-wrapper class).
The pre-existing `git -C <dir> <subcommand>` global-flag gap stays out of
scope, named by both the proposal and this record's own Hunt section, not
a blocker on this issue. This PR carries no closing keyword against issue
#114 — the execution plan on the issue is not itself marked complete, so
the human closes the issue separately once satisfied.

## Resolution path

Any open finding against this record is resolved by amending this file
with a `resolved_findings:` entry referencing the finder's record, per
contract v3 s16, before further build commits proceed.

## Verify

`env -u CLAUDE_PLUGIN_ROOT_CORE bash core/hooks/tests/run-board-gate-tests.sh`
→ `89 passed, 0 failed` (86 pre-existing + 3 new; red-state proof
pre-fix: `87 passed, 2 failed`, both new `want=allow` cases `got=deny` —
see `closed_checks` above).
`env -u CLAUDE_PLUGIN_ROOT_CORE bash core/hooks/tests/run-gate-lib-tests.sh`
→ `gate-lib: 53 passed, 1 failed` (pre-existing, unrelated macOS sandbox
artifact; `gate-lib.py` not in this delivery's write set).
`env -u CLAUDE_PLUGIN_ROOT_CORE bash core/hooks/tests/run-gh-guard-tests.sh`
→ `52 passed, 0 failed` (`gh-guard.sh` untouched by this delivery).
`env -u CLAUDE_PLUGIN_ROOT_CORE` avoids the ambient
`CLAUDE_PLUGIN_ROOT_CORE` ↦ installed-plugin-copy sandbox hazard
issue-99/107's own records document (this session's ambient shell carries
it; confirmed unset for every test run above).
