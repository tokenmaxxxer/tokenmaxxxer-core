# defect-verification — issue-163, phase 2

code_under_review: `6d695bc66e2ec64bca44fdefee3a4239650efab9` (origin/main)
Attempt list: `docs/issue-163/proposals/2026-08-08-silent-failure-hunt-attempt-list.md`
Repros: `tests/test_silent_failure_repros.py`

loop_state: complete

## What was done

Independently attempted all 7 self-devised, in-checkout candidates
(A1–A7) from the approved phase-1 attempt list, plus recorded the 43-repo
fleet scan (A8) as `blocked: needs-repro-access` per-repo rows. Every
attempt has a recorded outcome (`reproduced` / `not-reproduced` /
`blocked: needs-repro-access`). Every `reproduced` attempt has a runnable
repro in `tests/test_silent_failure_repros.py` and a finding addressed to
coding, with a deterministic severity band. Wrote this record and the 43-row
fleet table.

## Why

Issue-163 asks for an independent reproduction pass over silent-failure
and fail-open defects in core's and the plugins' hooks, per the approved
phase-1 attempt list (`docs/issue-163/proposals/2026-08-08-silent-failure-hunt-attempt-list.md`),
which itself derives from the phase-1 survey
(`docs/issue-163/reports/defect-verification/survey.md`). This role's
mandate is reproduction and reporting only — fixes are follow-up issues
for the operator, per the issue text and the attempt list's own
Out-of-scope section.

## Open findings

Three blocking findings stand, addressed to coding, none waived:

- **A2** — `warrant/hooks/hunt-guard.sh:87` never matches the actual
  qualified agent type `warrant:warrant-hunter`, so the hunter dispatch
  cap is inert. Severity: High.
- **A4** — `warrant/hooks/scope-gate.sh:207-239` auto-approves arbitrary
  Bash commands (regex-withhold bypass via variable indirection; no
  write-set check for Bash at all) during any approved proposal.
  Severity: Critical.
- **A5** — `core/hooks/trailer-gate.sh:86` skips the §13 trailer
  requirement entirely for a quote-split `git commi""t` commit.
  Severity: High.

Two advisory findings, not blocking:

- **A1** — `freelunch/hooks/observe.sh:44-45` silently skips its own
  `FREELUNCH_ENFORCE` check on malformed JSON. Severity: Medium.
- **A7** — `core/hooks/gh-guard.sh`'s self-admitted renamed-binary /
  indirect-wrapper gap still holds, unchanged. Severity: Low.

A3 and A6 are `not-reproduced` (both operate exactly as documented, no
enforcement effect found). A8's 43 rows are `blocked: needs-repro-access`
(scope fact: no rulebook checkout is reachable from this session).

## Attempts A1–A7 (this checkout)

### A1 — reproduced

`freelunch/hooks/observe.sh:44-45` — a malformed JSON payload hits
`except Exception: sys.exit(0)` before `FREELUNCH_ENFORCE`'s deny check
ever runs. A real `sync_agent_dispatch` violation with a valid payload is
correctly denied (control run: `permissionDecision: deny`); the identical
violation wrapped in a malformed-JSON payload produces no output and exit
0 — silently allowed, no trace in the observe log, no marker.

Evidence: `tests/test_silent_failure_repros.py::test_A1_observe_sh_malformed_json_silently_skips_enforcement`.

**Finding → coding.** `freelunch/hooks/observe.sh` fails open on the
enforcement check specifically (not only the logging path) whenever the
`PreToolUse` payload fails to parse as JSON. Severity: Medium (internal
best-practice nudge silently skipped, not a security boundary against an
external actor) → advisory.

### A2 — reproduced

