---
kind: current-state-survey
subject: issue-114
produced_by: implementation
loop_state: surveyed
---

# Survey: issue-114 — `_git_subcommand` re-splits the raw segment, same class #107 fixed

## Scope

Issue #114 asks for a phase-1 proposal only (explicit in the issue body:
"phase 1 이므로 구현하지 않는다"). It formalizes Finding 1 of
`docs/issue-107/reports/execution-observation.md`, which found — after
PR #108 unified `_cd_target`'s argument extraction with
`gate_lib.gate_trailing_words` — that `board-gate.sh`'s `_git_subcommand`
still re-splits the raw segment for its own argument (the git
subcommand), the same parser-differential seam #107 closed for `cd`.

## The bug, read from the current tree (working tree == `origin/main`,
`git status` clean, HEAD `2b093c1`, merged through PR #112)

Two functions inside `_segment_is_failing`
(`core/hooks/board-gate.sh:202-230`) answer two different questions about
a `git`-headed segment, using two different models of where the command
starts:

- **Head detection** (`core/hooks/board-gate.sh:214`,
  `gate_lib.gate_head_of(stripped)`) resolves through `TRANSPARENT`
  wrappers (`gate-lib.py:194-235`, `_resolve_transparent`) and correctly
  identifies `"timeout 30 git log"` as headed by `"git"`.
- **Subcommand extraction** (`core/hooks/board-gate.sh:187-199`,
  `_git_subcommand`) does NOT go through the resolver. It re-splits the
  raw segment itself — `segment.split()[1:]` (`:195`) — and returns the
  first non-flag word, on the hard assumption the head sits at word 0.
  For `"timeout 30 git log"` this returns `"30"` (the wrapper's own
  duration argument), not the git subcommand.

The call site that composes them (`board-gate.sh:214-216`):

```
head = gate_lib.gate_head_of(stripped)          # :214 -- resolver-based, correct ("git")
if head == "git":
    return _git_subcommand(stripped) not in GIT_READ_SUBCOMMANDS   # :216 -- raw split()[1:], wrong ("30")
```

`gate_head_of` correctly resolves the head to `"git"` through the
wrapper; `_git_subcommand` at the same call then reads the wrapper's own
argument (`"30"` for `timeout`, or the literal head word `"git"` itself
for the six argument-less wrappers, e.g. `_git_subcommand` on
`"command git log"` returns `"git"`) instead of the real subcommand.
Neither `"30"` nor `"git"` is in `GIT_READ_SUBCOMMANDS`
(`board-gate.sh:181-184`), so `_segment_is_failing` returns `True` for a
segment that is actually a read-only `git log`.

**Direction confirmed empirically** (hand-traced against the live
`gate-lib.py` in this tree, `gate_head_of` unmodified, comparing the
current `_git_subcommand` body against a `gate_trailing_words`-based
replacement, both called with the identical segment text):

| segment | resolved head | current subcommand read | current classified read? | `gate_trailing_words`-based subcommand read | would classify read? |
|---|---|---|---|---|---|
| `git log` | `git` | `log` | True | `log` | True |
| `timeout 30 git log` | `git` | `30` | **False (overblock)** | `log` | **True (fixed)** |
| `nohup git log` | `git` | `git` | **False (overblock)** | `log` | **True (fixed)** |
| `command git log` | `git` | `git` | **False (overblock)** | `log` | **True (fixed)** |
| `timeout 30 git rm -r <path>` | `git` | `30` | False (write, correct by accident) | `rm` | False (write, correct on purpose) |
| `command git rm -r <path>` | `git` | `git` | False (write, correct by accident) | `rm` | False (write, correct on purpose) |
| `git -C /tmp log` | `git` | `/tmp` | False (pre-existing, unrelated global-flag gap) | `/tmp` | False (unchanged — `-C`'s own argument is not a `TRANSPARENT` wrapper, out of #114's scope) |
| `git` (bare) | `git` | `""` | False (safe fallback, per docstring) | `""` | False (unchanged) |

