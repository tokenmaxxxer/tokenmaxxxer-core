---
kind: current-state-survey
subject: issue-100
produced_by: implementation
---

# Current-state survey — issue-100

## The two defective records (requirement 3's targets)

- `docs/issue-90/reports/implementation.md:5` — `code_under_review:
  d52d1e68c15dc8711ee0834520d643059942404d`, a docs-only proposal commit
  (`docs/issue-90/proposals/2026-08-03-scope-board-gate-candidates-and-port-approval-gate-fixes.md`,
  same sha). Five `closed_checks` entries at `:99-127` all carry
  `code_sha: d52d1e68…`, the same sha. The real code commit is `c66aecc`.
- `docs/issue-94/reports/implementation.md:5` — `code_under_review:
  74c790d00d6ee802af92671f3240216b4be4da41`, likewise the docs-only
  proposal commit. Four `closed_checks` entries at `:130,139,150,161` all
  carry `code_sha: 74c790d…`. The real code commit is `c9a63b4`.
- Both defects are independently confirmed as each record's Finding 2:
  `docs/issue-90/reports/execution-observation.md:351-386` and
  `docs/issue-94/reports/execution-observation.md:315-353` (the latter
  citing the former as "recurrence," four hours later, with an unactioned
  action item in between).
- Both observation records are explicitly out of bounds for this issue's
  edits (issue body constraint: "관찰 기록은 관찰 역할 소유"). They are read
  here as evidence only.

## Prior-good and other-shaped precedent already in the repo

- `docs/issue-88/reports/implementation.md:5` — `code_under_review: core/hooks/board-gate.sh,
  core/hooks/tests/run-board-gate-tests.sh, docs/handbooks/board-gate-tests.md`
  — comma-separated file list, `kind: implementation-record`.
- `docs/issue-20/reports/implementation.md:2-4` — same file-list shape for
  `code_under_review`, no `kind:` field at all (predates the field).
- A third, distinct idiom for the same structural bind, used in the
  `## Verify`/Hunt prose (not in YAML fields) by `docs/issue-20/reports/implementation.md:205-212`,
  `docs/issue-88/reports/implementation.md:178-188`, and
  `docs/issue-83/reports/implementation.md:91-95`: literal text
  `(code_sha: HEAD of this record)` instead of a resolved hex value —
  the self-reference is spelled out as symbolic text rather than faked
  with a real-looking sha.
- `docs/issue-93/reports/implementation.md:5` (`code_under_review:
  8f4ba9f887192054286b061fa86273513b8de929`, equal to its own
  `upstream[0].sha`) carries what looks like the identical defect
  pattern, unconfirmed because no execution-observation ran for
  issue-93. Not in scope: issue #100's requirement 3 names only issue-90
  and issue-94. Recorded here as a residual, not fixed.

## `kind:` count for the implementation role's own record

Every top-level `docs/issue-<n>/reports/implementation.md` carrying a
`kind:` field:

| record | kind |
|---|---|
| issue-88 | `implementation-record` |
| issue-90 | `coding-record` |
| issue-93 | `coding-record` |
| issue-94 | `coding-record` |

3 of 4 (`coding-record`) vs. 1 of 4 (`implementation-record`); issue-20
predates the field and does not count either way. `coding-record` is also
the kind name the contract's own artifact-kind table already sanctions
for this role's record (`core/contract/role-handoff-contract.md:63`,
row keyed to the pre-rename role name "coding" — the `coding`/`implementation`
naming double is a known, separately-tracked issue per this session's own
role directive, not something to reconcile here).

## The contract's existing rules that bound this decision

- `core/contract/role-handoff-contract.md:541-569` (§16) defines
  `closed_checks:` as `check:`/`code_sha:` pairs and makes `code_sha`
  load-bearing for downstream cite-and-skip: a check only counts as
  closed when its `code_sha` equals "the code sha currently under
  review." A file-list `code_under_review` has no single sha for a
  downstream `closed_checks` entry to equal — the schema in §16 assumes a
  single sha, and this issue's requirement 3 already tells us to route
  around that assumption for `closed_checks` specifically ("제거하거나
  검증 가능한 참조(파일:줄)로 대체").
- `core/contract/role-handoff-contract.md:784-817` (§20) is what
  `core/hooks/record-fields-gate.sh` enforces today (read in full,
  below) — it does not check the shape of `code_under_review` or
  `closed_checks[].code_sha` at all, only that some upstream-basis-shaped
  text exists (a `docs/issue-` substring, an "upstream"/"based on"/"basis:"
  word, OR any bare 7-40-char hex token — this last alternative is loose
  enough that a bare proposal sha in `code_under_review` already
  satisfies it, which is one reason the defect was never gate-caught).

## `record-fields-gate.sh` (the candidate check point)

Read in full at `core/hooks/record-fields-gate.sh`. It is a single canon
file, sourced by every rulebook via `${CLAUDE_PLUGIN_ROOT_CORE}/hooks/…`
— confirmed by `docs/handbooks/canon-scripts.md` and by `find` finding
exactly one copy in the repo (`core/hooks/record-fields-gate.sh`); no
per-rulebook vendored duplicate exists to keep in sync (issue-69 already
retired that pattern). Editing this one file is a single check point by
construction, matching the issue's cap. It role-parameterizes on
`CLAUDE_ROLE`/`RECORD_FIELDS_TERMINAL_STATES` and currently checks, on a
Write/Edit/MultiEdit to `docs/issue-<n>/reports/<role>.md`: presence of a
what-was-done section, a why section, an upstream-basis token, a
`loop_state:` line, an open-findings section, and (when `loop_state` is
non-terminal) a next-steps section and a resolution-path section. It has
no field-shape checks today — adding one is additive, not a rewrite.

Its test coverage lives in `core/hooks/tests/run-role-gates-tests.sh`
(documented in `docs/handbooks/role-gates-tests.md`), which already
drives `record-fields-gate.sh` as a real subprocess and asserts its kill
switch and its `RECORD_FIELDS_TERMINAL_STATES` override — the natural
place to add a case for a new field-shape check.

## Decision-doc placement

No `docs/issue-<n>/decisions/` directory exists anywhere in this repo yet
(`find docs -type d -name decisions` is empty) — this issue's decision
doc would be the first instance of that bucket. The six standing buckets
(`_assets, decisions, handbooks, proposals, reports, specs`) already
include `decisions` as a sanctioned per-issue bucket per the role-handoff
contract's output-layout rule, so this is a legitimate first use, not an
invented location.

## Write set this survey projects

- `docs/issue-100/decisions/<slug>.md` (new) — the citation-format and
  `kind:` decision, with the rejected merge-after-sha alternative.
- `core/hooks/record-fields-gate.sh` — one additive field-shape check.
- `core/hooks/tests/run-role-gates-tests.sh` — one new case exercising
  that check.
- `docs/handbooks/role-gates-tests.md` (or a new handbook entry
  colocated with it) — same-turn documentation of the new check, per the
  doc-placement ladder (a gate-behavior change is a "setup
  step"/behavior change, handbook home).
- `docs/issue-90/reports/implementation.md` and
  `docs/issue-94/reports/implementation.md` — citation-format-only edits
  (`code_under_review` → file list; `closed_checks[].code_sha` → dropped
  or replaced by a file:line reference). No verdict text, no `kind:`
  change (both already read `coding-record`, the majority/canonical
  value).
