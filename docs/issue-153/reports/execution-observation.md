---
kind: observation-record
subject: issue-153
produced_by: execution-observation
observed_role: implementation
observed_pr: 154
loop_state: landed
upstream:
  - path: docs/issue-153/reports/execution-observation/survey.md
    sha: 0d7dc6346b05308ccbc47080a2979d2437330354
  - path: docs/issue-153/reports/execution-observation/scout-brief.md
    sha: 0d7dc6346b05308ccbc47080a2979d2437330354
  - path: docs/issue-153/proposals/2026-08-08-observe-pr-154-sha-scan-scope.md
    sha: 0d7dc6346b05308ccbc47080a2979d2437330354
---

# Execution observation — issue-153, step 2

## Independence

This role did not author, and has not edited this session, any artifact
under observation. Nothing under `core/`, `test/`, `docs/handbooks/`,
`docs/reports/2026-08-08-hunt-issue-153-*`, or
`docs/issue-153/reports/implementation*` was written or modified by this
session; the only paths this branch writes are this file and this role's
own hunt record. No suite, gate, or script belonging to the observed
delivery was re-run: `core/hooks/tests/run-role-gates-tests.sh`,
`core/hooks/tests/run-all.sh`, `core/hooks/record-fields-gate.sh`, and
both reproductions inside the observed role's hunt record were never
executed here. The observed role's produced artifacts — the PR diff, its
two commits, its own record and survey and proposal, its hunt record, and
the issue/PR metadata — are the whole evidence set used below, read at the
merge state `6fd3b29211ec0d69d1cb587d71c457ea8243a4c7`. The two
measurements this session took of its own accord (a structural census of
`sha:`-line placement across the `docs/` corpus, and a listing of tracked
non-test `*.sh` paths, both at `6fd3b29`) are surveys of repository
contents, not executions of the observed code. No issue was filed; under
contract v3 issues are user-authored only, so findings return only in this
record, on this role's own PR, for the human to judge.

This statement precedes every verdict sentence in this document
deliberately, per contract §19's ordering requirement for this role.

## Why

Issue #153's `## 실행 계획` lists two steps: step 1 `implementation`, step
2 `execution-observation`. Step 1 landed as PR #154, merged
`2026-08-08T02:44:54Z` with merge commit `6fd3b29`
(`gh pr view 154 --json state,mergedAt,mergeCommit`). This record is step
2 — an independent judgment on whether that execution was sound, rendered
at three levels (outcome, trajectory, step) against the evidence the
approved phase-1 plan
(`docs/issue-153/proposals/2026-08-08-observe-pr-154-sha-scan-scope.md`)
fixed in advance. Phase 2 opened on the issue-level comment
<https://github.com/tokenmaxxxer/tokenmaxxxer-core/issues/153#issuecomment-5224181165>
(`jjongkwann`, `2026-08-08T02:57:49Z`, body exactly
`APPROVE issue-153/execution-observation`).

## What was done

Read the landed artifacts of PR #154 named in the evidence plan, took two
independent surveys of the repository corpus at the merge state, and wrote
the three-level verdict below with a citation adjacent to every
verdict-bearing sentence. Five deficiencies are recorded as findings, each
in the four-part blameless shape. Nothing under observation was edited or
re-executed.

## What was read this session, first-hand

1. Issue #153 body and both its comments (`gh issue view 153`,
   `gh issue view 153 --json comments`).
2. PR #154 metadata in full — title, body, state, `mergedAt`,
   `mergeCommit`, `createdAt`, `reviews` (`[]`), `comments` (`[]`)
   (`gh pr view 154 --json …`).
3. PR #156 metadata — this role's own phase-1 PR, `createdAt`
   `2026-08-08T02:56:21Z`, single commit `0d7dc63`
   (`gh pr view 156 --json createdAt,commits,reviews`).
4. `git show --stat 7036f95` — the observed role's phase-1 commit.
5. `git show 3f67436 -- core/hooks/record-fields-gate.sh`, read as diff.
6. `git show 3f67436 -- core/hooks/tests/run-role-gates-tests.sh`, read as
   diff.
7. `git show 3f67436 -- docs/handbooks/role-gates-tests.md`, read as diff.
8. `docs/issue-153/reports/implementation.md` (168 lines), in full.
9. `docs/issue-153/reports/implementation/survey.md` — `:1-30` and
   `:100-200`, covering the scout skip record, the F1/F2 traces, the
   requirement-3 census, and the adjacent-track check.
