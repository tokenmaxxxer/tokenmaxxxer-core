# Scout brief (issue-34)

Mode: single-round parallel WebSearch sweep, 3 angles in one turn (ADR
alternatives; RFC considered-alternatives/traceability; PR-template
checklist/failure-signal). Stopped after stage 1 — saturation reached
immediately: all three angles converge on the same well-established
format, no further deepening changes any build decision.

Must-bes (Kano) the field converges on:
- Alternatives get one line each: "[option] rejected: [reason]" — not a
  narrative comparison. (ADR sources)
- Checklist/traceability items are enumerable and mapped 1:1 to what
  shipped, so drift is mechanically checkable, not just narrated.
  (RFC/PR-template sources)
- A failure/regression signal is a named, checkable condition, not
  "reviewer said ok" circularity. (PR-template sources)

Performance axes: (1) conciseness of alternatives (one line, not essay),
(2) mechanical checkability of the checklist (grep/diff-able, not prose
judgment), (3) named failure condition vs restated success criteria.

Adopt: one-line rejection format for alternatives (ADR convention);
enumerable checklist item wording that phase 2 can literally check off
per item (RFC/PR-template convention).
Skip: automated CI enforcement of the template (PR-template sources'
"validation job fails the build") — out of scope, this repo's gate is
human-review-based (contract s19), not CI-based; would be a separate,
much larger proposal.

Segment fit: issue-34 is a contract-wording amendment, not a product
surface — the closest field analog is process/documentation tooling
(ADR, RFC, PR templates), not end-user products. Bar copied: structural
conciseness and mechanical traceability, not the tools themselves.

Gap line: current contract s19 proposal bullet already requires "write
surface / out of scope / success judgment" (a success framing) but has
no enumerable-clause checklist, no alternatives field, and no distinct
failure-signal field — exactly the three gaps the field's must-bes cover
and issue #34 names.

Sources:
- https://medium.com/@janmaleky/architecture-decision-records-adr-a-practical-template-for-system-design-exams-cd216bf275e8
- https://www.hashicorp.com/en/how-hashicorp-works/articles/rfc-template
- https://www.lambrospetrou.com/articles/rfc-template/
- https://www.pullchecklist.com/posts/github-pull-request-template-checklist
- https://axolo.co/blog/p/part-3-github-pull-request-template
