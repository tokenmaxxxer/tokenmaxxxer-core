---
issue: 361
role: secure-coding-input-validation-injection-defense-a072264b
author: secure-coding-input-validation-injection-defense-a072264b
skills: secure-coding-input-validation-injection-defense (skill-repository(c05de12))
verifies_subject: false  # flip to true only if this record is an independent verification of this subject's own deliverable -- see docs/handbooks/observer-verification.md
code_under_review: `core/hooks/board-gate.sh`
loop_state: landed
type: fix
breaking: false
verdict: delivered
upstream:
  - path: core/hooks/board-gate.sh
    sha: same-commit
  - path: core/hooks/tests/run-board-gate-tests.sh
    sha: same-commit
  - path: docs/handbooks/board-gate-tests.md
    sha: same-commit
---

# issue-361 — secure-coding-input-validation-injection-defense-a072264b record

## What was done

Closed the `*docs*` fast-path substring bypass in `core/hooks/board-gate.sh`
at both layers it existed.

**Shell layer** — before this change, `core/hooks/board-gate.sh` opened with:

```sh
case "$payload" in
  *'\u'*) ;;
  *docs*) ;;
  *) trap - EXIT; exit 0 ;;
esac
```

checked: `git show origin/main:core/hooks/board-gate.sh | sed -n '67,71p'` —
result: matches the block above verbatim. This exits 0 before python3
ever starts whenever the literal substring `docs` is absent from the raw
payload text. Added a second, independent raw-text scan —
`UNANALYZABLE_HEAD_RE`/`UNANALYZABLE_FLAG_RE`/`UNANALYZABLE_WRITE_HEAD_RE`
plus a heredoc/`$IFS` substring check — that mirrors the exact shape
vocabulary the python judge already treats as unanalyzable
(`INTERPRETER_HEADS` + `INLINE_FLAG_WORDS`, `WRITE_UNSAFE_HEADS`,
heredoc, `$IFS`/`${IFS` fusion). When this scan matches, the fast path no
longer exits early even if `docs` is absent — checked:
`git diff origin/main -- core/hooks/board-gate.sh` — result: the case
statement's `*)` branch is now `[ "$unanalyzable_shape" = 1 ] || { trap -
EXIT; exit 0; }` instead of an unconditional exit.

**Python layer** (same file, the embedded `CORE_BOARD_GATE` program,
`elif tool == "Bash":` branch): removed the redundant `if DOCS in
cmdline:` gate that wrapped the entire segment-scan/candidate-build/
unanalyzable-shape check — checked: `git diff origin/main -- core/hooks/
board-gate.sh` — result: the `if DOCS in cmdline:` line is deleted and
its body de-indented one level, now unconditional. This was an
undocumented second copy of the exact same literal-substring bet the
shell layer makes — so even a Bash command that reached python3 without
a literal `docs` substring still silently contributed nothing to
`candidates`/`unanalyzable`, and `if not hits: allow()` further down
waved it through. The scan now always runs for `tool == "Bash"`; this is
pure-Python string/regex work, not a subprocess, so the python3-startup
cost the pre-check exists to dodge was already paid to reach that line.

Added 4 new cases to `core/hooks/tests/run-board-gate-tests.sh`:
`chr-assembled-path-no-docs-substring` and
`unanalyzable-shape-no-docs-substring` (deny — pins the close),
`ordinary-command-still-fast-path` and
`interpreter-head-without-flag-fast-path` (allow — pins the preserved
fast path). checked: `env -u CLAUDE_PLUGIN_ROOT_CORE bash
core/hooks/tests/run-board-gate-tests.sh` — result: `147 passed, 2
failed` (the 2 failures are `feasibility-spikes`/`ops-postmortems`,
identical to the pre-existing failing-name set on `origin/main` —
checked: same command run against a fresh `git worktree add` of
`origin/main` — result: `143 passed, 2 failed`, same two names). Also
ran `env -u CLAUDE_PLUGIN_ROOT_CORE bash core/hooks/tests/run-scope-gate-
tests.sh` (result: `46 passed, 0 failed`, unchanged from `origin/main`)
and `env -u CLAUDE_PLUGIN_ROOT_CORE python3 -m pytest -q` (result: `3
failed, 79 passed`, identical failing-name set —
`test_proposal_shape_gate_refuses_missing_sections`,
`test_survey_order_gate_refuses_proposal_without_survey_or_skip`,
`test_A5_trailer_gate_quote_split_commit_is_detected` — as the same
command run against `origin/main`). Documented the fix, its rationale,
and the measured cost in `docs/handbooks/board-gate-tests.md`, following
this file's existing per-issue convention.

## Why

Issue #361: the shell-level `*docs*` fast path (and its python-layer
twin) decides, from raw command text alone, whether a Bash call can
possibly touch the board — but a write target built at *interpreter*
runtime (`python3 -c "...chr()..."`) never appears as that literal
substring in the *Bash* command text even though the target really is
under `docs/`. This let issue-225's own unanalyzable-write-shape deny be
silently skipped for exactly the class of command it exists to catch —
disclosed live by PR #360's delivery of issue-233 (out of scope there,
not a defect in that PR).

The issue's own acceptance explicitly forbade two easy-but-wrong fixes:
deleting the pre-check outright (measured cost of full analysis on every
Bash call: ~30ms/call — see Acceptance evidence below — real, not
negligible, on a hook that runs on every tool call), and widening the
substring list with more path names
(`docs`, `reports`, …) — "a closed set of names deciding a security
question... defeated by the same runtime-assembly the current check is
defeated by." Both are true of a *target path* scan. They are not true
of a *shape* scan: the interpreter head and its `-c`/`-e` flag have to be
spelled literally in the command text for the shell to actually invoke
them (unlike a target path, which a script can compute and never write
down), so a raw-text scan for that already-existing, already-reasoned-
about closed set (`INTERPRETER_HEADS`/`INLINE_FLAG_WORDS`/
`WRITE_UNSAFE_HEADS`) is a sound, deliberately over-inclusive proxy — a
false positive there costs one extra python3 call, never a missed
analysis. This is the approach the mounted
`secure-coding-input-validation-injection-defense` skill's rule 1
(allowlist a known-finite structure rather than reaching for a denylist)
and rule 9 (remove a duplicated validation layer rather than
maintaining two independently-drifting copies) both point at: the
existing `docs`-substring scan stays exactly as narrow as it was: the
*shape* scan is a second, independent control at the same trust
boundary, not a widening of the first, and the python-layer duplicate
of the first was removed rather than patched to match.

Alternative considered and rejected: forcing full python analysis for
every `Bash` tool call unconditionally (simplest possible fix, and the
one the issue's own "if the saving turns out to be negligible... the
simpler fix becomes available" clause would license). Rejected because
the saving is NOT negligible (see Acceptance evidence below) — this hook
runs on every Bash tool call in every role session, so unconditionally
paying python3-startup on each one would be a real, session-wide latency
regression the issue's own "must not" clause (and the standing
no-overhead-increase invariant) forbid introducing without measuring it.

## Acceptance evidence

Three checks, each executed live at the real `board-gate.sh` subprocess
level (fixture: `git init`, `docs/specs/approvers.md`, branch
`issue-3/qa`, `CLAUDE_SKILL=qa`), matching the issue's three acceptance
bullets:

1. **The `chr()`-assembled-path reproduction, before vs. after.** Command
   (adapted from PR #360's own reproduction — see Upstream basis for the
   one deliberate change): `python3 -c "import pathlib;pathlib.Path(bytes([100,111,99,115,47,105,115,115,117,101,45,51,47,114,101,112,111,114,116,115,47,112,119,110,101,100,46,109,100]).decode()).write_text(...)"`
   — decodes at Python runtime only to `docs/issue-3/reports/pwned.md`,
   role `qa` does not own. checked: this command run through
   `core/hooks/board-gate.sh` at `origin/main` (via `git worktree add`)
   — result: exit 0 (ALLOW), and the identical command executed for real
   via `bash -c` in the same fixture directory actually created the file
   (`REAL WRITE OCCURRED: bypass`). checked: the same command run through
   this branch's `core/hooks/board-gate.sh` — result: exit 2 (DENY),
   stderr `board-gate: a Bash call carries an un-analyzable write-capable
   shape ... issue-225 — the on-the-record PR #1627 bypass`. Same
   fixture, same command, only the gate binary differs. Pinned as
   `chr-assembled-path-no-docs-substring` in `run-board-gate-tests.sh`.
