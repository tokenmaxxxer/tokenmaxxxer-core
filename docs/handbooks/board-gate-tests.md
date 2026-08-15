# board-gate test harness

`core/hooks/tests/run-board-gate-tests.sh` exercises `core/hooks/board-gate.sh`
as a real subprocess against synthetic git repos and JSON tool-call
payloads (`run`/`runb` helpers; `want allow|deny` maps to exit 0/2).

Run it directly, no setup required:

    bash core/hooks/tests/run-board-gate-tests.sh

Covers R1 (docs/ layout), R2 (canonical contract), R3 (role required),
R4 (branch matches issue/role), and R5 (reports/ ownership, including
the role's own bare record directory for Bash `mkdir`/`rm`, and the
foreign-role denial).

Also covers `git` subcommand awareness (issue-60): `git` is judged by
its subcommand, not trusted whole-command. Read subcommands
(`log`/`show`/`diff`/`status`/`blame`/`ls-files`/`ls-tree`/`ls-remote`/
`cat-file`/`rev-parse`/`symbolic-ref`/`describe`/`shortlog`/`reflog`)
still short-circuit to allow (s4 READ-broad, unaffected); every other
subcommand (`rm`, `checkout --`, `restore`, `clean`, `apply`, `mv`,
`stash`, ...) is judged by the normal R1-R5 write scan like any other
write — denied on a foreign tree, allowed on the role's own once it
clears R5, same as `rm -rf` already was.

Also covers two read-classification false positives (issue-88):
quoted-`|` segment-split blindness — `SEGMENT` used to split on any bare
`|`/`;` with no quote-awareness, so a quoted BRE OR pattern like
`grep -n "A\|B" docs/x.md` cut into fake segments whose second fragment's
head was an arbitrary word, denied as a write (`bash-quoted-pipe-grep`,
`bash-quoted-pipe-classtest`, `bash-single-quoted-pipe`, plus the
negative-space `bash-quoted-pipe-then-redirect` proving a real unquoted
`|` later in the line still denies); and `cd` absent from
`READ_ONLY_HEADS` — a `cd`-prefixed read (`cd docs/issue-3 && cat x.md`)
was denied outright even though the identical read without the `cd`
prefix was allowed (`bash-cd-then-cat`, plus the negative-space
`bash-cd-then-write-foreign` proving a `cd`-prefixed write into a
foreign tree still denies).

`bash-escaped-quote-then-write` pins a bypass a warrant-hunt found in the
quoted-span regex itself: a backslash-escaped quote CHARACTER outside any
real shell quote (e.g. `ls \" ; rm -rf docs/issue-1/x #"`) must not open a
quoted-span match — otherwise it runs to an unrelated later quote (here,
one inside a `#` comment) and swallows the real `;` between two real
commands as if it were quoted content, hiding a write in the second real
command from the per-segment head check entirely (`_reads_only()` then
returns `True` and `allow()` skips R1-R5). Fixed with a `(?<!\\)`
negative lookbehind on both quote alternatives in `SEGMENT`.

Also covers candidate-scan scoping (issue-90): `_reads_only` used to
collapse per-segment classification down to one `bool`, so when the
`Bash` candidate builder saw `False` it fell back to scanning the entire
raw `cmdline` for `docs/`-shaped tokens — sweeping in tokens that sat
inside a DIFFERENT, already-provably-read-only segment on the same line.
`_write_candidate_segments(cmdline)` now returns *which* segments could
not be proven read-only, and the candidate scan runs only over those
segments' joined text. `bash-unresolved-head-then-read` pins the fix (a
read-only segment allows even though an unrelated, unresolvable segment
sits on the same line); its negative-space sibling
`bash-unresolved-head-real-write` proves a real write inside the failing
segment itself still denies — the scoping narrows *where* candidates are
hunted for, not *whether* a real write in scope is caught.

