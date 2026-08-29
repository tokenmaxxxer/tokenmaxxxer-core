---
issue: 233
role: adversarial-review-a3668c04
author: adversarial-review-a3668c04
skills: adversarial-review (skill-repository(c05de12))
verifies_subject: true
loop_state: landed
upstream:
  - path: core/hooks/board-gate.sh
    sha: 6e53b58acb8c2fb9ebbff4cdc22298d90b998f74
  - path: warrant/hooks/lib/scope-gate.py
    sha: 6e53b58acb8c2fb9ebbff4cdc22298d90b998f74
  - path: docs/issue-233/reports/secure-coding-input-validation-injection-defense+adversarial-review-746ed714.md
    sha: 6e53b58acb8c2fb9ebbff4cdc22298d90b998f74
---

# issue-233 — adversarial-review-a3668c04 record

## What was done

Independently verified PR #354 (`fix(issue-233): close interpreter-head-via-
expansion + -c/-e generically`, branch head `6e53b58`, base `8f95622`)
against `core/hooks/board-gate.sh` and `warrant/hooks/lib/scope-gate.py`.
Fanned out four independent structurally-blind hunters (per the
`adversarial-review` skill's core mechanism — session separation, each
hunter given only the two source files + `gate-lib.py` and a description of
the mechanism, never the builder's own reasoning about why it's safe) at:
(A) hunting for a structural bypass of the new `$`/backtick-based check
using mechanisms other than the ones the issue named; (B) negative controls
+ full-suite failing-name-set diff against `origin/main`; (C) independently
confirming the two findings the PR defers as out-of-scope; (D) overhead
re-measurement, the role-axis-regression check, monitor/watch machinery,
and a catastrophic-backtracking probe of the new regexes. I then personally
re-reproduced the two most consequential findings (the ReDoS, and the
brace-expansion/quote-adjacency bypass) myself against a byte-identical
copy of `pr-354`'s `board-gate.sh`, rather than trusting the hunters'
transcripts alone — see Test evidence.

canonical: `gh pr view 354` (state: OPEN, `Closes #233`, base `8f95622`)

## Why

CORE_BUILD_NOW=1 was set by the spawner (build-now bypass, contract v3
s19a) — this session delivers its verification record directly instead of
stopping after a phase-1 proposal.

## Upstream basis

