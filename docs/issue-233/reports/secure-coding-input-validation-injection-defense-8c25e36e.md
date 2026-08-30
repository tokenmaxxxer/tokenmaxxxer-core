---
issue: 233
role: secure-coding-input-validation-injection-defense-8c25e36e
author: secure-coding-input-validation-injection-defense-8c25e36e
skills: secure-coding-input-validation-injection-defense (skill-repository(c05de12))
verifies_subject: false
loop_state: landed
upstream:
  - path: docs/issue-233/reports/adversarial-review-57fd6be9.md
    sha: 580af981f6c98621e9d865eb885019d76e13f81d
  - path: docs/issue-233/reports/adversarial-review-5b45de6a.md
    sha: 11531ffe4fbdf6850be205b4249f98bf4b59a137
code_under_review:
  - core/hooks/board-gate.sh
  - core/hooks/tests/run-board-gate-tests.sh
  - warrant/hooks/lib/scope-gate.py
  - core/hooks/tests/run-scope-gate-tests.sh
type: fix
breaking: "false"
verdict: pass
---

# issue-233 — secure-coding-input-validation-injection-defense-8c25e36e record

## What was done

`CORE_BUILD_NOW=1` was set by the spawner (build-now bypass, contract v3
s19a) — delivered directly, no phase-1 proposal round.

