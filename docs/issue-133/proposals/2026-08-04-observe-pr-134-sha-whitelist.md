---
kind: proposal
subject: issue-133
produced_by: execution-observation
phase: 1
loop_state: proposed
observed_pr: 134
observed_role: implementation
upstream:
  - path: docs/issue-133/reports/execution-observation/survey.md
    sha: same-commit
  - path: docs/issue-133/reports/execution-observation/scout-brief.md
    sha: same-commit
---

files: `docs/issue-133/reports/execution-observation.md` (phase-2 record only)

# Proposal — step 2 independent observation of PR #134 (issue-133)

## What this proposal covers

Issue #133's `## 실행 계획` lists two steps. Step 1 (`implementation`) landed
as PR #134, merged `2026-08-04T07:35:51Z` into `main` as merge commit
`6236f9b5cf93ed880a3b362d892bf53888956b97` (`gh pr view 134 --json
state,mergedAt,mergeCommit` this session). Step 2 is this role's independent
observation of that execution — specifically of the `implementation` role's
two headless sessions on subject `issue-133`, whose output is the two
commits `de2b09c59963a1d4b64f3a0ced31513fe52d98d0` (phase 1) and
`778b810c0dcca9b300f644d78810e0b1e655e3c2` (phase 2). This document states,
before any judgment is formed, which verdict levels the phase-2 record will
address and what evidence each will be checked against. It renders no
judgment of its own, not even provisionally.

The inputs read first-hand are enumerated in
`docs/issue-133/reports/execution-observation/survey.md`
(`## What was read this session, first-hand`), together with the six
unknowns that survey leaves open; every artifact in that table was read
again first-hand in the session that writes this proposal — the observed PR
number and its metadata, both commit shas and their full diffs, the
delivered gate blob at `778b810`, and the observed role's own record
`docs/issue-133/reports/implementation.md` as committed at `778b810`.
Direction inputs — the category must-bes this observation is built to meet —
are in `docs/issue-133/reports/execution-observation/scout-brief.md`.

Two facts about this role's position, stated so the human need not infer
them: this role did not author and will not edit any artifact under
observation, and this role will not re-run the delivered gate or its test
suite. The delivered diffs, the commit messages, the observed role's own
record, and the PR/issue metadata are the whole admissible evidence set.

One live constraint on this document, recorded as fact: the very check under
observation matches this proposal's own path (`PROPOSALS_RE`,
`^docs/issue-[0-9]+/proposals/.*\.md$`, at
`778b810:core/hooks/record-fields-gate.sh:117-118`), and the delivered
helper collects *every* line of the reconstructed text matching
`^\s*sha:\s*(.*)$` whose stripped value is neither `same-commit` nor 40
lowercase hex (`778b810:core/hooks/record-fields-gate.sh:174-181`). The
unresolved spellings under discussion therefore cannot be quoted at
line-start anywhere in this proposal or in the phase-2 record; probe P1
below traces them by construction rather than by quotation.

## Verdict levels to be checked, and against what

All three levels of the contract's execution judgment will be addressed in
the phase-2 record; none will be omitted, and a level that turns out not to
apply will say so and why rather than being dropped silently.

### 1. Outcome — did PR #134 land what issue #133 asked

Checked forward (each requirement to an artifact) and backward (each
delivered change to a requirement that asked for it):

- **Requirement 1** (convert the check to an allow-list: literal
  `same-commit` or 40-hex only; empty upstream stays under the existing
  convention): against the `778b810` hunk for
  `core/hooks/record-fields-gate.sh` at `:169-185`, read as a diff, and
  against the pre-change baseline via `git show 778b810^:` of the same file
  where the old behaviour is needed — history, never the working tree. The
  empty-value half of this requirement is carried by probe P2.
- **Requirement 2** (red→green across the three unresolved spellings, with
  the two valid forms still passing): against the `778b810` hunk for
  `core/hooks/tests/run-role-gates-tests.sh` (three added `run_rf deny`
  cases) for the green half, and against the record's own `## Verify` text
  for the red half — whose evidence tier probe P3 fixes explicitly.