- `docs/issue-233/reports/secure-coding-input-validation-injection-defense+adversarial-review-746ed714.md`
  (commit `6e53b58`, part of PR #354) — the builder's own record, read in
  full, including its two hunt-round transcripts and its "Open findings"
  section. Not used as ground truth: every load-bearing claim in it (the
  4 named shapes DENIED, both suites green modulo pre-existing failures,
  no overhead, the two deferred findings' root cause) was independently
  re-derived rather than restated, per this task's own instruction.
- `git diff 8f95622 pr-354 -- core/hooks/board-gate.sh warrant/hooks/lib/scope-gate.py core/hooks/tests/run-board-gate-tests.sh core/hooks/tests/run-scope-gate-tests.sh`
  — the actual code diff, read in full before dispatching hunters.
- Issue #233 (`gh issue view 233`) — acceptance criteria and the 4 named
  bypass shapes from the third adversarial review of PR #228/issue-227.

## Open findings

1. **BLOCKING — new ReDoS in `warrant/hooks/lib/scope-gate.py`'s
   `UNANALYZABLE_WRITE_SHAPE`, introduced by this PR.** The alternative
   added for issue-233 at `warrant/hooks/lib/scope-gate.py` (the first of
   the two new alternatives, immediately following the `$IFS` clause):
   ```
   r"|(?:^|;|&&|\|\||\||\n)\s*\S*[`$]\S*[^\n|;&]*\s-[A-Za-z]*[ce](?:\s|=|$)"
   ```
   stacks three back-to-back unbounded quantifiers over overlapping
   character classes (`\S*`, `\S*`, `[^\n|;&]*`) with a tail
   (`\s-[A-Za-z]*[ce]`) that is frequently absent — the textbook
   catastrophic-backtracking shape. Re-derived independently (not just
   trusting the hunter): `derived: python3 -c "import re,time; pat =
   re.compile(r'(?:^|;|&&|\\|\\||\\||\\n)\\s*\\S*[\`\$]\\S*[^\\n|;&]*\\s-[A-Za-z]*[ce](?:\\s|=|\$)');
   [print(n, (lambda t0: (pat.search('\$'*n), time.perf_counter()-t0))(time.perf_counter())) for n in (50,100,200,400,800)]"`
   — result:
   ```
   50   0.18ms
   100  1.26ms
   200  9.47ms
   400  71.22ms
   800  553.25ms
   ```
   ~7-8x time per doubling of input length — exponential, not polynomial.
   A hunter subagent extended this against the actual compiled regex
   object extracted from the shipped file (`n=1600 -> 4.65s`), extrapolating
   n=5000 to hours. This regex runs on every gated write `scope-gate.py`
   evaluates; a command containing a long run of `$`/backtick characters
   with no resolving `-c`/`-e` tail (plausible from ordinary generated
   shell text — base64 blobs, `awk`/`perl` programs full of `$1..$N`
   field refs, heredoc bodies with many `$VAR` references — not only a
   deliberately adversarial input) hangs the security-enforcement hook
   itself for seconds to (extrapolated) minutes/hours. This is a new,
   serious defect introduced by the same commit that fixes the named
   issue, not a pre-existing gap. Resolution path: rewrite the new
   alternative to avoid the `\S*...\S*...[^\n|;&]*` stacking — e.g. a
   single bounded scan for "does `$`/backtick occur before the next
   `-c`/`-e`-shaped flag within one command-boundary-delimited span,"
   without the extra unbounded groups both fed by the same class of
   character. The sibling "fused" alternative added in the same commit
   (`r"|(?:^|;|&&|\|\||\||\n)\s*\S*[`$]\S*-[A-Za-z]*[ce]\b"`) does NOT
   show this blowup in isolation (clean ~O(n²) at worst, matching
   board-gate.sh's `EXPANDED_HEAD_FUSED_FLAG_RE`) — the defect is
   specific to the first of the two new alternatives.
   `board-gate.sh`'s `EXPANDED_HEAD_FUSED_FLAG_RE` has a milder, ordinary
   quadratic hotspot (`n=5000 -> 25ms`) from the same `\S*...\S*` shape —
   not catastrophic, but worth tightening in the same pass since it's the
   same construction. Given this PR runs on every Bash tool call gated
   by either hook, this alone is grounds not to consider issue-233 safely
   closed by PR #354 as it stands, independent of the genericity question
   below. I have not fixed this myself — this session's role is
   verification, not remediation of the PR under review, and PR #354's
   branch is not this session's write scope.

2. **Genericity claim is broader than what was actually achieved.** The
   PR's own inline comments and description claim the fix means "no
   enumeration needed... it does not matter whether the hidden head is
   python3, bash, or a name this gate has never heard of." Re-derived
   independently: `derived: python3 /tmp/repro_bypass.py` against a
   byte-identical extract of `pr-354`'s `board-gate.sh`
   (`git show pr-354:core/hooks/board-gate.sh`) —
   ```
   brace-expansion-head-flag: ALLOW (rc=0)      # {python3,-c} 'open(1)'
   quote-adjacency-single: ALLOW (rc=0)         # p'y'thon3 -c 'open(1)'
   quote-adjacency-double: ALLOW (rc=0)         # py""thon3 -c 'open(1)'
   control-plain-python3-c: DENY (rc=2)         # python3 -c 'open(1)' (sanity control)
   ```
   A hunter subagent (Unit A) additionally verified these are live,
   working exploits (the target file is actually written with
   attacker-controlled content when the payload runs for real, not just
   a gate-verdict check) and that neither is a regression — both ALLOW
   identically on the pre-fix commit `8f95622`. Brace expansion and
   quote-adjacency splicing are a genuinely different word-formation
   mechanism than the parameter-expansion/command-substitution family the
   issue names ("single-token-expansion" in the strict shell-grammar
   sense covers `${...}`/`$(...)`/backtick substitution, not brace
   expansion or literal quote-adjacent string concatenation, neither of
   which produces a `$`/backtick character in the resulting head token at
   all). So: **acceptance criterion 2, read literally ("no remaining
   single-token-expansion interpreter-head bypass"), is satisfied** — the
   hunters could not construct a variable/array/command-substitution-
   derived head that avoids a literal `$`/backtick anywhere in that token
   (arithmetic expansion and tilde expansion were both separately
   confirmed still DENIED). But the PR's broader prose claim of having
   closed "the interpreter-head masking class" generically, such that no
   future spelling needs a new rule, does not hold — brace expansion and
   quote-splicing are exactly the "next spelling" pattern the issue's own
   fix direction was trying to escape, just from a different shell
   mechanism than the ones enumerated in the issue. Not blocking against
   the literal acceptance criteria as worded, but the record should not
   repeat the "no enumeration ever needed again" framing without this
   caveat. Also separately confirmed (unaffected by any of this, out of
   scope, pre-existing): alias/function name-indirection and PATH-based
   binary shadowing both bypass both gates (neither gate resolves
   aliases/functions/PATH contents from static text, which is a design
   limit of the whole gate-house approach, not something this issue or
   PR claims to fix); and a `-c` invocation embedded as an argument to an
   unrelated head via command/process substitution used purely for its
   side effect (`diff <(python3 -c '...') /dev/null`) is not scanned for
   at all, since the write-shape check only ever inspects the resolved
   head of a segment.

3. **The two deferred out-of-scope findings are real and reproduce live,
   but the scope line is a judgment call, not an obviously correct one.**
   Re-derived independently: `derived: python3 -c "..."` (see script,
   both cases run against the real `board-gate.sh` subprocess via the
   `run-board-gate-tests.sh` harness pattern, board repo, write set
   `docs/issue-3/reports/`) —
   ```
   quoted-c-flag: ALLOW (rc=0)       # python3 '-c' 'open(1)'
   var-assign-prefix: ALLOW (rc=0)   # FOO=1 python3 -c 'open(1)'
   ```
   A hunter subagent (Unit C) traced both root causes by hand against
   `gate-lib.py`'s `_resolve_transparent`/`gate_head_of` (plain
   `segment.split()`, no quote-stripping, and no `VAR=value`-prefix skip)
   and confirmed the builder's stated root cause for both. It also caught
   one factual inaccuracy in the builder's own record: `gate_head_of` is
   called by `board-gate.sh` and `approval-gate.sh`, not `gh-guard.sh` as
   the record states (`gh-guard.sh` uses the separate
   `gate_wrapper_head_before`); and `approval-gate.sh`'s own use of
   `head` is limited to a `READ_ONLY_HEADS` fast-allow path, not
   write-shape enforcement, so the "blast radius beyond this issue's two
   files" argument for deferring finding 2 is real (a second caller
   exists) but weaker in practice than the record states. My own
   independent judgment agrees with the hunter's: the narrow technical
   claim is correct (`head` resolves in both cases to a literal,
   non-expanded string — `"python3"` or `"FOO=1"` — so neither is a
   single-token-expansion bypass, and the enumeration-vs-structure lesson
   this issue's fix embodies genuinely doesn't apply to fixing either
   gap). The deferral is transparently and accurately documented, not
   deceptive. But finding 1 (quoted `-c`) is a small, contained fix at
   the identical call sites this same commit already edits, no different
   in kind from the two hunt-round-1 bypasses that WERE folded into the
   commit rather than deferred — drawing the scope line at "is it
   single-token-expansion" rather than "does it defeat the -c/-e masking
   defense this issue is hardening" reads as anchoring to the acceptance
   criterion's literal wording to declare victory, more than as a
   principled scope boundary. Not blocking, but worth reconsidering
   before treating issue-233 as fully closed.

4. **Standing invariants** —
   - No return of the retired role axis: `derived: git diff 8f95622
     pr-354 -- core/hooks/board-gate.sh warrant/hooks/lib/scope-gate.py
     core/hooks/tests/run-board-gate-tests.sh
     core/hooks/tests/run-scope-gate-tests.sh | grep -inE 'role|ROLE|역할'`
     — 2 hits, both unchanged context lines from a pre-existing R4
     sidecar comment block, not code this PR touches or adds. None found.
   - No new bug, as failing-test SETS (not counts) vs `origin/main`:
     `derived: bash core/hooks/tests/run-board-gate-tests.sh`,
     `run-scope-gate-tests.sh`, `python3 -m pytest -q`, `run-all.sh` on
     pr-354 vs the same on a fresh `origin/main` worktree — identical
     failing-name sets on every suite (board-gate:
     `feasibility-spikes`, `ops-postmortems`; pytest:
     `test_proposal_shape_gate_refuses_missing_sections`,
     `test_survey_order_gate_refuses_proposal_without_survey_or_skip`,
     `test_A5_trailer_gate_quote_split_commit_is_detected`;
     approval-gate: `checkpoint-refusal-names-await-approval`,
     `execute-without-remote`; dispatcher-equivalence:
     `approval-gate: execution write, no approvers.md -> deny`;
     ups-diet: 0 failures both sides once path-length is controlled for
     — an independent hunter caught and corrected a false "regression"
     in this specific check caused by comparing worktrees at different
     absolute path lengths, since `run-ups-diet-tests.sh` embeds
     `CLAUDE_PLUGIN_ROOT_CORE`'s absolute path length into its byte
     budget). **Caveat**: this SET-equality check is exactly the kind of
     check that cannot catch finding 1 above (the ReDoS) — no existing
     test in either suite probes adversarial-length input, so "identical
     failing-name sets" is real evidence of no *regression on the
     existing test surface*, not evidence the new code is defect-free.
   - No overhead increase, on ordinary (non-adversarial) input: `derived:
     100x board-gate.sh subprocess timing`, pr-354 vs pre-fix `8f95622`,
     3 trials each — AFTER avg 49.75ms, BEFORE avg 49.27ms, delta
     +0.48ms, within run-to-run jitter (~3ms observed). The absolute
     ~43-44ms the PR's own description cites doesn't reproduce in this
     environment (this box measures ~47-51ms regardless of before/after
     — environment-dependent baseline, not a regression), but the
     directional "no meaningful overhead increase" claim holds for
     normal commands. It does NOT hold for the adversarial input in
     finding 1: a crafted command hits multi-second-to-unbounded latency
     on the exact same code path, a newly-introduced worst-case overhead
     this "no overhead" testing methodology (fixed representative
     command, 100 identical reps) was never positioned to catch.
   - Monitor/watch machinery unbroken, not quieter: `derived: bash
     core/hooks/tests/fleet-silent-failure-scan.sh`,
     `run-fleet-scan-tests.sh`, `python3 -m pytest -q
     tests/test_silent_failure_repros.py` on pr-354 vs `origin/main` —
     identical finding sets and identical single pre-existing failures
     on both sides (`live fleet run produces 43 repo rows` want=43
     got=44; `test_A5_trailer_gate_quote_split_commit_is_detected`).
     Nothing newly broken, silenced, or skipped.

## Next steps

None from this session — verification is complete (`loop_state: landed`).
**Recommendation to the human reviewing PR #354**: do not treat issue-233
as safely closed by this PR as it stands. Finding 1 (the `scope-gate.py`
ReDoS) is a newly-introduced, serious defect that should block landing
until fixed — it is the standout result of this review. Findings 2 and 3
are not blocking against the issue's literal acceptance criteria but
should inform whether the PR description's "closed generically" framing
and the two deferred findings' scope line are revisited before the issue
is considered done.

skill-verdict: adversarial-review — applied: invoked; used session
separation (four independent, structurally-blind subagent hunters, each
given only the source files and a description of the mechanism under
test, never the builder's own reasoning) as the evaluation engine for
verifying PR #354's genericity and safety claims, per the skill's core
mechanism (self-review is structurally biased; a fresh session is not).
Findings required file:line/exact-command evidence per the skill's Step 2
"evidence requirement," which all four hunters and my own follow-up
reproductions satisfy.
other mounted skills: work-in-english — not triggered (guidance-only via
core hook enforcement; this record and all commits/PR text are in English
regardless); model-routing — not triggered as a separate invocation
(the freelunch-protocol hook already governed this session's delegation
tiering mechanically — STEP 1 tally, fan-out to freelunch-worker
subagents — so there was no separate routing decision left to make);
implementation-audit — not triggered (this task asked for direct
adversarial security verification of specific claims, not the
Present/Surface/Absent/Incorrect/Unverifiable claim-classification
protocol that skill defines).
</content>
