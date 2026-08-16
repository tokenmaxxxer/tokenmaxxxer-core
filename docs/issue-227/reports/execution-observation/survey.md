---
kind: current-state-survey
subject: issue-227
produced_by: execution-observation
phase: 1
---

# Current-state survey — issue-227 (execution-observation)

## Scope under observation

- **Issue**: #227 — "gate hardening: `${IFS}` token-fusion fail-open +
  board-gate indirect-tee miss (residuals from #225 review)", OPEN, no
  labels, `infrastructure/no-direct-requirement — hardening follow-up to
  #225` (`gh issue view 227`). Names two residual write-gate holes found
  during core#226's adversarial review of #225 (not regressions from
  #225): (1) `${IFS}`/`$IFS` token-fusion fail-open on both board-gate
  and scope-gate, (2) board-gate's miss of an indirect `tee` (target
  arriving via `xargs`/stdin). Direction section proposes denying bare
  `$IFS`/`${IFS}` presence and adding `tee` to board-gate's unanalyzable
  set. Acceptance: gate tests for both new-deny shapes, legitimate writes
  (`python3 -m pytest`, `grep|head`, `git diff`) still allow, no-write-set
  byte-identical.
- **Observed role**: `implementation`.
- **Observed session**: that role's session on branch
  `issue-227/implementation`.
- **Observed PR**: **#228**, "fix(issue-227): deny `${IFS}` token-fusion
  and board-gate indirect-tee write-gate holes", author `JiwonJung94`,
  created `2026-08-15T23:37:13Z`, **state OPEN, mergedAt null**
  (`gh pr view 228 --json createdAt,mergedAt,state`). This PR is NOT yet
  landed on `main`.
- **Observed commit**: a single commit,
  `1a2d393fdb3c4fd8ace77cf564026e09c5cead74`, `2026-08-16T08:37:01+09:00`
  = `2026-08-15T23:37:01Z` (`gh pr view 228 --json commits`, `git log -1
  --format='%H %ai %s' 1a2d393`), carrying `Closes #227` and `Subject:
  issue-227` trailers, `Co-Authored-By: Claude Sonnet 5`. Diffstat: 6
  files, 251 insertions, 5 deletions (`git show 1a2d393 --stat`):
  `core/hooks/board-gate.sh`, `core/hooks/tests/run-board-gate-tests.sh`,
  `core/hooks/tests/run-scope-gate-tests.sh`,
  `docs/handbooks/board-gate-tests.md`,
  `docs/issue-227/reports/implementation.md` (new),
  `warrant/hooks/scope-gate.sh`.