Round 5 reverses the direction of rounds 1-4 per the operator's ruling
comment on issue #233 (`gh issue view 233 --comments`, ruling text
beginning "Operator ruling: (b) — declare the jurisdiction, and shrink the
over-refusal. Not (a), not (c)."). Two changes, both scoped to the
`INTERPRETER_HEADS`/`-c`/`-e` inline-code-flag machinery named in the
issue title — no change to the single-token-expansion bypass class (round
1-4's own axis), no `UNRESOLVED_SUBSTITUTION_WORD_RE`, no PostToolUse
move, all three explicitly ruled out in the round-5 task text:

1. **Jurisdiction limit stated explicitly**, in the two places a reader
   or a session actually sees it: `core/hooks/board-gate.sh`'s own R1-R5
   header (new paragraph right after R5, before "There is no token
   machinery") and its unanalyzable-write-shape deny message; the mirror
   comment block and deny message in `warrant/hooks/lib/scope-gate.py`.
   Both now say plainly that this is a write-set discipline check, not a
   security boundary, and that a shape built to deliberately hide its
   write target from a pre-expansion text read is out of jurisdiction —
   not silently claimed to be caught.

2. **Collateral over-refusal removed**, derived empirically against the
   real gate subprocess rather than guessed. `INLINE_FLAG_WORDS = ("-c",
   "-e")` (`core/hooks/board-gate.sh`) and the equivalent
   `-[A-Za-z]*[ce]` regex alternative (`warrant/hooks/lib/scope-gate.py`)
   applied both flag letters to every name in `python3, python, python2,
   bash, sh, zsh, perl, ruby, node, nodejs` uniformly. That is wrong per
   interpreter, not just broad: bash/sh/zsh's `-e` is the errexit option
   (unrelated to inline code), perl/ruby/node's `-c` means "check syntax,
   do not run" (the opposite of inline execution), and python has no `-e`
   flag at all. Replaced with a per-head allowlist of the one flag
   spelling each interpreter actually uses to mean "execute this string
   as code": `-c` for python/python2/python3/bash/sh/zsh, `-e` for
   perl/ruby/node/nodejs (`INLINE_FLAG_HEADS` dict in board-gate.sh; two
   flag-scoped regex alternatives in scope-gate.py). The var-indirected
   form (`P=bash; $P -c/-e ...`) got the identical split in both files'
   `VAR_INTERP_RE`/`UNANALYZABLE_WRITE_SHAPE`.

Both directions demonstrated live against the real subprocess (temp git
repo, `docs/specs/approvers.md` planted, branch `issue-3/qa`,
`CLAUDE_SKILL=qa`, real stdin JSON payload, real exit code — same harness
`run-board-gate-tests.sh`'s own `run()` uses):

```
derived: python3 /tmp/probe_run.py (harness written this session, board-gate.sh subprocess)
cd docs/issue-3 && bash -c "echo hi > pwn.md"        -> DENY   (the job: stays denied)
cd docs/issue-3 && perl -e "open(1)"                 -> DENY   (the job: stays denied)
cd docs/issue-3 && bash -e reports/script.sh         -> ALLOW  (given back: errexit, not inline)
cd docs/issue-3 && sh -e reports/script.sh           -> ALLOW  (given back: errexit, not inline)
cd docs/issue-3 && perl -c reports/script.pl         -> ALLOW  (given back: syntax-check-only)
cd docs/issue-3 && ruby -c reports/script.rb         -> ALLOW  (given back: syntax-check-only)
cd docs/issue-3 && node -c reports/script.js         -> ALLOW  (given back: syntax-check-only)
cd docs/issue-3 && python3 -e reports/foo.py         -> ALLOW  (given back: not a real python flag)
```
Full sweep (job side across every interpreter alias, given-back set, and a
combined-short-flag regression check `bash -xe`/`bash -ex`) re-run via
`python3 /tmp/probe_hunt.py` with zero MISMATCH lines against the expected
column — the adversarial-hunt round the acceptance criteria asks for.

acceptance: `bash core/hooks/tests/run-board-gate-tests.sh` — result: `155
passed, 2 failed` (the 2 failures, `feasibility-spikes`/`ops-postmortems`,
reproduce identically on `origin/main` with this session's changes
stashed — pre-existing, unrelated to this change; checked:
`git stash && bash core/hooks/tests/run-board-gate-tests.sh 2>&1 | grep
FAIL` on both states prints the same two names).

acceptance: `bash core/hooks/tests/run-scope-gate-tests.sh` — result: `62
passed, 0 failed`, including 4 job-stays-denied cases, 6 given-back-allow
cases, and 4 var-indirected split cases, all new this round.

## Why

The operator's ruling reframes what this gate is for: `core/hooks/
board-gate.sh`'s own header names R1 layout, R2 board opt-in, R3
`CLAUDE_SKILL`, R4 branch, R5 ownership as its rules — board-write
discipline, not a security sandbox. An interpreter call carrying inline
code is denied because the gate cannot determine which files it will
write, not because the command is dangerous. Given that framing, treating
`-e` as inline-code-introducing for bash/sh/zsh (where it means
errexit) or `-c` as inline-code-introducing for perl/ruby/node (where it
means syntax-check-only) served no R1/R4/R5 purpose: those commands are
exactly as analyzable (or not) as the same command without the flag, and
`bash script.sh` with no flag was already allowed. Narrowing to the
flag each interpreter actually uses to mean "run this string" removes
that cost while leaving every real inline-exec invocation denied, which
is what "declare the jurisdiction, and shrink the over-refusal — not the
job" calls for.

A per-head allowlist (rather than patching the denylist regex further)
matches the design the gate already uses on the head side
(`EXPANDED_HEAD_RE`, an allowlist-complement) and the input-validation
skill's own rule 1 (define exactly what IS authorized to carry the
inline-code meaning, rather than trying to enumerate more exceptions to a
broader match) — consulted this round (`skill-verdict` below) to confirm
the shape before landing it.

Alternatives considered and rejected, per the round-5 task's own explicit
list: (a) completing the flag-side symmetry with an
`UNRESOLVED_SUBSTITUTION_WORD_RE`-style allowlist-complement — rejected
by the operator's ruling because it pays ordinary computed-argument
commands (`python3 -m pytest -k "$(...)"`, `python3 script.py --input
"$(pwd)/...")`) to catch something outside this gate's job; (c) a
post-expansion shim / PostToolUse move — rejected as disproportionate
engineering for a threat model (adversarial evasion) this gate was never
built to hold; extending `INLINE_FLAG_WORDS`/`UNRESOLVED_SUBSTITUTION_
WORD_RE` to more spellings — rejected because round 5's task is to
narrow the allow side, not widen the deny side, and doing so would not
address the flag-per-interpreter mismatch this round actually found.

`scope-gate.py` (`warrant/`) received the identical fix for the identical
reason: the issue title scopes this to "board/scope-gate" together, and
`UNANALYZABLE_WRITE_SHAPE`'s `-[A-Za-z]*[ce]` alternative had the exact
same per-interpreter mismatch as `board-gate.sh`'s `INLINE_FLAG_WORDS`,
confirmed by unit-testing the extracted pattern directly in Python before
touching the file (see `derived` line under Open findings).

This was one coherent investigative thread (read the ruling, build a
probe harness, use each probe's result to shape the next one, apply the
same derived fix to both gates, then verify) — not width>=2 independent
~100-line units — so the freelunch-protocol's fan-out condition does not
apply; done solo, consuming repo/env tool calls directly rather than
delegating them to a background worker, consistent with contract v3
s22's override for a headless single-shot session whose results must be
continuously consumed and acted on throughout, not picked up once at the
end.

skill-verdict: secure-coding-input-validation-injection-defense —
applied: invoked; confirmed the per-head `INLINE_FLAG_HEADS`/
flag-scoped-regex mapping is rule-1 allowlist design (define exactly
which flag word IS the inline-code introducer per interpreter) rather
than a denylist grab-bag, and that it does not reopen the job (every
interpreter's actual inline-exec flag still denies).
skill-verdict: work-in-english — not-applicable: this skill's own
mounted description states enforcement is via the core hook, not a
Skill-tool judgment call this session makes; followed as guidance
(English throughout code, tests, commit, this record) without invoking.
other mounted skills: not triggered.

## What did not work

None — the two changes (jurisdiction-limit language, per-head flag
narrowing) landed as scoped in the round-5 task text on the first pass;
every test added for the given-back set and the still-denied set passed
without iteration.

## Upstream basis

- Issue #233 (`gh issue view 233 --comments`) — the operator's escalation
  comment (four live bypasses on the same axis, consult verdict
  recommending a jurisdiction-limit framing) and ruling comment
  ("Operator ruling: (b)...") that this round's scope and constraints
  come from verbatim.
- `docs/issue-233/reports/adversarial-review-57fd6be9.md` (PR #365,
  merged) — Finding 1's live reproduction of `python3 -m pytest
  $(cat reports/failing.txt)`, `bash reports/script.sh $(git rev-parse
  HEAD)`, `node reports/build.js $(pwd)`, and arithmetic-expansion
  denials against PR #363's (unmerged) `UNRESOLVED_SUBSTITUTION_WORD_RE`
  branch — read for orientation on the shape of "computed argument"
  over-refusal; independently re-derived against the actual current
  `origin/main` code (not PR #363's) this round, since PR #363 was never
  merged (`git log --oneline -1 -- core/hooks/board-gate.sh` shows the
  tip commit is round 4's review record, `580af98`, not a code merge).
- `docs/issue-233/reports/adversarial-review-5b45de6a.md` (PR #364,
  merged) — the same `main: allow / pr363: deny` contrast table for
  `python3 script.py --input "$(pwd)/data.csv"` and `$((1+1))`, same
  orientation-only role.
- `core/hooks/board-gate.sh` and `warrant/hooks/lib/scope-gate.py`, read
  in full before constructing any probe or edit.

## Open findings

None blocking. One judgment call made and disclosed rather than
guessed: the ruling text's concrete examples and header quote are all
`board-gate.sh`-specific, and does not name `scope-gate.py` explicitly in
round 5 (only in a prior round's still-open finding about the ANSI-C
bypass, which is the retired axis, not touched here). The issue title
("board/scope-gate: ... should be unanalyzable generically") names both
gates, and the collateral root cause — one flag-letter set applied to
every interpreter name — is structurally identical in both files'
regex/tuple, so the same narrow, mechanical fix was applied to both for
parity rather than left half-fixed in one. Verified the fix is
independently sound before applying it, not merely copied:

```
derived: python3 -c "<inline re-implementation of the split
UNANALYZABLE_WRITE_SHAPE pattern, run against 15 cases>"
15/15 matched expected (job-side ALLOW/DENY and given-back set) — see
this session's tool transcript for the exact script and output.
```

## Next steps

None — `loop_state: landed`. Both suites green
(`run-board-gate-tests.sh`: acceptance above; `run-scope-gate-tests.sh`:
acceptance above), full `pytest -q` failing-test-name set unchanged
against `origin/main` (`test_proposal_shape_gate_refuses_missing_sections`,
`test_survey_order_gate_refuses_proposal_without_survey_or_skip`,
`test_A5_trailer_gate_quote_split_commit_is_detected` — identical set on
both, checked: `git stash && python3 -m pytest -q 2>&1 | tail -8` vs the
same command unstashed), no overhead increase (measured:
`python3 /tmp/probe_overhead.py`, 30-call average, 46.8ms/call on
`origin/main` vs 49.9ms/call with this change — within subprocess-startup
noise, no added python3 invocation or O(n) work), no return of the
retired role axis (checked: `git diff origin/main -- core/hooks/
board-gate.sh warrant/hooks/lib/scope-gate.py core/hooks/tests/
run-board-gate-tests.sh core/hooks/tests/run-scope-gate-tests.sh | grep
-E "^\+" | grep -iE "\brole\b"` — zero added lines mention "role"), and
monitor/watch machinery untouched (checked: `git diff origin/main
--name-only` lists only the four gate/test files above — nothing under
`on-the-record`'s watch/monitor path touched).
