---
issue: 233
role: adversarial-review-5c3fbc55
author: adversarial-review-5c3fbc55
skills: adversarial-review (skill-repository(c05de12))
verifies_subject: true  # flip to true only if this record is an independent verification of this subject's own deliverable -- see docs/handbooks/observer-verification.md
loop_state: landed
upstream:
  - path: core/hooks/board-gate.sh
    sha: c2f8b3f42de88b39c33a697b20d5af91cfc47dfd
  - path: warrant/hooks/lib/scope-gate.py
    sha: c2f8b3f42de88b39c33a697b20d5af91cfc47dfd
  - path: core/hooks/tests/run-board-gate-tests.sh
    sha: c2f8b3f42de88b39c33a697b20d5af91cfc47dfd
  - path: core/hooks/tests/run-scope-gate-tests.sh
    sha: c2f8b3f42de88b39c33a697b20d5af91cfc47dfd
---

# issue-233 — adversarial-review-5c3fbc55 record

## What was done

Independent adversarial verification (round 5 on issue-233) of PR #367
(`issue-233/secure-coding-input-validation-injection-defense-8c25e36e`,
head `c2f8b3f42de88b39c33a697b20d5af91cfc47dfd`). Round 5 reverses the
direction of rounds 1-4: per the operator's ruling comment on issue #233
("Operator ruling: (b) — declare the jurisdiction, and shrink the
over-refusal. Not (a), not (c)."), this gate is write-set discipline
(R1/R4/R5), not a security sandbox, so the round states that limit
honestly and gives back legitimate commands rather than chasing the
single-token-expansion bypass class rounds 1-4 tracked. PR #367 narrows
`core/hooks/board-gate.sh`'s `INLINE_FLAG_WORDS = ("-c", "-e")` (applied
uniformly to every name in `INTERPRETER_HEADS`) and
`warrant/hooks/lib/scope-gate.py`'s equivalent `-[A-Za-z]*[ce]` regex
alternative to a per-head allowlist (`-c` for
python/python2/python3/bash/sh/zsh, `-e` for perl/ruby/node/nodejs), and
adds a jurisdiction-limit paragraph to both files' header comment and
deny message.

Re-derived independently against a real subprocess rather than restating
the PR's own record. Method (`git worktree add`, not a merge into this
branch — this branch's own tree stays untouched, `core/hooks/board-gate.sh`
here is still the pre-round-5 `main` copy):

```
git fetch origin pull/367/head:pr367-check
git worktree add /tmp/pr367_check pr367-check   # PR #367 head, c2f8b3f
git worktree add /tmp/main_check origin/main    # origin/main, 580af98
```

**Fast-path accounted for.** `board-gate.sh:80-83` (`case "$payload" in
*'\u'*) ;; *docs*) ;; *) trap - EXIT; exit 0 ;; esac`) exits 0 without any
analysis when the JSON payload has no literal `docs` substring — the
exact mistake flagged as a live risk for this round. Every payload below
routes the tested command through a `docs/issue-3/...` path (`cd
docs/issue-3 && ...`) so the substring is present in the raw command
text; verified by reading each probe's own gate stderr/rc rather than
trusting a bare `rc=0`.

**1. Exhaustive per-head sweep against the real board-gate.sh
subprocess** (`/tmp/probe367.sh`, harness mirrors
`run-board-gate-tests.sh`'s own `run()`: real temp git repo, `issue-3/qa`
branch, `docs/specs/approvers.md` planted, `CLAUDE_SKILL=qa`, real stdin
JSON, real exit code). All 10 members of `INTERPRETER_HEADS` — the
complete head list, not a sample — each with its real inline-exec flag
(job side) and its given-back flag (give-back side), plus the
var-indirected form (`P=head; $P -c/-e ...`) for the bash/perl pair:

```
derived: bash /tmp/probe367.sh (30 cases) — 30 ok, 0 mismatch
python3-c  bash-c  sh-c  zsh-c  perl-e  ruby-e  node-e  nodejs-e
python-c   python2-c                                          -> all DENY (job side, every head)
python3-e  bash-e  sh-e  zsh-e  perl-c  ruby-c  node-c  nodejs-c
python-e   python2-e                                          -> all ALLOW (give-back side, every head)
var-bash-c DENY, var-perl-e DENY, var-bash-e ALLOW, var-perl-c ALLOW
```

No head was dropped from the allowlist by omission: `INLINE_FLAG_HEADS`
is a dict with exactly the 10 `INTERPRETER_HEADS` keys, each mapped to
one flag tuple, so there is no tenth-head gap to find — confirmed by
exhausting the set rather than trusting the dict's shape by inspection.

