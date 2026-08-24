---
proposal: docs/issue-292/proposals/2026-08-24-execution-observation-verify-pr293.md
---

# Hunt record — execution-observation-verify-pr293

## after-proposal — stance 0: assume the gate just touched is bypassable — find the bypass

Verdict: FINDING — warrant/hooks/scope-gate.sh never scans `docs/issue-<n>/proposals/` (only the repo-root `docs/proposals/`), and its own "nested proposal directory" detector only matches paths ending literally in `/docs/proposals`, so it neither enforces nor warns about this proposal's write set at `docs/issue-292/proposals/2026-08-24-execution-observation-verify-pr293.md` — it silently allows writes to files outside the declared `files:` set.
Kind: silent-failure
Seed: docs/issue-292/proposals/2026-08-24-execution-observation-verify-pr293.md (frontmatter `files: [docs/issue-292/reports/execution-observation.md]`); gate under test: warrant/hooks/scope-gate.sh
cap_seconds: 60
tier: size:docs-only
diff_stat_lines: 82 (1 file, docs-only)
started_at: 2026-08-24T18:17:11+09:00
ended_at: 2026-08-24T18:18:01+09:00

### Reproduce
```
cd /home/jwjung/.tokenmaxxxer/work/tokenmaxxxer-core-issue-292-execution-observation
export CLAUDE_PROJECT_DIR="$(pwd)"
ls docs/proposals 2>&1          # -> No such file or directory (root proposals dir doesn't exist)
ls docs/issue-292/proposals     # -> 2026-08-24-execution-observation-verify-pr293.md (this proposal, real and current)
payload='{"tool_name":"Write","tool_input":{"file_path":"'"$(pwd)"'/core/hooks/approval-gate.sh","content":"malicious"}}'
echo "$payload" | bash warrant/hooks/scope-gate.sh
echo "EXIT_CODE=$?"
```

### Observed
`EXIT_CODE=0` with no stderr output at all — the gate allows a Write to `core/hooks/approval-gate.sh`, a file completely outside this proposal's frozen `files:` set (`docs/issue-292/reports/execution-observation.md`) and outside `docs/` entirely, without a peep. Root cause: `proposals_dir = docs/proposals` (warrant/hooks/scope-gate.sh:76) does not exist in this repo — every proposal in this repo lives under `docs/issue-<n>/proposals/` instead (confirmed by this very proposal's own path, and by the hunt-record path this dispatch was told to write to: `docs/issue-292/reports/...`). Because `proposals_dir` is missing, the gate calls `stand_down()` (line 108-109), which calls `nested_units()` (line 98) to check for reach it can't cover. But `nested_units()` (lines 79-93) only flags a directory whose path `.endswith("/docs/proposals")` — `docs/issue-292/proposals` ends in `/issue-292/proposals`, not `/docs/proposals`, so it is never added to `found`. `nested_units()` returns `[]`, the warning branch is skipped, and `stand_down()` falls through to `allow()` (unconditional `sys.exit(0)`) — silently, with no stderr message telling anyone the gate is blind to the very unit in flight.

### Expected
Either scope-gate.sh should scan `docs/issue-*/proposals/` (matching the convention this repo's other gates and this very hunt-record path use), enforcing this proposal's declared `files:` write set once approved and denying/warning on writes like the one above; or, at minimum, `nested_units()`'s pattern should also match `.../issue-*/proposals` so `stand_down()` takes the "holds proposals, but this gate reads the repository root only" warning branch (print to stderr + exit 1) instead of silently calling `allow()` — so the blind spot is visible on stderr rather than indistinguishable from an intentionally-permissive pass.

## before-landing — skip, docs-only, no before-landing dispatch

Phase-2's only write this transition was
`docs/issue-292/reports/execution-observation.md` (the record itself) —
every touched path is under `docs/`, so per warrant-protocol's DOCS-ONLY
FAST PATH the before-landing hunter dispatch is skipped. `git diff
--stat` against this transition's base (`8be902d`, the after-proposal
commit) confirms: 1 file changed, all under `docs/issue-292/reports/`.