10. `docs/issue-153/proposals/2026-08-08-narrow-sha-scan-scope-and-empty-value-carveout.md`
    — `:1-60` and `:100-200`, covering Request, Constraints, Rationale, and
    `## What will be done` in full.
11. `docs/reports/2026-08-08-hunt-issue-153-narrow-sha-scan-scope-and-empty-value-carveout.md`
    (236 lines), both hunt sections, in full.
12. `docs/specs/approvers.md` — two accounts, `JiwonJung94` and
    `jjongkwann`.
13. This role's own phase-1 trio and hunt record, landed by `0d7dc63`.
14. Two surveys taken this session at `6fd3b29`: a structural census of
    where `sha:` lines sit relative to a document's leading `---` block
    across `docs/`, and `git ls-tree -r --name-only 6fd3b29` filtered to
    non-test `*.sh` paths.

Not read, deliberately: `core/hooks/record-fields-gate.sh` and
`core/hooks/tests/run-role-gates-tests.sh` as current-tree or
whole-file-at-commit source. The evidence plan bound this observation to
the diff form (`git show 3f67436 -- <path>`), and that bound is honored;
where it leaves a claim unsettled, the residue is stated as residual
rather than closed.

## Verdict 1 — outcome: did PR #154 land what issue #153 asked

**Delivered, with two qualifications.** All three of the issue's
requirements have landed artifacts, and all three of its `check:`
Acceptance items map onto named test cases in the delivery commit
`3f67436`; the qualifications are that requirement 1's narrowing opened an
unpinned permissive path (Finding 1) and requirement 3's census was run
over a narrower habitat than the issue's wording asks (Finding 3).

**Requirement 1 (F1, scan scope) — landed.** `3f67436`'s
`core/hooks/record-fields-gate.sh` hunk replaces the whole-document
`re.finditer(r'^\s*sha:\s*(.*)$', text, re.M)` with a scan over a region
extracted by an anchored leading-frontmatter pattern
(`fm = re.match(r'^---[ \t]*\r?\n(.*?\n)^---[ \t]*\r?$', text, re.M | re.S)`),
which is precisely the narrowing the issue's requirement 1 asks for
("스캔 범위를 정본 표면으로 좁힌다 — 유력안은 YAML frontmatter 블록").
The issue's clause leaving the trailing-YAML-comment judgment to the
proposal is discharged: the judgment is recorded with its rejected
alternative in the observed proposal's Rationale
(`docs/issue-153/proposals/2026-08-08-narrow-sha-scan-scope-and-empty-value-carveout.md:118-133`),
and the corresponding `re.sub(r'[ \t]+#.*$', '', m.group(1))` strip landed
in the same hunk of `3f67436`.

**Requirement 2 (F2, carve-out + diagnosability) — landed.** The same
`3f67436` hunk narrows the post-field-name class from `\s*` to `[ \t]*`,
so the captured value can no longer cross a line break, and adds the
carve-out branch `if v == "": continue` that issue #133 required and PR
#134 never delivered. The observed record states the same in its own words
(`docs/issue-153/reports/implementation.md:29-68`), and the diff bears it
out independently of that statement.

**Requirement 3 (class census) — recorded, but over a narrower habitat
than the issue's 전수 조사 wording.** The census lives in
`docs/issue-153/reports/implementation/survey.md:141-179` and the
phase-2 record defers to it without new judgment
(`docs/issue-153/reports/implementation.md:98-105`), which is a legitimate
deferral — the issue asks the proposal to decide, and it did, recording
`code_under_review`'s enumerate-bad-shape check as an accepted limitation
with a stated reason (`…/survey.md:163-179`, restated at
`…-carveout.md:134-138`). The gap is scope, not diligence, and is Finding
3 below.

**Acceptance checks — all three map onto named landed cases in
`3f67436`'s `run-role-gates-tests.sh` hunk.**

