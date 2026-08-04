---
kind: observation-record
subject: issue-133
produced_by: execution-observation
observed_role: implementation
observed_pr: 134
loop_state: landed
upstream:
  - path: docs/issue-133/reports/execution-observation/survey.md
    sha: 90c1632bb4799bbd9a742d56939f5ee21274c0df
  - path: docs/issue-133/reports/execution-observation/scout-brief.md
    sha: 90c1632bb4799bbd9a742d56939f5ee21274c0df
  - path: docs/issue-133/proposals/2026-08-04-observe-pr-134-sha-whitelist.md
    sha: 90c1632bb4799bbd9a742d56939f5ee21274c0df
---

# Execution observation — issue-133, step 2

## Independence

This role did not author and has not edited any artifact under observation.
Nothing under `core/`, `test/`, `docs/handbooks/`, or the observed role's
`docs/issue-133/reports/implementation.md` / `docs/issue-133/reports/implementation/`
/ `docs/issue-133/proposals/2026-08-04-build-sha-whitelist-check.md` was
written by this session; the only file this session writes is this record.
No test, gate, or script belonging to the observed delivery was executed,
and no re-implementation of its task was performed — every claim below
rests on inspection of committed artifacts, GitHub metadata, or read-only
`grep` over the documentation corpus. Where a claim rests on the observed
role's own assertion rather than on something this role could inspect, it
is labelled as such at the point of use and again under
`## Evidence tiers`.

No issue was filed from this session. Findings return here, on this role's
own PR, for the human to judge and to file if they judge them valid.

## Why

