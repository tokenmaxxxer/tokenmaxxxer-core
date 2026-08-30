---
issue: 233
role: technical-writing-structure-comprehension-f80f29ba
author: technical-writing-structure-comprehension-f80f29ba
skills: technical-writing-structure-comprehension (skill-repository(c05de12))
verifies_subject: false
loop_state: landed
code_under_review: PR #385 (fcfdbce, d49dcec) plus this commit's own flag-side fix
type: fix
breaking: false
verdict: both gates' live deny() message now states the "out of this gate's jurisdiction" limit once per clause (flag-side, head-side), in matching vocabulary, instead of the flag-side clause surviving in an older "does not claim to catch" phrasing PR #385/#387 missed
upstream:
  - path: PR #385 (tokenmaxxxer/tokenmaxxxer-core), commits fcfdbce, d49dcec on top of origin/main@a9d8673
    sha: d49dcec23d654aa2469f9a7afdfcbc8b13238f72
  - path: PR #387's CHANGES comment on PR #385
    sha: same-commit
---

# issue-233 — technical-writing-structure-comprehension-f80f29ba record

## What was done

PR #385 (`fcfdbce`) unified three jurisdiction-limit phrasings onto "out
of this gate's jurisdiction" in the header comments and the head-side
sentence of both gates' `deny()` messages. PR #387's adversarial review
confirmed that unification was real but partial: both gates' live
`deny()` message still carried an older flag-side clause — "does not
claim to catch a shape deliberately built to hide that target from this
text-level read" — one sentence before the newly-unified head-side
sentence, inside the same paragraph, for what the message itself calls
"the same limit."