- **Requirement 3** (no retroactive fix to the real-world unresolved
  instance in `docs/issue-20/proposals/2026-07-31-build-gh-guard-endpoint-match.md`):
  against `gh pr diff 134 --name-only` (six paths) and against both commits'
  `--stat`, checking that no `docs/issue-20/**` path appears in either.
- **Constraint** (issue-128's landing convention and the five §20 checks
  unchanged): against the delivered blob at
  `778b810:core/hooks/record-fields-gate.sh:190-226` for the two call sites
  and the §20 `missing` logic, plus the diff's own hunk boundaries.
- **Backward direction**: every hunk in `778b810` mapped to the requirement
  or proposal clause that asked for it, with anything unmapped surfaced —
  the top-of-file comment rewrite at `:12-19` is the known candidate, and
  will be checked against the record's `## Rationale for deviations`.

### 2. Trajectory — was the phase-1 → phase-2 path sound

- **Phase-1 completeness** against `git show --stat de2b09c` (proposal +
  survey, 2 files, no execution work in that commit) and against contract
  §19's phase-1 requirements — an enumerable clause checklist, named
  alternatives with a reason each, a stated failure signal — read from
  `de2b09c:docs/issue-133/proposals/2026-08-04-build-sha-whitelist-check.md`.
- **Approval validity** against the issue-level comment whose body is
  `APPROVE issue-133/implementation`
  (<https://github.com/tokenmaxxxer/tokenmaxxxer-core/issues/133#issuecomment-5175895602>,
  author `jjongkwann`, `2026-08-04T07:27:17Z`), against
  `docs/specs/approvers.md`, against PR #134's author (`gh pr view 134
  --json author` → `jjongkwann`, hence §19's single-account path), and
  against the timestamp ordering `de2b09c` (07:24:31Z) → PR created
  (07:26:23Z) → APPROVE comment (07:27:17Z) → `778b810` (07:34:46Z).
- **Scout-skip validity** (survey unknown 4): the observed survey's
  `## Scout skip record` claims the "no design decision open" condition
  while the same commit's proposal records rejecting two alternatives.
  Checked against those two committed files first; if they cannot settle
  it, against the observed sessions' transcript files named in the survey's
  `## Scope` — reading a transcript is reading the observed session's own
  record, not a re-execution. If unreadable, the level will say the point is
  unverifiable rather than assume either way.
- **Phase-1 internal ordering** (survey unknown 5): same evidence ladder,
  same rule — recorded as unverifiable if the squashed commit and the
  transcripts cannot settle whether the survey preceded the proposal.
- **Delivery-to-proposal conformance**: each of the observed proposal's four
  `## What will be done` clauses mapped to the `778b810` hunk that fulfils
  it, or recorded as unfulfilled.

### 3. Step — which specific artifact, if any, is deficient

Four named probes, each producing either a finding or an explicit
no-finding:

- **P1 — false-positive reach of the tightened shape** (scout brief's first
  must-be). Candidate value classes traced by hand against the delivered
  loop at `778b810:core/hooks/record-fields-gate.sh:174-181`: an empty
  value; an uppercase or mixed-case 40-hex value; a 7-character abbreviated
  hex value (the observed survey's own tally reports 5 such instances in
  landed `execution-observation` records); an unresolved spelling appearing
  inside a fenced example block or an indented quotation within a proposal
  or record; a value carrying a trailing comment. Each traced against the
  pattern's actual Python semantics — `\s*` consumes whitespace only, `.`
  never matches a newline, the value is stripped before the exact tests —
  and cross-checked against a read-only repo-wide grep of existing values.
  Inspection tier throughout, stated as such; no execution.
- **P2 — requirement 1's empty-value clause** (survey unknown 2). What the
  pre-change pattern did with an empty value versus what the delivered loop
  does, read from `git show 778b810^:core/hooks/record-fields-gate.sh`
  against `778b810:` of the same file, and set against requirement 1's
  "빈 upstream 은 기존 규약대로" wording and the corpus fact that zero
  empty-valued lines of this field exist today.
- **P3 — evidence tier of requirement 2's red half** (survey unknown 3).
  The green half is committed as three test cases in `778b810`; the red half
  exists only as the record's own prose about a scratch run the record
  itself states was not committed (`778b810:docs/issue-133/reports/implementation.md`,
  `## Verify`, final paragraph). The record will name that asymmetry and the
  tier each half rests on — inspected artifact versus the observed role's
  own assertion — rather than presenting both as equally established.
