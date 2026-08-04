---
kind: coding-record
subject: issue-128
produced_by: implementation
code_under_review: `core/contract/role-handoff-contract.md`, `core/hooks/record-fields-gate.sh`, `core/hooks/tests/run-role-gates-tests.sh`, `docs/handbooks/role-gates-tests.md`
loop_state: landed
upstream:
  - path: docs/issue-128/proposals/2026-08-04-build-same-commit-upstream-sha-convention.md
    sha: 6963e3bcb20ceb07a29cd6fe958fbd9dc2c0f9cf
---

# Implementation record — issue-128

## Why

Phase 2, approved via issue-level comment `APPROVE issue-128/implementation`
(exact string, posted by an approvers.md account, jjongkwann — also this
PR's author, so single-account mode applies per contract v3 s19). Delivering
the approved proposal's `## What will be done` items 1-5: codify the
`sha: same-commit` convention in contract §1/§12, add the additive
placeholder-rejection check to `record-fields-gate.sh`, cover it with new
test cases, and document it in the handbook.

## What was done

1. `core/contract/role-handoff-contract.md` §1 — one new bullet after the
   existing chain-root bullet: when `path` lands in the same commit as the
   record/proposal citing it, `sha:` is written as the literal
   `same-commit`, never a bracketed placeholder; a later citation of the
   same `path` once that commit exists uses the real resolved sha.
2. `core/contract/role-handoff-contract.md` §12 — a new **Same-commit
   exemption** paragraph inserted directly after the existing "Chain-root
   exemption" paragraph, exempting a `sha: same-commit` entry from the
   git-log staleness comparison the same way `upstream: []` already is,
   and noting that future automated staleness tooling must special-case it.
3. `core/hooks/record-fields-gate.sh` — added `PROPOSALS_RE` (matching
   `docs/issue-[0-9]+/proposals/.*\.md`) alongside the existing per-role
   `RECORDS_RE`; the write-in-scope gate now admits either match
   (`is_record or is_proposal`). Added a `placeholder_shas()` helper
   (`^\s*sha:\s*(<[^\n]*>)\s*$`, one regex, per-line) and a shared
   `deny_placeholder()` message. A proposal-only write (`is_proposal and
   not is_record`) runs *only* this new check and exits — it never touches
   the five §20 checks, so a legitimate proposal missing "what was
   done"/"open findings" text is not false-positived. A record write
   (`is_record`) runs the new placeholder check in addition to the
   existing five §20 checks and the existing `code_under_review` bare-sha
   check, both of which are unchanged (confirmed by `git diff` — the only
   lines touched inside the existing record-path branch are the two lines
   adding the `placeholder_shas`/`deny_placeholder` call; the §20
   `missing` logic and the `code_under_review`/`loop_state` blocks are
   untouched). Verified by direct regex trace (not just test runs) that
   `^\s*sha:\s*` cannot match `acknowledged_sha:` or `code_sha:` lines —
   the literal token immediately following leading whitespace must be
   `sha:`, so neither of those other §1/§16 fields is affected. No new
   kill switch was added; the existing `RECORD_FIELDS_GATE_OFF` (checked
   via `gate_kill_switch_active` before any of this logic runs) already
   covers the new check, consistent with the proposal's "no new gate
   script" choice.
4. `core/hooks/tests/run-role-gates-tests.sh` — five new `run_rf` cases
   (the harness's existing helper, unmodified): proposal-path deny on
   `sha: <set at commit>`, proposal-path allow on `sha: same-commit`,
   proposal-path allow on a real 40-hex-char sha, record-path deny on a
   placeholder despite all five §20 fields otherwise present, record-path
   allow on `sha: same-commit`. Matches the proposal's "How you'll know it
   worked" checklist item verbatim (both a synthetic proposal path and a
   synthetic record path, `<set at commit>` denied, `same-commit`/real hex
   allowed).
5. `docs/handbooks/role-gates-tests.md` — one new paragraph, same turn as
   the gate change, describing the new check's scope (record + proposal
   paths), the denied shape (`^<.*>$`), and the allowed replacement
   (`same-commit`).
6. This record.

## What did not work

None. Every edit landed as drafted on the first attempt; no test failed
that wasn't already failing before this change (see `## Verify`).

## Doc-placement ladder

- [x] No `docs/issue-128/decisions/` entry — the phase-1 proposal's own
  `## Out of scope` explicitly rejects a standing decision doc for this
  change, following the issue-106/issue-118 precedent of landing a
  contract-wide record-norm change directly in the contract text with the
  rationale carried in the proposal's own `## Rationale`. This delivery
  executes that already-decided choice.
- [x] `docs/handbooks/role-gates-tests.md` updated in the same commit as
  the `record-fields-gate.sh` change it documents (item 5 above) — the
  doctrine-ladder rule for a changed mechanical check.
- [x] `docs/issue-128/reports/implementation.md` (this file) — the
  phase-2 record, per contract §11/§19.
- [x] No `.env.example` / dependency-manifest / migration entry — no env
  var, dependency, or schema change was introduced.

## Hunt

`warrant-hunter` is not among this session's available `Agent`-tool
subagent types (same absence noted in issue-88/90/93/94/98/100/106/118's
records). In its place, adopted each stance directly by inspection,
following the same local precedent.

