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