Also covers `FILE_REDIR` quote-awareness (issue-94): `FILE_REDIR` used to
run `.search()` on raw segment text, so a `>` sitting INSIDE a quoted
string (e.g. `grep -n "A > B" docs/x.md`, a pure read) was misread as a
write candidate and refused. Fixed by routing it through the shared
`gate_lib.gate_outside_quotes(seg, FILE_REDIR.pattern)` primitive
(`core/hooks/lib/gate-lib.py`), which strips quoted spans before matching.
`SUBSHELL` deliberately stays quote-blind — command substitution
(backtick / `$(`) is live even inside double quotes in real bash, so
making it quote-aware would newly ALLOW a real write like
`grep -n "$(touch docs/x.md)" README.md`. Four cases pin this:
`bash-quoted-redirect-in-grep` (the issue's exact repro: a quoted `>` in a
grep pattern must not be misread as a write); its negative-space sibling
`bash-real-redirect-then-quote` (a real, unquoted `>` into the board must
still deny); `bash-escaped-quote-then-redirect`, a warrant-hunt sibling of
`bash-escaped-quote-then-write` targeting `FILE_REDIR` instead of the
segment splitter (a backslash-escaped quote CHARACTER outside any real
shell quote must not open a fake quoted span that swallows the real `>`
between two real tokens); and `bash-quoted-subshell-write`, proving
`SUBSHELL` correctly stays quote-blind and keeps denying a real write
smuggled through command substitution inside double quotes.

Also covers issue-98's two requirements against `board-gate.sh`
specifically (the wrapper-head class fix itself lives in
`gh-guard.sh`/`gate-lib.py`; see `gh-guard-tests.md`). First, the issue's
own open question about whether a wrapper-headed write (`bash -c "echo hi
> docs/x"`, `timeout 30 bash -c "..."`, `nohup bash -c "..."`) bypasses
`FILE_REDIR` the same way it bypasses `gh-guard.sh`'s dequoted rules:
confirmed NOT a hole. `gate_outside_quotes(seg, FILE_REDIR.pattern)` does
miss the dequoted `>`, but `gate_lib.gate_head_of` then resolves the
segment's head to `bash`/`timeout`/`nohup` — none in `READ_ONLY_HEADS` or
`READ_UNLESS_INPLACE` — so the segment fails closed via the same
fall-through every other unrecognized head already takes.
`bash-wrapper-bash-c-foreign`, `bash-wrapper-timeout-foreign`,
`bash-wrapper-nohup-foreign` pin this as a regression guard on behavior
that was already correct before this issue; `bash-wrapper-own-record`
confirms a wrapped write to the role's OWN record still allows (not
evidence of a hole either way).

Second, a real, independent gap: `READ_UNLESS_INPLACE`'s `awk`/`sed`
heads read by default and only checked `-i`/`--in-place` for a write
signal, missing each language's OWN write mechanism. `awk`'s `print >
"file"` redirect syntax writes with no `-i` involved at all — fixed by
checking the raw (not `gate_outside_quotes`) `FILE_REDIR` pattern for
`awk`/`gawk` segments, since awk's own quoted program argument is not
inert data here (the same reasoning issue-98's Finding 1 turns on for
`bash -c`). `sed`'s file-write mechanism is the literal `w`/`W` command
(as its own command, or an `s///...w file` trailing flag), not `>` —
fixed by a new `SED_WRITE_CMD` pattern scoped to a `w`/`W` word boundary
followed by whitespace-then-a-filename-char, so an ordinary word starting
with w (`with`, `while`, ...) never matches. `awk-quoted-redirect-foreign`
and `sed-w-cmd-foreign` pin both fixes as `deny` on a foreign-record path
(the issue's own repro shapes); `sed-plain-read-foreign` pins a plain
`sed -n` read still `allow`. `gap-awk-comparison-over-block` pins a named,
accepted residual: `awk '$1 > 5 {print}' ...` uses a bare `>` as a
NUMERIC COMPARISON, not a redirect — indistinguishable from a real
redirect without a real awk parser (this file's own established
convention already accepts over-blocking as the safe direction for
exactly this kind of ambiguity) — so it now denies too, kept visible as a
`gap-*` case rather than silently accepted, mirroring `gap-c-*`/`gap-f-*`
in `gh-guard-tests.md`.

Also covers issue-99's dead empty-candidates fallback and the `cd`-relative
write-verb gap it shared (root-caused independently by
`docs/issue-90/reports/execution-observation.md` Finding 1). The `Bash`
candidate builder's `candidates.append(DOCS)` fallback — reached whenever
every write-classified segment carried no `docs/`-shaped token of its own
— was annotated "mentioned but unextractable: adjudicate" but structurally
could never do so: `posixpath.normpath("docs/")` is `"docs"`, whose
`.find("docs/")` is `-1`, so the fallback candidate never produced a hit
and the branch always reached `allow()` instead. A command whose write
target is expressed relative to a `cd`-ed foreign issue directory —
`cd docs/issue-49 && date > x.md` — allowed where the pre-issue-90 code
denied via R4; the same gap caught non-redirect write verbs (`cp`, `mv`)
too, since their targets carry no `docs/` token any more than the
redirect case's does.

Fixed by extending the existing per-segment classification (issue-90)
with an in-order walk that tracks the most recent `docs/`-landing `cd`
target as a sticky `cd_tail` — set only when a read-only `cd` segment's
own target itself lands under `docs/`, and never cleared by a later
non-`docs/` `cd` (a deliberate, existential tracker, not a full
relative-path resolver: reconstructing only the `cd` target *directory*
is enough to re-run R1-R4 correctly, since none of those need the exact
write-target filename). Any later write-classified segment with no
`docs/` token of its own now reconstructs `DOCS + cd_tail` as its
candidate instead of the dead fallback; a write-classified segment with
no token of its own AND no `cd_tail` set contributes nothing, preserving
issue-90's own negative space (a `docs/` mention sitting only in an
already-read-only segment elsewhere on the line must not manufacture a
candidate). `_write_candidate_segments`'s per-segment read/fail test was
extracted to `_segment_is_failing(seg, stripped)` so the walk and the
existing function share one classification, not two independent copies.

