---
subject: issue-142
code_under_review:
  - warrant/hooks/scope-gate.sh
  - warrant/hooks/hunt-guard.sh
  - warrant/hooks/state.sh
  - warrant/hooks/hunt-state.sh
  - warrant/hooks/directive.sh
  - terse/hooks/terse.sh
  - scout/hooks/directive.sh
  - core/hooks/tests/run-gate-lib-tests.sh
  - core/hooks/tests/run-gh-guard-tests.sh
  - core/hooks/tests/run-approval-gate-tests.sh
  - core/hooks/tests/run-board-gate-tests.sh
  - core/hooks/tests/compliance-check.sh
loop_state: delivered
open_findings: none
---

# Implementation record — issue-142

## What was done

C1/C4 canon sweep against the write set frozen in
`docs/issue-142/proposals/2026-08-07-canon-sweep-and-enforcement.md`, plus
the `compliance-check.sh` extension covering C2/C3 detection:

- **C1 (fail-open kill-switch idiom)** replaced with the guarded-source +
  `gate_trap_fail_closed` + `gate_kill_switch_active` canon in:
  `warrant/hooks/scope-gate.sh`, `warrant/hooks/hunt-guard.sh`,
  `warrant/hooks/state.sh`, `warrant/hooks/hunt-state.sh`,
  `warrant/hooks/directive.sh`, `terse/hooks/terse.sh`,
  `scout/hooks/directive.sh`.
- **C4 (`mktemp -d` test footgun)** converted to the `mktd` helper
  (`_tmp.sh`) in: `core/hooks/tests/run-gate-lib-tests.sh`,
  `core/hooks/tests/run-gh-guard-tests.sh`,
  `core/hooks/tests/run-approval-gate-tests.sh`,
  `core/hooks/tests/run-board-gate-tests.sh`.
- **compliance-check.sh extended**: (a) a hooks.json-less bare-tree
  fallback (one-level `*.sh` scan) closes the scanning gap the survey
  found; (b) a C2 check flags any `mktemp` call in a gate's own
  request-time path, naming the in-memory heredoc/stdin pattern
  (`scope-gate.sh`/`hunt-guard.sh`) as the canonical replacement; (c) a C3
  check flags a gate that recognizes Write/Edit/MultiEdit/NotebookEdit but
  never mentions Bash at all, naming `gate_bash_write_targets`
  (gate-lib.sh) as the canonical replacement — a gate that documents why
  Bash is out of its scope (any `bash`-mentioning comment) is not flagged.

## Completed items (doc-placement ladder)

- No new env var, config key, dependency, migration, or setup step
  introduced — nothing to add to a handbook.
- No library/format choice over a named alternative and no changed
  public signature/wire format beyond what the approved proposal's
  Rationale already covers — no new `docs/issue-142/decisions/` entry.
- No benchmark/investigation numbers produced — no
  `docs/issue-142/reports/` entry beyond this record.

## Effect verification

Ran `warrant/hooks/scope-gate.sh` directly (env `CLAUDE_ROLE=implementation`,
a scratch git repo as `CLAUDE_PROJECT_DIR`, a `Write` to a
`docs/issue-9/reports/implementation.md`-shaped in-scope path inside that
scratch repo) after the C1 rewrite: exits with no deny output — i.e.
still ALLOWS a normal in-scope edit by a role session. This matters
specifically because scope-gate only began loading in production today
(issue #283) — the rewrite could have silently broken a code path
nothing had exercised in production yet; it did not.

Ran every touched-repo test suite after the sweep + extension:
`run-approval-gate-tests.sh` (46/46), `run-board-gate-tests.sh` (94/94),
`run-gate-lib-tests.sh` (58/58, includes the compliance-check group),
`run-gh-guard-tests.sh` (54/54). Also ran `compliance-check.sh` itself
against core's own hooks: all six PreToolUse-wired gates report `ok`
(gh-guard.sh, approval-gate.sh, board-gate.sh, handbook-trigger-gate.sh,
record-fields-gate.sh, trailer-gate.sh) — the C2/C3 additions do not flag
any of core's own already-migrated gates as a false positive.

**What the extended compliance-check does on failure, and whether it can
turn existing repos' checks red**: it is a standalone check script, not a
PreToolUse gate — it does not run automatically on every commit/write in
this or any other repo, and nothing in this proposal wires it into a CI
job. It only runs when a repo's own CI or a human invokes it. So: it
CANNOT turn an existing repo's checks red by itself landing in this PR —
a repo goes red only if that repo separately (a) picks up this updated
compliance-check.sh (e.g. via its own core submodule/vendoring bump) AND
(b) already has it wired into a CI gate that fails the build on
non-zero exit. For any of the 43 rulebook repos, neither condition holds
today: they are out of this write set (see below) and, per the issue's
own fix direction, "give the rulebooks a way to run it in their own CI"
is still open work. On a rulebook repo that already carries C1/C2/C3/C4
instances (all 43 do, per the issue's survey) and later opts into running
this compliance-check, the new C2/C3 checks WOULD fail — that is the
intended enforcement effect, not a false positive: the check's failure
message would name the file and the canonical replacement, matching the
issue's acceptance criterion.

## Out of scope, explicitly not done

Per the approved proposal's Constraints and the issue's own text, the 43
rulebook repos are **not** touched by this PR and are **not** reported as
done. They are separate repositories not reachable from this working
tree's write set. They still carry, unswept:
- C1's 14 directive scripts (accessibility, growth-analytics ×3,
  secure-coding ×2, localization ×3, implementation ×5)
- C3's two Bash-bypassable gates (issue-retrospective-rulebook's
  contributing-factors-gate.sh, implementation-rulebook's
  survey-order-gate.sh)
