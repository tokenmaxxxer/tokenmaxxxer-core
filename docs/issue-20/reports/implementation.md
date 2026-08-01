---
subject: issue-20
role: implementation
code_under_review: core/hooks/gh-guard.sh, core/hooks/tests/run-gh-guard-tests.sh, README.md, docs/handbooks/gh-guard-tests.md
loop_state: landed
---

# Record — gh-guard endpoint+verb match (phase 2)

## What was done

Built the approved proposal
(`docs/issue-20/proposals/2026-07-31-build-gh-guard-endpoint-match.md`)
exactly, both files and checklist:

- `core/hooks/gh-guard.sh`:
  - Layer 0 pre-filter (`gh-guard.sh:38-41`) widened from `*gh*|*git*` to
    also include `*curl*|*wget*|*http://*|*https://*`, so a non-`gh`/`git`
    client reaches Layer 1 by design.
  - `RULES` (`gh-guard.sh:69-97`) gained four endpoint+verb patterns,
    independent of client binary, per proposal item 1: (a) a mutating
    verb (`-X POST/PUT/PATCH/DELETE`, `--method=`, or `-f `) against
    `pulls?/\d+/(reviews|merge)`; (b) `state=closed/open` or
    `-f state=` against the bare `pulls?/\d+` endpoint (PR close/reopen,
    raw-API); (c) a mutating verb or `-f (state|title|body)=` against
    the bare `issues?/\d+` endpoint (issue edit/close/reopen, raw-API);
    (d) a GraphQL mutation name (`mergePullRequest`,
    `addPullRequestReview`, etc.) alongside `graphql`. The two "bare"
    patterns ((b) and (c)) use `(?!/)` after the id so they don't also
    fire on `/comments` or `/merge`/`/reviews` sub-resources already
    covered by other rules — (b) matches the proposal's own explicit
    "bare, no `/merge` or `/reviews` suffix" wording; (c) extends the
    same tightening to `issues?/\d+` for consistency and to keep the
    Constraints section's false-denial bar (see "Rationale for
    deviations" for the one place the shipped regex differs from the
    proposal's literal text).
