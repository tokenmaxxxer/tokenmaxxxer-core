---
kind: coding-record
subject: issue-133
produced_by: implementation
code_under_review: `core/hooks/record-fields-gate.sh`, `core/hooks/tests/run-role-gates-tests.sh`, `docs/handbooks/role-gates-tests.md`
loop_state: landed
upstream:
  - path: docs/issue-133/proposals/2026-08-04-build-sha-whitelist-check.md
    sha: de2b09c59963a1d4b64f3a0ced31513fe52d98d0
---

# Implementation record — issue-133

## Why

Phase 2, approved via issue-level comment `APPROVE issue-133/implementation`
(exact string, posted by an approvers.md account, jjongkwann — also this
PR's author, so single-account mode applies per contract v3 s19). Delivering
the approved proposal's `## What will be done` items 1-4: convert
`record-fields-gate.sh`'s `sha:` check from a bracket-only blacklist to an
allow-list (`same-commit` or exactly 40 lowercase hex), reword the denial
message, add red-to-green tests for the three named unresolved spellings,
and update the handbook paragraph describing the check.

## What was done

1. `core/hooks/record-fields-gate.sh:171-179` — rewrote `placeholder_shas()`
   from a bracket-only regex (`^\s*sha:\s*(<[^\n]*>)\s*$`) to an allow-list:
   it now matches every `^\s*sha:\s*(.*)$` line, strips the value, and
   collects it as "bad" unless the value is exactly the literal
   `same-commit` or matches `^[0-9a-f]{40}$`. Reworded `deny_placeholder()`'s
   message from "is a bracket placeholder, not a resolvable value" to "is
   not `same-commit` or a 40-character hex commit sha", citing both
   issue-128 (origin) and issue-133 (this tightening). Both existing call
   sites (`:181-185` proposal early-exit, `:214-216` record path) call the
   same function unchanged — confirmed by `git diff`, only the function
   body and message text changed. Also updated the file's own top-of-file
   comment block (`:13-19`, same file already in the write set) from
   "denies any bracket placeholder" prose to describe the allow-list shape,
   so the in-file documentation does not go stale alongside the code it
   describes — not itemized separately in the proposal's `## What will be
   done`, but the same file/same-turn edit the doc-placement ladder already
   asks for a changed check's description.
2. `core/hooks/tests/run-role-gates-tests.sh` — added three new `run_rf`
   cases directly after the existing issue-128 block: proposal-path
   `sha: HEAD` denied, `sha: TBD` denied, `sha: <set at commit> -- fix
   later` (bracket + trailing prose) denied — all three labeled
   `(issue-133)`. Left the five existing issue-128 cases (bracket-deny,
   same-commit-allow x2, real-hex-allow, record-path bracket-deny/allow)
   untouched; they re-ran unmodified against the new implementation as part
   of `## Verify` below.
3. `docs/handbooks/role-gates-tests.md:28-38` — reworded the paragraph
   describing `record-fields-gate.sh`'s second check from bracket-blacklist
   prose to allow-list prose, naming all three now-denied unresolved
   spellings (`HEAD`, `TBD`, bracket+trailing-prose) alongside the
   already-denied bracket-only form, same turn as the gate change.
4. This record.

## What did not work

The first draft of the third new test case's trailing-prose string used a
literal em dash (`\xe2\x80\x94`) as a JSON hex escape inside the test
harness's `content` argument; `\x` is not a valid JSON string escape (JSON
only recognizes `\uXXXX`), so `python3 -c 'json.loads(...)'` inside
`record-fields-gate.sh` would have failed to parse that payload. Caught
before running the suite by re-reading the escape sequence against JSON's
grammar; replaced the em dash with a plain ASCII `--` in the test case
string (`core/hooks/tests/run-role-gates-tests.sh`, the "bracket+trailing-
prose" case) — the case only needs *some* trailing prose after the bracket
to reproduce Finding 1's third unresolved spelling, not the exact
character survey.md quoted.

## Rationale for deviations

One small addition beyond the proposal's `## What will be done` item 2
(which named only `deny_placeholder()`'s message text): also reworded
`record-fields-gate.sh:13-19`'s top-of-file comment block, which
documented the old check in the same "bracket placeholder" language the
proposal already flagged as inaccurate for `deny_placeholder()`'s message.
Leaving it unchanged would have left the file's own header contradicting
the code three lines below it. This is not a scope-exceeded stop (no file
outside the frozen write set was touched — `record-fields-gate.sh` was
already in scope) and not an alternative swap (no proposal-stated choice
was replaced) — it is a same-file, same-turn consistency fix directly
downstream of item 1/2's regex-and-message change, small enough (7 lines
of prose) not to warrant its own proposal cycle. Noted here per the
record-shape directive's broad divergence criterion rather than left
silent.

## Doc-placement ladder

- [x] No `docs/issue-133/decisions/` entry — this is a same-file,
  same-shape regex/message change to an existing check (per the approved
  proposal's own `## Rationale`, which already recorded and rejected the
  one real alternative considered — a YAML-parser rewrite — at phase 1);
  no new library-or-format choice or public-signature change was made at
  phase 2 to additionally record.
- [x] `docs/handbooks/role-gates-tests.md` updated in the same commit as
  the `record-fields-gate.sh` change it documents (item 3 above) — the
  doctrine-ladder rule for a changed mechanical check's description.
- [x] `docs/issue-133/reports/implementation.md` (this file) — the
  phase-2 record, per contract §11/§19.
- [x] No `.env.example` / dependency-manifest / migration entry — no env
  var, dependency, or schema change was introduced.
- [x] No `docs/issue-133/reports/` benchmark/investigation numbers beyond
  this record — the proposal's phase-1 survey already carried the
  repo-wide `sha:` value-shape tally; this delivery adds no new
  investigation, only the code and tests it specified.

## Hunt

`warrant-hunter` is not among this session's available `Agent`-tool
subagent types (same absence noted in issue-88/90/93/94/98/100/106/118/128's
records). In its place, adopted each stance directly by inspection,
following the same local precedent.

### after-proposal (retroactive) — stance: assume the rule as drafted cannot hold — find the state nothing maintains

Verdict: NO FINDING
Seed: `docs/issue-133/proposals/2026-08-04-build-sha-whitelist-check.md`
(the approved proposal, commit `de2b09c`)
Started/ended: this session, before and after drafting the gate edit.

Checked whether the new allow-list regex (`^\s*sha:\s*(.*)$`, then an exact
`same-commit`/40-hex test) could false-fire against a field it must not
touch, per the proposal's own constraint that the five §20 checks and the
separate `code_under_review` bare-sha check stay unchanged: traced the
regex by hand against `acknowledged_sha:` and `code_under_review:` lines —
`^\s*` consumes only whitespace, so the next literal characters checked
are `sha:`; on those other lines the next characters are `a`/`c`, not `s`,
so neither can match. Also confirmed by direct `git diff` that the §20
`missing` logic (`:192-206`) and the `code_under_review` block
(`:218-226`) are byte-identical before and after — only `placeholder_shas`,
`deny_placeholder`, and the top-of-file comment changed. No finding.

### before-landing — stance: assume this change and another gate cancel each other — find the pair

Verdict: NO FINDING
Seed: `core/hooks/tests/compliance-check.sh`, the mechanical scanner that
flags a hand-rolled `*_OFF` kill-switch check not routed through
`gate_kill_switch_active` (`core/hooks/tests/compliance-check.sh:89`).
Started/ended: this session, after drafting the gate edit.

The new code adds no new `*_OFF` variable and no new kill-switch branch —
it sits entirely inside the function body already gated by the existing
`gate_kill_switch_active "${RECORD_FIELDS_GATE_OFF:-}"` call at the top of
the script (line 46, unmoved). Ran the full `run-all.sh` suite, which
includes a dedicated "compliance-check hooks.json scan scope" pass
(4 passed, 0 failed). No finding.

### Closed checks (for verify)

closed_checks:
- name: new allow-list regex cannot match acknowledged_sha/code_under_review lines
  ref: core/hooks/record-fields-gate.sh:171-179 (regex/allow-list), :117-118,145-148 (scope match, untouched)
- name: five §20 field checks and code_under_review bare-sha check untouched
  ref: core/hooks/record-fields-gate.sh:192-206,218-226 (git diff: byte-identical)
- name: no new kill-switch variable introduced; existing RECORD_FIELDS_GATE_OFF covers the changed function
  ref: core/hooks/record-fields-gate.sh:46
- name: docs/issue-20 real-world sha: HEAD instance left byte-identical (no retroactive edit)
  ref: docs/issue-20/proposals/2026-07-31-build-gh-guard-endpoint-match.md (git diff empty against this delivery)
- name: red->green demonstrated directly against both the pre-fix and post-fix script as real subprocesses
  ref: core/hooks/tests/run-role-gates-tests.sh (post-fix, 3 new cases); this session's scratch check against `git show HEAD:core/hooks/record-fields-gate.sh` (pre-fix, not committed)

## Next steps

None open. This delivery completes all four `## What will be done` items
from the approved proposal; the proposal's own `## Out of scope` list
(retroactive edit to `docs/issue-20/…`, widening `PROPOSALS_RE`/`RECORDS_RE`
path scope, allow-listing abbreviated 7-39-char hex shas, SHA-256/64-hex
support) is deliberately not touched here.

## Resolution path

No open finding is raised against another role's record from this
delivery; both hunt stances above closed with no finding.

## Verify

`bash core/hooks/tests/run-role-gates-tests.sh` -> `role-gates: 27 passed,
0 failed` (24 pre-existing cases unaffected, 3 new issue-133 cases pass).

`bash core/hooks/tests/run-all.sh` -> `ALL OK` (role-gates 27/27,
stub-check 3/3, compliance-check 4/4, plus the three sibling-plugin suites
— terse, freelunch, scout — all pass).

`bash core/hooks/tests/run-gate-lib-tests.sh` -> `gate-lib: 57 passed, 1
failed`. The one failure (`compliance-check.sh: flags a hand-rolled
kill-switch + replace shape want=deny got=allow`) is the same pre-existing
sandbox artifact issue-128's record already documented (`mktemp: mkdtemp
failed ... Operation not permitted` / `mkdir: /hooks: Operation not
permitted` immediately precede it in this run's output too) — not caused
by this change, since this delivery touches no kill-switch code.

Red->green demonstrated directly, not only asserted: extracted the
pre-fix `record-fields-gate.sh` via `git show HEAD:core/hooks/
record-fields-gate.sh` and ran it as a real subprocess (same payload
construction `run_rf` uses) against the three unresolved spellings —
`sha: HEAD` -> allow, `sha: TBD` -> allow, `sha: <set at commit> -- fix
later` -> allow (red, confirming Finding 1's claim first-hand). The
post-fix script denies all three (green, from the `run-role-gates-tests.sh`
run above) while the two valid forms (`same-commit`, real 40-hex) keep
passing (pre-existing issue-128 cases, unaffected).

`git diff --stat` (this delivery, tracked files only) ->
`core/hooks/record-fields-gate.sh`, `core/hooks/tests/run-role-gates-tests.sh`,
`docs/handbooks/role-gates-tests.md` — matching the proposal's three-file
write set (the fourth file, this record, is untracked/new, not a diff).

`git diff --stat -- docs/issue-20/proposals/2026-07-31-build-gh-guard-endpoint-match.md`
-> empty (byte-identical), confirming requirement 3's no-retroactive-fix
constraint held.
