---
issue: 233
role: adversarial-review-563ecf52
author: adversarial-review-563ecf52
skills: adversarial-review (skill-repository(c05de12))
verifies_subject: true  # flip to true only if this record is an independent verification of this subject's own deliverable -- see docs/handbooks/observer-verification.md
loop_state: landed
upstream:
  - path: docs/issue-233/reports/secure-coding-input-validation-injection-defense-bcd7fd6a.md
    sha: 644443ab110e37f004ec2e477e1eddbd4e9fe003
  - path: core/hooks/board-gate.sh
    sha: 644443ab110e37f004ec2e477e1eddbd4e9fe003
  - path: warrant/hooks/lib/scope-gate.py
    sha: 644443ab110e37f004ec2e477e1eddbd4e9fe003
---

# issue-233 — adversarial-review-563ecf52 record

**Verdict: NO BLOCKING FINDING.** PR #367 round 6 (commit `644443ab`,
the PR's current head — `canonical: gh pr view 367 --json
headRefName,headRefOid` — `{"head":"issue-233/secure-coding-input-validation-injection-defense-8c25e36e","oid":"644443ab110e37f004ec2e477e1eddbd4e9fe003"}`)
is independently re-derived here by execution, not relayed from either
round 6's own record or round 5's `#368`/`#369` reviews. Every give-back
entry was probed with a real write-detection script run directly against
the real interpreter; every one of the 10 `INTERPRETER_HEADS`, plus
`perl -c`/`perl -e` specifically, was probed with a real
`board-gate.sh`/`scope-gate.sh` subprocess. No new bypass found. Two
pre-existing, disclosed, out-of-scope gaps were independently
reproduced and confirmed identical on `origin/main` (not round-6
regressions). Four standing invariants held.

## What was done

skill-verdict: adversarial-review — applied: invoked; this record follows
the skill's core mechanism (structurally independent evaluator, blind to
the builder's own claims, required to re-derive by direct execution
rather than relay documented/reported behavior) even though it runs as a
same-repository verification round rather than a separate blind-artifact
handoff — the operative discipline this round enforces is "verify by
execution, not by citation," which is exactly Step 3's gate.
skill-verdict: work-in-english — applied: invoked; this record, all
probe scripts, commit message and PR are in English; the final
user-facing summary is in Korean per the skill's routing rule.

**Setup.** Two isolated worktrees, matching round 5's methodology:
`/tmp/pr367-r6` = `644443ab110e37f004ec2e477e1eddbd4e9fe003` (PR #367's
real current head), `/tmp/main-r6` = `origin/main` (which resolved to
`ea8c498`, the round-5-review-record merge commit — `derived: git log
--oneline -1 origin/main` — `ea8c498 issue-233: independent adversarial
verification of PR #367 (round 5) — blocking finding: perl -c (#369)`;
PR #367's own code changes are not yet merged, so this is the correct
pre-round-5-code baseline for behavior comparison).

**Board-gate/scope-gate "docs"-substring fast-path trap accounted for**
(this issue has produced bogus results twice already from this):
`board-gate.sh` line 675 (`if DOCS in cmdline:`) exits allow with no
analysis when the raw Bash command text carries no literal `docs/`
substring — confirmed still present and load-bearing by dedicated probe
below. Every `board-gate.sh` payload in this round's probes carries a
literal `docs/issue-3` or `docs` substring in the command text itself
(not synthesized around it); `scope-gate.sh` has no equivalent
substring fast path (confirmed by reading `warrant/hooks/lib/scope-gate.py`
for any `DOCS`/`"docs"` fast-exit — the only `docs` reference there is
the proposals-dir check, unrelated), so its probes use plain `src/app.py`
paths without needing the substring.

### 1. Give-back entries — real write-detection execution, not documented meaning

