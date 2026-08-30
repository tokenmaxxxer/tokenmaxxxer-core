---
issue: 233
role: adversarial-review-40308792
author: adversarial-review-40308792
skills: adversarial-review (skill-repository(c05de12))
verifies_subject: true
loop_state: landed
upstream:
  - path: PR #382 (tokenmaxxxer/tokenmaxxxer-core), commits b6eaa25, 7c4b39a on top of origin/main@b129611
    sha: 7c4b39a97c9f6b41c403e295711291aa9c94fb04
code_under_review: PR #382 "issue-233: widen board/scope-gate jurisdiction wording to name the head side"
type: adversarial-review-record
breaking: false
verdict: wording-only claim holds; ten-constants byte-identity claim confirmed; one low-severity wording-coherence defect found (three-way phrasing variance across #367/#374/#382 jurisdiction texts)
skill-verdict: adversarial-review — applied: invoked; used its evidence-requirement (every finding cites a specific command/output or file:line, no vague claims) across all four checks and the invariants
skill-verdict: work-in-english — applied: invoked; record, commit messages, and PR body written in English
skill-verdict: implementation-audit — not-applicable: this task is a bespoke, task-specified verification (four fixed checks + four invariants), not the formal claim-extraction/Present-Surface-Absent-Incorrect-Unverifiable classification protocol
---

# issue-233 — adversarial-review-40308792 record

## What was done

Independent, structurally separate re-verification of PR #382
(https://github.com/tokenmaxxxer/tokenmaxxxer-core/pull/382), which claims to
be a wording-only rebase of the closed PR #378 onto current `main`: it keeps
PR #367's flag-side jurisdiction text byte-identical and adds one new
sentence naming an interpreter head assembled through bash's expansion
grammar (brace expansion, ANSI-C quoting, a hex-escaped word, variable
indirection) as equally outside the board/scope-gate's jurisdiction, matching
the vocabulary PR #374 already used for the flag/proxy-framing side.

Fetched the PR's actual head without touching the working branch:

```
git fetch origin pull/382/head:pr382-review
```

`git log --oneline pr382-review -3` confirms two new commits on top of
`origin/main@b129611`:

```
7c4b39a issue-233: record the gh-guard refusal on closing superseded PR #378
b6eaa25 issue-233: widen board/scope-gate jurisdiction wording to name the head side
b129611 issue-361: close board-gate.sh's *docs* fast-path substring bypass (#374)
```

`git diff --stat origin/main pr382-review`:

```
 core/hooks/board-gate.sh                           |  11 +-
 ...cal-writing-structure-comprehension-1973359c.md | 299 +++++++++++++++++++++
 warrant/hooks/lib/scope-gate.py                    |  12 +-
 3 files changed, 318 insertions(+), 4 deletions(-)
```

Only two code files touched, and the full diff (below) shows only two
comment/message insertion hunks per file — no other line in either file
changed. This is the base fact the four checks and four invariants below
build on.

### CHECK 1 — Detection-did-not-move (ten named constants)

PR #382's own body claims: `INTERPRETER_HEADS`, `INLINE_FLAG_HEADS`,
`WRITE_UNSAFE_HEADS`, `FUSED_INTERP_RE`, `VAR_INTERP_RE`,
`UNANALYZABLE_WRITE_SHAPE`, `UNANALYZABLE_HEAD_RE`, `UNANALYZABLE_FLAG_RE`,
`UNANALYZABLE_WRITE_HEAD_RE`, `IFS_TOKEN_RE` (ten names — `canonical: gh pr
view 382 --json body -q .body`, the "Wording-only change" bullet) are
byte-identical to `origin/main`.

Re-ran the PR's own verification command independently:

```
git diff origin/main pr382-review -- core/hooks/board-gate.sh warrant/hooks/lib/scope-gate.py \
  | grep -E "^[+-]" | grep -v "^+++\|^---" \
  | grep -E "INTERPRETER_HEADS|INLINE_FLAG|WRITE_UNSAFE_HEADS|FUSED_INTERP_RE|VAR_INTERP_RE|UNANALYZABLE_WRITE_SHAPE|UNANALYZABLE_HEAD_RE|UNANALYZABLE_FLAG_RE|UNANALYZABLE_WRITE_HEAD_RE|IFS_TOKEN_RE\s*="
```
result: no output, exit 1 (confirmed independently — same as the PR body claims).

But a grep over changed lines only proves no *assignment line* changed; it
would miss a change to a continuation line of a multi-line regex/tuple body
that doesn't itself contain `NAME =`. So this was cross-checked against the
**full diff** captured above (`git diff origin/main pr382-review -- core/hooks/board-gate.sh warrant/hooks/lib/scope-gate.py`),
which contains exactly two hunks per file (lines ~43-49 and ~853-859 in
board-gate.sh; ~134-140 and ~375-383 in scope-gate.py), all of which are
comment prose / deny-message string literals. None of the four hunks
overlaps the constants' line ranges. Then, per-name, checked each
definition's line individually in both refs:

```
INTERPRETER_HEADS:        main:582  pr:585  — identical text, shifted +3 lines
INLINE_FLAG_HEADS:        main:614  pr:617  — identical text, shifted +3 lines
WRITE_UNSAFE_HEADS:       main:637  pr:640  — identical text, shifted +3 lines
FUSED_INTERP_RE:          main:642  pr:645  — identical text, shifted +3 lines
VAR_INTERP_RE:            main:651  pr:654  — identical text, shifted +3 lines
UNANALYZABLE_WRITE_SHAPE: main:174  pr:178  — identical text, shifted +4 lines (scope-gate.py)
UNANALYZABLE_HEAD_RE:     main:107  pr:110  — identical text, shifted +3 lines
UNANALYZABLE_FLAG_RE:     main:108  pr:111  — identical text, shifted +3 lines
UNANALYZABLE_WRITE_HEAD_RE: main:109 pr:112 — identical text, shifted +3 lines
IFS_TOKEN_RE:             main:631  pr:634  — identical text, shifted +3 lines
```
derived: `git show origin/main:<file> | grep -n '^<NAME>\s*='` vs `git show
pr382-review:<file> | grep -n '^<NAME>\s*='`, run for all ten names against
both `core/hooks/board-gate.sh` and `warrant/hooks/lib/scope-gate.py`.

Verdict: **all ten checked, all ten confirmed unchanged.** The line-number
shift (+3 in board-gate.sh, +4 in scope-gate.py) is exactly the number of
new comment lines the wording change inserts above them; no assignment or
regex body differs. Detection did not move. This is the single most
consequential claim in the PR and it holds.

### CHECK 2 — Does the new sentence reach the deny message, or only a comment

Located the touched files via `git log --all --oneline | grep -iE '367|374|233'`
(shown above) and by reading the diff directly: both `core/hooks/board-gate.sh`
and `warrant/hooks/lib/scope-gate.py` gained the sentence in two places each —
the "Jurisdiction limit" **comment block** (lines ~43-49 / ~134-140) and the
**deny-message string literal** emitted on the `unanalyzable_shape`/
`UNANALYZABLE_WRITE_SHAPE` deny path (lines ~853-859 / ~375-383). The second
location is what a session actually sees on stderr.

Ran `board-gate.sh` as a real subprocess (not a unit-test harness) from a
`git worktree` of each ref, without touching the working branch:

```
git worktree add /tmp/wt-main origin/main -q
git worktree add /tmp/wt-pr382 pr382-review -q
```

Harness (`/tmp/run_gate_check.sh`): builds a throwaway git repo on branch
`issue-3/qa` with `docs/specs/approvers.md` present, pipes a
`{"tool_name":"Bash","tool_input":{"command":...},"cwd":...}` payload to the
gate with `CLAUDE_SKILL=qa`, and prints the literal exit code and
stdout+stderr — the same transport shape `core/hooks/tests/run-board-gate-tests.sh`
uses (`run()` helper).

**Interpreter-head-via-single-token-expansion probe**
(`${x:-python3} -c "open(\"reports/qa/pwn.md\",\"w\").write(\"1\")"`) —
BEFORE (origin/main):
```
RC=0
STDOUT/STDERR:
```
AFTER (pr382-review):
```
RC=0
STDOUT/STDERR:
```
Both ALLOW. This is the known, still-open bypass class issue #233 itself is
about (parameter-default expansion producing the interpreter head) — PR #382
explicitly does not claim to close it ("the expansion-grammar bypass class on
both the head and flag side stays open by design"), and this probe confirms
that claim rather than contradicting it: the shape the new sentence *talks
about* never reaches the deny path at all, before or after, so it cannot by
itself demonstrate whether the new sentence appears in a real denial. A
second probe was needed to answer the actual question the check asks (does
the new text live in the emitted message, not just a comment).

**Literal-head + `-c` probe** (`python3 -c "import sys; sys.stdout.write(1)"`,
the exact shape `run-board-gate-tests.sh`'s `inline-c-flag-mask-bypass` test
uses at line 609) — this one does hit the enforced deny path on both refs and
lets the deny-message text itself be inspected. BEFORE (origin/main):
```
RC=2
STDOUT/STDERR:
board-gate: a Bash call carries an un-analyzable write-capable shape (python3 -c "import sys; sys.stdout.write(1)") while this gate enforces role 'qa''s write-set. A heredoc body, an interpreter -c/-e inline script, or a dd invocation does not show its real write target in the command text, so this refuses rather than risk a masked out-of-set write (issue-225 — the on-the-record PR #1627 bypass). Use a provably read-only invocation (e.g. python3 -m pytest), or write through Write/Edit or a plain redirect this gate can read the target of. This is a write-set discipline check, not a security boundary (issue-233 round 5): it denies only shapes it cannot read the write target of, and does not claim to catch a shape deliberately built to hide that target from this text-level read.
```
AFTER (pr382-review):
```
RC=2
STDOUT/STDERR:
board-gate: a Bash call carries an un-analyzable write-capable shape (python3 -c "import sys; sys.stdout.write(1)") while this gate enforces role 'qa''s write-set. A heredoc body, an interpreter -c/-e inline script, or a dd invocation does not show its real write target in the command text, so this refuses rather than risk a masked out-of-set write (issue-225 — the on-the-record PR #1627 bypass). Use a provably read-only invocation (e.g. python3 -m pytest), or write through Write/Edit or a plain redirect this gate can read the target of. This is a write-set discipline check, not a security boundary (issue-233 round 5): it denies only shapes it cannot read the write target of, and does not claim to catch a shape deliberately built to hide that target from this text-level read. The same limit holds on the head side. An interpreter head that bash's own expansion grammar assembles -- brace expansion, ANSI-C quoting, a hex-escaped word, or variable indirection -- is equally outside what this gate claims to catch.
```
acceptance: `bash /tmp/run_gate_check.sh /tmp/wt-pr382/core/hooks/board-gate.sh 'python3 -c "..."'` — result: AFTER's stderr literally contains the new sentence. Verdict: **the new sentence reaches the actual denial text a session receives, not only a source comment.**

Pure-read control probes, both refs, both ALLOW (rc=0, empty stdout/stderr) —
no over-block regression:
```
cat ${HOME}/x          -> BEFORE RC=0, AFTER RC=0
awk '{print}' file     -> BEFORE RC=0, AFTER RC=0
```

### CHECK 3 — Coherence across three texts

All three quoted verbatim from `pr382-review`:

(a) PR #367's flag-side text (`core/hooks/board-gate.sh`, "Jurisdiction limit" comment, unchanged prefix):
> "Jurisdiction limit (issue-233 round 5): this is a write-set discipline check, not a security sandbox. [...] A command built to deliberately hide its own write target from this pre-expansion text read (bash's expansion grammar can rewrite a word into anything) is **outside what this gate claims to bound**; closing that class needs a different seam — the shell's own post-expansion argv — not a longer denylist of spellings here. The threat model this gate holds is a cooperative session drifting out of its lane, not an adversary routing around it."

(b) PR #374's proxy-framing paragraph (`core/hooks/board-gate.sh`, above `UNANALYZABLE_HEAD_RE`, untouched by #382):
> "This scan is a proxy, not a soundness guarantee: it catches the shape only when the head and flag are spelled literally in the command text. A head assembled through bash's expansion grammar defeats it the same way runtime assembly defeats the path scan above. A variable holding a printf-octal-decoded interpreter name is one confirmed shape (issue-361 PR #377). Nothing in this gate catches an expansion-built head. Closing that class is **out of this gate's jurisdiction**, per the limit stated above (issue-233 round 5, PR #367)."

(c) PR #382's new sentence (appended to both (a)'s comment and the deny message):
> "The same limit holds on the head side. An interpreter head that bash's own expansion grammar assembles -- brace expansion, ANSI-C quoting, a hex-escaped word, or variable indirection -- **is equally outside what this gate claims to catch**."

derived: `sed -n '35,52p' /tmp/wt-pr382/core/hooks/board-gate.sh` and
`sed -n '80,101p' /tmp/wt-pr382/core/hooks/board-gate.sh` (worktree of
`pr382-review`), quoted verbatim above.

**Verdict: they agree in substance but not in wording — a real, low-severity
defect.** All three describe the identical limit (an expansion-built shape
is outside the gate's reach), but each uses a different verb phrase for "this
is out of scope": (a) "outside what this gate claims to **bound**", (b) "out
of this gate's **jurisdiction**", (c) "outside what this gate claims to
**catch**". PR #382's own body claims the new sentence "reuses ... 'out of
this gate's jurisdiction' vocabulary" from PR #374 — but the sentence it
actually landed does not use the word "jurisdiction" at all; it coins a
third phrasing ("claims to catch") that matches neither predecessor
verbatim. This does not change behavior and a careful reader can still infer
the three sentences mean the same thing, but it is exactly the kind of
"same limit stated three subtly different ways" pattern the review brief
warned about, and the PR body's specific wording-provenance claim
("reuses ... vocabulary") is not accurate for the word "jurisdiction."

### CHECK 4 — PR #367's own text is byte-identical

`git diff origin/main pr382-review -- core/hooks/board-gate.sh
warrant/hooks/lib/scope-gate.py` (captured in full under "What was done")
shows the paragraph boundary as a single changed line: `# around it.` (main)
becomes `# around it. The same limit holds on the head side. An interpreter
head` (pr382-review) — i.e. the diff *mechanically* marks that line as
changed, because the new sentence is appended on the same source line before
the block re-wraps, not started as a new paragraph after a blank comment
line.

To check whether this is a real edit to PR #367's sentence or a pure
insertion after it, normalized (whitespace-collapsed, comment-marker-stripped)
both paragraphs and compared them programmatically:

```
derived: python3 - <<walk both `git show <ref>:core/hooks/board-gate.sh` line ranges 35-49 (main) / 35-52 (pr), strip
leading '#', join with single spaces, and compare>
MAIN NORM  : "...cooperative session drifting out of its lane, not an adversary routing around it. There is no token machinery: ..."
PR NORM    : "...cooperative session drifting out of its lane, not an adversary routing around it. The same limit holds on the head side. An interpreter head that bash's own expansion grammar assembles -- brace expansion, ANSI-C quoting, a hex-escaped word, or variable indirection -- is equally outside what this gate claims to catch. There is no token machinery: ..."
common prefix length: 771 of 771 chars of MAIN NORM (main_norm is a strict prefix of pr_norm up to the insertion point)
```
The same check was repeated for `warrant/hooks/lib/scope-gate.py` lines
128-140 (main) / 128-144 (pr): common prefix length 608 of 608 chars of MAIN
NORM, again a strict prefix.

Verdict: **confirmed.** Every byte of PR #367's original sentences is present,
unmodified, and in the same order in `pr382-review`; the new sentence is
inserted immediately after PR #367's closing sentence and before the next
existing sentence, not interleaved into or splicing any existing wording.
"Zero bytes changed" is accurate at the content level even though `git diff`
renders the boundary line as one changed line (an artifact of appending text
onto an existing physical line before rewrap, not evidence of an edit).

### Standing invariant 1 — no return of the retired role axis

"The retired role axis" is the `CLAUDE_ROLE`-keyed dispatch/config axis
retired in issue #331 (`git log --all --oneline | grep -iE "retire.*role
axis"` → `71234db`, `1eb781d`, `a657c8e`).

```
git diff origin/main pr382-review -- core/hooks/board-gate.sh core/hooks/tests/run-board-gate-tests.sh \
  warrant/hooks/lib/scope-gate.py core/hooks/tests/run-scope-gate-tests.sh docs/handbooks/board-gate-tests.md \
  | grep -E '^\+' | grep -iE '\brole\b'
```
result: no output, exit 1 — no reintroduction of the role axis in any form.

### Standing invariant 2 — no failing-test-name-set regression

Full suites run from clean `git worktree` checkouts of each ref (not the
working branch):

`bash core/hooks/tests/run-board-gate-tests.sh`:
```
origin/main:   159 passed, 2 failed — FAIL feasibility-spikes, FAIL ops-postmortems
pr382-review:  159 passed, 2 failed — FAIL feasibility-spikes, FAIL ops-postmortems
```
`diff <(sort main-FAIL-names) <(sort pr-FAIL-names)` → empty diff, exit 0.

`bash core/hooks/tests/run-scope-gate-tests.sh`: both refs 62 passed, 0
failed.

`python3 -m pytest -q` (run inside each worktree):
```
origin/main:   3 failed, 79 passed — FAILED test_promoted_hooks.py::test_proposal_shape_gate_refuses_missing_sections,
               FAILED test_promoted_hooks.py::test_survey_order_gate_refuses_proposal_without_survey_or_skip,
               FAILED test_silent_failure_repros.py::test_A5_trailer_gate_quote_split_commit_is_detected
pr382-review:  3 failed, 79 passed — identical three test names
```
Identical failing-test-name sets on all three suites, before and after.
No regression.

### Standing invariant 3 — no overhead increase

No dedicated overhead/benchmark script exists in this repo:
`unverifiable: find <repo> -iname "*overhead*" -o -iname "*benchmark*" —
reason: no matches; there is no repo-provided timing tool for this gate`.
Reused the same ad hoc subprocess-timing probe pattern earlier
adversarial-review records for this issue used (e.g.
`docs/issue-233/reports/adversarial-review-5c3fbc55.md`'s
`/tmp/overhead_probe.py`, 30-call average against a real subprocess):

```
derived: python3 /tmp/overhead_probe.py <gate> — 30-call subprocess average, real board-gate.sh invocation each call
/tmp/wt-main/core/hooks/board-gate.sh:   avg=48.2ms
/tmp/wt-pr382/core/hooks/board-gate.sh:  avg=49.0ms
```
0.8ms difference on a ~48ms subprocess-dominated call is noise (matches the
PR's own claim of "47ms before vs 49ms after ... noise-level"). No code path
was added — only comment/string-literal content grew. No overhead increase.

### Standing invariant 4 — monitor/watch machinery unbroken and not quieter

```
git diff origin/main pr382-review --name-only | grep -iE "on-the-record|monitor|watch"
```
result: no output, exit 1 — neither file touches any monitor/watch-named
path; the two edited files (`core/hooks/board-gate.sh`,
`warrant/hooks/lib/scope-gate.py`) are the only code files in the diff and
neither contains monitor/watch machinery to begin with (same conclusion the
PR body's own "no monitor/watch machinery exists in either edited file"
claim reaches, now independently re-derived rather than trusted).

## Why

Issue #233's own history (11+ prior adversarial-review rounds under
`docs/issue-233/reports/`) shows this lineage repeatedly slipping in two
specific ways: (1) a "wording-only" PR that quietly widens or narrows a
regex/constant while claiming not to, and (2) jurisdiction language that
drifts into a third dialect each time a new PR touches it, eroding the
claim that the wording is a precise, load-bearing contract rather than
decoration. Both of those exact failure modes are what CHECK 1 and CHECK 3
were built to catch, so this review ran both literally rather than trusting
PR #382's own self-report of either.

## Upstream basis

- PR #382 (github.com/tokenmaxxxer/tokenmaxxxer-core/pull/382), fetched as
  `pr382-review` at commit `7c4b39a97c9f6b41c403e295711291aa9c94fb04` (branch
  tip), built on `b6eaa25ea381c7f553c0ad0a0d7232d97eb496a6`, based on
  `origin/main@b129611`. Not `same-commit` — this is an external code ref,
  not a doc path landing in this commit.
- Issue #233 (github.com/tokenmaxxxer/tokenmaxxxer-core/issues/233).
- Prior lineage commits referenced: `b6cb34a` (PR #367, issue-233 round 5),
  `b129611` (PR #374, issue-361), `71234db`/`1eb781d`/`a657c8e` (issue-331,
  role-axis retirement).

## Open findings

1. **Wording-coherence drift (low severity, not blocking).** PR #382's body
   claims the new sentence "reuses ... 'out of this gate's jurisdiction'
   vocabulary" from PR #374, but the landed sentence instead reads "is
   equally outside what this gate claims to catch" — a third distinct verb
   phrase alongside PR #367's "outside what this gate claims to bound" and
   PR #374's "out of this gate's jurisdiction." All three are semantically
   aligned and none is a functional defect, but the PR body's specific
   wording-provenance claim is not accurate, and the pattern itself (three
   near-synonymous phrasings for one contractual limit) is the exact
   "decorative wording" risk this review was asked to watch for.
   Resolution path: a follow-up wording-only PR could normalize all three
   occurrences to one exact phrase (e.g. adopt "out of this gate's
   jurisdiction" everywhere, since that phrase is the one both #374's body
   and #382's body invoke), or none — this is a note for whoever next
   touches this comment block, not a blocker for #382 as-is.

## What did not work

None. All four checks and all four standing invariants completed with
directly-observed command output; nothing was blocked or left unverified
except invariant 3's benchmark-tool search, which is explicitly marked
`unverifiable` above with its reason (no such tool exists in this repo) per
the review brief's instruction not to fabricate a metric.

## Next steps

None — `loop_state: landed`. This record is terminal; no further action is
requested of PR #382 itself (the one open finding above is advisory, not
blocking).