| Issue #153 `check:` | Landed case in `3f67436` | Verdict |
| --- | --- | --- |
| 본문 펜스 블록 인용 통과 + frontmatter 비정합 값 거부 | `F1 red->green: fenced-block quotation outside frontmatter allowed` (allow) and `F1 regression: bad value inside frontmatter's own entry still denied` (deny) | mapped |
| 빈 값 carve-out 통과 + 거부 메시지가 실제 문제 줄 지목 | `F2 red->green: value-less line followed by another entry allowed (carve-out)` (allow) and the inline `F2 message-accuracy` probe | carve-out half mapped; message half mapped to a case that cannot distinguish fixed from unfixed — Finding 2 |
| 합법 값 + 뒤따르는 YAML 주석 통과 | `F1 comment case: conforming value + trailing YAML comment allowed` (allow) | mapped |

**Handbook — landed and accurate.** `3f67436`'s
`docs/handbooks/role-gates-tests.md` hunk appends one paragraph after
`:58` stating all three behaviors the delivery claims to document — the
narrowed scan region, the value-less-line allowance, and the
trailing-comment strip — and its wording matches the code in the same
commit rather than overstating it.

**Constraint conformance — held.** The whitelist semantics are visibly
untouched in `3f67436`'s gate hunk: the two accept branches
(`v == "same-commit"` and the 40-lowercase-hex `re.match`) survive the
rewrite verbatim, which is what issue #153's `## 제약` required. No
already-landed record or proposal was retroactively edited: `3f67436`
touches five paths, three code/handbook and two of the observed role's own
issue-153 documents (per the commit's own file list in the diffs read
above).

## Verdict 2 — trajectory: was the phase-1 → phase-2 path sound

**Sound.** Every gate the contract and the standing directives put on the
path was passed, in the required order, with the required artifact.

