---
issue: 370
role: adversarial-review-b4a7cf19
author: adversarial-review-b4a7cf19
skills: adversarial-review (skill-repository(c05de12))
verifies_subject: true  # independent verification of PR #398's own deliverable (issue-370 round 2)
loop_state: landed
upstream:
  - path: core/hooks/board-gate.sh
    sha: 14ae52af1146e2b171bfbd48b9bce984aa6b4e41
  - path: core/hooks/lib/gate-lib.py
    sha: 14ae52af1146e2b171bfbd48b9bce984aa6b4e41
  - path: warrant/hooks/lib/scope-gate.py
    sha: 14ae52af1146e2b171bfbd48b9bce984aa6b4e41
  - path: core/hooks/tests/run-scope-gate-tests.sh
    sha: 14ae52af1146e2b171bfbd48b9bce984aa6b4e41
---

# issue-370 — adversarial-review-b4a7cf19 record

skill-verdict: adversarial-review — applied: invoked; this entire record is the evaluator side of the protocol — a structurally independent session verifying PR #398 (round 2, a deliverable made by a different role session) with no shared context with its builder. Evidence gathered by three foreground `freelunch:freelunch-worker` subagents (raw command/output, no baked-in interpretation) plus direct re-derivation of the load-bearing claims myself where the workers' own findings needed cross-checking against each other or against source.
other mounted skills: not triggered (work-in-english followed as house style but not invoked as a Skill call; merge-gates/model-routing/verify-finding-record/conformance-review-finding-record not applicable — no merge-gate design, no delegated-work acceptance decision beyond this session's own re-derivation, no defect-verification or conformance-verdict record was requested)

## What was done

Independently verified `tokenmaxxxer/tokenmaxxxer-core#398` (issue-370 round 2, branch head `14ae52a`, base/merge-base `7040a3a`), which supersedes #391 and carries the full 11-commit rounds-1-3 salvage plus round 2's own two commits (`7ec6094`, `14ae52a`) onto a fresh branch. Re-derived the structural claim, the regression direction, guard variants, the retired-noun comment, the over-refusal probe, and four standing invariants — did not restate #395's own findings, which this task said already held for the salvage itself.

### 1. Structural claim — CONFIRMED, exhaustively, on both gates

canonical: `git show 14ae52a:core/hooks/board-gate.sh` lines 649-654 (direct-form
authoritative mapping, `INLINE_FLAG_HEADS`):
```python
INLINE_FLAG_HEADS = {
    "python3": ("-c",), "python": ("-c",), "python2": ("-c",),
    "bash": ("-c",), "sh": ("-c",), "zsh": ("-c",),
    "perl": ("-e", "-c"), "ruby": ("-e",),
    "node": ("-e",), "nodejs": ("-e",),
}
```
11 (interpreter, flag) pairs. `VAR_INTERP_RE` (lines 722-731) now builds
`_VAR_INTERP_C_NAMES`/`_VAR_INTERP_E_NAMES` by iterating this same dict —
`derived: git diff 7040a3a..14ae52a -- core/hooks/board-gate.sh` shows the
prior version spelled one combined name list independent of the table
(`python3?|bash|sh|zsh|perl|ruby|node|nodejs` for both `-c`/`-e`), which is
exactly why `perl` drifted for `-c`.

Same shape in `scope-gate.py` (lines 186-191 direct-form, 233-236
var-indirected): `_C_FLAG_INTERP_NAMES`/`_E_FLAG_INTERP_NAMES` are shared
string constants feeding both the direct-form `UNANALYZABLE_WRITE_SHAPE`
alternatives and the var-indirected `VAR_INTERP_RE`-equivalent — one
source, not two.

Exhaustive pair matrix, real subprocess (`bash core/hooks/board-gate.sh`
and `warrant/hooks/scope-gate.sh` fed JSON payloads, the same harness
contract `core/hooks/tests/run-board-gate-tests.sh`/`run-scope-gate-tests.sh`
use), covering every one of the 11 board-gate pairs and 10 scope-gate pairs
(perl→`-e`/`-c` counted once per gate): direct form and var-indirected form
(`P=<name>; $P <flag> ...`) matched exactly for every pair on both gates —
no pair from the direct-form mapping escapes via the indirected route,
including the exact claimed bug:
```
$ P=perl; # scope-gate.py, real subprocess
  echo '{"tool_name":"Bash","tool_input":{"command":"P=perl; $P -c script.pl"}}' \
    | WARRANT_PAYLOAD=... python3 warrant/hooks/lib/scope-gate.py
  -> exit 2 (deny)
```
verdict: CONFIRMED, no leak on either gate, for any interpreter/flag pair
in the direct-form mapping.

### 2. Round 5/6 regression check — CONFIRMED, no regression

derived: ran both `P=bash; $P -e ...` and `P=perl; $P -c ...` (direct and
var-indirected) against both gates, before and mentally cross-checked
against round 5/6's give-back rationale (comments at board-gate.sh
622-648): `bash -e`/`sh -e`/`zsh -e` (errexit, not inline code) allow;
`ruby -c`/`node -c` (syntax-check only) allow; `perl -c` (runs
`BEGIN`/`UNITCHECK`/`CHECK` blocks) denies; `python3 -e` (flag doesn't
exist for python3) allows. Every answer, direct and var-indirected, on
both gates, matches this baseline. `P=bash; $P -e ...` — the specific case
board-gate.sh's own new comment (§6 below) names as the regression this
salvage would otherwise reopen — stays allowed. No previously-working
command's answer changed.

