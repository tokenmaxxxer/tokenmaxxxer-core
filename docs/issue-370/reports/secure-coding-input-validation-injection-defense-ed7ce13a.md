---
issue: 370
role: secure-coding-input-validation-injection-defense-ed7ce13a
author: secure-coding-input-validation-injection-defense-ed7ce13a
skills: secure-coding-input-validation-injection-defense (skill-repository(c05de12))
verifies_subject: false  # flip to true only if this record is an independent verification of this subject's own deliverable -- see docs/handbooks/observer-verification.md
loop_state: done
code_under_review: core/hooks/board-gate.sh, core/hooks/lib/gate-lib.py, warrant/hooks/lib/scope-gate.py, core/hooks/tests/run-board-gate-tests.sh, core/hooks/tests/run-scope-gate-tests.sh, docs/handbooks/board-gate-tests.md
type: fix
breaking: false
verdict: delivered
upstream:
  - path: PR #363 (tokenmaxxxer/tokenmaxxxer-core), commits c4a2d16..c31d446
    sha: c4a2d1659389fdccbab05ec3a3536a6dfd7e8429
---

# issue-370 — secure-coding-input-validation-injection-defense-ed7ce13a record

## What was done

Cherry-picked 9 of PR #363's 12 commits onto `origin/main` (`git log
--oneline origin/main..HEAD` — derived: `git log --oneline
origin/main..HEAD | wc -l` — result: `10`, 9 cherry-picks plus 1
integration fix of my own, see below):

```
fdf1492 fix(issue-233): close interpreter-head-via-expansion + -c/-e generically
cc87629 docs(issue-233): note two non-blocking landing-gate advisories
0162234 fix(issue-233): widen expansion check to shell word formation
ce27fa9 fix(issue-233): close backslash-escape and backslash-newline word-formation bypasses
c656a68 issue-233: record for re-delivered word-formation fix
c7ba7fa fix(issue-233): make scope-gate's line-continuation splice quote-aware
387d5c9 issue-233: fold before-landing warrant-hunter finding into record
725173b issue-233: attach before-landing warrant-hunter's raw finding transcript
32176ef issue-233: make gate-lib.py's head tokenizer word-formation-aware
42983e5 issue-370: fix var-indirected over-refusal from combining rounds 1-3 with main's round 5/6 flag give-back
```

Excluded: `d434daa` (the rejected flag-side substitution-matching
commit named by the issue) **and also** `16a652b`
(`docs(issue-233): document round-4 trailing-word command-substitution
fix`) and `de44c51` (`issue-233: round-4 verification record for the
trailing-word command-substitution fix`) — a deviation from the issue
body's literal "exactly one commit is the part that got rejected"
framing; see Rationale below.

- checked: `git diff origin/main..HEAD | grep -c
  UNRESOLVED_SUBSTITUTION_WORD_RE` — result: `0` (d434daa's
  distinguishing symbol appears nowhere in the landed diff, and 16a652b
  /de44c51's own diffs are absent too — derived: `git diff
  origin/main..HEAD --stat | grep -c
  "adversarial-review-8bab0cf8"` — result: `0`)
- checked: `git diff origin/main..HEAD -- core/hooks/board-gate.sh
  warrant/hooks/lib/scope-gate.py | grep -n
  "^+INLINE_FLAG_HEADS\|^+INTERPRETER_HEADS"` — result: empty (no new
  key added to either flag/head table)

Resolved cherry-pick conflicts against `origin/main`'s already-landed
issue-233 round 5/6 work (`INLINE_FLAG_HEADS` per-interpreter give-back,
PR #367) in `fdf1492` (board-gate.sh's `VAR_INTERP_RE`/`EXPANDED_HEAD_RE`
definitions and the `run-scope-gate-tests.sh` round-5/6 test block) and
in `32176ef` (`docs/handbooks/board-gate-tests.md`, folded into a
dedicated "issue-233 rounds 1-3 (salvaged via issue-370)" section rather
than replacing round 5/6's own sections).

Added `docs/handbooks/board-gate-tests.md` documentation for rounds 1-3
(never previously landed, so never previously documented there) per
contract §21's handbook-trigger-gate advisory on `32176ef`'s
test-suite change.

**Integration bug found and fixed (commit `42983e5`, not from PR #363):**
combining rounds 1-3's generic `EXPANDED_HEAD_RE`+blanket-flag closure
with `origin/main`'s already-landed round 5/6 per-interpreter
`INLINE_FLAG_HEADS` give-back silently reopened two of round 5/6's own
tested allows as new denies — `P=bash; $P -e some/script.sh` and
`P=perl; $P -c some/script.pl` (both var-indirected). Neither round's own
PR exercised this combination (round 5/6 postdates rounds 1-4 on
`origin/main`; rounds 1-4 never landed until this session). Fixed in
both `core/hooks/board-gate.sh` and `warrant/hooks/lib/scope-gate.py` by
deferring to the existing, more specific `VAR_INTERP_RE` check whenever
the head is a bare `$NAME`/`${NAME}` reference to a variable with a
literal interpreter-name assignment visible in the same command text;
the blanket check is unchanged when no such assignment is visible.

## Why

The #233 ruling (referenced by the issue) holds that expansion-built
heads and flags are out of this gate's jurisdiction, but reading
literal, unexpanded text correctly is squarely in scope — that is what
rounds 1-3 do (tokenize backslash-escapes, quote spans, and
backslash-newline splices correctly) and what round 4/`d434daa` does not
(it tries to guess what an unresolved `$(...)`/backtick *substitution*
would produce on the flag side, the class #233 explicitly ruled out).

`16a652b` and `de44c51` were excluded alongside `d434daa` — not named by
the issue body, which lists only `d434daa` by hash — because both are
documentation *of* `d434daa`'s own change (their commit messages read
"document round-4 trailing-word command-substitution fix" and "round-4
verification record for the trailing-word command-substitution fix").
Landing them without the code they document would leave handbook/record
prose asserting a fix that is not present in the code, which is a worse
outcome than the "11 of 12" the issue names literally — the deviation
keeps the landed docs consistent with the landed code.

The `42983e5` fix defers to `VAR_INTERP_RE` rather than teaching the
generic `EXPANDED_HEAD_RE` branch a full per-interpreter table of its
own: `VAR_INTERP_RE` already encodes the correct, tested grouping
(including round 6's perl-only-direct-flag scoping), and duplicating
that table in the generic branch was the first attempt at a fix,
verified wrong live (see "What did not work").

**Skill-verdict:** `secure-coding-input-validation-injection-defense` —
applied: invoked; rule 1/2 (allowlist over denylist) already frames the
salvaged commits' own design (`EXPANDED_HEAD_RE`'s allowlist-complement
of safe path/word characters, replacing an earlier denylist of special
characters) and was preserved unchanged; rule 9 (remove/reconcile
duplicate validation layers on the same field) directly informed the
`42983e5` fix — `EXPANDED_HEAD_RE`'s blanket flag check and
`VAR_INTERP_RE`'s per-interpreter check were two independently-arrived-at
validations of the same var-indirected head/flag combination that had
silently drifted apart; the fix makes the generic layer defer to the
specific one instead of keeping both as independently enforced blanket
rules.

## What did not work

My first fix attempt for the `42983e5` regression resolved a bare
`$NAME`/`${NAME}` head to `INLINE_FLAG_HEADS[interpreter]` directly (the
same per-interpreter table `origin/main`'s direct-flag check uses) — this
correctly fixed `P=bash; $P -e ...` but wrongly flipped
`P=perl; $P -c ...` from allow to deny, because `INLINE_FLAG_HEADS["perl"]`
includes `-c` (round 6's *direct*-flag-only fix), while the existing,
already-tested `VAR_INTERP_RE` for the *var-indirected* path was never
extended to match round 6 (disclosed in `run-scope-gate-tests.sh`'s own
comment on `round5-var-indirected-perl-c-allowed` as an accepted,
out-of-scope residual). Caught by re-running `run-scope-gate-tests.sh`
before committing — checked: `env -u CLAUDE_PLUGIN_ROOT_CORE bash
core/hooks/tests/run-scope-gate-tests.sh` — result:
`round5-var-indirected-perl-c-allowed` failed (want=allow, got=deny) on
the first attempt. Replaced with the deferral fix described above, which
does not reimplement any per-interpreter table and cannot drift from
`VAR_INTERP_RE` the same way.

## Upstream basis

- PR #363 (tokenmaxxxer/tokenmaxxxer-core), commits `c4a2d16` through
  `c31d446` (9 of its 12 commits; see exclusion list above) — sha
  `c4a2d1659389fdccbab05ec3a3536a6dfd7e8429` for the first cherry-pick.
- The #233 ruling and issue #370's acceptance criteria (issue body,
  `gh issue view 370`) — canonical: `gh issue view 370 --json
  title,body,comments` output, read in full at the start of this
  session.
- `origin/main`'s already-landed issue-233 round 5/6 work (PR #367,
  `INLINE_FLAG_HEADS`) — canonical: `git show
  origin/main:core/hooks/board-gate.sh` (lines 580-620 at session start).

## Open findings

None outstanding. The `42983e5` integration bug (see above) was found
and fixed within this same session, not left open.

## Next steps

None — `loop_state: done`. This is a phase-2 (CORE_BUILD_NOW=1
build-now bypass) delivery; the PR carries `Closes #370` since the
salvage is complete per the issue's stated scope (PR #367 separately owns
the flag-side give-back/jurisdiction statement, explicitly out of scope
here).