`warrant/hooks/hunt-guard.sh:87` — `if agent_type != "warrant-hunter": allow()`.
This session's own agent registry names the real hunter
`warrant:warrant-hunter` (plugin-namespaced qualified form — see this
session's own available-agent-types listing). The guard's exact-match
check never matches that qualified name, so the single-flight lock and
the `WARRANT_HUNT_MAX` cap — the entire point of the file — never engage
for any real dispatch. Control (unqualified `warrant-hunter`, cap 0):
denied, exit 2. Same call with the qualified name actually in use:
allowed, exit 0.

`observe.sh`'s own in-repo comment (lines ~86-92) explicitly names this
exact failure mode for a *different* check ("the harness registers this
agent under the plugin-namespaced... nothing guarantees every context
injects that prefix, so both... are recognized") — `hunt-guard.sh` was not
given the same fix.

Evidence: `tests/test_silent_failure_repros.py::test_A2_hunt_guard_never_matches_actual_namespaced_agent_type`.

**Finding → coding.** `warrant/hooks/hunt-guard.sh:87` compares
`subagent_type` against only the unqualified `"warrant-hunter"`, so the
hunter dispatch cap is non-functional for the agent type actually
dispatched in this system. Severity: High (a designed safety limit is
completely inert as deployed, not merely narrowed) → blocking.

### A3 — not-reproduced (as a defect)

`warrant/hooks/scope-gate.sh:17` fails open on missing `python3` /
unreadable payload / unexpected schema exactly as its own header comment
documents ("Fails open on a missing python3, unreadable payload, or
unexpected schema."). This is disclosed, deliberate behavior operating as
documented, not a silent divergence between stated and actual behavior —
outside this role's mandate to flag as a defect. No finding.

### A4 — reproduced

`warrant/hooks/scope-gate.sh:207-239` — for the `Bash` tool, any command
that does not match the `WITHHELD` regex list and is not an untrailered
`git commit` gets an explicit `permissionDecision: allow` auto-approval,
with the reason "approval covers the work it described." Two independent
problems:

1. The withhold list is a fixed regex set (`rm -rf`, `sudo`, etc.) that
   trivial variable indirection bypasses: `F=-rf; rm $F /tmp/x` does not
   match `\brm\s+-[a-z]*[rR]` and is silently auto-approved.
2. The write-set restriction (the entire stated purpose of the file, per
   its own header: "edits land only in paths its frontmatter froze") is
   checked ONLY for `Write`/`Edit`/`NotebookEdit` `file_path`/`notebook_path`
   inputs. `Bash` commands are never checked against the write set at
   all — an unrelated command like
   `curl -s http://example.com/x -o /tmp/leak.txt` is auto-approved
   during any approved proposal, regardless of what the proposal's
   `files:` list says.

Evidence: `tests/test_silent_failure_repros.py::test_A4_scope_gate_auto_approves_arbitrary_bash_during_approved_proposal`.

**Finding → coding.** `warrant/hooks/scope-gate.sh` auto-approves
essentially arbitrary Bash commands (regex-withhold-list bypass via
indirection, and no write-set check for Bash at all) any time exactly one
proposal is `status: approved`. Severity: Critical (silently converts the
permission prompt into an auto-allow for destructive/exfiltrating
commands, during ordinary approved-work sessions) → blocking.

### A5 — reproduced

`core/hooks/trailer-gate.sh:86` — `commit_m = re.search(r'\bgit\b[^\n;&|]*\bcommit\b(?!-)', command)`.
Splitting the literal word "commit" with an empty-string quote pair —
`git commi""t -m x`, identical shell-effective command to
`git commit -m x` — no longer matches `\bcommit\b` as a contiguous word,
so `commit_m` is `None` and the function `allow()`s before ever reading
staged files or checking the trailer. Control (plain `git commit -m x`,
docs/issue-163 work staged, no trailer): denied, exit 2, correct message.
Same effective command, quote-split: allowed, exit 0, no trace.

Evidence: `tests/test_silent_failure_repros.py::test_A5_trailer_gate_quote_split_bypasses_commit_detection`.

**Finding → coding.** `core/hooks/trailer-gate.sh:86`'s single raw-text
regex for detecting `git commit` is bypassed by quote-splitting the
literal word, letting a commit that stages `docs/issue-<n>/**` work skip
the contract §13 trailer requirement entirely. Severity: High (defeats a
mandatory cross-role compliance mechanism with a one-character-class
bypass) → blocking.

### A6 — not-reproduced (as a defect)

`core/hooks/lib/role-directive.sh:30` — `[ -n "$role" ] || return 0` when
`CLAUDE_ROLE` is unset is documented in-file as "no role -> silent no-op,
same as core's own directive.sh." Reviewed every gate this checkout scans
(`trailer-gate.sh`, `scope-gate.sh`, `hunt-guard.sh`, `gh-guard.sh`,
`observe.sh`) for any dependency on `CLAUDE_ROLE` being *set* as an
enforcement precondition: none treat an absent role as an allow signal —
`trailer-gate.sh` merely falls back to the literal string `"trailer-gate"`
for its own message prefix. The no-op is cosmetic (the session-start
banner disappears) with no found enforcement effect. No finding.

### A7 — reproduced (self-admitted, tracked; no drift)

`core/hooks/gh-guard.sh`'s own test suite
(`core/hooks/tests/run-gh-guard-tests.sh`) still asserts `allow` for
`gap-c-renamed-bin` and `gap-c-file-indirect` — a renamed `gh` binary or
an indirect wrapper script still bypasses the guard, exactly as the suite
has documented it as an accepted gap. Full suite run: 54/54 passed,
including both gap-c cases at their expected `allow` outcome — the gap
has neither widened nor narrowed since it was last documented.

Evidence: `tests/test_silent_failure_repros.py::test_A7_gh_guard_renamed_binary_bypass_still_holds`.

**Finding → coding.** Re-affirms the existing, already-tracked
`gh-guard.sh` renamed-binary/indirect-wrapper gap is still live and
unchanged. Severity: Low (known, disclosed, covered by the file's own
test suite; this attempt found no new drift) → advisory.

## A8 — fleet scan, 43 rulebook repos

Fixed in advance by the phase-1 survey (`docs/issue-163/reports/defect-verification/survey.md`):
no sibling rulebook checkout is reachable from this session (single
public repo, `tokenmaxxxer-core`, confirmed via `gh repo view`/`gh api
user` and consistent with issue-142's own scope note that the fleet is
out of reach from core's checkout). Every row below is
`blocked: needs-repro-access` — recorded explicitly per row, not folded
into one blanket note, per the issue's own acceptance criterion ("zero
findings is a row, not an omission").

| # | Repo | Outcome | Note |
|---|------|---------|------|
| 1 | rulebook-repo-01 (name unknown — fleet not reachable) | blocked: needs-repro-access | No sibling rulebook checkout reachable from this session (single-repo GitHub identity `tokenmaxxxer-core`; confirmed independently and consistent with issue-142's own scope note) |
| 2 | rulebook-repo-02 (name unknown — fleet not reachable) | blocked: needs-repro-access | No sibling rulebook checkout reachable from this session (single-repo GitHub identity `tokenmaxxxer-core`; confirmed independently and consistent with issue-142's own scope note) |
| 3 | rulebook-repo-03 (name unknown — fleet not reachable) | blocked: needs-repro-access | No sibling rulebook checkout reachable from this session (single-repo GitHub identity `tokenmaxxxer-core`; confirmed independently and consistent with issue-142's own scope note) |
| 4 | rulebook-repo-04 (name unknown — fleet not reachable) | blocked: needs-repro-access | No sibling rulebook checkout reachable from this session (single-repo GitHub identity `tokenmaxxxer-core`; confirmed independently and consistent with issue-142's own scope note) |
| 5 | rulebook-repo-05 (name unknown — fleet not reachable) | blocked: needs-repro-access | No sibling rulebook checkout reachable from this session (single-repo GitHub identity `tokenmaxxxer-core`; confirmed independently and consistent with issue-142's own scope note) |
| 6 | rulebook-repo-06 (name unknown — fleet not reachable) | blocked: needs-repro-access | No sibling rulebook checkout reachable from this session (single-repo GitHub identity `tokenmaxxxer-core`; confirmed independently and consistent with issue-142's own scope note) |
| 7 | rulebook-repo-07 (name unknown — fleet not reachable) | blocked: needs-repro-access | No sibling rulebook checkout reachable from this session (single-repo GitHub identity `tokenmaxxxer-core`; confirmed independently and consistent with issue-142's own scope note) |
| 8 | rulebook-repo-08 (name unknown — fleet not reachable) | blocked: needs-repro-access | No sibling rulebook checkout reachable from this session (single-repo GitHub identity `tokenmaxxxer-core`; confirmed independently and consistent with issue-142's own scope note) |
| 9 | rulebook-repo-09 (name unknown — fleet not reachable) | blocked: needs-repro-access | No sibling rulebook checkout reachable from this session (single-repo GitHub identity `tokenmaxxxer-core`; confirmed independently and consistent with issue-142's own scope note) |
| 10 | rulebook-repo-10 (name unknown — fleet not reachable) | blocked: needs-repro-access | No sibling rulebook checkout reachable from this session (single-repo GitHub identity `tokenmaxxxer-core`; confirmed independently and consistent with issue-142's own scope note) |
| 11 | rulebook-repo-11 (name unknown — fleet not reachable) | blocked: needs-repro-access | No sibling rulebook checkout reachable from this session (single-repo GitHub identity `tokenmaxxxer-core`; confirmed independently and consistent with issue-142's own scope note) |
| 12 | rulebook-repo-12 (name unknown — fleet not reachable) | blocked: needs-repro-access | No sibling rulebook checkout reachable from this session (single-repo GitHub identity `tokenmaxxxer-core`; confirmed independently and consistent with issue-142's own scope note) |
| 13 | rulebook-repo-13 (name unknown — fleet not reachable) | blocked: needs-repro-access | No sibling rulebook checkout reachable from this session (single-repo GitHub identity `tokenmaxxxer-core`; confirmed independently and consistent with issue-142's own scope note) |
| 14 | rulebook-repo-14 (name unknown — fleet not reachable) | blocked: needs-repro-access | No sibling rulebook checkout reachable from this session (single-repo GitHub identity `tokenmaxxxer-core`; confirmed independently and consistent with issue-142's own scope note) |
| 15 | rulebook-repo-15 (name unknown — fleet not reachable) | blocked: needs-repro-access | No sibling rulebook checkout reachable from this session (single-repo GitHub identity `tokenmaxxxer-core`; confirmed independently and consistent with issue-142's own scope note) |
| 16 | rulebook-repo-16 (name unknown — fleet not reachable) | blocked: needs-repro-access | No sibling rulebook checkout reachable from this session (single-repo GitHub identity `tokenmaxxxer-core`; confirmed independently and consistent with issue-142's own scope note) |
| 17 | rulebook-repo-17 (name unknown — fleet not reachable) | blocked: needs-repro-access | No sibling rulebook checkout reachable from this session (single-repo GitHub identity `tokenmaxxxer-core`; confirmed independently and consistent with issue-142's own scope note) |
| 18 | rulebook-repo-18 (name unknown — fleet not reachable) | blocked: needs-repro-access | No sibling rulebook checkout reachable from this session (single-repo GitHub identity `tokenmaxxxer-core`; confirmed independently and consistent with issue-142's own scope note) |
| 19 | rulebook-repo-19 (name unknown — fleet not reachable) | blocked: needs-repro-access | No sibling rulebook checkout reachable from this session (single-repo GitHub identity `tokenmaxxxer-core`; confirmed independently and consistent with issue-142's own scope note) |
| 20 | rulebook-repo-20 (name unknown — fleet not reachable) | blocked: needs-repro-access | No sibling rulebook checkout reachable from this session (single-repo GitHub identity `tokenmaxxxer-core`; confirmed independently and consistent with issue-142's own scope note) |
| 21 | rulebook-repo-21 (name unknown — fleet not reachable) | blocked: needs-repro-access | No sibling rulebook checkout reachable from this session (single-repo GitHub identity `tokenmaxxxer-core`; confirmed independently and consistent with issue-142's own scope note) |
| 22 | rulebook-repo-22 (name unknown — fleet not reachable) | blocked: needs-repro-access | No sibling rulebook checkout reachable from this session (single-repo GitHub identity `tokenmaxxxer-core`; confirmed independently and consistent with issue-142's own scope note) |
| 23 | rulebook-repo-23 (name unknown — fleet not reachable) | blocked: needs-repro-access | No sibling rulebook checkout reachable from this session (single-repo GitHub identity `tokenmaxxxer-core`; confirmed independently and consistent with issue-142's own scope note) |
| 24 | rulebook-repo-24 (name unknown — fleet not reachable) | blocked: needs-repro-access | No sibling rulebook checkout reachable from this session (single-repo GitHub identity `tokenmaxxxer-core`; confirmed independently and consistent with issue-142's own scope note) |
| 25 | rulebook-repo-25 (name unknown — fleet not reachable) | blocked: needs-repro-access | No sibling rulebook checkout reachable from this session (single-repo GitHub identity `tokenmaxxxer-core`; confirmed independently and consistent with issue-142's own scope note) |
| 26 | rulebook-repo-26 (name unknown — fleet not reachable) | blocked: needs-repro-access | No sibling rulebook checkout reachable from this session (single-repo GitHub identity `tokenmaxxxer-core`; confirmed independently and consistent with issue-142's own scope note) |
| 27 | rulebook-repo-27 (name unknown — fleet not reachable) | blocked: needs-repro-access | No sibling rulebook checkout reachable from this session (single-repo GitHub identity `tokenmaxxxer-core`; confirmed independently and consistent with issue-142's own scope note) |
| 28 | rulebook-repo-28 (name unknown — fleet not reachable) | blocked: needs-repro-access | No sibling rulebook checkout reachable from this session (single-repo GitHub identity `tokenmaxxxer-core`; confirmed independently and consistent with issue-142's own scope note) |
| 29 | rulebook-repo-29 (name unknown — fleet not reachable) | blocked: needs-repro-access | No sibling rulebook checkout reachable from this session (single-repo GitHub identity `tokenmaxxxer-core`; confirmed independently and consistent with issue-142's own scope note) |
| 30 | rulebook-repo-30 (name unknown — fleet not reachable) | blocked: needs-repro-access | No sibling rulebook checkout reachable from this session (single-repo GitHub identity `tokenmaxxxer-core`; confirmed independently and consistent with issue-142's own scope note) |
| 31 | rulebook-repo-31 (name unknown — fleet not reachable) | blocked: needs-repro-access | No sibling rulebook checkout reachable from this session (single-repo GitHub identity `tokenmaxxxer-core`; confirmed independently and consistent with issue-142's own scope note) |
| 32 | rulebook-repo-32 (name unknown — fleet not reachable) | blocked: needs-repro-access | No sibling rulebook checkout reachable from this session (single-repo GitHub identity `tokenmaxxxer-core`; confirmed independently and consistent with issue-142's own scope note) |
| 33 | rulebook-repo-33 (name unknown — fleet not reachable) | blocked: needs-repro-access | No sibling rulebook checkout reachable from this session (single-repo GitHub identity `tokenmaxxxer-core`; confirmed independently and consistent with issue-142's own scope note) |
| 34 | rulebook-repo-34 (name unknown — fleet not reachable) | blocked: needs-repro-access | No sibling rulebook checkout reachable from this session (single-repo GitHub identity `tokenmaxxxer-core`; confirmed independently and consistent with issue-142's own scope note) |
| 35 | rulebook-repo-35 (name unknown — fleet not reachable) | blocked: needs-repro-access | No sibling rulebook checkout reachable from this session (single-repo GitHub identity `tokenmaxxxer-core`; confirmed independently and consistent with issue-142's own scope note) |
| 36 | rulebook-repo-36 (name unknown — fleet not reachable) | blocked: needs-repro-access | No sibling rulebook checkout reachable from this session (single-repo GitHub identity `tokenmaxxxer-core`; confirmed independently and consistent with issue-142's own scope note) |
| 37 | rulebook-repo-37 (name unknown — fleet not reachable) | blocked: needs-repro-access | No sibling rulebook checkout reachable from this session (single-repo GitHub identity `tokenmaxxxer-core`; confirmed independently and consistent with issue-142's own scope note) |
| 38 | rulebook-repo-38 (name unknown — fleet not reachable) | blocked: needs-repro-access | No sibling rulebook checkout reachable from this session (single-repo GitHub identity `tokenmaxxxer-core`; confirmed independently and consistent with issue-142's own scope note) |
| 39 | rulebook-repo-39 (name unknown — fleet not reachable) | blocked: needs-repro-access | No sibling rulebook checkout reachable from this session (single-repo GitHub identity `tokenmaxxxer-core`; confirmed independently and consistent with issue-142's own scope note) |
| 40 | rulebook-repo-40 (name unknown — fleet not reachable) | blocked: needs-repro-access | No sibling rulebook checkout reachable from this session (single-repo GitHub identity `tokenmaxxxer-core`; confirmed independently and consistent with issue-142's own scope note) |
| 41 | rulebook-repo-41 (name unknown — fleet not reachable) | blocked: needs-repro-access | No sibling rulebook checkout reachable from this session (single-repo GitHub identity `tokenmaxxxer-core`; confirmed independently and consistent with issue-142's own scope note) |
| 42 | rulebook-repo-42 (name unknown — fleet not reachable) | blocked: needs-repro-access | No sibling rulebook checkout reachable from this session (single-repo GitHub identity `tokenmaxxxer-core`; confirmed independently and consistent with issue-142's own scope note) |
| 43 | rulebook-repo-43 (name unknown — fleet not reachable) | blocked: needs-repro-access | No sibling rulebook checkout reachable from this session (single-repo GitHub identity `tokenmaxxxer-core`; confirmed independently and consistent with issue-142's own scope note) |

## Eligibility check

Unresolved blocking findings: A2, A4, A5. No waiver on record. **Not
eligible for `cleared`** — three blocking findings stand, addressed to
coding.

## Severity band lookup (deterministic, not freehand)

| Attempt | Outcome | Severity | Band |
|---|---|---|---|
| A1 | reproduced | Medium | advisory |
| A2 | reproduced | High | blocking |
| A3 | not-reproduced | — | — |
| A4 | reproduced | Critical | blocking |
| A5 | reproduced | High | blocking |
| A6 | not-reproduced | — | — |
| A7 | reproduced | Low | advisory |
| A8 (×43) | blocked: needs-repro-access | — | — |
