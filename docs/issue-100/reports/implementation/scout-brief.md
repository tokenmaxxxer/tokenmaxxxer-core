---
kind: scout-brief
subject: issue-100
produced_by: implementation
---

# Scout brief — issue-100

Non-product deliverable (a documentation/citation convention plus one
gate check); scouted against how comparable systems solve "a record
committed in the same commit as the artifact it describes cannot cite
that commit's own final sha." One stage: parallel sweep, two angles,
judged sufficient at the first judge point (the underlying constraint is
a structural git fact, not a matter of taste, and both angles converged
on the same answer as the current-state survey's own reasoning) — no
deepening round run. Mode: two `WebSearch` calls issued in the same turn
(genuine parallel dispatch, not serialized).

## Must-bes the field assumes

- ADR-shaped conventions never cite a decision record's own containing
  commit's sha; they identify a decision by a stable symbolic key (an
  `ADR-NNN` number or file slug) and let issue trackers/commit messages
  point at *that*, never the reverse. [ADR templates overview]
- Where a workflow genuinely needs "the sha of what I just committed,"
  the working pattern is a **second, later step** reading it back via
  `git rev-parse HEAD` (or `github.sha`) and threading it forward as
  output — always after the fact, in a separate write, never inline in
  the same commit. [GitHub Actions commit-sha discussion]

## Performance axes

- Auditability without a second actor: can a reader resolve the citation
  using only the one commit that exists at write time?
- No new machinery: does it need a bot/second commit/merge-time rewrite
  step this repo doesn't otherwise have?

## Adopt / skip

- Adopt: symbolic/file-identity citation over self-referential sha —
  matches both the ADR precedent and this repo's own pre-issue-90 records
  (`docs/issue-88`, `docs/issue-20`).
- Skip: "have the merge fill in the real sha" — every real-world version
  of that pattern requires an out-of-band second write after the
  triggering commit (a CI job, a bot amend), which this repo's contract
  doesn't grant to any role over another role's already-merged record,
  and which would leave the sha unresolved for exactly the pre-merge PR
  review window `closed_checks` cite-and-skip (§16) needs it for.

## Gap line

The field's must-be ("don't self-cite an in-progress commit's sha") is
already met by this repo's *older* records (issue-88, issue-20) and only
regressed starting issue-90; the gap is a lapsed convention, not a
missing capability — which is why the fix is a documented, gate-checked
decision rather than new tooling.

## Segment fit

One line: this is closer to an internal style-guide/lint-rule decision
than a product surface — the bar is "does the chosen convention hold up
against how disciplined engineering orgs solve the same self-reference
problem," which it does.

Sources:
- https://adr.github.io/adr-templates/
- https://github.com/architecture-decision-record/architecture-decision-record/blob/main/README.md
- https://github.com/orgs/community/discussions/63961
- https://www.kenmuse.com/blog/the-many-shas-of-a-github-pull-request/
