---
kind: scout-brief
subject: issue-122
produced_by: implementation
---

# Scout brief — issue-122

Mode: 2 parallel WebSearch angles in one turn (by-practice: single-source-
of-truth vs. duplicated-rule documentation conventions; by-analogy:
when a CI/pre-commit hook's rule belongs in contributor-facing docs vs.
only in the hook's own error message), one round. Judged saturated after
round 1 — the internal precedent (issue-106's identical mirror move,
already deeply read in the survey) already supplies the concrete shape;
external results converged on the same tension the issue's own
constraints already resolve, so a second round was judged unlikely to
change any build decision. This is an internal governance/tooling
convention with no external product exemplar to clone — the field
surveyed is developer-tooling practice, not a competing product
category.

Must-bes the field converges on:
- Single-source-of-truth: maintain one authoritative statement of a rule
  and reuse it, rather than letting copies drift (Wikipedia's SSOT entry;
  Paligo's content-reuse framing). This is the risk a `directive.sh`
  mirror runs if left unbounded — restated wording of the same rule,
  editable independently of the contract, is exactly the drift SSOT
  warns against.
- The opposing, equally-attested pull: a rule that is only discoverable
  by hitting an enforcement failure produces a documented DX gap —
  Docsie's write-up on documentation linting names this directly ("the
  knowledge is locked inside [material nobody consults] when they're
  staring at a failed lint check"), and the pre-commit/git-hooks sources
  converge on progressive error-message detail (name the rule, not just
  "a rule was violated") as the baseline, with proactive documentation
  as the layer above that baseline for rules contributors hit often.

Performance axis this fix competes on: SSOT/no-duplication vs.
upfront-discoverability-for-frequently-hit-rules. The field does not
resolve this tension with one universal answer — it is a judgment call
scoped by "how often is this rule actually hit," which is exactly the
axis issue #122's own requirement 2 already picks a position on ("게이트가
반복적으로 잡는 규칙만 directive 에 미러한다").

Adopt: treat `directive.sh`'s mirror as a *reader-convenience pointer to
still-canonical contract text*, not a second canonical copy — the
contract section stays the rule's authoritative statement (unchanged by
this issue), `directive.sh` gets one short paragraph restating its
consequence, which is the same shape §22's mirror already used and is
consistent with SSOT (one canonical source, one bounded reuse site, not
free copies). Bound future growth with an explicit criterion
("repeatedly caught" — i.e. observed gate friction, not anticipated
friction) rather than leaving every future contract section's mirror-or-
not decision to individual judgment.
Skip: building any mechanism that keeps the two texts in sync
automatically (e.g. generating `directive.sh`'s heredoc from the
contract file) — no source in this sweep suggested tooling-level sync
enforcement for a two-file, low-change-frequency pair, and the issue's
own constraints already reject an adjacent form of automation (auto-
attaching the trailer) for a related reason (goal is session awareness,
not mechanical patching).

Gap line: the current state already has the enforcing half
(`trailer-gate.sh`) and the authoritative half (contract §13) — it is
missing only the reader-facing "first thing a session sees" half, which
is precisely what `directive.sh` already supplies for `board-gate.sh`
and, since issue-106, for the headless-delegation rule. Requirement 2's
anti-bloat principle is the one piece the field sweep found no existing
internal statement of at all (survey: zero hits for any bloat/criterion
language across `directive.sh`, the contract, and `docs/handbooks/`).

Sources:
- https://en.wikipedia.org/wiki/Single_source_of_truth
- https://paligo.net/blog/content-reuse/what-is-single-source-of-truth-ssot/
- https://www.docsie.io/blog/glossary/documentation-linting/
- https://readme.com/resources/helpful-api-error-messages
