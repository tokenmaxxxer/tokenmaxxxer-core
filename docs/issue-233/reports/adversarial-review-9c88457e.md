---
issue: 233
role: adversarial-review-9c88457e
author: adversarial-review-9c88457e
skills: adversarial-review (skill-repository(c05de12))
verifies_subject: true
loop_state: landed
upstream:
  - path: PR #385 (tokenmaxxxer/tokenmaxxxer-core), commits fcfdbce, d49dcec on top of origin/main@a9d8673
    sha: d49dcec23d654aa2469f9a7afdfcbc8b13238f72
code_under_review: PR #385 "issue-233: unify jurisdiction wording to #374's phrasing"
type: adversarial-review-record
breaking: false
verdict: unification is partial, not complete — a fourth wording variant survives in both gates' live deny message, adjacent to the sentence the round unified; detection constants and both gates' subprocess-level deny path are otherwise confirmed unchanged and reachable
skill-verdict: adversarial-review — applied: invoked; every finding below cites a specific command/output or file:line rather than a restated summary, per the skill's evidence requirement
skill-verdict: work-in-english — applied: invoked; record, and this session's only other output (none — no code/PR/commit was authored by this session beyond this record), written in English
---

# issue-233 — adversarial-review-9c88457e record

## What was done

Independent, structurally separate re-verification of PR #385
(https://github.com/tokenmaxxxer/tokenmaxxxer-core/pull/385), which claims
to unify three previously-inconsistent jurisdiction-limit phrasings —
PR #367's "outside what this gate claims to bound", PR #382's "outside
what this gate claims to catch", and PR #374's already-landed "out of
this gate's jurisdiction" — onto the third one, in both
`core/hooks/board-gate.sh` and `warrant/hooks/lib/scope-gate.py`. PR #385
was raised as a direct follow-up to `adversarial-review-40308792`'s
CHECK 3 finding (docs/issue-233/reports/adversarial-review-40308792.md),
which is this record's own predecessor in the same review lineage.

Fetched the PR head without touching the working branch
(`git fetch origin pull/385/head:pr385`, `d49dcec` on top of
`origin/main@a9d8673`) and built two disposable worktrees,
`/tmp/wt-pr385` (pr385) and `/tmp/wt-main` (origin/main), for all
subprocess-level probing below — the working branch itself was not used
to run either gate.

### Check 1 — is the unification complete, or partial

Grepped both files on the `pr385` worktree for every remaining
`claim|catch|bound|jurisdiction` occurrence:

```
derived: grep -nE "claim|catch|bound|jurisdiction" /tmp/wt-pr385/core/hooks/board-gate.sh /tmp/wt-pr385/warrant/hooks/lib/scope-gate.py
```

Every "Jurisdiction limit" header-comment sentence, and the head-side
deny-message clause `fcfdbce` itself added, now reads "out of this
gate's jurisdiction" / "is equally out of this gate's jurisdiction" —
that much is fully unified, in both files.

But one sentence was missed. Both files' `deny()` message — the actual
string a session receives on stderr — carries an older, independent
flag-side clause that was never one of the three sentences named in any
prior round's brief and was never touched by `fcfdbce`:

```
board-gate.sh:858:   "write target of, and does not claim to catch a shape "
scope-gate.py:380:   "the write target of, and does not claim to catch a shape "
```

immediately followed, three lines later in the same message, by the
sentence `fcfdbce` did rewrite:

```
board-gate.sh:863:   "is equally out of this gate's jurisdiction."
scope-gate.py:385:   "indirection -- is equally out of this gate's jurisdiction."
```

`git show origin/main:core/hooks/board-gate.sh` / `:warrant/hooks/lib/scope-gate.py`
confirm this "does not claim to catch a shape deliberately built to hide
that target from this text-level read" clause already existed, worded
exactly this way, on `origin/main` before PR #367, PR #374, or PR #382
ever touched either file — it is the deny-message's own independent
lineage, distinct from the header-comment sentence PR #367 introduced
("outside what this gate claims to bound"), and `fcfdbce`'s diff (below,
Check 2) never lands a line at 858/380.

Read as full sentences, the live deny message in both gates now says,
verbatim, in the same paragraph: "...it denies only shapes it cannot
read the write target of, and **does not claim to catch** a shape
deliberately built to hide that target from this text-level read. The
same limit holds on the head side. An interpreter head that bash's own
expansion grammar assembles [...] is equally **out of this gate's
jurisdiction**." Two different verbs for the identical claim
("the same limit"), one sentence apart, in the one place source text
actually reaches a reader — confirmed live at the subprocess level
below (Check 3).

**Verdict: partial, not complete.** The round fixed every site any prior
review had explicitly named, but the check asked for every sentence
stating what these gates do not catch, not only the three previously
named ones, and this fourth site was missed. It reads as settled
(all three header sentences match) while the actual denial text a
session sees still juxtaposes two different verbs for "the same
limit" — the exact partial-unification-looks-worse-than-none shape the
review brief warned about.

### Check 2 — did detection move

