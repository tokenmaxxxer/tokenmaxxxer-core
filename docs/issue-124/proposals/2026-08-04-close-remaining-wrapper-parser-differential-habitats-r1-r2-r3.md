---
kind: build-proposal
subject: issue-124
produced_by: implementation
loop_state: proposed
upstream:
  - path: docs/issue-124/reports/implementation/survey.md
    sha: <set at commit>
---

files: `core/hooks/approval-gate.sh`, `core/hooks/board-gate.sh`,
`core/hooks/lib/gate-lib.py`, `core/hooks/tests/run-approval-gate-tests.sh`,
`core/hooks/tests/run-board-gate-tests.sh`,
`core/hooks/tests/run-gate-lib-tests.sh`,
`docs/handbooks/approval-gate-tests.md`, `docs/handbooks/board-gate-tests.md`

## Request

Issue #124 formalizes Verdict 4 of issue-114's step-2 execution
observation (`docs/issue-114/reports/execution-observation.md:232-304`):
the wrapper parser-differential class traced #99 → #107 → #114 is not
exhausted by PR #115. Three habitats remain, all fail-closed
(over-block, not a security hole), each with a pinned line and a
prescribed minimum fix shape:

- **R1** — `approval-gate.sh:122`'s read-only early-allow head check uses
  raw `cmdline.strip().split()[0]`, with no `TRANSPARENT`-wrapper
  resolution, so a wrapped read (`timeout 30 grep -rn foo src/`) misses
  the shortcut and falls to the slower candidate scan.
- **R2** — `board-gate.sh`'s `_git_subcommand` has no notion that some of
  git's own global flags take a separate value token, so
  `git -C /tmp log` reads `/tmp` as the subcommand instead of `log`.
- **R3** — `gate-lib.py`'s `_resolve_transparent` flag-skip loop treats
  every `-`-prefixed token as self-contained, so a `TRANSPARENT`
  wrapper's own value-taking flag (`timeout -s KILL 30 git log`) steals
  the wrapper's bare-positional slot and resolves the head to the wrong
  token.

Requirement 1 asks for all three in one delivery, each in the minimum
form the issue text names (deviations require a stated reason).
Requirement 2 asks for a red→green regression proof per habitat, plus a
same-shape write-direction case proving the write path stays denied.
Requirement 3 asks for a post-fix re-run of issue-114's own mechanical
enumeration method, confirming zero remaining habitats, recorded in
phase 2's record (not this proposal — issue #124 is phase-1-only here).

## Constraints

- `gh-guard.sh`'s non-resolver call (`gate_wrapper_head_before`, its own
  fail-open direction) stays unchanged — `gate-lib.py:281-296`'s
  documented design choice is not touched by any of R1/R2/R3.