2. **Ordinary non-board commands still short-circuit.** checked: for
   each of `git status`, `ls -la`, `grep -rn foo src/`, `npm test`,
   `python3 -m pytest -q`, `cat package.json`, `git diff --stat`, `echo
   hello world`, `find . -name star.py`, `curl -s https://example.com`
   — traced this branch's `core/hooks/board-gate.sh` with `bash -x` and
   grepped the trace for the `python3 -c "$CORE_BOARD_GATE"` invocation
   line — result: absent for all 10 (fast-path exit taken, python3 never
   started), including `python3 -m pytest -q` (interpreter head present,
   no `-c`/`-e` flag word — the case this fix must not regress). Pinned
   as `ordinary-command-still-fast-path` and
   `interpreter-head-without-flag-fast-path` in `run-board-gate-tests.sh`.
3. **Per-command overhead, stated as a number.** Interleaved single-call
   timing (`date +%s%N` around each subprocess call, alternating
   before/after so neither run gets a cold-cache advantage, `git status`
   payload, fast-path-eligible on both) — derived: three trials of N=200,
   200, 300 alternating calls to `origin/main`'s `board-gate.sh` vs. this
   branch's — result: before avg 16.472ms / 14.214ms / 22.738ms per
   call, after avg 17.254ms / 14.954ms / 23.624ms per call — a consistent
   **+0.7ms to +0.9ms per ordinary Bash call** (~4-6% relative) added by
   the new shape scan. Compared against the cost of the rejected
   alternative (deleting the pre-check, forcing full analysis
   unconditionally): derived: 50 non-interleaved calls each of a
   fast-path-eligible payload vs. a `docs`-write payload (which already
   forces full python analysis on both `origin/main` and this branch,
   unchanged) through `origin/main`'s gate — result: fast path 1.058s/50
   = 21.2ms/call vs. full analysis 2.587s/50 = 51.7ms/call, a **~30ms/call**
   difference. The shape scan's added cost (~0.7-0.9ms) is under 3% of
   what deleting the pre-check would have cost (~30ms) — the fast path's
   savings are preserved, not eliminated. The full-analysis (`docs`-write)
   path itself shows no regression: derived: 150 interleaved calls of a
   `docs`-write payload — result: before avg 56.548ms/call, after avg
   54.932ms/call (removing the redundant `if DOCS in cmdline:` gate cost
   nothing measurable).

