---
issue: 233
role: adversarial-review-e95fc262
author: adversarial-review-e95fc262
skills: adversarial-review (skill-repository(c05de12))
verifies_subject: true  # flip to true only if this record is an independent verification of this subject's own deliverable -- see docs/handbooks/observer-verification.md
loop_state: landed
upstream:
  - path: core/hooks/board-gate.sh
    sha: 45cf53034a5f474695f02241f08624ca0de734b2
  - path: warrant/hooks/lib/scope-gate.py
    sha: 45cf53034a5f474695f02241f08624ca0de734b2
  - path: docs/issue-233/reports/secure-coding-input-validation-injection-defense+adversarial-review-711fc48d.md
    sha: 45cf53034a5f474695f02241f08624ca0de734b2
---

# issue-233 — adversarial-review-e95fc262 record

## What was done

Independently verified PR #358 (`fix(issue-233): close interpreter-head
word-formation bypasses generically`, head `45cf530`, base `b4c5683`, the
delivery that supersedes PR #354 after #354 came back CHANGES) against
`core/hooks/board-gate.sh` and `warrant/hooks/lib/scope-gate.py`. Attacked
the central claim — that the allowlist-complement
`[^A-Za-z0-9_./+=@:-]` is "provably terminal against this whole failure
mode" — from both directions the task specified: (1) hunting for a head
that reaches an interpreter using only characters from the declared safe
set, and (2) hunting for a legitimate command PR #354 allowed that this
PR's allowlist now over-refuses. Also independently re-derived the two
segmenter changes (board-gate.sh's backslash-aware `_split_segments`,
scope-gate.py's `_splice_line_continuations`) and the four standing
invariants, and personally reproduced two of the PR's own claimed pre-fix
bypasses with real command execution.

canonical: `gh pr view 358` (state: OPEN, `Closes #233`, base `main`,
head `45cf530`)

Set up three worktrees for direct, live comparison rather than trusting
any single side's report: `/tmp/pr358-wt` (PR #358 head, `45cf530`),
`/tmp/pr354-wt` (PR #354 head, `6e53b58`, the prior delivery this PR
supersedes), `/tmp/main-wt` (`origin/main`, `be2058f`).

### Direction 1 — hunting a safe-characters-only bypass

Traced `gate_lib._resolve_transparent`/`gate_head_of`
(`core/hooks/lib/gate-lib.py:216-261`): `w = words[0].rsplit("/", 1)[-1]`
strips any path prefix from the head *before* it is compared against
`INTERPRETER_HEADS` or scanned by `EXPANDED_HEAD_RE`. So `./python3`,
`../bin/python3`, `/usr/bin/python3` all resolve to the literal head
`"python3"` and are DENIED the same way a bare `python3` is — confirmed:

```
derived: python3 /tmp/probe_board.py
True   head='python3'            cmd="python3 -c 'x'"
True   head='python3'            cmd="./python3 -c 'x'"
True   head='python3'            cmd="../bin/python3 -c 'x'"
True   head='python3'            cmd="/usr/bin/python3 -c 'x'"
```

Enumerated every bash mechanism that transforms a typed word into a
*different* string (parameter/command/arithmetic expansion, brace
expansion, extglob, tilde expansion, glob expansion) and checked each
one's required syntax characters (`$`, `` ` ``, `{`/`}`, `(`/`)`, `~`,
`*`/`?`/`[`/`]`) against the safe set `[A-Za-z0-9_./+=@:-]` — none of
those characters are in it, so none of those mechanisms can be invoked by
a head built only from safe characters. `+`, `=`, `@`, `:`, `-` have no
shell-level expansion meaning as bare word characters outside those
bracket/paren/dollar forms. Considered and rejected as false leads: a
symlink or PATH-shadowed binary named entirely with safe characters (e.g.
`ln -s python3 x; x -c ...`) does reach an interpreter through a safe-only
name, but this is the *already-disclosed* "PATH-based indirection /
shell-function shadowing" limitation the PR and the issue's own fix
direction explicitly rule out of scope (a text-based gate cannot resolve
what a name points to) — not a new instance of the single-token
word-formation class this issue targets, since no expansion/quoting/
escaping mechanism is doing any masking in that case; the name is exactly
what it appears to be. **Result: no safe-characters-only bypass of the
head-masking class found.** This specific direction of the PR's claim
held up under direct attack.

