---
kind: execution-observation-record
subject: issue-90
produced_by: execution-observation
observed_role: implementation
observed_pr: 91
observed_commits:
  - c66aecc1d1efe16f5a79901bb146f382c07996f4
  - d52d1e68c15dc8711ee0834520d643059942404d
observed_record: docs/issue-90/reports/implementation.md
loop_state: landed
upstream:
  - path: docs/issue-90/proposals/2026-08-03-observe-issue-90-implementation-execution.md
    sha: 6842c5f
---

# Execution observation — issue-90 implementation pass (PR #91)

## Independence

This role did not author or edit the observed artifact, in this session or
any other. No file under `core/`, `test/`, `docs/handbooks/`, or
`docs/issue-90/reports/implementation*` was written, and none is written
by this record. Nothing in PR #91 was re-executed: neither gate nor
either harness was run, at `c66aecc`, at `c66aecc^`, or anywhere else.
The admissible evidence for everything below is the merged PR, its
commits, and the observed role's own record — nothing produced by
re-running the observed role's task.

## Why

Issue #90's `## 실행 계획` lists step 2 as execution-observation, and the
human approved it with the exact-string comment
`APPROVE issue-90/execution-observation`, posted 2026-08-03T02:02:06Z by
`jjongkwann` (listed at `docs/specs/approvers.md:2`) at
https://github.com/tokenmaxxxer/tokenmaxxxer-core/issues/90#issuecomment-5161558759.
The observed role's own record claims 67/0 and 42/0 at
`docs/issue-90/reports/implementation.md:56-59` and reports catching three
vacuous cases mid-build at `:61-81`; the point of this pass is to settle
those claims from artifacts rather than take them on trust — in
particular whether the added cases discriminate at all, and whether the
deny cases deny for their named reason.

## What was done

Everything read first-hand this session, and cited by name throughout:

- `c66aecc` (deliver) and `d52d1e6` (propose) — message, metadata, full diff.
- The `c66aecc` and `c66aecc^` blobs of `core/hooks/board-gate.sh`,
  `core/hooks/approval-gate.sh`, `core/hooks/tests/run-board-gate-tests.sh`,
  `core/hooks/tests/run-approval-gate-tests.sh`.
- `docs/issue-90/reports/implementation.md` (the observed role's record).
- The approved write set at
  `docs/issue-90/proposals/2026-08-03-scope-board-gate-candidates-and-port-approval-gate-fixes.md:93-123`.
- PR #91's `body`, `reviews` (0), `comments` (0), `createdAt`, `mergedAt`.
- Issue #90's body and its three comments (URLs cited inline below), and
  `docs/specs/approvers.md:1-2`.

The phase-1 proposal
(`docs/issue-90/proposals/2026-08-03-observe-issue-90-implementation-execution.md:69-115`)
declared three checks, and they are what this record answers, unchanged:
(a) whether each of the 8 cases `c66aecc` added actually fails at
`c66aecc^`; (b) whether each deny case denies for its named reason rather
than an incidental one; (c) whether the mitigation stayed inside the
gates' protection scope.

The technique for all three is a **static discrimination trace**: each
case's literal command line is decoded through the harness's payload
construction, then walked through the gate's code path at `c66aecc` and
again at `c66aecc^`, and the two verdicts compared. Line references are
to the blob at the named commit, not to the working tree. Where a trace
could not settle a question it would be written as undetermined, not as
fine; no case below required that.

Criterion (b) needs this trace specifically because neither harness can
answer it: both discard the gate's stderr and compare exit code only
(`core/hooks/tests/run-board-gate-tests.sh:42` and `:22-28`;
`core/hooks/tests/run-approval-gate-tests.sh:103` and `:21-27`, both at
`c66aecc`). A deny is a deny to the harness whatever its reason — which
is precisely the hazard the observed role hit and recorded at
`docs/issue-90/reports/implementation.md:61-81`.

---

# Verdict

## Outcome — did PR #91 land what issue #90 asked

**Landed, with one protection-scope regression and one residual gap.**

Both named defects were fixed, and the delivered write set is exactly the
approved one. Issue #90's defect 1 (the candidate scan sweeping the whole
command line) is addressed by `_write_candidate_segments()` at
`core/hooks/board-gate.sh:208-240` (`c66aecc`), with the candidate scan
narrowed to `"\n".join(failing_segments)` at
`core/hooks/board-gate.sh:264-266` (`c66aecc`) — the same shape the
proposal approved at
`docs/issue-90/proposals/2026-08-03-scope-board-gate-candidates-and-port-approval-gate-fixes.md:95-113`.
Issue #90's defect 2 (approval-gate's twin defects) is addressed by
`"cd"` at `core/hooks/approval-gate.sh:85` and the quote-span-first,
`(?<!\\)`-guarded `WRITEISH` plus `_writeish()` at
`core/hooks/approval-gate.sh:96-107` (`c66aecc`), matching the approved
text at proposal lines `114-123`. Both handbooks were updated in the same
commit (`c66aecc`: `docs/handbooks/board-gate-tests.md` +14,
`docs/handbooks/approval-gate-tests.md` +30), satisfying issue #90's
same-turn documentation constraint.

