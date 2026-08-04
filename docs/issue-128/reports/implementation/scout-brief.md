---
kind: scout-brief
subject: issue-128
produced_by: implementation
---

# Scout brief — issue-128

Non-product deliverable (a citation-convention decision among three named
candidates). Two stages: reused `docs/issue-100/reports/implementation/scout-brief.md`
(same repo, same structural problem — "a record committed in the same
commit as the artifact it describes cannot cite that commit's own final
sha" — one prior sweep round, two parallel `WebSearch` angles) as stage 1,
then ran one deepening round of three parallel `WebSearch` calls targeting
what #100's brief did not cover: a literal "same-commit" self-reference
marker convention, and whether splitting one transaction into two commits
(candidate (b)) is an established discipline anywhere. Genuine parallel
dispatch both rounds (multiple `WebSearch` calls issued in the same turn).
Judged sufficient at judge point 1 — the deepening round surfaced no
convention beyond what #100's brief already established, and the git-split
literature treats commit-splitting as a one-off history-cleanup operation,
not a per-transaction discipline — so no further round was run.

## Must-bes the field assumes

- ADR-shaped conventions never cite a decision record's own containing
  commit's sha; they identify by a stable symbolic key, never a
  self-referential hash. [reused from #100's brief — ADR templates overview]
- Where a workflow genuinely needs "the sha of what was just committed,"
  the working pattern is always a *second, later* step reading it back
  (`git rev-parse HEAD` / `github.sha`) and threading it forward — never
  inline in the same commit. [reused — GitHub Actions commit-sha discussion]
- No indexed source documents a literal "same-commit"/"N/A"/"self" marker
  as an established ADR or git convention for this exact case — this
  round's three searches returned only generic ADR/commit-splitting
  material, nothing naming the specific marker. Absence noted, not treated
  as a finding against it.

## Performance axes

- Auditability without a second actor (can a reader resolve the citation
  from the one commit that exists at write time, same axis #100 used).
- Session-discipline load: does the convention require a session to
  remember an extra manual step (a later amend, a second commit) every
  single phase-1, the exact failure mode already observed 3x for the
  informal amend convention.

## Adopt / skip

- Adopt: a stable symbolic marker over a self-referential sha or an
  unenforced second-step convention — matches #100's own adopted pattern
  and this round found no counter-evidence.
- Skip: treating commit-splitting (candidate (b)) as a low-risk fix — the
  general git literature on splitting commits (`git rebase -i` + `reset` +
  re-commit) frames it as an occasional history-cleanup technique a session
  performs deliberately, not as a routine per-transaction discipline;
  adopting it as standing phase-1 practice would be a first in this repo
  (survey: every sampled phase-1 commit bundles survey + proposal in one),
  carrying the same "session must remember to do the extra step" risk class
  already responsible for 3 recurrences under candidate (c)'s informal form.

## Gap line

The field's must-be ("don't self-cite an in-progress commit; use a stable
symbolic identity instead") is already the shape #100 adopted for
`code_under_review` in this same repo; the gap for `upstream[].sha`
specifically is that no symbolic literal has been named for it yet, and
that §12's staleness-comparison rule (a consumer #100's field never had)
has no stated exemption for one. This is a missing convention plus a
missing exemption clause, not a missing capability.

## Segment fit

Internal style-guide/lint-rule decision, same segment as #100 — the bar is
whether the chosen convention holds against how disciplined engineering
orgs solve the same self-reference problem, which the reused ADR/CI
precedent still supports.

Sources:
- https://adr.github.io/adr-templates/ (reused from #100)
- https://github.com/architecture-decision-record/architecture-decision-record/blob/main/README.md (reused from #100)
- https://github.com/orgs/community/discussions/63961 (reused from #100)
- https://www.kenmuse.com/blog/the-many-shas-of-a-github-pull-request/ (reused from #100)
- https://dev.to/thelarkinn/split-a-commit-into-2-commits-with-git-rebase-31ee
- https://thoughtbot.com/blog/splitting-a-commit
- https://www.martinfowler.com/bliki/ArchitectureDecisionRecord.html
