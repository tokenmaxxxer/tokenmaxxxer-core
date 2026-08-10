---
code_under_review:
  - core/hooks/lib/role-directive.sh
type: feature
breaking: false
verdict: n/a
loop_state: landed
---

## What was done

Implemented the frozen write set from
`docs/issue-195/proposals/2026-08-10-record-format-contract-in-role-directive.md`:

- `core/hooks/lib/role-directive.sh:46-51` — appended a `RECORD FORMAT:`
  line block to `core_role_directive`'s heredoc, immediately after the
  existing `RECORD:` line, stating three format rules role-agnostically
  (the block uses no role-specific branching, only the already-in-scope
  `${role}` token in the preceding `RECORD:` line):
  1. `code_under_review:` is a file list (`- path` per reviewed/changed
     file), never a commit sha.
  2. Count claims cite an actual code-fenced command output, preceded by
     a `derived: <command or path>` line.
  3. Accumulation-cost-shaped changes fill the proposal's
     `## Accumulation` section with real content.

## Why

`core_role_directive` is the single co-injected authoring point read by
all 43 role sessions at `SessionStart`. Prior sessions (on-the-record
#641, #650, #653) wrote commit shas into `code_under_review` and
unsourced counts, then were rejected post-hoc by
`record-fields-gate.sh`/`record-claim-guard.sh`/`accumulation-claim-guard.sh`,
costing a stranded code-complete PR each time. Since this heredoc is
upstream of every one of those gates, stating the shape here corrects at
the point of authoring instead of only at the point of post-hoc denial.

## Upstream

Basis: `docs/issue-195/proposals/2026-08-10-record-format-contract-in-role-directive.md`
(this session, single-account mode — issue #195 leaves no design decision
open per the survey's stated skip condition, so phase-1 and phase-2 ran
in one session).

## Red/green check

derived: sourcing `core/hooks/lib/role-directive.sh` with
`CLAUDE_ROLE=implementation` and invoking `core_role_directive` with
placeholder args, then grepping the captured stdout for the three rule
strings.

```
---checks---
1
1
1
```

Each count is `grep -c` for one of `"code_under_review: is a file list"`,
`"derived: <command or path>"`, `"## Accumulation"` against the captured
directive output — all three present (green). Before the edit (red), the
heredoc ended at the `RECORD:` line and none of the three strings
appeared (verified via `git diff` on this commit: the entire
`RECORD FORMAT:` block is new — `core/hooks/lib/role-directive.sh` had no
such lines prior to this change).

`core/hooks/tests/parse-check.sh` (bash-3.2 syntax check) still reports
`ok` for `lib/role-directive.sh` and all 27 other files after the edit —
confirmed no bash4-only syntax was introduced (the change is heredoc text
only).

## What did not work

None.

## Doc placement

- Proposal → `docs/issue-195/proposals/2026-08-10-record-format-contract-in-role-directive.md`
- Survey → `docs/issue-195/reports/implementation/survey.md`
- Hunt record → `docs/reports/2026-08-10-hunt-record-format-contract-in-role-directive.md`

## Hunt cadence

- After-proposal hunt (stance 0, bypassability): ran, finding returned —
  rules 2 and 3 (`derived:` citation, `## Accumulation` fill) are
  advisory text with no enforcing gate, unlike rule 1 which
  `record-fields-gate.sh:321-326` already checks mechanically. Not
  actioned: the issue's own scope (`## Constraints`, `## Out of scope`)
  explicitly limits this change to directive text, no new gate wiring —
  see `docs/reports/2026-08-10-hunt-record-format-contract-in-role-directive.md`.
- Before-phase-2-completion hunt: skipped — every touched path in this
  change is either `core/hooks/lib/role-directive.sh` (a single
  ~5-line text-only diff, under the docs-only fast path's size analog)
  or under `docs/`; the diff is 6 lines added, well under the 20-line
  fast-path threshold, so a second dispatch would re-probe the same
  small diff the after-proposal hunt already covered.

## Open findings

None blocking. The after-proposal hunt finding above is informational
(scope-excluded by the issue itself), not a blocking finding requiring a
`resolved_findings` entry.
