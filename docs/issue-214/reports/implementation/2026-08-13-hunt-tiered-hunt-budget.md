---
proposal: docs/issue-214/proposals/tiered-hunt-budget.md
---

# Hunt record — tiered-hunt-budget

## after-proposal — stance 3: assume the rule as written cannot hold — find the state nothing maintains

Verdict: FINDING — the Request's "extra stances only on FIND" has no state carrying a prior dispatch's FINDING/NO-FINDING result into hunt-tier.sh, and it contradicts the directive's actual adaptive-cadence rule, which does the opposite (a FIND resets stance count *down* to the size-derived default; only miss-streaks step it, never up).
Kind: design-error
Seed: docs/issue-214/proposals/tiered-hunt-budget.md (new-file, docs-only)
cap_seconds: 120
tier: default
diff_stat_lines: ~90 (new proposal file)
started_at: 2026-08-13T00:00:00Z
ended_at: 2026-08-13T00:03:00Z

### Reproduce
```
grep -n "extra stances only on FIND" docs/issue-214/proposals/tiered-hunt-budget.md
grep -n "stances\|two stances" warrant/hooks/directive.sh
```
Proposal line 15: "extra stances only on FIND"
`hunt-tier.sh`'s described interface (proposal lines 42-49) is `<base-ref> [<head-ref>]` — a pure `git diff --numstat` scan with no input for "did the previous stance find something." Its `stances=<0|1|2>` output is derived purely from diff shape (`full` tier = fixed 2 regardless of size/history), so the promised "extra stances only on FIND" behavior cannot be produced by the script as specified — there is no state anywhere (not in hunt-tier.sh's inputs, not in hunt-state.sh's lock/count files, not in the directive) that records a prior stance's FIND/NO-FIND result for a later stance-count decision to consult.

directive.sh:70 states the opposite mapping that already exists and governs stance/tier count: "A `FINDING` resets the streak and the tier to the size-derived default on the next dispatch" (i.e., FIND -> normal/reset, not FIND -> bonus stance) and "if the last 3 consecutive hunt dispatches ... returned `NO FINDING`, drop the next dispatch's tier by one step" (i.e., misses shrink budget, not finds grow it).

### Expected
The Request's framing should either be dropped/reworded to match the directive's real (and unchanged, per Constraints) adaptive-cadence semantics, or the proposal should specify what state would need to be added (and by what mechanism) to let a stance-count decision consult a prior dispatch's FIND/NO-FIND outcome — currently nothing does, so "extra stances only on FIND" is a promise the design as written cannot keep.

## before-landing — stance 1: assume this change and another plugin's rule cancel each other — find the pair

Verdict: FINDING — hunt-tier.sh's gates/hooks path-segment override forces tier=full for a diff that is entirely under docs/, directly contradicting directive.sh's "DOCS-ONLY FAST PATH" rule (skip the before-landing dispatch entirely when every touched path is under docs/) whenever the docs path itself contains a `hooks/` or `gates/` directory segment.
Kind: composition
Seed: warrant/hooks/hunt-tier.sh (new), warrant/hooks/directive.sh tier-table addition — diff for `git diff main issue-214/implementation`
cap_seconds: 180
tier: full
diff_stat_lines: ~3 files touched under warrant/hooks/ (hunt-tier.sh, tests/run-hunt-tier-tests.sh, directive.sh addition)
started_at: 2026-08-13T00:00:00Z
ended_at: 2026-08-13T00:15:00Z

### Reproduce
```
mkdir -p /tmp/fakebin && cat > /tmp/fakebin/git <<'EOF2'
#!/usr/bin/env bash
if [ "$1" = "diff" ]; then
  printf '1\t0\tdocs/issue-1/reports/hooks/notes.md\n'
  exit 0
fi
exec /usr/bin/git "$@"
EOF2
chmod +x /tmp/fakebin/git
PATH=/tmp/fakebin:$PATH bash warrant/hooks/hunt-tier.sh HEAD~1 HEAD
```

### Observed
```
tier=full cap_seconds=180 max_stances=2 reason=gates-or-hooks-path-touched
```
for a diff whose only touched file is `docs/issue-1/reports/hooks/notes.md` — entirely under `docs/`.

### Expected
Per directive.sh line 69 ("DOCS-ONLY FAST PATH: when every touched path is under `docs/`, the before-landing dispatch is skipped"), and directive.sh line 67's own claim that hunt-tier.sh "is the check this table's mapping must match", a wholly-docs diff should never classify as `tier=full` — it should report `tier=docs-only` (or be recognized as the fast-path-skip case) regardless of what subdirectory name the docs path happens to use. Instead the `*/hooks/*|*/gates/*` segment match runs on every path unconditionally, including ones already under `docs/`, so the override silently cancels the docs-only fast path for any docs path with a `hooks` or `gates` directory component (e.g. a hunt record written to `docs/issue-<n>/reports/<role>/...` where a role or report subfolder is literally named `hooks` or `gates`, or a proposal path like `docs/issue-63/proposals/hooks-and-gates/...`).