For every entry still on round 6's give-back list, built a script/probe
that writes a sentinel file if the flag executes anything at all
(inline-string-as-argument test, and — for languages with a
load-time/`BEGIN`-style hook — a staged-write-in-the-referenced-file
test, the exact construct that caught round 5's `perl -c` bug), ran it
against the real interpreter binary (not the gate), and read the
sentinel state directly:

```
derived: bash -e 'echo pwned > pwn_bash_inline.md'   (in /tmp/verify-r6)
bash: echo pwned > pwn_bash_inline.md: 그런 파일이나 디렉터리가 없습니다
exit=1 — pwn_bash_inline.md NOT CREATED (bash treats -e's next word as a
script PATH, never as an inline code string; comparison: `bash -e
script_bash.sh` on a real script file executes normally and writes —
expected, visible-in-text, not the concern)

derived: sh -e 'echo pwned > pwn_sh_inline.md'
sh: 0: cannot open echo pwned > pwn_sh_inline.md: No such file
exit=2 — pwn_sh_inline.md NOT CREATED

derived: docker run --rm -v /tmp/verify-r6:/work -w /work alpine:3.20 sh -c
  'apk add --no-cache zsh; zsh -e "echo pwned > pwn_zsh_inline.md"'
zsh: can't open input file: echo pwned > pwn_zsh_inline.md
exit=127 — pwn_zsh_inline.md NOT CREATED (zsh unavailable locally, run in
alpine:3.20 container per this round's instruction not to mark
undetermined; comparison: `zsh -e script_zsh.sh` on a real file executes
normally — normal-write, expected)

derived: python3 -e 'open("pwn_py3_e.md","w").write("pwned")'
Unknown option: -e
exit=2 — pwn_py3_e.md NOT CREATED

derived: docker run --rm -v /tmp/verify-r6:/work -w /work python:2 sh -c
  'python -e "open(\"pwn_py_e.md\",\"w\").write(\"pwned\")"; python2 -e "open(\"pwn_py2_e.md\",\"w\").write(\"pwned\")"'
Unknown option: -e   (both python and python2)
exit=2 (both) — pwn_py_e.md and pwn_py2_e.md NOT CREATED (python/python2
unavailable locally, run in the `python:2` container, which ships both
`/usr/local/bin/python` and `/usr/local/bin/python2`, per this round's
instruction not to mark undetermined)

derived: node -c script_node.js   (script has a module-scope IIFE
  writing pwn_node_c_iife.md AND a bare top-level writeFileSync writing
  pwn_node_c_toplevel.md)
exit=0 — neither pwn_node_c_iife.md nor pwn_node_c_toplevel.md created
(node -c is genuinely parse-only, including for an IIFE)

derived: nodejs -c script_nodejs.js   (same script, the separate v12
  binary distinct from node v22)
exit=0 — no file created

derived: docker run --rm -v /tmp/verify-r6:/work -w /work ruby:3-alpine sh -c
  'ruby -c script_ruby.rb'   (script has `BEGIN { File.write("pwn_ruby_c_begin.md", ...) }`
  AND a bare top-level File.write to pwn_ruby_c_toplevel.md)
ruby 3.4.10 ... Syntax OK
exit=0 — neither pwn_ruby_c_begin.md nor pwn_ruby_c_toplevel.md created
(Ruby's BEGIN block, unlike Perl's, does NOT run under -c; ruby
unavailable locally, run in ruby:3-alpine per this round's instruction)

derived: perl -c script_perl.pl   (BEGIN block writes pwn_perl_c_begin.md)
script_perl.pl syntax OK
exit=0 — pwn_perl_c_begin.md: "pwned-by-BEGIN"  (CREATED — perl -c is
genuinely dangerous, confirms round 6 was right to drop it; sanity
cross-check, not a give-back entry — perl -c/-e are both denied on the
current PR, verified at the gate level in section 2 below)
```

Every one of the 9 entries currently on round 6's give-back list (`bash
-e`, `sh -e`, `zsh -e`, `ruby -c`, `node -c`, `nodejs -c`, `python3 -e`,
`python -e`, `python2 -e`) produced **no sentinel write** under direct
execution. `perl -c` produced a write (confirming it is correctly *not*
on the give-back list any more). Interpreters unavailable locally
(`zsh`, `ruby`, `python`, `python2`) were run in containers
(`alpine:3.20`+`apk add zsh`, `ruby:3-alpine`, `python:2`), never marked
undetermined, per this round's explicit instruction.

### 2. Job side — all 10 `INTERPRETER_HEADS`, real gate subprocess, must be DENIED (enumerated, not sampled)

Built `/tmp/verify-r6/probe_board.sh` and `/tmp/verify-r6/probe_scope.sh`,
modeled on `core/hooks/tests/run-board-gate-tests.sh`'s/`run-scope-gate-tests.sh`'s
own `run()` harness, and ran each against both `/tmp/pr367-r6`
(`644443ab`) and `/tmp/main-r6` (`origin/main`):

```
derived: bash /tmp/verify-r6/probe_board.sh /tmp/pr367-r6
=== JOB SIDE: all 10 INTERPRETER_HEADS, real inline-exec flag, must be DENIED ===
OK   want=deny   got=deny   python3-c
OK   want=deny   got=deny   python-c
OK   want=deny   got=deny   python2-c
OK   want=deny   got=deny   bash-c
OK   want=deny   got=deny   sh-c
OK   want=deny   got=deny   zsh-c
OK   want=deny   got=deny   perl-e
OK   want=deny   got=deny   perl-c
OK   want=deny   got=deny   ruby-e
OK   want=deny   got=deny   node-e
OK   want=deny   got=deny   nodejs-e
=== GIVEN-BACK SIDE: dropped flag, must be ALLOW ===
OK   want=allow  got=allow  bash-e / sh-e / zsh-e / ruby-c / node-c /
                            nodejs-c / python3-e / python-e / python2-e
                            (all 9, all OK)
=== PERL FULLY OUT: both -c and -e denied ===
OK   want=deny   got=deny   perl-c-recheck
OK   want=deny   got=deny   perl-e-recheck
=== PURE-READ REGRESSION GUARD ===
OK   want=allow  got=allow  home-expansion (${HOME}/x)
OK   want=allow  got=allow  awk-print (awk '{print}' file)
=== FAST-PATH TRAP CHECK ===
OK   want=allow  got=allow  no-docs-substring (confirms the trap exists
                            and this round's own probes avoid it)
```

All 21 board-gate.sh cases pass on `644443ab`. The same script against
`/tmp/main-r6` (`origin/main`, pre-round-5 code) denies all 10 job-side
heads AND all 9 given-back entries uniformly (`FAIL want=allow
got=deny` on all 9 give-back names) — the expected pre-round-5 baseline,
confirming the give-back behavior is new to this PR, not baseline noise.

```
derived: bash /tmp/verify-r6/probe_scope.sh /tmp/pr367-r6
(same structure, same GATE=warrant/hooks/scope-gate.sh,
CLAUDE_PLUGIN_ROOT_CORE=<worktree>/core)
=== JOB SIDE ===: 10/11 OK, one FAIL:
FAIL want=deny   got=allow  python2-c   python2 -c "open(\"src/app.py\",\"w\").write(\"1\")"
=== GIVEN-BACK SIDE ===: all 9 OK (allow)
=== PERL FULLY OUT ===: both OK (deny)
```

The `python2-c` mismatch on `scope-gate.py` is **not new**: the identical
probe against `/tmp/main-r6` (`origin/main`) gives the identical `allow`
— `derived: bash /tmp/verify-r6/probe_scope.sh /tmp/main-r6` — confirming
`scope-gate.py`'s `UNANALYZABLE_WRITE_SHAPE` regex has never covered
`python2` under the `python3?` alternation, before or after any of
rounds 5/6 (this is the same gap round 5's `#369` record already
disclosed as non-blocking; independently re-confirmed here, not
relayed).

### 3. Perl fully out — direct confirmation, both flags, real subprocess

Covered inline above in sections 1 and 2: `perl -c` write-detection
(section 1, writes `pwn_perl_c_begin.md` — dangerous) and gate-level
`perl-c`/`perl-e`/`perl-c-recheck`/`perl-e-recheck` (section 2, all
`deny` on both `board-gate.sh` and `scope-gate.sh` against `644443ab`).
Both flags denied at both the interpreter-execution level and the
gate-subprocess level.

### 4. Disclosed pre-existing gaps — independently reproduced, confirmed non-regressions

Two gaps round 6's own record discloses as pre-existing and out of
scope. Both independently reproduced here rather than taken on the
builder's word:

- **`scope-gate.py` never covers `python2` for either flag letter**
  (section 2 above) — identical on `644443ab` and `origin/main`.
- **Bundled short flags bypass both gates' exact/end-anchored `-c`
  matching** (e.g. `perl -wc`):
```
derived: (probe script run against both worktrees, payload
  'cd docs/issue-3 && perl -wc reports/pwn.pl', board-gate.sh)
/tmp/pr367-r6 -> allow
/tmp/main-r6  -> allow      (identical — not a round-6 regression)

derived: perl -wc script_perl.pl   (real execution, BEGIN block present)
script_perl.pl syntax OK
exit=0 — pwn_perl_c_begin.md: "pwned-by-BEGIN"  (confirms -wc really
does execute the BEGIN block too, same class as -c)
```
Both gaps match round 6's own "Open findings" section exactly and are
outside this issue's acceptance criteria (single-token-expansion class
only) and the operator's ruling (no new flag-spelling matching this
round). Not blocking.