The record's harness counts are corroborated exactly. Recounting the
registered assertions in the `c66aecc` blobs: board-gate 57 `run`/`runb`
lines + 5 `drifted` + `noRole` + `noremote` + `fastpath` + 2 `garbage` =
**67**, matching `docs/issue-90/reports/implementation.md:56`;
approval-gate 39 `run` lines + `noremote` + `norole` + `kill_switch` =
**42**, matching `docs/issue-90/reports/implementation.md:57`. What this
corroborates is the *registration* count only — a static recount cannot
confirm the `0 failed` half of that claim, and this observation does not
assert it either way, since confirming it would require the re-run this
role is prohibited from doing.

### (a) Do the 8 added cases fail at `c66aecc^`?

Four of the eight do. The other four are, by their own stated design in
the harness comments, guard cases that must hold on **both** sides of the
change; none of them is claimed by the observed role to be a mutant-kill
case.

| # | case (`c66aecc`) | want | at `c66aecc` | at `c66aecc^` | fails at `c66aecc^`? |
|---|---|---|---|---|---|
| 1 | `bash-unresolved-head-then-read` — `run-board-gate-tests.sh:269` | allow | allow | **deny (R4)** | **yes** |
| 2 | `bash-unresolved-head-real-write` — `run-board-gate-tests.sh:273` | deny | deny (R4) | deny (R4) | no — negative-space sibling |
| 3 | `bash-cd-then-read-own-reports` — `run-approval-gate-tests.sh:166` | allow | allow | **deny (no approval)** | **yes** |
| 4 | `bash-cd-then-write-src` — `run-approval-gate-tests.sh:169` | deny | deny (no approval) | deny (no approval) | no — negative-space sibling |
| 5 | `bash-quoted-redirect-in-grep` — `run-approval-gate-tests.sh:176` | allow | allow | **deny (no approval)** | **yes** |
| 6 | `bash-single-quoted-pipe-grep` — `run-approval-gate-tests.sh:177` | allow | allow | **deny (no approval)** | **yes** |
| 7 | `bash-quoted-redirect-then-real-pipe` — `run-approval-gate-tests.sh:180` | deny | deny (no approval) | deny (no approval) | no — negative-space sibling |
| 8 | `bash-escaped-quote-then-write` — `run-approval-gate-tests.sh:186` | deny | deny (no approval) | deny (no approval) | no — kills a mutant of the *new* code |

Traces for the four that discriminate:

- **Case 1**, `date; grep -n foo docs/issue-49/reports/x.md`. At
  `c66aecc`, `_split_segments` cuts at `;`; segment `date` fails
  classification (`date` is in neither `READ_ONLY_HEADS` at
  `core/hooks/board-gate.sh:96-99` nor `READ_UNLESS_INPLACE` at `:104`),
  segment `grep …` passes on head `grep`; the scan runs over `date` only
  (`:264-266`), finds no `docs/` token, falls back to
  `candidates = ["docs/"]` (`:268`), which yields no hit at `:277-282`
  and reaches `allow()` at `:284`. At `c66aecc^`, `_reads_only` returns
  `False` on the same `date` segment and the scan runs over the whole
  `cmdline`, so `docs/issue-49/reports/x.md` becomes a candidate and R4
  denies (branch `issue-3/qa`, expected `issue-49/qa`). This is the false
  positive issue #90 named, and it is genuinely killed.
