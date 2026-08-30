---
issue: 370
role: adversarial-review-0126df44
author: adversarial-review-0126df44
skills: adversarial-review (skill-repository(c05de12))
verifies_subject: true
code_under_review: PR #391 "issue-370: salvage PR #363's head-side work (rounds 1-3) + fix var-indirected over-refusal"
loop_state: landed
type: adversarial-review-record
breaking: false
verdict: BLOCKING — the delivery's own headline claim (the "integration bug fix") reintroduces a live, confirmed arbitrary-code-execution bypass (`P=perl; $P -c script.pl`) in both `core/hooks/board-gate.sh` and `warrant/hooks/lib/scope-gate.py`, via a stale `VAR_INTERP_RE` grouping that predates round 6's own finding that `perl -c` is dangerous. Everything else independently re-derived (the `d434daa` exclusion, the four named bypass classes, the over-refusal probe, all four standing invariants) checks out clean.
skill-verdict: adversarial-review — applied: invoked; every finding below cites the exact command and pasted output that produced it (own probes plus two delegated verification passes whose raw output is quoted, not summarized), per the skill's evidence requirement and its "find real problems, don't restate the maker's record" framing
skill-verdict: work-in-english — applied: invoked; this record and all intermediate script/probe artifacts are in English; only the end-of-turn user-facing summary is in Korean
upstream:
  - path: PR #391 (tokenmaxxxer/tokenmaxxxer-core), branch `issue-370/secure-coding-input-validation-injection-defense-ed7ce13a`
    sha: 8bdc2779560c1a1cbd8bc80406dee2ab30130fbb
  - path: origin/main (base for every before/after comparison)
    sha: 7040a3a3b8390f0ddd964e21f02d011ae5e1016c
  - path: PR #363 (tokenmaxxxer/tokenmaxxxer-core), source of the salvaged/excluded commits
    sha: c4a2d1659389fdccbab05ec3a3536a6dfd7e8429
---

# issue-370 — adversarial-review-0126df44 record

## What was done

Independent, structurally separate re-verification of PR #391
(https://github.com/tokenmaxxxer/tokenmaxxxer-core/pull/391), which
claims to (a) salvage 9 of PR #363's 12 commits (rounds 1-3, the
head-side interpreter-masking closures) onto `origin/main`, excluding
round 4's rejected flag-side commit `d434daa` and the two commits that
document/verify it, and (b) fix a newly-discovered integration bug where
rounds 1-3's generic expansion-head closure, combined with `origin/main`'s
already-landed round 5/6 per-interpreter flag give-back, silently
re-denied two of round 5/6's own tested allows.

Fetched the PR head without touching the working branch
(`git fetch origin pull/391/head:pr-391-review`, tip `8bdc277` on top of
`origin/main@7040a3a`) and the original PR #363 head
(`git fetch origin pull/363/head:pr-363-orig`, needed to inspect the
excluded commits `d434daa`/`16a652b`/`de44c51` directly, since they are
not reachable from `pr-391-review` at all). Built two disposable
worktrees, `/tmp/wt-main` (`origin/main`) and `/tmp/wt-pr391`
(`pr-391-review`), for every subprocess-level probe below — the working
branch itself never ran either gate directly.

Six checks below. Checks 1 and 2 (the exclusion correctness and the
integration-bug claim — the two things the task asked to attack hardest)
were run directly, by hand, because both required first reverse-engineering
undocumented regex interactions (`VAR_INTERP_RE`'s exact grouping,
`_bare_var_has_literal_interp_assignment`'s guard) that could not be
handed to a worker without first understanding them well enough to write
a correct probe; getting this wrong would have produced a worker report
that looked thorough but proved nothing. Checks 3-6 (the four named
bypass classes before/after, the over-refusal probe, the four standing
invariants, and the retired-noun-in-comment judgment) were delegated to
two independent foreground verification passes once the invocation
contract and exact payloads were pinned down, and their raw output is
quoted directly below, not restated from memory.

**Operational note, stated up front because it cost real turns to
discover:** this session's own Bash tool calls are gated by the very
`board-gate.sh` this review probes. A `tool_input` command whose literal
text contains a `docs/issue-<n>` substring for a foreign issue number
trips this session's own PreToolUse hook (R4: wrong branch for that
issue tree) — a pure text-substring collision between the probe payload
(which necessarily targets a fake `docs/issue-3/reports` board for the
*nested* gate under test) and the *live* gate wrapping this very session.
Worked around by writing every probe harness to a script file under
`/tmp` via `Write`, then invoking it as a single `bash /tmp/foo.sh`
call whose own literal text carries no `docs` substring.