This confirms the issue's own diagnosis: the misread direction is
**fail-closed** (over-blocking a read-only wrapped `git` segment), never
fail-open — a wrapper-prefixed git *write* segment is denied both before
and after a fix, because `_segment_is_failing` defaults to `True`
(write-candidate) whenever the extracted subcommand isn't a recognized
read verb, and neither the wrapper's own token nor its duration argument
is ever in `GIT_READ_SUBCOMMANDS`. So this is a classification-accuracy
bug (unnecessary refusal), not a security hole — matching issue #114's
own "무판정 allow는 아니므로 보안 구멍이 아니라 분류 정확성 문제다."

The `git -C /tmp log` row is a **separate, pre-existing** gap: `-C`
takes its own value argument and neither the current code nor a
`gate_trailing_words`-based replacement special-cases it (both read
`/tmp` as the candidate subcommand). This is untouched by either the
current bug or its fix — `-C` is a `git`-own flag, not a
`TRANSPARENT`-wrapper prefix, and issue #114's requirements name only
the wrapper-prefix class. Confirmed out of scope below.

## `gate_lib.gate_trailing_words` — the accessor #107 already built

`core/hooks/lib/gate-lib.py:248-260`, added by issue #107 (PR #108):

```python
def gate_trailing_words(segment):
    return _resolve_transparent(segment)[1]
```

`core/hooks/board-gate.sh:259-273`, `_cd_target` (issue #107's own
consumer of this accessor) is the exact model issue #114 requirement 1
names as the target shape:

```python
def _cd_target(stripped):
    for w in gate_lib.gate_trailing_words(stripped):
        if not w.startswith("-"):
            return w
    return ""
```

`_git_subcommand`'s own docstring (`board-gate.sh:187-199`) already says
"same skip-leading-flags idiom `_git_subcommand` already uses for the
analogous git-subcommand case" is quoted the other direction inside
`_cd_target`'s docstring (`:263-264`) — i.e. `_cd_target`'s own comment
already treats `_git_subcommand`'s *flag-skip loop* as the reused idiom.
Issue #114 is the missing half: the loop body is already shared in
shape; only the *iteration source* (`segment.split()[1:]` vs
`gate_lib.gate_trailing_words(segment)`) still differs.

## Write set this proposal will name

- `core/hooks/board-gate.sh` — `_git_subcommand` (`:187-199`) changed to
  iterate `gate_lib.gate_trailing_words(segment)` instead of
  `segment.split()[1:]`; its own call site (`:216`,
  `_git_subcommand(stripped)`) is unchanged (same argument, same
  position).
- `core/hooks/tests/run-board-gate-tests.sh` — regression cases per
  issue #114 requirement 2 (red→green proof for a wrapper-prefixed
  read-only git segment; a fixed case for the reverse direction, a
  wrapper-prefixed git write segment staying denied).

`gate_lib.gate_trailing_words` and `gate_lib.gate_head_of` already exist,
unchanged, from #107 — **no `gate-lib.py` edit is needed** for this
issue, unlike #107 (which had to add the accessor in the first place).
This is the one structural difference from #107's write set.

`grep` across `core/hooks/*.sh core/hooks/lib/*.py` confirms
`_git_subcommand` has exactly one call site (`board-gate.sh:216`) and
`gate_trailing_words` has exactly one existing caller (`_cd_target`,
`:270`) plus this proposal's new one; no third consumer of either
symbol exists.

## Existing test conventions (`run-board-gate-tests.sh`)