- **Base**: this branch was cut from `main` at `cac1049` (merge of #226),
  the same base the observed PR's diff (`git diff cac1049 1a2d393`)
  resolves against with no other intervening commits.

This session's own working tree is `main` at `cac1049`
(`git status` shows this branch clean, up to date with `origin/main`, no
commits ahead) — the observed PR has not landed here.

## What was read, first-hand, this session

1. Issue #227 body in full (`gh issue view 227`) — both named residuals,
   the direction section, the acceptance `check:` and empty-state lines.
2. Issue #227's two comments, fetched verbatim
   (`gh issue view 227 --json comments`): `JiwonJung94`,
   `2026-08-15T23:30:02Z`, body exactly `APPROVE issue-227/implementation`
   (implementation-role approval, not this role's); and a `[watch]`
   session-end notice at `23:37:20Z` pointing at PR #228. **No
   `APPROVE issue-227/execution-observation` comment exists on this
   issue** — this role's own phase 2 has not been opened.
3. PR #228 metadata in full — title, body, author, state, `createdAt`,
   `mergedAt` (`null`), `commits` (`gh pr view 228 …`), and its review +
   comment list (`gh pr view 228 --json reviews,comments`): `reviews`
   empty; one issue-style comment from `JiwonJung94` at
   `2026-08-15T23:45:35Z`
   (<https://github.com/tokenmaxxxer/tokenmaxxxer-core/pull/228#issuecomment-5304788003>),
   title "Independent adversarial review verdict: CHANGES (two blocking
   findings)".
4. `gh pr diff 228` in full — every hunk in `core/hooks/board-gate.sh`,
   `warrant/hooks/scope-gate.sh`, both test-suite files, the handbook
   addition, and the new `docs/issue-227/reports/implementation.md`.
5. `docs/issue-227/reports/implementation.md` as delivered in `1a2d393`
   (read via the diff in item 4, in full) — `verdict: pass`,
   `loop_state: landed` frontmatter; "What was done", "Why", "Upstream /
   basis", "What did not work" (two false starts: an over-broad
   unconditional `tee` branch that broke `bash-tee-comment-not-target`,
   and a malformed-JSON red test rewritten to the issue's minimal repro),
   "Open findings: None", and "Test evidence" citing `119 passed, 0
   failed` (board-gate), `35 passed, 0 failed` (scope-gate), `ALL OK`
   (`run-all.sh`).
6. `docs/specs/approvers.md` — two accounts, `JiwonJung94` and
   `jjongkwann`.
7. `docs/issue-225/reports/implementation.md` and the #226 review context
   referenced by both the issue and the observed record, to confirm the
   "unanalyzable write shape must deny" lesson this PR extends is the one
   `_is_unanalyzable_write_shape` / `UNANALYZABLE_WRITE_SHAPE` already
   encode (read via the diff context lines in item 4, which quote the
   surrounding pre-existing function).

## What the adversarial-review comment (item 3) asserts, read verbatim

Posted `2026-08-15T23:45:35Z`, ~8 minutes after the observed commit
(`23:37:01Z`) and PR creation (`23:37:13Z`) — i.e. **after** the record's
`verdict: pass` / `loop_state: landed` was already committed. Two
BLOCKING findings, both with concrete repro commands quoted in the
comment body:

- **Blocking 1 — new false positive.** The added regex `\$\{?IFS\}?` (both
  gates) has no boundary after `IFS`, so any variable merely *starting*
  with `IFS` trips it: `cat "$IFSHOME/notes.md"`, `cat "${IFS_DIR}/x"` are
  claimed to now hard-deny as pure reads. This is asserted to collide
  with the issue's own empty-state / legitimate-write acceptance
  language ("legitimate ... still allow").
- **Blocking 2 — surviving fusion-class spellings.** The reviewer claims
  the underlying class (interpreter-head+flag detection defeated by a
  non-whitespace separator) survives via other spellings that still
  execute a real masked write and are still allowed: command-substitution
  fusion (`python3$(printf " ")-c '...'`), interpreter-head via variable
  indirection (`P=python3; $P -c '...'`), and `awk`/`gawk`/`ed`/`ex`
  absent from `INTERPRETER_HEADS`.

Both claims are **asserted by the observed role's own PR-comment**, not
independently re-run by this survey (mode: `asserted` for the phase-2
record unless this role reproduces them itself with a `read`/`command`
citation).

## Open surfaces this proposal must allocate

1. **Outcome vs. the record's self-declared `pass`/`landed`.** The
   record's frontmatter was committed before the adversarial-review
   comment existed. Whether `outcome` should be judged against the
   record's own step-level citations (recomputation rule) or must also
   weigh the still-open, still-unaddressed blocking comment as itself a
   citable step-level fact about the PR's current state.
2. **PR non-merge as a trajectory fact.** PR #228 is open, unresolved,
   with two blocking findings outstanding and no follow-up commit since.
   Whether this bears on `outcome` (not yet landed on `main`), on
   `trajectory` (approved-by-human check — the *implementation* role's
   approval predates PR creation and is valid for that role, but this
   role has no approval of its own yet), or both.
3. **Approval-path check for the observed role.** The single
   `APPROVE issue-227/implementation` comment (`23:30:02Z`) predates PR
   #228's creation (`23:37:13Z`) — ordering consistent with contract v3
   §19's single-account path for the *implementation* role. This role's
   own trajectory check must state plainly that this is the
   *implementation* role's approval, not a general blanket sign-off on
   downstream steps.
4. **Blocking-finding 1 reproducibility.** Whether `cat "$IFSHOME/notes.md"`
   against the landed regex actually denies, checked by reading the
   landed `IFS_TOKEN_RE = re.compile(r"\$\{?IFS\}?")` /
   `r"|\$\{?IFS\}?"` patterns (from the diff already read, item 4)
   against Python `re.search` semantics, without executing the gate.
5. **Blocking-finding 2's scope against the issue's own text.** Issue
   #227's direction section explicitly scopes to the `$IFS` spelling
   ("A cheap, high-value catch: if `$IFS` or `${IFS}` appears anywhere ...
   deny") and does not name command-substitution fusion, variable
   indirection, or `awk`/`gawk`/`ed`/`ex` — whether the surviving
   spellings are an issue-227 acceptance gap or a legitimately
   out-of-scope residual for a future issue, and whether the observed
   record's silence on them (`Open findings: None`) is itself a step-level
   deficiency.
6. **"What did not work" section's own false-start disclosure** — whether
   the two documented false starts (over-broad `tee`, malformed-JSON test)
   are consistent with the final diff (item 4) and the final green test
   counts, i.e. whether the record's narrative matches the landed code
   rather than an earlier, discarded state.
7. **Test-evidence citation form** — whether `119 passed, 0 failed` /
   `35 passed, 0 failed` / `ALL OK` in the record are quoted verbatim from
   an actual run this role can also point at (the record states them as
   `derived:` command output, not merely asserted prose), per this role's
   own record-format requirement to distinguish `derived:` from bare
   prose claims.
8. **Frozen write-set / phase purity** — the single commit `1a2d393`
   carries both code (`core/`, `warrant/`) and the phase-2-shaped record
   file in one commit, under the build-now bypass (issue #227 is tagged
   `validity-consult-skip: trivial`, no proposal round visible for the
   implementation role) — whether that bypass was actually authorized
   (`CORE_BUILD_NOW=1` is asserted, not independently observable from a
   merged artifact list) and what evidentiary weight this role can give
   it (mode: `asserted`, since the spawning environment variable itself
   is not a readable artifact).
