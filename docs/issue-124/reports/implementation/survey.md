# Current-state survey — issue-124

Subject: issue-124 ("래퍼 파서-차동 클래스의 잔여 서식지 3곳 일괄 종료 —
R1·R2·R3"). Scope: the three residual habitats issue-114's step-2
execution observation named in its Verdict 4
(`docs/issue-114/reports/execution-observation.md:232-304`), read here
directly from the current tree (branch `issue-124/implementation`, based
on `main` at merge commit `451439e` and unchanged since for these files —
confirmed by `git log -1 --format=%H -- core/hooks/approval-gate.sh
core/hooks/board-gate.sh core/hooks/lib/gate-lib.py` all resolving to
`451439e` or earlier).

## R1 — `approval-gate.sh`'s early-allow head, no `TRANSPARENT` resolution

`core/hooks/approval-gate.sh:118-124`:

```python
head = cmdline.strip().split()[0].rsplit("/", 1)[-1] if cmdline.strip() else ""
if head in READ_ONLY_HEADS and not gate_lib.gate_outside_quotes(cmdline, r"[>|`]|\$\("):
    allow()              # reading the tree is phase-agnostic
```

`gate_lib` is already imported at `approval-gate.sh:62-64` (same
`importlib.util.spec_from_file_location` pattern `board-gate.sh` and
`gh-guard.sh` use) — this site simply never calls into it for head
resolution. `head` is word 0 of the *raw* command line, so a wrapper
prefix (`timeout 30 grep -rn foo src/`) resolves to `"timeout"`, which is
not in `READ_ONLY_HEADS` (`approval-gate.sh:88-89`, the same 10-entry
tuple `board-gate.sh` used to carry pre-issue-60/88), so the shortcut is
skipped and the command falls through to the candidate-token scan
(`approval-gate.sh:125-127`) — over-block, not a security hole (this gate
already denies by default when candidates hit; missing the shortcut just
means a legitimate read gets judged the slow way, and for a bare read
with no `src/`/`test/`/`docs/issue-*` token in it at all, `hits` stays
empty and `allow()` still fires at `approval-gate.sh:132-133`, but a
wrapped read *whose arguments happen to contain such a token* — e.g.
`timeout 30 grep -rn foo src/app.py` — has no such rescue and is
misjudged).

`gate_lib.gate_head_of(segment)` (`core/hooks/lib/gate-lib.py:238-245`)
is exactly this resolution, already relocated out of `board-gate.sh` in
issue-98 for reuse by `board-gate.sh` and `gh-guard.sh`. It calls
`_resolve_transparent(segment)[0]`, handles the empty-string case the
same way (`""` in, `""` out — `_resolve_transparent("")` hits the
`while words:` guard on an empty list and returns `("", [])`), and
already strips the `.rsplit("/", 1)[-1]` basename the current line does
by hand. A straight substitution —
`head = gate_lib.gate_head_of(cmdline)` — is a drop-in for the existing
line; `gate_head_of` is written for a single command *segment*, and this
call site only ever sees the shortcut fire for a single-segment line in
the first place, because the accompanying
`gate_lib.gate_outside_quotes(cmdline, r"[>|`]|\$\(")` check already
requires no pipe/`&&`/`` ` ``/`$(` character survive outside quotes
before the shortcut is even considered (`approval-gate.sh:123`) — so
feeding the whole `cmdline` into `gate_head_of` is safe: whenever this
branch runs, `cmdline` is a single segment by construction.

## R2 — `board-gate.sh`'s `_git_subcommand`, value-taking global flags

`core/hooks/board-gate.sh:187-207`:

```python
def _git_subcommand(segment):
    for w in gate_lib.gate_trailing_words(segment):
        if not w.startswith("-"):
            return w
    return ""
```

`gate_trailing_words` (`gate-lib.py:248-260`) already resolves through a
`TRANSPARENT` wrapper prefix (issue-114's fix). What it does not do —
undocumented as a gap in its own docstring, but explicit in
`_git_subcommand`'s docstring (`board-gate.sh:190-193`) — is know that
`git`'s own global flags can take a *separate* value token before the
subcommand. `git`'s synopsis (`man git`, `git version 2.50.1` in this
environment) is:

```
git [-v | --version] [-h | --help] [-C <path>] [-c <name>=<value>]
    [--exec-path[=<path>]] [--html-path] [--man-path] [--info-path]
    [-p | --paginate | -P | --no-pager] [--no-replace-objects] [--no-lazy-fetch]
    [--no-optional-locks] [--no-advice] [--bare] [--git-dir=<path>]
    [--work-tree=<path>] [--namespace=<name>] [--config-env=<name>=<envvar>]
    <command> [<args>]
```

`-C <path>` and `-c <name>=<value>` are git's own two space-separated
(non-`=`-joined) global flags — the ones a hand-typed command line
actually uses this way in practice (`--git-dir=`/`--work-tree=`/
`--namespace=`/`--config-env=` are conventionally spelled with `=`
attached, per the synopsis's own bracket notation, and are not the shape
issue #124's text or issue-114's observation names). For
`git -C /tmp log`, `gate_trailing_words` returns
`["-C", "/tmp", "log"]`; the current loop's `not w.startswith("-")` test
skips `"-C"` (flag-shaped) but then returns `"/tmp"` — the *value* of
`-C`, not the subcommand — because the loop has no notion that `-C`
consumes the next word. `"/tmp"` is not in `GIT_READ_SUBCOMMANDS`
(`board-gate.sh:181-184`), so the segment becomes a write candidate:
fail-closed over-block, matching issue-114's own Verdict-4 citation
(`docs/issue-114/reports/execution-observation.md:271-281`, which in
turn cites the shipped docstring at `board-gate.sh:191-194` and the
prior record's declared-out-of-scope note at
`docs/issue-114/reports/implementation.md:192-194`).

The fix shape issue #124 names — "값-받는 git 전역 플래그 스킵 추가" — is a
value-flag table analogous to `gate-lib.py`'s own
`TRANSPARENT_TAKES_ARG` (`gate-lib.py:200`), scoped to `_git_subcommand`
only (constraint: `#107(_cd_target)`/`#114(_git_subcommand 골격)`'s landed
form is respected; `_cd_target`'s own argument-taking-flags need is a
different question — `cd` takes no global flags of this shape and is out
of this issue's text). No test in `run-board-gate-tests.sh` currently
exercises `git -C`/`git -c` at all (grep confirms: no `-C` or `-c` token
appears among the `git`-headed cases in the "git subcommand awareness"
block or the wrapper-prefixed block added by issue-114) — so this is a
real gap being closed, not a previously-tested-then-broken behavior.

## R3 — `gate-lib.py`'s `_resolve_transparent`, a wrapper's own value-taking flag

`core/hooks/lib/gate-lib.py:203-235`:

```python
def _resolve_transparent(segment):
    words = segment.split()
    while words:
        w = words[0].rsplit("/", 1)[-1]
        if w not in TRANSPARENT:
            return w, words[1:]
        skip_extra = w in TRANSPARENT_TAKES_ARG
        i = 1
        while i < len(words):
            tok = words[i]
            if tok.startswith("-") or "=" in tok.split("/")[0]:
                i += 1
                continue
            if skip_extra:
                skip_extra = False
                i += 1
                continue
            break
        words = words[i:]
    return "", []
```

Traced for `timeout -s KILL 30 git log`: `words[0]` is `"timeout"` (in
`TRANSPARENT`); `skip_extra = True` (`"timeout"` is in
`TRANSPARENT_TAKES_ARG`, `gate-lib.py:200`). The inner loop: `i=1`,
`tok="-s"` — flag-shaped, `i` becomes 2 (treated as self-contained,
*not* as a flag that itself takes a value). `i=2`, `tok="KILL"` — not
flag-shaped, so it falls to the `skip_extra` branch: consumed as
`timeout`'s own bare-DURATION slot (wrong; that slot belongs to `"30"`),
`skip_extra` cleared, `i` becomes 3. `i=3`, `tok="30"` — not flag-shaped
and `skip_extra` is now `False`, so the loop `break`s here. `words`
becomes `words[3:]` = `["30", "git", "log"]`; the outer `while` loops
again with `w = "30"`, which is not in `TRANSPARENT`, so
`_resolve_transparent` **returns `("30", ["git", "log"])`** — the head
resolves to `"30"`, not `"git"`.

This is not a hidden defect — `gate-lib.py`'s own docstring for the
*different* function `gate_wrapper_head_before` states it outright
(`gate-lib.py:283-291`, listing `nice -n 10`, `env -u FOO`,
`timeout -s KILL 30`, and `xargs -I fmt` as exactly the shapes
`_resolve_transparent`'s walk misresolves — worded as the reason
`gate_wrapper_head_before` deliberately does *not* call into that walk).
`gate_wrapper_head_before` is used only by `gh-guard.sh`
(`core/hooks/gh-guard.sh:147`), whose failure direction is fail-*open*
(`gate-lib.py:281-296` states this design choice explicitly — the
constraint issue #124 names as unchanged: "gh-guard.sh 의 비-리졸버 선택은
무변경"). `_resolve_transparent`/`gate_head_of`/`gate_trailing_words`
serve `board-gate.sh`, whose failure direction for an unresolved or
misresolved head is fail-*closed* (`board-gate.sh:210-238`,
`_segment_is_failing`'s final `return True`) — so the exact same
misresolution that is merely a documented, accepted non-hole for
`gh-guard.sh` is an over-block for `board-gate.sh` (e.g.
`timeout -s KILL 30 git log -- docs/issue-49` denies a pure read today).

The four shapes the docstring already names (`nice`, `env`, `timeout`,
`xargs`) are the ones with a documented own-flag-takes-a-value case in
common shell usage; `time`, `command`, `builtin`, `nohup` (the other
`TRANSPARENT` members) carry no such commonly-used value-taking flag.
`run-gate-lib-tests.sh`'s existing `wrapperhead` cases already cover
these four shapes for `gate_wrapper_head_before`
(`run-gate-lib-tests.sh:257-260`); no equivalent case exists for
`gate_head_of`/`_resolve_transparent` today — `headof`'s five cases
(`run-gate-lib-tests.sh:207-216`) cover `bash -c`, `xargs`/`xargs -I{}`
(glued, no-space flag forms), `timeout`'s own bare DURATION, and `nohup`,
but no wrapper-own value-taking flag in space-separated form.

## Test-harness and doc-placement surfaces touched

- `core/hooks/tests/run-approval-gate-tests.sh` — real-subprocess harness
  for `approval-gate.sh` (`run()` helper, `want allow|deny`); R1's fix
  needs a new wrapped-read case plus a same-shape write-direction sibling
  (issue-114's own two-case-per-habitat convention).
- `core/hooks/tests/run-board-gate-tests.sh` — real-subprocess harness
  for `board-gate.sh`; R2's fix needs `git -C <dir> log`-shaped
  read-allow plus `git -C <dir> rm ...`-shaped write-deny.
- `core/hooks/tests/run-gate-lib-tests.sh` — direct-`python3`-import
  harness (`headof`/`wrapperhead` helpers) for `gate-lib.py`; R3's fix
  needs a `headof` case for `timeout -s KILL 30 git log` (and reasonably
  its siblings `nice -n 10`, `env -u FOO`, `xargs -I fmt`, matching what
  `wrapperhead` already covers for the other function) resolving to the
  real command, not the misread token.
- `core/hooks/handbook-trigger-gate.sh:90-114` — its `OP_PATTERNS`
  regex `(^|/)(deploy|setup|run|install)[^/]*\.sh$` matches all three
  `run-*-tests.sh` files above. A commit that stages any of them (which
  this delivery's phase 2 will) is refused unless the same commit also
  stages some file under `docs/handbooks/` — "conservative component
  derivation": *any* handbook file counts, not necessarily a matching
  one (`handbook-trigger-gate.sh:11-13`). `docs/handbooks/` already has
  dedicated `approval-gate-tests.md` and `board-gate-tests.md` files
  documenting each prior fix in this same lineage (issue-60, -88, -90,
  -94, -98, -99, -107, -114 for `board-gate-tests.md`; issue-88/-90/-94
  for `approval-gate-tests.md`), and no dedicated
  `gate-lib-tests.md` handbook exists — `gate-lib.py`'s own coverage is
  documented inline in those same two files plus its own top-of-file
  comment (`gate-lib.py:1-13`). Following the existing convention (one
  paragraph per fix, in the handbook matching the test file that gained
  the case) rather than relying on the gate's "any handbook" minimum is
  the established practice this delivery's phase 2 should keep.
- `docs/issue-114/reports/execution-observation.md` — the R1/R2/R3
  citations this issue is scoped from; read-only reference, not written.

## Unknowns / residual risk carried into the proposal

- Whether `git -c <name>=<value>` (the second git-own space-separated
  global flag) should be handled identically to `-C` in the same table,
  or whether issue #124's text ("값-받는 git 전역 플래그", plural, no single
  flag named) implies exactly this. Resolved in the proposal's
  `## What will be done` — both are the two flags git's own synopsis
  documents as space-separated-only, so both go in the same table by the
  same reasoning; no `=`-joined-only long flag is included, since none
  of those appear in any existing test fixture or issue text and adding
  speculative coverage for a shape nobody has hit would be scope creep
  in the other direction.
- Whether R3's fix should extend to all eight `TRANSPARENT` members or
  only the four the docstring already documents. Resolved in the
  proposal's `## Rationale` — scoped to the four documented shapes.

## Scout-directive skip record

**Skipped.** Reason: pure bugfix to internal command-parsing logic — the
same skip condition issue-114's own phase-1 survey recorded
(`docs/issue-114/reports/implementation/survey.md:196-205`, "pure bugfix
to internal command-parsing logic") for the immediately preceding fix in
this identical lineage (#99 → #107 → #114 → #124). All three habitats
here are internal parser-differential bugs in already-existing,
already-scoped gate logic with no product-facing surface, no new
dependency, and no external category to benchmark against; issue #124's
own text additionally pre-specifies each fix's minimum shape, leaving
implementation detail (which flags, which table shape) as the only open
design surface — addressed above and in the proposal's `## Rationale`
via the codebase's own existing conventions (`TRANSPARENT_TAKES_ARG`,
`gate_wrapper_head_before`'s docstring) rather than external research.
