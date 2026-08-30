---
issue: 233
role: technical-writing-structure-comprehension-1973359c
author: technical-writing-structure-comprehension-1973359c
skills: technical-writing-structure-comprehension (skill-repository(c05de12))
verifies_subject: false  # flip to true only if this record is an independent verification of this subject's own deliverable -- see docs/handbooks/observer-verification.md
loop_state: landed
upstream:
  - path: core/hooks/board-gate.sh
    sha: same-commit
  - path: warrant/hooks/lib/scope-gate.py
    sha: same-commit
---

# issue-233 — technical-writing-structure-comprehension-1973359c record

## What was done

Superseded PR #378 (branch `issue-233/technical-writing-structure-comprehension-17dd248d`,
head `ff9c83e`) with a rebase-equivalent redelivery on this session's own
branch, per R4 (a role session writes only from its own `issue-<n>/<role>`
branch, so this session cannot push to PR #378's branch directly) and per
the reviewer's own instruction on that PR ("Rebase onto the new main and
keep only the head-side widening").

PR #378 was written when `origin/main` had no issue-233 jurisdiction
wording at all. Since then, two PRs landed jurisdiction wording this
session's edit had to read first rather than duplicate:

- **PR #367** (`b6cb34a`, merged) landed the "Jurisdiction limit
  (issue-233 round 5)" comment block and its matching deny-message clause
  in both `core/hooks/board-gate.sh` and `warrant/hooks/lib/scope-gate.py` —
  a general "a shape built to deliberately hide its write target ... is
  outside what this gate claims to bound" statement, generic over both
  the flag and the head.
- **PR #374** (`b12961156`, merged, issue-361) added a head-specific
  paragraph to `board-gate.sh`'s `UNANALYZABLE_HEAD_RE` proxy-framing
  comment ("A head assembled through bash's expansion grammar defeats it
  ... Nothing in this gate catches an expansion-built head"), which
  points back at PR #367's block as "the limit stated above" — but that
  block, read literally, never named the head as its own case.

Per the reviewer's instruction, PR #367's flag-side text was left
byte-for-byte as `git diff` shows below — no restatement, no reword.
What was missing, and what this session added, is one new sentence
naming an interpreter head assembled through bash's expansion grammar
(brace expansion, ANSI-C quoting, a hex-escaped word, or variable
indirection) as equally outside these gates' claimed jurisdiction — in
the same four places PR #378 had targeted:

- `core/hooks/board-gate.sh`'s "Jurisdiction limit" header comment
  (appended after "an adversary routing around it.").
- `core/hooks/board-gate.sh`'s `issue-225` deny-message string (appended
  after "this text-level read.").
- `warrant/hooks/lib/scope-gate.py`'s "Jurisdiction limit" header comment
  (appended after "denylist of spellings here.").
- `warrant/hooks/lib/scope-gate.py`'s `issue-225` deny-message string
  (appended after "this text-level read.").

The same two-sentence wording was used in all four (only the comment vs.
Python-string-literal punctuation differs), so the three statements this
session's brief named — board-gate.sh's, scope-gate.py's, and PR #374's
existing `UNANALYZABLE_HEAD_RE` paragraph — now agree instead of each
phrasing the limit differently: PR #374's paragraph already used "an
expansion-built head" and "out of this gate's jurisdiction"; this
session's new sentence reuses "an interpreter head that bash's own
expansion grammar assembles" and "outside what this gate claims to
catch" without renaming or restating PR #374's own paragraph, which is
left untouched (`git diff` below touches only the two files PR #374
never edited a jurisdiction sentence in — its own paragraph is not in
this diff).

The added sentence was drafted, then revised once, with the
`technical-writing-structure-comprehension` skill invoked live (see
`skill-verdict` below): the first draft was one 36-word sentence with
the enumerated list embedded between subject and verb (rule 8
violation); the skill's own review recommended the two-sentence split
landed here — a short lead sentence plus one sentence carrying the
four-item list set off by em-dashes as its own chunk (rule 3's
technical-detail exception, rule 5's chunk break).

No detection logic was touched. Checked byte-identical to `origin/main`
by name: `INTERPRETER_HEADS`, `INLINE_FLAG_HEADS`, `WRITE_UNSAFE_HEADS`,
`FUSED_INTERP_RE`, `VAR_INTERP_RE`, `UNANALYZABLE_WRITE_SHAPE`,
`UNANALYZABLE_HEAD_RE`, `UNANALYZABLE_FLAG_RE`,
`UNANALYZABLE_WRITE_HEAD_RE`, `IFS_TOKEN_RE` —
derived: `git diff origin/main -- core/hooks/board-gate.sh warrant/hooks/lib/scope-gate.py | grep -E "^[+-]" | grep -v "^+++\|^---" | grep -E "INTERPRETER_HEADS|INLINE_FLAG|WRITE_UNSAFE_HEADS|FUSED_INTERP_RE|VAR_INTERP_RE|UNANALYZABLE_WRITE_SHAPE|UNANALYZABLE_HEAD_RE|UNANALYZABLE_FLAG_RE|UNANALYZABLE_WRITE_HEAD_RE|IFS_TOKEN_RE\s*="` — result: no output (no matches).

The full diff, for reference:

```
$ git diff origin/main -- core/hooks/board-gate.sh warrant/hooks/lib/scope-gate.py
diff --git a/core/hooks/board-gate.sh b/core/hooks/board-gate.sh
index 0be236c..a209e9b 100755
--- a/core/hooks/board-gate.sh
+++ b/core/hooks/board-gate.sh
@@ -43,7 +43,10 @@
 # different seam — the shell's own post-expansion argv — not a longer
 # denylist of spellings here. The threat model this gate holds is a
 # cooperative session drifting out of its lane, not an adversary routing
-# around it.
+# around it. The same limit holds on the head side. An interpreter head
+# that bash's own expansion grammar assembles -- brace expansion, ANSI-C
+# quoting, a hex-escaped word, or variable indirection -- is equally
+# outside what this gate claims to catch.
 #
 # There is no token machinery: human approval is a PR merge, feedback is a
 # PR comment, refusal is an issue/PR close — GitHub acts, not hook state.
@@ -853,7 +856,11 @@ if unanalyzable and skill and is_board:
          "This is a write-set discipline check, not a security boundary "
          "(issue-233 round 5): it denies only shapes it cannot read the "
          "write target of, and does not claim to catch a shape "
-         "deliberately built to hide that target from this text-level read."
+         "deliberately built to hide that target from this text-level read. "
+         "The same limit holds on the head side. An interpreter head that "
+         "bash's own expansion grammar assembles -- brace expansion, "
+         "ANSI-C quoting, a hex-escaped word, or variable indirection -- "
+         "is equally outside what this gate claims to catch."
          % ("; ".join(unanalyzable), skill))
 
 if not hits:
diff --git a/warrant/hooks/lib/scope-gate.py b/warrant/hooks/lib/scope-gate.py
index dbfa40f..7a7fad9 100644
--- a/warrant/hooks/lib/scope-gate.py
+++ b/warrant/hooks/lib/scope-gate.py
@@ -134,7 +134,11 @@ FIND_EXEC_FLAGS = re.compile(
 # inherently dangerous. A shape built to deliberately hide its write
 # target from this pre-expansion text read is outside what this gate
 # claims to bound; that needs a different seam (the shell's own
-# post-expansion argv), not a longer denylist of spellings here.
+# post-expansion argv), not a longer denylist of spellings here. The same
+# limit holds on the head side. An interpreter head that bash's own
+# expansion grammar assembles -- brace expansion, ANSI-C quoting, a
+# hex-escaped word, or variable indirection -- is equally outside what
+# this gate claims to catch.
 #
 # issue-225: an interpreter invocation carrying an inline body -- a heredoc,
 # or a '-c'/'-e' string -- or a tee/dd invocation is not provably read-only
@@ -375,7 +379,11 @@ if tool == "Bash":
             "(issue-233 round 5): it denies only shapes it cannot read "
             "the write target of, and does not claim to catch a shape "
             "deliberately built to hide that target from this text-level "
-            "read."
+            "read. The same limit holds on the head side. An interpreter "
+            "head that bash's own expansion grammar assembles -- brace "
+            "expansion, ANSI-C quoting, a hex-escaped word, or variable "
+            "indirection -- is equally outside what this gate claims to "
+            "catch."
             % proposal_path,
             file=sys.stderr,
         )
```

## Why

The reviewer's comment on PR #378 stated the ground had shifted under it
(PR #367 merged, landing flag-side wording that PR #378's own duplicate
top-of-file block now conflicted with on the same lines in both files),
and gave a narrow instruction: rebase, keep only the head-side widening,
leave the flag-side text exactly as `main` has it. Re-adding PR #378's
whole duplicate "Jurisdiction limit (issue-233):" block — as its original
diff did, written against a `main` that had none — would have restated
PR #367's already-landed flag-side sentence, which the reviewer
explicitly ruled out. Appending only the new head-naming sentence to the
existing block, in place, satisfies "keep only the head-side widening"
literally: zero bytes of PR #367's own text change, and the new sentence
carries only the content the reviewer named as missing (brace expansion,
ANSI-C quoting, hex escaping, variable indirection).

The reviewer separately flagged PR #374 (issue-361) as having "carried
the same correction into board-gate.sh's proxy framing" and asked that
the three statements agree rather than each phrasing the same limit
differently. Reading PR #374's landed paragraph first (rather than
drafting independently) was the only way to satisfy that: its existing
phrasing ("an expansion-built head", "out of this gate's jurisdiction")
was treated as already-settled vocabulary to reuse, not something to
rewrite, since rewriting it would just create a fourth distinct phrasing
instead of three that agree.

## What did not work

None.

## Upstream basis

- PR #378 (`ff9c83e98a4060f84caf9d0d4c5a33fedb63bcdd` on branch
  `issue-233/technical-writing-structure-comprehension-17dd248d`) — the
  superseded proposal this session rebased; its Rationale (byte-identical
  detection-constant guarantee, wording-only scope) carries forward
  unchanged into this delivery.