### Direction 2 — hunting a legitimate command this PR over-refuses that PR #354 allowed

Found one, and it reproduces on both gates. A real filesystem path
containing a space, referenced with an ordinary backslash-escape (the
standard shell idiom, e.g. what bash's own tab-completion inserts) —
`/opt/My\ Python/python3 -c '...'` — is a completely ordinary way to
invoke an interpreter living at a space-containing path. Live bash
execution confirms it runs exactly like `/opt/My Python/python3 -c '...'`
(real symlink, `bash /tmp/repro_space.sh`):

```
derived: bash /tmp/repro_space.sh
ran-as-python3
```

`gate_lib._resolve_transparent` tokenizes with a plain, non-shell-aware
`segment.split()` (`core/hooks/lib/gate-lib.py:230`), which does not
understand the backslash-escape and splits the path at the escaped space,
leaving `head = "My\\"` (ends in a literal backslash). Under PR #354's
narrow `` [`$] `` denylist this fragment matches nothing and is allowed.
Under PR #358's allowlist-complement, a backslash is outside
`[A-Za-z0-9_./+=@:-]`, so `EXPANDED_HEAD_RE.search(head)` now fires and
the whole call is refused as an "un-analyzable write-capable shape" —
even though the write target is the role's own in-set file and the
command is a plain, ordinary interpreter invocation, not an attack:

```
derived: /tmp/run_gate_probe.sh 'cd __D__ && /opt/My\ Python/python3 -c "open(\"reports/qa/pwn.md\",\"w\").write(\"1\")"'
--- PR354 ---
ALLOW (rc=0)

--- PR358 ---
DENY (rc=2)
board-gate: a Bash call carries an un-analyzable write-capable shape (/opt/My\ Python/python3 -c "open(\"reports/qa/pwn.md\",\"w\").write(\"1\")") while this gate enforces role 'qa''s write-set. ...
```

Same regression, same mechanism, in `warrant/hooks/lib/scope-gate.py`
(the shared `[^A-Za-z0-9_./+=@:-]` design was applied to both gates):

```
derived: /tmp/run_scope_probe.sh '/opt/My\ Python/python3 -c "open(\"pwn.md\",\"w\").write(\"1\")"'
--- PR354 ---
ALLOW (rc=0)

--- PR358 ---
DENY (rc=2)
warrant: refused — this Bash call carries an un-analyzable write-capable shape ...
```

This directly contradicts the PR's own false-refusal-cost accounting in
`core/hooks/board-gate.sh` (comment block above `EXPANDED_HEAD_RE`,
`+130..+156` in the PR diff): "this is not a new over-block on any
PREVIOUSLY-ALLOWED interpreter -c/-e invocation, only on ones that were
already falling through unrecognized." The escaped-space path *was*
previously allowed (by PR #354, the PR's own stated baseline) and is now
refused — a genuinely new over-block the PR's own cost analysis claims
does not exist. This is exactly the failure shape issue-233's parent
context warns against (fail-closing out of parsing rather than into it),
just realized as a false DENY instead of a false ALLOW.

### A related, narrower finding: the flag can be masked the same way the head was

Escaping the *flag* word instead of the head with the identical
single-backslash mechanism the PR just closed for the head
(`python3 \-c '...'`) is a live, working, currently-undetected bypass on
both gates, on both PR #354 and PR #358 — unchanged by this PR:

```
derived: bash -c "D=\$(mktemp -d); cd \"\$D\"; python3 \\-c 'open(\"pwn.md\",\"w\").write(\"1\")'; ls \"\$D\"; cat \"\$D/pwn.md\""
pwn.md
1
```

```
derived: /tmp/run_gate_probe.sh 'cd __D__ && python3 \-c "open(\"reports/qa/pwn.md\",\"w\").write(\"1\")"'
--- PR354 ---
ALLOW (rc=0)
--- PR358 ---
ALLOW (rc=0)
```

Root cause: `head in INTERPRETER_HEADS` resolves correctly to `"python3"`
(the escape is on the *next* word, not the head), so `EXPANDED_HEAD_RE`
never even runs; the actual gap is `INLINE_FLAG_WORDS` membership
(`core/hooks/board-gate.sh:725-727`) doing exact string equality against
the raw trailing word `"\\-c"`, which never equals `"-c"`. Same gap in
`warrant/hooks/lib/scope-gate.py`'s `\s-[A-Za-z]*[ce]` alternative, which
requires the hyphen to sit directly after whitespace — the intervening
backslash breaks that adjacency. **This is not a new finding in kind**:
PR #354's own "Out of scope" list already named "Quoted `-c`/`-e` flag on
a literal interpreter name" (`python3 "-c" '...'`) as a disclosed,
accepted residual for the identical reason (a single-token decoration on
the flag word, not the head, defeats exact-match/adjacency checks), and
PR #358 carries that same disclosure forward unchanged. My reproduction
shows the disclosed limitation is broader than the one example given —
backslash-escape works exactly like quoting does — but it does not
contradict the PR's specific "provably terminal against the whole class"
claim, which is explicitly scoped in the code comments to *head*
masking, not flag masking. Not blocking on its own; flagged so the
"Out of scope" line is understood to cover the general mechanism (any
single-token decoration on the flag word), not just the one named
example.

### Segmenter changes

`core/hooks/board-gate.sh`'s `_split_segments` backslash-newline handling
(`core/hooks/board-gate.sh:39-53`) and `warrant/hooks/lib/scope-gate.py`'s
`_splice_line_continuations` (`warrant/hooks/lib/scope-gate.py:307-333`)
both passed their own new tests and my independent reproductions of the
two behaviors they claim: a real backslash-newline splice runs as one
word in bash (reproduced below), and a backslash-newline *inside single
quotes* must NOT be spliced (real bash performs no escape processing
inside single quotes) — verified live:

```
derived: bash -c "printf 'foo t\\\\\\ntee bar\\n'" | cat -A | head -1
foo t\
```
(single-quoted `'foo t\<newline>ee bar'` prints the backslash and newline
untouched in real bash — confirms the PR's own comment at
`warrant/hooks/lib/scope-gate.py:1502-1508` about the single/double-quote
asymmetry; the quote-aware rewrite this PR's commit 4 made is the correct
fix direction for the round-4 warrant-hunter finding it documents.)

### Live reproduction of two of the PR's own claimed pre-fix bypasses

```
derived: bash /tmp/repro_brace.sh   # {python3,} -c 'open("pwn.md","w").write("1")'
pwn.md
```

```
derived: bash /tmp/repro_newline.sh   # pyth\<newline>on3 -c 'open("pwn.md","w").write("1")'
pwn.md
```

Both confirmed to write the marker file for real, matching the PR's own
"confirmed live before being fixed" claim for these two shapes.

### Acceptance criteria — the four named shapes and pure-read negative controls

Ran both full suites against the PR #358 worktree:

```
derived: cd /tmp/pr358-wt && bash core/hooks/tests/run-board-gate-tests.sh 2>&1 | tail -3
== 166 passed, 2 failed ==
derived: cd /tmp/pr358-wt && bash core/hooks/tests/run-scope-gate-tests.sh 2>&1 | tail -3
== 70 passed, 0 failed ==
```
All four named shapes (`${x:-python3} -c`, `${x:=bash} -c`,
`$(echo python3) -c`, prior non-blocking `eval`/`sh -x`) are exercised as
explicit DENY/ALLOW test cases in both suites (see
`core/hooks/tests/run-board-gate-tests.sh:206-311`,
`core/hooks/tests/run-scope-gate-tests.sh:336-431`) and pass. Pure-read
forms named in the issue (`${HOME}/x`, `awk '{print}' file`) are covered
by `param-expansion-path-read-allowed` and
`awk-pure-read-not-overblocked` and pass.

### Standing invariants

- **No return of the retired role/역할 axis**:
```
derived: cd /tmp/pr358-wt && git diff origin/main...HEAD -- core/hooks/board-gate.sh warrant/hooks/lib/scope-gate.py core/hooks/tests/run-board-gate-tests.sh core/hooks/tests/run-scope-gate-tests.sh | grep -n -E '^\+.*(\brole\b|역할)'
```
  zero matches in the four code/test files (10 hits total across the
  whole PR diff, all inside `docs/issue-233/reports/*.md` prose/
  frontmatter `role:` record keys, not the retired persisted-key axis).

- **No new bug, failing-test SETS vs `origin/main`** (names, not counts):
  board-gate: `feasibility-spikes`, `ops-postmortems` — identical on both
  sides. pytest: `test_proposal_shape_gate_refuses_missing_sections`,
  `test_survey_order_gate_refuses_proposal_without_survey_or_skip`,
  `test_A5_trailer_gate_quote_split_commit_is_detected` — identical on
  both sides (`derived: cd /tmp/pr358-wt && python3 -m pytest -q` vs
  `cd /tmp/main-wt && python3 -m pytest -q`, 3 failed/79 passed both).
  `run-approval-gate-tests.sh` (65/2 both), `run-gh-guard-tests.sh`
  (54/0 both), `run-dispatcher-equivalence-tests.sh` (24/1 both,
  identical name), `run-ups-diet-tests.sh` (36/0 both),
  `run-fleet-scan-tests.sh` (26/1 both, identical name `live fleet run
  produces 43 repo rows` want=43 got=44) — every suite's failing-name set
  is identical between PR #358 and a fresh `origin/main` worktree.

- **No overhead increase**: `derived: /tmp/overhead.sh <worktree>`, 100x
  board-gate.sh subprocess timing, 2 trials each —
  PR #358: 11ms, 11ms. `origin/main`: 10ms, 12ms. Within run-to-run
  jitter; no measurable increase.

- **Monitor/watch machinery unbroken, not quieter**: `run-fleet-scan-tests.sh`
  produces the identical pass/fail count (26 passed, 1 failed) and the
  identical single pre-existing-flake failure name on both PR #358 and
  `origin/main` — nothing newly silenced or skipped.

## Why

CORE_BUILD_NOW=1 was set by the spawner (build-now bypass, contract v3
s19a) — this session delivers its verification record directly instead
of stopping after a phase-1 proposal. This record's own change is
docs-only (a single new file under `docs/issue-233/reports/`), so per the
warrant protocol's docs-only fast path the before-landing hunter dispatch
is skipped, and since no proposal was written under the build-now bypass
there is no after-proposal dispatch moment either — noted rather than
silently omitted.

## What did not work

None.

## Upstream basis

- `docs/issue-233/reports/secure-coding-input-validation-injection-defense+adversarial-review-711fc48d.md`
  (same-commit as PR #358's head, `45cf530`) — the builder's own record,
  read in full including its four-commit narrative and its
  false-refusal-cost analysis. Not used as ground truth: every claim
  used above (the four shapes DENIED, both suites green, no overhead, no
  over-block on previously-allowed invocations) was independently
  re-derived against live worktrees rather than restated.
- `git diff b4c5683 45cf530 -- core/hooks/board-gate.sh warrant/hooks/lib/scope-gate.py core/hooks/tests/run-board-gate-tests.sh core/hooks/tests/run-scope-gate-tests.sh` —
  the actual code diff (`gh pr diff 358`), read in full before hunting.
- Issue #233 (`gh issue view 233`) — acceptance criteria and the parent
  context's "fail-closing out of parsing" prohibition.
- PR #354 (`gh pr view 354`, head `6e53b58`) — the prior delivery this PR
  supersedes, used as the "previously allowed" baseline for the
  over-refusal hunt.

## Open findings

1. **BLOCKING — new over-refusal regression on a legitimate, previously-allowed
   command, in both `core/hooks/board-gate.sh` and
   `warrant/hooks/lib/scope-gate.py`.** A backslash-escaped-space real
   filesystem path to an interpreter (`/opt/My\ Python/python3 -c '...'`
   — ordinary shell syntax, confirmed live to execute the interpreter
   normally) was ALLOWED by PR #354 and is DENIED by PR #358, because the
   naive `segment.split()` tokenizer fragments the escaped path and the
   resulting head fragment contains a backslash, which the new
   allowlist-complement treats as unsafe. This directly contradicts the
   PR's own stated false-refusal-cost claim that the widening creates "not
   a new over-block on any PREVIOUSLY-ALLOWED plain interpreter
   invocation." See Direction 2 above for full reproduction on both
   gates. Resolution path: either exempt a lone trailing backslash
   produced by escaped-whitespace fragmentation from the unsafe-character
   scan (recognize the fragmentation artifact rather than the character
   itself), or make the tokenizer backslash-space-aware before the
   character class ever sees the head — same shape as the fix already
   applied for backslash-newline in this same PR. Not fixed by this
   session — this session's role is verification, not remediation, and
   PR #358's branch is not this session's write scope.

2. **Non-blocking — the "provably terminal" claim is correctly scoped to
   head-masking and holds there; a sibling flag-masking gap (already
   partly disclosed) is broader than the one example named.** Direction 1
   found no safe-characters-only bypass of the *head* check — the
   allowlist-complement design is sound against every shell word-formation
   mechanism I could enumerate. But `python3 \-c '...'` (escaping the flag
   word instead of the head) is a live, undetected bypass on both gates,
   unchanged by this PR. PR #354's disclosed "Quoted `-c`/`-e` flag" out-of-
   scope item already names the same underlying gap (a single-token
   decoration on the flag defeats exact-match/adjacency) for the quote
   case; this session's reproduction shows the same gap reachable via
   backslash-escape too, not just quoting. Recommend broadening that
   out-of-scope line's phrasing to name the mechanism (any single-token
   decoration on the flag word) rather than the one example, so a future
   adversarial round doesn't re-report this as new. Not blocking against
   the issue's literal acceptance criteria, which is scoped to
   interpreter-*head* masking.

3. **Standing invariants**: all four (role axis, failing-test-name-set
   parity, overhead, monitor/watch machinery) hold — see Standing
   invariants above for full derivations.

## Next steps

None from this session for the invariant/acceptance-criteria checks —
those are settled (`loop_state: landed`). **Recommendation to whoever
lands or re-reviews PR #358**: finding 1 (the escaped-space-path
over-refusal) is a genuine regression against the issue's own
"pure-read forms still ALLOWED" / "no fail-closing your way out of
parsing" acceptance bar, on a previously-working, ordinary shell idiom —
it should be fixed before this issue is treated as safely closed.
Finding 2 is a documentation/scoping note, not a code blocker.

skill-verdict: adversarial-review — applied: invoked; used the skill's
core mechanism (this session is structurally independent of PR #358's
builder session, has no access to its reasoning, and re-derived every
load-bearing claim — the four DENY shapes, the false-refusal-cost
analysis, both suites' pass counts, the two live-reproduced pre-fix
bypasses — via direct command execution against live worktrees rather
than citing or trusting the builder's own record) as directed by the
skill's Step 5 argument evidence requirement (every finding above cites
an exact file:line and a `derived:` reproduction).
other mounted skills: test-depth-audit — not-applicable: this task is a
security/adversarial review of gate logic, not an audit of an existing
test suite's assertion quality. implementation-audit — not-applicable:
the task explicitly prescribed the adversarial-review protocol directly,
not the two-session claim-extraction-then-classification protocol.
defect-verification-independence-from-upstream-verdicts — not-applicable:
no prior review verdict (e.g. a "Present" classification or closed_checks
entry) is being re-verified here; this is a first-pass independent review
of PR #358 itself. silent-failure-audit — not-applicable: the code under
review is regex/tokenization logic, not try/catch or error-handling
paths. product-discovery-opportunity-solution-tree — not-applicable:
unrelated to opportunity/outcome framing work.
other mounted (not invoked via Skill tool this session, so no
skill-verdict line owed per the invoke-before-apply rule): work-in-english
— its guidance was followed anyway (this record, all commits, and the PR
description are written in English throughout) without a separate Skill
tool call.