**2. Same sweep against `warrant/hooks/scope-gate.sh` /
`scope-gate.py`** (`/tmp/probe_scope367.sh`, mirrors
`run-scope-gate-tests.sh`'s own `run()`: approved-proposal fixture,
`CLAUDE_PLUGIN_ROOT_CORE`, real stdin JSON, real exit code):

```
derived: bash /tmp/probe_scope367.sh — 19 ok, 1 mismatch
```

19/20 matched (all `-e` heads correctly denied on the job side and
allowed on the give-back side; `-c` heads correctly denied/allowed for
python/python3/bash/sh/zsh). One mismatch: `python2 -c "open(1,\"w\")"`
returns `allow` (should deny — see Open findings; pre-existing, not a
round-5 regression).

**3. Given-back commands are genuinely benign — checked by running the
actual flag, not assumed:**

```
derived: bash -c 'set -e; echo before; false; echo after'  -> prints "before" only (errexit stops before "after"; no code executes)
derived: perl -c /tmp/t.pl (file prints "SHOULD NOT RUN")  -> "/tmp/t.pl syntax OK", nothing printed, no run
derived: node -c /tmp/t.js (file logs "SHOULD NOT RUN")    -> exit 0, nothing printed, no run
derived: python3 -e 'print(1)'                             -> "Unknown option: -e" (not a real flag; can never carry inline code)
```
unverifiable: ruby is not installed in this sandbox (`which ruby` empty)
— `ruby -c`'s syntax-check-only behavior is not independently executed
here, only documented Ruby behavior relied on; the gate-level ALLOW for
`ruby -c` (item 1 above) is still a real, executed subprocess result,
only the semantic-benignity claim for `-c` on ruby specifically is
unverified locally.

**4. Jurisdiction-limit message: reaches the actual deny path, not only
the header.** Read the literal stderr both gates print on a real deny
(not the header comment):

```
derived: probe367.sh's "jurisdiction message" section, rc=2, board-gate.sh stderr:
"...Use a provably read-only invocation (e.g. python3 -m pytest), or write through Write/Edit or a plain redirect this gate can read the target of. This is a write-set discipline check, not a security boundary (issue-233 round 5): it denies only shapes it cannot read the write target of, and does not claim to catch a shape deliberately built to hide that target from this text-level read."

derived: scope-gate.sh bash -c deny, stderr:
"...This is a write-set discipline check, not a security boundary (issue-233 round 5): it denies only shapes it cannot read the write target of, and does not claim to catch a shape deliberately built to hide that target from this text-level read."
```

Both match the ruling's own framing verbatim in substance ("write-set
discipline", "not a security boundary/sandbox", "does not claim to
catch"). Judged honest: it states a limit, not an achievement — it does
not say the gate "prevents injection" or similar, and does not overclaim
coverage it does not have.

**Four standing invariants, each with the command and its actual output:**

```
derived: git diff origin/main -- core/hooks/board-gate.sh core/hooks/tests/run-board-gate-tests.sh warrant/hooks/lib/scope-gate.py core/hooks/tests/run-scope-gate-tests.sh docs/handbooks/board-gate-tests.md | grep -E '^\+' | grep -iE '\brole\b'
-> no output (exit 1, no match) — no return of the retired role axis in any reshaped form.

derived: python3 -m pytest -q on both /tmp/pr367_check and /tmp/main_check
pr367_check: FAILED test_proposal_shape_gate_refuses_missing_sections, test_survey_order_gate_refuses_proposal_without_survey_or_skip, test_A5_trailer_gate_quote_split_commit_is_detected -- 3 failed, 79 passed
main_check:  FAILED test_proposal_shape_gate_refuses_missing_sections, test_survey_order_gate_refuses_proposal_without_survey_or_skip, test_A5_trailer_gate_quote_split_commit_is_detected -- 3 failed, 79 passed
-> identical set of 3 names on both branches -- no new bug.

derived: bash core/hooks/tests/run-board-gate-tests.sh on both worktrees
pr367_check: 155 passed, 2 failed (feasibility-spikes, ops-postmortems)
main_check:  same 2 names, same count (46-baseline run-scope-gate-tests.sh: 0 failed; pr367_check's 62: 0 failed, +16 new round-5 cases)
-> identical failing-name set -- no new bug, board-gate-tests and scope-gate-tests suites both green modulo the pre-existing pair.

derived: python3 /tmp/overhead_probe.py <repo>, 30-call average, real board-gate.sh subprocess each call
/tmp/main_check: avg=55.8ms   /tmp/pr367_check: avg=54.7ms
-> no overhead increase (within subprocess-startup noise; PR #367 adds a dict lookup, not new work per call).

derived: git diff origin/main --name-only (pr367_check worktree) | grep -iE "on-the-record|monitor|watch"
-> no output (exit 1, no match) — monitor/watch machinery untouched, not touched at all, so not quieter.
```

