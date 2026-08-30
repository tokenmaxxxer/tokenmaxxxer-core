---
issue: 233
role: adversarial-review-a814c155
author: adversarial-review-a814c155
skills: adversarial-review (skill-repository(c05de12))
verifies_subject: true  # flip to true only if this record is an independent verification of this subject's own deliverable -- see docs/handbooks/observer-verification.md
loop_state: landed
upstream:
  - path: core/hooks/board-gate.sh
    sha: c2f8b3f42de88b39c33a697b20d5af91cfc47dfd
  - path: warrant/hooks/lib/scope-gate.py
    sha: c2f8b3f42de88b39c33a697b20d5af91cfc47dfd
  - path: docs/issue-233/reports/secure-coding-input-validation-injection-defense-8c25e36e.md
    sha: c2f8b3f42de88b39c33a697b20d5af91cfc47dfd
---

# issue-233 — adversarial-review-a814c155 record

**Verdict: BLOCKING FINDING.** PR #367 should not merge as-is. Its
given-back `perl -c` allow is a false-allow for a real write: Perl
executes `BEGIN`/`UNITCHECK`/`CHECK` blocks during a `-c` syntax check
(documented Perl semantics, not an edge case), so `perl -c
reports/evil.pl` performs a genuine, unanalyzed filesystem write while
both `board-gate.sh` and `scope-gate.py` now classify it as
provably-safe. The identical command was correctly denied on
`origin/main` before this PR — this is a regression this PR introduces,
not a pre-existing gap. See item 0 and Open findings below; everything
else checked in this round (exhaustive per-head job-side sweep for the
other 9 heads, the other four given-back commands, jurisdiction-message
placement, the four standing invariants) held with no other blocking
issue.

## What was done

**0. Blocking finding (surfaced by this round's before-landing warrant
hunter, `subagent_type: warrant-hunter`, stance 0 — "assume the gate just
touched is bypassable", dispatched against `docs/issue-233/reports/adversarial-review-a814c155.md`
as this round's proposal-equivalent since `CORE_BUILD_NOW=1` skipped the
normal proposal file — then independently re-verified end-to-end by this
session, not merely relayed):**

Real perl, independent of any gate, confirms `-c` executes `BEGIN`
blocks:

```
derived: perl -c /tmp/verify_perl_c/evil.pl  (file: BEGIN { open($fh,">","/tmp/verify_perl_c/pwn_verify.md"); print $fh "pwned-by-BEGIN-during-dash-c\n"; } print "this line never runs under -c\n";)
/tmp/verify_perl_c/evil.pl syntax OK
exit=0
$ cat /tmp/verify_perl_c/pwn_verify.md
pwned-by-BEGIN-during-dash-c
```
The file was created and populated by the `-c` invocation itself — the
"syntax-check-only, does not execute" premise PR #367 gives as its
reason to allowlist `perl -c` (`INLINE_FLAG_HEADS` comment: "the opposite
of inline execution") is empirically false for Perl. (Checked the two
other "check-only" given-backs for the same class of gap: `node -c` —
independently verified via a real `node -c /tmp/verify_node_c/evil.js`
containing a top-level `fs.writeFileSync` call — creates no file, node's
`-c`/`--check` is genuinely parse-only. `ruby -c` — no local ruby
available, verified via `docker run --rm ruby:3-alpine` with a `BEGIN {
File.write(...) }` script — creates no file either, Ruby's `-c` is
genuinely parse-only and does not run `BEGIN` blocks. Perl is the outlier
among the three.)