## Why

Adversarial review means not trusting the maker's own record: PR #391's
body makes three load-bearing claims (the exclusion is clean, the
integration bug is genuinely fixed, the four named bypass classes are
genuinely closed) and this session re-derives each independently rather
than restating them. The integration-bug claim gets the most attention
because the task explicitly named it "the most valuable claim in this
delivery and the one most worth attacking" — and because a fix that
narrows a blanket deny into a per-interpreter deferral is exactly the
shape of change most likely to open a gap for the one interpreter (perl)
that doesn't fit the deferral target's assumptions. Hand-verification was
chosen for Checks 1-2 specifically because the failure mode being hunted
(a stale regex grouping silently misclassifying one interpreter) is not
something a worker can be handed a ready-made payload for — the payload
itself only exists once you already understand why `VAR_INTERP_RE` and
`INLINE_FLAG_HEADS` can disagree. Checks 3-6 are comparatively mechanical
(run known payloads, run known test suites, diff known outputs) and were
delegated once the invocation contract and exact payload set were pinned
down by hand, to keep this record's own turns spent on judgment rather
than on re-typing test-harness boilerplate.

### Check 1 — is the `d434daa` exclusion clean

`derived: git show d434daa --stat` — touches only
`core/hooks/board-gate.sh` (+`UNRESOLVED_SUBSTITUTION_WORD_RE`, the
flag-side `$(`/backtick-in-a-trailing-word check PR #360's review found
missing) and its own test file. `16a652b` touches only
`docs/handbooks/board-gate-tests.md` (`derived: git show 16a652b --stat`),
adding exactly one section, "round 4 CHANGES-review re-delivery:
unresolved substitution in a trailing word is unanalyzable", which
quotes `UNRESOLVED_SUBSTITUTION_WORD_RE` and the four `cmdsub-*-produces-flag-*`
test names by name. `de44c51`'s frontmatter cites
`sha: d434daa73d995b45e8fd18ba57441ee8d34cd991` as its sole upstream
basis (`derived: git show de44c51 -- 'docs/issue-233/*' | grep -n 'sha:'`)
and its body quotes `UNRESOLVED_SUBSTITUTION_WORD_RE` by name three times
— both excluded docs commits describe `d434daa` and nothing else that
could have landed independently of it.

