---
issue: 233
role: adversarial-review-7c59e6b4
author: adversarial-review-7c59e6b4
skills: adversarial-review (skill-repository(c05de12))
verifies_subject: true  # this record is an independent verification of PR #388's own deliverable
loop_state: landed
upstream:
  - path: core/hooks/board-gate.sh
    sha: 555894cf3692908f7b5b5998a62e92cdee50aa2e
  - path: warrant/hooks/lib/scope-gate.py
    sha: 555894cf3692908f7b5b5998a62e92cdee50aa2e
  - path: docs/issue-233/reports/technical-writing-structure-comprehension-f80f29ba.md
    sha: 555894cf3692908f7b5b5998a62e92cdee50aa2e
  - path: docs/issue-233/reports/technical-writing-structure-comprehension-dc23230a.md
    sha: b6eaa25ea381c7f553c0ad0a0d7232d97eb496a6
---

# issue-233 — adversarial-review-7c59e6b4 record

skill-verdict: adversarial-review — applied: invoked; this entire record is the evaluator side of the protocol — a structurally independent session verifying PR #388 (round 9, a deliverable made by a different role session) with no shared context with its builder, gathering evidence via foreground subagents that returned raw command output only (no interpretation baked in) so the judgment below is this session's own.
other mounted skills: not triggered (work-in-english followed as house style but not invoked as a Skill call; verify-finding-record/merge-gates/parallel-decomposition/premortem not applicable — no defect-verification record was requested, no concurrent-landing gate design was needed, no multi-agent build fan-out on shared files, no plan pressure-test)

## What was done

Independently verified PR #388 (`tokenmaxxxer/tokenmaxxxer-core#388`, branch
`issue-233/technical-writing-structure-comprehension-f80f29ba`, single commit
`555894c`) against four checks, and settled its relationship to PR #385.

### 1. #388 vs #385 — superset confirmed, disposition: reduce #385 to docs-only

canonical: `gh pr diff 388` / `gh pr diff 385` (both fetched live, not from
memory) — both PRs touch exactly `core/hooks/board-gate.sh` and
`warrant/hooks/lib/scope-gate.py`, 2 hunks each (a header-comment hunk and a
`deny()`-message hunk).

derived: `diff <(grep -v '^index' 388_board_header.hunk) <(grep -v '^index' 385_board_header.hunk)`
and the same for `scope-gate.py` — both exit 0 (byte-identical), for both files.

derived: line-by-line comparison of the `deny()`-message hunks (both files)
shows the line reading `"...deliberately built to hide that target from
this text-level read."` (board-gate.sh) / the scope-gate.py equivalent
appears in #385's hunk as **unmodified context** (no leading `-`) — #385
appends new sentences after it without rewording it. In #388's hunk, the
same line is **removed and replaced**:
```diff
-         "write target of, and does not claim to catch a shape "
-         "deliberately built to hide that target from this text-level "
-         "read. The same limit holds on the head side. ..."
+         "write target of. A shape deliberately built to hide that "
+         "target from this text-level read is out of this gate's "
+         "jurisdiction. The same limit holds on the head side. ..."
```
This is exactly what PR #388's own description claims: it takes the
flag-side clause PR #387 (already merged, `8c7cc8d`) flagged as still
carrying the old "does not claim to catch a shape..." phrasing, and unifies
it onto the same "out of this gate's jurisdiction" vocabulary #385 already
gave the head-side sentence. Verdict: **CONFIRMED strict superset** — every
code hunk #385 carries is contained in #388 (byte-identical header,
subsumed deny-message wording), and #388 additionally covers the one clause
#387 found #385 left partial. No hunk in #385 is absent from #388.

canonical: `gh pr view 385 --json files` / `gh pr view 388 --json files` —
#385 adds three files under `docs/issue-233/reports/` that #388 does not:
`technical-writing-structure-comprehension-1973359c.md` (+299),
`technical-writing-structure-comprehension-dc23230a.md` (+105), and
`technical-writing-structure-comprehension-dc23230a/2026-08-30-hunt-....md`
(+59). These are three different role sessions' own work records (a widen
attempt, a wording-unify-to-#374 attempt, and a before-landing hunt record)
— none of their content is a duplicate of #388's own single record
(`...-f80f29ba.md`, +166), which documents only #388's own round.

**Disposition**: #385 has no remaining code contribution once #388 lands —
its code hunks are a strict subset. Its three docs/issue-233 records are
real history (distinct role sessions' work) that #388 does not carry and
must not be lost. The correct move is to **reduce #385 to a docs-only PR**
(drop its two code-file hunks, keep its three added report files) and land
it on that basis, rather than closing it outright or merging it as-is
alongside #388 (which would double-apply the header/deny-message hunks and
conflict). This record does not perform that reduction itself — it is
outside this round's write set (issue-233/adversarial-review-7c59e6b4 owns
only this record) — but states the disposition so it isn't lost.

