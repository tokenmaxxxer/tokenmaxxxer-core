# Survey — issue-141

Skip condition: pure bugfix (scout-directive skip condition 1). The three
defects are logic errors in existing gate scripts; no product/design
decision is open, so scouting (external exemplar research) is skipped.
This file satisfies survey-order-directive's requirement to survey the
actual write surface before drafting the proposal.

## Write surfaces

- `core/hooks/trailer-gate.sh` (175 lines): PreToolUse gate on `Bash`
  matching `git commit`. Embedded python3 heredoc (lines 42-168) does the
  real work. Bug D1 is at lines 134-165: `shlex.split(command)` on the
  raw, unexpanded shell command string. `shlex` has no notion of `$(...)`
  command substitution or `<<EOF` heredocs — for
  `git commit -m "$(cat <<'EOF' ... Subject: issue-N ... EOF)"` the `-m`
  token's value literally becomes the source text `$(cat <<'EOF'` (up to
  the quote shlex thinks closes it), not the resolved message. Two
  failure modes fall out of the same defect:
  - the resolved message DOES carry a valid trailer, but shlex's token
    happens not to contain it → wrongly denied at :165 with a false
    "lacks the required trailer" claim (should route to the honest
    "cannot be verified statically" branch at :161, which already exists
    for the `-F`/editor case but is never reached for this construct).
  - the resolved message does NOT carry the trailer, but the raw source
    text around the heredoc happens to contain the string
    `Subject: issue-N` → the regex at :164 matches source text and
    wrongly ALLOWS (bypass).
  Both are one root cause: shlex is being asked to resolve shell
  constructs it cannot resolve, and the code proceeds as if it succeeded.

- `core/hooks/handbook-trigger-gate.sh` (136 lines): PreToolUse gate on
  `Bash` matching `git commit`. Bug D2 is structural, not a parsing bug:
  PreToolUse denies the whole tool call before it runs, so for
  `git add <paths> && git commit ...` the `git add` never executes and
  `git diff --cached --name-only` (line 83) reads the PRE-add staged
  set. When the handbook update is exactly the file the pending `git add`
  would stage, the gate incorrectly denies with the same message text
  used for a genuine violation (lines 120-125) — the two cases are
  currently indistinguishable to the calling agent.

- Both scripts source `core/hooks/lib/gate-lib.sh` and are registered in
  `core/hooks/hooks.json` as `${CLAUDE_PLUGIN_ROOT}/hooks/<name>.sh`.
  Bug D3: `${CLAUDE_PLUGIN_ROOT}` is a Claude Code harness-level
  substitution used only in the hook *registration* command string; when
  the harness reports a hook error it echoes that registration string
  verbatim, unexpanded, in the `PreToolUse:Bash hook error: [...]`
  wrapper — that wrapper is harness output, outside this repo's control.
  What IS in this repo's control: the gate's own `deny()` message body
  never names a concrete, openable path — an agent reading only the gate
  message has nothing to `cat`/`grep`. Both `trailer-gate.sh`'s bash-level
  `deny()` (line 29) and its python `deny()` (line 47-49), and
  `handbook-trigger-gate.sh`'s equivalents (line 28, line 52-53), print
  only a role-prefixed sentence with no path.

- `core/hooks/lib/gate-lib.sh` exists and is already sourced by both
  gates; it is a plausible home for a shared "resolve this gate's own
  absolute path" helper so the fix isn't duplicated per gate, but adding
  a helper there is in scope only if it stays a small, generic addition
  — the write set below lists it as a candidate, to be exercised only if
  duplicating a 2-line path resolution in each gate proves worse.

## No test directory currently covers these gates

`find . -iname "*trailer-gate*" -o -iname "*handbook-trigger*"` under any
`test/` tree returns nothing — there is no existing test harness for
these two scripts to extend; new test files are needed (acceptance
criteria in the issue are directly testable as shell/python assertions
against the gates' stdin/stdout/exit-code contract).

## Prior decisions

`docs/decisions/` was not searched for gate-specific ADRs beyond what's
already documented inline in each gate's own header comment (both carry
substantial rationale in comments, e.g. trailer-gate.sh's "Promoted to
core canon (issue-66)" note, handbook-trigger-gate.sh's same). No
existing ADR contradicts the fix direction below.