- `_cd_target` (#107) and `_git_subcommand`'s existing
  `gate_trailing_words`-based skeleton (#114) stay exactly as landed;
  this issue conforms the remaining habitats to that model, it does not
  redesign what already landed.
- No regression in existing negative space or in any previously-landed
  regression case, across all three touched test harnesses.
- Fail-closed direction preserved throughout: nowhere does this delivery
  turn an unresolved or misresolved head into a new fail-open shortcut —
  each fix narrows over-blocking, never widens what is trusted by
  default.

## Rationale

**Reuse the codebase's own existing resolver primitives and skip-table
idiom, rather than adding a second, independent parsing path for any of
the three sites.** Concretely: R1 calls the already-imported
`gate_lib.gate_head_of`; R2 adds a value-flag skip table to
`_git_subcommand` shaped like `gate-lib.py`'s own
`TRANSPARENT_TAKES_ARG`; R3 adds a per-wrapper value-flag table to
`_resolve_transparent` consulted before its existing
`TRANSPARENT_TAKES_ARG` slot.

Alternatives considered and rejected, one per site:

- **R1 — write a second, local head-resolution helper inside
  `approval-gate.sh`, scoped only to matching `READ_ONLY_HEADS`, instead
  of calling `gate_lib.gate_head_of`.** Rejected: this is exactly the
  duplication issue-98 already eliminated for `board-gate.sh`/
  `gh-guard.sh` by relocating head resolution into `gate_lib`. A second
  copy is a second place for this same bug class to recur — which is the
  recurrence this whole #99→#107→#114→#124 lineage exists to close, not
  extend.
- **R2 — generalize `_resolve_transparent`/`gate_trailing_words` itself
  to be git-flag-aware, instead of scoping the fix to `_git_subcommand`.**
  Rejected: `_resolve_transparent`'s job is resolving *shell-level*
  `TRANSPARENT` wrapper prefixes (`timeout`, `env`, ...), not any
  individual downstream command's own flag grammar. Git's global flags
  are a property of git, not of a wrapper; the existing call-site split
  (`gate_head_of` resolves the wrapper, `_git_subcommand` reads git's own
  argument shape) is exactly the boundary #107/#114 already established
  and the issue's own constraint says to respect.
- **R3 — route `_resolve_transparent` through `gate_wrapper_head_before`'s
  backward-scan logic instead of adding a forward per-wrapper flag
  table.** Rejected: `gate_wrapper_head_before` deliberately is *not* the
  resolver walk (`gate-lib.py:281-296` states this outright) because it
  assumes a fail-open caller and returns only a head, never
  `trailing_words` — `board-gate.sh`'s callers need `trailing_words` too
  (`_git_subcommand`, `_cd_target`). Reusing it would blur an
  intentional fail-open/fail-closed split the codebase already documents
  as deliberate, and would still require new plumbing to produce
  `trailing_words` from it.

**Scoping the flag tables minimally, not exhaustively:** R2's table is
`-C` and `-c` only — the two global flags `git`'s own synopsis documents
as space-separated (not `=`-joined); `--git-dir=`/`--work-tree=`/
`--namespace=`/`--config-env=` already resolve correctly today with no
fix needed, because an `=`-joined flag never introduces an extra
positional token for `_git_subcommand`'s loop to misread (confirmed by
trace in the survey). R3's table covers the four `TRANSPARENT` members
whose own value-taking flag is already named in `gate-lib.py`'s own
`gate_wrapper_head_before` docstring (`nice -n`, `env -u`,
`timeout -s`, `xargs -I`) — the other four members (`time`, `command`,
`builtin`, `nohup`) have no such flag in common use, and adding
speculative table entries for hypothetical future flags nobody has hit
would be scope creep in the direction issue #124 is trying to close, not
open.

## What will be done

- **R1**, `core/hooks/approval-gate.sh:118-122`: replace
  `head = cmdline.strip().split()[0].rsplit("/", 1)[-1] if cmdline.strip() else ""`
  with `head = gate_lib.gate_head_of(cmdline)`. `gate_lib` is already
  imported at this file's top (`:62-64`); `gate_head_of("")` already
  returns `""`, matching the current empty-cmdline branch. Safe to feed
  the whole `cmdline` (not just a single segment) because the
  accompanying `gate_lib.gate_outside_quotes(cmdline, r"[>|`]|\$\(")`
  check already requires no pipe/backtick/`$(` survive outside quotes
  before this branch is reached — this branch only ever sees a
  single-segment line in practice (verified in the survey against every
  existing `run-approval-gate-tests.sh` case that currently takes this
  shortcut).
- **R2**, `core/hooks/board-gate.sh`, near `_git_subcommand`
  (`:187-207`): add a module-level tuple
  `GIT_GLOBAL_VALUE_FLAGS = ("-C", "-c")` with a comment naming git's own
  synopsis as the source and stating the `=`-joined forms need no
  handling. Rewrite `_git_subcommand`'s loop to walk
  `gate_lib.gate_trailing_words(segment)` by index, skipping one extra
  word whenever the current word is in `GIT_GLOBAL_VALUE_FLAGS` — same
  shape as `_resolve_transparent`'s own `skip_extra` idiom, scoped to
  this function only (`gate_trailing_words`/`_resolve_transparent`
  themselves are unchanged by this bullet).
- **R3**, `core/hooks/lib/gate-lib.py`, near `TRANSPARENT_TAKES_ARG`
  (`:194-200`): add
  `TRANSPARENT_FLAG_TAKES_ARG = {"nice": ("-n", "--adjustment"), "env": ("-u", "--unset"), "timeout": ("-s", "--signal"), "xargs": ("-I",)}`
  (docstring citing `gate_wrapper_head_before`'s own docstring,
  `:283-291`, as the source of these four shapes). In
  `_resolve_transparent`'s inner loop (`:224-233`), before the existing
  `tok.startswith("-")`-then-`skip_extra` branches, check whether `tok`
  is in `TRANSPARENT_FLAG_TAKES_ARG.get(w, ())`; if so, advance `i` by 2
  (consuming the flag and its value) and `continue`, leaving the
  existing `skip_extra`/bare-flag branches untouched for every other
  token. This runs *before* `skip_extra` gets a chance at the flag's
  value token, closing the exact misread the survey traced for
  `timeout -s KILL 30 git log`.
- **Tests**, one red→green pair plus a write-direction sibling per
  habitat, following this lineage's established two-case-per-habitat
  convention (#114's `bash-wrapper-timeout-git-log-foreign-issue` /
  `bash-wrapper-timeout-git-rm-foreign-issue` pattern):
  - `run-approval-gate-tests.sh`: a wrapped read
    (`timeout 30 grep -rn foo src/app.py`, want `allow`) and a
    same-wrapper write (`timeout 30 sh -c "echo hi > src/app.py"` or
    equivalent wrapped-write shape, want `deny`, unchanged before/after).
  - `run-board-gate-tests.sh`: `git -C /tmp log --oneline -- docs/issue-49`
    (want `allow`) and `git -C /tmp rm -r docs/issue-49/reports` (want
    `deny`, unchanged before/after).
  - `run-gate-lib-tests.sh`: `headof` cases for
    `timeout -s KILL 30 git log`, `nice -n 10 git log`,
    `env -u FOO git log`, `xargs -I{} git log`-equivalent shapes,
    asserting resolution to the real command head, not the misread
    token.
- **Handbooks**: append one paragraph each to
  `docs/handbooks/approval-gate-tests.md` (R1) and
  `docs/handbooks/board-gate-tests.md` (R2 and R3 — `board-gate.sh` is
  the fail-closed consumer of `gate_head_of`'s R3 fix, matching how that
  file already documents `gate-lib.py`-side changes it consumes, e.g.
  issue-94's `gate_outside_quotes` paragraph), in the same voice and
  citation style the existing paragraphs use. This satisfies
  `handbook-trigger-gate.sh`'s same-commit-handbook-touch requirement
  (its `OP_PATTERNS` regex matches all three `run-*-tests.sh` files) and
  follows the file's own established one-paragraph-per-fix convention
  rather than relying on the gate's "any handbook file" minimum.
- **Closing verification** (phase 2's record, not this proposal): re-run
  issue-114's exact enumeration method —
  `git grep -n "gate_head_of\|gate_trailing_words\|gate_wrapper_head_before" -- core warrant`
  and `git grep -n "split()" -- core/hooks warrant/hooks` — against the
  post-fix tree, and confirm the three rows this issue names (R1/R2/R3)
  no longer read as fail-closed differentials in the resulting table,
  recorded as the class-closure statement Requirement 3 asks for.

## Out of scope

- Any `TRANSPARENT` wrapper flag beyond the four the docstring already
  names (`nice -n`, `env -u`, `timeout -s`, `xargs -I`) — no table
  entries for `time`/`command`/`builtin`/`nohup`, none of which have a
  documented value-taking flag in common use today. A future flag
  starting to matter in practice is a future issue, per this file's own
  "safe direction, not a new hole" convention for the residue an
  intentionally-scoped fix leaves behind.
- Any git global flag beyond `-C`/`-c` — the `=`-joined long flags
  (`--git-dir=`, `--work-tree=`, `--namespace=`, `--config-env=`) already
  resolve correctly with no code change (traced in the survey) and gain
  no new test coverage here; adding it would be untested scope with no
  behavior to fix.
- `gh-guard.sh`'s `gate_wrapper_head_before` call and its documented
  fail-open design choice — unchanged, per the issue's own constraint.
- `_cd_target`'s argument extraction — unchanged; `cd` takes no
  value-consuming global flag analogous to git's `-C`/`-c`, so it has no
  R2-shaped gap to close.
- A new habitat surfacing from the post-fix re-enumeration that is not
  one of R1/R2/R3 — Requirement 3 expects zero remaining after these
  three, but if the mechanical re-run turns up something unanticipated,
  that becomes a record finding for the human to scope into its own
  issue, not a silent expansion of this delivery's write set
  (scope-exceeded rule).

## How you'll know it worked

- `bash core/hooks/tests/run-approval-gate-tests.sh` → `0 failed`,
  including R1's new wrapped-read allow case and its wrapped-write deny
  sibling, with every pre-existing case unchanged.
- `bash core/hooks/tests/run-board-gate-tests.sh` → `0 failed`, including
  R2's new `git -C` read-allow case and its `git -C ... rm` write-deny
  sibling, with every pre-existing case (including issue-114's own
  wrapper-prefixed `git` cases) unchanged.
- `bash core/hooks/tests/run-gate-lib-tests.sh` → `0 failed`, all seven
  mandatory groups still exercised, including R3's new `headof` cases
  resolving to the real command head for all four documented
  wrapper-own-value-flag shapes.
- Red-state proof recorded per habitat: each new allow-case, run against
  the pre-fix code, fails as `want=allow got=deny` (over-block), then
  passes post-fix — the same red→green discipline #114's own record
  used.
- The post-fix re-run of issue-114's enumeration method (Requirement 3)
  shows R1, R2, and R3 no longer as fail-closed differentials — the
  class-closure statement this issue exists to produce, written into
  phase 2's record.
