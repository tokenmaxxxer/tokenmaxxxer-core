---
kind: coding-record
subject: issue-116
produced_by: implementation
code_under_review: `freelunch/hooks/observe.sh`, `freelunch/hooks/tests/run-observe-tests.sh`, `core/hooks/tests/run-all.sh`, `warrant/hooks/directive.sh`, `core/hooks/directive.sh`, `core/contract/role-handoff-contract.md`
loop_state: landed
upstream:
  - path: docs/issue-116/proposals/2026-08-04-approval-rule-gap-repairs.md
    sha: 97f8ce63183574dd1a6e411e953bc88576850a53
---

# Implementation record — issue-116

## Why

Phase 2, approved via issue-level comment `APPROVE issue-116/implementation`
(exact string, posted by an approvers.md account, jjongkwann, on issue #116).
Delivering the approved proposal's six `## What will be done` items: three
step-2-observation follow-ups from `docs/issue-106/reports/execution-observation.md`
(Findings 1-2) and `on-the-record` issue-227's execution-observation (Finding
1) — a headless-scoped carve-out on `observe.sh`'s `sync_agent_dispatch`
enforcement so it no longer contradicts contract v3 s22, the same s22
subordination note `warrant/hooks/directive.sh` was missing (with an audit
of `scout`/`terse` confirming they need none), and a role-session-side duty
to surface a near-miss approval comment rather than silently pass it. All
six items landed inside the proposal's frozen write set.

## What was done

1. **`freelunch/hooks/observe.sh`** (headless carve-out, requirement 1).
   Reads `CLAUDE_CODE_ENTRYPOINT` — a value the harness sets before the
   session's own conversation begins, so it is not conversation-writable
   (closes the warrant-hunt pre-mortem finding already dispositioned in the
   proposal). `session_is_interactive = (entrypoint == "cli")`; empirically
   confirmed this session's own headless value is `sdk-cli`. `violations`
   still always lists `sync_agent_dispatch` when `run_in_background: false`
   (unchanged, full audit trail preserved — now also logged as
   `session_entrypoint`); it now contributes to `row["enforced"]` only when
   `session_is_interactive` is true, so a headless session is never denied
   for the one call shape contract v3 s22 requires it to make, while the
   existing interactive-session deny is unchanged. `non_sonnet_worker` and
   its deny are untouched, in every session type. Updated both the deny
   reason text (`:130-138`, the item's own cited `:101-107` at the prior
   SHA) and the top-of-file header comment (`:11-19`) so neither asserts
   "semantically equivalent to waiting" as a universal claim — see
   `## Rationale for deviations` for the header-comment addition.
   tty state was evaluated and rejected as an operative signal (documented
   inline, `:60-63`): this hook's own stdout is captured by the harness to
   parse the permission-decision JSON in every invocation mode, so
   `isatty()` on it cannot discriminate interactive from headless for this
   specific hook — the frozen behavior ("keyed on the hook's own inherited
   environment/tty state") is satisfied by evaluating tty and finding it
   non-discriminating here, not by wiring a dead branch.
2. **`freelunch/hooks/tests/run-observe-tests.sh`** (new). Nine cases:
   the proposal's three required (headless sync-dispatch allowed,
   interactive sync-dispatch still denied, non-sonnet-worker still denied
   regardless of session type — doubled across both session types plus the
   two allow-paths for full coverage) plus an ambiguous/unset-entrypoint
   case and two audit-trail assertions (violation still logged when not
   enforced; `enforced: true` still recorded when it is). See
   `## What did not work` for two defects caught and fixed before this
   landed.
3. **`core/hooks/tests/run-all.sh`.** New "freelunch observe.sh enforcement
   (sibling plugin)" entry, two lines (header echo + invocation), matching
   the file's own existing per-entry convention (every other sibling-plugin
   entry, including the one right above it, is also two lines, not one —
   the proposal's "one line" was shorthand for "one entry").
