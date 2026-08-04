---
kind: build-proposal
subject: issue-114
produced_by: implementation
loop_state: proposed
upstream:
  - path: docs/issue-114/reports/implementation/survey.md
    sha: <set at commit>
---

files: `core/hooks/board-gate.sh`, `core/hooks/tests/run-board-gate-tests.sh`

## Request

Issue #114 formalizes Finding 1 of
`docs/issue-107/reports/execution-observation.md`: on the merged gate,
`board-gate.sh`'s `_git_subcommand` (`:187-199`) still reads a `git`
segment's subcommand by re-splitting the raw segment
(`segment.split()[1:]`, first non-flag word) instead of through
`gate_lib.gate_head_of`'s own resolver — the exact parser-differential
seam issue #107 closed for `_cd_target`, left as a documented remaining
sibling in #107's own execution-observation record. Root cause (survey,
"The bug"): the call site (`_segment_is_failing`, `:214-216`) already
resolves the segment's head to `"git"` through any `TRANSPARENT` wrapper
via `gate_lib.gate_head_of`, but then passes the same raw segment to
`_git_subcommand`, which re-splits it independently and reads the
wrapper's own token instead of the subcommand. For
`"timeout 30 git log"`, `_git_subcommand` returns `"30"` (the wrapper's
duration argument); for the six argument-less pre-#98 wrappers (`nohup`,
`command`, `env`, `xargs`, `time`, `nice`, `builtin`), it returns the
literal wrapper word itself (e.g. `"git"` for `"command git log"`).
Neither is in `GIT_READ_SUBCOMMANDS`, so a wrapper-prefixed read-only git
segment is misclassified as a write candidate. Confirmed by hand-trace
against the live `gate-lib.py` in this tree (survey, comparison table):
the misread direction is fail-closed only — a wrapper-prefixed git
*write* segment is denied both before and after a fix — matching issue
#114's own diagnosis that this is a classification-accuracy bug, not a
security hole. Issue #114 is phase-1-only — this proposal, no code.

**Scout-directive skip record:** scouting is skipped for this issue.
This is a pure bugfix to internal command-parsing logic in a security
gate, with no product-facing surface, no library/framework choice, and
no best-in-class category to compare against; issue #114's own text
already names the fix's direction (reuse `gate_lib.gate_trailing_words`,
the accessor #107 already built and `_cd_target` already demonstrates).
No scout-brief.md is produced (recorded in full in the survey's own
"Scout-directive skip record" section) — the same skip condition and
reasoning #107's own proposal recorded for the sibling `_cd_target` fix.

## Constraints

- `gate_lib.gate_trailing_words` and `_cd_target` are unchanged — issue
  #114's own `## 제약` names both as #107's property.
- The `TRANSPARENT` tuple (`gate-lib.py:194-195`) is unchanged — issue
  #114 is argument-extraction consistency, not wrapper-set policy.
- `_git_subcommand`'s sole call site (`board-gate.sh:216`,
  `_git_subcommand(stripped)`) keeps its current argument and position —
  confirmed by grep (survey): no other call site exists.
