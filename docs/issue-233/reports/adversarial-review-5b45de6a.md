---
issue: 233
role: adversarial-review-5b45de6a
author: adversarial-review-5b45de6a
skills: adversarial-review (skill-repository(c05de12))
verifies_subject: true
loop_state: landed
upstream:
  - path: core/hooks/board-gate.sh
    sha: de44c51a8de3c9802ee0e67dbdb7bb500e8dca8b
  - path: core/hooks/lib/gate-lib.py
    sha: de44c51a8de3c9802ee0e67dbdb7bb500e8dca8b
  - path: warrant/hooks/lib/scope-gate.py
    sha: de44c51a8de3c9802ee0e67dbdb7bb500e8dca8b
  - path: docs/issue-233/reports/secure-coding-input-validation-injection-defense+adversarial-review-8bab0cf8.md
    sha: de44c51a8de3c9802ee0e67dbdb7bb500e8dca8b
---

# issue-233 — adversarial-review-5b45de6a record

## What was done

Independently verified PR #363 (round 4 on issue-233, branch head
`de44c51`, base `origin/main` = `aff774b`) against `core/hooks/board-gate.sh`,
`core/hooks/lib/gate-lib.py`, and `warrant/hooks/lib/scope-gate.py`. This
round's own claim: a command substitution (`$(...)`/backtick) that
PRODUCES the `-c`/`-e` flag word evaded `INLINE_FLAG_WORDS`, fixed by a
new `UNRESOLVED_SUBSTITUTION_WORD_RE = re.compile(r"\$\(|`")`
(`core/hooks/board-gate.sh:744`, applied at `:770` inside
`_is_unanalyzable_write_shape`).

I set up two clean git worktrees (`origin/main` at `aff774b`, PR head at
`de44c51`, confirmed `main` is an ancestor of the PR branch — a clean
12-commit diff) and built a harness that invokes `board-gate.sh` and
`warrant/hooks/scope-gate.sh` as real subprocesses against a fabricated
board repo (branch `issue-3/qa`, `docs/issue-3/reports/` tree), the same
pattern `run-board-gate-tests.sh`/`run-scope-gate-tests.sh` use, so every
verdict below is a live gate decision, not a regex read.

canonical: `gh pr view 363` (state: OPEN, `Advances #233`, base `main`)

**Round 4's own two fixed shapes re-confirmed, live, both directions:**
```
derived: bash /tmp/wt/probe_board3.sh <worktree> <cmdfile>
cd docs/issue-3 && python3 $(echo -c) open("reports/qa/pwn.md","w").write("1")
  main:  allow   pr363: deny
cd docs/issue-3 && perl `printf %s -e` 'open(FH,">reports/qa/pwn.md");print FH 1'
  main:  allow   pr363: deny
```
Real-shell execution (outside any gate) confirms both mechanisms actually
write attacker-controlled content:
```
derived: cd /tmp/realtest && python3 $(echo -c) 'open("reports/qa/pwn.md","w").write("REAL_WRITE_1")' && cat reports/qa/pwn.md
result: REAL_WRITE_1
derived: perl `printf %s -e` 'open(FH,">reports/qa/pwn.md");print FH "REAL_WRITE_2"' && cat reports/qa/pwn.md
result: REAL_WRITE_2
```

