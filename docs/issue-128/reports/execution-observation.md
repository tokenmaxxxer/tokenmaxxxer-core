---
kind: observation-record
subject: issue-128
produced_by: execution-observation
observed_role: implementation
observed_pr: 129
loop_state: landed
upstream:
  - path: docs/issue-128/reports/execution-observation/survey.md
    sha: 0b1002c285a4a52391867744307e078351354101
  - path: docs/issue-128/reports/execution-observation/scout-brief.md
    sha: 0b1002c285a4a52391867744307e078351354101
  - path: docs/issue-128/proposals/2026-08-04-observe-pr-129-same-commit-sha-convention.md
    sha: 0b1002c285a4a52391867744307e078351354101
---

# Execution observation — issue-128, step 2

## Independence

This role did not author, and has not edited this session, any artifact
under observation. Nothing under `core/`, `test/`, `docs/handbooks/`, or
`docs/issue-128/reports/implementation*` was written or modified by this
session; `git status` on this branch shows exactly one changed path, this
file. No test, gate, or script belonging to the observed delivery was
re-run — the observed role's produced artifacts (the PR diff, its two
commits, its own record, the PR/issue metadata, and its session
transcript) are the whole evidence set used below. No issue was filed;
findings return only in this record, on this role's own PR, for the human
to judge.

This statement precedes every verdict sentence in this document
deliberately, per contract §19's ordering requirement for this role.

## Why

