Scout skip: scout-directive's second mandatory skip condition applies —
the spec leaves no design decision open. Issue #203's fix direction is
already fully specified (text edit to one heredoc, keep `git commit -m`,
add a staging-of-new-files instruction, scope to the write set) and the
Acceptance section names the exact check. There is no product-shaped
surface or external category to benchmark against; this is a
docs/internal-tooling text fix.

## Current state

- The actual authoring point is `core/hooks/lib/role-directive.sh`,
  `core_role_directive()`, a heredoc (`cat <<EOF ... EOF`) that every
  role's `hooks/directive.sh` sources and calls with four role-unique
  strings (issue-66: single co-injected source for all 43 role copies).
  `core/hooks/directive.sh` itself does not contain the commit-staging
  line directly — it is emitted by this shared function at session
  start and shows up verbatim in every role's directive output,
  including this very session's own `<system-reminder>` (see the line
  "A commit that stages any docs/issue-<n>/** work must use git commit
  -m and carry a Subject: issue-<n> trailer...").
- Current text (role-directive.sh, in the heredoc, ~line 116 of the
  rendered output / same relative position in the source function):

  ```
  - A commit that stages any docs/issue-<n>/** work must use git commit -m
    and carry a Subject: issue-<n> trailer naming that issue (contract v3
    s13), one commit per subject — the same requirement trailer-gate.sh
    already enforces mechanically at commit time.
  ```

  This line specifies *which commit form* (`-m`, not `-F`/editor — so
  trailer-gate.sh's mechanical trailer check keeps working) and *what
  trailer* it must carry, but says nothing about *staging*. It reads as
  if the file set to be committed is already correctly staged, which is
  false whenever the role's write set includes a brand-new (untracked)
  file: `git commit -am` (or plain `git commit -m` after no `git add`)
  silently stages only modifications to already-tracked paths and skips
  untracked ones, producing an empty or incomplete commit and a
  downstream `gh pr create` failure ("No commits between main and
  branch") with no error at commit time itself.
- Confirmed by reading `git commit --help` behavior and by the issue's
  own field instance (issue-341, consumer repo, 2026-08-11): a 25KB new
  test file, `git commit -m` used directly, empty PR, two
  `uncommitted-work` session endings.
- `trailer-gate.sh` (the mechanical enforcer for the trailer half of
  this same line) operates on the commit's *args* (`-m` form) and the
  already-staged tree; it does not check staging completeness against
  the role's intended write set, so it would not catch this failure
  mode either — confirmed by reading `core/hooks/tests/run-role-gates-tests.sh`'s
  `run_trailer` harness, which pre-stages files with `git add -A` before
  invoking the gate and only asserts on the trailer/role-label axis.
- No other hook or gate in `core/hooks/` mentions `git add` or staging
  at all (`grep -rl "git add" core/hooks/` returns nothing outside test
  harness scaffolding that stages fixtures for other purposes). This
  confirms the gap is real: nothing upstream or downstream currently
  tells a role session to stage new files, and nothing mechanically
  catches the omission before the PR-create failure surfaces.
- Prior precedent for this exact class of fix: issue-195's proposal
  (`docs/issue-195/proposals/2026-08-10-record-format-contract-in-role-directive.md`)
  extended this same heredoc, in place, with additional instructional
  lines appended after an existing bullet — same file, same mechanism,
  same "content-only, no new wiring" scope. That precedent is the basis
  for treating this issue the same way rather than inventing a new gate
  script.

## Write set (projected)

- `core/hooks/lib/role-directive.sh` — the only file that needs to
  change; the heredoc text is the sole artifact in question.
- No test file exists yet for this heredoc's content (the closest
  harness, `core/hooks/tests/run-role-gates-tests.sh`, exercises the
  *gates*, not the directive text itself) and the issue's Acceptance
  section requires a unit test asserting the directive instructs
  staging of new files. That test is new: a small script under
  `core/hooks/tests/` (or a lib-level test file) that sources/renders
  `core_role_directive` with a role set and greps its output for the
  staging instruction, following this repo's existing pattern of
  subprocess-exercised bash test scripts (see
  `core/hooks/tests/run-role-gates-tests.sh` for the report()/pass/fail
  idiom).
- No dependency, env var, or migration surface is touched — pure text +
  a new bash test script, both under `core/hooks/**`, which is outside
  `docs/issue-203/**` but is the actual code fix the issue demands;
  phase-1 here (per this session's role) is proposal-only, and the
  proposal enumerates that write set for approval before phase 2 touches
  it. This survey/proposal writing itself stays under
  `docs/issue-203/**` as instructed.

## Alternatives considered (for the proposal's Rationale)

1. Edit the heredoc text only (chosen candidate) — minimal, matches
   issue-195 precedent, keeps `git commit -m` requirement intact.
2. Add a new mechanical pre-commit gate script that inspects the diff
   between the role's declared write set and `git status --porcelain`
   and refuses if an untracked file in that write set isn't staged —
   genuinely plausible: this is exactly the class of fix
   `trailer-gate.sh` already represents for the trailer-format half of
   the same sentence, and the issue's "Fix direction" explicitly
   suggests it as an option ("e.g. `git add -A <scoped paths>`... or an
   explicit note"). Rejected in the proposal because the issue's own
   Acceptance check is scoped to the *directive text*, not a new gate,
   and a new gate is separate, larger scope (detecting "the role's
   legitimate write set" mechanically requires knowing that set, which
   the directive doesn't currently expose in machine-readable form) —
   worth flagging as a natural follow-up issue, not this one.
