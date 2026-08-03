---
kind: build-proposal
subject: issue-98
produced_by: implementation
loop_state: proposed
upstream:
  - path: docs/issue-98/reports/implementation/survey.md
    sha: <set at commit>
  - path: docs/issue-98/reports/implementation/scout-brief.md
    sha: <set at commit>
---

files: `core/hooks/lib/gate-lib.py`, `core/hooks/board-gate.sh`,
`core/hooks/gh-guard.sh`, `core/hooks/tests/run-gate-lib-tests.sh`,
`core/hooks/tests/run-board-gate-tests.sh`,
`core/hooks/tests/run-gh-guard-tests.sh`,
`docs/handbooks/gate-house-standard.md`,
`docs/handbooks/board-gate-tests.md`, `docs/handbooks/gh-guard-tests.md`

## Request

Issue #98, against `docs/issue-94/reports/execution-observation.md`'s
Finding 1: `gate_dequote` blanks quoted spans to inert data, but `bash -c`/
`sh -c`/`eval` (and, per the issue's own local adversarial verification,
`timeout … bash -c`, `env bash -c`, `xargs … bash -c`, `nohup bash -c`, and
`python3 -c "…os.system(…)"`) **execute** that data. `gh-guard.sh`'s three
dequoted verb rules (review --approve, merge/close/reopen, issue create/
close/…) all lost their pre-#94 ability to deny these — live-reproduced in
the survey, all 8 named variants currently `allow` a real `gh pr merge`.
Requirement 1 asks this be closed as a class (raw re-check gated on a
wrapper head, or excluding wrapper heads from the dequote path — either way,
first checking whether board-gate's existing `TRANSPARENT`/`_head_of()` can
be reused rather than reimplemented). Requirement 2 asks board-gate's own
`READ_UNLESS_INPLACE` heads (`sed`/`awk`/`gawk`) be separately checked for
quoted-redirect writes — the survey confirms this is real and independent of
the wrapper class: `awk '{print > "…"}' f` and `sed '… w …' f` both `allow`
today with no `bash -c` involved at all.

The survey also settled the issue's own open question about board-gate's
`FILE_REDIR` half: live-reproducing `bash -c "echo hi > …/reports/review.md"`
(and the `timeout`/`nohup` variants) against a foreign-record target
**denies**, via `_head_of()` resolving to a head (`bash`/`timeout`/`nohup`)
that isn't in `READ_ONLY_HEADS`, so the segment fails closed regardless of
what `FILE_REDIR` itself sees. Board-gate needs no fix for this half.

## Constraints

- The three `gh-guard.sh` rules' existing, #94-fixed negative space
  (`grep "gh pr merge" file.txt`, `grep -n "gh pr review --approve" notes.py`,
  `grep -n "gh issue create" notes.py`) keeps allowing — the fix adds a new
  detection path gated on a wrapper head, it does not undo dequoting for
  heads that aren't one.
- Every existing case in `run-board-gate-tests.sh` (67 sites),
  `run-gh-guard-tests.sh` (37 assertions), and `run-gate-lib-tests.sh` keeps
  its current verdict.
- Regression cases use the issue's exact repro set (`bash -c`, `bash -lc`,
  `timeout … bash -c`, `env bash -c`, `xargs … bash -c`, `nohup bash -c`,
  `python3 -c "…os.system(…)"`, and the `awk`/`sed` quoted-redirect case)
  and must fail (wrong verdict) on the pre-change code — verified in the
  survey by live-running them, not asserted.
- The fix is one reusable primitive (a wrapper-head enumeration plus a
  head-resolver, both in `gate_lib.py`), not per-phrase string patterns —
  the issue's explicit "클래스로 막을 것, 문자열 몇 개 추가가 아니라."
- `TRANSPARENT`/`_head_of()` are relocated to `gate_lib.py` and reused, not
  reimplemented, per requirement 1's explicit reuse check.

## Rationale

