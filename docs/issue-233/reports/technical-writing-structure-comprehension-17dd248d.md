---
issue: 233
role: technical-writing-structure-comprehension-17dd248d
author: technical-writing-structure-comprehension-17dd248d
skills: technical-writing-structure-comprehension (skill-repository(c05de12))
verifies_subject: false  # flip to true only if this record is an independent verification of this subject's own deliverable -- see docs/handbooks/observer-verification.md
loop_state: landed
upstream:
  - path: docs/issue-233/reports/adversarial-review-3670bcb4.md
    sha: same-commit  # merged as commit 88eb598 (PR #376) — this branch is cut from that tip; see git log check below
  - path: PR #367 (issue-233: drop perl from -c/-e give-back, re-derive rest by execution (round 6)) — open, unmerged, carries the flag-side jurisdiction wording this record widens to the head side
    sha: 644443ab110e37f004ec2e477e1eddbd4e9fe003
code_under_review:
  - core/hooks/board-gate.sh
  - warrant/hooks/lib/scope-gate.py
type: docs
breaking: "false"
verdict: pass
---

# issue-233 — technical-writing-structure-comprehension-17dd248d record

skill-verdict: technical-writing-structure-comprehension — not-applicable:
wording-only jurisdiction-statement edit, not sentence/paragraph
restructuring for reader load. Checked before writing: the added
paragraphs run 10-13 lines of ~70-column prose, but each sentence lands at
or under the skill's ~15-20-word target already (e.g. "It reads the
command TEXT before the shell runs it, and it catches every write shape
that text states literally" is two independent clauses joined by "and,"
each clause short); there was no long/nested sentence here to split, so
the skill's actual technique (chunk breaks, filler-clause deletion,
sentence splitting) had nothing to apply to. The task is a scope-wording
correction to match an operator ruling, not a readability pass.
other mounted skills: not triggered.

## What was done

Reworded the jurisdiction/scope statement of the board-write-discipline
gate in the two places a session actually reads it, in both files the
issue title names ("board/scope-gate"), per the operator's final ruling
on issue #233 (`gh issue view 233 --comments`, the comment beginning
"Ruling extended: the jurisdiction limit covers the HEAD side too."):

1. **`core/hooks/board-gate.sh`** — added a "Jurisdiction limit
   (issue-233)" paragraph to the R1-R5 header comment (right after R5,
   before "There is no token machinery"), and appended a jurisdiction
   sentence to the `_is_unanalyzable_write_shape` deny message (the
   `deny("a Bash call carries an un-analyzable write-capable shape ...")`
   call, :746-758).
2. **`warrant/hooks/lib/scope-gate.py`** — added the identical-in-substance
   paragraph immediately above `UNANALYZABLE_WRITE_SHAPE = re.compile(...)`
   (:141-155), and appended the matching sentence to `withheld()`'s deny
   print in the `tool == "Bash"` branch (:330-360).

Both additions say the same two things: (a) this is a write-set
discipline check (R1/R4/R5 in board-gate.sh; the one approved proposal's
write-set in scope-gate.py), not a security boundary, and it catches
every write shape the command text states literally — a plain `python3
-c "..."`, a plain heredoc, a plain `dd`; (b) it does not claim to catch a
shape where bash's own expansion grammar produces the interpreter HEAD
(`python3`) or its inline-code FLAG (`-c`/`-e`) instead of the text naming
either directly — brace expansion, ANSI-C quoting, a hex-escaped word,
variable indirection, or any other pre-exec rewrite — because both sides
are the same unbounded grammar a pre-expansion text read cannot bound.

No matching/detection logic changed: `INTERPRETER_HEADS`,
`INLINE_FLAG_WORDS`, `WRITE_UNSAFE_HEADS`, `FUSED_INTERP_RE`,
`VAR_INTERP_RE`, and `UNANALYZABLE_WRITE_SHAPE`'s regex are byte-identical
to `origin/main`. Verified directly:

```
derived: git diff origin/main -- core/hooks/board-gate.sh warrant/hooks/lib/scope-gate.py \
  | grep -E "^[+-]" | grep -v "^+++\|^---" \
  | grep -E "INTERPRETER_HEADS|INLINE_FLAG|WRITE_UNSAFE_HEADS|FUSED_INTERP_RE|VAR_INTERP_RE|UNANALYZABLE_WRITE_SHAPE\s*="
result: (no output) — no line touching any of those six names appears in the diff
```

The two files' actual `git diff` against `origin/main` is 42 insertions,
2 deletions, both files, comment/string text only:

```
core/hooks/board-gate.sh        | 23 ++++++++++++++++++++++-
warrant/hooks/lib/scope-gate.py | 21 ++++++++++++++++++++-
2 files changed, 42 insertions(+), 2 deletions(-)
```