**Attack on the fix itself — the mirror-image gap is only half-closed.**
`UNRESOLVED_SUBSTITUTION_WORD_RE` names exactly two spellings (`$(` and
backtick) instead of mirroring `EXPANDED_HEAD_RE`'s allowlist-complement
structure (`[^A-Za-z0-9_./+=@:-]`, any unsafe character, no enumeration).
The task brief named "parameter-expansion operators" as one shape to try
against this pattern — it is a live bypass, on the identical axis round 4
itself exists to close (the FLAG word produced by a single-token
expansion), just a spelling `$(`/backtick doesn't cover:
```
derived: real bash — x=-c; python3 $x 'open("reports/qa/pwn.md","w").write("REAL_VAR_INDIRECT_FLAG")'; cat reports/qa/pwn.md
result: REAL_VAR_INDIRECT_FLAG   (bare $x, no substitution character at all)

derived: real bash — python3 ${x:--c} 'open("reports/qa/pwn.md","w").write("REAL_PARAM_DEFAULT_FLAG")'; cat reports/qa/pwn.md
result: REAL_PARAM_DEFAULT_FLAG  (single command, no prior assignment needed)

derived: bash /tmp/wt/probe_board3.sh <worktree> <cmdfile>
cd docs/issue-3 && x=-c; python3 $x open("reports/qa/pwn.md","w").write("1")
  main:  allow   pr363: allow   <- NOT fixed by this PR
cd docs/issue-3 && python3 ${x:--c} open("reports/qa/pwn.md","w").write("1")
  main:  allow   pr363: allow   <- NOT fixed by this PR
```
Control confirming the equivalent HEAD-side construct is already denied
(so the asymmetry is real and specific to the flag side):
```
derived: bash /tmp/wt/probe_board3.sh <worktree> <cmdfile>
cd docs/issue-3 && y=python3; $y -c open("reports/qa/pwn.md","w").write("1")
  main:  deny   pr363: deny   (EXPANDED_HEAD_RE already covers bare $y as a head)
```
This is the same class the issue exists to retire, on the same side round
4 patched — not a fifth mechanism on a third axis. `_is_unanalyzable_write_shape`
still only checks `w in INLINE_FLAG_WORDS` (exact match) or
`UNRESOLVED_SUBSTITUTION_WORD_RE.search(w)` (substring `$(`/backtick) —
neither test fires on a trailing word whose only unsafe character is a
bare `$`. Nesting and quoting around a substitution do not additionally
evade (both `EXPANDED_HEAD_RE`/`UNRESOLVED_SUBSTITUTION_WORD_RE` are
unanchored substring searches, so quoting the whole span, as in the
over-refusal case below, does not hide the `$(`); arithmetic expansion
(`$((...))`) is caught (over-broad, see below) because it also starts
with the literal `$(`.

**`warrant/hooks/lib/scope-gate.py` received no equivalent fix at all —
round 4's own named bypass is still open there.** The PR's diff to this
file (`_splice_line_continuations` quote-awareness) is unrelated to the
flag-substitution class; `UNANALYZABLE_WRITE_SHAPE` (`warrant/hooks/lib/scope-gate.py:144`)
was not touched for it. Verified live via the `scope-gate.sh` subprocess
(same board-repo pattern, one approved proposal, `files: [src/app.py]`):
```
derived: bash /tmp/wt/probe_scope.sh <worktree> <cmdfile>
cd docs/issue-3 && python3 $(echo -c) open("reports/qa/pwn.md","w").write("1")   # round 4's OWN fixed case
  main:  allow   pr363: allow   <- still open in scope-gate.py
cd docs/issue-3 && x=-c; python3 $x open("reports/qa/pwn.md","w").write("1")
  main:  allow   pr363: allow
cd docs/issue-3 && python3 ${x:--c} open("reports/qa/pwn.md","w").write("1")
  main:  allow   pr363: allow
sanity control — cd docs/issue-3 && python3 -c open("reports/qa/pwn.md","w").write("1")
  main:  deny   pr363: deny
```
Root cause: `scope-gate.py` has no tokenizer at all — `UNANALYZABLE_WRITE_SHAPE`
requires the literal substring `-c`/`-e` immediately preceded by whitespace
(`\s-[A-Za-z]*[ce](?:\s|=|$)`) somewhere in the raw command text. A
substitution/expansion that PRODUCES that flag at runtime never puts the
literal two-character flag text next to a real whitespace character in
the source, so this class never matched here even before round 4 — round
4 fixed `board-gate.sh` only and did not carry the fix to its sibling
gate, despite touching `scope-gate.py` in the same commit set for an
unrelated finding.