- `core/hooks/tests/run-gh-guard-tests.sh`: one `run` line per case
  confirmed in the survey (`docs/issue-20/reports/implementation/survey.md`),
  newly-closed and still-open alike, grouped and commented by the
  survey's own Group A/B/C/D labels: 3 Group A (curl/wget REST hits) +
  6 Group B (`gh api` raw GraphQL/PR-state/issue-state shapes) as `deny`,
  2 Group C (renamed binary, file-indirection) + 1 Group D (`Write` tool)
  as `allow` — plus one more `deny` line for the Group C literal-IP
  probe, which testing showed is no longer an open gap (see "What did
  not work"). The Group D case needed its own probe block instead of the
  `run()` helper, since `run()` hardcodes `tool_name:"Bash"`.
- `README.md` (lines 37-55): split the old "One account, by default" +
  "Hardening options (optional)" pair into three bullets — the
  single-account default (unchanged mechanics, now naming
  `gh-guard.sh` as the only thing standing between a role session and
  self-approval), `gh-guard.sh` as defense-in-depth (states plainly that
  it is a command-text blocklist, not a completeness guarantee, and
  names all four residual gaps — file-indirection, renamed binary, a
  client whose text never spells `gh`/`git`/`curl`/`wget`/`http(s)`, and
  non-`Bash` tools — pointing at the `gap-c-*`/`gap-d-*` tests), and the
  two-account model reframed as "the structural fix," explicitly not
  optional hardening on top of an already-sufficient default.

## Verification run (this session)

- `/bin/bash core/hooks/tests/run-gh-guard-tests.sh` → `32 passed, 0 failed`
  (19 pre-existing + 13 new: all Group A/B/C/D cases plus the
  literal-IP addition).
- `/bin/bash core/hooks/tests/run-all.sh` → `ALL OK` (parse-check,
  deny-only shape check, board gate 58/58, approval gate 36/36, gh
  guard 32/32, role-agnostic gates 17/17, stub-canon 3/3,
  compliance-scan-scope 4/4, sibling-plugin parse checks) — confirms the
  change stayed additive to `gh-guard.sh` only, no cross-hook
  regression.
- `bash -n core/hooks/gh-guard.sh` and
  `bash -n core/hooks/tests/run-gh-guard-tests.sh` → both syntax-clean
  (bash 3.2 target).
- Before writing the final test assertions, every survey-confirmed case
  (13 new + the 8 sanity/constraint cases already in the suite) was
  probed directly against the modified `gh-guard.sh` as a real
  subprocess (the same technique the survey and the test harness use),
  so every `deny`/`allow` line in the test file reflects an observed
  result, not an assumed one.

## What did not work

- Wrote the GraphQL rule exactly as the proposal's item 1 bullet 4
  spelled it, `r"/graphql\b"` (leading slash). Expected: matches `gh api
  graphql -f query=...mergePullRequest...` per the proposal's own stated
  target. Actual: it does not — `gh api graphql` has no `/` before
  `graphql`, so the two Group B GraphQL probes (`gap-b-graphql-merge`,
  `gap-b-graphql-approve`) came back `allow` on first run instead of the
  required `deny`. Fixed by dropping the leading-slash requirement
  (`r"\bgraphql\b"`, which still matches a raw `.../graphql` REST path
  too, since `/` is a non-word char and satisfies `\b`). Re-run: both
  cases `deny`. See "Rationale for deviations."
- Proposal item 2's parenthetical asserts widening Layer 0 to include
  `curl`/`https://` "does not close the literal-IP case." Expected (per
  that text): the survey's literal-IP probe (`curl -X PUT ...
  https://140.82.112.6/repos/o/r/pulls/7/merge`) stays `allow`. Actual:
  it now `deny`s, because the probe's own command text still literally
  contains `curl` and `https://` — the widened Layer 0 lets it through
  to Layer 1, where the new endpoint+verb rule (item 1a) matches
  `pulls/7/merge` + `-X PUT` regardless of the host. This is a real,
  verified finding, not a proposal deviation: item 2 was implemented
  exactly as specified, and the outcome for this one probe is better
  than the proposal predicted. The conceptual residual gap the proposal
  meant (a client whose command text avoids `gh`/`git`/`curl`/`wget`/
  `http://`/`https://` entirely) is still real and still open — README's
  defense-in-depth bullet names it in that general form rather than as
  "literal IP." No such avoiding-all-six probe was in the survey's
  confirmed case list, so none was added to the test file — adding one
  would mean inventing a case beyond "one run line per case confirmed in
  the survey," which is out of this phase's frozen scope.
- Attempted `git commit` with exactly the proposal's three frozen files
  staged. Expected: commit succeeds. Actual:
  `core/hooks/handbook-trigger-gate.sh` refused it — the staged
  `core/hooks/tests/run-gh-guard-tests.sh` matches contract §21's
  `run*.sh` operational-surface pattern, and no `docs/handbooks/` file
  was staged alongside it. Fixed by adding
  `docs/handbooks/gh-guard-tests.md` (see "Doc-placement ladder"); the
  proposal's own three-file code write set was otherwise untouched.

## Rationale for deviations

Two places where the shipped code differs from the proposal's literal
text, both discovered by running the change rather than assuming it
worked, and both required to meet the proposal's own stated acceptance
criteria ("How you'll know it worked": the GraphQL deny-cases must
pass):

- **GraphQL rule regex.** Proposal text: `r"/graphql\b"`. Shipped:
  `r"\bgraphql\b"`. Reason: the literal-slash form cannot match `gh api
  graphql ...`, one of the exact six deny-categories the proposal's own
  "What will be done" item 3 and "Failure signal" require to pass. The
  word-boundary form matches both that shape and a raw `.../graphql`
  URL, so it is strictly broader in the direction the proposal already
  intended ("regardless of whether it's reached via `gh api graphql` or
  a raw POST to `/graphql`" — proposal's own words for what this rule
  should cover).
- **`issues?/\d+` bare-endpoint exclusion.** Proposal text only states
  the "bare, no `/merge` or `/reviews` suffix" exclusion for the `pulls?`
  rule (item 1, bullet 2); it does not say the same for the `issues?`
  rule (bullet 3). Shipped both with the same `(?!/)` exclusion, so a
  raw-API mutation on `issues/N/comments` (already governed by the
  existing APPROVE-comment rule) does not also trip the new bare-issue
  rule on an unrelated `-X POST` to the comments endpoint. This is a
  verb-scoping tightening in the direction the proposal's own
  Constraints section requires ("must not turn ordinary phase-1
  research or phase-2 delivery commands into false denials") and its
  Failure signal names as the thing to watch for ("the new rules are
  over-broad and need verb-scoping tightened before merge"); it changes
  no test outcome in either direction, since no survey-confirmed case
  exercises `issues/N/comments` with a mutating verb.

Both changes stay inside the proposal's stated design (endpoint+verb
matching, independent of client binary) — neither adds a new pattern
category, widens the write set, or changes the approach.

## Upstream basis

`docs/issue-20/proposals/2026-07-31-build-gh-guard-endpoint-match.md`,
approved via issue-level comment `APPROVE issue-20/implementation` from
`jjongkwann` (`docs/specs/approvers.md`-listed — single-account path).

## Doc-placement ladder

- [x] No new env var, config key, dependency, or migration.
- [x] `core/hooks/tests/run-gh-guard-tests.sh` is an operational surface
  under contract §21 (`core/hooks/handbook-trigger-gate.sh`'s
  `run/setup/deploy script` pattern matches any staged
  `run*.sh`/`setup*.sh`/`deploy*.sh`/`install*.sh`) — the commit gate
  refused the first commit attempt on exactly this ground. Created
  `docs/handbooks/gh-guard-tests.md`, mirroring the existing per-gate
  handbook pattern (`approval-gate-tests.md`, `board-gate-tests.md`),
  documenting the harness and the new Group A/B/C/D coverage. This file
  was not in the phase-1 proposal's frozen list — it is the standing
  doctrine-ladder obligation (role directive: "config key/... run/setup
  script -> the component's handbook, same turn"), not a scope
  expansion of the code change itself, and the code write set stayed
  exactly the proposal's three files.
- [x] No library-or-format choice beyond what the phase-1 proposal's
  own "Alternatives considered" section already decided, and no changed
  public signature/wire format — no `docs/issue-20/decisions/` entry.
- [x] Verification run and the two regex-fix findings recorded in this
  file (`docs/issue-20/reports/implementation.md`).

## Hunt cadence

No `warrant-hunter` dispatch performed this session. Reasons, both
independent of the finding itself: (1) `warrant-hunter` is not among
this session's available `Agent`-tool subagent types, and the `warrant`
plugin's own `UserPromptSubmit` hook (which would normally inject the
dispatch instruction and its `docs/proposals/`/`docs/reports/` paths)
did not fire for this session — the plugin appears inactive for this
role/session rather than merely quiet; (2) this turn's explicit
constraint is headless and single-shot — work handed to
`run_in_background: true` (the hunter's own dispatch contract) dies
with the parent turn before it can report, which is the exact failure
mode this session was warned against. In its place, verification for
this delivery is the direct empirical probe run described above (every
survey-confirmed case run against the real `gh-guard.sh` subprocess,
plus the full `run-all.sh` suite) — recorded as closed checks below for
verify to cite or re-derive, not as a substitute certificate. Matches
the precedent recorded in `docs/issue-83/reports/implementation.md`
under the same constraint.

## Closed checks

- `core/hooks/tests/run-gh-guard-tests.sh` (code_sha: HEAD of this
  record): 32 passed, 0 failed — run locally, output captured above.
- `core/hooks/tests/run-all.sh` (code_sha: HEAD of this record): ALL OK
  — run locally, output captured above.
- `bash -n` on both modified shell files (code_sha: HEAD of this
  record): syntax-clean.
- Direct subprocess probe of all 13 survey-confirmed cases plus the 8
  pre-existing sanity/constraint cases (code_sha: HEAD of this record):
  every result matches the test file's asserted `deny`/`allow`, per the
  "Verification run" section above.

## Next steps

None from this phase. The conceptual residual gap noted in "What did
not work" (a client avoiding all of `gh`/`git`/`curl`/`wget`/`http(s)`
in its command text) has no survey-confirmed probe and is out of this
phase's frozen scope; a future issue could survey it explicitly if
worth closing.

## Open findings

None outstanding.