### after-proposal (retroactive) — stance: assume the rule as drafted cannot hold — find the state nothing maintains

Verdict: NO FINDING
Seed: `docs/issue-128/proposals/2026-08-04-build-same-commit-upstream-sha-convention.md` (the approved proposal, commit `6963e3b`)
Started/ended: this session, before and after drafting the gate edit.

Checked whether the new `^\s*sha:\s*(<[^\n]*>)\s*$` regex could false-fire
against a field it must not touch, per the proposal's own constraint that
`closed_checks[].code_sha` and `code_under_review` (§100's settled fields)
stay untouched: traced the regex by hand against `acknowledged_sha:` and
`code_sha:` lines — `^\s*` consumes only whitespace, so the very next
literal characters checked are `sha:`; on an `acknowledged_sha:` or
`code_sha:` line those next characters are `a`/`c`, not `s`, so neither
line can match. Also confirmed the new check's exit path for a
proposal-only write never reaches the five §20 field checks, so a
proposal legitimately lacking "what was done"/"open findings" prose is
not newly false-positived (`run_rf allow "proposal sha: same-commit
allowed"` uses content with no such prose and passes). No finding.

### before-landing — stance: assume this change and another gate cancel each other — find the pair

Verdict: NO FINDING
Seed: `core/hooks/tests/compliance-check.sh`, the mechanical scanner that
flags a hand-rolled `*_OFF` kill-switch check not routed through
`gate_kill_switch_active` (`core/hooks/tests/compliance-check.sh:89`).
Started/ended: this session, after drafting the gate edit.

The new code adds no new `*_OFF` variable and no new case-statement kill
switch — it sits entirely inside the branch already gated by the existing
`gate_kill_switch_active "${RECORD_FIELDS_GATE_OFF:-}"` call at the top of
the script (line 46, unmoved). Ran the full `run-all.sh` suite, which
includes a dedicated "compliance-check hooks.json scan scope" pass
(4 passed, 0 failed) and confirmed `record-fields-gate.sh` still classifies
as "core's own migrated gates pass clean" in `run-gate-lib-tests.sh`. No
finding.

### Closed checks (for verify)

closed_checks:
- name: new sha-placeholder regex cannot match acknowledged_sha/code_sha lines
  ref: core/hooks/record-fields-gate.sh:172 (regex), :118,145-148 (scope match)
- name: proposal-only write path never reaches the five §20 checks
  ref: core/hooks/record-fields-gate.sh:181-185
- name: no new kill-switch variable introduced; existing RECORD_FIELDS_GATE_OFF covers the new check
  ref: core/hooks/record-fields-gate.sh:46
- name: compliance-check.sh and stub-check.sh still pass clean against the modified file
  ref: core/hooks/tests/run-all.sh (compliance-check hooks.json scan scope: 4 passed), core/hooks/tests/run-gate-lib-tests.sh ("compliance-check.sh: core's own migrated gates pass clean allow")

## Next steps

None open. This delivery completes all five `## What will be done` items
from the approved proposal; the proposal's own `## Out of scope` list
(retroactive fixes to the 16+ existing placeholder instances,
`code_under_review`/`closed_checks[].code_sha`, any merge-time backfill,
a standing decision doc, `acknowledged_sha` semantics beyond the new
exemption) is deliberately not touched here.

## Resolution path

No open finding is raised against another role's record from this
delivery; both hunt stances above closed with no finding.

## Verify

`bash core/hooks/tests/run-role-gates-tests.sh` → `role-gates: 24 passed,
0 failed` (19 pre-existing cases unaffected, 5 new issue-128 cases pass).

`bash core/hooks/tests/run-all.sh` → `ALL OK` (role-gates 24/24,
stub-check 3/3, compliance-check 4/4, plus the three sibling-plugin
suites — terse, freelunch, scout — all pass).

`bash core/hooks/tests/run-gate-lib-tests.sh` → `gate-lib: 53 passed, 1
failed`. The one failure
(`compliance-check.sh: flags a hand-rolled kill-switch + replace shape
want=deny got=allow`) is a pre-existing sandbox artifact, not caused by
this change: confirmed by `git stash`-ing this delivery's diff and
re-running the same suite against unmodified `origin/main` — identical
`53 passed, 1 failed` result, with the same `mktemp: mkdtemp failed ...
Operation not permitted` / `mkdir: /docs: Operation not permitted` /
`mkdir: /hooks: Operation not permitted` lines preceding it in both runs
(this session's sandbox denies writes to `/docs`, `/hooks`, and some
`mkdtemp` paths outside the allow-listed set, which several
`run-gate-lib-tests.sh` cases need to build fixture trees). Then restored
this delivery's diff (`git stash pop`).

`git diff --stat` (this delivery, tracked files only) →
`core/contract/role-handoff-contract.md | 16 ++`,
`core/hooks/record-fields-gate.sh | 35 +++++++++++++++++++++++++++++--`,
`core/hooks/tests/run-role-gates-tests.sh | 17 +++++`,
`docs/handbooks/role-gates-tests.md | 11 +++`, matching the proposal's
five-file write set (the fifth file, this record, is untracked/new, not
a diff).
