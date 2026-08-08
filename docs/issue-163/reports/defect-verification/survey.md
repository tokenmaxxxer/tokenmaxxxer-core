# Survey — issue-163 (defect-verification, phase 1)

code_under_review: `6d695bc66e2ec64bca44fdefee3a4239650efab9` (origin/main HEAD at survey time)

## No upstream records to read

`docs/issue-163/` had no `reports/implementation.md`, `reports/qa.md`, or
`reports/review.md` before this session — issue-163 is a direct hunt
assigned straight to defect-verification (per the issue's own text: "This
role reproduces and reports; fixes are follow-up issues the operator
files"), not a build-then-verify pipeline subject. There is no coding
record, qa record, or review record for this subject, and therefore no
closed_checks to cite or re-derive. Every attempt below is a self-devised
path, sourced from the issue text and this survey's own scan.

## Scope reality check: fleet is not reachable

The issue asks for a scan across "the 43 rulebook copies." This checkout
has no sibling rulebook trees (confirmed: `docs/issue-142/proposals/2026-08-07-canon-sweep-and-enforcement.md:106`
and `docs/issue-142/reports/implementation.md:100-101` both state the 43
rulebook repos are "not present in this working tree" and were
deliberately excluded from #142's write set for the same reason). `gh repo
view`/`gh api user` in this session show the authenticated account
(`JiwonJung94`) owns exactly one public repo, `tokenmaxxxer-core`; no
fleet org or sibling checkouts are reachable from here. The fleet-scan
half of this issue is `blocked: needs-repro-access` as a scope fact, not
an outcome of any single attempt — recorded here so phase 2 doesn't
re-discover it. `core/hooks/tests/compliance-check.sh` is written to be
invoked from *within* a rulebook's own hooks dir (its own header
documents this), so the scanner is portable; only the target repos are
absent.

## Core + plugin-hook scan (this checkout's reachable scope)

Scanned: `core/hooks/*.sh`, `core/hooks/lib/*.sh`, `core/hooks/lib/*.py`,
`core/hooks/tests/*.sh`, `core/hooks/tests/*.py`, `warrant/hooks/*.sh`,
`terse/hooks/*.sh`, `scout/hooks/*.sh`, `freelunch/hooks/*.sh` (38 files),
via a dispatched Explore-agent read pass, against the six signal
categories from the issue (swallowed errors, fail-open-on-internal-error,
absent-input-allows, string-judged commands, mktemp footguns, dead deny
branches).

Candidate hits (evidence pointers, not verdicts — verification is phase 2):

1. `freelunch/hooks/observe.sh:159` — the python invocation is wrapped in
   `2>/dev/null` with an unconditional `exit 0` after it; an uncaught
   exception inside the python payload would be swallowed and read as a
   clean pass, silently disabling whatever `FREELUNCH_ENFORCE` denial that
   run was supposed to produce.
2. `warrant/hooks/hunt-guard.sh:28,51-56` — fail-open when `python3` is
   absent or the JSON payload doesn't parse, which would let hunter
   dispatch proceed uncapped instead of being blocked.
3. `warrant/hooks/scope-gate.sh:17,25,51-59` — same fail-open shape on
   missing python3 / unreadable / unexpected-schema payload; comments in
   the file mark this as deliberate, which is exactly the "kill-switch
   idiom the #142 sweep may have missed" the issue calls out — deliberate
   fail-open is still fail-open and worth an independent repro.
4. `warrant/hooks/scope-gate.sh:183-220` — the dangerous-command withhold
   list is regex-on-raw-string, the #141 family the issue names
   explicitly; candidate bypass via quoting/`$(...)`/variable substitution.
5. `core/hooks/trailer-gate.sh:86` — the top-level `git ... commit`
   detector is a single regex against the raw command text; anything that
   reaches `git commit` without matching the pattern would skip the whole
   §13 trailer check entirely (a string-judged command, #141 family).
6. `core/hooks/lib/role-directive.sh:30` — silently no-ops when
   `CLAUDE_ROLE` is unset; the role-directive banner just disappears with
   no error surfaced. Candidate absent-input-allow, though the blast
   radius (informational banner vs. an enforcement decision) needs
   confirming before it's worth a repro slot.
7. `core/hooks/gh-guard.sh` — string-judged command matching; the file's
   *own* test suite (`core/hooks/tests/run-gh-guard-tests.sh`, the
   `gap-c-*` cases) already documents accepted, live bypasses via a
   renamed `gh` binary or an indirect wrapper script — this is a named,
   self-admitted gap, not a hidden one, but the issue asks for "anything
   that renders as success while the work did not happen," and an
   accepted-gap comment is exactly a candidate for "does it still hold
   under adversarial pressure, or has drift made it worse."

Categories searched with **no** surviving instance found in this scope
(recorded so phase 2 doesn't re-scan them from zero):
- Fail-open-on-internal-error in the primary enforcement gates
  (`record-fields-gate.sh`, `board-gate.sh`, `approval-gate.sh`,
  `handbook-trigger-gate.sh`, `trailer-gate.sh` core logic) — all wrap
  their python judge in `trap ... EXIT` / `except Exception: sys.exit(2)`
  fail-closed patterns.
- mktemp/runtime-write footguns in any gate's request-time hot path —
  `compliance-check.sh:143-144` actively greps for and would flag a
  `mktemp` call inside a gate script; none found outside test harnesses,
  which correctly scope to `${TMPDIR:-/tmp}`.
- Dead/always-false deny conditions — none spotted in `board-gate.sh`,
  `approval-gate.sh`, `record-fields-gate.sh`.
- `set +e` without a restore — no `set +e` anywhere in scope; gates use
  `set -uo pipefail` plus `trap` instead of manual errexit toggling.
- Absent-input-allows in `approval-gate.sh`/`board-gate.sh` specifically —
  both explicitly `deny()` on empty payload / missing remote / unresolved
  branch.

## Scout-directive skip record

Scouting (external exemplar research) was skipped: this deliverable's
shape is fixed by the defect-verification role's own protocol (an attempt
list naming sources, then phase-2 reproduction with a fixed three-value
outcome and a deterministic severity band) — there is no external
product/design decision this survey could improve by benchmarking other
teams' silent-failure audits. This falls under the "spec leaves no design
decision open" skip condition.