This round brought that flag-side clause onto the same "out of this
gate's jurisdiction" wording, in both `core/hooks/board-gate.sh` and
`warrant/hooks/lib/scope-gate.py`. The edit is confined to the
`deny()`/`print()` string literals in both files (the header comments
were already unified by PR #385 and were left untouched):

canonical: `git diff FETCH_HEAD -- core/hooks/board-gate.sh warrant/hooks/lib/scope-gate.py` (FETCH_HEAD = PR #385's `d49dcec`, fetched via `git fetch origin issue-233/technical-writing-structure-comprehension-dc23230a`)

```
-         "write target of, and does not claim to catch a shape "
-         "deliberately built to hide that target from this text-level read. "
-         "The same limit holds on the head side. An interpreter head that "
-         "bash's own expansion grammar assembles -- brace expansion, "
-         "ANSI-C quoting, a hex-escaped word, or variable indirection -- "
-         "is equally out of this gate's jurisdiction."
+         "write target of. A shape deliberately built to hide that "
+         "target from this text-level read is out of this gate's "
+         "jurisdiction. The same limit holds on the head side. An "
+         "interpreter head that bash's own expansion grammar assembles "
+         "-- brace expansion, ANSI-C quoting, a hex-escaped word, or "
+         "variable indirection -- is equally out of this gate's "
+         "jurisdiction."
```

(`warrant/hooks/lib/scope-gate.py` gets the same clause swap in its
`print(...)` call; both hunks are otherwise a rewrap, no other line
changed.) No regex, constant, or branch condition in either file was
touched — `unanalyzable and skill and is_board` (board-gate.sh) and
`UNANALYZABLE_WRITE_SHAPE.search(command)` (scope-gate.py) are the same
lines before and after this commit.

Sentence structure of the new clause was checked against the mounted
technical-writing-structure-comprehension skill: the semicolon-joined
first draft ("...write target of; a shape deliberately built...") was
two independent clauses in one sentence, so it was split into two
sentences at the period ("...write target of. A shape deliberately
built...") to match the skill's rule 2 and the existing "The same limit
holds on the head side." sentence already in the paragraph.

Live subprocess deny output, captured before (PR #385's `d49dcec`, i.e.
this branch's starting point before this commit's edit) and after (this
commit) against a real board-gate.sh / scope-gate.py invocation with an
unanalyzable `python3 -c` write shape:

canonical: `bash /tmp/gate-probe.sh` (board-gate.sh, temp git repo, branch `issue-3/qa`, `docs/specs/approvers.md` present, `CLAUDE_SKILL=qa`, payload `{"tool_name":"Bash","tool_input":{"command":"cd docs/issue-3 && python3 -c \"import sys; sys.stdout.write(1)\""},...}`)

Before (PR #385's `d49dcec`):
```
board-gate: a Bash call carries an un-analyzable write-capable shape (python3 -c "import sys; sys.stdout.write(1)") while this gate enforces role 'qa''s write-set. A heredoc body, an interpreter -c/-e inline script, or a dd invocation does not show its real write target in the command text, so this refuses rather than risk a masked out-of-set write (issue-225 — the on-the-record PR #1627 bypass). Use a provably read-only invocation (e.g. python3 -m pytest), or write through Write/Edit or a plain redirect this gate can read the target of. This is a write-set discipline check, not a security boundary (issue-233 round 5): it denies only shapes it cannot read the write target of, and does not claim to catch a shape deliberately built to hide that target from this text-level read.
rc=2
```

After (this commit — the full deny message a session actually reads):
```
board-gate: a Bash call carries an un-analyzable write-capable shape (python3 -c "import sys; sys.stdout.write(1)") while this gate enforces role 'qa''s write-set. A heredoc body, an interpreter -c/-e inline script, or a dd invocation does not show its real write target in the command text, so this refuses rather than risk a masked out-of-set write (issue-225 — the on-the-record PR #1627 bypass). Use a provably read-only invocation (e.g. python3 -m pytest), or write through Write/Edit or a plain redirect this gate can read the target of. This is a write-set discipline check, not a security boundary (issue-233 round 5): it denies only shapes it cannot read the write target of. A shape deliberately built to hide that target from this text-level read is out of this gate's jurisdiction. The same limit holds on the head side. An interpreter head that bash's own expansion grammar assembles -- brace expansion, ANSI-C quoting, a hex-escaped word, or variable indirection -- is equally out of this gate's jurisdiction.
rc=2
```

canonical: `bash /tmp/gate-probe2.sh` (scope-gate.py, temp git repo with one `status: approved` proposal restricting the write set to `src/app.py`, payload `{"tool_name":"Bash","tool_input":{"command":"python3 -c \"open(1)\""},...}`)

Before (`origin/main`, same string as PR #385's `d49dcec` for this clause — PR #385 never touched this line):
```
warrant: refused — this Bash call carries an un-analyzable write-capable shape (a heredoc body, an interpreter -c/-e inline script, or tee/dd) while docs/proposals/2026-08-08-probe.md's write set is enforced. Its real write target is not visible in the command text, so this refuses rather than risk a masked out-of-set write (issue-225). Use a provably read-only invocation (e.g. python3 -m pytest), or write through Write/Edit or a plain redirect the write-set check can read the target of. This is a write-set discipline check, not a security boundary (issue-233 round 5): it denies only shapes it cannot read the write target of, and does not claim to catch a shape deliberately built to hide that target from this text-level read.
rc=2
```

After (this commit):
```
warrant: refused — this Bash call carries an un-analyzable write-capable shape (a heredoc body, an interpreter -c/-e inline script, or tee/dd) while docs/proposals/2026-08-08-probe.md's write set is enforced. Its real write target is not visible in the command text, so this refuses rather than risk a masked out-of-set write (issue-225). Use a provably read-only invocation (e.g. python3 -m pytest), or write through Write/Edit or a plain redirect the write-set check can read the target of. This is a write-set discipline check, not a security boundary (issue-233 round 5): it denies only shapes it cannot read the write target of. A shape deliberately built to hide that target from this text-level read is out of this gate's jurisdiction. The same limit holds on the head side. An interpreter head that bash's own expansion grammar assembles -- brace expansion, ANSI-C quoting, a hex-escaped word, or variable indirection -- is equally out of this gate's jurisdiction.
rc=2
```

Read whole, the "after" message now states the jurisdiction limit once
per clause (once for the flag-side shape, once for the head-side shape),
both times in the same words — not the same limit stated twice in two
different vocabularies inside one paragraph, which was PR #387's
finding.

## Why

PR #387's CHANGES comment on PR #385 pointed at exactly one clause, in
two files: the deny message a session actually reads on refusal still
had two different verbs ("does not claim to catch" vs. "is ... out of
this gate's jurisdiction") for one limit the text itself calls "the same
limit." The header comments a maintainer reads were already consistent;
the fix target was the message text a session receives, not another
maintainer-facing comment. Bringing the flag-side clause onto the
already-unified head-side phrasing closes that gap without adding a
fourth vocabulary or touching detection logic.

## What did not work

None.

## Upstream basis

- PR #385 (`fcfdbce` "issue-233: unify jurisdiction wording to #374's
  phrasing", `d49dcec` "issue-233: add before-landing hunt record"),
  fetched from `issue-233/technical-writing-structure-comprehension-dc23230a`
  — this commit's starting point for `core/hooks/board-gate.sh` and
  `warrant/hooks/lib/scope-gate.py`. sha: `d49dcec23d654aa2469f9a7afdfcbc8b13238f72`
- PR #387 (merged to `origin/main` as `8c7cc8d`) — adversarial review of
  PR #385 that found the flag-side clause survivor this commit fixes.
  sha: same-commit (already on this branch's base, `origin/main`)
- PR #385's CHANGES comment (posted by the human/orchestrator on PR
  #385, quoting PR #387's finding) — the direct instruction for this
  round's scope: one clause, two files, text-only. sha: same-commit
  (comment text, not a repo path)

## Open findings

None. Detection logic (the ten named constants PR #387 already checked
byte-identical across three rounds) was not touched and was not
re-checked in this round, per this round's explicit instruction not to
redo that check a fourth time — confirmed by the `git diff FETCH_HEAD`
hunks above touching only string-literal content inside the existing
`deny()`/`print()` calls, not the `if unanalyzable and skill and
is_board:` / `UNANALYZABLE_WRITE_SHAPE.search(command)` lines that guard
them. The four standing invariants (role-axis, test-failure-set,
overhead, monitor/watch) and the three test suites were verified by PR
#387 against PR #385's diff and were not redone here, per the same
instruction — this commit's diff is a strict subset of what that
verification already covered (same two string-literal regions, no new
code path).

skill-verdict: technical-writing-structure-comprehension — applied: invoked; used to check the new deny-message clause's sentence structure (rule 2: split the semicolon-joined multi-clause draft into two sentences at a period) before landing the edit
skill-verdict: work-in-english — applied: invoked; this record, the commit message, and the PR body are written in English; the final chat summary to the user is in Korean per the skill's routing rule

## Next steps

None — this closes the residual PR #387 found on PR #385. Filed as
`Advances #233` rather than closing the issue: this is a partial,
text-only follow-up to PR #385, not a fresh pass over issue #233's own
detection acceptance criteria.
