---
kind: observation-record
subject: issue-116
produced_by: execution-observation
loop_state: observed
upstream:
  - path: docs/issue-116/reports/execution-observation/survey.md
  - path: docs/issue-116/reports/execution-observation/scout-brief.md
  - path: docs/issue-116/proposals/2026-08-04-independent-observation-of-pr-117.md
    sha: b1ff18b
observed:
  - pr: 117
    merge_commit: c94cb33
    commits: [97f8ce63183574dd1a6e411e953bc88576850a53, f991220b1f6b56717f17bff84f00e972e9130ebf]
    record: docs/issue-116/reports/implementation.md
---

# Execution observation — PR #117 (issue-116 step 1, `implementation`)

## Independence

This role did not author or edit the observed artifact, in this session
or any other. PR #117, its two commits, and
`docs/issue-116/reports/implementation.md` were produced by the
`implementation` role on branch `issue-116/implementation`. This session
has written only `docs/issue-116/reports/execution-observation.md` and
its phase-1 siblings under
`docs/issue-116/reports/execution-observation/`; it has edited nothing
under the observed role's `src/`-equivalent paths (`core/`, `freelunch/`,
`warrant/`, `scout/`, `terse/`), nothing under `test/`-equivalent paths,
and nothing in the observed role's record. It has run none of the
observed role's code: `freelunch/hooks/observe.sh` was never invoked and
`freelunch/hooks/tests/run-observe-tests.sh` was never executed, in any
mode, including as a spot check of the carve-out. Every judgment below
rests on the landed diffs, the two records, the approved proposals, the
issue, and the GitHub API's comment payloads — all read first-hand in
this session.

No verdict language appears above this line.

## Why

Issue #116's `## 실행 계획` names step 2 `execution-observation`. Phase 2
of this role opened on the issue-level comment whose entire body is
`APPROVE issue-116/execution-observation`, posted by `jjongkwann`
(`author_association: MEMBER`) at `2026-08-04T06:00:16Z`
(https://github.com/tokenmaxxxer/tokenmaxxxer-core/issues/116#issuecomment-5175204214).
That account is listed in `docs/specs/approvers.md:2`; PR #121's author
is the same account (`gh pr view 121 --json author` → `jjongkwann`), so
contract v3 §19's single-account path is the applicable one and the
issue-comment form is correct. String equality was checked against the
API body, not read out of prose.

This record delivers the three verdict levels the approved proposal
(`docs/issue-116/proposals/2026-08-04-independent-observation-of-pr-117.md`)
committed to, resolved against its six check points.

## What was done

Read this session, first-hand: `gh issue view 116` (three `## 요구사항`,
two `## 제약`); the GitHub API comment list for issue #116 (both bodies
verbatim); `git show f991220 --stat` and its full diff restricted to
`freelunch/hooks/observe.sh`, `warrant/hooks/directive.sh`,
`core/hooks/tests/run-all.sh`, `docs/handbooks/freelunch-observe-tests.md`,
and `core/contract/role-handoff-contract.md`; the landed blob
`f991220:freelunch/hooks/tests/run-observe-tests.sh` in full (88 lines);
`git show 97f8ce6 --stat`; the pre-images
`97f8ce6:core/hooks/tests/run-all.sh` and
`97f8ce6:core/contract/role-handoff-contract.md` (section index only);
`docs/issue-116/reports/implementation.md` (head and `:159-306`); the
observed proposal's `files:` line, its `## What will be done` items 1-4,
and its `## Warrant hunt` disposition; `docs/specs/approvers.md`; and
`git ls-files` for this repository's committed configuration surfaces.
Then the three-level verdict below was written and committed on branch
`issue-116/execution-observation`.

---

# Verdict

## Level 1 — Outcome: PASS

**All three `## 요구사항` and both `## 제약` landed.**