`bash-cd-relative-redirect-foreign` pins the issue's own headline repro
(`cd docs/issue-49 && date > x.md`, want deny via genuine R4
adjudication); `bash-cd-relative-cp-foreign` and `bash-cd-relative-mv-foreign`
pin the same gap for non-redirect write verbs. `bash-cd-relative-write-own-issue`
is the negative-space sibling: a role's own legitimate `cd`-then-write
into its own issue tree still allows, now via genuine R1-R4 adjudication
rather than the dead fallback's accidental allow.
`bash-cd-out-then-write-elsewhere` pins the accepted over-blocking
trade-off named in the fix's proposal: `cd_tail` is sticky and never
un-set, so `cd`-ing back OUT of `docs/` before the write
(`cd docs/issue-49 && cd /tmp && date > y.md`) still denies even though
the write's real target is `/tmp` — a deliberate, measured cost of the
simpler existential tracker (this file's own established
"over-blocking is the safe direction" posture), not a bug. Full
relative-path resolution (tracking exact effective cwd through arbitrary
`cd`/`cd ..`/multi-hop chains, un-set on leaving `docs/`) and closing the
related, pre-existing, same-issue cross-role R5 gap this fix does not
touch (`cd docs/issue-3/reports && cp /tmp/a review.md` allowing when R5
would want deny — needs per-command destination-argument extraction, a
materially larger surface) are both named explicitly out of scope; see
`docs/issue-99/proposals/2026-08-03-fix-board-gate-dead-fallback-and-cd-write-verb-gap.md`.

Also covers a wrapper-prefixed `cd` argument-extraction gap (issue-107,
Finding 1 of `docs/issue-99/reports/execution-observation.md`): head
detection (`gate_lib.gate_head_of`) correctly resolves a wrapped segment
like `timeout 30 cd docs/issue-49` to `cd` through
`gate_lib._resolve_transparent`'s wrapper walk, but `_cd_target` used to
re-split the RAW segment (`stripped.split()[1:]`) instead of reading that
same walk's own trailing words — an index assumption a wrapper prefix
invalidates, so it read the wrapper's own argument (`timeout`'s duration,
or the wrapper word itself for an argument-less wrapper like `command`)
instead of the real `cd` target. `cd_tail` was then never set, and a
`docs/`-token-free write after the wrapped `cd` reached `allow()` with no
rule applied — the same unadjudicated-write class issue-99 was filed to
close, just reachable through a wrapper prefix issue-99 itself did not
have to consider. Fixed with a new accessor,
`gate_lib.gate_trailing_words(segment)` (`_resolve_transparent(segment)[1]`),
so `_cd_target` reads the same command-start model `gate_head_of` already
uses instead of a second, independent one. `bash-wrapper-timeout-cd-relative-foreign`
and `bash-wrapper-command-cd-relative-foreign` pin the fix (`deny`),
covering both the extra-argument wrapper shape (`timeout`) and an
argument-less pre-issue-98 wrapper shape (`command`).