**Requirement 1's option (b) — exclude wrapper-headed commands from the
dequote path entirely — is rejected in favor of option (a), a per-quoted-
span raw re-check gated on the wrapper head immediately introducing that
specific span.** A whole-command "is the head of this line a wrapper, then
skip dequoting for the whole line" design was considered first (simpler to
state) and rejected: `gh-guard.sh` has no segmentation (the #94 proposal
warrant-hunted and explicitly rejected adding it, for a real reason —
`_split_segments` is quote-aware but not paren-aware, so a real single
invocation with an unquoted separator-shaped character inside `$(...)`
would be sliced wrong), so a compound line like `grep -n "gh pr merge" x.py;
bash -c "gh pr merge 5"` has a first word (`grep`) that is not a wrapper —
a whole-line-head design would miss the real wrapper sitting later on the
same line. Per-quoted-span resolution (find the word(s) immediately before
each quoted span, walk back only to the previous top-level separator, and
resolve *that* local head through `TRANSPARENT`) answers the question the
issue actually asks — "is *this* quote a wrapper's code argument" — without
re-litigating the segmentation decision #94 already made: no rule's `.*`
reach or its pattern is segmented, only the small local text immediately
preceding a quote span is inspected to classify that one span.

**`TRANSPARENT` and `_head_of()` move to `gate_lib.py` verbatim (same
`importlib.util.spec_from_file_location` pattern `record-fields-gate.sh`/
`board-gate.sh` already use for `gate_dequote`), rather than gh-guard
growing its own copy.** This is the reuse the issue asks be checked first;
the survey confirms both pieces already do real, working work and the
alternative — a second, gh-guard-local head-resolver — is exactly the
"grow a fourth inline copy" issue #94's own constraint and this issue's
"한 자리로 모은다" precedent argue against. `TRANSPARENT` gains `timeout`
and `nohup` (two of the issue's own named variants) in the same move:
board-gate doesn't need them today (an unrecognized head already fails
closed there), but gh-guard's new per-span resolver does need to see through
them to reach the real `bash`/`sh`/`eval` head underneath
`timeout 30 bash -c "…"`/`nohup bash -c "…"`.

