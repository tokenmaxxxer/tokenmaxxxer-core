# Gate-house standard: the shared gate library (issue-72)

A 2026-08-01 audit of the 43 downstream rulebook repos' merged gates found
six repo-wide structural defect classes, not isolated per-repo bugs (issue
#72's background). `core/hooks/lib/gate-lib.sh` (+ `core/hooks/lib/gate-lib.py`)
is the canon fix every rulebook gate should source instead of re-deriving
its own version of each shape. This handbook is what a rulebook's own A+
remediation issue links to.

## What `gate-lib.sh` / `gate-lib.py` provide

Sourced from a gate script (bash) and loaded via `importlib` from a gate's
own Python payload — see the usage comment at the top of each file for the
exact lines. **The bash source line is mandatory-guarded**
(`. "$path" || { echo "<gate-name>.sh: cannot source gate-lib.sh" >&2; exit 2; }`,
issue-75-confirmed defect: an unguarded source that fails when core is
unreachable defines no `gate_*` function, and the resulting "command not
found" (127) reads as the kill switch being off to every
`gate_kill_switch_active ... || { exit 0; }` call site — silently allowing
everything). `compliance-check.sh` flags an unguarded source; see below.
Functions, one per defect class from the issue's background:

- `gate_trap_fail_closed` — the one canonical fail-closed EXIT trap.
- `gate_kill_switch_active <value>` — **fixed** convention: only a
  recognized on-spelling (`1`/`true`/`yes`/`on`) disables; empty, a
  recognized off-spelling, or any unrecognized value all stay active.
  (Core's own canon had this backwards before issue-72: any unrecognized
  value silently disabled the gate — see "the two bugs this issue fixed"
  below.)
- `gate_deny <name> <msg>` / `gate_allow` — stderr-only deny (exit 2) /
  allow (exit 0).
- `gate_parse_json_or_deny(raw, deny)` (Python) — malformed-JSON deny,
  including empty payload and non-object top level.
- `gate_normalize_path(root, path)` (Python) — absolute/relative/
  `./`-prefixed path normalization to a root-relative tail, or `None` when
  the path resolves outside root.
- `gate_reconstruct_write(tool, tool_input, current_content)` (Python) —
  full `Write`/`Edit`/`MultiEdit`/`NotebookEdit` reconstruction, honoring
  each edit's own `replace_all` flag independently (MultiEdit) and
  returning the edited cell source for `NotebookEdit`.
- `gate_bash_write_targets <command>` (bash) / `gate_bash_write_targets(command)`
  (Python, issue-75 parity fix) — token-scan a `Bash` `tool_input.command`
  string for path-shaped candidates, the technique `approval-gate.sh`/
  `board-gate.sh` already used, now reusable by any gate that currently
  only matches the `Write`/`Edit`-family tools. Both languages use the
  same character class and return the same token set for the same
  command string (sh prints one token per line; py returns a list — the
  natural per-language shape for identical data).
- `gate_budget_exceeded <started_epoch> <cap_seconds> [<now_epoch>]`
  (bash, issue-63) — returns true (exit 0) when `now - started > cap`;
  `now_epoch` defaults to `date +%s` when omitted, so tests can pass a
  fixed clock. Malformed numeric input fails open (returns 1,
  not-exceeded), matching this file's convention for untrusted external
  input. A caller checking its **own** bookkeeping (e.g. a lock file it
  wrote itself) should treat a malformed field as corrupt state and fail
  closed instead of relying on this default — see `warrant/hooks/
  hunt-guard.sh`'s budget-check block, which does exactly that ahead of
  calling this function.
- `gate_dequote(text)` / `gate_outside_quotes(text, pattern)` (Python,
  issue-94) — blank every quoted span in `text` to a space, and match a
  pattern only outside quotes. The shared primitive that replaces each
  gate's own inline "quote-span-first regex + finditer-skip-quote-matches"
  trick, so a pattern like a `gh pr merge` phrase or a redirect character
  sitting only inside a quoted argument (e.g. a `grep` search pattern)
  never falsely fires.
- `TRANSPARENT` / `gate_head_of(segment)` (Python, issue-98) — relocated
  from `board-gate.sh`'s own `_head_of`: resolves a pipeline segment
  through pass-through wrappers (`xargs`, `env`, `time`, `nice`,
  `command`, `builtin`, plus `timeout`/`nohup` added in this move) to the
  command it actually runs. `timeout`'s own bare positional DURATION
  argument (`timeout 30 cmd`, no flag) is skipped one hop at a time
  rather than filtered from the whole remainder in one pass, so a flag
  belonging to the REAL command (not the wrapper) is never mistaken for
  the wrapper's own and swept away.
- `WRAPPER_HEADS` / `gate_wrapper_head_before(cmdline, span_start)`
  (Python, issue-98) — `gate_dequote` blanks a quoted span to inert data,
  but `bash -c`/`sh -c`/`eval`/`python3 -c` (and the same family through
  `timeout`/`env`/`xargs`/`nohup`) **execute** that data. Given the start
  position of a quoted span, walks back to the previous top-level
  separator outside any quote, then scans that local text's words
  DIRECTLY for the rightmost `WRAPPER_HEADS` word (`bash`/`sh`/`dash`/
  `ksh`/`zsh`/`eval`/`python`/`python3`/`python2`/`perl`) — deliberately
  NOT via `gate_head_of`'s TRANSPARENT hop-by-hop walk, which assumes
  every `-`-prefixed token is a self-contained flag and so misresolves a
  wrapper reached through a TRANSPARENT prefix whose OWN flag takes a
  separate value token (`nice -n 10 bash -c "..."`, `timeout -s KILL 30
  bash -c "..."`; found by a hunt pass, `docs/issue-98/reports/
  implementation.md`). Returns the found head only when its quoted
  argument is unambiguously code — `eval` always executes with no flag
  needed; `perl` needs an `-e`-shaped flag (its real code-argument flag;
  `-c` means "check syntax, don't run" for perl); any other wrapper head
  needs a `-c`-shaped flag (`-c`, or a combined short-flag token
  containing `c`, e.g. `-lc`) between the head and the quote. A gate that
  needs to know "is this quoted text about to run as a command" (not
  merely "is this quoted text real data") calls this per matched quoted
  span; see `gh-guard.sh`'s three dequoted verb rules for the pattern.

## The two bugs this issue fixed in core's own canon

Not just future-proofing for the 43 rulebooks — core's own seven gates had
these bugs too (issue-72 survey sections 2 and 6), fixed as part of this
migration:

1. **Kill-switch default-on-unrecognized-value.** Every kill switch in this
   repo (`CORE_OFF`, `TRAILER_GATE_OFF`, `RECORD_FIELDS_GATE_OFF`,
   `HANDBOOK_TRIGGER_GATE_OFF`) used
   `case ... in ""|0|false|no|off) ;; *) exit 0 ;; esac` — any value other
   than a recognized off-spelling, including a typo, disabled the gate.
   All seven `core/hooks/*.sh` gates now call `gate_kill_switch_active`
   instead.
2. **`replace_all` ignored.** `record-fields-gate.sh` always did
   `current.replace(old, new, 1)` regardless of the real `Edit`/`MultiEdit`
   call's `replace_all` field, and never reconstructed `NotebookEdit` at
   all. It now calls `gate_lib.gate_reconstruct_write`, which honors
   `replace_all` per-edit and reconstructs `NotebookEdit`'s cell source.

## Standard test harness

`core/hooks/tests/run-gate-lib-tests.sh` makes seven case groups mandatory —
a run that skips any of them fails the harness itself:

1. `Edit` with `replace_all: true` against a multiply-occurring
   `old_string`.
2. `MultiEdit` with a mix of `replace_all: true`/`false` edits in one call.
3. Malformed JSON (truncated, non-object, empty).
4. Kill-switch set to an unrecognized value — must assert the gate stays
   **active**.
5. Absolute `file_path` matching the same scope a relative-path fixture
   already matches, plus a `./`-prefixed variant.
6. A `Bash`-tool file write reaching the same target a `Write`-tool call
   would hit, plus sh/py `gate_bash_write_targets` parity.
7. `gate-lib.sh` sourced with `CLAUDE_PLUGIN_ROOT_CORE` pointed at a
   nonexistent path and no valid relative fallback — must assert **deny**
   (exit 2), not the pre-issue-75 silent-allow bug.

Additional non-mandatory groups accumulate alongside these seven as
`gate-lib.sh` grows — e.g. `gate_budget_exceeded`'s red/green pair
(issue-63) — without changing the seven-group floor above.

Run it the same way `run-role-gates-tests.sh` is run today, from
`core/hooks/tests/`: `bash run-gate-lib-tests.sh`.

## Compliance detector

`core/hooks/tests/compliance-check.sh [hooks-dir]`, modeled on
`stub-check.sh`'s pattern: flags a gate that reads a `*_OFF` kill-switch
env var without calling `gate_kill_switch_active` (hand-rolled, likely
fail-open), a gate that reconstructs `Edit`/`MultiEdit` content via its
own `.replace(old, new[, 1])` call instead of `gate_reconstruct_write`
(likely `replace_all`-ignoring), and a gate that sources `gate-lib.sh`
with no `||` guard on the same line (issue-75: fail-open on missing core).
Invoked the same way `stub-check.sh` is, against a rulebook's own hooks
directory:

```
"${CORE_PLUGIN_ROOT:-$CLAUDE_PLUGIN_ROOT/../core}/hooks/tests/compliance-check.sh" "$(dirname "$0")/.."
```

`gate-lib.sh`, `gate-lib.py`, and `compliance-check.sh` are all listed in
`core/hooks/tests/canon-manifest.txt`, so `stub-check.sh` itself catches a
rulebook vendoring a copy of any of them, per
[`canon-scripts.md`](canon-scripts.md)'s reference-not-copy rule.

**Scan scope (issue-78): by hooks.json registration, not by filename.**
The scan set used to be every file under `$dir` matching `*-gate.sh` —
a filename rule that missed any PreToolUse-wired script named something
else (confirmed: `hunt-guard.sh` and `gh-guard.sh` are both wired into
their own `hooks.json`'s `PreToolUse` array but neither matches
`*-gate.sh`, so both silently skipped every check above). The scan set is
now resolved by reading every `hooks.json` under `$dir`, extracting each
`PreToolUse[].hooks[].command` entry's script path, and resolving it
relative to that `hooks.json`'s own directory (`hooks.json` lives at
`<plugin>/hooks/hooks.json`; commands are written as
`${CLAUDE_PLUGIN_ROOT}/hooks/<name>.sh`, i.e. relative to `<plugin>`, one
level above `hooks.json` itself) — matched as a literal string line, the
same grep-based approach the per-file checks above already use rather
than pulling in a JSON parser dependency. A script present on disk but not
wired into any `hooks.json`'s `PreToolUse` array is correctly excluded:
compliance-check judges what actually fires, not what merely exists.

