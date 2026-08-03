---
kind: observation-record
subject: issue-99
produced_by: execution-observation
observed_role: implementation
observed_pr: 102
observed_commits: e163815, aa3f206, 232e2aa
observed_merge_commit: 27fd5fe
loop_state: landed
upstream:
  - path: docs/issue-99/proposals/2026-08-03-independent-observation-of-pr-102.md
    sha: c5ea7946969810404e4dc2b942974679e0b30c24
  - path: docs/issue-99/reports/execution-observation/survey.md
    sha: 5d48f8904d06abf2ebb65186280b3da48feb7fdd
  - path: docs/issue-99/reports/execution-observation/scout-brief.md
    sha: 67164b4471e7983b1313aa0009590bf30350349d
---

# Execution observation record — issue-99 / implementation (PR #102)

## Independence

This role did not author, edit, or in any way contribute to the artifact
it judges here. PR #102, its three commits (`e163815`, `aa3f206`,
`232e2aa`), the merge `27fd5fe`, and the observed role's own record
`docs/issue-99/reports/implementation.md` were all produced by a separate
session on the branch `issue-99/implementation`; this session's entire
write surface is `docs/issue-99/reports/execution-observation.md` and
`docs/issue-99/reports/execution-observation/`, plus its own proposal.
Nothing under `core/hooks/**`, `core/hooks/tests/**`, or
`docs/issue-99/reports/implementation*` was modified this session, and no
part of the observed task was re-executed: `run-board-gate-tests.sh` was
not run, and the live gate was not invoked to probe any command. Every
verdict below rests on a commit diff, a merged file, or a GitHub artifact
read this session, cited adjacent to the claim it supports.

No verdict language appears before this point in this document.

## Why