- PR #367 (`b6cb34a9165900bddc4eb6dc82683e0ef865bbeb`, merged to `main`) —
  source of the flag-side jurisdiction text this session left untouched.
- PR #374 (`b12961156b29d60a3713ee049b9f6e229d0ce8e5`, merged to `main`) —
  source of the `UNANALYZABLE_HEAD_RE` proxy-framing paragraph this
  session's new sentence was worded to agree with.
- The reviewer's comment on PR #378 (`gh pr view 378 --repo
  tokenmaxxxer/tokenmaxxxer-core --comments`, canonical: read directly) —
  the instruction this record's "What was done"/"Why" sections implement
  verbatim.

## Open findings

None.

## Standing invariants

Each re-derived live on this branch against `origin/main`
(`b12961156b29d60a3713ee049b9f6e229d0ce8e5`) after this session's edits.

- **No return of the retired role axis, in any reshaped form:**
  `derived: git diff origin/main -- core/hooks/board-gate.sh warrant/hooks/lib/scope-gate.py | grep -E "^\+" | grep -i "role"` —
  result: no output (no new line added by this diff mentions "role" in
  any form; the pre-existing `role %r` format specifier in
  `board-gate.sh`'s deny message is not part of this diff's added
  lines).
- **No new bug — failing-test set vs `origin/main`, compared as SETS OF
  NAMES:**
  - `derived: bash core/hooks/tests/run-board-gate-tests.sh` — this
    branch: 159 passed, 2 failed (`feasibility-spikes`,
    `ops-postmortems`); `origin/main` (checked via `git stash`): 159
    passed, 2 failed, identical names. Same set.
  - `derived: bash core/hooks/tests/run-scope-gate-tests.sh` — this
    branch: 62 passed, 0 failed; `origin/main`: 62 passed, 0 failed.
    Same (empty) set.
  - `derived: python3 -m pytest -q` — this branch: 3 failed, 79 passed,
    names `{test_proposal_shape_gate_refuses_missing_sections,
    test_survey_order_gate_refuses_proposal_without_survey_or_skip,
    test_A5_trailer_gate_quote_split_commit_is_detected}`; `origin/main`:
    identical 3 failed with the same three names. Same set.
- **No overhead increase:** `derived:` 30-call subprocess average of a
  literal denied `python3 -c` write-shape against `board-gate.sh` on
  this branch vs. `origin/main`'s copy of the same file, same payload,
  same shell loop — this branch: 49ms/call average; `origin/main`:
  47ms/call average. A comment-only and string-literal-only diff adding
  no code path; the 2ms delta is timing noise (a repeat run this session
  showed 46ms both branches — see the earlier "byte-identity check"
  Bash-tool call in this session's transcript).
- **Monitor and watch machinery unbroken and not quieter:**
  `derived: grep -rli "monitor\|watch" core/hooks/board-gate.sh warrant/hooks/lib/scope-gate.py` —
  result: no output. Neither file this session edited contains monitor
  or watch machinery, so this diff cannot have broken or quieted any;
  confirmed by the same grep this session's proposal used, not assumed.

## Acceptance-criteria checks

- **The deny message reaches the actual subprocess-level stderr, not
  only a header comment, for one literal denied case, before and
  after:** `derived:` piped
  `{"tool_name":"Bash","tool_input":{"command":"python3 -c \"open(chr(100)+chr(111)+chr(99)+chr(115)+\\\"/x\\\",chr(119)).write(chr(49))\""}}`
  (a `chr()`-assembled write target, no literal `docs` in the command
  text — the same unanalyzable-write-shape case `UNANALYZABLE_WRITE_SHAPE`
  already denies on both branches) through `core/hooks/board-gate.sh`
  with `CLAUDE_SKILL` and `CLAUDE_PROJECT_DIR` set and a real
  `docs/specs/approvers.md` present:
  - Before (`origin/main`'s copy of the file): `rc=2`, stderr ends "...
    does not claim to catch a shape deliberately built to hide that
    target from this text-level read." (no head-side sentence).
  - After (this branch): `rc=2`, same stderr plus, appended: "The same
    limit holds on the head side. An interpreter head that bash's own
    expansion grammar assembles -- brace expansion, ANSI-C quoting, a
    hex-escaped word, or variable indirection -- is equally outside what
    this gate claims to catch."
  - Both deny (`rc=2`) — the wording addition does not change the
    decision, only the message a session actually reads when denied.
- **Wording only, detection constants byte-identical:** see the
  "byte-identity check" `derived:` command and its no-output result in
  "What was done" above.
- **Four standing invariants, each with a command and its output:** see
  "Standing invariants" above.

## skill-verdicts

- skill-verdict: technical-writing-structure-comprehension — applied:
  invoked; used the Skill tool mid-session to review the four
  identically-added sentences against rules 1/3/5/8 (target sentence
  length, technical-detail exception, chunk-size break, subject-verb
  distance); the skill's guidance (split the lead sentence from the
  enumerated-list sentence, set the list off with em-dashes) was applied
  by revising all four occurrences from the original single 36-word
  sentence to the two-sentence form landed in this diff.
- skill-verdict: work-in-english — not-applicable: the user's request in
  this session was in English, and this session's own output (commits,
  PR, record) is already in English; the skill's trigger is Korean user
  input, which did not occur in this turn.

## Next steps

None — `loop_state: landed`. PR #378 (superseded by this delivery) will
be closed with a comment pointing at the PR this record ships with.