## Canon combination forms (issue-78)

`directive.sh`'s structural check in `stub-check.sh` used to hardcode
exactly one permitted shape: a single `core_role_directive` call, with
every other non-blank/non-comment/non-assignment line treated as regrown
boilerplate. That broke sales-rulebook's already-approved (issue-10)
directive-fragment combination shape — a `FRAGMENTS=(...)` array plus a
`for frag in "${FRAGMENTS[@]}"; do ... core_role_directive "$frag"; done`
loop — even though the shape itself was approved elsewhere; the failure
was a canon-format gap in `stub-check.sh`, not a rulebook defect.

`core/hooks/tests/canon-forms.txt` is a new manifest, one registered
`directive.sh` combination shape per group of `name:pattern-description`
lines, in the same plain-line convention `canon-manifest.txt` already
uses. `stub-check.sh` classifies each non-blank/non-comment/
non-assignment line of a `directive.sh` against the union of every
pattern registered in this manifest (in addition to the built-in
source-line/`core_role_directive`/assignment checks); a line matching any
registered pattern is not "regrown boilerplate". A `directive.sh` matching
no registered shape at all still fails, unchanged. Missing manifest falls
back to the single-call-only shape (no extra patterns permitted), the
same missing-manifest fallback pattern `CANON_GATES` already uses.

