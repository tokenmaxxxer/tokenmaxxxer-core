---
kind: observation-record
subject: issue-157
produced_by: execution-observation
observed_role: implementation
observed_pr: 158
loop_state: landed
upstream:
  - path: docs/issue-157/reports/execution-observation/survey.md
    sha: 5beba37195a2c0f58a8c33749657505632bd0fdf
  - path: docs/issue-157/reports/execution-observation/scout-brief.md
    sha: 5beba37195a2c0f58a8c33749657505632bd0fdf
  - path: docs/issue-157/proposals/2026-08-08-observe-pr-158-issue-157-execution.md
    sha: 5beba37195a2c0f58a8c33749657505632bd0fdf
---

# Execution observation — issue-157, step 2

## Independence

This role did not author, and has not edited this session, any artifact
under observation. Nothing under `core/`, `test/`, `docs/handbooks/`,
`docs/reports/2026-08-08-hunt-issue-157-*`,
`docs/issue-157/proposals/2026-08-08-frontmatter-fallback-*`, or
`docs/issue-157/reports/implementation*` was written or modified by this
session; the only paths this branch writes are this file, this role's
phase-1 trio, and this role's own hunt record.

No suite, gate, script, or reproduction belonging to the observed delivery
was executed here: `core/hooks/tests/run-role-gates-tests.sh`,
`core/hooks/tests/run-all.sh`, `core/hooks/record-fields-gate.sh`, both
Python reproductions inside the observed role's hunt record, and every
`python3` trace inside its survey were never run by this session. The two
code files the delivery touched were read **only** as
`git show 7cd6392e5fc0d3509bd3228232c2ba0b43b58f4d -- <path>` diffs, never
as current-tree source; where a pre-image was needed it was taken from the
verbatim quote inside the observed role's own survey
(`docs/issue-157/reports/implementation/survey.md:29-44`). Every on-paper
revert below is computed from those two texts, never by reverting anything
on disk.

The evidence set is the observed role's produced artifacts and the
issue/PR metadata, read at the merge state
`01d5a8fb7ddab7dd76a373b7ee8ed8983fb1d966`: the two commits
`cdbe166e003d4c8c31a66e05427ce33e1132cfff` and
`7cd6392e5fc0d3509bd3228232c2ba0b43b58f4d` (message, `--stat`, and
per-path diffs), `docs/issue-157/reports/implementation.md`,
`docs/issue-157/reports/implementation/survey.md`,
`docs/issue-157/proposals/2026-08-08-frontmatter-fallback-f2-discriminator-f3-census-f4-handbook.md`,
`docs/reports/2026-08-08-hunt-issue-157-frontmatter-fallback-f2-discriminator-f3-census-f4-handbook.md`,
`docs/specs/approvers.md`, `docs/issue-153/reports/execution-observation.md`
(the upstream record that authored the four findings), issue #157's body
and both of its comments fetched verbatim through the API, and PR #158's
title, body, author, timestamps and review list. Two listings this session
took of its own accord — `git ls-tree -r --name-only HEAD -- docs/proposals docs/reports`
and a `git log` read of trailer fields across the last twelve commits — are
surveys of repository contents and commit metadata, not executions of the
observed code.

No issue was filed. Under contract v3 issues are user-authored only, so
the findings below return solely in this record, on this role's own PR,
for the human to judge.

## Why

Issue #157's `## 실행 계획` lists two steps. Step 1 (`implementation`)
landed as PR #158, merged `2026-08-08T03:55:20Z` as
`01d5a8fb7ddab7dd76a373b7ee8ed8983fb1d966`. Step 2 is this role's
independent observation of that execution, and it is the issue's final
planned step. Phase 2 of this role opened on the issue-level comment
<https://github.com/tokenmaxxxer/tokenmaxxxer-core/issues/157#issuecomment-5224446103>
(`jjongkwann`, `2026-08-08T04:13:40Z`), whose entire body is the exact
string `APPROVE issue-157/execution-observation`; `jjongkwann` is listed in
`docs/specs/approvers.md` and is also this branch's PR author, so contract
v3 §19's single-account issue-comment path is the one that applies.

## What was done

This record was opened as the first act of phase 2 and carries the three
verdict levels the role owes — outcome, trajectory, step — each addressed
explicitly rather than silently omitted, with every verdict-bearing
sentence citing the artifact it rests on immediately beside the claim. It
executes the evidence plan approved at
`docs/issue-157/proposals/2026-08-08-observe-pr-158-issue-157-execution.md`
item by item: the seven level-1 evidence items, the seven level-2 items,
and the seven level-3 artifacts named there each appear below with the
artifact they were read from, including the ones that turned out to support
the observed role's account. The four audit lenses adopted from
`docs/issue-157/reports/execution-observation/scout-brief.md` are applied
where that brief aimed them (must-be 1 on the red-green integrity section,
must-be 2 on the constraint-boundary derivation, must-be 3 on the cadence
audit trail, must-be 4 on the handbook paragraph), and the one method
deliberately skipped — actually reverting and re-running — is stated as
skipped with its residue named under `## Method residue`.

