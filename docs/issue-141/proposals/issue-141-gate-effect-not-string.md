---
status: proposed
files:
  - core/hooks/trailer-gate.sh
  - core/hooks/handbook-trigger-gate.sh
  - core/hooks/lib/gate-lib.sh
  - test/hooks/test_trailer_gate.sh
  - test/hooks/test_handbook_trigger_gate.sh
---

## Request

Issue #141: three gate defects share one root cause — the gates judge the
Bash command STRING instead of the effect it would have. (D1)
`trailer-gate.sh` tokenizes the raw command with `shlex.split()`, which
cannot resolve `$(...)`/heredoc constructs, so it both false-denies a
commit whose real message carries the trailer and passes a commit whose
trailer exists only in unresolved source text (bypass). (D2)
`handbook-trigger-gate.sh` denies `git add <paths> && git commit ...`
unconditionally because PreToolUse blocks the whole call before `git add`
runs, so the gate judges pre-add staged state with a message identical to
a genuine violation. (D3) deny messages name no concrete, openable path,
which drove a live session into repeated `find /` scans and reading a
stale gate copy from another session's scratchpad.

## Constraints

- Skip condition per scout-directive: pure bugfix, no external
  design/product decision open — scouting was skipped (see survey.md).
- Fail-closed posture of both gates must not regress: an unresolved edge
  case must still deny, never silently allow.
- No new runtime dependency; both gates already require `python3` and
  `git` on PATH — stay within that.
- The harness's own `PreToolUse:Bash hook error: [${CLAUDE_PLUGIN_ROOT}/...]`
  wrapper text is outside this repo's control (Claude Code harness
  behavior, not this repo's code) — D3's fix scope is limited to what the
  gate's own `deny()` message body prints.

## Rationale

**D1 — reopened after review (2026-08-07):** the first draft of this
proposal denied every statically-unresolvable `-m` construct outright,
which would have made the issue-280 heredoc commit DENIED — directly
contradicting the acceptance criterion that the same commit be ALLOWED.
PR #144 review caught the contradiction and asked for an explicit choice
between (1) deny-everything-unresolvable, contract updated to say
heredoc commits are no longer available, or (2) judge the resolved
effect so the legitimate heredoc is ALLOWED and the source-text-only
bypass is DENIED. Full sandboxed execution of the whole command (a `git`
shim intercepting the eventual `commit` call) was rejected for the
reason the first draft gave: the command can carry arbitrary side effects
before that point (rm, network calls, etc.), and neutralizing everything
except the final invocation is re-implementing a bash sandbox inside a
security gate.

**Chosen: (2), scoped to just the message argument, not the whole
command.** Extract only the `-m`/`--message` argument's expression text
(not the surrounding command) and, before evaluating it, run it through
an allowlist: the expression must consist solely of `$(...)`/backtick
substitutions and heredocs whose only invoked commands are from a fixed
safe set (`cat`, `printf`, `echo` — no other command name, no
`;`/`&&`/`|`/redirection-to-file inside the expression). An expression
that passes the allowlist is evaluated with `timeout 2s bash -c` in a
subshell with `PATH` restricted to a directory containing only those
three coreutils (no network, no git, no filesystem mutation reachable),
and the resulting resolved string is what gets checked for the
`Subject:` trailer — not the raw source text. An expression that fails
the allowlist (uses any other command, or times out) falls back to the
gate's existing "cannot be verified statically" deny branch, unchanged
from the first draft — fail-closed is preserved for anything the
allowlist can't vouch for.

This resolves both acceptance criteria at once: the issue-280 idiom
(`$(cat <<'EOF' ... EOF)`, pure heredoc text, no side effects) passes the
allowlist, resolves to its real message, and is judged on that — ALLOWED
when the trailer is actually present in the resolved text. The issue-30
shape (trailer sitting only in source text outside what the expression
actually resolves to) is judged on the resolved text too, so a
source-only trailer no longer passes — bypass closed. A message
construct using any command outside the allowlist (e.g. embedding
`$(curl ...)` or `$(git log ...)`) never gets executed by the gate at
all — it falls to the same statically-unresolvable deny as before, so
the gate never runs attacker-influenced commands beyond the three
allowlisted coreutils. This is a narrower, auditable version of the
sandboxed-shim idea the first draft rejected — narrow enough (three
commands, no shell metacharacters, 2s timeout) that its own failure
surface stays smaller than the bug it fixes, unlike whole-command
execution.

**D1 — reopened again after review round 2 (2026-08-07): allowlist
admitted behaviors, not just names.** The scoped allowlist above named
three commands but did not constrain their arguments or where the three
coreutils would live on `PATH` during resolution. Two holes, both
closed here rather than deferred to the build:

1. *`cat` with a file operand is a read primitive, not a heredoc reader.*
   `cat` admitted unconditionally lets `$(cat ~/.gitconfig)` or
   `$(cat /etc/passwd)` pass the allowlist — the gate itself then reads
   that file, and the resolved (file) content flows into the trailer
   check and, on a deny, into the deny message written to the session
   log and event file. That is an arbitrary-file-to-log path opened by
   the gate meant to prevent bypass. **Chosen fix:** the allowlist admits
   `cat` only with **zero operands** (heredoc/pipe stdin only — no
   filename argument of any form, including `-`). `printf` and `echo`
   are likewise argument-shape-checked rather than admitted wholesale:
   their arguments must be a literal format/string plus data (no `-`
   flags that open files, no argument containing `/` since a real
   heredoc payload never needs one to serve as a commit message).
   Considered instead: allow `cat` with operands but restrict it to a
   fixed set of paths. Rejected — the idiom this exists to support
   (`$(cat <<'EOF' ... EOF)`) never needs a file operand at all, so
   admitting file operands only widens the attack surface for zero
   legitimate gain.
2. *A `PATH`-directory allowlist is only as strong as the directory's
   own write permissions.* The gate runs inside the role session's own
   process tree; if the directory holding the three allowlisted
   coreutils sits anywhere the session can write (workspace, `$TMPDIR`,
   a directory the gate creates fresh under either), the session can
   drop its own executable named `cat`/`printf`/`echo` ahead of the real
   ones on that `PATH`, and the allowlist degrades to an allowlist of
   *names* the gate blindly trusts, not of *behaviors*. **Chosen fix:**
   drop the PATH-directory approach entirely. Resolve each of the three
   binaries to its absolute system path once, at gate-script load time,
   via `command -v cat`/`command -v printf`/`command -v echo` restricted
   to a fixed, non-session-writable candidate list (`/bin`, `/usr/bin` —
   the standard coreutils locations on the CI/session base image), and
   invoke those absolute paths directly inside the `timeout 2s bash -c`
   subshell with `PATH` set to empty (`env -i PATH= timeout 2s bash -c
   '...'` with the three resolved absolute paths substituted verbatim
   into the trusted wrapper script, not looked up by bare name at
   resolution time). This is cleaner than assembling and shipping a
   restricted `PATH` directory, as the reviewer suggested, and removes
   the writable-directory hole structurally rather than by convention.
   A dedicated test shadows `cat` on the session's `PATH` (a shell
   script named `cat` placed earlier on `PATH` than the real binary,
   printing a sentinel) and asserts the gate's resolved trailer check
   still reflects the *real* `cat`'s output, not the shadow's — proving
   resolution bypasses session `PATH` rather than trusting it.