**Real human approval, correct path.** PR #154's review list is empty
(`gh pr view 154 --json reviews` → `{"reviews":[]}`), and the PR author is
`jjongkwann` (`gh pr view 154 --json author`), so contract v3 §19's
single-account mode applies. The approval is the issue-level comment
<https://github.com/tokenmaxxxer/tokenmaxxxer-core/issues/153#issuecomment-5223954819>,
whose entire body is the exact string `APPROVE issue-153/implementation`,
posted by `jjongkwann` — an account listed in `docs/specs/approvers.md`,
with `"is_bot": false` on the same account in
`gh pr view 154 --json author`. String equality holds; no prose
interpretation was needed. No near-miss or affirmative-sounding non-match
exists to report: issue #153 carries exactly two comments and both are
exact-string approvals, the second being this role's own
(<https://github.com/tokenmaxxxer/tokenmaxxxer-core/issues/153#issuecomment-5224181165>).

**Ordering is correct.** `7036f95` committed `2026-08-08T01:54:37Z`
(`git show 7036f95`) → PR #154 created `2026-08-08T01:55:59Z`
(`gh pr view 154 --json createdAt`) → approval `2026-08-08T01:57:10Z` →
`3f67436` committed `2026-08-08T02:43:12Z` (`git show 3f67436`) → merge
`2026-08-08T02:44:54Z`. Phase-2 work begins 46 minutes after the approval,
never before it.

**Phase-1 write set is pure.** `git show --stat 7036f95` shows exactly
three files, all under `docs/` — the proposal, the survey, and the hunt
record — `586` insertions, `0` deletions, and no path under `core/`,
`test/`, or `docs/issue-153/reports/implementation.md`. The record file
correctly waited for the approval: it first appears in `3f67436`.

**Scout skip is admissible and recorded.**
`docs/issue-153/reports/implementation/survey.md:9-22` carries the skip
record, names the condition ("pure bugfix"), and argues it — the two
defects are named findings against an already-landed change with an exact
file:line locus. That is one of the scout directive's two permitted skip
conditions, and the mandatory skip record exists rather than being
silently omitted.

**Deviation handling matches the directive as written.** The
before-landing hunt's mark-strip fix was added to `3f67436` without a
second approval. The warrant directive's SCOPE EXCEEDED clause triggers on
needing "a file outside the write set"; the frozen write set is the
proposal's `files:` line (`…-carveout.md:11`), which lists
`core/hooks/record-fields-gate.sh`, and the fix landed inside
`placeholder_shas` in that same listed file — so no scope-exceeded stop
was owed. The record argues exactly this and supplies both an impact
assessment and the resolution route
(`docs/issue-153/reports/implementation.md:82-97`), which is the shape a
change-control audit asks of an unlisted addition. The addition is also
disclosed where a PR reader meets it: in `3f67436`'s commit message body
and in PR #154's own Summary bullet.

**Hunt cadence is complete and correctly ordered.** Both dispatches exist
in
`docs/reports/2026-08-08-hunt-issue-153-narrow-sha-scan-scope-and-empty-value-carveout.md`
with their `tier` / `cap_seconds` / `started_at` / `ended_at` fields
present (`:12-16` for after-proposal, `:100-104` for before-landing), and
both returned FINDING. The after-proposal finding was folded back into the
plan *before* the proposal commit rather than after: the end-of-string
closing anchor and the dedicated no-trailing-newline test case both appear
in `7036f95`'s own proposal text (`…-carveout.md:141-147` and `:172-178`),
and `7036f95`'s commit message states the correction explicitly. The
before-landing finding is resolved in `3f67436` itself and
regression-pinned there.

**PR hygiene held.** PR #154's title — `issue-153: narrow
record-fields-gate sha scan scope, deliver empty-value carve-out` — and
its body carry no GitHub closing keyword; the body references `#153` and
`#134` as plain references (`gh pr view 154 --json title,body`). Both
commit messages carry the required `Subject: issue-153` trailer
(`git show 7036f95`, `git show 3f67436`).

## Verdict 3 — step: which specific artifact, if any, is deficient

Five artifacts are deficient, none fatally. Each is written up in the
Findings section below with its four-part shape; this section states the
per-artifact judgment and cites where it comes from.

1. **The `placeholder_shas` hunk in `3f67436` — deficient on
   continuity-of-enforcement.** The no-match fallback
   (`region = fm.group(1) if fm else ""`) means a written document with no
   leading `---` block has *zero* field lines inspected, where the
   pre-`3f67436` pattern inspected every one. The delivery's own added test
   comment states the consequence in the same commit — "a fixture without
   the fence would fall through the 'no frontmatter, nothing to check' path
   and pass vacuously regardless of the value inside it" — and no landed
   case pins that path. Finding 1.
2. **The normalization step in the same hunk — bounded as one instance,
   not as a class, but adequately so.** The leading-mark strip
   (`if text.startswith(<U+FEFF>): text = text[1:]`) is stated in the
   hunk's own comment as fixing exactly the shape the before-landing hunt
   found, and neither the record nor the proposal claims it closes a
   class. The corpus census this session took at `6fd3b29` found 69
   documents carrying such a field line and **0** with no leading `---`
   block, so no landed document reaches any other leading-byte shape
   today. Not a deficiency in itself; its unpinned twin is Finding 1 and
   its opposite direction is Finding 4.
3. **The seven new test cases in `3f67436` — six non-vacuous, one
   verdict-identical before and after the fix.** The `F2 message-accuracy`
   probe asserts the denial names the value `HEAD` for a frontmatter entry
   whose value is non-empty. In the pre-image pattern visible as the
   removed line in the same diff (`^\s*sha:\s*(.*)$`), the `\s*` after the
   field name cannot reach the newline for that input because the value
   character blocks it, and `.` does not match a newline — so the
   unmodified gate produces the identical denial text. The case is a true
   assertion but not a regression pin for the newline-swallowing defect it
   is named for. Finding 2. Consistently, the record's own red→green claim
   names three cases and does not include this one
   (`docs/issue-153/reports/implementation.md:112-121`), which is honest
   reporting of the same fact.
4. **The 8 reshaped issue-128/133 fixtures in `3f67436` — verdicts
   preserved, count misstated.** Reading each `-`/`+` pair in the test
   diff: 5 deny-expecting fixtures (issue-128 bracket-placeholder
   proposal, issue-128 bracket-placeholder record, and the issue-133
   `HEAD`, `TBD`, and bracket-plus-trailing-prose cases) and 3
   allow-expecting fixtures (issue-128 same-commit proposal,
   real-40-hex proposal, same-commit record) had their fixture strings
   rewritten to carry a `---` fence — 8 in total, with every expected
   verdict unchanged. `3f67436`'s commit message and PR #154's body both
   say "reshaped 5 pre-existing issue-128/133 fixtures". Finding 5. The 5
   the record's `## What did not work`
   (`docs/issue-153/reports/implementation.md:70-81`) describes as having
   flipped are exactly the 5 deny cases, so that section is accurate; it
   is the count in the commit message and PR body that the diff
   contradicts.
5. **`docs/issue-153/reports/implementation.md` as a record — accurate on
   every claim this observation could check against the diff.** Its
   `closed_checks` list of seven names (`:157-165`) matches the diff's six
   `run_rf` additions plus the one inline subprocess probe, and its claim
   that all seven run "as real subprocess cases" holds — the inline probe
   pipes a `Write`-shaped payload into `"$HOOKS/record-fields-gate.sh"`
   under `env CLAUDE_ROLE=coding`. Its `code_under_review` frontmatter
   lists the three code/handbook paths `3f67436` actually touches. Its
   `## Doc placement` (`:129-143`) and `## Open findings` (`:166-168`) are
   present and consistent. Not deficient.
6. **The approved proposal `7036f95` as a plan — foresaw one of the two
   hunt-found shapes, and one it could not have.** The no-trailing-newline
   shape was foreseen because its own after-proposal hunt found it and it
   was folded in before the commit (`…-carveout.md:172-178`). The
   leading-mark shape was not, and the record says so. Neither is a
   planning deficiency; a hunt existing to find what a plan missed is the
   cadence working. What the plan did assert without a citation is
   "other gates already require a well-formed proposal/record shape"
   (`…-carveout.md:147-148`) — the load-bearing justification for the
   permissive fallback, and the root of Finding 1.
7. **PR #154's title and body against the merge content — accurate.** The
   body's four Summary bullets each correspond to a path in `3f67436`, the
   Scope note restates the unchanged whitelist semantics and the
   `code_under_review` accepted limitation, and the Test plan's three
   claims are the same three the record makes. Aside from the reshape
   count (Finding 5), nothing in the body overstates the merge.

## Findings

### Finding 1 — a document with no leading frontmatter now escapes the check entirely, and nothing pins it

**Impact.** After `3f67436`, `placeholder_shas` inspects zero field lines
in any written document that does not open with a `---` fence, because
`region = fm.group(1) if fm else ""` makes a failed anchor yield an empty
scan region rather than a fallback. Before `3f67436` the same document had
every such line checked. The direction is permissive: values that
issue-128 and issue-133 exist to deny — including the literal `HEAD` and
`TBD` spellings those issues named — are allowed in that shape. No landed
test case in `3f67436`'s suite hunk asserts what the gate does for it, and
the same commit leaves standing an `allow` fixture for a record with no
frontmatter fence at all (`core/hooks/tests/run-role-gates-tests.sh:92` in
`3f67436`'s post-image, unchanged context in the diff: a
`loop_state:`/`code_under_review:`/`upstream:` record written as flat body
content, expected to pass) — so the gate at that commit demonstrably
accepts frontmatter-less records rather than rejecting them upstream.

**Timeline.** The permissive fallback is specified in the approved
proposal's `## What will be done` item 1 (`…-carveout.md:145-148`),
justified there by the uncited claim that "other gates already require a
well-formed proposal/record shape". The observed role's own after-proposal
hunter contested exactly that sentence for the no-trailing-newline case
(`docs/reports/2026-08-08-hunt-issue-153-narrow-sha-scan-scope-and-empty-value-carveout.md:88-98`:
"only argues for the case where no frontmatter exists at all"), and that
narrower case was fixed. The broader case the hunter conceded — no
frontmatter at all — was never re-examined. `3f67436` then landed it, and
its own added test comment names the consequence out loud while adding no
case for it.

**Root cause.** The justification for the fallback was asserted rather
than traced to a gate. This observation found no artifact in PR #154 that
names a gate requiring a leading `---` block, and the delivery's own suite
contains a counter-example fixture. A narrowing whose failure branch is
permissive is judged by what stops being enforced; the plan judged it by
what starts being allowed.

**Action item (for the human to judge; this role files no issue).** Decide
whether a frontmatter-less document should be treated as "nothing to
check" or as a denial, and pin the decision either way with a case in
`run-role-gates-tests.sh`. If "nothing to check" is the intended answer,
the claim that another gate requires the fence needs a citation, or the
issue-140 fixture at `:92` needs to stop being an `allow`. Mitigating
context, measured this session, not asserted: at `6fd3b29`, 69 `docs/`
documents carry such a field line and every one of them opens with a `---`
block, so the gap has no live instance today — the same "0 live instances,
future writes only" posture issue #153 itself treats as a valid finding.

### Finding 2 — the F2 message-accuracy case cannot distinguish the fixed gate from the unfixed one

**Impact.** Issue #153's second Acceptance check has two halves: the
carve-out passes, *and* "거부 메시지가 실제 문제 줄의 값을 지목한다(개행
삼킴 제거)". The carve-out half is pinned red→green by
`F2 red->green: value-less line followed by another entry allowed
(carve-out)`. The denial-message half is pinned only by the inline
`F2 message-accuracy` probe in `3f67436`, whose fixture places a
*non-empty* value on the field-name line and asserts the output contains
`sha: HEAD is not`. Under the pre-image pattern shown as the removed line
in the very same diff, that input yields the same captured value and
therefore the same message — so the assertion passes identically with the
fix reverted, and the newline-swallowing behavior it names is not what it
measures.

