---
issue: 233
role: adversarial-review-31f68317
author: adversarial-review-31f68317
skills: adversarial-review (skill-repository(c05de12)), work-in-english (skill-repository(c05de12))
verifies_subject: true  # this record is an independent verification of PR #354's deliverable
loop_state: landed
upstream:
  - path: core/hooks/board-gate.sh
    sha: 6e53b5824cc60cee6cb35f2cc5bcc9838d2c1d40
  - path: warrant/hooks/lib/scope-gate.py
    sha: 6e53b5824cc60cee6cb35f2cc5bcc9838d2c1d40
  - path: docs/issue-233/reports/secure-coding-input-validation-injection-defense+adversarial-review-746ed714.md
    sha: 6e53b5824cc60cee6cb35f2cc5bcc9838d2c1d40
---

# issue-233 — adversarial-review-31f68317 record

## What was done

Independently verified core PR #354 (issue #233) — canonical: `gh pr view
354` output (state: OPEN, headRefName
`issue-233/secure-coding-input-validation-injection-defense+adversarial-review-746ed714`,
head `6e53b58`). Two isolated git worktrees were prepared for live testing
(no edits made to either): `/tmp/pr354-review` at PR head `6e53b58`, and
`/tmp/main-review` at the branch's true base `255867b` (current
`origin/main`) — derived: `git worktree add /tmp/pr354-review
origin/issue-233/secure-coding-input-validation-injection-defense+adversarial-review-746ed714`,
`git worktree add /tmp/main-review origin/main`.

Four structurally-independent background evaluator passes (freelunch
workers, blind to each other's reasoning, each given only the technical
attack vector to test and the gates' own invocation contract copied
verbatim from `core/hooks/tests/run-board-gate-tests.sh` /
`run-scope-gate-tests.sh`) were run in parallel against the live gates in
both worktrees:
1. Expansion-syntax hunt: arithmetic expansion, process substitution,
   brace expansion, tilde expansion, quote-splicing.
2. Indirection hunt: shell-function shadowing, PATH manipulation, plus
   live retest of the PR's own two disclosed open findings (quoted `-c`,
   `VAR=value` prefix), plus a backslash-escaped head.
3. Negative controls (own + new: `/home/jwjung/bin/tool`, `grep -e`,
   `$`-bearing awk program, `$`-bearing filename) and full regression —
   failing-test-NAME sets, board-gate/scope-gate/pytest/run-all, PR vs.
   main worktree.
4. Invariants: retired role-axis grep, monitor/watch suite health,
   independent 100×-subprocess overhead re-measurement.

One ambiguous finding from pass 4 (an apparent reintroduction of the
retired `"role"` sidecar key) was resolved by directly simulating the
actual merge — see Open findings below — since a raw two-commit diff is
not equivalent to what a real merge produces. Two of the highest-impact
claimed bypasses (brace expansion, quote-splicing) were independently
re-executed by this session directly, both through the live gate and as
bare shell commands, before being written up here as confirmed.

## Why

The issue's acceptance check 2 ("an adversarial hunt round finds no
remaining single-token-expansion interpreter-head bypass") is the entire
point of this review, and the PR's summary explicitly claims
GENERICITY — a structural "does the head token contain `$`/a backtick"
check instead of enumerating interpreter spellings, on the reasoning that
enumeration is the closed-set shape this program has spent a month
retiring on other axes (issue-2600/issue-2670/issue-349). A claim of
genericity is falsified by a single counter-example, so the review
prioritized actually trying to produce one live, over re-reading the PR's
own already-extensive test suite. Structurally-independent background
workers (per the `adversarial-review` skill's core mechanism: a fresh
context with no stake in the builder's reasoning finds what self-review
structurally cannot) were used instead of this session directly running
every vector serially, both for coverage breadth (4 independent angles in
parallel) and so that no single evaluator's assumptions about "what
counts as a bypass" silently filtered the search.

Considered and rejected: trusting the PR's own before/after
reproduction and hunt-round transcripts as sufficient verification — this
would defeat the purpose of an independent review (the builder session's
"two independent adversarial hunt-round subagents" were still dispatched
and read by the same builder session that wrote the fix, which is exactly
the self-review structure this skill exists to route around).

## Upstream basis

- Issue #233 (this issue) — canonical: `gh issue view 233` output.
- PR #354 — canonical: `gh pr view 354` and `gh pr diff 354` output, head
  commit `6e53b58acb8c2fb9ebbff4cdc22298d90b998f74`.
- `docs/issue-233/reports/secure-coding-input-validation-injection-defense+adversarial-review-746ed714.md`
  (PR #354's own builder-session record) — read in full; sha:
  `6e53b5824cc60cee6cb35f2cc5bcc9838d2c1d40` (PR head).
- `core/hooks/board-gate.sh`, `warrant/hooks/lib/scope-gate.py`,
  `core/hooks/tests/run-board-gate-tests.sh`,
  `core/hooks/tests/run-scope-gate-tests.sh` as they stand at PR head
  `6e53b58`, and the same files at branch base `255867b`
  (`origin/main`), both read in full and exercised live via two worktrees.

## Open findings

**FINDING 1 — CONFIRMED, falsifies the GENERICITY claim: brace expansion
with null-field removal bypasses both gates.**
`{python3,} -c '...'` — bash's brace expansion of `{python3,}` produces
two fields (`python3`, empty); the unquoted empty field is removed by
ordinary word-splitting, collapsing the head to exactly one word,
`python3`, with `-c` as an ordinary second word. The gate's literal
(unexpanded) head token is the 11-character string `"{python3,}"` —
contains no `$`/backtick and does not equal the enumerated literal
`"python3"`, so it matches neither `INTERPRETER_HEADS` nor
`EXPANDED_HEAD_RE` (board-gate), and scope-gate's regex requires
whitespace/start-of-command immediately before `python3`, but `{` sits
there instead. Verified independently by this session, not just cited
from the worker transcript:
```
$ cd /tmp && {python3,} -c 'open("/tmp/notes_direct.txt","w").write("brace-expansion-worked")'
exit=0
$ cat /tmp/notes_direct.txt
brace-expansion-worked
```
derived (board-gate on `/tmp/pr354-review`, real board repo, `CLAUDE_SKILL=qa`):
```
printf '%s' '{"tool_name": "Bash", "tool_input": {"command": "{python3,} -c open(\"notes_qa.txt\",\"w\").write(\"1\")"}, "cwd": "<td>"}' \
  | env CLAUDE_PROJECT_DIR=<td> CLAUDE_PLUGIN_ROOT=/tmp/pr354-review CLAUDE_SKILL=qa /bin/bash /tmp/pr354-review/core/hooks/board-gate.sh
rc=0   # ALLOW
```
This reproduces identically on `/tmp/main-review` (pre-fix) — pre-existing,
not introduced by PR #354, but also **not closed by it**, despite being a
genuine single-token shell-expansion mechanism (brace expansion is a
named form of shell word expansion, exactly the class issue #233's title
names) producing a real, executing, out-of-write-set-analyzable
interpreter head.
Resolution path: not fixed by this review (read-only verification); the
PR should not claim generic closure of "single-token-expansion
interpreter head" until this is addressed too — likely requires real
shell-word tokenization/quote-and-brace-removal at the head-resolution
layer (`gate_head_of`/`_resolve_transparent`, and scope-gate.py's
whole-text regex) rather than another pattern alternative.

**FINDING 2 — CONFIRMED, falsifies the GENERICITY claim: quote-splicing
(adjacent quoted-string concatenation) bypasses both gates.**
`pyt''hon3 -c '...'` / `pyt"hon"3 -c '...'` — bash concatenates adjacent
quoted/unquoted string pieces with no space into a single word
`python3` at parse time. The gate never does shell-aware quote removal:
`gate_head_of` does a plain `.split()` on raw text, so the head token it
actually sees is the literal 10-character string `pyt''hon3` (quote
characters included) — not equal to `"python3"`, contains no
`$`/backtick. scope-gate.py's regex over raw text is fooled the same way.
Live worker evidence (raw shell, outside the gate): both `pwn.md`/`pwn2.md`
targets ended up containing `1`, confirming real `python3 -c` execution.
Reproduces identically pre-fix on `/tmp/main-review` — pre-existing, not
closed by this PR. Same resolution path as Finding 1: this is a shell
word-formation mechanism, not `$`/backtick expansion, and a check keyed
only on `$`/backtick cannot be generic against it.

**FINDING 3 — CONFIRMED, adjacent indirection class (not itself a
single-token-expansion bypass, but the same "unanalyzable write shape
slips through" failure mode): shell-function shadowing and PATH-based
indirection.**
`pywrap() { python3 -c "$1"; }; pywrap '...'` — board-gate ALLOW, head
resolves to the literal, non-enumerated word `pywrap`; live execution
confirmed real. `export PATH=/tmp/evilbin:$PATH; run -c '...'` (a plain
name resolving via `PATH` to a real interpreter/wrapper) — ALLOW on both
gates; live execution confirmed real. Judged **out of this issue's
literal scope** (the head token in both cases genuinely is not an
"interpreter name produced by expansion" — it's a locally-defined name
or a `PATH`-shadowed name the gate has no way to resolve by reading text
alone), consistent with the PR's own framing that this is a text-based
gate. Worth a follow-up issue but not a blocker on issue #233's stated
acceptance criteria.

**FINDING 4 — RE-VERIFIED, PR's own disclosed open finding #1: quoted
`-c` flag on a literal interpreter name.** `python3 '-c' '...'` — ALLOW
on both gates, live execution confirmed real by the worker. Confirmed
genuinely out of issue #233's scope: head resolves correctly to the
literal `python3`; the miss is `INLINE_FLAG_WORDS`/the scope-gate regex
never stripping the surrounding quote characters before comparing to
`-c`/`-e` — a flag-detection bug, not a head-identity bug. Matches the
PR's own stated scoping; agree with the PR's deferral.

**FINDING 5 — RE-VERIFIED, PR's own disclosed open finding #2: a leading
`VAR=value` prefix.** `FOO=1 python3 -c '...'` — board-gate ALLOW
(`gate_head_of` resolves head as the literal `FOO=1`, live execution
confirmed real); scope-gate DENY for real reasons (its whole-text regex
matches `python3` preceded by any whitespace, so a `VAR=` prefix doesn't
hide it there). The PR's scoping judgment (out of issue #233's stated
scope, since the resolved head is a literal non-`$`/backtick string, not
an expansion-produced interpreter name) is defensible and this review
does not overturn it, though it is the closest of the disclosed findings
to the issue's own framing — the underlying problem (`gate_head_of`
returning the wrong word entirely) is the same "gate can't read the true
head" family, just triggered by a missing-assignment-skip rather than an
expansion. Agree with the PR's deferral to a separate issue scoped at
`gate_head_of` itself (shared by board-gate.sh and gh-guard.sh).

**FINDING 6 — RESOLVED FALSE POSITIVE: retired `"role"` sidecar key did
not actually reappear.** A raw two-commit diff (`git diff
255867b..6e53b58 -- core/hooks/board-gate.sh`) shows a hunk where PR #354's
branch still reads `_sidecar.get("role")`/`_sidecar["role"]` where
`origin/main` (255867b, issue-2741) reads `_sidecar.get("skill")`/
`_sidecar["skill"]` with an explicit rename-fallback warning. This is
**not a defect in the PR's diff** — PR #354 forked from `8f95622`, one
commit before `255867b` landed, and never touched that hunk at all (a
raw two-dot diff between two arbitrary commits is not merge-base-aware
and will show every independent change made on the other branch since
divergence, which is exactly what happened here). Confirmed directly by
simulating the actual merge instead of trusting the raw diff:
```
$ git merge-base 255867b 6e53b58
8f9562263f8fe6ae791d3962444d0efcf0aa63de
$ git checkout 255867b && git merge --no-commit --no-ff 6e53b58
자동 병합: core/hooks/board-gate.sh
자동 병합: core/hooks/tests/run-board-gate-tests.sh
자동 병합이 잘 진행되었습니다.
$ grep -n '_sidecar\.get("role"\|_sidecar\.get("skill")' core/hooks/board-gate.sh
920:    if (isinstance(_sidecar, dict) and isinstance(_sidecar.get("skill"), str)
923:        _sidecar_skill = _sidecar["skill"]
$ grep -n '"role":"%s"\|"skill":"%s"' core/hooks/tests/run-board-gate-tests.sh
89:      printf '{"skill":"%s","issue":%s}' ...
```
A real 3-way merge auto-resolves cleanly and correctly keeps `"skill"` in
both the source and the test fixture — issue-2741's fix survives merge
intact. **Verdict: not a regression.** Hygiene note only: PR #354's
branch should be rebased onto current `origin/main` before merging to
avoid carrying a stale base into the merge commit, but this does not
block the issue-233 content and is not a security or correctness defect.

**FINDING 7 — invariant checks that held, independently re-derived (not
just re-stated from the PR):**
- Negative controls: `/home/jwjung/bin/tool --flag ...`, `grep "pattern"
  x.md -e extra`, `awk '{print $1, $2}' x.md`, `cat 'file$with$dollars.md'`,
  `cat "${HOME}/x"`, `awk '{print}' x.md` — all 6 ALLOW on board-gate, no
  over-block regression.
- Full regression: failing-test-NAME sets are identical between
  `/tmp/pr354-review` and `/tmp/main-review` for pytest (3 names:
  `test_proposal_shape_gate_refuses_missing_sections`,
  `test_survey_order_gate_refuses_proposal_without_survey_or_skip`,
  `test_A5_trailer_gate_quote_split_commit_is_detected`), board-gate
  (`feasibility-spikes`, `ops-postmortems`), approval-gate, and
  dispatcher-equivalence — set difference is empty in every case; PR
  #354 adds 14 new passing tests to each of the two gate suites, none
  regressed.
- Monitor/watch machinery: `fleet-silent-failure-scan.sh` output
  byte-identical between worktrees (only tmp-path prefixes differ);
  `run-fleet-scan-tests.sh` 26 passed/1 failed on both (same pre-existing
  flake, same want/got); `run-fleet-scan.sh` live run identical summary
  (`total=44 clean=8 with-findings=36`) and identical per-repo finding
  text on both worktrees — not quieter, not broken.
- Overhead: independent re-measurement (own timing harness, not the
  PR's), 100 invocations × 2 runs × 2 shapes × 2 worktrees, all 8
  averages in the 42.9-51.3ms band; PR354 vs. main delta is ±2-5ms, within
  subprocess/bash-startup noise, consistent with "no measurable
  regression."
- No `CLAUDE_ROLE` occurrences anywhere in the diff; the only genuine
  `"role"`-key hit (Finding 6) is resolved as a non-issue.

## Overall verdict

**Acceptance check 1** (gate tests: the 4 named shapes DENIED, pure
reads ALLOWED, both full suites green) — **PASS**, independently
re-derived.

**Acceptance check 2** (an adversarial hunt round finds no remaining
single-token-expansion interpreter-head bypass) — **FAIL**. Findings 1
and 2 are live, reproducible, single-token shell-expansion mechanisms
(brace expansion, quote-splicing) that produce a real, executing
interpreter head with a confirmed out-of-write-set file write, undetected
by the PR's `$`/backtick structural check, on the PR's own current head
commit. The PR's four specifically-named shapes plus its own two
hunt-round fixes are genuinely closed and correctly verified — but the
"generic, structural, no-enumeration-needed" framing is overstated: the
check is generic across *ways of producing `$`/backtick in the head
text*, not generic across *ways of producing an unresolvable-by-`.split()`
head token*, which is the broader claim the issue's title and the PR's
own rationale comments make ("it does not matter which of countless
possible programs the expansion resolves to"). Recommend: do not merge
as claiming full closure of the class; either scope the claim down to
"`$`/backtick-shaped expansions only" explicitly, or address Findings 1-2
before landing (likely requires real shell tokenization at
`gate_head_of`, not another regex alternative).

No new bug, no overhead increase, monitor/watch machinery intact,
no genuine reintroduction of the retired role axis (Finding 6 resolved).

## Warrant note

Build-now bypass (CORE_BUILD_NOW=1, spawner-set) — proposal round
skipped. Warrant-hunter dispatch skipped at landing: the only touched
path this session writes is this record file, entirely under `docs/`
(DOCS-ONLY FAST PATH).

## Next steps

None — this record is terminal (`loop_state: landed`). Findings 1-2
should be filed as a follow-up issue against the same class if the
maintainer agrees; this session does not open one unprompted (out of
this role's write set).

skill-verdict: adversarial-review — applied: invoked; used as the
structuring mechanism for four structurally-independent background
evaluator passes (each blind to the others' reasoning, none given the
PR's own hunt-round transcripts as ground truth) rather than trusting
the builder session's self-reported hunt rounds.
skill-verdict: work-in-english — applied: invoked; this record, all
worker prompts, and all commands/output are in English; only the final
turn-ending summary to the user is in Korean.
other mounted skills: implementation-audit not triggered — this task
asked for an adversarial security hunt against a specific structural
claim, not a systematic Present/Surface/Absent/Incorrect/Unverifiable
classification of extracted spec claims.
