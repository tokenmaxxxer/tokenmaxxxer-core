---
kind: coding-record
subject: issue-132
produced_by: implementation
code_under_review: `core/hooks/tests/run-board-gate-tests.sh`, `docs/handbooks/board-gate-tests.md`
loop_state: landed
upstream:
  - path: docs/issue-132/proposals/2026-08-04-wrapper-class-closeout-r3-write-pin-record-fix-b1b2-note.md
    sha: a7879861081d74324f55a50b42bf7e44a0804f4d
---

# Implementation record — issue-132

## Why

Phase 2, approved via issue-level comment `APPROVE issue-132/implementation`
(exact string), posted 2026-08-04T07:32:16Z by `jjongkwann` — a
`docs/specs/approvers.md` account (`- jjongkwann`) who also authored PR
#135, so single-account mode applies per contract v3 s19. Reconfirmed in
this session (`gh issue view 132 --json state,comments`, `gh pr view 135
--json author`): issue state `OPEN`, one comment, `author.login:
"jjongkwann"`, body exactly `"APPROVE issue-132/implementation"`,
`isMinimized: false`; PR #135 `author.login: "jjongkwann"`.

Delivering the approved proposal's three requirements: F1 (a
write-direction pin for R3 in `run-board-gate-tests.sh`), F2 (the
`implementation.md:321` count correction), and B1/B2 (a handbook paragraph
documenting the residual flag-table coverage as accepted and fail-closed).
F2 could not be delivered as approved — see `## Rationale for deviations`.

## What was done

### F1 — `core/hooks/tests/run-board-gate-tests.sh`

Added one new case immediately after the existing R2 negative-space
sibling (`bash-git-c-flag-rm-foreign-issue`), exactly as the proposal
specified, with the comment block naming issue-124/R3, issue-132/F1, and
the root cause (the resolver has no allow/deny concept, so the pin
belongs at the verdict layer, not the resolver layer):

```
run deny  bash-wrapper-timeout-s-git-rm-foreign-issue Bash '{"command":"timeout -s KILL 30 git rm -r docs/issue-49/reports"}'
```

Baseline (before the case existed): `bash
core/hooks/tests/run-board-gate-tests.sh` → `91 passed, 0 failed`. After
adding the case: `92 passed, 0 failed` — the new case reports `ok …
deny`, no other case's outcome changed.

**Fail-closed proof** (the proposal's resolved framing of "red-green 증명"
for a case that denies both before and after the fix — see the proposal's
`## Rationale`, F1, "Rejected alternative: verdict-flip red-green proof"):
locally neutralized `TRANSPARENT_FLAG_TAKES_ARG["timeout"]` in
`core/hooks/lib/gate-lib.py` (removed the `"timeout": ("-s", "--signal"),`
entry only, not committed) and re-ran both suites:

```
run-board-gate-tests.sh → ok  bash-wrapper-timeout-s-git-rm-foreign-issue deny
                           == 92 passed, 0 failed ==
run-gate-lib-tests.sh   → FAIL gate_head_of: timeout's own -s value-taking
                           flag no longer swallows the bare DURATION slot
                           want=git got=30
                           gate-lib: 56 passed, 2 failed
```

This confirms both halves of the proof: the new board-gate case's `deny`
verdict is unchanged with R3's fix removed (fail-closed, no verdict
regression possible even without R3), while the genuine resolver-level
red→green R3 actually fixed (`run-gate-lib-tests.sh`'s `gate_head_of`
`timeout -s KILL 30 git log` case, `run-gate-lib-tests.sh:217`) flips to
failing under the same neutralization — the real defect this write-pin
rides on. Restored `gate-lib.py` from a pre-edit copy immediately after;
`git status --porcelain core/hooks/lib/gate-lib.py` and `git diff --
core/hooks/lib/gate-lib.py` both confirm zero bytes changed against the
landed tree.

### B1/B2 — `docs/handbooks/board-gate-tests.md`

Appended one paragraph after the existing R3 paragraph naming both
residues as accepted, intentionally-bounded, fail-closed limitations (not
unnoticed gaps) — `GIT_GLOBAL_VALUE_FLAGS` covering `-C`/`-c` only (B1),
`TRANSPARENT_FLAG_TAKES_ARG` covering one flag per wrapper (B2) — with the
expansion trigger (a concrete over-blocking case, not speculative
coverage), mirroring the file's own `gap-awk-comparison-over-block`
convention. Also added the short addendum the proposal flagged as
possibly needed once F1 landed: the R3 paragraph's closing sentence now
also names the new `run-board-gate-tests.sh` write-direction pin, since
the sentence previously stated R3 was pinned only by
`run-gate-lib-tests.sh`'s `headof` cases (accurate before this delivery,
would have gone stale after it).