**A new, sibling enumeration `WRAPPER_HEADS` (`bash`, `sh`, `dash`, `ksh`,
`zsh`, `eval`, `python`, `python3`, `python2`, `perl`) is added rather than
folding wrapper heads into `TRANSPARENT`.** `TRANSPARENT` answers "skip this
word, the *next bare word* is the real command" (true for `xargs`/`env`/
`time`/`nice`/`command`/`builtin` — they take the wrapped command as
separate, space-delimited words). A wrapper head answers a different
question: "the *next argument, which may be one quoted string*, is a whole
command line to be **re-parsed and executed**." Conflating the two would
make `_head_of()` try to "skip past" `bash -c` the way it skips past `env`,
which is wrong — there is nothing after `bash -c "…"` to skip to; the
payload is inside the quote itself. `perl`/`python`/`python2` are additions
beyond the issue's literal repro set, justified by the scout brief: GTFOBins
names exactly this family ("if you spot vi, less, python, perl, or awk,
you're probably able to escape it") as the well-known interpreter-escape
class, and `python3` is independently required by the issue's own
`os.system(...)` case — enumerating the whole family the scout brief
surfaced costs one tuple entry each and closes an equivalent, foreseeable
gap (`perl -e "..."`) the issue's literal list happens not to name.
Editors (`vi`/`less` via `:!`) and other GTFOBins entries are rejected for
this issue (Out of scope) — they are a `Bash`-tool-invoked-editor scenario,
a materially different shape than a command string containing a wrapper
head, and the issue names none of them.

**Board-gate's `SUBSHELL` and the FILE_REDIR-quote-exclusion added in #94
are left untouched.** The survey's live reproduction shows the wrapper class
is already denied there via the unrecognized-head fail-closed default, for
every variant the issue names, including the `timeout`/`nohup` ones
`TRANSPARENT` doesn't even cover — because "not in `TRANSPARENT`" resolves
to a literal head (`timeout`, `nohup`) that also isn't in `READ_ONLY_HEADS`,
which fails closed all the same. Touching `SUBSHELL` or `FILE_REDIR` here
would be a change with no named defect behind it, against a check #94's own
hunt already found unsafe to touch further (SUBSHELL must stay quote-blind:
`$(...)` is live even inside double quotes).

**`READ_UNLESS_INPLACE`'s `awk` branch gains a raw (not dequoted)
`FILE_REDIR`-pattern check — reusing the existing `FILE_REDIR` constant,
not a new pattern — as an additional write-candidate trigger alongside
`INPLACE`.** Rejected alternative: parse awk's grammar to distinguish a
`print > "file"` redirect from a `$1 > 5` comparison — both use a bare `>`,
and the survey's negative-space case (`awk '$1 > 5 {print}' …`) shows this
ambiguity is real. Rejected because it requires an awk parser to resolve
correctly and this file's own established convention (repeated inline
comments: "over-blocking is the safe direction here") already accepts the
over-block direction for exactly this kind of ambiguity; a comparison-vs-
redirect `awk` filter targeting a docs/ path will be refused as a write
candidate, which is a false positive but not a hole. **`sed`'s branch gains
a narrower check for the `w` command** (`sed`'s file-write mechanism, unlike
awk's, is the literal `w filename` command/flag rather than `>`) — scoped to
the `w`-command shape (following a command boundary or an `s///` flags
position), accepting a residual: an exotic `w`-command spelling this
pattern doesn't anticipate may still slip through, named as a `gap-*`
regression case per the existing `gap-c-*`/`gap-f-*` convention rather than
promised fixed.

**Finding 3 (SEGMENT's unguarded second copy of the quote-span alternation,
`board-gate.sh:140`) is included.** This proposal already opens
`board-gate.sh` to move `TRANSPARENT`/`_head_of()` out and import from
`gate_lib`; building `SEGMENT` from `gate_lib.GATE_QUOTE_SPAN.pattern` the
same way `:230` already builds its `FILE_REDIR` argument from
`FILE_REDIR.pattern` is a one-line change in a file this proposal is already
editing, directly closes a named, unresolved drift risk, and needs no new
test (the existing `run-board-gate-tests.sh` suite already exercises
`SEGMENT`'s splitting behavior; single-sourcing the pattern text changes no
observable behavior to pin).

**Finding 5 (three stale `WRITEISH`/`_writeish` comments in
`run-approval-gate-tests.sh`) is excluded.** That file is not in this
issue's write set — it belongs to `approval-gate.sh`, which this issue does
not touch, and the three lines are comments with no functional effect. Per
the scope-exceeded rule, pulling in an unrelated file for a documentary-only
fix is exactly the kind of mid-build widening to avoid; it is a clean,
independent one-line-per-comment fix better left to its own follow-up (the
observation record already names the actionable rewording) than bundled
into a proposal whose write set is otherwise entirely `board-gate.sh`/
`gh-guard.sh`/`gate-lib.py`.

## What will be done

- [ ] `core/hooks/lib/gate-lib.py`: relocate `TRANSPARENT` (extended with
  `timeout`, `nohup`) and `_head_of` (renamed `gate_head_of` for the public
  API) from `board-gate.sh` verbatim in behavior. Add `WRAPPER_HEADS =
  ("bash", "sh", "dash", "ksh", "zsh", "eval", "python", "python3",
  "python2", "perl")` and a `gate_wrapper_head_before(cmdline, span_start)`
  helper: walks backward from `span_start` to the previous top-level
  separator (`;`, `|`, `&&`, `||`, newline, or start-of-string, all outside
  quotes — reusing `GATE_QUOTE_SPAN`/`gate_dequote` to find "outside quotes"
  the same way the rest of the file already does), resolves the head of that
  local text through `gate_head_of`/`TRANSPARENT` the same way board-gate
  resolves a segment head today, and returns that head only when it is in
  `WRAPPER_HEADS` **and** (the head is `eval`, which always executes its
  argument with no flag needed, **or** a `-c`-shaped flag token — exactly
  `-c` or a combined short-flag token containing `c`, e.g. `-lc`/`-ic` — sits
  between the head and the quote). Returns `""` otherwise (not a wrapper
  invocation for this span).
- [ ] `core/hooks/board-gate.sh`: import `gate_lib`; replace the local
  `TRANSPARENT`/`_head_of` definitions with `gate_lib.TRANSPARENT`/
  `gate_lib.gate_head_of` (no behavior change for board-gate's own
  `_write_candidate_segments`, confirmed by the existing suite staying
  green). Build `SEGMENT` from `gate_lib.GATE_QUOTE_SPAN.pattern` instead of
  the inline literal (Finding 3). In the `READ_UNLESS_INPLACE` branch, deny
  read-only classification (i.e. `failing.append(seg)` instead of
  `continue`) when, in addition to today's `INPLACE.search(stripped)`: for
  `awk`/`gawk`, `FILE_REDIR.search(stripped)` (raw, not
  `gate_outside_quotes` — awk's own quoted program argument is not inert
  data here, the same reasoning Finding 1 turns on for `bash -c`); for
  `sed`, a new `SED_WRITE_CMD` pattern matching the `w`/`W` command or an
  `s///…w …` flag.
- [ ] `core/hooks/gh-guard.sh`: import `gate_lib`. For the three
  `dequote=True` rules only, after the existing `re.search(pat, dq)` check,
  add: if the pattern does not match `dq` but does match raw `cmd`, walk
  `gate_lib.GATE_QUOTE_SPAN.finditer(cmd)`; for each quoted span whose raw
  text also matches `pat`, call `gate_lib.gate_wrapper_head_before(cmd,
  span.start())`; deny if any span returns a non-empty wrapper head. The 8
  `dequote=False` rules are untouched (Out of scope, unchanged from #94).
- [ ] `core/hooks/tests/run-gate-lib-tests.sh`: unit tests for
  `gate_head_of`/`TRANSPARENT` (parity check: same behavior as board-gate's
  pre-move local copy, via a couple of segments already exercised in
  `run-board-gate-tests.sh`) and `gate_wrapper_head_before` (returns `bash`/
  `sh`/`eval`/`python3` for the issue's named shapes including the
  `timeout`/`env`/`xargs`/`nohup`-prefixed ones; returns `""` for
  `grep "gh pr merge" file.txt`'s quoted span).
- [ ] `core/hooks/tests/run-gh-guard-tests.sh`: a `wrapper-*` group, one case
  per issue-named variant (`bash -c`, `bash -lc`, `timeout … bash -c`,
  `env bash -c`, `xargs … bash -c`, `nohup bash -c`, `python3 -c
  "…os.system(…)"`, `sh -c`, `eval`) — all `deny`, each holding a real
  `gh pr merge`/`--approve`/`issue create` payload; re-run the three
  existing `quote-*` negative-space cases (`quote-gh-pr-merge-in-grep`, etc.)
  unchanged, confirming they still `allow`; one additional negative-space
  case, `wrapper-bash-c-plain-grep` — `bash -c "grep -n 'gh pr merge' x.py"`,
  a *legitimate* grep nested inside a real `bash -c` — asserted `deny`
  (documented, not silently accepted: this is the known, safe-direction
  over-block cost of not parsing the wrapper's own argument, named in
  Out of scope below, mirroring the existing `gap-c-*`/`gap-f-*`
  kept-visible-residual convention rather than hidden).
- [ ] `core/hooks/tests/run-board-gate-tests.sh`: a `wrapper-*`/`awk-*`/
  `sed-*` group — the issue's `awk '{print > "…"}' f` and a `sed '… w …' f`
  case on a foreign-record path, both `deny`; negative-space siblings
  `awk '$1 > 5 {print}' …` (comparison, not redirect) and plain `sed -n
  1,Np …` both still `allow`; `bash -c "echo hi > …/reports/review.md"` and
  its `timeout`/`nohup` variants re-asserted `deny` (already correct
  pre-change per the survey — pinned here as a regression guard, not a new
  fix) plus one on the role's own record still `allow`.
- [ ] `docs/handbooks/gate-house-standard.md`: document `WRAPPER_HEADS`,
  `gate_head_of`, `gate_wrapper_head_before` under "## What `gate-lib.sh` /
  `gate-lib.py` provide."
- [ ] `docs/handbooks/board-gate-tests.md`, `docs/handbooks/gh-guard-tests.md`:
  one entry each, issue-98, naming the wrapper-head class fix and the
  `awk`/`sed` redirect-detection fix respectively, plus the accepted
  over-block residual (`bash -c` wrapping a legitimate grep).
- [ ] Verify: `bash core/hooks/tests/run-gate-lib-tests.sh`, `bash
  core/hooks/tests/run-board-gate-tests.sh`, `bash
  core/hooks/tests/run-gh-guard-tests.sh` — all `0 failed`, including every
  pre-existing case unchanged; each new `deny` case's stderr inspected to
  confirm it denies for the rule this proposal names.

## Out of scope

- Finding 5 (stale `WRITEISH`/`_writeish` comments in
  `run-approval-gate-tests.sh`) — not this issue's write set (Rationale).
- The full GTFOBins catalogue (editors' `:!` shell-escape, `find -exec`,
  pagers, etc.) — a `Bash`-tool command string containing a wrapper head is
  this issue's named shape; a `Bash` call invoking `vi`/`less` interactively
  is a different mechanism the issue does not reproduce.
- `board-gate.sh`'s `SUBSHELL` and the #94 `FILE_REDIR`-quote-exclusion —
  confirmed unaffected by this issue's named repro set (survey), left as-is.
- A `bash -c` (or `sh -c`/`eval`/`python3 -c`) argument containing a nested
  wrapper invocation of its own (e.g. `bash -c "bash -c \"gh pr merge 5\""`)
  — the per-span resolver checks one level of wrapper head per quoted span;
  recursive re-scanning inside an already-identified wrapper's own quoted
  argument is a real extension point, not built here (no named repro, and
  the outer span already denies regardless of what its inner content is,
  since `gate_wrapper_head_before` firing is itself sufficient to deny —
  nesting cannot un-deny an already-caught span).
- The `bash -c "grep ... gh pr merge ..."` over-block residual (nested
  legitimate-data-lookup inside a real wrapper invocation) — accepted,
  tracked by its own regression case, not solved (Rationale).
- Any GTFOBins-named interpreter beyond `bash`/`sh`/`dash`/`ksh`/`zsh`/
  `eval`/`python`/`python3`/`python2`/`perl` (e.g. `ruby -e`, `node -e`,
  `lua -e`) — `WRAPPER_HEADS` is a plain tuple, trivially extensible later;
  not populated further without a named repro.
- Migrating `approval-gate.sh` to `gate_lib.gate_head_of`/`WRAPPER_HEADS` —
  `approval-gate.sh` has no head-resolution logic today and this issue does
  not touch it.

## How you'll know it worked

All three test harnesses (`run-gate-lib-tests.sh`, `run-board-gate-tests.sh`,
`run-gh-guard-tests.sh`) report `0 failed`, including: every issue-named
wrapper variant now `deny`s on `gh-guard.sh` (currently `allow`, per the
survey's live reproduction); the `awk`/`sed` quoted-redirect cases now
`deny` on `board-gate.sh` (currently `allow`); the `awk` comparison and
plain-`sed`-read negative-space cases still `allow`; the three existing
`quote-*` gh-guard negative-space cases still `allow`; the `bash -c`/
`timeout`/`nohup`-wrapped foreign-record board-gate cases still `deny`
(regression guard on behavior the survey found already correct); every
pre-existing case in all three suites keeps its current verdict unchanged.