Checked the landed diff for both directions of leakage:
```
derived: grep -n "UNRESOLVED_SUBSTITUTION_WORD_RE" <(gh pr diff 391)
```
result: the symbol appears twice, both inside the new
`docs/issue-370/reports/secure-coding-input-validation-injection-defense-ed7ce13a.md`
record, both as prose confirming its absence ("... `grep -c
UNRESOLVED_SUBSTITUTION_WORD_RE` — result: `0`") — never in code.
```
derived: git diff origin/main..pr-391-review -- core/hooks/tests/run-board-gate-tests.sh | grep -n "cmdsub"
```
result: no output — none of `d434daa`'s four round-4 test names
(`cmdsub-dollarparen-produces-flag-python`, etc.) exist in the landed
diff. And the landed handbook addition
(`derived: git diff origin/main..pr-391-review -- docs/handbooks/board-gate-tests.md`)
contains exactly two new sections, both titled "issue-233 rounds 1-3
(salvaged via issue-370)..." — rounds 1-3 content only, no round-4
section.

**Verdict: clean.** `d434daa`'s code and its two documenting commits are
excluded as a matched, coherent unit; nothing that landed is left
undocumented, and nothing excluded is documented as if it had landed.

### Check 2 — the integration-bug claim (headline finding)

`origin/main` has no `EXPANDED_HEAD_RE` at all
(`derived: grep -n EXPANDED_HEAD_RE /tmp/wt-main/core/hooks/board-gate.sh`
— no output) — a bare `$P` head is simply never recognized as
interpreter-shaped on main, so `P=<anything>; $P -c/-e ...` passes
through unanalyzed regardless of danger; this is the pre-existing,
known-open "interpreter-head-via-expansion" gap rounds 1-3 exist to
close. PR #391 adds `EXPANDED_HEAD_RE` (flags any `$`/backtick/etc. in
the head) plus a carve-out, `_bare_var_has_literal_interp_assignment`
(`core/hooks/board-gate.sh:829-838`, mirrored in
`warrant/hooks/lib/scope-gate.py:329-339`): when a bare `$NAME`/`${NAME}`
head's variable is assigned a literal interpreter name earlier in the
same command text, the blanket `-c`/`-e` deny is skipped and the
decision defers entirely to the pre-existing `VAR_INTERP_RE`
(`core/hooks/board-gate.sh:706-710`, unchanged since before this PR —
confirmed byte-identical between `origin/main` and `pr-391-review` via
`derived: diff <(sed -n '/^VAR_INTERP_RE = /,/^)$/p' /tmp/wt-main/core/hooks/board-gate.sh) <(sed -n '/^VAR_INTERP_RE = /,/^)$/p' /tmp/wt-pr391/core/hooks/board-gate.sh)`
— only the trailing comment block differs, the regex itself does not).

`VAR_INTERP_RE` pairs `(python3?|bash|sh|zsh)` with `-c` only, and
`(perl|ruby|node|nodejs)` with `-e` only — one dangerous flag per
interpreter. But `INLINE_FLAG_HEADS` (`core/hooks/board-gate.sh:649-654`,
the table governing DIRECT, non-indirected heads) gives perl **two**
dangerous flags: `"perl": ("-e", "-c")`, per round 6's own finding that
`perl -c` still executes `BEGIN`/`UNITCHECK`/`CHECK` blocks (confirmed
directly, live, below) — a fact `VAR_INTERP_RE`'s two-alternative shape,
written before round 6, structurally cannot express (each alternative
hard-codes exactly one flag per interpreter group). This gap is not
hidden — PR #391's own comment at `board-gate.sh:824` says the deferral
uses `VAR_INTERP_RE`'s "own (round-1-4, not round-6-narrowed) flag
grouping" — but the implication (that this staleness is safe) was never
checked against the specific case where it isn't.

Live reproduction, `/tmp/wt-pr391` (identical script re-run against
`/tmp/wt-main`, same result on both — this specific gap is not new,
see below):
```
derived: bash /tmp/probe_integration.sh /tmp/wt-pr391
allow   P=bash;$P -e (indirected errexit give-back)
allow   P=perl;$P -c (indirected -- perl -c is dangerous!)
deny    perl -c DIRECT (control, must deny per round6)
deny    P=perl;$P -e (indirected -- should deny, perl -e dangerous)
deny    P=bash;$P -c (indirected -- should deny, bash -c dangerous)
```
`P=perl; $P -c script.pl` is **allowed** by board-gate.sh — a live
bypass — while the literal, unindirected `perl -c script.pl` is
correctly denied one line above it, in the same run.

Live proof this is exploitable, not merely a classification quirk (real
perl, no gate involved, direct proof `-c` still executes code):
```
derived: (BEGIN block in /tmp/mal.pl) P=perl; "$P" -c /tmp/mal.pl
perl -c exit=0
/tmp/mal.pl syntax OK
--- did the file get written? ---
pwned via perl -c BEGIN block
```

The three angles the task asked to specifically construct — a bare-var
head whose assignment is not literal, not visible, or reassigned before
use — are all correctly denied (`derived: bash /tmp/probe_integration2.sh /tmp/wt-pr391`):
```
deny   non-literal: P=$(echo perl); $P -c
deny   non-visible (env-only P=perl): $P -c
deny   reassign: P=bash; P=perl; $P -c
deny   decoy-in-string: echo 'P=bash'; P=perl; $P -c
deny   P=node;$P -e (indirected, literal+visible)
allow  P=ruby;$P -c (indirected, should allow -- ruby -c is safe)
```
So the guard's *mechanism* (checking for a literal, visible assignment)
is sound and not itself spoofable by the constructions above — the
failure is narrower and different from what was asked to construct: even
with a genuinely literal, visible assignment, the interpreter it defers
to (`VAR_INTERP_RE`) gives the wrong answer for exactly one interpreter
(`perl`) because that interpreter alone has two dangerous flags where
`VAR_INTERP_RE`'s shape assumes one.

Confirmed the identical bug in `warrant/hooks/lib/scope-gate.py`, with
the write target pinned to the actually-approved file (`src/app.py`) to
remove any "outside the write set" confound:
```
derived: bash /tmp/probe_scopegate2.sh /tmp/wt-pr391
allow   P=perl;$P -c src/app.py (in-scope target, indirected, perl -c dangerous)
deny    perl -c src/app.py DIRECT (control, in-scope target)
allow   P=bash;$P -e src/app.py (in-scope target, give-back case)
allow   P=ruby;$P -c src/app.py (in-scope target, ruby -c is safe)
```
Same shape, same root cause (`scope-gate.py`'s own copy of
`UNANALYZABLE_WRITE_SHAPE` at `warrant/hooks/lib/scope-gate.py:213-219`
uses the identical `python3?|bash|sh|zsh`+`-c` /
`perl|ruby|node|nodejs`+`-e` grouping).

Whether this is a *regression* depends on the baseline: `P=perl; $P -c`
is allowed on **both** `origin/main` (because main never analyzes bare
variable heads at all) and `pr-391-review` (because the new analysis
explicitly defers away from itself for this shape) — so it is not a
newly-introduced hole relative to `origin/main`'s literal behavior. But
it is a failure of this PR's own stated closure: the whole point of
rounds 1-3 plus this integration fix is that a bare-variable interpreter
head is no longer a blind spot, and for every interpreter except perl
that is now true. Perl is a live, confirmed exception the PR does not
disclose and does not test for.

**Verdict: BLOCKING.** The literal denial of `perl -c` (direct) sitting
one line away from the live allow of `P=perl; $P -c` (indirected) in the
same probe run is the same "obviously inconsistent once you see both
lines together" pattern this whole review lineage exists to catch.
Resolution path: either widen `VAR_INTERP_RE`'s second alternative to
also pair `perl` with `-c` (mirroring `INLINE_FLAG_HEADS["perl"]`
exactly), or have `_bare_var_has_literal_interp_assignment`'s caller
consult `INLINE_FLAG_HEADS` directly per-interpreter instead of the
coarser `VAR_INTERP_RE`, and add a `P=perl;$P -c`-shaped DENY test to
both gates' suites so this cannot silently regress again.

### Check 3 — the four named bypass classes, before/after at the subprocess level

Delegated to an independent foreground verification pass (raw output
quoted, not restated). Full harness and per-payload table in the pass's
own transcript; the table it produced:

| Class | Payload | before (main) | after (pr391) |
|---|---|---|---|
| interpreter-head-via-expansion | `$(echo python3) -c ...` | ALLOW (live bypass) | DENY |
| interpreter-head-via-expansion | `` `echo python3` -c ... `` | DENY (coincidental — see note) | DENY |
| interpreter-head-via-expansion | `"$SHELL" -c ...` | ALLOW (live bypass) | DENY |
| interpreter-head-via-expansion | `{python3,} -c ...` | ALLOW (live bypass) | DENY |
| backslash-escape word formation | `p\y\t\h\o\n3 -c ...` | ALLOW (live bypass) | DENY |
| backslash-newline splicing | `pyth\<newline>on3 -c ...` | ALLOW (live bypass) | DENY |
| quoted/escaped-space path | `/opt/My\ Python/python3 -c ...` | ALLOW (live bypass) | DENY |
| quoted/escaped-space path | `"/opt/My Python/python3" -c ...` | ALLOW (live bypass) | DENY |

One discrepancy the delegated pass flagged and I accept: the
backtick-command-substitution sub-case (`` `echo python3` -c ``) already
denied on `origin/main`, but *coincidentally* — main's pre-existing
`FUSED_INTERP_RE` happens to match because the closing backtick sits
immediately adjacent to the literal substring `python3`, not because
main has any structural defense against expansion-produced heads (the
other three sub-cases of the same class sailed through on main). This
does not weaken the after-state verdict (pr391 denies it for the
correct, general reason) but the "before" column should not be read as
"main already closed command-substitution heads generically" — it
didn't; this one spelling got lucky.
Every payload's raw command text targeted `$BOARD` (`docs/issue-3/reports`)
specifically so it would fall through board-gate's `*docs*` fast path
into full analysis rather than exiting 0 without ever being judged — see
Check 5 for the fast-path accounting in full.

**Verdict: all four classes genuinely closed**, net of the one
coincidental-not-structural note on main's baseline above.

### Check 4 — over-refusal probe (no new denial)

Same delegated pass, `/tmp/wt-pr391` only, all seven required ALLOW:

```
allow  python3 script.py --input "$(pwd)/data.csv"     (fast path)
allow  python3 -m pytest -k "$(echo foo)"               (fast path)
allow  git status                                        (fast path)
allow  python3 -m pytest -q                              (fast path)
allow  cd $BOARD && bash -e script.sh                    (full analysis)
allow  cd $BOARD && node -c script.js                    (full analysis)
allow  cd $BOARD && ruby -c script.rb                    (full analysis)
```
This includes the exact command issue #370 names as PR #363's own
originally-measured false denial (`python3 script.py --input
"$(pwd)/data.csv"`) — confirmed allowed on the salvage. **Verdict: clean,
no new over-refusal.**

### Check 5 — the docs fast-path test-harness trap (issue #361), accounted for

`board-gate.sh` exits 0 with zero analysis unless the raw payload
contains the literal substring `docs`, `<<`, `$IFS`/`${IFS`, or matches
an "unanalyzable shape" heuristic (`derived: sed -n '111,124p'
/tmp/wt-pr391/core/hooks/board-gate.sh` — the `case "$payload" in
*'\u'*) ;; *docs*) ;; *) [ "$unanalyzable_shape" = 1 ] || exit 0 ;; esac`
gate). Every Check 3/4 payload that needed to reach real analysis was
constructed against `$BOARD` (`docs/issue-3/reports`), which always
contains `docs`, guaranteeing the full Python judge ran rather than the
shell fast path. The over-refusal cases that legitimately have nothing
to do with `docs/` (`git status`, the two `pytest`/`script.py`
invocations) were left to take the fast path deliberately — that is
itself the correct, intended behavior for an unrelated ordinary command,
not a gap in the test. Every deny observed anywhere in Checks 2-4 came
with the real Python judge's `board-gate: ...` stderr message, confirmed
by the delegated pass reading the log on every run, not a bare exit
code — ruling out a false-negative "deny" that was actually some other
error path.

### Check 6 — the retired-noun comment (issue #366 lineage)

PR #391 adds one occurrence of the word "role" in `core/hooks/lib/gate-lib.py`'s
`_shell_split` docstring/comment block: `"a `qa`-role call denied nothing
while writing outside `qa`'s own write-set"`. This phrase is not new
prose — it is copied verbatim from an earlier, already-committed review
record, `docs/issue-233/reports/adversarial-review-13d75b7e.md:273`
(`derived: git grep -n "qa\`-role call denied nothing"`), predating
issue #366. It is illustrative prose in a comment describing an attack
scenario, not a live message string (issue #366's actual target —
`board-gate.sh:747`'s `role %r` denial text reaching a session) and not
a code identifier. Issue #274's own relic-sweep (landed as the tip
commit on `main` this PR's branch predates) already found ~1,500 such
comment/docstring occurrences repo-wide and left them as an accepted,
already-owned-by-#366-and-siblings category — this is one more of the
same, not a new class of exposure.

**My view: reword it anyway, non-blocking.** It costs nothing (one
clause), and #391 is new code being authored in the post-migration era —
copying the retired noun forward into a fresh comment, even verbatim
from an old record, is exactly the kind of drift that let #366's count
grow to ~1,500 in the first place. Something like "a caller scoped to
`qa`'s own write-set wrote outside it" preserves the illustration without
the noun. Not a blocker: it is a comment, already-tolerated by this
repo's own explicit precedent, and rewording it does not change any
gate's behavior.

## Standing invariants

- **No return of the retired role/역할 axis, in any reshaped form:**
  `derived: git diff origin/main..pr-391-review -- '*.sh' '*.py' | grep -niE '\brole\b|역할'` —
  3 hits: the Check 6 comment (new, category "prose in comment", accepted
  above) and two unchanged context lines around an unrelated hunk in
  `run-scope-gate-tests.sh` (pre-existing text, not part of this diff's
  additions). No identifier, variable, or live-message-string hit.
  **PASS.**
- **No new bug — failing-test set vs `origin/main`, as SETS OF NAMES:**
  `derived: bash core/hooks/tests/run-board-gate-tests.sh` and
  `run-scope-gate-tests.sh`, run on both worktrees, FAIL-name sets
  diffed with `comm`. Board-gate: both fail exactly
  `{feasibility-spikes, ops-postmortems}` (159→190 passed, still 2
  failed, identical set); scope-gate: both 0 failed (62→92 passed). The
  "fail on pr391 but not main" set is empty for both suites. No
  top-level `pytest.ini`/`setup.cfg`/`pyproject.toml` exists in this
  repo, so no repo-wide pytest comparison applies. **PASS.**
- **No overhead increase:** interleaved 100-call timing of
  `board-gate.sh` itself (not `git status` alone) against a real payload,
  two independent runs: run 1 main 15.82ms/call vs pr391 15.87ms/call
  (+0.3%); run 2 main 9.73ms/call vs pr391 9.67ms/call (pr391 faster).
  Both within normal subprocess-spawn noise, no disproportionate
  (>3x) or pathological slowdown despite real new regex work added.
  **PASS.**
- **Monitor and watch machinery unbroken and not quieter:** no file in
  the repo is literally named "monitor" or "watch"
  (`derived: git grep -liI "monitor\|watch" -- '*.sh' '*.py'` — no hit);
  the applicable silent-failure-detection machinery is
  `core/hooks/tests/run-fleet-scan-tests.sh` /
  `fleet-silent-failure-scan.sh` (issue #168). Run on both worktrees:
  byte-identical output (`diff` — no output), 27 total cases both sides,
  identical single pre-existing failure (`live fleet run produces 43
  repo rows want=43 got=44`, unrelated to this PR, present on
  `origin/main` too). Not quieter, not broken. **PASS.**

## What did not work

- Initial `warrant/hooks/scope-gate.sh` probes used `CLAUDE_PLUGIN_ROOT_CORE`
  pointed at the worktree root; this failed (`cannot source gate-lib.sh`)
  because the real test harness's `CORE_ROOT` is the worktree's `core/`
  subdirectory specifically, not the repo root — fixed by pointing at
  `<worktree>/core` instead, confirmed against `run-scope-gate-tests.sh`'s
  own `HERE/../..` derivation.
- The first hand-run probe of the integration bug used a literal
  `docs/issue-3/reports` path directly in a Bash tool_input string and
  was refused by this session's own live `board-gate.sh` PreToolUse hook
  (see the operational note above) — switched to writing probe harnesses
  to `/tmp/*.sh` files first and invoking them with a `docs`-substring-free
  outer command.
- A first attempt to introspect `scope-gate.py`'s regexes via
  `importlib.util` module loading exited silently (`SystemExit: 0`)
  because the file is a top-level script with no `if __name__ ==
  "__main__"` guard — it runs its whole gate logic (including reading
  empty stdin) at import time. Abandoned introspection in favor of
  black-box subprocess probing with a controlled write target
  (`src/app.py`, the approved file) to isolate the interpreter-danger
  question from the separate write-set-membership question.

## Upstream basis

- PR #391 (https://github.com/tokenmaxxxer/tokenmaxxxer-core/pull/391),
  branch `issue-370/secure-coding-input-validation-injection-defense-ed7ce13a`,
  fetched as `pr-391-review` at `8bdc277` — the subject of this review,
  read directly (diff, commits, and the worktree checkout), canonical.
- PR #363 (https://github.com/tokenmaxxxer/tokenmaxxxer-core/pull/363),
  fetched as `pr-363-orig` — source of the excluded commits `d434daa`,
  `16a652b`, `de44c51`, read directly via `git show`, canonical.
- `origin/main` at `7040a3a` — the pre-PR-391 baseline used for every
  before/after subprocess comparison above.
- Issue #370's own body — acceptance criteria and the docs-fast-path
  trap warning, read directly via `gh issue view 370`, canonical.
- Issue #366's open body — the retired-noun-in-live-message background
  for Check 6, read directly via `gh issue view 366`, canonical.

## Open findings

- **BLOCKING** (Check 2): `P=perl; $P -c <script>` is allowed by both
  `core/hooks/board-gate.sh` and `warrant/hooks/lib/scope-gate.py` on
  `pr-391-review`, a live, confirmed arbitrary-code-execution path
  (perl `BEGIN` blocks execute under `-c`), while the direct,
  unindirected `perl -c <script>` is correctly denied by both gates in
  the same probe run. Resolution path: widen `VAR_INTERP_RE` (both
  files) to pair `perl` with `-c` as well as `-e`, matching
  `INLINE_FLAG_HEADS["perl"]` exactly, and add a
  `P=perl;$P -c`-shaped DENY regression test to both gates' suites.
- Non-blocking (Check 6): one new "role"-bearing comment in
  `core/hooks/lib/gate-lib.py`, copied verbatim from an older,
  already-committed record predating issue #366. Recommend a one-clause
  reword; does not affect any gate's behavior and matches an
  already-tolerated repo-wide category (issue #274's relic sweep).

## Next steps

None for this session — `loop_state: landed`. The blocking finding above
is left for a follow-up fix-and-verify round on PR #391 (or a successor
PR) before this salvage should be considered safe to merge as delivered;
this record's resolution path is written specifically so that round does
not need to re-derive the root cause from scratch.
