---
kind: coding-record
subject: issue-100
produced_by: implementation
code_under_review: `core/hooks/record-fields-gate.sh`, `core/hooks/tests/run-role-gates-tests.sh`, `docs/handbooks/role-gates-tests.md`, `docs/issue-100/decisions/2026-08-03-record-citation-format-and-kind-convention.md`
loop_state: landed
upstream:
  - path: docs/issue-100/proposals/2026-08-03-canonicalize-record-citation-format.md
    sha: 8637a9ff24268468ca7e900a9661c1ab8ad229ea
---

# Implementation record — issue-100

## Why

Phase 2, approved via issue-level comment `APPROVE issue-100/implementation`
(exact string, posted by an approvers.md account, jjongkwann:
https://github.com/tokenmaxxxer/tokenmaxxxer-core/issues/100#issuecomment-5163202989).
Delivering the approved proposal's four decisions (file-list
`code_under_review`, `ref:` file:line replacing `closed_checks[].code_sha`,
one gate check point, `kind: coding-record` canonical) as a decision
document plus the one gate enforcement point. The proposal's item 5 (fixing
the citation format in `docs/issue-90/reports/implementation.md` and
`docs/issue-94/reports/implementation.md`) could not be delivered — see
`## Rationale for deviations`.

## What was done

1. `docs/issue-100/decisions/2026-08-03-record-citation-format-and-kind-convention.md`
   (new): records all four decisions from the proposal's Rationale — the
   file-list `code_under_review` convention with the rejected
   merge-time-backfill alternative and why; `ref:` file:line replacing
   `closed_checks[].code_sha` with the rejected drop-the-field alternative
   and why; the `record-fields-gate.sh` check as the one enforcement point
   with the rejected handbook-only alternative and why; `kind:
   coding-record` as canonical with the 3-of-4 count.
2. `core/hooks/record-fields-gate.sh:187-194`: one additive check, scoped
   to `role in ("coding", "implementation")`, denying a write to that
   role's own record when `code_under_review:`'s value, stripped, matches
   `^[0-9a-f]{7,40}$` (a bare commit-sha token, nothing else on the line)
   instead of a file list. No other check in this file changed — confirmed
   by `git diff core/hooks/record-fields-gate.sh`, a single inserted block
   between the existing "missing §20 fields" deny and the `loop_state`
   terminal-state check.
3. `core/hooks/tests/run-role-gates-tests.sh:76-81`: two new `run_rf`
   cases, `CLAUDE_ROLE=implementation` against
   `docs/issue-3/reports/implementation.md` — a bare 40-hex-char
   `code_under_review:` denied, a backtick-quoted two-file list allowed.
4. `docs/handbooks/role-gates-tests.md`: one entry (after the existing
   `RECORD_FIELDS_TERMINAL_STATES` paragraph) documenting the new check and
   pointing at the decision doc.
5. Ran the full suite: `bash core/hooks/tests/run-role-gates-tests.sh` →
   `role-gates: 19 passed, 0 failed`, including the 2 new cases; the 17
   pre-existing cases (trailer-gate, record-fields-gate, handbook-trigger-gate,
   stub-check) are unaffected.

## What did not work

- Attempted `Edit` on `docs/issue-90/reports/implementation.md` (proposal
  item 5, the `code_under_review` file-list conversion). Expected: the
  write would land, since the proposal explicitly froze this file in its
  write set. Actual: `board-gate.sh` denied it — "writing docs/issue-90/
  requires branch issue-90/implementation (current: issue-100/implementation).
  Every role output reaches main only through a PR the human merges —
  never a direct write from another branch. (contract v3 s10)". Retargeted
  a synthetic same-content probe at `docs/issue-94/reports/implementation.md`
  to confirm the same rule applies there too (it does, by inspection of
  the identical R4 branch check in `core/hooks/board-gate.sh:19-28`, not a
  second live denial — one confirmed denial was enough to establish the
  rule is unconditional on the target issue number). Neither file was
  touched; `git status`/`git diff` on both confirm zero bytes changed.
  Not fixed — this is a structural block, not a typo; see `## Rationale
  for deviations`.

## Doc-placement ladder

- [x] `docs/issue-100/decisions/2026-08-03-record-citation-format-and-kind-convention.md`
  — the hard-to-reverse choice (record citation format, `kind:`
  convention) goes to `docs/issue-<n>/decisions/` per contract §21, same
  turn as the gate change that enforces it.
