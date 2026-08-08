---
proposal: docs/issue-183/proposals/2026-08-08-stub-check-canon-source-exclusion.md
---

# Hunt record — stub-check-canon-source-exclusion

## after-proposal — stance 3: assume the rule as written cannot hold — find the state nothing maintains

Verdict: FINDING — the planned path-prefix filter only exempts hits under `$repo_root/core/hooks/`, but this repo's real layout has more than one legitimate canonical home for a `CANON_GATES` entry (`parse-check.sh` is separately canonical under `core/`, `terse/`, `freelunch/`, and `scout/` per `compliance-check.sh`'s own hash-based design), so the fix leaves those plugins' own sanctioned copies false-flagged exactly as today, unaddressed by the "drop hits under core/hooks/" rule.
Kind: design-error
Seed: docs/issue-183/proposals/2026-08-08-stub-check-canon-source-exclusion.md (proposal-only diff, 2 files / 112 lines)
cap_seconds: 60
tier: default
diff_stat_lines: 112
started_at: 2026-08-08T12:02:02Z
ended_at: 2026-08-08T12:10:00Z

### Reproduce
```
cd /home/jwjung/.tokenmaxxxer/work/tokenmaxxxer-core-issue-183-implementation
bash core/hooks/tests/stub-check.sh terse/hooks
```

### Observed
```
stub-check: FAIL — vendored copy of core canon file 'parse-check.sh' found:
terse/hooks/tests/parse-check.sh
  This file is now a core hook (core/hooks/hooks.json), fired for
  every plugin install. A local copy is drift, not a stub — delete
  it and drop the file's own hooks.json entry, if any (issue-66).
```
`terse/hooks/tests/parse-check.sh` is terse's own sanctioned, independently-maintained canonical copy (compliance-check.sh's comment at lines 74-83 explicitly documents "parse-check.sh: core/terse/freelunch/scout each carry their own copy" and hash-compares a hit against ALL of them, not just core's). stub-check.sh's absence-based `CANON_GATES` loop has no concept of this and flags it as vendored drift regardless.

The proposal's planned fix computes `repo_root` and drops only hits resolving under `$repo_root/core/hooks/` before flagging. That rule is scoped to a single directory (core's own canonical home) and does not maintain — has no state or manifest tracking — the fact that some `CANON_GATES` entries (parse-check.sh, per canon-manifest.txt + compliance-check.sh's own design) are legitimately canonical in more than one plugin root in this same repo. Running the same repro against the fix's own acceptance case (`core/hooks`) will pass, but `terse/hooks`, `freelunch/hooks`, and `scout/hooks` will continue to false-positive on `parse-check.sh` exactly as they do pre-fix, since none of those paths resolve under `$repo_root/core/hooks/`.

### Expected
Either the fix's exemption rule accounts for all of this repo's legitimate canonical roots for a given `CANON_GATES`/manifest entry (mirroring compliance-check.sh's per-name, multi-source model), or the proposal should explicitly scope its "still flags" acceptance case to confirm it does NOT regress/mask this known multi-canon-source class, rather than only testing a single vendored-copy-outside-core/hooks fixture. As written, the proposal's "How you'll know it worked" checklist never exercises this layout and would ship a fix that looks complete while leaving three plugins' own canonical parse-check.sh copies permanently false-flagged whenever anyone points stub-check.sh at them.
