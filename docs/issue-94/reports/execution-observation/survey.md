---
kind: current-state-survey
subject: issue-94
produced_by: execution-observation
loop_state: phase-1
---

# Current-state survey — what is on the board for issue-94, and what is not yet known

## Scope of this observation (named, not "recent work")

- **Role under observation:** `implementation`, on branch
  `issue-94/implementation`.
- **Session under observation:** the one that produced the two commits
  below; its own account of itself is `docs/issue-94/reports/implementation.md`
  (blob at `c9a63b4`).
- **Issue:** #94 — "따옴표 안 문자열이 여전히 동작으로 오인된다 — board-gate
  쓰기성 판정과 gh-guard 전체 (#88·#90 이 남긴 두 자리)", state OPEN
  (reopened by the human after PR #96's `Closes #94` auto-closed it).
- **PR:** #96, `issue-94/implementation` → `main`, **MERGED**
  2026-08-03T05:36:18Z by `jjongkwann`
  (https://github.com/tokenmaxxxer/tokenmaxxxer-core/pull/96).
- **Commits:** `74c790d` (propose, docs-only, 2 files / +560) and
  `c9a63b4` (deliver, 12 files / +396 −35); merge commit `19a99ba`.
- **This role's own branch/PR:** `issue-94/execution-observation`; no PR
  open for it at survey time (`gh pr list --state all` shows none), and
  no `APPROVE issue-94/execution-observation` comment exists on the issue
  (the only APPROVE-shaped comment there is
  `APPROVE issue-94/implementation`).

## What was actually read this session, firsthand

Read directly, not summarized secondhand:

1. `gh issue view 94` (body + both comments) — the requirement text, and
   the human's reopen comment.
2. `gh pr view 96 --json reviews,mergedBy,mergedAt,body` — PR body,
   `"reviews": []`, merge author/time.
3. `git show --stat` for `74c790d` and `c9a63b4` — full commit messages
   and file lists.
4. `git show c9a63b4 -- core/hooks/lib/gate-lib.py core/hooks/board-gate.sh
   core/hooks/approval-gate.sh core/hooks/gh-guard.sh` — the complete
   source diff.
5. `git show c9a63b4 -- core/hooks/tests/run-board-gate-tests.sh
   core/hooks/tests/run-gh-guard-tests.sh core/hooks/tests/run-gate-lib-tests.sh`
   — the complete test diff.
6. `git show 74c790d:core/hooks/board-gate.sh` (pre-image regex
   definitions) and `git show 74c790d:core/hooks/tests/*` (pre-image
   assertion-site counts).
7. `docs/issue-94/reports/implementation.md` — the observed role's own
   record, in full.
8. `docs/issue-94/reports/execution-observation.md` — **does not exist**
   yet; this role has produced nothing prior to this survey.
9. `docs/issue-90/reports/execution-observation.md:351-386` — the prior
   observation's Finding 2, for the record-convention baseline.

Not read as evidence, on purpose: any file under `core/hooks/` in its
current working-tree form. Working-tree `src/` shows what exists now, not
what the observed session did; every source claim below is anchored to a
git blob at a named sha.

## Current state, as read from the artifacts

**Board state (what is merged to `main`).** `19a99ba` merged PR #96, so
`c9a63b4`'s twelve files are the board. Four source files changed:

- `core/hooks/lib/gate-lib.py` — three new symbols appended:
  `GATE_QUOTE_SPAN`, `gate_dequote(text)` (`GATE_QUOTE_SPAN.sub(" ", text)`),
  `gate_outside_quotes(text, pattern)`.
- `core/hooks/board-gate.sh` — one behavioral line changed inside
  `_write_candidate_segments`: `SUBSHELL.search(seg) or FILE_REDIR.search(seg)`
  became `SUBSHELL.search(seg) or gate_lib.gate_outside_quotes(seg, FILE_REDIR.pattern)`,
  plus a 4-line `importlib.util` block.
- `core/hooks/approval-gate.sh` — `WRITEISH` and `_writeish` deleted
  (21 lines including their comment block); the single call site became
  `gate_lib.gate_outside_quotes(cmdline, r"[>|`]|\$\(")`.
- `core/hooks/gh-guard.sh` — every `RULES` tuple gained a third element,
  a bool; the loop became `for pat, why, dequote in RULES` matching
  against `dq if dequote else cmd`, where `dq = gate_lib.gate_dequote(cmd)`.
  Three tuples carry `True`, eight carry `False`.

**Pre-image, for comparison** (`74c790d:core/hooks/board-gate.sh`):
`FILE_REDIR = re.compile(r">>?(?!&)")` at line 112,
`SUBSHELL = re.compile(r"[\`]|\$\(")` at line 118,
`SEGMENT = re.compile(r"(?<!\\)'[^']*'|(?<!\\)\"(?:[^\"\\]|\\.)*\"|\|\||&&|[|;\n]")`
at line 136, and the raw check at line 226.

**Tests added** (assertion-site counts, `^run ` lines, pre → post):
`run-board-gate-tests.sh` 47 → 51, `run-gh-guard-tests.sh` 31 → 36,
`run-approval-gate-tests.sh` 39 → 39, and `run-gate-lib-tests.sh` gained
a `dequote`/`outquotes` helper pair driving 7 new assertions.

**The observed role's own claims**, from
`docs/issue-94/reports/implementation.md`: suites at `71/0` (board-gate),
`42/0` (approval-gate), `37/0` (gh-guard), `36/1` (gate-lib, the 1 called
pre-existing and unrelated); `SUBSHELL` byte-for-byte unchanged; the 8
`False` gh-guard rules textually and order-wise unchanged; approval-gate
observably unchanged; `GATE_QUOTE_SPAN` text identical to the fragment it
centralizes.

**Approval trail.** PR #96 carries `"reviews": []`. Approval ran through
the single-account path: an issue comment whose body is exactly
`APPROVE issue-94/implementation`, by `jjongkwann` (an `approvers.md`
account — `docs/specs/approvers.md` lists `JiwonJung94` and `jjongkwann`).
The record cites that comment at
`docs/issue-94/reports/implementation.md:16-18`.

**Record fields.** `docs/issue-94/reports/implementation.md:5` carries
`code_under_review: 74c790d…`, and each of the four `closed_checks`
entries (`:130`, `:139`, `:150`, `:161`) carries
`code_sha: 74c790d…`. `74c790d`'s own `--stat` is two files, both under
`docs/issue-94/`. The prior observation recorded the same shape as its
Finding 2 at `docs/issue-90/reports/execution-observation.md:351-386`.

## Write surfaces this observation will touch

Only three paths, all this role's own:

1. `docs/issue-94/reports/execution-observation/survey.md` (this file).
2. `docs/issue-94/reports/execution-observation/scout-brief.md`.
3. `docs/issue-94/proposals/2026-08-03-independent-observation-of-pr-96.md`.

Phase 2, if a human approves, adds exactly one more:
`docs/issue-94/reports/execution-observation.md`. Nothing under
`core/`, nothing under the observed role's report or proposal paths.

## Unknowns — what the artifacts do not yet settle

These are the gaps the phase-2 evidence plan has to close; none is
answered here.

- **U1 — before-state failure of the new cases.** Issue requirement 3
  demands the regression cases fail against pre-change code. The diff
  shows 9 new hook-level cases, but the record does not state, per case,
  which ones flip verdict at `74c790d` and which merely re-pin existing
  behavior. Whether each of the 9 is a new-failure case or a
  negative-space case is unresolved from the record alone.
- **U2 — the `gap-f` case's demonstrative value.** The test's own comment
  (`run-gh-guard-tests.sh`, `c9a63b4` diff) says it "denies correctly
  here because of the real, unquoted curl call later on the line, not
  because of the quoted `pulls/5/merge` text", while the record at
  `:80-82` describes it as pinning "the named residual false-positive on
  an out-of-scope rule". Whether those two descriptions agree is
  unresolved.
- **U3 — the suite totals.** Static `^run ` counts at `c9a63b4` are 51
  (board-gate), 36 (gh-guard), 39 (approval-gate) against claimed 71, 37,
  42. The per-suite *deltas* (+4, +5, +0) match the record's "4 new
  cases / 5 new cases / no new cases" exactly, but the absolute totals do
  not reconcile to a one-assertion-per-`run` model, so the harnesses must
  emit assertions from constructs a `^run ` grep does not see. The
  reconciliation model is unknown.
- **U4 — relaxation scope on the three dequoted rules.** `gate_dequote`
  blanks quoted spans before matching. Rule 1's pattern
  (`\bgh\s+pr\s+review\b.*(--approve|-a\b|--request-changes)`) has a `.*`
  that can span a quoted region, and its trailing alternatives are
  ordinary argv tokens that a shell will still deliver when quoted.
  Whether any real, executing act now escapes the three dequoted rules
  that did not escape them at `74c790d` is unresolved.
- **U5 — double-quoted command substitution.** The Rationale keeps
  `SUBSHELL` quote-blind precisely because `$(...)`/backticks stay live
  inside double quotes. board-gate's path is covered by the untouched
  `SUBSHELL` operand, but approval-gate's replacement folds `` [>|`] ``
  and `\$\(` into `gate_outside_quotes`, which dequotes first. Whether
  the approval-gate call site therefore stops seeing a live command
  substitution inside double quotes is unresolved.
- **U6 — centralization vs drift.** `GATE_QUOTE_SPAN` (gate-lib) and
  `SEGMENT` (`board-gate.sh:136` at the pre-image) carry the same
  quote-span alternation text, and the diff does not show `SEGMENT`
  being rewritten to consume the new primitive. Whether the
  centralization actually removes the second copy — the thing that would
  structurally prevent drift — or merely adds a third call site beside
  it, is unresolved.
- **U7 — record-convention recurrence.** Whether issue-94's
  `code_under_review` / `code_sha` shape reproduces the exact defect
  `docs/issue-90/reports/execution-observation.md:351-386` described, and
  whether anything between the two issues was supposed to have settled
  it, is unresolved from the record alone.
- **U8 — scope delivered vs scope asked.** Issue requirement 2 asks that
  gh-guard "split the command into segments and exclude quoted spans
  before judging"; `c9a63b4` adds no segmentation and dequotes 3 of 11
  rules. The proposal states a Rationale for narrowing. Whether the
  narrowing was carried through the approval path (i.e. whether the human
  approved the narrowed scope, not the issue's literal scope) is
  answerable from the approval trail but not yet examined.

## Scout aim

The sweep that follows targets U1, U4/U5, U8 and U6 — i.e. how strong
audits of a *scoped mitigation to a text-matching security gate*
establish (a) that regression cases were failing beforehand, (b) that a
relaxation did not widen the hole, and (c) how partial fixes and their
residuals are expected to be recorded. Angles are derived from these
gaps, not from the issue's wording.