- [x] `docs/handbooks/role-gates-tests.md` — the new
  `record-fields-gate.sh` check documented same-turn as the gate change
  (operational-surface entry, contract §21's handbook grant).
- No new env var, dependency, or migration.

## Rationale for deviations

The approved proposal's `## What will be done` item 5 named
`docs/issue-90/reports/implementation.md` and
`docs/issue-94/reports/implementation.md` as part of this PR's frozen
write set, to be edited in place for citation-format-only fixes. Neither
edit could be made from this branch: `core/hooks/board-gate.sh` R4 (line
19-28, "Branch") denies any write under `docs/issue-<n>/` unless the
current git branch is exactly `issue-<n>/<CLAUDE_ROLE>` — confirmed live
(`## What did not work`, above) against `docs/issue-90/`, and true by the
same unconditional rule for `docs/issue-94/` (contract v3 s10, s11:
"every role output reaches main only through a PR the human merges —
never a direct write from another branch"). This is the same
never-overwrite-ownership boundary the decision document's own Decision 1
rationale invokes to reject the merge-time-backfill alternative — it
applies with equal force to editing these two already-merged records from
issue-100's branch. The proposal's phase-1 research did not test an
actual write to a foreign issue's record path and so did not surface this
blocker before approval.

Scope actually delivered: the convention (Decisions 1-2), its one
enforcement point (Decision 3), and the `kind:` canonicalization
(Decision 4) — all of which apply going forward and are what prevents a
third recurrence. Not delivered: the two records' own citation-format
correction (proposal item 5, requirement 3 of issue #100). This record
does not silently drop that requirement; it is carried forward under
`## Next steps` for a follow-up issue scoped to run on
`issue-90/implementation` and `issue-94/implementation` respectively (or
whatever mechanism the user chooses for a cross-issue documentation
correction under contract v3's branch-ownership model).

## Hunt

Stance for this pass: **boundary-prober** — assume the new regex either
under-denies (misses a real bare-sha value in some other shape) or
over-denies (blocks a legitimate file-list value that happens to look
sha-like), rotating from issue-90's adversarial-reader and issue-94's
contract-literalist stances. `warrant-hunter` is not among this session's
available `Agent`-tool subagent types (same absence noted in
issue-88/90/93/94's records); adopted the stance directly by reading the
shipped regex and its call site rather than executing further live
probes (a same-branch synthetic-payload probe against a *foreign* record
path itself triggers `board-gate.sh` R5 as a Bash-command path-token
false positive — the same class already on record in
`docs/issue-94/reports/execution-observation.md`'s note on the live
board-gate path-token false positive — so this pass verifies the regex
by inspection instead of by further live invocation).

closed_checks:
- name: new check scoped to role in {"coding","implementation"} only
  ref: core/hooks/record-fields-gate.sh:187
  result: the added block is `if role in ("coding", "implementation"):`
    wrapping the `code_under_review` regex check — a write to
    `docs/issue-<n>/reports/product.md` (or any role outside the pair)
    never reaches this branch, regardless of what its `code_under_review`
    value looks like. Confirmed by reading the diff; no other conditional
    in the file was touched.
- name: bare-sha denied, file-list allowed, for CLAUDE_ROLE=implementation
  ref: core/hooks/tests/run-role-gates-tests.sh:76
  result: `bash core/hooks/tests/run-role-gates-tests.sh` →
    `role-gates: 19 passed, 0 failed`, including both new cases
    (`implementation record code_under_review bare sha denied (issue-100)`
    → deny, `implementation record code_under_review file list allowed
    (issue-100)` → allow).
- name: regex `^[0-9a-f]{7,40}$` matches only a bare token, not a
  file-list value or a sha with trailing text
  ref: core/hooks/record-fields-gate.sh:188-190
  result: by inspection — `re.search(r'^\s*code_under_review:\s*(.+?)\s*$', ...)`
    captures the value up to end-of-line (comment-tolerant per the same
    pattern the contract's own `kind:` parsing note asks for), then
    `re.match(r'^[0-9a-f]{7,40}$', ...)` requires the captured group to be
    *entirely* 7-40 lowercase-hex characters — a backtick-quoted file
    list (contains `` ` ``, `,`, spaces) or a sha followed by trailing
    prose never matches; a bare 7-40-char lowercase-hex token always does.
    The two live-tested boundary values (a bare 40-hex-char token denied,
    a backtick-quoted two-file list allowed) pin both ends of this
    behavior; the untested interior of the 7-40 range follows from the
    same `{7,40}` quantifier and was not separately re-verified live.
- name: decision document's stated behavior matches the shipped gate check
  ref: docs/issue-100/decisions/2026-08-03-record-citation-format-and-kind-convention.md
  result: Decision 3's regex (`^[0-9a-f]{7,40}$`) and role scope
    (`{"coding", "implementation"}`) are copied verbatim from the same
    values written into `core/hooks/record-fields-gate.sh:187-190` in this
    same commit — no drift between what the decision document claims and
    what the gate enforces.

## Open findings

None raised against this record.

## Next steps

- A follow-up is needed to actually correct
  `docs/issue-90/reports/implementation.md` and
  `docs/issue-94/reports/implementation.md` to the canonical citation
  format the decision document now defines — this record could not do it
  from `issue-100/implementation` (contract v3 s10/s11, `## Rationale for
  deviations`). The correction is citation-format-only per the original
  issue's own constraint (verdict content unchanged); it needs a role
  session invoked on `issue-90/implementation` and `issue-94/implementation`
  respectively, or another mechanism the user chooses for a cross-issue
  documentation-only correction.
- No other open work from this proposal.

## Resolution path

Any open finding against this record is resolved by amending this file
with a `resolved_findings:` entry referencing the finder's record, per
contract v3 s16, before further build commits proceed.

## Verify

`bash core/hooks/tests/run-role-gates-tests.sh` →
`role-gates: 19 passed, 0 failed`.