### 2. Live hook-boundary reproduction — reached the intended rule, not a mismatch

The prior two attempts (per the task) hit an R4 branch-mismatch rule once
and a clean allow once — the same self-verification trap this issue has
produced before. To avoid repeating that, the reproduction below (run by a
foreground worker, evidence relayed raw) used the issue's own existing test
fixture rather than a hand-built command, and then isolated every
`UNANALYZABLE_WRITE_SHAPE`-equivalent regex branch against the exact
command string to prove only the intended branch fired.

derived: fixture taken verbatim from `core/hooks/tests/run-scope-gate-tests.sh:236-237`
(`var-indirected-interpreter-head`): `P=python3; $P -c 'open(1)'`, fed to
the real hook boundary — `warrant/hooks/scope-gate.sh` reading JSON from
stdin (`payload="$(cat)"`, confirmed by reading the hook script directly,
not assumed) and invoking `warrant/hooks/lib/scope-gate.py` with
`WARRANT_PAYLOAD` — on PR #388's checked-out branch (commit `555894c`),
with a real `docs/proposals/*.md` proposal file (`status: approved`,
`files: - src/app.py`) so the write-set is actually enforced.

Exit code: `2`. Emitted stderr, verbatim:

```
warrant: refused — this Bash call carries an un-analyzable write-capable shape (a heredoc body, an interpreter -c/-e inline script, or tee/dd) while docs/proposals/2026-08-08-probe.md's write set is enforced. Its real write target is not visible in the command text, so this refuses rather than risk a masked out-of-set write (issue-225). Use a provably read-only invocation (e.g. python3 -m pytest), or write through Write/Edit or a plain redirect the write-set check can read the target of. This is a write-set discipline check, not a security boundary (issue-233 round 5): it denies only shapes it cannot read the write target of. A shape deliberately built to hide that target from this text-level read is out of this gate's jurisdiction. The same limit holds on the head side. An interpreter head that bash's own expansion grammar assembles -- brace expansion, ANSI-C quoting, a hex-escaped word, or variable indirection -- is equally out of this gate's jurisdiction.
```

derived: isolating each alternation branch of the unanalyzable-shape regex
against the literal command string `"P=python3; $P -c 'open(1)'"` (Python
`re.search` per sub-pattern) showed exactly one match: the
VAR-INDIRECTED-python/bash/sh/zsh-HEAD-+-`-c` branch
(`warrant/hooks/lib/scope-gate.py:214-215`,
`r"\b(\w+)=(?:python3?|bash|sh|zsh)\b[^\n]*(?:\$\{\1\}|\$\1\b)[^\n]*-c\b"`).
No other branch (heredoc, tee/dd, fused `$(...)`, perl/ruby/node `-e`,
etc.) matched. The message-emitting call site is
`warrant/hooks/lib/scope-gate.py:368` (`if UNANALYZABLE_WRITE_SHAPE.search(command):`),
message body lines 369–387, `sys.exit(2)` at line 390 — the `%s`
interpolation is `proposal_path`, confirmed present verbatim
(`docs/proposals/2026-08-08-probe.md`) in the stderr above.

**Verdict: the `%` format expression is well-formed and the gate did not
die** — it reached, and correctly fired, the interpreter-head-via-
single-token-expansion + `-c` path specifically, not R4 and not a clean
allow. The reasoning for why the prior two attempts missed (wrong fixture
shape, most likely — this run reused the suite's own fixture instead of
constructing one by hand) is inferential and not independently confirmed
here.

### 3. Wording-only invariant

canonical: `gh pr diff 388 -- core/hooks/board-gate.sh warrant/hooks/lib/scope-gate.py`
— every changed line in both hunks (per file) is inside a Python/bash
string literal (a `deny()`/`print()` argument or a header comment); no
`if`/regex/constant/branch line is touched. This matches PR #388's own
description ("Text-only... no regex, constant, or branch condition
touched") and is independently confirmed by the hunk text itself (§1
above shows the full hunks — every `-`/`+` line is a quoted string
segment).