**D2 — considered, rejected:** scope the gate to the `git commit` segment
only and skip judging staged state entirely when a `git add` precedes it
in the same compound command (i.e., trust that the add will do its job).
Rejected: that would blind the gate exactly when it matters most —
compound add+commit is the common case, and skipping judgment there
defeats the gate's purpose for the majority of real invocations, not just
the false-positive minority. **Chosen instead:** project the staged set
forward — parse `&&`/`;`/`|`-separated segments for `git add <pathspec>`
calls preceding the `git commit` segment, resolve each pathspec against
the working tree with `git add --dry-run --` (no actual staging side
effect), union the dry-run result with the currently-staged set, and
judge against the union. When a pathspec can't be resolved statically
(e.g. it contains a shell variable), fall back to a distinctly-worded
deny ("staged set cannot be projected past `git add <expr>`; the
add's target depends on shell/variable expansion") instead of reusing the
genuine-violation message — this directly satisfies the issue's "make
the two failure modes distinguishable" requirement.

**D3 — considered, rejected:** have the gate try to compute and print
`${CLAUDE_PLUGIN_ROOT}` itself. Rejected: the gate process has no
reliable way to know the harness's own substitution value at runtime
(it's a harness-side concept, not exported to the hook's environment) —
guessing it risks printing a second, still-wrong path and compounding the
confusion. **Chosen instead:** each gate already resolves its own
absolute path today for `gate-lib.sh` sourcing
(`$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)`); reuse that same
resolution to compute the gate script's own absolute path and append it
to every `deny()` message body (both the bash-level and python-level
`deny()` functions), e.g. `... (gate: /abs/path/to/trailer-gate.sh)`.
This gives the agent a path it can actually `cat`, without depending on
harness internals.

## What will be done

- `trailer-gate.sh`: before `shlex.split`, scan the raw command's
  `-m`/`--message` argument text for `$(`, a backtick, or a `<<`
  here-doc marker. If found, apply the allowlist check described in
  Rationale: only `cat` (zero operands), `printf`, and `echo`
  (argument-shape-checked, no `-`-flag or `/`-containing arguments)
  invocations, no other command name, no `;`/`&&`/`|`/file-redirection
  inside the expression. If the expression passes, resolve the three
  binaries to absolute system paths (`command -v` restricted to
  `/bin`,`/usr/bin`) once at load time, then evaluate the expression via
  `env -i PATH= timeout 2s bash -c` invoking those absolute paths — never
  a restricted-`PATH`-directory shim — and check the *resolved* string
  for the trailer. If it fails the allowlist or the resolution times
  out, route to the existing "cannot be verified statically" deny branch
  (reworded to name the detected construct) instead of calling
  `shlex.split` and trusting its result. Plain quoted literals (including
  ones containing escaped embedded quotes) continue through the existing
  shlex + regex path unchanged.
- `handbook-trigger-gate.sh`: before reading `git diff --cached
  --name-only`, split the command on `&&`/`;`/`|`, find `git add`
  segments that precede the `git commit` segment, and for each resolvable
  pathspec run `git -C <root> add --dry-run --` to compute what it would
  stage; union that projected set with the actually-staged set before
  applying the existing operational-surface/handbook check. Add a
  distinct deny message for the "pathspec not statically resolvable"
  case.
- `gate-lib.sh`: add one small shared helper (e.g. `gate_self_path`) that
  returns the calling gate script's resolved absolute path, used by both
  scripts' `deny()` paths for D3 — only if sharing it turns out cleaner
  than the ~2-line inline resolution already used for `CLAUDE_PLUGIN_ROOT_CORE`
  in each script; otherwise the inline form is kept and this file is
  untouched (decided during the build, not a design decision needing
  approval).
- New test files exercise the issue's four acceptance criteria directly
  by invoking each gate script with a crafted JSON payload on stdin
  against a scratch git repo, asserting exit code and (for D3) that no
  deny message contains an unexpanded `${`.
- `test_trailer_gate.sh` adds two cases for the holes closed above: (a)
  `$(cat ~/.gitconfig)`/`$(cat /etc/passwd)`-shaped `-m` expressions are
  DENIED via the allowlist branch, never executed; (b) with a shell
  script named `cat` placed earlier on the test session's `PATH` than
  the real binary, the gate's resolved trailer check still reflects the
  real `cat`'s output — proving resolution uses the absolute-path lookup
  done at load time, not the session `PATH`.
- Phase-2 record (`docs/issue-141/reports/implementation.md`) adds,
  per on-the-record#298: which commit-message shapes that pass on `main`
  today start being DENIED once this lands (the allowlist is strictly
  narrower than "anything shlex could not previously resolve was denied
  anyway," but any `-m` expression using a command outside
  `cat`/`printf`/`echo`, or `cat` with an operand, that previously
  happened to slip past a shlex quirk, now denies explicitly); and the
  observed wall-clock cost of the `timeout 2s bash -c` resolution path
  on the real issue-280 heredoc idiom (not just the 2s worst case).

## Out of scope

- Any change to the harness's own `[${CLAUDE_PLUGIN_ROOT}/...]` wrapper
  text — that's Claude Code harness behavior, not this repo.
- Rewriting either gate's overall structure or promoting further shared
  logic beyond the one optional `gate_self_path` helper.
- Any other gate in `core/hooks/` not named in the issue (board-gate.sh,
  approval-gate.sh, gh-guard.sh, record-fields-gate.sh) — out of scope
  even if they share superficially similar patterns.
- Resolving message constructs that invoke anything beyond
  `cat`/`printf`/`echo` (e.g. `$(curl ...)`, `$(git log ...)`, nested
  command substitutions calling other tools). Those still deny via
  "cannot be verified statically" — widening the allowlist is a separate
  decision, not implied by this fix.

## How you'll know it worked

- A crafted `git commit -m "$(cat <<'EOF' ... Subject: issue-280 ...
  EOF)"` payload (real message carries the trailer) passes the
  cat/heredoc allowlist, resolves to its real message, and is ALLOWED by
  trailer-gate.sh.
- The issue-30-shaped payload (trailer sits only in source text outside
  what the `-m` expression actually resolves to — e.g. in a shell
  comment or unrelated part of the command, not in what `cat`/heredoc
  emits) is judged on the resolved string, finds no trailer there, and
  is DENIED by trailer-gate.sh with a message distinct from and not
  claiming "lacks the required trailer" when the construct instead fails
  the allowlist.
- A payload whose `-m` expression invokes a command outside the
  `cat`/`printf`/`echo` allowlist is never executed by the gate and is
  DENIED via the "cannot be verified statically" branch.
- `git add docs/handbooks/x.md && git commit -m "..."` payload where the
  handbook update is exactly what the pending add would stage is ALLOWED
  by handbook-trigger-gate.sh.
- `grep -r '\${' <captured deny output>` across both gates' test
  fixtures returns nothing.
- A `-m` expression of the form `$(cat <path>)` (any operand, including
  `~/.gitconfig`, `/etc/passwd`, or `-`) is DENIED by trailer-gate.sh via
  the allowlist branch — the gate never opens the named file.
- With a shadow `cat` placed ahead of the real binary on the test
  session's `PATH`, the gate's resolved trailer check still matches the
  real `cat`'s output, not the shadow's — proving binary resolution does
  not trust session `PATH`.