- C4's 106 `mktemp -d` test scripts
- C5's 9 `install.sh` (`plugin update ... || true`)

That sweep, plus wiring `compliance-check.sh` into each rulebook's own CI,
needs its own plan (a separate proposal per the issue's fix direction) —
it is not partially done by this PR and must not be read as such.

## Review response (PR #145)

Two blockers raised on the first review round, both closed in this commit:

**(1) Canon check did not detect a re-introduction.** Repro before the fix:
appended the old fail-open case block (`case "${WARRANT_OFF:-}" in
""|0|false|no|off) ;; *) exit 0 ;; esac`) to `warrant/hooks/state.sh` and
ran `compliance-check.sh warrant/hooks` — `rc=0`, only
`hunt-guard.sh`/`scope-gate.sh` even appeared in the output. Two compounding
gaps: (a) the script only ever collected PreToolUse-wired hooks, so
`state.sh` (a SessionStart hook) was never scanned at all; (b) the existing
kill-switch check only fires when `gate_kill_switch_active` is *absent* from
the file, so even a scanned file with the idiom re-appended alongside its
already-migrated call would pass. Fixed both: `compliance-check.sh` now
collects registered scripts from every hooks.json event block, not
PreToolUse only, and a new check matches the literal `*) exit 0 ;;` branch
shape directly, independent of what else the file contains. Re-ran the same
repro after the fix: `rc=1`, `compliance-check: FAIL —
.../warrant/hooks/state.sh:` naming the hand-rolled case branch and the
canonical replacement (`gate_kill_switch_active`, gate-lib.sh) — matching
the issue's acceptance criterion verbatim. Re-ran `compliance-check.sh`
against `warrant/hooks`, `terse/hooks`, `scout/hooks`, and `core/hooks`
with `state.sh` reverted to confirm no new false positive (all `ok`), and
`run-gate-lib-tests.sh` (58/58, including the compliance-check group).

**(2) Kill-switch migration was unproven.** The record's original "Effect
verification" section ran scope-gate once with no `WARRANT_OFF` set at all
and against a payload the gate ALLOWed either way — it never proved the
gate can genuinely DENY, so the on/off values were never actually
distinguished. Re-verified with a payload the gate genuinely denies: a
scratch repo with a proposal `status: approved` and `files: [foo.txt]`,
then a `Write` to `bar.txt` (outside the frozen set). Results:
`WARRANT_OFF` unset → deny (rc=2, "outside the write set"); `1`, `true`,
`yes`, `on` → allow (rc=0, gate disabled) — the only four values that
should disable it; `0`, `off`, `typo`, `"OFF "` (trailing space) → deny
(rc=2, gate stays ACTIVE) — confirming the fixed narrow disabling set
(`gate_kill_switch_active`, gate-lib.sh:66-73) actually holds at the gate
that consumes it, not just in the library function's own unit tests.

**Hunt before landing**: dispatched warrant-hunter (stance: assume this
guard goes silent when its own input is malformed) against the two
compliance-check.sh edits above. Finding: the new `*) exit 0 ;;` regex was
anchored to one physical line (`^\s*\*\)\s*exit\s+0\s*;;`) and silently
missed the identical idiom written across separate lines (`*)` / `exit 0`
/ `;;` each on their own line) — a shape at least as common as the
one-liner in hand-written case statements. Fixed by joining the file onto
one line first (`tr '\n' ' ' | grep -qE ...`) before matching. Verified:
appended a multi-line fail-open case block to `warrant/hooks/state.sh`,
confirmed `rc=1` naming the file, reverted, confirmed `compliance-check.sh`
still reports `ok` on all of `warrant/hooks`, `core/hooks`, `terse/hooks`,
`scout/hooks`, and re-ran `run-gate-lib-tests.sh` (58/58).

**Fleet status, stated plainly again**: the two fixes above extend
`compliance-check.sh`'s detection surface; they do not touch the 43
rulebook repos. Those repos remain outside this write set and still carry,
unswept: C1's 14 directive scripts, C3's two Bash-bypassable gates, C4's
106 `mktemp -d` test scripts, and C5's 9 `install.sh`
(`plugin update ... || true`) — unchanged from the "Out of scope" section
above. This PR closes the detection gap and proves the one migration
already in the write set; it does not close the fleet.

## What did not work

None.