- Every existing case in `run-board-gate-tests.sh` keeps its current
  verdict; the fix must not open or close any case the survey did not
  name, in particular the unwrapped "git subcommand awareness" block
  (`:223-239`, issue #60) and the unwrapped read-broad cases
  (`bash-gitlog-pathspec`, `bash-gitlog-glob`, `bash-wc-pipe`, `:206-214`).
- No new dependency; no rewrite of `_resolve_transparent` or
  `gate_trailing_words` — the fix reuses their existing return value, it
  does not change how that value is computed.
- The pre-existing, unrelated `git -C <dir> <subcommand>` global-flag gap
  (survey table: `git -C /tmp log` still misreads `/tmp` as the
  subcommand, both before and after this fix) is untouched — `-C` is a
  `git`-own flag, not a `TRANSPARENT`-wrapper prefix, and issue #114
  names only the wrapper-prefix class.

## Rationale

**Chosen shape: change `_git_subcommand`'s body
(`board-gate.sh:187-199`) to iterate
`gate_lib.gate_trailing_words(segment)` instead of
`segment.split()[1:]`, keeping its existing flag-skipping loop, its
existing signature (`segment` in, subcommand-or-`""` out), and its sole
call site (`:216`) completely unchanged.**

One alternative was considered and rejected:

1. **Move the resolve to the call site**: have `_segment_is_failing`
   compute `gate_lib.gate_trailing_words(stripped)` once (alongside its
   existing `gate_lib.gate_head_of(stripped)` call) and pass the
   resulting word list into `_git_subcommand`, changing its signature
   from "segment string in" to "word list in" — avoiding a second,
   independent `_resolve_transparent` walk over the same segment.
   Rejected: this breaks the established `_cd_target` precedent, which
   independently calls `gate_lib.gate_trailing_words(stripped)` *inside
   itself* rather than receiving pre-resolved words from its caller
   (`board-gate.sh:270`, `_cd_target`'s own body) — `_git_subcommand`
   changing shape while `_cd_target` keeps the body-internal-call shape
   would leave the module's two analogous helpers following two
   different call conventions for the same kind of resolve, the same
   inconsistency issue #114 exists to close, just moved one level up.
   It also touches the call site (`:214-216`) for a redundant-walk
   saving that is not a measured performance concern (`_resolve_transparent`
   is a short in-memory list walk, not I/O), for a larger diff than a
   drop-in body replacement with no behavior change. Both alternatives
   were hand-traced against the same eight segment shapes in the survey
   (bare `git log`, `timeout`/`nohup`/`command`-prefixed reads,
   `timeout`/`command`-prefixed writes, the `-C` global-flag case, bare
   `git`) and produce identical classification results — the choice is
   about call-convention consistency with `_cd_target`, not correctness.

## What will be done

1. `core/hooks/board-gate.sh`: change `_git_subcommand`
   (`:187-199`) to iterate `gate_lib.gate_trailing_words(segment)`
   instead of `segment.split()[1:]`, keeping the existing
   first-non-flag-word loop and the existing call site (`:216`,
   `_git_subcommand(stripped)`) unchanged. The docstring is updated to
   describe wrapper-prefix resolution (mirroring `_cd_target`'s own
   docstring, `:259-269`, which already names `_git_subcommand`'s
   flag-skip loop as the shared idiom — issue #114 closes the other half
   of that cross-reference: the iteration source, not just the loop
   body).
2. `core/hooks/tests/run-board-gate-tests.sh`: add three `run` cases
   next to the existing "git subcommand awareness" block (`:223-239`,
   issue #60), following that block's own `bash-git-<verb>-foreign-issue`
   naming convention with a `wrapper-<wrapper>-` prefix (matching how
   issue #107 prefixed its own two `cd` cases):
   - `bash-wrapper-timeout-git-log-foreign-issue` (want `allow`):
     `timeout 30 git log --oneline -1 -- docs/issue-49` — the read-only
     wrapped shape issue #114's own example names, mirroring the
     existing unwrapped `bash-gitlog-pathspec` case (`:206`).
   - `bash-wrapper-command-git-log-foreign-issue` (want `allow`):
     `command git log --oneline -1 -- docs/issue-49` — the pre-#98
     argument-less wrapper shape issue #114 requirement 2 names
     explicitly ("#98 이전 래퍼 1종 포함"), `command` chosen as the same
     pre-#98 wrapper #107's own two-case precedent already used (no
     reason to prefer a different one surfaced in the survey).
   - `bash-wrapper-timeout-git-rm-foreign-issue` (want `deny`, unchanged
     before and after): `timeout 30 git rm -r docs/issue-49/reports` —
     pins issue #114 requirement 2's explicit reverse-direction case (a
     wrapper-prefixed git *write* segment stays refused), mirroring the
     existing unwrapped `bash-git-rm-foreign-issue` case (`:228`).
3. Phase-2 execution records the red→green proof issue #114 requirement
   2 asks for: the two `allow`-want cases run against the current,
   unfixed tree first (expected: `FAIL want=allow got=deny` for both —
   the over-block red state — with the `deny`-want reverse-direction
   case and all pre-existing cases already passing unchanged), then
   again after the code change (expected: full pass, count = current
   baseline + 3).

## Out of scope

- Any change to `TRANSPARENT`, `gate_lib.gate_trailing_words`, or
  `_cd_target` — issue #114's own constraint.
- The `git -C <dir> <subcommand>` global-flag misread (survey: `git -C
  /tmp log` reads `/tmp` as the subcommand both before and after this
  fix) — a separate, pre-existing gap outside a `TRANSPARENT`-wrapper
  prefix, not named by issue #114's requirements.
- A `nohup` (or any wrapper beyond `timeout`/`command`) regression case:
  issue #114 requirement 2 mandates the `timeout` shape plus at least
  one pre-#98 wrapper for the read direction, and one case for the
  reverse (write) direction; every `TRANSPARENT` member resolves through
  the identical `_resolve_transparent` path already exercised by
  `timeout` (extra-argument shape) and `command` (argument-less shape),
  so a further case would not exercise a new code path — the same
  reasoning #107's own proposal used to leave `nohup` out of its two-case
  set.
- A `docs/handbooks/board-gate-tests.md` update: no new dependency,
  config key, migration, or changed public signature — `_git_subcommand`
  keeps its existing signature and sole call site; only its internal
  iteration source changes, same shape as #107's own accessor addition,
  which #107's proposal also left open. Left to phase-2 judgment (or the
  repo's own mechanical `handbook-trigger-gate.sh`, which forced #107's
  hand on this exact question) rather than committed to here.
- Re-examining Findings 2 or 3 of `docs/issue-99/reports/execution-observation.md`,
  or any other finding of `docs/issue-107/reports/execution-observation.md`
  beyond Finding 1 — issue #114 is scoped to Finding 1 of the #107
  execution-observation record only.

## How you'll know it worked

- `bash core/hooks/tests/run-board-gate-tests.sh` run against the
  current tree (before the code change) shows exactly two new `FAIL
  want=allow got=deny` lines for `bash-wrapper-timeout-git-log-foreign-issue`
  and `bash-wrapper-command-git-log-foreign-issue`, with
  `bash-wrapper-timeout-git-rm-foreign-issue` already passing (`deny`,
  unchanged) and the existing case count/verdicts otherwise unchanged —
  this is the red half of requirement 2's proof, and the direction
  (`want=allow got=deny`, an over-block) matches the survey's own
  fail-closed diagnosis.
- After the code change, the same invocation shows full pass at
  (current baseline count) + 3, with no case that previously passed now
  failing — the green half, and the proof that requirement 3 (no
  regression in existing negative space, in particular the unwrapped
  "git subcommand awareness" block `:223-239` and the unwrapped
  read-broad cases `:206-214`) still holds.
- No branch this fix adds is reachable-but-unproven: the changed
  iteration source in `_git_subcommand` is entered by every case that
  reaches it (every existing and new `git`-headed case in the suite),
  and the three new cases specifically exercise the wrapped-read,
  pre-#98-wrapped-read, and wrapped-write paths issue #114 requirement 2
  names.