- **Case 3**, `cd docs/issue-7/reports/coding && ls`. At `c66aecc`, head
  `cd` is in `READ_ONLY_HEADS` (`core/hooks/approval-gate.sh:85`) and
  `_writeish` finds nothing (`:139-140`) → `allow()`. At `c66aecc^`, `cd`
  is absent from that tuple, so the early allow is skipped, the token
  `docs/issue-7/reports/coding` is collected at `:141-143`, and
  `execution_surface()` returns `True` on it — the role-own-subtree
  exemption at `:124` tests `tail.startswith("reports/coding/")` and the
  tail here is exactly `reports/coding` with no trailing slash — so the
  gate reaches the approval check and denies at `:316-321` under the
  harness's `nopr` stub (`run-approval-gate-tests.sh:46`).
- **Cases 5 and 6**, `grep -n "a > b" src/app.py` and
  `grep -n 'a > b' src/app.py`. At `c66aecc`, `WRITEISH`'s quoted-span
  alternatives match the whole `"a > b"` / `'a > b'` span first and
  `_writeish` skips it (`core/hooks/approval-gate.sh:101-107`) →
  `allow()` at `:139-140`. At `c66aecc^`,
  `WRITEISH = re.compile(r"[>|`]|\$\(")` matches the `>` inside the
  quotes, the early allow is skipped, `src/app.py` is collected as a
  candidate, and the gate denies at the approval check.

Why the other four do not discriminate, and why that is not a defect:
cases 2, 4 and 7 are labelled negative-space siblings in the harness
itself (`run-board-gate-tests.sh:270-272`,
`run-approval-gate-tests.sh:167-168` and `:178-179`, all at `c66aecc`) —
their job is to prove the mitigation did **not** open a hole, which by
construction requires the same verdict on both sides. Case 8 is a
warrant-hunt regression ported from issue-88
(`run-approval-gate-tests.sh:181-185`, `c66aecc`); at `c66aecc^` the
quote-blind `WRITEISH` matches the bare `>` and denies for a different
reason, but the case does kill a real mutant of the *new* code: dropping
the `(?<!\\)` guard from the double-quote alternative makes the regex
match `" > docs/issue-7/x.md #"` as a quoted span, `_writeish` returns
`False`, and head `ls` reaches `allow()` — a `want deny` failure.

The observed record's phrasing at
`docs/issue-90/reports/implementation.md:56-59` ("all 8 new cases pass to
their proposal-specified verdict") is accurate as written, and it does not
claim mutant-kill for all eight; the 4/8 split above is the detail it
leaves implicit rather than a discrepancy with it.

### (b) Do the deny cases deny for their named reason?

**Yes, all four, and none via an incidental path.** Because both harnesses
compare exit code only, this had to be traced rather than read off a
green suite.

- Case 2 (`date > docs/issue-49/reports/x.md`) reaches
  `core/hooks/board-gate.sh:406-409` (`c66aecc`) — R4, branch
  `issue-3/qa` against the required `issue-49/qa`. That deny is only
  reachable *because* the candidate was extracted from the failing
  segment at `:264-266`; had the scoping dropped it, `hits` would be
  empty and `:284` would allow. The case therefore tests what its comment
  claims.
- Cases 4, 7 and 8 all reach `core/hooks/approval-gate.sh:316-321`
  (`c66aecc`) — the "neither the PR … nor issue … carries an approval"
  deny, under the `nopr` stub which supplies no PR and no issue comments
  (`run-approval-gate-tests.sh:46`). None of them denies through the
  unreadable-payload path at `core/hooks/approval-gate.sh:74-75`: the
  JSON that `run()` builds at `run-approval-gate-tests.sh:97` is valid for
  each. Case 4 carries no quote characters at all; case 7 constructs
  `{"command":"grep -n \"a > b\" x | tee docs/issue-7/reports/coding.md"}`;
  case 8 constructs `{"command":"ls \\\" > docs/issue-7/x.md #\""}`, which
  decodes to the command line `ls \" > docs/issue-7/x.md #"` its own
  comment at `run-approval-gate-tests.sh:185` states it intends. The
  pre-escaping the observed role describes at
  `docs/issue-90/reports/implementation.md:63-81` is present and correct
  in the committed lines.

That last point is worth stating plainly, since it is the specific failure
the observed role recorded against itself: the three cases it describes as
vacuous mid-build are **not** vacuous as committed. The self-reported
episode was real and was fixed before `c66aecc`.

### (c) Did the mitigation stay inside the gates' protection scope?

**Mostly, but not entirely — see Finding 1.** Two of the three changes are
clean:

- The approval-gate `_writeish()` change narrows nothing that was traced.
  Its documented converse (a real quote preceded by an escaped backslash
  over-splits rather than under-splits) errs toward denying, the safe
  direction, exactly as `core/hooks/board-gate.sh:133-135` (`c66aecc`)
  describes for the same regex shape.
- Adding `"cd"` to `core/hooks/approval-gate.sh:85` does widen the early
  `allow()` at `:139-140`, because that gate has no segment splitting and
  the head is the whole line's first word (`:138`) — so
  `cd docs/issue-7 && cp a.md src/app.py` allows. But that hole is
  pre-existing and class-identical for the twelve heads already listed at
  `c66aecc^`: `ls x && cp a.md src/app.py` allowed there too, for the same
  reason. `c66aecc` adds one entry to an existing class rather than
  opening a new one, and it is exactly the port issue #90 asked for.

The board-gate scoping change is where scope actually moved; that is
Finding 1.

## Trajectory — was the phase-1 → phase-2 path sound

**Sound on the gate, with one closure defect the human has already
caught.**

The order is correct and every step is a real artifact. `d52d1e6`
(2026-08-03 10:00:56 +0900) is docs-only — 2 files, 414 insertions, both
under `docs/issue-90/` — so nothing executable preceded the approval. PR
#91 opened at 2026-08-03T01:01:09Z. The approval is
`APPROVE issue-90/implementation`, posted at 2026-08-03T01:06:20Z by
`jjongkwann`, listed at `docs/specs/approvers.md:2`
(https://github.com/tokenmaxxxer/tokenmaxxxer-core/issues/90#issuecomment-5161283887);
the whole comment body is that exact string, which is the single-account
path contract v3 s19 requires given PR #91's author is the same account.
PR #91 carries `reviews: 0`, so the two-account path was correctly not
relied on. `c66aecc` (2026-08-03 10:17:26 +0900 = 01:17:26Z) lands
**after** the approval, and PR #91 merged at 2026-08-03T01:21:15Z. The
delivered write set matches the approved one at proposal lines `93-123`
with no scope creep: the two gates, the two harnesses, the two handbooks,
and the record.

Phase-1 rigor also holds up: the survey and proposal both exist
(`docs/issue-90/reports/implementation/survey.md`,
`docs/issue-90/proposals/2026-08-03-scope-board-gate-candidates-and-port-approval-gate-fixes.md`,
both introduced by `d52d1e6`), and the proposal's write set is specific
down to line ranges rather than prose intent.

The one trajectory defect is closure, not approval: `c66aecc`'s message
carries `Closes #90` while the issue's own `## 실행 계획` still had step 2
(execution-observation) unchecked, so merging PR #91 auto-closed the issue
with the plan unexhausted. The human caught this and reopened at
2026-08-03T01:47:44Z
(https://github.com/tokenmaxxxer/tokenmaxxxer-core/issues/90#issuecomment-5161476238),
naming it an issue-189 contract violation already tracked as issue #228.
This observation records it as observed and already-owned; it does not
re-raise it.

A second, smaller trajectory note: PR #91's body still reads "No code
changes in this PR — phase 1 only. Phase 2 (implementation) opens after an
approvers.md human Approves", yet `c66aecc` merged under that body. The
statement was true when written and was never updated. It is a
record-accuracy blemish on the merged PR, not a gate violation — the
approval it describes did in fact arrive before the code.

## Step — which specific artifact is deficient

Two findings, in `## Open findings` below. Everything else traced clean:
the two gate diffs match the approved proposal text, the eight cases are
all non-vacuous as committed, both handbook entries describe what the code
actually does, and both harness counts recount exactly.

## Open findings

### Finding 1 — board-gate: scoping the candidate scan removed a deny that `c66aecc^` had

**Artifact:** `core/hooks/board-gate.sh:226` and `:264-268` (`c66aecc`).

**Impact.** A command whose write target is expressed *relative* to a
`cd`-ed foreign issue directory now allows where `c66aecc^` denied.
Traced example: `cd docs/issue-49 && date > x.md`, from the harness's
standard board context (role `qa`, branch `issue-3/qa`). At `c66aecc`,
`_split_segments` cuts at `&&`; segment `cd docs/issue-49` classifies
read-only on head `cd` (`:99`) and is dropped from `failing`; segment
`date > x.md` matches `FILE_REDIR` (`:226`) and is the only text scanned
(`:264-266`), and it contains no `docs/`-shaped token. `candidates` is
therefore empty, the fallback appends `DOCS` (`:268`), and that fallback
yields nothing at `:277-282` because `posixpath.normpath("docs/")` is
`"docs"`, whose `.find("docs/")` is `-1` — so `hits` is empty and `:284`
allows. At `c66aecc^` the whole-line scan collected `docs/issue-49`,
producing the hit `issue-49` and an R4 deny. The write reaches
`docs/issue-49/x.md` from a session branched `issue-3/qa`, which is
exactly what R4 exists to refuse.

**Timeline.** Introduced by `c66aecc` (2026-08-03 10:17:26 +0900); not
present at `c66aecc^`; still present on `main` as merged by PR #91 at
2026-08-03T01:21:15Z.

**Root cause.** Two things compose. First, the old whole-probe
`SUBSHELL`/`FILE_REDIR` test was doing double duty — it was a
classification test, but it also guaranteed that *every* `docs/` token on
a redirecting line got adjudicated, including tokens the segment scan
would never have reached. Moving it per-segment (`:226`) was the correct
fix for defect 1 and silently retired that second, undocumented effect.
Second, the `candidates.append(DOCS)` fallback at `:268` is annotated
"mentioned but unextractable: adjudicate" but has never adjudicated
anything: `DOCS` is `"docs/"` and the hit extraction at `:277-282`
normalizes the trailing slash away, so the branch always reaches `allow()`
instead. That dead branch existed unchanged at `c66aecc^` and was almost
never reached there; scoping the scan to failing segments makes "no
`docs/` token in scope" a common outcome, which promotes the dead branch
into a load-bearing path. Neither the proposal
(`…-scope-board-gate-candidates-and-port-approval-gate-fixes.md:107-113`)
nor the record (`docs/issue-90/reports/implementation.md:24-32`) mentions
the fallback, so the interaction was never in view.

**Action item (for the human to judge; this role files nothing).** Make
the `:268` fallback do what its comment claims — adjudicate rather than
allow — so that "a `docs/` path was mentioned and no candidate could be
extracted from the failing segments" fails closed. A candidate that
survives `:277-282` is what R1-R5 need; `DOCS` as written cannot survive
it. The observed role's own negative-space case
(`bash-unresolved-head-real-write`, `run-board-gate-tests.sh:273`) does
not cover this shape, because its write target carries a literal `docs/`
token inside the failing segment; a case shaped like
`cd docs/issue-49 && date > x.md` would.

### Finding 2 — the record's `code_sha` citations point at a commit that predates the code they describe

**Artifact:** `docs/issue-90/reports/implementation.md:5` and `:99-127`.

**Impact.** `code_under_review: d52d1e68…` and all five `closed_checks`
entries carry `code_sha: d52d1e68…`. `d52d1e6` is docs-only — 2 files,
both under `docs/issue-90/`, verified from its own `--stat`. None of the
test cases those checks cite (`bash-escaped-quote-then-write`,
`bash-unresolved-head-real-write`, `bash-cd-then-write-src`,
`bash-quoted-redirect-then-real-pipe`) exists at that sha; they first
exist at `c66aecc`. A reader auditing the closed checks at their stated
sha finds nothing to audit, which is the one thing a `code_sha` field is
for.

**Timeline.** Present in the record as committed in `c66aecc`; merged with
PR #91 at 2026-08-03T01:21:15Z.

**Root cause.** A structural bind, not carelessness: the record is
committed *in the same commit as the code it describes*, so the sha it
would want to cite does not exist when the file is written, and the
proposal sha is the only real one available. The repo's own prior records
sidestep this by not using a sha at all — `code_under_review` is a **file
list** at `docs/issue-88/reports/implementation.md:5` (blob at `33bcb20`)
and at `docs/issue-20/reports/implementation.md:4` (blob at `ea26ff2`).
Issue-90's record departs from that convention (and also uses
`kind: coding-record` where issue-88 uses `kind: implementation-record`),
which is what turned an unavoidable constraint into a false citation.

**Action item (for the human to judge; this role files nothing).** Either
restore the prior records' file-list form for `code_under_review` and drop
`code_sha` from `closed_checks`, or define the field as "the sha the
checks were run against, resolved post-merge" and have it written by the
merge rather than the author. The convention divergence between
`docs/issue-88/reports/implementation.md:2-5` and
`docs/issue-90/reports/implementation.md:2-5` is itself worth settling in
one place.

### Residuals — observed, not charged against `c66aecc`

Neither of the first two is a regression; both were already true at
`c66aecc^`, and both are recorded here only so the next pass on these
gates does not rediscover them.

- **board-gate's write-ish detection is still quote-blind**, even though
  its segment *splitting* is not. `FILE_REDIR`/`SUBSHELL` are applied to
  raw segment text at `core/hooks/board-gate.sh:226` (`c66aecc`), so
  `grep -n "A > B" docs/issue-49/reports/x.md` — a pure read — still
  classifies as a write candidate and still denies on R4, for exactly the
  reason issue #88 fixed for `|` in `SEGMENT` and `c66aecc` fixed for
  `>`/`|` in approval-gate's `WRITEISH`. After this "port", approval-gate
  is quote-aware about write-ish characters and board-gate is not. Issue
  #90's own background text warns that whitelist-shaped fixes leave the
  category cause standing; this is the piece of the category still
  standing.
- **The approval-gate harness's `run()` builds JSON by naive `printf`**
  (`run-approval-gate-tests.sh:97`, `c66aecc`). The observed role
  documented the hazard in the handbook rather than fixing the builder,
  which is a defensible scope call, but the next author who writes a
  `cmd=` containing a quote and forgets the manual escaping gets a
  silently vacuous `want deny` case — the same trap, one handbook
  paragraph away.
- Cosmetic, no action proposed: the case named
  `bash-single-quoted-pipe-grep` (`run-approval-gate-tests.sh:177`,
  `c66aecc`) exercises a single-quoted *redirect* (`'a > b'`), not a pipe.
  The case is correct; only its name is.

## Not applicable

Nothing in this observation was rendered "not applicable": all three
verdict levels apply and all three are answered above. Recording the
absence explicitly, per this role's phase-2 contract, rather than omitting
the heading.

## Next steps

Observation complete; `loop_state: landed`. This record is committed on
`issue-90/execution-observation` and carried by PR #92, which is this
role's sole phase-2 artifact. Findings 1 and 2 now wait on the human's
judgment on PR #92 — this role neither fixes them (it never edits the
observed artifact) nor files an issue for them (issues are user-authored
under contract v3). Issue #90's plan step 2 is thereby exhausted; the
human closes the issue, as they said they would at
https://github.com/tokenmaxxxer/tokenmaxxxer-core/issues/90#issuecomment-5161476238.

## Resolution path

Any finding raised against **this** record is resolved by amending this
file with a `resolved_findings:` entry referencing the finder's record,
per contract v3 s16, before any further commit on this branch. Findings 1
and 2, which this record raises against PR #91, are resolved outside it:
the human judges them on PR #92 and, if either is accepted, files the
issue themselves. This record edits nothing the observed role produced.