## Acceptance verification (executed-live)

**1. The head-side work lands without `d434daa`.**
- derived: `git diff origin/main..HEAD | grep -c
  UNRESOLVED_SUBSTITUTION_WORD_RE` — result: `0`

**2. The four bypasses those rounds closed are still closed — live
before/after at the real `board-gate.sh`/`scope-gate.py` subprocess
level**, run against `origin/main`'s own gate binaries (checked out at
`/tmp/main-baseline`, commit `8c7cc8d`) as BEFORE and this branch's gate
binaries as AFTER, using the salvaged branch's own test fixtures
(`run-board-gate-tests.sh`/`run-scope-gate-tests.sh`, re-pointed at each
gate binary in turn — a real subprocess invocation both times, not a
unit-level call):

| bypass class | test name | BEFORE (origin/main) | AFTER (this branch) |
|---|---|---|---|
| interpreter-head-via-expansion | `expanded-head-cmdsub-produces-head` | allow (bypassed) | deny |
| interpreter-head-via-expansion | `expanded-head-param-default-dash` | allow (bypassed) | deny |
| backslash-escape word formation | `backslash-escape-spelling` (board-gate), `backslash-escape-spelling` (scope-gate) | allow (bypassed) | deny |
| backslash-newline splicing | `backslash-newline-splice` (board-gate), `backslash-newline-splice` (scope-gate) | allow (bypassed) | deny |
| quoted/escaped-space path | `escaped-space-interpreter-path-c-flag`, `quoted-path-with-spaces-c-flag` (both gates) | allow (bypassed) | deny |