Issue #128's `## 실행 계획` lists two steps: step 1 `implementation`
(landed as PR #129, merge commit `d588e95`), step 2 this role's
independent observation of that execution. Phase 2 of this role opened on
the issue-level comment whose entire body is `APPROVE
issue-128/execution-observation`, posted by `jjongkwann` — listed in
`docs/specs/approvers.md` — at 2026-08-04T07:07:40Z
(<https://github.com/tokenmaxxxer/tokenmaxxxer-core/issues/128#issuecomment-5175726099>).
`jjongkwann` is also this PR's author, so the single-account path of
contract §19 applies. String equality was checked, not read as prose: the
comment body is exactly that string and nothing else.

The evidence design executed below is the one approved in
`docs/issue-128/proposals/2026-08-04-observe-pr-129-same-commit-sha-convention.md`
(commit `0b1002c`), unchanged.

## What was done

Executed the approved proposal's three-level verdict design against PR
#129's two commits (`6963e3b` phase 1, `6486c4b` phase 2), the observed
role's own record and phase-1 artifacts, the issue and PR metadata, and —
for the one ordering question the committed artifacts could not settle —
the observed session's own transcript. Ran the two read-only repo sweeps
the proposal committed to (placeholder-shape and path-scope), and the
three named probes. Wrote this record; no other file was written.

## What was read this session, first-hand

| Artifact | How read | Tier |
| --- | --- | --- |
| Issue #128 body and both comments | `gh issue view 128`; `gh api repos/.../issues/128/comments` with exact bodies printed via `repr()` | metadata |
| PR #129 metadata, reviews, commits | `gh pr view 129 --json ...` — `state: MERGED`, `mergeCommit d588e95`, `reviews: []` | metadata |
| PR #131 metadata, reviews | `gh pr view 131 --json reviews,comments` — both empty | metadata |
| Commit `6963e3b` message + `--stat` | `git log -1`, `git show --stat` — 3 files, +450, all under `docs/issue-128/` | diff |
| Commit `6486c4b` full diff | `git show 6486c4b -- core/hooks/record-fields-gate.sh` and `-- core/contract/... run-role-gates-tests.sh docs/handbooks/...` | diff |
| The gate file **as delivered at `6486c4b`** | `git show 6486c4b:core/hooks/record-fields-gate.sh` (lines 95-200) — used for control-flow order, never the working tree | diff |
| `docs/issue-128/reports/implementation.md` | read in full, 193 lines | the observed role's own assertion |
| `docs/issue-128/proposals/2026-08-04-build-same-commit-upstream-sha-convention.md` | read in full, 178 lines | the observed role's own assertion |
| `docs/issue-128/reports/implementation/survey.md`, `.../scout-brief.md` | read (survey §§ around lines 10-18, 43-45, 83; brief in full) | the observed role's own assertion |
| Contract §1, §12, §19, §20 | `core/contract/role-handoff-contract.md:16`, `:460`, `:672`, `:827-870` | the standard being applied |
| Observed session transcript (phase-1 session) | `~/.claude/projects/-Users-jk--tokenmaxxxer-work-tokenmaxxxer-core-issue-128-implementation/8a50b3a6-….jsonl`, tool-call sequence extracted by timestamp | the observed session's own record |
| Repo-wide sweeps | `grep`/`sed` value-shape tally over `docs/**/*.md`, read-only | first-hand inspection |

Deliberately **not** read as evidence of what happened: the working-tree
contents of `core/hooks/record-fields-gate.sh`,
`core/hooks/tests/run-role-gates-tests.sh`, or the contract's §1/§12 text
as delivered. Working-tree source shows what exists now, not what that
session produced; `6486c4b`'s diff and blob are the admissible record.

## Verdict 1 — outcome: did PR #129 land what issue #128 asked

**PASS, with one gap in requirement 3's coverage** (detailed as Finding 1).
Forward and backward traceability were both checked.

**Requirement 1 — decide the canonical same-commit citation, comparing
(a)/(b)/(c).** Met. The proposal's `## Rationale`
(`docs/issue-128/proposals/2026-08-04-build-same-commit-upstream-sha-convention.md:49-114`)
selects candidate (a) `sha: same-commit` and carries one dedicated
rejection paragraph each for (b) two-commit phase 1 (`:71-81`) and (c)
gate-enforced post-commit amend (`:83-94`); all three candidates the issue
named are addressed, and the choice is stated once, unambiguously (`:49`).

**Requirement 2 — codify the decision in the record-norm text the issue
calls "계약 §20 계열".** Met on substance, with the section number
transparently reinterpreted before approval. `6486c4b`'s contract diff adds
an 8-line bullet to §1's `upstream[].sha` bullet list and an 8-line
**Same-commit exemption** paragraph to §12, and touches no line of §20
(`git show 6486c4b -- core/contract/role-handoff-contract.md`, both hunks
at `@@ -36,6 +36,14 @@` and `@@ -468,6 +476,14 @@`). Read against §20's own
text (`core/contract/role-handoff-contract.md:827-870`), §20 is
"Per-role record minimum content" — a list of what a record must *state* —
and contains no frontmatter-field-shape clause a `sha:` convention could
be attached to; §1 (`:16-38`) is the sole normative definition of the field
and §12 (`:460`) its only consumer, which is exactly what the observed
role's own survey concluded (`docs/issue-128/reports/implementation/survey.md:10-11`).
This resolves survey unknown 1: §1/§12 is the correct home, not a
substitution for the asked-for one. The restatement was not silent — the
proposal's `## Request` states the target as "the contract's own
record-norm text (§1/§12 family)" at `…-convention.md:30-31`, i.e. in the
document the human approved at 06:48:33Z, so the reinterpretation was
visible to the approver before the approval and needed no separate flag.

**Requirement 3 — judge whether to mechanically reject a leftover
placeholder, and design the check.** Judged yes and designed
(`…-convention.md:96-114`), and delivered: `6486c4b` adds `PROPOSALS_RE`,
a `placeholder_shas()` helper, a `deny_placeholder()` message, an
`is_proposal and not is_record` early-exit, and one call of the same check
on the record path (`git show 6486c4b -- core/hooks/record-fields-gate.sh`,
hunks at `@@ -107,6 +115,7 @@`, `@@ -133,8 +142,10 @@`, `@@ -157,6 +168,22 @@`,
`@@ -184,6 +211,10 @@`). The gap is that the delivered check's shape is
narrower than the defect class the issue names — see Finding 1.

**Constraint — no retroactive fix to existing placeholder instances.**
Honoured. `git show --stat 6486c4b` lists five files
(`core/contract/role-handoff-contract.md`,
`core/hooks/record-fields-gate.sh`, `core/hooks/tests/run-role-gates-tests.sh`,
`docs/handbooks/role-gates-tests.md`,
`docs/issue-128/reports/implementation.md`); none is a pre-existing issue
tree document, and the 23 `<set at commit>` instances this session's sweep
counts across `docs/` are untouched by both commits.

**Constraint — existing `record-fields-gate.sh` checks unchanged.**
Honoured as to check *logic*: in the `@@ -184,6 +211,10 @@` hunk the only
added lines are the four-line `bad = placeholder_shas(new_text)` call, with
the five §20 `missing` checks and the `code_under_review` bare-sha block
present only as unchanged context. The scope *gate* did widen, which is
what the change required, but that widening also re-homes two pre-existing
fail-closed guards onto proposal writes — see Finding 2.

**Backward traceability.** Every hunk in `6486c4b` maps to a requirement:
the two contract hunks to requirement 2, the four gate hunks and the five
test cases to requirement 3, the handbook paragraph to the doctrine-ladder
rule the record cites (`docs/issue-128/reports/implementation.md:87-89`),
the record itself to §11/§19. Nothing landed that no requirement asked for.

## Verdict 2 — trajectory: was the phase-1 → phase-2 path sound

**SOUND on all four checks.**

**Phase-1 completeness.** `git show --stat 6963e3b` is exactly three files
— the survey, the scout brief, and the proposal, +450 lines, all under
`docs/issue-128/` — with no `core/`, `test/`, or handbook line in it, so no
execution work landed before the Approve. Against §19's phase-1 bar
(`core/contract/role-handoff-contract.md:672-730`): the proposal carries an
enumerable clause checklist (`…-convention.md:125-149`, five numbered
items), two named alternatives each with a stated reason
(`:71-81` and `:83-94`, plus a third rejected alternative — a separate gate
script — at `:100-114`), and an explicit `**Failure signal.**` paragraph
(`:116-123`).

**Approval validity.** The comment body is exactly `APPROVE
issue-128/implementation`, author `jjongkwann`, created 2026-08-04T06:48:33Z
(<https://github.com/tokenmaxxxer/tokenmaxxxer-core/issues/128#issuecomment-5175563333>,
body compared by `repr()` this session, not paraphrased); `jjongkwann` is
listed in `docs/specs/approvers.md` and is PR #129's author
(`gh pr view 129 --json author`), so §19's single-account path is the
applicable one and its exact-string condition is met. Ordering holds:
`6963e3b` authored 06:47:26Z → PR #129 created 06:47:51Z → Approve
06:48:33Z → `6486c4b` authored 06:58:26Z → merged 06:59:26Z
(`gh pr view 129 --json commits,createdAt,mergedAt`). No phase-2 line
exists before the approval. This resolves survey unknown 6.

**Survey-before-scout, scout-before-proposal ordering.** Sound in
substance; one ordering nuance recorded rather than charged as a defect.
The scout brief states its own mode and stage count — stage 1 a reuse of
`docs/issue-100/reports/implementation/scout-brief.md`, then one deepening
round of three genuinely parallel `WebSearch` calls, stopped at judge point 1
(`docs/issue-128/reports/implementation/scout-brief.md:9-21`) — but is
silent on whether the survey preceded it, which is why the proposal
provided for reading the transcript. The transcript settles it: the
survey's entire evidence-gathering pass ran 06:38:32Z–06:41:14Z (the issue
read, the `docs/` inventory, the `upstream[]` and `staleness` greps, the
`grep -rn "set at commit"` sweep at 06:39:07Z, the issue-100/issue-118
reads), the three `WebSearch` calls fired together at 06:41:35–36Z, and the
three files were written at 06:45:26Z (survey), 06:45:50Z (brief),
06:47:12Z (proposal) — transcript
`8a50b3a6-d7d1-4518-a7bd-d0a6ca014e4f.jsonl`, tool-use entries at lines
22-115 and 141-150. So the sweep aimed at gaps the survey work had already
surfaced (the brief's gap line and candidate-(b) rejection both cite
survey findings from that window), and the proposal came last; only the
survey *file's* write trails the sweep by four minutes. This resolves
survey unknown 5, which the phase-1 survey had left unverifiable.

**Delivery-to-proposal conformance.** All five `## What will be done`
clauses landed. Clause 1 → the §1 bullet hunk (`6486c4b`,
`@@ -36,6 +36,14 @@`); clause 2 → the §12 exemption hunk
(`@@ -468,6 +476,14 @@`); clause 3 → the four gate hunks; clause 4 → the
five `run_rf` cases (`@@ -80,6 +80,23 @@` of
`core/hooks/tests/run-role-gates-tests.sh`); clause 5 → the handbook
paragraph (`@@ -25,6 +25,17 @@` of `docs/handbooks/role-gates-tests.md`).
One narrowing, immaterial: clause 4 promised a real "7-40-hex-char sha"
allow case and the delivered case uses a 40-char sha only
(`run-role-gates-tests.sh` case "proposal sha real hex allowed") — the
delivered check does not inspect hex length at all, so the 7-char end
exercises no distinct path.

## Verdict 3 — step: which specific artifact, if any, is deficient

Three probes, each closed.

**Probe A — false-negative probe of the new regex: FINDING** (Finding 1).
The delivered pattern is
`^\s*sha:\s*(<[^\n]*>)\s*$` with `re.M` (`6486c4b`,
`core/hooks/record-fields-gate.sh`, `placeholder_shas()`). Traced by hand
against candidate inputs: a non-bracket unresolved value (`sha: HEAD`,
`sha: TBD`) never reaches the group's required leading `<`, so it is
admitted; a bracketed value with trailing prose (`sha: <set at commit> —
fix later`) fails the closing `\s*$` after backtracking and is admitted; a
quoted placeholder (`sha: "<set at commit>"`) fails the leading `<` and is
admitted. Of these, one is not hypothetical — see Finding 1.

**Probe B — path-scope probe: NO FINDING as to live instances, one
structural gap recorded.** `PROPOSALS_RE` matches
`^docs/issue-[0-9]+/proposals/.*\.md$` and `RECORDS_RE` only a role's own
`^docs/issue-[0-9]+/reports/<role>\.md$` (`6486c4b`, both at the
`@@ -107,6 +115,7 @@` and `@@ -133,8 +142,10 @@` hunks). A read-only sweep
of every bracket-placeholder `sha:` line in `docs/` this session returns 23
instances in exactly two homes — `docs/issue-<n>/proposals/*.md` (21) and
`docs/issue-46/reports/coding.md` / `docs/issue-49/reports/coding.md` (2) —
both of which the two patterns do match, so the live population is covered.
The structural gap: `docs/issue-<n>/decisions/` carries live
`upstream[].sha` frontmatter
(`docs/issue-100/decisions/2026-08-03-record-citation-format-and-kind-convention.md:5-7`,
value a real 40-hex sha) in a home neither pattern matches. The
`reports/<role>/` subtree is clear — its single sweep hit,
`docs/issue-128/reports/implementation/survey.md:17`, is inside a fenced
quotation of the contract's own field template
(`…/survey.md:12-18`), not a live frontmatter field.

**Probe C — record-content probe against §20: NO FINDING.**
`docs/issue-128/reports/implementation.md` satisfies §20's list
(`core/contract/role-handoff-contract.md:835-862`): item 1 at
`## What was done` (`:24-72`), item 2 at `## Why` (`:14-22`) with the
rejected alternative carried at `## Doc-placement ladder` (`:81-86`), item
3 via the frontmatter `upstream` entry with a real resolved sha
`6963e3bc…` (`:7-9`), `loop_state: landed` (`:6`), and `## Resolution path`
(`:159-162`); items 4 and 5 at `## Next steps` (`:150-157`) and the same
resolution-path section. Item 6 (defect class and other habitats) does not
apply, because that record states no confirmed `finding` — both hunt
stances close `Verdict: NO FINDING` (`:104`, `:122`) — and §20 conditions
item 6 on a confirmed finding existing (`:855-857`). Recorded here rather
than omitted, per the three-level rule.

## Findings

### Finding 1 — the placeholder check misses a live, in-scope non-bracket placeholder

**Impact.** `docs/issue-20/proposals/2026-07-31-build-gh-guard-endpoint-match.md:4-7`
carries `upstream: - path: docs/issue-20/reports/implementation/survey.md`
with `sha: HEAD` — the exact same-commit citation case issue #128 exists to
fix, spelled without brackets. That file's path matches `PROPOSALS_RE`, and
the delivered regex admits the value (traced above, Probe A). The gate
therefore stops one spelling of the defect while leaving the class open: a
future session writing `sha: HEAD`, `sha: TBD`, or a bracketed value with
trailing prose passes the new check and reproduces the recurrence #128 was
opened to end. Severity is moderate, not critical — the convention is now
in the contract (`6486c4b`, §1 hunk) and the dominant spelling (23 of 24
live instances) is caught.

**Timeline.** 06:39:07Z the observed session ran
`grep -rn "set at commit" --include="*.md" .` (transcript
`8a50b3a6-….jsonl`, tool-use entry at line 67), fixing the measured
population to that one literal; the survey records that grep as the sweep
(`docs/issue-128/reports/implementation/survey.md:43-45`). 06:47:12Z the
proposal specified the check as denying "only the literal
bracket-placeholder shape (`^<.*>$`)" and explicitly declined to
allow-list legal values (`…-convention.md:112-114`). 06:48:33Z approved.
06:58:26Z delivered at that shape (`6486c4b`).

**Root cause.** The sweep that sized the problem was keyed to a literal
string rather than to the field's value shape, so the design inherited the
literal's syntax as the whole defect class. A shape-agnostic tally of every
`sha:` value under `docs/` — run read-only this session — returns 51 real
hex, 23 `<set at commit>`, 4 `same-commit`, 1 `HEAD`, 1 `<commit SHA the
artifact was read at>`; the `HEAD` instance is invisible to a
`<set at commit>` grep and immediate in a value tally.

**Action item.** For the human to judge, not for this role to file: invert
the check from deny-list to allow-list — deny any `sha:` value that is
neither 7-40 hex nor the literal `same-commit` — which covers the class the
issue names in the same one-regex footprint. The existing instance at
`docs/issue-20/…:7` is out of scope for repair under issue #128's own
no-retroactive-fix constraint; only the check's shape is in scope.

**Defect class and other habitats (§20 item 6).** Class: *an unresolvable
value stand-in admitted because the guard is keyed to one spelling rather
than to the value's shape.* Swept this session, read-only and repo-wide,
in two directions. (i) Other value shapes: the tally above — one
non-bracket instance, named. (ii) Other document homes carrying the same
field outside the two matched patterns: `docs/issue-<n>/decisions/` carries
live `upstream[].sha`
(`docs/issue-100/decisions/2026-08-03-…-convention.md:5-7`) and is matched
by neither pattern; there is no standing `docs/decisions/` directory in
this tree (`ls docs/decisions/` → No such file or directory); per-issue
`reports/<role>/` subtrees carry no live `sha:` field today. No placeholder
currently sits in the uncovered decisions home, so this half of the sweep
records an exposure, not a live defect.

### Finding 2 — proposal writes newly inherit two §20-worded fail-closed guards

**Impact.** Before `6486c4b`, a `docs/issue-<n>/proposals/*.md` write left
this gate immediately at the path check — the deleted line
`if not RECORDS_RE.match(rel): sys.exit(0)` in the `@@ -133,8 +142,10 @@`
hunk. After it, `is_proposal` passes the scope gate, and the new
narrow check's early exit (`if is_proposal and not is_record:`) sits
*below* two pre-existing fail-closed guards in the delivered file
(`git show 6486c4b:core/hooks/record-fields-gate.sh`, control-flow order:
scope match → read existing file → `gate_reconstruct_write` → `new_text is
None` deny → `placeholder_shas` def → proposal early exit). So a proposal
write whose resulting content the gate cannot reconstruct, or whose
existing file cannot be read, is now refused with a message describing
§20 record fields — "failing closed on §20" and "Write the full record
with Write … so §20 fields can be checked" — checks a proposal write never
runs. Severity low: the reconstruct path returns non-`None` for any plain
`Write`, so this bites only unreconstructable `Edit`/`MultiEdit` shapes.

**Timeline.** The proposal promised "Existing checks and their path scope
are unchanged" (`…-convention.md:141-142`) and the record repeats the
claim, scoped to the five §20 checks and the `code_under_review` check
(`docs/issue-128/reports/implementation.md:44-51`). Both statements are
true of those checks; neither statement covers the two guards above, which
sit outside the record-path branch and were therefore not in view.

**Root cause.** The scope match was widened at the top of the function
while the new narrow check was inserted below two guards that were written
when only record paths could reach them; nothing in the change re-examined
what else the widened scope now admits.

**Action item.** For the human to judge: move the `is_proposal and not
is_record` branch above the existing-file read and the reconstruct block,
or reword the two messages to be artifact-kind-neutral.

**Defect class and other habitats (§20 item 6).** Class: *a scope widening
that silently re-homes pre-existing fail-closed guards onto a new artifact
kind.* Swept: `record-fields-gate.sh` is the only file in `6486c4b` whose
path-matching was touched, and `PROPOSALS_RE` is the only path class added
(`git show 6486c4b -- core/hooks/record-fields-gate.sh`, one added
`PROPOSALS_RE` line); `git show --stat 6486c4b` shows no other gate script
in the commit, so no sibling gate acquired a new path class here.

## Open findings

Findings 1 and 2 are open as of this record and are raised for the human
to judge on this PR. Neither is filed as an issue — under contract v3
issues are user-authored only, and this role does not file them. Neither
is repaired here: both live under the observed role's `core/` paths, which
this role never edits. Resolution path: the human decides whether either
warrants a follow-up issue; if one is opened, it belongs to a role that
owns `core/hooks/`, not to this one.

## Evidence tiers — what rests on the observed role's own assertion

Stated plainly so the human can weigh each claim:

- `role-gates: 24 passed, 0 failed`, `run-all.sh → ALL OK`, and the
  `gate-lib: 53 passed, 1 failed` pre-existing-failure attribution with its
  `git stash` A/B comparison exist only as text in the observed role's own
  record (`docs/issue-128/reports/implementation.md:166-185`). Re-running
  that suite is prohibited for this role, so none of it is independently
  confirmed here. The available inspection-tier substitute was run: all
  five new `run_rf` cases were traced by hand against the delivered regex
  and control flow, and each behaves as its label asserts — in particular
  the "record sha bracket placeholder denied despite complete §20 fields"
  case supplies all five §20 fields, so it genuinely proves the new check
  fires independently of them (`6486c4b`,
  `core/hooks/tests/run-role-gates-tests.sh`, `@@ -80,6 +80,23 @@`).
- The two `## Hunt` stances' `NO FINDING` verdicts and the stated
  unavailability of the `warrant-hunter` subagent
  (`docs/issue-128/reports/implementation.md:95-136`) are that session's
  own account. The first stance's substance — that `^\s*sha:\s*` cannot
  match `acknowledged_sha:`/`code_sha:` — was independently re-traced this
  session and is correct.
- Everything in Verdicts 1-3 above other than the two items in this section
  rests on the diff, the delivered blob at `6486c4b`, the transcript, the
  issue/PR metadata, or this session's own read-only sweeps.

## Proposal clause conformance (C1-C10)

- C1 fulfilled — this file written as the first act of phase 2, `loop_state`
  `observing` at write, updated to `landed` before commit.
- C2 fulfilled — `## Independence` precedes every verdict sentence.
- C3 fulfilled — `## Verdict 1`, requirements 1-3 and both constraints, each
  with an adjacent citation.
- C4 fulfilled — `## Verdict 2`, all four sub-checks.
- C5 fulfilled — `## Verdict 3`, probes A/B/C, each closing as a finding or
  an explicit no-finding.
- C6 fulfilled — every verdict sentence names a commit sha, `file:line`, or
  URL adjacent to it.
- C7 fulfilled — Findings 1 and 2 each carry impact / timeline / root cause
  / action item.
- C8 fulfilled — each finding carries its defect class and the
  other-habitats sweep result.
- C9 fulfilled — no file outside this one was written in phase 2; no issue
  filed; nothing under the observed role's paths edited.
- C10 fulfilled — `## Evidence tiers` names every claim resting on the
  observed role's own assertion.

Survey unknowns 1, 5 and 6 are resolved above; unknowns 2, 3 and 4 are
resolved by Finding 1's sweep, Probe B, and `## Evidence tiers`
respectively.

## Verify

- `git status --short` on branch `issue-128/execution-observation` lists
  only `docs/issue-128/reports/execution-observation.md` — no observed-role
  path touched.
- Every sha, `file:line`, and URL cited above was produced by a command run
  in this session; no citation was copied from another document's claim.
- This record's own `upstream[].sha` entries are real resolved 40-hex
  values, because the phase-1 artifacts they cite landed in the earlier
  commit `0b1002c` — the `same-commit` literal is correctly *not* used here.