Neither `TRANSPARENT_FLAG_TAKES_ARG` nor `GIT_GLOBAL_VALUE_FLAGS` gained
any new entry — confirmed by `git diff -- core/hooks/lib/gate-lib.py`
(empty) and `git diff -- core/hooks/board-gate.sh` (this file was never
touched this session).

### F2 — not delivered from this branch; see `## Rationale for deviations`

## What did not work

- Attempted `Edit` on `docs/issue-124/reports/implementation.md:321` (the
  count correction the proposal's `## What will be done` item 2 froze).
  Expected: the write would land, since the proposal explicitly named this
  file in its write set and its own `## Rationale` judged the correction
  as inside the #100 precedent's carved-out exception. Actual:
  `board-gate.sh` denied it — `writing docs/issue-124/ requires branch
  issue-124/implementation (current: issue-132/implementation). Every role
  output reaches main only through a PR the human merges — never a direct
  write from another branch. (contract v3 s10)`. Not fixed — this is R4,
  a structural block, not a typo; see `## Rationale for deviations`. No
  bytes of `docs/issue-124/reports/implementation.md` changed (`git status
  --porcelain docs/issue-124/reports/implementation.md` empty throughout).

## Doc-placement ladder

- [x] `docs/handbooks/board-gate-tests.md` — the B1/B2 accepted-limitation
  paragraph and the R3-paragraph addendum, same turn as the test-suite
  change they document (operational-surface entries, contract §21's
  handbook grant). No new env var, dependency, or migration.
- [ ] F2's count correction — not placed this turn; see `## Rationale for
  deviations` and `## Next steps`.

## Hunt

`warrant-hunter` is not among this session's available `Agent`-tool
subagent types (same absence issue-100's, issue-118's, and issue-124's
own records note). Adopted the stance directly by inspection in its
place, rotated from issue-100's boundary-prober and issue-90's
adversarial-reader.

### Stance: scope-creep hunter — assume the delivery quietly widened past the frozen write set; find where.

Verdict: NO FINDING.

- `git status --porcelain` (repo root, this session): exactly two files
  modified — `core/hooks/tests/run-board-gate-tests.sh`,
  `docs/handbooks/board-gate-tests.md` — matching the proposal's frozen
  `files:` list (minus the two files the block below explains, and minus
  the two documentation files this proposal itself, `docs/issue-132/
  reports/implementation/survey.md` and `docs/issue-132/proposals/…`,
  which phase 1 already landed in commit `a787986`).
- `git diff -- core/hooks/lib/gate-lib.py`, `git diff --
  core/hooks/board-gate.sh`, `git diff -- core/hooks/approval-gate.sh`:
  all empty — the proposal's `## Constraints` ("No change to any of PR
  #126's landed code") holds; the local `gate-lib.py` neutralization used
  for the fail-closed proof was restored before this check, confirmed
  clean.
- `TRANSPARENT_FLAG_TAKES_ARG`/`GIT_GLOBAL_VALUE_FLAGS`: re-read both
  tables in the current tree after all edits — four and two entries
  respectively, unchanged from before this session, matching the
  proposal's explicit "no new table entries" constraint.
- `docs/issue-124/reports/implementation.md`: confirmed untouched (see
  `## What did not work`) rather than partially edited or reformatted
  beyond the one sentence the proposal named.

Seed: `docs/issue-132/proposals/2026-08-04-wrapper-class-closeout-r3-write-pin-record-fix-b1b2-note.md`
`## What will be done` and `## Out of scope`, commit `a787986`.
Started/ended: this session, after applying the two delivered edits and
confirming the F2 block.

## Rationale for deviations

The approved proposal's `## What will be done` item 2 named
`docs/issue-124/reports/implementation.md:321` as part of this PR's frozen
write set, to be edited in place (six → eight, matching the file's own
`## Verify` table). This edit could not be made from this branch:
`core/hooks/board-gate.sh` R4 denies any write under `docs/issue-<n>/`
unless the current git branch is exactly `issue-<n>/<CLAUDE_ROLE>` —
confirmed live (`## What did not work`, above) against
`docs/issue-124/reports/implementation.md`.

This is not a new discovery in this codebase — it is the *identical*
block `docs/issue-100/reports/implementation.md`'s own `## Rationale for
deviations` (`:86-107`) already recorded, against the same two-file class
of cross-issue record correction, for `docs/issue-90/` and
`docs/issue-94/`'s own records. The proposal's `## Rationale` (F2 section)
cited issue #100's *decision document* — which states the file-list
`code_under_review` convention and, in its own body text, describes a
"dedicated follow-up issue authorizing an in-place correction… done" — as
precedent that this shape of correction lands in place. That citation
is incomplete: issue #100's *decision document* records the convention
adopted going forward, but issue #100's own *implementation record*
(`docs/issue-100/reports/implementation.md:59-73,86-107`) shows the
in-place correction of `docs/issue-90/` and `docs/issue-94/`'s records was
attempted and denied by this same R4 rule, and was carried forward as an
undelivered `## Next steps` item, not completed. The proposal's phase-1
survey read the decision document's Decision 1-4 text and the observed
proposal's `## Rationale`, but did not read issue-100's own `##
What did not work`/`## Rationale for deviations` sections before citing
it as a completed-in-place precedent — this session's own live attempt
surfaced the gap the survey did not.

This does not change the survey's F2 *judgment* (that a bounded,
verdict-preserving, single-count correction of one's own already-merged
record, grounded in a published observation Finding, is inside the shape
#100 already legitimized rather than the general no-retroactive-edit
prohibition) — it changes only the *delivery mechanism*: like #100 before
it, the correction is authorized in principle but structurally
undeliverable from this branch, and is carried forward the same way #100
carried its own analogous item forward.