Also spot-checked the `round5-var-indirected-perl-c-allowed` test case
in `core/hooks/tests/run-scope-gate-tests.sh` (`P=perl; $P -c
some/script.pl` → allow) — this is the round 1-4 substitution/expansion
bypass class, explicitly out of scope for this round and this issue's
current acceptance criteria (task instructions: "do not add substitution
matching... all ruled out"); the in-repo comment at
`core/hooks/tests/run-scope-gate-tests.sh:298-303` already discloses it
correctly. Not a new finding.

### 5. Four standing invariants

```
derived: git diff ea8c498 -- core/hooks/board-gate.sh
  warrant/hooks/lib/scope-gate.py core/hooks/tests/run-board-gate-tests.sh
  core/hooks/tests/run-scope-gate-tests.sh | grep -E '^\+' | grep -iE '\brole\b'
(no output, exit=1) — no return of the retired role axis.

derived: cd /tmp/pr367-r6 && python3 -m pytest -q   (644443ab worktree)
FAILED tests/test_promoted_hooks.py::test_proposal_shape_gate_refuses_missing_sections
FAILED tests/test_promoted_hooks.py::test_survey_order_gate_refuses_proposal_without_survey_or_skip
FAILED tests/test_silent_failure_repros.py::test_A5_trailer_gate_quote_split_commit_is_detected
3 failed, 79 passed in 7.79s

derived: cd /tmp/main-r6 && python3 -m pytest -q   (origin/main worktree)
FAILED tests/test_promoted_hooks.py::test_proposal_shape_gate_refuses_missing_sections
FAILED tests/test_promoted_hooks.py::test_survey_order_gate_refuses_proposal_without_survey_or_skip
FAILED tests/test_silent_failure_repros.py::test_A5_trailer_gate_quote_split_commit_is_detected
3 failed, 79 passed in 6.44s
Failing-test-name sets: {test_proposal_shape_gate_refuses_missing_sections,
test_survey_order_gate_refuses_proposal_without_survey_or_skip,
test_A5_trailer_gate_quote_split_commit_is_detected} on both branches —
identical sets. No new bug.

derived: cd /tmp/pr367-r6 && bash core/hooks/tests/run-board-gate-tests.sh
FAIL   feasibility-spikes   want=allow got=deny
FAIL   ops-postmortems      want=allow got=deny
155 passed, 2 failed

derived: cd /tmp/main-r6 && bash core/hooks/tests/run-board-gate-tests.sh
FAIL   feasibility-spikes   want=allow got=deny
FAIL   ops-postmortems      want=allow got=deny
143 passed, 2 failed
Same 2 pre-existing failure names on both branches (test count differs
because 644443ab adds new test cases; the failing names themselves are
identical).

derived: cd /tmp/pr367-r6 && bash core/hooks/tests/run-scope-gate-tests.sh
62 passed, 0 failed

derived: bash /tmp/verify-r6/overhead_probe.sh /tmp/pr367-r6
ROOT=/tmp/pr367-r6 avg=46.53ms over 30 calls
derived: bash /tmp/verify-r6/overhead_probe.sh /tmp/main-r6
ROOT=/tmp/main-r6 avg=50.8ms over 30 calls
No overhead increase — 644443ab is ~4ms/call faster than origin/main on
this measurement, well within subprocess-startup noise, no regression in
either direction.

derived: cd /tmp/pr367-r6 && git diff ea8c498 --name-only
core/hooks/board-gate.sh
core/hooks/tests/run-board-gate-tests.sh
core/hooks/tests/run-scope-gate-tests.sh
docs/handbooks/board-gate-tests.md
docs/issue-233/reports/adversarial-review-5c3fbc55.md
docs/issue-233/reports/adversarial-review-a814c155.md
docs/issue-233/reports/adversarial-review-a814c155/2026-08-30-hunt-adversarial-review-a814c155.md
docs/issue-233/reports/secure-coding-input-validation-injection-defense-8c25e36e.md
docs/issue-233/reports/secure-coding-input-validation-injection-defense-bcd7fd6a.md
docs/issue-233/reports/secure-coding-input-validation-injection-defense-bcd7fd6a/hunt-round6-perl-c-give-back.md
warrant/hooks/lib/scope-gate.py
Nothing under any monitor/watch path. Monitor/watch machinery unbroken
and not quieter (untouched).
```

## Why

The task set for this round is explicitly about *how* verification is
done, not just its conclusion: round 5's two prior reviews split on
exactly this axis — one accepted `perl -c`'s documented meaning
("syntax-check-only") and passed it, the other built and ran a real
write-detection script and caught the `BEGIN`-block write. Round 6's own
record claims to have applied the executed-check method to every
remaining entry. Rather than accept that claim, this round rebuilt every
probe from scratch — a fresh write-detection script per interpreter, run
directly against the real binary (or a container when the binary was
unavailable locally, never marked undetermined), independent of round
6's own scripts or output. Every one of round 6's per-entry execution
claims reproduced identically under this round's independent probes,
including the two disclosed pre-existing gaps (confirmed non-regressions
by comparison against `origin/main`) and the Ruby-vs-Perl `BEGIN`-block
divergence (the exact mechanism that made round 5 wrong for Perl).

The 10-head, both-gate enumeration (rather than a sample) matters
because a per-head allowlist is a hole magnet: a head silently omitted
from `INLINE_FLAG_HEADS`/`UNANALYZABLE_WRITE_SHAPE` would deny nothing
for that head and nothing in the give-back tests would catch it, since
those tests only ever probe the heads someone remembered to write a
test for. Enumerating all 10 against both gates directly from the
`INTERPRETER_HEADS` tuple closes that gap for this round's verification
itself.

## What did not work

None — the scope-gate probe harness (`probe_scope.sh`) initially set
`CLAUDE_PLUGIN_ROOT_CORE` to the worktree root instead of
`<worktree>/core`, causing `scope-gate.sh` to fail sourcing
`gate-lib.sh` and exit 2 (deny) unconditionally for every case,
producing a false "all denied identically on both branches" result.
Caught immediately by running one case with output un-redirected
(`scope-gate.sh: cannot source gate-lib.sh`) before drawing any
conclusion from it, and fixed by pointing `CORE_ROOT` at
`$ROOT/core` (matching `core/hooks/tests/run-scope-gate-tests.sh`'s own
`CORE_ROOT="$(cd "$HERE/../.." && pwd -P)"` computation) before any
scope-gate finding in this record was drawn from it.

## Upstream basis

- `docs/issue-233/reports/secure-coding-input-validation-injection-defense-bcd7fd6a.md`
  (round 6 record, PR #367, commit `644443ab110e37f004ec2e477e1eddbd4e9fe003`)
  — the claims re-derived in this round.
- `docs/issue-233/reports/adversarial-review-a814c155.md` (round 5's
  blocking-finding review, PR #369) — the write-detection-by-execution
  methodology this round applies independently, not the methodology's
  output.
- `core/hooks/board-gate.sh`, `warrant/hooks/lib/scope-gate.py`,
  `core/hooks/tests/run-board-gate-tests.sh`,
  `core/hooks/tests/run-scope-gate-tests.sh` at `644443ab`, read in full.
- `origin/main` at `ea8c498` as the comparison baseline for all four
  standing invariants and both disclosed-gap non-regression checks.

## Open findings

None new. The two pre-existing gaps (scope-gate.py `python2` coverage;
bundled-short-flag detection on both gates) are round 6's own disclosed,
non-blocking, out-of-scope findings, independently reproduced and
confirmed identical on `origin/main` in this round — not opened here,
not reopened as blocking.

## Next steps

None. `loop_state: landed` — this round found no blocking issue; PR #367
at `644443ab` is not contradicted by this independent re-derivation.
