---
proposal: docs/issue-157/proposals/2026-08-08-observe-pr-158-issue-157-execution.md
---

# Hunt record — observe-pr-158-issue-157-execution

## after-proposal — stance 0: assume the gate just touched is bypassable — find the bypass

Verdict: NO FINDING
Seed: the pair of gates named in the dispatch — (a) core/hooks/record-fields-gate.sh's placeholder_shas sha check as modified by 7cd6392e5fc0d3509bd3228232c2ba0b43b58f4d, tested against the three uncommitted docs (docs/issue-157/reports/execution-observation/survey.md, docs/issue-157/reports/execution-observation/scout-brief.md, docs/issue-157/proposals/2026-08-08-observe-pr-158-issue-157-execution.md); (b) the phase-1 no-verdict gate, tested by grepping those same three files for verdict-shaped language.
cap_seconds: 60
tier: default (size:docs-only)
diff_stat_lines: 613 (3 new untracked files: survey.md 260, scout-brief.md 84, proposal 269 — no deletions)
started_at: 2026-08-08T04:03:28Z
ended_at: 2026-08-08T04:10:30Z

### What was checked

(a) sha gate: confirmed byte-exact that all three files open with a `---`
line at offset 0 (`od -An -tx1 -N 20 <file>` -> `2d 2d 2d 0a ...` for all
three, no BOM, no leading blank line), so the F1 whole-document fallback
branch is provably unreached for them. Fed the actual proposal file's real
content through the real gate as a synthetic Write payload
(`CLAUDE_ROLE=execution-observation CLAUDE_PROJECT_DIR=<repo>
bash core/hooks/record-fields-gate.sh < payload.json`, tool_input.file_path
= the proposal's own path, content = the file's current bytes) -> exit 0,
no denial, matching the proposal's "gate-safe self-citation" claim. Grepped
all three files for a `sha:` field line at any indentation: only the two
`sha: same-commit` lines in the proposal's frontmatter exist; no
non-conforming spelling appears anywhere, in or out of frontmatter, in
field shape.

Noted but not a counterexample: `RECORDS_RE` (`^docs/issue-[0-9]+/reports/%s\.md$`)
does not match `docs/issue-157/reports/execution-observation/survey.md` or
`.../scout-brief.md` (they sit one directory below the record path), so
`placeholder_shas` is never invoked on those two files at all -- an even
stronger form of "the fallback branch is never reached" than the proposal
claims, not a contradiction of it, and neither file carries a sha: line
regardless. Tried to construct a premature-non-greedy-close bypass (a
frontmatter block containing an embedded unindented `---` line before a
trailing `sha:` field, which `(.*?\n)` would stop at, leaving the real
`sha:` line unscanned in the discarded remainder) -- real in principle, but
it reproduces the pre-existing, documented, already-disclosed #154
frontmatter-only-scope trade-off, not a hole introduced by 7cd6392, and
none of the three actual files have any embedded `---` inside their
frontmatter to trigger it.

(b) phase-gate: grepped the three files for verdict-shaped predicates
(is/meets/satisfies/compliant/discharges/holds/fails/passes/overstates,
"already", "clearly", etc.). Every one of survey.md's ten unknowns (U1-U10)
is explicitly closed with "Open question: ...". The one declarative-looking
line found, scout-brief.md:71 ("Current state already meets must-be 4's
*form* ... and must-be 2's *disclosure* ..."), is not novel: it is the same
"Gap line" idiom, near-verbatim, as the precedent scout-brief
docs/issue-153/reports/execution-observation/scout-brief.md:53-59
("Current state already meets must-be 3 ... and partly must-be 2 ...").
That precedent artifact was accepted under issue-153 (merged as PR #156),
so this is an established convention of the scout-brief deliverable kind
(describing which analytical lenses the sweep's own evidence already
covers, not a verdict on the audited PR's compliance), not a defect
specific to this transition. The proposal itself never cites this Gap
line's "meets" conclusion as settled; every place it references a must-be
it reframes as an open verification task (e.g. proposal:172-174 treats
must-be 4 as "verified one by one", not pre-concluded).

No reproduction contradicts either half of the proposal's claim for the
three files actually written this turn. Not pursued further given the cap.

## before-landing — skipped

Skip reason: **docs-only, no before-landing dispatch.** Every path in this
transition's write set is under `docs/` (`docs/issue-157/reports/execution-observation/survey.md`,
`docs/issue-157/reports/execution-observation/scout-brief.md`,
`docs/issue-157/proposals/2026-08-08-observe-pr-158-issue-157-execution.md`,
and this record), which is the warrant directive's docs-only fast path.
Recorded here rather than left silent, per the same mandatory-skip-line
shape the scout directive uses.

## Dispatch-mode note

`.warrant-hunt.count` does not exist in this worktree, so the rotation
index could not be read from it; stance 0 was used, matching this role's
own precedent for the same transition on issue-153
(`docs/reports/2026-08-08-hunt-observe-pr-154-sha-scan-scope.md`, stance 0).

The dispatch above was run synchronously rather than with
`run_in_background: true`. This session is headless and single-shot, and
role-handoff contract v3 §22 prohibits ending a turn having delegated work
whose result was not consumed in that same turn; §22 is declared to take
priority over the warrant directive's background-dispatch instruction, so
the result was awaited and acted on before this commit.
