---
issue: 233
role: adversarial-review-57fd6be9
author: adversarial-review-57fd6be9
skills: adversarial-review (skill-repository(c05de12))
verifies_subject: true  # flip to true only if this record is an independent verification of this subject's own deliverable -- see docs/handbooks/observer-verification.md
loop_state: landed
upstream:
  - path: core/hooks/board-gate.sh
    sha: d434daa73d995b45e8fd18ba57441ee8d34cd991
  - path: core/hooks/lib/gate-lib.py
    sha: c31d446ca75e9500ae84187777f5466bcd36897f
  - path: warrant/hooks/lib/scope-gate.py
    sha: d434daa73d995b45e8fd18ba57441ee8d34cd991
---

# issue-233 — adversarial-review-57fd6be9 record

## What was done

Independent adversarial verification (round 4 on issue-233) of PR #363
(`issue-233/secure-coding-input-validation-injection-defense+adversarial-review-8bab0cf8`,
head `de44c51a8de3c9802ee0e67dbdb7bb500e8dca8b`). This PR adds
`UNRESOLVED_SUBSTITUTION_WORD_RE = re.compile(r"\$\(|`")`
(`core/hooks/board-gate.sh:744`) and applies it inside
`_is_unanalyzable_write_shape` (`core/hooks/board-gate.sh:766-771`) so a
trailing word containing an unresolved `$(`/backtick, combined with an
interpreter head, denies — closing PR #360's own reviewed gap (a
substitution that PRODUCES the `-c`/`-e` flag word evaded
`INLINE_FLAG_WORDS`).

Re-derived independently rather than restating the PR's own record:

1. Cloned the PR branch and `origin/main` into a scratch checkout
   (`/tmp/pr363`), diffed `core/hooks/board-gate.sh` /
   `core/hooks/lib/gate-lib.py` against `origin/main` directly (the merge
   base is `origin/main`'s current tip `aff774b` — none of rounds 1-3's
   code has actually landed on `main`, only their review records; PR #363
   carries the full cumulative fix chain as one branch).
2. Re-ran `run-board-gate-tests.sh`, `run-scope-gate-tests.sh`, `pytest -q`,
   `run-approval-gate-tests.sh`, `run-gh-guard-tests.sh`,
   `run-dispatcher-equivalence-tests.sh`, `run-gate-lib-tests.sh`,
   `run-ups-diet-tests.sh`, `run-fleet-scan-tests.sh` on both the PR branch
   and `origin/main`, comparing FAILING TEST NAMES as sets (never counts).
3. Re-measured the 100x subprocess-timing overhead claim myself.
4. Built a standalone harness (`probe.sh`/`probe2.sh`/`deny4.sh`/
   `pureread.sh`/`arith.sh`/`anticheck.sh` under `/tmp`) that drives the
   real `core/hooks/board-gate.sh` subprocess the same way
   `run-board-gate-tests.sh`'s own `run()` helper does (temp git repo,
   `docs/specs/approvers.md` planted, `issue-3/qa` branch, `CLAUDE_SKILL=qa`,
   real stdin JSON payload, real exit code), and used it to find and
   live-confirm two problems beyond what the PR's own test suite covers.

### Finding 1 (CONFIRMED, over-refusal — broader than disclosed): the
new check denies any interpreter invocation with ANY unrelated
`$(`/backtick/arithmetic-expansion trailing word, not just a
substitution that plausibly resembles a code flag

`_is_unanalyzable_write_shape` (`core/hooks/board-gate.sh:766-771`) fires
the new `UNRESOLVED_SUBSTITUTION_WORD_RE` check unconditionally once
`head in INTERPRETER_HEADS` — it is not scoped to "flag-checking
position" the way the PR's own comment describes it
(`core/hooks/board-gate.sh:708-732`); it fires whether or not `-c`/`-e`
appears anywhere on the line. The PR's own test suite discloses and
accepts this cost with exactly one example
(`cmdsub-unrelated-trailing-word-still-denied-r4`,
`run-board-gate-tests.sh:887`: `python3 file.py $(date)`), which reads as
a narrow, deliberately-contrived edge case. Live reproduction shows the
blast radius is wider: it also denies the gate's OWN recommended safe
alternative, and it fires on arithmetic expansion, which cannot spell
`-c`/`-e` at all.