**Methodological trap avoided**: a `git diff main...pr-388-check` computed
against this working tree's **local** `main` (`450b758`, missing ~20
commits that are already on `origin/main`, including the issue-361/335/336
gate hardening and the `CLAUDE_ROLE`→`CLAUDE_SKILL` rename) showed a
94-file, ~12k-line diff and several real logic/regex changes
(`NONEXECUTING_LIST_HEADS`, `INLINE_FLAG_HEADS` restructuring,
`VAR_INTERP_RE` narrowing, the `role`→`skill` env-var rename, an
un-guarding of the `if DOCS in cmdline:` fast path). None of that is
PR #388's own contribution — it is pre-existing, already-landed-or-in-
flight work from earlier issues (361, 335, 336, 227) and issue #366's
rename that #388's branch is stacked on top of; local `main` was simply
stale relative to `origin/main`. `gh pr diff 388` (computed by GitHub
against the live base, not a stale local ref) is the correct comparison
and is the one cited above. Flagging this because it is exactly the kind
of "hit a different rule/branch" trap the task warned about, one level up
— at the diff-tooling level rather than the hook-invocation level.

derived: test-suite execution comparison (not just diff-reading) between
`pr-388-check` and an `origin/main` worktree —
`bash core/hooks/tests/run-board-gate-tests.sh`: `159 passed, 2 failed` on
both, same two named failures (`feasibility-spikes`, `ops-postmortems`,
both pre-existing and unrelated to this PR);
`bash core/hooks/tests/run-scope-gate-tests.sh`: `62 passed, 0 failed` on
both; `python3 -m pytest core/hooks/test_board_gate.py -q`: `22 passed` on
both. **No allow flipped to deny and no deny flipped to allow** on either
gate's test suite between `pr-388-check` and `origin/main`.

### 4. Retired-role-axis check and #366 coverage gap

derived: `git diff origin/main...pr-388-check -- core/hooks/board-gate.sh warrant/hooks/lib/scope-gate.py | grep -E '^\+[^+]'`
— zero occurrences of `role`/`persona`/`character`/`hat`/`역할` in any line
PR #388 itself adds. **No return of the retired role axis in any reshaped
form within #388's own diff.**

The user's own finding — the live deny message on branch
`issue-233/adversarial-review-7c59e6b4` (and on `origin/main`) still
contains `"Every role output reaches main only through a PR the human
merges"` — is real and reproduced directly:

```
$ grep -n "human merges" core/hooks/board-gate.sh
1056:         "for %s. Every role output reaches main only through a PR the "
1057:         "human merges — never a direct write from another branch. "
```

This is a live `deny()` call (`core/hooks/board-gate.sh:1040-1059`, the
R4/maintenance-targets branch-mismatch check) — delivered to a running
session on an R4 deny, not a comment. It is untouched by both #385 and
#388 (neither PR's diff includes this line).

derived: checked whether issue #366's branches (`git log --all --oneline | grep -i 366` →
commits `99a9640`, `d3adeed`; open PRs #389, #392, #393, #394, all
`state: OPEN`, all `mergeable: MERGEABLE`) fix this exact line, by reading
`core/hooks/board-gate.sh` at that line on each PR's actual branch tip
(not the split-line phrase grep, which misses this because the string is
built from two adjacent Python literals — an exact-phrase grep never
matches it on any branch, including this one):

```
$ for b in issue-366-check-389 issue-366-check-392 issue-366-check-393 issue-366-check-394; do
    git show "$b:core/hooks/board-gate.sh" | grep -n "human merges"
  done
issue-366-check-389:1048: "for %s. Every skill output reaches main only through a PR the "
issue-366-check-392:1048: "for %s. Every role output reaches main only through a PR the "
issue-366-check-393:1048: "for %s. Every role output reaches main only through a PR the "
issue-366-check-394:1048: "for %s. Every skill's output reaches main only through a PR the "
```

