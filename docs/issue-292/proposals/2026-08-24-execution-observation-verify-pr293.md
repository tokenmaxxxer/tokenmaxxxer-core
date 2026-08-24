---
status: proposed
files:
  - docs/issue-292/reports/execution-observation.md
---

# Proposal: execution-observation record verifying issue-292/implementation (PR #293)

## Request

Fill in the pre-written execution-observation record skeleton at
`docs/issue-292/reports/execution-observation.md` (issue #2135's
skeleton format) with an independent verification of the work already
landed on `issue-292/implementation` and opened as PR #293
("issue-292: document shell-variable-split Bash-path-extraction gap as
accepted, not fixed"): that PR's own claim is that every
`PreToolUse`-wired gate in this repo which extracts a Bash command's
target path via static regex was enumerated, none was code-fixed, and
the gap is instead accepted and documented in a new decision doc plus a
handbook section.

## Constraints

- Write only `docs/issue-292/reports/execution-observation.md` this
  phase — no code, no other role's record, no other issue's tree.
- The record must use the pre-written skeleton's frontmatter (`issue`,
  `role`, `loop_state`, `upstream`, `subject`, `test`, `result`,
  `assertedBy`) and its five section headings, in the skeleton's own
  order — this proposal does not introduce a new record shape.
- PR #293 is still open, not yet merged to main; this record observes
  the PR's content as of its current commit, not a moving target — if
  PR #293 changes materially before this record's phase-2 work starts,
  that basis is stated explicitly rather than silently re-read.

## Rationale

Considered writing a full current-state survey
(`docs/issue-292/reports/execution-observation/survey.md`) before this
proposal, per the standard survey-before-proposal ordering. Rejected:
there is no open design decision here to survey toward. The record's
structure is fixed by a pre-written skeleton (issue #2135), and the
subject matter — PR #293's diff, its decision doc, and its own
implementation record — is a closed, already-written set of artifacts
to read and cross-check, not a space of implementation alternatives to
weigh. Writing a survey file here would restate the same diff read the
record itself performs, adding a file without adding information. This
falls under the survey-order-directive's own "the spec leaves no design
decision open" skip condition, named here per that directive's
requirement that the skip be stated, not left implicit.

## What will be done

Re-derive, from the actual gate source (not just PR #293's own
narration), whether `core/hooks/approval-gate.sh`,
`core/hooks/board-gate.sh`, `core/hooks/record-shape-gate.sh`,
`core/hooks/ordering-gate.sh`, and `warrant/hooks/scope-gate.sh` match
the vulnerable/not-vulnerable classification PR #293 claims for each;
confirm PR #293's "no `core/hooks/*` or `warrant/hooks/*` behavior
changed" claim against its actual diff (`docs/decisions/...`,
`docs/handbooks/gate-house-standard.md`, and its own
`docs/issue-292/reports/implementation.md` — three files, docs-only);
record a concrete verdict (pass/fail per claim, not just a restatement)
in the skeleton's `## What was done`, `## Why`, `## Upstream basis`,
`## Open findings`, and `## Next steps` sections; set `result:` and
`assertedBy:` frontmatter and move `loop_state` to this record kind's
terminal value once the verification is complete.

## Out of scope

- Re-opening or re-litigating PR #293's accept-vs-fix decision itself
  — that call belongs to issue #292/PR #293, not to this observation.
- Any gate or hook code change.
- Anything outside `docs/issue-292/reports/execution-observation.md`.

## How you'll know it worked

`docs/issue-292/reports/execution-observation.md` is filled in per the
skeleton with a stated, evidenced verdict on PR #293's two central
claims (gate-enumeration accuracy; no-enforcement-code-changed), citing
the actual gate source lines checked rather than only restating PR
#293's own text, frontmatter `result:`/`assertedBy:` set, and
`loop_state` at this record kind's terminal value.