```
derived: git diff origin/main pr385 -- core/hooks/board-gate.sh warrant/hooks/lib/scope-gate.py | grep -E '^[+-]' | grep -v '^+++\|^---'
```
result: four hunks, all comment prose or `deny()`/message string
literals (the two header-comment paragraphs and the two deny-message
tails quoted in "What was done" above) — no other line in either file
changed.

Checked all ten named constants individually by definition-line grep in
both refs (`git show <ref>:<file> | grep -n '^<NAME>\s*='`):
`INTERPRETER_HEADS`, `INLINE_FLAG_HEADS`, `WRITE_UNSAFE_HEADS`,
`FUSED_INTERP_RE`, `VAR_INTERP_RE`, `UNANALYZABLE_WRITE_SHAPE`,
`UNANALYZABLE_HEAD_RE`, `UNANALYZABLE_FLAG_RE`,
`UNANALYZABLE_WRITE_HEAD_RE`, `IFS_TOKEN_RE` — all ten identical text on
`origin/main` and `pr385`, in both `core/hooks/board-gate.sh` and
`warrant/hooks/lib/scope-gate.py` (the ones defined there).
**Verdict: detection did not move.** No prior round (adversarial-review-40308792
included) found movement either; this round adds no new movement.

### Check 3 — does the unified sentence reach the actual deny message, in both gates

Ran both gates as real subprocesses against the `pr385` worktree, via a
throwaway driver (`/tmp/drive_gates.py`) that builds a disposable git
repo, pipes a `{"tool_name":"Bash","tool_input":{"command":...},"cwd":...}`
payload on stdin, and captures the literal exit code / stdout / stderr —
the same transport shape `core/hooks/tests/run-*-gate-tests.sh` use.

**`core/hooks/board-gate.sh`** (payload: `cd <repo> && P=python3; ${P} -c
'open(1)'`, branch `issue-3/qa`, `docs/specs/approvers.md` present,
`CLAUDE_SKILL=qa`):
```
RC= 2
STDERR: board-gate: a Bash call carries an un-analyzable write-capable shape (P=python3; ${P} -c 'open(1)') while this gate enforces role 'qa''s write-set. A heredoc body, an interpreter -c/-e inline script, or a dd invocation does not show its real write target in the command text, so this refuses rather than risk a masked out-of-set write (issue-225 — the on-the-record PR #1627 bypass). Use a provably read-only invocation (e.g. python3 -m pytest), or write through Write/Edit or a plain redirect this gate can read the target of. This is a write-set discipline check, not a security boundary (issue-233 round 5): it denies only shapes it cannot read the write target of, and does not claim to catch a shape deliberately built to hide that target from this text-level read. The same limit holds on the head side. An interpreter head that bash's own expansion grammar assembles -- brace expansion, ANSI-C quoting, a hex-escaped word, or variable indirection -- is equally out of this gate's jurisdiction.
```

**`warrant/hooks/scope-gate.sh` → `scope-gate.py`** (payload: same
command, one `docs/proposals/2026-08-30-test.md` with `status:
approved`, `CLAUDE_PROJECT_DIR` set, `CLAUDE_PLUGIN_ROOT_CORE=<worktree>/core`):
```
RC= 2
STDERR: warrant: refused — this Bash call carries an un-analyzable write-capable shape (a heredoc body, an interpreter -c/-e inline script, or tee/dd) while docs/proposals/2026-08-30-test.md's write set is enforced. Its real write target is not visible in the command text, so this refuses rather than risk a masked out-of-set write (issue-225). Use a provably read-only invocation (e.g. python3 -m pytest), or write through Write/Edit or a plain redirect the write-set check can read the target of. This is a write-set discipline check, not a security boundary (issue-233 round 5): it denies only shapes it cannot read the write target of, and does not claim to catch a shape deliberately built to hide that target from this text-level read. The same limit holds on the head side. An interpreter head that bash's own expansion grammar assembles -- brace expansion, ANSI-C quoting, a hex-escaped word, or variable indirection -- is equally out of this gate's jurisdiction.
```

Same payload against `/tmp/wt-main` (origin/main, before `fcfdbce`) for
contrast — both gates deny (`RC=2`) with the identical message minus the
last sentence's tail, which read `"...is equally outside what this gate
claims to catch."` (PR #382's wording, pre-unification):
```
board-gate.sh (origin/main): ...is equally outside what this gate claims to catch.
scope-gate.py (origin/main): ...is equally outside what this gate claims to catch.
```

**Verdict: confirmed for both gates.** The unified "out of this gate's
jurisdiction" sentence reaches the actual subprocess-level stderr in
both `board-gate.sh` and `scope-gate.py`, not only a source comment —
but per Check 1, the sentence immediately before it in the same message
was not brought along, so what a session actually reads is
inconsistent, not merely comment-vs-message.

### Judgement — one limit, or three that share a phrase

