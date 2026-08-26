---
proposal: commit 51cca43 (no proposal file exists for this delivery — build-now bypass, contract v3 s19a)
---

# Hunt record — issue-328 build-now delivery

## before-landing

Stance taken (index 0 of mandatory rotation): "assume the gate just touched is bypassable — find the bypass."

Diff/commit examined: 51cca43 ("issue-328: investigation record — skill-mount compatibility confirmed by real load, missing-entry fail-open documented, physical data move blocked by cross-repo boundary + no role-to-skill selection convention"). One file, docs/issue-328/reports/implementation.md, 327 insertions, purely additive docs. No hooks/, gates/, or source file touched.

No gate file was touched by this diff, so applied reading (b) from the dispatch prompt: checked whether the record's own derived:/canonical: citations could be gamed with fabricated-looking evidence that record-claim-guard.sh (or a human reviewer) would accept without the commands having actually been run.

What I checked:
- Read core/hooks/citation-gate.sh:80-131 (the `deny()` function and the missing-entry short-circuit at lines 89-92) and diffed it against the report's `canonical: core/hooks/citation-gate.sh:89-92` block (report lines 82-87) — line numbers and quoted source text match the real file exactly.
- Cross-checked the report's Finding 2 claim (fail-open on missing role/config row, gate exits 0 via `deny()`'s issue-282 DEMOTE advisory-only design) against the actual `deny()` implementation (lines 65-78: always `sys.exit(0)` after printing to stderr/emitting additionalContext) — the report's "exit=0" alongside a printed violation message is correct current behavior, not a misrepresentation; the record itself flags this as a "Silently-Absorbed pattern" rather than hiding it.
- Attempted to locate the cited skill-registry config files (`/home/jwjung/skill-registry/skills/architecture-decomposition-strategy/citation-config.json`) to re-run one `derived:` command verbatim; the file no longer exists. This is consistent with the record's own documented cleanup step (report line 268: `git checkout -- . && git clean -fd architecture-decomposition-strategy content-design-operational-playbook`), not evidence the citation was fabricated.
- No record-claim-guard.sh exists anywhere on the filesystem (searched via `find`), so there is no live citation-verification gate for this specific bypass mechanism to be checked against in this repo state.

No reproduction obtained within the docs-only cap. The cited line numbers/source text are independently verifiable against the current core/hooks/citation-gate.sh and match; no fabricated-looking or unverifiable `derived:`/`canonical:` claim was found.

Verdict: NO FINDING
Seed: commit 51cca43, docs/issue-328/reports/implementation.md (all citations therein)
cap_seconds: 60
tier: size:docs-only
diff_stat_lines: 327 insertions, 0 deletions (1 file)
started_at: 2026-08-26T00:00:00+09:00 (approx, session start)
ended_at: 2026-08-26T00:01:30+09:00 (approx)