Scope actually delivered: F1 (the write-direction pin, with fail-closed
proof) and B1/B2 (the handbook paragraph). Not delivered: F2 (the count
correction to `docs/issue-124/reports/implementation.md:321`). This
record does not silently drop that requirement; it is carried forward
under `## Next steps`.

## Next steps

F2 (correcting `docs/issue-124/reports/implementation.md:321` from "the
six new cases (2 per habitat)" to "the eight new cases (2 + 2 + 4…)",
exactly as this proposal's `## What will be done` item 2 specifies, under
the F2 Rationale judgment this proposal already argued) needs a session
running on `issue-124/implementation` — the only branch `board-gate.sh`
R4 permits to write that path — or whatever mechanism the user chooses
for a cross-issue documentation correction under contract v3's
branch-ownership model. This mirrors `docs/issue-100/reports/
implementation.md:112-115`'s own unresolved analogous item; both remain
open, undelivered corrections to already-merged records, blocked by the
same rule, as of this record.

## Resolution path

No open finding is raised against F1 or B1/B2's delivered content; the
Hunt pass above closed with no finding. F2 is not a finding against this
delivery's own artifacts — it is an undelivered requirement, structurally
blocked, documented above and carried to `## Next steps`. Human decision
needed: whether to open a dedicated `issue-124/implementation` session (or
equivalent) to complete F2, defer it, or accept the record's known,
internally-flagged arithmetic error (`:308` vs `:321`) as a standing,
documented discrepancy.

## Verify

**F1 red-green** (fail-closed proof; full command output above in `##
What was done`):

| check | before neutralization | after neutralizing `TRANSPARENT_FLAG_TAKES_ARG["timeout"]` |
|---|---|---|
| `run-board-gate-tests.sh` new case | `deny` | `deny` (unchanged — fail-closed) |
| `run-gate-lib-tests.sh` `gate_head_of … timeout -s KILL 30 git log` | `git` (correct) | `30` (wrong — the genuine red) |

**Full-suite zero-regression confirmation**, all three run after both
delivered edits, `gate-lib.py` restored to landed state:

```
bash core/hooks/tests/run-approval-gate-tests.sh   → 44 passed, 0 failed
bash core/hooks/tests/run-board-gate-tests.sh      → 92 passed, 0 failed
bash core/hooks/tests/run-gate-lib-tests.sh        → 57 passed, 1 failed
```

The one `run-gate-lib-tests.sh` failure (`compliance-check.sh`, hand-rolled
kill-switch + replace shape, `want=deny got=allow`) is the same pre-existing
sandbox artifact `docs/issue-124/reports/implementation.md:323-329`
already documents (`mktemp`/`mkdir` denied under `/` in this sandbox) —
present in this session's own baseline run before any edit, not introduced
by this delivery.

closed_checks:
- name: TRANSPARENT_FLAG_TAKES_ARG and GIT_GLOBAL_VALUE_FLAGS gained no new entries
  ref: core/hooks/lib/gate-lib.py:208-213, core/hooks/board-gate.sh (git diff empty this session)
- name: gate-lib.py's local fail-closed-proof neutralization was fully restored, zero diff against landed tree
  ref: core/hooks/lib/gate-lib.py (git status --porcelain empty)
- name: docs/issue-124/reports/implementation.md carries zero bytes of change (F2 undelivered, not partially applied)
  ref: docs/issue-124/reports/implementation.md (git status --porcelain empty)