**Timeline.** The case was specified in this exact shape in the approved
proposal (`…-carveout.md:184-188`: "a genuinely non-conforming value on the
same line, immediately followed by another non-blank line"), and landed
that way in `3f67436`. The record's red→green section
(`docs/issue-153/reports/implementation.md:112-121`) names the three cases
that went red on revert and does not include this one, so the record
neither claims nor conceals the gap — it simply is not read as one.

**Root cause.** The defect being pinned only manifests when the captured
value is empty, because `\s*` can only reach the newline when no value
character blocks it. The test case was designed around the *symptom
description* ("names the wrong line") rather than around the input class
that produces it, so it inherited the wrong fixture.

**Action item (for the human to judge).** A case whose field-name line
carries no value and whose *next* line carries a non-conforming one would
separate the two behaviors: unfixed, the denial names the swallowed
next-line text; fixed, the empty line is carved out and the denial names
the following line's own value. That single case would make Acceptance
check 2's second half a real pin.

### Finding 3 — requirement 3's census ran over 7 of the repository's 18 non-test shell files

**Impact.** Issue #153 requirement 3 asks for a 전수 조사 (exhaustive
census) of the same defect class's other habitats. The census's stated
method is "Grep across every `core/hooks/*.sh` (excluding `tests/`)"
(`docs/issue-153/reports/implementation/survey.md:141`). At `6fd3b29`,
`git ls-tree -r --name-only 6fd3b29` filtered to non-test `*.sh` paths
returns 18 files; that glob matches 7 of them. Outside it sit
`core/hooks/lib/gate-lib.sh` and `core/hooks/lib/role-directive.sh` — the
first being the shared library `record-fields-gate.sh` itself calls for
`gate_reconstruct_write` — plus nine sibling-plugin hooks under
`freelunch/`, `scout/`, `terse/`, and `warrant/`. The record states no
judgment on whether those were examined or deliberately excluded
(`docs/issue-153/reports/implementation.md:98-105` defers wholly to the
survey), so the 전수 claim is unestablished by what is recorded — this is
a statement about the census's recorded scope, not a claim that a defect
exists in any of the eleven.

