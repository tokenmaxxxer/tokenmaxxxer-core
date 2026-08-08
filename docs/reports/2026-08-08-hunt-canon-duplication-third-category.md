---
proposal: docs/issue-185/proposals/canon-duplication-third-category.md
---

# Hunt record — canon-duplication-third-category

## after-proposal — stance 1: assume this change and another plugin's rule cancel each other — find the pair

Verdict: NO FINDING
Seed: docs/issue-185/proposals/canon-duplication-third-category.md (proposed gate_directive_custom_by_convention in core/hooks/lib/gate-lib.sh, wired into stub-check.sh and compliance-check.sh --canon-duplication)
cap_seconds: 60
tier: default (docs-only diff, size tier: docs-only)
diff_stat_lines: N/A (proposal doc only, code not yet built)
started_at: 2026-08-08T00:00:00Z
ended_at: 2026-08-08T00:01:00Z

Searched for other rules that scan directive.sh across the repo
(handbook-trigger-gate.sh's gate-prose-coverage-check.py, run-role-gates-tests.sh,
run-fleet-scan-tests.sh) that could conflict with the proposed needle check on
`core_role_directive`/`gate_[A-Za-z_]+` tokens. The only sibling directive.sh-scanning
rule found is gate-prose-coverage-check.py, which requires directive.sh to contain
prose needles extracted from sibling gate scripts' has_any()/dict-key/regex-field
literals (e.g. "what was done") — unrelated in shape to the gate_-prefixed function
token needle the proposal checks for. No pair of rules that cancel or conflict on
the same input was found; stopping without a reproduction.