### 3. Over-refusal probe — CONFIRMED, still allowed

derived: `bash core/hooks/tests/run-board-gate-tests.sh` includes and
passes `round5-script-computed-input` (`python3 script.py --input
"$(pwd)/data.csv"`-shaped) and the pytest computed-arg case
(`python3 -m pytest -k "$(echo foo)"`) — both `ok ... allow` at `14ae52a`.
This is the exact "#363's branch denied this" class named in the issue's
own acceptance criteria; it is unaffected by round 2.

### 4. Guard variants — CONFIRMED on scope-gate.py; one caveat on board-gate.sh

- **Non-literal (command substitution)**: `P=$(echo perl); $P -c f.pl`
  denies on both gates.
- **Reassignment**: `P=bash; P=perl; $P -c f.pl` denies on both gates
  (the regex is adjacency-insensitive — any qualifying `NAME=interp`
  assignment anywhere before `$NAME ... -flag` trips it).
- **Non-visible assignment** — this is where the two gates diverge, and
  where "non-visible" needs precision. `scope-gate.py` has no shell-level
  pre-filter (`warrant/hooks/scope-gate.sh` unconditionally invokes
  `python3 scope-gate.py` for every call once armed — `canonical: cat
  warrant/hooks/scope-gate.sh`, no `UNANALYZABLE_*`-style short-circuit
  anywhere in it) — so its analysis always runs, and correctly denies
  even when no assignment is textually present at all.

  `board-gate.sh` is different: it has a shell-level fast path (lines
  107-124) that skips invoking `python3` entirely unless the raw payload
  text contains BOTH a literal interpreter name (`UNANALYZABLE_HEAD_RE`)
  AND a literal `-c`/`-e` (`UNANALYZABLE_FLAG_RE`). I re-derived this
  myself, independent of the worker's report, against a fresh worktree
  fetch of `14ae52a`:
  ```
  $ payload='{"tool_name":"Bash","tool_input":{"command":"$P -c f.pl"},"cwd":"<repo>"}'
  $ printf '%s' "$payload" | env CLAUDE_PROJECT_DIR=<repo> CLAUDE_PLUGIN_ROOT=<plugin> \
      CLAUDE_SKILL=qa /bin/bash core/hooks/board-gate.sh; echo $?
  0            # ALLOW — no literal interpreter name anywhere in the payload text
  $ payload='{"tool_name":"Bash","tool_input":{"command":"P=perl; $P -c f.pl"},"cwd":"<repo>"}'
  $ printf '%s' "$payload" | env ... /bin/bash core/hooks/board-gate.sh; echo $?
  2            # DENY — assignment present as literal text (even non-adjacent to $P)
  ```
  PR #395's own guard-variant #2 test (recovered via `WebFetch` of its raw
  record, `issue-370/adversarial-review-0126df44` branch, since a direct
  `gh api .../contents/docs/issue-370/...` read is refused by
  `record-claim-guard`'s own foreign-path check even for reads) used
  `$P -c` with `P=perl` "set only in environment" and got `deny` — that
  matches my second case above (assignment present as literal *text*
  somewhere in the payload, just not adjacent to the `$P` use), not a
  truly-absent-from-text case. When the interpreter name never appears as
  literal text anywhere in the single command string at all — the genuine
  "`$P` set only in the environment" case — board-gate.sh's shell-level
  fast path exits before `python3` is ever invoked, and the command is
  **allowed**.

  This is **not introduced by round 2**: `derived: git diff 7040a3a..14ae52a
  -- core/hooks/board-gate.sh | grep -c UNANALYZABLE` → `0`, the fast path
  predates this branch entirely, and its own header comment (lines 90-98)
  already discloses the limit ("Nothing in this gate catches an
  expansion-built head... out of this gate's jurisdiction"). But round 2's
  own new comment (§6 below, added in `7ec6094`) makes a claim about this
  exact scenario that direct testing shows is false at the full-gate
  level — see §6.

### 5. Retired-noun comment — CONFIRMED, reworded not deleted, still identifies its target

`derived: git show 7ec6094 -- core/hooks/lib/gate-lib.py`:
```diff
-# bypass (a `qa`-role call denied nothing while writing outside `qa`'s own
-# write-set). Matched here BEFORE the bare single-quote alternative (same
-# ordering the bare-`$` case needed): the `$` is consumed as PART of the
-# quote-opening token, not left for `\S` to claim first.
+# bypass (a role session's call denied nothing while writing outside that
+# role's own write-set). Matched here BEFORE the bare single-quote
+# alternative (same ordering the bare-`$` case needed): the `$` is
+# consumed as PART of the quote-opening token, not left for `\S` to claim
+# first.
```
The retired noun here is the specific example role name `` `qa` `` (a
hard-coded example, not the general English word "role"), genericized to
"a role session" — the comment still identifies exactly what it points at
(the `$'-c'` ANSI-C-quote fusion bypass, `gate_trailing_words()` never
seeing the literal string `"-c"`). Note this is a **different** retired
noun than issue-366's role→skill denial-message rename (§7 below); the
general word "role" is correctly retained here since this is an internal
source comment, not the user-facing denial-message text issue-366
targeted.

### 6. PR #398's own diff, and one overclaim in it

`derived: git show 7ec6094 --stat` — touches exactly
`core/hooks/board-gate.sh`, `core/hooks/lib/gate-lib.py` (comment only),
`warrant/hooks/lib/scope-gate.py`, `core/hooks/tests/run-scope-gate-tests.sh`,
plus a new docs record; `14ae52a` touches only
`docs/handbooks/board-gate-tests.md`. Nothing unexpected.

`7ec6094` adds this comment to `board-gate.sh` (`derived: git show 7ec6094
-- core/hooks/board-gate.sh`, the `_bare_var_has_literal_interp_assignment`
preamble):
```
# ...When the assignment is visible and literal, this defers entirely to
# VAR_INTERP_RE's own verdict instead of blanket-checking here; when no
# such assignment is visible (`$P` set only in the environment, or never
# assigned at all), the existing conservative blanket check is unchanged --
# that residual is the genuine interpreter-head-via-expansion class this
# salvage exists to keep closed.
```
"the existing conservative blanket check is unchanged" describes the
`EXPANDED_HEAD_RE`/`INLINE_FLAG_WORDS` check that lives **inside** the
Python judge. §4's reproduction shows that for the true "`$P` set only in
the environment" case, the Python judge is never reached at all — the
shell-level `UNANALYZABLE_HEAD_RE` fast path (unrelated to and untouched
by this commit) exits first. So the blanket check is not "unchanged and
still catching it" for that specific case; it never runs. This is a
narrow, non-blocking finding: the comment's factual claim overstates what
this salvage — or anything before it — actually closes for the
zero-textual-trace case. Practically low-severity given Claude Code's own
Bash tool does not persist shell state across separate tool calls (so an
attacker cannot set `$P` in one call and rely on it surviving to a
later, separately-gated call), but the comment should say the residual
stays open for that specific sub-case, not "kept closed."

### 7. `d434daa`'s hunks — CONFIRMED absent

`derived:`
```
$ git log --oneline 237c8b9..14ae52a | grep d434daa   # exit 1, no match
$ git merge-base --is-ancestor d434daa 14ae52a; echo $?   # 1, not an ancestor
$ d434_patchid=$(git show d434daa | git patch-id | awk '{print $1}')
$ git log 237c8b9..14ae52a --oneline | while read sha rest; do
    pid=$(git show "$sha" | git patch-id | awk '{print $1}')
    [ "$pid" = "$d434_patchid" ] && echo "MATCH: $sha"
  done   # no output -- no commit in range matches d434daa's patch content
$ grep -n UNRESOLVED_SUBSTITUTION_WORD_RE core/hooks/board-gate.sh core/hooks/tests/run-board-gate-tests.sh
  # exit 1, absent -- d434daa's own unique symbol is not present
```
`INTERPRETER_HEADS` (a different, pre-existing symbol from an earlier
issue-233 commit, `5a0a5a6`) does appear in the tree and initially looked
like a false positive; patch-id comparison across the full commit range
rules out `d434daa`'s content specifically, not just its name.

## Standing invariants (all four checked live)

1. **Retired-noun leak, `\brole\b` (word-boundary, catches "roles"
   without false-matching it)** — `derived: grep -rnE '\brole\b'
   core/hooks/board-gate.sh core/hooks/lib/gate-lib.py
   warrant/hooks/lib/scope-gate.py warrant/hooks/scope-gate.sh` finds
   extensive live hits, e.g. `board-gate.sh:1135: "The board belongs to
   role sessions; ..."`. Root cause: this branch's merge-base is
   `7040a3a`, and `derived: git merge-base --is-ancestor 237c8b9
   14ae52a; echo $?` → `1` — `237c8b9` (the commit that landed issue-366's
   role→skill denial-message rename, PR #389, on current main) is **not**
   an ancestor of this branch; it forked before that rename landed and was
   never rebased past it. Isolating what round 2's own diff adds:
   `derived: git diff 7040a3a..14ae52a -- core/hooks/board-gate.sh
   core/hooks/lib/gate-lib.py warrant/hooks/lib/scope-gate.py
   warrant/hooks/scope-gate.sh | grep -E '^\+' | grep -E '\brole\b'` →
   exactly 2 lines, both from §5's comment reword (pre-existing "role"
   wording repositioned, not new denial-message text). None of the
   user-facing denial-message lines issue-366 already fixed on main
   (e.g. `board-gate.sh:1135`, `:1058`) are touched by round 2's diff, so
   a clean rebase/merge onto current main would pick up main's
   already-"skill" wording for those lines automatically. Action item:
   this branch needs a rebase onto current main before landing — not a
   defect in round 2's own diff, but a real pre-land requirement flagged
   here since a stale merge could otherwise silently reintroduce "role"
   wording main already retired.

2. **No new bug** — read `7ec6094`'s full diff directly; the
   `_VAR_INTERP_C_NAMES`/`_VAR_INTERP_E_NAMES` (board-gate.sh) and
   `_C_FLAG_INTERP_NAMES`/`_E_FLAG_INTERP_NAMES` (scope-gate.py)
   derivations are correct (`\b` word boundaries make dict-iteration
   order irrelevant; perl correctly appears in both `-c`- and
   `-e`-named groups on both gates). No off-by-one or wrong-variable bug
   in the derivation itself. Two *pre-existing*, round-2-independent
   failures surfaced by invariant 3 below are a real, disclosed gap —
   see there.

3. **Failing-test set vs `origin/main`, as sets of names, collection
   scope stated** — collection scope: `core/hooks/tests/run-board-gate-tests.sh`
   and `core/hooks/tests/run-scope-gate-tests.sh` (the two suites that
   directly exercise the gates round 2 touches), run as real subprocesses
   against three checkouts:
   ```
   origin/main (237c8b9):   159 passed, 2 failed: {feasibility-spikes, ops-postmortems}
   pre-round-2 tip (6431146): 188 passed, 4 failed: {feasibility-spikes, ops-postmortems,
                                quoted-path-with-spaces-c-flag, ansi-c-quoted-flag-word}
   PR #398 HEAD (14ae52a):  188 passed, 4 failed: {feasibility-spikes, ops-postmortems,
                                quoted-path-with-spaces-c-flag, ansi-c-quoted-flag-word}
   ```
   (scope-gate: 92 passed, 0 failed at `14ae52a`.) The set difference
   against `origin/main` — `{quoted-path-with-spaces-c-flag,
   ansi-c-quoted-flag-word}` — is **identical** between `6431146` (before
   round 2's own two commits) and `14ae52a` (after): round 2 introduces
   **zero** new test failures. But both were already failing at the exact
   commit that added them, `derived: git checkout 2fb9038 && bash
   core/hooks/tests/run-board-gate-tests.sh` → same 4 failures — this is a
   long-standing, disclosed gap from an earlier issue-233 salvage commit,
   not round 2's to fix, but directly relevant to this issue's own
   acceptance criteria (which name "the quoted/escaped-space path" as one
   of the four classes needing live verification). Live before/after on
   that specific class: `escaped-space-interpreter-path-c-flag`
   (backslash-escaped space, e.g. `/opt/My\ Python/python3 -c ...`)
   **denies** correctly; `quoted-path-with-spaces-c-flag` (the same path
   double-quoted instead, `"/opt/My Python/python3" -c ...`) and
   `ansi-c-quoted-flag-word` (`python3 $'-c' ...`) both **allow** —
   `want=deny got=allow` in the suite's own output, reproduced identically
   at `origin/main`... no, at `6431146` and `14ae52a` (not present as
   failures on `origin/main` because these test *names* don't exist there
   at all — they were added by `2fb9038`, an issue-233 commit not yet on
   main). Half the "quoted/escaped-space path" class is covered; half is
   open.

4. **No overhead increase** — `7ec6094`'s diff only changes the *source
   strings* two module-level `re.compile()` calls compile (compiled once,
   at script load) and adds two `"|".join(re.escape(n) for n in
   INLINE_FLAG_HEADS if ...)` comprehensions over a 10-entry dict
   (evaluated once per gate invocation, same cost class as before). No new
   subprocess spawns, no loop added inside the per-command-segment hot
   path.

5. **Monitor/watch machinery unbroken and not quieter** — `derived: git
   ls-files | grep -iE 'monitor|watch'` → no output. No such machinery
   exists in this repo; invariant is vacuously satisfied.

## Why

adversarial-review protocol: independent, structurally isolated
verification of a deliverable this session did not build, incentivized to
find what is wrong rather than confirm what was claimed.

## What did not work

None.

## Upstream basis

`tokenmaxxxer/tokenmaxxxer-core#398`, branch head `14ae52a`
(`14ae52af1146e2b171bfbd48b9bce984aa6b4e41`), merge-base `7040a3a` against
`origin/main` at `237c8b9` (current main tip at review time). Context only
(not restated): `#395`'s record, `issue-370/adversarial-review-0126df44`,
`docs/issue-370/reports/adversarial-review-0126df44.md`, sha
`same-commit` is not applicable (external branch) — read via `WebFetch` of
its raw GitHub content for the guard-variant-2 wording check in §4.

## Open findings

1. **Board-gate.sh comment overclaim (§6)** — the `_bare_var_has_literal_interp_assignment`
   preamble comment added in `7ec6094` claims the "conservative blanket
   check" catches the `$P` set-only-in-environment residual; direct
   testing shows the shell-level fast path prevents that check from ever
   running in that exact case. Resolution path: correct the comment
   wording (or, if closing the case is wanted, that requires touching the
   shell-level `UNANALYZABLE_HEAD_RE` fast path, which is out of round
   2's stated scope and not something this record recommends doing
   reflexively). Non-blocking: pre-existing mechanism, low practical
   exploitability given Claude Code's Bash tool does not persist shell
   state across tool calls.
2. **Pre-existing "quoted-path-with-spaces" gap, half of the acceptance
   criteria's named class (invariant 3)** — `quoted-path-with-spaces-c-flag`
   and `ansi-c-quoted-flag-word` fail identically before and after round
   2; not round 2's regression, but the issue's own acceptance criteria
   name this exact bypass class for live verification, so it is
   surfaced here rather than silently passed over. Resolution path: a
   follow-up round (issue-233 or issue-370) closing the quoted-literal
   (as opposed to backslash-escaped) form of this class.
3. **Branch staleness re: issue-366's role→skill rename (invariant 1)** —
   needs a rebase onto current main before landing; not a defect in round
   2's own diff. Resolution path: rebase `issue-370/adversarial-review-b4a7cf19`'s
   upstream PR branch (`#398`) onto `origin/main` before merge.
4. **Test coverage asymmetry** — `scope-gate.py` got a dedicated
   regression test for the perl `-c` fix (`round5-var-indirected-perl-c-denied`
   in `run-scope-gate-tests.sh`); `board-gate.sh`'s identical fix has no
   committed regression test, only the manual reproduction in §1 of this
   record. Resolution path: a small follow-up adding the symmetric test
   to `run-board-gate-tests.sh`.
5. **Residual un-derived third enumeration** —
   `_bare_var_has_literal_interp_assignment`'s own name list
   (`r"\b%s=(?:python3?|python2|bash|sh|zsh|perl|ruby|node|nodejs)\b"`, both
   gates) is hand-written, not derived from `INLINE_FLAG_HEADS`/
   `_C_FLAG_INTERP_NAMES`+`_E_FLAG_INTERP_NAMES` the way round 2's stated
   principle requires. Coincidentally consistent with the authoritative
   set today; structurally the same "second/third independent
   enumeration that can drift" pattern round 2 claims to retire, just
   recurring in a spot round 2 didn't touch. Resolution path: fold this
   into the same single-source derivation in a follow-up.

None of findings 1-5 contradict round 2's own stated claim — that claim
(the var-indirected deferral in both gates is now derived from, and
matches, the direct-form per-interpreter flag mapping, closing the
`P=perl; $P -c ...` drift) holds under exhaustive, live, independently
re-derived verification, with no regression on round 5/6's give-backs and
no new test failures.

## Next steps

None — this record is terminal for this round. Findings 1-5 above are
the resolution paths for whoever picks up issue-370 or issue-233 next.
`loop_state: landed`.