Live against the real gate subprocess, re-verified by this session
directly (not just the hunter's report) in a fresh worktree pair
(`/tmp/pr367-recheck` = `pull/367/head` @ `c2f8b3f`, `/tmp/main-recheck` =
`origin/main` @ `580af98`):

```
derived: bash /tmp/verify_perl_c_gate.sh /tmp/pr367-recheck   (payload: cd docs/issue-3 && perl -c reports/evil.pl)
ROOT=/tmp/pr367-recheck VERDICT=allow RC=0

derived: bash /tmp/verify_perl_c_gate.sh /tmp/main-recheck
ROOT=/tmp/main-recheck VERDICT=deny RC=2

derived: bash /tmp/verify_perl_c_scope.sh /tmp/pr367-recheck  (payload: perl -c src/evil.pl, warrant/hooks/scope-gate.sh)
ROOT=/tmp/pr367-recheck VERDICT=allow RC=0

derived: bash /tmp/verify_perl_c_scope.sh /tmp/main-recheck
ROOT=/tmp/main-recheck VERDICT=deny RC=2
```

Both gates flip `perl -c <path-under-the-enforced-write-set>` from
correctly-denied on `origin/main` to allowed on PR #367, for a command
that can perform an arbitrary real write through a `BEGIN` block with no
trace in the gate's text-level read. This is squarely inside the
operator's own stated threat model for this gate — "a cooperative session
drifting out of its lane" (issue #233 ruling comment) — not only an
adversarial-evasion case: a session that runs `perl -c
some_script.pl` to syntax-check a script before running it, where that
script happens to carry a `BEGIN` block (a common, unremarkable Perl
idiom — `use lib '...'`-style path setup, config loading, feature
detection all commonly live in `BEGIN`), performs an unreviewed write the
gate now waves through as "provably safe."

Full detail (constructed independently by the hunter, matches this
session's own re-derivation above) is at
`docs/issue-233/reports/adversarial-review-a814c155/2026-08-30-hunt-adversarial-review-a814c155.md`.

The remainder of this section covers the rest of the round's brief
(exhaustive per-head sweep, given-back benignity for the other four
commands, jurisdiction-message placement, the four standing invariants,
and the PR #363 stranding question) — all of it independent of, and
already covered by, the blocking finding above.

Independent adversarial verification of PR #367 (round 5 on issue #233),
`issue-233/secure-coding-input-validation-injection-defense-8c25e36e` @
`c2f8b3f`. PR #367 states the board/scope-gate jurisdiction limit
explicitly (in header comment AND deny message) and narrows the `-c`/`-e`
inline-code-flag check from a uniform set applied to all 10
`INTERPRETER_HEADS` to a per-head allowlist (`INLINE_FLAG_HEADS` in
board-gate.sh; two flag-scoped regex alternatives in scope-gate.py).

Read the operator's ruling comment on issue #233 first (`gh issue view
233 --repo tokenmaxxxer/tokenmaxxxer-core`, comment beginning "Operator
ruling: (b) — declare the jurisdiction, and shrink the over-refusal. Not
(a), not (c)."): round 5 reverses direction from rounds 1-4 — this is
write-set discipline (R1/R4/R5), not a security sandbox, so this round
gives back legitimate commands rather than closing bypasses.

Fetched PR #367's real diff (`gh pr diff 367`) and checked it out in an
isolated worktree (`git worktree add /tmp/pr367-check pr-367-check`,
`origin/pull/367/head`) alongside a second worktree of `origin/main`
(`/tmp/main-check`) for baseline comparison. All probes below ran the
real `board-gate.sh`/`scope-gate.sh` subprocess, not a re-read of the
diff or the PR's own record — every probe command contains a literal
`docs` substring (`cd docs/issue-3 && ...` / a `docs/proposals/...` write
set) so the no-`docs`-substring fast path (core#361, out of scope here,
confirmed live below) is not silently short-circuiting the check.

**1. Exhaustive per-head job-side/given-back sweep, real subprocess,
board-gate.sh** (`/tmp/probe.sh`, harness modeled on
`run-board-gate-tests.sh`'s own `run()`):

```
=== JOB SIDE: real inline-exec flag per head, must stay DENIED ===
OK   want=deny  got=deny  python3-c   cd docs/issue-3 && python3 -c "open('reports/pwn.md','w').write('1')"
OK   want=deny  got=deny  python-c    cd docs/issue-3 && python -c "open('reports/pwn.md','w').write('1')"
OK   want=deny  got=deny  python2-c   cd docs/issue-3 && python2 -c "open('reports/pwn.md','w').write('1')"
OK   want=deny  got=deny  bash-c      cd docs/issue-3 && bash -c "echo hi > reports/pwn.md"
OK   want=deny  got=deny  sh-c        cd docs/issue-3 && sh -c "echo hi > reports/pwn.md"
OK   want=deny  got=deny  zsh-c       cd docs/issue-3 && zsh -c "echo hi > reports/pwn.md"
OK   want=deny  got=deny  perl-e      cd docs/issue-3 && perl -e "open(F,'>reports/pwn.md');print F 1"
OK   want=deny  got=deny  ruby-e      cd docs/issue-3 && ruby -e "File.write('reports/pwn.md','1')"
OK   want=deny  got=deny  node-e      cd docs/issue-3 && node -e "require('fs').writeFileSync('reports/pwn.md','1')"
OK   want=deny  got=deny  nodejs-e    cd docs/issue-3 && nodejs -e "require('fs').writeFileSync('reports/pwn.md','1')"

=== GIVEN-BACK SIDE: dropped flag, must be ALLOW ===
OK   want=allow got=allow bash-e      cd docs/issue-3 && bash -e reports/script.sh
OK   want=allow got=allow sh-e        cd docs/issue-3 && sh -e reports/script.sh
OK   want=allow got=allow zsh-e       cd docs/issue-3 && zsh -e reports/script.sh
OK   want=allow got=allow perl-c      cd docs/issue-3 && perl -c reports/script.pl
OK   want=allow got=allow ruby-c      cd docs/issue-3 && ruby -c reports/script.rb
OK   want=allow got=allow node-c      cd docs/issue-3 && node -c reports/script.js
OK   want=allow got=allow nodejs-c    cd docs/issue-3 && nodejs -c reports/script.js
OK   want=allow got=allow python3-e   cd docs/issue-3 && python3 -e reports/foo.py
OK   want=allow got=allow python-e    cd docs/issue-3 && python -e reports/foo.py
OK   want=allow got=allow python2-e   cd docs/issue-3 && python2 -e reports/foo.py

=== ADVERSARIAL: -c still fires alongside the given-back flag ===
OK   want=deny  got=deny  bash-e-plus-c   cd docs/issue-3 && bash -e -c "echo hi > reports/pwn.md"
OK   want=deny  got=deny  perl-c-plus-e   cd docs/issue-3 && perl -c -e "open(F,'>reports/pwn.md')"

=== PURE-READ REGRESSION GUARD ===
OK   want=allow got=allow home-expansion  cd docs/issue-3 && cat "${HOME}/x" ; echo docs
OK   want=allow got=allow awk-print       awk '{print}' reports/file.md
OK   want=allow got=allow pytest-computed python3 -m pytest -k "$(echo foo)" ; echo docs
OK   want=allow got=allow script-computed python3 script.py --input "$(pwd)/data.csv" ; echo docs

=== FAST-PATH CHECK (no 'docs' substring => exit 0, core#361, out of scope) ===
OK   want=allow got=allow no-docs-substring  bash -c "echo hi > /tmp/pwn_....md"
```
This is exhaustive over all 10 names in `INTERPRETER_HEADS` — no head lost
its real inline-code flag; every given-back combination is the exact
"other" flag letter for that head. Also ran `bash core/hooks/tests/run-board-gate-tests.sh`
(`155 passed, 2 failed`, same 2 pre-existing failures as `origin/main` —
`feasibility-spikes`/`ops-postmortems`, confirmed via
`git -C /tmp/pr367-check stash` toggling) and
`bash core/hooks/tests/run-scope-gate-tests.sh` (`62 passed, 0 failed`).

**2. Same sweep against scope-gate.sh** (`/tmp/probe_scope.sh`), plus
var-indirected split — all OK, **except one MISMATCH**: `python2 -c
"open('src/pwn.py','w').write('1')"` is **allow**, wanted deny. Traced
this to `UNANALYZABLE_WRITE_SHAPE`'s alternation using `python3?` (matches
`python`/`python3`, never `python2`) — re-ran the identical probe against
`origin/main`'s `scope-gate.py` (`/tmp/probe_scope_main.sh`) and got the
same `allow`: `python3?` never covered `python2` in scope-gate.py, before
or after this PR (`origin/main`'s `UNANALYZABLE_WRITE_SHAPE` line 146 has
the identical `python3?` group). **Not a round-5 regression** — PR #367
didn't touch this alternative's head list, only split it by flag. It is a
factual gap in the PR's own docs/handbook claim, though: the round-5
handbook entry states "`-c` for python/python2/python3/bash/sh/zsh" as
the fix applied identically to both gates, but scope-gate.py's actual
regex never included `python2` in that group — non-blocking (nothing
loosened; `python2 -c` was already allowed pre-PR), noted below as an
Open finding for accuracy, not a gate defect this round introduced.

**3. Combined-short-flag probe** (`bash -ec "..."`, `bash -ce "..."`,
`sh -ec "..."`, `python3 -Bc "..."`) — all **allow** on both PR #367
(`/tmp/probe.sh`) and `origin/main` (`/tmp/probe_main.sh`): `bash -ec`
denies on neither branch. Root cause: `gate_trailing_words` /
`_resolve_transparent` (`core/hooks/lib/gate-lib.py:216`) never splits a
bundled short-option word — `"-ec"` stays one token, and the exact-match
`w in INLINE_FLAG_HEADS[head]` test (unchanged shape from the pre-PR
`w in INLINE_FLAG_WORDS`) never matches it. **Pre-existing on
`origin/main`, unaffected by round 5** — not caused by the flag-per-head
narrowing (round 5 didn't touch how trailing words are tokenized), and
explicitly out of scope per this round's task text ("do not extend the
check to more flag spellings").

**4. Jurisdiction statement placement — checked at the actual deny
message a session reads, not just the header comment.** Triggered a real
`bash -c "echo hi > reports/pwn.md"` deny through the PR's own
`board-gate.sh` subprocess (`/tmp/get_deny_msg.sh`) and through
`scope-gate.sh` (`/tmp/get_deny_msg_scope.sh`):

```
derived: bash /tmp/get_deny_msg.sh (real board-gate.sh subprocess, PR #367 worktree)
board-gate: a Bash call carries an un-analyzable write-capable shape (bash -c "echo hi >
reports/pwn.md") while this gate enforces role 'qa''s write-set. ... Use a provably
read-only invocation (e.g. python3 -m pytest), or write through Write/Edit or a plain
redirect this gate can read the target of. This is a write-set discipline check, not a
security boundary (issue-233 round 5): it denies only shapes it cannot read the write
target of, and does not claim to catch a shape deliberately built to hide that target
from this text-level read.
RC=2

derived: bash /tmp/get_deny_msg_scope.sh (real scope-gate.sh subprocess, PR #367 worktree)
warrant: refused — this Bash call carries an un-analyzable write-capable shape ...
This is a write-set discipline check, not a security boundary (issue-233 round 5): it
denies only shapes it cannot read the write target of, and does not claim to catch a
shape deliberately built to hide that target from this text-level read.
RC=2
```
Both messages carry the jurisdiction sentence live, in the exact text a
session sees on refusal — not only in the R1-R5 header comment. Judged
honest: it states what the gate denies (unreadable write target) and
explicitly disclaims catching deliberate-hiding shapes, matching what
sections 1-3 above independently confirmed the code actually does (real
inline-exec stays denied; it does not claim to catch the round 1-4
single-token-expansion class, which this round does not touch).

**5. Four standing invariants, re-derived independently (not read off the
PR's own record):**

- No return of the retired role axis:
  `git diff origin/main -- core/hooks/board-gate.sh warrant/hooks/lib/scope-gate.py
  core/hooks/tests/run-board-gate-tests.sh core/hooks/tests/run-scope-gate-tests.sh
  | grep -E '^\+' | grep -iE '\brole\b'` — zero matches (grep exit 1).
- No new bug — failing-test set vs `origin/main`, compared as SETS OF
  NAMES: `python3 -m pytest -q` on the PR #367 worktree gives `3 failed,
  79 passed` — `{test_proposal_shape_gate_refuses_missing_sections,
  test_survey_order_gate_refuses_proposal_without_survey_or_skip,
  test_A5_trailer_gate_quote_split_commit_is_detected}`; the identical
  command on the `origin/main` worktree gives `3 failed, 79 passed` with
  the **same three names**. Sets equal.
- No overhead increase: `/tmp/overhead_probe.sh`, 30-call average of a
  real `board-gate.sh` subprocess invocation — PR #367: `52.82 ms/call`;
  `origin/main`: `50.69 ms/call`. ~2ms delta on a ~51ms base, within
  subprocess-startup noise (matches the PR's own claimed 46.8ms/49.9ms
  order of magnitude).
- Monitor/watch machinery unbroken and not quieter:
  `git diff origin/main --name-only` on the PR #367 worktree lists only
  `core/hooks/board-gate.sh`, `core/hooks/tests/run-board-gate-tests.sh`,
  `core/hooks/tests/run-scope-gate-tests.sh`,
  `docs/handbooks/board-gate-tests.md`,
  `docs/issue-233/reports/secure-coding-input-validation-injection-defense-8c25e36e.md`,
  `warrant/hooks/lib/scope-gate.py` — nothing under any monitor/watch
  path.

**6. PR #363 stranding, per the task's explicit ask (not a defect in PR
#367 itself):** `gh pr view 363` — still `state: OPEN`,
`mergeable: MERGEABLE`. `gh pr diff 363 --name-only` shows it touches
`core/hooks/lib/gate-lib.py` (the `_shell_split` tokenizer, escaped-space/
quoted-path fixes, ANSI-C fusion fix — ~2474 diff lines in that one file
alone, `awk` count on the fetched diff) — a file PR #367 does **not**
touch at all (`git diff origin/main --name-only` above has no
`gate-lib.py` entry). PR #367's body says `Closes #233`. **Yes, merging
PR #367 as-is would strand PR #363's non-security work**: closing #233
removes the only open issue anchoring PR #363, and PR #363's gate-lib.py
fixes (independent of, and not superseded by, PR #367's board-gate.sh/
scope-gate.py changes) would sit merged-clean but un-landed with nothing
left open to prompt landing them.

## Why

Chose real-subprocess probing over re-reading the PR's own record because
the task is independent verification — the PR's own `derived:`/
`acceptance:` lines are the thing being checked, not the source of truth.
Built two isolated worktrees (`origin/main` and PR #367's head) so every
comparison ("was this already denied", "is this a round-5 regression")
is a live diff between two real gate subprocesses, not a memory of what
round 1-4's records said. Every probe command was constructed to contain
a literal `docs` substring after the warning about board-gate.sh's
no-`docs`-substring fast path (core#361) — the fast-path-triggering case
is itself pinned as a control (`no-docs-substring` above, confirmed
`allow` unconditionally, correctly out of scope here).

Scoped the check to exactly what the task asked: exhaustive per-head
job-side/given-back verification (found the perl -c blocking finding),
given-back-command benignity (checked what the flag actually does for
each of the five, not just whether the gate denies it — this is exactly
what surfaced the finding: node -c and ruby -c are genuinely parse-only,
independently confirmed; perl -c is not, independently confirmed),
jurisdiction-statement placement and honesty (confirmed live at the deny
message), the four invariants (independently re-derived, all hold), and
the PR #363 note (confirmed real). Did not extend into new flag
spellings, substitution matching, or PostToolUse, per the task's explicit
"ruled out" list — the two adjacent gaps found (combined-short-flag
exact-match miss, scope-gate.py's `python3?` never covering `python2`)
were investigated only far enough to confirm they are pre-existing and
unworsened by this PR, not chased into a fix (out of scope for a
verification round, and the task named those extensions as ruled out).
The perl -c finding is different in kind from those two: it is not
pre-existing (origin/main correctly denied it) and not an extension of
the check's scope — it is round 5's own change producing a wrong answer
for the exact five given-back commands the task asked to verify as
"genuinely benign."

The warrant-directive's before-landing hunter dispatch (stance 0,
mandatory at this transition regardless of the round's own findings so
far) is what surfaced this — this session's own initial sweep (item 1
below) tested only whether the gate's verdict matched the PR's claimed
verdict (allow/deny), not whether the underlying flag-semantics premise
itself was true. Independently re-derived (not merely relayed) before
writing it up here: real perl BEGIN-block execution under `-c`, real
node/ruby non-execution under `-c` for contrast, and the gate subprocess
verdict on both `origin/main` and PR #367 for both `board-gate.sh` and
`scope-gate.py`.

freelunch-protocol tally already stated at the top of this session's
first turn (width=1, LEAN SOLO — one coherent investigative thread, no
freezable contract to split against); consuming repo/env tool calls
directly throughout this record is consistent with contract v3 s22's
override for a headless single-shot session whose probe results
continuously shape the next probe. The one dispatched hunter (background,
`warrant-hunter`, `model: sonnet`) was waited on and its finding consumed
within this same turn, per the warrant-directive's own s22 subordination
clause for headless single-shot sessions.

skill-verdict: adversarial-review — applied: invoked; ran the actual
protocol this record follows (independent evaluator posture: constructed
own probes against the real gate subprocess rather than trusting or
re-narrating PR #367's own `derived:`/`acceptance:` claims, actively
hunted for a per-head allowlist hole and a jurisdiction-message honesty
gap rather than confirming the PR's framing, and — critically — checked
the given-back commands' actual runtime semantics rather than only their
gate verdicts, which is what found the blocking finding).
skill-verdict: work-in-english — not-applicable: this skill's own mounted
description states enforcement is via the core hook, not a Skill-tool
judgment call this session makes; followed as guidance (English
throughout this record and all probe scripts) without invoking.
other mounted skills: not triggered.

## What did not work

None — every probe ran clean on the first construction; the two adjacent
gaps found (combined-short-flag, scope-gate.py `python2`) were
discoveries, not failed attempts, and neither required a retry.

## Upstream basis

- PR #367 (`issue-233/secure-coding-input-validation-injection-defense-8c25e36e`
  @ `c2f8b3f42de88b39c33a697b20d5af91cfc47dfd`) — `gh pr view 367` /
  `gh pr diff 367`, and the real subprocess checked out at
  `/tmp/pr367-check` (worktree, removed after this session).
- `origin/main` @ `580af98` (the round-4-review-record tip commit, no
  round 1-4 code merge landed — confirmed via
  `git log --oneline -1 -- core/hooks/board-gate.sh` on `origin/main`) —
  worktree at `/tmp/main-check` (removed after this session), used as the
  baseline for every "is this pre-existing" and every invariant
  comparison above.
- Issue #233 (`gh issue view 233 --repo tokenmaxxxer/tokenmaxxxer-core
  --json comments`) — the escalation comment (four live round-4 bypasses,
  the consult verdict) and the operator's ruling comment ("Operator
  ruling: (b) — declare the jurisdiction...") this round's scope and
  constraints come from verbatim.
- PR #363 (`gh pr view 363`, `gh pr diff 363 --name-only`) — read only to
  answer the task's explicit stranding question; not otherwise treated as
  upstream for this round's own subject.
- `docs/issue-233/reports/adversarial-review-a814c155/2026-08-30-hunt-adversarial-review-a814c155.md`
  (same-commit — lands alongside this record) — this round's mandatory
  before-landing warrant-hunter dispatch (stance 0), whose finding is
  independently re-derived (not merely relayed) in item 0 of "What was
  done" above: PR #367's own diff (`gh pr diff 367`) is the hunter's own
  cited seed.

## Open findings

- **BLOCKING — see item 0 of "What was done" for the full reproduction:**
  `perl -c` is genuinely code-executing (Perl runs `BEGIN`/`UNITCHECK`/
  `CHECK` blocks during a syntax check — documented Perl behavior, not an
  edge case), so PR #367's per-head allowlist gives back a real,
  unanalyzed write vector for both `board-gate.sh` and `scope-gate.py`
  that was correctly denied on `origin/main`. Round 5's own rationale for
  this specific given-back ("the opposite of inline execution") is false
  for the interpreter it names. Resolution path: this is the round's own
  finding to fix, not a follow-up — narrowest correction is to drop
  `perl` from the `-c`-side given-back set (keep denying `perl -c`, as
  `origin/main` did) while leaving `ruby -c`/`node -c` (independently
  confirmed genuinely parse-only) given back as-is; a broader fix would
  need to re-examine whether any other interpreter in the allowlist has
  a similar compile-time-side-effect flag this round's per-head mapping
  assumed away without checking.
- **Non-blocking, documentation accuracy only:** the round-5 handbook
  entry (`docs/handbooks/board-gate-tests.md`, added by this PR) and the
  PR's own record (`docs/issue-233/reports/secure-coding-input-validation-injection-defense-8c25e36e.md`)
  both describe the fix as applying "`-c` for python/python2/python3/
  bash/sh/zsh" identically to both `board-gate.sh` and `scope-gate.py`.
  For `board-gate.sh` this is accurate (`INLINE_FLAG_HEADS` explicitly
  keys `"python2": ("-c",)`). For `scope-gate.py` it is not:
  `UNANALYZABLE_WRITE_SHAPE`'s `-c` alternative uses `python3?`, which
  never matched `python2`, before or after this PR (confirmed identical
  `allow` on both `origin/main` and PR #367 for a literal `python2 -c
  "open(...)...write(...)"` probe). No gate behavior regressed — `python2
  -c` was already allowed pre-PR and stays allowed — but the docs
  overclaim symmetry that isn't actually there in the code. Resolution
  path: a follow-up documentation correction (or a scope-gate.py
  `python3?` → `python2?3?` fix, if the operator wants parity), not
  something this verification round is scoped to apply itself.
- **Non-blocking, pre-existing, explicitly out of scope this round:**
  bundled short-option flags (`bash -ec "..."`, `bash -ce "..."`, `sh -ec
  "..."`, `python3 -Bc "..."`) are `allow` on both `origin/main` and PR
  #367 — `gate_trailing_words` never splits a bundled token, so the
  exact-match flag check (`w in INLINE_FLAG_HEADS[head]`, same shape
  before and after this PR) never fires on `"-ec"`. Not a round-5
  regression; the task's own "do not extend the check to more flag
  spellings" rules out fixing this here.
- PR #363 stranding — see item 6 above; not a defect in PR #367, but real
  operationally: merging #367's `Closes #233` as-is orphans PR #363's
  independent `gate-lib.py` work with no open issue left pointing at it.

## Next steps

`loop_state: landed` for this verification record itself (the round's
own next step is a fix, owned by whoever picks up the blocking finding —
not further work by this review round). Derived: item 0 of "What was
done" (real-perl `BEGIN`-block reproduction, plus real gate-subprocess
verdicts on both `board-gate.sh` and `scope-gate.py`, both `origin/main`
and PR #367) shows PR #367's `perl -c` given-back is a real, unanalyzed
write vector reopened by this round, not present on `origin/main` — this
is a **blocking finding against PR #367**, not a clean pass. Everything
else the round asked for held: derived: `/tmp/probe.sh` and
`/tmp/probe_scope.sh` (real board-gate.sh/scope-gate.sh subprocess
sweeps, section 1-2 above, 0 job-side mismatches for all 10 heads' real
inline-exec flags) plus `/tmp/get_deny_msg.sh` and
`/tmp/get_deny_msg_scope.sh` (section 4, live deny-message capture): the
jurisdiction statement is live at the actual deny message and does not
overclaim, and all four standing invariants hold under independent
re-derivation (section 5). The two adjacent non-blocking gaps found
(combined-short-flag, scope-gate.py's `python2` miss) are pre-existing
and out of round-5's explicit scope; the PR #363 stranding note is
answered but is not this PR's defect to fix. PR #367 should not be merged
with `Closes #233` until the `perl -c` given-back is corrected (or
dropped) and re-verified.