Adding a newly-approved combination shape in the future is a manifest
line addition to `canon-forms.txt`, not a new hardcoded regex block in
`stub-check.sh` — the same "config-driven registry over one-hardcoded-
case-per-shape" shape `CANON_GATES` was already extracted from
`canon-manifest.txt` to establish (issue-69).

**Body-row coverage (issue-83):** the original entries above only cover
the fragment-loop's header (`FRAGMENTS=(...)` / `for ... in ...`) and
footer (`done`). sales-rulebook's real `directive.sh` (not the toy
fixture the original suite used) spreads its `for ... in` argument list
across backslash-continued quoted-path lines, puts `do` on its own line,
and sources each fragment with a test-and-source body row
(`[ -f "$frag" ] && . "$frag" 2>/dev/null`) — three physical-line shapes
none of the header/footer patterns matched, so the real approved loop
still failed `stub-check.sh`. Three more `fragment-loop:` pattern lines
in `canon-forms.txt` cover them, same registry mechanism, no new
`stub-check.sh` logic.

**Alternative considered and deferred:** defining the fragment-loop
combination as a separate sourced *file* (splitting it out of
`directive.sh` entirely) instead of teaching `stub-check.sh` to recognize
it inline. This sidesteps `stub-check.sh`'s per-line classification
entirely, but it requires every already-migrated rulebook (43 repos,
issue-66/69/72/75 lineage) to restructure `directive.sh` again on a new
physical-layout rule — a second migration wave stacked on the one just
finished. Manifest-registration fixes the same problem by relaxing
`stub-check.sh`'s classifier, with zero rulebook-side restructuring.
Recorded here so a future issue can revisit the split-file option if a
combination shape emerges that manifest-registration truly cannot
express.

