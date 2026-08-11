# Survey — issue-204

Scout skip: pure directive-text/gate-mirroring fix with the design already
decided by the on-the-record audit (row citations name the exact source
and target). No product-shaped decision is open — skip condition "spec
leaves no design decision open" applies.

## Where the shared role directive is assembled

`core/hooks/directive.sh` (this repo) is the SessionStart hook whose
heredoc is injected verbatim into EVERY role session as
`[core] Interaction protocol for role '<role>' (role-handoff contract
v3): ...` — confirmed by comparing its heredoc text against this
session's own second `<system-reminder>` above, which is a byte-for-byte
render of it with `${role}` substituted to `implementation`. This is the
"shared role directive (the text every role receives)" the issue names,
distinct from `core/hooks/lib/role-directive.sh` (the `core_role_directive`
helper each *rulebook's own* `directive.sh` sources for its four
role-unique paragraphs — YOU_DECIDE/USE_WHEN/PRODUCES/HAND_OFF). Rows
3/20 have no role-specific angle, so they belong in `core/hooks/directive.sh`
directly. Row 4/14 already exists, word-for-word, in the coding
rulebook's `USE_WHEN` block (see below) — promoting it means moving that
paragraph's substance into the shared file so every non-coding role gets
it too, not copying it into each rulebook separately.

`core/hooks/directive.sh:104-152` is the current heredoc body (interaction
protocol bullets, ending with the operational-surface-file rule and
`EOF`). New bullets append after the last one (`- A commit that stages an
operational-surface file...`) and before `EOF`.

Precedent for exactly this move: issue-203 added a staging-instruction
bullet to this same heredoc, with a paired test at
`core/hooks/tests/run-role-directive-staging-tests.sh` that runs the
hook with `CLAUDE_ROLE=implementation`, inspects the rendered heredoc
text via `case`, and includes an "empty-state" fixture assertion (a hand-
built fixture missing the instruction must fail the check). The new test
this proposal adds follows that same shape.

## Row 4/14 — existing source text (to promote, not duplicate)

`/home/jwjung/tokenmaxxxer/rulebooks/implementation-rulebook/coding/hooks/directive.sh`
(the `coding` plugin's own directive, sourced from a sibling repo — read
locally for reference; not part of this repo's write set), `USE_WHEN`
variable, closing paragraph:

```
ISSUE REFERENCE, phase-dependent: the phase-1 proposal PR references its
issue as plain #n in the body — never Closes/Fixes/Resolves #n. Merging
a phase-1 PR must not auto-close the issue; only the phase-2 delivery PR
carries Closes #n. If a phase-2 session finds its issue already closed
with no delivery landed, that is an anomaly to report, not a completed
task — do not silently exit.
```

Gate mirror (on-the-record, not this repo — read-only reference):
`.../on-the-record/hooks/pr-preflight.sh:226-250` (`check_body`) — phase1
requires a plain `#<issue>` reference and explicitly forbids
Closes/Fixes/Resolves; phase2 requires `Closes #<issue>` (or Fixes/
Resolves). This confirms the rule text above already matches what the
gate checks — safe to promote verbatim in substance.

Every other rulebook's own `directive.sh` (product-discovery, qa,
review, verify, architecture, execution-observation, etc.) has no
paragraph covering this — the audit's row 4/14 gap. Since
`core/hooks/directive.sh` is shared by construction, adding it there once
closes the gap for all of them without editing each rulebook.

## Row 3 — spec-index regeneration

Gate: `.../on-the-record/hooks/spec-index-preflight.sh` (read-only
reference, not this repo) — `INDEX_REL = "docs/specs/reconciled-index.md"`;
when a staged spec file's content hash no longer matches the row recorded
in `docs/specs/reconciled-index.md`, the gate denies with: "staged
content changed for tracked spec file(s) [...] but
docs/specs/reconciled-index.md was not updated to match in the same
staged set. Regenerate with `python3 gates/spec_index.py --update`,
stage the updated index, and retry the commit." No existing bullet in
`core/hooks/directive.sh` or any rulebook directive mentions this file or
command — confirmed gap.

## Row 20 — pytest SKIPPED / pass-count fidelity

Gate: `.../on-the-record/hooks/role-test-claim-guard.sh` (read-only
reference, not this repo), a Stop-hook structural check on a role's own
reply text:
- if pasted pytest output contains `SKIPPED` lines and the prose
  separately claims a clean pass (모두 통과/all tests pass/clean pass)
  without mentioning skips anywhere in the prose, it is flagged
  (issue #334 mirror).
- if a pasted pytest summary line says `N passed` and the prose
  separately hand-types a different pass count, it is flagged (issue
  #435 mirror: "count must be derived from the real run, not retyped").
No existing bullet states this. It is a plain-text rule mirrorable
without a gate script (Stop hooks only inspect prose after the fact),
same as rows 3 and 4/14.

## Write set actually needed

- `core/hooks/directive.sh` — three new bullets in the existing heredoc.
- `core/hooks/tests/run-directive-shape-tests.sh` — new test asserting
  the three shapes are present (mirrors the issue's Acceptance test
  requirement and the run-role-directive-staging-tests.sh precedent,
  including an empty-state fixture per bullet).
- `core/hooks/tests/run-all.sh` (or equivalent aggregator, if one exists)
  — wire the new test file in if the aggregator lists test files
  explicitly.
- `docs/issue-204/reports/implementation/survey.md` (this file),
  `docs/issue-204/proposals/*.md` — phase-1 homes.

No new dependency, no env var, no migration, no dependency-manifest
change — pure bash heredoc text + bash test script, matching the
existing tooling in `core/hooks/`.

## Alternative considered

Add the three shapes to `core/hooks/lib/role-directive.sh`'s
`core_role_directive` function body (the common four-paragraph
boilerplate every rulebook sources) instead of `core/hooks/directive.sh`.
Rejected: `core_role_directive`'s body is the *rulebook-authored*
per-role content (YOU_DECIDE/USE_WHEN/PRODUCES/HAND_OFF passed in as
arguments) — the function itself only renders boilerplate framing
(preamble, RECORD/RECORD FORMAT footer) around those arguments, not
role-independent protocol rules. `core/hooks/directive.sh`'s own heredoc
is the file core (not a rulebook) already uses for role-independent
protocol bullets (branch-per-issue, phase gating, staging instructions
from issue-203) — the correct, existing home for more of the same kind.