**Timeline.** The census was written in phase 1 (`…/survey.md:141-179`,
landed by `7036f95`) and its judgment carried into the proposal's
Rationale (`…-carveout.md:134-138`) and then into the phase-2 record
unchanged. No stage re-examined the habitat boundary.

**Root cause.** The habitat was scoped by directory glob rather than by
the class definition. The class as the issue states it — a document check
whose scan reaches past the canonical surface — is a property of any hook
that parses repository documents, and `core/hooks/*.sh` is a narrower set
than that.

**Action item (for the human to judge).** Either extend the census to the
eleven uncovered non-test hooks and record the result, or record
explicitly that the class was scoped to `core/hooks/*.sh` and why the
sibling-plugin hooks and `core/hooks/lib/` are out of that class. What is
missing is the second sentence, not necessarily the extra work.

### Finding 4 — the narrowing anchor's early-close direction is neither pinned nor disclosed

**Impact.** The closing anchor is non-greedy (`(.*?\n)^---[ \t]*\r?$`), so
the region ends at the *first* column-0 `---` line after the opening
fence. If such a line appears inside what the author wrote as frontmatter,
the region truncates and every field line below it goes unscanned — the
same silent-permissive outcome as the leading-mark bypass the delivery did
fix, from the opposite side of the anchor. This role's own phase-1 hunt
reproduced it against a standalone copy of the landed pattern and recorded
the truncated region and the empty result
(`docs/reports/2026-08-08-hunt-observe-pr-154-sha-scan-scope.md`, stance
0). None of the seven cases added by `3f67436` constructs a region whose
boundary is ambiguous: all seven use a single fence pair, so the shape is
untested, and neither the record nor the handbook paragraph mentions the
boundary rule.

