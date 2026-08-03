---
kind: current-state-survey
subject: issue-98
produced_by: execution-observation
loop_state: phase-1
---

# Current-state survey — what is on the board for issue-98, and what is not yet known

Nothing in this file is a verdict. Every entry below is an observation of an
artifact read this session, plus a note of what a phase-2 judgment would have
to settle about it. Verdict language belongs to phase 2 and is deliberately
absent here.

## Scope of this observation (named, not "recent work")

- **Role under observation:** `implementation`, on branch
  `issue-98/implementation`.
- **Issue:** #98 — "래퍼 명령(bash -c/eval)이 dequote 를 우회한다", authored by
  `jjongkwann`, state OPEN, execution plan `step 1 implementation` /
  `step 2 execution-observation`.
- **PR under observation:** **#103**, "propose(implementation): wrapper-head
  class fix for the dequote bypass", author `jjongkwann`, head
  `issue-98/implementation`, merged 2026-08-03T07:58:36Z as merge commit
  `9cd8a20f1779a180a42e431d1ae07d6ad797c71b`.
- **Its two commits:** `27a0c8aaeba542400f7c3c43828b89c94ffa2d9a`
  (propose, phase 1) and `e51bc09a4ea10965027e692edd5d7f1408a73951`
  (deliver, phase 2).
- **This session's role:** `execution-observation`, on branch
  `issue-98/execution-observation`, issue #98 step 2.

## What was actually read this session (research basis)

- `gh issue view 98` (full body + its single comment) and
  `gh issue view 98 --comments`.
- `gh pr view 103` metadata: number, author, merge commit, head ref, the
  13-path file list, and both commit SHAs.
- `git show e51bc09` — full diff of `core/hooks/lib/gate-lib.py`,
  `core/hooks/board-gate.sh`, `core/hooks/gh-guard.sh`, and the added cases
  in `core/hooks/tests/run-gh-guard-tests.sh` /
  `run-board-gate-tests.sh`; plus the commit message in full.
- `git show 27a0c8a:core/hooks/board-gate.sh` — the pre-delivery state of
  the symbols the delivery moved.
- `docs/issue-98/reports/implementation.md` — the observed role's own
  record, in full (313 lines).
- `docs/issue-100/decisions/2026-08-03-record-citation-format-and-kind-convention.md`
  — the citation convention that landed on main between this PR's two
  commits.
- `git show 85d4e29 -- core/hooks/record-fields-gate.sh` — the mechanical
  check issue-100 Decision 3 added.
- `git merge-base --is-ancestor a339ad9 e51bc09` and
  `git log --format=%P -1 e51bc09` — branch ancestry.

Explicitly **not** read as evidence: the current working-tree `core/hooks/*`
files. Under this role's independence rule `src/` shows what exists now, not
what the observed role did; the admissible artifacts are the diff at
`e51bc09`, the commits, and the record. No part of the observed role's task
was re-executed, and no test harness was run.

## Approval state (contract v3 s19)

- Issue #98 carries exactly one comment, whose entire body is
  `APPROVE issue-98/implementation` (author `jjongkwann`, an
  `docs/specs/approvers.md` account). That string names the **implementation**
  role, not this one.
- No PR exists yet for `issue-98/execution-observation`, and therefore no
  review Approve on it.
- Consequence for this session: this role is in **phase 1**. Its record
  (`docs/issue-98/reports/execution-observation.md`) is phase-2 output and is
  not written in this session.

## What the observed PR contains (structural, no judgment)

1. **New shared primitives** in `core/hooks/lib/gate-lib.py` at `e51bc09`:
   `TRANSPARENT` (gate-lib.py:194), `TRANSPARENT_TAKES_ARG` (:200),
   `_resolve_transparent` (:203), `gate_head_of` (:238), `WRAPPER_HEADS`
   (:248), `_WRAPPER_C_FLAG_RE` (:252), `_PERL_E_FLAG_RE` (:255),
   `gate_wrapper_head_before` (:258).
2. **gh-guard.sh** at `e51bc09`: a `_deny_for` helper (:128) and a new
   per-quoted-span branch (:144-148) that runs only `if dequote and
   re.search(pat, cmd)`, iterates `GATE_QUOTE_SPAN` matches, and denies when
   `gate_wrapper_head_before` returns a non-empty head. The 8 `dequote=False`
   rules are untouched by the diff.
3. **board-gate.sh** at `e51bc09`: `SEGMENT` now built from
   `gate_lib.GATE_QUOTE_SPAN.pattern` (:140); the local `TRANSPARENT`/
   `_head_of` definitions are deleted and the one call site reads
   `gate_lib.gate_head_of(stripped)` (:223); `SED_WRITE_CMD` added (:175);
   the `READ_UNLESS_INPLACE` branch (:231-241) additionally treats a raw
   `FILE_REDIR` hit (awk/gawk) or a `SED_WRITE_CMD` hit (sed) as a write.
4. **Tests**: 15 new `run-gh-guard-tests.sh` cases at :94-124 (9
   issue-named wrapper variants, 5 hunt-found variants, 1 named over-block
   residual `wrapper-bash-c-plain-grep`) and 8 new
   `run-board-gate-tests.sh` cases at :297-319.
5. **Handbooks**: `gate-house-standard.md`, `board-gate-tests.md`,
   `gh-guard-tests.md` all appear in PR #103's file list.

## Open unknowns this survey could not settle from reading alone

These are the write surfaces where the record makes a claim the diff does not
by itself confirm or deny. Each is a phase-2 evidence line, not a finding.

