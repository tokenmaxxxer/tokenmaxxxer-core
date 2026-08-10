---
proposal: docs/issue-195/proposals/2026-08-10-record-format-contract-in-role-directive.md
---

# Hunt record — record-format-contract-in-role-directive

## after-proposal — stance 0: assume the gate just touched is bypassable — find the bypass

Verdict: FINDING — two of the three new format rules (derived: command-cite for count claims, ## Accumulation section fill) have no enforcing gate anywhere in the repo; only the pre-existing code_under_review-sha rule is code-checked (in core/hooks/record-fields-gate.sh). role-directive.sh is a SessionStart heredoc printed as advisory text with no follow-up validation, so an agent can write a record violating rules (2) and (3) and nothing blocks it — silent bypass by default, not requiring any env var.
Kind: silent-failure
Seed: docs/issue-195/proposals/2026-08-10-record-format-contract-in-role-directive.md; core/hooks/lib/role-directive.sh
cap_seconds: 90
tier: default
diff_stat_lines: 0 (pre-implementation; proposal only)
started_at: 2026-08-10T00:00:00
ended_at: 2026-08-10T00:01:20

### Reproduce
```
grep -rln "derived:" core/  # empty: no gate checks for cited derived: output
grep -rln "Accumulation" core/hooks/*.sh core/hooks/lib/*.sh  # empty: no gate checks for filled Accumulation section
grep -rln "code_under_review" core/hooks/lib/*.sh core/hooks/*.sh  # only record-fields-gate.sh, and only for rule (1)
```

### Observed
Only rule (1) (code_under_review must be a file list) has a matching check in core/hooks/record-fields-gate.sh:321-326. No file in the repo greps for "derived:" or "Accumulation" as an enforcement target.

### Expected
If the proposal intends all three rules to be gate contracts (as implied by putting them in the same RECORD directive block as the already-enforced sha rule), rules (2) and (3) need a corresponding check in record-fields-gate.sh (or equivalent) — otherwise they are unenforced text that any agent can silently ignore.