Issue #99's `## 실행 계획` step 2 is `execution-observation`: an
independent judgment of whether step 1's session — the `implementation`
role on branch `issue-99/implementation`, delivered as PR #102 and merged
as `27fd5fe` — executed soundly. Phase 2 of this role opened on the
issue-level comment whose entire body is the exact string
`APPROVE issue-99/execution-observation`, posted by `jjongkwann`, an
account listed in `docs/specs/approvers.md` (second entry), read this
session via `gh issue view 99 --comments`. That is contract v3 s19's
single-account path; PR #105 carries no PR-level review, so no other path
was available or used. The three check points this record must reach were
fixed before any evidence was weighed, in
`docs/issue-99/proposals/2026-08-03-independent-observation-of-pr-102.md`
(unreachable-branch trap, post-merge silent-allow recurrence, combination
with core issue-98's observation Finding 1), together with the two fact
discrepancies the phase-1 survey left open (U2, U3).

## What was done

Read, this session, as the evidence base — and nothing was re-executed:

- `gh issue view 99` (body, all five `## 요구사항`, `## 실행 계획`) and
  `gh issue view 99 --comments`; `gh pr list --state all`.
- `git show 232e2aa` for `core/hooks/board-gate.sh`,
  `core/hooks/tests/run-board-gate-tests.sh`,
  `docs/handbooks/board-gate-tests.md`, plus its full commit message and
  `--stat`.
- `git show e51bc09` for `core/hooks/board-gate.sh`,
  `core/hooks/gh-guard.sh`, `core/hooks/lib/gate-lib.py` — the
  neighbouring issue-98 change this record must combine with.
- `docs/issue-99/reports/implementation.md` (the observed role's own
  record) and
  `docs/issue-99/proposals/2026-08-03-fix-board-gate-dead-fallback-and-cd-write-verb-gap.md`.
- `docs/issue-98/reports/execution-observation.md` (Finding 1 and the
  closing observation) and
  `docs/issue-98/reports/execution-observation/survey.md` (U6) — the
  merged records carrying the only recorded live gate events.
- `git log --no-walk` author dates for the ten commits cited below, to
  separate pre-merge from post-merge events by timestamp.
- `git show 27fd5fe:core/hooks/board-gate.sh` limited to the
  `READ_ONLY_HEADS` tuple, to confirm one mechanism claim against the
  landed artifact rather than the working tree.

Deliberately **not** read as evidence: the working-tree state of
`core/hooks/**`, which shows what exists now rather than what the
observed session did. Deliberately **not** run: the board-gate test
suite, any gate, or any re-implementation of issue #99's fix.

Produced from that base: a three-level verdict (outcome, trajectory,
step), adjudications of the three named check points and of U2/U3, and
three findings in the four-part blameless shape — all below, each
verdict-bearing sentence carrying its citation adjacent to it.

## Verdict — outcome

**PR #102 landed what issue #99 asked, with one requirement met by
narrowing rather than as written.** Requirement by requirement:

- **Requirement 1 (fallback must adjudicate; no structurally
  unextractable candidate) — met in its second half, narrowed in its
  first.** The `candidates.append(DOCS)` literal is deleted from every
  code path (`232e2aa:core/hooks/board-gate.sh`, hunk replacing
  `if not candidates: candidates.append(DOCS)` with the in-order walk),
  and every candidate the builder can now append either already contains
  a `docs/` literal or is `DOCS + cd_tail` where `cd_tail` was itself
  produced by `_docs_relative_tail` returning a non-empty tail
  (`232e2aa:core/hooks/board-gate.sh`, `if tail: cd_tail = tail`) — so no
  reachable path re-creates the dead shape. The requirement's first half,
  however, states that "`docs/` path mentioned but no candidate
  extractable from the failing segment" must be **fail-closed**; the
  delivered code makes exactly that condition fail-**open** when `cd_tail`
  is unset (`232e2aa:core/hooks/board-gate.sh`, the `elif cd_tail:` arm
  with no `else`, followed by `if not hits: allow()`). That is not an
  oversight in substance — requirement 3's negative space
  (`bash-unresolved-head-then-read`, `date; grep -n foo docs/…`,
  `232e2aa:core/hooks/tests/run-board-gate-tests.sh:272`) demands that
  same condition allow, so requirements 1 and 3 are literally
  contradictory and the delivery picked the only resolution that
  satisfies 3. The deficiency is that the record never says so → Finding 2.
- **Requirement 2 (`cp`/`mv` gap) — met.** Closed by the same `cd_tail`
  mechanism and pinned by two cases in the same commit,
  `bash-cd-relative-cp-foreign` and `bash-cd-relative-mv-foreign`
  (`232e2aa:core/hooks/tests/run-board-gate-tests.sh`, both `run deny`).
  The mechanism does not depend on which argument is the write target, so
  it generalizes past the two verbs the issue named — the record's own
  reasoning at `docs/issue-99/reports/implementation.md:130-134` matches
  the diff.
- **Requirement 3 (regression cases pre-change-failing; negative space
  held) — met, with a count discrepancy in the commit message.** Four new
  `deny` cases and one new `allow` case were added
  (`232e2aa:core/hooks/tests/run-board-gate-tests.sh`, five `run` lines);
  the record states the four `deny` cases produced exactly four FAILs
  against the stashed pre-fix code and that the `allow` case already
  passed pre-fix (`docs/issue-99/reports/implementation.md:151-162`). The
  commit message says "5 new regression cases confirmed failing"
  (`232e2aa` message body) → Finding 3.
- **Requirement 4 (no branch whose reachability is unproven) — met for
  every branch that can change a verdict.** See the branch enumeration
  under check point 1 below.
- **Requirement 5 (handbook updated in the same commit) — met.**
  `docs/handbooks/board-gate-tests.md` is +54 lines in `232e2aa` itself
  (`git show --stat 232e2aa`), and its new section documents the dead
  fallback, the `cd_tail` mechanism, and the accepted over-blocking
  trade-off (`232e2aa:docs/handbooks/board-gate-tests.md`, section
  beginning "Also covers issue-99's dead empty-candidates fallback").

## Verdict — trajectory

**Sound.** The phase-1→phase-2 path holds at every checkpoint the
contract sets:

- **Scouted and surveyed before proposing.** `e163815` is a phase-1-only
  commit — survey, scout brief, and proposal, three files, no code
  (`git show --stat e163815`, dated 2026-08-03 15:40:15 +0900) — and the
  code commit `232e2aa` (17:11:47) comes 91 minutes later. Phase-1
  material was not back-filled after the code.
- **Approval was real and correctly typed.** The record cites the
  issue-level comment `APPROVE issue-99/implementation` at
  `.../issues/99#issuecomment-5163202866`
  (`docs/issue-99/reports/implementation.md:16-18`); PR #102 carries no
  review, so the single-account path was the applicable one and was the
  one used. Verified independently this session: `gh issue view 99
  --comments` returns that comment body verbatim from `jjongkwann`.
- **Main was merged before phase-2 work, not after.** `aa3f206`
  (17:01:10) merges `origin/main` into the branch and precedes `232e2aa`
  (17:11:47), so the delivery was written against the post-issue-98 tree
  rather than rebased onto it afterwards.
- **The one trajectory weakness is the seam this created.** `aa3f206`
  landed 2 minutes 34 seconds after `9cd8a20` merged issue-98's
  `TRANSPARENT` change to `main` (16:58:36), and nothing in the observed
  session's record re-examines the merged-in change against the walk it
  was about to write (`docs/issue-99/reports/implementation.md:99-106`
  records only that no new design choice was made). That is the root
  cause of Finding 1 and is charged there, not twice.

## Verdict — step

Three artifacts are deficient; each is charged once, below, in the
four-part blameless shape. The delivered code is correct for every case
its own tests cover, and the negative space issue-90 established survives
(`232e2aa:core/hooks/tests/run-board-gate-tests.sh:272`, unchanged). No
deficiency is charged against the handbook entry, the proposal, or the
approval path.

---

## Check point 1 — did the landing code avoid the unreachable-branch trap?

**It did, for every branch that can change a verdict; one inert branch is
unpinned.** Issue #99 requirement 4 forbids shipping a branch whose
reachability is not empirically shown, after the local experiment's
C1-F1 trap (a rescan branch whose regex literal equalled its own entry
condition). Enumerating every branch `232e2aa` adds to the `Bash`
candidate builder (`232e2aa:core/hooks/board-gate.sh`), and naming the
case **in the same commit** that enters each:

| branch | entered by |
| --- | --- |
| `if not any(failing …): allow()` | pre-existing read-only lines, e.g. the issue-90 cases retained in `run-board-gate-tests.sh` |
| `if own_hits: candidates.extend(own_hits)` | `bash-unresolved-head-real-write` (`date > docs/issue-49/reports/x.md`), `232e2aa:…run-board-gate-tests.sh:274` |
| `elif cd_tail: candidates.append(DOCS + cd_tail)` | all four new `deny` cases and the new `allow` case |
| neither arm (failing segment, no own token, no `cd_tail`) | `bash-unresolved-head-then-read` (`date; grep -n foo docs/…`), `232e2aa:…run-board-gate-tests.sh:272` — the record's claim at `docs/issue-99/reports/implementation.md:144-147` checks out against the diff |
| `if tail: cd_tail = tail` (taken) | `bash-cd-relative-redirect-foreign`, `cd docs/issue-49` |
| `if tail:` **not** taken (a `cd` to a non-`docs/` target) | `bash-cd-out-then-write-elsewhere`, whose `cd /tmp` segment sets no tail |
| `_cd_target` returning `""` | **no case in the commit** |

The last row is the only gap, and it is inert: `_cd_target` returns `""`
only for a bare `cd` or a flags-only `cd`
(`232e2aa:core/hooks/board-gate.sh`, `for w in stripped.split()[1:]`
falling through to `return ""`), after which `if target:` skips the
assignment and `cd_tail` keeps its prior value — the same outcome as not
having walked the segment at all. It is structurally reachable (`cd;
grep foo docs/x` satisfies the outer `if DOCS in cmdline` guard), unlike
the C1-F1 branch the issue warns about, which could not be reached by any
input. So requirement 4's actual prohibition — shipping a branch that
*cannot* be reached — is honoured; what is missing is a pin on a branch
that can be reached but cannot change a verdict. Recorded, not charged.

Method note: this enumeration is from the diff hunks and the test hunk of
the same commit only. No suite was re-run, per the scout brief's must-be
that a reachability claim carry an inspectable path rather than a tool's
verdict (`docs/issue-99/reports/execution-observation/scout-brief.md`,
"Category must-bes", first bullet).

## Check point 2 — did the silent-allow failure mode recur after the merge?

**No recurrence is recorded, and the only post-merge live gate event on
the board runs in the opposite direction.** Two live gate events exist in
merged records, and they separate cleanly by timestamp:

1. The U6 addendum at
   `docs/issue-98/reports/execution-observation/survey.md:148-159`
   describes a refusal met while committing that session's phase-1 files
   — the commit that became `850a99c`, authored 17:07:51, i.e. **11
   minutes 9 seconds before** `27fd5fe` merged at 17:19:00. The addendum
   recording it (`e062d4a`, 17:23:53) is post-merge but the event it
   describes is not, so it says nothing about the issue-99 gate.
2. The closing observation at
   `docs/issue-98/reports/execution-observation.md:534-540` (committed at
   `99d94aa`, 17:32:12, after the merge) describes a second refusal and
   labels it itself: "This is the current `main` gate (post-issue-99)". It
   is a **refusal** — a foreign record's path appearing as an argument to
   `git show <sha>:<path>` while the redirect went to `$TMPDIR` — i.e. a
   fail-closed false positive of the path-token class issue-94 already
   recorded, not a silent allow.

A search of every record merged to `main` after `27fd5fe` for a recorded
silent allow returns nothing. What that absence can support: no session
has yet reported the issue-99 failure mode recurring. What it cannot
support: it is not evidence that the mode is closed. Exactly one PR
(#104, merged `428ebe7` at 19:56:12) landed sessions in the window, the
board carries no runtime log or gate-event artifact directory, and gate
events are recorded only when a role happens to narrate one — so the
sample is one session's incidental notes, and a silent allow is by
construction the event least likely to be noticed and written down.
Finding 1 below identifies a live instance of the mode by static
inspection, which is why the absence of a recorded one is not treated as
reassurance here.

One further data point from this session, offered as context and charged
against nothing: a `git log` invocation in this session was refused by a
hook with `Contains for_statement`. That is a different gate from
`board-gate.sh` and concerns shell form, not board writes; it is noted
only because it is a live post-merge event and it too runs in the
refusal direction.

## Check point 3 — combination with core issue-98's observation Finding 1

**The combination is unexercised, and it re-opens the exact silent-allow
class issue #99 exists to close.** This is Finding 1.

Issue-98's observation Finding 1
(`docs/issue-98/reports/execution-observation.md:388-432`) reports that
`e51bc09` extended `TRANSPARENT` to include `timeout` and `nohup` while
both the proposal and the record stated no board-gate behaviour change.
The two diffs show the mechanism by which that change and `232e2aa` meet:

- `e51bc09:core/hooks/lib/gate-lib.py` defines
  `TRANSPARENT = ("xargs", "env", "time", "nice", "command", "builtin",
  "timeout", "nohup")` and `TRANSPARENT_TAKES_ARG = ("timeout",)`, and
  `_resolve_transparent` walks a segment's words through them, skipping
  one extra bare positional word for `timeout`, so
  `gate_head_of("timeout 30 cd docs/issue-49")` resolves to `"cd"`. The
  same commit deletes board-gate's own `_head_of`
  (`e51bc09:core/hooks/board-gate.sh`, removing
  `TRANSPARENT = ("xargs", "env", "time", "nice", "command", "builtin")`
  and the function under it) and repoints the classifier at
  `gate_lib.gate_head_of`.
- `232e2aa:core/hooks/board-gate.sh` builds its `cd`-tracking walk on
  that resolver — `if gate_lib.gate_head_of(stripped) == "cd"` — but
  extracts the `cd` target with `_cd_target(stripped)`, which iterates
  `stripped.split()[1:]` and returns the first non-flag word. That is
  index-based: it assumes the head sits at word 0 and that its argument
  is the first non-flag word after it.
- `cd` is in `READ_ONLY_HEADS`
  (`27fd5fe:core/hooks/board-gate.sh:103`), so a wrapper-prefixed `cd`
  segment is classified not-failing and enters the tracking arm.

Composed, for `timeout 30 cd docs/issue-49 && date > x.md`: segment one
is not failing, `gate_head_of` says `"cd"`, and `_cd_target` returns
`"30"` — the wrapper's duration argument, not the path — so
`_docs_relative_tail("30")` is `""` and `cd_tail` is never set
(`232e2aa:core/hooks/board-gate.sh`, `if target:` / `if tail:`). Segment
two is failing on `FILE_REDIR`, carries no `docs/` token of its own, and
with `cd_tail` empty falls through both arms contributing nothing, so
`candidates` is empty, `hits` is empty, and control reaches
`if not hits: allow()` — an allow with no adjudication, on a command
whose write lands in another role's issue tree. `nohup cd docs/issue-49
&& date > x.md` reaches the same end by the same route
(`_cd_target` returns `"cd"`).

Direction and scope, stated precisely:

- Nothing here is a **regression** introduced by `232e2aa`. On the
  pre-`232e2aa` code the wrapped form reached the dead
  `candidates.append(DOCS)` fallback and allowed for that reason instead
  (`e51bc09:core/hooks/board-gate.sh`, `if not candidates:` arm). The fix
  closed the bare form and left the wrapped form open.
- `e51bc09` did not **create** the seam either. Six wrappers — `xargs`,
  `env`, `time`, `nice`, `command`, `builtin` — were already in
  board-gate's own `TRANSPARENT` before it (`e51bc09` deletes exactly
  that tuple), so `command cd docs/issue-49 && date > x.md` takes the
  same route. What `e51bc09` did was widen the wrapper set from six to
  eight, and `timeout`'s extra bare positional argument makes the misread
  token especially unlikely to be path-shaped.
- The seam belongs to `232e2aa`: it adopted `gate_head_of` for head
  detection and hand-rolled argument extraction beside it, so the two
  disagree about where the command starts.
- No case in `232e2aa:core/hooks/tests/run-board-gate-tests.sh` composes
  a wrapper with a `cd`; all five new cases use a bare `cd`. The
  composition is unexercised in either direction.

Charged as Finding 1 against `232e2aa`, not against `e51bc09` — issue-98's
own observation already put the `TRANSPARENT` extension in front of the
human on PR #104, and this record does not re-charge it.

## U2 — record versus commit message on the regression count

**Adjudicated: the record is right and the commit message overstates by
one.** The commit message of `232e2aa` says "5 new regression cases
confirmed failing (want=deny got=allow) against the pre-fix code". The
diff adds five `run` lines, of which four are `run deny` and one —
`bash-cd-relative-write-own-issue` — is `run allow`
(`232e2aa:core/hooks/tests/run-board-gate-tests.sh`). A `run allow` case
cannot produce `want=deny got=allow`, and the record says as much
without prompting: "exactly 4 FAILs … (80 passed, 4 failed);
`bash-cd-relative-write-own-issue` passed even pre-fix (the dead
fallback's own accidental allow)"
(`docs/issue-99/reports/implementation.md:151-162`). The record is
internally consistent and matches the diff; the commit message does not.
Charged as Finding 3.

## U3 — proposal-to-delivery count drift

**Adjudicated: reconciled, no deficiency.** The proposal predicted "the
full suite still at 71+6 passed"
(`docs/issue-99/proposals/2026-08-03-fix-board-gate-dead-fallback-and-cd-write-verb-gap.md:185`)
and the record reports 79 pre-existing + 5 new = 84
(`docs/issue-99/reports/implementation.md:163-167`). Both numbers move
for reasons visible in the artifacts, and neither indicates a missing or
dropped case:

- The baseline moved 71 → 79 because `aa3f206` merged `main` at 17:01:10,
  after `9cd8a20` (16:58:36) landed issue-98's own new cases —
  `e51bc09`'s commit message states "run-board-gate-tests.sh (79 passed,
  0 failed)" for the post-issue-98 tree, which is precisely the baseline
  the record used. The proposal's 71 was written at 15:40:15
  (`e163815`), before issue-98 merged, so it was correct when written and
  stale by delivery.
- The new-case count moved 6 → 5 because the proposal's list of six `run`
  lines includes one marked "stays exactly as issue-90 left it (no
  change)" — `bash-unresolved-head-then-read`
  (`…-cd-write-verb-gap.md:149`). Five of the six are genuinely new, and
  five is what the diff adds.

79 + 5 = 84, which is what the record reports and what `232e2aa`'s commit
message reports for the post-fix suite. The drift is a stale prediction
reconciling exactly, not a discrepancy. Worth noting only that the same
off-by-one — counting the no-change line as if it were new — is the most
plausible origin of Finding 3's "5 … confirmed failing".

---

## Open findings

### Finding 1 — a wrapper-prefixed `cd` defeats the new tracker, restoring the unadjudicated allow issue #99 was filed to close

- **Impact.** `timeout 30 cd docs/issue-49 && date > x.md` reaches
  `allow()` with no adjudication on the merged gate: `gate_head_of`
  identifies the segment as a `cd`
  (`e51bc09:core/hooks/lib/gate-lib.py`, `TRANSPARENT` including
  `"timeout"` plus `TRANSPARENT_TAKES_ARG = ("timeout",)`), but
  `_cd_target` reads word 1 of the raw segment and returns `"30"`
  (`232e2aa:core/hooks/board-gate.sh`, `for w in stripped.split()[1:]`),
  so `cd_tail` is never set and the write segment — no `docs/` token of
  its own — contributes no candidate, ending at `if not hits: allow()`.
  The same holds for `nohup`, and for the six wrappers that predate
  issue-98 (`command`, `env`, `xargs`, `time`, `nice`, `builtin`). This is
  the same failure class the issue names — a write into a foreign issue
  tree reaching allow with no rule ever applied — reachable by one extra
  word. It is not a regression: the bare form is now correctly denied
  (`232e2aa:core/hooks/tests/run-board-gate-tests.sh`,
  `bash-cd-relative-redirect-foreign`), and the wrapped form allowed
  before this fix too, via the dead fallback.
- **Timeline.** `e51bc09` (16:38:40) moves `TRANSPARENT` into `gate-lib`
  and adds `timeout`/`nohup`; `9cd8a20` merges it at 16:58:36; `aa3f206`
  pulls it into the observed branch at 17:01:10, 2m34s later; `232e2aa`
  (17:11:47) writes the `cd` walk on top of the merged resolver;
  `27fd5fe` merges at 17:19:00. Issue-98's own observation flagged the
  `TRANSPARENT` extension as an undeclared board-gate behaviour change at
  `99d94aa` (17:32:12), 13 minutes after the merge — after this
  composition had already landed.
- **Root cause.** The delivery correctly reused the shared classifier for
  *head detection* — `_segment_is_failing` and the walk both call
  `gate_lib.gate_head_of` — and then hand-rolled the *argument*
  extraction next to it on an index assumption (`split()[1:]`) that the
  resolver had already invalidated. The two halves of one question ("is
  this a `cd`?" / "what is it `cd`-ing to?") were answered by different
  models of where a command begins. The seam was invisible to review
  because both changes are locally correct and `git` reports no conflict
  between them; the surrounding docstring even cites `_git_subcommand` as
  the idiom being reused, and that function shares the same index
  assumption, so the inconsistency reads as consistency.
- **Action item (for the human to judge, not for this role to do).**
  Decide whether the wrapper-prefixed form must be adjudicated. If yes,
  the smallest fix consistent with this delivery's own reuse principle is
  to extract the `cd` argument from the resolver's own trailing words
  rather than from `split()[1:]` — `e51bc09:core/hooks/lib/gate-lib.py`'s
  `_resolve_transparent` already returns `(head, trailing_words)` and
  `gate_head_of` discards the second element — and to pin it with a
  `run deny` case of the shape `timeout 30 cd docs/issue-49 && date >
  x.md`. If no, the acceptance belongs in
  `docs/handbooks/board-gate-tests.md` beside the over-blocking trade-off
  already recorded there, so the next reader does not rediscover it.

### Finding 2 — the record's requirement-1 argument answers half the requirement without saying so

- **Impact.** A reader auditing issue #99 requirement 1 from the record
  is told the requirement is met
  (`docs/issue-99/reports/implementation.md:120-129`: "the `DOCS`
  literal candidate is gone from every code path … no reachable path
  re-creates the old dead shape"). That answers the requirement's second
  clause — no candidate that structurally cannot pass hit-extraction —
  and is true against the diff. The first clause asks that "`docs/` path
  mentioned but no candidate extractable from the failing segment" be
  **fail-closed**, and the delivered code allows that case whenever
  `cd_tail` is unset (`232e2aa:core/hooks/board-gate.sh`, the `elif
  cd_tail:` arm with no `else`). The reader cannot tell from the record
  that a clause was traded away, or why. The substantive decision is
  correct — requirement 3's preserved negative space
  (`232e2aa:core/hooks/tests/run-board-gate-tests.sh:272`) requires that
  exact case to allow, so requirements 1 and 3 contradict each other and
  only one resolution satisfies both tests — which is what makes the
  silence costly rather than harmless: the contradiction is the single
  most useful thing this delivery learned, and it is recorded nowhere a
  future reader will look. Finding 1 is a live instance of the residue
  that trade-off leaves.
- **Timeline.** The trade-off is reasoned about in the code comment at
  `232e2aa:core/hooks/board-gate.sh` ("a failing segment with no `docs/`
  token of its own and no preceding `docs/`-landing cd contributes
  nothing, which is exactly issue-90's own preserved negative space") and
  in `232e2aa:docs/handbooks/board-gate-tests.md`, both written in the
  same commit as the record — so the reasoning existed and simply did not
  reach the requirement-1 argument.
- **Root cause.** The `## Hunt` section adopts a `contract-literalist`
  stance, "re-reading the issue's own four requirements line by line
  against the actual diff"
  (`docs/issue-99/reports/implementation.md:112-119`). Applied to a
  requirement with two clauses, the pass matched the clause the diff
  visibly satisfies and did not test the other against the same diff; a
  literalist read has no step at which two requirements are checked
  *against each other*, which is exactly where this contradiction lives.
  The stance also explains why the count in Finding 3 survived: it checks
  the diff against the issue, never the commit message against the record.
- **Action item (for the human to judge).** If the residue is accepted,
  one sentence in the requirement-1 argument naming the contradiction and
  its resolution is enough; the code comment already contains the
  wording. If it is not accepted, the decision belongs with Finding 1,
  since they share a mechanism.

### Finding 3 — the commit message claims five pre-change-failing cases where four failed

- **Impact.** `232e2aa`'s message states "5 new regression cases
  confirmed failing (want=deny got=allow) against the pre-fix code". Four
  did; the fifth new case is `run allow
  bash-cd-relative-write-own-issue`
  (`232e2aa:core/hooks/tests/run-board-gate-tests.sh`), which cannot
  produce `want=deny got=allow` and which the record explicitly reports
  as passing pre-fix
  (`docs/issue-99/reports/implementation.md:151-162`). Issue #99
  requirement 3 is precisely the "confirmed failing before the change"
  property, so the overstated number sits on the one claim the
  requirement asks to be evidenced, in the artifact — the commit message
  — that outlives the branch and is read without the record beside it.
  The record itself is accurate and self-correcting, which bounds the
  impact to a reader who stops at `git log`.
- **Timeline.** Written at `232e2aa` (17:11:47), merged at `27fd5fe`
  (17:19:00); a commit message cannot be amended after merge without a
  rewrite, so unlike Findings 1 and 2 this one is not repairable in
  place — only annotatable.
- **Root cause.** The delivery counted "new cases" (five) and
  "pre-change-failing cases" (four) as one number. The proposal's own
  plan listed six `run` lines of which one was marked no-change
  (`…-cd-write-verb-gap.md:145-150`), so an off-by-one between "lines
  listed", "cases added", and "cases that failed pre-fix" was available
  throughout, and the record resolved it correctly while the message did
  not. This is the second consecutive recurrence of the class issue-98's
  observation charged as its Finding 2 — "a claim's headline number
  exceeds what its own evidence shows"
  (`docs/issue-98/reports/execution-observation.md:441-449`) — which is
  the part worth the human's attention, more than this instance's own
  cost.
- **Action item (for the human to judge).** Nothing is repairable in the
  merged message. If the recurrence is judged to matter, the durable fix
  is a convention — a headline count in a commit message states what its
  own `closed_checks` result states, verbatim — rather than a correction
  to this commit.

## What is not deficient

- The delivered mechanism against the cases it covers: all four foreign
  `deny` cases and the own-issue `allow` case follow from the diff as
  written (`232e2aa:core/hooks/board-gate.sh` walk +
  `232e2aa:core/hooks/tests/run-board-gate-tests.sh`), and the deliberate
  over-blocking of `cd docs/issue-49 && cd /tmp && date > y.md` is pinned
  as a verdict rather than left implicit.
- Issue-90's negative space, unchanged and still passing by construction
  of the "no token, no `cd_tail`" fall-through
  (`232e2aa:core/hooks/tests/run-board-gate-tests.sh:272`).
- The `_segment_is_failing` extraction, which is behaviour-preserving
  line for line against the code it replaces (`232e2aa`, the two hunks
  are a move plus an inversion of the `continue` polarity, with the
  `awk`/`sed` clauses from `e51bc09` carried across verbatim).
- The R5 residual the record carries as "confirmed still present by
  construction … not re-verified live"
  (`docs/issue-99/reports/implementation.md:177-189`). Judged adequate:
  the mechanism named — `DOCS + cd_tail` never carrying the write-target
  filename — is visible in the diff and is the same fact a live probe
  would establish, and the proposal named the gap out of scope with
  reasoning before approval
  (`…-cd-write-verb-gap.md`, `## Out of scope`, first bullet). "By
  construction" is the right standard when the construction is
  inspectable, which here it is.
- The approval path, the phase ordering, and the handbook update, all
  addressed under the trajectory and outcome verdicts above.

## Next steps

None for this role. The three findings stand in this record on PR #105
for the human to judge; this role files no issue, opens no follow-up, and
does not touch the observed role's artifacts. Finding 1 is the one with a
live behavioural consequence and is the one to read first.

## Resolution path

Each finding is resolved by the human judging it on PR #105 and, if
valid, authoring the issue themselves (contract v3: issues are
user-authored only). A finding the human rejects needs no artifact
change. If a finding is accepted and fixed by a later role, that role's
own record cites this record's finding number; this file is not amended
by another role.

## What did not work

Two frictions, recorded for the board rather than charged against
anything. First, a `git log --format=…` invocation using a shell `for`
loop was refused this session by a hook with `Contains for_statement`;
re-expressed as `git log --no-walk <sha> <sha> …` it ran, so the refusal
cost one round trip and no evidence. Second, the observation of a seam
between two independently-correct commits has no artifact to sit in:
`git` reports no conflict, both PRs are green, and the composition is
visible only by reading two diffs against each other with the merge
timestamps in hand — which is what made Finding 1 findable here and
invisible in either session that produced it.
