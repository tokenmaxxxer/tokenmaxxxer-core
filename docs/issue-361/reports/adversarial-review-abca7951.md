---
issue: 361
role: adversarial-review-abca7951
author: adversarial-review-abca7951
skills: adversarial-review (skill-repository(c05de12))
verifies_subject: true  # independent round-3 verification of PR #374's deliverable
loop_state: landed
upstream:
  - path: core/hooks/board-gate.sh
    sha: c9f1c4ce455a13e7285e3c2b9f0a22b6f76974b9
  - path: core/hooks/tests/run-board-gate-tests.sh
    sha: c9f1c4ce455a13e7285e3c2b9f0a22b6f76974b9
  - path: docs/handbooks/board-gate-tests.md
    sha: c9f1c4ce455a13e7285e3c2b9f0a22b6f76974b9
  - path: docs/issue-361/reports/secure-coding-input-validation-injection-defense-a072264b.md
    sha: c9f1c4ce455a13e7285e3c2b9f0a22b6f76974b9
---

# issue-361 — adversarial-review-abca7951 record

## What was done

Independent round-3 verification of PR #374 as it stands after round 2
(head `c9f1c4c`, `issue-361/secure-coding-input-validation-injection-defense-a072264b`).
Round 1 (PR #377) found the shell-scan soundness claim false. Round 2
(commit `64a58fa`) was scoped to replacing that claim with an accurate one,
prose only. This round re-derives both things the task named as at risk —
that the replacement claim is actually true everywhere, and that the
detection logic underneath it truly did not move — plus re-runs every
check round 1 established, since those claims travel with the branch and
the branch has since merged `origin/main` (picking up PR #367). All of the
below was re-derived live against fresh worktrees of `origin/main` and the
PR head, or against a live `gh pr view`/`gh pr diff` fetch; the builder's
own record (`...a072264b.md`) and PR #377/#374's prior records were read
only to locate what to re-check, not restated as fact.

**Verdict: BLOCKING. Round 2 fixed the false soundness claim in exactly
one place — the inline comment in `core/hooks/board-gate.sh` — and left it
standing, verbatim, unfixed, in two other branch surfaces that describe
the identical scan: the PR's own live description, and the PR's own
delivery record file. A reviewer who reads the PR body or the record
instead of the diff still meets the disproven claim.**

1. **Claim-truth: fixed in the code comment, not fixed in the PR body or
   the record file it shipped — CONFIRMED, this is the "second thing that
   fails quietly."**

   The code comment (`core/hooks/board-gate.sh`, current head, lines
   ~92-97) now reads:
   ```
   # This scan is a proxy, not a soundness guarantee: it catches the
   # shape only when the head and flag are spelled literally in the
   # command text. A head assembled through bash's expansion grammar
   # defeats it the same way runtime assembly defeats the path scan
   # above. A variable holding a printf-octal-decoded interpreter name is
   # one confirmed shape (issue-361 PR #377). Nothing in this gate
   # catches an expansion-built head.
   ```
   This is accurate and matches actual behavior (falsified below, item 5).
   `docs/handbooks/board-gate-tests.md` (lines 727-745, current head)
   carries the same corrected framing — but that text arrived via the
   separately-reviewed merge of PR #367 (commit `b6cb34a`), not via
   round 2's own commit.

   Round 2's own commit, `64a58fa`, touched only
   `core/hooks/board-gate.sh`:
   `derived: git show 64a58fa --stat -- core/hooks/board-gate.sh` — 1 file
   changed, 24 insertions, 14 deletions, all inside the comment block
   (confirmed non-comment-line-empty below, item 2). It did not touch the
   PR body or the added record file. Checking both of those directly:

   PR body, fetched live just now (not cached from an earlier round):
   `derived: gh pr view 374 --repo tokenmaxxxer/tokenmaxxxer-core --json body -q .body`
   ```
   ...unlike a write *target*, an interpreter head and its `-c`/`-e` flag
   have to be spelled literally in the text for the shell to actually
   invoke them, so this scan is a sound, deliberately over-inclusive
   proxy (a false positive costs one extra python3 call, never a missed
   analysis)....
   ```
   This is the exact "sound... proxy" wording PR #377 disproved. It has
   not been edited since round 1 — `gh pr view` reflects the PR's current
   live description, and this is what it says right now.

   The record file the PR itself ships,
   `docs/issue-361/reports/secure-coding-input-validation-injection-defense-a072264b.md`,
   added by the PR's first commit (`e1dcbb0`) and never touched again
   (`derived: git log --oneline e1dcbb0..c9f1c4c -- docs/issue-361/reports/secure-coding-input-validation-injection-defense-a072264b.md`
   — empty output, zero commits touched it after the initial add):
   `derived: git show c9f1c4c:docs/issue-361/reports/secure-coding-input-validation-injection-defense-a072264b.md | sed -n '105,116p'`
   ```
   about. Both are true of a *target path* scan. They are not true
   of a *shape* scan: the interpreter head and its `-c`/`-e` flag have to be
   spelled literally in the command text for the shell to actually invoke
   them (unlike a target path, which a script can compute and never write
   down), so a raw-text scan for that already-existing, already-reasoned-
   about closed set (`INTERPRETER_HEADS`/`INLINE_FLAG_WORDS`/
   `WRITE_UNSAFE_HEADS`) is a sound, deliberately over-inclusive proxy — a
   false positive there costs one extra python3 call, never a missed
   analysis.
   ```
   Same disproven claim, verbatim. "Read every place the branch describes
   what the scan does" surfaces three such places; only one was fixed.
   A replacement claim confined to the file a reviewer is least likely to
   read as the PR's headline (an inline comment, versus the PR description
   and the PR's own record) is not the fix the round was scoped to
   deliver.

2. **Detection logic truly did not change in round 2's own commit —
   CONFIRMED, isolated from the PR #367 merge.**

   The branch's overall diff against `origin/main` is not the right
   window to check this in, because the branch merged `origin/main` mid-PR
   to pick up PR #367 (commit `b6cb34a`, already independently verified
   across rounds 5-8 of issue-233) — that merge legitimately changed
   `INLINE_FLAG_WORDS`→`INLINE_FLAG_HEADS` and split `VAR_INTERP_RE`, and
   attributing those changes to this round would be wrong. Isolating round
   2's own commit instead:
   `derived: git show 64a58fa -- core/hooks/board-gate.sh | grep -E '^[+-]' | grep -v '^[+-]#' | grep -v '^+++' | grep -v '^---'`
   — **zero lines of output.** Every `+`/`-` line in commit `64a58fa` that
   is not a comment line is filtered out by this command and none remain:
   the commit is comment-only, matching its own commit message ("No scan
   logic changes -- comment text only").

   Named constants checked for byte-identity across `e1dcbb0` (pre-round-2)
   and `c9f1c4c` (current head):
   `derived: diff <(git show e1dcbb0:core/hooks/board-gate.sh | grep "^UNANALYZABLE_") <(git show c9f1c4c:core/hooks/board-gate.sh | grep "^UNANALYZABLE_")`
   — empty diff. `UNANALYZABLE_HEAD_RE`, `UNANALYZABLE_FLAG_RE`, and
   `UNANALYZABLE_WRITE_HEAD_RE` are byte-identical strings at both
   revisions, and `INTERPRETER_HEADS` is likewise unchanged
   (`("python3","python","python2","bash","sh","zsh","perl","ruby","node","nodejs")`
   at both). `INLINE_FLAG_WORDS`/`INLINE_FLAG_HEADS` and `VAR_INTERP_RE`
   did change between `e1dcbb0` and `c9f1c4c`, but that change is entirely
   attributable to the `b6cb34a` merge (PR #367), not to round 2's own
   `64a58fa` commit, per the isolated diff above. A comment-only commit
   cannot change runtime behavior at all — this makes the round-1 fast-path
   and catch/miss findings below trivially still valid for anything that
   only depends on code, not comments.

3. **Round-1 established checks — still hold on the current head.**

   `chr()`-assembled-path reproduction from PR #360/#377's record (decodes
   to `docs/issue-3/reports/pwned.md`):
   `derived: python3 -c "import pathlib;pathlib.Path(bytes([100,111,99,115,47,105,115,115,117,101,45,51,47,114,101,112,111,114,116,115,47,112,119,110,101,100,46,109,100]).decode()).write_text(chr(120))"` run through the hook —
   `origin/main: RC=0 GOT=allow`; `PR #374 head c9f1c4c: RC=2 GOT=deny`
   (stderr cites issue-225's unanalyzable-write-shape deny). Still caught.

   Literal `python3 -c` with a runtime-computed write target
   (`open(__import__('os').environ.get('X', ...), 'w').write('z')`, target
   supplied via an env var never appearing in the command text):
   `origin/main: RC=0 GOT=allow`; `PR #374 head: RC=2 GOT=deny` — still
   caught, because the command text still spells `python3`/`-c` literally
   regardless of where the write target comes from.

   Fast path still short-circuits ordinary commands:
   `derived: bash -x core/hooks/board-gate.sh` (PR head) traced for
   `git status`, `ls -la`, `echo hi`, grepped for the `python3 -c
   "$CORE_BOARD_GATE"` judge-invocation line — **0 matches for all three**,
   confirming the shell fast path exits before the python judge starts.

   Overhead: round 2's commit is comment-only (item 2), so it cannot have
   moved runtime cost from what rounds 1/#377 already measured
   (interleaved N=200-300, 3 trials: +0.5-0.9ms/call fast path,
   ~30ms/call for removing the pre-check entirely). A single non-interleaved
   N=50 trial run this round (`git status` fast path: main 27.25ms/call vs
   head 26.04ms/call; full-analysis path: main 47.14ms/call vs head
   49.08ms/call) is noisier than that methodology and does not cleanly
   reproduce the exact delta in the same direction either way — expected,
   since a single non-interleaved N=50 trial is far noisier than an
   interleaved N=200-300 one, and not informative on its own. The stronger
   evidence is the code diff itself: comment-only means zero possible
   runtime delta from this round, full stop. The previously-established
   +0.5-0.9ms / ~30ms numbers stand unchanged because nothing that could
   affect them changed.

4. **#367 consistency — the two jurisdiction texts agree.**

   PR #367's jurisdiction wording, landed as the header comment in
   `core/hooks/board-gate.sh` (lines 33-45, current head): "...A command
   built to deliberately hide its own write target from this pre-expansion
   text read (bash's expansion grammar can rewrite a word into anything)
   is outside what this gate claims to bound... The threat model this gate
   holds is a cooperative session drifting out of its lane, not an
   adversary routing around it." Round 2's own prose (item 1 above): "A
   head assembled through bash's expansion grammar defeats it the same
   way runtime assembly defeats the path scan above... Nothing in this
   gate catches an expansion-built head." Both texts place the
   expansion-class gap outside the gate's claimed jurisdiction and neither
   contradicts the other — round 2's prose does not undercut #367's
   wording. (Side note, not a #374 defect: PR #378, open at time of check,
   proposes widening #367's wording further to name the head side
   explicitly, on the operator's own view that the flag-only phrasing
   "reads as though only the flag side is out of scope" — that is
   #367/#378's own wording question, not something #374 introduces or
   contradicts.)

5. **Falsifying the round-2 claim itself, per the task's own test.**

   (a) A literal, real interpreter head/flag the enumerated regex does not
   cover: `php -r "file_put_contents(...)"` — `php` is not in
   `UNANALYZABLE_HEAD_RE`'s list, `-r` is not in `UNANALYZABLE_FLAG_RE`.
   `origin/main: RC=0 GOT=allow`; `PR #374 head: RC=0 GOT=allow` — passes
   through undenied on both. This does **not** falsify the round-2
   sentence itself: "catches the shape only when spelled literally" is a
   necessary-condition claim (literal spelling is required to be caught),
   not a claim that all literal spellings are caught — the sentence never
   promises enumeration completeness. Reporting it as a real, pre-existing
   scope boundary of a closed-vocabulary approach (present before and
   after round 2, unaffected by round 2's comment-only change, not a
   regression) rather than a false claim.

   (b) A shell-expansion-produced interpreter head: `$(echo python3) -c
   "..."` (same `chr()` write). `origin/main: RC=0 GOT=allow`; `PR #374
   head: RC=0 GOT=allow` — passes through undenied on both, exactly as
   round 2's prose says it will ("Nothing in this gate catches an
   expansion-built head"). The claim holds for this construction.

6. **Test-harness trap (this issue's own subject) — which layer denied
   each payload, stated explicitly.**

   Payload with no literal `docs` substring anywhere, a plain redirect to
   an env-var-supplied path (`D=$(printf '%s' "$TARGETDIR"); cd "$D" &&
   echo hi > out6.md`, `TARGETDIR=docs/issue-3/reports`): **passthrough on
   both `origin/main` and PR head** — neither the fast-path skip nor the
   full scan's shape checks fire, because this is a plain `>` redirect,
   not an interpreter `-c`/`-e` invocation, a `WRITE_UNSAFE_HEADS` head, a
   heredoc, or an `$IFS` fusion. This is outside the class issue-361's fix
   targets (per the jurisdiction-limit text, item 4) and outside what
   `_is_unanalyzable_write_shape` was ever built to catch — not a
   regression from this PR.

   Payload with no literal `docs` substring, a `dd` write
   (`D=$(printf '%s' "$TARGETDIR"); echo hi | dd of="$D/out7.md"`):
   `origin/main: RC=0 GOT=allow` (old fast path's `*docs*`-only gate never
   let it reach the python judge); `PR #374 head: RC=2 GOT=deny` — **caught
   by the full scan**, via `UNANALYZABLE_WRITE_HEAD_RE` matching `dd` in
   the shell layer forcing past the fast path, then confirmed unanalyzable
   by the python judge. This is exactly the class issue-361's fix targets,
   and it works on the current head.

7. **Standing invariants.**
   - No return of the retired role axis (`CLAUDE_ROLE`):
     `derived: grep -rn "CLAUDE_ROLE" core/hooks/board-gate.sh` on both
     worktrees — 0 matches on both. `role` as a word still appears (R4
     "role session", `.on-the-record/role.json`) — current, non-retired
     vocabulary, not the retired axis.
   - No new bug, failing-test sets vs `origin/main`, as sets of names:
     `derived: bash core/hooks/tests/run-board-gate-tests.sh` (both) —
     main 155 passed/2 failed, head 159 passed/2 failed (+4 = the new
     issue-361 test cases, all passing); failing-name set both
     `{feasibility-spikes, ops-postmortems}`, identical.
     `derived: bash core/hooks/tests/run-scope-gate-tests.sh` (both) — 62
     passed/0 failed, identical.
     `derived: python3 -m pytest -q` (both) — 3 failed/79 passed both,
     failing-name set both
     `{test_proposal_shape_gate_refuses_missing_sections,
     test_survey_order_gate_refuses_proposal_without_survey_or_skip,
     test_A5_trailer_gate_quote_split_commit_is_detected}`, identical
     (`diff` of sorted `FAILED` lines empty).
   - No overhead increase: covered in item 3 — round 2's commit is
     comment-only, so it cannot have moved the previously-established
     +0.5-0.9ms/call number, and this round's own (noisier, single-trial)
     measurement is consistent with no regression within that
     methodology's noise band.
   - Monitor/watch machinery unbroken, not quieter:
     `derived: bash core/hooks/tests/run-fleet-scan-tests.sh` (both) —
     `pass=26 fail=1` identical on both, same failing case
     (`live fleet run produces 43 repo rows want=43 got=44`, pre-existing
     flake unrelated to this PR), event volume identical, not quieter.
     (Unrelated side note: PR #378's own body claims "no monitor/watch
     machinery exists anywhere in this repo for this gate," which this
     check contradicts directly — `run-fleet-scan-tests.sh` exists and
     ran on both worktrees. That is a #378 accuracy issue, not a #374
     one, noted here only because this round's invariant check surfaced
     it.)

## Why

Findings ordered by what the task itself flagged as the trap: the
claim-truth check first (does round 2's replacement actually hold
everywhere the branch makes the claim, not just where the diff touched),
then the detection-logic-unchanged check the task named as the one that
"fails quietly" (isolating round 2's own commit from the PR #367 merge
that landed in the same branch, rather than trusting the PR's "comment
text only" self-description), then the round-1 carryover checks and
invariants, since those must still hold on a branch that moved.

## What did not work

None — no dead ends in this verification pass; every check listed above
produced an actual result.

## Upstream basis

PR #374 (`tokenmaxxxer/tokenmaxxxer-core`), branch
`issue-361/secure-coding-input-validation-injection-defense-a072264b`,
head `c9f1c4ce455a13e7285e3c2b9f0a22b6f76974b9`. Round-2 commit `64a58fa`
diffed in isolation from the `b6cb34a` (PR #367) merge landed in the same
branch. The PR's own record file
`docs/issue-361/reports/secure-coding-input-validation-injection-defense-a072264b.md`
and prior adversarial-review records (`docs/issue-361/reports/
independent-adversarial-verification-*` at commits `831b1ba`/`42b81b5`,
i.e. PRs #375/#377) were read to locate what to re-check, not restated as
fact — all cited findings above were re-derived live against fresh
`origin/main` and PR-head worktrees or a live `gh pr view`/`gh pr diff`
fetch in this session.

## Open findings

1. **BLOCKING — round 2's soundness-claim fix is incomplete: it lands in
   `core/hooks/board-gate.sh`'s comment only, and the same disproven
   "sound... proxy" claim still stands, unedited, in the PR's own live
   description and in the PR's own delivery record file
   `docs/issue-361/reports/secure-coding-input-validation-injection-defense-a072264b.md`.**
   Resolution path: a further round must edit the PR description (via
   `gh pr edit --body`) and amend or annotate the record file to carry the
   same "proxy, not soundness guarantee" framing now in the code comment —
   or explicitly supersede the record file's claim rather than leaving it
   standing unchallenged next to the code it describes.
2. Non-blocking observations, not findings requiring a fix: the
   `php -r` literal-head gap (item 5a) is a pre-existing, unaffected
   scope boundary of the closed interpreter-name vocabulary, not a false
   claim or a regression; the plain-redirect passthrough (item 6, payload
   A) is outside the class issue-361's fix targets; PR #378's "no
   monitor/watch machinery" claim (item 7) is a #378 accuracy issue, not
   a #374 one.
3. All items from rounds 1-2 not superseded above (detection logic,
   fast-path short-circuit, chr()/env-var-target catches, #367
   consistency, no-new-failing-tests, monitor/watch volume) — reconfirmed,
   none reopened.

## Next steps

None — this record is terminal (`loop_state: landed`). Resolving open
finding 1 (fixing the PR body and the shipped record file, not just the
code comment) is next-round work for a builder session against issue-361,
not this record.

skill-verdict: adversarial-review — applied: invoked; loaded the skill's
procedure before finalizing verdict/findings shape — this session already
satisfies its Step 2 gate (structurally independent evaluator, no access
to the builder's session, artifact fetched fresh via `gh pr view`/`gh pr
diff`/worktrees rather than trusting the builder's or a prior round's
record) by the role-handoff contract's own spawn setup.
other mounted skills: work-in-english — not triggered as a standalone
invocation (this record and all repo-bound artifacts are written in
English per its policy regardless of the surrounding session's language);
implementation-audit — not-applicable: this is a targeted round-3
re-verification of a specific prior claim and its detection-logic
provenance, not a fresh two-session claim-by-claim audit against the
original issue text.