**Timeline.** The direction was raised against this observation's own
draft evidence plan before phase 2 opened, which is why the approved plan
(`docs/issue-153/proposals/2026-08-08-observe-pr-154-sha-scan-scope.md`,
Level 3 item 1) commits to examining both directions. The observed role's
two hunts both landed on the anchor's not-matching-at-all side; neither
took this side.

**Root cause.** Both hunt dispatches used the same stance index, so both
probed the anchor from the same direction, and the test list was written
from the fixed shapes rather than from the anchor's degrees of freedom.

**Action item (for the human to judge).** Severity is genuinely low: a
column-0 `---` inside a frontmatter block is not valid YAML frontmatter in
the first place, and the corpus census taken this session at `6fd3b29`
found no document whose frontmatter region truncates that way. The cheap
close is one sentence in the handbook stating that the region ends at the
first closing fence, so the boundary rule is documented rather than
implicit.

### Finding 5 — the reshaped-fixture count in the commit message and PR body understates the diff

**Impact.** `3f67436`'s commit message says "reshaped 5 pre-existing
issue-128/133 fixtures", and PR #154's body repeats it. The diff rewrites
8 fixture strings, as enumerated in Verdict 3 item 4. A reader
reconciling the message against the diff meets 3 unexplained fixture
edits — and reshaped fixtures are exactly the artifact class a reviewer is
expected to question first, so the discrepancy costs review attention on
the one class where it is least affordable. All 8 keep their expected
verdicts, so nothing is silently retired by the reshape itself.

**Timeline.** The record's `## What did not work`
(`docs/issue-153/reports/implementation.md:70-81`) accurately says 5 of
the pre-existing cases stopped passing — those are the 5 deny cases. The
count then travelled into the commit message and the PR body attached to
the verb "reshaped" instead of "failed", where it is wrong.

**Root cause.** A number describing failures was reused to describe edits.
The two sets differ by the 3 allow-expecting fixtures that were reshaped
for shape consistency although they would have kept passing unmodified.

**Action item (for the human to judge).** Nothing to fix in the code; the
correction belongs in this record, which is where it now is. Under the
repository's no-retroactive-edit rule (issue #100 precedent, restated at
`…-carveout.md:38-40`) the landed commit message and PR body stay as they
are.

## Open findings

Findings 1–5 above are open for the human's judgment. This role files no
issue and edits nothing under observation; if any of them warrants a
follow-up issue, the human authors it.

## Next steps

1. Commit this record on `issue-153/execution-observation` with a
   `Subject: issue-153` trailer and push it to PR #156; the orchestrator
   updates the PR body and merges.
2. Nothing further is owed by this role on issue #153. Step 2 of the
   issue's `## 실행 계획` is complete once this record is merged; the PR
   merge is the human's acceptance act, and issue closure is theirs.
3. No re-observation is scheduled: re-reading the same merged artifacts
   would produce the same verdict, and the role never re-executes what it
   observed.

## Resolution path

Findings 1–5 return to the human on PR #156 and nowhere else — this role
neither files issues nor edits the observed artifacts. Each finding's own
`**Action item**` paragraph states the concrete close for it, so the
resolution path per finding is:

- **Finding 1** — human decides the intended semantics for a
  frontmatter-less document, then a follow-up issue (human-authored) pins
  it with a `run_rf` case and either cites the gate that requires the
  fence or reclassifies the issue-140 `allow` fixture at
  `core/hooks/tests/run-role-gates-tests.sh:92`. Highest-value of the
  five; permissive direction, no live instance today.
- **Finding 2** — one added test case with a value-less field line
  followed by a non-conforming one; closes Acceptance check 2's second
  half as a real red→green pin. Cheap, mechanical.