### Before/after: header comment (`core/hooks/board-gate.sh`, inserted after R5)

Before (`origin/main`, nothing existed at this point in the header — the
comment block went straight from R5 to "There is no token machinery"):

```
#   R5  Ownership. Within docs/issue-<n>/reports/, a role writes only its
#       own record (<role>.md), its own subtree (<role>/**), and the
#       per-role extra subtree the contract grants (feasibility: spikes/**,
#       ops: postmortems/**). Foreign-record writes are refused (s11).
#
# There is no token machinery: human approval is a PR merge, feedback is a
# PR comment, refusal is an issue/PR close — GitHub acts, not hook state.
```

After:

```
#   R5  Ownership. Within docs/issue-<n>/reports/, a role writes only its
#       own record (<role>.md), its own subtree (<role>/**), and the
#       per-role extra subtree the contract grants (feasibility: spikes/**,
#       ops: postmortems/**). Foreign-record writes are refused (s11).
#
# Jurisdiction limit (issue-233): this is a write-set discipline check for
# R1/R4/R5, not a security sandbox. It reads the command TEXT before the
# shell runs it, and it catches every write shape that text states
# literally — a plain `python3 -c "..."`, a plain heredoc, a plain `dd`.
# It does not claim to catch a shape where bash's own expansion grammar
# produces the interpreter HEAD (e.g. `python3`) or its inline-code FLAG
# (e.g. `-c`/`-e`) instead of the command text naming either directly —
# brace expansion, ANSI-C quoting, a hex-escaped word, variable
# indirection, or any other rewrite bash performs before exec. Both sides
# are the same unbounded grammar for the same reason: a pre-expansion text
# read cannot compute what bash is about to produce, on the head or on the
# flag, so closing either needs a different seam (the shell's own
# post-expansion argv), not one more spelling added here. The threat model
# this gate holds is a cooperative session drifting out of its lane, not
# an adversary routing around it.
#
# There is no token machinery: human approval is a PR merge, feedback is a
# PR comment, refusal is an issue/PR close — GitHub acts, not hook state.
```

`warrant/hooks/lib/scope-gate.py` received the same-substance paragraph
placed directly above `UNANALYZABLE_WRITE_SHAPE = re.compile(` — see
`git diff` above for the literal text; it is the board-gate.sh paragraph
minus the R1/R4/R5 reference (scope-gate.py has no numbered rule set —
its equivalent is "the one approved proposal's write-set").

### Before/after: deny message, captured at the real subprocess (`core/hooks/board-gate.sh`)

Harness: a temp git repo, `docs/specs/approvers.md` planted (board opt-in),
`CLAUDE_SKILL=implementation`, a real stdin JSON `tool_input` payload for
`cd <board>/docs/issue-9 && python3 -c "import sys; sys.stdout.write(1)"`
— a plain, literal `-c` invocation the gate is supposed to catch — piped
into `core/hooks/board-gate.sh` as an actual `/bin/bash` subprocess (same
invocation shape `core/hooks/tests/run-board-gate-tests.sh`'s own `run()`
uses). Script: `/tmp/probe233.sh`.