- **U1 — pre-change failure scope.** The commit message of `e51bc09` states
  "Every new regression case confirmed to fail on the pre-issue-98 code via
  git stash". The record's second `closed_checks` entry
  (`docs/issue-98/reports/implementation.md:221-231`) documents a narrower
  run: 10 FAILs covering the 9 original wrapper cases plus
  `wrapper-bash-c-plain-grep`, with the 5 hunt-driven cases explicitly added
  *after* that stash/pop cycle and evidenced instead against the
  pre-hunt-fix code (record:232-243). Whether the two statements are
  reconcilable, and whether the 14 wrapper deny cases as a set are pinned to
  a pre-change failure, is a phase-2 question.
- **U2 — board-gate behavior delta from the TRANSPARENT relocation.**
  At `27a0c8a`, `board-gate.sh:172` defined
  `TRANSPARENT = ("xargs", "env", "time", "nice", "command", "builtin")` —
  6 entries. At `e51bc09`, `gate-lib.py:194-198` defines the same name with
  **8** entries, adding `timeout` and `nohup`, plus
  `TRANSPARENT_TAKES_ARG = ("timeout",)` (:200). `board-gate.sh:223` now
  consumes that extended tuple. A mechanical trace of
  `_write_candidate_segments` (board-gate.sh:220-242) over a command such as
  `timeout 30 cat <foreign-record>` resolves the head differently before and
  after (`timeout`, which is in none of `READ_ONLY_HEADS` (:99-103),
  `READ_UNLESS_INPLACE` (:108) or the git branch, versus `cat`, which is in
  `READ_ONLY_HEADS`). None of the 8 new board-gate cases at :297-319 pins a
  `timeout`/`nohup`-prefixed **read**. Whether this delta is intended,
  whether its direction matters, and whether the record's "confirmed by the
  hunt / harmless" characterization (record:90-92) covers it, are phase-2
  questions.
- **U3 — negative space.** `run-gh-guard-tests.sh:78-80` holds the three
  pre-existing `quote-*` allow cases including
  `grep -n "... gh pr merge ..."`; the diff does not modify them. A new
  case at :124, `wrapper-bash-c-plain-grep`, asserts **deny** for
  `bash -c "grep -n 'gh pr merge' x.py"`, described in the diff's own
  comment as an accepted over-block residual. Issue #98 requirement 3 asks
  that the mitigation not undo the legitimate quoted-data use. Whether the
  preserved-plus-over-blocked split satisfies that requirement, and at what
  risk, is a phase-2 question.
- **U4 — the recorded out-of-scope limit.** The record's `## Hunt`
  (record:192-204) and `## Open findings` (record:265-277) name
  adjacent-quoted-string concatenation (`bash -c "gh pr mer""ge 5"`) as a
  structural, pre-existing `GATE_QUOTE_SPAN` limitation left unfixed. The
  same section states the `nice -n 10`-class value-taking-flag wrapper was
  **found and fixed** (record:184-188), pinned by
  `run-gh-guard-tests.sh:110-113`; what remains is that
  `gate_head_of`/`TRANSPARENT` keep the imprecision for board-gate's own
  use, called harmless there (gate-lib.py:258-283 docstring; record:90-92).
  Which of these is actually the residual limit, and its risk, is a phase-2
  question.
- **U6 — live gate behavior met while producing this survey (not about PR
  #103's content).** The first attempt to commit these phase-1 files was
  refused by the live `board-gate.sh` hook: `docs/issue-98/reports/
  implementation.md belongs to another role. execution-observation writes
  only execution-observation.md, execution-observation/** — never a foreign
  record. (contract v3 s11)`. No such write was attempted; the foreign path
  appeared only as a *citation inside the commit message text* passed to
  `git commit -F -` on stdin. The same class of path-token false positive
  was recorded by issue-94's own observation (`2680c8f`). Worked around by
  passing the message from a file outside the repo. Whether this is a
  distinct finding or a known, already-reported residual is a phase-2
  question; it concerns the board's current gate, not PR #103's delivery.
- **U5 — citation convention.** `docs/issue-98/reports/implementation.md:5`
  reads `code_under_review: 27a0c8aaeba542400f7c3c43828b89c94ffa2d9a` — a
  bare 40-hex token, and specifically the *proposal* commit, not the
  delivery commit `e51bc09`; its five `closed_checks` entries (record:215,
  222, 233, 245, 254) each carry `code_sha: 27a0c8aa…`. Issue-100's
  decision, merged to main as `a339ad9` at 2026-08-03T06:33:15Z, states
  `code_under_review` cites a file list (decision:25-49) and
  `closed_checks[].code_sha` becomes `ref: <file>:<line>`
  (decision:51-66), enforced by a `record-fields-gate.sh` check scoped to
  `role in ("coding", "implementation")` that denies a bare-sha
  `code_under_review` (added in `85d4e29`). Measured ancestry:
  `git merge-base --is-ancestor a339ad9 e51bc09` returns **non-zero** and
  `git log --format=%P -1 e51bc09` is `27a0c8aa…` — the delivery commit's
  branch did **not** contain issue-100's decision or its gate check, though
  main did at the time the delivery was authored (e51bc09 authored
  2026-08-03T07:38:40Z, i.e. after `a339ad9`). `kind: coding-record`
  (record:2) matches decision:92-103. What follows from this — for the
  record, and for the "structurally prevented" claim in decision:68-90 — is
  a phase-2 question.