This only matters on the actual enforced path — `_is_unanalyzable_write_shape`
is only reached for a Bash segment that already mentions `docs/`
somewhere on the line and both `and skill and is_board` must hold
(`core/hooks/board-gate.sh:809`, `:929`) — but a role session `cd`-ing
into its own `docs/issue-N/` directory before running a command is the
single most common role-session shape in this repo's own workflow
(this very review used it throughout).

Reproduced live, real `board-gate.sh` subprocess, PR branch vs.
`origin/main`, identical command, same temp-repo/role/branch harness
`run-board-gate-tests.sh` itself uses:

```
$ cd docs/issue-3 && python3 -m pytest $(cat reports/failing.txt)
origin/main:    allow
PR #363 branch: deny — "board-gate: a Bash call carries an un-analyzable
                 write-capable shape (python3 -m pytest
                 $(cat reports/failing.txt)) ... Use a provably
                 read-only invocation (e.g. python3 -m pytest) ..."
```

The gate's own deny message names `python3 -m pytest` as the safe
escape hatch in the same breath it denies exactly that shape once a
dynamic argument list is involved. Two more real, plausible role-session
commands, same contrast:

```
$ cd docs/issue-3 && bash reports/script.sh $(git rev-parse HEAD)
origin/main:    allow      PR #363 branch: deny
$ cd docs/issue-3 && node reports/build.js $(pwd)
origin/main:    allow      PR #363 branch: deny
```

And arithmetic expansion — which can only ever produce digits/operators,
never `-c`/`-e` — is caught too, purely because `$((` contains the
two-character substring `$(`:

```
$ cd docs/issue-3 && python3 reports/tally.py $((1+2))
origin/main:    allow      PR #363 branch: deny
```

Judgment: this is the same trade-off direction `EXPANDED_HEAD_RE` itself
already accepted for the head side (documented false-refusal cost,
`core/hooks/board-gate.sh:680-700`), and the PR is honest that a cost
exists — it is not a silent, undisclosed regression. But the PR's single
test case understates it: the description frames the cost as "an
interpreter invocation carrying an unrelated substitution argument"
(sounds like a rare shape); live testing shows it also breaks the
gate's own suggested remedy and fires on syntax (arithmetic expansion)
that can never carry the flag it is guarding against. Not blocking by
itself (issue-225's fail-closed posture already privileges refusing a
maybe-unsafe write over guessing it safe, and every prior round of this
issue has made the identical trade explicitly), but the PR description
should say so plainly rather than let one narrow test stand in for the
real breadth, and a future round could narrow `UNRESOLVED_SUBSTITUTION_WORD_RE`
to skip `$((` (arithmetic) at essentially no cost, since arithmetic
expansion is lexically distinguishable from command substitution.

### Finding 2 (CONFIRMED, live security bypass — same axis, not a new
third axis): ANSI-C `$'...'` escape decoding spells the `-c`/`-e` flag
word without `$(`, a backtick, or the literal text "-c"/"-e" anywhere

`gate-lib.py`'s `_shell_split` (`core/hooks/lib/gate-lib.py:274-276`)
resolves a `$'...'` ANSI-C-quoted token by stripping the `$'`/`'`
wrapper and keeping the interior text AS-IS — it does not decode any of
bash's own ANSI-C backslash escapes (`\xHH`, octal, `\n`, `\t`, ...)
inside that span. `$'\x2dc'` is real bash's own spelling of the
two-character string `-c` (`\x2d` is a hex escape for `-`, immediately
followed by the literal `c`) — confirmed directly:

