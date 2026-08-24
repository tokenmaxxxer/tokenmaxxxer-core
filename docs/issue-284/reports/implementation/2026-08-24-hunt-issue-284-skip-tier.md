---
proposal: build-now bypass, no proposal file — issue #284
---

# Hunt record — issue-284-skip-tier

## before-landing — stance 1: assume the gate/composition change just touched is bypassable — find the bypass

Verdict: FINDING — a 1-line self-approval edit to a docs/proposals/*.md frontmatter `status:` field (proposed -> approved) is docs-only and <=5 lines, so the new tier=skip floor exempts it from hunter dispatch entirely, even though that exact status flip is what scope-gate.sh treats as the security-relevant trigger for enabling/altering write-set enforcement.
Kind: composition
Seed: staged warrant/hooks/hunt-tier.sh (new tier=skip branch), warrant/directive/warrant-protocol.md prose bullet, warrant/hooks/tests/run-hunt-tier-tests.sh
cap_seconds: 180
tier: size:full (gates-or-hooks-path-touched)
diff_stat_lines: 4 files staged (hunt-tier.sh, run-hunt-tier-tests.sh, warrant-protocol.md, docs/issue-284/reports/implementation.md)
started_at: 2026-08-24T00:00:00Z
ended_at: 2026-08-24T00:15:00Z

### Reproduce
```
tmp=$(mktemp -d); cd "$tmp"; git init -q
mkdir -p docs/proposals
cat > docs/proposals/2026-08-24-example.md <<'EOF2'
---
status: proposed
write_set:
  - src/foo.py
---

# Example proposal
EOF2
git add -A && git commit -q -m base

sed -i 's/status: proposed/status: approved/' docs/proposals/2026-08-24-example.md
git add -A && git commit -q -m "self-approve"

git diff --numstat HEAD~1 HEAD
bash /home/jwjung/.tokenmaxxxer/work/tokenmaxxxer-core-issue-284-implementation/warrant/hooks/hunt-tier.sh HEAD~1 HEAD
```

### Observed
```
1	1	docs/proposals/2026-08-24-example.md
tier=skip cap_seconds=0 max_stances=0 reason=docs-only-trivial-diff
```
The diff that flips a proposal's `status:` field from `proposed` to `approved` — the exact field `warrant/hooks/scope-gate.sh` reads (`STATUS = re.compile(r"^status:\s*([A-Za-z]+)...")`, `if state == "approved": approved.append(...)`) to decide whether write-set enforcement is armed — is classified `tier=skip`, `cap_seconds=0`. Per hunt-tier.sh's own contract ("Output ... the dispatch itself is skipped, not merely shrunk to the cheapest paid tier"), no warrant-hunter dispatch happens at all for this diff.

### Expected
A frontmatter field that a gate script (scope-gate.sh) machine-reads to decide enforcement state is not "docs" in the sense the skip-tier's `docs_only` test intends (prose, no behavioral effect). The `gates_hooks_hit` override already carves out an explicit "docs/ is never gates/hooks code even if it's ABOUT hooks" exception (hunt-tier.sh:58-60) for report/prose files, but that same blanket exception also swallows docs/proposals/*.md frontmatter, which is not prose — it is the on-disk state scope-gate.sh's own approval gate reads. A self-approval (or any other frontmatter-only status/write_set edit) of <=5 changed lines should not silently land tier=skip; at minimum it should fall through to a paid tier (docs-only/small/full) so a hunter dispatch actually looks at it.

### Resolution
Fixed before landing, same session: added a `proposals_hit` flag to `warrant/hooks/hunt-tier.sh`, set whenever any touched path has a `proposals/` directory segment (mirrors the existing `gates_hooks_hit` segment-match style), and gated the skip branch on `proposals_hit -eq 0`. A proposals/ path — small and docs-only or not — now falls through to the unchanged docs-only (60s) tier instead of skip. `warrant/directive/warrant-protocol.md`'s new bullet was updated to state the exclusion explicitly, and a regression test (`proposals-path-does-not-skip`) was added to `run-hunt-tier-tests.sh` reproducing this exact repro shape. Re-running the reproduction above after the fix:
```
$ bash /home/jwjung/.tokenmaxxxer/work/tokenmaxxxer-core-issue-284-implementation/warrant/hooks/hunt-tier.sh HEAD~1 HEAD
tier=docs-only cap_seconds=60 max_stances=1 reason=docs-only-or-tiny-diff
```
