---
proposal: docs/issue-204/proposals/shared-directive-gate-shapes.md
---

# Hunt record — shared-directive-gate-shapes

## after-proposal — stance 4: assume the write set cannot carry this work — find the path the build will need that the proposal does not list.

Verdict: NO FINDING
Seed: docs/issue-204/proposals/shared-directive-gate-shapes.md (new file, frozen write set: core/hooks/directive.sh, core/hooks/tests/run-directive-shape-tests.sh)
cap_seconds: 60
tier: default
diff_stat_lines: 1 file added, ~90 lines (proposal doc)
started_at: 2026-08-11T00:00:00Z
ended_at: 2026-08-11T00:01:30Z

Checked whether the proposal's frozen write set omits a path the described
work will actually need: confirmed no `docs/specs/reconciled-index.md` or
`gates/spec_index.py` exists in this repo (correctly external, per the
proposal's own out-of-scope note); confirmed no `coding` rulebook
`directive.sh` exists in this repo (only `scout/hooks/directive.sh`,
`core/hooks/directive.sh`, `warrant/hooks/directive.sh` — the referenced
`implementation`/`coding` rulebook directives genuinely live in another
repo, so the phase-split duplication called out in Rationale cannot be
deduplicated here, matching the proposal's claim); confirmed
`run-role-directive-staging-tests.sh` (the cited precedent) really is
absent from `core/hooks/tests/run-all.sh`, so the new test file's
same omission is a documented, consistent choice, not a silent gap; and
confirmed no CI workflow file references either test script, so nothing
outside the two-file write set needs updating to wire the new test in.
Found no third path (fixture file, registry, workflow entry) the proposed
work would need but the write set fails to list.

## before-landing — stance 0: assume the gate just touched is bypassable — find the bypass

Verdict: FINDING — the phase-split assertion in run-directive-shape-tests.sh only checks that "plain #<issue>", "is forbidden", and "phase-2 delivery PR" each occur somewhere in the rendered heredoc, with no requirement they belong to the same bullet/sentence, so it passes even if directive.sh's phase-split bullet is replaced by two unrelated, meaningless bullets that happen to contain those phrases.
Kind: silent-failure
Seed: core/hooks/directive.sh (3 new interaction-protocol bullets) and core/hooks/tests/run-directive-shape-tests.sh (new)
cap_seconds: 120
tier: default
diff_stat_lines: core/hooks/directive.sh +14 lines (3 bullets), run-directive-shape-tests.sh new file
started_at: 2026-08-11T00:00:00Z
ended_at: 2026-08-11T00:05:00Z

### Reproduce
```
cd core/hooks
python3 - <<'PY'
p = "directive.sh"
s = open(p).read()
old = """- PR trailer phase split: a phase-1 proposal PR references its issue as a
  plain #<issue> in the body; Closes/Fixes/Resolves #<issue> is forbidden
  until the phase-2 delivery PR, which must carry it — pr-preflight.sh's
  check_body refuses a phase-1 body carrying Closes/Fixes/Resolves and a
  phase-2 body missing it."""
new = """- Coffee is optional but bagels reference their topping as a
  plain #<issue> on the menu.
- Skateboarding indoors is forbidden except during the phase-2 delivery PR
  celebration party."""
assert old in s
open(p, "w").write(s.replace(old, new))
PY
bash tests/run-directive-shape-tests.sh
```

### Observed
```
ok     names the Closes/Fixes phase split for non-coding roles      present
...
directive-shape: 6 passed, 0 failed
```
All 6 assertions pass even though the actual phase-split rule text has been
replaced with two disconnected, nonsensical bullets that no longer state the
Closes/Fixes/Resolves prohibition or which PR trailer belongs where.

### Expected
The test should fail when the phase-split rule's substantive content (the
Closes/Fixes/Resolves-until-phase-2 relationship) is not actually stated as
one coherent rule — e.g. by requiring the three phrases to co-occur within a
single bullet/paragraph (a bounded window or single `-`-prefixed block),
not merely anywhere in the whole heredoc.

### resolved_findings
- finding: phase-split (and, by the same defect class, spec-index and
  test-claim) assertions matched phrases anywhere in the whole heredoc
  instead of within one coherent bullet.
  fix: all three assertions now isolate their own bullet block via `awk`
  before matching, so scattered/disconnected phrases no longer satisfy
  the check. Added a bypass-fixture test reproducing the hunter's exact
  disconnected-bullets case and asserting it is rejected.
  code_under_review:
    - core/hooks/tests/run-directive-shape-tests.sh
  verified: bash core/hooks/tests/run-directive-shape-tests.sh -> 7 passed, 0 failed (includes the new bypass-fixture assertion)