## Why

Adversarial review's own mechanism (skill-verdict below) is session
separation: this role session never saw PR #367's builder session, only
its committed diff and record via `gh pr diff`/`gh pr view`, and
re-derived every claim against a real subprocess in a scratch git
worktree rather than re-reading the PR's own transcript of its test
runs. The order followed the task's own three-part structure (job not
loosened -> give-backs genuinely benign -> jurisdiction statement
judged) because each part's outcome bounds what the next part needs to
check: had any head lost its deny, benignity of the *other* heads'
give-backs would not have mattered; had the jurisdiction text been
absent from the deny path, "worded honestly" would have been moot.

This is one coherent investigative thread with a strict sequential
dependency (read the ruling -> build a probe harness against the real
gate -> use each probe's result to decide what the next probe needs to
check -> judge the jurisdiction text -> check the four invariants ->
write this record), not width>=2 independently-producible ~100-line
units, so freelunch-protocol's fan-out condition does not apply and this
was done solo. Every repo/environment tool call in this investigation
was made directly rather than delegated to a background
`freelunch:freelunch-worker`, per both freelunch-protocol.md's and
warrant-protocol.md's own explicit subordination clause: this is a
headless, single-shot role session, and the delegation model those
directives otherwise mandate ("dispatch ONE background worker... never
run_in_background: false") would end the turn with dispatched work whose
result was not consumed within it. The two stated alternatives under
that override are "wait for the delegated result and act on it before
the turn ends" or "do not delegate that unit at all" — this session took
the second, because the task is a chain of probes where each result
picks the next probe (a fixed-brief background worker cannot do that
without becoming a second orchestrator), and because adversarial review's
entire value is this session's own continuous skepticism applied at each
step, not a one-shot raw delivery from a worker with no stake in
re-checking its own probe design.

skill-verdict: adversarial-review — applied: invoked; this role session
is itself the "evaluator" the skill describes (structurally separate
from PR #367's builder session, receiving only the committed diff/PR
body/record via `gh`, never the builder's own reasoning or transcript);
re-derived every test result against a real subprocess in a fresh
worktree instead of restating the PR record's own numbers, and used the
mismatch-hunting stance (deliberately tried combined short flags and the
scope-gate.py python2 case the PR's own test list does not cover) rather
than confirming only the cases the PR already claims.
skill-verdict: work-in-english — applied: invoked implicitly per the
mounted skill's own note that its enforcement is a hook, not a
per-session judgment call; followed as guidance (this record, all probe
scripts, and the PR/commit below are in English) without a separate
Skill-tool invocation beyond the one already logged for
adversarial-review this session.
other mounted skills: not triggered.

## What did not work

None — every probe ran on the first construction; the one real
discrepancy found (scope-gate.py's `python2 -c` gap, below) surfaced from
deliberately testing a case the PR's own test file does not cover, not
from a probe that had to be redone.

## Upstream basis

- Issue #233, `gh issue view 233 --comments` — the operator's escalation
  comment (four live same-axis bypasses, HOLD) and the ruling comment
  ("Operator ruling: (b)...") this round's scope comes from verbatim.
- PR #367 (`gh pr view 367 --json ...`, `gh pr diff 367`) — the full diff
  of `core/hooks/board-gate.sh`, `warrant/hooks/lib/scope-gate.py`,
  `core/hooks/tests/run-board-gate-tests.sh`,
  `core/hooks/tests/run-scope-gate-tests.sh`,
  `docs/handbooks/board-gate-tests.md`, and its own
  `docs/issue-233/reports/secure-coding-input-validation-injection-defense-8c25e36e.md`
  record — read for what the PR claims, not restated as this record's own
  evidence.
- PR #363 (`gh pr view 363 --json state,mergeable,title`, `gh pr diff 363
  --name-only`) — read to check the stranded-work question below.
- `/tmp/pr367_check` (PR #367 head `c2f8b3f`) and `/tmp/main_check`
  (`origin/main` `580af98`), both `git worktree add` scratch checkouts,
  read in full and used for every subprocess probe and suite run in this
  record; removed (`git worktree remove --force`) after use.

## Open findings

**1. `warrant/hooks/lib/scope-gate.py`: `python2 -c "..."` is not denied
— `allow` where every other `-c` head correctly denies (probe item 2
above).** Root cause: `UNANALYZABLE_WRITE_SHAPE`'s head alternation uses
the regex `python3?` (matches literal `python` or `python3` only) instead
of an explicit head list — `python2` was never in the regex alternation,
board-gate.sh's `INTERPRETER_HEADS`/`INLINE_FLAG_HEADS` tuple/dict
notwithstanding (that file lists `python2` literally and correctly
denies it — probe item 1's `python2-c: ok deny`). **Confirmed
pre-existing, not a round-5 regression**: `git show
origin/main:warrant/hooks/lib/scope-gate.py | grep python3?` shows the
identical `python3?` alternation at the pre-round-5 line 146, and
`bash /tmp/probe_scope_main.sh` (same `python2 -c` payload against
`/tmp/main_check`) returns `rc=0` (allow) too. Round 5's own diff did not
touch which head names the regex matches — it only split the existing
`-[A-Za-z]*[ce]` alternative into a `-c` branch and an `-e` branch,
carrying the pre-existing `python3?` substring into both branches
unchanged. **Not a blocking finding against PR #367**: the give-back did
not open this hole, and the task's blocking-finding criterion is scoped
to "the real board-gate.sh subprocess level," where every head
(including python2) is correctly denied. Flagged here because it is a
real, live, reproducible gap in the sibling gate the issue title also
names ("board/scope-gate"), left uncaught by PR #367's own test list
(neither `run-scope-gate-tests.sh`'s new cases nor its pre-existing 46
cover a bare `python2 -c`) despite the PR record's "Full sweep... zero
MISMATCH lines" claim — that claim is about board-gate.sh's flag-per-head
mapping, not an exhaustive head sweep of scope-gate.py's separate regex
implementation. Resolution path: a future round's own task, not this
PR's — out of round 5's explicitly declared scope ("does not touch the
single-token-expansion bypass class... does not add
`UNRESOLVED_SUBSTITUTION_WORD_RE` or any new flag spelling").

**2. Combined short flags (`bash -xc`, `bash -ec`) allow on both
`main` and PR #367 — pre-existing, not this round's scope.** `derived:
bash /tmp/probe367.sh` (combined-flags section) and the equivalent
against `/tmp/main_check` both return `allow` for `bash -xc "echo hi >
pwn.md"` and `bash -ec "echo hi > pwn.md"`. Cause: the exact-word match
`w in INLINE_FLAG_HEADS[head]` (post-round-5) / `w in INLINE_FLAG_WORDS`
(pre-round-5) checks `gate_trailing_words` output against the literal
string `-c`, which a combined flag like `-xc` never equals — identical
behavior before and after this PR, so not introduced by it. Not raised
as a finding needing action here: the task explicitly rules out
"extend[ing] the check to more flag spellings" this round, and combined
short flags are a spelling question, not the per-head mismatch this PR
targets.

**3. PR #363 (round 4, still open) would be stranded if #367 merges as
labeled.** `gh pr view 363 --json state,mergeable,title` shows PR #363 is
still `OPEN` (2548 additions, `gh pr view 363 --json additions`), and its
diff (`gh pr diff 363 --name-only`) carries the `_shell_split` tokenizer,
the escaped-space and quoted-path fixes, and the ANSI-C fusion fix, none
of which are anywhere on `origin/main` today (`grep -n
"_shell_split\|ANSI-C\|fusion" core/hooks/board-gate.sh
core/hooks/lib/gate-lib.py` on `origin/main` finds nothing but incidental
comment text) or in PR #367's own diff (PR #367's file list has no
`core/hooks/lib/gate-lib.py` at all). PR #367's body reads `Closes
#233`. **If PR #367 merges as labeled, issue #233 closes while PR #363's
three non-security fixes remain on an open, unmerged branch with no
open issue left to justify landing them** — the operator's own round-4
ruling explicitly said "PR #363's non-security work... all stands and is
unaffected by this hold," which was true while #233 stayed open, but a
closed #233 removes the thing currently keeping #363 live in review
flow. This is not this PR's defect to fix (round 5's task is narrowly
scoped to the jurisdiction statement and the flag-per-head split, and
the operator's ruling never asked PR #367 to carry #363's tokenizer
work), but it is a real consequence of merging #367 exactly as titled,
and belongs in this record as the task explicitly asked.

## Next steps

None — `loop_state: landed`. This is a review record, not a fix: no
code change is proposed here. The two open findings above (scope-gate.py
python2 gap, PR #363 stranding) are handed to the operator/future rounds
as findings, not resolved by this record.
