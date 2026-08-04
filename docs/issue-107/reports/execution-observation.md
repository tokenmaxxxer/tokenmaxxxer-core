---
kind: observation-record
subject: issue-107
produced_by: execution-observation
observed_role: implementation
observed_pr: 108
loop_state: landed
upstream:
  - path: docs/issue-107/reports/execution-observation/survey.md
    sha: 2b769e6
  - path: docs/issue-107/reports/execution-observation/scout-brief.md
    sha: 2b769e6
  - path: docs/issue-107/proposals/2026-08-04-independent-observation-of-pr-108.md
    sha: 2b769e6
---

# Execution observation — issue-107, step 2

## Independence

This role did not author, edit, or execute the artifact it judges below. The
observed work is the `implementation` role's session on branch
`issue-107/implementation`, delivered as PR #108 and merged as `f6d6983`; this
session's entire write surface is
`docs/issue-107/reports/execution-observation.md` and
`docs/issue-107/reports/execution-observation/`. Nothing under `core/`,
`test/`, or `docs/issue-107/reports/implementation*` was touched this session,
and no test suite, hook, or gate was run. Every statement below rests on
artifacts read in this session — commit diffs, blobs at named commits, the
observed role's own documents, and GitHub artifacts — never on a re-execution
of the observed task. Verdict language begins only after this section.

## Why