`loop_state` opened at `observing` while the evidence above was read and
moves to `landed` with this commit, which is the transition that completes
this role's work on issue #157; no further phase remains on this branch.

---

## Verdict summary

All three verdict levels apply to this execution; none is written off as
inapplicable.

- **Outcome — PASS.** All four requirements and all four `check:`
  acceptance items of issue #157 landed in
  `7cd6392e5fc0d3509bd3228232c2ba0b43b58f4d`, and the issue's two
  constraints hold. One acceptance item (check 2) is discharged in the
  survey rather than in the record the check names — Finding 3.
- **Trajectory — SOUND.** The phase-1 → phase-2 path ran in the required
  order against a valid single-account approval, with a pure phase-1 write
  set and both hunt dispatches present at the correct stances. One
  tension (the scout skip) is stated below without being graded a
  deficiency; the cadence's own audit trail is defective — Finding 1.
- **Step — four deficiencies, all non-blocking**, plus two minor hygiene
  notes. None reverses the outcome verdict; the most consequential
  (Finding 1) is an audit-trail defect, not a behaviour defect.

---

## Level 1 — outcome

### Requirement 1 (F1) — met

`git show 7cd6392e5fc0d3509bd3228232c2ba0b43b58f4d -- core/hooks/record-fields-gate.sh`
changes exactly two code lines (post-image `:208-209`): the frontmatter
anchor is matched against `text.lstrip()` instead of the raw `text`, and
the no-match fallback becomes the full original `text` instead of the
empty string — which is the semantics the approved proposal froze at
`docs/issue-157/proposals/2026-08-08-frontmatter-fallback-f2-discriminator-f3-census-f4-handbook.md:187-194`,
delivered without drift.

The trade-off comparison the requirement demands is recorded, not merely
concluded: the rejected fail-closed candidate is written out with the
reason it was rejected and the five currently-passing fixtures it would
break (`…-f4-handbook.md:111-122`), traced first in the survey against the
live fixture set (`docs/issue-157/reports/implementation/survey.md:76-89`),
and the chosen candidate is traced the same way
(`…/implementation/survey.md:90-103`). The `:92` allow fixture's
disposition — the second half of the requirement — is answered explicitly
and with a reason (`…-f4-handbook.md:124-131`, and
`…/implementation/survey.md:111-121`: the fixture's content carries no line
matching the gate's own field regex, so no candidate changes its verdict).

The red-green pin landed as `core/hooks/tests/run-role-gates-tests.sh:164-170`
in `7cd6392e5fc0d3509bd3228232c2ba0b43b58f4d`'s post-image (a fence-less
document whose only field line carries the `HEAD` spelling, expected
`deny`).

### Requirement 1's constraint boundary (survey U1) — inside the constraint