**Requirement 1** (`observe.sh` no longer refuses synchronous delegation
in a headless context, without weakening the hook's original purpose) —
**met.** `f991220`'s `observe.sh` hunk `@@ -80,7 +100,15 @@` replaces
`row["enforced"] = bool(enforce and row["violations"])` with a separate
`enforceable` list from which `sync_agent_dispatch` is removed when
`session_is_interactive` is false, and `f991220`'s hunk
`@@ -45,11 +49,27 @@` defines `session_is_interactive = entrypoint ==
"cli"`. The boundary the requirement demanded is held on three counts,
each visible in the same diff: `non_sonnet_worker` never enters the
removal branch and so still denies in every session type; the violation
is still appended to `row["violations"]` unconditionally, preserving the
audit trail; and the interactive deny path is untouched. The floor
("최소한 헤드리스 맥락에서") is exceeded rather than merely met — the
carve-out also covers unset and unrecognized entrypoints, which the
approved proposal explicitly authorized as its own fail-toward-not-denying
floor (`docs/issue-116/proposals/2026-08-04-approval-rule-gap-repairs.md`,
`## What will be done` item 1).

**Requirement 2** (§22 subordination note in `warrant/hooks/directive.sh`,
plus an exhaustive `scout`/`terse` audit) — **met, with a defect in the
audit's recorded reasoning** (Finding 1 below). The note landed at
`f991220`'s `warrant/hooks/directive.sh` hunk `@@ -21,6 +21,8 @@`,
inserted immediately after the opening `<warrant-directive
priority="high">` line and before the first dispatch instruction, in the
same shape the requirement asked for. Its conclusion about `scout` and
`terse` — that neither needs the note — is **correct**: the `scout`
directive emitted into this session by scout's own `UserPromptSubmit`
hook does mandate parallel subagent dispatch ("Run several such angles
concurrently in one turn … as parallel subagents (Agent tool, one message
with multiple calls)") but binds the results to an in-turn consumption
point ("JUDGE POINT 1: look at the sweep's combined results together"),
so it structurally cannot produce the end-a-turn-with-unconsumed-delegation
shape §22 forbids; the `terse` directive emitted into the same session
contains no delegation instruction at all, only output-style rules. The
reasoning the record gives for that conclusion is invalid — see Finding 1.

**Requirement 3** (role-session duty for non-canonical approval comments,
without breaking the cross-reference to otr's warn text) — **met.**
`f991220`'s sole `core/contract/role-handoff-contract.md` hunk
(`@@ -759 +759,11 @@`) adds the duty to §19, and the mirror landed at
`core/hooks/directive.sh` hunk `@@ -93,7 +93,15 @@`. Both are confirmed
live rather than merely committed: the `core` directive text injected
into **this** session at SessionStart carries the new paragraph verbatim
("When the comment you find is itself approval-shaped but fails this test
— a near-match or an affirmative-sounding comment, from a listed or
unlisted account — state that fact plainly once (not repeatedly), in your
reply or your record"). The cross-reference constraint is satisfied by
construction: the landed text refers to "any warn duty a spawning
orchestrator carries under its own rulebook" without naming
`on-the-record`'s `run.md:209-215`, so it cannot drift out of sync with
otr line numbers. Whether otr's own text agrees is **uncheckable from
this branch** — a different repository, out of scope by issue #116's own
`## 제약` — and is recorded as uncheckable rather than guessed.

**제약 1** (§22's body unchanged) — **met.** `f991220` touches
`core/contract/role-handoff-contract.md` in exactly one hunk, at line 759
(`git show f991220 --unified=0`), which sits inside §19: in the pre-image
`97f8ce6:core/contract/role-handoff-contract.md`, §20 begins at line 801
and §21 at line 836, so §22's body lies entirely below the edit and is
untouched.

**제약 2** (otr files out of scope) — **met.** `f991220 --stat` lists
eight paths, all under `core/`, `freelunch/`, `warrant/`, or `docs/`; no
`on-the-record` path appears.

## Level 2 — Trajectory: PASS

The phase-1→phase-2 path is sound on every element contract v3 §19
requires, and the ordering is verifiable from timestamps alone.

- **Survey before proposing, and scouting ran.** `97f8ce6 --stat` is
  docs-only, three files, +566/-0:
  `docs/issue-116/proposals/2026-08-04-approval-rule-gap-repairs.md`
  (240), `docs/issue-116/reports/implementation/survey.md` (250),
  `docs/issue-116/reports/implementation/scout-brief.md` (76). No rule
  text, no code, no record — the phase boundary held.
- **Real human approval, right form, right order.** The approval is the
  issue comment whose entire body is `APPROVE issue-116/implementation`,
  by `jjongkwann` (`MEMBER`, listed at `docs/specs/approvers.md:2`), at
  `2026-08-04T05:03:44Z`
  (https://github.com/tokenmaxxxer/tokenmaxxxer-core/issues/116#issuecomment-5174824813).
  PR #117's author is the same account, so single-account mode applies
  and the issue-comment path is the correct one. Ordering:
  phase-1 commit `04:54:03Z` → approval `05:03:44Z` → phase-2 commit
  `05:34:31Z` → merge `05:40:14Z`. No phase-2 byte predates the approval.
- **Scouting was not skipped and the pre-mortem was carried forward.**
  The proposal's `## Warrant hunt` records a phase-1 pre-mortem finding
  and a disposition that made non-spoofability a build-time constraint
  ("whichever exact signal phase 2 lands on must be harness-set, not
  conversation-writable, or this finding re-opens"). Phase 2 answered it
  in the landed inline comment rather than dropping it. That the answer
  is asserted rather than demonstrated is a step-level defect (Finding 2),
  not a trajectory one: the trajectory question is whether the pre-mortem
  was carried across the phase boundary, and it was.
- **Near-miss duty, discharged by this session.** Per the very §19 text
  `f991220` adds, this observing session states plainly, once: it
  encountered **no** approval-shaped near-miss. Issue #116 carries
  exactly two comments and both are exact-string canonical approvals
  (`APPROVE issue-116/implementation`,
  `APPROVE issue-116/execution-observation`); PR #117 and PR #121 carry
  zero PR reviews. There was nothing to surface.

## Level 3 — Step: two findings, neither blocking

Both findings are against the observed **record's evidence**, not against
what landed in the code. No landed behavior is wrong on the evidence
read. The proposal's six check points resolve as follows; the two that
became findings are written out in full under `## Open findings`.

**Check point 1 — the non-spoofability claim.** The claim is *asserted,
not demonstrated* (Finding 2). Of the four evidence lines the proposal
named, the record and inline comment support only the weakest: the value
was observed (`sdk-cli` headless, `cli` interactive) but no
who-can-set-it analysis is recorded anywhere in `f991220` or the
observed record. Against it: this repository commits no
`.claude/settings.json` and no JSON file containing an `env` block
(`git ls-files`; `git grep -ln '"env"' -- '*.json'` → no hits), so the
one documented channel my phase-1 scout brief identified — the settings
`env` key, which
`docs/issue-116/reports/execution-observation/scout-brief.md` records as
supplying "environment variables applied to every session and to
subprocesses Claude Code spawns from it"
(https://code.claude.com/docs/en/settings) — is not wired inside this
repository, though it remains a user-level surface outside it.

**Check point 2 — are the nine cases effective, not merely nine?**
**Yes, effective.** Judged as a reading standard against the landed
`f991220:freelunch/hooks/tests/run-observe-tests.sh`, never by executing
it:

- The decision predicate `entrypoint == "cli"` partitions into
  `cli` / known-non-`cli` / unknown-or-unset. All three are instantiated:
  `:62` (`cli` → deny), `:60` (`sdk-cli` → allow), `:64` (`""` → allow).
  Each would fail if the carve-out were inverted or removed.
- The two row assertions (`:68-73`, `:74-79`) are **not** tautological,
  contrary to the concern the proposal raised. `headless-violation-still-logged`
  asserts the log row contains `"sync_agent_dispatch"` *and*
  `"enforced": false`; it discriminates against the most plausible wrong
  implementation of the same requirement — suppressing the violation from
  `row["violations"]` itself rather than from the separate `enforceable`
  list `f991220` introduces — which would have silently destroyed the
  audit trail the requirement calls for.
- `non_sonnet_worker` is pinned across both session types (`:82-83`),
  which is what makes "the hook's original purpose is not weakened"
  testable rather than merely claimed.
- The `run-all.sh` wiring **does** propagate failure. The added line
  `/bin/bash ".../run-observe-tests.sh" | tail -2 || rc=1` is a pipeline,
  and the runner's pre-image already sets `set -uo pipefail`
  (`97f8ce6:core/hooks/tests/run-all.sh:3`, cited as pre-image precisely
  so pre-existing behavior is not credited to the observed role), so the
  script's non-zero exit survives the pipe to `tail` and reaches `|| rc=1`.

  Three surfaces `f991220` touched are **not** covered: the
  `FREELUNCH_ENFORCE`-unset observe-only path (every `run` invocation sets
  `FREELUNCH_ENFORCE=1`, `:48`), the `Workflow` tool branch (every payload
  uses `"tool_name":"Agent"`, `:46`) which now also receives the new
  `session_entrypoint` field, and the changed deny-reason text's own
  content (the `want deny` check matches only `permissionDecision":"deny"`,
  `:51`). These are recorded as named gaps, not elevated to findings:
  on the diff read, none of the three carries changed *behavior* —
  `enforce` being falsy short-circuits `bool(enforce and enforceable)`
  identically before and after, the `Workflow` branch's only delta is one
  added log field, and the reason text is user-facing prose.

**Check point 3 — outcome coverage.** Resolved under Level 1 above.

**Check point 4 — trajectory ordering and approval validity.** Resolved
under Level 2 above.

**Check point 5 — the three declared deviations.** **All three are
in-scope, and their disclosure is exemplary.** The header-comment fix
(record `:167-176`) corrects the identical false premise in the same file
already inside the frozen `files:` set
(`docs/issue-116/proposals/2026-08-04-approval-rule-gap-repairs.md:1`);
leaving it would have preserved at comment level the contradiction the
delivery removes at code level. The added `row["session_entrypoint"]`
field (record `:177-183`) is the direct implementation of item 1's own
"full audit trail preserved" commitment, not a new commitment. The new
file `docs/handbooks/freelunch-observe-tests.md` (record `:184-201`) is
outside the frozen `files:` list, but was forced by
`core/hooks/handbook-trigger-gate.sh` refusing the commit — a repo-wide
mechanical gate of the same tier as the `Subject:` trailer gate, which
binds regardless of what a proposal's `files:` line happens to name. The
record discloses that the gate matched `run-all.sh` on filename alone
(record `:150-155`), i.e. a false positive by the gate's own admitted
design, and complied rather than routing around it. That is the correct
call: satisfying a mechanical contract gate is not a discretionary scope
widening.

**Check point 6 — the hunt finding's disposition.** **Sound.** The
`## Hunt` FINDING (record `:220-261`) is that `freelunch/README.md:86`
still documents enforcement as unconditional. `freelunch/README.md` is
genuinely absent from the proposal's frozen `files:` line
(`docs/issue-116/proposals/2026-08-04-approval-rule-gap-repairs.md:1`),
so carrying it to `## Next steps` (record `:265-270`) rather than editing
it matches §19's write-set discipline, and `## Resolution path` (record
`:278-284`) correctly declines to raise it as a blocking finding against
another role. The residual risk is real and belongs in front of the
human: `main` now carries a documentation statement that contradicts its
own code until a follow-up proposal lands. That is a consequence of
correct scope discipline, not a defect in it.

The second `## Next steps` item (record `:271-275`) hands recurrence
detection of the new §19 near-miss duty to this step. It is discharged
only as far as artifacts allow: this session is the first role session
opened after §19 landed, it received the new duty live (quoted under
Requirement 3 above), and it applied the duty — finding nothing to
surface. That is n=1 and establishes the duty is *delivered*, not that
it *recurs*. Stated as such rather than claimed as verified.

## Open findings

### Finding 1 — the `scout`/`terse` audit tests for the remedy, not for the gap

- **Impact.** Low, and nothing wrong landed: the conclusion ("no s22 gap
  in `scout`/`terse`") is correct, independently confirmed above from the
  two directives' own text as emitted into this session. What is
  deficient is the recorded evidence for it. The audit as written is not
  safely repeatable: applied to a newly-added directive-emitting plugin
  that *does* carry an unconditional dispatch instruction, it would
  return "zero `s22` matches" and therefore "no gap" — the exact opposite
  of the truth, because absence of the string `s22` is the gap's
  signature, not its absence. Requirement 2 asked for an exhaustive audit
  of the sibling plugins; a future re-application is what makes that
  exhaustiveness durable.
- **Timeline.** The approved proposal's checklist specified a combined
  `rg -n "s22|contract v3"` pattern. At build time that pattern produced
  two hits in `scout/hooks/directive.sh` that turned out to be unrelated
  `contract v3 s19` references. The record narrowed the pattern to `s22`
  alone, got zero matches in `scout/hooks/directive.sh` and
  `terse/hooks/terse.sh`, and recorded the inference "so no s22 gap
  exists there" (`docs/issue-116/reports/implementation.md:298-300`).
  Landed in `f991220`.
- **Root cause.** The search predicate tests for the presence of the
  *remedy* (the string `s22`) instead of the presence of the *condition
  the remedy fixes* (an unconditional delegate-and-do-not-wait
  instruction). The narrowing was a correct fix to a false-positive
  problem, and it silently inverted the test's meaning while fixing it.
- **Action item** (for the human to judge — this role files no issue).
  If the sibling-plugin audit is meant to be re-run when a new
  directive-emitting plugin lands, the repeatable predicate is: grep each
  directive-emitting hook for unconditional dispatch language
  (`dispatch`/`background`/`never wait`), then check each hit for an
  adjacent §22 subordination note. Recording that predicate next to the
  conclusion would make requirement 2's "전수 확인" durable rather than
  point-in-time.

### Finding 2 — "not conversation-writable" is asserted, and its own proposal made it binding

- **Impact.** Low and self-limiting, but the claim is stronger than its
  evidence. Even if `CLAUDE_CODE_ENTRYPOINT` were reachable from a
  session's own configuration surfaces, the bypass it would buy is
  strictly dominated by one that already exists through the same channel:
  `observe.sh` reads both its kill switch and its enforcement flag from
  the same inherited environment
  (`f991220:freelunch/hooks/observe.sh:26` `FREELUNCH_OFF`, `:38` and
  `:42` `FREELUNCH_ENFORCE`), so anything able to set the entrypoint
  variable could set `FREELUNCH_OFF=1` and disable the hook outright.
  The carve-out therefore adds **no new bypass surface** — which is why
  this is a wording-and-evidence defect rather than a security defect.
- **Timeline.** The phase-1 proposal's `## Warrant hunt` disposition made
  the property a build-time constraint: "whichever exact signal phase 2
  lands on must be harness-set, not conversation-writable, or this
  finding re-opens". `f991220`'s inline comment in `observe.sh` and the
  record at `docs/issue-116/reports/implementation.md:31-34` then state
  the property flatly ("not conversation-writable"). Neither names a
  channel enumeration, and the observed value set (`sdk-cli` vs `cli`) is
  the only evidence offered.
- **Root cause.** The disposition set a verification *obligation* without
  a verification *method*, so "harness-set" was discharged by observing
  the variable's value rather than by analysing who can set it across the
  process ancestry. My phase-1 scout brief records the check that would
  have closed it — the settings `env` key applies environment variables
  to subprocesses Claude Code spawns
  (`docs/issue-116/reports/execution-observation/scout-brief.md`,
  https://code.claude.com/docs/en/settings) — and this session confirms
  that channel is not wired inside this repository (`git ls-files`;
  `git grep -ln '"env"' -- '*.json'` → no hits), leaving it a user-level
  surface outside the repo's control.
- **Action item** (for the human to judge). Either record the channel
  list the claim was checked against, or — better, and what the evidence
  actually supports — restate the design's justification as the
  dominated-bypass argument above: the signal does not need to be
  unspoofable, because spoofing it is strictly weaker than the
  pre-existing `FREELUNCH_OFF` bypass through the identical channel. As
  worded today, the pre-mortem's own re-open condition is arguably
  unmet on the record's evidence.

## Next steps

- The two findings above are for the human to judge on PR #121. Under
  contract v3 this role files no issue; if either warrants one, the human
  files it.
- Recurrence detection for §19's new near-miss duty is established at
  n=1 only (this session). A later role session encountering an actual
  near-miss comment is what would confirm the duty fires; nothing in this
  branch can produce that evidence.
- `freelunch/README.md:86`'s contradiction with the landed carve-out
  remains open on `main`, correctly carried by the observed role to its
  own `## Next steps` (record `:265-270`). It is another role's write
  surface and is not touched here.

## Resolution path

No blocking finding is raised against the observed role's record, and
nothing in PR #117 is judged to require reversal. Both findings are
evidence-quality defects in
`docs/issue-116/reports/implementation.md`, a file this role must not
edit; they resolve — if the human judges them worth resolving — through a
separately-filed, human-authored issue and a future proposal, not through
any edit from this branch. This record and PR #121 are where they are
handed over.