- The "git subcommand awareness" block (`:223-239`, issue #60) already
  covers write-shaped git subcommands (`git rm`, `git checkout --`,
  `git restore`) denying, and read-shaped ones (`git log`, `git diff`,
  `git show`) allowing — all **unwrapped**. No existing case in this
  block, or anywhere in the file (confirmed by grep for `timeout.*git`,
  `nohup.*git`, `command.*git`), composes a `TRANSPARENT` wrapper with a
  `git` segment. The composition issue #114 must pin is genuinely new
  coverage.
- The parallel case #107 already landed for `cd`
  (`bash-wrapper-timeout-cd-relative-foreign`,
  `bash-wrapper-command-cd-relative-foreign`, `:304-305`) is the direct
  naming-convention precedent: `bash-wrapper-<wrapper>-<verb>-<...>`.
  issue #114's own two cases would extend that pattern for `git`, e.g.
  `bash-wrapper-timeout-git-log-*` (read, allow) and
  `bash-wrapper-timeout-git-rm-*` (write, deny) — exact names decided in
  the proposal.
- Red-then-green evidence convention: #107's own record
  (`docs/issue-107/reports/implementation.md`, `closed_checks`) added
  the new cases to the test file first, ran them against the unfixed
  tree to confirm `FAIL want=deny got=allow`, then applied the code fix
  and re-ran for a clean pass — the same convention issue #114
  requirement 2 asks for (red = over-block, i.e. `want=allow got=deny`
  for a read case here, since the failure direction is the opposite of
  #107's).
- Sandbox hazard already documented by #107's own record
  (`docs/issue-107/reports/implementation.md`, "What did not work"):
  `CLAUDE_PLUGIN_ROOT_CORE`, when set in the ambient shell, points
  `board-gate.sh`'s own `gate-lib.sh` source at the *installed* plugin
  copy instead of this working tree, so a phase-2 test run needs
  `env -u CLAUDE_PLUGIN_ROOT_CORE` to exercise the edited file. Not
  relevant to this phase-1 proposal itself, but carried forward here so
  phase-2 does not have to rediscover it.

## Design space for the fix

Issue #114 requirement 1 already names the target shape directly: unify
`_git_subcommand`'s argument extraction with the same command-start
model `gate_head_of` uses, i.e. `gate_lib.gate_trailing_words` — the
exact idiom `_cd_target` already applies. Given the write set above
touches exactly one function, one call site, and a test-only regression
addition, this is not an open design choice with multiple structurally
distinct shapes to weigh (unlike #107, which had to choose between
adding a new `gate-lib.py` accessor or renaming an internal one — that
choice is already made, by #107, and `gate_trailing_words` already
exists). The remaining decision the proposal must still make is
narrower: how `_git_subcommand`'s docstring records the change (to keep
it honest about what it now does, the way `_cd_target`'s docstring
records reading `gate_trailing_words`), and the exact regression-case
names/shapes. See the proposal's own Rationale for the one alternative
worth naming and rejecting.

## Scout-directive skip record

**Skipped.** This is a pure bugfix to internal command-parsing logic
inside a security gate (`board-gate.sh`) — no product-facing surface, no
library/framework choice, and no best-in-class category to compare
against. Issue #114 itself names the fix's direction (reuse the
resolver's own trailing words, the exact accessor #107 already built),
and the empirical trace above confirms it closes the over-block without
opening a new allow. No `scout-brief.md` is produced for this issue —
same skip condition and same reasoning #107's own survey recorded for
the sibling `_cd_target` fix.

## Open questions the proposal must resolve

- Exact regression-case names and count: at minimum, one wrapper-prefixed
  read-only git segment (over-block before, allow after) and one
  wrapper-prefixed git write segment (deny, unchanged, pinning the
  reverse direction issue #114 requirement 2 explicitly asks for).
  Whether to cover more than one wrapper head (e.g. both `timeout` and
  `command`, mirroring #107's own two-case pattern) is decided in the
  proposal.
- Whether `_git_subcommand`'s docstring needs a rewrite (it currently
  describes flag-skipping behavior only, not wrapper-prefix handling) or
  a smaller addendum.