## Per-repo migration checklist

For each of the 43 rulebook repos' A+ remediation issue:

1. Run `compliance-check.sh` against the rulebook's current gates and
   record the violation list.
2. Migrate each flagged gate to source `gate-lib.sh` **with the mandatory
   `||` guard** (bash) and load `gate-lib.py` (Python payload), replacing
   its own hand-rolled kill switch / path-normalize / reconstruct logic
   with the equivalent `gate_*` call.
3. Re-run the rulebook's own gate tests, plus a copy of the seven-case
   `run-gate-lib-tests.sh` suite adapted to that rulebook's gates.
4. Re-run `compliance-check.sh` clean.
5. File the rulebook's own A+ remediation issue referencing this
   handbook, citing the now-clean `compliance-check.sh` output as
   evidence.

This issue (#72) is the prerequisite standard; no retroactive fix to any
of the 43 rulebooks' already-merged gates happens in this repo — each
rulebook's own A+ issue does that work, following the checklist above.

## Transition note (issue-75, for the final 43-rulebook remediation batch)

The 2026-08-01 43-rulebook A+ re-audit found two core-canon defects in this
standard itself, fixed in issue-75:

1. **Unguarded source is fail-open.** The original usage comment showed a
   bare `. "$path"` with no `||` guard. A rulebook that copied that
   example verbatim silently disables every gate using it when core is
   unreachable (the exact mechanism above). Every rulebook that already
   migrated per this handbook before issue-75 should re-pull the guarded
   source line from the current usage comment and re-check with
   `compliance-check.sh`, which now flags the unguarded form.
2. **`gate_bash_write_targets` was sh-only.** Any rulebook gate whose
   Python payload called `gate_lib.gate_bash_write_targets` hit an
   `AttributeError` on every `Bash` tool call (confirmed in
   pr-communications: fail-closed on every command, not just writes).
   `gate-lib.py` now has the function, sh/py parity-tested. Rulebooks that
   worked around the missing function (e.g. skipped Bash-write coverage
   entirely) should switch to calling it directly.

Both fixes are additive — no public function's existing behavior changed,
per this issue's own constraint — so re-pulling is a drop-in source-line
and call-site update, not a rewrite.

## Canon sweep of core's own remaining plugins + two new compliance checks (issue-142)

A 2026-08-07 audit found the fail-open kill-switch idiom (the same bug
class fixed in "The two bugs this issue fixed in core's own canon" above)
still live in core's own `warrant` and `terse` plugins —
`warrant/hooks/{scope-gate,hunt-guard,state,hunt-state,directive}.sh` and
`terse/hooks/terse.sh` (plus `scout/hooks/directive.sh`, found by the same
repo-wide grep though not in the issue's own enumerated list) had never
been migrated off `case ... in ""|0|false|no|off) ;; *) exit 0 ;; esac`.
All now source `gate-lib.sh` guarded and call `gate_kill_switch_active`,
same as core's seven `core/hooks/*.sh` gates already did.

`compliance-check.sh` gained two more checks, alongside the kill-switch/
`replace_all`/unguarded-source checks above:

- **C2 — runtime `mktemp` in a gate's own request-time path.** A gate that
  calls `mktemp` outside a test harness writes scratch state to disk on
  every invocation; under a sandbox whose platform tmp dir is unwritable,
  the gate false-DENIES every call regardless of content (the
  `erm-order-gate.sh` class from issue-142's survey). Flagged with
  `grep -qE '(^|[^A-Za-z_#])mktemp\b'`; the canonical fix is passing the
  payload to `python3` in-memory (heredoc/stdin), the pattern
  `scope-gate.sh`/`hunt-guard.sh` already use.
- **C3 — a Write/Edit-family gate that never mentions Bash at all.** A gate
  that only recognizes `Write`/`Edit`/`MultiEdit`/`NotebookEdit` in
  `tool_name` and has no `gate_bash_write_targets` coverage is bypassable
  via the same target written through `Bash` (`echo`/redirect, `tee`,
  `sed -i`). Flagged when the file matches
  `"(Write|Edit|MultiEdit|NotebookEdit)"` but neither calls
  `gate_bash_write_targets` nor mentions `bash` (case-insensitive) anywhere
  — a gate that deliberately punts Bash writes elsewhere and says so in a
  comment is treated as a considered decision, not a gap, and stays clean.

Also closed a scanning gap the survey found: a hooks directory with no
`hooks.json` at all (a bare tree, or a fixture-only tree) used to read as
"registered and found empty" and exit 0 with nothing scanned. When no
`hooks.json` exists AND the registration-based scan comes back empty, the
scan now falls back to every `*.sh` file directly under the given
directory (non-recursive — this is the "nothing to read a registration
from" case, not a license to walk an arbitrary tree).

**These two new checks are detection only, not a CI gate.**
`compliance-check.sh` is a standalone script a repo's own CI or a human
invokes; it does not run automatically on every write anywhere, in this
repo or any other. It cannot turn an existing repo's checks red by itself
landing here — that requires the repo to separately pick up this updated
script AND already have it wired into a build-failing CI step. None of
the 43 rulebook repos meet both conditions today (see the per-repo
migration checklist above, still open per issue-142's own scope line);
wiring `compliance-check.sh` into each rulebook's own CI is future work,
not done by this sweep.