- derived: `env -u CLAUDE_PLUGIN_ROOT_CORE bash
  core/hooks/tests/run-board-gate-tests.sh` (this branch) — result:
  `190 passed, 2 failed` (the 2 pre-existing, see invariant 2 below)
- derived: `env -u CLAUDE_PLUGIN_ROOT_CORE bash
  core/hooks/tests/run-scope-gate-tests.sh` (this branch) — result:
  `92 passed, 0 failed`
- derived (BEFORE, `origin/main`'s gate binary run through this
  branch's own test fixtures with `GATE=`/`PLUGIN_ROOT=`/`CORE_ROOT=`
  repointed at `/tmp/main-baseline`): board-gate `175 passed, 17 failed`
  (17 = the salvaged bypasses, all `want=deny got=allow`); scope-gate
  `79 passed, 13 failed` (13 = the same class, all `want=deny got=allow`)
- **Test-harness trap accounted for (issue #361, per the issue's own
  warning):** `board-gate.sh` exits 0 with no analysis when the raw
  payload has no literal `docs` substring. My first three manual probes
  of this class (before reusing the project's own test fixtures) hit a
  *related* but distinct trap and produced false `rc=0` (allow) results
  even with a `docs` substring present, because my ad hoc fixture was
  missing `CLAUDE_SKILL` and `docs/specs/approvers.md` — without both,
  `board-gate.sh`'s own `if unanalyzable and skill and is_board: deny(...)`
  guard never reaches the deny branch regardless of the analysis result.
  Caught by cross-checking against the project's own
  `run-board-gate-tests.sh` `run()` helper, which sets both; every
  before/after result in the table above and the pass/fail counts
  above were produced through that same, correctly-fixtured helper (or
  a byte-identical copy of it re-pointed at the other gate binary), not
  my ad hoc probes.

**3. No new over-refusal — ordinary commands #363's branch denied, now
allowed, live at the real `board-gate.sh` subprocess level:**
- derived: direct subprocess probe (properly fixtured: `CLAUDE_SKILL=qa`,
  `docs/specs/approvers.md` present, role branch `issue-3/qa`) of:
  `python3 script.py --input "$(pwd)/data.csv"`,
  `python3 -m pytest -k "$(echo foo)"`, `bash -e some/script.sh`,
  `ruby -c some/script.rb`, `node -c some/script.js`,
  `grep "$PATTERN" docs/other.py -e extra`, `cat "${HOME}/x"` — result:
  all 7 `ALLOW`
- derived: `env -u CLAUDE_PLUGIN_ROOT_CORE bash
  core/hooks/tests/run-board-gate-tests.sh` — `round5-pytest-computed-arg`
  and `round5-script-computed-input` both `ok ... allow`
- derived: `env -u CLAUDE_PLUGIN_ROOT_CORE bash
  core/hooks/tests/run-scope-gate-tests.sh` — same two cases both
  `ok ... allow`

## Four standing invariants (executed-live)

**No return of the retired role/역할 axis.**
- derived: `git diff origin/main..HEAD -- core/hooks/board-gate.sh
  warrant/hooks/lib/scope-gate.py core/hooks/lib/gate-lib.py
  core/hooks/tests/ | grep -iE "^\+.*\brole\b|^\+.*역할" | grep -v
  "^+++"` — result: one hit, an English-prose comment referring to "a
  `qa`-role call" (pre-existing terminology describing the write-set
  discipline the gate already enforces), not an identifier or code
  reference to the retired axis.

