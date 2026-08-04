---
kind: build-proposal
subject: issue-107
produced_by: implementation
loop_state: proposed
upstream:
  - path: docs/issue-107/reports/implementation/survey.md
    sha: <set at commit>
---

files: `core/hooks/lib/gate-lib.py`, `core/hooks/board-gate.sh`, `core/hooks/tests/run-board-gate-tests.sh`

## Request

Issue #107 formalizes Finding 1 of
`docs/issue-99/reports/execution-observation.md`: on the merged gate, a
wrapper-prefixed `cd` segment — `timeout 30 cd docs/issue-49 && date >
x.md`, and the same shape with `nohup` or any of the six pre-#98
wrappers (`command`, `env`, `xargs`, `time`, `nice`, `builtin`) — reaches
`allow()` with no rule ever applied, the exact unadjudicated-write class
issue #99 was filed to close. Root cause (survey, "The bug"): head
detection (`gate_lib.gate_head_of`, via `_resolve_transparent`) correctly
resolves the segment's head to `"cd"` through any `TRANSPARENT` wrapper,
but `board-gate.sh`'s `_cd_target` extracts the `cd` argument by
re-splitting the raw segment on whitespace (`stripped.split()[1:]`,
first non-flag word) — an index assumption that a wrapper prefix
invalidates. For `timeout 30 cd docs/issue-49`, `_cd_target` reads `"30"`
(the wrapper's own duration argument) instead of the path, so `cd_tail`
is never set, the write segment contributes no candidate, and
`if not hits: allow()` fires unadjudicated. Not a regression: the
pre-#102 dead fallback allowed the same wrapped shape for a different
reason; #102 closed the bare form and left the wrapped form open. Issue
#107 is phase-1-only — this proposal, no code.

**Scout-directive skip record:** scouting is skipped for this issue. This
is a pure bugfix to internal command-parsing logic in a security gate,
with no product-facing surface, no library/framework choice, and no
best-in-class category to compare against; issue #107's own action item
already fixes the direction (reuse the resolver's own trailing words).
No scout-brief.md is produced (recorded in full in the survey's own
"Scout-directive skip record" section).

## Constraints

- The `cd_tail` mechanism and the dead-fallback removal issue #99 landed
  are unchanged — issue #107's own `## 제약` names this as another role's
  property.
- The `TRANSPARENT` tuple itself (`gate-lib.py:194-195`) is unchanged —
  issue #107 is argument-extraction consistency, not wrapper-set policy.
- `gate_head_of`'s existing contract (a bare string) and its two current
  call sites (`board-gate.sh:214`, `:329`) must not change behavior —
  confirmed by grep this survey: those are the only two call sites in
  the repo, and `gh-guard.sh` uses a different function
  (`gate_wrapper_head_before`) for an unrelated question, so it is
  unaffected either way.
- Every existing case in `run-board-gate-tests.sh` keeps its current
  verdict; the fix must not open or close any case the survey did not
  name.
- No new dependency; no rewrite of `_resolve_transparent`'s own walk —
  the fix reuses its existing return value, it does not change how that
  value is computed.

## Rationale

**Chosen shape: add one new public accessor,
`gate_lib.gate_trailing_words(segment)`, returning
`_resolve_transparent(segment)[1]`; change `_cd_target` in
`board-gate.sh` to iterate that instead of `stripped.split()[1:]`,
keeping `_cd_target`'s own call site (`board-gate.sh:330`,
`_cd_target(stripped)`) and its own flag-skipping loop untouched.**

Two alternatives were considered and rejected:

1. **Duplicate the wrapper-skip logic locally inside `_cd_target`**
   (hand-check for `TRANSPARENT` membership and `timeout`'s extra
   argument, inline in `board-gate.sh`, without touching `gate-lib.py`
   at all). Rejected: this is the exact seam Finding 1's root-cause
   section names — head detection and argument extraction answering "is
   this a `cd`?" / "what is it `cd`-ing to?" via two independent models
   of where a command starts. A local copy would still be a *second*
   copy, just a more accurate one today; the next time `TRANSPARENT`
   changes (it already has once, issue #98 adding `timeout`/`nohup`),
   only one of the two copies would be updated and the same class of bug
   would reopen. Reusing the resolver's own output is the only shape
   that makes the two questions structurally unable to disagree.
2. **Rename `_resolve_transparent` to a public name
   (`gate_resolve_transparent`) and have both `gate_head_of` and
   `_cd_target` call it directly**, `gate_head_of` becoming a one-line
   wrapper. This also produces correct trailing words for all four
   traced shapes (bare, `timeout`, `nohup`, `command`) — hand-verified
   in the survey — so it is not rejected on correctness. Rejected on
   footprint: it touches `gate_head_of` and both of its existing call
   sites (`board-gate.sh:214`, `:329`) for no functional reason — the
   head-detection call site never needed trailing words — and it
   promotes a `_`-prefixed internal helper across the module's own
   public/private naming line (`gate_*` for public, `_`-prefix for
   internal) for a single caller that only needs the second tuple
   element. Adding one small accessor is the smaller, more reviewable
   diff for the same correctness result.

Both alternatives were hand-traced against the four shapes that matter —
bare `cd docs/issue-49`, `timeout 30 cd docs/issue-49`, `nohup cd
docs/issue-49`, `command cd docs/issue-49` — in the survey; all three
candidate designs (chosen + two rejected) produce the same correct
trailing words. The choice is about blast radius and reuse-of-existing-
seam risk, not about which one is correct.

## What will be done

1. `core/hooks/lib/gate-lib.py`: add
   `gate_trailing_words(segment)`, returning
   `_resolve_transparent(segment)[1]`, next to `gate_head_of`
   (`gate-lib.py:238-245`), with a docstring naming its one caller's
   need (the words after the resolved head, in original order, for a
   `cd` segment's argument extraction) so a future reader does not
   mistake it for a second, competing resolver.
2. `core/hooks/board-gate.sh`: change `_cd_target`
   (`board-gate.sh:259-269`) to iterate
   `gate_lib.gate_trailing_words(stripped)` instead of
   `stripped.split()[1:]`, keeping its existing first-non-flag-word
   scan and its existing call site (`:330`, `_cd_target(stripped)`)
   unchanged.
3. `core/hooks/tests/run-board-gate-tests.sh`: add two `run deny` cases
   next to the existing `bash-cd-relative-*-foreign` block
   (`:283-297`), following that block's naming convention:
   - `bash-wrapper-timeout-cd-relative-foreign`:
     `timeout 30 cd docs/issue-49 && date > x.md`
   - `bash-wrapper-command-cd-relative-foreign`:
     `command cd docs/issue-49 && date > x.md`
   (`command` chosen as the pre-#98 wrapper to cover, satisfying issue
   #107 requirement 2's "`command` 또는 `env`" alternative — no reason
   to prefer `env` over `command` surfaced in the survey, so the first
   of the two named options is used.)
4. Phase-2 execution records the red→green proof issue #107 requirement
   2 asks for: both new cases run against the current, unfixed tree
   first (expected: `FAIL want=deny got=allow` for both, all pre-
   existing cases still passing at their current count), then again
   after the code change (expected: full pass, count = current baseline
   + 2).

## Out of scope

- Any change to `TRANSPARENT`, `TRANSPARENT_TAKES_ARG`, or the set of
  wrapper heads board-gate recognizes — issue #107's own constraint.
- A `nohup` regression case: issue #107 requirement 2 mandates `timeout`
  plus at least one pre-#98 wrapper; `nohup` resolves through the exact
  same `_resolve_transparent` path already covered by the `timeout` and
  `command` cases (both argument-less-wrapper and extra-argument-wrapper
  shapes are exercised), so a third case would not exercise a new code
  path. Left for a future session to add if the human judges the
  explicit pin worth it.
- A `docs/handbooks/board-gate-tests.md` update: the doctrine ladder
  (env var / config key / new dependency / migration / setup step ->
  handbook) does not clearly apply — this is a new accessor alongside an
  unchanged one, not a new dependency or config surface. Left to phase-2
  judgment rather than committed to here, so the write set stays exactly
  what the survey found necessary.
- Re-examining Finding 2 or Finding 3 from the same execution-observation
  record — issue #107 is scoped to Finding 1 only; those two remain
  unresolved findings for the human to judge separately, per that
  record's own "Resolution path" section.

## How you'll know it worked

- `bash core/hooks/tests/run-board-gate-tests.sh` run against the
  current tree (before the code change) shows exactly two new `FAIL
  want=deny got=allow` lines for `bash-wrapper-timeout-cd-relative-
  foreign` and `bash-wrapper-command-cd-relative-foreign`, with the
  existing case count unchanged and all still passing — this is the red
  half of requirement 2's proof.
- After the code change, the same invocation shows full pass at
  (current baseline count) + 2, with no case that previously passed now
  failing — the green half, and the proof that requirement 3 (issue-90's
  preserved negative space, e.g. `bash-unresolved-head-then-read`,
  `bash-cd-then-cat`) still holds.
- `bash core/hooks/tests/run-gate-lib-tests.sh` still passes in full
  after the change, in particular its five `gate_head_of`/`TRANSPARENT`
  cases (`:208-216`) — confirming `gate_head_of`'s own contract and its
  two existing call sites are unaffected by adding
  `gate_trailing_words` beside it.
- No branch this fix adds is reachable-but-unproven: both new lines in
  `_cd_target`'s iteration source are entered by the two new test cases
  themselves, and the bare-`cd` and no-wrapper paths remain entered by
  every pre-existing `cd`-related case in the same file (issue #107
  requirement 3 / issue #99 requirement 4's standard).