- **P4 — class sweep** (survey unknown 6, contract §20 item 6). The class in
  play is *a validator that enumerates bad values instead of good ones*.
  Swept read-only across the sibling mechanical checks — the other content
  checks inside `record-fields-gate.sh`, plus `trailer-gate.sh`,
  `handbook-trigger-gate.sh`, `stub-check.sh` — with the result recorded
  whether or not it yields a finding, and with the §20 applicability
  question (whether item 6 is owed when the observed record closes both hunt
  stances at `NO FINDING`) answered explicitly.

Every verdict-bearing sentence in the phase-2 record will carry its source —
commit sha, `file:line`, or comment URL — immediately adjacent to it, and
will name the evidence tier it rests on. Any deficiency finding will carry
the four-part blameless shape: impact, timeline, root cause, action item.

## Clause checklist (what phase 2 commits to producing)

- C1. `docs/issue-133/reports/execution-observation.md` written as the first
  act of phase 2, with `loop_state` updated at each transition.
- C2. The independence statement placed before any verdict language in that
  record.
- C3. Outcome verdict covering issue requirements 1, 2, 3, the constraint,
  and the backward direction, each with an adjacent citation.
- C4. Trajectory verdict covering phase-1 completeness, approval validity,
  scout-skip validity, phase-1 ordering, and clause conformance.
- C5. Step verdict covering probes P1-P4, each closing as a finding or an
  explicit no-finding.
- C6. Every verdict-bearing sentence carries an adjacent source citation and
  its evidence tier.
- C7. Any confirmed finding carries impact / timeline / root cause / action
  item.
- C8. Any confirmed finding carries contract §20 item 6: its defect class
  and the other-habitats sweep result (P4 supplies the sweep either way).
- C9. No file outside `docs/issue-133/reports/execution-observation.md` is
  written in phase 2; no issue is filed; nothing under the observed role's
  paths is edited.
- C10. The record states plainly which claims rest on the observed role's
  own assertion (e.g. the quoted `role-gates: 27 passed, 0 failed`) rather
  than on evidence this role could inspect independently.

## Alternatives considered

- **Outcome-only verdict read from the observed record.** Not chosen: the
  record is the observed role's own account, so an outcome read solely from
  it rests entirely on inquiry-tier evidence, and it cannot answer the
  backward direction — what landed that no requirement asked for — at all.
- **Re-running `run-role-gates-tests.sh` to confirm the `27 passed` claim,
  or re-running the pre-fix script to confirm the red half.** Not chosen:
  re-executing the observed role's code is prohibited for this role, and the
  inspection-tier substitute (reading the three added cases and the
  delivered loop in the `778b810` diff) is available and is what the
  evidence hierarchy admits when re-performance is not.

## Failure signal

If this observation design is wrong, the signal is one of: (i) a legitimate
write is refused in a later session by a value class P1 declared clear;
(ii) a verdict in the phase-2 record turns out to describe the working tree
rather than what `778b810` delivered — the one evidence substitution this
role is specifically barred from making; or (iii) the human reading the
record cannot tell which claims were inspected first-hand and which were
taken from the observed role's own assertion.

## Out of scope

- Any edit to `core/`, `test/`, `docs/handbooks/`, or the observed role's
  `docs/issue-133/reports/implementation*` paths.
- Filing an issue for any finding — under contract v3 findings return in
  this role's record on this PR; the human files what they judge valid.
- Re-opening issue #133's own excluded items: the retroactive fix to
  `docs/issue-20/…` (requirement 3), and the observed proposal's
  `## Out of scope` list (widening the two path patterns, allow-listing
  abbreviated hex, SHA-256 support).
- Re-executing any test, gate, or script belonging to the observed delivery.

## How you'll know it worked

- The phase-2 record addresses all three verdict levels explicitly, with no
  level silently omitted.
- Every verdict-bearing sentence in it names a commit sha, `file:line`, or
  URL adjacent to the verdict.
- The independence statement appears before the first verdict sentence.
- Clauses C1-C10 are each marked fulfilled with the section that fulfils
  them, or marked dropped with a reason.
