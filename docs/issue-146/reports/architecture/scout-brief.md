---
kind: scout-brief
subject: issue-146
produced_by: architecture
---

# Scout brief — issue-146

Mode: batched-sequential (2 WebSearch calls in one turn, plus the
current-state survey's internal precedent read first per survey-first
order). 1 sweep stage, 1 judge point, no deepening round needed — the two
searches converged on the same category and the internal precedent
(`stub-check.sh`, `compliance-check.sh`) already fixes the execution
model, so a further round would not change any build decision (saturation
reached at stage 1).

## Category and must-bes

The field this belongs to is **doc-code drift detectors** (a code anchor
paired with a doc anchor, flagged on divergence), not semantic-consistency
checkers. Must-bes observed across exemplars:
- Pair a code-side anchor with a doc-side anchor explicitly, don't infer
  pairing by proximity or naming convention alone (Drift/VSCode: pairs
  doc blocks with code anchors).
- Run at a defined trigger point (commit/CI), not only ad hoc (DocSync:
  pre-commit hook, catches drift "immediately").
- Stay on parse/structure, not semantics: "static analysis tools can
  detect the absence of documentation, they cannot evaluate its semantic
  consistency" — the explicit boundary this class of tool accepts.

## Performance axes

- **No network calls / no LLM dependency** (DocSync: tree-sitter parsing,
  "never makes network calls") vs. LLM-based semantic checkers (Semcheck).
  The gate-literal↔prose tie #146 asks for is checkable by pure string
  presence — no semantic judgment needed to know whether a literal a gate
  can deny on appears anywhere in the prose a role reads.
- **Fails at the earliest possible trigger point** (pre-commit/CI) vs.
  discovered at runtime (the #140-fixed staircase — the gate itself was the
  detector, at exactly the point a role got denied).

## Adopt / skip

- **Adopt**: mechanical anchor-pairing, checked in CI, no semantic
  judgment attempted. This matches the issue's own framing exactly ("a
  test that... extracts its literal needles and asserts each appears in at
  least one injected prose surface").
- **Skip**: LLM-based semantic-alignment checking (Semcheck-class tools).
  Explicitly out of scope — the issue asks for a *mechanical* check;
  reaching for semantic judgment here would also reintroduce the
  nondeterminism gates are built to avoid (see gate-lib.sh's fail-closed
  philosophy).

## Gap line

The current state (see survey.md) already has the CI *execution model*
(stub-check.sh/compliance-check.sh: canon script referenced, not vendored,
scoped by hooks.json registration) — that must-be is already met. It is
missing the *anchor-pairing* must-be entirely: nothing today extracts gate
literals as data, nothing extracts prose-surface text as data, nothing
joins them. That gap is this proposal's actual scope.

## Sources
- [Drift (VSCode) — drift-vscode](https://github.com/pallaprolus/drift-vscode)
- [DocSync — Living Documentation for Your Codebase](https://docsync-1q4.pages.dev/)
- [Stop Documentation Drift with Kiro (Medium)](https://medium.com/@timawang/stop-documentation-drift-with-kiro-keep-code-and-docs-in-sync-to-ship-faster-79e0a644e1bc)
- [Semcheck — code/spec alignment via LLM](https://www.xugj520.cn/en/archives/ai-code-documentation-sync-tool.html)