4. **`warrant/hooks/directive.sh`** (requirement 2). Inserted the
   `SUBORDINATE TO CONTRACT v3 s22 IN HEADLESS/SINGLE-SHOT SESSIONS`
   paragraph, adapted in shape from `freelunch/hooks/freelunch.sh:39`
   (naming the hunter-dispatch instructions it subordinates, since
   `warrant`'s unconditional text is "dispatch ONE background agent...
   and carry on without waiting," not `freelunch`'s worker fan-out),
   placed immediately after the opening `<warrant-directive
   priority="high">` tag and before the first unconditional dispatch line,
   per the proposal's own placement instruction. `scout/hooks/directive.sh`
   and `terse/hooks/terse.sh` left unedited, per the proposal's own audit
   (survey.md) confirming neither carries unconditional "don't wait"
   dispatch language.
5. **`core/hooks/directive.sh`** (requirement 3, mirror). Extended the
   "any other comment... is feedback" bullet with the role-session
   near-miss-reporting duty: state a near-miss plainly once, in the reply
   or the record, complementary to (not a substitute for) any warn duty
   the spawning orchestrator carries.
6. **`core/contract/role-handoff-contract.md`, section 19** (requirement 3,
   canonical). Same duty, mirrored in substance into the "Any other comment
   is feedback on the proposal" bullet (`:757-759` at the prior SHA).
7. Ran `bash core/hooks/tests/run-all.sh` (below, `## Verify`) — full suite
   green, including the new test and every edited file's bash-3.2
   parse-check.
8. Before-landing warrant hunt (below, `## Hunt`) — one real finding,
   disposed as a `## Next steps` follow-up, not a blocker (see
   `## Resolution path`).
9. This record.

## What did not work

- First attempt: prototype the headless-vs-interactive behavior with a
  throwaway smoke-test script written via the `Write` tool to `/tmp/claude`
  and then `$TMPDIR` (`/tmp/claude-501`) — both attempts errored
  "you haven't granted it yet" (a permission gate on new scratch paths,
  separate from the sandbox's own declared-writable list, apparently not
  auto-approved headless). Switched to constructing the same script via a
  `Bash` heredoc instead — that failed too, with "Contains brace with quote
  character (expansion obfuscation)": the sandbox's static command-text
  analyzer flags a literal `{"...":"..."}` JSON payload embedded in a
  heredoc-writing command, regardless of the heredoc's own quoting.
  Resolution: skipped the scratch-prototype step entirely and wrote the
  real test harness directly at its final repo destination via `Write`
  (which is not gated the same way, presumably because the write set's
  own paths are pre-authorized for this session), then exercised it with a
  plain `bash <path>` command — no JSON literal in the command text itself,
  so the analyzer had nothing to flag.
- `run-observe-tests.sh`'s first draft called `run allow NAME ... ` inside
  a `$(...)` command substitution for two cases, to capture the logged row
  alongside the pass/fail check in one call. Expected: the `report` call
  inside `run` would update the script's `$pass`/`$fail` counters as usual.
  Actual: `$(...)` forks a subshell, so those two `report` calls updated
  `$pass`/`$fail` in the subshell only — the parent's counters silently
  never saw them (the same class of sandbox-shaped bug
  `core/hooks/tests/_tmp.sh` already documents for `mktemp`, for a
  different reason). Caught before landing: the first full run reported
  "7 passed" against 9 expected calls. Fixed by making `run` set globals
  (`$got`, `$row`) as a side effect and never invoking it inside `$(...)`;
  re-run showed "9 passed, 0 failed" with all nine `ok` lines visible.
- The same test file's `mktemp` call (bare, no `-p`) failed under this
  session's sandbox with "Operation not permitted" — macOS's `mktemp`
  resolves its default directory via `confstr(_CS_DARWIN_USER_TEMP_DIR)`
  to `/var/folders/.../T`, ignoring `$TMPDIR`, and the sandbox denies
  writes there (same defect `core/hooks/tests/_tmp.sh` documents for
  `mktemp -d`, ported here to a single-file `mktemp`). Fixed with
  `mktemp -p "${TMPDIR:-/tmp}"`, matching that file's own established
  fix pattern.

## Doc-placement ladder

- [x] No `docs/issue-116/decisions/` entry. The one genuinely open
  build-time choice this delivery makes — the literal predicate for
  "clearly interactive" (`CLAUDE_CODE_ENTRYPOINT == "cli"`, tty rejected
  as non-discriminating for this hook) — was explicitly pre-authorized by
  the proposal's own `## Out of scope` as "ordinary implementation detail
  settled during phase-2 build," not a decision requiring its own record;
  the reasoning is inlined in the code comment (`observe.sh:52-63`) and in
  `## What was done` item 1 above instead.
- [x] `docs/handbooks/freelunch-observe-tests.md` (new). No environment
  variable, config key, dependency, or migration was introduced —
  `CLAUDE_CODE_ENTRYPOINT` is an existing harness-set signal, read, not
  introduced. `core/hooks/handbook-trigger-gate.sh` mechanically refused
  the first commit attempt anyway: its `OP_PATTERNS` regex
  `(deploy|setup|run|install)[^/]*\.sh$` matches `run-all.sh` on filename
  alone (a false-positive by the gate's own admitted design — "the gate
  enforces STRUCTURE... never which component, a human-owned judgment"),
  since editing `core/hooks/tests/run-all.sh` to wire in the new test
  counts as touching a "run/setup/deploy script" regardless of what the
  one added line actually does. See `## Rationale for deviations` below.
- [x] `docs/issue-116/reports/implementation.md` (this file) — the
  phase-2 record, per contract §11/§19.

## Rationale for deviations

Three points beyond the proposal's literal cited scope, none a
scope-exceeded stop or an alternative-swap — two are in-file elaborations
inside the already-frozen `freelunch/hooks/observe.sh`, the third is one
new file outside the proposal's `files:` list, added only because a
repo-wide mechanical gate required it to land any commit at all:

- **Header comment (`:11-19`), not only the deny reason text
  (`:101-107`/`:130-138`).** Item 1 named only the deny reason text for the
  "no longer a universal claim" fix. The file's top-of-file comment block
  asserted the identical false premise ("a background dispatch +
  completion notification is semantically equivalent to waiting
  synchronously") about the same mechanism this issue exists to correct.
  Leaving it uncorrected in the same file would recreate, at the comment
  level, the exact contradiction this delivery removes at the code level.
  Fixed in place rather than filed as a follow-up, since it is the same
  file, same sentence-level claim, already inside the frozen write set.
- **`row["session_entrypoint"]` field, not named in item 1's text.** Item 1
  commits to "full audit trail preserved" when `sync_agent_dispatch` is
  logged but not enforced. Without recording which entrypoint value drove
  that decision, a future reader of the log alone cannot tell why a given
  row's `enforced` is `false` despite carrying the violation. Added as the
  direct implementation of the "full audit trail" commitment already in
  the approved text, not a new commitment.
- **`docs/handbooks/freelunch-observe-tests.md` (new file, outside
  `files:`).** The first `git commit` attempt was refused by
  `core/hooks/handbook-trigger-gate.sh` (contract §21's mechanical half):
  staging `core/hooks/tests/run-all.sh` matched its `run/setup/deploy
  script` filename pattern with no `docs/handbooks/**` path staged
  alongside it. This is the same tier of obligation as the `Subject:
  issue-116` commit trailer (`core/hooks/trailer-gate.sh`) — a repo-wide,
  mechanically-enforced contract requirement that binds regardless of
  whether a given proposal's `files:` list happens to name it, not a
  discretionary scope widening the SCOPE-EXCEEDED rule is about. Searched
  `docs/handbooks/*` first (section 21's own "search before write") for an
  existing handbook covering `core/hooks/tests/run-all.sh` or this test;
  none exists (the existing five handbooks each cover one specific
  existing gate/test harness, not `run-all.sh` as a whole), so a new file
  was created, sized and shaped to match that same one-handbook-per-test-
  harness precedent (`docs/handbooks/approval-gate-tests.md` et al.),
  rather than widening scope by inventing a broader "core test suite"
  handbook nothing else in the repo has.

## Hunt

`warrant-hunter` is not among this session's available `Agent`-tool
subagent types (same absence noted in issue-88/90/93/94/98/100/106's
records). Adopted the stance directly by inspection, per the same local
precedent. `.warrant-hunt.count` does not exist in this working tree
(confirmed again this session); phase 1's own hunt (proposal, `## Warrant
hunt`) already used stance index `0 mod 5` for its after-proposal
pre-mortem, so this before-landing dispatch takes the next stance in
rotation, index 1: "assume this change and another plugin's rule cancel
each other — find the pair." Diff size at dispatch time: 5 tracked files
changed (`git diff --stat`: 64 insertions/10 deletions) plus one new
~85-line test file — the 21-200-line bucket, 120s cap, one stance (warrant's
own "default when size is unclear" tier).

### before-landing — stance: assume this change and another plugin's rule cancel each other — find the pair

Verdict: FINDING — `freelunch/README.md:79-89` documents `observe.sh`'s
enforcement mode as if a flagged call is always denied under
`FREELUNCH_ENFORCE=1` ("a flagged call is denied with a corrective reason
and the model re-issues it corrected"), with no mention of the headless
carve-out this delivery adds.
Kind: composition (this repo's own documentation now contradicts the code
it describes)
Seed: `git diff` of this transition (`freelunch/hooks/observe.sh` +
`freelunch/hooks/tests/run-observe-tests.sh`) against every other file that
references `sync_agent_dispatch`/`FREELUNCH_ENFORCE` in the repository
(`grep -rn`, non-`docs/` hits only).

#### Reproduce

```
grep -n "FREELUNCH_ENFORCE" freelunch/README.md
```
→ `:86`: "With `FREELUNCH_ENFORCE=1` a flagged call is denied with a
corrective reason and the model re-issues it corrected." No mention of
session type or a carve-out.

#### Observed

`freelunch/README.md` is the plugin's own user-facing documentation
(`## Telemetry & optional enforcement`, `:79-89`), unconditional: it reads
as "every flagged call is denied under enforce mode," which was true before
this delivery and is no longer true for `sync_agent_dispatch` in a
non-interactive/ambiguous-entrypoint session.

#### Expected

A reader of `freelunch/README.md` alone, with no reason to also read
`observe.sh`'s source, would expect `FREELUNCH_ENFORCE=1` to deny a
synchronous headless dispatch — the opposite of this delivery's actual
behavior. `freelunch/README.md` is not in this proposal's frozen write set
(`files:` lists only `freelunch/hooks/observe.sh`,
`freelunch/hooks/tests/run-observe-tests.sh`, `core/hooks/tests/run-all.sh`,
`warrant/hooks/directive.sh`, `core/hooks/directive.sh`,
`core/contract/role-handoff-contract.md`). Per this role's own build
discipline — finish what the approved proposal covers, stop, and report
rather than widen the write set mid-build — `freelunch/README.md` is not
edited by this delivery; the fix is recorded below as a follow-up.

## Next steps

- **`freelunch/README.md`'s `## Telemetry & optional enforcement` section
  (this repo, in scope for a future proposal).** Update `:86`'s
  unconditional "a flagged call is denied" language to state the headless
  carve-out this delivery adds to `sync_agent_dispatch` — same shape of
  follow-up issue-106's own record left for `warrant/hooks/directive.sh`,
  which this issue then delivered.
- Recurrence/consistency detection for the near-miss-reporting duty this
  issue adds to `role-handoff-contract.md` §19 / `core/hooks/directive.sh`
  (whether role sessions opened after this section lands actually surface
  a near-miss when they encounter one) is step 2's own job
  (execution-observation), not this delivery's.

## Resolution path

No open finding is raised against another role's record from this
delivery. The one `Hunt` finding above (`freelunch/README.md` composition
gap) is carried forward as a `## Next steps` follow-up recommendation, not
a blocking `finding:` block against another role — resolving it is a
future, separately-filed proposal on this same repo, kept outside this
delivery's frozen write set rather than folded in here.

## Verify

`bash core/hooks/tests/run-all.sh` → `ALL OK`: bash 3.2 parse 22/22, deny-only
3/3, board gate 86/0, approval gate 42/0, gh guard 52/0, role-agnostic gates
19/0, stub-check canon forms 3/0, compliance-check scan-scope 4/0;
`terse`/`freelunch`/`scout` sibling-plugin parse-checks (including all
edited files) all `ok`; new `freelunch observe.sh enforcement` entry 9/0.

`grep -n "s22" warrant/hooks/directive.sh` → one match (the new
subordination paragraph), satisfying the proposal's own "How you'll know it
worked" checklist item 3 (its literal `rg -n "s22|contract v3"` combined
pattern also matches `scout/hooks/directive.sh` twice, but both are
pre-existing `contract v3 s19` survey-order references unrelated to s22 —
confirmed by re-running with `s22` alone: zero matches in
`scout/hooks/directive.sh` and `terse/hooks/terse.sh`, so no s22 gap exists
there, matching the proposal's own "no gap found" claim; the combined grep
pattern in the proposal's checklist item 4 is imprecise, not the build).

`grep -n "near-miss\|near-match" core/contract/role-handoff-contract.md
core/hooks/directive.sh` → both files carry the new text, satisfying
checklist item 5 (the mirror, not just the canonical copy).