Issue #107's `## 실행 계획` lists two steps; step 2 is `execution-observation`.
Phase 2 opened on the issue-level comment whose entire body is
`APPROVE issue-107/execution-observation`, posted by `jjongkwann` — an account
listed in `docs/specs/approvers.md:2` — at `2026-08-04T02:40:35Z`
(comment id `5173982041`, read this session via
`gh api repos/tokenmaxxxer/tokenmaxxxer-core/issues/107/comments`). The checks
adjudicated here were fixed in advance by
`docs/issue-107/proposals/2026-08-04-independent-observation-of-pr-108.md`
(committed `2b769e6`, carried on PR #112) and are answered below in that
document's own order.

## What was done

Read this session (each item was opened in this session; none is a secondhand
summary):

- `gh issue view 107` (full body: 3 requirements, 2 constraints, 실행 계획) and
  `gh issue view 107 --comments`; `gh api …/issues/107/comments` for the two
  approval comments' authors, ids, and timestamps.
- `gh pr view 108` — `state: MERGED`, `author: jjongkwann`, `reviewers:` empty,
  `additions: 633 / deletions: 1`; `gh pr list --state all` for PR #108's and
  PR #112's creation times.
- `git show --stat 67eb71e`, `git show --stat ace7dda`, and `git show ace7dda`
  restricted to `core/hooks/board-gate.sh`, `core/hooks/lib/gate-lib.py`,
  `core/hooks/tests/run-board-gate-tests.sh`, `docs/handbooks/board-gate-tests.md`.
- Blobs at named commits: `ace7dda:core/hooks/lib/gate-lib.py`,
  `ace7dda:core/hooks/board-gate.sh`, `ace7dda~1:core/hooks/board-gate.sh`,
  `ace7dda:core/hooks/tests/run-board-gate-tests.sh`,
  `ace7dda~1:core/hooks/tests/run-board-gate-tests.sh`,
  `ace7dda:core/hooks/gh-guard.sh`, `ace7dda:core/hooks/handbook-trigger-gate.sh`.
- The observed role's own documents: `docs/issue-107/reports/implementation.md`
  (223 lines), `docs/issue-107/proposals/2026-08-03-fix-board-gate-wrapper-cd-argument-extraction.md`,
  `docs/issue-107/reports/implementation/survey.md`.
- `docs/issue-99/reports/execution-observation.md:405-430` (the upstream
  Finding 1 this issue formalizes) and
  `core/contract/role-handoff-contract.md:845-905` (section 21).

**Not run, deliberately:** `run-board-gate-tests.sh`, `run-gate-lib-tests.sh`,
`run-gh-guard-tests.sh`, `handbook-trigger-gate.sh`, and the live gate on any
probe command. **Not read as evidence:** the working-tree state of
`core/hooks/**`, which shows what exists now rather than what the observed
session did; every code fact below is read at `ace7dda` or `ace7dda~1`.

## Verdict 1 — outcome

**PASS.** PR #108 landed what issue #107 asked, requirement by requirement.

**Requirement 1 (unify wrapper-prefixed `cd` argument extraction with head
detection's command-start model): met.** The `ace7dda` diff for
`core/hooks/board-gate.sh` replaces `_cd_target`'s single line
`for w in stripped.split()[1:]:` with `for w in gate_lib.gate_trailing_words(stripped):`,
and the same commit's `core/hooks/lib/gate-lib.py` hunk adds
`gate_trailing_words(segment)` returning `_resolve_transparent(segment)[1]`
(`ace7dda:core/hooks/lib/gate-lib.py:248-259`). `gate_head_of` is
`_resolve_transparent(segment)[0]` at `ace7dda:core/hooks/lib/gate-lib.py:245`,
and it is the function the walk calls one line above the `_cd_target` call to
decide the segment IS a `cd` (`ace7dda:core/hooks/board-gate.sh:333-334`). Both
halves of the question now read the same tuple from the same walk, which is
exactly the minimal design issue #107 requirement 1 named. Reading
`_resolve_transparent` at `ace7dda:core/hooks/lib/gate-lib.py:203-235`, its
loop stops at the first non-`TRANSPARENT` word and returns `words[1:]` from
that point, with `TRANSPARENT_TAKES_ARG` skipping `timeout`'s duration
(`:222,229-232`) — so for `timeout 30 cd docs/issue-49` the trailing words are
`["docs/issue-49"]`, not `["30", "cd", …]`.

**Requirement 2 (regression cases covering the `timeout` shape plus one pre-#98
wrapper, with a red→green record): met, with the red half at assertion tier.**
`ace7dda:core/hooks/tests/run-board-gate-tests.sh` adds exactly two `run deny`
rows next to the existing `bash-cd-*-foreign` block:
`bash-wrapper-timeout-cd-relative-foreign` (`timeout 30 cd docs/issue-49 && date > x.md`)
and `bash-wrapper-command-cd-relative-foreign` (`command cd docs/issue-49 && date > x.md`),
above a six-line comment naming the root cause — `command` is one of the two
pre-#98 wrappers issue #107 requirement 2 permitted (`command` 또는 `env`). The
red→green claim itself (`docs/issue-107/reports/implementation.md:152-171`:
`84 passed, 2 failed` pre-fix, `86 passed, 0 failed` post-fix) is a claim about
executions this role may not reproduce; it sits at the **assertion tier**. The
static cross-check available is the case tally, measured this session by
counting the file's own helper invocations at both blobs: `ace7dda~1` → 82
prefixed + 2 bare (`noremote`, `fastpath`) = **84**; `ace7dda` → 84 + 2 = **86**.
The record's stated counts are exactly the tally the artifacts support, so the
assertion is internally consistent with the diff — corroborated, not
reperformed.

**Requirement 3 (no unreachable branch; existing negative space intact): met.**
The `ace7dda` `_cd_target` hunk changes the iteration *source* only; the
function's control flow (`if not w.startswith("-"): return w` / `return ""`) is
byte-identical to `ace7dda~1`, so no branch was added that could be unreachable.
Both named negative-space rows survive at `ace7dda:core/hooks/tests/run-board-gate-tests.sh:251`
(`run allow bash-cd-then-cat`) and `:269`
(`run allow bash-unresolved-head-then-read`), unmodified by the diff. Statically,
a bare `cd docs/… ` resolves in `_resolve_transparent` on its first iteration
(`words[0]` is `cd`, not in `TRANSPARENT`, → `return w, words[1:]`,
`ace7dda:core/hooks/lib/gate-lib.py:218-221`), so `gate_trailing_words` returns
precisely what `split()[1:]` returned for every non-wrapped `cd` — the bare-`cd`
cases cannot change verdict. Whether they in fact passed is the record's
assertion (`implementation.md:162-171`), tier-labelled as such.

**Constraints (`cd_tail` and dead-fallback untouched; `TRANSPARENT` tuple
untouched): met.** `git show --stat ace7dda` reports `board-gate.sh` at `+6/-1`
and `gate-lib.py` at `+15/-0`, and the full diff for those two files contains
exactly one hunk each — the `_cd_target` docstring+line change and the appended
`gate_trailing_words`. `TRANSPARENT` / `TRANSPARENT_TAKES_ARG` sit at
`ace7dda:core/hooks/lib/gate-lib.py:194-200` with no hunk touching them, and
the `cd_tail` walk at `ace7dda:core/hooks/board-gate.sh:330-338` is identical to
`ace7dda~1:core/hooks/board-gate.sh:326-334` modulo the four-line offset.

## Verdict 2 — trajectory

**PASS.** The phase-1 → phase-2 path is sound on every leg that left an
artifact.

**Phase separation: clean.** `git show --stat 67eb71e` is documents only —
`docs/issue-107/proposals/2026-08-03-…md` (+185) and
`docs/issue-107/reports/implementation/survey.md` (+176), 361 insertions, no
code — and its message says "Phase 1 only: survey + proposal … No code
changed." All code lands in `ace7dda`.

**Survey before proposal: satisfied.** Both phase-1 homes are present in the
same commit `67eb71e`, and the proposal's frontmatter names the survey as its
`upstream:` (`docs/issue-107/proposals/2026-08-03-fix-board-gate-wrapper-cd-argument-extraction.md:6-8`),
with the proposal's `## Rationale` resolving the survey's own open question
(`implementation/survey.md:170-172`, "Which of the two accessor shapes above to
pick").

**Approval: real, correctly-pathed, and ordered before delivery.** PR #108's
author is `jjongkwann` and it carries no PR-level review (`gh pr view 108`:
`reviewers:` empty) — so two-account mode was unavailable and contract v3 s19's
single-account path governs. That path was satisfied exactly: an issue-level
comment whose entire body is the string `APPROVE issue-107/implementation`,
posted by `jjongkwann`, listed at `docs/specs/approvers.md:2`, comment id
`5173547264` at `2026-08-04T01:29:46Z`. Ordering, all read this session:
`67eb71e` at `2026-08-03T12:34:09Z` → PR #108 created `2026-08-03T12:35:37Z` →
approval `2026-08-04T01:29:46Z` → delivery `ace7dda` at `2026-08-04T01:37:57Z`
(8m11s after the approval) → merge `f6d6983` at `2026-08-04T02:03:46Z`. No
phase-2 write precedes the approval. This closes survey **U1** and **U4**: the
timestamp unavailable to the phase-1 session was retrievable this session
through `gh api …/issues/107/comments`, and the record's own citation of
`issuecomment-5173547264` (`implementation.md:16-18`) is accurate.

**Scouting: properly skipped, with the record the directive requires.** The
observed session recorded the skip in both phase-1 homes —
`docs/issue-107/reports/implementation/survey.md:160-168` and
`docs/issue-107/proposals/2026-08-03-fix-board-gate-wrapper-cd-argument-extraction.md:35-41`
— citing the pure-bugfix condition and the fact that issue #107 itself fixes
the direction. That is one of the directive's two permitted skip conditions and
the reason is stated in one sentence, as required.

**Deviation handling: disclosed, not absorbed silently.** The delivery touched
one file outside the proposal's frozen `files:` line
(`…-fix-board-gate-wrapper-cd-argument-extraction.md:11`, three paths, no
handbook), and the record declares it in a dedicated
`## Rationale for deviations` (`implementation.md:57-79`) rather than leaving
the reader to find it in the diff. Adjudication of the deviation itself is
Verdict 3, candidate 1.

## Verdict 3 — step

Five candidates were committed to in the observation plan
(`docs/issue-107/proposals/2026-08-04-independent-observation-of-pr-108.md:71-110`).
Two produce findings; three are clean.

**Candidate 1 — the handbook deviation: justified, minimally scoped, correctly
recorded. No deficiency.** Adjudicated on the plan's three sub-questions:

- *(a) Did the in-force gate mechanically compel a handbook touch for this
  staged set?* **Yes.** `ace7dda:core/hooks/handbook-trigger-gate.sh:103` carries
  `(re.compile(r'(^|/)(deploy|setup|run|install)[^/]*\.sh$'), "run/setup/deploy script")`,
  which `core/hooks/tests/run-board-gate-tests.sh` matches on its basename;
  `:113-114` exits 0 only when `op_hits` is empty, `:116-118` exits 0 when any
  staged path matches `^docs/handbooks/.+`, and `:120-125` denies otherwise. With
  the proposal's three-path write set staged and no handbook, the gate's own
  text yields deny. The gate read here is the one in force at `ace7dda`: its last
  change is `52bdc15`, an ancestor of `ace7dda` (`git merge-base --is-ancestor`,
  established in the phase-1 survey at
  `docs/issue-107/reports/execution-observation/survey.md:53-57`).
- *(b) Does §21's substantive text independently require one?* **No — and this
  is the honest answer, not a criticism of the delivery.**
  `core/contract/role-handoff-contract.md:855-860` states the trigger as "an
  environment variable, a config key, a dependency, a migration, or a
  run/setup/deploy step in the target project"; a test-runner harness is none of
  those, which is exactly what the proposal's `## Out of scope`
  (`…-fix-board-gate-wrapper-cd-argument-extraction.md:152-157`) concluded. The
  gate's filename regex is deliberately broader than the spec's substantive
  list — its own header calls the derivation "Conservative" — so the gate and
  the spec do not cover the same set for this file. This resolves survey **U5**:
  the mechanical gate governed the commit, the substantive spec did not
  independently demand the write, and the two do not contradict because the
  gate enforces structure while §21 states intent. Notably, the delivery did
  the thing a broad-pattern gate hit calls for: it recorded the reason at the
  point of occurrence (`implementation.md:57-79`) instead of treating the
  pattern match as self-justifying compliance.
- *(c) Was the write scoped to the gate's minimum?* **Yes.** The `ace7dda` diff
  for `docs/handbooks/board-gate-tests.md` is a single appended 21-line
  paragraph, matching the file's established per-issue-paragraph shape, and its
  content is confined to this issue's root cause, the `gate_trailing_words` fix,
  and the two pinning case names. Nothing unrelated rides along. The file choice
  also satisfies §21's "Search before write"
  (`role-handoff-contract.md:876-882`): an existing handbook covering exactly
  this surface was updated in place rather than a new `<component>` slug minted.

**Candidate 2 — sibling call site of the same defect class: FINDING 1 (below).**
The same index assumption survives at exactly one site in the delivered tree.
Swept this session across all three hook files at `ace7dda`
(`grep -n "split()\["` on `board-gate.sh`, `lib/gate-lib.py`, `gh-guard.sh`):
one hit, `ace7dda:core/hooks/board-gate.sh:195` — `_git_subcommand`'s
`words = segment.split()[1:]`, reached at `:214-216` where the head has already
been resolved through `gate_lib.gate_head_of`. That is structurally the same
two-model seam the fix removed from `_cd_target`, and
`docs/issue-99/reports/execution-observation.md:418-422` named it in advance
("the surrounding docstring even cites `_git_subcommand` as the idiom being
reused, and that function shares the same index assumption"). Its failure
direction is the opposite one: for `timeout 30 git status`, `gate_head_of`
returns `git` while `_git_subcommand` reads `"30"`, and `"30" not in
GIT_READ_SUBCOMMANDS` evaluates true (`ace7dda:core/hooks/board-gate.sh:216`),
so the segment is classified as a write — fail-closed, which
`_git_subcommand`'s own docstring names as "the safe direction, not a new hole"
(`ace7dda:core/hooks/board-gate.sh:190-193`). **No live bypass exists here, and
leaving the code unchanged was correct** — issue #107 requirement 1 is scoped to
`cd`. The finding is about the scope statement, not the code.

**Candidate 3 — the red-green claim's evidence tier: clean, tier-labelled.**
Handled in Verdict 1 requirement 2: the record's counts (84/2 red, 86/0 green,
`implementation.md:152-171`) match the case tally this session measured from the
two blobs (84 → 86) exactly. The claim remains at assertion tier and is labelled
so here rather than presented as reperformed — closing survey **U3** as
unresolvable-from-artifacts-but-corroborated.

**Candidate 4 — the refusal event: consistent, unverifiable, and stated as
such.** Whether `handbook-trigger-gate.sh` actually fired on the observed
session's commit attempt (`implementation.md:57-79`) leaves no repository
artifact. What static reading establishes is the conditional: the in-force gate,
given that staged set, denies (candidate 1(a) above). The record's claim is
therefore *consistent with* the gate's own logic; that it occurred is not
established by any artifact and is not assumed here in either direction. Survey
**U2** closes as unresolvable from artifacts, with the reason stated.

**Candidate 5 — citation drift: no defect; both citations are correct at their
own commit.** The proposal cites `board-gate.sh:329` / `:330`
(`…-fix-board-gate-wrapper-cd-argument-extraction.md:70,93,121`) and the record
cites `:333` / `:334` (`implementation.md:33,37`). Read this session:
`ace7dda~1:core/hooks/board-gate.sh:329-330` is
`if gate_lib.gate_head_of(stripped) == "cd":` / `target = _cd_target(stripped)`,
and the identical two lines sit at `ace7dda:core/hooks/board-gate.sh:333-334` —
the four docstring lines the delivery added shifted them by exactly 4. The
phase-1 document cites the pre-delivery tree and the phase-2 document cites the
delivered tree; each is accurate as of its own commit. Survey **U6** closes as a
non-issue.

## Findings

### Finding 1 — the sibling call site of the fixed defect class is unnamed in the delivery's scope statements

- **Impact.** Low, and documentation-level only: no bypass, no behaviour
  change. `_git_subcommand` (`ace7dda:core/hooks/board-gate.sh:195`) still
  answers "which git subcommand" from a raw `segment.split()[1:]` while its
  caller has already resolved the head through `gate_lib.gate_head_of`
  (`:214-216`) — the same parser-differential seam the delivery removed from
  `_cd_target`. Its misread direction is fail-closed
  (`"30" not in GIT_READ_SUBCOMMANDS` → treated as a write, `:190-193, :216`), so
  the practical cost today is possible over-denial of wrapper-prefixed read-only
  git segments, not an unadjudicated allow. The real cost is to the next reader:
  the class is now half-consolidated with nothing on the record saying so.
- **Timeline.** `docs/issue-99/reports/execution-observation.md:418-422` names
  `_git_subcommand` as sharing the index assumption (2026-08-03). Issue #107 is
  filed scoped to the `cd` half. The observed session's three documents —
  proposal, survey, and record — contain zero occurrences of `_git_subcommand`
  (`grep -n "_git_subcommand"` over all three this session returned no hits),
  even though the docstring the delivery itself edited still cites it as the
  idiom being reused (`ace7dda:core/hooks/board-gate.sh:264`). The record's
  `## Open findings` states "None" (`implementation.md:185-191`) and
  `## Next steps` names only a `nohup` case and the handbook as residuals
  (`:193-201`).
- **Root cause.** The issue text scoped requirement 1 to `cd`, and the session
  tracked the issue's scope faithfully; nothing in its own loop asked "where else
  does this class live". The upstream record had already answered that question,
  but it lived in a *different* issue's record — read for the defect it
  formalized, not swept for the siblings it also named.
- **Action item (for the human, not for this role).** Decide whether
  `_git_subcommand`'s index assumption is worth a follow-up issue. Two facts
  bear on it: the direction is fail-closed, so it is a correctness-of-classification
  question rather than a security hole; and consolidating it would be the same
  one-line change (`gate_lib.gate_trailing_words`) the `cd` half just took. This
  role does not file issues under contract v3.

### Finding 2 — the record's `## Next steps` contradicts its own `## What was done` about the handbook

- **Impact.** Low, documentation-only. `docs/issue-107/reports/implementation.md:198-201`
  lists "a `docs/handbooks/board-gate-tests.md` entry, judged not clearly
  applicable under the doctrine ladder" among residuals that "are not blockers on
  this issue" — i.e. as something still outstanding. The same record states at
  `:51-55` that the entry was written, and explains at `:57-79` why; `ace7dda`'s
  `--stat` confirms `docs/handbooks/board-gate-tests.md | 21 +++`. A reader who
  reaches `## Next steps` first is told the handbook is unwritten when it was
  written in that same commit.
- **Timeline.** The proposal (`67eb71e`) listed the handbook as an open residual;
  the gate forced the write at `ace7dda` commit time; `## What was done` item 4,
  `## Rationale for deviations`, and the `## Doc-placement ladder` bullet at
  `:115-118` were all updated to reflect it, while `## Next steps` at `:198-201`
  retained the proposal-era wording.
- **Root cause.** The deviation was absorbed in three of the record's four
  handbook-touching sections; the fourth restates the *proposal's* residual list
  verbatim, where the same sentence stops being true once the deviation lands.
  A section that quotes an upstream document's open items has no signal that it
  needs re-reading when one of those items closes mid-delivery.
- **Action item (for the human, not for this role).** Judge whether the stale
  sentence warrants an amendment to `implementation.md` under that record's own
  `## Resolution path` (`:203-207`). This role does not edit the observed role's
  record.

## Evidence tiers

- **Artifact-derived (reperformable from this repo):** every claim in Verdict 1
  requirements 1 and 3 and the constraints; the case tally 84 → 86; the whole of
  Verdict 2's phase-separation, survey-before-proposal, approval-and-ordering,
  and scout-skip legs; candidates 1(a), 1(c), 2, and 5; both findings.
- **Assertion tier (the observed role's claim, corroborated but not
  reperformed):** the red run `84 passed, 2 failed` and the green run
  `86 passed, 0 failed` (`implementation.md:152-171`); the `gate-lib`
  `53 passed, 1 failed` and `gh-guard` `52 passed, 0 failed` runs (`:172-183`);
  the `CLAUDE_PLUGIN_ROOT_CORE` contamination narrative (`:81-99`); and that the
  handbook gate actually fired (`:57-79`, candidate 4).
- **Out of reach and not judged:** nothing beyond the above; survey unknowns
  U1–U6 are each resolved or explicitly closed as unresolvable, in Verdicts 2
  and 3.

## Open findings

Two, both above, both documentation-level, neither blocking. Under contract v3
this role files no issue; the human judges these on PR #112 and files if valid.

## Resolution path

Any open finding against *this* record is resolved by amending this file with a
`resolved_findings:` entry referencing the finder's record, per contract v3 s16.
Findings 1 and 2 are addressed to the human, not to the observed role: neither
this record nor this session touches `docs/issue-107/reports/implementation.md`.

## Verify

Nothing was executed. The verification available for this record is that each
verdict-bearing sentence above names a commit SHA, a `file:line` at a named
commit, or a GitHub artifact id adjacent to the claim, and that every such
source was opened in this session — the list is `## What was done`. The
statically-derived numbers a reader can re-check without running anything:
`git show --stat ace7dda` (5 files, +272/-1) and the helper-invocation tally of
`run-board-gate-tests.sh` at `ace7dda~1` (84) versus `ace7dda` (86).