**Verdict: #366's sweep DOES cover this specific string — in both of its
code-carrying PRs.** #389 ("issue-366: replace retired 'role' noun with
'skill' in gate denial messages") and #394 ("issue-366: rename retired
'role' noun to 'skill' in gate messages") both rewrite this line to
"skill"/"skill's" (with a minor grammar difference between the two —
"skill output" vs "skill's output" — that is a coordination question for
#366's own reviewers, not a hole). #392 and #393 are independent-
verification PRs of #389 (review records only, no code diff of their own)
built directly on unfixed `main`, so unsurprisingly still show "role" —
that is expected and not evidence of a gap. **No hole found in #366's
coverage of this string.** This check is scoped to the one string the user
found; it is not a full audit of #366's claimed ~179-line population.

## Why

The task asked for independent verification, not trust in either PR's own
description — both PR #388's body and the prior two hook-reproduction
attempts (by others) explicitly warned this issue has a history of
self-verification traps (hitting the wrong rule, or a stale-diff artifact
that looks like a real finding). Every claim above is backed by a command
this session (or its foreground evidence-gathering delegates, consumed
synchronously within this same turn per contract v3 s22) actually ran
against the real branches, not by reading either PR's description as fact.

## What did not work

None — both verification angles (superset/disposition, hook reproduction)
succeeded on the approach described above. The one dead end worth noting:
an initial `git diff main...pr-388-check` (against local, stale `main`)
looked like it disproved the wording-only claim; re-deriving against the
correct base (`gh pr diff 388`, GitHub's own live-base computation) and
confirming with executed test-suite comparisons resolved it. See §3 above.

## Upstream basis

- `core/hooks/board-gate.sh` and `warrant/hooks/lib/scope-gate.py` at
  PR #388's commit `555894cf3692908f7b5b5998a62e92cdee50aa2e`.
- `docs/issue-233/reports/technical-writing-structure-comprehension-f80f29ba.md`
  (PR #388's own record, same commit).
- `docs/issue-233/reports/technical-writing-structure-comprehension-dc23230a.md`
  and sibling files (PR #385, commit `b6eaa25ea381c7f553c0ad0a0d7232d97eb496a6`).
- PR #387 (merged, `8c7cc8d`), the prior adversarial review that found
  #385's jurisdiction wording unification partial — the finding #388
  addresses.
- Issue #366 and PRs #389/#392/#393/#394 (all `OPEN`, `MERGEABLE` at check
  time) for the retired-role-axis coverage check.

## Open findings

1. **#385 disposition is a recommendation, not an action taken.** This
   record states that #385 should be reduced to docs-only and landed that
   way; it does not itself edit #385's branch or open a follow-up PR to do
   so. Resolution path: a human or the next role session on issue-233
   should either push a commit to #385's branch dropping its two code
   hunks, or open a small follow-up PR carrying just its three docs/issue-233
   files, referencing this record.
2. **#366 has two competing/redundant code-fix PRs open concurrently**
   (#389, #394), with a minor grammar difference in the same rewritten
   string. Not a hole in coverage of the specific string this task asked
   about, but worth #366's own reviewers resolving before merge to avoid
   landing both or landing the wrong one. Out of this issue's scope to
   resolve here.
3. **No new adversarial hunt for other single-token-expansion bypasses was
   run in this round.** This task's ask was verification of #388 and its
   relationship to #385 plus four specific standing invariants — not a
   fresh ground-up hunt against the issue's full acceptance criterion 2.
   Prior rounds (per #388's own PR body) already covered that hunt against
   #385's diff; #388's diff is a confirmed strict subset of what that hunt
   covered (§1). No new bypass was found as a side effect of the checks
   run here, but this was not an exhaustive hunt.

## Standing invariants (all four checked live, per the task)

1. **No return of the retired role axis in any reshaped form** — CONFIRMED
   for #388's own diff (§4, zero role-ish tokens in added lines).
2. **No new bug — failing-test set vs origin/main, compared as sets of
   names** — CONFIRMED identical: `bash core/hooks/tests/run-board-gate-tests.sh`
   (159 passed/2 failed, same 2 names both sides), `run-scope-gate-tests.sh`
   (62/0 both sides), `pytest core/hooks/test_board_gate.py` (22/0 both
   sides), top-level `pytest tests/` (3 failed/51 passed, identical 3 names
   both sides: `test_proposal_shape_gate_refuses_missing_sections`,
   `test_survey_order_gate_refuses_proposal_without_survey_or_skip`,
   `test_A5_trailer_gate_quote_split_commit_is_detected`), `pytest test/`
   (6/0 both sides). `comm -3` on the sorted name sets: empty output on
   every suite.
3. **No overhead increase** — no dedicated overhead/benchmark script exists
   in-repo for these two specific files (`grep -rln "overhead"
   --include=*.sh --include=*.py .` → no script hits, only doc prose). The
   one real in-repo timing check, `run-dispatcher-equivalence-tests.sh`
   (exercises the whole PreToolUse dispatcher, not board-gate/scope-gate
   specifically), reported avg 42ms on `pr-388-check` vs 41ms on
   `origin/main` — within noise, not a measured increase. No dedicated
   per-gate benchmark exists to check more precisely than that.
4. **Monitor and watch machinery unbroken and not quieter** — no script
   named for "monitor" or "watch" machinery exists anywhere in this repo
   (`grep -rlni "monitor"` / `"watch"` outside `.git` → hits only in
   `docs/**/*.md` prose, zero `.sh`/`.py` files). Neither `board-gate.sh`
   nor `scope-gate.py` writes to a persistent log or increments a
   persisted counter on either branch. This invariant is vacuously true —
   there is no such machinery under that name to break or quiet.

## Next steps

None — this record is terminal for this round. Follow-ups are captured as
Open findings 1–3 above for whoever picks up issue-233 or issue-366 next.
`loop_state: landed`.