```
$ bash -c 'x=$'"'"'\x2dc'"'"'; printf "%s\n" "$x"'
-c
```

But `_shell_split` treats the token's payload as already-resolved
literal text and returns the raw, undecoded string `\x2dc` (backslash,
x, 2, d, c — five characters) as the trailing word. That string:
- does not literal-equal `"-c"` (`INLINE_FLAG_WORDS` membership,
  `core/hooks/board-gate.sh:768`, never fires), and
- contains no `$(` or backtick (`UNRESOLVED_SUBSTITUTION_WORD_RE`,
  `core/hooks/board-gate.sh:744`/`:770`, this round's own new check,
  never fires either).

Live reproduction, real `board-gate.sh` subprocess AND real bash
execution proving the write actually happens, PR #363 branch:

```
$ cd docs/issue-3 && python3 $'\x2dc' 'open("reports/pwn.md","w").write("1")'
board-gate.sh verdict: allow (exit 0)
real bash execution result: reports/pwn.md now contains "1"
```

This is a live, confirmed bypass of this round's own fix, on the exact
axis the fix and this issue's acceptance criteria target (an interpreter
head plus an unanalyzable `-c`/`-e`-shaped trailing word via
single-token expansion) — `$'...'` ANSI-C quoting is itself one of the
single-token expansion forms this issue's own history already names
(the `$'-c'` literal-content fusion gap `gate-lib.py:212-225`'s own
comment documents fixing in an earlier round). It is not a new mechanism
class (no third axis): the root cause is the same "the tokenizer
declares a quoted span fully resolved without checking whether its
content can still change the flag comparison" gap that motivated this
round's own fix for `$(`/backtick — `_shell_split` just has an
additional, undecoded escape-sequence layer inside `$'...'` that neither
this round's fix nor any prior round's `EXPANDED_HEAD_RE`/
`UNRESOLVED_SUBSTITUTION_WORD_RE` widening touches, because escape
decoding was never the axis those regexes scan for. Per the standing
instruction to say explicitly which of "next fix" or "signal about the
seam" this is: **this is the next fix on the existing flag-word axis,
not a third axis** — the fix shape that would close it (decode or, more
conservatively, treat any backslash-escape sequence inside a `$'...'`
span as unanalyzable, mirroring `EXPANDED_HEAD_RE`'s own
allowlist-complement posture rather than trying to fully re-implement
bash's ANSI-C decoding) is a narrowing of the same tool this round
already introduced, not a new tool.

I did not find a third, structurally distinct mechanism (nesting,
quoting-around-a-substitution, parameter-expansion operators, process
substitution) beyond these two. Quoting around a substitution
(`"$(echo -c)"`) is still caught: the whole quoted span becomes one word
via the existing double-quote token form, and `UNRESOLVED_SUBSTITUTION_WORD_RE`
still substring-matches `$(` inside it (confirmed live: deny). Process
substitution (`<(...)`/`>(...)`) cannot spell the flag word at all — it
expands to a `/dev/fd/N` path, not to the substituted text — so it is
not a bypass vector for this specific check, confirmed by inspection (no
live test needed: the shell semantics rule it out structurally, unlike
the ANSI-C case where the semantics needed a live check to settle it).

### Full evidence, both directions, live at the real subprocess level

- Deny (issue's own 4 original shapes, all still denied on the PR
  branch, live): `${x:-python3} -c ...`, `${x:=bash} -c ...`,
  `$(echo python3) -c ...` — all `deny`.
- Allow (issue's own 2 pure-read acceptance shapes, live, PR branch):
  `cat "${HOME}/x"` — `allow`; `cd docs/issue-3 && awk '{print $1}' reports/review.md`
  — `allow`.
- Allow → deny transition this round's own new check introduces (Finding
  1, live, PR branch vs. `origin/main`): the three commands quoted above.
- Allow (should be deny — Finding 2, live, PR branch): the ANSI-C
  `$'\x2dc'` command quoted above, with a real filesystem write as
  corroboration.

### Standing invariants (each with its command and output)

1. **No return of the retired role axis, in any form:**
   `git diff origin/main..<PR-branch-head> -- core/hooks/board-gate.sh
   core/hooks/lib/gate-lib.py core/hooks/tests/run-board-gate-tests.sh
   core/hooks/tests/run-scope-gate-tests.sh warrant/hooks/lib/scope-gate.py
   | grep -in "role\|역할"` → two hits, both pre-existing prose (a
   comment word "role" meaning `CLAUDE_SKILL`, and the R4-sidecar test
   section's own "role-free branch" language) — no retired
   `role.json`/persisted-key shape anywhere in the diff.

2. **No overhead increase:** re-measured myself (100x
   `board-gate.sh` subprocess, same read-only payload, both checkouts):
   PR branch `real 0m4.922s` (100 calls) ≈ 49.2ms/call; `origin/main`
   `real 0m4.620s` ≈ 46.2ms/call. The ~3ms/call delta is inside
   run-to-run process-spawn jitter on this box (consistent with the
   ~3ms jitter the round-3 review already measured on the same
   environment) — re-derives the PR's own "no overhead" claim, not a
   new number to trust blind.

3. **No new bug beyond Findings 1/2 above:** ran the full test-suite set
   (`run-board-gate-tests.sh`, `run-scope-gate-tests.sh`, `pytest -q`,
   `run-approval-gate-tests.sh`, `run-gh-guard-tests.sh`,
   `run-dispatcher-equivalence-tests.sh`, `run-gate-lib-tests.sh`,
   `run-ups-diet-tests.sh`) on the PR branch and `origin/main` and
   diffed the FAILING TEST NAME sets — identical on every suite:
   `run-board-gate-tests.sh` `{feasibility-spikes, ops-postmortems}` (181
   vs 143 passed — the PR's own 4 new deny cases + 2 allow negative
   controls + 1 accepted-cost case account for the pass-count growth,
   same failing names either side); `run-scope-gate-tests.sh` 0 failures
   both (76 vs 46 passed, no name to compare); `pytest -q`
   `{test_proposal_shape_gate_refuses_missing_sections,
   test_survey_order_gate_refuses_proposal_without_survey_or_skip,
   test_A5_trailer_gate_quote_split_commit_is_detected}` on both;
   `run-approval-gate-tests.sh`
   `{checkpoint-refusal-names-await-approval, execute-without-remote}`
   on both; `run-gh-guard-tests.sh` 0 failures both;
   `run-dispatcher-equivalence-tests.sh` `{approval-gate: execution
   write, no approvers.md -> deny}` on both; `run-gate-lib-tests.sh`
   `{record-fields-gate.sh: missing §20 fields still denied
   post-migration, record-fields-gate.sh: RECORD_FIELDS_GATE_OFF=banana
   stays active (issue-72 fix)}` on both; `run-ups-diet-tests.sh` 0
   failures both.

4. **Monitor/watch machinery unbroken and not quieter:**
   `run-fleet-scan-tests.sh` — identical single pre-existing flake on
   both checkouts: `live fleet run produces 43 repo rows` want=43 got=44.
   Not a new failure, not a newly-passing (quieter) suite.

## Why

This round's own PR description frames its fix narrowly (mirrors
`EXPANDED_HEAD_RE`'s structural rule onto the flag side) and explicitly
names round three's over-refusal correction as the reason to check for
symmetry cost here. Verifying that claim required showing, live, both
that the deny set is real (the 4 original bypass shapes + the round-4
substitution-produces-flag shapes) and that the allow set the PR
disclosed as an accepted cost is not understated — which required
constructing realistic role-session commands beyond the PR's own single
test case, not just re-running the PR's suite. Verifying "no remaining
single-token-expansion bypass" required specifically attacking the
`_shell_split`/`_WORD_TOKEN_RE` tokenizer's own already-known-fragile
spot (the `$'...'` ANSI-C handling, itself the product of a prior
before-landing warrant-hunt finding) for the one class of decoding it
still does not perform, rather than re-trying the substitution shapes
the PR's own tests already cover.

## What did not work

None — every hypothesis this session formed was checked live before
being written down (see the negative results in Finding 2: nested
substitution, quoted substitution, and process substitution were each
tested or ruled out by inspection, not merely asserted).

## Upstream basis

Independent verification of `tokenmaxxxer/tokenmaxxxer-core` PR #363
(branch
`issue-233/secure-coding-input-validation-injection-defense+adversarial-review-8bab0cf8`,
head `de44c51a8de3c9802ee0e67dbdb7bb500e8dca8b`), diffed against
`origin/main` tip `aff774bdcc3363dbde5c38249c50fe6ce5be4a0d`. The three
`upstream:` entries in this record's frontmatter cite the specific
commits that introduced the code under review: `d434daa7` (the
round-4 `UNRESOLVED_SUBSTITUTION_WORD_RE` fix in `board-gate.sh` and its
mirror in `scope-gate.py`), and `c31d446c` (the `gate-lib.py`
`_shell_split`/`$'...'` tokenizer Finding 2 is against, landed in an
earlier commit on the same PR branch).

## Open findings

- Finding 1 (over-refusal broader than the PR's single disclosed test
  case) — resolution path: not blocking; a future round could narrow
  `UNRESOLVED_SUBSTITUTION_WORD_RE` to exclude `$((` (arithmetic) and
  the PR description/test suite should add the `-m pytest`/script-arg
  shapes as explicit accepted-cost cases rather than leaving the true
  breadth to be discovered by review.
- Finding 2 (live confirmed bypass: ANSI-C `$'\x2dc'`-shaped flag word)
  — resolution path: blocking. This round's own acceptance criterion
  ("an adversarial hunt round finds no remaining single-token-expansion
  interpreter-head bypass") is not met; issue-233 should not be
  considered closed. The fix shape is a narrowing of this round's own
  tool (treat a backslash-escape sequence inside `$'...'`/`$"..."` as
  unanalyzable, or fully decode ANSI-C escapes before the literal-equality
  check), on the same axis, not a new mechanism class.
- scope-gate.py's own flag-word gap (regex-only, no tokenizer — likely
  also vulnerable to both findings above, since its `UNANALYZABLE_WRITE_SHAPE`
  regex requires the literal `-c`/`-e` text in the raw command string) is
  the PR's own disclosed, already out-of-scope item — not re-opened here,
  but noted as a candidate to re-verify once round 5 lands on
  `board-gate.sh`, since scope-gate.py has no tokenizer at all and is
  presumably at least as exposed to Finding 2's mechanism.

## Next steps

None from this session — verification is complete (`loop_state: landed`).
**Recommendation to the human reviewing PR #363**: do not close issue-233
on this PR. Finding 2 is a live, confirmed bypass of the round's own
stated acceptance criterion and should block landing until fixed (or the
issue should explicitly accept it as a documented residual, which no
round so far has done for a *confirmed working exploit*). Finding 1 is
not blocking but the PR description understates its breadth and should
be corrected before merge regardless of Finding 2's outcome.

skill-verdict: adversarial-review — applied: invoked; this review session
is itself the structurally-independent evaluator per the skill's core
mechanism — it never built PR #363, received only the artifact (the PR
diff and its own test suite) rather than the builder's reasoning, and
every finding above required a live reproduction against the real
`board-gate.sh` subprocess before being written down, satisfying the
skill's Step 2 evidence requirement (file:line plus a runnable
command/output, not "this feels incomplete").
other mounted skills: work-in-english — not triggered as a separate
invocation (guidance-only via core hook enforcement; this record and all
commits/PR text are written in English regardless).