Read as a set, the three header-comment sentences PR #385 targeted (PR
#367's flag-side comment, PR #374's `UNANALYZABLE_HEAD_RE` paragraph,
PR #382's head-side addition) now genuinely describe one limit: same
referent (the gate's pre-expansion text-read is blind to a
deliberately-hidden write target, on both the flag and the head side),
same word for the boundary ("jurisdiction"), same causal framing ("the
same limit holds on the head side"). That part is real coherence, not
string equality — a reader moving between the two files' header
comments and PR #374's paragraph gets one consistent story.

But the set is incomplete, and where it is incomplete matters more than
where it succeeded: the deny-message flag-side clause that predates all
three named sentences was never brought into the set, so the message a
session actually receives on a denial reads as two limits that happen
to sit one sentence apart — "does not claim to catch [X]" and "[Y] is
out of this gate's jurisdiction" — for what the very same sentence
calls "the same limit." The header comments are coherent; the thing a
session actually reads when denied is not.

## Why

Adversarial review of a wording-unification PR has to check the unified
text where it is actually consumed (subprocess stderr), not just where
it is easiest to read (source comments) — per this issue's own history,
a previous round (#382, caught by #383/40308792) already showed that a
"vocabulary reused from #374" claim in a PR body did not match the PR's
own diff. The same discipline — re-derive from the live deny message,
don't trust the record's account of which clauses were touched — is
what surfaced this round's gap: the technical-writing record on PR #385
(`technical-writing-structure-comprehension-1973359c.md`) states it
edited "the deny() message string reached by the enforced-write-set
path," which is true of the message as a whole, but does not claim (and
on inspection did not) touch the deny message's own flag-side clause —
a claim I did not take at face value.

## What did not work

None.

## Upstream basis

- PR #385 (`fcfdbce`, `d49dcec` on `origin/main@a9d8673`) — the subject
  of this review; `gh pr diff 385`, `git fetch origin
  pull/385/head:pr385`, canonical.
- `docs/issue-233/reports/adversarial-review-40308792.md` (this review's
  direct predecessor, merged via PR #383) — source of the CHECK 3
  finding PR #385 was raised to fix; read directly, canonical.
- `origin/main` at `a9d8673` (this session's base) — the pre-`fcfdbce`
  state used for every before/after subprocess comparison above.

## Open findings

- One open finding: `core/hooks/board-gate.sh:858` and
  `warrant/hooks/lib/scope-gate.py:380` still read "does not claim to
  catch a shape deliberately built to hide that target from this
  text-level read" — a fourth, un-unified phrasing for the same
  jurisdiction limit, one sentence away from the newly-unified "is
  equally out of this gate's jurisdiction" clause in the same message.
  Resolution path: a follow-up wording-only edit rewriting this clause
  to "is out of this gate's jurisdiction" (or equivalent), in both
  files, verified the same way this record verified `fcfdbce` — real
  subprocess denial, before/after, plus the ten-constant byte-identity
  check re-run.

## Standing invariants

- **No return of the retired role axis, in any reshaped form:**
  `derived: git diff origin/main pr385 -- core/hooks/board-gate.sh warrant/hooks/lib/scope-gate.py | grep -E '^\+' | grep -v '^+++' | grep -i role` —
  result: no output (no added line mentions "role" in any form).
- **No new bug — failing-test set vs `origin/main`, compared as SETS OF
  NAMES:**
  - `derived: bash core/hooks/tests/run-board-gate-tests.sh` (run from
    `/tmp/wt-pr385` and `/tmp/wt-main` separately) — both: 159 passed, 2
    failed, `FAIL feasibility-spikes`, `FAIL ops-postmortems`. Same set.
  - `derived: bash core/hooks/tests/run-scope-gate-tests.sh` — both: 62
    passed, 0 failed. Same (empty) set.
  - `derived: python3 -m pytest -q` (run from each worktree) — both: 3
    failed, 79 passed, names
    `{test_proposal_shape_gate_refuses_missing_sections,
    test_survey_order_gate_refuses_proposal_without_survey_or_skip,
    test_A5_trailer_gate_quote_split_commit_is_detected}`. Same set.
- **No overhead increase:** `derived: python3 /tmp/time_gates.py <worktree> <board|scope> 30` —
  `board-gate.sh`: `origin/main` 50.1ms/call avg, `pr385` 53.7ms/call
  avg (30 calls each); `scope-gate.py`: `origin/main` 49.7ms/call avg,
  `pr385` 40.4ms/call avg (30 calls each). Both deltas are inside normal
  subprocess-timing noise for a comment/string-literal-only diff that
  adds no executed code path; the scope-gate.py direction is actually
  faster on `pr385`, ruling out a systematic slowdown.
- **Monitor and watch machinery unbroken and not quieter:**
  `derived: grep -in "monitor\|watch" /tmp/wt-pr385/core/hooks/board-gate.sh /tmp/wt-pr385/warrant/hooks/lib/scope-gate.py` —
  result: no output. Neither file PR #385 touches contains monitor or
  watch machinery, so this diff cannot have broken or quieted any.

## Next steps

None for this session — `loop_state: landed`. This record's one open
finding (the un-unified deny-message flag-side clause) is left for a
follow-up wording session per the resolution path stated above; it does
not block PR #385 from being merged as-is (both gates still deny
correctly, the message is degraded in coherence, not in behavior), but
it means issue #233's "the round did not finish" condition applies to
this wording lineage until that clause is fixed.