The survey left open whether changing the anchor's input to
`text.lstrip()` is "fallback 의미론" (permitted) or a change to #154's
landed frontmatter-scoping (forbidden by issue #157's `## 제약`). It is the
former, and this is derivable from the diff alone rather than assumed:
`re.match` anchors at index 0, so in the pre-image
(`docs/issue-157/reports/implementation/survey.md:33`) the anchor matched
if and only if the text began with `---` after the BOM strip; for exactly
those documents `text.lstrip()` **is** `text`, so the post-image
(`core/hooks/record-fields-gate.sh:208` in
`7cd6392e5fc0d3509bd3228232c2ba0b43b58f4d`) selects a byte-identical
`region`. Every document whose region was non-empty before is unchanged;
the only documents whose treatment changes are those the anchor previously
missed, which is precisely F1's territory.

The same derivation settles the direction of the change: for a
whitespace-preceded fenced document the old region was empty and the new
one is the frontmatter block, and for a fence-less document the old region
was empty and the new one is the whole text. In both cases the old flagged
set is empty, so it is a subset of the new one — the change is
monotonically stricter and no previously-denied write becomes allowed
(`git show 7cd6392e5fc0d3509bd3228232c2ba0b43b58f4d -- core/hooks/record-fields-gate.sh`,
post-image `:208-209`). This is what scout must-be 2 asks to be stated
explicitly, and it is the answer the observed role's own Rationale asserts
without deriving (`…-f4-handbook.md:72-75`).

### Requirement 2 (F2) — met in substance

The discriminating fixture landed as an inline message-content probe at
`core/hooks/tests/run-role-gates-tests.sh:187-197` in
`7cd6392e5fc0d3509bd3228232c2ba0b43b58f4d`'s post-image: a two-entry
`upstream:` block whose first entry's field line is value-less and whose
second entry carries the `HEAD` spelling, asserting that the denial message
contains the substring `sha: HEAD is not`. That is the shape issue #157's
F2 paragraph specified ("값 없는 줄 + 다음 줄에 비정합 값").

Its discriminating power against the pre-#154 pattern is traced in
`docs/issue-157/reports/implementation/survey.md:189-225`, and the trace
holds on re-derivation from the two pattern texts the survey itself quotes
(`…/implementation/survey.md:171-172`): under the old pattern the
value-less line's trailing `\s*` crosses the newline and captures the
literal `- path: other` as `bad[0]`, and since `deny_placeholder` reports
only `bad[0]` the substring the probe asserts cannot appear. The survey
also records a rejected simpler fixture and why it would be a false
discriminator (`…/implementation/survey.md:217-225`) — the mark of a
fixture that was reasoned about rather than guessed.

Where this falls short is *where the proof is recorded*, not whether it
exists — Finding 3.

### Requirement 3 (F3 census) — met

`docs/issue-157/reports/implementation.md:126-146` states the census
result in the record itself, as the issue's acceptance check requires:
11/11 files outside issue-153's original `core/hooks/*.sh` glob examined,
0 additional instances of F1's class, with the two files that independently
implement a fail-closed `frontmatter(path)` helper named. The underlying
file-by-file work is in `docs/issue-157/reports/implementation/survey.md:236-315`,
and it includes a method correction worth noting on its own terms
(`…/implementation/survey.md:253-259`): issue-153's literal grep pattern
missed precompiled-pattern call sites, which is exactly the form two of
the eleven files use. The census was therefore not a re-run of a method
known to be incomplete; the incompleteness was found and repaired before
the count was taken. The issue offered "extension **or** boundary
rationale" and the role delivered the stronger of the two
(`…/implementation/survey.md:295-301`).

### Requirement 4 (F4 handbook sentence) — met, with a wording defect

`git show 7cd6392e5fc0d3509bd3228232c2ba0b43b58f4d -- docs/handbooks/role-gates-tests.md`
adds a paragraph at post-image `:73-83` carrying both sentences: the F1
fallback ("has its *entire text* scanned instead of being skipped") and the
F4 boundary ("ends at the *first* column-0 `---` line found after the
opening fence, not the last"). Verified claim-by-claim against the gate
hunk in the same commit, per scout must-be 4: the F4 sentence is accurate —
the anchor's middle group is non-greedy, so the closing anchor binds to the
first candidate. The F1 sentence's *tolerance clause* is not accurate —
Finding 2.

### Acceptance checks 1–4

- **Check 1** ("펜스-부재 + 비정합 값 red-green 케이스가 스위트에 추가,
  수정 전 red 재현 기록 포함") — **mapped.** Assertion at
  `core/hooks/tests/run-role-gates-tests.sh:164-170` in
  `7cd6392e5fc0d3509bd3228232c2ba0b43b58f4d`; the pre-fix red reproduction
  is recorded at `docs/issue-157/reports/implementation.md:13-23` as a
  gate-only `git stash` producing exactly one named FAIL.
- **Check 2** ("판별형 message-accuracy 케이스가 수정 전 게이트에서 실패함을
  기록으로 증명") — **mapped to the survey, not to the record.** The proof
  exists (`docs/issue-157/reports/implementation/survey.md:189-225`); the
  record's own entry for this check does not restate or cite it
  (`docs/issue-157/reports/implementation.md:24-33`). See Finding 3.
- **Check 3** ("census 확장 결과 또는 경계 사유가 record 에 명시") —
  **mapped.** `docs/issue-157/reports/implementation.md:126-146`.
- **Check 4** ("핸드북에 영역 경계 문장 존재") — **mapped.**
  `docs/handbooks/role-gates-tests.md:79-83` in
  `7cd6392e5fc0d3509bd3228232c2ba0b43b58f4d`'s post-image.

### Constraint conformance

- **"#154-landed semantics unchanged"** — holds, by the index-0 derivation
  in the constraint-boundary section above, computed from
  `git show 7cd6392e5fc0d3509bd3228232c2ba0b43b58f4d -- core/hooks/record-fields-gate.sh`
  and the pre-image at `docs/issue-157/reports/implementation/survey.md:33-34`.
  The empty-value carve-out, the YAML-comment strip and the value whitelist
  are untouched context lines in that same hunk.
- **"No retroactive edit"** — holds. `git show --name-only 7cd6392e5fc0d3509bd3228232c2ba0b43b58f4d`
  lists five paths, none of them a previously-landed record or proposal:
  `core/hooks/record-fields-gate.sh`, `core/hooks/tests/run-role-gates-tests.sh`,
  `docs/handbooks/role-gates-tests.md`,
  `docs/issue-157/reports/implementation.md` (new in this commit), and this
  issue's own hunt record.

### Red-green integrity of the four added assertions (scout must-be 1)

The literal method — revert and re-run — is deliberately skipped; this
role may not execute the observed role's code. The revert is performed on
paper against the pre-image the observed survey quotes
(`docs/issue-157/reports/implementation/survey.md:29-44`), and the residue
is named at the end.

1. `F1 red->green: fence-less document's bad sha value denied` — content is
   a single fence-less field line carrying `HEAD`. Pre-image: anchor
   misses, the region is empty, nothing flagged → `allow`, expected `deny`
   → **FAIL**. Post-image: the region is the whole text, and `HEAD` matches
   neither `same-commit` nor 40-hex → `deny`. Discriminates **this
   change's** pre-image. Non-vacuous.
2. `F1 regression: fence-less document's conforming sha value stays allowed`
   — same shape with a conforming value. Pre-image `allow`, post-image
   `allow`. Vacuous against this change by construction; it guards against
   the fallback degenerating into an always-deny, which is a real future
   risk the diff introduces. Legitimate as written.
3. `F1 hunt regression: leading blank line before a real fence…` — a
   leading newline, a conforming frontmatter block, then a body quoting the
   `HEAD` spelling inside a fence. Pre-image: the anchor misses at index 0,
   the region is empty → `allow`. Post-image: `lstrip()` makes the anchor
   match, the region is the frontmatter block, the body is out of region →
   `allow`. Green on both sides, but for **different reasons**; the
   pre-image it actually discriminates against is the proposal's discarded
   one-token draft (`docs/reports/2026-08-08-hunt-issue-157-frontmatter-fallback-f2-discriminator-f3-census-f4-handbook.md:40-44`,
   `:69-71`), which never landed. That is a legitimate regression pin on a
   design the hunt forced, not a defect; the record's characterisation at
   `docs/issue-157/reports/implementation.md:18-22` is accurate as to
   intent, and the nuance is recorded here so a later reader does not
   mistake its greenness for coverage of the landed change.
4. `F2 discriminator` — the fixture opens with a fence at byte 0, so
   pre-image and post-image select the identical region and the probe
   passes on both sides of **this** change; the pre-image it discriminates
   against is pre-#154 (see Requirement 2 above).

The record's claim of **exactly one FAIL** under a gate-only stash
(`docs/issue-157/reports/implementation.md:13-23`) is therefore consistent
with what these four fixtures must produce against the quoted pre-image:
assertion 1 fails, assertions 2–4 pass. The `56 → 60` count
(`docs/issue-157/reports/implementation.md:117-120`) is consistent with the
diff, which adds three `run_rf` cases and one `report` call — four
assertions — in
`git show 7cd6392e5fc0d3509bd3228232c2ba0b43b58f4d -- core/hooks/tests/run-role-gates-tests.sh`,
and with the independently re-run 56/0 baseline the survey records
(`docs/issue-157/reports/implementation/survey.md:46-51`).

**Residual, stated as residual:** the `60 passed, 0 failed` figure, the
clean `run-all.sh` result, and the corpus counts 239/96/2 at
`docs/issue-157/reports/implementation.md:42-46` are self-reported and were
not re-executed here. Nothing in the diffs contradicts them and the
on-paper revert agrees with the one-FAIL claim, but they are corroborated,
not verified, by this observation.

---

## Level 2 — trajectory

### Approval gate — valid, single-account path, no near-miss

PR #158's author is `jjongkwann` and its review list is empty
(`gh pr view 158 --json author,reviews` → `"reviews":[]`), so the
two-account PR-review path of contract v3 §19 was unavailable and the
single-account issue-comment path is the one that applies. Issue #157
carries exactly two comments, both fetched verbatim through the API. The
one that opened the observed role's phase 2 is
<https://github.com/tokenmaxxxer/tokenmaxxxer-core/issues/157#issuecomment-5224334825>
(`jjongkwann`, `2026-08-08T03:41:06Z`), whose entire body is the exact
string `APPROVE issue-157/implementation`; `jjongkwann` is listed in
`docs/specs/approvers.md`. String equality holds and the account is
listed, so the gate is satisfied. The second comment
(<https://github.com/tokenmaxxxer/tokenmaxxxer-core/issues/157#issuecomment-5224446103>,
`2026-08-08T04:13:40Z`) is this role's own approval and is not an approval
of PR #158.

**No near-miss to report**, stated plainly here because a near-match should
reach the human from the session that read it: neither comment is prose,
neither is an affirmative-sounding non-match, and neither came from an
unlisted or bot account.

### Ordering — correct, no phase-2 work before the approval

`cdbe166e003d4c8c31a66e05427ce33e1132cfff` at `2026-08-08T03:38:50Z` → PR
#158 created `2026-08-08T03:39:16Z` → approval `2026-08-08T03:41:06Z` →
`7cd6392e5fc0d3509bd3228232c2ba0b43b58f4d` at `2026-08-08T03:53:59Z` →
merge `2026-08-08T03:55:20Z`. Every code, test, handbook and record path
lands in the post-approval commit; the pre-approval commit contains none of
them (`git show --stat` on each).

### Phase-1 write-set purity — clean

`git show --stat cdbe166e003d4c8c31a66e05427ce33e1132cfff` is three files,
all under `docs/`, 780 insertions and 0 deletions: the survey, the
proposal, and the hunt record. No path under `core/`, `test/`, or
`docs/handbooks/`, and no record file. `git log -- docs/issue-157/reports/implementation.md`
returns a single commit, `7cd6392e5fc0d3509bd3228232c2ba0b43b58f4d` — the
phase-2 record correctly waited for the approval rather than being written
early and held back.

### Frozen write-set conformance (survey U10) — no scope-exceeded event

The approved proposal's `files:` line
(`docs/issue-157/proposals/2026-08-08-frontmatter-fallback-f2-discriminator-f3-census-f4-handbook.md:11`)
names three paths; the delivery touched five. The two extra paths are
`docs/issue-157/reports/implementation.md` and this issue's hunt record,
both under `docs/`, which the warrant directive exempts from the frozen
write set as "the record the work produces". The record path is
additionally named as a deliverable in the proposal's own `## What will be
done` item 4 (`…-f4-handbook.md:234-239`), so a reader of the approved plan
was told to expect it. No stop was owed.

### Survey-before-proposal — held; scout skip — admissible, with a stated tension

The survey exists as a separate phase-1 artifact and the proposal cites it
as its upstream (`…-f4-handbook.md:6-8`), so the required order held.

The scout skip is recorded rather than silent
(`docs/issue-157/reports/implementation/survey.md:9-22`), which is the
directive's mandatory-skip-record requirement, and it argues its condition
instead of merely naming it. The tension is that the skip record's own text
concedes "the one open design choice — F1's fallback semantics", while the
condition it invokes is "pure bugfix", and issue #157's requirement 1
explicitly asks the proposal to compare candidates and choose. This
observation does not grade that a deficiency, for two cited reasons: the
comparison the scout pass exists to inform was in fact performed, against
in-repo evidence that no external sweep could have supplied
(`docs/issue-157/reports/implementation/survey.md:76-109` traces both
candidates against the live fixture set, and the rejected candidate's cost
is quantified as five currently-passing fixtures); and this role's own
precedent accepted the identical skip condition and reasoning for the same
file one issue earlier (`docs/issue-153/reports/execution-observation.md:206-212`).
The tension is recorded so the human can set the boundary if they read it
differently.

### Hunt cadence — both dispatches present, stances rotated, audit trail defective

Both required dispatches exist and are recorded even where one found
nothing to block on: after-proposal at stance 0
(`docs/reports/2026-08-08-hunt-issue-157-frontmatter-fallback-f2-discriminator-f3-census-f4-handbook.md:7-9`)
and before-landing at stance 1 (same file, `:100-102`), which is the
correct rotation rather than a repeated stance. Both returned FINDING, and
both findings are dispositioned in the record's `## Hunt cadence`
(`docs/issue-157/reports/implementation.md:170-183`).

The after-proposal finding was folded back **before** the proposal was
approved, not after: the proposal text inside
`cdbe166e003d4c8c31a66e05427ce33e1132cfff` already carries the revision
(`…-f4-handbook.md:85-109`, "Revised after this proposal's own
after-proposal hunt"), and the phase-2 commit does not touch that file at
all (`git show --name-only 7cd6392e5fc0d3509bd3228232c2ba0b43b58f4d`). The
human therefore approved the post-hunt design, which is the ordering the
cadence exists to produce. This is the strongest single point in the
observed trajectory: a hunt that changed the plan before the plan was
approved.

The audit-trail fields that are supposed to make this checkable do not
survive checking — Finding 1.

### Before-landing finding's disposition (survey U3) — adequate, with one residual

The disposition at `docs/issue-157/reports/implementation.md:34-62` treats
the composition finding as an already-accepted trade-off and re-measures it
rather than re-citing it. Both of this observation's open questions about
that measurement resolve in the observed role's favour:

- The corpus glob `docs/issue-*/{reports,proposals}/**/*.md` omits the
  standing `docs/proposals/` bucket, but
  `git ls-tree -r --name-only HEAD -- docs/proposals` returns no entries at
  the merge state, so the omission excludes zero files and cannot change
  the count.
- The five fence-less, section-20-complete fixtures at
  `core/hooks/tests/run-role-gates-tests.sh:75-92` are test fixtures rather
  than live corpus documents, and the survey grepped them for a field line
  and found none (`docs/issue-157/reports/implementation/survey.md:95-103`),
  so they flip no verdict and are not an uncounted live-instance class.

**Residual:** the disposition's path-scope claim — that
`docs/issue-12/reports/review/survey.md` is never evaluated because
`RECORDS_RE`/`PROPOSALS_RE` do not match a `reports/<subdir>/…` path
(`docs/issue-157/reports/implementation.md:46-50`) — rests on the record's
own description of two regexes that the delivery did not change and that
this role may not read as current-tree source. It is consistent with this
role's independently observed behaviour on its own phase-1 files
(`docs/reports/2026-08-08-hunt-observe-pr-158-issue-157-execution.md:33-38`),
but it is corroborated, not verified, here.

A second residual, not a deficiency: "0 live corpus documents are denied by
this fallback that were allowed before it"
(`docs/issue-157/reports/implementation.md:55-56`) is a measurement of
documents that already exist, while the gate fires on writes that do not
exist yet. The trade-off's cost lands on future fence-less documents —
including exactly the shape the hunter's own reproduction used
(`docs/reports/2026-08-08-hunt-issue-157-frontmatter-fallback-f2-discriminator-f3-census-f4-handbook.md:112-120`).
The proposal named and accepted that cost before approval
(`…-f4-handbook.md:76-80`), so it is a disclosed, approved trade-off rather
than an undisclosed regression; the record's number is simply narrower than
the sentence it supports.

### PR hygiene — clean on the load-bearing checks

No GitHub closing keyword appears in PR #158's title or body
(`gh pr view 158 --json title,body`; the body's reference section is a bare
`#157`), nor in either commit message. Both commits carry the
`Subject: issue-157` trailer required by contract v3 §13, read from
`git log --format='%(trailers:key=Subject,valueonly)'` on
`cdbe166e003d4c8c31a66e05427ce33e1132cfff` and
`7cd6392e5fc0d3509bd3228232c2ba0b43b58f4d`. Two lesser hygiene notes are
recorded under level 3.

---

## Level 3 — step

Four deficiencies and two minor notes. Each deficiency carries the
four-part blameless shape, scaled to the single finding.

### Finding 1 — the hunt record's audit-trail timestamps are internally impossible

**Impact.** The hunt cadence's four self-reported clock fields are the only
artifact that makes the "hunt ran at the right transition, inside its cap"
claim auditable, and none of them survives a sequence check. Every ordering
claim that rests on them — including the load-bearing one, that the
after-proposal hunt preceded the proposal it revised — has to be
re-established from git and GitHub metadata instead, which this observation
was able to do (see the cadence section above) but which a reader trusting
the record could not.

**Timeline.** The after-proposal section reports
`started_at: 2026-08-08T01:57:00Z` / `ended_at: 2026-08-08T02:04:30Z`
(`docs/reports/2026-08-08-hunt-issue-157-frontmatter-fallback-f2-discriminator-f3-census-f4-handbook.md:15-16`)
and the before-landing section reports `started_at: 2026-08-08T00:00:00Z` /
`ended_at: 2026-08-08T00:20:00Z` (same file, `:108-109`). Issue #157 itself
was created `2026-08-08T03:13:46Z` (`gh issue view 157 --json createdAt`),
`cdbe166e003d4c8c31a66e05427ce33e1132cfff` landed `2026-08-08T03:38:50Z`
and `7cd6392e5fc0d3509bd3228232c2ba0b43b58f4d` landed `2026-08-08T03:53:59Z`.
Three separate contradictions follow: both hunts claim to have run over an
hour **before the issue that seeded them existed**; the before-landing hunt
claims a window earlier than the after-proposal hunt, inverting the cadence
order the directive mandates; and both elapsed spans (450s and 1200s)
exceed their own declared `cap_seconds` (`60` at `:12`, `120` at `:105`) by
7.5× and 10×.

**Root cause.** The clock fields were composed rather than measured. The
directive asks for a wall-clock cap "self-measured via `date`"; nothing in
either section cites a `date` reading, and the before-landing pair's round
values (`00:00:00Z`, `00:20:00Z`) read as placeholders rather than
observations. The remaining fields in the same sections — stance, kind,
seed, `diff_stat_lines`, reproduction, observed, expected — are specific
and check out against the diffs, so the defect is isolated to the
timestamps, not to the hunts.

**Action item (for the human to judge, not filed as an issue).** Either
stamp `started_at`/`ended_at` from an actual `date` call at dispatch and
return, or drop the two fields and keep `cap_seconds` plus a measured
elapsed — a field that is always composed is worse than no field, because
it invites the reliance this finding had to withdraw.

### Finding 2 — the handbook understates the tolerance the landed code implements

**Impact.** `docs/handbooks/role-gates-tests.md:73-75` in
`7cd6392e5fc0d3509bd3228232c2ba0b43b58f4d`'s post-image tells a reader that
a document is treated as fence-less "after tolerating **one** incidental
leading blank line or byte-order mark". The landed call is `text.lstrip()`
(same commit, `core/hooks/record-fields-gate.sh:208`), which strips leading
whitespace of any kind and any quantity. A reader who writes a document
with two leading blank lines, or with leading spaces before the fence, will
predict a whole-document scan from the handbook and get a frontmatter-only
scan from the gate — the opposite of the check they were planning around.
The direction is safe (the code is more permissive about recognising a
fence than the doc says), so nothing is silently unchecked; the cost is a
reader's mental model, which is what a handbook is for.

**Timeline.** The accurate phrasing exists upstream and was available:
`…-f4-handbook.md:99-100` says "leading whitespace of any kind stripped".
The narrowing to "one incidental leading blank line" first appears in the
approved proposal's plan for the comment (`…-f4-handbook.md:196-198`),
propagates into the code comment
(`core/hooks/record-fields-gate.sh:192-194` in the same commit), and lands
in the handbook sentence.

**Root cause.** The wording was inherited from the hunt's motivating
example — the hunter's reproduction used exactly one stray blank line
(`docs/reports/2026-08-08-hunt-issue-157-frontmatter-fallback-f2-discriminator-f3-census-f4-handbook.md:57-60`)
— and the example's specificity was carried into a sentence describing the
general rule.

**Action item.** Describe the tolerance as leading whitespace rather than
as one blank line, in the handbook sentence and the function comment. Not
urgent; no behaviour changes.

### Finding 3 — acceptance check 2's proof is not in the record the check names

**Impact.** Issue #157's second acceptance check asks that the
discriminating message-accuracy case be proven to fail against the
pre-change gate **기록으로**. The record's entry for that check
(`docs/issue-157/reports/implementation.md:24-33`) states that the case
passes now and that no production-code change backs it, and stops there:
it neither restates the pre-#154 discrimination trace nor cites where it
lives. A reader auditing the record alone therefore meets an assertion that
the case is a discriminator with no path to the evidence — which is the
precise failure mode issue-153's Finding 2 was about in the first place, an
assertion standing where a trace belongs. The proof does exist
(`docs/issue-157/reports/implementation/survey.md:189-225`) and holds on
re-derivation, so this is a traceability defect, not a missing proof.

**Timeline.** The proposal's F2 plan located the trace in the survey and
did not carry a restatement into the record's plan
(`…-f4-handbook.md:227-234`), while the same proposal explicitly *did* plan
a restatement for the census (`…-f4-handbook.md:234-239`: "the survey
already contains the work; the record is where the issue's acceptance check
expects to find it stated"). The record then followed both plans faithfully
(`docs/issue-157/reports/implementation.md:126-146` restates the census;
`:24-33` does not restate the F2 trace).

**Root cause.** The two acceptance checks were read as asking different
things — check 3 says "record 에 명시" and check 2 says "기록으로 증명" —
and the looser wording of check 2 was read as satisfied by any landed
artifact. That reading is defensible on the Korean wording, which is why
this is graded a deficiency in traceability rather than an unmet
requirement; but the asymmetry leaves the record self-sufficient for
requirement 3 and not for requirement 2.

**Action item.** A single citation line in the F2 `closed_checks` entry
pointing at the survey's trace would close it. Deliberately not applied by
this role: the record under observation is not this role's to edit.

### Finding 4 — the approved plan's comment-replacement half is not visible in the delivery

**Impact.** The approved proposal's item 1 has two bullets: change the
anchor and fallback, and update the function comment "instead of the
current comment's 'other gates already require a well-formed
proposal/record shape' claim, which the observation found uncited and which
this change makes moot" (`…-f4-handbook.md:195-202`). The delivered gate
hunk performs the additive half — nineteen new comment lines at
`core/hooks/record-fields-gate.sh:187-205` in
`7cd6392e5fc0d3509bd3228232c2ba0b43b58f4d` — and deletes nothing: the whole
commit records two deletions and both are the code lines `:208-209`
(`git show --stat` and the per-path diff). The record describes only the
additive half ("Comment block updated in place to state this fallback and
its provenance", `docs/issue-157/reports/implementation.md:91-93`), so a
reader comparing plan to delivery is not told the replacement did not
happen.

**Timeline.** The quoted claim is located by this role's upstream record in
issue-153's **approved proposal**, not in the gate's comment
(`docs/issue-153/reports/execution-observation.md:348-350`, citing
`…-carveout.md:147-148`). Two readings follow, and this observation cannot
separate them from admissible evidence: either the sentence also stands in
the gate's comment block above the delivered hunk, in which case the
planned replacement was simply not delivered; or it never did, in which
case the proposal's item 1 mis-located it — and "replacing" it where it
actually lives would be a retroactive edit to a landed proposal, which
issue #157's own second constraint forbids.

**Root cause.** The plan named a deletion target by quoting its text rather
than by citing its `file:line`, so neither the delivery nor the record
could be checked against it. **Residual, stated as residual:** settling
which reading is correct requires reading the gate's current-tree source
above the diffed hunk, which this role's independence constraint and its
own approved evidence plan both forbid; the finding is therefore reported
as a plan-to-delivery traceability gap, and the human can resolve it in one
look.

**Action item.** Cite deletion targets by `file:line` in a plan, and record
the disposition when a planned edit turns out to be unnecessary or
unreachable — a plan item that quietly does not land reads identically to
one that was forgotten.

### Minor note A — neither commit carries the `Proposal:` trailer

The warrant directive requires every commit to end with a trailer naming
its proposal. A `git log --format='%(trailers:key=Proposal,valueonly)'`
read shows the field empty on both
`cdbe166e003d4c8c31a66e05427ce33e1132cfff` and
`7cd6392e5fc0d3509bd3228232c2ba0b43b58f4d`, so `git log --grep` cannot
answer "what shipped for this proposal" for issue-157's implementation.
This is a standing pattern for the observed role rather than a slip
specific to this PR — `3f67436caf23d4da45ba9a9ace5c959acc8d705a` and
`7036f9549e6dced30fdd23f9d5ad5e6c41b338e1` are likewise empty, while this
role's own commits (`0d7dc6346b05308ccbc47080a2979d2437330354`,
`d65d2c7018782cd2f8365fc32cc782c042611b3e`) carry it. Flagged once, at
minor weight: a repo-wide inconsistency between two roles is the human's
call to settle, not a defect to pin on this execution.

### Minor note B — PR #158's title still says "(phase 1)" at merge

The title at merge is "issue-157: frontmatter fallback, F2 discriminator,
F3 census, F4 handbook (phase 1)" (`gh pr view 158 --json title`), while
the merge commit `01d5a8fb7ddab7dd76a373b7ee8ed8983fb1d966` contains the
phase-2 delivery. The body was updated — its final paragraph describes the
phase-2 delivery and names the delivering commit
(`gh pr view 158 --json body`) — so the PR is not misleading to anyone who
opens it, only to someone reading a PR list. No closing keyword is present
in either.

### Artifacts checked and found sound

Recorded with the same citation discipline as the findings, because a level
that produced no finding still has to show what supported that.

- **The `placeholder_shas` hunk** (`core/hooks/record-fields-gate.sh:208-209`
  in `7cd6392e5fc0d3509bd3228232c2ba0b43b58f4d`) is the approved design
  delivered without drift, and is monotonically stricter — see the
  constraint-boundary derivation at level 1.
- **The record as a record** — `docs/issue-157/reports/implementation.md`
  carries `loop_state: landed` (`:6`), a `code_under_review` list matching
  the three code/handbook paths the commit touches (`:5`), three
  `closed_checks` entries each naming its result (`:10-62`), a
  `## Doc placement` with both taken and not-taken ladder outcomes reasoned
  (`:148-162`), a `## What did not work` that says "None" with a reason
  rather than being omitted (`:164-168`), a `## Hunt cadence` covering both
  dispatches (`:170-183`), and `## Open findings: none` (`:190-192`). Not
  deficient.
- **The approved proposal as a plan** — its four `## What will be done`
  items (`…-f4-handbook.md:185-239`) are the four that landed, one for one.
  Its own after-proposal hunt found the shape its first draft missed and
  the revision reached the approved text (`…-f4-handbook.md:85-109`); its
  test list (`:203-225`) foresaw all four assertions that landed, including
  the hunt-driven regression case. Its `## Constraints` section carries a
  gate-safety constraint on its own text (`:49-53`) — the same discipline
  this role applies to its own documents.
- **The survey as research** — it re-ran the 56/0 baseline itself rather
  than relaying it (`docs/issue-157/reports/implementation/survey.md:46-51`),
  corrected issue-153's census method before reusing it (`:253-259`), and
  recorded an adjacent-track coordination check against open PR #145 by
  reading its diff (`:303-315`). That is discovery over guessing.
- **PR #158's body against the merge content** — its four Summary bullets
  each correspond to a path in `7cd6392e5fc0d3509bd3228232c2ba0b43b58f4d`,
  and its appended phase-2 paragraph names the stash-verified red-green, the
  F2 discriminator, the census, the handbook sentence, the 239-document
  re-verification and the 60/0 suite result — every one of which is
  traceable to the record or the diff. Aside from the stale title (Minor
  note B), nothing in the body overstates the merge.

---

## Method residue

Stated so the next reader knows what this observation did not close.

- **The skipped method.** Scout must-be 1's literal form — revert the fix
  and re-run the suite — was not performed; this role may not execute the
  observed role's code. Every red-green claim above is an on-paper revert
  computed from the diff and the pre-image quoted at
  `docs/issue-157/reports/implementation/survey.md:29-44`. The residue is
  that a discrepancy visible only at runtime (an environment-dependent
  fixture, a shell-quoting artifact in the inline probe's payload) would not
  have been caught here.
- **Self-reported numbers.** `60 passed, 0 failed`, the clean `run-all.sh`,
  and the 239/96/2 corpus counts are corroborated by internal consistency
  and diff support, not verified by execution.
- **The gate's path regexes.** `RECORDS_RE`/`PROPOSALS_RE` were not read;
  the disposition's path-scope claim at
  `docs/issue-157/reports/implementation.md:46-50` is taken as the observed
  role's own statement, cross-checked only against this role's independent
  observation of the same behaviour on its own phase-1 files.

## Open findings

Findings 1–4 above, plus minor notes A and B, are returned to the human on
this role's PR for judgement. Under contract v3 this role files no issue;
if any of them warrants follow-up work, the human authors that issue. None
of them can be closed inside this role's write surface — every one names an
artifact this role is forbidden to edit — so this record is where they
stop.