BEFORE (`git stash`-ed back to `origin/main`'s board-gate.sh, `derived:
bash /tmp/probe233.sh` against the stashed tree):

```
RC=2
---STDOUT---
---STDERR---
board-gate: a Bash call carries an un-analyzable write-capable shape (python3 -c "import sys; sys.stdout.write(1)") while this gate enforces role 'implementation''s write-set. A heredoc body, an interpreter -c/-e inline script, or a dd invocation does not show its real write target in the command text, so this refuses rather than risk a masked out-of-set write (issue-225 — the on-the-record PR #1627 bypass). Use a provably read-only invocation (e.g. python3 -m pytest), or write through Write/Edit or a plain redirect this gate can read the target of.
```

(This exact text was also hit live, unprompted, during this session: an
early `cat > /tmp/probe233.sh <<'SCRIPT'` heredoc I ran to author the
probe was itself denied by this session's own live `board-gate.sh`
PreToolUse hook with byte-identical wording — switched to the `Write`
tool for that file instead, and kept the heredoc-triggered transcript as
independent confirmation the message is the one actually reachable at
hook-invocation time, not just in a hand-built probe.)

AFTER (`derived: bash /tmp/probe233.sh` against the edited working tree):

```
RC=2
---STDOUT---
---STDERR---
board-gate: a Bash call carries an un-analyzable write-capable shape (python3 -c "import sys; sys.stdout.write(1)") while this gate enforces role 'implementation''s write-set. A heredoc body, an interpreter -c/-e inline script, or a dd invocation does not show its real write target in the command text, so this refuses rather than risk a masked out-of-set write (issue-225 — the on-the-record PR #1627 bypass). Use a provably read-only invocation (e.g. python3 -m pytest), or write through Write/Edit or a plain redirect this gate can read the target of. This is a write-set discipline check, not a security boundary (issue-233): it catches a write shape the command text states literally, and it does not claim to catch a shape where the interpreter head or its flag is itself produced by an expansion rather than named directly in the text.
```

Both are `rc=2` (deny) — the job (a plain, literal `-c` invocation) stays
exactly as denied as before; only the message text grew the jurisdiction
sentence.

## Why

The issue's own ruling history (round 5 → round 6 → round 7/8) closes on
one point relevant here, quoted verbatim from `gh issue view 233
--comments`'s final ruling comment:

> "PR #372: closed, not merged. Its approach cannot be completed and its
> over-refusal cost is already measurable... PR #367 carries the issue. It
> has the jurisdiction statement, the per-head give-back, and the perl
> drop that PR #369's execution-based check earned. Its jurisdiction
> wording must be widened to name the head side explicitly, since it
> currently reads as though only the flag side is out of scope."

`gh pr view 367` confirms it is still `OPEN` (state, checked live this
session) and its jurisdiction paragraph (`gh pr diff 367`) reads, verbatim:
"a command built to deliberately hide its own write target from this
pre-expansion text read (bash's expansion grammar can rewrite a word into
anything) is outside what this gate claims to bound" — grammatically
about "a command," but every worked example around it (`bash -e
script.sh`, `perl -c`, `-c`/`-e` flag give-backs) is flag-side only, which
is exactly the "reads as though only the flag side is out of scope" gap
the ruling names.

`git merge-base --is-ancestor 644443a HEAD` (PR #367's tip) returns
false — none of PR #367's, #372's, or #363's actual code commits are
ancestors of this branch's base (`origin/main`, tip `88eb598`); only the
verification/record PRs (#354→#376, all "adversarial review" record-only
PRs) are merged. So `origin/main`'s `board-gate.sh`/`scope-gate.py`
today carry **no** jurisdiction wording at all, flag-side or head-side —
confirmed: `grep -in jurisdiction core/hooks/board-gate.sh
warrant/hooks/lib/scope-gate.py` on the pre-edit tree returned nothing.
This record's task was scoped narrower than adopting PR #367 wholesale
(no `INLINE_FLAG_HEADS` per-head allowlist, no `VAR_INTERP_RE` split — a
detection-logic change PR #367 also carries and this record was
explicitly told not to touch): it lands only the jurisdiction-statement
wording, corrected up front to name both sides, directly against
`origin/main`, rather than land the flag-only wording first and widen it
in a second pass.

Wording choice: "covers write shapes it can read literally... a head OR a
flag produced by an expansion is outside what it claims to catch" (the
task's own framing) is stated as a scope declaration, not an apology —
matching the ruling's own diagnosis that round 5's error was treating the
head-side allowlist as a real "unanalyzable" check when it "worked only
because interpreter names are a small closed vocabulary." The added text
never says "this is a known bug" or "this will be fixed" — it says what
the gate does catch (a literal invocation) and what it does not (an
expansion-produced head or flag), symmetrically.

## What did not work

None. The wording-only scope (no detection-logic touch) was unambiguous
once the ruling comment and PR #367's actual diff were read in full; no
alternative phrasing was tried and discarded, and no test needed updating
(neither `run-board-gate-tests.sh` nor `run-scope-gate-tests.sh` asserts
the deny message's literal text — confirmed: `grep -n "un-analyzable
write-capable shape\|masked out-of-set write" core/hooks/tests/
run-board-gate-tests.sh core/hooks/tests/run-scope-gate-tests.sh` matched
nothing).

## Upstream basis

- Issue #233, `gh issue view 233 --comments` — the two most recent
  human-authored ruling comments (author `JiwonJung94`, not a `[watch]`/
  bot comment): "Operator ruling: (b) — declare the jurisdiction, and
  shrink the over-refusal..." (round 5) and "Ruling extended: the
  jurisdiction limit covers the HEAD side too. PR #372 is closed unmerged;
  PR #367 is the delivery." (final, this session's mandate).
- `docs/issue-233/reports/adversarial-review-3670bcb4.md` (PR #376,
  merged as `88eb598`, this branch's base) — the round-8 verification
  record whose blocking finding (nested brace expansion, ANSI-C quoting,
  hex-escape, line-continuation, all head-side) is what the final ruling
  comment answers.
- PR #367 (`gh pr view 367`, `gh pr diff 367`) — open, unmerged; read in
  full for its flag-side jurisdiction wording (`sha:
  644443ab110e37f004ec2e477e1eddbd4e9fe003`) to confirm exactly what needs
  widening, without adopting its bundled `INLINE_FLAG_HEADS` detection
  change.
- `core/hooks/board-gate.sh` and `warrant/hooks/lib/scope-gate.py`, read
  in full before editing.

## Open findings

None blocking. PR #367 itself (jurisdiction wording plus the per-head
flag-allowlist narrowing) remains open and unmerged after this record;
this delivery does not close or supersede it, and does not implement
issue #233's full generic-unanalyzability acceptance criteria (the
expansion-grammar bypass class stays open by design, per every ruling
in this issue's history) — the PR opened from this record says so via
`Advances #233`, not `Closes`.

## Next steps

None blocking; `loop_state: landed`. Four standing invariants checked:

**(a) No return of the retired "role axis".** The retired axis (`git log
--all --oneline | grep -i "role axis"`: `71234db` "retire the role axis
from ordering-gate.sh dispatch table", `1eb781d`/`a657c8e` "retire the
role axis from citation/facet-keyword config gates") is role-**keyed
dispatch/config logic** — a closed-set-of-role-names table selecting
per-role behavior — in `ordering-gate.sh`, `citation-gate.sh`, and
`facet-keyword-gate.sh`, plus a later-found stray instance in
`record-fields-gate.sh` (its own comment, :162-168: "a role-name-keyed
dict used to sit here... role-axis removal (issue-331) left it live by
accident. Removed per operator ruling (2026-08-27, issue-341)"). Neither
`board-gate.sh` nor `scope-gate.py` is in that retirement's file list, and
this record's diff adds zero role-conditional branches (checked: `derived:
git diff origin/main -- core/hooks/board-gate.sh
warrant/hooks/lib/scope-gate.py | grep -E "^\+" | grep -iE "\brole\b"`,
result: no output — no added line mentions "role" at all, even in prose).
The pre-existing, unedited-by-this-record use of "role" as an ordinary
English noun ("a role session", "role's own record") throughout
`board-gate.sh`'s R1-R5 header is untouched by this diff and was never
part of the retired axis (that retirement targeted identifiers
`CLAUDE_ROLE`/`role.json`'s `role` key and per-role dispatch tables, not
the English word) — confirmed by `git blame`-adjacent history:
`60cbcb5`/`8f95622`/`255867b` already did that identifier rename in this
same file before this record's base commit.

**(b) No new bug — failing-test-name set unchanged.**

```
derived: python3 -m pytest -q   (run on origin/main state, via git stash)
result: 3 failed, 79 passed —
  tests/test_promoted_hooks.py::test_proposal_shape_gate_refuses_missing_sections
  tests/test_promoted_hooks.py::test_survey_order_gate_refuses_proposal_without_survey_or_skip
  tests/test_silent_failure_repros.py::test_A5_trailer_gate_quote_split_commit_is_detected

derived: python3 -m pytest -q   (run on this record's edited tree)
result: 3 failed, 79 passed — identical three names, same order

derived: diff <(sort before-FAILED.txt) <(sort after-FAILED.txt)
result: (no output) — the two failing-test-name sets are identical as sets
```

`bash core/hooks/tests/run-board-gate-tests.sh`: `143 passed, 2 failed`
before and after, same two names both times (`feasibility-spikes`,
`ops-postmortems`, both pre-existing `want=allow got=deny` — unrelated to
this comment/message-only change). `bash core/hooks/tests/
run-scope-gate-tests.sh`: `46 passed, 0 failed` before and after,
unchanged.

**(c) No overhead increase.**

```
derived: python3 /tmp/probe_overhead.py   (30-call average, real
  board-gate.sh subprocess, real stdin JSON, a literal `python3 -c`
  job that stays denied both times)
BEFORE (git stash — origin/main board-gate.sh): N=30 avg=47.10ms min=35.52ms max=65.58ms
AFTER  (this record's edited board-gate.sh):    N=30 avg=45.90ms min=37.12ms max=61.65ms
```

The after-average is lower than before, well within the ~30ms
subprocess/`python3`-startup spread visible between min and max on either
side — a comment/string-only change adds no new code path, no new regex
compile, and no new `python3` invocation, so no regression is expected or
measured.

**(d) Monitor/watch machinery: none exists for this gate in this repo.**
Checked exhaustively before concluding "not applicable" rather than
assuming it:

```
derived: find . -iname "*watch*" -not -path "*/.git/*"
result: (no output)

derived: find . -iname "*monitor*" -not -path "*/.git/*"
result: (no output)

derived: grep -rln "watch" --include="*.sh" --include="*.py" . | grep -v node_modules
result: (no output)
```

No file, script, or code reference matching "watch" or "monitor" exists
anywhere in this repository (the `[watch] issue-233/...` lines visible in
`gh issue view 233 --comments` are posted by `on-the-record`, a separate
plugin/tool this repo does not vendor — not machinery this repo's own
test suite runs or could regress). There is nothing to run before/after,
and nothing to make quieter.