## What did not work

None — no reverted attempt, no alternate branch abandoned mid-way. The
two-layer design (shell shape-scan + python duplicate-gate removal) was
the first approach tried and is what shipped.

## Upstream basis

Issue #361 body (verbatim acceptance criteria, `gh issue view 361`) and
PR #360's own record of the `chr()`-assembled-path reproduction. That
record is not present on `origin/main` or this branch — PR #360 was
closed/superseded by #363→#367→#372 (checked: `gh pr view 360 --json
state,mergedAt` — result: `state: CLOSED, mergedAt: null`) — so its
report file is deliberately not cited here as a backtick working-tree
path (it exists only on the closed PR's own branch, not this one); it
was instead fetched live via `git fetch origin issue-233/secure-coding-
input-validation-injection-defense+adversarial-review-dea32ebc` and read
with `git show FETCH_HEAD:<that branch's own hunt-record path under
docs/issue-233/reports/...>` to obtain the reproduction shape. The
reproduction's chr()-list target path and role/branch fixture were
reused here, adapted to a plain `-c` flag rather than `$'-c'`
ANSI-C-quoted — the ANSI-C-quote tokenizer gap is issue #233's own
still-open, separately-tracked defect (checked: `gh pr list --search
233 --state open` — result: PR #367/#372 both open, #372 titled
"close interpreter-head-via-single-token-expansion generically"), and
mixing it into this reproduction would have made this fix's result
depend on an unrelated open bug's status.

## Open findings

None.

## Next steps

None — `loop_state: landed`. This record's code changes are committed
in this same PR; no follow-on work is implied by the acceptance
criteria. issue-233's own ANSI-C-quote gap remains open and tracked
separately (PR #367/#372), unaffected by this fix (see Upstream basis).

skill-verdict: secure-coding-input-validation-injection-defense —
applied: invoked; loaded the skill's allowlist/denylist/duplicate-layer
rules and used rule 1 (allowlist a known-finite shape rather than a
denylist) and rule 9 (remove a duplicated validation layer rather than
maintaining two copies) to justify both the shell-layer shape scan's
design and the removal of the redundant python-layer `if DOCS in
cmdline:` gate — see Why above.
other mounted skills: not triggered — work-in-english (this record and
all commit/PR text are already English) and hypothesis-testing (no
go/kill/pivot decision was open here) were reviewed and judged
not-applicable to this bugfix task.