Phase 2, opened by the issue-level comment whose entire body is
`APPROVE issue-133/execution-observation`, posted by `jjongkwann` (listed
in `docs/specs/approvers.md`) at `2026-08-04T10:29:45Z`
(<https://github.com/tokenmaxxxer/tokenmaxxxer-core/issues/133#issuecomment-5177782930>).
This role's PR #136 is authored by `jjongkwann` as well
(`gh pr list --head issue-133/execution-observation --json author`), so
contract v3 §19's single-account path is the applicable one and the
issue-level exact-string comment is the valid approval route.

Issue #133's `## 실행 계획` lists two steps; step 1 (`implementation`)
landed as PR #134, step 2 is this observation. This record delivers the
three-level verdict the approved phase-1 proposal
(`90c1632:docs/issue-133/proposals/2026-08-04-observe-pr-134-sha-whitelist.md`)
committed to producing.

## What was done

Read PR #134's metadata, both of its commits and their full diffs, the
delivered gate/test/handbook blobs at `778b810`, the observed role's own
phase-1 and phase-2 artifacts, the pre-change blob at `778b810^`, the
issue and its comments, `docs/specs/approvers.md`, the observed phase-1
session transcript (for write ordering only), and the documentation corpus
by read-only `grep`. Rendered the three verdicts below — outcome,
trajectory, step — against that evidence, ran the four probes P1-P4 the
approved proposal named, and recorded two confirmed step-level findings
plus one class-habitat sweep result.

## What was read this session, first-hand

| Artifact | How read |
| --- | --- |
| Issue #133 body | `gh issue view 133` — `## 요구사항` 1-3, `## 제약`, `## 실행 계획` |
| Issue #133 comments | `gh api repos/tokenmaxxxer/tokenmaxxxer-core/issues/133/comments` with author, timestamp, `html_url` — two comments |
| PR #134 metadata | `gh pr view 134 --json number,title,author,state,mergedAt,mergeCommit,createdAt,url,additions,deletions,reviews,comments` |
| PR #134 changed paths | `gh pr diff 134 --name-only` — six paths |
| PR #136 metadata (this role's own) | `gh pr list --head issue-133/execution-observation --json number,state,url,title,author,createdAt` |
| Commit `de2b09c` | `git show --stat` + both files in full |
| Commit `778b810` | `git show --stat`; full diffs of `core/hooks/record-fields-gate.sh`, `core/hooks/tests/run-role-gates-tests.sh`, `docs/handbooks/role-gates-tests.md` |
| Gate **as delivered** at `778b810` | `git show 778b810:core/hooks/record-fields-gate.sh`, lines 100-300 — never the working tree, for any what-happened claim |
| Gate **before** the change | `git show 778b810^:core/hooks/record-fields-gate.sh:165-190` |
| Test harness as delivered | `git show 778b810:core/hooks/tests/run-role-gates-tests.sh`, the issue-128 and issue-133 case blocks |
| Observed record | `git show 778b810:docs/issue-133/reports/implementation.md` — in full |
| Observed proposal | `git show de2b09c:docs/issue-133/proposals/2026-08-04-build-sha-whitelist-check.md` — in full |
| Observed survey | `git show de2b09c:docs/issue-133/reports/implementation/survey.md` |
| Observed phase-1 transcript | `grep -n -o '"file_path":"…"'` for the two phase-1 paths, first-occurrence order only |
| `docs/specs/approvers.md` | in full — two accounts, `JiwonJung94` and `jjongkwann` |
| Corpus of `upstream` sha values | `grep -rEn "^[[:space:]]*sha:" --include="*.md" docs/` (91 lines) plus targeted greps for empty, abbreviated, and non-conforming values |
| Sibling gates, for the P4 class sweep | `grep -nE "re\.(match\|search\|finditer\|fullmatch)"` over `core/hooks/trailer-gate.sh`, `core/hooks/handbook-trigger-gate.sh`, `core/hooks/tests/stub-check.sh`, plus `stub-check.sh:110-130` |

Read as the *standard being applied*, not as evidence of what happened:
the role-handoff contract's §19/§20, and this role's own phase-1 artifacts
at `90c1632`.

## Verdict 1 — outcome: did PR #134 land what issue #133 asked

**Verdict: the PR landed what the issue asked, with one clause of
requirement 1 undelivered** — the empty-value carve-out, Finding 2 below.
PR #134 is `MERGED`, merged `2026-08-04T07:35:51Z` as merge commit
`6236f9b5cf93ed880a3b362d892bf53888956b97` (`gh pr view 134 --json
state,mergedAt,mergeCommit`).

**Requirement 1 — convert the check to an allow-list.** Delivered. The
helper's body at `778b810:core/hooks/record-fields-gate.sh:174-181` now
iterates every `^\s*sha:\s*(.*)$` match, strips the captured value, and
`continue`s only when the value is exactly `same-commit` or matches
`^[0-9a-f]{40}$`, appending everything else to `bad`; the pre-change body
at `778b810^:core/hooks/record-fields-gate.sh:171-172` was a single
comprehension over `^\s*sha:\s*(<[^\n]*>)\s*$`, i.e. bracket-shaped values
only. That is a deny-list→allow-list inversion in exactly the shape
requirement 1 names. Traced by hand against the delivered pattern (no
execution): the literal `same-commit` and a lowercase 40-hex value both
hit the `continue`; every other value reaches `bad.append(v)`. The
carve-out clause of the same requirement ("빈 upstream 은 기존 규약대로",
`gh issue view 133`, `## 요구사항` item 1) is **not** delivered — see
Finding 2 at `778b810:core/hooks/record-fields-gate.sh:174-181`.

**Requirement 2 — red→green across the three unresolved spellings, the two
valid forms still passing.** The **green** half is delivered and inspected:
three `run_rf deny` cases at
`778b810:core/hooks/tests/run-role-gates-tests.sh:101-109` cover the values
`HEAD`, `TBD`, and a bracket placeholder with trailing prose, and the two
valid forms keep their pre-existing `run_rf allow` cases at
`778b810:core/hooks/tests/run-role-gates-tests.sh:87-92` and `:96-98`,
which the diff leaves outside every changed hunk (`git show 778b810 --
core/hooks/tests/run-role-gates-tests.sh`, one hunk, `@@ -97,6 +97,17 @@`,
additions only). The **red** half rests on the observed role's own
assertion, not on anything this role could inspect: the pre-fix run is
described in prose at `778b810:docs/issue-133/reports/implementation.md`,
`## Verify`, final paragraph, which states the pre-fix script was extracted
with `git show HEAD:…` and run as a subprocess, and states that scratch
check was not committed. The two halves therefore rest on different
evidence tiers, and this record does not present them as equally
established — see `## Evidence tiers` and probe P3.

**Requirement 3 — no retroactive fix to the live unresolved instance.**
Delivered. `gh pr diff 134 --name-only` returns exactly six paths —
`core/hooks/record-fields-gate.sh`,
`core/hooks/tests/run-role-gates-tests.sh`,
`docs/handbooks/role-gates-tests.md`,
`docs/issue-133/proposals/2026-08-04-build-sha-whitelist-check.md`,
`docs/issue-133/reports/implementation.md`,
`docs/issue-133/reports/implementation/survey.md` — none of them under
`docs/issue-20/**`, and both commits' stats agree (`git show --stat
de2b09c`: 2 files; `git show --stat 778b810`: 4 files). The gate's
new-writes-only property is structural and untouched by this change: the
script exits at `778b810:core/hooks/record-fields-gate.sh:141-142` unless
the tool call is a `Write`/`Edit`/`MultiEdit`/`NotebookEdit` carrying a
path, so a file nobody writes to never reaches the check.

**Constraint — issue-128's landing convention and the five §20 checks
unchanged.** Held. The `778b810` diff of the gate contains exactly two
hunks (`@@ -12,11 +12,14 @@` and `@@ -169,13 +172,19 @@`); the five §20
`missing` checks at `778b810:core/hooks/record-fields-gate.sh:201-214`,
the `code_under_review` check at `:227-235`, the non-terminal
`loop_state` branch at `:236-248`, and both `PROPOSALS_RE`/`RECORDS_RE`
definitions at `:120-121` all sit outside both hunks. Both call sites
still invoke the same helper — proposal path at `:190-194`, record path at
`:223-225` — and `same-commit` remains the canonical value, allowed at
`:178`.

**Backward direction — what landed that no requirement asked for.** Four
files changed at `778b810`; every hunk maps to a requirement or to a
disclosed deviation. The gate's helper and denial-message hunk maps to
requirement 1 and to the observed proposal's `## What will be done` items
1-2; the test hunk maps to requirement 2 and item 3; the handbook hunk
(`git show 778b810 -- docs/handbooks/role-gates-tests.md`, +11/−8 in one
paragraph) maps to item 4; the record file is the phase-2 record itself.
The one hunk no requirement asked for is the gate's top-of-file comment
rewrite at `778b810:core/hooks/record-fields-gate.sh:12-19`, and it is
disclosed by the observed role under
`778b810:docs/issue-133/reports/implementation.md`, `## Rationale for
deviations`, as a same-file same-turn consistency fix. Nothing unmapped
remains.

## Verdict 2 — trajectory: was the phase-1 → phase-2 path sound

**Verdict: sound at every checked point.**

**Phase-1 completeness.** `git show --stat de2b09c` shows two files,
`+347`, both phase-1 homes — the proposal and the survey — and no
execution work whatsoever in that commit; the gate, the tests, and the
handbook first appear at `778b810`. The proposal carries an enumerable
clause checklist (`de2b09c:docs/issue-133/proposals/2026-08-04-build-sha-whitelist-check.md`,
`## What will be done`, items 1-4), two named alternatives each with a
stated reason (`## Rationale`: a YAML-parser rewrite, rejected for adding
a non-stdlib dependency and a new fail-closed surface; a 7-40 hex range,
rejected against the issue's own literal 40-character wording), and a
`**Failure signal.**` paragraph naming the observable that would prove the
choice too strict. Contract §19's phase-1 requirements are met.

**Approval validity.** The observed role's phase 2 opened on the
issue-level comment whose entire body is `APPROVE issue-133/implementation`,
author `jjongkwann`, `2026-08-04T07:27:17Z`
(<https://github.com/tokenmaxxxer/tokenmaxxxer-core/issues/133#issuecomment-5175895602>).
`jjongkwann` is listed in `docs/specs/approvers.md` (read in full this
session: `JiwonJung94`, `jjongkwann`) and is PR #134's author (`gh pr view
134 --json author` → `login: jjongkwann`), so §19's single-account
exact-string path is the right one and the string matches exactly. PR #134
carries `reviews: []` and `comments: []` (`gh pr view 134 --json
reviews,comments`), which is consistent: under the single-account path no
PR review Approve is expected. Timestamp ordering holds strictly —
`de2b09c` committed `2026-08-04T07:24:31Z` → PR #134 created
`2026-08-04T07:26:23Z` → approval comment `07:27:17Z` → `778b810`
committed `2026-08-04T07:34:46Z` → merge `07:35:51Z`. No phase-2 artifact
predates the approval.

**Scout-skip validity** (this role's phase-1 survey left it open as
unknown 4). Resolved from the committed artifacts, no finding. The skip
record exists with its one-line reason as the scout directive requires
(`de2b09c:docs/issue-133/reports/implementation/survey.md`, `## Scout skip
record`), and the reason survives inspection: issue #133's requirement 1
pins the allow-list shape verbatim, so the "what should the value shape
be" question the sweep would have aimed at was closed by the spec before
phase 1 began. The tension this role's survey flagged — that the same
commit's proposal rejects two alternatives — does not overturn it: both
rejections are implementation-approach rationale (which parser style; which
length the issue already fixed), not open product-facing direction. One
nit, not raised as a finding: the skip record cites the "no design decision
open" condition where the "pure bugfix" condition fits at least as
squarely, since the proposal itself characterises the work as a same-file
regex fix against a named defect (`de2b09c:…build-sha-whitelist-check.md`,
`## Rationale`, first paragraph). Either condition is a valid skip.

**Phase-1 internal ordering** (survey unknown 5). Survey-first order held.
`de2b09c` contains both files in one commit and so cannot settle it, but
the observed session's own phase-1 transcript can: in
`~/.claude/projects/-Users-jk--tokenmaxxxer-work-tokenmaxxxer-core-issue-133-implementation/99273927-d8d4-41f2-8205-6c6dd4dff7b6.jsonl`,
the first `file_path` occurrence of `docs/issue-133/reports/implementation/survey.md`
is at transcript line 110 and the first occurrence of
`docs/issue-133/proposals/2026-08-04-build-sha-whitelist-check.md` is at
line 115 — the survey write precedes the proposal write. Reading the
observed session's transcript is reading that session's own record, not a
re-execution of its task. The committed artifacts point the same way
independently: the proposal's frontmatter cites the survey as its sole
`upstream` entry and its `## Request` closes by referring the reader to the
survey's `## Scout skip record` by name (`de2b09c:…build-sha-whitelist-check.md`).

**Delivery-to-proposal conformance.** All four `## What will be done`
clauses are fulfilled, each traceable to a hunk: item 1 (allow-list regex)
→ `778b810:core/hooks/record-fields-gate.sh:174-181`; item 2 (denial
message reworded) → `:183-188`; item 3 (three new `run_rf` cases) →
`778b810:core/hooks/tests/run-role-gates-tests.sh:100-109`; item 4
(handbook paragraph) → `git show 778b810 --
docs/handbooks/role-gates-tests.md`. The single delivery beyond those four
is disclosed rather than silent (`778b810:docs/issue-133/reports/implementation.md`,
`## Rationale for deviations`). The observed record's own `## What did not
work` also records a caught-before-running defect in the third test case's
JSON escape, which is the shape of disclosure this level looks for.

## Verdict 3 — step: which specific artifact, if any, is deficient

**Verdict: two artifacts are deficient, both at `778b810:core/hooks/record-fields-gate.sh:174-181`
— the delivered helper's scan scope (Finding 1) and its unhandled empty
value (Finding 2).** No deficiency was found in the test harness, the
handbook paragraph, the observed proposal, or the observed record's
disclosure behaviour. The four probes the approved proposal named close as
follows.

**P1 — false-positive reach of the tightened shape.** Each candidate value
class traced by hand against `778b810:core/hooks/record-fields-gate.sh:174-181`,
using Python's actual semantics (`\s` matches a newline; `.` does not; `$`
under `re.M` matches at a line end; the captured value is `.strip()`ped
before the two exact tests), and cross-checked against a read-only corpus
grep. No execution.

- *An empty value.* Newly denied where the pre-change regex ignored it →
  **Finding 2**.
- *An uppercase or mixed-case 40-hex value.* Denied: `^[0-9a-f]{40}$` is
  lowercase-only (`:178`). Not raised as a separate finding — the corpus
  grep found zero such values among the 91 lines under `docs/`, and the
  denial is the direct consequence of the shape requirement 1 names. Worth
  the human's awareness only because `git` itself accepts uppercase
  object names.
- *A 7-character abbreviated hex value.* Denied for future writes. **Not a
  finding**: this class was considered and decided at phase 1, with three
  reasons and a failure signal, at `de2b09c:…build-sha-whitelist-check.md`,
  `## Rationale`, third block, and it is listed under that proposal's
  `## Out of scope`. This session's own count refines the observed survey's
  tally: 11 abbreviated-hex lines across 5 files —
  `docs/issue-90/reports/execution-observation.md` (1),
  `docs/issue-107/reports/execution-observation.md` (3),
  `docs/issue-116/reports/execution-observation.md` (1),
  `docs/issue-122/reports/execution-observation.md` (3),
  `docs/issue-124/reports/execution-observation.md` (3). None is broken
  today (the gate only evaluates an actual write), and contract §11 already
  forbids rewriting a merged record — so the scoping decision holds, and it
  was a decision rather than an inheritance, which is what this axis asks.
- *A non-conforming value quoted as an example inside a proposal or a
  record.* Denied → **Finding 1**.
- *A value carrying a trailing YAML comment* (`<40-hex> # phase-1 commit`).
  Denied: the capture takes the rest of the line and `.strip()` removes
  whitespace only, so the comment stays inside the compared value
  (`:176-177`). Folded into Finding 1 — same root cause (a line regex over
  raw text where the convention being enforced is a YAML one), no separate
  action item.

**P2 — requirement 1's empty-value clause.** Closes as **Finding 2**. The
pre-change regex at `778b810^:core/hooks/record-fields-gate.sh:171-172`
required a `<...>` bracket in the captured group, so a value-less line
never matched and was admitted; the delivered loop at `778b810:…:174-181`
captures `(.*)`, which matches the empty string, and an empty value is
neither `same-commit` nor 40-hex, so it lands in `bad`. Read against
requirement 1's carve-out and against the corpus fact that zero
empty-valued lines exist today (targeted grep for
`^[[:space:]]*sha:[[:space:]]*$` over `docs/**/*.md`: no hits), this is a
future-writes concern, which is why Finding 2 is filed at low impact.

**P3 — evidence tier of requirement 2's red half.** Closes with the
asymmetry named rather than a deficiency. The green half is an inspected
artifact (three committed cases,
`778b810:core/hooks/tests/run-role-gates-tests.sh:101-109`); the red half
is the observed role's own assertion about an uncommitted scratch run
(`778b810:docs/issue-133/reports/implementation.md`, `## Verify`, final
paragraph). This role is barred from re-running either half, so the tier
cannot be raised from here — but it can be partly corroborated by
inspection: the pre-change regex at `778b810^:…:171-172` requires a `<`
followed by a `>` and then only whitespace to the line end, which by hand
admits `HEAD` (no bracket at all), admits `TBD` (same), and admits a
bracket followed by trailing prose (the trailing `\s*$` anchor fails, so
the line does not match and is not collected). The red half is therefore
independently supported by reading the pre-change pattern, and the
uncommitted run is not the only thing holding it up. One coverage
observation, deliberately **not** raised as a finding: all three added
cases use a proposal path
(`docs/issue-3/proposals/2026-08-04-x.md`,
`778b810:core/hooks/tests/run-role-gates-tests.sh:102,105,108`), so the
record-path call site is exercised for the new spellings by no new case —
but both call sites invoke the same helper (`778b810:…:191` and `:223`,
verified in the delivered blob), so the behaviour under test is shared and
the coverage gap is presentational, not behavioural.

**P4 — class sweep for "a validator that enumerates bad values instead of
good ones".** Swept read-only across the sibling mechanical checks. One
genuine cognate habitat found, reported below as a sweep result rather
than as a deficiency of PR #134, because issue #133's `## 제약` and the
observed proposal's `## Out of scope` both place it outside this subject:

- **Same file, same class:** the `code_under_review` check at
  `778b810:core/hooks/record-fields-gate.sh:227-235` denies a value only
  when it matches `^[0-9a-f]{7,40}$` — i.e. it enumerates the one bad shape
  it knows (a bare lowercase sha) and admits everything else, including an
  uppercase bare sha and any unresolved spelling. This is the identical
  structure issue-128's Finding 1 named, sitting three lines below the check
  that was just inverted, and untouched by this delivery by design.
- **Adjacent but a different class:** `core/hooks/trailer-gate.sh:83` and
  `core/hooks/handbook-trigger-gate.sh:71` recognise a commit command by
  pattern (`\bgit\b[^\n;&|]*\bcommit\b(?!-)`) and fall through when the
  spelling is unrecognised. The failure direction is similar, but these are
  trigger recognisers, not value validators; recorded so the sweep is not
  read as broader than it is.
- **Clean, and a positive contrast:** `core/hooks/trailer-gate.sh:164`
  requires an exact `Subject: issue-<n>` line (allow-shape), and
  `core/hooks/tests/stub-check.sh:116-126` is an allow-list by construction
  — it filters out the permitted line shapes and fails on whatever remains.
- **§20 clause 6 applicability, answered explicitly:** clause 6 (defect
  class plus other habitats) binds a record that states a *confirmed*
  finding. The observed record closes both hunt stances at `Verdict: NO
  FINDING` (`778b810:docs/issue-133/reports/implementation.md`, `## Hunt`),
  so clause 6 was **not owed** of it, and its absence there is not a
  deficiency. The sweep above is this role's, owed by this record's own
  findings.

Note on the sibling-gate reads: `trailer-gate.sh`,
`handbook-trigger-gate.sh`, and `stub-check.sh` are untouched by PR #134
(`gh pr diff 134 --name-only`), so reading them at their current state
answers "does this class live elsewhere today", which is what the sweep
asks — it is not used, and cannot be used, as evidence of what the
observed role did.

## Findings

### Finding 1 — the tightened check scans the whole document, so a proposal or record cannot quote a non-conforming value at line start

**Impact.** Any role writing its own `docs/issue-<n>/reports/<role>.md` or
any `docs/issue-<n>/proposals/*.md` is refused if the resulting file
contains, anywhere at line start, a `sha:` line whose value is not exactly
`same-commit` or 40 lowercase hex — including inside a fenced code block,
an indented quotation, or a worked example. The class of writes this
refuses is precisely the class needed to *document* the defect this gate
exists to catch: an observation record or a proposal that quotes an
offending value verbatim to explain it. It also refuses a legitimate value
carrying a trailing YAML comment.

**Timeline.** The behaviour originates at PR #129 (issue-128), whose
bracket-only regex at `778b810^:core/hooks/record-fields-gate.sh:171-172`
already denied a bracket-shaped example at line start. `778b810`
(`2026-08-04T07:34:46Z`) widened its reach from bracket-shaped values to
*every* non-conforming spelling, at
`778b810:core/hooks/record-fields-gate.sh:174-181`. It is not hypothetical
in this subject: the observed role's own phase-1 survey documents the live
defect by quoting the offending value inside a fenced YAML block at
`docs/issue-133/reports/implementation/survey.md:57` (landed at `de2b09c`,
still present). That file was admitted only because `reports/<role>/survey.md`
is a subdirectory path matched by neither `RECORDS_RE` nor `PROPOSALS_RE`
(`778b810:core/hooks/record-fields-gate.sh:120-121`); the identical
quotation inside `docs/issue-133/reports/implementation.md` or inside
either role's proposal would have been denied. This role's own phase-1
survey recorded the same constraint as a state fact before any verdict was
formed (`90c1632:docs/issue-133/reports/execution-observation/survey.md`,
`## Write surfaces this role owns`), and this record is written under it —
every offending spelling here is paraphrased or wrapped rather than quoted
at line start.

**Root cause.** The check runs over `new_text`, the entire reconstructed
file content produced at
`778b810:core/hooks/record-fields-gate.sh:165`, with a line regex
(`:176`) and no restriction to the frontmatter block and no exclusion for
fenced or quoted regions. The convention being enforced is a property of
the frontmatter's `upstream` entries, but the enforcement surface is the
whole document. Inverting the value test — the change issue #133 asked for
— necessarily widened the consequence, and no artifact in PR #134 traces
it: neither the proposal's `## Rationale`, nor its `## Out of scope`, nor
the record's `## Hunt`, whose after-proposal stance checked only whether
the new regex could false-fire on *other field names*
(`778b810:docs/issue-133/reports/implementation.md`, `## Hunt`,
after-proposal stance) — not whether it could false-fire on a legitimate
line of the same field.

**Action item** (for the human to judge and file, not filed from here).
Scope the scan to the frontmatter block — the region between the leading
`---` fences — or skip fenced-code and indented-quotation regions before
collecting values, at `core/hooks/record-fields-gate.sh:174-181`, and add a
`run_rf allow` case covering a record that quotes an offending value inside
a fenced block. A narrower alternative, if the whole-document scan is
wanted deliberately, is to record that as a decision so the next role that
hits it finds the reason rather than rediscovering it.

**Defect class and other habitats** (§20 clause 6). Class: *a
content-scoped rule enforced over a wider text region than the region the
rule is about*. Habitats swept this session: the five §20 field checks at
`778b810:core/hooks/record-fields-gate.sh:201-214` share the whole-document
scan but are presence heuristics, where a match outside the intended region
can only make the check more permissive, never refuse a legitimate write —
so the class is present but harmless there; the `code_under_review` check
at `:227-235` is anchored to a single line by `re.search(..., re.M)` on a
named field and is likewise whole-document but presence-directional.
`trailer-gate.sh:164` scans the joined commit message, which is the region
its rule is about. No second harmful habitat found.

### Finding 2 — requirement 1's empty-value carve-out is undelivered, and an empty value now produces a misleading denial

**Impact.** A write whose `upstream` entry carries the field with no value
is now refused where it was previously admitted, and the refusal message
does not name a value the author can act on. Worse, because `\s` matches a
newline, the captured "value" for a value-less line is not the empty string
in the common case: at
`778b810:core/hooks/record-fields-gate.sh:176` the `\s*` after the literal
`sha:` greedily consumes the line break and any following blank lines, and
`(.*)$` then captures the *next* non-blank line's text. The denial at
`:183-188` interpolates `bad[0]` into its message, so the author is told
that some unrelated line — the next heading, for instance — is not a valid
commit sha. Bounded in practice: this session's targeted grep for
value-less lines of this field across `docs/**/*.md` found zero instances
among 91 total, so the impact is on future writes and on the
diagnosability of the refusal, not on any existing document.

**Timeline.** Issue #133's requirement 1 carved the empty case out
explicitly ("빈 upstream 은 기존 규약대로", `gh issue view 133`), and the
observed proposal restated the carve-out in its `## Request` item 1 ("empty
`upstream` stays under the existing convention, untouched",
`de2b09c:docs/issue-133/proposals/2026-08-04-build-sha-whitelist-check.md`).
From there it disappears: the proposal's `## What will be done` items 1-4
do not mention it, no case among the three added at
`778b810:core/hooks/tests/run-role-gates-tests.sh:101-109` covers it, and
the record's `## What was done` and `## Verify`
(`778b810:docs/issue-133/reports/implementation.md`) do not address it. The
behaviour change itself landed at `778b810`.

**Root cause.** The carve-out is ambiguous between two readings — an absent
`upstream` list (no line of this field at all, structurally out of the
regex's reach, so genuinely untouched) and an empty *value* on a present
line (newly collected as bad) — and the delivery resolved the ambiguity by
not noticing it. The allow-list rewrite at `:174-181` was written as an
inversion of the value test alone; the pre-change regex's incidental
requirement of a `<` bracket had been carrying the empty case, and nothing
replaced it.

**Action item** (for the human to judge and file, not filed from here).
Decide the carve-out's reading and make it explicit at
`core/hooks/record-fields-gate.sh:174-181`: either skip a value-less line
(matching the pre-change behaviour the requirement's wording points at) or
deny it deliberately with a message that says the value is empty. In either
case anchor the value capture to the same line — for instance by matching
horizontal whitespace only after the field name — so the message can never
name a following line, and add one `run_rf` case fixing the chosen
behaviour.

**Defect class and other habitats** (§20 clause 6). Class: *a
requirement's carve-out clause restated at phase 1 and then dropped before
the clause checklist, so nothing downstream tests it*. Habitats swept this
session: the other three requirement-derived clauses of issue #133 each
appear in the proposal's `## What will be done` and again in the delivered
diff (mapped one-by-one under Verdict 1), so this is the only clause of
this subject that is stated in the `## Request` but absent from the
checklist. The regex sub-class — `\s*` spanning a line break where a
single-line field is meant — appears once more in the same file at
`:176` only; `:210` (`loop_state`) and `:228` (`code_under_review`) both
use `\s*` after the field name but require a non-empty value shape
immediately, so a line break there fails the match rather than crossing it.

## Open findings

Two, both above, both against the observed delivery's gate change, neither
filed as an issue from this session (contract v3: issues are user-authored;
findings return in this record on this role's PR):

1. Finding 1 — whole-document scan refuses legitimate quoted examples in
   proposals and records (`778b810:core/hooks/record-fields-gate.sh:174-181`).
2. Finding 2 — requirement 1's empty-value carve-out undelivered, and the
   empty-value denial names the wrong line
   (`778b810:core/hooks/record-fields-gate.sh:176,183-188`).

One class-habitat sweep result recorded under P4 that is **not** a finding
against PR #134 (it is outside the subject by the issue's own constraint):
the `code_under_review` check at
`778b810:core/hooks/record-fields-gate.sh:227-235` still enumerates the one
bad shape it knows rather than allow-listing good ones.

## Evidence tiers — what rests on the observed role's own assertion

- **Inspected first-hand:** every citation of the form `<sha>:<path>:<line>`
  above, both commits' diffs and stats, PR #134's and #136's GitHub
  metadata, the two issue comments, `docs/specs/approvers.md`, the corpus
  greps, the sibling-gate greps, and the phase-1 transcript's two
  first-occurrence line numbers.
- **Traced by hand, not executed:** every claim about what the delivered
  and pre-change patterns do to a given value — P1's five classes, P2's
  empty-value behaviour, P3's corroboration of the red half, and Finding
  2's newline-spanning capture. These rest on Python regex semantics
  applied to the pattern text as it appears in the `778b810` diff, at
  inspection tier. This role is barred from re-running the observed
  delivery's code, so none of them was executed.
- **The observed role's own assertion, not independently verifiable from
  here:** the suite results quoted at
  `778b810:docs/issue-133/reports/implementation.md`, `## Verify` —
  `role-gates: 27 passed, 0 failed`, `run-all.sh` → `ALL OK`,
  `gate-lib: 57 passed, 1 failed` with the failure attributed to a
  pre-existing sandbox artifact — and the uncommitted pre-fix scratch run
  that establishes requirement 2's red half. This record does not restate
  any of them as established fact.

## Proposal clause conformance (C1-C10)

| Clause | State | Where |
| --- | --- | --- |
| C1 record written first in phase 2, `loop_state` maintained | fulfilled | this file, written as phase 2's first act; frontmatter `loop_state: landed` |
| C2 independence statement before any verdict language | fulfilled | `## Independence`, preceding every verdict section |
| C3 outcome across requirements 1-3, constraint, backward direction | fulfilled | `## Verdict 1` |
| C4 trajectory across completeness, approval, scout-skip, ordering, conformance | fulfilled | `## Verdict 2` |
| C5 step across probes P1-P4, each closing as finding or explicit no-finding | fulfilled | `## Verdict 3` |
| C6 adjacent citation and evidence tier on every verdict-bearing sentence | fulfilled | throughout; tiers consolidated under `## Evidence tiers` |
| C7 four-part shape on every confirmed finding | fulfilled | Findings 1 and 2 |
| C8 §20 clause 6 (defect class + other habitats) on every confirmed finding | fulfilled | closing paragraph of each finding; P4 supplies the sweep |
| C9 no file outside this record written; no issue filed; nothing under the observed role's paths edited | fulfilled | `git status` before commit shows this file only |
| C10 claims resting on the observed role's assertion named as such | fulfilled | `## Evidence tiers`, third bullet |

## Next steps

None open for this role. The two findings are the human's to judge; if
judged valid they become user-authored issues, which this role does not
file.

## Resolution path

Findings 1 and 2 are raised against `core/hooks/record-fields-gate.sh` as
delivered at `778b810` — the observed role's landed artifact, already
merged. Neither is fixed here: this role does not edit the observed
artifact, and contract v3 routes a confirmed deficiency to the human
through this record on PR #136, not through an edit and not through an
issue filed by this session.

## Verify

- Three-level verdict present and none omitted: `## Verdict 1` (outcome),
  `## Verdict 2` (trajectory), `## Verdict 3` (step).
- Independence statement precedes the first verdict sentence: `##
  Independence` is the first section after the title; the first verdict
  language appears under `## Verdict 1`.
- Every verdict-bearing sentence names a commit sha, `file:line`, or URL
  adjacent to the verdict; claims that rest on the observed role's own
  assertion are labelled at the point of use and listed under
  `## Evidence tiers`.
- Nothing under the observed role's paths was written: the only path staged
  by this session's commit is
  `docs/issue-133/reports/execution-observation.md`.
- No test, gate, or script from the observed delivery was executed this
  session; every behavioural claim about the delivered pattern is a hand
  trace of the pattern text as it appears in the `778b810` diff.