- **Finding 3** — either extend the census to the 11 uncovered non-test
  hooks, or record the class boundary explicitly. Either resolves it; the
  missing artifact is the recorded judgment, not necessarily the work.
- **Finding 4** — one handbook sentence stating the region ends at the
  first closing fence. Lowest severity; documentation-only close.
- **Finding 5** — already resolved by this record stating the corrected
  count of 8; the landed commit message and PR body stay unedited under
  the no-retroactive-fix rule.

None of the five blocks merging PR #154's work, which is already on the
board; all five are follow-up material for the human to accept, defer, or
reject.

## Evidence tiers — what rests on the observed role's own assertion

- **Verified against the diff or against metadata this session read:**
  every claim in Verdicts 1–3 and Findings 1–5 above, except as listed
  next.
- **Rests on the observed role's own assertion, unverified here by
  choice:** the `56 passed, 0 failed` figure and the `run-all.sh` `ALL OK`
  result (`docs/issue-153/reports/implementation.md:106-111`, `:126-128`),
  and the directly-observed red→green on three cases (`:112-121`). The
  evidence plan forbade re-running the suite and bound the test file to
  its diff form, so the pre-existing case count could not be counted
  independently. What is checkable is internal consistency, and it holds:
  the diff adds exactly 7 assertions (6 `run_rf` plus 1 inline `report`),
  and 49 + 7 = 56. The residue is that the 49 is the observed role's
  number, and it is stated as residual rather than closed.
- **Rests on the observed role's hunt record:** the end-to-end
  reproductions at
  `docs/reports/2026-08-08-hunt-issue-153-narrow-sha-scan-scope-and-empty-value-carveout.md:150-200`,
  which were read, not re-run. Their conclusions are corroborated
  independently by the landed diff — the mark strip and the
  end-of-string-tolerant closing anchor are both visible in `3f67436` —
  so nothing in this record depends on the reproductions alone.
- **Measured by this session, independent of the observed role:** the
  corpus census (69 documents carrying such a field line at `6fd3b29`, 0
  without a leading `---` block, 2 with a field line outside it — both
  survey files quoting the pattern in prose, which is precisely the case
  F1 exists to unblock) and the 18-file non-test `*.sh` listing behind
  Finding 3.

## Proposal clause conformance

Against `docs/issue-153/proposals/2026-08-08-observe-pr-154-sha-scan-scope.md`:

- All three verdict levels addressed explicitly, none omitted. Done —
  Verdicts 1, 2, 3 above. No level turned out to be inapplicable, so no
  "not applicable, because X" line was needed.
- Every verdict-bearing sentence carries an adjacent SHA, `file:line`, or
  comment URL. Done.
- All six trajectory evidence items and all six step-level artifacts from
  the plan appear with the artifact each was read from, including the ones
  supporting the observed role's account (Verdict 2's findings of
  soundness; Verdict 3 items 5, 6, 7).
- No re-execution: the four named targets were not run; residual
  uncertainty is stated as residual in Evidence tiers above.
- `src`-side files read only through `git show 3f67436 -- <path>`. Held.
- No edits to the observed role's artifacts. Held — this branch writes
  this file and this role's own hunt record only.
- Gate-safe self-citation: no non-conforming field value is reproduced
  anywhere in this document in frontmatter shape; such values are named in
  prose (`HEAD`, `TBD`) instead.

## Verify

- `gh pr view 154 --json state,mergedAt,mergeCommit` → `MERGED`,
  `2026-08-08T02:44:54Z`, `6fd3b29211ec0d69d1cb587d71c457ea8243a4c7`.
- `gh issue view 153 --json comments` → two comments, both exact-string
  approvals by `jjongkwann`.
- `git show 3f67436 -- core/hooks/record-fields-gate.sh` → the
  `placeholder_shas` hunk behind Verdicts 1 and 3 and Findings 1, 2, 4.
- `git show 3f67436 -- core/hooks/tests/run-role-gates-tests.sh` → the 6
  `run_rf` additions, the inline probe, the 8 reshaped fixtures, and the
  unchanged `:92` context line behind Findings 1, 2, 5.
- `git show --stat 7036f95` → the three-file, docs-only phase-1 write set.
- `git ls-tree -r --name-only 6fd3b29` filtered to non-test `*.sh` → 18
  files, behind Finding 3.
