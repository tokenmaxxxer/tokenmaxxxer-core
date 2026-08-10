---
proposal: docs/issue-200/proposals/conflict-free-system-writes.md
---

# Hunt record — conflict-free-system-writes

## after-proposal — stance 3: assume the rule as written cannot hold — find the state nothing maintains

Verdict: FINDING — the re-keyed report path `docs/issue-<n>/reports/hunt-<slug>.md` depends on an "issue number" that no proposal schema or dispatch protocol actually stores; it is only ever guessed from a directory-naming convention that `warrant/hooks/directive.sh` itself does not follow in its own literal text, and item 4 of this proposal does not touch the part of directive.sh that documents the conflicting convention.
Kind: design-error
Seed: docs/issue-200/proposals/conflict-free-system-writes.md (item 3/4: "update the report-path line... from `docs/reports/<date>-hunt-<proposal-slug>.md` to `docs/issue-<n>/reports/hunt-<proposal-slug>.md`"; rationale claims "a hunter dispatch always knows its proposal's issue number (the dispatcher reads it from the branch/proposal path)")
cap_seconds: 60
tier: default
diff_stat_lines: 94 (docs-only, both new files)
started_at: 2026-08-11T00:00:00Z
ended_at: 2026-08-11T00:05:00Z

### Reproduce
```
grep -n 'files:\|status:\|issue' warrant/hooks/directive.sh   # frontmatter schema: status, files — no `issue:` field, ever
grep -n 'docs/proposals/' warrant/hooks/directive.sh           # line 24 & 63: the ONLY convention the file documents is
                                                                # docs/proposals/YYYY-MM-DD-<slug>.md and
                                                                # `Proposal: docs/proposals/2026-07-22-<slug>.md`
ls docs/proposals                                              # no such directory exists anywhere in the repo
```
This very dispatch is the reproduction of the failure mode: the proposal under test lives at
`docs/issue-200/proposals/conflict-free-system-writes.md`, but the dispatcher that sent this hunt told it (per
directive.sh's current, unmodified instructions) to write its record to the flat, non-issue-scoped
`docs/reports/2026-08-11-hunt-conflict-free-system-writes.md` — not `docs/issue-200/reports/hunt-....md`. The
"the dispatcher reads it from the branch/proposal path" claim in the proposal's rationale is not backed by any
rule directive.sh actually states: directive.sh's own frontmatter template has no `issue` field, and its own
literal documented proposal-path convention (`docs/proposals/YYYY-MM-DD-<slug>.md`) carries no issue number at
all. Item 4 of the proposal patches only "the matching path text (line 76) ... and the docs/reports/ reference,"
leaving lines 24/63 (the frontmatter template and commit-trailer example, which still say `docs/proposals/...`
with no issue number) untouched and self-contradictory with the new `docs/issue-<n>/reports/...` rule the same
file is being edited to state elsewhere.

### Observed
`ls docs/proposals` -> no such file or directory (the convention directive.sh documents as canonical does not
exist); `grep -n 'issue' warrant/hooks/directive.sh` before this proposal's line-76 edit returns nothing — no
field or mechanism carries an issue number for the hunter's report-path substitution to read.

### Expected
For "re-key hunt-report paths by issue number" to hold as a rule, the issue number has to be state something
maintains — either a frontmatter `issue:` field on the proposal, or a proposal-path convention directive.sh
itself unambiguously documents everywhere it mentions the proposal path (including lines 24 and 63, and the
commit-trailer example), not just the one line (76) the proposal's item 4 lists for editing.
