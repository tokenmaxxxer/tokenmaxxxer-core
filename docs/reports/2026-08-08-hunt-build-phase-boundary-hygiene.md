---
proposal: docs/proposals/2026-08-08-build-phase-boundary-hygiene.md
---

# Hunt record — build-phase-boundary-hygiene

## before-landing — stance 1: assume the rule as written cannot hold — find the state nothing maintains

Verdict: FINDING — F1's "checks that path against R4 ... and, if its own branch cannot write it" is phrased as a conditional, but under R4's actual implementation the condition is always true (never false) whenever F1 triggers, so no "can write it" branch ever exists to check against.
Kind: design-error
Seed: core/contract/role-handoff-contract.md §19 phase-1 bullet, new "Write-set branch-writability check" sentence (around :694), referencing core/hooks/board-gate.sh R4
cap_seconds: 60
tier: default
diff_stat_lines: single contract-text file, small delta (prose-only)
started_at: 2026-08-08T00:00:00Z
ended_at: 2026-08-08T00:05:00Z

### Reproduce
```
cd <repo>
git branch --show-current   # issue-155/implementation
CORE_PAYLOAD='{"tool_input":{"file_path":"docs/issue-132/proposals/foo.md"}}' \
  CLAUDE_ROLE=implementation CLAUDE_PROJECT_DIR="$PWD" \
  bash core/hooks/board-gate.sh <<< '{"tool_input":{"file_path":"docs/issue-132/proposals/foo.md"}}'
```
Read `core/hooks/board-gate.sh:508-515` (R4): for every `docs/issue-<m>/` write, `expected = "%s/%s" % (issue_dir, role)` where `role` is `$CLAUDE_ROLE` (unaffected by which issue is "subject"), and the branch is whatever branch the role session is actually on (`issue-<n>/<role>` per contract v3 s10, where `n` is the subject issue of the current proposal). F1 only triggers when `m != n` (the whole point of the norm is a *foreign*-issue path). But R4's own denial condition is `branch != expected`, i.e. `issue-<n>/<role> != issue-<m>/<role>`, which is true by construction whenever `m != n` — no branch name a role session can be on satisfies both "this is the role's own branch for subject issue n" and "this is `issue-<m>/<role>`" for `m != n` simultaneously.

### Observed
`board-gate.sh` denies the write deterministically: `writing docs/issue-132/ requires branch issue-132/implementation (current: issue-155/implementation)`. This holds for any role name, any `m`, any `n`, as long as `m != n` — there is no input under which R4 grants a foreign-issue path when `m != n`.

### Expected
The contract text at §19 phase-1 ("Write-set branch-writability check") reads as if the role performs a genuine check with two live outcomes — "if its own branch ... cannot write it, designs a routing alternative" implies a companion case where the branch *can* write it and no alternative is needed. Under R4 as actually implemented, that companion case is unreachable for every path the sentence is scoped to (any `docs/issue-<m>/` path with `m != n`): the check's answer is not run-time state to be discovered, it is a compile-time certainty already knowable from `m != n` alone (no per-role or per-path variation matters). The norm should either say plainly "any `docs/issue-<m>/` path with `m != n` is always undeliverable by this role's own branch — route it," dropping the false conditionality, or R4 should be the thing amended if a genuine per-case check (that can actually pass sometimes) was intended.
