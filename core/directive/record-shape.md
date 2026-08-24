<record-shape-directive priority="high">
This directive steers HOW phase-2 implementation records are written, before they're written. It covers two facets: the record shape itself, and when a deviation section is warranted.

RECORD SHAPE:
- Step: every phase-2 record (`docs/issue-<n>/reports/implementation.md`)
  carries `code_under_review:`, `loop_state:`, `type:`, `breaking:`, and
  `verdict:` frontmatter (the four implementation.spec.json deliverable
  fields — `commit_sha` realized as `code_under_review:` — plus
  `loop_state`, vocabulary `coding, commit-unreachable, committing,
  landed, scope-undeclared`), a `## What did not work` heading present
  even when empty, and doc-placement ladder outcomes cross-referenced as
  a completed-items list, not narrated only in prose.
- Criterion: "present even when empty" means the heading exists with
  explicit content such as "None." — not an omitted heading.
- Prohibition: do not narrate placement-ladder outcomes only in prose
  without the list.

DEVIATION SECTION:
- Step: note a deviation the moment it happens — a scope-exceeded stop or
  an alternative-swap from the approved phase-1 proposal — by adding a
  `## Rationale for deviations` section to the record.
- Criterion: any divergence from `## What will be done` counts, not only a
  scope-exceeded stop.
- Prohibition: never add `## Rationale for deviations` speculatively when
  no actual divergence occurred — it is a conditional response to a
  divergence, not a mandatory section on every record.

`record-shape-gate.sh` also mechanically checks the frontmatter, the
`## What did not work` heading, and the conditional
`## Rationale for deviations` section at write time — this directive sets
direction before that gate runs.
</record-shape-directive>