Also covers a wrapper-prefixed `git` subcommand-extraction gap (issue-114,
Finding 1 of `docs/issue-107/reports/execution-observation.md` — the
sibling issue-107 itself left open when it closed the same class for
`cd`): head detection (`gate_lib.gate_head_of`) correctly resolves a
wrapped segment like `timeout 30 git log` to `git` through
`gate_lib._resolve_transparent`'s wrapper walk, but `_git_subcommand` used
to re-split the RAW segment (`segment.split()[1:]`) instead of reading
that same walk's own trailing words, so it read the wrapper's own
argument (`timeout`'s duration, or the wrapper word itself for an
argument-less wrapper like `command`) instead of the real git subcommand.
Neither is in `GIT_READ_SUBCOMMANDS`, so a wrapper-prefixed read-only
`git` segment was misclassified as a write candidate — a fail-closed
over-block only (a wrapper-prefixed git *write* segment stayed denied
both before and after), not a security hole. Fixed by switching
`_git_subcommand` to iterate `gate_lib.gate_trailing_words(segment)`
instead of `segment.split()[1:]` — the same accessor issue-107 already
built and `_cd_target` already consumes.
`bash-wrapper-timeout-git-log-foreign-issue` and
`bash-wrapper-command-git-log-foreign-issue` pin the fix (`allow`),
covering the extra-argument wrapper shape (`timeout`) and an
argument-less pre-issue-98 wrapper shape (`command`);
`bash-wrapper-timeout-git-rm-foreign-issue` pins the reverse direction
(`deny`, unchanged before and after) — a wrapper-prefixed git *write*
segment still denies. The `git -C <dir> <subcommand>` global-flag misread
named in the prior paragraph (`git -C /tmp log` reading `/tmp` as the
subcommand) was left untouched by issue-114 on purpose — `-C` is a
`git`-own flag, not a `TRANSPARENT`-wrapper prefix, out of that issue's
scope — but is no longer an open gap: it is closed by issue-124/R2, below.

Also covers a `git`-own global-value-flag misread (issue-124, R2 —
`docs/issue-114/reports/execution-observation.md` `## Verdict 4`, R2):
`_git_subcommand` had no notion that some of git's own global flags take a
separate, space-joined value token, so `git -C /tmp log` read `/tmp` as the
subcommand instead of `log` — not in `GIT_READ_SUBCOMMANDS`, so the segment
was misclassified as a write candidate (an over-block, not a hole — the
fail-closed direction was already the case before this fix). Fixed with a
new module-level tuple `GIT_GLOBAL_VALUE_FLAGS = ("-C", "-c")` — the two
global flags `git`'s own synopsis documents as space-separated; the
`=`-joined long forms (`--git-dir=`, `--work-tree=`, `--namespace=`,
`--config-env=`) already resolved correctly with no code change, since an
`=`-joined flag never introduces an extra positional token for the loop to
misread — and rewriting `_git_subcommand`'s loop to walk
`gate_lib.gate_trailing_words(segment)` by index, skipping one extra word
whenever the current word is in `GIT_GLOBAL_VALUE_FLAGS`, the same
`skip_extra` shape `_resolve_transparent` itself already uses, scoped to
this function only. `bash-git-c-flag-log-foreign-issue` pins the fix
(`allow`, subcommand now correctly read as `log`); its negative-space
sibling `bash-git-c-flag-rm-foreign-issue` pins that a `git -C ... rm`
write stays denied, unchanged before and after.