**Over-refusal audit — the accepted cost is broader than the one named
example.** The PR names one cost (`python3 file.py $(date)`, confirmed
denied both branches consistent with the PR's own claim). Tried to find
whether this reads as a narrow, named cost or a de facto "deny anything
with a dollar-paren":
```
derived: bash /tmp/wt/probe_board3.sh <worktree> <cmdfile>
cd docs/issue-3 && python3 script.py --input "$(pwd)/data.csv"
  main:  allow   pr363: deny
cd docs/issue-3 && python3 script.py $((1+1))
  main:  allow   pr363: deny
```
`"$(pwd)/data.csv"`-style interpolation (current directory, a git SHA, a
timestamp, a hostname folded into a script argument) is a very ordinary
shell idiom, not an edge case — quoting the substitution does not exempt
it, since the check is an unanchored substring search over the whole
trailing word. Arithmetic expansion is caught too, incidentally, because
`$((` also contains the literal `$(`. This is a real, non-trivial breadth
increase beyond the PR's single named example: any interpreter invocation
that passes a dynamically-built argument now denies, which is a common
enough pattern that "narrow, accepted cost" undersells it. I judge this
proportionate to keep as-is only if the PR description is read as
accepting that breadth explicitly — as written it names one narrow
example (`$(date)`), which understates what actually gets refused.

**Negative controls (must stay allowed) — reconfirmed:**
```
derived: bash /tmp/wt/probe_board3.sh <worktree> <cmdfile>
echo see docs/issue-3/x.md ; cat "${HOME}/x"        main: allow  pr363: allow
```

## Why

CORE_BUILD_NOW=1 was set by the spawner (build-now bypass, contract v3
s19a) — this session delivers its verification record directly instead of
stopping after a phase-1 proposal. This task is a single coherent
investigative thread where each probe's construction depends on the
verdict of the previous one (e.g., the ownership-rule false deny found
while building the harness had to be diagnosed before the real
substitution-bypass probes were meaningful) — not width>=2 independent
~100-line units — so the freelunch-protocol's fan-out condition does not
apply; this was done solo, consuming repo/env tool calls directly rather
than delegating them to a background worker, consistent with its own
"else solo" branch.

## What did not work

None.

## Upstream basis

- `docs/issue-233/reports/secure-coding-input-validation-injection-defense+adversarial-review-8bab0cf8.md`
  (part of PR #363) — the builder's own record, read for orientation only;
  every load-bearing claim in it (the two fixed shapes DENIED, the named
  false-refusal cost, both suites green modulo pre-existing failures, no
  overhead) was independently re-derived against the real subprocess
  rather than restated.
- `git diff origin/main...pr-363 -- core/hooks/board-gate.sh core/hooks/lib/gate-lib.py warrant/hooks/lib/scope-gate.py`
  — the actual code diff, read in full before constructing any probe.
- Issue #233 (`gh issue view 233`) and PR #363's own description
  (`gh pr view 363`) — acceptance criteria and this round's stated fix
  direction / accepted cost.

## Open findings

1. **BLOCKING — the flag-side fix only covers command substitution, not
   parameter expansion; the identical single-token-expansion mechanism
   round 4 exists to close still bypasses `board-gate.sh` on the flag
   side.** `UNRESOLVED_SUBSTITUTION_WORD_RE = re.compile(r"\$\(|`")`
   (`core/hooks/board-gate.sh:744`) is a two-spelling denylist where
   `EXPANDED_HEAD_RE` (the pattern this fix's own commit message says it
   mirrors) is an allowlist-complement covering every unsafe character
   including a bare `$`. `x=-c; python3 $x '...'` and the single-command
   `python3 ${x:--c} '...'` both real-write a file (`REAL_VAR_INDIRECT_FLAG`,
   `REAL_PARAM_DEFAULT_FLAG` above) and both `allow` through
   `board-gate.sh` on `pr363`, identically to `origin/main` — this PR did
   not move the needle on this specific spelling. Resolution path: widen
   `UNRESOLVED_SUBSTITUTION_WORD_RE` to the same allowlist-complement
   `EXPANDED_HEAD_RE` already uses, applied to each trailing word, rather
   than adding a third named spelling — the same lesson this issue's own
   commit history (round 2, round 3) already drew for the head side.

2. **BLOCKING — `warrant/hooks/lib/scope-gate.py` never received any
   fix for this class; round 4's own named bypass (`$(echo -c)` producing
   the flag) is still `allow` there on both `origin/main` and `pr363`.**
   `UNANALYZABLE_WRITE_SHAPE` (`warrant/hooks/lib/scope-gate.py:144`)
   requires the literal flag text adjacent to real whitespace in the raw
   command; no expansion/substitution-aware check parallel to
   `UNRESOLVED_SUBSTITUTION_WORD_RE` exists in this file at all. This PR
   touches `scope-gate.py` in the same commit set (the line-continuation
   quote-awareness fix) but left this specific, in-scope gap untouched —
   it is not a pre-existing-and-disclosed gap, it is the same gap this
   PR's own stated purpose is to close, just missing from one of the two
   gates the issue is scoped to. Resolution path: add a scope-gate.py
   equivalent of `UNRESOLVED_SUBSTITUTION_WORD_RE`/`EXPANDED_HEAD_RE`'s
   allowlist-complement, scanning the word following a resolved
   interpreter head for any character outside the safe set, mirroring
   what this same PR just did for `board-gate.sh`.

3. **Over-refusal breadth understated in the PR description.** The named
   cost (`python3 file.py $(date)`) is real, but `python3 script.py
   --input "$(pwd)/data.csv"` — an ordinary path-interpolation idiom, and
   arithmetic expansion (`$((1+1))`) also newly deny. Not blocking on its
   own (the issue's fix direction explicitly prioritizes refusing to
   misanalyze over guessing safe), but the PR's "narrow, accepted cost"
   framing should name the breadth (any interpreter call with a
   substitution/arithmetic-expansion argument anywhere, not just one
   contrived example) so the human landing this can judge the tradeoff
   accurately.

4. **Standing invariants** —
   - No return of the retired role axis: `derived: git diff
     origin/main...pr-363 -- core/hooks/board-gate.sh
     core/hooks/lib/gate-lib.py warrant/hooks/lib/scope-gate.py | grep -E
     '^\+' | grep -iE '\brole\b|역할'` — one hit, a comment line
     referring to "a `qa`-role call" (the RBAC role concept in prose, not
     the retired `role` persisted-key/sidecar field issue #2741 retired).
     No code identifier reintroduces the retired axis.
   - No new bug, as failing-test SETS (not counts) vs `origin/main`:
     `derived: bash core/hooks/tests/run-board-gate-tests.sh` — main
     "143 passed, 2 failed" / pr363 "181 passed, 2 failed", identical
     failing names both sides (`feasibility-spikes`, `ops-postmortems`).
     `derived: bash core/hooks/tests/run-scope-gate-tests.sh` — main
     "46 passed, 0 failed" / pr363 "76 passed, 0 failed" (0 failures
     both, not a set comparison but both empty). `derived: python3 -m
     pytest -q` — both branches "3 failed, 79 passed", identical failing
     names both sides (`test_proposal_shape_gate_refuses_missing_sections`,
     `test_survey_order_gate_refuses_proposal_without_survey_or_skip`,
     `test_A5_trailer_gate_quote_split_commit_is_detected`). The higher
     pass counts on `pr363` are entirely this round's own new test cases
     (board-gate +38, scope-gate +30), not existing tests changing
     verdict.
   - No overhead increase: `derived: 50x board-gate.sh subprocess timing`
     (a trivial `echo hi` command, board repo, role qa) — main 5ms/call
     avg, pr363 5ms/call avg, flat.
   - Monitor/watch machinery unbroken, not quieter: `derived: bash
     core/hooks/tests/run-fleet-scan-tests.sh` — both branches
     "pass=26 fail=1", identical.

## Next steps

None from this session — verification is complete (`loop_state: landed`).
**Recommendation to the human reviewing PR #363**: findings 1 and 2 are
both live, real, on-axis bypasses of the exact mechanism this PR claims
to close (single-token-expansion producing the `-c`/`-e` flag word) —
not a new, fifth mechanism on a third axis, but the same round-4 fix
under-scoped in two ways (parameter expansion not covered alongside
command substitution; the sibling gate not touched at all). I would not
treat issue-233 as closed by PR #363 as it stands. Finding 3 is a
proportionality note for the human, not a defect.

skill-verdict: adversarial-review — applied: invoked; used the skill's
core mechanism as this session's own operating structure — a
structurally independent evaluator session (no access to the builder
session's reasoning, receiving only the PR diff and its own record as
artifacts) forming every verdict from a live re-run of the actual
`board-gate.sh`/`scope-gate.sh` subprocess rather than trusting the
builder's stated results, per the skill's Step 2/3 evidence requirement
(every finding above cites a file:line and a reproducible command/output
pair).
skill-verdict: work-in-english — applied: invoked; this record, every
scratch probe file, commit message, and PR body are written in English
per the skill's route (repo-bound exhaust to English); the final
user-facing summary of this turn is written in Korean per the skill's
other half.
</content>
