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

**D1 — considered, rejected:** actually executing the given command
inside a sandboxed `git` shim to observe the real resulting message, then
reading it back. Rejected: the command can contain arbitrary side
effects beyond the commit (rm, network calls, etc.); safely neutralizing
everything except the final `git commit` invocation while still letting
bash resolve `$(...)`/heredocs correctly is effectively re-implementing a
bash sandbox inside a security gate — the failure surface of the fix
would exceed the failure surface of the bug. **Chosen instead:** detect
when the `-m`/`--message` argument contains an unresolved shell construct
(`$(`, backtick, or a `<<` heredoc marker) that `shlex` cannot evaluate,
and in that case take the gate's own pre-existing "cannot be verified
statically" deny branch (currently reachable only via `-F`/editor) rather
than proceeding to assert presence or absence from a string shlex
half-parsed. This closes both the false-deny (issue-280 case) and the
bypass (issue-30 case) with the same branch, and matches the gate's own
documented fail-closed philosophy ("a commit whose message cannot be
read statically... is DENIED") — it was already the right branch, just
unreachable for this construct.

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
  here-doc marker; if found, route directly to the existing "cannot be
  verified statically" deny branch (reworded to name the detected
  construct) instead of calling `shlex.split` and trusting its result.
  Plain quoted literals (including ones containing escaped embedded
  quotes) continue through the existing shlex + regex path unchanged.
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

## Out of scope

- Any change to the harness's own `[${CLAUDE_PLUGIN_ROOT}/...]` wrapper
  text — that's Claude Code harness behavior, not this repo.
- Rewriting either gate's overall structure or promoting further shared
  logic beyond the one optional `gate_self_path` helper.
- Any other gate in `core/hooks/` not named in the issue (board-gate.sh,
  approval-gate.sh, gh-guard.sh, record-fields-gate.sh) — out of scope
  even if they share superficially similar patterns.

## How you'll know it worked

- A crafted `git commit -m "$(cat <<'EOF' ... Subject: issue-280 ...
  EOF)"` payload (real message carries the trailer) is ALLOWED by
  trailer-gate.sh.
- The issue-30-shaped payload (trailer only in unresolved source text,
  not in the actual would-be message) is DENIED by trailer-gate.sh, with
  a message distinct from and not claiming "lacks the required trailer".
- `git add docs/handbooks/x.md && git commit -m "..."` payload where the
  handbook update is exactly what the pending add would stage is ALLOWED
  by handbook-trigger-gate.sh.
- `grep -r '\${' <captured deny output>` across both gates' test
  fixtures returns nothing.