**No new bug — failing-test set vs `origin/main`, as sets of names.**
- derived: `env -u CLAUDE_PLUGIN_ROOT_CORE bash
  core/hooks/tests/run-board-gate-tests.sh` (both branches) — identical
  failing set `{feasibility-spikes, ops-postmortems}`, `190 passed, 2
  failed` (this branch) vs `159 passed, 2 failed` (`origin/main`)
- derived: `env -u CLAUDE_PLUGIN_ROOT_CORE bash
  core/hooks/tests/run-scope-gate-tests.sh` — `92 passed, 0 failed`
  (this branch) vs `62 passed, 0 failed` (`origin/main`); identical
  (empty) failing set
- derived: `env -u CLAUDE_PLUGIN_ROOT_CORE python3 -m pytest -q` (both
  branches) — identical failing set `{test_proposal_shape_gate_refuses_missing_sections,
  test_survey_order_gate_refuses_proposal_without_survey_or_skip,
  test_A5_trailer_gate_quote_split_commit_is_detected}`, `3 failed, 79
  passed` on both

**No overhead increase.**
- derived: interleaved single-call timing of `git status`
  (fast-path-eligible, alternating branch/main, N=150 each) — `origin/main`
  5.32ms avg, this branch 5.31ms avg per `board-gate.sh` subprocess call
  (within noise; this branch's new checks are pure-Python and run only
  inside the existing python judge, which `git status` never reaches on
  either branch since the shell-level fast path exits first).

**Monitor and watch machinery unbroken and not quieter.**
- derived: `bash core/hooks/tests/run-fleet-scan-tests.sh` — `pass=26
  fail=1` on both this branch and `origin/main`, same failing case
  (`live fleet run produces 43 repo rows`, `want=43 got=44`) and same
  total case count (27) on both — not quieter.

other mounted skills: not triggered (`work-in-english` guidance was
followed by default — all commits/docs/this record are in English —
without a separate invocation; `implementation-audit`,
`verify-finding-record`, and `adversarial-review` are two-session/
independent-evaluator protocols and this is a single-session
build-now delivery per the `CORE_BUILD_NOW=1` bypass, so no
structurally-independent second session exists to run them against).