Also covers, as this gate's fail-closed consumer, a `TRANSPARENT`-wrapper
own-value-flag misread fixed at its source in `gate_lib._resolve_transparent`
(issue-124, R3 — `docs/issue-114/reports/execution-observation.md`
`## Verdict 4`, R3): the flag-skip loop treated every `-`-prefixed token as
self-contained, so a `TRANSPARENT` wrapper's own value-taking flag (e.g.
`timeout -s KILL 30 git log`) stole the wrapper's bare-positional slot and
resolved the head to the wrong token (`"30"`, not `"git"`) — here, that
means a wrapper-and-git-own-flag-prefixed read fell through to
`return True` in `_segment_is_failing` (unresolved head, write candidate)
even though `_git_subcommand`'s own R2 fix above is correct once the head
actually resolves to `"git"`. Fixed in `core/hooks/lib/gate-lib.py` by
adding `TRANSPARENT_FLAG_TAKES_ARG` — a per-wrapper table of the four
`TRANSPARENT` members with a documented own value-taking flag
(`nice -n`/`--adjustment`, `env -u`/`--unset`, `timeout -s`/`--signal`,
`xargs -I`) — consulted in `_resolve_transparent`'s inner loop before the
existing `skip_extra`/bare-flag branches get a chance at the flag's value
token. `board-gate.sh` carries no code change for R3 (the fix is entirely
in `gate-lib.py`, this file's own shared primitive), but the R2 test cases
above already exercise the corrected resolver transitively; R3 itself is
pinned directly by new `headof` cases in `run-gate-lib-tests.sh` (see that
harness) since `_resolve_transparent`/`gate_head_of` is where the defect
and the fix both live. Also pinned from the write-verdict side, closing a
gap the observation of PR #126 found (issue-132, F1):
`bash-wrapper-timeout-s-git-rm-foreign-issue`, in this file, exercises a
`TRANSPARENT` wrapper's own value-taking flag on a `git` *write* segment
(`timeout -s KILL 30 git rm ...`) — `deny`, unchanged before and after,
since a resolver-level misread here falls through to `_segment_is_failing`'s
unresolved-head default-deny rather than opening a hole. The four
`run-gate-lib-tests.sh` cases pin the resolver's read→head correctness;
this case pins that the allow/deny verdict computed one layer up in
`_segment_is_failing` stays correct (and fail-closed even if it weren't)
once that head is consumed.

**Accepted residual coverage (issue-132, B1/B2).** Two of this gate's flag
tables cover a documented subset of their real surface, not its full
surface, and both residues are fail-closed (over-block only, never a
hole) — this is an accepted, intentionally-bounded limitation, not an
unnoticed gap: (a) `GIT_GLOBAL_VALUE_FLAGS` (`board-gate.sh`, R2 above)
covers `-C`/`-c` only; git also accepts several other global flags in the
same space-joined form (e.g. `--namespace <ns>`) that this table does not
recognize — an unrecognized global flag's value token can still derail
subcommand extraction the same way `-C`/`-c` used to, defaulting to deny.
(b) `TRANSPARENT_FLAG_TAKES_ARG` (`gate-lib.py`, R3 above) covers one
documented own-value-taking flag per wrapper; `env`, `timeout`, and
`xargs` each accept further value-taking flags the table does not list —
same fail-closed consequence. Neither table is expanded speculatively
here: the observed proposal that shipped R1-R3 already scoped both tables
minimally on purpose ("adding speculative table entries for hypothetical
future flags nobody has hit would be scope creep in the direction issue
#124 is trying to close, not open"), and the independent observation of
that delivery confirmed both residues as out-of-scope class facts, not a
PR #126 defect. The **expansion trigger** for either table: a concrete
command line that actually hits one of these uncovered shapes and is
over-blocked in real use — mirroring this same handbook's own
`gap-awk-comparison-over-block` convention above (kept visible rather than
silently accepted). Until such a case exists, both residues stay
documented here, not coded.

Also covers issue-142's C4 sweep: the `internal_error` case's scratch
`python3` stub directory used to come from a raw `mktemp -d` call,
replaced with the `mktd` helper from `_tmp.sh`, assigned to a separate
`stubdir` so it does not collide with the case's own `td`. Mechanical,
no behavior change; no new test cases. See
`docs/handbooks/approval-gate-tests.md` for the full rationale (shared
across all four harnesses this sweep touched).

Also covers issue-138's fail-closed rc-remap fix: `board-gate.sh` used
to clear the EXIT trap before propagating the python judge's own exit
code, so an uncaught python error (rc=1) exited non-blocking instead of
denying. `python3-internal-error` stubs a `python3` on `PATH` that
unconditionally exits 1 and asserts the gate still exits 2 (deny), the
same `_fc_rc`-style remap `trailer-gate.sh`/`record-fields-gate.sh`
already carried. `empty-payload` pins that empty stdin denies rather
than silently falling through the `*docs*` fast path to allow.

**issue-149: URL false positive on the docs/ tail extractor.** The
`own_hits` regex in the `Bash` candidate-builder branch and
`_docs_relative_tail` shared no concept of "this token names an external
resource" -- either function found the substring `docs/` anywhere in a
token, so an external URL whose path happens to contain that substring
(e.g. `code.claude.com` under a scheme) got its post-substring remainder
extracted and classified against the six standing buckets, which it
predictably failed, denying a plain read of an external page. Cause: the
`own_hits` char class (`[\w./~$-]`) excluded `:`, so the greedy prefix
match before the substring severed at the URL's own scheme colon
(`https:`), landing the match on the host-plus-path remainder and
producing a tail that reads as an unrecognized top-level docs component.
Fixed by widening the char class to `[\w./~$:-]` (so a scheme is captured
as part of the match instead of being severed) and adding a URL
classifier inside `_docs_relative_tail`: a token matching
`^[A-Za-z][A-Za-z0-9+.-]*://`, or containing `://` before its first
docs-substring occurrence, returns `""` immediately -- the same "no
docs-token here" result the function already returns when no such
substring is present at all. No new allow path was added; the token
simply stops being a candidate. Pinned by `url-docs-path-1`/
`url-docs-path-2` (the issue's own two repro URLs, both `allow`) and the
negative-space siblings `url-docs-negative-write`/`url-docs-negative-issue`
(genuine out-of-bucket repository writes, both `deny`, unchanged) proving
the fix narrows classification without loosening the deny.

**issue-187: comment/echoed text is not a write target.** `own_hits`
scanned a failing `Bash` segment's full raw text, so a `docs/issue-N`
-shaped string sitting only in an ECHOED comment (e.g. `echo "see
docs/issue-3/x.md for context" > /tmp/notes.txt`) was misread as a write
candidate even though the real redirect target was `/tmp/notes.txt`.
Fixed by `_write_target_windows(seg, stripped)`: for a failing segment
whose failure reason is a real (outside-quotes) `FILE_REDIR` match or a
`tee` head, `own_hits` now scans only the actual write-target window —
the text immediately following the redirect operator, or `tee`'s own
trailing non-flag arguments — instead of the whole segment. Every other
failing reason (git write subcommands, subshells, in-place edits, and
`READ_UNLESS_INPLACE`'s own raw quote-blind redirect scan for `awk`/`sed`,
where the matched argument IS the real target and
`gap-awk-comparison-over-block`'s accepted over-block already depends on
the full-segment scan) keeps scanning the whole segment, unchanged.
`bash-echo-comment-not-target` and `bash-tee-comment-not-target` pin the
fix (`allow`: a comment mentioning a foreign record no longer denies a
write elsewhere); their negative-space siblings
`bash-echo-comment-real-target` and `bash-tee-comment-real-target` pin
that a real write into a foreign record through the same echo/redirect or
echo/tee shape still denies. `gate_lib.gate_dequote` collapses each
quoted span to a single space rather than preserving its length, so the
window extractor slices the write-target tail from the dequoted text
itself (not the original segment) to keep match offsets aligned.

Also issue-187: `warrant/hooks/scope-gate.sh`'s frozen-write-set gate
gained a content-inspect carve-out for `hooks/*.sh` paths (this handbook
covers `board-gate.sh`'s own sibling fix above; see
`core/hooks/tests/run-scope-gate-tests.sh` for the scope-gate coverage,
run from `run-all.sh`'s `scope gate (warrant)` section). A hook-script
edit outside the frozen write set no longer denies on path alone — its
proposed content is checked against a small denylist (piping into a
shell, `curl`/`wget` piped into a shell, `rm -rf`, `sudo`, disabling a
trap by ignoring `EXIT` (`trap '' EXIT`), short-circuiting a gate's kill
switch check) and only a hit still denies; every other path keeps the
content-blind write-set behavior unchanged.

issue-189: `warrant/hooks/scope-gate.sh`'s `KNOWN_STATES` gained
`"rejected"` alongside `"withdrawn"` — same non-warrant treatment (known,
readable, never eligible for the write-set/trailer enforcement branch).
`run-scope-gate-tests.sh`'s `run_status` harness pins
`rejected-proposal-stands-down` next to the existing
`withdrawn-proposal-stands-down` case. `core/hooks/tests/deny-only-check.sh`
also gained a `reject_forgery_probe`, symmetric to its existing
`forgery_probe`: an off-branch forged board write is refused the same way
regardless of whether its content spells approval or rejection (no new
trust boundary — see `docs/issue-189/proposals/2026-08-10-rejection-withdrawal-lifecycle-design.md`).

A before-landing warrant-hunt (stance 1) found the first version of this
denylist too broad: `trap - EXIT` (restore-default) is the project-wide
sanctioned early-exit idiom every gate script's own kill-switch/success
path uses (`{ trap - EXIT; exit 0; }`), so writing a hook edit whose
content merely reproduces another gate's own shipped source (the hunt's
repro used `core/hooks/gh-guard.sh` verbatim) was denied as "disabling a
gate's fail-closed trap" — defeating the carve-out's own purpose. Fixed
by narrowing the rule to the actually-dangerous shape: disarming a trap
by IGNORING the signal (`trap '' EXIT` / `trap -- '' EXIT`, which
silences whatever the trap existed to run with no exit to follow it),
never the sanctioned restore-then-exit idiom. `hook-write-disables-trap`
pins the narrowed rule (`deny`); its negative-space sibling
`hook-write-standard-early-exit` pins the sanctioned idiom now allowing.

issue-216 (observed as on-the-record#1581): `warrant/hooks/scope-gate.sh`'s
malformed-frontmatter branch (`len(approved) != 1` with a non-empty
`malformed` list) used to `sys.exit(1)` unconditionally, which the gate's
own fail-closed EXIT trap remaps to `exit 2` — hard-blocking every tool
call in the session, including pure reads, whenever any
`docs/proposals/*.md` had no closing `---` or an unrecognized `status`.
That blocked the only path to even inspecting the file the warning names.
Fixed by degrading to warn-and-allow for read-only calls: a read tool
(`Read`/`Grep`/`Glob`/`NotebookRead`) or a `Bash` command that passes the
existing `readonly_allowed()` allowlist still gets the same stderr
warning, but exits 0 instead. Write/Edit/NotebookEdit and any
non-allowlisted Bash still hit the hard block, unchanged — a gate that
cannot enforce a write-set (no single approved unit) has nothing to
protect from a read. `SHELL_CHAIN`/`SAFE_ARG`/`READONLY_ALLOW`/
`readonly_allowed()` moved earlier in the script so the malformed branch
(which now needs them) can reach them; a new `call_is_readonly()` helper
classifies the current tool call. `run-scope-gate-tests.sh`'s
`run_malformed` harness pins: `malformed-readonly-bash-allowed`,
`malformed-read-tool-allowed`, `malformed-grep-tool-allowed` (all
`allow`); `malformed-write-still-blocked`,
`malformed-nonreadonly-bash-still-blocked` (both `deny`, unchanged).

issue-218: `readonly_allowed()`'s `SHELL_CHAIN` used to reject any command
containing `|`, so single-pipe read-only inspection pipelines
(`grep ... | head`, `git log | tail`) fail-closed instead of vouching,
while `SAFE_ARG`'s argument char class admitted `<`/`>`, letting a
redirection write (`cat a > b`) match the read-only allowlist. Fixed:
`SHELL_CHAIN` no longer disqualifies on a bare `|` (now rejects `;`, `&`,
backtick, `$(`, `||`, `<`, `>`, and embedded newlines instead);
`readonly_allowed()` splits the command on `|` and vouches only when
every segment independently matches `READONLY_ALLOW`; `SAFE_ARG` excludes
`<`/`>`; and a new `FIND_EXEC_FLAGS` guard refuses the vouch when a
`find` segment carries an exec-capable flag (`-exec`/`-execdir`/`-ok`/
`-okdir`/`-delete`/`-fprint`/`-fprintf`/`-fls`). `run-scope-gate-tests.sh`
pins: `malformed-piped-grep-head-allowed`,
`malformed-piped-git-log-tail-allowed`, `approved-piped-all-readonly-allowed`
(all `allow`); `malformed-piped-grep-sh-denied`,
`malformed-redirect-write-denied`, `malformed-newline-smuggled-denied`,
`malformed-find-exec-denied` (all `deny`).

issue-218 follow-up (PR #219 review): `FIND_EXEC_FLAGS`'s `fprint\b`
matched `-fprint` but not `-fprint0`, since `0` is a word char and leaves
no boundary after `t` — so `find . -fprint0 out`, a file write, still
passed the read-only vouch. Fixed by widening the alternative to
`fprint0?`. `run-scope-gate-tests.sh` pins a new
`malformed-find-fprint0-denied` case (`deny`).

Scope item 2 of issue-149 surveyed the same find-anywhere root cause for
other false-positive shapes and reported, without fixing, two further
cases and one examined-and-ruled-out path: (1) a directory name that
merely *ends in* the docs component (e.g. `mydocs/x.md`) still matches
the plain substring search the same way; (2) a docs-shaped substring
inside a quoted literal that names no path at all (e.g. a grep pattern or
commit message) still becomes a candidate, since `own_hits` runs on raw
segment text rather than a quote-stripped view; (3) the `cd`-tracking
path was examined and found not to carry the URL false positive (a `cd`
to a URL is not a real shell operation) -- it carries case (1) only, not
a new shape. See the issue-149 proposal's Out of scope section for the
full survey.

## R4 maintenance-targets exception (issue-222)

R4 ("board write happens only on branch issue-<n>/<role>") now carries a
narrow, operator-controlled exception: when the current branch's own
issue (`issue-<n>/<role>` matching `CLAUDE_ROLE`) has a body containing a
literal `maintenance-targets: <tree list>` line, that branch may ALSO
write the listed other `docs/issue-<m>/` trees. The declaration is read
live via `gh issue view <own-issue> --json body` (the `CORE_GH` test
seam, same shape as `approval-gate.sh`'s issue-state check) — never
cached to a repo file, since a repo file would be exactly the surface a
role's own tools could self-expand. The lazy fetch fires only on a
same-issue mismatch (never on the ordinary own-issue write path), and
any `gh` failure or unparseable body is treated as an empty declaration
set — fail closed, same as no declaration existed. Accepted target
tokens: `docs/issue-<n>` or `issue-<n>` (comma/whitespace separated).

`run-board-gate-tests.sh` pins: `maint-refused-no-decl` (deny, no
declaration — byte-identical to pre-issue-222 R4), `maint-permitted-decl`
(allow, matching `maintenance-targets:` entry), `maint-unlisted-refused`
(deny, declaration present but not naming the target tree),
`maint-own-issue-never-calls-gh` (allow, with `CORE_GH` pointed at a
nonexistent path — proves the own-issue path never shells out).

## Un-analyzable write-capable Bash shapes (issue-225)

A script interpreter invocation with an inline body — a heredoc
(`python3 - <<EOF`, `bash <<EOF`), an interpreter `-c`/`-e` flag
(python3/python/bash/sh/zsh/perl/ruby/node), or `dd` — carries its real
write target somewhere the gate cannot read it from the visible command
text. `_mask_heredocs` (issue-198) already blanks heredoc bodies before
the segment scan runs, so a write hidden inside one contributed zero
candidates and the whole call fell through `if not hits: allow()` as a
plain read — the exact bypass on-the-record PR #1627 hit live (`python3
- <<EOF` after board-gate had already denied a direct cross-issue
`Edit`).

board-gate now tracks, per write-capable-and-unproven segment, whether it
is also "unanalyzable" this way AND contributed no docs/-shaped candidate
of its own; when a role is set and the repo is a board
(`docs/specs/approvers.md` present), any such segment denies the whole
call before the `if not hits: allow()` fallthrough. `warrant/hooks/
scope-gate.sh` carries the matching fix: the same shape check runs ahead
of `withheld()`/`readonly_allowed()` in the Bash branch that only
executes while exactly one proposal is `approved` (a write-set is
actively enforced) — `tee`/`dd` previously matched `withheld()`'s own
entries and only declined to vouch (the same fallthrough posture as any
unrecognized command); they now deny explicitly, same as heredocs/`-c`/
`-e`.

Both fixes apply only where a write-set is actually being enforced — an
unrestricted session (no `CLAUDE_ROLE`, or no approved proposal in
progress), and a repo with no enforceable write-set, keep today's
behavior byte-identical. `python3 -m pytest` and every other provably
read-only call remain unaffected.

`run-board-gate-tests.sh` pins: `heredoc-python-mask-bypass`,
`heredoc-bash-mask-bypass`, `inline-c-flag-mask-bypass` (deny — the live
bypass shape and its bash/`-c` siblings), `heredoc-unrestricted-session-
unaffected` (allow — no board contract, no role), `python-pytest-still-
allowed` (allow — provably read-only, even alongside an unrelated docs/
mention on the same line).

`run-scope-gate-tests.sh` pins the matching cases against an approved
write-set: `heredoc-write-shape-denied`, `bash-heredoc-write-shape-
denied`, `inline-c-flag-write-shape-denied`, `tee-write-shape-denied`,
`dd-write-shape-denied` (deny), `python-pytest-still-allowed` (allow),
`heredoc-unrestricted-session-unaffected` (allow — no `docs/proposals`
directory at all, so the gate stands down).
