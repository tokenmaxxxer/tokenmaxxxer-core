---
code_under_review: core/hooks/trailer-gate.sh, core/hooks/handbook-trigger-gate.sh, test/hooks/test_trailer_gate.sh, test/hooks/test_handbook_trigger_gate.sh
loop_state: phase-2-complete
---

# Implementation record — issue-141

Phase 2. Approved via single-account `APPROVE issue-141/implementation`
issue comment (2026-08-07). Implements
docs/issue-141/proposals/issue-141-gate-effect-not-string.md as it stands
after two review rounds.

## What was done

- **D1** (`core/hooks/trailer-gate.sh`): before shlex, the raw `-m`/
  `--message` argument text is scanned for a quoted value whose entire
  content is a single `$(...)` or backtick expression (a heredoc-aware
  scanner, `_scan_dollar_paren_or_backtick`, treats heredoc bodies as
  opaque so stray parens/quotes inside them don't desync the scan). If
  found, `_check_allowlist` requires the expression's inner command to be
  either bare `cat` with zero operands (heredoc/stdin only — no file
  operand, closing the arbitrary-file-read hole raised in review round 2)
  or a shape-checked `printf`/`echo` (no `-`-flag args, no `/` in any
  arg, no nested substitution/`;`/`&`/`|`). A passing expression is
  resolved by `_evaluate_allowlisted`: `cat` is replaced with its
  load-time-resolved absolute path (`command -v` restricted to `/bin`,
  `/usr/bin` only — never a session-PATH lookup, closing the
  writable-PATH-directory hole from review round 2), and the inner
  command text runs as a `bash -s` script with `PATH=` empty and a 2s
  timeout. The *resolved* string, not the source text, is checked for
  the `Subject:` trailer. Anything that fails the allowlist, the scan, or
  times out falls to the existing "cannot verify statically" deny
  (reworded to name the detected construct) instead of proceeding to
  shlex. Plain literal `-m` values (the common case) are unaffected —
  they still go through the pre-existing shlex + regex path unchanged.
- **D2** (`core/hooks/handbook-trigger-gate.sh`): the raw command is split
  on `&&`/`;`/`|`; every `git add` segment preceding the `git commit`
  segment is tokenized (`shlex.split`), and its pathspec (tokens after
  any `--` separator, or non-`-`-prefixed tokens before one — the
  warrant-hunt fix below) is resolved via `git add --dry-run --` and
  unioned into the judged staged set. A pathspec containing `$`/backtick
  denies with a distinct message ("cannot be projected statically")
  instead of the genuine-violation wording.
- **D3** (both gates): each script resolves its own absolute path at
  startup (`self_path`, same `dirname "${BASH_SOURCE[0]}"` idiom already
  used for `gate-lib.sh` sourcing) and appends `(gate: <path>)` to every
  `deny()` call — bash-level, python-level, and the internal-error/
  fail-closed branches.
- **`gate-lib.sh`**: left untouched. The proposal listed a shared
  `gate_self_path` helper as a candidate only if it proved cleaner than
  the ~2-line inline resolution; the inline form (identical to the
  existing `CLAUDE_PLUGIN_ROOT_CORE` idiom each gate already carries) was
  simpler for two call sites and is what shipped.
- Tests: `test/hooks/test_trailer_gate.sh` (10 cases),
  `test/hooks/test_handbook_trigger_gate.sh` (6 cases), following the
  house `core/hooks/tests/_tmp.sh` + real-subprocess-against-real-payload
  convention used by `run-board-gate-tests.sh` etc. Both scripts pass; the
  full house suite (`core/hooks/tests/run-all.sh`) passes with no
  regressions (94/94 board, 46/46 approval, 54/54 gh-guard, 47/47 prior
  role-gates, plus the two new suites).

## Acceptance criteria — observed output

All commands run as real subprocess invocations of the gate scripts
against real JSON payloads and real scratch git repos (not simulated).
Full transcripts are in `test/hooks/test_trailer_gate.sh` and
`test/hooks/test_handbook_trigger_gate.sh`; representative captures below
(role prefix and full deny text abbreviated with `…`).

1. **issue-280 heredoc commit is ALLOWED.**
   `git commit -m "$(cat <<'EOF' … Subject: issue-141 … EOF)"` (message
   also carries an embedded double quote, `"quoting"`) →
   `EXIT_CODE=0`. Resolution completed in ~65ms observed wall-clock (not
   the 2s worst case) — measured with `time` around the real subprocess
   call.
2. **issue-30-shaped source-text-only trailer is DENIED.** Heredoc body
   has no trailer; a trailing shell comment outside the `-m` value's
   quotes mentions `Subject: issue-141` — the resolved message is judged,
   finds no trailer, denies:
   `refused — trailer-gate: this commit stages issue-141 work but its
   message lacks the required Subject: issue-141 trailer … EXIT_CODE=2`.
3. **Commit message with a double quote + valid trailer is ALLOWED** —
   same as case 1 (the embedded `"quoting"` text is inside the heredoc
   body, which is what breaks shlex pre-fix; post-fix it resolves fine).
4. **`git add X && git commit` succeeds when the handbook requirement is
   met.** `git add docs/handbooks/foo.md && git commit -m "…adds
   requirements.txt…"` with `requirements.txt` already staged and
   `docs/handbooks/foo.md` present-but-unstaged → `EXIT_CODE=0`
   (pre-fix this denied unconditionally, per D2's proposal-stated bug).
5. **No deny message contains an unexpanded `${`.** `grep -qF '${'`
   across five captured deny transcripts (trailer-gate: no-trailer,
   cat-with-file-operand, echo-with-flag; handbook-trigger-gate:
   bare-commit, unresolvable-pathspec) → no match. Every deny instead
   names a concrete path, e.g.
   `(gate: /…/core/hooks/trailer-gate.sh)`.
6. **`cat` with a file operand is refused.**
   `git commit -m "$(cat /etc/hostname)"` →
   `refused — … its -m message is a $(...)/backtick construct that is
   not a plain cat(heredoc)/printf/echo invocation matching the
   allowlist … EXIT_CODE=2`. The file is never opened — the allowlist
   check is a regex/shape match on source text, before any subprocess
   runs.
7. **A `cat` shadowed on the session PATH does not fool the gate.** A
   passthrough shadow `cat` (forwards to `/bin/cat` but logs every
   invocation) placed first on `PATH`; gate invoked with that `PATH`.
   Result: `EXIT_CODE=0` (real trailer honored) and the shadow log shows
   exactly **one** invocation — the gate's own unrelated payload-read
   `cat` call — proving the `-m` resolution step never looked the binary
   up by name on `PATH` at all (it used the absolute path substituted in
   at allowlist-check time, under `PATH=` empty).

## Which commit-message shapes that work on `main` today start being denied

- Any `-m "$(...)"` / backtick construct invoking a command **outside**
  `cat`/`printf`/`echo` (e.g. `$(date)`, `$(git log -1)`, `$(curl …)`) —
  on `main` today these were tokenized by naive `shlex.split`, so the
  outcome was essentially arbitrary (sometimes an accidental deny,
  sometimes an accidental *allow* via source-text coincidence — the D1
  bypass this issue exists to close). Post-fix these uniformly and
  explicitly deny with "cannot be verified statically", naming the
  construct.
- `cat` invoked **with any operand** inside a `-m` substitution (e.g.
  `$(cat somefile)`, `$(cat -)`) — previously shlex-dependent/undefined,
  now explicitly denied via the allowlist branch, and the named file is
  never opened by the gate.
- `printf`/`echo` invoked with a `-`-flag argument (e.g. `echo -e …`) or
  an argument containing `/` inside a `-m` substitution — same as above,
  now explicitly denied rather than shlex-dependent.
- **Nothing that previously, genuinely passed becomes newly denied.**
  Plain literal `-m` messages (with or without an inline trailer,
  including ones with escaped embedded quotes) are unchanged — verified
  by `plain-message-with-trailer` / `plain-message-without-trailer` test
  cases, which exercise the pre-existing shlex path untouched by this
  fix. The one shape that changes from DENY to ALLOW is the issue-280
  idiom itself (pure heredoc text through `cat`) — an intentional fix,
  not a new restriction.
- On the D2 side: `git add <paths> && git commit …` where the add would
  satisfy the handbook obligation moves from unconditional DENY to
  ALLOW — also an intentional fix, not a new restriction. Nothing new
  starts being denied on the handbook-trigger side; the projection is
  strictly additive (it can only add files to the judged set that a real
  commit's `git add` would also add).

## What did not work

- First allowlist draft filtered `git add` tokens with a blanket
  `if not t.startswith("-")`, intending to drop `git add` *option* flags
  (`-v`, `-f`) from the pathspec list. The warrant-hunt below found this
  also silently dropped the `--` end-of-options separator and any
  pathspec that itself starts with `-` (e.g. a file named
  `-setup.sh`, or `-mydir/requirements.txt`), so such a pathspec was
  never passed to `git add --dry-run` and never entered the projected
  staged set — a silent-allow hole on exactly the class of input the
  fix exists to close. Fixed: tokens are now scanned for a literal `--`
  separator; only tokens **before** it that start with `-` are treated
  as options, everything at or after `--` is a pathspec regardless of
  leading `-`. Regression test added
  (`addcommit-dash-named-pathspec-still-denied` in
  `test/hooks/test_handbook_trigger_gate.sh`).

## Rationale for deviations

None — implementation matches the approved proposal's "What will be
done" section (D1/D2/D3, allowlist shape, absolute-path resolution,
test coverage). The dash-pathspec fix above is a bug-fix within D2's
already-approved scope (the `git add --dry-run` projection), not a
deviation from the proposal's design.

## Hunt cadence

- **Before-landing dispatch** (this transition): `warrant-hunter`,
  stance "assume this guard goes silent when its own input is
  malformed — make it go silent", diff-size tier `default` (290 total
  lines changed, cap 180s). Record:
  `docs/reports/2026-08-07-hunt-issue-141-gate-effect-not-string.md`.
  **Result: FINDING** — the dash-pathspec silent-allow hole documented
  above under "What did not work". Fixed and regression-tested before
  this record was finalized (contract's blocking-finding gate: the
  finder's own re-clearance is the finding's authority, not this note;
  this record states the fix and the test that pins it).
- No after-proposal dispatch is recorded in this session (phase-1 PR
  #144 review rounds served that role in substance — two independent
  human review passes already found and closed two allowlist holes
  before phase 2 began).

## Open findings

None open. The one warrant-hunt finding (dash-pathspec silent allow) is
fixed and test-pinned; see "What did not work" and the hunt record.

## Closed checks

- `closed_checks`: acceptance-criteria-1-through-7 — all seven
  acceptance scenarios in the issue and proposal's "How you'll know it
  worked" section, verified as real subprocess runs against real
  payloads (see "Acceptance criteria — observed output" above).
- `closed_checks`: full-house-regression — `core/hooks/tests/run-all.sh`
  passes in full (board/approval/gh-guard/role-gates/stub-check/
  compliance-check + sibling-plugin suites), confirming no regression
  to any other gate or to the pre-existing plain-`-m` trailer path.

## Next steps

None open for this issue. Commit, push, open the delivery PR with
`Closes #141`.

## Resolution path

N/A — no open findings.
